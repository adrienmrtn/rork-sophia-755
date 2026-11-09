import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { AdminHeader } from "@/components/admin/AdminChrome";
import { BlockView } from "@/components/CourseBlocks";
import { JobSteps, JobSummary } from "@/components/studio/JobSteps";
import { StatusPill } from "@/components/studio/StudioChrome";
import { Card, Initials, container } from "@/components/ui";
import { renderInline } from "@/lib/catalog/inline";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { getStudioSession, type CreatorAccount } from "@/lib/studio/account";
import { LANGS } from "@/lib/catalog/types";
import { LANG_NAMES } from "@/lib/catalog/lang-names";
import { getDraft, getJob, listReviews, shortDateTime } from "@/lib/studio/data";
import { moneyCents, parseQuota, quotaBadge } from "@/lib/studio/payments";
import { CLASSIFICATION_LABEL, courseWords, validateCourse, type Classification, type DraftCourse } from "@/lib/studio/course-format";
import { decideProposal, publishDraft, reviewDraft } from "@/app/admin/actions";

export const dynamic = "force-dynamic";

const DECISION_LABEL: Record<string, string> = {
  proposed: "Proposal sent",
  proposal_accepted: "Proposal accepted",
  proposal_returned: "Proposal returned",
  submitted: "Sent for review",
  withdrawn: "Withdrawn",
  changes_requested: "Changes requested",
  accepted: "Validated",
  validated: "Credited to the author",
  rejected: "Declined",
  reopened: "Reopened",
  published: "Production finished",
  publish_failed: "Production failed",
  note: "Note",
};

const DONE: Record<string, string> = {
  published: "Production launched. The factory reports step by step below.",
  proposal_accepted: "Proposal accepted. The author can now write the course.",
  proposal_returned: "Proposal returned to the author with your note.",
};

