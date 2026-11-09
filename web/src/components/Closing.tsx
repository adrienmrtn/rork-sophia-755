"use client";

import Image from "next/image";
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { showcase } from "@/lib/showcase";
import { links } from "@/lib/config";
import { Button, Rise } from "./ui";

// Avis repris de l'onboarding de l'app (AppLocalizable.swift, onboardingV2.review.*).
const reviews = [
  { name: "Camille, 22 ans", text: "Depuis que je scroll moins et que j'utilise Sophia, j'ai l'impression que je retiens beaucoup plus de choses.", avatar: 1 },
  { name: "Yanis, 27 ans", text: "10 minutes le matin dans le métro et le soir j'ai un truc à raconter. Franchement je suis accro.", avatar: 2 },
  { name: "Inès, 19 ans", text: "J'ai toujours détesté « réviser », mais là ça rentre tout seul. Ma mémoire me surprend.", avatar: 3 },
  { name: "Thomas, 31 ans", text: "Je remplace mes scrolls sans fin par un cours. En un mois, mes proches ont remarqué la différence.", avatar: 4 },
  { name: "Sarah, 26 ans", text: "Enfin une app qui me donne l'impression d'avancer, pas de perdre mon temps. Je la lance tous les jours.", avatar: 5 },
  { name: "Malik, 23 ans", text: "Les quiz espacés, c'est magique : je me souviens de trucs appris il y a des semaines sans forcer.", avatar: 0 },
];

export function Testimonials() {
  return (
    <section className="bg-cream py-20 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <Rise className="text-center">
          <p className="eyebrow">Ils lisent Sophia</p>
          <h2 className="mt-4 text-4xl font-extrabold tracking-[-0.03em] sm:text-5xl">Ce qu&apos;en disent nos lecteurs</h2>
          <p className="mt-3 font-serif text-xl text-ink-2">Plus de 1 000 avis sur les stores.</p>
        </Rise>
        <div className="mt-12 columns-1 gap-5 sm:columns-2 lg:columns-3">
          {reviews.map((r, i) => (
            <Rise key={r.name} delay={(i % 3) * 90} className="mb-5 break-inside-avoid">
              <figure className="rounded-[22px] bg-paper p-6 ring-1 ring-line">
                <p className="text-[15px] tracking-[0.2em] text-saffron" aria-label="5 étoiles sur 5">★★★★★</p>
                <blockquote className="mt-3 font-serif text-[20px] leading-snug text-ink">« {r.text} »</blockquote>
                <figcaption className="mt-5 flex items-center gap-3">
                  {r.avatar ? (
                    <Image src={`/img/avatars/review_${r.avatar}.webp`} alt="" width={40} height={40} className="h-10 w-10 rounded-full object-cover" />
                  ) : (
                    <span className="flex h-10 w-10 items-center justify-center rounded-full bg-saffron-soft font-bold text-navy">{r.name[0]}</span>
                  )}
                  <span className="text-[15px] font-bold">{r.name}</span>
                </figcaption>
              </figure>
            </Rise>
          ))}
        </div>
      </div>
    </section>
  );
}

const faq = [
  {
    q: "Qu'est-ce que Sophia ?",
    a: "Une app de culture générale : chaque jour, un cours court écrit par un spécialiste, suivi d'un quiz pour retenir l'essentiel. Histoire, sciences, littérature, art, mythologie et actualité du monde.",
  },
  {
    q: "Combien de temps faut-il par jour ?",
    a: "Environ 10 minutes. Les cours se lisent d'une traite : dans les transports, à la pause déjeuner ou avant de dormir.",
  },
  {
    q: "Qui écrit les cours ?",
    a: `Des profs, des chercheurs et des auteurs spécialisés (${showcase.stats.creators} à ce jour), venus d'universités comme Oxford, Queen's University Belfast, Boston University ou l'université de Belgrade. Chaque cours est relu avant publication.`,
  },
  {
    q: "Comment marche le bloqueur d'apps ?",
    a: "Vous choisissez les apps qui vous distraient. Sophia les verrouille jusqu'à ce que le cours du jour soit terminé, puis les libère. Vous gardez la main sur la liste à tout moment.",
  },
  {
    q: "Sophia est-elle gratuite ?",
    a: "L'introduction de chaque cours est gratuite. Premium débloque tous les cours, les quiz, la narration audio et le bloqueur, avec trois jours d'essai.",
  },
  {
    q: "Sur quels appareils, dans quelles langues ?",
    a: `Sur iPhone et Android, en ${showcase.stats.languages} langues, dont le français, l'anglais, l'espagnol, l'allemand, l'italien, le portugais et le japonais.`,
  },
];

