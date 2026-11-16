import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, SectionTitle, Tile } from "@/components/admin/DataChrome";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { percent, readDataFilters } from "@/lib/studio/paywalls";
import { MILESTONE_LABEL, MIN_COHORT, RETENTION_MILESTONES, heat, retained, type RetentionDashboard } from "@/lib/studio/retention";

export const dynamic = "force-dynamic";

const n = (value: number) => Number(value).toLocaleString("en");
const cohortDay = (iso: string) => new Date(`${iso}T00:00:00Z`).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" });

/** La rétention par cohorte d'inscription, en deux mesures qui ne se mélangent pas : « a
 *  appris » (XP gagné, toutes versions) et « a rouvert l'app » (événement envoyé par l'app,
 *  versions récentes, parmi les comptes suivis). Tout vient d'un appel à
 *  admin_cohort_retention, réservé à l'équipe ; ces données ne suivent que la période. */
export default async function RetentionDataPage({ searchParams }: PageProps<"/admin/data/retention">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const filters = readDataFilters(await searchParams);

  const { data, error } = await session.supabase.rpc("admin_cohort_retention", { p_days: filters.days });
  const d = (data ?? null) as RetentionDashboard | null;
  const cohorts = d?.cohorts ?? [];
  const tracked = cohorts.filter((c) => Number(c.tracked) > 0);
  const best = (rates: (number | null)[]) => Math.max(0, ...rates.map((r) => r ?? 0));
  const bestLearned0 = best(cohorts.map((c) => retained(c.learned_0, c.signups)));
  const bestLearned = Object.fromEntries(RETENTION_MILESTONES.map((m) => [m, best(cohorts.map((c) => retained(c.learned[m], c.signups)))]));
  const bestReopened = Object.fromEntries(RETENTION_MILESTONES.map((m) => [m, best(tracked.filter((c) => Number(c.tracked) >= MIN_COHORT).map((c) => retained(c.reopened[m], c.tracked)))]));
  const total = (t: { active: number; base: number }) => percent(retained(Number(t.base) ? t.active : null, t.base));

  return (
    <>
      <AdminHeader session={session} active="data" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Data" lead="What people do in the app: paywalls, onboarding, usage, friends and feedback." />
        <DataNav active="retention" filters={filters} languages={[]} periodOnly />

        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}

        {d && (
          <>
            <section className="flex flex-col gap-4">
              <SectionTitle
                title="Came back and learned"
                note={`A cohort is every account created on one UTC day. “Learned” means the account earned XP that day: a course or a quiz finished, reading progress. Counted by the server for every app version, so cohorts compare over time.${d.updated_at ? ` Refreshed every hour, last on ${shortDateTime(d.updated_at)}.` : ""}`}
              />
              <div className="grid grid-cols-2 gap-4 md:grid-cols-4 lg:grid-cols-7">
                <Tile label="Accounts created" value={n(d.totals.signups)} />
                <Tile label="Learned on day 0" value={percent(retained(Number(d.totals.signups) ? d.totals.learned_0 : null, d.totals.signups))} />
                {RETENTION_MILESTONES.map((m) => (
                  <Tile key={m} label={`Learned on ${MILESTONE_LABEL[m]}`} value={total(d.totals.learned[m])} />
                ))}
              </div>
              <p className="text-[13px] text-ink-3">
                Day 0 is the signup day: the share that learned something right away. D+7 means on the seventh day after signup exactly, not at some point during the week. Each share is against all accounts created that day, including those that never
                read anything. A milestone shows “–” until its day is over, and the tiles only average the cohorts old enough to have it.
              </p>
              <Card className="flex flex-col gap-3 p-6">
                {cohorts.length === 0 ? (
                  <p className="text-[14px] text-ink-3">No account was created on this period.</p>
                ) : (
                  <CohortTable
                    baseLabel="Accounts"
                    rows={cohorts.map((c) => ({ day: c.day, base: c.signups, first: { active: c.learned_0, max: bestLearned0 }, cells: RETENTION_MILESTONES.map((m) => ({ active: c.learned[m], max: bestLearned[m] })) }))}
                    firstLabel="Learned on day 0"
                    today={d.today}
                  />
                )}
              </Card>
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle
                title="Reopened the app"
                note="The usual retention: the app was opened again that day, whether or not anything was finished. Only recent app versions report it, so it is measured among the accounts whose app sent events on their signup day (“tracked accounts”), not among all signups."
              />
              {tracked.length === 0 ? (
                <Card className="p-6 text-[14px] text-ink-3">No account created on this period runs an app version that reports its openings.</Card>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-6">
                    <Tile label="Tracked accounts" value={`${n(d.totals.tracked)} · ${percent(retained(Number(d.totals.signups) ? d.totals.tracked : null, d.totals.signups))}`} />
                    {RETENTION_MILESTONES.map((m) => (
                      <Tile key={m} label={`Reopened on ${MILESTONE_LABEL[m]}`} value={total(d.totals.reopened[m])} />
                    ))}
                  </div>
                  <p className="text-[13px] text-ink-3">
                    Tracked accounts are shown with their share of all accounts created on the period. Cohorts with fewer than {MIN_COHORT} tracked accounts are shown without shading: their shares move too much to mean anything.
                  </p>
                  <Card className="flex flex-col gap-3 p-6">
                    <CohortTable
                      baseLabel="Tracked accounts"
                      rows={tracked.map((c) => ({ day: c.day, base: c.tracked, cells: RETENTION_MILESTONES.map((m) => ({ active: c.reopened[m], max: Number(c.tracked) >= MIN_COHORT ? bestReopened[m] : 0 })) }))}
                      today={d.today}
                    />
                  </Card>
                </>
              )}
            </section>
          </>
        )}
      </main>
    </>
  );
}

