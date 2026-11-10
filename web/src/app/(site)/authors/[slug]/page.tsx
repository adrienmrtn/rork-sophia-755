import Link from "next/link";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { AuthorAvatar } from "@/components/AuthorCard";
import { CourseCard } from "@/components/CourseCard";
import { SiteHeader } from "@/components/SiteChrome";
import { StoreButtons } from "@/components/StoreButtons";
import { buttonClass, ButtonLink, CheckIcon, container, Pill } from "@/components/ui";
import { catalog } from "@/lib/catalog/source";
import { authorPath } from "@/lib/catalog/slugs";
import { t } from "@/lib/copy/en";
import { APP_STORE_ID, SITE_URL } from "@/lib/env";

export const dynamic = "force-dynamic";

const COUNTRY: Record<string, string> = { FR: "France", US: "United States", GB: "United Kingdom", RS: "Serbia", KR: "South Korea", SK: "Slovakia", DE: "Germany", ES: "Spain", IT: "Italy", BE: "Belgium", CH: "Switzerland", CA: "Canada", NL: "Netherlands", PT: "Portugal", PL: "Poland" };

export async function generateMetadata({ params }: PageProps<"/authors/[slug]">): Promise<Metadata> {
  const { slug } = await params;
  const creator = await catalog.getCreator("en", slug);
  if (!creator) return { title: "Author not found" };
  const description = creator.bio ?? creator.title ?? undefined;
  return {
    title: creator.name,
    description,
    alternates: { canonical: authorPath(slug) },
    openGraph: { title: creator.name, description, url: authorPath(slug), siteName: "Sophia", images: creator.photoUrl ? [{ url: creator.photoUrl }] : undefined, type: "profile" },
    // Bannière Safari : « Ouvrir » l'app sur cet auteur si elle est installée, sinon l'App Store.
    itunes: { appId: APP_STORE_ID, appArgument: `${SITE_URL}${authorPath(slug)}` },
  };
}

