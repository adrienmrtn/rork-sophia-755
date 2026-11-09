"use client";

import { AnimatePresence, motion } from "motion/react";
import { useEffect, useState } from "react";
import { IconBookmark, IconCheck, IconHeart, IconShare } from "./icons";

/** Lecture / écriture locale sans jamais casser la page (navigation privée, stockage bloqué). */
function useStored(key: string, initial: boolean) {
  const [v, setV] = useState(initial);
  useEffect(() => {
    try {
      const raw = localStorage.getItem(key);
      if (raw !== null) setV(raw === "1");
    } catch {}
  }, [key]);
  const set = (next: boolean) => {
    setV(next);
    try {
      localStorage.setItem(key, next ? "1" : "0");
    } catch {}
  };
  return [v, set] as const;
}

function Burst() {
  return (
    <span className="pointer-events-none absolute left-1/2 top-1/2" aria-hidden>
      {Array.from({ length: 8 }, (_, i) => {
        const a = (Math.PI * 2 * i) / 8;
        return (
          <motion.span
            key={i}
            className="absolute h-1.5 w-1.5 rounded-full bg-coral"
            initial={{ x: 0, y: 0, opacity: 1, scale: 1 }}
            animate={{ x: Math.cos(a) * 22, y: Math.sin(a) * 22, opacity: 0, scale: 0.4 }}
            transition={{ duration: 0.55, ease: "easeOut" }}
          />
        );
      })}
    </span>
  );
}

/** Barre d'actions d'un article : j'aime, enregistrer, partager. */
export function ActionBar({ slug, title }: { slug: string; title: string }) {
  const [liked, setLiked] = useStored(`like:${slug}`, false);
  const [saved, setSaved] = useStored(`save:${slug}`, false);
  const [copied, setCopied] = useState(false);
  const [burst, setBurst] = useState(0);

  async function share() {
    const url = window.location.href;
    try {
      if (navigator.share) {
        await navigator.share({ title, url });
        return;
      }
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {}
  }

  const btn = "relative inline-flex h-9 items-center gap-1.5 rounded-full px-3 text-[14px] font-semibold transition-colors";
  return (
    <div className="flex items-center gap-1 border-y border-line py-2">
      <motion.button
        type="button"
        whileTap={{ scale: 0.85 }}
        onClick={() => {
          setLiked(!liked);
          if (!liked) setBurst((b) => b + 1);
        }}
        aria-pressed={liked}
        className={`${btn} ${liked ? "text-coral" : "text-ink-2 hover:bg-cream"}`}
      >
        <motion.span key={String(liked)} initial={{ scale: 0.6 }} animate={{ scale: 1 }} transition={{ type: "spring", stiffness: 500, damping: 12 }}>
          <IconHeart className="h-5 w-5" filled={liked} />
        </motion.span>
        J&apos;aime
        {burst > 0 && liked && <Burst key={burst} />}
      </motion.button>
      <motion.button type="button" whileTap={{ scale: 0.85 }} onClick={() => setSaved(!saved)} aria-pressed={saved} className={`${btn} ${saved ? "text-navy" : "text-ink-2 hover:bg-cream"}`}>
        <IconBookmark className="h-5 w-5" filled={saved} />
        {saved ? "Enregistré" : "Enregistrer"}
      </motion.button>
      <motion.button type="button" whileTap={{ scale: 0.85 }} onClick={share} className={`${btn} ml-auto text-ink-2 hover:bg-cream`}>
        <IconShare className="h-5 w-5" />
        <AnimatePresence mode="wait" initial={false}>
          <motion.span key={String(copied)} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }}>
            {copied ? "Lien copié" : "Partager"}
          </motion.span>
        </AnimatePresence>
      </motion.button>
    </div>
  );
}

