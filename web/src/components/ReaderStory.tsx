"use client";

import Image from "next/image";
import {
  AnimatePresence,
  motion,
  useMotionValueEvent,
  useScroll,
  useTransform,
  type MotionValue,
} from "motion/react";
import { useRef, useState } from "react";
import { site } from "@/lib/site";
import { RichText } from "./RichText";
import { Avatar } from "./ui";

const r = site.reader;

const steps = [
  {
    tag: "Lire",
    title: "Dix minutes, une histoire complète",
    text: "Chaque cours part d'une question et la déroule en cinq parties courtes. On le lit d'une traite, dans le métro ou avant de dormir, et on en ressort avec une histoire à raconter.",
  },
  {
    tag: "Retenir",
    title: "Un quiz pour que ça reste",
    text: "À la fin, un quiz vérifie ce que vous avez retenu. Les questions reviennent ensuite au bon moment, selon la répétition espacée, pour ancrer le cours sur le long terme.",
  },
  {
    tag: "Revenir",
    title: "Une habitude qui tient",
    text: "Série de jours, XP, niveaux : la progression se voit. Et si vous le voulez, vos apps les plus prenantes restent bloquées jusqu'au cours du jour.",
  },
];

/* ---------- Les trois écrans, animés par une progression 0 → 1 ---------- */

function ArticlePane({ p }: { p: MotionValue<number> }) {
  const read = useTransform(p, [0, 1], ["4%", "100%"]);
  const textY = useTransform(p, [0, 1], [0, -90]);
  return (
    <div className="flex h-full flex-col">
      <div className="relative aspect-[16/8] shrink-0">
        <Image src={r.image} alt="" fill sizes="480px" className="object-cover" />
        <div className="absolute inset-x-0 bottom-0 h-1 bg-ink/10">
          <motion.div className="h-full bg-saffron" style={{ width: read }} />
        </div>
      </div>
      <div className="relative min-h-0 flex-1 overflow-hidden px-6 pt-5 sm:px-7">
        <motion.div style={{ y: textY }}>
          <p className="eyebrow">{r.subject} · Introduction</p>
          <h3 className="mt-2 text-[22px] font-extrabold leading-tight tracking-tight">{r.title}</h3>
          <div className="mt-3 flex items-center gap-2.5 text-[13px] text-ink-2">
            <Avatar author={r.author} size={30} />
            <span>
              <strong className="block text-ink">{r.author.name}</strong>
              <span className="line-clamp-1">{r.author.title}</span>
            </span>
          </div>
          <div className="mt-5 space-y-4 font-serif text-[17px] leading-[1.6] text-ink-2">
            {r.paragraphs.map((t, i) => (
              <p key={i} className={i === 0 ? "drop-cap" : ""}>
                <RichText text={t} />
              </p>
            ))}
          </div>
        </motion.div>
        <div className="pointer-events-none absolute inset-x-0 bottom-0 h-20 bg-gradient-to-t from-paper to-transparent" />
      </div>
      <div className="flex shrink-0 gap-1.5 border-t border-line px-6 py-4">
        {r.sections.map((s, i) => (
          <SectionTick key={s} p={p} i={i} n={r.sections.length} label={s} />
        ))}
      </div>
    </div>
  );
}

function SectionTick({ p, i, n, label }: { p: MotionValue<number>; i: number; n: number; label: string }) {
  const fill = useTransform(p, [i / n, (i + 1) / n], ["0%", "100%"]);
  return (
    <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-sand" title={label}>
      <motion.div className="h-full rounded-full bg-navy" style={{ width: fill }} />
    </div>
  );
}

