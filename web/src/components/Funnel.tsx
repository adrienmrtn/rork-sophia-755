"use client";

import Image from "next/image";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useMemo, useState } from "react";
import { links, type PlanId } from "@/lib/config";
import { Avatar, Logo } from "./ui";
import { IconCheck, IconLock } from "./icons";

type SubjectOption = { slug: string; label: string; image: string };
type CardT = { slug: string; title: string; hook: string; image: string; subject: string; author: { slug: string; name: string; title: string; photo: string | null } };
type Plan = { id: PlanId; name: string; price: string; period: string; perMonth: string; trialDays: number; badge?: string; checkoutUrl: string | null };
type Stats = { courses: number; creators: number; languages: number; quizQuestions: number; collections: number };

// Objectifs et profils repris de l'onboarding de l'app (onboardingV2.objective.* et onboardingV2.profile.*).
const goals = [
  { id: "cultivate", label: "Me cultiver au quotidien", emoji: "📚", nickname: "L'Esprit Curieux", tagline: "Vous voulez comprendre le monde, un peu plus chaque jour." },
  { id: "reduceScreen", label: "Réduire mon temps d'écran", emoji: "📵", nickname: "Le Reconquérant", tagline: "Vous reprenez le contrôle de votre temps et de votre attention." },
  { id: "exams", label: "Réussir mes études ou examens", emoji: "🎓", nickname: "Le Stratège", tagline: "Vous apprenez avec méthode pour être prêt le jour J." },
  { id: "impress", label: "Briller en société", emoji: "✨", nickname: "L'Éclatant", tagline: "Bientôt, c'est vous qui aurez les meilleures anecdotes." },
  { id: "curiosity", label: "Apprendre par curiosité", emoji: "🧭", nickname: "L'Explorateur", tagline: "Votre curiosité n'a pas de limite. Nourrissons-la." },
];
const minutes = [
  { v: 5, label: "5 minutes", hint: "Un cours en deux fois" },
  { v: 10, label: "10 minutes", hint: "Un cours par jour, le rythme conseillé" },
  { v: 15, label: "15 minutes", hint: "Un cours et sa révision" },
  { v: 20, label: "20 minutes ou plus", hint: "Pour aller vite" },
];
const moments = [
  { v: "matin", label: "Le matin", emoji: "☕" },
  { v: "trajet", label: "Dans les transports", emoji: "🚇" },
  { v: "midi", label: "À la pause déjeuner", emoji: "🥪" },
  { v: "soir", label: "Le soir, avant de dormir", emoji: "🌙" },
];
const screen = [
  { v: 1.5, label: "Moins de 2 heures" },
  { v: 3, label: "2 à 4 heures" },
  { v: 5, label: "4 à 6 heures" },
  { v: 7, label: "Plus de 6 heures" },
];

type Step = "goals" | "subjects" | "minutes" | "moment" | "screen" | "analysis" | "profile" | "email" | "plan" | "payment" | "done";
const order: Step[] = ["goals", "subjects", "minutes", "moment", "screen", "analysis", "profile", "email", "plan", "payment", "done"];
const progressSteps: Step[] = ["goals", "subjects", "minutes", "moment", "screen", "profile", "email", "plan", "payment"];

function Choice({ selected, onClick, children, multi = false }: { selected: boolean; onClick: () => void; children: React.ReactNode; multi?: boolean }) {
  return (
    <motion.button
      type="button"
      onClick={onClick}
      whileTap={{ scale: 0.98 }}
      aria-pressed={selected}
      className={`flex w-full items-center gap-3 rounded-2xl px-5 py-4 text-left text-[16px] font-bold transition-colors ${
        selected ? "bg-navy text-white" : "bg-paper text-ink ring-1 ring-line hover:ring-navy/40"
      }`}
    >
      <span className="flex-1">{children}</span>
      <span className={`flex h-6 w-6 shrink-0 items-center justify-center ${multi ? "rounded-md" : "rounded-full"} ${selected ? "bg-white text-navy" : "ring-1 ring-line"}`}>
        {selected && <IconCheck className="h-4 w-4" />}
      </span>
    </motion.button>
  );
}

function Title({ children, sub }: { children: React.ReactNode; sub?: string }) {
  return (
    <div className="mb-7">
      <h1 className="text-[28px] font-extrabold leading-tight tracking-[-0.025em] sm:text-[34px]">{children}</h1>
      {sub && <p className="mt-2 font-serif text-[18px] text-ink-2">{sub}</p>}
    </div>
  );
}

