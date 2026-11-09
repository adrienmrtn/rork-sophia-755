import Link from "next/link";
import { Initials, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { displayName, type StudioSession } from "@/lib/studio/account";
import { createDraft, signOut } from "@/app/studio/actions";

type Active = "dashboard" | "courses" | "payments" | "profile" | "guide" | "admin";

/** L'en-tête de l'espace auteur, celui de la maquette « Tableau de bord ». */
export function StudioHeader({ session, active }: { session: StudioSession; active?: Active }) {
  const name = displayName(session.account, session.user);
  const link = (key: Active, href: string, label: string) => (
    <Link href={href} className={`py-2.5 text-[15px] font-semibold text-ink-2 hover:text-navy ${active === key ? "border-b-2 border-navy font-extrabold text-navy" : ""}`}>
      {label}
    </Link>
  );
  return (
    <header className="border-b border-line bg-white">
      <div className={`${container} flex flex-wrap items-center gap-x-7 gap-y-3 py-3.5`}>
        <div className="flex items-center gap-2.5">
          <Link href="/" className="text-[24px] font-extrabold tracking-[-0.5px] text-navy">
            Sophia
          </Link>
          <span className="rounded-full bg-tint px-2.5 py-1 text-[12px] font-bold text-navy">{s.nav.badge}</span>
        </div>
        <nav className="flex flex-1 flex-wrap items-center gap-x-[22px] gap-y-1">
          {link("dashboard", "/studio", s.nav.dashboard)}
          {link("courses", "/studio/courses", s.nav.courses)}
          {link("payments", "/studio#payments", s.nav.payments)}
          {link("profile", "/studio/profile", s.nav.profile)}
          {link("guide", "/studio/guide", s.nav.guide)}
          {session.isAdmin && link("admin", "/admin", s.nav.admin)}
        </nav>
        <div className="flex items-center gap-3">
          <form action={createDraft}>
            <button type="submit" className="inline-flex h-11 items-center gap-2 rounded-btn bg-navy px-[18px] text-[15px] font-bold text-white hover:bg-ink">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden="true">
                <path d="M12 5v14M5 12h14" />
              </svg>
              {s.nav.write}
            </button>
          </form>
          <details className="relative">
            <summary className="list-none cursor-pointer" aria-label={name}>
              <Initials name={name} size={40} className="bg-[#B45309] text-white" />
            </summary>
            <div className="absolute right-0 z-10 mt-2 flex w-56 flex-col gap-1 rounded-2xl border border-line bg-white p-2 shadow-[0_16px_40px_rgba(22,38,61,.12)]">
              <span className="truncate px-3 py-2 text-[13px] text-ink-3">{session.user.email}</span>
              <Link href="/studio/profile" className="rounded-xl px-3 py-2 text-[14px] font-semibold hover:bg-paper">
                {s.nav.profile}
              </Link>
              <form action={signOut}>
                <button type="submit" className="w-full rounded-xl px-3 py-2 text-left text-[14px] font-semibold text-red hover:bg-paper">
                  {s.nav.signOut}
                </button>
              </form>
            </div>
          </details>
        </div>
      </div>
    </header>
  );
}

export function StatusPill({ status }: { status: string }) {
  const look: Record<string, string> = {
    draft: "bg-tint text-ink-2",
    submitted: "bg-amber-bg text-amber",
    changes_requested: "bg-red-bg text-red",
    accepted: "bg-green-bg text-green",
    publishing: "bg-tint text-navy",
    published: "bg-green-bg text-green",
    failed: "bg-red-bg text-red",
    archived: "bg-paper text-muted",
  };
  return <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[12px] font-bold ${look[status] ?? "bg-tint text-ink-2"}`}>{s.dashboard.statuses[status] ?? status}</span>;
}
