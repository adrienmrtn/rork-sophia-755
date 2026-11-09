import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { coursesOf, getSubject, subjects, toCard } from "@/lib/catalog";
import { PostCard, PostRow } from "@/components/posts";

export const dynamicParams = false;

export function generateStaticParams() {
  return subjects.map((s) => ({ slug: s.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const s = getSubject((await params).slug);
  return s ? { title: `${s.label} · Sophia`, description: s.blurb } : {};
}

const anchor = (t: string) => t.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-");

export default async function SubjectPage({ params }: { params: Promise<{ slug: string }> }) {
  const subject = getSubject((await params).slug);
  if (!subject) notFound();
  const groups = subject.subcategories.map((g) => ({ ...g, list: coursesOf(g.courses) }));
  const top = groups.flatMap((g) => g.list).filter((c) => c.author !== "redaction").slice(0, 3);
  const highlight = top.length >= 3 ? top : groups.flatMap((g) => g.list).slice(0, 3);

  return (
    <div className="mx-auto max-w-[1000px] px-4 py-10 sm:px-8 lg:py-14">
      <nav className="fade-up text-[14px] font-semibold text-ink-3" aria-label="Fil d'Ariane">
        <a href="/explorer" className="hover:text-navy">
          Explorer
        </a>{" "}
        / <span className="text-ink-2">{subject.label}</span>
      </nav>
      <h1 className="fade-up mt-3 text-[38px] font-extrabold tracking-[-0.03em] sm:text-[52px]" style={{ "--d": "60ms" } as React.CSSProperties}>
        {subject.label}
      </h1>
      <p className="fade-up mt-2 max-w-2xl font-serif text-[20px] leading-relaxed text-ink-2" style={{ "--d": "120ms" } as React.CSSProperties}>
        {subject.blurb} {subject.count} cours.
      </p>

      <div className="sticky top-14 z-10 -mx-4 mt-6 border-b border-line bg-paper/95 px-4 py-3 backdrop-blur lg:top-0">
        <div className="flex gap-2 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {groups.map((g) => (
            <a key={g.title} href={`#${anchor(g.title)}`} className="whitespace-nowrap rounded-full bg-sand px-3.5 py-1.5 text-[13px] font-bold text-ink-2 hover:text-ink">
              {g.title} <span className="text-ink-3">{g.list.length}</span>
            </a>
          ))}
        </div>
      </div>

      <ul className="mt-8 grid gap-4 sm:grid-cols-3">
        {highlight.map((c, i) => (
          <li key={c.slug} className="fade-up" style={{ "--d": `${180 + i * 70}ms` } as React.CSSProperties}>
            <PostCard c={toCard(c)} priority={i === 0} />
          </li>
        ))}
      </ul>

      {groups.map((g) => (
        <section key={g.title} id={anchor(g.title)} className="mt-12 scroll-mt-32 lg:scroll-mt-20">
          <h2 className="text-[22px] font-extrabold tracking-tight">
            {g.title} <span className="text-ink-3">· {g.list.length}</span>
          </h2>
          <div className="mt-2 max-w-[720px] divide-y divide-line">
            {g.list.map((c) => (
              <PostRow key={c.slug} c={toCard(c)} showSubject={false} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