function Next({ disabled, onClick, children = "Continuer" }: { disabled?: boolean; onClick: () => void; children?: React.ReactNode }) {
  return (
    <motion.button
      type="button"
      disabled={disabled}
      onClick={onClick}
      whileTap={disabled ? undefined : { scale: 0.97 }}
      className="mt-8 flex h-14 w-full items-center justify-center rounded-2xl bg-navy text-[17px] font-bold text-white shadow-[0_10px_24px_-10px_rgba(26,58,107,0.7)] transition-opacity disabled:opacity-35"
    >
      {children}
    </motion.button>
  );
}

function Analysis({ onDone, subjects }: { onDone: () => void; subjects: string[] }) {
  const lines = [
    "Vos objectifs",
    subjects.length ? `${subjects.length} matière${subjects.length > 1 ? "s" : ""} choisie${subjects.length > 1 ? "s" : ""}` : "Vos matières",
    "Votre rythme",
    "Votre programme de 30 jours",
  ];
  const [done, setDone] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setDone((d) => d + 1), 750);
    return () => clearInterval(t);
  }, []);
  useEffect(() => {
    if (done > lines.length) onDone();
  }, [done, lines.length, onDone]);
  const pct = Math.min(100, Math.round((done / lines.length) * 100));
  return (
    <div className="flex flex-col items-center text-center">
      <div className="relative h-36 w-36">
        <svg viewBox="0 0 100 100" className="h-full w-full -rotate-90">
          <circle cx="50" cy="50" r="44" fill="none" stroke="var(--color-sand)" strokeWidth="8" />
          <motion.circle cx="50" cy="50" r="44" fill="none" stroke="var(--color-navy)" strokeWidth="8" strokeLinecap="round" pathLength={1} initial={{ pathLength: 0 }} animate={{ pathLength: pct / 100 }} transition={{ duration: 0.7 }} />
        </svg>
        <span className="absolute inset-0 flex items-center justify-center text-[30px] font-extrabold tabular-nums">{pct}%</span>
      </div>
      <h1 className="mt-6 text-[26px] font-extrabold tracking-tight">Nous composons votre programme</h1>
      <ul className="mt-6 w-full max-w-xs space-y-3 text-left">
        {lines.map((l, i) => (
          <li key={l} className="flex items-center gap-3 text-[16px] font-semibold">
            <motion.span
              animate={{ backgroundColor: i < done ? "#387d5a" : "#f3ecdf", scale: i === done - 1 ? [0.8, 1.15, 1] : 1 }}
              className="flex h-7 w-7 items-center justify-center rounded-full text-white"
            >
              {i < done && <IconCheck className="h-4 w-4" />}
            </motion.span>
            <span className={i < done ? "text-ink" : "text-ink-3"}>{l}</span>
          </li>
        ))}
      </ul>
      <p className="mt-8 max-w-sm font-serif text-[17px] text-ink-2">500 000 personnes lisent un cours Sophia chaque mois.</p>
    </div>
  );
}

