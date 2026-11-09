"use client";

import Image from "next/image";
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { showcase } from "@/lib/showcase";
import { Arrow, Button } from "./ui";

const confettiColors = ["#f2b134", "#e05a3a", "#1a3a6b", "#387d5a", "#2e62c4"];

function Burst() {
  const pieces = Array.from({ length: 18 }, (_, i) => {
    const angle = (Math.PI * 2 * i) / 18 + (i % 2) * 0.2;
    const dist = 70 + (i % 3) * 30;
    return { x: Math.cos(angle) * dist, y: Math.sin(angle) * dist, c: confettiColors[i % confettiColors.length], r: i * 40 };
  });
  return (
    <span className="pointer-events-none absolute left-1/2 top-1/2" aria-hidden>
      {pieces.map((p, i) => (
        <motion.span
          key={i}
          className="absolute h-2.5 w-1.5 rounded-sm"
          style={{ backgroundColor: p.c }}
          initial={{ x: 0, y: 0, opacity: 1, rotate: 0, scale: 1 }}
          animate={{ x: p.x, y: p.y + 30, opacity: 0, rotate: p.r, scale: 0.6 }}
          transition={{ duration: 0.9, ease: [0.2, 0.8, 0.2, 1] }}
        />
      ))}
    </span>
  );
}

