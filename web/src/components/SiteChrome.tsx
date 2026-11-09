import Image from "next/image";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { t } from "@/lib/copy/en";
import { StoreButtons } from "./StoreButtons";
import { ButtonLink, container } from "./ui";

function GlobeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <circle cx="12" cy="12" r="9" />
      <path d="M3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18" />
    </svg>
  );
}

/** « Se connecter » pour un visiteur, « Mon studio » pour un compte connecté. */
async function AccountLink() {
  let signedIn = false;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    signedIn = Boolean(user);
  } catch {
    signedIn = false;
  }
  return signedIn ? (
    <ButtonLink href="/studio" variant="ghost">
      {t.nav.studio}
    </ButtonLink>
  ) : (
    <ButtonLink href="/join" variant="ghost">
      {t.nav.signIn}
    </ButtonLink>
  );
}

export function SiteHeader({ active }: { active?: "explore" | "write" | "premium" | "about" }) {
  const link = (key: NonNullable<typeof active>, href: string, label: string) => (
    <Link
      href={href}
      className={`py-2.5 text-[15px] font-semibold text-ink-2 hover:text-navy ${active === key ? "border-b-2 border-navy font-extrabold text-navy" : ""}`}
    >
      {label}
    </Link>
  );
  return (
    <header className="border-b border-line bg-white">
      <div className={`${container} flex flex-wrap items-center gap-x-7 gap-y-3 py-3.5`}>
        <Link href="/" aria-label="Sophia, home" className="flex items-center">
          <Image src="/brand/sophia-logo.png" alt="Sophia" width={1192} height={334} className="h-[34px] w-auto" priority />
        </Link>
        <nav className="flex flex-1 flex-wrap items-center gap-x-6 gap-y-1">
          {link("explore", "/courses", t.nav.explore)}
          {link("write", "/write", t.nav.write)}
          {link("premium", "/#premium", t.nav.premium)}
          {link("about", "/about", t.nav.about)}
        </nav>
        <div className="flex flex-wrap items-center gap-2.5">
          <span className="inline-flex h-11 items-center gap-2 rounded-btn border border-line px-3.5 text-[14px] font-bold text-ink-2" title={t.nav.language}>
            <GlobeIcon /> EN
          </span>
          <AccountLink />
          <ButtonLink href="/#download">{t.nav.download}</ButtonLink>
        </div>
      </div>
    </header>
  );
}

export function SiteFooter({ compact = false }: { compact?: boolean }) {
  if (compact) {
    return (
      <footer className="border-t border-line bg-paper">
        <div className={`${container} flex flex-wrap items-center justify-between gap-x-6 gap-y-3 py-8 text-[13px] text-ink-3`}>
          <span>{t.footer.copyright}</span>
          <nav className="flex flex-wrap gap-x-[18px] text-[13px] font-semibold">
            <Link href="/about">{t.footer.about}</Link>
            <Link href="/legal/privacy">{t.footer.privacy}</Link>
            <Link href="/legal/terms">{t.footer.terms}</Link>
            <Link href="/write">{t.footer.writeForSophia}</Link>
          </nav>
        </div>
      </footer>
    );
  }
  const col = (title: string, links: [string, string][]) => (
    <div className="flex min-w-[160px] flex-1 flex-col gap-2.5 text-[14px]">
      <strong className="text-[13px] font-bold uppercase tracking-[.6px] text-muted">{title}</strong>
      {links.map(([label, href]) => (
        <Link key={href + label} href={href} className="text-ink-2 hover:text-navy">
          {label}
        </Link>
      ))}
    </div>
  );
  return (
    <footer className="border-t border-line bg-paper">
      <div className={`${container} flex flex-col gap-8 pt-12 pb-8`}>
        <div className="flex flex-wrap gap-x-12 gap-y-8">
          <div className="flex min-w-[260px] flex-1 flex-col gap-3.5">
            <Image src="/brand/sophia-logo.png" alt="Sophia" width={1192} height={334} className="h-[30px] w-auto self-start" />
            <span className="max-w-[280px] text-[14px] leading-relaxed text-ink-3">{t.footer.tagline}</span>
            <StoreButtons size="compact" />
          </div>
          {col(t.footer.learn, [
            [t.footer.exploreCourses, "/courses"],
            [t.footer.authors, "/authors"],
            [t.footer.premium, "/#premium"],
            [t.footer.app, "/#download"],
          ])}
          {col(t.footer.create, [
            [t.footer.writeForSophia, "/write"],
            [t.footer.guide, "/write#guide"],
            [t.footer.hub, "https://sophia-culture.com/creators"],
            [t.footer.signIn, "/join"],
          ])}
          {col(t.footer.sophia, [
            [t.footer.about, "/about"],
            [t.footer.help, "/about#help"],
            [t.footer.contact, "/about#contact"],
          ])}
          {col(t.footer.legal, [
            [t.footer.privacy, "/legal/privacy"],
            [t.footer.terms, "/legal/terms"],
            [t.footer.agreement, "/legal/creator-agreement"],
          ])}
        </div>
        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-line pt-6 text-[13px] text-ink-3">
          <span>{t.footer.copyright}</span>
          <span className="inline-flex items-center gap-2 font-semibold">
            <GlobeIcon /> English
          </span>
        </div>
      </div>
    </footer>
  );
}
