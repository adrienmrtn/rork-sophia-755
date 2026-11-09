"use client";

import Image from "next/image";
import { site } from "@/lib/site";
import { Counter, Rise } from "./ui";

const figures = [
  { value: 500000, label: "lecteurs chaque mois" },
  { value: site.stats.courses, label: "cours publiés" },
  { value: site.stats.quizQuestions, label: "questions de quiz" },
  { value: site.stats.languages, label: "langues" },
];

export function Proof() {
  const logos = [...site.universities, ...site.universities, ...site.universities, ...site.universities];
  return (
    <section className="bg-paper py-16 sm:py-20">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <dl className="grid grid-cols-2 gap-y-10 sm:grid-cols-4">
          {figures.map((f, i) => (
            <Rise key={f.label} delay={i * 80} className={`px-2 sm:px-6 ${i > 0 ? "sm:border-l sm:border-line" : ""}`}>
              <dt className="sr-only">{f.label}</dt>
              <dd>
                <Counter value={f.value} className="block text-[34px] font-extrabold tracking-[-0.03em] text-navy sm:text-[44px]" />
                <span className="mt-1 block text-[15px] font-medium text-ink-2">{f.label}</span>
              </dd>
            </Rise>
          ))}
        </dl>
      </div>

      <div className="mt-16">
        <p className="eyebrow text-center !text-ink-3">Nos auteurs enseignent ou ont étudié à</p>
        <div className="group relative mt-6 flex overflow-hidden [mask-image:linear-gradient(to_right,transparent,black_12%,black_88%,transparent)]">
          <div className="flex shrink-0 animate-marquee items-center gap-16 pr-16" style={{ "--marquee-duration": "40s" } as React.CSSProperties}>
            {logos.map((u, i) => (
              <Image
                key={i}
                src={u}
                alt=""
                width={160}
                height={64}
                className="h-12 w-auto object-contain opacity-60 grayscale transition hover:opacity-100 hover:grayscale-0"
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
