import Image from "next/image";
import { Avatar } from "./ui";
import { IconClock, IconVerified } from "./icons";

export type Card = {
  slug: string;
  title: string;
  hook: string;
  subtitle: string;
  image: string;
  subject: string;
  subjectSlug?: string;
  quizCount: number;
  author: { slug: string; name: string; title: string; photo: string | null };
};

export function Byline({ author, size = 22, extra }: { author: Card["author"]; size?: number; extra?: React.ReactNode }) {
  return (
    <div className="flex min-w-0 items-center gap-2 text-[13px] text-ink-2">
      <Avatar author={author} size={size} />
      <a href={`/auteurs/${author.slug}`} className="relative z-10 truncate font-semibold text-ink hover:underline">
        {author.name}
      </a>
      {author.slug !== "redaction" && <IconVerified className="h-3.5 w-3.5 shrink-0 text-sky" />}
      {extra}
    </div>
  );
}

/** Ligne de fil, comme une publication dans l'app Substack. */
export function PostRow({ c, showSubject = true }: { c: Card; showSubject?: boolean }) {
  return (
    <article className="group relative flex gap-4 py-5 sm:gap-6">
      <div className="min-w-0 flex-1">
        <Byline author={c.author} />
        <h3 className="mt-2 text-[18px] font-extrabold leading-snug tracking-tight transition-colors group-hover:text-navy sm:text-[20px]">
          <a href={`/cours/${c.slug}`} className="after:absolute after:inset-0">
            {c.title}
          </a>
        </h3>
        <p className="mt-1.5 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2 sm:text-[17px]">{c.hook}</p>
        <p className="mt-3 flex flex-wrap items-center gap-x-2 text-[12px] font-bold uppercase tracking-wider text-ink-3">
          {showSubject && (
            <>
              <span className="text-sky">{c.subject}</span>
              <span aria-hidden>·</span>
            </>
          )}
          <span className="inline-flex items-center gap-1">
            <IconClock className="h-3.5 w-3.5" /> 10 min
          </span>
          <span aria-hidden>·</span>
          <span>{c.quizCount} questions</span>
        </p>
      </div>
      <div className="relative aspect-[4/3] w-24 shrink-0 self-center overflow-hidden rounded-xl bg-sand sm:w-40">
        <Image src={c.image} alt="" fill sizes="(max-width: 640px) 96px, 160px" className="object-cover transition-transform duration-500 group-hover:scale-105" />
      </div>
    </article>
  );
}

/** Carte verticale (grilles). */
export function PostCard({ c, priority = false }: { c: Card; priority?: boolean }) {
  return (
    <article className="group relative flex h-full flex-col overflow-hidden rounded-[20px] bg-paper ring-1 ring-line transition-shadow hover:shadow-[0_24px_48px_-28px_rgba(22,38,61,0.4)]">
      <div className="relative aspect-[16/10] overflow-hidden bg-sand">
        <Image src={c.image} alt="" fill sizes="(max-width: 640px) 100vw, 360px" priority={priority} className="object-cover transition-transform duration-700 group-hover:scale-105" />
        <span className="absolute left-3 top-3 rounded-full bg-paper/95 px-2.5 py-1 text-[11px] font-bold text-navy">{c.subject}</span>
      </div>
      <div className="flex flex-1 flex-col p-5">
        <Byline author={c.author} />
        <h3 className="mt-2.5 text-[18px] font-extrabold leading-snug tracking-tight group-hover:text-navy">
          <a href={`/cours/${c.slug}`} className="after:absolute after:inset-0">
            {c.title}
          </a>
        </h3>
        <p className="mt-1.5 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2">{c.hook}</p>
      </div>
    </article>
  );
}

/** Grand article à la une. */
export function FeaturedPost({ c }: { c: Card }) {
  return (
    <article className="group relative overflow-hidden rounded-[24px] bg-paper ring-1 ring-line">
      <div className="relative aspect-[16/8] overflow-hidden bg-sand">
        <Image src={c.image} alt="" fill sizes="(max-width: 1024px) 100vw, 680px" priority className="object-cover transition-transform duration-700 group-hover:scale-[1.03]" />
        <span className="absolute left-4 top-4 rounded-full bg-saffron px-3 py-1 text-[12px] font-extrabold text-ink">Le cours du jour</span>
      </div>
      <div className="p-6">
        <Byline author={c.author} size={26} extra={<span className="text-ink-3">· {c.subject}</span>} />
        <h2 className="mt-3 text-[26px] font-extrabold leading-tight tracking-[-0.02em] group-hover:text-navy sm:text-[30px]">
          <a href={`/cours/${c.slug}`} className="after:absolute after:inset-0">
            {c.title}
          </a>
        </h2>
        <p className="mt-2 font-serif text-[19px] leading-snug text-ink-2">{c.hook}</p>
      </div>
    </article>
  );
}

export function SectionTitle({ eyebrow, title, action }: { eyebrow?: string; title: string; action?: React.ReactNode }) {
  return (
    <div className="flex items-end justify-between gap-4">
      <div>
        {eyebrow && <p className="eyebrow">{eyebrow}</p>}
        <h2 className="mt-1 text-[22px] font-extrabold tracking-tight">{title}</h2>
      </div>
      {action}
    </div>
  );
}
