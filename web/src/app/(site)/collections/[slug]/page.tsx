import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { collections, coursesOf, getCollection, toCard } from "@/lib/catalog";
import { Byline } from "@/components/posts";
import { Arrow, Button } from "@/components/ui";

export const dynamicParams = false;

export function generateStaticParams() {
  return collections.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const c = getCollection((await params).slug);
  return c ? { title: `${c.title} · Sophia`, description: c.description, openGraph: { images: [c.image] } } : {};
}

export default async function CollectionPage({ params }: { params: Promise<{ slug: string }> }) {
  const col = getCollection((await params).slug);
  if (!col) notFound();
  const list = coursesOf(col.courses);
  const others = collections.filter((c) => c.slug !== col.slug).slice(0, 3);

  return (
    <div className="pb-16">
      <div className="relative">
        <div className="relative aspect-[16/7] max-h-[420px] w-full overflow-hidden bg-sand">
          <Image src={col.image} alt="" fill priority sizes="100vw" className="object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-ink/80 via-ink/20 to-transparent" />
        </div>
        <div className="absolute inset-x-0 bottom-0 mx-auto max-w-[760px] px-4 pb-6 text-white sm:px-6 sm:pb-10">
          <p className="fade-up text-[12px] font-bold uppercase tracking-[0.14em] text-saffron">Collection · {list.length} cours</p>
          <h1 className="fade-up mt-2 text-[30px] font-extrabold leading-[1.08] tracking-[-0.03em] sm:text-[44px]" style={{ "--d": "80ms" } as React.CSSProperties}>
            {col.title}
          </h1>
        </div>
      </div>

      <div className="mx-auto max-w-[760px] px-4 sm:px-6">
        <p className="mt-8 font-serif text-[21px] leading-relaxed text-ink-2">{col.description}</p>

        <ol className="mt-8 space-y-3">
          {list.map((c, i) => {
            const card = toCard(c);
            return (
              <li key={c.slug} className="fade-up group relative flex gap-4 rounded-[20px] p-4 ring-1 ring-line transition-colors hover:bg-cream sm:gap-5" style={{ "--d": `${120 + i * 60}ms` } as React.CSSProperties}>
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-navy text-[15px] font-extrabold text-white tabular-nums">{i + 1}</span>
                <div className="min-w-0 flex-1">
                  <Byline author={card.author} />
                  <a href={`/cours/${c.slug}`} className="mt-1.5 block text-[18px] font-extrabold leading-snug after:absolute after:inset-0 group-hover:text-navy">
                    {c.title}
                  </a>
                  <p className="mt-1 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2">{c.hook}</p>
                </div>
                <div className="relative hidden aspect-[4/3] w-28 shrink-0 self-center overflow-hidden rounded-xl sm:block">
                  <Image src={c.image} alt="" fill sizes="112px" className="object-cover" />
                </div>
              </li>
            );
          })}
        </ol>

        <div className="mt-10 flex flex-col items-start justify-between gap-4 rounded-[22px] bg-cream p-6 sm:flex-row sm:items-center">
          <p className="font-serif text-[18px] text-ink-2">Toute la collection, ses quiz et sa version audio avec Premium.</p>
          <Button href={`/commencer?collection=${col.slug}`}>
            Essayer gratuitement <Arrow />
          </Button>
        </div>

        <section className="mt-14">
          <p className="eyebrow">Autres collections</p>
          <ul className="mt-4 grid gap-4 sm:grid-cols-3">
            {others.map((c) => (
              <li key={c.slug}>
                <a href={`/collections/${c.slug}`} className="group block">
                  <div className="relative aspect-[16/9] overflow-hidden rounded-xl">
                    <Image src={c.image} alt="" fill sizes="240px" className="object-cover transition-transform duration-700 group-hover:scale-105" />
                  </div>
                  <p className="mt-2 text-[15px] font-extrabold leading-snug group-hover:text-navy">{c.title}</p>
                </a>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
}