export default async function AuthorPage({ params }: PageProps<"/authors/[slug]">) {
  const { slug } = await params;
  const [creator, all, creators] = await Promise.all([catalog.getCreator("en", slug), catalog.listCourses("en"), catalog.listCreators("en")]);
  if (!creator) notFound();
  const courses = all.filter((c) => creator.courseIds.includes(c.id)).sort((a, b) => b.number - a.number);
  const others = creators.filter((c) => c.slug !== slug && c.courseIds.length && c.photoUrl).slice(0, 3);
  const a = t.author;
  const byId = new Map(all.map((c) => [c.id, c]));

  return (
    <>
      <SiteHeader />
      <main className={`${container} flex flex-col gap-12 pt-8 pb-24`}>
        <nav aria-label="Breadcrumb" className="flex flex-wrap items-center gap-2 text-[13px] font-semibold text-ink-3">
          <Link href="/">Home</Link>
          <span aria-hidden="true">›</span>
          <Link href="/authors">{a.breadcrumb}</Link>
          <span aria-hidden="true">›</span>
          <span className="text-ink">{creator.name}</span>
        </nav>

        <section className="flex flex-wrap items-start gap-x-12 gap-y-8 rounded-[28px] border border-line bg-paper p-6 md:p-9">
          <AuthorAvatar creator={creator} size={168} className="border-4 border-white shadow-[0_10px_30px_rgba(22,38,61,.12)]" />
          <div className="flex min-w-0 flex-[1_1_420px] flex-col gap-3.5">
            <div className="flex flex-wrap items-center gap-2.5">
              <h1 className="text-[40px] font-extrabold leading-[1.1] tracking-[-1.1px]">{creator.name}</h1>
              {creator.verified && (
                <Pill tone="green">
                  <CheckIcon className="h-3.5 w-3.5" /> {a.verified}
                </Pill>
              )}
            </div>
            {creator.title && <p className="text-[18px] font-semibold text-ink-2">{creator.title}</p>}
            {creator.bio && <p className="max-w-[680px] text-[16px] leading-[1.6] text-ink-3">{creator.bio}</p>}
            <div className="flex flex-wrap items-center gap-x-5 gap-y-2 text-[14px] font-semibold text-ink-2">
              {creator.institution && <span>{creator.institution}</span>}
              {creator.country && <span>{COUNTRY[creator.country] ?? creator.country}</span>}
              <span>{a.courses(courses.length)}</span>
              <span>{a.writesIn}</span>
            </div>
            <div className="flex flex-wrap gap-2.5 pt-1">
              {/* Sur téléphone, le bouton ouvre l'app sur la page du créateur (sophia://author/<slug>) ;
                  sur ordinateur, il mène aux boutons des magasins. */}
              <a href={`sophia://author/${creator.slug}`} className={buttonClass("primary", "h-12 px-5 md:hidden")}>
                {a.follow}
              </a>
              <ButtonLink href="#follow" className="hidden h-12 px-5 md:inline-flex">
                {a.follow}
              </ButtonLink>
              {Object.entries(creator.links).map(([label, url]) => (
                <a key={url} href={url} className="inline-flex h-12 items-center rounded-btn border border-line bg-white px-4 text-[15px] font-bold text-navy">
                  {label}
                </a>
              ))}
            </div>
          </div>
        </section>

        <section className="flex flex-col gap-6">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <h2 className="text-[30px] font-extrabold tracking-[-0.7px]">{a.theirCourses}</h2>
            <span className="text-[14px] font-semibold text-ink-3">{a.courses(courses.length)}</span>
          </div>
          {courses.length === 0 ? (
            <p className="rounded-card border border-line bg-paper px-6 py-5 text-[15px] leading-[1.55] text-ink-3">{a.noCoursesYet}</p>
          ) : (
            <div className="grid grid-cols-1 gap-x-5 gap-y-6 sm:grid-cols-2 lg:grid-cols-3">
              {courses.map((c, i) => (
                <CourseCard key={c.id} course={c} index={i} />
              ))}
            </div>
          )}
        </section>

        <section className="flex flex-wrap gap-6">
          <div id="follow" className="flex min-w-0 flex-[1_1_520px] flex-wrap items-center justify-between gap-x-6 gap-y-4 rounded-card bg-ink px-8 py-7 text-white">
            <div className="flex max-w-[420px] flex-col gap-1.5">
              <strong className="text-[20px] font-extrabold">{a.followBand(creator.name)}</strong>
              <span className="text-[15px] leading-[1.5] text-[#DDE3EC]">{a.followBandLead}</span>
            </div>
            <StoreButtons size="compact" resumeUrl={`${SITE_URL}${authorPath(creator.slug)}`} />
          </div>
          {others.length > 0 && (
            <div className="flex min-w-0 flex-[1_1_400px] flex-col gap-3.5 rounded-card border border-line px-7 py-6">
              <strong className="text-[13px] font-bold uppercase tracking-[1px] text-muted">{a.otherAuthors}</strong>
              <div className="flex flex-col gap-3">
                {others.map((o) => (
                  <Link key={o.slug} href={authorPath(o.slug)} className="flex items-center gap-3">
                    <AuthorAvatar creator={o} size={40} />
                    <span className="flex flex-col">
                      <strong className="text-[14px] font-bold text-ink">{o.name}</strong>
                      <span className="text-[12px] text-ink-3">
                        {[...new Set(o.courseIds.map((id) => byId.get(id)?.subject).filter(Boolean))].length ? a.courses(o.courseIds.length) : ""}
                      </span>
                    </span>
                  </Link>
                ))}
              </div>
              <Link href="/authors" className="text-[14px] font-bold text-blue">
                {a.allAuthors}
              </Link>
            </div>
          )}
        </section>
      </main>
    </>
  );
}
