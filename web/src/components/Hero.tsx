"use client";

import Image from "next/image";
import { motion, useMotionValue, useSpring, useTransform } from "motion/react";
import { useEffect, useState } from "react";
import { site, links, type Course } from "@/lib/site";
import { Arrow, Avatar, Button, StoreBadges } from "./ui";

function PostCard({ c, priority = false }: { c: Course; priority?: boolean }) {
  return (
    <article className="overflow-hidden rounded-[22px] bg-paper shadow-[0_30px_60px_-30px_rgba(22,38,61,0.45),0_0_0_1px_rgba(22,38,61,0.06)]">
      <div className="relative aspect-[16/9]">
        <Image src={c.image} alt="" fill sizes="(max-width: 1024px) 90vw, 420px" className="object-cover" priority={priority} />
        <span className="absolute left-3 top-3 rounded-full bg-paper/95 px-2.5 py-1 text-[11px] font-bold text-navy backdrop-blur">
          {c.subject}
        </span>
      </div>
      <div className="p-5">
        <div className="flex items-center gap-2 text-[13px] text-ink-2">
          <Avatar author={c.author} size={24} />
          <span className="truncate font-semibold text-ink">{c.author.name}</span>
          <span aria-hidden>·</span>
          <span className="shrink-0">10 min</span>
        </div>
        <h3 className="mt-3 text-[19px] font-extrabold leading-snug tracking-tight">{c.title}</h3>
        <p className="mt-2 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2">{c.hook}</p>
        <div className="mt-4 flex items-center justify-between border-t border-line pt-3 text-[13px] font-semibold text-ink-2">
          <span>{c.quizCount} questions de quiz</span>
          <span className="inline-flex items-center gap-1 text-navy">
            Lire <Arrow className="h-3.5 w-3.5" />
          </span>
        </div>
      </div>
    </article>
  );
}

/** Pile de cours qui défile toute seule, comme un fil de publications. */
function HeroFeed() {
  const feed = site.heroFeed;
  const n = feed.length;
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    if (paused || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const t = setInterval(() => setIndex((i) => (i + 1) % n), 3400);
    return () => clearInterval(t);
  }, [paused, n]);

  return (
    <div
      className="relative mx-auto h-[480px] w-full max-w-[400px] sm:h-[520px]"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      aria-label="Exemples de cours"
    >
      {feed.map((c, i) => {
        const pos = (i - index + n) % n;
        const state =
          pos === 0
            ? { y: 0, scale: 1, rotate: 0, opacity: 1, zIndex: 30 }
            : pos === 1
              ? { y: 26, scale: 0.94, rotate: 3, opacity: 1, zIndex: 20 }
              : pos === 2
                ? { y: 50, scale: 0.88, rotate: -3, opacity: 0.9, zIndex: 10 }
                : pos === n - 1
                  ? { y: -70, scale: 1.02, rotate: -8, opacity: 0, zIndex: 40 }
                  : { y: 60, scale: 0.85, rotate: 0, opacity: 0, zIndex: 0 };
        return (
          <motion.div
            key={c.id}
            className="absolute inset-x-0 top-0"
            initial={false}
            animate={state}
            transition={{ type: "spring", stiffness: 120, damping: 20, mass: 0.9 }}
            aria-hidden={pos !== 0}
          >
            <PostCard c={c} priority={i < 2} />
          </motion.div>
        );
      })}
      <div className="absolute -bottom-2 left-1/2 flex -translate-x-1/2 gap-1.5" aria-hidden>
        {feed.map((c, i) => (
          <motion.span
            key={c.id}
            className="h-1.5 rounded-full bg-navy"
            animate={{ width: i === index ? 22 : 6, opacity: i === index ? 1 : 0.25 }}
          />
        ))}
      </div>
    </div>
  );
}

