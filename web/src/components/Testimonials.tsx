import Image from "next/image";
import { Reveal } from "./Reveal";

// Avis repris de l'onboarding de l'app (AppLocalizable.swift, onboardingV2.review.*).
const reviews = [
  { name: "Camille, 22 ans", text: "Depuis que je scroll moins et que j'utilise Sophia, j'ai l'impression que je retiens beaucoup plus de choses.", tone: "bg-sky" },
  { name: "Yanis, 27 ans", text: "10 minutes le matin dans le métro et le soir j'ai un truc à raconter. Franchement je suis accro.", tone: "bg-saffron-soft" },
  { name: "Inès, 19 ans", text: "J'ai toujours détesté « réviser », mais là ça rentre tout seul. Ma mémoire me surprend.", tone: "bg-mint" },
  { name: "Thomas, 31 ans", text: "Je remplace mes scrolls sans fin par un cours. En un mois, mes proches ont remarqué la différence.", tone: "bg-pink-soft" },
  { name: "Sarah, 26 ans", text: "Enfin une app qui me donne l'impression d'avancer, pas de perdre mon temps. Je la lance tous les jours.", tone: "bg-violet-soft" },
  { name: "Malik, 23 ans", text: "Les quiz espacés, c'est magique : je me souviens de trucs appris il y a des semaines sans forcer.", tone: "bg-peach" },
];

/** Nombre de photos disponibles dans public/img/avatars. */
const AVATARS = 5;

export function Testimonials() {
  const loop = [...reviews, ...reviews];
  return (
    <section className="overflow-hidden border-b-[3px] border-ink bg-pink py-20 sm:py-24">
      <Reveal className="mx-auto max-w-6xl px-4 text-center sm:px-6">
        <h2 className="font-display text-4xl font-extrabold tracking-tight sm:text-5xl">Ce qu&apos;en disent nos lecteurs</h2>
        <p className="mt-3 text-lg font-medium text-ink/80">Plus de 1 000 avis sur les stores.</p>
      </Reveal>
      <div className="group mt-12 flex overflow-hidden py-4">
        <ul
          className="flex shrink-0 animate-marquee gap-6 pr-6 group-hover:[animation-play-state:paused]"
          style={{ "--marquee-duration": "60s" } as React.CSSProperties}
        >
          {loop.map((r, i) => (
            <li
              key={i}
              aria-hidden={i >= reviews.length}
              className={`brutal flex w-[300px] shrink-0 flex-col justify-between rounded-3xl ${r.tone} p-6 sm:w-[360px] ${
                i % 2 ? "rotate-1" : "-rotate-1"
              }`}
            >
              <div>
                <p className="text-lg tracking-widest text-ink" aria-label="5 étoiles sur 5">
                  ★★★★★
                </p>
                <p className="mt-3 text-[17px] font-medium leading-relaxed">« {r.text} »</p>
              </div>
              <div className="mt-6 flex items-center gap-3">
                {(i % reviews.length) < AVATARS ? (
                  <Image
                    src={`/img/avatars/review_${(i % reviews.length) + 1}.webp`}
                    alt=""
                    width={44}
                    height={44}
                    className="h-11 w-11 rounded-full border-2 border-ink object-cover"
                  />
                ) : (
                  <span className="flex h-11 w-11 items-center justify-center rounded-full border-2 border-ink bg-paper font-display font-bold">
                    {r.name[0]}
                  </span>
                )}
                <p className="font-display font-bold">{r.name}</p>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
