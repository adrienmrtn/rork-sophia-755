import Image from "next/image";
import Link from "next/link";
import { AuthorCard } from "@/components/AuthorCard";
import { CourseCard } from "@/components/CourseCard";
import { SiteHeader } from "@/components/SiteChrome";
import { StoreButtons } from "@/components/StoreButtons";
import { ArrowIcon, ButtonLink, CheckIcon, Dot, Eyebrow, Pill, container } from "@/components/ui";
import { catalog } from "@/lib/catalog/source";
import { creatorMap, creatorsWithPhoto, featuredCourses, sampleTitles, subjectCounts } from "@/lib/catalog/select";
import { SUBJECT_ART, SUBJECT_LABEL, subjectParam } from "@/lib/catalog/slugs";
import { SUBJECTS } from "@/lib/catalog/types";
import { t } from "@/lib/copy/en";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const [courses, creators] = await Promise.all([catalog.listCourses("en"), catalog.listCreators("en")]);
  const counts = subjectCounts(courses);
  const featured = featuredCourses(courses, 4);
  const byCreator = creatorMap(creators);
  const authors = creatorsWithPhoto(creators, 8);
  const h = t.home;

  return (
    <>
      <SiteHeader />
      <main>
        {/* Héros */}
        <section id="download" className={`${container} flex flex-wrap items-center gap-x-14 gap-y-10 pt-16 pb-[72px]`}>
          <div className="flex min-w-0 flex-[1_1_520px] flex-col gap-[22px]">
            <Eyebrow>{h.eyebrow}</Eyebrow>
            <h1 className="text-[44px] font-extrabold leading-[1.04] tracking-[-1.4px] text-ink md:text-[60px] md:tracking-[-1.8px]">{h.title}</h1>
            <p className="max-w-[560px] text-[20px] leading-[1.5] text-ink-3">{h.lead}</p>
            <div className="flex flex-wrap items-center gap-3 pt-1">
              <StoreButtons />
              <Link href="/write" className="inline-flex h-14 items-center gap-1.5 px-3 text-[16px] font-bold text-blue">
                {h.writeLink} <ArrowIcon />
              </Link>
            </div>
            <div className="flex flex-wrap items-center gap-x-[18px] gap-y-2.5 pt-1.5 text-[14px] font-semibold text-ink-2">
              <span className="inline-flex items-center gap-1.5">
                <CheckIcon className="h-4 w-4 text-green-2" />
                {h.rating}
              </span>
              <Dot />
              <span>{h.readers}</span>
              <Dot />
              <span>{courses.length || 310} {t.explore.results}</span>
              <Dot />
              <span>{h.languages}</span>
            </div>
          </div>
          <div className="flex min-w-0 flex-[1_1_460px] justify-center">
            <Image src="/art/hero.webp" alt={h.heroAlt} width={1365} height={1024} priority className="aspect-[4/3] w-full max-w-[600px] rounded-[28px] object-cover shadow-[0_24px_60px_rgba(22,38,61,.16)]" />
          </div>
        </section>

        {/* L’app en trois écrans */}
        <section className="border-y border-line bg-paper">
          <div className={`${container} flex flex-col gap-10 pt-16`}>
            <div className="flex max-w-[720px] flex-col gap-2.5">
              <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px]">{h.appTitle}</h2>
              <p className="text-[17px] leading-[1.5] text-ink-3">{h.appLead}</p>
            </div>
            <div className="grid grid-cols-1 items-end gap-6 sm:grid-cols-3">
              {[
                ["/app/explore.png", h.appExplore, 250, 400],
                ["/app/home.png", h.appFeed, 290, 470],
                ["/app/reader.png", h.appReader, 250, 400],
              ].map(([src, caption, w, hgt]) => (
                <figure key={String(src)} className="m-0 flex flex-col items-center gap-[18px]">
                  <figcaption className="text-center text-[15px] font-bold text-ink">{caption}</figcaption>
                  <div className="overflow-hidden rounded-t-[34px] border-8 border-b-0 border-ink bg-ink" style={{ width: Number(w), height: Number(hgt) }}>
                    <Image src={String(src)} alt="" width={Number(w)} height={Number(hgt)} className="h-full w-full rounded-t-[26px] object-cover object-top" />
                  </div>
                </figure>
              ))}
            </div>
          </div>
        </section>

        {/* Matières */}
        <section className={`${container} flex flex-col gap-8 pt-20 pb-6`}>
          <div className="flex flex-wrap items-end justify-between gap-4">
            <h2 className="max-w-[760px] text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px]">{h.subjectsTitle}</h2>
            <ButtonLink href="/courses" variant="secondary" className="h-12">
              {h.exploreAll} <ArrowIcon />
            </ButtonLink>
          </div>
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {SUBJECTS.map((subject) => (
              <Link key={subject} href={`/courses?subject=${subjectParam(subject)}`} className="flex flex-col overflow-hidden rounded-card border border-line bg-white hover:border-line-2">
                <Image src={SUBJECT_ART[subject]} alt="" width={800} height={450} className="aspect-video w-full bg-cream object-cover" />
                <span className="flex flex-col gap-2 px-5 pt-[18px] pb-5">
                  <span className="flex items-baseline justify-between gap-2.5">
                    <strong className="text-[21px] font-extrabold tracking-[-0.4px] text-ink">{SUBJECT_LABEL[subject]}</strong>
                    <span className="text-[13px] font-bold text-ink-3">
                      {counts[subject]} {h.coursesLabel}
                    </span>
                  </span>
                  <span className="text-[14px] leading-[1.5] text-ink-3">{sampleTitles(courses, subject, 2).join(" · ")}</span>
                </span>
              </Link>
            ))}
          </div>
        </section>

        {/* Cette semaine */}
        <section className={`${container} flex flex-col gap-7 pt-16 pb-6`}>
          <div className="flex flex-col gap-2">
            <h2 className="text-[30px] font-extrabold tracking-[-0.7px]">{h.thisWeek}</h2>
            <p className="text-[16px] text-ink-3">{h.thisWeekLead}</p>
          </div>
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {featured.map((c, i) => (
              <CourseCard key={c.id} course={c} creator={c.creatorSlug ? byCreator.get(c.creatorSlug) : null} index={i} />
            ))}
          </div>
        </section>

        {/* Auteurs */}
        <section className={`${container} flex flex-col gap-8 pt-20 pb-6`}>
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="flex max-w-[760px] flex-col gap-2.5">
              <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px]">{h.authorsTitle}</h2>
              <p className="text-[17px] leading-[1.5] text-ink-3">{h.authorsLead}</p>
            </div>
            <ButtonLink href="/authors" variant="secondary" className="h-12">
              {h.allAuthors} <ArrowIcon />
            </ButtonLink>
          </div>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {authors.map((a) => (
              <AuthorCard key={a.slug} creator={a} />
            ))}
          </div>
        </section>

        {/* Premium */}
        <section id="premium" className={`${container} pt-20 pb-6`}>
          <div className="flex flex-wrap items-center gap-x-12 gap-y-8 overflow-hidden rounded-[28px] bg-ink p-8 text-white md:p-12">
            <div className="flex min-w-0 flex-[1_1_460px] flex-col gap-4">
              <span className="text-[13px] font-bold uppercase tracking-[1.2px] text-saffron">{h.premiumEyebrow}</span>
              <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px] text-white">{h.premiumTitle}</h2>
              <p className="text-[17px] leading-[1.55] text-[#DDE3EC]">{h.premiumLead}</p>
              <ul className="grid grid-cols-1 gap-x-5 gap-y-2.5 text-[15px] font-semibold text-white sm:grid-cols-2">
                {h.premiumItems.map((item) => (
                  <li key={item} className="flex items-center gap-2.5">
                    <CheckIcon className="text-saffron" /> {item}
                  </li>
                ))}
              </ul>
              <a href="#download" className="mt-1.5 inline-flex h-[50px] w-fit items-center rounded-btn bg-white px-[22px] text-[15px] font-extrabold text-navy">
                {h.premiumCta}
              </a>
            </div>
            <div className="flex min-w-0 flex-[1_1_320px] justify-center">
              <Image src="/art/poster_premium.webp" alt="" width={600} height={600} className="aspect-square w-full max-w-[380px] rounded-[24px] object-cover" />
            </div>
          </div>
        </section>

        {/* Écrire pour Sophia */}
        <section className={`${container} pt-10 pb-8`}>
          <div className="flex flex-wrap items-center gap-x-12 gap-y-8 rounded-[28px] border border-cream-2 bg-cream p-8 md:p-12">
            <div className="flex min-w-0 flex-[1_1_400px] justify-center">
              <Image src="/art/poster_ecrire.webp" alt={h.ecrireAlt} width={1365} height={1024} className="aspect-[4/3] w-full max-w-[520px] rounded-[24px] object-cover" />
            </div>
            <div className="flex min-w-0 flex-[1_1_460px] flex-col gap-4">
              <Eyebrow>{h.writeEyebrow}</Eyebrow>
              <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px] text-ink">{h.writeTitle}</h2>
              <p className="text-[16px] leading-[1.55] text-ink-2">{h.writeLead}</p>
              <ol className="grid grid-cols-1 gap-x-5 gap-y-3 sm:grid-cols-2">
                {h.writeSteps.map(([title, detail], i) => (
                  <li key={title} className="flex items-start gap-3">
                    <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-navy text-[13px] font-extrabold text-white">{i + 1}</span>
                    <span className="text-[14px] leading-[1.45] text-ink-2">
                      <strong className="text-ink">{title}</strong>: {detail}
                    </span>
                  </li>
                ))}
              </ol>
              <div className="flex flex-wrap gap-3 pt-1.5">
                <ButtonLink href="/join" className="h-[50px] px-[22px] font-extrabold">
                  {h.becomeAuthor}
                </ButtonLink>
                <ButtonLink href="/write" variant="secondary" className="h-[50px] px-[22px]">
                  {h.seeEditor}
                </ButtonLink>
              </div>
            </div>
          </div>
        </section>

        {/* Deviens créateur : vidéos courtes et diaporamas. Pas de lien pour l'instant. */}
        <section id="creators" className={`${container} pb-24`}>
          <div className="flex flex-wrap items-center gap-x-12 gap-y-8 rounded-[28px] bg-ink p-8 text-white md:p-12">
            <div className="flex min-w-0 flex-[1_1_460px] flex-col gap-4">
              <div className="flex flex-wrap items-center gap-3">
                <span className="text-[13px] font-bold uppercase tracking-[1.2px] text-saffron">{h.creatorEyebrow}</span>
                <Pill tone="amber">{h.creatorSoon}</Pill>
              </div>
              <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px]">{h.creatorTitle}</h2>
              <p className="text-[16px] leading-[1.55] text-[#DDE3EC]">{h.creatorLead}</p>
              <ul className="flex flex-col gap-3">
                {h.creatorItems.map(([title, detail]) => (
                  <li key={title} className="flex items-start gap-3">
                    <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-white/15 text-white">
                      <CheckIcon className="h-3.5 w-3.5" />
                    </span>
                    <span className="text-[14px] leading-[1.45] text-[#DDE3EC]">
                      <strong className="text-white">{title}</strong>: {detail}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
            <div className="flex min-w-0 flex-[1_1_400px] justify-center">
              <Image src="/art/poster_createur.webp" alt={h.creatorAlt} width={1365} height={1024} className="aspect-[4/3] w-full max-w-[520px] rounded-[24px] object-cover" />
            </div>
          </div>
        </section>
      </main>
    </>
  );
}

export function PremiumPill() {
  return <Pill tone="amber">{t.home.premiumEyebrow}</Pill>;
}
