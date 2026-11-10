import Image from "next/image";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { CoursePicker } from "@/components/admin/CoursePicker";
import { EventCardPreview } from "@/components/admin/EventCardPreview";
import { Card, CheckIcon, Pill, buttonClass, container } from "@/components/ui";
import { catalog } from "@/lib/catalog/source";
import { LANG_NAMES } from "@/lib/catalog/lang-names";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { getStudioSession } from "@/lib/studio/account";
import { CAMPAIGN_KINDS, CAMPAIGN_SYMBOLS, EDITED_LANGS, TEXT_FIELDS, TEXT_LABELS, TEXT_LIMITS, UPCOMING_ROWS, campaignFromRow, emptyCampaign, languagesFilled, languagesMissing, localized, publishProblems, statusTone, type Campaign } from "@/lib/studio/campaigns";
import { shortDateTime } from "@/lib/studio/data";
import { coversConfigured } from "@/lib/studio/covers";
import { translationConfigured } from "@/lib/studio/translate";
import { chooseEventBadge, chooseEventImage, deleteCampaign, generateEventBadge, saveCampaign, setCampaignStatus, translateCampaignAction } from "../actions";

export const dynamic = "force-dynamic";
export const maxDuration = 120;

const input = "h-11 w-full rounded-xl border border-line bg-white px-3.5 text-[15px] text-ink outline-none transition focus:border-blue focus:ring-4 focus:ring-blue/10";
const textarea = "w-full rounded-xl border border-line bg-white px-3.5 py-3 text-[15px] leading-[1.5] text-ink outline-none transition focus:border-blue focus:ring-4 focus:ring-blue/10";
const label = "flex flex-col gap-1.5 text-[13px] font-bold text-ink-2";
const select = `${input} appearance-none`;

