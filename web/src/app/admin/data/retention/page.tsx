import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, SectionTitle, Tile } from "@/components/admin/DataChrome";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { percent, readDataFilters } from "@/lib/studio/paywalls";
import { MILESTONE_LABEL, RETENTION_MILESTONES, heat, retained, type RetentionDashboard } from "@/lib/studio/retention";

export const dynamic = "force-dynamic";

const n = (value: number) => Number(value).toLocaleString("en");
const cohortDay = (iso: string) => new Date(`${iso}T00:00:00Z`).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" });

/** La rétention par cohorte d'inscription : une ligne par jour de création de compte, la part
 *  encore active à J+1, J+3, J+7, J+14 et J+30. Tout vient d'un appel à
 *  admin_retention_dashboard, réservé à l'équipe ; ces données ne suivent que la période. */
export default async function RetentionDataPage({ searchParams }: PageProps<"/admin/data/retention">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const filters = readDataFilters(await searchParams);

  const { data, error } = await session.supabase.rpc("admin_retention_dashboard", { p_days: filters.days });
  const d = (data ?? null) as RetentionDashboard | null;
  const cohorts = d?.cohorts ?? [];
  const best = Object.fromEntries(RETENTION_MILESTONES.map((m) => [m, Math.max(0, ...cohorts.map((c) => retained(c[m], c.signups) ?? 0))]));
  const bestD0 = Math.max(0, ...cohorts.map((c) => retained(c.d0, c.signups) ?? 0));

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
          <section className="flex flex-col gap-4">
            <SectionTitle
              title="Retention by signup day"
              note={`A cohort is every account created on one UTC day. These numbers follow the period only.${d.updated_at ? ` Refreshed every hour, last on ${shortDateTime(d.updated_at)}.` : ""}`}
            />
            <div className="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-6">
              <Tile label="Accounts created" value={n(d.totals.signups)} />
              {RETENTION_MILESTONES.map((m) => (
                <Tile key={m} label={`Active on ${MILESTONE_LABEL[m]}`} value={percent(retained(d.totals[m].signups ? d.totals[m].active : null, d.totals[m].signups))} />
              ))}
            </div>
            <p className="text-[13px] text-ink-3">
              Active on D+7 means active on the seventh day after signup exactly, not at some point during the week. A day counts as active when the account earned XP (a course or a quiz finished, reading progress: every app version) or when its app sent
              any usage event (recent versions only, so the newest cohorts read slightly higher). Each share is against all accounts created that day, including those that never read anything. A milestone shows “–” until its day is over, and the tiles
              only average the cohorts old enough to have it.
            </p>

            <Card className="flex flex-col gap-3 p-6">
              {cohorts.length === 0 ? (
                <p className="text-[14px] text-ink-3">No account was created on this period.</p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full min-w-[720px] text-[14px]">
                    <thead>
                      <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
                        <th className="py-2 pr-3 font-bold">Signup day</th>
                        <Th>Accounts</Th>
                        <Th>Active on day 0</Th>
                        {RETENTION_MILESTONES.map((m) => (
                          <Th key={m}>{MILESTONE_LABEL[m]}</Th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-line">
                      {cohorts.map((c) => (
                        <tr key={c.day}>
                          <td className="py-2 pr-3 font-semibold whitespace-nowrap">
                            {cohortDay(c.day)}
                            {c.day === d.today && <span className="ml-2 text-[12px] font-bold text-ink-3">today, so far</span>}
                          </td>
                          <td className="py-2 pl-3 text-right font-extrabold whitespace-nowrap text-ink tabular-nums">{n(c.signups)}</td>
                          <Rate active={c.d0} signups={c.signups} max={bestD0} />
                          {RETENTION_MILESTONES.map((m) => (
                            <Rate key={m} active={c[m]} signups={c.signups} max={best[m]} />
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </Card>
          </section>
        )}
      </main>
    </>
  );
}

function Th({ children }: { children: React.ReactNode }) {
  return <th className="py-2 pl-3 text-right font-bold">{children}</th>;
}

/** Une case : la part, sur un fond d'autant plus soutenu qu'elle est haute dans sa colonne ;
 *  le nombre de comptes est dans l'infobulle. */
function Rate({ active, signups, max }: { active: number | null; signups: number; max: number }) {
  const rate = retained(active, signups);
  return (
    <td className="py-1 pl-3 text-right whitespace-nowrap tabular-nums">
      {rate == null ? (
        <span className="px-2 text-ink-3">–</span>
      ) : (
        <span title={`${n(Number(active))} of ${n(signups)} accounts`} className="inline-block min-w-[64px] rounded-md px-2 py-1 font-semibold text-ink" style={{ backgroundColor: heat(rate, max) }}>
          {percent(rate)}
        </span>
      )}
    </td>
  );
}
