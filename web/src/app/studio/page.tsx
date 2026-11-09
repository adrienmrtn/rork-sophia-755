import Link from "next/link";
import { redirect } from "next/navigation";
import { Art } from "@/components/studio/Art";
import { StatusPill, StudioHeader } from "@/components/studio/StudioChrome";
import { ReadsChart } from "@/components/studio/ReadsChart";
import { ButtonLink, Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { displayName, getStudioSession, nextOnboardingPath } from "@/lib/studio/account";
import { listDrafts, loadDashboard, pct, shortDate } from "@/lib/studio/data";
import { moneyCents, quotaSummary, type QuotaTone } from "@/lib/studio/payments";

export const dynamic = "force-dynamic";

const PERIODS = [7, 28, 90];
const TONE: Record<QuotaTone, string> = { ok: "bg-white/80 text-navy", full: "bg-white/80 text-amber", blocked: "bg-red-bg text-red" };

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
  const first = name.split(" ")[0] || name;
  const delta = dash.reads_prev > 0 ? (dash.reads - dash.reads_prev) / dash.reads_prev : null;
  const published = dash.courses.filter((c) => c.status === "published");
  const subjectAvg = (() => {
    const subjects = [...new Set(published.map((c) => c.subject).filter(Boolean))] as string[];
    if (subjects.length !== 1) return null;
    const avg = dash.subject_per_1000[subjects[0]];
    return avg == null ? null : { subject: SUBJECT_LABEL[subjects[0] as keyof typeof SUBJECT_LABEL] ?? subjects[0], avg: String(avg) };
  })();
  const quota = quotaSummary(dash.quota);
  const fee = moneyCents(dash.fee_cents, dash.currency);
  const pending = dash.credits.filter((c) => !c.paid_at);
  const unpublishedDrafts = drafts.filter((x) => x.status !== "published" && x.status !== "archived");
  const inReview = drafts.filter((x) => x.status === "submitted").length;
  const hasData = published.length > 0;

  return (
    <>
      <StudioHeader session={session} active="dashboard" />
      <main className={`${container} flex flex-1 flex-col gap-7 pt-7 pb-20`}>
        {account.status === "suspended" && <Card className="border-red-bg bg-red-bg/60 px-6 py-4 text-[15px] font-semibold text-red">{d.suspended}</Card>}

        {/* Bandeau d'accueil */}
        <section className={`grid grid-cols-1 gap-6 overflow-hidden rounded-[28px] border p-7 md:grid-cols-[minmax(0,1fr)_260px] md:p-9 ${hasData ? "border-cream-2 bg-cream" : "border-tint bg-tint/60"}`}>
          <div className="flex flex-col justify-center gap-4">
            <span className="text-[12px] font-bold uppercase tracking-[1.2px] text-blue">{hasData ? `Last ${days} days` : "Your studio"}</span>
            <h1 className="text-[34px] font-extrabold leading-[1.08] tracking-[-0.9px] text-ink md:text-[40px]">{d.hello(first)}</h1>
            <p className="max-w-[560px] text-[17px] leading-[1.5] text-ink-2">
              {hasData ? d.summary(dash.reads, days, dash.languages_read) : onboarding ? s.onboarding.note : d.empty}
              {!hasData && inReview > 0 && ` ${inReview === 1 ? "One course is" : `${inReview} courses are`} with the team right now.`}
            </p>
            <div className="flex flex-wrap items-center gap-3 pt-1">
              {onboarding ? (
                <ButtonLink href={onboarding} variant="primary" className="!rounded-full">
                  {d.continueOnboarding}
                </ButtonLink>
              ) : (
                <Link href="/studio/courses/new" className="inline-flex h-11 items-center gap-2 rounded-full bg-navy px-5 text-[15px] font-bold text-white transition-colors hover:bg-ink">
                    {s.nav.write}
                  </Link>
              )}
              <ButtonLink href="/studio/courses" variant="ghost" className="!rounded-full">
                {s.nav.courses} →
              </ButtonLink>
            </div>
            {!onboarding && (
              <p className={`inline-flex w-fit items-center gap-2 rounded-full px-3 py-1.5 text-[13px] font-semibold ${TONE[quota.tone]}`}>
                {quota.headline}
                {quota.detail ? ` ${quota.detail}.` : ""}
              </p>
            )}
            {account.status === "pending" && !onboarding && (
              <p className="inline-flex w-fit items-center gap-2 rounded-full bg-white/80 px-3 py-1.5 text-[13px] font-semibold text-amber">
                <span aria-hidden="true" className="h-2 w-2 rounded-full bg-saffron" /> {d.pending}
              </p>
            )}
          </div>
          <Art name={hasData ? "studio_stats" : onboarding ? "studio_identity" : "studio_desk"} size={260} className="mx-auto w-full max-w-[260px] md:mx-0" priority />
        </section>

        {/* KPI */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <Kpi icon="eye" chip="bg-tint text-navy" label={d.reads} value={dash.reads.toLocaleString("en")} sub={delta == null ? d.vsPrevious : `${delta >= 0 ? "+" : ""}${Math.round(delta * 100)}% ${d.vsPrevious}`} tone={delta == null ? "muted" : delta >= 0 ? "green" : "red"} />
          <Kpi icon="target" chip="bg-cream text-amber" label={d.per1000} value={dash.per_1000 == null ? "–" : String(dash.per_1000)} sub={subjectAvg ? d.aboveAvg(subjectAvg.subject, subjectAvg.avg) : d.onCourses(published.length)} />
          <Kpi icon="users" chip="bg-green-bg text-green" label={d.followers} value={`${dash.followers_gained >= 0 ? "+" : ""}${dash.followers_gained.toLocaleString("en")}`} sub={d.onCourses(published.length)} />
          <Kpi icon="coin" chip="bg-amber-bg text-amber" label={d.earnings} value={moneyCents(dash.pot_cents, dash.currency)} sub={dash.pot_cents > 0 ? `${d.estimated} · ${d.validatedCourses(pending.length, fee)}` : d.validatedCourses(dash.credits.length, fee)} tone={dash.pot_cents > 0 ? "green" : "muted"} />
        </div>

        <div className="grid grid-cols-1 gap-5 lg:grid-cols-[2fr_1fr]">
          <Card className="flex flex-col gap-4 p-6">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <div className="flex flex-col gap-0.5">
                <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">{d.chartTitle}</h2>
                <span className="text-[13px] text-ink-3">{d.chartLead}</span>
              </div>
              <div className="flex items-center gap-1 rounded-full border border-line bg-white p-1">
                {PERIODS.map((p) => (
                  <Link key={p} href={p === 28 ? "/studio" : `/studio?days=${p}`} className={`rounded-full px-3 py-1 text-[12px] font-bold transition-colors ${p === days ? "bg-navy text-white" : "text-ink-3 hover:bg-paper"}`}>
                    {d.periods[String(p)]}
                  </Link>
                ))}
              </div>
            </div>
            <ReadsChart series={dash.series} />
          </Card>
          <Card id="payments" className="flex flex-col gap-4 border-cream-2 bg-cream p-6">
            <div className="flex flex-col gap-0.5">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">{d.payments}</h2>
              <span className="text-[13px] text-ink-3">{d.paymentNote(fee)}</span>
            </div>
            <div className="flex items-end justify-between gap-3 rounded-2xl bg-white/80 px-4 py-3">
              <div className="flex flex-col">
                <span className="text-[12px] font-bold uppercase tracking-[1px] text-muted">{d.earnings}</span>
                <strong className="text-[26px] font-extrabold tracking-[-0.6px] text-navy tabular-nums">{moneyCents(dash.pot_cents, dash.currency)}</strong>
              </div>
              <span className="text-[12px] font-semibold text-ink-3">{dash.pot_cents > 0 ? d.estimated : d.paidOn}</span>
            </div>
            <ul className="flex flex-col divide-y divide-cream-2">
              {dash.credits.length === 0 && <li className="py-3 text-[14px] text-muted">{d.nothingYet}</li>}
              {dash.credits.slice(0, 8).map((c) => (
                <li key={c.id} className="flex items-center justify-between gap-3 py-3">
                  <div className="flex min-w-0 flex-col">
                    <strong className="truncate text-[14px] font-bold">{c.title || s.courses.untitled}</strong>
                    <span className="text-[12px] text-ink-3">Validated {shortDate(c.created_at)}{c.paid_at ? ` · paid ${shortDate(c.paid_at)}` : ""}</span>
                  </div>
                  <div className="flex shrink-0 flex-col items-end">
                    <strong className="text-[15px] font-extrabold text-navy tabular-nums">{moneyCents(c.amount_cents, dash.currency)}</strong>
                    <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${c.paid_at ? "bg-green-bg text-green" : "bg-white text-amber"}`}>{c.paid_at ? d.paid : d.current}</span>
                  </div>
                </li>
              ))}
            </ul>
            {dash.payouts.length > 0 && (
              <div className="flex flex-col gap-1 border-t border-cream-2 pt-3">
                <span className="text-[12px] font-bold uppercase tracking-[1px] text-muted">{d.payoutsTitle}</span>
                <ul className="flex flex-col gap-1 text-[13px] text-ink-2">
                  {dash.payouts.slice(0, 6).map((p) => (
                    <li key={p.id} className="flex items-center justify-between gap-3">
                      <span>{shortDate(p.paid_at)} · {p.credits_count} {p.credits_count === 1 ? "course" : "courses"}</span>
                      <strong className="tabular-nums">{moneyCents(p.amount_cents, dash.currency)}</strong>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </Card>
        </div>

        {/* Mes cours */}
        <Card className="flex flex-col gap-4 p-6">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div className="flex flex-col gap-0.5">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">{d.myCourses}</h2>
              <span className="text-[13px] text-ink-3">{d.myCoursesLead}</span>
            </div>
            <Link href="/studio/courses" className="text-[13px] font-bold text-blue">
              {s.nav.courses} →
            </Link>
          </div>
          {dash.courses.length === 0 && unpublishedDrafts.length === 0 ? (
            <div className="flex flex-wrap items-center gap-6 rounded-2xl bg-paper p-6">
              <Art name="studio_empty" size={120} />
              <div className="flex min-w-[240px] flex-1 flex-col gap-3">
                <p className="text-[15px] leading-[1.5] text-ink-2">{s.courses.empty}</p>
                <Link href="/studio/courses/new" className="inline-flex h-10 items-center rounded-full bg-navy px-4 text-[14px] font-bold text-white transition-colors hover:bg-ink">
                    {d.newCourse}
                  </Link>
              </div>
            </div>
          ) : (
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
                    <tr key={c.id} className="transition-colors hover:bg-paper">
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
                    <tr key={x.id} className="transition-colors hover:bg-paper">
                      <td className="py-3 pr-4">
                        <Link href={x.status === "draft" || x.status === "changes_requested" ? `/studio/courses/${x.id}` : `/studio/courses/${x.id}/status`} className="font-bold text-ink hover:text-navy">
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
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </main>
    </>
  );
}

const ICONS = {
  eye: <path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12zm10 3a3 3 0 1 0 0-6 3 3 0 0 0 0 6z" />,
  target: <path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zm0-5a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm0-3a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" />,
  users: <path d="M16 11a4 4 0 1 0-8 0 4 4 0 0 0 8 0zM4 20a8 8 0 0 1 16 0" />,
  coin: <path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zm0-13v10m-3-2.5c0 1 1.3 1.5 3 1.5s3-.6 3-1.8-1.3-1.5-3-1.9-3-.7-3-1.8S10.3 10 12 10s3 .5 3 1.5" />,
} as const;

function Kpi({ icon, chip, label, value, sub, tone = "muted" }: { icon: keyof typeof ICONS; chip: string; label: string; value: string; sub: string; tone?: "muted" | "green" | "red" }) {
  const color = tone === "green" ? "text-green-2" : tone === "red" ? "text-red-2" : "text-ink-3";
  return (
    <Card className="flex flex-col gap-3 p-5 transition-shadow hover:shadow-[0_10px_30px_rgba(22,38,61,.06)]">
      <div className="flex items-center justify-between">
        <span className="text-[13px] font-bold text-ink-3">{label}</span>
        <span className={`inline-flex h-8 w-8 items-center justify-center rounded-full ${chip}`}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            {ICONS[icon]}
          </svg>
        </span>
      </div>
      <strong className="text-[30px] font-extrabold tracking-[-0.8px] text-ink tabular-nums">{value}</strong>
      <span className={`text-[12px] font-semibold ${color}`}>{sub}</span>
    </Card>
  );
}