const DONE: Record<string, string> = { badge: "Badges generated. Pick the one you want; the first is used until you choose.", image: "Images generated. Pick the one you prefer below; generate again if neither fits.", saved: "Event saved.", published: "Event published. The apps pick it up at their next catalogue refresh (within the hour).", "kept-draft": "Saved as a draft.", "translated-none": "Every language already has its texts.", unpublished: "Event back to draft: hidden from the apps at their next catalogue refresh.", archived: "Event archived: withdrawn from the apps, kept here.", restored: "Event back as a draft. Publish it when ready." };

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
  const covers = campaign.course_ids.map((id) => courses.find((c) => c.id === id)).filter((c) => c !== undefined).slice(0, 3).map((c) => ({ id: c.id, title: c.title, coverUrl: c.coverUrl }));
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
          <Card className="flex flex-col gap-5 p-6">
            <ol className="flex flex-wrap gap-x-6 gap-y-2 text-[13px] font-semibold text-ink-3">
              {[
                ["1", "Write the texts in English", true],
                ["2", "Save", true],
                ["3", `Translate (${filled.length}/30 languages)`, missing.length === 0],
                ["4", "Publish", campaign.status === "published"],
              ].map(([n, label, done]) => (
                <li key={String(n)} className="flex items-center gap-2">
                  <span className={`inline-flex h-6 w-6 items-center justify-center rounded-full text-[12px] font-extrabold ${done ? "bg-green-bg text-green" : "bg-tint text-navy"}`}>{done ? "✓" : String(n)}</span>
                  <span className={done ? "text-green" : ""}>{String(label)}</span>
                </li>
              ))}
            </ol>
            <div className="flex flex-wrap items-start gap-x-10 gap-y-4">
              <div className="flex min-w-[280px] flex-1 flex-col gap-3">
                <strong className="text-[15px] font-extrabold text-ink">
                  {campaign.status === "published" ? "Live in the apps" : campaign.status === "archived" ? "Archived" : problems.length === 0 ? "Ready to publish" : `${problems.length} thing${problems.length > 1 ? "s" : ""} before publishing`}
                </strong>
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
                <form action={setCampaignStatus} className="flex flex-wrap items-center gap-3">
                  <input type="hidden" name="slug" value={campaign.slug} />
                  {campaign.status === "published" ? (
                    <>
                      <button type="submit" name="status" value="draft" className={buttonClass("secondary", "h-11 px-5")}>
                        Unpublish (back to draft)
                      </button>
                      <span className="text-[12px] text-muted">Readers lose it at their next catalogue refresh, within the hour.</span>
                    </>
                  ) : (
                    <>
                      <button type="submit" name="status" value="published" disabled={problems.length > 0} className={buttonClass("primary", "h-11 px-5 disabled:opacity-50")}>
                        Publish now
                      </button>
                      <span className="text-[12px] text-muted">{problems.length > 0 ? "Fix the list above, save, then publish." : missing.length > 0 ? `Goes live as it is: readers in the ${missing.length} untranslated languages see the English texts. Translate first if you prefer.` : "Live in the apps within the hour, in the 30 languages."}</span>
                    </>
                  )}
                </form>
              </div>
              <div className="flex min-w-[280px] flex-1 flex-col gap-2">
                <strong className="text-[15px] font-extrabold text-ink">Languages · {filled.length}/30</strong>
                <p className="text-[13px] leading-[1.5] text-ink-3">
                  You write in English only. The other 29 languages come from the button below, in one go, from the saved English texts. Until then, readers in those languages see the English texts.
                  {missing.length > 0 && filled.length > 0 ? ` Missing: ${missing.map((l) => LANG_NAMES[l] ?? l).join(", ")}.` : missing.length === 0 ? " Every language is filled." : ""}
                </p>
                <form action={translateCampaignAction} className="flex flex-wrap items-center gap-3 pt-1">
                  <input type="hidden" name="slug" value={campaign.slug} />
                  <button type="submit" disabled={missing.length === 0 || !translationConfigured()} className={buttonClass("secondary", "h-10 px-4 disabled:opacity-50")}>
                    Translate into the {missing.length} missing language{missing.length === 1 ? "" : "s"}
                  </button>
                  <span className="text-[12px] text-muted">{translationConfigured() ? "About a minute. Never overwrites a filled language; re-save the English texts first if you changed them." : "Not configured on the server (FAL_KEY)."}</span>
                </form>
              </div>
            </div>
          </Card>
        )}

        {!isNew && (
          <Card className="flex flex-wrap items-start gap-8 p-6">
            <div className="flex flex-col gap-3">
              <strong className="text-[15px] font-extrabold text-ink">Feed card preview</strong>
              <EventCardPreview campaign={campaign} covers={covers} />
            </div>
            <div className="flex min-w-[260px] flex-1 flex-col gap-3 text-[13px] leading-[1.5] text-ink-3">
              <p>What readers see in “For you”, in English, with the saved texts and image. In the apps the symbol is an icon, the challenge bar belongs to each reader, and the common goal counts every reader.</p>
              <p className="text-[12px] text-muted">Upload an image or generate two with AI from the <strong>Image</strong> card below; the generated candidates appear here, pick one.</p>
              {campaign.image_candidates.length > 0 && (
                <div className="flex flex-col gap-2 pt-2">
                  <strong className="text-[13px] font-extrabold text-ink">Generated images</strong>
                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    {campaign.image_candidates.map((c) => {
                      const current = c.url === campaign.image_url;
                      return (
                        <form key={c.url} action={chooseEventImage} className={`flex flex-col gap-2 rounded-xl border p-2 ${current ? "border-navy" : "border-line"}`}>
                          <input type="hidden" name="slug" value={campaign.slug} />
                          <input type="hidden" name="url" value={c.url} />
                          <Image src={c.url} alt="" width={640} height={360} unoptimized className="aspect-video w-full rounded-lg object-cover" />
                          <div className="flex items-center justify-between gap-2">
                            <span className="text-[12px] font-semibold text-ink-2">{c.style === "poster" ? "Website poster style" : "Course cover style"}</span>
                            {current ? <Pill tone="green">In use</Pill> : <button type="submit" className={buttonClass("secondary", "h-8 px-3 text-[13px]")}>Use this image</button>}
                          </div>
                        </form>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          </Card>
        )}

        {!isNew && (
          <Card className="flex flex-wrap items-start gap-8 p-6">
            <div className="flex min-w-[240px] max-w-[320px] flex-col gap-3">
              <strong className="text-[15px] font-extrabold text-ink">Badge</strong>
              <p className="text-[13px] leading-[1.5] text-ink-3">
                Readers who finish the challenge earn this badge and can show it on their profile. The button draws three paper-cut emblems from the English title, tagline and badge name; pick one. Without an image, the apps show the event symbol.
              </p>
              <form action={generateEventBadge} className="flex flex-col gap-2">
                <input type="hidden" name="slug" value={campaign.slug} />
                <button type="submit" disabled={!coversConfigured() || !titleEn} className={buttonClass("secondary", "h-10 w-fit px-4 disabled:opacity-50")}>
                  Generate 3 badges with AI
                </button>
                <span className="text-[12px] text-muted">{coversConfigured() ? "About 30 seconds. Earlier candidates are kept (9 at most)." : "Not configured on the server (FAL_KEY)."}</span>
              </form>
            </div>
            <div className="flex min-w-[260px] flex-1 flex-col gap-2">
              {campaign.badge_candidates.length === 0 ? (
                <p className="text-[13px] text-muted">No badge generated yet.</p>
              ) : (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                  {campaign.badge_candidates.map((c) => {
                    const current = c.url === campaign.badge_image_url;
                    return (
                      <form key={c.url} action={chooseEventBadge} className={`flex flex-col items-center gap-2 rounded-xl border p-3 ${current ? "border-navy" : "border-line"}`}>
                        <input type="hidden" name="slug" value={campaign.slug} />
                        <input type="hidden" name="url" value={c.url} />
                        <Image src={c.url} alt="" width={240} height={240} unoptimized className="aspect-square w-full max-w-[140px] rounded-full object-cover" />
                        {current ? <Pill tone="green">In use</Pill> : <button type="submit" className={buttonClass("secondary", "h-8 px-3 text-[13px]")}>Use this badge</button>}
                      </form>
                    );
                  })}
                </div>
              )}
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
              <input type="hidden" name="status" value={campaign.status} />
            </div>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <label className={label}>
                Countries (optional)
                <input name="countries" defaultValue={(campaign.countries ?? []).join(", ")} placeholder="Everywhere" className={input} />
              </label>
              <p className="self-end pb-2 text-[13px] leading-[1.5] text-ink-3 md:col-span-2">
                Where the event is shown, not its language: two-letter country codes separated by commas (FR, BE, CH, CA…), compared with the region of the phone. Empty: shown in every country. The texts are translated into the 30 languages from the card at the top, whatever the countries.
              </p>
            </div>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <label className={label}>
                Common goal: courses read together (optional)
                <input type="number" name="goal_target" defaultValue={campaign.goal_target ?? ""} min={1} max={100000000} placeholder="10000" className={input} />
              </label>
              <p className="self-end pb-2 text-[13px] leading-[1.5] text-ink-3 md:col-span-2">
                Every course of the collection finished by any reader during the event counts. Recounted every hour: {campaign.goal_count.toLocaleString("en-GB")} so far. Shown as a second bar on the card and on the event page.
              </p>
            </div>
          </Card>

          <Card className="flex flex-col gap-4 p-6">
            <div className="flex flex-col gap-1">
              <strong className="text-[15px] font-extrabold text-ink">Image</strong>
              <p className="text-[13px] text-ink-3">Optional. 16:9, JPEG, PNG or WebP, 6 MB max. Shown at the top of the feed card and of the event page; without it the card stays navy with the symbol.</p>
            </div>
            <div className="flex flex-wrap items-start gap-6">
              {campaign.image_url ? (
                <Image src={campaign.image_url} alt="" width={640} height={360} unoptimized className="aspect-video w-full max-w-[360px] rounded-xl object-cover" />
              ) : (
                <div className="flex aspect-video w-full max-w-[360px] items-center justify-center rounded-xl bg-ink px-6 text-center text-[13px] font-semibold text-white/70">No image yet: the card stays navy with the symbol</div>
              )}
              <div className="flex min-w-[260px] flex-1 flex-col gap-3">
                <label className={label}>
                  Upload an image
                  <input type="file" name="image" accept="image/jpeg,image/png,image/webp" className="text-[14px]" />
                </label>
                {campaign.image_url && (
                  <label className="flex items-center gap-2 text-[14px] font-semibold text-ink-2">
                    <input type="checkbox" name="remove_image" className="h-4 w-4 accent-navy" /> Remove the current image
                  </label>
                )}
                <p className="text-[12px] text-muted">Saved with the event.</p>
                <div className="flex items-center gap-3 text-[11px] font-bold uppercase tracking-[1px] text-muted">
                  <span className="h-px flex-1 bg-line" />
                  or
                  <span className="h-px flex-1 bg-line" />
                </div>
                <div className="flex flex-col gap-2">
                  <button type="submit" name="intent" value="generate" disabled={!coversConfigured()} className={buttonClass("secondary", "h-10 w-fit px-4 disabled:opacity-50")}>
                    Generate 2 images with AI
                  </button>
                  <span className="text-[12px] text-muted">
                    {coversConfigured()
                      ? `${isNew ? "Creates the event" : "Saves the event"}, then draws two 16:9 images from the English title and tagline: one in the art direction of course covers, one in the paper-cut style of the website. About 30 seconds. Then pick one in the preview card${isNew ? " of the next page" : " above"}.`
                      : "Not configured on the server (FAL_KEY)."}
                  </span>
                </div>
              </div>
            </div>
          </Card>

          <Card className="flex flex-col gap-5 p-6">
            <div className="flex flex-col gap-1">
              <strong className="text-[15px] font-extrabold text-ink">Texts</strong>
              <p className="text-[13px] text-ink-3">Write in English only. The 29 other languages, French included, come from the Translate button once these texts are final.</p>
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
                  <div key={i} className="grid grid-cols-1 gap-3 rounded-xl border border-line p-3 md:grid-cols-[1fr_220px_170px]">
                    <label className={label}>
                      Title (English)
                      <input name={`upcoming_${i}_title_en`} defaultValue={u?.title.en ?? ""} maxLength={120} className={input} />
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
            <span className="text-[13px] text-muted">{isNew ? "Creates the event as a draft, hidden from readers. Then translate and publish from the top of its page." : "Saves the texts, dates, courses and image; the event keeps its status. Publishing and unpublishing are the buttons at the top of the page."}</span>
          </div>
        </form>

        {!isNew && (
          <div className="flex flex-wrap items-center gap-x-8 gap-y-3 border-t border-line pt-6">
            <form action={setCampaignStatus} className="flex flex-wrap items-center gap-3">
              <input type="hidden" name="slug" value={campaign.slug} />
              <button type="submit" name="status" value={campaign.status === "archived" ? "draft" : "archived"} className="text-[14px] font-bold text-amber">
                {campaign.status === "archived" ? "Put back as a draft" : "Archive this event"}
              </button>
              <span className="text-[13px] text-muted">{campaign.status === "archived" ? "It comes back hidden; publish it again when ready." : "Withdrawn from the apps, kept here with its participants."}</span>
            </form>
            <form action={deleteCampaign} className="flex flex-wrap items-center gap-3">
              <input type="hidden" name="slug" value={campaign.slug} />
              <button type="submit" disabled={campaign.status === "published"} className="text-[14px] font-bold text-red disabled:opacity-40">
                Delete this event
              </button>
              <span className="text-[13px] text-muted">{campaign.status === "published" ? "Unpublish or archive it first: readers may hold its badge." : "Permanent. Prefer archiving to keep the record."}</span>
            </form>
          </div>
        )}
      </main>
    </>
  );
}
