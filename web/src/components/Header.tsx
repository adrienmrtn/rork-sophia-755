"use client";

import { AnimatePresence, motion, useMotionValueEvent, useScroll, useSpring } from "motion/react";
import { useState } from "react";
import { Button, Logo } from "./ui";
import { links } from "@/lib/site";

const nav = [
  { href: "#fil", label: "Les cours" },
  { href: "#methode", label: "La méthode" },
  { href: "#auteurs", label: "Les auteurs" },
  { href: "#premium", label: "Premium" },
];

export function Header() {
  const { scrollY, scrollYProgress } = useScroll();
  const progress = useSpring(scrollYProgress, { stiffness: 140, damping: 30, restDelta: 0.001 });
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useMotionValueEvent(scrollY, "change", (y) => setScrolled(y > 8));

  return (
    <header
      className={`sticky top-0 z-50 transition-[background-color,box-shadow] duration-300 ${
        scrolled ? "bg-paper/90 shadow-[0_1px_0_var(--color-line)] backdrop-blur-md" : "bg-cream"
      }`}
    >
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
        <a href="#" aria-label="Sophia, retour en haut">
          <Logo />
        </a>

        <nav className="hidden items-center gap-1 md:flex" aria-label="Navigation principale">
          {nav.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="rounded-lg px-3 py-2 text-[15px] font-semibold text-ink-2 transition-colors hover:bg-sand hover:text-ink"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <span className="hidden sm:block">
            <Button href={links.appStore} size="sm">
              Télécharger l&apos;app
            </Button>
          </span>
          <button
            type="button"
            className="flex h-10 w-10 items-center justify-center rounded-xl text-ink ring-1 ring-line md:hidden"
            aria-expanded={open}
            aria-controls="menu-mobile"
            aria-label={open ? "Fermer le menu" : "Ouvrir le menu"}
            onClick={() => setOpen((v) => !v)}
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
              <motion.path animate={{ d: open ? "M6 6L18 18" : "M4 8L20 8" }} />
              <motion.path animate={{ d: open ? "M18 6L6 18" : "M4 16L20 16" }} />
            </svg>
          </button>
        </div>
      </div>

      {/* Barre de lecture, comme sur un article. */}
      <motion.div className="absolute inset-x-0 bottom-0 h-[3px] origin-left bg-saffron" style={{ scaleX: progress }} aria-hidden />

      <AnimatePresence>
        {open && (
          <motion.nav
            id="menu-mobile"
            aria-label="Navigation mobile"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ type: "spring", stiffness: 260, damping: 30 }}
            className="overflow-hidden border-t border-line bg-paper md:hidden"
          >
            <div className="px-4 pb-6 pt-2">
              {nav.map((item, i) => (
                <motion.a
                  key={item.href}
                  href={item.href}
                  onClick={() => setOpen(false)}
                  initial={{ x: -16, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.05 * i }}
                  className="block border-b border-line py-3.5 text-lg font-bold"
                >
                  {item.label}
                </motion.a>
              ))}
              <Button href={links.appStore} className="mt-5 w-full">
                Télécharger l&apos;app
              </Button>
            </div>
          </motion.nav>
        )}
      </AnimatePresence>
    </header>
  );
}
