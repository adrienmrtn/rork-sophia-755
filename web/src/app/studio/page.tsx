import Link from "next/link";
import { redirect } from "next/navigation";
import { StatusPill, StudioHeader } from "@/components/studio/StudioChrome";
import { ReadsChart } from "@/components/studio/ReadsChart";
import { ButtonLink, Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { displayName, getStudioSession, nextOnboardingPath } from "@/lib/studio/account";
import { listDrafts, loadDashboard, money, pct, shortDate } from "@/lib/studio/data";
import { createDraft } from "@/app/studio/actions";

export const dynamic = "force-dynamic";

const PERIODS = [7, 28, 90];

export default async function DashboardPage({ searchParams }: PageProps<"/studio">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio");
  const { account, supabase, user, agreementSigned } = session;
  if (!account) redirect("/studio/onboarding/identity");
  const sp = await searchParams;
  const days = PERIODS.includes(Number(sp.days)) ? Number(sp.days) : 28;
  const onboarding = nextOnboardingPath(account, agreementSigned);

  const [dash, drafts] = await Promise.all([loadDashboard(supabase, days), listDrafts(supabase, user.id)]);
  const d = s.dashboard;
  const name = displayName(account, user);
  const delta = dash.reads_prev > 0 ? (dash.reads - dash.reads_prev) / dash.reads_prev : null;
  const published = dash.courses.filter((c) => c.status === "published");
  const subjectAvg = (() => {
    const subjects = [...new Set(published.map((c) => c.subject).filter(Boolean))] as string[];
    if (subjects.length !== 1) return null;
    const avg = dash.subject_per_1000[subjects[0]];
    return avg == null ? null : { subject: SUBJECT_LABEL[subjects[0] as keyof typeof SUBJECT_LABEL] ?? subjects[0], avg: String(avg) };
  })();
  const current = dash.payouts.find((p) => p.current);
  const unpublishedDrafts = drafts.filter((x) => x.status !== "published" && x.status !== "archived");

  return (
    <>
      <StudioHeader session={session} active="dashboard" />
      <main className={`${container} flex flex-1 flex-col gap-7 pt-8 pb-20`}>
        {onboarding && (
          <Card className="flex flex-wrap items-center justify-between gap-4 border-amber-bg bg-amber-bg/50 px-6 py-4">
            <span className="text-[15px] font-semibold text-amber">{s.onboarding.note}</span>
            <ButtonLink href={onboarding} variant="dark">
              {d.continueOnboarding}
            </ButtonLink>
          </Card>
        )}
        {account.status === "pending" && !onboarding && <Card className="border-amber-bg bg-amber-bg/50 px-6 py-4 text-[15px] font-semibold text-amber">{d.pending}</Card>}
        {account.status === "suspended" && <Card className="border-red-bg bg-red-bg/60 px-6 py-4 text-[15px] font-semibold text-red">{d.suspended}</Card>}

        <div className="flex flex-wrap items-end justify-between gap-4">
          <div className="flex flex-col gap-1.5">
            <h1 className="text-[32px] font-extrabold tracking-[-0.8px] text-ink">{d.hello(name.split(" ")[0] || name)}</h1>
            <p className="text-[16px] text-ink-3">{published.length === 0 ? d.empty : d.summary(dash.reads, days, dash.languages_read)}</p>
          </div>
          <div className="flex items-center gap-1 rounded-xl border border-line bg-white p-1">
            {PERIODS.map((p) => (
              <Link key={p} href={p === 28 ? "/studio" : `/studio?days=${p}`} className={`rounded-lg px-3 py-1.5 text-[13px] font-bold ${p === days ? "bg-navy text-white" : "text-ink-3 hover:bg-paper"}`}>
                {d.periods[String(p)]}
              </Link>
            ))}
          </div>
        </div>

        {/* KPI */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <Kpi label={d.reads} value={dash.reads.toLocaleString("en")} sub={delta == null ? d.vsPrevious : `${delta >= 0 ? "+" : ""}${Math.round(delta * 100)}% ${d.vsPrevious}`} tone={delta == null ? "muted" : delta >= 0 ? "green" : "red"} />
          <Kpi label={d.per1000} value={dash.per_1000 == null ? "–" : String(dash.per_1000)} sub={subjectAvg ? d.aboveAvg(subjectAvg.subject, subjectAvg.avg) : d.onCourses(published.length)} />
          <Kpi label={d.followers} value={`${dash.followers_gained >= 0 ? "+" : ""}${dash.followers_gained.toLocaleString("en")}`} sub={d.onCourses(published.length)} />
          <Kpi label={d.earnings} value={current ? money(current.amount, current.currency) : "–"} sub={current ? `${d.estimated} · ${d.paidOn}` : d.noData} />
        </div>

        <div className="grid grid-cols-1 gap-5 lg:grid-cols-[2fr_1fr]">
          <Card className="flex flex-col gap-4 p-6">
            <div className="flex flex-col gap-0.5">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">{d.chartTitle}</h2>
              <span className="text-[13px] text-ink-3">{d.chartLead}</span>
            </div>
            <ReadsChart series={dash.series} />
          </Card>
          <Card id="payments" className="flex flex-col gap-4 p-6">
            <div className="flex flex-col gap-0.5">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">{d.payments}</h2>
              <span className="text-[13px] text-ink-3">{d.paymentNote(current?.readers ?? 0)}</span>
            </div>
            <ul className="flex flex-col divide-y divide-line">
              {dash.payouts.length === 0 && <li className="py-3 text-[14px] text-muted">{d.noData}</li>}
              {dash.payouts.map((p) => (
                <li key={p.month} className="flex items-center justify-between gap-3 py-3">
                  <div className="flex flex-col">
                    <strong className="text-[15px] font-bold">{new Date(`${p.month}-01T00:00:00Z`).toLocaleDateString("en-GB", { month: "long", year: "numeric", timeZone: "UTC" })}</strong>
                    <span className="text-[12px] text-ink-3">
                      {Math.round(p.minutes).toLocaleString("en")} min · {p.readers} readers · {(p.share * 100).toFixed(1)}% of the pool
                    </span>
                  </div>
                  <div className="flex flex-col items-end">
                    <strong className="text-[16px] font-extrabold text-navy">{money(p.amount, p.currency)}</strong>
                    <span className="text-[12px] text-muted">{p.current ? d.current : d.paid}</span>
                  </div>
                </li>
              ))}
            </ul>
          </Card>
        </div>

        {/* Mes cours */}
        <Card className="flex flex-col gap-4 p-6">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div className="flex flex-col gap-0.5">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">{d.myCourses}</h2>
              <span className="text-[13px] text-ink-3">{d.myCoursesLead}</span>
            </div>
            <form action={createDraft}>
              <button type="submit" className="inline-flex h-10 items-center rounded-xl border border-line bg-white px-4 text-[14px] font-bold text-navy hover:bg-paper">
                {d.newCourse}
              </button>
            </form>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] border-collapse text-[14px]">
              <thead>
                <tr className="text-left text-[12px] font-bold uppercase tracking-[.8px] text-muted">
                  <th className="py-2 pr-4 font-bold">{d.cols.course}</th>
                  <th className="py-2 pr-4 font-bold">{d.cols.status}</th>
                  <th className="py-2 pr-4 text-right font-bold">{d.cols.reads}</th>
                  <th className="py-2 pr-4 text-right font-bold">{d.cols.per1000}</th>
                  <th className="py-2 pr-4 text-right font-bold">{d.cols.completion}</th>
                  <th className="py-2 text-right font-bold">{d.cols.langs}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {dash.courses.map((c) => (
                  <tr key={c.id} className="hover:bg-paper">
                    <td className="py-3 pr-4">
                      <Link href={`/studio/courses/app/${encodeURIComponent(c.id)}`} className="font-bold text-ink hover:text-navy">
                        {c.title ?? c.id}
                      </Link>
                      <span className="block text-[12px] text-ink-3">
                        {c.subject ? (SUBJECT_LABEL[c.subject as keyof typeof SUBJECT_LABEL] ?? c.subject) : ""}
                        {c.published_at ? ` · ${shortDate(c.published_at)}` : ""}
                      </span>
                    </td>
                    <td className="py-3 pr-4">
                      <StatusPill status={c.status === "published" ? "published" : c.status === "in_production" ? "publishing" : c.status} />
                    </td>
                    <td className="py-3 pr-4 text-right tabular-nums">{c.reads.toLocaleString("en")}</td>
                    <td className="py-3 pr-4 text-right tabular-nums">{c.per_1000 ?? "–"}</td>
                    <td className="py-3 pr-4 text-right tabular-nums">{pct(c.completion)}</td>
                    <td className="py-3 text-right tabular-nums">{c.published_langs}</td>
                  </tr>
                ))}
                {unpublishedDrafts.map((x) => (
                  <tr key={x.id} className="hover:bg-paper">
                    <td className="py-3 pr-4">
                      <Link href={`/studio/courses/${x.id}`} className="font-bold text-ink hover:text-navy">
                        {x.title || s.courses.untitled}
                      </Link>
                      <span className="block text-[12px] text-ink-3">{s.courses.updated(shortDate(x.updated_at))}</span>
                    </td>
                    <td className="py-3 pr-4">
                      <StatusPill status={x.status} />
                    </td>
                    <td className="py-3 pr-4 text-right text-muted">–</td>
                    <td className="py-3 pr-4 text-right text-muted">–</td>
                    <td className="py-3 pr-4 text-right text-muted">–</td>
                    <td className="py-3 text-right text-muted">–</td>
                  </tr>
                ))}
                {dash.courses.length === 0 && unpublishedDrafts.length === 0 && (
                  <tr>
                    <td colSpan={6} className="py-6 text-center text-[14px] text-muted">
                      {s.courses.empty}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </main>
    </>
  );
}

function Kpi({ label, value, sub, tone = "muted" }: { label: string; value: string; sub: string; tone?: "muted" | "green" | "red" }) {
  const color = tone === "green" ? "text-green-2" : tone === "red" ? "text-red-2" : "text-ink-3";
  return (
    <Card className="flex flex-col gap-1.5 p-5">
      <span className="text-[13px] font-bold text-ink-3">{label}</span>
      <strong className="text-[30px] font-extrabold tracking-[-0.8px] text-ink tabular-nums">{value}</strong>
      <span className={`text-[12px] font-semibold ${color}`}>{sub}</span>
    </Card>
  );
}
