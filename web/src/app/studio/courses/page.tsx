import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Art } from "@/components/studio/Art";
import { PageTitle, StatusPill, StudioHeader } from "@/components/studio/StudioChrome";
import { Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { SUBJECT_ART, SUBJECT_LABEL } from "@/lib/catalog/slugs";
import type { Subject } from "@/lib/catalog/types";
import { getStudioSession } from "@/lib/studio/account";
import { listDrafts, shortDate } from "@/lib/studio/data";
import { quotaSummary, type QuotaTone } from "@/lib/studio/payments";
import { courseWords, type DraftCourse } from "@/lib/studio/course-format";

export const dynamic = "force-dynamic";

const GROUPS: [string, string, string[]][] = [
  [s.courses.proposals, s.courses.proposalsLead, ["proposed", "proposal_returned"]],
  ["In progress", "Accepted proposals. Only you can see them. Open one to keep writing.", ["draft", "changes_requested"]],
  ["With the team", "In review, validated, or going through the factory.", ["submitted", "accepted", "publishing", "failed"]],
  ["Published", "Live in the app. Their readers are on your dashboard.", ["published"]],
  ["Archived", "", ["archived"]],
];

const TONE: Record<QuotaTone, string> = { ok: "bg-tint text-navy", full: "bg-cream text-amber", blocked: "bg-red-bg text-red" };
const NEW_BUTTON = "inline-flex h-11 items-center gap-2 rounded-full bg-navy px-5 text-[15px] font-bold text-white transition-colors hover:bg-ink";

export default async function CoursesPage({ searchParams }: PageProps<"/studio/courses">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/courses");
  if (!session.account) redirect("/studio/onboarding/identity");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const drafts = await listDrafts(session.supabase, session.user.id);
  const c = s.courses;
  const q = quotaSummary(session.quota);
  const canPropose = session.quota ? session.quota.can_propose : true;

  return (
    <>
      <StudioHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col gap-8 pt-7 pb-20`}>
        <PageTitle title={c.title} lead={c.lead}>
          <div className="flex flex-col items-end gap-2">
            {canPropose ? (
              <Link href="/studio/courses/new" className={NEW_BUTTON}>
                + {c.newCourse}
              </Link>
            ) : (
              <span className={`${NEW_BUTTON} cursor-not-allowed opacity-40`} title={q.detail || q.headline}>
                + {c.newCourse}
              </span>
            )}
            <span className={`rounded-full px-3 py-1 text-[12px] font-bold ${TONE[q.tone]}`}>
              {q.headline}
              {q.detail ? ` ${q.detail}.` : ""}
            </span>
          </div>
        </PageTitle>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {done === "deleted" && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">Proposal deleted.</p>}
        {drafts.length === 0 && (
          <Card className="grid grid-cols-1 items-center gap-6 border-tint bg-tint/60 p-8 md:grid-cols-[220px_minmax(0,1fr)]">
            <Art name="studio_empty" size={220} className="mx-auto" />
            <div className="flex flex-col items-start gap-4">
              <h2 className="text-[24px] font-extrabold tracking-[-0.5px] text-ink">Your first course starts with a proposal</h2>
              <p className="max-w-[560px] text-[16px] leading-[1.55] text-ink-2">{c.empty}</p>
              {canPropose && (
                <Link href="/studio/courses/new" className={NEW_BUTTON}>
                  {c.newCourse}
                </Link>
              )}
            </div>
          </Card>
        )}
        {GROUPS.map(([title, lead, statuses]) => {
          const rows = drafts.filter((d) => statuses.includes(d.status));
          if (rows.length === 0) return null;
          return (
            <section key={title} className="flex flex-col gap-4">
              <div className="flex flex-col gap-0.5">
                <h2 className="text-[20px] font-extrabold tracking-[-0.4px] text-ink">
                  {title} <span className="text-[15px] font-bold text-muted">· {rows.length}</span>
                </h2>
                {lead && <span className="text-[13px] text-ink-3">{lead}</span>}
              </div>
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                {rows.map((d) => {
                  const isProposal = d.status === "proposed" || d.status === "proposal_returned";
                  const words = courseWords({ sections: d.sections ?? [] } as DraftCourse);
                  const editable = d.status === "draft" || d.status === "changes_requested";
                  const href = editable ? `/studio/courses/${d.id}` : `/studio/courses/${d.id}/status`;
                  const heroUrl = d.hero?.image_url ?? (d.hero?.image ? `https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/${d.hero.image}.jpg` : null);
                  const poster = SUBJECT_ART[(d.subject as Subject) ?? "histoire"] ?? SUBJECT_ART.histoire;
                  if (isProposal) {
                    return (
                      <Link key={d.id} href={href} className="group flex flex-col gap-3 rounded-card border border-line bg-white p-5 transition hover:-translate-y-0.5 hover:border-line-2 hover:shadow-[0_14px_34px_rgba(22,38,61,.08)]">
                        <div className="flex items-center justify-between gap-3">
                          <StatusPill status={d.status} />
                          <span className="text-[12px] text-ink-3">{d.proposed_at ? `Sent ${shortDate(d.proposed_at)}` : ""}</span>
                        </div>
                        <strong className="line-clamp-2 text-[18px] font-extrabold leading-[1.25] tracking-[-0.3px] text-ink">{d.title || c.untitled}</strong>
                        <p className="line-clamp-3 text-[14px] leading-[1.5] text-ink-2">{d.pitch}</p>
                        {d.status === "proposal_returned" && d.proposal_note && <p className="line-clamp-3 rounded-xl bg-red-bg/60 px-3 py-2 text-[13px] text-red">{d.proposal_note}</p>}
                        <span className="mt-auto pt-1 text-[13px] font-bold text-blue">{c.seeProposal} →</span>
                      </Link>
                    );
                  }
                  return (
                    <Link key={d.id} href={href} className="group flex flex-col overflow-hidden rounded-card border border-line bg-white transition hover:-translate-y-0.5 hover:border-line-2 hover:shadow-[0_14px_34px_rgba(22,38,61,.08)]">
                      <div className="relative aspect-[16/9] w-full overflow-hidden bg-tint">
                        {heroUrl ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={heroUrl} alt="" className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-[1.03]" />
                        ) : (
                          <Image src={poster} alt="" width={640} height={360} className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-[1.03]" />
                        )}
                        <span className="absolute left-3 top-3">
                          <StatusPill status={d.status} />
                        </span>
                      </div>
                      <div className="flex flex-1 flex-col gap-2.5 p-5">
                        <span className="text-[12px] font-bold uppercase tracking-[1px] text-blue">
                          {d.subject ? (SUBJECT_LABEL[d.subject as Subject] ?? d.subject) : "Course"} · {d.origin_lang.toUpperCase()}
                        </span>
                        <strong className="line-clamp-2 text-[18px] font-extrabold leading-[1.25] tracking-[-0.3px] text-ink">{d.title || c.untitled}</strong>
                        <span className="text-[13px] text-ink-3">
                          {c.sections(d.sections?.length ?? 0)} · {c.words(words)} · {c.updated(shortDate(d.updated_at))}
                        </span>
                        {d.status === "changes_requested" && d.review_comment && <p className="line-clamp-3 rounded-xl bg-red-bg/60 px-3 py-2 text-[13px] text-red">{d.review_comment}</p>}
                        {d.validated_at && <span className="text-[12px] font-bold text-green">Validated {shortDate(d.validated_at)} · $15 in your pot</span>}
                        <span className="mt-auto pt-1 text-[13px] font-bold text-blue">{editable ? c.openEditor : c.track} →</span>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </section>
          );
        })}
      </main>
    </>
  );
}
