import Image from "next/image";
import { site } from "@/lib/site";
import { Reveal } from "./Reveal";

type Col = (typeof site.collections)[number];

function Row({ items, reverse = false, duration = 70 }: { items: Col[]; reverse?: boolean; duration?: number }) {
  const loop = [...items, ...items];
  return (
    <div className="group flex overflow-hidden py-3">
      <ul
        className="flex shrink-0 animate-marquee gap-6 pr-6 group-hover:[animation-play-state:paused]"
        style={
          {
            "--marquee-duration": `${duration}s`,
            animationDirection: reverse ? "reverse" : "normal",
          } as React.CSSProperties
        }
      >
        {loop.map((c, i) => (
          <li
            key={`${c.id}-${i}`}
            aria-hidden={i >= items.length}
            className="brutal w-[280px] shrink-0 overflow-hidden rounded-3xl bg-paper sm:w-[320px]"
          >
            <div className="relative aspect-[16/9] border-b-[2.5px] border-ink">
              <Image src={c.image} alt="" fill sizes="320px" className="object-cover" />
              <span className="absolute right-3 top-3 rounded-full border-2 border-ink bg-paper px-2 py-0.5 text-xs font-bold">
                {c.count} cours
              </span>
            </div>
            <div className="p-4">
              <p className="font-display text-lg font-bold leading-snug">{c.title}</p>
              <p className="mt-1 line-clamp-2 text-sm text-ink-soft">{c.description}</p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function Collections() {
  const half = Math.ceil(site.collections.length / 2);
  return (
    <section className="overflow-hidden border-b-[3px] border-ink bg-violet-soft py-20 sm:py-24">
      <Reveal className="mx-auto max-w-6xl px-4 text-center sm:px-6">
        <h2 className="font-display text-4xl font-extrabold tracking-tight sm:text-5xl">
          {site.stats.collections} collections pour aller plus loin
        </h2>
        <p className="mx-auto mt-4 max-w-2xl text-lg text-ink-soft">
          Des parcours thématiques qui relient l&apos;histoire, les sciences et l&apos;art. Des pyramides
          à Gengis Khan, de Gilgamesh à Superman.
        </p>
      </Reveal>
      <div className="mt-12 space-y-3">
        <Row items={site.collections.slice(0, half)} duration={80} />
        <Row items={site.collections.slice(half)} reverse duration={90} />
      </div>
    </section>
  );
}
