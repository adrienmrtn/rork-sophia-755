"use client";

import Image from "next/image";
import { useState } from "react";
import { site, links } from "@/lib/site";
import { Button } from "./ui";

const style: Record<string, { tone: string; emoji: string }> = {
  histoire: { tone: "bg-peach", emoji: "📜" },
  sciences: { tone: "bg-sky", emoji: "🔬" },
  comprendreLeMonde: { tone: "bg-mint", emoji: "🌍" },
  litterature: { tone: "bg-violet-soft", emoji: "📚" },
  mythologie: { tone: "bg-saffron", emoji: "🏛️" },
  art: { tone: "bg-pink-soft", emoji: "🎨" },
};

export function SubjectExplorer() {
  const [active, setActive] = useState(site.subjects[0].id);
  const subject = site.subjects.find((s) => s.id === active) ?? site.subjects[0];
  const s = style[subject.id];

  return (
    <section id="cours" className="scroll-mt-20 border-b-[3px] border-ink bg-cream py-20 sm:py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="text-center">
          <h2 className="font-display text-4xl font-extrabold tracking-tight sm:text-5xl">
            {site.stats.courses} cours, 6 matières, 0 manuel
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-lg text-ink-soft">
            Choisis une matière et découvre quelques cours parmi ceux que lisent nos utilisateurs.
          </p>
        </div>

        <div className="mt-10 flex flex-wrap justify-center gap-3" role="tablist" aria-label="Matières">
          {site.subjects.map((sub) => {
            const selected = sub.id === active;
            return (
              <button
                key={sub.id}
                type="button"
                role="tab"
                aria-selected={selected}
                aria-controls="matiere-panel"
                onClick={() => setActive(sub.id)}
                className={`brutal-sm rounded-full px-4 py-2 font-display text-base font-bold transition-all ${
                  style[sub.id].tone
                } ${selected ? "-translate-y-0.5 shadow-[5px_5px_0_0_var(--color-ink)] ring-4 ring-ink/10" : "opacity-80 hover:opacity-100"}`}
              >
                <span aria-hidden>{style[sub.id].emoji}</span> {sub.label}
                <span className="ml-2 rounded-full bg-ink px-2 py-0.5 text-xs text-cream">{sub.count}</span>
              </button>
            );
          })}
        </div>

        <div
          id="matiere-panel"
          role="tabpanel"
          key={subject.id}
          className={`brutal-lg mt-10 grid gap-6 rounded-[32px] ${s.tone} p-5 sm:p-8 lg:grid-cols-[0.8fr_2fr]`}
        >
          <div className="flex flex-col justify-between gap-6">
            <div>
              <span className="inline-flex items-center gap-2 rounded-full bg-ink px-3 py-1 text-sm font-bold text-cream">
                {s.emoji} {subject.label}
              </span>
              <p className="mt-5 font-display text-6xl font-extrabold">{subject.count}</p>
              <p className="font-semibold text-ink-soft">cours dans cette matière</p>
            </div>
            <Button href={links.appStore} tone="cream" className="self-start">
              Lire le premier cours
            </Button>
          </div>

          <ol className="grid gap-4 sm:grid-cols-2">
            {subject.courses.map((c, i) => (
              <li
                key={c.id}
                className="brutal group flex overflow-hidden rounded-2xl bg-paper transition-transform duration-200 hover:-translate-y-1"
                style={{ animation: `fadein 400ms ${i * 70}ms both` }}
              >
                <div className="relative w-[38%] shrink-0 overflow-hidden border-r-[2.5px] border-ink">
                  <Image
                    src={c.image}
                    alt=""
                    fill
                    sizes="(max-width: 640px) 35vw, 200px"
                    className="object-cover transition-transform duration-500 group-hover:scale-110"
                  />
                  <span className="absolute left-2 top-2 flex h-6 w-6 items-center justify-center rounded-full border-2 border-ink bg-paper text-xs font-bold">
                    {i + 1}
                  </span>
                </div>
                <div className="flex flex-col justify-center p-4">
                  <p className="font-display text-base font-bold leading-snug">{c.title}</p>
                  <p className="mt-1.5 line-clamp-2 text-sm text-ink-soft">{c.hook}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </div>
      <style>{`@keyframes fadein{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}`}</style>
    </section>
  );
}