export function QuizDemo() {
  const total = showcase.quiz.length;
  const [index, setIndex] = useState(0);
  const [picked, setPicked] = useState<number | null>(null);
  const [score, setScore] = useState(0);
  const done = index >= total;
  const q = showcase.quiz[Math.min(index, total - 1)];

  function choose(i: number) {
    if (picked !== null) return;
    setPicked(i);
    if (i === q.correctIndex) setScore((s) => s + 1);
  }

  return (
    <section className="bg-cream py-20 sm:py-28">
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <div className="text-center">
          <p className="eyebrow">À vous de jouer</p>
          <h2 className="mt-4 text-4xl font-extrabold tracking-[-0.03em] sm:text-5xl">Testez votre culture générale</h2>
          <p className="mx-auto mt-4 max-w-xl font-serif text-xl text-ink-2">
            {total} questions tirées des quiz de l&apos;app. Combien en aurez-vous ?
          </p>
        </div>

        <div className="mt-10 overflow-hidden rounded-[28px] bg-paper shadow-[0_40px_80px_-40px_rgba(22,38,61,0.4)] ring-1 ring-line">
          <div className="h-1.5 bg-sand">
            <motion.div className="h-full bg-saffron" animate={{ width: `${(Math.min(index + (picked !== null ? 1 : 0), total) / total) * 100}%` }} transition={{ type: "spring", stiffness: 120, damping: 20 }} />
          </div>
          <AnimatePresence mode="wait" initial={false}>
            {!done ? (
              <motion.div key={index} initial={{ opacity: 0, x: 40 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -40 }} transition={{ type: "spring", stiffness: 260, damping: 28 }}>
                <div className="flex items-center gap-4 border-b border-line p-5 sm:px-8">
                  <div className="relative h-12 w-16 shrink-0 overflow-hidden rounded-lg">
                    <Image src={q.image} alt="" fill sizes="64px" className="object-cover" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[12px] font-bold uppercase tracking-wider text-ink-3">Tiré du cours</p>
                    <p className="truncate text-[15px] font-semibold">{q.course}</p>
                  </div>
                  <span className="tabular-nums text-sm font-bold text-ink-2">
                    {index + 1}/{total}
                  </span>
                </div>

                <div className="p-5 sm:p-8">
                  <p className="text-[24px] font-extrabold leading-snug tracking-tight sm:text-[28px]">{q.question}</p>
                  <div className="mt-6 grid gap-3 sm:grid-cols-2">
                    {q.options.map((o, i) => {
                      const isCorrect = i === q.correctIndex;
                      const isPicked = picked === i;
                      const tone =
                        picked === null
                          ? "bg-paper ring-line hover:ring-navy/40 hover:bg-cream"
                          : isCorrect
                            ? "bg-sage-soft ring-sage/40"
                            : isPicked
                              ? "bg-coral-soft ring-coral/40"
                              : "bg-paper ring-line opacity-50";
                      return (
                        <motion.button
                          key={o}
                          type="button"
                          onClick={() => choose(i)}
                          disabled={picked !== null}
                          whileHover={picked === null ? { y: -2 } : undefined}
                          whileTap={picked === null ? { scale: 0.98 } : undefined}
                          animate={isPicked && !isCorrect ? { x: [0, -8, 8, -5, 5, 0] } : isCorrect && picked !== null ? { scale: [1, 1.04, 1] } : {}}
                          transition={{ duration: 0.45 }}
                          className={`relative flex items-center gap-3 rounded-2xl px-4 py-4 text-left text-[15px] font-semibold ring-1 transition-colors ${tone}`}
                        >
                          <span
                            className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-bold ${
                              picked !== null && isCorrect ? "bg-sage text-white" : isPicked ? "bg-coral text-white" : "bg-sand text-ink-2"
                            }`}
                          >
                            {picked !== null && isCorrect ? "✓" : isPicked ? "✕" : String.fromCharCode(65 + i)}
                          </span>
                          {o}
                          {isPicked && isCorrect && <Burst />}
                        </motion.button>
                      );
                    })}
                  </div>

                  <AnimatePresence>
                    {picked !== null && (
                      <motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: "auto" }}
                        className="overflow-hidden"
                        aria-live="polite"
                      >
                        <div className="flex flex-col gap-4 pt-6 sm:flex-row sm:items-end sm:justify-between">
                          <p className="max-w-lg font-serif text-[18px] leading-snug text-ink-2">
                            <strong className="font-sans text-ink">{picked === q.correctIndex ? "Bien vu. " : "Pas cette fois. "}</strong>
                            {q.explanation}
                          </p>
                          <motion.button
                            type="button"
                            whileHover={{ y: -2 }}
                            whileTap={{ scale: 0.97 }}
                            onClick={() => {
                              setPicked(null);
                              setIndex((n) => n + 1);
                            }}
                            className="inline-flex h-12 shrink-0 items-center gap-2 rounded-xl bg-navy px-5 font-bold text-white"
                          >
                            {index + 1 < total ? "Question suivante" : "Voir mon score"} <Arrow />
                          </motion.button>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </motion.div>
            ) : (
              <motion.div key="score" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="p-8 text-center sm:p-12">
                <motion.p className="text-6xl" initial={{ rotate: -20, scale: 0 }} animate={{ rotate: 0, scale: 1 }} transition={{ type: "spring", stiffness: 260, damping: 12 }} aria-hidden>
                  {score >= total - 1 ? "🏆" : score >= total / 2 ? "🔥" : "🌱"}
                </motion.p>
                <p className="mt-4 text-6xl font-extrabold tracking-tight text-navy">
                  {score}/{total}
                </p>
                <p className="mx-auto mt-3 max-w-md font-serif text-xl text-ink-2">
                  {score >= total - 1
                    ? "Impressionnant. Il reste 300 cours pour le confirmer."
                    : score >= total / 2
                      ? "Pas mal du tout. Dix minutes par jour et ce sera un sans-faute."
                      : "Tout le monde commence quelque part. Votre premier cours vous attend."}
                </p>
                <div className="mt-8 flex flex-wrap justify-center gap-3">
                  <Button href="/commencer" size="lg">
                    Continuer dans l&apos;app <Arrow />
                  </Button>
                  <motion.button
                    type="button"
                    whileTap={{ scale: 0.97 }}
                    onClick={() => {
                      setScore(0);
                      setPicked(null);
                      setIndex(0);
                    }}
                    className="h-14 rounded-xl px-6 font-bold text-navy ring-1 ring-line hover:bg-cream"
                  >
                    Recommencer
                  </motion.button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </section>
  );
}
