"use client";

import Image from "next/image";
import { motion, useInView } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { site, links, type Creator } from "@/lib/site";
import { Arrow, Avatar, Button, Rise } from "./ui";

function AuthorCard({ a, i }: { a: Creator; i: number }) {
  return (
    <Rise delay={(i % 4) * 70}>
      <motion.article
        initial="rest"
        whileHover="hover"
        animate="rest"
        className="group relative h-full rounded-[22px] bg-paper p-5 ring-1 ring-line transition-shadow hover:shadow-[0_24px_48px_-24px_rgba(22,38,61,0.35)]"
      >
        <div className="flex items-center gap-3.5">
          <Avatar author={a} size={56} className="!ring-0" />
          <div className="min-w-0">
            <h3 className="truncate text-[17px] font-extrabold tracking-tight">{a.name}</h3>
            <p className="text-[13px] font-semibold text-sky">{a.courseCount} cours</p>
          </div>
        </div>
        <p className="mt-3 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2">{a.title}</p>
        <div className="relative mt-4 h-16">
          {a.courses.map((c, k) => (
            <motion.div
              key={c.title}
              variants={{
                rest: { x: k * 18, rotate: 0, y: 0 },
                hover: { x: k * 74, rotate: [-4, 2, 5][k], y: -4 },
              }}
              transition={{ type: "spring", stiffness: 260, damping: 20 }}
              className="absolute left-0 top-0 h-16 w-[88px] overflow-hidden rounded-lg ring-2 ring-paper"
              style={{ zIndex: 3 - k }}
              title={c.title}
            >
              <Image src={c.image} alt="" fill sizes="88px" className="object-cover" />
            </motion.div>
          ))}
        </div>
      </motion.article>
    </Rise>
  );
}

const steps = [
  { title: "Compte auteur", text: "nom, titre, institution, photo, contrat signé en ligne." },
  { title: "500 à 900 mots", text: "cinq parties, une frise, un « Le savais-tu ? », des images libres de droits." },
  { title: "Relecture sous 72 h", text: "l'équipe relit, demande au besoin une retouche, puis accepte." },
  { title: "Publié en 30 langues", text: "quiz, glossaire, couverture, traductions et audio faits pour vous." },
];

const draftTitle = "Pourquoi les Romains construisaient-ils des routes droites ?";

/** Faux éditeur dont le titre se tape tout seul. */
function EditorMock() {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: "-15% 0px" });
  const [typed, setTyped] = useState(draftTitle.length);

  useEffect(() => {
    if (!inView || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    setTyped(0);
    let n = 0;
    const t = setInterval(() => {
      n += 1;
      setTyped(n);
      if (n >= draftTitle.length) clearInterval(t);
    }, 38);
    return () => clearInterval(t);
  }, [inView]);

  const finished = typed >= draftTitle.length;

  return (
    <div ref={ref} className="overflow-hidden rounded-[22px] bg-paper shadow-[0_30px_60px_-30px_rgba(22,38,61,0.45)] ring-1 ring-line">
      <div className="flex items-center gap-1.5 border-b border-line px-4 py-3">
        <span className="h-2.5 w-2.5 rounded-full bg-coral/70" />
        <span className="h-2.5 w-2.5 rounded-full bg-saffron/80" />
        <span className="h-2.5 w-2.5 rounded-full bg-sage/70" />
        <span className="ml-3 text-[12px] font-semibold text-ink-3">Brouillon · enregistré</span>
      </div>
      <div className="p-6">
        <p className="eyebrow">Histoire · Partie 1 sur 5</p>
        <p className="mt-2 min-h-[3.4em] text-[22px] font-extrabold leading-snug tracking-tight">
          {draftTitle.slice(0, typed)}
          {!finished && <span className="ml-0.5 inline-block h-[1em] w-[2px] translate-y-[3px] animate-pulse bg-navy" />}
        </p>
        <div className="mt-4 space-y-2.5">
          {[100, 94, 97, 60].map((w, i) => (
            <motion.div
              key={i}
              className="h-2.5 rounded-full bg-sand"
              initial={false}
              animate={{ width: finished ? `${w}%` : "0%" }}
              transition={{ delay: i * 0.12, duration: 0.6, ease: [0.2, 0.8, 0.2, 1] }}
            />
          ))}
        </div>
        <motion.div
          initial={false}
          animate={{ opacity: finished ? 1 : 0, y: finished ? 0 : 10 }}
          transition={{ delay: 0.6 }}
          className="mt-5 rounded-xl bg-saffron-soft p-4"
        >
          <p className="text-[13px] font-extrabold text-navy">Le savais-tu ?</p>
          <p className="mt-1 font-serif text-[15px] leading-snug text-ink-2">
            Le réseau routier romain a compté plus de 80 000 km de voies pavées.
          </p>
        </motion.div>
        <div className="mt-5 flex items-center justify-between text-[13px] font-semibold text-ink-2">
          <span className="tabular-nums">{finished ? 642 : Math.round((typed / draftTitle.length) * 40)} mots</span>
          <span className="rounded-lg bg-navy px-3 py-1.5 text-white">Envoyer en relecture</span>
        </div>
      </div>
    </div>
  );
}

