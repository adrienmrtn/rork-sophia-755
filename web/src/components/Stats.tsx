import { site, fr } from "@/lib/site";
import { Reveal } from "./Reveal";

const stats = [
  { value: "500 000", label: "lecteurs chaque mois sur Sophia", icon: "👀", tone: "bg-pink-soft" },
  { value: fr(site.stats.courses), label: "cours en histoire, sciences, art et plus", icon: "📚", tone: "bg-saffron-soft" },
  { value: fr(site.stats.quizQuestions), label: "questions de quiz pour retenir", icon: "🧠", tone: "bg-violet-soft" },
  { value: String(site.stats.languages), label: "langues disponibles dans l'app", icon: "🌍", tone: "bg-mint" },
];

const moments = [
  { emoji: "🚇", title: "Dans le métro", text: "Un cours entre deux stations, au lieu de faire défiler.", tone: "bg-sky", r: "-rotate-3" },
  { emoji: "🥪", title: "À la pause déj", text: "Dix minutes, une histoire, et une anecdote pour l'après-midi.", tone: "bg-saffron", r: "rotate-2" },
  { emoji: "🌙", title: "Avant de dormir", text: "Le cerveau retient mieux ce qu'il lit juste avant le sommeil.", tone: "bg-violet-soft", r: "-rotate-1" },
  { emoji: "📵", title: "À la place de TikTok", text: "Tes apps restent bloquées tant que ton cours du jour n'est pas fait.", tone: "bg-mint", r: "rotate-3" },
];

export function Stats() {
  return (
    <>
      <section className="border-b-[3px] border-ink bg-cream py-16">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <ul className="grid grid-cols-2 gap-4 sm:gap-6 lg:grid-cols-4">
            {stats.map((s, i) => (
              <Reveal as="li" key={s.label} delay={i * 80}>
                <div className={`brutal h-full rounded-3xl ${s.tone} p-5 sm:p-6`}>
                  <div className="flex items-start justify-between gap-2">
                    <p className="whitespace-nowrap font-display text-[28px] font-extrabold tracking-tight sm:text-4xl lg:text-[40px]">{s.value}</p>
                    <span className="text-2xl sm:text-3xl" aria-hidden>
                      {s.icon}
                    </span>
                  </div>
                  <p className="mt-3 text-sm font-medium text-ink-soft sm:text-base">{s.label}</p>
                </div>
              </Reveal>
            ))}
          </ul>
        </div>
      </section>

      <section className="relative overflow-hidden border-b-[3px] border-ink bg-pink py-20">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <Reveal>
            <h2 className="mx-auto max-w-3xl text-center font-display text-4xl font-extrabold leading-tight tracking-tight sm:text-5xl">
              10 minutes qui se glissent partout dans ta journée
            </h2>
          </Reveal>
          <div className="mt-14 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {moments.map((m, i) => (
              <Reveal key={m.title} delay={i * 90}>
                <div
                  className={`brutal-lg h-full rounded-3xl ${m.tone} ${m.r} p-6 transition-transform duration-300 hover:rotate-0 hover:scale-[1.03]`}
                >
                  <div className="brutal-sm mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-paper text-3xl">
                    {m.emoji}
                  </div>
                  <h3 className="font-display text-2xl font-bold">{m.title}</h3>
                  <p className="mt-2 text-ink-soft">{m.text}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
