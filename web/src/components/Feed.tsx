"use client";

import Image from "next/image";
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { site, links } from "@/lib/site";
import { Arrow, Avatar, Rise } from "./ui";

/** Le fil des cours, présenté comme une page de publication : onglets par matière, une ligne par cours. */
export function Feed() {
  const [active, setActive] = useState(site.subjects[0].id);
  const subject = site.subjects.find((s) => s.id === active) ?? site.subjects[0];

  return (
    <section id="fil" className="scroll-mt-16 bg-cream py-20 sm:py-28">
      <div className="mx-auto grid max-w-6xl gap-12 px-4 sm:px-6 lg:grid-cols-[1fr_1.7fr] lg:gap-14">
        <div className="lg:sticky lg:top-28 lg:self-start">
          <Rise>
            <p className="eyebrow">Le fil</p>
            <h2 className="mt-4 text-4xl font-extrabold leading-[1.08] tracking-[-0.03em] sm:text-5xl lg:text-[44px]">
              Des cours qu&apos;on lit comme une bonne newsletter
            </h2>
            <p className="mt-5 font-serif text-xl leading-relaxed text-ink-2">
              Une question, une histoire, les idées clés. {site.stats.courses} cours en six matières, chacun signé
              par la personne qui l&apos;a écrit.
            </p>
          </Rise>
        </div>

        <div className="min-w-0">
          <div className="-mx-4 overflow-x-auto px-4 pb-2 [scrollbar-width:none] sm:mx-0 sm:px-0 [&::-webkit-scrollbar]:hidden" role="tablist" aria-label="Matières">
            <div className="flex w-max gap-1 rounded-2xl bg-sand p-1.5">
              {site.subjects.map((s) => {
                const selected = s.id === active;
                return (
                  <button
                    key={s.id}
                    type="button"
                    role="tab"
                    id={`tab-${s.id}`}
                    aria-selected={selected}
                    aria-controls="fil-panel"
                    onClick={() => setActive(s.id)}
                    className={`relative rounded-xl px-4 py-2.5 text-[15px] font-bold transition-colors ${selected ? "text-ink" : "text-ink-2 hover:text-ink"}`}
                  >
                    {selected && (
                      <motion.span
                        layoutId="tab-pill"
                        className="absolute inset-0 rounded-xl bg-paper shadow-sm"
                        transition={{ type: "spring", stiffness: 380, damping: 32 }}
                      />
                    )}
                    <span className="relative whitespace-nowrap">
                      {s.label} <span className="ml-1 text-[13px] font-semibold text-ink-3">{s.count}</span>
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          <div id="fil-panel" role="tabpanel" aria-labelledby={`tab-${subject.id}`} className="mt-6 overflow-hidden rounded-[24px] bg-paper ring-1 ring-line">
            <AnimatePresence mode="wait" initial={false}>
              <motion.ol key={subject.id} initial="out" animate="in" exit="out" variants={{ in: { transition: { staggerChildren: 0.06 } }, out: {} }}>
                {subject.courses.map((c, i) => (
                  <motion.li
                    key={c.id}
                    variants={{ out: { opacity: 0, y: 14 }, in: { opacity: 1, y: 0 } }}
                    transition={{ type: "spring", stiffness: 260, damping: 26 }}
                    className={i > 0 ? "border-t border-line" : ""}
                  >
                    <a href={links.appStore} target="_blank" rel="noopener" className="group flex gap-4 p-5 transition-colors hover:bg-cream/60 sm:gap-6 sm:p-6">
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2 text-[13px] text-ink-2">
                          <Avatar author={c.author} size={22} />
                          <span className="truncate font-semibold text-ink">{c.author.name}</span>
                        </div>
                        <h3 className="mt-2 text-[18px] font-extrabold leading-snug tracking-tight transition-colors group-hover:text-navy sm:text-[20px]">
                          {c.title}
                        </h3>
                        <p className="mt-1.5 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2 sm:text-[17px]">{c.hook}</p>
                        <p className="mt-3 flex flex-wrap items-center gap-x-2 text-[12px] font-bold uppercase tracking-wider text-ink-3">
                          <span>{c.subtitle || subject.label}</span>
                          <span aria-hidden>·</span>
                          <span>10 min</span>
                          <span aria-hidden>·</span>
                          <span>Quiz de {c.quizCount} questions</span>
                        </p>
                      </div>
                      <div className="relative aspect-[4/3] w-28 shrink-0 self-center overflow-hidden rounded-xl sm:w-44">
                        <Image src={c.image} alt="" fill sizes="(max-width: 640px) 112px, 176px" className="object-cover transition-transform duration-500 group-hover:scale-105" />
                      </div>
                    </a>
                  </motion.li>
                ))}
              </motion.ol>
            </AnimatePresence>
            <a href={links.appStore} target="_blank" rel="noopener" className="group flex items-center justify-between border-t border-line bg-cream/50 px-6 py-4 text-[15px] font-bold text-navy">
              Voir les {subject.count} cours de {subject.label.toLowerCase()} dans l&apos;app
              <Arrow className="h-4 w-4 transition-transform group-hover:translate-x-1" />
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
