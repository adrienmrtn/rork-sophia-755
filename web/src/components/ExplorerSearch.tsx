"use client";

import Image from "next/image";
import { AnimatePresence, motion } from "motion/react";
import { useMemo, useState } from "react";
import { IconSearch } from "./icons";

type Item = { slug: string; title: string; subject: string; author: string; image: string };

const norm = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

/** Recherche instantanée dans tout le catalogue (titres, matières, auteurs). */
export function ExplorerSearch({ items, suggestions }: { items: Item[]; suggestions: string[] }) {
  const [q, setQ] = useState("");
  const index = useMemo(() => items.map((it) => ({ it, key: norm(`${it.title} ${it.subject} ${it.author}`) })), [items]);
  const words = norm(q).split(/\s+/).filter(Boolean);
  const results = words.length ? index.filter(({ key }) => words.every((w) => key.includes(w))).map(({ it }) => it) : [];

  return (
    <div>
      <label htmlFor="recherche" className="sr-only">
        Rechercher un cours
      </label>
      <div className="relative">
        <IconSearch className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-ink-3" />
        <input
          id="recherche"
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Napoléon, trous noirs, Kafka, la Joconde…"
          autoComplete="off"
          className="h-14 w-full rounded-2xl bg-cream pl-12 pr-4 text-[16px] font-medium outline-none ring-1 ring-line transition focus:bg-paper focus:ring-2 focus:ring-navy"
        />
      </div>
      {!q && (
        <div className="mt-3 flex flex-wrap gap-2">
          {suggestions.map((s) => (
            <button key={s} type="button" onClick={() => setQ(s)} className="rounded-full bg-sand px-3 py-1.5 text-[13px] font-semibold text-ink-2 hover:text-ink">
              {s}
            </button>
          ))}
        </div>
      )}
      <AnimatePresence initial={false}>
        {q && (
          <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mt-4 overflow-hidden rounded-2xl ring-1 ring-line" aria-live="polite">
            <p className="border-b border-line bg-cream/60 px-4 py-2.5 text-[13px] font-semibold text-ink-2">
              {results.length === 0 ? "Aucun cours ne correspond. Essayez un autre mot." : `${results.length} cours`}
            </p>
            <ul className="max-h-[420px] divide-y divide-line overflow-y-auto">
              {results.slice(0, 40).map((r) => (
                <li key={r.slug}>
                  <a href={`/cours/${r.slug}`} className="flex items-center gap-3 px-4 py-3 hover:bg-cream">
                    <span className="relative h-11 w-14 shrink-0 overflow-hidden rounded-lg">
                      <Image src={r.image} alt="" fill sizes="56px" className="object-cover" />
                    </span>
                    <span className="min-w-0">
                      <span className="line-clamp-1 text-[15px] font-bold">{r.title}</span>
                      <span className="text-[13px] text-ink-2">
                        {r.subject} · {r.author}
                      </span>
                    </span>
                  </a>
                </li>
              ))}
            </ul>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
