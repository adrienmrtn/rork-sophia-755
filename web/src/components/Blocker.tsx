import { Reveal } from "./Reveal";
import { Squiggle } from "./ui";

const apps = [
  { emoji: "🎵", tone: "bg-pink", label: "Vidéos courtes" },
  { emoji: "📸", tone: "bg-peach", label: "Photos" },
  { emoji: "▶️", tone: "bg-saffron", label: "Vidéos" },
  { emoji: "💬", tone: "bg-sky", label: "Messages" },
  { emoji: "🐦", tone: "bg-mint", label: "Fil d'actu" },
  { emoji: "🎮", tone: "bg-violet-soft", label: "Jeux" },
];

export function Blocker() {
  return (
    <section className="relative overflow-hidden border-b-[3px] border-ink bg-ink py-20 text-cream sm:py-28">
      <div className="mx-auto grid max-w-6xl items-center gap-14 px-4 sm:px-6 lg:grid-cols-2">
        <Reveal>
          <span className="inline-block rounded-full border-2 border-cream/80 px-3 py-1 text-xs font-bold uppercase tracking-[0.14em]">
            Le bloqueur d&apos;apps
          </span>
          <h2 className="mt-5 font-display text-4xl font-extrabold leading-[1.05] tracking-tight sm:text-6xl">
            Tes apps attendent.
            <br />
            <span className="text-saffron">Ton cerveau, non.</span>
          </h2>
          <Squiggle className="mt-4 h-6 w-40" stroke="var(--color-pink)" />
          <p className="mt-6 max-w-lg text-lg leading-relaxed text-cream/80">
            Choisis les apps qui te volent ton temps. Sophia les verrouille jusqu&apos;à ce que tu aies
            fait ton cours du jour. Dix minutes plus tard, tu les retrouves, avec quelque chose de neuf
            dans la tête.
          </p>
          <blockquote className="mt-8 max-w-lg rounded-3xl border-2 border-cream/30 p-5 text-cream/90">
            « Avant, je passais 7 h par jour sur mon téléphone. Aujourd&apos;hui 40 minutes avec Sophia,
            et je me sens plus intelligent chaque semaine. »
            <footer className="mt-2 text-sm font-bold text-saffron">Léa, 24 ans</footer>
          </blockquote>
        </Reveal>

        <Reveal delay={150}>
          <div className="relative mx-auto w-full max-w-md">
            <div className="rounded-[36px] border-[3px] border-cream bg-navy p-6 shadow-[8px_8px_0_0_var(--color-saffron)] sm:p-8">
              <div className="grid grid-cols-3 gap-5">
                {apps.map((a, i) => (
                  <div key={a.label} className="text-center">
                    <div
                      className={`relative mx-auto flex aspect-square w-full items-center justify-center rounded-2xl border-[2.5px] border-ink ${a.tone} text-3xl`}
                    >
                      <span className="opacity-40 grayscale">{a.emoji}</span>
                      <span
                        className="absolute -right-2 -top-2 flex h-8 w-8 items-center justify-center rounded-full border-[2.5px] border-ink bg-paper text-sm shadow-[2px_2px_0_0_var(--color-ink)]"
                        style={{ animation: `float 4s ease-in-out ${i * 0.3}s infinite` }}
                      >
                        🔒
                      </span>
                    </div>
                    <p className="mt-2 text-xs font-semibold text-cream/70">{a.label}</p>
                  </div>
                ))}
              </div>
              <div className="mt-8 rounded-2xl border-[2.5px] border-ink bg-saffron p-4 text-ink">
                <p className="font-display text-lg font-extrabold">Encore 1 cours pour débloquer 🔓</p>
                <div className="mt-3 h-3 overflow-hidden rounded-full border-2 border-ink bg-paper">
                  <div className="h-full w-[70%] bg-pink" />
                </div>
                <p className="mt-2 text-sm font-semibold">7 minutes de lecture restantes</p>
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