export function Hero() {
  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const sx = useSpring(mx, { stiffness: 60, damping: 18 });
  const sy = useSpring(my, { stiffness: 60, damping: 18 });
    const far = { x: useTransform(sx, (v) => v * -14), y: useTransform(sy, (v) => v * -14) };

  const covers = site.collections;
  const authors = site.creators.filter((c) => c.photo).slice(0, 5);

  return (
    <section
      className="relative overflow-hidden bg-cream"
      onMouseMove={(e) => {
        const r = e.currentTarget.getBoundingClientRect();
        mx.set((e.clientX - r.left) / r.width - 0.5);
        my.set((e.clientY - r.top) / r.height - 0.5);
      }}
    >
      {/* Couvertures de collections en arrière-plan, qui suivent la souris. */}
      <motion.div style={far} className="pointer-events-none absolute -left-10 top-24 hidden w-44 2xl:block" aria-hidden>
        <div className="animate-float overflow-hidden rounded-2xl opacity-80 shadow-xl" style={{ "--r": "-8deg" } as React.CSSProperties}>
          <Image src={covers[12].image} alt="" width={360} height={200} className="h-auto w-full" />
        </div>
      </motion.div>
      <motion.div style={far} className="pointer-events-none absolute -right-8 top-16 hidden w-40 2xl:block" aria-hidden>
        <div className="animate-float overflow-hidden rounded-2xl opacity-80 shadow-xl" style={{ "--r": "7deg", animationDelay: "-1.5s" } as React.CSSProperties}>
          <Image src={covers[5].image} alt="" width={320} height={180} className="h-auto w-full" />
        </div>
      </motion.div>

      <div className="relative mx-auto grid max-w-6xl items-center gap-14 px-4 pb-20 pt-12 sm:px-6 lg:grid-cols-[1.15fr_1fr] lg:pb-28 lg:pt-20">
        <div>
          <p className="fade-up inline-flex items-center gap-2 rounded-full bg-paper px-3 py-1.5 text-[13px] font-semibold text-ink-2 shadow-sm ring-1 ring-line" style={{ "--d": "0ms" } as React.CSSProperties}>
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-coral opacity-60" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-coral" />
            </span>
            Un nouveau cours chaque jour, signé par un spécialiste
          </p>

          <h1 className="mt-7 text-[44px] font-extrabold leading-[1.02] tracking-[-0.035em] text-ink sm:text-[64px] lg:text-[72px]">
            <span className="rise-line"><span style={{ "--d": "80ms" } as React.CSSProperties}>Moins de scroll,</span></span>
            <br />
            <span className="rise-line"><span style={{ "--d": "200ms" } as React.CSSProperties}>plus de</span></span>{" "}
            <span className="relative inline-block">
              <span className="rise-line"><span className="text-navy" style={{ "--d": "320ms" } as React.CSSProperties}>culture.</span></span>
              <svg className="draw absolute -bottom-2 left-0 h-4 w-full sm:-bottom-3 sm:h-5" viewBox="0 0 300 20" preserveAspectRatio="none" aria-hidden>
                <path d="M3 14C60 4 130 3 297 10" fill="none" stroke="var(--color-saffron)" strokeWidth="7" strokeLinecap="round" pathLength={1} />
              </svg>
            </span>
          </h1>

          <p className="fade-up mt-8 max-w-[34rem] font-serif text-[21px] leading-[1.5] text-ink-2 sm:text-[23px]" style={{ "--d": "500ms" } as React.CSSProperties}>
            Chaque jour, un cours de 10 minutes écrit par un historien, une médecin ou un philosophe. Un
            quiz pour retenir l&apos;essentiel. Et vos apps qui restent bloquées tant que vous n&apos;avez pas lu.
          </p>

          <div className="fade-up mt-9 flex flex-wrap items-center gap-3" style={{ "--d": "650ms" } as React.CSSProperties}>
            <Button href={links.appStore} size="lg">
              Lire mon premier cours <Arrow />
            </Button>
            <Button href="#fil" variant="secondary" size="lg">
              Voir les cours
            </Button>
          </div>

          <div className="fade-up mt-10 flex items-center gap-3" style={{ "--d": "800ms" } as React.CSSProperties}>
            <div className="flex -space-x-2.5">
              {authors.map((a) => (
                <Avatar key={a.name} author={a} size={38} />
              ))}
            </div>
            <p className="text-sm leading-snug text-ink-2">
              <strong className="text-ink">{site.stats.creators} auteurs</strong> venus d&apos;Oxford, de Boston,
              <br className="hidden sm:block" /> de Belgrade ou de l&apos;Académie slovaque des sciences
            </p>
          </div>
        </div>

        <div className="fade-up relative" style={{ "--d": "300ms" } as React.CSSProperties}>
          <HeroFeed />
          <motion.div
            initial={{ y: 30, opacity: 0, scale: 0.9 }}
            animate={{ y: 0, opacity: 1, scale: 1 }}
            transition={{ delay: 1.6, type: "spring", stiffness: 200, damping: 18 }}
            className="absolute -left-2 bottom-6 z-50 hidden w-[230px] items-center gap-3 rounded-2xl bg-paper p-3 shadow-[0_20px_40px_-15px_rgba(22,38,61,0.4)] ring-1 ring-line sm:flex lg:-left-16"
          >
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-saffron-soft text-lg" aria-hidden>
              🔥
            </span>
            <span className="text-[13px] leading-snug">
              <strong className="block">Série de 12 jours</strong>
              <span className="text-ink-2">Votre cours du jour est prêt</span>
            </span>
          </motion.div>
        </div>
      </div>

      <div className="relative border-y border-line bg-paper">
        <StoreStrip />
      </div>
    </section>
  );
}

function StoreStrip() {
  return (
    <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-4 py-5 sm:flex-row sm:px-6">
      <p className="text-center text-[15px] font-semibold text-ink-2 sm:text-left">
        Gratuit sur iPhone et Android, en {site.stats.languages} langues.
      </p>
      <StoreBadges />
    </div>
  );
}
