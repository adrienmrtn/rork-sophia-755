import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, PLATFORM_LABEL, SectionTitle, Tile } from "@/components/admin/DataChrome";
import { DayBars } from "@/components/admin/DayBars";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { percent, readDataFilters } from "@/lib/studio/paywalls";
import { DUEL_KIND_LABEL, courseName, perDay, ratio, type UsageCounts, type UsageDashboard } from "@/lib/studio/usage";

export const dynamic = "force-dynamic";

const n = (value: number) => Number(value).toLocaleString("en");

/** L'usage de l'app : lecture, quiz et duels. Tout vient d'un appel à admin_usage_dashboard,
 *  réservé à l'équipe. */
export default async function UsageDataPage({ searchParams }: PageProps<"/admin/data/usage">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const filters = readDataFilters(await searchParams);

  const { data, error } = await session.supabase.rpc("admin_usage_dashboard", { p_days: filters.days, p_platform: filters.platform, p_lang: filters.lang });
  const d = (data ?? null) as UsageDashboard | null;
  const duelsStarted = (d?.duels.by_kind ?? []).reduce((total, row) => total + Number(row.started), 0);

  return (
    <>
      <AdminHeader session={session} active="data" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Data" lead="What people do in the app: paywalls, onboarding, usage, friends and feedback." />
        <DataNav active="usage" filters={filters} languages={d?.languages ?? []} />

        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}

        {d && (
          <>
            <section className="flex flex-col gap-4">
              <SectionTitle title="Reading" note={`Counted by the app itself, signed-in users, in UTC days.${d.updated_at ? ` Refreshed every hour, last on ${shortDateTime(d.updated_at)}.` : ""}`} />
              {Number(d.totals.user_days) === 0 ? (
                <Card className="p-6 text-[14px] text-ink-3">No usage was recorded with these filters. Only app versions that send usage events are counted: until they are released, the numbers here come from test builds.</Card>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-4 md:grid-cols-5">
                    <Tile label="Active users per day" value={n(perDay(d.totals.user_days, d.days))} />
                    <Tile label="Courses opened" value={n(d.totals.course_opens)} />
                    <Tile label="Pages read" value={n(d.totals.pages_read)} />
                    <Tile label="Courses finished" value={`${n(d.totals.completes)} · ${percent(ratio(d.totals.completes, d.totals.course_opens))}`} />
                    <Tile label="Likes" value={n(d.totals.likes)} />
                  </div>
                  <p className="text-[13px] text-ink-3">Active users per day is the average over the period. A page read is one section of a course left after reading. “Finished” is against courses opened.</p>

                  <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
                    <Card className="flex flex-col gap-4 p-6">
                      <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Active users per day</h3>
                      <DayBars series={d.series.map((p) => ({ day: p.day, value: Number(p.active_users) }))} unit="users" label="Active users per day" />
                    </Card>
                    <Card className="flex flex-col gap-4 p-6">
                      <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Pages read per day</h3>
                      <DayBars series={d.series.map((p) => ({ day: p.day, value: Number(p.pages_read) }))} unit="pages" label="Pages read per day" />
                    </Card>
                  </div>

                  <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
                    <Card className="flex flex-col gap-3 p-6">
                      <h3 className="text-[16px] font-extrabold">By language</h3>
                      <UsageTable first="Language" rows={d.by_language.map((r) => ({ key: r.lang, ...r }))} days={d.days} />
                    </Card>
                    <Card className="flex flex-col gap-3 p-6">
                      <h3 className="text-[16px] font-extrabold">By platform</h3>
                      <UsageTable first="Platform" rows={d.by_platform.map((r) => ({ key: PLATFORM_LABEL[r.platform] ?? r.platform, ...r }))} days={d.days} />
                    </Card>
                  </div>

                  <Card className="flex flex-col gap-3 p-6">
                    <div className="flex flex-col gap-1">
                      <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Most opened courses</h3>
                      <p className="text-[13px] text-ink-3">The 25 most opened. Pages per open tells how far people read once inside.</p>
                    </div>
                    <div className="overflow-x-auto">
                      <table className="w-full min-w-[680px] text-[14px]">
                        <thead>
                          <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
                            <th className="w-8 py-2 pr-2 font-bold">#</th>
                            <th className="py-2 pr-3 font-bold">Course</th>
                            <Th>Opens</Th>
                            <Th>Pages read</Th>
                            <Th>Pages / open</Th>
                            <Th>Finished</Th>
                            <Th>Likes</Th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-line">
                          {d.top_courses.map((c, i) => (
                            <tr key={c.course_id}>
                              <td className="py-2 pr-2 text-ink-3 tabular-nums">{i + 1}</td>
                              <td className="py-2 pr-3 font-semibold">{courseName(c)}</td>
                              <Td strong>{n(c.opens)}</Td>
                              <Td>{n(c.pages_read)}</Td>
                              <Td>{Number(c.opens) ? (Number(c.pages_read) / Number(c.opens)).toFixed(1) : "–"}</Td>
                              <Td>{percent(ratio(c.completes, c.opens))}</Td>
                              <Td>{n(c.likes)}</Td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </Card>
                </>
              )}
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle title="Quiz" note="Every answer validated in a quiz: end of course, learning path and training." />
              <div className="grid grid-cols-2 gap-4 md:grid-cols-3">
                <Tile label="Answers" value={n(d.totals.quiz_answers)} />
                <Tile label="Correct" value={percent(ratio(d.totals.quiz_correct, d.totals.quiz_answers))} />
                <Tile label="Questions answered" value={n(d.quiz.questions_seen)} />
              </div>
              <Card className="flex flex-col gap-3 p-6">
                <div className="flex flex-col gap-1">
                  <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Most missed questions</h3>
                  <p className="text-[13px] text-ink-3">
                    The 25 lowest shares of correct answers, among the {n(d.quiz.questions_ranked)} questions with at least {n(d.min_answers)} answers. A question nearly everyone misses is often badly worded rather than hard.
                  </p>
                </div>
                {d.quiz.hardest.length === 0 ? (
                  <p className="text-[14px] text-ink-3">No question has reached {n(d.min_answers)} answers on this period yet.</p>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full min-w-[680px] text-[14px]">
                      <thead>
                        <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
                          <th className="py-2 pr-3 font-bold">Question</th>
                          <Th>Answers</Th>
                          <Th>Correct</Th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-line">
                        {d.quiz.hardest.map((q) => (
                          <tr key={q.question_id}>
                            <td className="py-2 pr-3">
                              <span className="block font-semibold">{q.question ?? q.question_id}</span>
                              <span className="block text-[13px] text-ink-3">{courseName(q)}</span>
                            </td>
                            <Td>{n(q.answers)}</Td>
                            <Td strong>{percent(Number(q.rate))}</Td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </Card>
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle
                title="Duels"
                note={`Counted by the game server, every app version. A duel between friends counts for the one who starts it.${filters.platform ? " With a platform filter, only players whose app sends usage events are counted." : ""}`}
              />
              <div className="grid grid-cols-1 gap-5 lg:grid-cols-[1fr_2fr]">
                <Card className="flex flex-col gap-3 p-6">
                  <div className="flex items-baseline justify-between gap-3">
                    <h3 className="text-[16px] font-extrabold">Duels started</h3>
                    <strong className="text-[22px] font-extrabold text-ink tabular-nums">{n(duelsStarted)}</strong>
                  </div>
                  {d.duels.by_kind.length === 0 ? (
                    <p className="text-[14px] text-ink-3">No duel on this period.</p>
                  ) : (
                    <table className="w-full text-[14px]">
                      <thead>
                        <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
                          <th className="py-2 pr-3 font-bold">Type</th>
                          <Th>Started</Th>
                          <Th>Finished</Th>
                          <Th>Abandoned</Th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-line">
                        {d.duels.by_kind.map((k) => (
                          <tr key={k.kind}>
                            <td className="py-2 pr-3 font-semibold">{DUEL_KIND_LABEL[k.kind] ?? k.kind}</td>
                            <Td strong>{n(k.started)}</Td>
                            <Td>{n(k.finished)}</Td>
                            <Td>{`${n(k.abandoned)} · ${percent(ratio(k.abandoned, k.started))}`}</Td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </Card>
                <Card className="flex flex-col gap-4 p-6">
                  <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Duels started per day</h3>
                  <DayBars series={d.series.map((p) => ({ day: p.day, value: Number(p.duels) }))} unit="duels" label="Duels started per day" />
                </Card>
              </div>
            </section>
          </>
        )}
      </main>
    </>
  );
}

function Th({ children }: { children: React.ReactNode }) {
  return <th className="py-2 pl-3 text-right font-bold">{children}</th>;
}

function Td({ children, strong }: { children: React.ReactNode; strong?: boolean }) {
  return <td className={`py-2 pl-3 text-right whitespace-nowrap tabular-nums ${strong ? "font-extrabold text-ink" : "text-ink-2"}`}>{children}</td>;
}

function UsageTable({ first, rows, days }: { first: string; rows: (UsageCounts & { key: string })[]; days: number }) {
  if (rows.length === 0) return <p className="text-[14px] text-ink-3">Nothing on this period.</p>;
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[440px] text-[14px]">
        <thead>
          <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
            <th className="py-2 pr-3 font-bold">{first}</th>
            <Th>Users / day</Th>
            <Th>Opens</Th>
            <Th>Pages</Th>
            <Th>Quiz correct</Th>
          </tr>
        </thead>
        <tbody className="divide-y divide-line">
          {rows.map((r) => (
            <tr key={r.key}>
              <td className="py-2 pr-3 font-semibold whitespace-nowrap">{r.key}</td>
              <Td strong>{n(perDay(r.user_days, days))}</Td>
              <Td>{n(r.course_opens)}</Td>
              <Td>{n(r.pages_read)}</Td>
              <Td>{percent(ratio(r.quiz_correct, r.quiz_answers))}</Td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