export function Faq() {
  const [open, setOpen] = useState(0);
  return (
    <section id="faq" className="scroll-mt-16 bg-paper py-20 sm:py-28">
      <div className="mx-auto grid max-w-6xl gap-12 px-4 sm:px-6 lg:grid-cols-[0.8fr_1.4fr]">
        <Rise>
          <p className="eyebrow">Questions fréquentes</p>
          <h2 className="mt-4 text-4xl font-extrabold leading-[1.08] tracking-[-0.03em] sm:text-5xl">Tout ce que vous vous demandez</h2>
        </Rise>
        <div className="divide-y divide-line border-y border-line">
          {faq.map((item, i) => {
            const isOpen = open === i;
            return (
              <div key={item.q}>
                <button
                  type="button"
                  id={`faq-q-${i}`}
                  aria-expanded={isOpen}
                  aria-controls={`faq-a-${i}`}
                  onClick={() => setOpen(isOpen ? -1 : i)}
                  className="flex w-full items-center justify-between gap-4 py-5 text-left text-[18px] font-extrabold tracking-tight"
                >
                  {item.q}
                  <motion.span
                    animate={{ rotate: isOpen ? 45 : 0, backgroundColor: isOpen ? "#1a3a6b" : "#f3ecdf", color: isOpen ? "#ffffff" : "#1a3a6b" }}
                    className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
                  >
                    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden>
                      <path d="M12 5v14M5 12h14" />
                    </svg>
                  </motion.span>
                </button>
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      id={`faq-a-${i}`}
                      role="region"
                      aria-labelledby={`faq-q-${i}`}
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ type: "spring", stiffness: 220, damping: 30 }}
                      className="overflow-hidden"
                    >
                      <p className="max-w-2xl pb-6 font-serif text-[18px] leading-relaxed text-ink-2">{item.a}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export function FinalCta() {
  const covers = showcase.heroFeed;
  return (
    <section className="relative overflow-hidden bg-cream py-24 sm:py-32">
      <div className="pointer-events-none absolute inset-0 flex items-center justify-center" aria-hidden>
        {covers.map((c, i) => {
          const angle = (i / covers.length) * Math.PI * 2;
          return (
            <motion.div
              key={c.slug}
              className="absolute hidden h-24 w-32 overflow-hidden rounded-xl opacity-90 shadow-lg md:block"
              style={{ left: `calc(50% + ${Math.cos(angle) * 46}% - 64px)`, top: `calc(50% + ${Math.sin(angle) * 38}% - 48px)` }}
              animate={{ y: [0, -10, 0], rotate: [i % 2 ? -4 : 4, i % 2 ? 2 : -2, i % 2 ? -4 : 4] }}
              transition={{ duration: 6 + i, repeat: Infinity, ease: "easeInOut" }}
            >
              <Image src={c.image} alt="" fill sizes="128px" className="object-cover" />
            </motion.div>
          );
        })}
      </div>
      <Rise className="relative mx-auto max-w-2xl px-4 text-center sm:px-6">
        <Image src="/img/brand/app_icon.webp" alt="" width={88} height={88} className="mx-auto h-20 w-20 rounded-[22px] shadow-xl" />
        <h2 className="mt-8 text-5xl font-extrabold leading-[1.02] tracking-[-0.035em] sm:text-6xl">
          Votre version la plus cultivée commence ici.
        </h2>
        <p className="mx-auto mt-5 max-w-lg font-serif text-xl leading-relaxed text-ink-2">
          Téléchargez Sophia, lisez votre premier cours en dix minutes, et voyez votre culture générale grandir semaine
          après semaine.
        </p>
        <div className="mt-9 flex flex-wrap justify-center gap-3"><Button href="/commencer" size="lg">Commencer gratuitement</Button><Button href={links.download} variant="secondary" size="lg">Télécharger l&apos;app</Button></div>
      </Rise>
    </section>
  );
}
