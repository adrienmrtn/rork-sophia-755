import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import { notFound, permanentRedirect } from "next/navigation";
import { CourseCard } from "@/components/CourseCard";
import { AuthorAvatar } from "@/components/AuthorCard";
import { BlockView, creditLine } from "@/components/CourseBlocks";
import { SiteHeader } from "@/components/SiteChrome";
import { StoreButtons } from "@/components/StoreButtons";
import { ArrowIcon, ButtonLink, Pill, container } from "@/components/ui";
import { renderInline } from "@/lib/catalog/inline";
import { catalog, freeSection, isTextBlock } from "@/lib/catalog/source";
import { creatorMap } from "@/lib/catalog/select";
import { authorPath, coursePath, parseCourseParam, SUBJECT_LABEL, subjectParam } from "@/lib/catalog/slugs";
import type { Block, CourseDetail } from "@/lib/catalog/types";
import { t } from "@/lib/copy/en";
import { APP_STORE_ID, SITE_URL } from "@/lib/env";

export const dynamic = "force-dynamic";

async function load(slug: string): Promise<CourseDetail | null> {
  const number = parseCourseParam(slug);
  if (number === null) return null;
  return catalog.getCourse("en", number);
}

export async function generateMetadata({ params }: PageProps<"/courses/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const course = await load(slug);
  if (!course) return { title: "Course not found" };
  const description = course.description.replace(/\*\*|\*/g, "").slice(0, 300);
  return {
    title: course.title,
    description,
    alternates: { canonical: coursePath(course) },
    openGraph: { title: course.title, description, url: coursePath(course), siteName: "Sophia", images: course.coverUrl ? [{ url: course.coverUrl }] : undefined, type: "article" },
    twitter: { card: course.coverUrl ? "summary_large_image" : "summary", title: course.title, description, images: course.coverUrl ? [course.coverUrl] : undefined },
    // Bannière Safari : « Ouvrir » l'app sur ce cours si elle est installée, sinon l'App Store.
    itunes: { appId: APP_STORE_ID, appArgument: `${SITE_URL}${coursePath(course)}` },
  };
}

const CLASS_LABEL: Record<string, string> = {
  referenceHistorique: "reference",
  concept: "concept",
  evenementConnexe: "event",
  personnage: "person",
  lieuInstitution: "place",
};

