import Image from "next/image";
import Link from "next/link";
import { container } from "@/components/ui";
import type { StudioSession } from "@/lib/studio/account";
import { signOut } from "@/app/studio/actions";

type Active = "overview" | "review" | "creators" | "payouts" | "production" | "events";

/** L'en-tête de l'espace équipe : six pages, un retour au Studio. */
export function AdminHeader({ session, active, queue }: { session: StudioSession; active?: Active; queue?: number }) {
  const link = (key: Active, href: string, label: string, badge?: number) => (
    <Link href={href} className={`inline-flex items-center gap-2 py-2.5 text-[15px] font-semibold text-ink-2 hover:text-navy ${active === key ? "border-b-2 border-navy font-extrabold text-navy" : ""}`}>
      {label}
      {badge ? <span className="inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-coral px-1.5 text-[11px] font-extrabold text-white">{badge}</span> : null}
    </Link>
  );
  return (
    <header className="border-b border-line bg-white">
      <div className={`${container} flex flex-wrap items-center gap-x-7 gap-y-3 py-3.5`}>
        <div className="flex items-center gap-2.5">
          <Link href="/" aria-label="Sophia, home" className="flex items-center">
            <Image src="/brand/sophia-logo.png" alt="Sophia" width={1192} height={334} className="h-[30px] w-auto" />
          </Link>
          <span className="rounded-full bg-ink px-2.5 py-1 text-[12px] font-bold text-white">Team</span>
        </div>
        <nav className="flex flex-1 flex-wrap items-center gap-x-[22px] gap-y-1">
          {link("overview", "/admin", "Overview")}
          {link("review", "/admin/review", "Review queue", queue)}
          {link("creators", "/admin/creators", "Creators")}
          {link("payouts", "/admin/payouts", "Payouts")}
          {link("production", "/admin/production", "Production")}
          {link("events", "/admin/events", "Events")}
        </nav>
        <div className="flex items-center gap-4 text-[14px] font-semibold text-ink-3">
          <span className="hidden truncate text-[13px] text-muted md:inline">{session.user.email}</span>
          <Link href="/studio" className="font-bold text-blue">
            My studio
          </Link>
          <form action={signOut}>
            <button type="submit" className="font-bold text-ink-3 hover:text-red">
              Sign out
            </button>
          </form>
        </div>
      </div>
    </header>
  );
}

export function AdminTitle({ title, lead, children }: { title: string; lead?: string; children?: React.ReactNode }) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-4">
      <div className="flex flex-col gap-1.5">
        <h1 className="text-[30px] font-extrabold tracking-[-0.7px] text-ink">{title}</h1>
        {lead && <p className="text-[15px] text-ink-3">{lead}</p>}
      </div>
      {children}
    </div>
  );
}
