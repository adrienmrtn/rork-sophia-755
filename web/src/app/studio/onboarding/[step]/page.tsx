import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { CheckIcon, Eyebrow, Initials, container } from "@/components/ui";
import { PhotoUpload } from "@/components/studio/PhotoUpload";
import { createClient } from "@/lib/supabase/server";
import { renderMarkdown } from "@/lib/markdown";
import { s } from "@/lib/copy/studio-en";
import { LANGS } from "@/lib/catalog/types";
import { displayName, getStudioSession, slugFromName, type OnboardingStep } from "@/lib/studio/account";
import { finishGuide, saveCredentials, saveIdentity, saveProfile, signAgreement, signOut } from "@/app/studio/actions";

const STEPS: Exclude<OnboardingStep, "done">[] = ["identity", "credentials", "profile", "agreement", "guide"];
const LANG_NAMES: Record<string, string> = { fr: "French", en: "English", es: "Spanish", de: "German", pt: "Portuguese (Brazil)", "pt-PT": "Portuguese (Portugal)", it: "Italian", tr: "Turkish", pl: "Polish", ro: "Romanian", nl: "Dutch", el: "Greek", sv: "Swedish", hu: "Hungarian", bg: "Bulgarian", cs: "Czech", da: "Danish", nb: "Norwegian", ru: "Russian", hr: "Croatian", sl: "Slovene", sk: "Slovak", sr: "Serbian", ar: "Arabic", he: "Hebrew", fi: "Finnish", et: "Estonian", lt: "Lithuanian", lv: "Latvian", ja: "Japanese" };
const COUNTRIES: [string, string][] = [["FR", "France"], ["BE", "Belgium"], ["CH", "Switzerland"], ["CA", "Canada"], ["US", "United States"], ["GB", "United Kingdom"], ["DE", "Germany"], ["ES", "Spain"], ["IT", "Italy"], ["PT", "Portugal"], ["NL", "Netherlands"], ["PL", "Poland"], ["RS", "Serbia"], ["KR", "South Korea"], ["SK", "Slovakia"], ["TR", "Turkey"], ["JP", "Japan"], ["IN", "India"], ["BR", "Brazil"], ["MX", "Mexico"], ["AU", "Australia"], ["OTHER", "Other"]];

const input = "h-12 rounded-xl border border-line bg-white px-3.5 text-[15px] text-ink outline-none focus:border-blue";
const label = "flex flex-col gap-1.5 text-[13px] font-bold text-ink-2";
const help = "text-[12px] font-medium text-muted";

