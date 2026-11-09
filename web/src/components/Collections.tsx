"use client";

import Image from "next/image";
import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";
import { site } from "@/lib/site";
import { Rise } from "./ui";

type Col = (typeof site.collections)[number];

function Card({ c }: { c: Col }) {
  return (
    <motion.article
      whileHover={{ y: -6 }}
      transition={{ type: "spring", stiffness: 300, damping: 22 }}
      className="group w-[300px] shrink-0 overflow-hidden rounded-[20px] bg-paper ring-1 ring-line sm:w-[340px]"
    >
      <div className="relative aspect-[16/9] overflow-hidden">
        <Image src={c.image} alt="" fill sizes="340px" className="object-cover transition-transform duration-700 group-hover:scale-105" />
      </div>
      <div className="p-5">
        <p className="text-[12px] font-bold uppercase tracking-wider text-ink-3">Collection · {c.count} cours</p>
        <h3 className="mt-1.5 text-[18px] font-extrabold leading-snug tracking-tight">{c.title}</h3>
        <p className="mt-1.5 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2">{c.description}</p>
      </div>
    </motion.article>
  );
}

/** Deux rangées qui glissent en sens opposé au rythme du défilement. */
export function Collections() {
  const ref = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });
  const left = useTransform(scrollYProgress, [0, 1], ["0%", "-28%"]);
  const right = useTransform(scrollYProgress, [0, 1], ["-28%", "0%"]);
  const half = Math.ceil(site.collections.length / 2);

  return (
    <section ref={ref} className="overflow-hidden bg-paper py-20 sm:py-28">
      <Rise className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="flex flex-wrap items-end justify-between gap-6">
          <div className="max-w-2xl">
            <p className="eyebrow">Les collections</p>
            <h2 className="mt-4 text-4xl font-extrabold leading-[1.08] tracking-[-0.03em] sm:text-5xl">
              {site.stats.collections} parcours pour aller plus loin
            </h2>
          </div>
          <p className="max-w-sm font-serif text-xl leading-relaxed text-ink-2">
            Des pyramides à Gengis Khan, de Gilgamesh à Superman : des séries de cours qui relient les époques et
            les disciplines.
          </p>
        </div>
      </Rise>
      <div className="mt-14 space-y-6">
        <motion.div style={{ x: left }} className="flex gap-6 pl-4 sm:pl-6">
          {site.collections.slice(0, half).map((c) => (
            <Card key={c.id} c={c} />
          ))}
        </motion.div>
        <motion.div style={{ x: right }} className="flex gap-6 pl-4 sm:pl-6">
          {site.collections.slice(half).map((c) => (
            <Card key={c.id} c={c} />
          ))}
        </motion.div>
      </div>
    </section>
  );
}
