import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { StudioHeader } from "@/components/studio/StudioChrome";
import { Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { courseNumber, slugify, SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { getStudioSession } from "@/lib/studio/account";
import { pct } from "@/lib/studio/data";

export const dynamic = "force-dynamic";

interface StatsRow {
  course_id: string;
  lang: string;
  impressions: number;
  opens: number;
  completes: number;
  completes_per_1000_impressions: number | null;
  likes: number;
  saves: number;
  shares: number;
  readers: number;
  followers_gained: number;
  sections: { index: number; viewers: number; reach: number | null }[];
}

interface Detail {
  course_id: string;
  days: number;
  stats: StatsRow[];
  languages: { lang: string; reads: number; completes: number }[];
  quiz: { answers: number; correct: number };
  sections: string[] | null;
}

const PERIODS = [7, 28, 90];

/** Un cours publié vu par son auteur : où les lecteurs décrochent, les langues, le quiz. */
export default async function AppCoursePage({ params, searchParams }: PageProps<"/studio/courses/app/[courseId]">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio");
  const { courseId } = await params;
  const sp = await searchParams;
  const days = PERIODS.includes(Number(sp.days)) ? Number(sp.days) : 28;
  const { supabase } = session;
  const [{ data: detail, error }, { data: course }] = await Promise.all([
    supabase.rpc("creator_course_detail", { p_course_id: courseId, p_days: days }),
    supabase.from("courses").select("id,subject,status,origin_lang,published_at,course_contents(lang,title,content,status)").eq("id", courseId).maybeSingle(),
  ]);
  if (error || !detail) notFound();
  const d = detail as Detail;
  type ContentRow = { lang: string; title: string; content: { sections?: { title: string }[] } | null; status: string };
  const contents = ((course as { course_contents?: ContentRow[] } | null)?.course_contents ?? []) as ContentRow[];
  const originLang = (course as { origin_lang?: string } | null)?.origin_lang ?? "fr";
  const origin = contents.find((c) => c.lang === originLang) ?? contents[0];
  const title = origin?.title ?? courseId;
  const sectionTitles = origin?.content?.sections?.map((x) => x.title) ?? [];
  const publishedLangs = contents.filter((c) => c.status === "published").length;

  const rows = d.stats ?? [];
  const total = rows.reduce(
    (acc, r) => ({ impressions: acc.impressions + Number(r.impressions), opens: acc.opens + Number(r.opens), completes: acc.completes + Number(r.completes), likes: acc.likes + Number(r.likes), saves: acc.saves + Number(r.saves), shares: acc.shares + Number(r.shares), readers: acc.readers + Number(r.readers), followers: acc.followers + Number(r.followers_gained) }),
    { impressions: 0, opens: 0, completes: 0, likes: 0, saves: 0, shares: 0, readers: 0, followers: 0 },
  );
  const viewers = new Map<number, number>();
  for (const r of rows) for (const sec of r.sections ?? []) viewers.set(sec.index, (viewers.get(sec.index) ?? 0) + Number(sec.viewers));
  const sectionCount = Math.max(sectionTitles.length, d.sections?.length ?? 0, viewers.size ? Math.max(...viewers.keys()) + 1 : 0);
  const reach = Array.from({ length: sectionCount }, (_, i) => ({ index: i, title: sectionTitles[i] ?? `Section ${i + 1}`, viewers: viewers.get(i) ?? 0, reach: total.opens > 0 ? Math.min(1, (viewers.get(i) ?? 0) / total.opens) : null }));
  const per1000 = total.impressions > 0 ? Math.round((total.completes * 10000) / total.impressions) / 10 : null;
  const number = courseNumber(courseId);
  const subject = (course as { subject?: string } | null)?.subject;
  const quizScore = d.quiz && Number(d.quiz.answers) > 0 ? Number(d.quiz.correct) / Number(d.quiz.answers) : null;

  return (
    <>
      <StudioHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <Link href="/studio" className="text-[13px] font-bold text-blue">
          ← {s.nav.dashboard}
        </Link>
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div className="flex flex-col gap-1.5">
            <span className="text-[13px] font-bold uppercase tracking-[1px] text-muted">
              {subject ? (SUBJECT_LABEL[subject as keyof typeof SUBJECT_LABEL] ?? subject) : "Course"} · {publishedLangs} languages published
            </span>
            <h1 className="text-[30px] font-extrabold tracking-[-0.7px] text-ink">{title}</h1>
            {number != null && (
              <Link href={`/courses/${number}-${slugify(title)}`} className="text-[14px] font-bold text-blue">
                See the public page →
              </Link>
            )}
          </div>
          <div className="flex items-center gap-1 rounded-xl border border-line bg-white p-1">
            {PERIODS.map((p) => (
              <Link key={p} href={p === 28 ? `/studio/courses/app/${encodeURIComponent(courseId)}` : `/studio/courses/app/${encodeURIComponent(courseId)}?days=${p}`} className={`rounded-lg px-3 py-1.5 text-[13px] font-bold ${p === days ? "bg-navy text-white" : "text-ink-3 hover:bg-paper"}`}>
                {s.dashboard.periods[String(p)]}
              </Link>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-6">
          <Stat label="Impressions" value={total.impressions} />
          <Stat label={s.dashboard.reads} value={total.opens} />
          <Stat label="Completed" value={total.completes} />
          <Stat label={s.dashboard.cols.per1000} value={per1000 ?? "–"} />
          <Stat label={s.dashboard.likes} value={total.likes} />
          <Stat label={s.dashboard.followers} value={`${total.followers >= 0 ? "+" : ""}${total.followers}`} />
        </div>

        <div className="grid grid-cols-1 gap-5 lg:grid-cols-[3fr_2fr]">
          <Card className="flex flex-col gap-4 p-6">
            <div className="flex flex-col gap-0.5">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Where readers stop</h2>
              <span className="text-[13px] text-ink-3">Share of readers who opened the course and reached each section.</span>
            </div>
            {total.opens === 0 ? (
              <p className="py-6 text-center text-[14px] text-muted">{s.dashboard.noData}</p>
            ) : (
              <ol className="flex flex-col gap-2.5">
                {reach.map((r) => (
                  <li key={r.index} className="grid grid-cols-[28px_1fr_56px] items-center gap-3 text-[14px]">
                    <span className="text-[12px] font-bold text-muted">{r.index + 1}</span>
                    <div className="flex flex-col gap-1">
                      <span className="truncate font-semibold text-ink">{r.title}</span>
                      <div className="h-2 w-full overflow-hidden rounded-full bg-tint">
                        <div className="h-full rounded-full bg-navy" style={{ width: `${Math.round((r.reach ?? 0) * 100)}%` }} />
                      </div>
                    </div>
                    <span className="text-right tabular-nums text-ink-3">{pct(r.reach)}</span>
                  </li>
                ))}
              </ol>
            )}
          </Card>
          <div className="flex flex-col gap-5">
            <Card className="flex flex-col gap-3 p-6">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Languages</h2>
              {(d.languages ?? []).length === 0 ? (
                <p className="text-[14px] text-muted">{s.dashboard.noData}</p>
              ) : (
                <ul className="flex flex-col divide-y divide-line text-[14px]">
                  {d.languages.map((l) => (
                    <li key={l.lang} className="flex items-center justify-between py-2">
                      <span className="font-semibold uppercase">{l.lang}</span>
                      <span className="tabular-nums text-ink-3">
                        {Number(l.reads).toLocaleString("en")} reads · {Number(l.reads) > 0 ? pct(Number(l.completes) / Number(l.reads)) : "–"} completed
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
            <Card className="flex flex-col gap-2 p-6">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Quiz</h2>
              <p className="text-[14px] text-ink-3">
                {quizScore == null ? s.dashboard.noData : `${Number(d.quiz.answers).toLocaleString("en")} answers, ${pct(quizScore)} correct. Below 60% usually means a question is unclear or the text does not state the fact.`}
              </p>
              <p className="text-[13px] text-muted">
                Saves {total.saves.toLocaleString("en")} · Shares {total.shares.toLocaleString("en")} · Distinct readers {total.readers.toLocaleString("en")}
              </p>
            </Card>
          </div>
        </div>
      </main>
    </>
  );
}

function Stat({ label, value }: { label: string; value: number | string }) {
  return (
    <Card className="flex flex-col gap-1 p-4">
      <span className="text-[12px] font-bold text-ink-3">{label}</span>
      <strong className="text-[24px] font-extrabold tracking-[-0.6px] text-ink tabular-nums">{typeof value === "number" ? value.toLocaleString("en") : value}</strong>
    </Card>
  );
}