export default async function OnboardingPage({ params, searchParams }: PageProps<"/studio/onboarding/[step]">) {
  const { step } = await params;
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  if (!STEPS.includes(step as Exclude<OnboardingStep, "done">)) notFound();
  const current = step as Exclude<OnboardingStep, "done">;
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio");
  const { account, agreementSigned, user } = session;
  // On ne saute pas d'étape : la première non faite est la plus loin où l'on peut aller.
  const reached = account ? (account.onboarding_step === "done" ? STEPS.length : STEPS.indexOf(account.onboarding_step as Exclude<OnboardingStep, "done">)) : 0;
  const index = STEPS.indexOf(current);
  if (index > reached) redirect(`/studio/onboarding/${STEPS[Math.max(0, reached)] ?? "identity"}`);
  if (current !== "identity" && !account) redirect("/studio/onboarding/identity");

  const o = s.onboarding;
  const name = displayName(account, user);
  const supabase = await createClient();

  type Doc = { version: number; title: string; body_md: string };
  let doc: Doc | null = null;
  if (current === "agreement" || current === "guide") {
    const slug = current === "agreement" ? "creator-agreement" : "writing-guide";
    const { data } = await supabase.from("studio_documents").select("version,title,body_md").eq("slug", slug).eq("lang", "en").order("version", { ascending: false }).limit(1).maybeSingle();
    doc = (data as Doc | null) ?? null;
  }
  let signedAt: string | null = null;
  if (current === "agreement" && agreementSigned) {
    const { data } = await supabase.from("creator_agreements").select("signed_at").eq("user_id", user.id).order("signed_at", { ascending: false }).limit(1).maybeSingle();
    signedAt = (data?.signed_at as string | undefined) ?? null;
  }
  let photoUrl: string | null = null;
  if (account?.photo_path) {
    const { data } = await supabase.storage.from("studio-photos").createSignedUrl(account.photo_path, 3600);
    photoUrl = data?.signedUrl ?? null;
  }

  return (
    <>
      <header className="border-b border-line bg-white">
        <div className={`${container} flex flex-wrap items-center justify-between gap-x-6 gap-y-3 py-3.5`}>
          <div className="flex items-center gap-2.5">
            <Link href="/" className="text-[26px] font-extrabold tracking-[-0.6px] text-navy">
              Sophia
            </Link>
            <span className="rounded-full bg-tint px-2.5 py-1 text-[12px] font-bold text-navy">{s.nav.badge}</span>
          </div>
          <form action={signOut} className="text-[14px] font-semibold text-ink-3">
            {user.email} ·{" "}
            <button type="submit" className="font-bold text-blue">
              {s.nav.signOut}
            </button>
          </form>
        </div>
      </header>

      <main className={`${container} flex flex-1 flex-wrap items-start gap-x-12 gap-y-8 pt-10 pb-20`}>
        {/* Étapes */}
        <nav aria-label={o.title} className="flex min-w-0 flex-[0_1_300px] flex-col gap-1 rounded-card border border-line bg-white p-5">
          <span className="px-2 pb-2.5 text-[13px] font-bold uppercase tracking-[1px] text-muted">{o.title}</span>
          {STEPS.map((st, i) => {
            const done = i < reached || (st === "agreement" && agreementSigned) || (account?.onboarding_step === "done");
            const isCurrent = st === current;
            const [title, sub] = o.steps[st];
            const reachable = i <= reached;
            const inner = (
              <>
                <span className={`inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[13px] font-extrabold ${done ? "bg-green-bg text-green" : isCurrent ? "bg-navy text-white" : "border border-line-2 text-ink-3"}`}>{done ? <CheckIcon className="h-3.5 w-3.5" /> : i + 1}</span>
                <span className="flex flex-col">
                  <strong className={`text-[14px] ${isCurrent ? "font-extrabold text-navy" : done ? "font-bold text-ink" : "font-bold text-ink-3"}`}>{title}</strong>
                  <span className="text-[12px] text-ink-3">{sub}</span>
                </span>
              </>
            );
            return reachable ? (
              <Link key={st} href={`/studio/onboarding/${st}`} aria-current={isCurrent ? "step" : undefined} className={`flex items-center gap-3 rounded-xl px-2 py-2.5 ${isCurrent ? "bg-tint" : "hover:bg-paper"}`}>
                {inner}
              </Link>
            ) : (
              <span key={st} className="flex items-center gap-3 rounded-xl px-2 py-2.5 opacity-80">
                {inner}
              </span>
            );
          })}
          <div className="m-2 mt-3 rounded-[14px] border border-cream-2 bg-cream p-3.5 text-[13px] leading-[1.5] text-ink-2">{o.note}</div>
        </nav>

        {/* Contenu de l'étape */}
        <section className="flex min-w-0 max-w-[760px] flex-[1_1_560px] flex-col gap-6">
          <div className="flex flex-col gap-2">
            <Eyebrow>{o.stepOf(index + 1)}</Eyebrow>
            {error && (
              <p role="alert" className="rounded-xl bg-red-bg px-3.5 py-2.5 text-[13px] font-semibold text-red">
                {error === "name" ? "First and last name are required." : error === "lang" ? "Choose the language you write in." : error === "incomplete" ? "Type your full name and tick the box to sign." : error}
              </p>
            )}
          </div>

          {current === "identity" && (
            <form action={saveIdentity} className="flex flex-col gap-5 rounded-card border border-line bg-white p-7">
              <div className="flex flex-col gap-2">
                <h1 className="text-[32px] font-extrabold leading-[1.1] tracking-[-0.8px]">{o.identity.title}</h1>
                <p className="text-[15px] leading-[1.55] text-ink-3">{o.identity.lead}</p>
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <label className={label}>
                  {o.identity.first}
                  <input name="first_name" required maxLength={80} defaultValue={account?.first_name ?? ""} className={input} />
                </label>
                <label className={label}>
                  {o.identity.last}
                  <input name="last_name" required maxLength={80} defaultValue={account?.last_name ?? ""} className={input} />
                </label>
              </div>
              <label className={label}>
                {o.identity.display}
                <input name="display_name" maxLength={120} defaultValue={account?.display_name ?? ""} placeholder={name} className={input} />
                <span className={help}>{o.identity.displayHelp(account?.slug ?? slugFromName(account?.first_name ?? "", account?.last_name ?? ""))}</span>
              </label>
              <label className={label}>
                {o.identity.lang}
                <select name="writing_lang" defaultValue={account?.writing_lang ?? "en"} className={input}>
                  {LANGS.map((l) => (
                    <option key={l} value={l}>
                      {LANG_NAMES[l] ?? l}
                    </option>
                  ))}
                </select>
                <span className={help}>{o.identity.langHelp}</span>
              </label>
              <div className="flex justify-end pt-1">
                <button type="submit" className="h-12 rounded-btn bg-navy px-[22px] text-[15px] font-extrabold text-white hover:bg-ink">
                  {o.continue}
                </button>
              </div>
            </form>
          )}

          {current === "credentials" && account && (
            <form action={saveCredentials} className="flex flex-col gap-5 rounded-card border border-line bg-white p-7">
              <div className="flex flex-col gap-2">
                <h1 className="text-[32px] font-extrabold leading-[1.1] tracking-[-0.8px]">{o.credentials.title}</h1>
                <p className="text-[15px] leading-[1.55] text-ink-3">{o.credentials.lead}</p>
              </div>
              <label className={label}>
                {o.credentials.titleField}
                <input name="title" maxLength={160} defaultValue={account.title ?? ""} placeholder={o.credentials.titlePlaceholder} className={input} />
              </label>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <label className={label}>
                  {o.credentials.institution}
                  <input name="institution" maxLength={160} defaultValue={account.institution ?? ""} className={input} />
                </label>
                <label className={label}>
                  {o.credentials.country}
                  <select name="country" defaultValue={account.country ?? "FR"} className={input}>
                    {COUNTRIES.map(([code, nm]) => (
                      <option key={code} value={code === "OTHER" ? "" : code}>
                        {nm}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              <fieldset className="flex flex-col gap-3 border-0 p-0">
                <legend className="pb-1.5 text-[13px] font-bold text-ink-2">{o.credentials.links}</legend>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <label className={label}>
                    <span className="text-[12px] text-ink-3">{o.credentials.website}</span>
                    <input name="website" type="url" placeholder="https://" defaultValue={account.links?.website ?? ""} className={input} />
                  </label>
                  <label className={label}>
                    <span className="text-[12px] text-ink-3">{o.credentials.scholar}</span>
                    <input name="scholar" type="url" placeholder="https://" defaultValue={account.links?.scholar ?? ""} className={input} />
                  </label>
                </div>
              </fieldset>
              <div className="flex items-center justify-between pt-1">
                <Link href="/studio/onboarding/identity" className="text-[15px] font-bold text-ink-3">
                  {o.back}
                </Link>
                <button type="submit" className="h-12 rounded-btn bg-navy px-[22px] text-[15px] font-extrabold text-white hover:bg-ink">
                  {o.continue}
                </button>
              </div>
            </form>
          )}

          {current === "profile" && account && (
            <form action={saveProfile} className="flex flex-col gap-5 rounded-card border border-line bg-white p-7">
              <input type="hidden" name="from" value="onboarding" />
              <div className="flex flex-col gap-2">
                <h1 className="text-[32px] font-extrabold leading-[1.1] tracking-[-0.8px]">{o.profile.title}</h1>
                <p className="text-[15px] leading-[1.55] text-ink-3">{o.profile.lead}</p>
              </div>
              <PhotoUpload userId={user.id} name={name} currentUrl={photoUrl} />
              <label className={label}>
                {o.identity.display}
                <input name="display_name" maxLength={120} defaultValue={account.display_name ?? name} className={input} />
              </label>
              <label className={label}>
                {o.credentials.titleField}
                <input name="title" maxLength={160} defaultValue={account.title ?? ""} className={input} />
              </label>
              <label className={label}>
                {o.profile.bio}
                <textarea name="bio" rows={3} maxLength={300} defaultValue={account.bio ?? ""} className="rounded-xl border border-line px-3.5 py-3 text-[15px] leading-[1.5] text-ink outline-none focus:border-blue" />
                <span className={help}>{o.profile.bioHelp}</span>
              </label>
              <label className={label}>
                {o.profile.longBio}
                <textarea name="long_bio" rows={5} maxLength={1200} defaultValue={account.long_bio ?? ""} className="rounded-xl border border-line px-3.5 py-3 text-[15px] leading-[1.5] text-ink outline-none focus:border-blue" />
                <span className={help}>{o.profile.longBioHelp}</span>
              </label>
              <div className="flex flex-col gap-2.5 rounded-2xl border border-line bg-paper p-4">
                <span className="text-[12px] font-bold uppercase tracking-[1px] text-muted">{o.profile.preview}</span>
                <div className="flex items-center gap-3">
                  <Initials name={name} size={44} />
                  <span className="flex flex-col gap-0.5">
                    <strong className="text-[15px] font-bold">
                      {o.profile.by} {account.display_name ?? name}
                    </strong>
                    <span className="text-[13px] text-ink-3">{account.title ?? o.credentials.titlePlaceholder}</span>
                  </span>
                </div>
              </div>
              <div className="flex items-center justify-between pt-1">
                <Link href="/studio/onboarding/credentials" className="text-[15px] font-bold text-ink-3">
                  {o.back}
                </Link>
                <button type="submit" className="h-12 rounded-btn bg-navy px-[22px] text-[15px] font-extrabold text-white hover:bg-ink">
                  {o.continue}
                </button>
              </div>
            </form>
          )}

          {current === "agreement" && (
            <div className="flex flex-col gap-5">
              <div className="flex flex-col gap-2">
                <h1 className="text-[32px] font-extrabold leading-[1.1] tracking-[-0.8px]">{o.agreement.title}</h1>
                <p className="text-[15px] leading-[1.55] text-ink-3">{o.agreement.lead}</p>
              </div>
              <article className="max-h-[520px] overflow-y-auto rounded-card border border-line bg-white p-7 text-[15px] leading-[1.6] text-ink-2">
                {doc ? (
                  <>
                    <p className="text-[12px] font-bold uppercase tracking-[1px] text-muted">{o.agreement.version(doc.version)}</p>
                    {renderMarkdown(doc.body_md)}
                  </>
                ) : (
                  <p>The agreement is not published yet.</p>
                )}
              </article>
              {agreementSigned ? (
                <div className="flex flex-col gap-3 rounded-card border border-green-bg bg-green-bg/50 p-6">
                  <strong className="text-[16px] font-extrabold text-green">{o.agreement.signed(signedAt ? new Date(signedAt).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" }) : "")}</strong>
                  <Link href="/studio/onboarding/guide" className="inline-flex h-12 w-fit items-center rounded-btn bg-navy px-[22px] text-[15px] font-extrabold text-white">
                    {o.continue}
                  </Link>
                </div>
              ) : (
                <form action={signAgreement} className="flex flex-col gap-4 rounded-card border border-line bg-white p-7">
                  <label className={label}>
                    {o.agreement.nameLabel}
                    <input name="signed_name" required minLength={3} maxLength={160} defaultValue={name} className={input} />
                  </label>
                  <label className="flex items-start gap-3 text-[14px] font-semibold text-ink-2">
                    <input type="checkbox" name="accept" required className="mt-1 h-4 w-4" />
                    {o.agreement.check}
                  </label>
                  <p className={help}>{o.agreement.draftNote}</p>
                  <div className="flex items-center justify-between pt-1">
                    <Link href="/studio/onboarding/profile" className="text-[15px] font-bold text-ink-3">
                      {o.back}
                    </Link>
                    <button type="submit" disabled={!doc} className="h-12 rounded-btn bg-navy px-[22px] text-[15px] font-extrabold text-white hover:bg-ink disabled:opacity-50">
                      {o.agreement.sign}
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}

          {current === "guide" && (
            <div className="flex flex-col gap-5">
              <div className="flex flex-col gap-2">
                <h1 className="text-[32px] font-extrabold leading-[1.1] tracking-[-0.8px]">{o.guide.title}</h1>
                <p className="text-[15px] leading-[1.55] text-ink-3">{o.guide.lead}</p>
              </div>
              <article className="rounded-card border border-line bg-white p-7 text-[15px] leading-[1.6] text-ink-2">{doc ? renderMarkdown(doc.body_md) : <p>The guide is not published yet.</p>}</article>
              <form action={finishGuide} className="flex items-center justify-between rounded-card border border-line bg-white p-6">
                <label className="flex items-center gap-3 text-[14px] font-semibold text-ink-2">
                  <input type="checkbox" required className="h-4 w-4" /> {o.guide.check}
                </label>
                <button type="submit" className="h-12 rounded-btn bg-navy px-[22px] text-[15px] font-extrabold text-white hover:bg-ink">
                  {o.guide.finish}
                </button>
              </form>
            </div>
          )}
        </section>
      </main>
    </>
  );
}
