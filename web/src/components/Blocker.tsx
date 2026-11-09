"use client";

import { AnimatePresence, motion, useInView } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { Rise } from "./ui";

const apps = [
  { emoji: "🎵", label: "Vidéos courtes", tone: "bg-coral-soft" },
  { emoji: "📸", label: "Photos", tone: "bg-saffron-soft" },
  { emoji: "▶️", label: "Vidéos", tone: "bg-sage-soft" },
  { emoji: "💬", label: "Messages", tone: "bg-[#dde7f8]" },
  { emoji: "🧵", label: "Fil d'actu", tone: "bg-sand" },
  { emoji: "🎮", label: "Jeux", tone: "bg-coral-soft" },
];

type Phase = "free" | "locking" | "reading" | "unlocked";

/** Démo en boucle : les apps se verrouillent, le cours se lit, elles se libèrent. */
export function Blocker() {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { margin: "-20% 0px -20% 0px" });
  const [phase, setPhase] = useState<Phase>("free");

  useEffect(() => {
    if (!inView) return;
    const seq: [Phase, number][] = [
      ["free", 900],
      ["locking", 1500],
      ["reading", 3200],
      ["unlocked", 2200],
    ];
    let i = 0;
    let t: ReturnType<typeof setTimeout>;
    const tick = () => {
      setPhase(seq[i][0]);
      t = setTimeout(tick, seq[i][1]);
      i = (i + 1) % seq.length;
    };
    tick();
    return () => clearTimeout(t);
  }, [inView]);

  const locked = phase === "locking" || phase === "reading";

  return (
    <section className="overflow-hidden bg-navy py-20 text-white sm:py-28">
      <div className="mx-auto grid max-w-6xl items-center gap-14 px-4 sm:px-6 lg:grid-cols-2 lg:gap-20">
        <Rise>
          <p className="eyebrow !text-saffron">Le bloqueur d&apos;apps</p>
          <h2 className="mt-4 text-4xl font-extrabold leading-[1.06] tracking-[-0.03em] sm:text-[54px]">
            Vos apps attendent. Votre cours d&apos;abord.
          </h2>
          <p className="mt-6 max-w-lg font-serif text-xl leading-relaxed text-white/80">
            Choisissez les apps qui vous prennent le plus de temps. Sophia les verrouille jusqu&apos;à ce que
            le cours du jour soit lu, puis vous les rend. Dix minutes plus tard, vous retrouvez votre fil avec
            une histoire de plus en tête.
          </p>
          <figure className="mt-10 max-w-lg border-l-[3px] border-saffron pl-5">
            <blockquote className="font-serif text-[20px] italic leading-relaxed text-white/90">
              « Avant, je passais 7 h par jour sur mon téléphone. Aujourd&apos;hui 40 minutes avec Sophia, et je
              me sens plus intelligent chaque semaine. »
            </blockquote>
            <figcaption className="mt-3 text-sm font-bold text-saffron">Léa, 24 ans</figcaption>
          </figure>
        </Rise>

        <div ref={ref} className="relative mx-auto w-full max-w-[420px]">
          <div className="rounded-[36px] bg-white/[0.06] p-6 ring-1 ring-white/15 sm:p-8">
            <div className="grid grid-cols-3 gap-5">
              {apps.map((a, i) => (
                <div key={a.label} className="text-center">
                  <motion.div
                    animate={{ filter: locked ? "grayscale(1)" : "grayscale(0)", scale: phase === "unlocked" ? [1, 1.08, 1] : 1 }}
                    transition={{ delay: phase === "unlocked" ? i * 0.06 : 0, duration: 0.4 }}
                    className={`relative mx-auto flex aspect-square w-full items-center justify-center rounded-[22px] ${a.tone} text-[34px]`}
                  >
                    <motion.span animate={{ opacity: locked ? 0.35 : 1 }}>{a.emoji}</motion.span>
                    <AnimatePresence>
                      {locked && (
                        <motion.span
                          initial={{ y: -40, opacity: 0, rotate: -20 }}
                          animate={{ y: 0, opacity: 1, rotate: 0 }}
                          exit={{ y: -20, opacity: 0, scale: 1.4, rotate: 15 }}
                          transition={{ type: "spring", stiffness: 420, damping: 16, delay: phase === "locking" ? i * 0.12 : 0 }}
                          className="absolute -right-2 -top-2 flex h-9 w-9 items-center justify-center rounded-full bg-paper text-[15px] shadow-lg"
                        >
                          🔒
                        </motion.span>
                      )}
                    </AnimatePresence>
                  </motion.div>
                  <p className="mt-2 text-xs font-semibold text-white/60">{a.label}</p>
                </div>
              ))}
            </div>

            <div className="mt-8 h-[92px] rounded-2xl bg-paper p-4 text-ink">
              <AnimatePresence mode="wait" initial={false}>
                {phase === "unlocked" ? (
                  <motion.div key="ok" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
                    <p className="text-lg font-extrabold text-sage">Cours terminé, apps débloquées 🔓</p>
                    <p className="mt-1 text-sm font-semibold text-ink-2">À demain pour le prochain.</p>
                  </motion.div>
                ) : (
                  <motion.div key="read" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
                    <p className="text-lg font-extrabold">{locked ? "Encore un cours pour débloquer" : "Le cours du jour vous attend"}</p>
                    <div className="mt-3 h-2.5 overflow-hidden rounded-full bg-sand">
                      <motion.div
                        className="h-full rounded-full bg-saffron"
                        animate={{ width: phase === "reading" ? "100%" : phase === "locking" ? "8%" : "0%" }}
                        transition={{ duration: phase === "reading" ? 3 : 0.4, ease: "linear" }}
                      />
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
