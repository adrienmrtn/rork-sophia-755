import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, SectionTitle, Tile } from "@/components/admin/DataChrome";
import { DayBars } from "@/components/admin/DayBars";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { funnel, questionViews, type FunnelStep, type OnboardingDashboard } from "@/lib/studio/onboarding";
import { percent, readDataFilters } from "@/lib/studio/paywalls";

export const dynamic = "force-dynamic";

/** L'onboarding : combien d'installations voient chaque écran, et ce qu'elles répondent.
 *  Tout vient d'un appel à admin_onboarding_dashboard, réservé à l'équipe. */
export default async function OnboardingDataPage({ searchParams }: PageProps<"/admin/data/onboarding">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const filters = readDataFilters(await searchParams);

  const { data, error } = await session.supabase.rpc("admin_onboarding_dashboard", { p_days: filters.days, p_platform: filters.platform, p_lang: filters.lang });
  const d = (data ?? null) as OnboardingDashboard | null;
  const steps = funnel(d?.steps ?? []);
  const questions = questionViews(d?.questions ?? []);
  const started = steps.find((s) => s.step === "welcome")?.installs ?? Math.max(0, ...steps.map((s) => s.installs));
  const at = (name: string) => steps.find((s) => s.step === name) ?? null;
  const login = at("login");
  const afterLogin = at("welcome_aboard");
  const paywall = Math.max(at("paywall_annual")?.installs ?? 0, 0) + Math.max(at("paywall")?.installs ?? 0, 0);

  return (
    <>
      <AdminHeader session={session} active="data" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Data" lead="What people do in the app: paywalls and onboarding." />
        <DataNav active="onboarding" filters={filters} languages={d?.languages ?? []} />

        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}

        {d && (
          <>
            <section className="flex flex-col gap-4">
              <SectionTitle
                title="Funnel"
                note={`One installation counts once per day and per screen, with or without an account, in UTC days.${d.updated_at ? ` Refreshed every hour, last on ${shortDateTime(d.updated_at)}.` : ""}`}
              />
              {steps.length === 0 ? (
                <Card className="p-6 text-[14px] text-ink-3">No onboarding was recorded with these filters. Only app versions that send usage events are counted: until they are released, the numbers here come from test builds.</Card>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                    <Tile label="Started" value={started.toLocaleString("en")} />
                    <Tile label="Reached login" value={login ? `${login.installs.toLocaleString("en")} · ${percent(login.share)}` : "–"} />
                    <Tile label="Signed in" value={afterLogin ? `${afterLogin.installs.toLocaleString("en")} · ${percent(afterLogin.share)}` : "–"} />
                    <Tile label="Reached the paywall" value={paywall ? `${paywall.toLocaleString("en")} · ${percent(started ? paywall / started : null)}` : "–"} />
                  </div>

                  <Card className="flex flex-col gap-4 p-6">
                    <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Onboardings started per day</h3>
                    <DayBars series={d.series.map((p) => ({ day: p.day, value: Number(p.installs) }))} unit="installations" label="Onboardings started per day" />
                  </Card>

                  <Card className="flex flex-col gap-4 p-6">
                    <div className="flex flex-col gap-1">
                      <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Screen by screen</h3>
                      <p className="text-[13px] text-ink-3">The share is against the installations that started. “Lost” is the gap with the screen before; a screen that part of the people never sees by design is marked, and its dip is not a drop-off.</p>
                    </div>
                    <FunnelTable steps={steps} />
                  </Card>
                </>
              )}
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle title="Answers" note="The last answer each installation gave. The age is a range, never an exact age; first names are not collected." />
              {questions.length === 0 ? (
                <Card className="p-6 text-[14px] text-ink-3">No answer on this period. Answers are sent by the next app versions.</Card>
              ) : (
                <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
                  {questions.map((q) => (
                    <Card key={q.question} className="flex flex-col gap-3 p-6">
                      <div className="flex items-baseline justify-between gap-3">
                        <h3 className="text-[16px] font-extrabold">{q.label}</h3>
                        <span className="shrink-0 text-[13px] text-ink-3 tabular-nums">{q.answered.toLocaleString("en")} answered</span>
                      </div>
                      <ul className="flex flex-col gap-2">
                        {q.options.map((o) => (
                          <li key={o.value} className="flex flex-col gap-1">
                            <div className="flex items-baseline justify-between gap-3 text-[14px]">
                              <span className="font-semibold">{o.label}</span>
                              <span className="shrink-0 tabular-nums text-ink-2">
                                {o.installs.toLocaleString("en")} · <strong className="text-ink">{percent(o.share)}</strong>
                              </span>
                            </div>
                            <Bar share={o.share} />
                          </li>
                        ))}
                      </ul>
                    </Card>
                  ))}
                </div>
              )}
            </section>
          </>
        )}
      </main>
    </>
  );
}

/** Une barre horizontale, de 0 à 100 % de la largeur. */
function Bar({ share, tone = "navy" }: { share: number | null; tone?: "navy" | "muted" }) {
  const width = Math.max(0, Math.min(1, share ?? 0)) * 100;
  return (
    <div className="h-2 w-full overflow-hidden rounded-full bg-paper" aria-hidden="true">
      <div className={`h-full rounded-full ${tone === "navy" ? "bg-navy" : "bg-line-2"}`} style={{ width: `${width}%` }} />
    </div>
  );
}

function FunnelTable({ steps }: { steps: FunnelStep[] }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[640px] text-[14px]">
        <thead>
          <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
            <th className="w-8 py-2 pr-2 font-bold">#</th>
            <th className="py-2 pr-3 font-bold">Screen</th>
            <th className="w-[34%] py-2 pr-3 font-bold" aria-label="Share, as a bar" />
            <th className="py-2 pl-3 text-right font-bold">Installations</th>
            <th className="py-2 pl-3 text-right font-bold">Share</th>
            <th className="py-2 pl-3 text-right font-bold">Lost</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-line">
          {steps.map((s, i) => {
            const previous = i > 0 ? steps[i - 1] : null;
            // Un écran facultatif fausse l'écart, pour lui comme pour celui qui le suit.
            const comparable = previous && !s.note && !previous.note && previous.installs > 0;
            const lost = comparable ? 1 - s.installs / previous.installs : null;
            return (
              <tr key={s.step}>
                <td className="py-2 pr-2 text-ink-3 tabular-nums">{i + 1}</td>
                <td className="py-2 pr-3">
                  <span className="font-semibold whitespace-nowrap">{s.label}</span>
                  {s.note && <span className="ml-2 rounded-full bg-paper px-2 py-0.5 text-[12px] font-semibold whitespace-nowrap text-ink-3">{s.note}</span>}
                </td>
                <td className="py-2 pr-3">
                  <Bar share={s.share} tone={s.note ? "muted" : "navy"} />
                </td>
                <td className="py-2 pl-3 text-right tabular-nums text-ink-2">{s.installs.toLocaleString("en")}</td>
                <td className="py-2 pl-3 text-right font-extrabold tabular-nums text-ink">{percent(s.share)}</td>
                <td className={`py-2 pl-3 text-right tabular-nums ${lost !== null && lost >= 0.1 ? "font-extrabold text-coral" : "text-ink-3"}`}>{lost === null || lost <= 0 ? "–" : `−${percent(lost)}`}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
