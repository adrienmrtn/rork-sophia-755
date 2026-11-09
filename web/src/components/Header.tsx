"use client";

import { useEffect, useState } from "react";
import { Button, Logo } from "./ui";
import { links } from "@/lib/site";

const nav = [
  { href: "#cours", label: "Les cours" },
  { href: "#methode", label: "La méthode" },
  { href: "#profs", label: "Les profs" },
  { href: "#faq", label: "FAQ" },
];

export function Header() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`sticky top-0 z-50 border-b-[2.5px] transition-colors ${
        scrolled ? "border-ink bg-cream/95 backdrop-blur" : "border-transparent bg-cream"
      }`}
    >
      <div className="mx-auto flex h-[72px] max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
        <a href="#" aria-label="Sophia, accueil">
          <Logo />
        </a>

        <nav className="hidden items-center gap-8 md:flex" aria-label="Navigation principale">
          {nav.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="font-semibold text-ink-soft underline-offset-[6px] decoration-[3px] decoration-saffron hover:text-ink hover:underline"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <span className="hidden sm:block">
            <Button href={links.appStore} tone="pink" size="sm">
              Essayer gratuitement
            </Button>
          </span>
          <button
            type="button"
            className="brutal-sm press flex h-10 w-10 items-center justify-center rounded-xl bg-paper md:hidden"
            aria-expanded={open}
            aria-controls="menu-mobile"
            aria-label={open ? "Fermer le menu" : "Ouvrir le menu"}
            onClick={() => setOpen((v) => !v)}
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              {open ? <path d="M6 6l12 12M18 6 6 18" /> : <path d="M4 7h16M4 12h16M4 17h16" />}
            </svg>
          </button>
        </div>
      </div>

      {open && (
        <nav id="menu-mobile" className="border-t-[2.5px] border-ink bg-cream px-4 pb-6 pt-2 md:hidden" aria-label="Navigation mobile">
          {nav.map((item) => (
            <a
              key={item.href}
              href={item.href}
              onClick={() => setOpen(false)}
              className="block border-b-2 border-dashed border-ink/20 py-3 font-display text-xl font-bold"
            >
              {item.label}
            </a>
          ))}
          <Button href={links.appStore} tone="pink" className="mt-5 w-full">
            Essayer gratuitement
          </Button>
        </nav>
      )}
    </header>
  );
}