type Cell = { active: number | null; max: number };

/** Une ligne par cohorte, la plus récente d'abord : sa taille, puis la part active à chaque jalon. */
function CohortTable({ rows, baseLabel, firstLabel, today }: { rows: { day: string; base: number; first?: Cell; cells: Cell[] }[]; baseLabel: string; firstLabel?: string; today: string }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[720px] text-[14px]">
        <thead>
          <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
            <th className="py-2 pr-3 font-bold">Signup day</th>
            <Th>{baseLabel}</Th>
            {firstLabel && <Th>{firstLabel}</Th>}
            {RETENTION_MILESTONES.map((m) => (
              <Th key={m}>{MILESTONE_LABEL[m]}</Th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-line">
          {rows.map((row) => (
            <tr key={row.day}>
              <td className="py-2 pr-3 font-semibold whitespace-nowrap">
                {cohortDay(row.day)}
                {row.day === today && <span className="ml-2 text-[12px] font-bold text-ink-3">today, so far</span>}
              </td>
              <td className="py-2 pl-3 text-right font-extrabold whitespace-nowrap text-ink tabular-nums">{n(row.base)}</td>
              {row.first && <Rate cell={row.first} base={row.base} />}
              {row.cells.map((cell, i) => (
                <Rate key={RETENTION_MILESTONES[i]} cell={cell} base={row.base} />
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function Th({ children }: { children: React.ReactNode }) {
  return <th className="py-2 pl-3 text-right font-bold">{children}</th>;
}

/** Une case : la part, sur un fond d'autant plus soutenu qu'elle est haute dans sa colonne ;
 *  le nombre de comptes est dans l'infobulle. */
function Rate({ cell, base }: { cell: Cell; base: number }) {
  const rate = retained(cell.active, base);
  return (
    <td className="py-1 pl-3 text-right whitespace-nowrap tabular-nums">
      {rate == null ? (
        <span className="px-2 text-ink-3">–</span>
      ) : (
        <span title={`${n(Number(cell.active))} of ${n(base)} accounts`} className="inline-block min-w-[64px] rounded-md px-2 py-1 font-semibold text-ink" style={{ backgroundColor: heat(rate, cell.max) }}>
          {percent(rate)}
        </span>
      )}
    </td>
  );
}