export default async function CoursePage({ params }: PageProps<"/courses/[slug]">) {
  const { slug } = await params;
  const course = await load(slug);
  if (!course) notFound();
  const canonical = coursePath(course);
  if (`/courses/${slug}` !== canonical) permanentRedirect(canonical);

  const [all, creators] = await Promise.all([catalog.listCourses("en"), catalog.listCreators("en")]);
  const byCreator = creatorMap(creators);
  const creator = course.creatorSlug ? byCreator.get(course.creatorSlug) ?? null : null;
  const intro = freeSection(course);
  const others = all.filter((c) => c.subject === course.subject && c.id !== course.id).slice(0, 4);
  const coverCredit = creditLine(Object.values(course.credits).length ? course.credits[Object.keys(course.credits)[0]] : null);
  const c = t.course;
  const totalParts = course.sections.length || course.sectionCount;
  const glossaryShown = course.glossary.slice(0, 4);

  return (
    <>
      <SiteHeader active="explore" />
      <main className={`${container} flex flex-col gap-10 pt-8 pb-24`}>
        <nav aria-label="Breadcrumb" className="flex flex-wrap items-center gap-2 text-[13px] font-semibold text-ink-3">
          <Link href="/courses">{c.breadcrumbExplore}</Link>
          <span aria-hidden="true">›</span>
          <Link href={`/courses?subject=${subjectParam(course.subject)}`}>{SUBJECT_LABEL[course.subject]}</Link>
          {course.subcategory && (
            <>
              <span aria-hidden="true">›</span>
              <span className="text-ink">{course.subcategory}</span>
            </>
          )}
        </nav>

        {/* Tête */}
        <div className="flex flex-wrap items-start gap-x-12 gap-y-8">
          <div className="flex min-w-0 flex-[1_1_520px] flex-col gap-[18px]">
            <Pill className="self-start">
              {SUBJECT_LABEL[course.subject]}
              {course.subcategory ? ` · ${course.subcategory}` : ""}
            </Pill>
            <h1 className="text-[36px] font-extrabold leading-[1.08] tracking-[-1px] md:text-[46px] md:tracking-[-1.3px]">{course.title}</h1>
            {course.hook && <p className="text-[19px] leading-[1.5] text-ink-3">{renderInline(course.hook)}</p>}
            <div className="flex flex-wrap items-center gap-x-[18px] gap-y-2 text-[14px] font-semibold text-ink-2">
              {course.subtitle && <span>{course.subtitle}</span>}
              <span>{c.minutes(course.minutes)}</span>
              <span>{c.parts(totalParts)}</span>
              {course.quizCount > 0 && <span>{c.quiz(course.quizCount)}</span>}
            </div>
            <div className="flex flex-wrap items-center gap-2.5 pt-1">
              <ButtonLink href="#rest" className="h-12 px-5">
                {c.readInApp} <ArrowIcon />
              </ButtonLink>
              <span className="text-[13px] text-ink-3">{c.availableIn(course.languages.length || 30)}</span>
            </div>
          </div>
          {course.coverUrl && (
            <figure className="m-0 flex min-w-0 flex-[1_1_460px] flex-col gap-2.5">
              <Image src={course.coverUrl} alt="" width={1200} height={750} priority className="aspect-[16/10] w-full rounded-card bg-tint object-cover" />
              {coverCredit && <figcaption className="text-[12px] text-muted">{coverCredit}</figcaption>}
            </figure>
          )}
        </div>

        {/* Lecture + colonne */}
        <div className="flex flex-wrap items-start gap-x-14 gap-y-10">
          <article className="flex min-w-0 max-w-[720px] flex-[999_1_560px] flex-col gap-7">
            {intro && (
              <>
                <div className="flex items-center justify-between gap-3 border-b border-line pb-3.5">
                  <span className="text-[13px] font-bold uppercase tracking-[1.2px] text-blue">
                    {c.partOf(1, totalParts)} · {c.free}
                  </span>
                  <span className="text-[13px] font-semibold text-ink-3">{intro.title}</span>
                </div>
                <div className="prose-course flex flex-col">
                  {intro.blocks.map((b, i) => (
                    <BlockView key={i} block={b} credits={course.credits} />
                  ))}
                </div>
              </>
            )}

            {/* La suite dans l’app */}
            <div id="rest" className="flex flex-col gap-[18px] rounded-card border border-line bg-paper p-7">
              <div className="flex flex-col gap-1.5">
                <strong className="text-[20px] font-extrabold text-ink">{c.restTitle}</strong>
                <span className="text-[15px] leading-[1.5] text-ink-3">{c.restLead}</span>
              </div>
              {course.sections.length > 1 && (
                <ol className="flex flex-col border-t border-line">
                  {course.sections.slice(1).map((s, i) => (
                    <li key={s.id ?? i} className="flex items-center gap-3 border-b border-line py-3 text-[15px] font-semibold text-ink-2">
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#8994A6" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                        <rect x="5" y="11" width="14" height="10" rx="2" />
                        <path d="M8 11V8a4 4 0 0 1 8 0v3" />
                      </svg>
                      <span className="w-5 text-muted">{i + 2}</span>
                      {s.title}
                    </li>
                  ))}
                </ol>
              )}
              <div className="flex flex-wrap items-center gap-2.5">
                <StoreButtons size="compact" resumeUrl={`${SITE_URL}${canonical}`} />
                <a href={`sophia://course/${course.id}`} className="inline-flex h-[46px] items-center px-3 text-[14px] font-bold text-blue">
                  {c.alreadyInstalled}
                </a>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-3">
              <div className="flex flex-col gap-1.5 rounded-2xl border border-line px-[18px] py-4">
                <strong className="text-[15px] font-extrabold">{c.contains.quiz}</strong>
                <span className="text-[13px] leading-[1.45] text-ink-3">{c.contains.quizLead(course.quizCount || 8)}</span>
              </div>
              <div className="flex flex-col gap-1.5 rounded-2xl border border-line px-[18px] py-4">
                <strong className="text-[15px] font-extrabold">{c.contains.glossary}</strong>
                <span className="text-[13px] leading-[1.45] text-ink-3">{c.contains.glossaryLead(course.glossary.length)}</span>
              </div>
              <div className="flex flex-col gap-1.5 rounded-2xl border border-line px-[18px] py-4">
                <strong className="text-[15px] font-extrabold">{c.contains.languages}</strong>
                <span className="text-[13px] leading-[1.45] text-ink-3">{c.contains.languagesLead}</span>
              </div>
            </div>
          </article>

          <aside className="flex min-w-0 max-w-[360px] flex-[1_1_300px] flex-col gap-5">
            {course.sections.length > 0 && (
              <div className="flex flex-col gap-3 rounded-[18px] border border-line p-5">
                <strong className="text-[13px] font-bold uppercase tracking-[1px] text-muted">{c.inThisCourse}</strong>
                <ol className="flex flex-col gap-2.5 text-[14px] font-semibold text-ink-2">
                  {course.sections.map((s, i) => (
                    <li key={s.id ?? i} className="flex items-baseline gap-2.5">
                      <span className={`inline-flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full text-[12px] font-extrabold ${i === 0 ? "bg-navy text-white" : "bg-tint text-navy"}`}>{i + 1}</span>
                      <span>
                        {s.title}
                        {i === 0 && <span className="font-bold text-green-2"> · {c.free}</span>}
                      </span>
                    </li>
                  ))}
                </ol>
              </div>
            )}
            {glossaryShown.length > 0 && (
              <div id="glossary" className="flex flex-col gap-3 rounded-[18px] border border-line p-5">
                <strong className="text-[13px] font-bold uppercase tracking-[1px] text-muted">{c.glossary}</strong>
                <dl className="flex flex-col gap-3">
                  {glossaryShown.map((g) => (
                    <div key={g.term} className="flex flex-col gap-0.5">
                      <dt className="text-[14px] font-bold text-ink">
                        {g.term} <span className="text-[11px] font-bold uppercase tracking-[.5px] text-muted">· {CLASS_LABEL[g.classification] ?? g.classification}</span>
                      </dt>
                      <dd className="m-0 text-[13px] leading-[1.45] text-ink-3">{g.explanation}</dd>
                    </div>
                  ))}
                </dl>
                {course.glossary.length > glossaryShown.length && <span className="text-[12px] text-muted">{c.moreTerms(course.glossary.length - glossaryShown.length)}</span>}
              </div>
            )}
            {course.sources.length > 0 && (
              <div className="flex flex-col gap-3 rounded-[18px] border border-line p-5">
                <strong className="text-[13px] font-bold uppercase tracking-[1px] text-muted">{c.sources}</strong>
                <ul className="flex flex-col gap-2 text-[13px] leading-[1.45] text-ink-2">
                  {course.sources.map((s, i) => (
                    <li key={i}>{s.url ? <a href={s.url} className="underline decoration-line-2 underline-offset-2 hover:text-navy">{s.text}</a> : s.text}</li>
                  ))}
                </ul>
              </div>
            )}
            <div className="flex flex-col gap-3 rounded-[18px] border border-line bg-paper p-5">
              {creator ? (
                <>
                  <div className="flex items-center gap-3">
                    <AuthorAvatar creator={creator} size={48} />
                    <span className="flex flex-col">
                      <span className="text-[12px] font-bold uppercase tracking-[.6px] text-muted">{c.by}</span>
                      <strong className="text-[15px] font-bold text-ink">{creator.name}</strong>
                    </span>
                  </div>
                  {creator.title && <span className="text-[13px] leading-[1.45] text-ink-3">{creator.title}</span>}
                  <Link href={authorPath(creator.slug)} className="text-[14px] font-bold text-blue">
                    {creator.courseIds.length > 1 ? t.author.courses(creator.courseIds.length) : t.author.breadcrumb} <ArrowIcon className="inline" />
                  </Link>
                </>
              ) : (
                <>
                  <strong className="text-[13px] font-bold uppercase tracking-[1px] text-muted">{c.aSophiaCourse}</strong>
                  <span className="text-[14px] leading-[1.5] text-ink-2">{c.houseAuthor}</span>
                  <Link href="/authors" className="text-[14px] font-bold text-blue">
                    {c.seeAuthors}
                  </Link>
                </>
              )}
            </div>
          </aside>
        </div>

        {/* Même matière */}
        {others.length > 0 && (
          <section className="flex flex-col gap-6 border-t border-line pt-6">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <h2 className="text-[28px] font-extrabold tracking-[-0.7px]">{c.sameSubject}</h2>
              <Link href={`/courses?subject=${subjectParam(course.subject)}`} className="text-[15px] font-bold text-blue">
                {c.allOf(SUBJECT_LABEL[course.subject])}
              </Link>
            </div>
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
              {others.map((o, i) => (
                <CourseCard key={o.id} course={o} creator={o.creatorSlug ? byCreator.get(o.creatorSlug) : null} index={i} />
              ))}
            </div>
          </section>
        )}
      </main>
    </>
  );
}

export function TextBlockGuard(block: Block) {
  return isTextBlock(block);
}
