import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { CoursePicker } from "@/components/admin/CoursePicker";
import { Card, CheckIcon, Pill, buttonClass, container } from "@/components/ui";
import { catalog } from "@/lib/catalog/source";
import { LANG_NAMES } from "@/lib/catalog/lang-names";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { getStudioSession } from "@/lib/studio/account";
import { CAMPAIGN_KINDS, CAMPAIGN_STATUSES, CAMPAIGN_SYMBOLS, EDITED_LANGS, TEXT_FIELDS, TEXT_LABELS, TEXT_LIMITS, UPCOMING_ROWS, campaignFromRow, emptyCampaign, languagesFilled, languagesMissing, localized, publishProblems, statusTone, type Campaign } from "@/lib/studio/campaigns";
import { shortDateTime } from "@/lib/studio/data";
import { translationConfigured } from "@/lib/studio/translate";
import { deleteCampaign, saveCampaign, translateCampaignAction } from "../actions";

export const dynamic = "force-dynamic";
export const maxDuration = 60;

const input = "h-11 w-full rounded-xl border border-line bg-white px-3.5 text-[15px] text-ink outline-none transition focus:border-blue focus:ring-4 focus:ring-blue/10";
const textarea = "w-full rounded-xl border border-line bg-white px-3.5 py-3 text-[15px] leading-[1.5] text-ink outline-none transition focus:border-blue focus:ring-4 focus:ring-blue/10";
const label = "flex flex-col gap-1.5 text-[13px] font-bold text-ink-2";
const select = `${input} appearance-none`;

const DONE: Record<string, string> = { saved: "Event saved.", published: "Event published. The apps pick it up at their next catalogue refresh (within the hour).", "kept-draft": "Saved as a draft.", "translated-none": "Every language already has its texts." };

