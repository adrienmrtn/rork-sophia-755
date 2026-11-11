import Image from "next/image";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Eyebrow, buttonClass, container } from "@/components/ui";
import { APP_STORE_URL, PLAY_STORE_URL } from "@/lib/env";

/** `/invite/<handle>` : la page que l'app partage pour le parrainage (« Invite un ami et gagne
 *  3 cours gratuits », docs/parrainage.md). App installée : iOS ouvre le lien dans l'app, qui
 *  retient le code. Sinon, la page donne le code à saisir après l'inscription et mène aux
 *  boutiques. Le code est le @ de celui qui invite ; la page ne lit rien en base. */
export const metadata: Metadata = { title: "You're invited to Sophia", robots: { index: false } };

const HANDLE = /^[a-z][a-z0-9]{2,19}$/;

export default async function InvitePage({ params }: PageProps<"/invite/[handle]">) {
  const { handle: raw } = await params;
  const handle = decodeURIComponent(raw).replace(/^@/, "").toLowerCase();
  if (!HANDLE.test(handle)) notFound();

  return (
    <main className={`${container} flex flex-wrap items-center justify-center gap-x-20 gap-y-10 py-14`}>
      <section className="flex min-w-0 max-w-[520px] flex-[1_1_380px] flex-col gap-5">
        <Eyebrow>Invitation</Eyebrow>
        <h1 className="text-[40px] font-extrabold leading-[1.08] tracking-[-1.2px]">@{handle} invites you to Sophia</h1>
        <p className="text-[17px] leading-[1.55] text-ink-3">
          Short courses written by teachers, one new thing learned every day. Install the app, create your account,
          then enter this code in Profile → Invite a friend.
        </p>
        <div className="flex items-center justify-between gap-4 rounded-card border border-dashed border-line bg-white px-5 py-4">
          <span className="text-[13px] font-bold uppercase tracking-[0.6px] text-ink-3">Invite code</span>
          <span className="text-[24px] font-extrabold tracking-[-0.4px]">@{handle}</span>
        </div>
        <div className="flex flex-wrap gap-3">
          <a href={APP_STORE_URL} className={buttonClass("primary")}>
            Download on the App Store
          </a>
          <a href={PLAY_STORE_URL} className={buttonClass("secondary")}>
            Get it on Google Play
          </a>
        </div>
      </section>
      <Image
        src="/art/poster_inviter.webp"
        alt=""
        width={1200}
        height={900}
        className="aspect-[4/3] w-full max-w-[440px] rounded-card object-cover"
      />
    </main>
  );
}
