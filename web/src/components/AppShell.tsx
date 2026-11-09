"use client";

import { motion, useScroll, useSpring } from "motion/react";
import { usePathname } from "next/navigation";
import { links } from "@/lib/config";
import { Logo } from "./ui";
import {
  IconCompass,
  IconCrown,
  IconDownload,
  IconHome,
  IconLayers,
  IconPen,
  IconSpark,
  IconUsers,
} from "./icons";

const nav = [
  { href: "/", label: "Accueil", Icon: IconHome },
  { href: "/explorer", label: "Explorer", Icon: IconCompass },
  { href: "/auteurs", label: "Auteurs", Icon: IconUsers },
  { href: "/collections", label: "Collections", Icon: IconLayers },
  { href: "/methode", label: "La méthode", Icon: IconSpark },
  { href: "/premium", label: "Premium", Icon: IconCrown },
];

const mobileNav = [
  { href: "/", label: "Accueil", Icon: IconHome },
  { href: "/explorer", label: "Explorer", Icon: IconCompass },
  { href: "/auteurs", label: "Auteurs", Icon: IconUsers },
  { href: "/premium", label: "Premium", Icon: IconCrown },
  { href: "/devenir-createur", label: "Écrire", Icon: IconPen },
];

function isActive(pathname: string, href: string) {
  const p = pathname.replace(/\/$/, "") || "/";
  if (href === "/") return p === "/";
  return p === href || p.startsWith(href + "/") || (href === "/explorer" && (p.startsWith("/matieres") || p.startsWith("/cours")));
}

function ScrollBar() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 140, damping: 30, restDelta: 0.001 });
  return <motion.div className="fixed inset-x-0 top-0 z-[60] h-[3px] origin-left bg-saffron" style={{ scaleX }} aria-hidden />;
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname() ?? "/";

  return (
    <div className="min-h-screen bg-paper">
      <ScrollBar />

      {/* Barre latérale (ordinateur) */}
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-[248px] flex-col border-r border-line bg-paper px-4 py-6 lg:flex">
        <a href="/" className="px-3" aria-label="Sophia, accueil">
          <Logo />
        </a>
        <nav className="mt-8 flex flex-col gap-0.5" aria-label="Navigation principale">
          {nav.map(({ href, label, Icon }) => {
            const active = isActive(pathname, href);
            return (
              <a
                key={href}
                href={href}
                aria-current={active ? "page" : undefined}
                className={`relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-[15px] font-semibold transition-colors ${
                  active ? "text-ink" : "text-ink-2 hover:bg-cream hover:text-ink"
                }`}
              >
                {active && <motion.span layoutId="nav-active" className="absolute inset-0 rounded-xl bg-sand" transition={{ type: "spring", stiffness: 400, damping: 34 }} />}
                <Icon className="relative h-[22px] w-[22px]" filled={active} />
                <span className="relative">{label}</span>
              </a>
            );
          })}
        </nav>

        <div className="mt-6 border-t border-line pt-6">
          <a
            href="/devenir-createur"
            className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-[15px] font-semibold transition-colors ${
              isActive(pathname, "/devenir-createur") ? "bg-sand text-ink" : "text-ink-2 hover:bg-cream hover:text-ink"
            }`}
          >
            <IconPen className="h-[22px] w-[22px]" /> Devenir créateur
          </a>
        </div>

        <div className="mt-auto space-y-2.5">
          <a
            href="/commencer"
            className="flex h-12 items-center justify-center rounded-xl bg-navy font-bold text-white shadow-[0_8px_20px_-8px_rgba(26,58,107,0.6)] transition-colors hover:bg-navy-deep"
          >
            Commencer gratuitement
          </a>
          <a
            href={links.download}
            target="_blank"
            rel="noopener"
            className="flex h-11 items-center justify-center gap-2 rounded-xl text-[15px] font-bold text-navy ring-1 ring-line transition-colors hover:bg-cream"
          >
            <IconDownload className="h-4 w-4" /> Télécharger l&apos;app
          </a>
        </div>
      </aside>

      {/* Barre du haut (mobile) */}
      <header className="sticky top-0 z-40 flex h-14 items-center justify-between border-b border-line bg-paper/95 px-4 backdrop-blur lg:hidden">
        <a href="/" aria-label="Sophia, accueil">
          <Logo className="!w-[104px]" />
        </a>
        <a href="/commencer" className="flex h-9 items-center rounded-lg bg-navy px-3.5 text-sm font-bold text-white">
          Commencer
        </a>
      </header>

      <div className="pb-20 lg:pb-0 lg:pl-[248px]">
        {children}
        <SiteFooter />
      </div>

      {/* Barre d'onglets (mobile) */}
      <nav
        className="fixed inset-x-0 bottom-0 z-40 grid grid-cols-5 border-t border-line bg-paper/95 pb-[env(safe-area-inset-bottom)] backdrop-blur lg:hidden"
        aria-label="Navigation mobile"
      >
        {mobileNav.map(({ href, label, Icon }) => {
          const active = isActive(pathname, href);
          return (
            <a key={href} href={href} aria-current={active ? "page" : undefined} className={`flex flex-col items-center gap-0.5 py-2 text-[11px] font-bold ${active ? "text-navy" : "text-ink-3"}`}>
              <Icon className="h-6 w-6" filled={active} />
              {label}
            </a>
          );
        })}
      </nav>
    </div>
  );
}

function SiteFooter() {
  const cols = [
    { title: "Apprendre", items: [["Accueil", "/"], ["Explorer", "/explorer"], ["Collections", "/collections"], ["La méthode", "/methode"]] },
    { title: "Sophia", items: [["Premium", "/premium"], ["Commencer", "/commencer"], ["Télécharger l'app", links.download]] },
    { title: "Créer", items: [["Devenir créateur", "/devenir-createur"], ["Les auteurs", "/auteurs"]] },
    { title: "Légal", items: [["Confidentialité", links.privacy], ["Conditions d'utilisation", links.terms], ["Support", links.support]] },
  ];
  return (
    <footer className="border-t border-line bg-cream/60 px-4 py-12 sm:px-8">
      <div className="mx-auto grid max-w-5xl gap-10 sm:grid-cols-[1.2fr_2fr]">
        <div>
          <Logo />
          <p className="mt-3 max-w-xs font-serif text-[17px] leading-snug text-ink-2">La culture générale, dix minutes par jour, écrite par ceux qui savent.</p>
        </div>
        <div className="grid grid-cols-2 gap-8 sm:grid-cols-4">
          {cols.map((c) => (
            <div key={c.title}>
              <p className="text-[12px] font-bold uppercase tracking-[0.14em] text-ink-3">{c.title}</p>
              <ul className="mt-3 space-y-2 text-[14px] font-semibold text-ink-2">
                {c.items.map(([label, href]) => (
                  <li key={label}>
                    <a href={href} className="hover:text-navy" {...(href.startsWith("http") ? { target: "_blank", rel: "noopener" } : {})}>
                      {label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
      <p className="mx-auto mt-10 max-w-5xl text-[13px] text-ink-3">© {new Date().getFullYear()} Sophia. Tous droits réservés.</p>
    </footer>
  );
}
