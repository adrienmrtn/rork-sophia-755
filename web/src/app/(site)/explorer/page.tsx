import type { Metadata } from "next";
import Image from "next/image";
import { collections, courses, coursesOf, getCreator, guestCreators, stats, subjects } from "@/lib/catalog";
import { ExplorerSearch } from "@/components/ExplorerSearch";
import { SectionTitle } from "@/components/posts";
import { Arrow, Avatar } from "@/components/ui";

export const metadata: Metadata = { title: "Explorer · Sophia", description: `Les ${stats.courses} cours de Sophia, par matière, collection et auteur.` };

export default function ExplorerPage() {
  const items = courses.map((c) => ({ slug: c.slug, title: c.title, subject: c.subjectLabel, author: getCreator(c.author)!.name, image: c.image }));
  return (
    <div className="mx-auto max-w-[1000px] px-4 py-10 sm:px-8 lg:py-14">
      <h1 className="fade-up text-[36px] font-extrabold tracking-[-0.03em] sm:text-[44px]">Explorer</h1>
      <p className="fade-up mt-2 font-serif text-[20px] text-ink-2" style={{ "--d": "60ms" } as React.CSSProperties}>
        {stats.courses} cours, {stats.collections} collections, {stats.creators} auteurs.
      </p>
      <div className="fade-up mt-6" style={{ "--d": "120ms" } as React.CSSProperties}>
        <ExplorerSearch items={items} suggestions={["Napoléon", "Rome", "cerveau", "Picasso", "Grèce", "espace", "économie"]} />
      </div>

      <section className="mt-14">
        <SectionTitle title="Les matières" />
        <ul className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {subjects.map((s, i) => {
            const imgs = coursesOf(s.subcategories.flatMap((x) => x.courses)).slice(0, 4);
            return (
              <li key={s.slug} className="fade-up" style={{ "--d": `${160 + i * 60}ms` } as React.CSSProperties}>
                <a href={`/matieres/${s.slug}`} className="group block overflow-hidden rounded-[20px] ring-1 ring-line transition-shadow hover:shadow-[0_24px_48px_-28px_rgba(22,38,61,0.4)]">
                  <div className="grid aspect-[16/9] grid-cols-2 grid-rows-2 gap-0.5 bg-line">
                    {imgs.map((c) => (
                      <div key={c.slug} className="relative overflow-hidden">
                        <Image src={c.image} alt="" fill sizes="180px" className="object-cover transition-transform duration-700 group-hover:scale-110" />
                      </div>
                    ))}
                  </div>
                  <div className="p-5">
                    <p className="flex items-center justify-between text-[19px] font-extrabold tracking-tight group-hover:text-navy">
                      {s.label} <span className="text-[14px] font-bold text-ink-3">{s.count}</span>
                    </p>
                    <p className="mt-1 font-serif text-[16px] leading-snug text-ink-2">{s.blurb}</p>
                  </div>
                </a>
              </li>
            );
          })}
        </ul>
      </section>

      <section className="mt-14">
        <SectionTitle
          title="Collections"
          action={
            <a href="/collections" className="inline-flex items-center gap-1 text-[14px] font-bold text-navy hover:underline">
              Tout voir <Arrow className="h-3.5 w-3.5" />
            </a>
          }
        />
        <ul className="-mx-4 mt-5 flex snap-x gap-4 overflow-x-auto px-4 pb-3 [scrollbar-width:thin]">
          {collections.slice(0, 10).map((c) => (
            <li key={c.slug} className="w-[260px] shrink-0 snap-start">
              <a href={`/collections/${c.slug}`} className="group block">
                <div className="relative aspect-[16/9] overflow-hidden rounded-2xl">
                  <Image src={c.image} alt="" fill sizes="260px" className="object-cover transition-transform duration-700 group-hover:scale-105" />
                </div>
                <p className="mt-2.5 text-[15px] font-extrabold leading-snug group-hover:text-navy">{c.title}</p>
                <p className="text-[13px] text-ink-3">{c.courses.length} cours</p>
              </a>
            </li>
          ))}
        </ul>
      </section>

      <section className="mt-14">
        <SectionTitle
          title="Auteurs"
          action={
            <a href="/auteurs" className="inline-flex items-center gap-1 text-[14px] font-bold text-navy hover:underline">
              Tout voir <Arrow className="h-3.5 w-3.5" />
            </a>
          }
        />
        <ul className="mt-5 grid grid-cols-2 gap-4 sm:grid-cols-4">
          {guestCreators.slice(0, 8).map((a) => (
            <li key={a.slug}>
              <a href={`/auteurs/${a.slug}`} className="group flex flex-col items-center rounded-[20px] p-4 text-center ring-1 ring-line hover:bg-cream">
                <Avatar author={a} size={64} className="!ring-0" />
                <p className="mt-3 line-clamp-1 text-[15px] font-extrabold group-hover:text-navy">{a.name}</p>
                <p className="text-[12.5px] text-ink-3">{a.courses.length} cours</p>
              </a>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}
