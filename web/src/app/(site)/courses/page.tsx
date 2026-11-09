import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import { CourseCard } from "@/components/CourseCard";
import { SiteHeader } from "@/components/SiteChrome";
import { StoreButtons } from "@/components/StoreButtons";
import { Eyebrow, container } from "@/components/ui";
import { catalog } from "@/lib/catalog/source";
import { creatorMap, subjectCounts } from "@/lib/catalog/select";
import { SUBJECT_ART, SUBJECT_LABEL, subjectFromParam, subjectParam } from "@/lib/catalog/slugs";
import { SUBJECTS, type Subject } from "@/lib/catalog/types";
import { t } from "@/lib/copy/en";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Explore the courses",
  description: "310 general-knowledge courses in six subjects. Read the introduction of each one for free.",
};

const PAGE_SIZE = 24;

function normalise(s: string) {
  return s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

export default async function CoursesPage({ searchParams }: PageProps<"/courses">) {
  const params = await searchParams;
  const subject = subjectFromParam(typeof params.subject === "string" ? params.subject : undefined);
  const q = typeof params.q === "string" ? params.q.trim() : "";
  const sub = typeof params.sub === "string" ? params.sub : "";
  const page = Math.max(1, Number(typeof params.page === "string" ? params.page : "1") || 1);

  const [all, creators] = await Promise.all([catalog.listCourses("en"), catalog.listCreators("en")]);
  const counts = subjectCounts(all);
  const byCreator = creatorMap(creators);

  let list = subject ? all.filter((c) => c.subject === subject) : all;
  if (sub) list = list.filter((c) => c.subcategory === sub);
  if (q) {
    const needle = normalise(q);
    list = list.filter((c) => {
      const creator = c.creatorSlug ? byCreator.get(c.creatorSlug) : null;
      return [c.title, c.subtitle, c.description, c.subcategory, creator?.name].some((v) => v && normalise(v).includes(needle));
    });
  }
  const subcategories = subject ? [...new Set(all.filter((c) => c.subject === subject).map((c) => c.subcategory).filter((s): s is string => Boolean(s)))].sort() : [];
  const total = list.length;
  const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const current = Math.min(page, pages);
  const slice = list.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  const href = (over: Record<string, string | undefined>) => {
    const sp = new URLSearchParams();
    const merged = { subject: subject ? subjectParam(subject) : undefined, q: q || undefined, sub: sub || undefined, ...over };
    for (const [k, v] of Object.entries(merged)) if (v) sp.set(k, v);
    const s = sp.toString();
    return `/courses${s ? `?${s}` : ""}`;
  };

  const e = t.explore;
  return (
    <>
      <SiteHeader active="explore" />
      <main className={`${container} flex flex-col gap-10 pt-12 pb-24`}>
        <div className="flex flex-wrap items-end justify-between gap-x-10 gap-y-5">
          <div className="flex max-w-[720px] flex-col gap-2.5">
            <Eyebrow>{e.eyebrow}</Eyebrow>
            <h1 className="text-[44px] font-extrabold leading-[1.08] tracking-[-1.2px]">{e.title}</h1>
            <p className="text-[17px] leading-[1.5] text-ink-3">{e.lead}</p>
          </div>
          <form action="/courses" className="flex w-full max-w-[480px] flex-[1_1_360px] items-center gap-2.5">
            {subject && <input type="hidden" name="subject" value={subjectParam(subject)} />}
            <label htmlFor="q" className="sr-only">
              {e.search}
            </label>
            <span className="flex h-[50px] flex-1 items-center gap-2.5 rounded-btn border border-line bg-paper px-4">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#55637A" strokeWidth="2.2" strokeLinecap="round" aria-hidden="true">
                <circle cx="11" cy="11" r="7" />
                <path d="M20 20l-3.5-3.5" />
              </svg>
              <input id="q" name="q" type="search" defaultValue={q} placeholder={e.searchPlaceholder} className="flex-1 bg-transparent text-[15px] text-ink outline-none placeholder:text-muted" />
            </span>
            <button type="submit" className="h-[50px] rounded-btn bg-navy px-[18px] text-[15px] font-bold text-white">
              {e.search}
            </button>
          </form>
        </div>

        {/* Matières */}
        <div className="grid grid-cols-2 gap-3.5 sm:grid-cols-3 lg:grid-cols-6">
          {SUBJECTS.map((s: Subject) => (
            <Link
              key={s}
              href={subject === s ? href({ subject: undefined, sub: undefined }) : `/courses?subject=${subjectParam(s)}`}
              aria-current={subject === s ? "page" : undefined}
              className={`flex flex-col overflow-hidden rounded-[18px] bg-white ${subject === s ? "border-2 border-navy" : "border border-line hover:border-line-2"}`}
            >
              <Image src={SUBJECT_ART[s]} alt="" width={400} height={250} className="aspect-[16/10] w-full object-cover" />
              <span className="flex flex-col gap-0.5 px-3.5 pt-3 pb-3.5">
                <strong className="text-[15px] font-extrabold text-ink">{SUBJECT_LABEL[s]}</strong>
                <span className="text-[12px] font-semibold text-ink-3">
                  {counts[s]} {e.results}
                </span>
              </span>
            </Link>
          ))}
        </div>

        {/* Filtres */}
        <div className="flex flex-wrap items-center justify-between gap-x-6 gap-y-3 border-t border-line pt-6">
          <div className="flex flex-wrap items-center gap-2">
            <span className="mr-1.5 text-[14px] font-bold text-ink">
              {subject ? SUBJECT_LABEL[subject] : t.explore.all} · {total} {e.results}
            </span>
            {subject && (
              <>
                <Link href={href({ sub: undefined })} className={`inline-flex h-9 items-center rounded-full px-3.5 text-[13px] font-bold ${!sub ? "bg-navy text-white" : "border border-line text-ink-2"}`}>
                  {e.all}
                </Link>
                {subcategories.map((s) => (
                  <Link key={s} href={href({ sub: s })} className={`inline-flex h-9 items-center rounded-full px-3.5 text-[13px] font-semibold ${sub === s ? "bg-navy text-white" : "border border-line text-ink-2"}`}>
                    {s}
                  </Link>
                ))}
              </>
            )}
          </div>
        </div>

        {/* Grille */}
        {slice.length ? (
          <div className="grid grid-cols-1 gap-x-5 gap-y-6 sm:grid-cols-2 lg:grid-cols-4">
            {slice.map((c, i) => (
              <CourseCard key={c.id} course={c} creator={c.creatorSlug ? byCreator.get(c.creatorSlug) : null} index={i} />
            ))}
          </div>
        ) : (
          <p className="rounded-card border border-line bg-paper p-8 text-center text-[16px] text-ink-3">{e.noResults}</p>
        )}

        {/* Pagination */}
        {pages > 1 && (
          <nav aria-label="Pages" className="flex items-center justify-center gap-2">
            {Array.from({ length: pages }, (_, i) => i + 1).map((p) => (
              <Link key={p} href={href({ page: p === 1 ? undefined : String(p) })} aria-current={p === current ? "page" : undefined} className={`inline-flex h-10 w-10 items-center justify-center rounded-xl text-[14px] font-bold ${p === current ? "bg-navy text-white" : "border border-line text-ink"}`}>
                {p}
              </Link>
            ))}
          </nav>
        )}

        {/* Bande app */}
        <div className="flex flex-wrap items-center justify-between gap-x-8 gap-y-4 rounded-card bg-ink px-8 py-7 text-white">
          <div className="flex flex-col gap-1.5">
            <strong className="text-[20px] font-extrabold">{e.appBand}</strong>
            <span className="text-[15px] text-[#DDE3EC]">{e.appBandLead}</span>
          </div>
          <StoreButtons size="compact" />
        </div>
      </main>
    </>
  );
}