/** Bouton Suivre d'un auteur : se souvient du choix sur cet appareil. */
export function FollowButton({ slug, size = "md" }: { slug: string; size?: "sm" | "md" }) {
  const [on, setOn] = useStored(`follow:${slug}`, false);
  const h = size === "sm" ? "h-8 px-3 text-[13px]" : "h-11 px-5 text-[15px]";
  return (
    <motion.button
      type="button"
      layout
      whileTap={{ scale: 0.94 }}
      onClick={() => setOn(!on)}
      aria-pressed={on}
      className={`relative z-10 inline-flex shrink-0 items-center gap-1.5 rounded-full font-bold transition-colors ${h} ${
        on ? "bg-sand text-ink" : "bg-navy text-white hover:bg-navy-deep"
      }`}
    >
      <AnimatePresence mode="wait" initial={false}>
        <motion.span key={String(on)} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }} className="inline-flex items-center gap-1">
          {on ? (
            <>
              <IconCheck className="h-4 w-4" /> Suivi
            </>
          ) : (
            "Suivre"
          )}
        </motion.span>
      </AnimatePresence>
    </motion.button>
  );
}

/** Une question de quiz jouable, à la fin d'un article. */
export function OneQuestion({ quiz }: { quiz: { question: string; options: string[]; correctIndex: number; explanation: string } }) {
  const [picked, setPicked] = useState<number | null>(null);
  return (
    <div className="rounded-[22px] bg-cream p-5 sm:p-7">
      <p className="eyebrow">Testez-vous</p>
      <p className="mt-2 text-[21px] font-extrabold leading-snug tracking-tight">{quiz.question}</p>
      <div className="mt-5 grid gap-2.5 sm:grid-cols-2">
        {quiz.options.map((o, i) => {
          const ok = i === quiz.correctIndex;
          const tone =
            picked === null ? "bg-paper ring-line hover:ring-navy/40" : ok ? "bg-sage-soft ring-sage/40" : i === picked ? "bg-coral-soft ring-coral/40" : "bg-paper ring-line opacity-50";
          return (
            <motion.button
              key={o}
              type="button"
              disabled={picked !== null}
              onClick={() => setPicked(i)}
              whileTap={picked === null ? { scale: 0.98 } : undefined}
              animate={picked === i && !ok ? { x: [0, -6, 6, -4, 4, 0] } : picked !== null && ok ? { scale: [1, 1.03, 1] } : {}}
              className={`flex items-center gap-3 rounded-2xl px-4 py-3 text-left text-[15px] font-semibold ring-1 transition-colors ${tone}`}
            >
              <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[13px] font-bold ${picked !== null && ok ? "bg-sage text-white" : "bg-sand text-ink-2"}`}>
                {picked !== null && ok ? "✓" : String.fromCharCode(65 + i)}
              </span>
              {o}
            </motion.button>
          );
        })}
      </div>
      <AnimatePresence>
        {picked !== null && (
          <motion.p initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} className="overflow-hidden font-serif text-[17px] leading-snug text-ink-2" aria-live="polite">
            <span className="block pt-4">
              <strong className="font-sans text-ink">{picked === quiz.correctIndex ? "Bien vu. " : "Pas cette fois. "}</strong>
              {quiz.explanation}
            </span>
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  );
}

/** Onglets d'un fil (accueil) : la liste change avec un léger fondu. */
export function FeedTabs({ tabs, children }: { tabs: { key: string; label: string }[]; children: React.ReactNode[] }) {
  const [active, setActive] = useState(0);
  return (
    <div>
      <div className="sticky top-14 z-20 -mx-4 border-b border-line bg-paper/95 px-4 backdrop-blur lg:top-0" role="tablist" aria-label="Fil">
        <div className="flex gap-1 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {tabs.map((t, i) => (
            <button
              key={t.key}
              type="button"
              role="tab"
              id={`feed-tab-${t.key}`}
              aria-selected={i === active}
              aria-controls="feed-panel"
              onClick={() => setActive(i)}
              className={`relative whitespace-nowrap px-3 py-3.5 text-[15px] font-bold transition-colors ${i === active ? "text-ink" : "text-ink-3 hover:text-ink-2"}`}
            >
              {t.label}
              {i === active && <motion.span layoutId="feed-underline" className="absolute inset-x-2 bottom-0 h-[3px] rounded-full bg-navy" />}
            </button>
          ))}
        </div>
      </div>
      <div id="feed-panel" role="tabpanel" aria-labelledby={`feed-tab-${tabs[active].key}`}>
        <AnimatePresence mode="wait" initial={false}>
          <motion.div key={active} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.25 }}>
            {children[active]}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}
