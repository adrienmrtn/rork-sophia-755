import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, PLATFORM_LABEL, SectionTitle, Tile } from "@/components/admin/DataChrome";
import { DayBars } from "@/components/admin/DayBars";
import { Card, Pill, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { bytesLabel, healthAlerts, projectedJournalBytes, scheduleLabel, type DataHealth } from "@/lib/studio/health";
import { percent, readDataFilters } from "@/lib/studio/paywalls";
import { ratio } from "@/lib/studio/usage";

export const dynamic = "force-dynamic";

const n = (value: number) => Number(value).toLocaleString("en");

/** La santé de la collecte : ce qui arrive, ce que ça pèse, et si les recalculs tournent.
 *  Tout vient d'un appel à admin_data_health, réservé à l'équipe. La page n'a pas de filtre. */
export default async function HealthDataPage({ searchParams }: PageProps<"/admin/data/health">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const filters = readDataFilters(await searchParams);

  const { data, error } = await session.supabase.rpc("admin_data_health");
  const d = (data ?? null) as DataHealth | null;
  const alerts = d ? healthAlerts(d) : [];
  const projected = d ? projectedJournalBytes(d) : 0;
  const yesterday = d ? d.platforms.reduce((total, p) => total + Number(p.events_yesterday), 0) : 0;

  return (
    <>
      <AdminHeader session={session} active="data" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Data" lead="What people do in the app: paywalls, onboarding, usage, friends and feedback." />
        <DataNav active="health" filters={filters} languages={[]} noFilters />

        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}

        {d && (
          <>
            <section className="flex flex-col gap-4">
              <SectionTitle title="Collection health" note={`Is data coming in, how much room does it take, and do the hourly refreshes run. Checked on ${shortDateTime(d.checked_at)}.`} />
              {alerts.length === 0 ? (
                <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">Nothing to act on: both platforms send events and every scheduled task ran.</p>
              ) : (
                <ul className="flex flex-col gap-2">
                  {alerts.map((a) => (
                    <li key={a.text} role={a.level === "red" ? "alert" : undefined} className={`rounded-xl px-4 py-3 text-[14px] font-semibold ${a.level === "red" ? "bg-red-bg text-red" : "bg-amber-bg text-amber"}`}>
                      {a.text}
                    </li>
                  ))}
                </ul>
              )}
              <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                <Tile label="Events yesterday" value={n(yesterday)} />
                <Tile label="Database size" value={bytesLabel(d.database_bytes)} />
                <Tile label="Event journal" value={bytesLabel(Number(d.journal.bytes) + Number(d.journal.onboarding_bytes))} />
                <Tile label={`Journal at ${d.retention_days} days`} value={`~${bytesLabel(projected)}`} />
              </div>
              <p className="text-[13px] text-ink-3">
                The journal keeps the detail of every event for {d.retention_days} days ({n(d.journal.days_kept)} so far{d.journal.oldest_day ? `, since ${d.journal.oldest_day}` : ""}, about {n(d.journal.rows)} rows). “Journal at {d.retention_days} days” is the size it will settle at if events keep coming at the pace of the last seven full days. The daily
                summaries behind every page of this section are kept forever and weigh {bytesLabel(d.journal.summaries_bytes)}.
              </p>
              <Card className="flex flex-col gap-4 p-6">
                <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Events received per day</h3>
                <DayBars series={d.series.map((p) => ({ day: p.day, value: Number(p.events) }))} unit="events" label="Events received per day" />
              </Card>
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle title="Where the volume comes from" note="The last seven full days. An event that dominates here is the first place to look when the journal grows too fast." />
              <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
                <Card className="flex flex-col gap-3 p-6">
                  <h3 className="text-[16px] font-extrabold">By event</h3>
                  {d.last_7_days.by_name.length === 0 ? (
                    <p className="text-[14px] text-ink-3">No event on the last seven days.</p>
                  ) : (
                    <ul className="flex flex-col gap-2">
                      {d.last_7_days.by_name.slice(0, 12).map((e) => {
                        const share = ratio(e.events, d.last_7_days.events);
                        return (
                          <li key={e.name} className="flex flex-col gap-1">
                            <div className="flex items-baseline justify-between gap-3 text-[14px]">
                              <code className="font-semibold">{e.name}</code>
                              <span className="shrink-0 tabular-nums text-ink-2">
                                {n(e.events)} · <strong className="text-ink">{percent(share)}</strong>
                              </span>
                            </div>
                            <div className="h-2 w-full overflow-hidden rounded-full bg-paper" aria-hidden="true">
                              <div className="h-full rounded-full bg-navy" style={{ width: `${Math.min(1, share ?? 0) * 100}%` }} />
                            </div>
                          </li>
                        );
                      })}
                    </ul>
                  )}
                </Card>
                <Card className="flex flex-col gap-3 p-6">
                  <h3 className="text-[16px] font-extrabold">By app version</h3>
                  <p className="text-[13px] text-ink-3">A version missing here does not collect usage. A platform with no line has sent nothing this week.</p>
                  {d.last_7_days.by_version.length === 0 ? (
                    <p className="text-[14px] text-ink-3">No event on the last seven days.</p>
                  ) : (
                    <table className="w-full text-[14px]">
                      <thead>
                        <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
                          <th className="py-2 pr-3 font-bold">Platform</th>
                          <th className="py-2 pr-3 font-bold">Version</th>
                          <th className="py-2 pl-3 text-right font-bold">Events</th>
                          <th className="py-2 pl-3 text-right font-bold">Last seen</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-line">
                        {d.last_7_days.by_version.map((v) => (
                          <tr key={`${v.platform}-${v.app_version}`}>
                            <td className="py-2 pr-3 font-semibold">{PLATFORM_LABEL[v.platform] ?? v.platform}</td>
                            <td className="py-2 pr-3 tabular-nums">{v.app_version || "–"}</td>
                            <td className="py-2 pl-3 text-right font-extrabold tabular-nums">{n(v.events)}</td>
                            <td className="py-2 pl-3 text-right tabular-nums text-ink-2">{v.last_day}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </Card>
              </div>
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle title="Scheduled tasks" note="The tasks that rebuild the daily summaries and drop the detail past its retention. A task that fails or stops leaves this section showing old numbers." />
              <Card className="p-6">
                <div className="overflow-x-auto">
                  <table className="w-full min-w-[560px] text-[14px]">
                    <thead>
                      <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
                        <th className="py-2 pr-3 font-bold">Task</th>
                        <th className="py-2 pr-3 font-bold">Runs</th>
                        <th className="py-2 pr-3 font-bold">Last run</th>
                        <th className="py-2 pl-3 text-right font-bold">Took</th>
                        <th className="py-2 pl-3 text-right font-bold">Result</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-line">
                      {d.jobs.map((job) => (
                        <tr key={job.name}>
                          <td className="py-2 pr-3">
                            <code className="font-semibold">{job.name}</code>
                          </td>
                          <td className="py-2 pr-3 text-ink-2">{scheduleLabel(job.schedule)}</td>
                          <td className="py-2 pr-3 text-ink-2 tabular-nums">{job.started_at ? shortDateTime(job.started_at) : "–"}</td>
                          <td className="py-2 pl-3 text-right tabular-nums text-ink-2">{job.seconds === null ? "–" : `${Number(job.seconds).toFixed(1)} s`}</td>
                          <td className="py-2 pl-3 text-right">
                            {!job.active ? <Pill tone="red">Off</Pill> : job.status === "succeeded" ? <Pill tone="green">OK</Pill> : job.status === "failed" ? <Pill tone="red">Failed</Pill> : <Pill tone="amber">{job.status ?? "Not yet"}</Pill>}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </Card>
            </section>
          </>
        )}
      </main>
    </>
  );
}
