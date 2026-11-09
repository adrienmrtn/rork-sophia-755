import Image from "next/image";
import Link from "next/link";
import { Initials, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { displayName, type StudioSession } from "@/lib/studio/account";
import { createDraft, signOut } from "@/app/studio/actions";

type Active = "dashboard" | "courses" | "payments" | "profile" | "guide" | "admin";

/** L'en-tête de l'espace auteur : des onglets en pastilles, le bouton Écrire, le menu du compte. */
export function StudioHeader({ session, active }: { session: StudioSession; active?: Active }) {
  const name = displayName(session.account, session.user);
  const link = (key: Active, href: string, label: string) => (
    <Link href={href} className={`rounded-full px-3.5 py-2 text-[14px] font-bold transition-colors ${active === key ? "bg-tint text-navy" : "text-ink-2 hover:bg-paper hover:text-navy"}`}>
      {label}
    </Link>
  );
  return (
    <header className="sticky top-0 z-20 border-b border-line bg-white/95 backdrop-blur">
      <div className={`${container} flex flex-wrap items-center gap-x-6 gap-y-2 py-3`}>
        <div className="flex items-center gap-2.5">
          <Link href="/" aria-label="Sophia, home" className="flex items-center">
            <Image src="/brand/sophia-logo.png" alt="Sophia" width={1192} height={334} className="h-[30px] w-auto" />
          </Link>
          <span className="rounded-full bg-cream px-2.5 py-1 text-[12px] font-bold text-amber">{s.nav.badge}</span>
        </div>
        <nav className="flex flex-1 flex-wrap items-center gap-1">
          {link("dashboard", "/studio", s.nav.dashboard)}
          {link("courses", "/studio/courses", s.nav.courses)}
          {link("payments", "/studio#payments", s.nav.payments)}
          {link("profile", "/studio/profile", s.nav.profile)}
          {link("guide", "/studio/guide", s.nav.guide)}
          {session.isAdmin && link("admin", "/admin", s.nav.admin)}
        </nav>
        <div className="flex items-center gap-3">
          <form action={createDraft}>
            <button type="submit" className="inline-flex h-10 items-center gap-2 rounded-full bg-navy px-4 text-[14px] font-bold text-white transition-colors hover:bg-ink">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" aria-hidden="true">
                <path d="M12 5v14M5 12h14" />
              </svg>
              {s.nav.write}
            </button>
          </form>
          <details className="relative">
            <summary className="list-none cursor-pointer rounded-full ring-offset-2 transition hover:ring-2 hover:ring-tint" aria-label={name}>
              <Initials name={name} size={40} className="bg-saffron text-ink" />
            </summary>
            <div className="absolute right-0 z-10 mt-2 flex w-60 flex-col gap-1 rounded-2xl border border-line bg-white p-2 shadow-[0_16px_40px_rgba(22,38,61,.12)]">
              <span className="truncate px-3 py-2 text-[13px] text-ink-3">{session.user.email}</span>
              <Link href="/studio/profile" className="rounded-xl px-3 py-2 text-[14px] font-semibold hover:bg-paper">
                {s.nav.profile}
              </Link>
              {session.account?.slug && session.publicPage ? (
                <Link href={`/authors/${session.account.slug}`} className="rounded-xl px-3 py-2 text-[14px] font-semibold hover:bg-paper">
                  My public page
                </Link>
              ) : (
                <span className="px-3 py-2 text-[12px] leading-[1.4] text-muted">Your public page appears with your first published course.</span>
              )}
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

export function StatusPill({ status, size = "md" }: { status: string; size?: "sm" | "md" }) {
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
  const dot: Record<string, string> = { draft: "bg-line-2", submitted: "bg-saffron", changes_requested: "bg-coral", accepted: "bg-green-2", publishing: "bg-blue", published: "bg-green-2", failed: "bg-red-2", archived: "bg-muted" };
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full font-bold ${size === "sm" ? "px-2 py-0.5 text-[11px]" : "px-2.5 py-1 text-[12px]"} ${look[status] ?? "bg-tint text-ink-2"}`}>
      <span aria-hidden="true" className={`h-1.5 w-1.5 rounded-full ${dot[status] ?? "bg-line-2"}`} />
      {s.dashboard.statuses[status] ?? status}
    </span>
  );
}

/** L'en-tête d'une page du Studio : titre, phrase d'accroche, actions à droite. */
export function PageTitle({ eyebrow, title, lead, children }: { eyebrow?: string; title: string; lead?: string; children?: React.ReactNode }) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-4">
      <div className="flex flex-col gap-1.5">
        {eyebrow && <span className="text-[12px] font-bold uppercase tracking-[1.2px] text-blue">{eyebrow}</span>}
        <h1 className="text-[32px] font-extrabold tracking-[-0.8px] text-ink">{title}</h1>
        {lead && <p className="max-w-[640px] text-[16px] leading-[1.5] text-ink-3">{lead}</p>}
      </div>
      {children}
    </div>
  );
}
