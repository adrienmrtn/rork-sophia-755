import Link from "next/link";
import { redirect } from "next/navigation";
import { ArtPanel } from "@/components/studio/Art";
import { PageTitle, StudioHeader } from "@/components/studio/StudioChrome";
import { PhotoUpload } from "@/components/studio/PhotoUpload";
import { Card, Initials, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { displayName, getStudioSession } from "@/lib/studio/account";
import { saveProfile } from "@/app/studio/actions";

export const dynamic = "force-dynamic";

const input = "h-12 w-full rounded-xl border border-line bg-white px-3.5 text-[15px] text-ink outline-none transition focus:border-blue focus:ring-4 focus:ring-blue/10";
const textarea = "w-full rounded-xl border border-line bg-white px-3.5 py-3 text-[15px] leading-[1.5] text-ink outline-none transition focus:border-blue focus:ring-4 focus:ring-blue/10";
const label = "flex flex-col gap-1.5 text-[13px] font-bold text-ink-2";
const help = "text-[12px] font-medium text-muted";

export default async function ProfilePage({ searchParams }: PageProps<"/studio/profile">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/profile");
  const { account, supabase, user } = session;
  if (!account) redirect("/studio/onboarding/identity");
  const sp = await searchParams;
  const saved = sp.saved === "1";
  const error = typeof sp.error === "string" ? sp.error : null;
  const o = s.onboarding.profile;
  const name = displayName(account, user);
  let photoUrl: string | null = null;
  if (account.photo_path) {
    const { data } = await supabase.storage.from("studio-photos").createSignedUrl(account.photo_path, 3600);
    photoUrl = data?.signedUrl ?? null;
  }
  return (
    <>
      <StudioHeader session={session} active="profile" />
      <main className={`${container} flex flex-1 flex-col gap-7 pt-7 pb-20`}>
        <PageTitle title={s.profile.title} lead={s.profile.lead}>
          {account.slug && (
            <Link href={`/authors/${account.slug}`} className="inline-flex h-11 items-center rounded-full border border-line bg-white px-5 text-[14px] font-bold text-navy transition-colors hover:bg-paper">
              See my public page →
            </Link>
          )}
        </PageTitle>
        {saved && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">{s.profile.saved}</p>}
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
          <Card className="flex flex-col gap-6 p-7">
            <PhotoUpload userId={user.id} name={name} currentUrl={photoUrl} />
            <form action={saveProfile} className="flex flex-col gap-5">
              <label className={label}>
                {s.onboarding.identity.display}
                <input name="display_name" defaultValue={account.display_name ?? ""} maxLength={120} className={input} />
              </label>
              <label className={label}>
                {s.onboarding.credentials.titleField}
                <input name="title" defaultValue={account.title ?? ""} maxLength={160} placeholder={s.onboarding.credentials.titlePlaceholder} className={input} />
              </label>
              <label className={label}>
                {o.bio}
                <textarea name="bio" defaultValue={account.bio ?? ""} maxLength={300} rows={3} className={textarea} />
                <span className={help}>{o.bioHelp}</span>
              </label>
              <label className={label}>
                {o.longBio}
                <textarea name="long_bio" defaultValue={account.long_bio ?? ""} maxLength={1200} rows={7} className={textarea} />
                <span className={help}>{o.longBioHelp}</span>
              </label>
              <div className="flex flex-wrap items-center justify-between gap-3 border-t border-line pt-5">
                <span className="text-[13px] text-ink-3">
                  {[account.institution, account.country].filter(Boolean).join(" · ")}
                  {account.institution || account.country ? " · " : ""}
                  <Link href="/studio/onboarding/credentials" className="font-bold text-blue">
                    Edit credentials
                  </Link>
                </span>
                <button type="submit" className="inline-flex h-11 items-center rounded-full bg-navy px-5 text-[15px] font-bold text-white transition-colors hover:bg-ink">
                  {s.profile.save}
                </button>
              </div>
            </form>
          </Card>
          <div className="flex flex-col gap-5">
            <Card className="flex flex-col gap-3 p-5">
              <span className="text-[12px] font-bold uppercase tracking-[1px] text-muted">{o.preview}</span>
              <div className="flex items-center gap-3">
                {photoUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={photoUrl} alt="" className="h-12 w-12 rounded-full object-cover" />
                ) : (
                  <Initials name={name} size={48} />
                )}
                <span className="flex min-w-0 flex-col">
                  <strong className="truncate text-[15px] font-bold">
                    {o.by} {account.display_name ?? name}
                  </strong>
                  <span className="line-clamp-2 text-[13px] text-ink-3">{account.title ?? s.onboarding.credentials.titlePlaceholder}</span>
                </span>
              </div>
              {account.bio && <p className="text-[13px] leading-[1.5] text-ink-2">{account.bio}</p>}
            </Card>
            <ArtPanel name="studio_photo" title="What readers see" size={240}>
              Your photo, name and title sit under every course, in 30 languages. Changes reach the app within a day.
            </ArtPanel>
          </div>
        </div>
      </main>
    </>
  );
}