export default async function EventEditorPage({ params, searchParams }: PageProps<"/admin/events/[slug]">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const { slug } = await params;
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const isNew = slug === "new";

  let campaign: Campaign = emptyCampaign();
  if (!isNew) {
    const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
    if (!data) notFound();
    campaign = campaignFromRow(data as Record<string, unknown>);
  }
  const [courses, creators] = await Promise.all([catalog.listCourses("en"), catalog.listCreators("en")]);
  const creatorName = new Map(creators.map((c) => [c.slug, c.name]));
  const pickable = courses.map((c) => ({ id: c.id, title: c.title, subject: SUBJECT_LABEL[c.subject] ?? c.subject, creator: c.creatorSlug ? (creatorName.get(c.creatorSlug) ?? c.creatorSlug) : null }));
  const problems = publishProblems(campaign, { courseIds: new Set(courses.map((c) => c.id)), creatorSlugs: new Set(creators.map((c) => c.slug)) });
  const filled = languagesFilled(campaign);
  const missing = languagesMissing(campaign).filter((l) => !(EDITED_LANGS as readonly string[]).includes(l));
  const doneText = done ? (DONE[done] ?? (done.startsWith("translated-") ? `Translated into ${done.slice("translated-".length)} more language${done.endsWith("-1") ? "" : "s"}. Spot-check a few; French and English are yours to write.` : null)) : null;
  const titleEn = localized(campaign.title, "en");

  return (
    <>
      <AdminHeader session={session} active="events" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-24`}>
        <div className="flex flex-col gap-2">
          <Link href="/admin/events" className="text-[13px] font-bold text-blue">
            ← Events
          </Link>
          <AdminTitle title={isNew ? "New event" : titleEn || campaign.slug} lead={isNew ? "Fill in English at least; translate into the other languages once the texts are final." : `${campaign.slug} · ${campaign.participants.toLocaleString("en-GB")} participants · updated ${shortDateTime(campaign.updated_at)}`}>
            {!isNew && <Pill tone={statusTone(campaign.status)}>{campaign.status}</Pill>}
          </AdminTitle>
        </div>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {doneText && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">{doneText}</p>}

        {!isNew && (
          <Card className="flex flex-wrap items-start gap-x-10 gap-y-4 p-6">
            <div className="flex min-w-[260px] flex-1 flex-col gap-2">
              <strong className="text-[15px] font-extrabold text-ink">{problems.length === 0 ? "Ready to publish" : `${problems.length} thing${problems.length > 1 ? "s" : ""} before publishing`}</strong>
              {problems.length === 0 ? (
                <p className="flex items-center gap-2 text-[14px] text-green">
                  <CheckIcon className="h-4 w-4" /> Texts in English, a collection, a reachable challenge, valid announced courses.
                </p>
              ) : (
                <ul className="flex list-disc flex-col gap-1 pl-5 text-[14px] text-ink-2">
                  {problems.map((p) => (
                    <li key={p}>{p}</li>
                  ))}
                </ul>
              )}
            </div>
            <div className="flex min-w-[260px] flex-1 flex-col gap-2">
              <strong className="text-[15px] font-extrabold text-ink">
                {filled.length}/30 languages
              </strong>
              <p className="text-[13px] leading-[1.5] text-ink-3">
                {filled.length > 0 ? filled.map((l) => LANG_NAMES[l] ?? l).join(", ") : "No complete language yet."}
                {missing.length > 0 && filled.length > 0 ? ` · missing: ${missing.map((l) => LANG_NAMES[l] ?? l).join(", ")}` : ""}
              </p>
              <form action={translateCampaignAction} className="flex flex-wrap items-center gap-3 pt-1">
                <input type="hidden" name="slug" value={campaign.slug} />
                <button type="submit" disabled={missing.length === 0 || !translationConfigured()} className={buttonClass("secondary", "h-10 px-4 disabled:opacity-50")}>
                  Translate into the {missing.length} missing language{missing.length === 1 ? "" : "s"}
                </button>
                <span className="text-[12px] text-muted">{translationConfigured() ? "Uses the saved texts: save first. Never overwrites a filled language." : "Not configured on the server (FAL_KEY)."}</span>
              </form>
            </div>
          </Card>
        )}

        <form action={saveCampaign} className="flex flex-col gap-6">
          {!isNew && <input type="hidden" name="existing_slug" value={campaign.slug} />}

          <Card className="flex flex-col gap-5 p-6">
            <strong className="text-[15px] font-extrabold text-ink">Identity</strong>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <label className={label}>
                Slug (address in the apps)
                <input name="slug" defaultValue={campaign.slug} placeholder="movember-2026" pattern="[a-z0-9]+(-[a-z0-9]+)*" minLength={3} maxLength={60} required readOnly={!isNew} className={`${input} ${isNew ? "" : "bg-paper text-ink-3"}`} />
              </label>
              <label className={label}>
                Kind
                <select name="kind" defaultValue={campaign.kind} className={select}>
                  {CAMPAIGN_KINDS.map((k) => (
                    <option key={k.id} value={k.id}>
                      {k.label}
                    </option>
                  ))}
                </select>
              </label>
              <label className={label}>
                Symbol
                <select name="symbol" defaultValue={campaign.symbol} className={select}>
                  {CAMPAIGN_SYMBOLS.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.label} ({s.id})
                    </option>
                  ))}
                </select>
              </label>
            </div>
            <ul className="grid grid-cols-1 gap-x-6 gap-y-1 text-[12px] text-muted sm:grid-cols-2">
              {CAMPAIGN_KINDS.map((k) => (
                <li key={k.id}>
                  <strong className="text-ink-2">{k.label}</strong>: {k.hint}
                </li>
              ))}
            </ul>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
              <label className={label}>
                First day
                <input type="date" name="starts_at" defaultValue={campaign.starts_at} required className={input} />
              </label>
              <label className={label}>
                Last day
                <input type="date" name="ends_at" defaultValue={campaign.ends_at} required className={input} />
              </label>
              <label className={label}>
                Challenge: courses to finish
                <input type="number" name="challenge_target" defaultValue={campaign.challenge_target} min={1} max={50} required className={input} />
              </label>
              <label className={label}>
                Status
                <select name="status" defaultValue={campaign.status} className={select}>
                  {CAMPAIGN_STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {s === "draft" ? "Draft (hidden from the apps)" : s === "published" ? "Published (live in the apps)" : "Archived (withdrawn, kept)"}
                    </option>
                  ))}
                </select>
              </label>
            </div>
          </Card>

          <Card className="flex flex-col gap-5 p-6">
            <div className="flex flex-col gap-1">
              <strong className="text-[15px] font-extrabold text-ink">Texts</strong>
              <p className="text-[13px] text-ink-3">English is what the apps fall back to; French is read by most readers. The other 28 languages come from the Translate button once these are final.</p>
            </div>
            <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
              {EDITED_LANGS.map((lang) => (
                <div key={lang} className="flex flex-col gap-4">
                  <span className="text-[12px] font-bold uppercase tracking-[1px] text-muted">{LANG_NAMES[lang]}</span>
                  {TEXT_FIELDS.map((field) =>
                    field === "description" ? (
                      <label key={field} className={label}>
                        {TEXT_LABELS[field]} ({TEXT_LIMITS[field]} characters)
                        <textarea name={`${field}_${lang}`} defaultValue={campaign[field][lang] ?? ""} maxLength={TEXT_LIMITS[field]} rows={3} className={textarea} />
                      </label>
                    ) : (
                      <label key={field} className={label}>
                        {TEXT_LABELS[field]} ({TEXT_LIMITS[field]} characters)
                        <input name={`${field}_${lang}`} defaultValue={campaign[field][lang] ?? ""} maxLength={TEXT_LIMITS[field]} className={input} />
                      </label>
                    ),
                  )}
                </div>
              ))}
            </div>
          </Card>

          <Card className="flex flex-col gap-5 p-6">
            <div className="flex flex-col gap-1">
              <strong className="text-[15px] font-extrabold text-ink">Collection</strong>
              <p className="text-[13px] text-ink-3">The courses readers are invited to finish during the event. Only published courses are listed; the challenge target cannot exceed their number.</p>
            </div>
            <CoursePicker courses={pickable} selected={campaign.course_ids} inputClass={input} />
          </Card>

          <Card className="flex flex-col gap-5 p-6">
            <div className="flex flex-col gap-1">
              <strong className="text-[15px] font-extrabold text-ink">Announced courses</strong>
              <p className="text-[13px] text-ink-3">Courses being written for the event, with their release date. Readers can ask to be told when one comes out. Leave a row empty to drop it.</p>
            </div>
            <div className="flex flex-col gap-3">
              {Array.from({ length: UPCOMING_ROWS }, (_, i) => {
                const u = campaign.upcoming[i];
                return (
                  <div key={i} className="grid grid-cols-1 gap-3 rounded-xl border border-line p-3 md:grid-cols-[1fr_1fr_200px_160px]">
                    <label className={label}>
                      Title (English)
                      <input name={`upcoming_${i}_title_en`} defaultValue={u?.title.en ?? ""} maxLength={120} className={input} />
                    </label>
                    <label className={label}>
                      Title (French)
                      <input name={`upcoming_${i}_title_fr`} defaultValue={u?.title.fr ?? ""} maxLength={120} className={input} />
                    </label>
                    <label className={label}>
                      Author
                      <select name={`upcoming_${i}_creator`} defaultValue={u?.creator ?? ""} className={select}>
                        <option value="">Not announced</option>
                        {creators.map((c) => (
                          <option key={c.slug} value={c.slug}>
                            {c.name}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label className={label}>
                      Release date
                      <input type="date" name={`upcoming_${i}_date`} defaultValue={u?.date ?? ""} className={input} />
                    </label>
                  </div>
                );
              })}
            </div>
          </Card>

          <div className="flex flex-wrap items-center gap-3">
            <button type="submit" className={buttonClass("primary", "h-12 px-6 font-extrabold")}>
              {isNew ? "Create the event" : "Save"}
            </button>
            <span className="text-[13px] text-muted">Set the status to Published to make it live; a draft stays invisible to readers.</span>
          </div>
        </form>

        {!isNew && (
          <form action={deleteCampaign} className="flex flex-wrap items-center gap-3 border-t border-line pt-6">
            <input type="hidden" name="slug" value={campaign.slug} />
            <button type="submit" disabled={campaign.status === "published"} className="text-[14px] font-bold text-red disabled:opacity-40">
              Delete this event
            </button>
            <span className="text-[13px] text-muted">{campaign.status === "published" ? "Archive it first: readers may hold its badge." : "Permanent. Prefer Archived to keep the record."}</span>
          </form>
        )}
      </main>
    </>
  );
}
