import Image from "next/image";
import { site, links } from "@/lib/site";
import { Reveal } from "./Reveal";
import { Button, Laurel } from "./ui";

const tones = ["bg-sky", "bg-pink-soft", "bg-mint", "bg-saffron-soft", "bg-peach", "bg-violet-soft"];

function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0])
    .join("");
}

export function Profs() {
  const creators = site.creators.slice(0, 8);
  return (
    <section id="profs" className="scroll-mt-20 border-b-[3px] border-ink bg-cream py-20 sm:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="grid items-end gap-8 lg:grid-cols-[1.3fr_1fr]">
          <Reveal>
            <span className="brutal-sm inline-block rounded-full bg-mint px-3 py-1 text-xs font-bold uppercase tracking-[0.14em]">
              ✓ Profs vérifiés
            </span>
            <h2 className="mt-5 font-display text-4xl font-extrabold leading-tight tracking-tight sm:text-5xl">
              Écrits par des profs et des chercheurs, pas par un algorithme
            </h2>
          </Reveal>
          <Reveal delay={100}>
            <p className="text-lg leading-relaxed text-ink-soft">
              Historiens, philosophes, médecins, chimistes : {site.stats.creators} spécialistes venus
              d&apos;universités du monde entier écrivent et relisent les cours de Sophia.
            </p>
          </Reveal>
        </div>

        <ul className="mt-14 grid grid-cols-2 gap-4 sm:gap-6 lg:grid-cols-4">
          {creators.map((c, i) => (
            <Reveal as="li" key={c.name} delay={(i % 4) * 80}>
              <div className={`brutal h-full rounded-3xl bg-paper p-4 transition-transform hover:-rotate-1 sm:p-5`}>
                <div className={`relative aspect-square overflow-hidden rounded-2xl border-[2.5px] border-ink ${tones[i % tones.length]}`}>
                  {c.photo ? (
                    <Image src={c.photo} alt={c.name} fill sizes="(max-width: 1024px) 45vw, 260px" className="object-cover" />
                  ) : (
                    <span className="flex h-full items-center justify-center font-display text-5xl font-extrabold">
                      {initials(c.name)}
                    </span>
                  )}
                </div>
                <p className="mt-4 font-display text-lg font-bold leading-tight">{c.name}</p>
                <p className="mt-1 line-clamp-3 text-sm text-ink-soft">{c.title}</p>
              </div>
            </Reveal>
          ))}
        </ul>

        <Reveal className="mt-14">
          <div className="flex flex-wrap items-center justify-center gap-x-10 gap-y-6 opacity-80">
            <Laurel className="hidden h-12 w-6 text-ink sm:block" />
            {site.universities.map((u) => (
              <Image key={u} src={u} alt="" width={160} height={60} className="h-12 w-auto object-contain grayscale sm:h-14" />
            ))}
            <Laurel flip className="hidden h-12 w-6 text-ink sm:block" />
          </div>
        </Reveal>

        <Reveal className="mt-16">
          <div className="brutal-lg grid items-center gap-6 rounded-[32px] bg-ink p-8 text-cream sm:p-10 lg:grid-cols-[1.5fr_1fr]">
            <div>
              <h3 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
                Tu enseignes ? Écris pour Sophia.
              </h3>
              <p className="mt-3 max-w-xl text-lg text-cream/80">
                Partage ta matière avec des centaines de milliers de lecteurs curieux, dans 30 langues. On
                s&apos;occupe des illustrations, des quiz et de la traduction.
              </p>
            </div>
            <div className="lg:text-right">
              <Button href={links.writeForUs} tone="saffron" size="lg">
                Proposer un cours
              </Button>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
