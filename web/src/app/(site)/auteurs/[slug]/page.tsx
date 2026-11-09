import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { coursesOf, creators, getCreator, stats, subjects, toCard } from "@/lib/catalog";
import { FollowButton } from "@/components/interactive";
import { IconVerified } from "@/components/icons";
import { PostRow } from "@/components/posts";
import { Avatar, Button } from "@/components/ui";

export const dynamicParams = false;

export function generateStaticParams() {
  return creators.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const a = getCreator((await params).slug);
  return a ? { title: `${a.name} · Sophia`, description: a.title } : {};
}

const flag = (cc: string | null) =>
  cc && /^[A-Z]{2}$/.test(cc) ? String.fromCodePoint(...[...cc].map((ch) => 0x1f1a5 + ch.charCodeAt(0))) : "";

const linkLabels: Record<string, string> = { orcid: "ORCID", scholar: "Google Scholar", site: "Site web" };

export default async function AuthorPage({ params }: { params: Promise<{ slug: string }> }) {
  const author = getCreator((await params).slug);
  if (!author) notFound();
  const own = coursesOf(author.courses);
  const quiz = own.reduce((n, c) => n + c.quizCount, 0);
  const isHouse = author.slug === "redaction";
  const bySubject = subjects
    .map((s) => ({ s, list: own.filter((c) => c.subject === s.slug) }))
    .filter((g) => g.list.length);
  const banner = own.slice(0, 3);

  return (
    <div className="pb-16">
      <div className="relative h-40 overflow-hidden bg-sand sm:h-56">
        <div className="absolute inset-0 grid grid-cols-3">
          {banner.map((c) => (
            <div key={c.slug} className="relative">
              <Image src={c.image} alt="" fill sizes="33vw" className="object-cover" priority />
            </div>
          ))}
        </div>
        <div className="absolute inset-0 bg-gradient-to-b from-ink/10 to-ink/50" />
      </div>

      <div className="mx-auto max-w-[760px] px-4 sm:px-6">
        <div className="-mt-12 flex items-end justify-between gap-4 sm:-mt-14">
          <div className="fade-up rounded-full bg-paper p-1.5" style={{ "--d": "0ms" } as React.CSSProperties}>
            <Avatar author={{ name: author.name, title: author.title, photo: author.photo }} size={104} className="!ring-0" />
          </div>
          <div className="pb-2">
            <FollowButton slug={author.slug} />
          </div>
        </div>

        <h1 className="fade-up mt-4 flex items-center gap-2 text-[32px] font-extrabold tracking-[-0.03em] sm:text-[40px]" style={{ "--d": "80ms" } as React.CSSProperties}>
          {author.name}
          {!isHouse && <IconVerified className="h-7 w-7 text-sky" />}
        </h1>
        <p className="fade-up mt-1 text-[16px] font-semibold text-ink-2" style={{ "--d": "140ms" } as React.CSSProperties}>
          {author.title}
          {author.country ? ` · ${flag(author.country)}` : ""}
        </p>

        <dl className="mt-5 flex flex-wrap gap-x-8 gap-y-2 text-[14px]">
          <div>
            <dt className="sr-only">Cours</dt>
            <dd>
              <strong className="text-[18px] font-extrabold tabular-nums">{own.length}</strong> <span className="text-ink-2">cours</span>
            </dd>
          </div>
          <div>
            <dt className="sr-only">Questions</dt>
            <dd>
              <strong className="text-[18px] font-extrabold tabular-nums">{quiz}</strong> <span className="text-ink-2">questions de quiz</span>
            </dd>
          </div>
          <div>
            <dt className="sr-only">Langues</dt>
            <dd>
              <strong className="text-[18px] font-extrabold tabular-nums">{stats.languages}</strong> <span className="text-ink-2">langues</span>
            </dd>
          </div>
        </dl>

        <section className="mt-8">
          <p className="eyebrow">À propos</p>
          <p className="mt-3 font-serif text-[19px] leading-[1.65] text-ink/90">{author.bio}</p>
          {author.institution && <p className="mt-3 text-[14px] font-semibold text-ink-2">{author.institution}</p>}
          {Object.keys(author.links).length > 0 && (
            <div className="mt-4 flex flex-wrap gap-2">
              {Object.entries(author.links as Record<string, string>).map(([k, url]) => (
                <a key={k} href={url} target="_blank" rel="noopener" className="rounded-full px-3.5 py-1.5 text-[13px] font-bold text-navy ring-1 ring-line hover:bg-cream">
                  {linkLabels[k] ?? k} ↗
                </a>
              ))}
            </div>
          )}
        </section>

        <section className="mt-12">
          <div className="sticky top-14 z-10 -mx-4 border-b border-line bg-paper/95 px-4 py-3 backdrop-blur lg:top-0">
            <h2 className="text-[20px] font-extrabold tracking-tight">
              {isHouse ? "Les cours de la rédaction" : `Les cours de ${author.name.split(" ")[0]}`}
            </h2>
          </div>
          {bySubject.map(({ s, list }) => (
            <div key={s.slug} className="mt-6">
              {bySubject.length > 1 && (
                <p className="text-[13px] font-bold uppercase tracking-[0.14em] text-sky">
                  {s.label} · {list.length}
                </p>
              )}
              <div className="divide-y divide-line">
                {list.map((c) => (
                  <PostRow key={c.slug} c={toCard(c)} showSubject={false} />
                ))}
              </div>
            </div>
          ))}
        </section>

        {!isHouse && (
          <section className="mt-12 rounded-[22px] bg-cream p-6 sm:p-8">
            <p className="text-[20px] font-extrabold tracking-tight">Lire tous les cours de {author.name}</p>
            <p className="mt-2 font-serif text-[18px] text-ink-2">Avec Premium, chaque cours en entier, ses quiz et sa version audio.</p>
            <div className="mt-5">
              <Button href={`/commencer?auteur=${author.slug}`}>Essayer 3 jours gratuits</Button>
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