export default async function ReviewPage({ params, searchParams }: PageProps<"/admin/review/[id]">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const { id } = await params;
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const { supabase } = session;
  const draft = await getDraft(supabase, id);
  if (!draft) notFound();
  const [{ data: accountRow }, reviews, job, { data: quotaRaw }] = await Promise.all([
    supabase.from("creator_accounts").select("*").eq("user_id", draft.user_id).maybeSingle(),
    listReviews(supabase, id),
    draft.last_job_id ? getJob(supabase, draft.last_job_id) : null,
    supabase.rpc("studio_quota", { p_user: draft.user_id }),
  ]);
  const account = (accountRow as CreatorAccount | null) ?? null;
  const quota = parseQuota(quotaRaw);
  const fee = moneyCents(quota?.fee_cents ?? 1500, quota?.currency ?? "USD");
  const isProposal = draft.status === "proposed" || draft.status === "proposal_returned";
  // Pour un cours publié : les langues déjà en ligne, pour proposer les autres.
  const publishedLangs = new Set<string>();
  if (draft.status === "published" && draft.app_course_id) {
    const { data: contents } = await supabase.from("course_contents").select("lang,status").eq("course_id", draft.app_course_id);
    for (const row of (contents ?? []) as { lang: string; status: string }[]) if (row.status === "published") publishedLangs.add(row.lang);
  }
  const missingLangs = LANGS.filter((l) => l !== draft.origin_lang && !publishedLangs.has(l));
  let photoUrl: string | null = null;
  if (account?.photo_path) {
    const { data } = await supabase.storage.from("studio-photos").createSignedUrl(account.photo_path, 3600);
    photoUrl = data?.signedUrl ?? null;
  }
  const course: DraftCourse = { title: draft.title, subtitle: draft.subtitle, subject: draft.subject, subcategory: draft.subcategory, description: draft.description, hero: draft.hero ?? {}, sections: draft.sections ?? [], sources: draft.sources ?? [], glossary: draft.glossary ?? [] };
  const findings = isProposal ? [] : validateCourse(course);
  const errors = findings.filter((f) => f.severity === "error");
  const warnings = findings.filter((f) => f.severity === "warning");
  const words = courseWords(course);
  const canDecide = draft.status === "submitted";
  const needsValidation = !draft.validated_at && ["submitted", "changes_requested"].includes(draft.status);
  const accountBlocks = needsValidation && account?.status !== "approved";
  const quotaBlocks = needsValidation && quota != null && !quota.can_validate && account?.status === "approved";
  const canPublish = ["submitted", "accepted", "failed"].includes(draft.status) && errors.length === 0 && !accountBlocks && !quotaBlocks;
  const authorName = account?.display_name || [account?.first_name, account?.last_name].filter(Boolean).join(" ") || "Unknown author";
  const heroSrc = course.hero.image_url ?? (course.hero.image ? `https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/${course.hero.image}.jpg` : null);

  const authorCard = (
    <Card className="flex flex-col gap-3 p-5">
      <div className="flex items-center gap-3">
        {photoUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={photoUrl} alt="" className="h-12 w-12 rounded-full object-cover" />
        ) : (
          <Initials name={authorName} size={48} />
        )}
        <div className="flex min-w-0 flex-col">
          <strong className="truncate text-[15px] font-bold">{authorName}</strong>
          <span className="truncate text-[12px] text-ink-3">{account?.title ?? account?.email ?? ""}</span>
        </div>
      </div>
      <dl className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-[13px]">
        <dt className="text-ink-3">Account</dt>
        <dd className="font-semibold">{account?.status ?? "–"}</dd>
        <dt className="text-ink-3">Slug</dt>
        <dd className="truncate font-semibold">{account?.slug ?? "–"}</dd>
        <dt className="text-ink-3">Institution</dt>
        <dd className="truncate font-semibold">{[account?.institution, account?.country].filter(Boolean).join(", ") || "–"}</dd>
        <dt className="text-ink-3">Email</dt>
        <dd className="truncate font-semibold">{account?.email ?? "–"}</dd>
        <dt className="text-ink-3">Quota</dt>
        <dd className={`font-semibold ${quota && (quota.blocked || !quota.can_validate) ? "text-amber" : ""}`}>{quotaBadge(quota)}</dd>
      </dl>
      <Link href="/admin/creators" className="text-[13px] font-bold text-blue">
        Manage the account →
      </Link>
    </Card>
  );

  const historyCard = (
    <Card className="flex flex-col gap-3 p-5">
      <h2 className="text-[16px] font-extrabold">History</h2>
      <ol className="flex flex-col gap-2.5">
        {reviews.length === 0 && <li className="text-[13px] text-muted">Nothing yet.</li>}
        {reviews.map((r) => (
          <li key={r.id} className="flex flex-col border-l-2 border-line pl-3 text-[13px]">
            <span className="font-bold text-ink">{DECISION_LABEL[r.decision] ?? r.decision}</span>
            <span className="text-[12px] text-muted">{shortDateTime(r.created_at)}</span>
            {r.comment && r.decision !== "proposed" && <p className="mt-0.5 whitespace-pre-wrap text-ink-2">{r.comment}</p>}
          </li>
        ))}
      </ol>
    </Card>
  );

  if (isProposal) {
    return (
      <>
        <AdminHeader session={session} active="review" />
        <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
          <Link href="/admin/review" className="text-[13px] font-bold text-blue">
            ← Review queue
          </Link>
          {error && (
            <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
              {error}
            </p>
          )}
          {done && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">{DONE[done] ?? `Decision recorded: ${DECISION_LABEL[done] ?? done}.`}</p>}
          <div className="grid grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1fr)_400px]">
            <article className="flex flex-col gap-5">
              <Card className="flex flex-col gap-4 p-8">
                <div className="flex flex-wrap items-center gap-3">
                  <StatusPill status={draft.status} />
                  <span className="text-[13px] text-ink-3">
                    Proposal · {draft.origin_lang.toUpperCase()} · sent {shortDateTime(draft.proposed_at ?? draft.created_at)}
                  </span>
                </div>
                <h1 className="text-[34px] font-extrabold leading-[1.1] tracking-[-0.9px] text-ink">{draft.title || "Untitled course"}</h1>
                <p className="whitespace-pre-wrap text-[17px] leading-[1.6] text-ink-2">{draft.pitch || "No pitch."}</p>
                {draft.status === "proposal_returned" && draft.proposal_note && (
                  <div className="rounded-2xl bg-red-bg/50 px-4 py-3 text-[14px] text-ink">
                    <strong className="block text-[12px] font-bold uppercase tracking-[1px] text-red">Your note to the author</strong>
                    <p className="mt-1 whitespace-pre-wrap">{draft.proposal_note}</p>
                  </div>
                )}
              </Card>
            </article>
            <aside className="flex flex-col gap-5 xl:sticky xl:top-6 xl:self-start">
              {authorCard}
              <Card className="flex flex-col gap-4 p-5">
                <h2 className="text-[16px] font-extrabold">Decision</h2>
                <p className="text-[13px] text-ink-3">Accepting opens the editor for the author. Returning sends your note (another title, an angle to change). Deleting removes the proposal for good.</p>
                <form action={decideProposal} className="flex flex-col gap-2">
                  <input type="hidden" name="id" value={draft.id} />
                  <textarea name="note" rows={4} placeholder="Note to the author, or a title to suggest (required to return)" className="w-full resize-none rounded-xl border border-line bg-white px-3.5 py-2.5 text-[14px] leading-[1.5] outline-none focus:border-blue" />
                  <div className="flex flex-wrap gap-2">
                    <button type="submit" name="decision" value="accepted" className="rounded-xl bg-navy px-3 py-2 text-[13px] font-bold text-white hover:bg-ink">
                      Accept the proposal
                    </button>
                    <button type="submit" name="decision" value="returned" className="rounded-xl border border-line bg-white px-3 py-2 text-[13px] font-bold text-amber hover:bg-cream">
                      Return with the note
                    </button>
                    <button type="submit" name="decision" value="deleted" className="rounded-xl border border-line bg-white px-3 py-2 text-[13px] font-bold text-red hover:bg-red-bg">
                      Delete
                    </button>
                  </div>
                </form>
                {quota && !quota.can_propose && <p className="text-[12px] text-amber">This author is at their limit ({quota.open} in progress for a limit of {quota.limit}); accepting is still possible.</p>}
              </Card>
              {historyCard}
            </aside>
          </div>
        </main>
      </>
    );
  }

  return (
    <>
      <AdminHeader session={session} active="review" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <Link href="/admin/review" className="text-[13px] font-bold text-blue">
          ← Review queue
        </Link>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {done && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">{DONE[done] ?? `Decision recorded: ${DECISION_LABEL[done] ?? done}.`}</p>}

        <div className="grid grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1fr)_400px]">
          {/* Le cours */}
          <article className="flex flex-col gap-5">
            <Card className="flex flex-col gap-4 p-8">
              <div className="flex flex-wrap items-center gap-3">
                <StatusPill status={draft.status} />
                <span className="text-[13px] text-ink-3">
                  {course.subject ? `${SUBJECT_LABEL[course.subject as keyof typeof SUBJECT_LABEL] ?? course.subject}${course.subcategory ? ` · ${course.subcategory}` : ""} · ` : ""}
                  {draft.origin_lang.toUpperCase()} · {course.sections.length} sections · {words.toLocaleString("en")} words · v{draft.version}
                </span>
                {draft.validated_at && <span className="rounded-full bg-green-bg px-2.5 py-1 text-[12px] font-bold text-green">Validated {shortDateTime(draft.validated_at)} · {fee} credited</span>}
              </div>
              <h1 className="text-[34px] font-extrabold leading-[1.1] tracking-[-0.9px] text-ink">{course.title || "Untitled course"}</h1>
              {course.subtitle && <p className="text-[18px] font-semibold text-ink-3">{course.subtitle}</p>}
              {course.description && <p className="text-[17px] leading-[1.55] text-ink-2">{renderInline(course.description)}</p>}
              {heroSrc && (
                <figure className="flex flex-col gap-1.5">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={heroSrc} alt="" className="aspect-[16/9] w-full rounded-card object-cover" />
                  {course.hero.credit && <figcaption className="text-[12px] text-muted">{[course.hero.credit.title, course.hero.credit.author, course.hero.credit.license, course.hero.credit.source].filter(Boolean).join(" · ")}</figcaption>}
                </figure>
              )}
              {course.hero.hook && <p className="text-[15px] italic text-ink-3">Hook: {course.hero.hook}</p>}
            </Card>
            {draft.pitch && (
              <Card className="flex flex-col gap-2 border-cream-2 bg-cream p-6">
                <strong className="text-[12px] font-bold uppercase tracking-[1px] text-amber">The proposal, as accepted{draft.proposal_decided_at ? ` on ${shortDateTime(draft.proposal_decided_at)}` : ""}</strong>
                <p className="whitespace-pre-wrap text-[14px] leading-[1.55] text-ink-2">{draft.pitch}</p>
                {draft.proposal_note && <p className="text-[13px] text-ink-3">Your note then: {draft.proposal_note}</p>}
              </Card>
            )}
            {course.sections.map((sec, i) => (
              <Card key={i} className="prose-course flex flex-col gap-3 p-8">
                <div className="flex items-center gap-3">
                  <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-tint text-[12px] font-extrabold text-navy">{i + 1}</span>
                  <h2 className="text-[24px] font-extrabold tracking-[-0.5px] text-ink">{sec.title || `Section ${i + 1}`}</h2>
                  <span className="ml-auto text-[12px] font-bold text-muted">{i === 0 || sec.free ? "Free" : "Premium"}</span>
                </div>
                {sec.blocks.map((b, j) => (
                  <BlockView key={j} block={b} plain />
                ))}
              </Card>
            ))}
            <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
              <Card className="flex flex-col gap-3 p-6">
                <h2 className="text-[16px] font-extrabold">Glossary · {course.glossary.length}</h2>
                <ul className="flex flex-col gap-2 text-[14px]">
                  {course.glossary.map((g, i) => (
                    <li key={i}>
                      <strong>{g.term}</strong> <span className="text-[12px] text-muted">{CLASSIFICATION_LABEL[g.classification as Classification] ?? g.classification}</span>
                      <p className="text-ink-2">{g.explanation}</p>
                    </li>
                  ))}
                  {course.glossary.length === 0 && <li className="text-muted">None (the factory will write the cited terms).</li>}
                </ul>
              </Card>
              <Card className="flex flex-col gap-3 p-6">
                <h2 className="text-[16px] font-extrabold">Sources · {course.sources.length}</h2>
                <ul className="flex flex-col gap-1.5 text-[14px] text-ink-2">
                  {course.sources.map((src, i) => (
                    <li key={i}>
                      {src.url ? (
                        <a href={src.url} target="_blank" rel="noreferrer" className="text-blue underline">
                          {src.text}
                        </a>
                      ) : (
                        src.text
                      )}
                    </li>
                  ))}
                  {course.sources.length === 0 && <li className="text-muted">None.</li>}
                </ul>
              </Card>
            </div>
          </article>

          {/* Décision */}
          <aside className="flex flex-col gap-5 xl:sticky xl:top-6 xl:max-h-[calc(100vh-48px)] xl:self-start xl:overflow-y-auto">
            {authorCard}

            <Card className="flex flex-col gap-3 p-5">
              <h2 className="text-[16px] font-extrabold">Format checks</h2>
              <p className={`text-[13px] font-semibold ${errors.length ? "text-red" : "text-green"}`}>{errors.length ? `${errors.length} problems: the factory would refuse this course.` : "The factory would accept this course."}</p>
              {errors.length > 0 && (
                <ul className="flex flex-col gap-1 text-[13px] text-ink-2">
                  {errors.map((f, i) => (
                    <li key={i}>· {f.message}</li>
                  ))}
                </ul>
              )}
              {warnings.length > 0 && (
                <details>
                  <summary className="cursor-pointer text-[13px] font-bold text-ink-3">{warnings.length} advice notes</summary>
                  <ul className="mt-1 flex flex-col gap-1 text-[13px] text-ink-3">
                    {warnings.map((f, i) => (
                      <li key={i}>· {f.message}</li>
                    ))}
                  </ul>
                </details>
              )}
            </Card>

            <Card className="flex flex-col gap-4 p-5">
              <h2 className="text-[16px] font-extrabold">Decision</h2>
              {accountBlocks && <p className="rounded-xl bg-amber-bg/60 px-3 py-2 text-[13px] font-semibold text-amber">The author&apos;s account is {account?.status ?? "missing"}. Approve it on the Creators page before validating: validation pays {fee}.</p>}
              {quotaBlocks && quota && (
                <p className="rounded-xl bg-amber-bg/60 px-3 py-2 text-[13px] font-semibold text-amber">
                  Weekly limit reached for this author ({quota.used}/{quota.limit} validated{quota.first_week ? " in their first week" : " this week"}). Validation opens again on {quota.period_end ? new Date(quota.period_end).toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "short", timeZone: "Europe/Paris" }) : "the next period"}, or raise their limit on the Creators page.
                </p>
              )}
              {canPublish && (
                <form action={publishDraft} className="flex flex-col gap-3">
                  <input type="hidden" name="id" value={draft.id} />
                  <details className="rounded-xl border border-line bg-paper p-3 text-[13px]">
                    <summary className="cursor-pointer font-bold text-ink-2">
                      Languages: all 29 by default <span className="font-medium text-muted">(click to choose)</span>
                    </summary>
                    <p className="mt-2 text-[12px] text-muted">
                      {draft.origin_lang.toUpperCase()} is the original and is always published. Untick the languages this course should not be translated into.
                    </p>
                    <div className="mt-2 grid grid-cols-2 gap-x-3 gap-y-1.5 sm:grid-cols-3">
                      {LANGS.filter((l) => l !== draft.origin_lang).map((l) => (
                        <label key={l} className="flex items-center gap-1.5 text-[12px] font-semibold text-ink-2">
                          <input type="checkbox" name="languages" value={l} defaultChecked className="h-3.5 w-3.5 accent-navy" />
                          {LANG_NAMES[l] ?? l}
                        </label>
                      ))}
                    </div>
                  </details>
                  <button type="submit" className="inline-flex h-11 items-center justify-center rounded-btn bg-navy px-4 text-[15px] font-bold text-white hover:bg-ink">
                    {draft.status === "failed" ? "Relaunch production" : draft.status === "accepted" ? "Launch production" : `Accept and launch production · +${fee}`}
                  </button>
                  <span className="text-[12px] text-muted">
                    {needsValidation ? `Validates the course: ${fee} go to the author's pot (paid Monday) and one slot of their weekly limit is used. Then ` : ""}
                    {needsValidation ? "sends" : "Sends"} the course to publish-course; the factory writes the quiz and the glossary, translates into the chosen languages and publishes each one that passes. About an hour for 29 languages.
                  </span>
                </form>
              )}
              {draft.status === "publishing" && <p className="text-[13px] text-ink-3">In production. Decisions reopen once the factory is done.</p>}
              {draft.status === "published" && draft.app_course_id && (
                <form action={publishDraft} className="flex flex-col gap-3">
                  <input type="hidden" name="id" value={draft.id} />
                  <p className="text-[13px] text-ink-2">
                    Live in <strong>{publishedLangs.size}</strong> {publishedLangs.size === 1 ? "language" : "languages"}: {[...publishedLangs].map((l) => LANG_NAMES[l] ?? l).join(", ") || "none yet"}.
                  </p>
                  {missingLangs.length > 0 ? (
                    <details className="rounded-xl border border-line bg-paper p-3 text-[13px]">
                      <summary className="cursor-pointer font-bold text-ink-2">Translate into more languages</summary>
                      <div className="mt-2 grid grid-cols-2 gap-x-3 gap-y-1.5 sm:grid-cols-3">
                        {missingLangs.map((l) => (
                          <label key={l} className="flex items-center gap-1.5 text-[12px] font-semibold text-ink-2">
                            <input type="checkbox" name="languages" value={l} className="h-3.5 w-3.5 accent-navy" />
                            {LANG_NAMES[l] ?? l}
                          </label>
                        ))}
                      </div>
                      <button type="submit" className="mt-3 inline-flex h-10 items-center justify-center rounded-btn bg-navy px-4 text-[14px] font-bold text-white hover:bg-ink">
                        Launch these translations
                      </button>
                      <span className="mt-2 block text-[12px] text-muted">The factory translates the course into the ticked languages only; the ones already live are untouched.</span>
                    </details>
                  ) : (
                    <p className="text-[12px] text-muted">Published in every language.</p>
                  )}
                </form>
              )}
              {(canDecide || draft.status === "accepted" || draft.status === "published" || draft.status === "archived" || draft.status === "changes_requested" || draft.status === "failed") && (
                <form action={reviewDraft} className="flex flex-col gap-2">
                  <input type="hidden" name="id" value={draft.id} />
                  <textarea name="comment" rows={4} placeholder="Message to the author (required to request changes)" className="w-full resize-none rounded-xl border border-line bg-white px-3.5 py-2.5 text-[14px] leading-[1.5] outline-none focus:border-blue" />
                  <div className="flex flex-wrap gap-2">
                    {canDecide && (
                      <>
                        <button type="submit" name="decision" value="changes_requested" className="rounded-xl border border-line bg-white px-3 py-2 text-[13px] font-bold text-red hover:bg-red-bg">
                          Request changes
                        </button>
                        {!accountBlocks && !quotaBlocks && (
                          <button type="submit" name="decision" value="accepted" className="rounded-xl border border-line bg-white px-3 py-2 text-[13px] font-bold text-green hover:bg-green-bg">
                            Validate only (+{fee}, launch later)
                          </button>
                        )}
                        <button type="submit" name="decision" value="rejected" className="rounded-xl border border-line bg-white px-3 py-2 text-[13px] font-bold text-ink-3 hover:bg-paper">
                          Decline
                        </button>
                      </>
                    )}
                    {(draft.status === "accepted" || draft.status === "archived" || draft.status === "changes_requested" || draft.status === "failed") && (
                      <button type="submit" name="decision" value="reopened" className="rounded-xl border border-line bg-white px-3 py-2 text-[13px] font-bold text-navy hover:bg-tint">
                        Reopen for the author
                      </button>
                    )}
                    <button type="submit" name="decision" value="note" className="rounded-xl px-3 py-2 text-[13px] font-bold text-ink-3 hover:bg-paper">
                      Add a note
                    </button>
                  </div>
                </form>
              )}
            </Card>

            {job && (
              <Card className="flex flex-col gap-4 p-5">
                <div className="flex items-center justify-between">
                  <h2 className="text-[16px] font-extrabold">Production</h2>
                  <Link href={`/admin/production/${job.job.id}`} className="text-[13px] font-bold text-blue">
                    Details →
                  </Link>
                </div>
                <JobSummary job={job.job} />
                <JobSteps steps={job.steps} />
              </Card>
            )}

            {historyCard}
          </aside>
        </div>
      </main>
    </>
  );
}
