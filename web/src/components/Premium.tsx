"use client";

import Image from "next/image";
import { motion, useScroll, useTransform, type MotionValue } from "motion/react";
import { useRef } from "react";
import { site, links } from "@/lib/site";
import { Arrow, Button } from "./ui";

const perks = [
  `Les ${site.stats.courses} cours en entier`,
  "Quiz et glossaire",
  "Narration audio",
  "Le Parcours",
  `${site.stats.collections} collections`,
  "Bloqueur d'apps",
];

/** Encart Premium : un éventail de couvertures qui s'ouvre au défilement. */
export function Premium() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "center center"] });
  const spread = useTransform(scrollYProgress, [0, 1], [0, 1]);
  const covers = [site.subjects[5].courses[0], site.subjects[0].courses[2], site.subjects[4].courses[0], site.subjects[1].courses[4], site.subjects[3].courses[4]];

  return (
    <section id="premium" className="scroll-mt-16 bg-paper pb-20 sm:pb-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div ref={ref} className="relative grid items-center gap-12 overflow-hidden rounded-[32px] bg-navy-deep p-8 text-white sm:p-12 lg:grid-cols-[1.1fr_1fr] lg:p-16">
          <div className="relative z-10">
            <p className="eyebrow !text-saffron">Sophia Premium</p>
            <h2 className="mt-4 text-4xl font-extrabold leading-[1.06] tracking-[-0.03em] sm:text-5xl">
              Tous les cours, toutes les langues, sans publicité.
            </h2>
            <p className="mt-5 max-w-lg font-serif text-[19px] leading-relaxed text-white/80">
              L&apos;introduction de chaque cours est gratuite. Premium ouvre la suite : tous les cours, les quiz,
              la narration audio, le Parcours, et le bloqueur qui garde vos autres apps fermées jusqu&apos;au cours
              du jour. Trois jours d&apos;essai, l&apos;abonnement se prend dans l&apos;app.
            </p>
            <ul className="mt-7 grid max-w-lg grid-cols-2 gap-x-6 gap-y-3">
              {perks.map((p, i) => (
                <motion.li
                  key={p}
                  initial={{ x: -10 }}
                  whileInView={{ x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.07, type: "spring", stiffness: 200, damping: 18 }}
                  className="flex items-center gap-2.5 text-[15px] font-semibold"
                >
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-saffron text-[11px] font-black text-navy">✓</span>
                  {p}
                </motion.li>
              ))}
            </ul>
            <div className="mt-9">
              <Button href={links.appStore} variant="saffron" size="lg">
                Essayer 3 jours gratuits <Arrow />
              </Button>
            </div>
          </div>

          <div className="relative mx-auto h-[300px] w-full max-w-[420px] sm:h-[360px]">
            {covers.map((c, i) => {
              const offset = i - 2;
              return <FanCard key={c.id} image={c.image} title={c.title} offset={offset} spread={spread} />;
            })}
          </div>
        </div>
      </div>
    </section>
  );
}

function FanCard({ image, title, offset, spread }: { image: string; title: string; offset: number; spread: MotionValue<number> }) {
  const rotate = useTransform(spread, (s) => offset * 9 * s);
  const x = useTransform(spread, (s) => offset * 62 * s);
  const y = useTransform(spread, (s) => Math.abs(offset) * 16 * s);
  return (
    <motion.div
      style={{ rotate, x, y, zIndex: 10 - Math.abs(offset) }}
      whileHover={{ y: -18, scale: 1.04 }}
      className="absolute left-1/2 top-4 -ml-[90px] w-[180px] origin-bottom overflow-hidden rounded-2xl bg-paper shadow-2xl sm:-ml-[105px] sm:w-[210px]"
    >
      <div className="relative aspect-[4/5]">
        <Image src={image} alt="" fill sizes="210px" className="object-cover" />
        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-ink/85 to-transparent p-3 pt-10">
          <p className="line-clamp-2 text-[13px] font-bold leading-snug text-white">{title}</p>
        </div>
      </div>
    </motion.div>
  );
}