export function Authors() {
  const authors = site.creators.filter((c) => c.photo).slice(0, 8);
  return (
    <section id="auteurs" className="scroll-mt-16 bg-paper py-20 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <Rise className="flex flex-wrap items-end justify-between gap-6">
          <div className="max-w-2xl">
            <p className="eyebrow">Les auteurs</p>
            <h2 className="mt-4 text-4xl font-extrabold leading-[1.08] tracking-[-0.03em] sm:text-5xl">
              Écrits par des profs et des chercheurs
            </h2>
          </div>
          <p className="max-w-sm font-serif text-xl leading-relaxed text-ink-2">
            Docteurs, chercheurs, professeurs. Chaque auteur signe ses cours, et chaque cours est relu avant
            publication.
          </p>
        </Rise>

        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {authors.map((a, i) => (
            <AuthorCard key={a.name} a={a} i={i} />
          ))}
        </div>

        <Rise className="mt-20">
          <div className="grid items-center gap-10 rounded-[32px] bg-cream p-6 sm:p-10 lg:grid-cols-[1fr_1.1fr] lg:gap-14 lg:p-14">
            <div className="order-2 lg:order-1">
              <EditorMock />
            </div>
            <div className="order-1 lg:order-2">
              <p className="eyebrow">Pour les enseignants et les chercheurs</p>
              <h3 className="mt-4 text-3xl font-extrabold leading-[1.1] tracking-[-0.03em] sm:text-[40px]">
                Vous savez quelque chose que le monde devrait savoir ? Écrivez un cours.
              </h3>
              <p className="mt-5 font-serif text-[19px] leading-relaxed text-ink-2">
                Vous écrivez dans votre langue, dans un éditeur qui vous guide. Sophia relit, traduit en{" "}
                {site.stats.languages} langues, met en voix et publie. Vous suivez vos lectures et recevez chaque mois
                une part des revenus Premium, selon le temps que les abonnés passent sur vos cours.
              </p>
              <ol className="mt-7 grid gap-x-6 gap-y-5 sm:grid-cols-2">
                {steps.map((s, i) => (
                  <motion.li
                    key={s.title}
                    initial={{ x: -12 }}
                    whileInView={{ x: 0 }}
                    viewport={{ once: true }}
                    transition={{ delay: i * 0.1, type: "spring", stiffness: 160, damping: 18 }}
                    className="flex gap-3"
                  >
                    <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-navy text-[13px] font-bold text-white">
                      {i + 1}
                    </span>
                    <p className="text-[15px] leading-snug text-ink-2">
                      <strong className="text-ink">{s.title}</strong> : {s.text}
                    </p>
                  </motion.li>
                ))}
              </ol>
              <div className="mt-8 flex flex-wrap gap-3">
                <Button href={links.writeForUs}>
                  Devenir auteur <Arrow />
                </Button>
              </div>
            </div>
          </div>
        </Rise>
      </div>
    </section>
  );
}
