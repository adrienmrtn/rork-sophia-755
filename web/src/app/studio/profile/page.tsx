import Link from "next/link";
import { redirect } from "next/navigation";
import { StudioHeader } from "@/components/studio/StudioChrome";
import { PhotoUpload } from "@/components/studio/PhotoUpload";
import { Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { displayName, getStudioSession } from "@/lib/studio/account";
import { saveProfile } from "@/app/studio/actions";

export const dynamic = "force-dynamic";

const input = "h-12 rounded-xl border border-line bg-white px-3.5 text-[15px] text-ink outline-none focus:border-blue";
const textarea = "rounded-xl border border-line bg-white px-3.5 py-3 text-[15px] leading-[1.5] text-ink outline-none focus:border-blue";
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
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div className="flex flex-col gap-1.5">
            <h1 className="text-[32px] font-extrabold tracking-[-0.8px] text-ink">{s.profile.title}</h1>
            <p className="text-[16px] text-ink-3">{s.profile.lead}</p>
          </div>
          {account.slug && (
            <Link href={`/authors/${account.slug}`} className="text-[14px] font-bold text-blue">
              sophia-culture.com/authors/{account.slug} →
            </Link>
          )}
        </div>
        {saved && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">{s.profile.saved}</p>}
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        <Card className="flex max-w-[820px] flex-col gap-6 p-8">
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
                {account.institution ? `${account.institution} · ` : ""}
                {account.country ?? ""} ·{" "}
                <Link href="/studio/onboarding/credentials" className="font-bold text-blue">
                  Edit credentials
                </Link>
              </span>
              <button type="submit" className="inline-flex h-11 items-center rounded-btn bg-navy px-[18px] text-[15px] font-bold text-white hover:bg-ink">
                {s.profile.save}
              </button>
            </div>
          </form>
        </Card>
      </main>
    </>
  );
}