export function Funnel({ subjects, picks, plans, stats }: { subjects: SubjectOption[]; picks: Record<string, CardT[]>; plans: Plan[]; stats: Stats }) {
  const [step, setStep] = useState<Step>("goals");
  const [dir, setDir] = useState(1);
  const [chosenGoals, setGoals] = useState<string[]>([]);
  const [chosenSubjects, setSubjects] = useState<string[]>([]);
  const [mins, setMins] = useState<number | null>(null);
  const [moment, setMoment] = useState<string | null>(null);
  const [hours, setHours] = useState<number | null>(null);
  const [email, setEmail] = useState("");
  const [plan, setPlan] = useState<PlanId>("annuel");

  useEffect(() => {
    try {
      const p = new URLSearchParams(window.location.search).get("offre");
      if (p === "annuel" || p === "mensuel") setPlan(p);
    } catch {}
  }, []);

  const go = (s: Step) => {
    setDir(order.indexOf(s) >= order.indexOf(step) ? 1 : -1);
    setStep(s);
    try {
      window.scrollTo({ top: 0 });
    } catch {}
  };
  const next = () => go(order[order.indexOf(step) + 1]);
  const back = () => {
    let i = order.indexOf(step) - 1;
    if (order[i] === "analysis") i -= 1;
    if (i >= 0) go(order[i]);
  };

  const goal = goals.find((g) => g.id === chosenGoals[0]) ?? goals[0];
  const recos = useMemo(() => {
    const keys = chosenSubjects.length ? chosenSubjects : subjects.map((s) => s.slug);
    return keys.flatMap((k) => picks[k] ?? []).filter((c, i, a) => a.findIndex((x) => x.slug === c.slug) === i).slice(0, 3);
  }, [chosenSubjects, picks, subjects]);
  const selectedPlan = plans.find((p) => p.id === plan)!;
  const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
  const pi = progressSteps.indexOf(step);
  const daysLost = hours ? Math.round((hours * 365) / 24) : 0;
  const coursesPerYear = mins ? Math.round((mins * 365) / 10) : 365;

  function pay() {
    if (!selectedPlan.checkoutUrl) return;
    const url = new URL(selectedPlan.checkoutUrl);
    url.searchParams.set("prefilled_email", email);
    url.searchParams.set("email", email);
    window.location.href = url.toString();
  }

  const today = new Date();
  const day = (n: number) => new Date(today.getTime() + n * 86400000).toLocaleDateString("fr-FR", { day: "numeric", month: "long" });

  return (
    <div className="min-h-screen bg-cream">
      <header className="sticky top-0 z-30 bg-cream/95 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-xl items-center justify-between gap-4 px-4">
          {step !== "goals" && step !== "analysis" && step !== "done" ? (
            <button type="button" onClick={back} className="flex h-10 w-10 items-center justify-center rounded-full hover:bg-sand" aria-label="Retour">
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                <path d="M15 5l-7 7 7 7" />
              </svg>
            </button>
          ) : (
            <span className="w-10" />
          )}
          <a href="/" aria-label="Sophia, accueil">
            <Logo className="!w-[100px]" />
          </a>
          <a href="/" className="flex h-10 w-10 items-center justify-center rounded-full hover:bg-sand" aria-label="Quitter">
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden>
              <path d="M6 6l12 12M18 6 6 18" />
            </svg>
          </a>
        </div>
        {pi >= 0 && (
          <div className="mx-auto h-1.5 max-w-xl px-4">
            <div className="h-full overflow-hidden rounded-full bg-sand">
              <motion.div className="h-full rounded-full bg-saffron" animate={{ width: `${((pi + 1) / progressSteps.length) * 100}%` }} transition={{ type: "spring", stiffness: 120, damping: 20 }} />
            </div>
          </div>
        )}
      </header>

      <main className="mx-auto max-w-xl px-4 pb-16 pt-8">
        <AnimatePresence mode="wait" custom={dir} initial={false}>
          <motion.div
            key={step}
            custom={dir}
            variants={{ enter: (d: number) => ({ opacity: 0, x: d * 40 }), center: { opacity: 1, x: 0 }, exit: (d: number) => ({ opacity: 0, x: d * -40 }) }}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{ type: "spring", stiffness: 300, damping: 32 }}
          >
            {step === "goals" && (
              <>
                <Title sub="Vous pouvez en choisir plusieurs.">Qu&apos;attendez-vous de Sophia ?</Title>
                <div className="space-y-3">
                  {goals.map((g) => (
                    <Choice key={g.id} multi selected={chosenGoals.includes(g.id)} onClick={() => setGoals((cur) => (cur.includes(g.id) ? cur.filter((x) => x !== g.id) : [...cur, g.id]))}>
                      <span className="mr-2">{g.emoji}</span>
                      {g.label}
                    </Choice>
                  ))}
                </div>
                <Next disabled={!chosenGoals.length} onClick={next} />
              </>
            )}

            {step === "subjects" && (
              <>
                <Title sub="Votre fil commencera par celles-ci.">Quelles matières vous attirent ?</Title>
                <div className="grid grid-cols-2 gap-3">
                  {subjects.map((s) => {
                    const on = chosenSubjects.includes(s.slug);
                    return (
                      <motion.button
                        key={s.slug}
                        type="button"
                        whileTap={{ scale: 0.97 }}
                        aria-pressed={on}
                        onClick={() => setSubjects((cur) => (on ? cur.filter((x) => x !== s.slug) : [...cur, s.slug]))}
                        className={`relative overflow-hidden rounded-2xl text-left transition-shadow ${on ? "ring-[3px] ring-navy" : "ring-1 ring-line"}`}
                      >
                        <div className="relative aspect-[4/3]">
                          <Image src={s.image} alt="" fill sizes="260px" className="object-cover" />
                          <div className="absolute inset-0 bg-gradient-to-t from-ink/80 to-transparent" />
                        </div>
                        <span className="absolute bottom-3 left-3 text-[16px] font-extrabold text-white">{s.label}</span>
                        <AnimatePresence>
                          {on && (
                            <motion.span initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }} className="absolute right-2.5 top-2.5 flex h-7 w-7 items-center justify-center rounded-full bg-navy text-white">
                              <IconCheck className="h-4 w-4" />
                            </motion.span>
                          )}
                        </AnimatePresence>
                      </motion.button>
                    );
                  })}
                </div>
                <Next disabled={!chosenSubjects.length} onClick={next} />
              </>
            )}

            {step === "minutes" && (
              <>
                <Title>Combien de temps par jour voulez-vous y consacrer ?</Title>
                <div className="space-y-3">
                  {minutes.map((m) => (
                    <Choice key={m.v} selected={mins === m.v} onClick={() => setMins(m.v)}>
                      {m.label}
                      <span className={`block text-[13px] font-semibold ${mins === m.v ? "text-white/75" : "text-ink-3"}`}>{m.hint}</span>
                    </Choice>
                  ))}
                </div>
                <Next disabled={mins === null} onClick={next} />
              </>
            )}

            {step === "moment" && (
              <>
                <Title sub="Nous vous rappellerons votre cours à ce moment-là.">Quand lirez-vous le plus souvent ?</Title>
                <div className="space-y-3">
                  {moments.map((m) => (
                    <Choice key={m.v} selected={moment === m.v} onClick={() => setMoment(m.v)}>
                      <span className="mr-2">{m.emoji}</span>
                      {m.label}
                    </Choice>
                  ))}
                </div>
                <Next disabled={!moment} onClick={next} />
              </>
            )}

            {step === "screen" && (
              <>
                <Title sub="Une estimation suffit.">Combien de temps passez-vous sur votre téléphone par jour ?</Title>
                <div className="space-y-3">
                  {screen.map((s) => (
                    <Choice key={s.v} selected={hours === s.v} onClick={() => setHours(s.v)}>
                      {s.label}
                    </Choice>
                  ))}
                </div>
                <AnimatePresence>
                  {hours !== null && (
                    <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} className="overflow-hidden">
                      <div className="mt-5 rounded-2xl bg-navy-deep p-5 text-white">
                        <p className="text-[15px] font-semibold text-white/75">Sur un an, cela représente</p>
                        <p className="mt-1 text-[34px] font-extrabold tabular-nums tracking-tight text-saffron">{daysLost} jours entiers</p>
                        <p className="mt-1 font-serif text-[16px] text-white/85">
                          Dix minutes de ce temps suffisent pour lire 365 cours dans l&apos;année.
                        </p>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
                <Next disabled={hours === null} onClick={next} />
              </>
            )}

            {step === "analysis" && <Analysis subjects={chosenSubjects} onDone={() => go("profile")} />}

            {step === "profile" && (
              <>
                <p className="eyebrow">Votre profil</p>
                <motion.h1 initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ type: "spring", stiffness: 200, damping: 16 }} className="mt-2 text-[40px] font-extrabold tracking-[-0.03em] text-navy">
                  {goal.nickname}
                </motion.h1>
                <p className="mt-2 font-serif text-[20px] text-ink-2">{goal.tagline}</p>
                <div className="mt-6 grid grid-cols-3 gap-3 text-center">
                  {[
                    [`${mins ?? 10} min`, "par jour"],
                    [`${coursesPerYear}`, "cours par an"],
                    [`${chosenSubjects.length || 6}`, chosenSubjects.length === 1 ? "matière" : "matières"],
                  ].map(([v, l], i) => (
                    <motion.div key={l} initial={{ y: 16, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.15 + i * 0.1 }} className="rounded-2xl bg-paper p-4 ring-1 ring-line">
                      <p className="text-[24px] font-extrabold tabular-nums">{v}</p>
                      <p className="text-[13px] font-semibold text-ink-2">{l}</p>
                    </motion.div>
                  ))}
                </div>
                <p className="mt-8 text-[15px] font-extrabold">Vos premiers cours</p>
                <ul className="mt-3 space-y-3">
                  {recos.map((c, i) => (
                    <motion.li key={c.slug} initial={{ x: 20, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={{ delay: 0.4 + i * 0.1 }} className="flex items-center gap-3 rounded-2xl bg-paper p-3 ring-1 ring-line">
                      <span className="relative h-16 w-20 shrink-0 overflow-hidden rounded-xl">
                        <Image src={c.image} alt="" fill sizes="80px" className="object-cover" />
                      </span>
                      <span className="min-w-0">
                        <span className="line-clamp-2 text-[15px] font-bold leading-snug">{c.title}</span>
                        <span className="mt-1 flex items-center gap-1.5 text-[12.5px] text-ink-2">
                          <Avatar author={c.author} size={16} className="!ring-0" /> {c.author.name}
                        </span>
                      </span>
                    </motion.li>
                  ))}
                </ul>
                <Next onClick={next}>C&apos;est parti</Next>
              </>
            )}

            {step === "email" && (
              <>
                <Title sub="Vous vous connecterez avec cette adresse dans l'app pour retrouver votre programme et votre abonnement.">Créez votre compte</Title>
                <label htmlFor="funnel-email" className="mb-1.5 block text-[14px] font-bold">
                  Adresse e-mail
                </label>
                <input
                  id="funnel-email"
                  type="email"
                  autoComplete="email"
                  inputMode="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="vous@exemple.fr"
                  className="h-14 w-full rounded-2xl bg-paper px-5 text-[17px] outline-none ring-1 ring-line focus:ring-2 focus:ring-navy"
                />
                {email.length > 4 && !emailOk && <p className="mt-2 text-[14px] font-semibold text-coral">Cette adresse ne semble pas complète.</p>}
                <p className="mt-4 text-[13px] leading-relaxed text-ink-3">
                  En continuant, vous acceptez les{" "}
                  <a href={links.terms} target="_blank" rel="noopener" className="underline">
                    conditions d&apos;utilisation
                  </a>{" "}
                  et la{" "}
                  <a href={links.privacy} target="_blank" rel="noopener" className="underline">
                    politique de confidentialité
                  </a>
                  .
                </p>
                <Next disabled={!emailOk} onClick={next} />
              </>
            )}

            {step === "plan" && (
              <>
                <Title>Débloquez tout Sophia, gratuitement pendant 3 jours</Title>
                <div className="space-y-3">
                  {plans.map((p) => {
                    const on = plan === p.id;
                    return (
                      <motion.button
                        key={p.id}
                        type="button"
                        whileTap={{ scale: 0.98 }}
                        onClick={() => setPlan(p.id)}
                        aria-pressed={on}
                        className={`relative flex w-full items-center gap-4 rounded-2xl bg-paper p-5 text-left transition-shadow ${on ? "ring-[3px] ring-navy" : "ring-1 ring-line"}`}
                      >
                        {p.badge && <span className="absolute -top-2.5 right-4 rounded-full bg-saffron px-2.5 py-0.5 text-[11px] font-extrabold">{p.badge}</span>}
                        <span className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full ${on ? "bg-navy text-white" : "ring-1 ring-line"}`}>{on && <IconCheck className="h-4 w-4" />}</span>
                        <span className="flex-1">
                          <span className="block text-[17px] font-extrabold">{p.name}</span>
                          <span className="block text-[14px] text-ink-2">
                            {p.price} {p.period}
                          </span>
                        </span>
                        <span className="text-right text-[14px] font-bold text-navy">{p.perMonth}</span>
                      </motion.button>
                    );
                  })}
                </div>
                <ol className="relative mt-8 space-y-5 pl-9">
                  <span className="absolute bottom-2 left-[13px] top-2 w-[3px] rounded-full bg-gradient-to-b from-saffron via-saffron to-sand" aria-hidden />
                  {[
                    ["Aujourd'hui", "Accès complet : tous les cours, les quiz, l'audio et le bloqueur."],
                    [day(2), "Un rappel par e-mail, la veille de la fin de l'essai."],
                    [day(selectedPlan.trialDays), `Début de l'abonnement : ${selectedPlan.price} ${selectedPlan.period}. Annulable avant, sans frais.`],
                  ].map(([d, t], i) => (
                    <li key={d} className="relative">
                      <span className={`absolute -left-9 top-0.5 flex h-7 w-7 items-center justify-center rounded-full ${i === 0 ? "bg-saffron" : "bg-paper ring-2 ring-sand"}`}>
                        {i === 0 ? <IconLock className="h-3.5 w-3.5" /> : <span className="h-2 w-2 rounded-full bg-ink-3" />}
                      </span>
                      <p className="text-[15px] font-extrabold">{d}</p>
                      <p className="font-serif text-[16px] text-ink-2">{t}</p>
                    </li>
                  ))}
                </ol>
                <Next onClick={next}>Commencer mon essai gratuit</Next>
                <p className="mt-3 text-center text-[13px] text-ink-3">Sans engagement · Annulable en un clic</p>
              </>
            )}

            {step === "payment" && (
              <>
                <Title>Paiement</Title>
                <div className="rounded-2xl bg-paper p-5 ring-1 ring-line">
                  <p className="text-[13px] font-bold uppercase tracking-wider text-ink-3">Récapitulatif</p>
                  <div className="mt-3 flex items-baseline justify-between gap-4">
                    <span className="text-[17px] font-extrabold">Sophia Premium · {selectedPlan.name}</span>
                    <span className="text-[15px] font-bold">{selectedPlan.price}</span>
                  </div>
                  <div className="mt-3 space-y-1.5 border-t border-line pt-3 text-[15px]">
                    <p className="flex justify-between">
                      <span className="text-ink-2">À payer aujourd&apos;hui</span>
                      <strong>0,00 €</strong>
                    </p>
                    <p className="flex justify-between">
                      <span className="text-ink-2">Le {day(selectedPlan.trialDays)}</span>
                      <span>
                        {selectedPlan.price} {selectedPlan.period}
                      </span>
                    </p>
                    <p className="flex justify-between">
                      <span className="text-ink-2">Compte</span>
                      <span className="truncate pl-4">{email}</span>
                    </p>
                  </div>
                </div>

                {selectedPlan.checkoutUrl ? (
                  <>
                    <Next onClick={pay}>
                      <IconLock className="mr-2 h-4 w-4" /> Payer en toute sécurité
                    </Next>
                    <p className="mt-3 text-center text-[13px] text-ink-3">Carte bancaire, Apple Pay ou Google Pay, sur une page de paiement sécurisée.</p>
                  </>
                ) : (
                  <div className="mt-6 rounded-2xl bg-saffron-soft p-5" role="status">
                    <p className="text-[15px] font-extrabold">Paiement pas encore branché</p>
                    <p className="mt-1 text-[14px] leading-relaxed text-ink-2">
                      Le bouton de paiement redirigera vers la page de paiement sécurisée dès que son lien sera configuré
                      (NEXT_PUBLIC_CHECKOUT_URL_ANNUEL et NEXT_PUBLIC_CHECKOUT_URL_MENSUEL). Aucun paiement n&apos;est possible pour l&apos;instant.
                    </p>
                    <button type="button" onClick={next} className="mt-3 text-[14px] font-bold text-navy underline">
                      Voir l&apos;écran de confirmation (aperçu)
                    </button>
                  </div>
                )}
              </>
            )}

            {step === "done" && (
              <div className="text-center">
                <motion.span initial={{ scale: 0, rotate: -30 }} animate={{ scale: 1, rotate: 0 }} transition={{ type: "spring", stiffness: 260, damping: 14 }} className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-sage text-white">
                  <IconCheck className="h-10 w-10" />
                </motion.span>
                <h1 className="mt-6 text-[32px] font-extrabold tracking-tight">Bienvenue dans Sophia Premium</h1>
                <p className="mt-2 font-serif text-[19px] text-ink-2">Il ne reste qu&apos;à installer l&apos;app et à vous connecter avec {email || "votre adresse e-mail"}.</p>
                <ol className="mx-auto mt-8 max-w-sm space-y-3 text-left">
                  {["Téléchargez Sophia sur votre téléphone", "Connectez-vous avec la même adresse e-mail", `Lisez votre premier cours : ${recos[0]?.title ?? "il vous attend"}`].map((t, i) => (
                    <li key={t} className="flex gap-3 rounded-2xl bg-paper p-4 text-[15px] font-semibold ring-1 ring-line">
                      <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-navy text-[13px] font-bold text-white">{i + 1}</span>
                      {t}
                    </li>
                  ))}
                </ol>
                <a href={links.download} target="_blank" rel="noopener" className="mt-8 flex h-14 w-full items-center justify-center rounded-2xl bg-navy text-[17px] font-bold text-white">
                  Télécharger l&apos;app
                </a>
                <p className="mt-3 text-[13px] text-ink-3">taap.it/sophia · iPhone et Android, {stats.languages} langues</p>
              </div>
            )}
          </motion.div>
        </AnimatePresence>
      </main>
    </div>
  );
}
