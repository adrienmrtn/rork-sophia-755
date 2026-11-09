import type { Metadata } from "next";
import Image from "next/image";
import { collections, stats } from "@/lib/catalog";

export const metadata: Metadata = { title: "Collections · Sophia", description: `${stats.collections} parcours thématiques pour aller plus loin.` };

export default function CollectionsPage() {
  return (
    <div className="mx-auto max-w-[1100px] px-4 py-10 sm:px-8 lg:py-14">
      <p className="fade-up eyebrow">Les collections</p>
      <h1 className="fade-up mt-3 max-w-2xl text-[36px] font-extrabold leading-[1.06] tracking-[-0.03em] sm:text-[48px]" style={{ "--d": "60ms" } as React.CSSProperties}>
        {stats.collections} parcours pour aller plus loin
      </h1>
      <p className="fade-up mt-4 max-w-2xl font-serif text-[20px] leading-relaxed text-ink-2" style={{ "--d": "120ms" } as React.CSSProperties}>
        Des séries de cinq à sept cours qui relient les époques et les disciplines. Des pyramides à Gengis Khan, de Gilgamesh à Superman.
      </p>
      <ul className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {collections.map((c, i) => (
          <li key={c.slug} className="fade-up" style={{ "--d": `${Math.min(i, 9) * 50 + 150}ms` } as React.CSSProperties}>
            <a href={`/collections/${c.slug}`} className="group block h-full overflow-hidden rounded-[20px] ring-1 ring-line transition-shadow hover:shadow-[0_24px_48px_-28px_rgba(22,38,61,0.4)]">
              <div className="relative aspect-[16/9] overflow-hidden">
                <Image src={c.image} alt="" fill sizes="(max-width: 640px) 100vw, 340px" className="object-cover transition-transform duration-700 group-hover:scale-105" priority={i < 3} />
              </div>
              <div className="p-5">
                <p className="text-[12px] font-bold uppercase tracking-wider text-ink-3">{c.courses.length} cours</p>
                <h2 className="mt-1 text-[18px] font-extrabold leading-snug tracking-tight group-hover:text-navy">{c.title}</h2>
                <p className="mt-1.5 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2">{c.description}</p>
              </div>
            </a>
          </li>
        ))}
      </ul>
    </div>
  );
}