function QuizPane({ p }: { p: MotionValue<number> }) {
  const q = r.quiz;
  const [revealed, setRevealed] = useState(false);
  useMotionValueEvent(p, "change", (v) => setRevealed(v > 0.45));
  return (
    <div className="flex h-full flex-col bg-cream p-6 sm:p-7">
      <div className="flex items-center justify-between text-[13px] font-bold">
        <span className="rounded-full bg-paper px-3 py-1 ring-1 ring-line">Quiz · 1/{site.reader.quizCount}</span>
        <span className="rounded-full bg-saffron-soft px-3 py-1 text-navy">Révision dans 3 jours</span>
      </div>
      <p className="mt-6 text-[22px] font-extrabold leading-snug tracking-tight">{q.question}</p>
      <div className="mt-6 space-y-2.5">
        {q.options.map((o, i) => {
          const correct = i === q.correctIndex;
          return (
            <motion.div
              key={o}
              animate={
                revealed && correct
                  ? { scale: [1, 1.03, 1], backgroundColor: "var(--color-sage-soft)" }
                  : { scale: 1, backgroundColor: "var(--color-paper)", opacity: revealed ? 0.55 : 1 }
              }
              transition={{ duration: 0.45 }}
              className="flex items-center gap-3 rounded-2xl px-4 py-3.5 text-[15px] font-semibold ring-1 ring-line"
            >
              <span
                className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[13px] font-bold transition-colors ${
                  revealed && correct ? "bg-sage text-white" : "bg-sand text-ink-2"
                }`}
              >
                {revealed && correct ? "✓" : String.fromCharCode(65 + i)}
              </span>
              {o}
            </motion.div>
          );
        })}
      </div>
      <AnimatePresence>
        {revealed && (
          <motion.p
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            className="mt-auto rounded-2xl bg-paper p-4 font-serif text-[16px] leading-snug text-ink-2 ring-1 ring-line"
          >
            <strong className="font-sans text-sage">Bonne réponse.</strong> Cette question reviendra dans
            trois jours, puis dans une semaine.
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  );
}

function StreakPane({ p }: { p: MotionValue<number> }) {
  const days = ["L", "M", "M", "J", "V", "S", "D"];
  const [done, setDone] = useState(0);
  useMotionValueEvent(p, "change", (v) => setDone(Math.min(7, Math.max(0, Math.round(v * 8)))));
  const xp = useTransform(p, [0, 1], ["35%", "92%"]);
  return (
    <div className="flex h-full flex-col justify-center bg-navy p-7 text-white">
      <div className="flex items-center gap-4">
        <motion.span
          className="text-5xl"
          animate={{ scale: [1, 1.12, 1], rotate: [0, -4, 4, 0] }}
          transition={{ duration: 1.6, repeat: Infinity, ease: "easeInOut" }}
          aria-hidden
        >
          🔥
        </motion.span>
        <div>
          <p className="text-[40px] font-extrabold leading-none tracking-tight">
            <span className="tabular-nums">{5 + done}</span> jours
          </p>
          <p className="mt-1 font-semibold text-white/70">de série en cours</p>
        </div>
      </div>
      <div className="mt-8 grid grid-cols-7 gap-2">
        {days.map((d, i) => (
          <div key={i} className="text-center">
            <motion.div
              animate={i < done ? { backgroundColor: "#f2b134", scale: [0.8, 1.1, 1] } : { backgroundColor: "rgba(255,255,255,0.1)", scale: 1 }}
              transition={{ duration: 0.35 }}
              className="mx-auto flex aspect-square w-full items-center justify-center rounded-xl text-sm font-bold text-navy"
            >
              {i < done ? "✓" : ""}
            </motion.div>
            <span className="mt-1.5 block text-xs font-bold text-white/60">{d}</span>
          </div>
        ))}
      </div>
      <div className="mt-8">
        <div className="mb-2 flex justify-between text-sm font-bold">
          <span>Niveau 7</span>
          <span className="text-white/70">vers le niveau 8</span>
        </div>
        <div className="h-3 overflow-hidden rounded-full bg-white/10">
          <motion.div className="h-full rounded-full bg-coral" style={{ width: xp }} />
        </div>
      </div>
    </div>
  );
}

const panes = [ArticlePane, QuizPane, StreakPane];

/* ---------- Version bureau : récit au défilement, écran collant ---------- */

function StickyStory() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end end"] });
  const [step, setStep] = useState(0);
  useMotionValueEvent(scrollYProgress, "change", (v) => setStep(Math.min(2, Math.floor(v * 3))));
  const local = useTransform(scrollYProgress, (v) => Math.min(1, Math.max(0, v * 3 - step)));
  const bar = useTransform(local, [0, 1], ["0%", "100%"]);
  const Pane = panes[step];

  return (
    <div ref={ref} className="relative hidden h-[300vh] lg:block">
      <div className="sticky top-16 flex h-[calc(100vh-4rem)] items-center">
        <div className="mx-auto grid w-full max-w-6xl grid-cols-[1fr_440px] items-center gap-20 px-6">
          <div>
            <p className="eyebrow">La méthode</p>
            <h2 className="mt-4 max-w-lg text-5xl font-extrabold leading-[1.06] tracking-[-0.03em]">
              Lire, retenir, revenir le lendemain
            </h2>
            <ol className="mt-10 space-y-2">
              {steps.map((s, i) => (
                <li key={s.tag}>
                  <motion.div
                    animate={{ opacity: i === step ? 1 : 0.4 }}
                    className="relative rounded-2xl py-4 pl-6 pr-4"
                  >
                    <div className="absolute bottom-3 left-0 top-3 w-[3px] overflow-hidden rounded-full bg-line">
                      {i === step && <motion.div className="w-full rounded-full bg-saffron" style={{ height: bar }} />}
                      {i < step && <div className="h-full w-full bg-saffron" />}
                    </div>
                    <p className="text-[13px] font-bold uppercase tracking-[0.14em] text-sky">
                      {i + 1}. {s.tag}
                    </p>
                    <p className="mt-1 text-2xl font-extrabold tracking-tight">{s.title}</p>
                    <AnimatePresence initial={false}>
                      {i === step && (
                        <motion.p
                          initial={{ height: 0, opacity: 0 }}
                          animate={{ height: "auto", opacity: 1 }}
                          exit={{ height: 0, opacity: 0 }}
                          transition={{ type: "spring", stiffness: 200, damping: 28 }}
                          className="overflow-hidden font-serif text-[19px] leading-relaxed text-ink-2"
                        >
                          <span className="block pt-2">{s.text}</span>
                        </motion.p>
                      )}
                    </AnimatePresence>
                  </motion.div>
                </li>
              ))}
            </ol>
          </div>

          <div className="relative h-[min(640px,calc(100vh-8rem))]">
            <motion.div
              className="absolute -inset-6 -z-10 rounded-[44px]"
              animate={{ backgroundColor: ["#fde9bd", "#e0ede5", "#fbdcd3"][step], rotate: [-2, 2, -1][step] }}
              transition={{ type: "spring", stiffness: 80, damping: 20 }}
            />
            <div className="h-full overflow-hidden rounded-[28px] bg-paper shadow-[0_40px_80px_-40px_rgba(22,38,61,0.5)] ring-1 ring-line">
              <AnimatePresence mode="wait" initial={false}>
                <motion.div
                  key={step}
                  className="h-full"
                  initial={{ opacity: 0, y: 40, scale: 0.97 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: -40, scale: 0.97 }}
                  transition={{ type: "spring", stiffness: 220, damping: 26 }}
                >
                  <Pane p={local} />
                </motion.div>
              </AnimatePresence>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------- Version mobile : les trois écrans à la suite ---------- */

function MobileStep({ i }: { i: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 85%", "end 40%"] });
  const Pane = panes[i];
  const s = steps[i];
  return (
    <div ref={ref}>
      <p className="text-[13px] font-bold uppercase tracking-[0.14em] text-sky">
        {i + 1}. {s.tag}
      </p>
      <h3 className="mt-1 text-2xl font-extrabold tracking-tight">{s.title}</h3>
      <p className="mt-2 font-serif text-lg leading-relaxed text-ink-2">{s.text}</p>
      <div className="mt-6 h-[520px] overflow-hidden rounded-[24px] bg-paper shadow-[0_30px_60px_-30px_rgba(22,38,61,0.45)] ring-1 ring-line">
        <Pane p={scrollYProgress} />
      </div>
    </div>
  );
}

export function ReaderStory() {
  return (
    <section id="methode" className="scroll-mt-16 bg-paper">
      <StickyStory />
      <div className="px-4 py-20 sm:px-6 lg:hidden">
        <p className="eyebrow">La méthode</p>
        <h2 className="mt-4 text-4xl font-extrabold leading-[1.08] tracking-[-0.03em]">Lire, retenir, revenir le lendemain</h2>
        <div className="mt-12 space-y-16">
          {steps.map((s, i) => (
            <MobileStep key={s.tag} i={i} />
          ))}
        </div>
      </div>
    </section>
  );
}
