import Image from "next/image";
import { site } from "@/lib/site";
import { Reveal } from "./Reveal";
import { Spark, Starburst } from "./ui";

function CourseStack() {
  const imgs = [site.subjects[4].courses[0], site.subjects[0].courses[1], site.subjects[5].courses[1]];
  return (
    <div className="relative h-full min-h-[300px]">
      {imgs.map((c, i) => (
        <div
          key={c.id}
          className="brutal absolute w-[62%] overflow-hidden rounded-2xl bg-paper"
          style={{
            left: `${6 + i * 15}%`,
            top: `${10 + i * 12}%`,
            transform: `rotate(${[-8, 3, -2][i]}deg)`,
            zIndex: i,
          }}
        >
          <div className="relative aspect-[16/10] border-b-[2.5px] border-ink">
            <Image src={c.image} alt="" fill sizes="300px" className="object-cover" />
          </div>
          <p className="line-clamp-2 p-3 font-display text-sm font-bold leading-snug">{c.title}</p>
        </div>
      ))}
      <div className="brutal absolute bottom-4 right-4 z-10 rotate-6 rounded-full bg-saffron px-4 py-2 font-display text-lg font-extrabold">
        ⏱ 10 min
      </div>
    </div>
  );
}

function QuizCards() {
  const q = site.quiz[2];
  return (
    <div className="relative flex h-full min-h-[300px] items-center justify-center">
      <div className="brutal absolute w-[78%] -rotate-6 rounded-3xl bg-violet-soft p-6 opacity-80" style={{ height: "70%" }} />
      <div className="brutal relative w-[82%] rotate-2 rounded-3xl bg-paper p-6">
        <p className="text-xs font-bold uppercase tracking-widest text-violet">Révision · J+7</p>
        <p className="mt-2 font-display text-xl font-bold leading-snug">{q.question}</p>
        <div className="mt-4 grid gap-2 sm:grid-cols-2">
          {q.options.map((o, i) => (
            <span
              key={o}
              className={`rounded-xl border-2 border-ink px-2 py-2 text-center text-xs font-semibold ${
                i === q.correctIndex ? "bg-mint" : "bg-cream"
              }`}
            >
              {o}
            </span>
          ))}
        </div>
      </div>
      <Spark className="absolute -right-2 top-2 h-14 w-14" fill="var(--color-pink)" />
    </div>
  );
}

function StreakCard() {
  const days = ["L", "M", "M", "J", "V", "S", "D"];
  return (
    <div className="relative flex h-full min-h-[300px] items-center justify-center">
      <div className="brutal w-[86%] rounded-3xl bg-paper p-6">
        <div className="flex items-center gap-4">
          <span className="text-5xl" aria-hidden>
            🔥
          </span>
          <div>
            <p className="font-display text-4xl font-extrabold leading-none">12 jours</p>
            <p className="font-semibold text-ink-soft">de série en cours</p>
          </div>
        </div>
        <div className="mt-6 grid grid-cols-7 gap-2">
          {days.map((d, i) => (
            <div key={i} className="text-center">
              <div
                className={`mx-auto flex aspect-square w-full items-center justify-center rounded-xl border-2 border-ink text-sm font-bold ${
                  i < 5 ? "bg-pink" : i === 5 ? "bg-saffron" : "bg-cream"
                }`}
              >
                {i < 5 ? "✓" : i === 5 ? "★" : ""}
              </div>
              <span className="mt-1 block text-xs font-bold text-ink-soft">{d}</span>
            </div>
          ))}
        </div>
        <div className="mt-6">
          <div className="mb-1 flex justify-between text-xs font-bold">
            <span>Niveau 7</span>
            <span>840 / 1 000 XP</span>
          </div>
          <div className="h-4 overflow-hidden rounded-full border-2 border-ink bg-cream">
            <div className="h-full w-[84%] bg-violet" />
          </div>
        </div>
      </div>
      <Starburst className="absolute -left-1 -top-1 h-16 w-16" fill="var(--color-saffron)" />
    </div>
  );
}

const rows = [
  {
    tag: "Le cours du jour",
    title: "Une histoire captivante, pas un chapitre de manuel",
    text: "Chaque jour, un cours court et dense : une question, un récit, les idées clés. Écrit pour se lire d'une traite, dans le métro ou au lit.",
    visual: <CourseStack />,
    tone: "bg-saffron-soft",
  },
  {
    tag: "Le quiz",
    title: "Lire c'est bien, retenir c'est mieux",
    text: "Chaque cours se termine par un quiz. Les questions reviennent ensuite au bon moment, selon la répétition espacée, pour ancrer ce que tu as appris sur le long terme.",
    visual: <QuizCards />,
    tone: "bg-violet-soft",
  },
  {
    tag: "La série",
    title: "Une habitude qui tient, jour après jour",
    text: "Série de jours, XP, niveaux et badges : Sophia tient plus du jeu que de la corvée. Ta flamme te rappelle de revenir, ta progression te donne envie de continuer.",
    visual: <StreakCard />,
    tone: "bg-pink-soft",
  },
];

export function Method() {
  return (
    <section id="methode" className="scroll-mt-20 border-b-[3px] border-ink bg-paper py-20 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <Reveal>
          <h2 className="mx-auto max-w-3xl text-center font-display text-4xl font-extrabold tracking-tight sm:text-5xl">
            Voici comment Sophia te fait aimer apprendre
          </h2>
        </Reveal>

        <div className="mt-16 space-y-20 sm:space-y-28">
          {rows.map((r, i) => (
            <div key={r.tag} className="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
              <Reveal className={i % 2 === 1 ? "lg:order-2" : ""}>
                <span className="brutal-sm inline-block rounded-full bg-ink px-3 py-1 text-xs font-bold uppercase tracking-[0.14em] text-cream">
                  {String(i + 1).padStart(2, "0")} · {r.tag}
                </span>
                <h3 className="mt-5 font-display text-3xl font-extrabold leading-tight tracking-tight sm:text-4xl">{r.title}</h3>
                <p className="mt-4 max-w-lg text-lg leading-relaxed text-ink-soft">{r.text}</p>
              </Reveal>
              <Reveal delay={120}>
                <div className={`brutal-lg grid-paper rounded-[32px] ${r.tone} p-4 sm:p-6`}>{r.visual}</div>
              </Reveal>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
