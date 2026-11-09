import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { courses, coursesOf, getCollection, getCourse, getCourseBody, getCreator, toCard } from "@/lib/catalog";
import { links } from "@/lib/config";
import { RichText } from "@/components/RichText";
import { ActionBar, FollowButton, OneQuestion } from "@/components/interactive";
import { IconLock, IconVerified } from "@/components/icons";
import { PostRow } from "@/components/posts";
import { Arrow, Avatar, Button } from "@/components/ui";

export const dynamicParams = false;

export function generateStaticParams() {
  return courses.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const c = getCourse((await params).slug);
  if (!c) return {};
  return { title: `${c.title} · Sophia`, description: c.hook, openGraph: { title: c.title, description: c.hook, images: [c.image] } };
}

export default async function CoursePage({ params }: { params: Promise<{ slug: string }> }) {
  const course = getCourse((await params).slug);
  if (!course) notFound();
  const body = getCourseBody(course.slug);
  const author = getCreator(course.author)!;
  const card = toCard(course);
  const collection = course.collections[0] ? getCollection(course.collections[0]) : undefined;
  const related = (collection ? coursesOf(collection.courses) : courses.filter((c) => c.subject === course.subject))
    .filter((c) => c.slug !== course.slug)
    .slice(0, 3);
  const locked = body.sections.slice(1);
  const firstParagraph = body.intro.findIndex((b) => b.type === "paragraph");

  return (
    <article className="mx-auto max-w-[700px] px-4 pb-16 pt-8 sm:px-6 lg:pt-14">
      <a href={`/matieres/${course.subject}`} className="fade-up eyebrow hover:underline" style={{ "--d": "0ms" } as React.CSSProperties}>
        {course.subjectLabel}
        {course.subcategory ? ` · ${course.subcategory}` : ""}
      </a>
      <h1 className="fade-up mt-3 text-[34px] font-extrabold leading-[1.08] tracking-[-0.03em] sm:text-[44px]" style={{ "--d": "60ms" } as React.CSSProperties}>
        {course.title}
      </h1>
      <p className="fade-up mt-4 font-serif text-[21px] leading-snug text-ink-2 sm:text-[23px]" style={{ "--d": "140ms" } as React.CSSProperties}>
        {course.hook}
      </p>

      <div className="fade-up mt-6 flex items-center gap-3" style={{ "--d": "220ms" } as React.CSSProperties}>
        <Avatar author={card.author} size={44} className="!ring-0" />
        <div className="min-w-0 flex-1">
          <a href={`/auteurs/${author.slug}`} className="flex items-center gap-1 text-[15px] font-bold hover:underline">
            {author.name}
            {author.slug !== "redaction" && <IconVerified className="h-4 w-4 text-sky" />}
          </a>
          <p className="text-[13px] text-ink-2">
            {course.subtitle ? `${course.subtitle} · ` : ""}10 min de lecture · Quiz de {course.quizCount} questions
          </p>
        </div>
        <FollowButton slug={author.slug} size="sm" />
      </div>

      <div className="mt-6">
        <ActionBar slug={course.slug} title={course.title} />
      </div>

      <div className="relative mt-8 aspect-[16/9] overflow-hidden rounded-[20px] bg-sand">
        <Image src={course.image} alt="" fill priority sizes="(max-width: 760px) 100vw, 700px" className="object-cover" />
      </div>

      <div className="mt-10 space-y-6 font-serif text-[20px] leading-[1.7] text-ink/90">
        <p className="font-sans text-[13px] font-bold uppercase tracking-[0.14em] text-ink-3">{body.sections[0]}</p>
        {body.intro.map((b, i) =>
          b.type === "paragraph" ? (
            <p key={i} className={i === firstParagraph ? "drop-cap" : ""}>
              <RichText text={b.text} />
            </p>
          ) : (
            <aside key={i} className="rounded-2xl bg-saffron-soft px-6 py-5 text-[18px] leading-relaxed">
              <p className="font-sans text-[13px] font-extrabold uppercase tracking-wider text-navy">Le savais-tu ?</p>
              <p className="mt-1.5">
                <RichText text={b.text} />
              </p>
            </aside>
          ),
        )}
      </div>

      {/* Mur d'abonnement, comme un article réservé aux abonnés. */}
      <div className="relative mt-8">
        {body.teaser && (
          <div className="relative max-h-40 overflow-hidden" aria-hidden>
            <p className="font-sans text-[13px] font-bold uppercase tracking-[0.14em] text-ink-3">{locked[0]}</p>
            <p className="mt-4 select-none font-serif text-[20px] leading-[1.7] text-ink/90 blur-[3px]">
              <RichText text={body.teaser} />
            </p>
            <div className="absolute inset-0 bg-gradient-to-b from-transparent via-paper/70 to-paper" />
          </div>
        )}
        <div className="relative -mt-4 rounded-[24px] bg-paper p-6 text-center shadow-[0_30px_60px_-30px_rgba(22,38,61,0.35)] ring-1 ring-line sm:p-9">
          <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-navy text-white">
            <IconLock className="h-5 w-5" />
          </span>
          <h2 className="mt-4 text-[24px] font-extrabold tracking-tight">La suite de ce cours est réservée aux abonnés</h2>
          <p className="mx-auto mt-2 max-w-md font-serif text-[18px] leading-snug text-ink-2">
            Encore {locked.length} parties et un quiz de {course.quizCount} questions. Trois jours gratuits pour tout lire.
          </p>
          <ol className="mx-auto mt-6 max-w-sm space-y-2 text-left">
            {locked.map((s, i) => (
              <li key={s} className="flex items-center gap-3 rounded-xl bg-cream px-4 py-2.5 text-[14.5px] font-semibold text-ink-2">
                <span className="tabular-nums text-ink-3">{i + 2}</span>
                <span className="flex-1">{s}</span>
                <IconLock className="h-4 w-4 text-ink-3" />
              </li>
            ))}
          </ol>
          <div className="mt-7 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
            <Button href={`/commencer?cours=${course.slug}`} size="lg">
              Essayer 3 jours gratuits <Arrow />
            </Button>
            <Button href={links.download} variant="secondary" size="lg">
              Lire dans l&apos;app
            </Button>
          </div>
        </div>
      </div>

      {body.quiz && (
        <div className="mt-12">
          <OneQuestion quiz={body.quiz} />
        </div>
      )}

      <section className="mt-12 rounded-[22px] p-6 ring-1 ring-line">
        <div className="flex items-start gap-4">
          <Avatar author={card.author} size={56} className="!ring-0" />
          <div className="min-w-0 flex-1">
            <p className="text-[12px] font-bold uppercase tracking-[0.14em] text-ink-3">À propos de l&apos;auteur</p>
            <a href={`/auteurs/${author.slug}`} className="mt-1 block text-[18px] font-extrabold hover:underline">
              {author.name}
            </a>
            <p className="text-[14px] text-ink-2">{author.title}</p>
          </div>
          <FollowButton slug={author.slug} size="sm" />
        </div>
        <p className="mt-4 line-clamp-4 font-serif text-[17px] leading-relaxed text-ink-2">{author.bio}</p>
        <a href={`/auteurs/${author.slug}`} className="mt-3 inline-flex items-center gap-1 text-[14px] font-bold text-navy hover:underline">
          Ses {author.courses.length} cours <Arrow className="h-3.5 w-3.5" />
        </a>
      </section>

      {related.length > 0 && (
        <section className="mt-12">
          <p className="eyebrow">{collection ? "Dans la même collection" : `Plus de cours en ${course.subjectLabel.toLowerCase()}`}</p>
          {collection && (
            <a href={`/collections/${collection.slug}`} className="mt-1 block text-[22px] font-extrabold tracking-tight hover:text-navy">
              {collection.title}
            </a>
          )}
          <div className="mt-2 divide-y divide-line">
            {related.map((c) => (
              <PostRow key={c.slug} c={toCard(c)} />
            ))}
          </div>
        </section>
      )}
    </article>
  );
}
