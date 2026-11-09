"use client";

import Image from "next/image";
import { useState } from "react";
import { site, links } from "@/lib/site";
import { Button, Flower, Starburst } from "./ui";

export function QuizDemo() {
  const total = site.quiz.length;
  const [index, setIndex] = useState(0);
  const [picked, setPicked] = useState<number | null>(null);
  const [score, setScore] = useState(0);
  const done = index >= total;
  const q = site.quiz[Math.min(index, total - 1)];

  function choose(i: number) {
    if (picked !== null) return;
    setPicked(i);
    if (i === q.correctIndex) setScore((s) => s + 1);
  }

  function next() {
    setPicked(null);
    setIndex((i) => i + 1);
  }

  function restart() {
    setPicked(null);
    setScore(0);
    setIndex(0);
  }

  return (
    <section className="relative overflow-hidden border-b-[3px] border-ink bg-saffron py-20 sm:py-24">
      <Flower className="absolute -right-8 top-10 hidden h-32 w-32 animate-spin-slow md:block" fill="var(--color-violet-soft)" />
      <Starburst className="absolute -left-6 bottom-10 hidden h-24 w-24 animate-spin-slow md:block" fill="var(--color-pink)" />

      <div className="relative mx-auto max-w-3xl px-4 sm:px-6">
        <div className="text-center">
          <h2 className="font-display text-4xl font-extrabold tracking-tight sm:text-5xl">Teste ta culture G</h2>
          <p className="mt-3 text-lg font-medium text-ink/80">
            {total} vraies questions tirées des quiz de l&apos;app. Combien vas-tu en avoir ?
          </p>
        </div>

        <div className="brutal-lg mt-10 overflow-hidden rounded-[32px] bg-paper">
          {!done ? (
            <>
              <div className="flex items-center gap-4 border-b-[2.5px] border-ink bg-cream p-4 sm:p-5">
                <div className="relative h-14 w-14 shrink-0 overflow-hidden rounded-xl border-2 border-ink">
                  <Image src={q.image} alt="" fill sizes="56px" className="object-cover" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-xs font-bold uppercase tracking-widest text-violet">Tiré du cours</p>
                  <p className="truncate font-semibold">{q.course}</p>
                </div>
                <span className="rounded-full border-2 border-ink bg-saffron-soft px-3 py-1 text-sm font-bold">
                  {index + 1}/{total}
                </span>
              </div>

              <div className="p-5 sm:p-8">
                <p className="font-display text-2xl font-bold leading-snug sm:text-[28px]">{q.question}</p>
                <div className="mt-6 grid gap-3 sm:grid-cols-2">
                  {q.options.map((o, i) => {
                    const isCorrect = i === q.correctIndex;
                    const state =
                      picked === null
                        ? "bg-paper hover:-translate-y-0.5 hover:bg-violet-soft"
                        : isCorrect
                          ? "bg-mint"
                          : i === picked
                            ? "bg-pink"
                            : "bg-paper opacity-50";
                    return (
                      <button
                        key={o}
                        type="button"
                        onClick={() => choose(i)}
                        disabled={picked !== null}
                        className={`brutal-sm flex items-center gap-3 rounded-2xl px-4 py-3.5 text-left font-semibold transition-all ${state}`}
                      >
                        <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full border-2 border-ink bg-cream text-sm font-bold">
                          {picked !== null && isCorrect ? "✓" : picked === i ? "✗" : String.fromCharCode(65 + i)}
                        </span>
                        {o}
                      </button>
                    );
                  })}
                </div>

                {picked !== null && (
                  <div className="mt-6 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between" aria-live="polite">
                    <p className="max-w-lg text-ink-soft">
                      <strong className="text-ink">{picked === q.correctIndex ? "Bien joué ! " : "Raté, mais maintenant tu sais : "}</strong>
                      {q.explanation}
                    </p>
                    <button
                      type="button"
                      onClick={next}
                      className="brutal press shrink-0 rounded-full bg-violet px-6 py-3 font-display font-bold text-white"
                    >
                      {index + 1 < total ? "Question suivante →" : "Voir mon score"}
                    </button>
                  </div>
                )}
              </div>
            </>
          ) : (
            <div className="p-8 text-center sm:p-12">
              <p className="text-6xl" aria-hidden>
                {score >= total - 1 ? "🏆" : score >= total / 2 ? "🔥" : "🌱"}
              </p>
              <p className="mt-4 font-display text-5xl font-extrabold">
                {score}/{total}
              </p>
              <p className="mx-auto mt-3 max-w-md text-lg text-ink-soft">
                {score >= total - 1
                  ? "Impressionnant. Viens le prouver sur les 300 autres cours."
                  : score >= total / 2
                    ? "Pas mal du tout ! Dix minutes par jour et tu feras un sans-faute."
                    : "Tout le monde commence quelque part. Ton premier cours t'attend."}
              </p>
              <div className="mt-8 flex flex-wrap justify-center gap-3">
                <Button href={links.appStore} tone="pink" size="lg">
                  Continuer dans l&apos;app
                </Button>
                <button type="button" onClick={restart} className="brutal press rounded-full bg-paper px-6 py-3 font-display font-bold">
                  Recommencer
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
