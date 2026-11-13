import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, PLATFORM_LABEL, SectionTitle, Tile } from "@/components/admin/DataChrome";
import { DayBars } from "@/components/admin/DayBars";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import {
  MIN_VARIANT_VIEWERS,
  conversion,
  dollars,
  groupExperiments,
  percent,
  readDataFilters,
  type PaywallCounts,
  type PaywallDashboard,
} from "@/lib/studio/paywalls";

export const dynamic = "force-dynamic";

/** Les données de l'app : les paywalls d'abord (affichages, achats, tests A/B, revenus).
 *  Tout vient d'un appel à admin_paywall_dashboard, réservé à l'équipe. */
export default async function DataPage({ searchParams }: PageProps<"/admin/data">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const filters = readDataFilters(sp);

  const { data, error } = await session.supabase.rpc("admin_paywall_dashboard", { p_days: filters.days, p_platform: filters.platform, p_lang: filters.lang });
  const d = (data ?? null) as PaywallDashboard | null;
  const languages = d?.languages ?? [];
  const experiments = groupExperiments(d?.by_experiment ?? []);
  const revenue = d?.revenue;

  return (
    <>
      <AdminHeader session={session} active="data" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Data" lead="What people do in the app: paywalls and onboarding." />

        <DataNav active="paywalls" filters={filters} languages={languages} />

        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}

        {d && revenue && (
          <>
            <section className="flex flex-col gap-4">
              <SectionTitle title="In the app" note={`Counted by the app itself, in UTC days.${d.updated_at ? ` Refreshed every hour, last on ${shortDateTime(d.updated_at)}.` : ""}`} />
              {Number(d.totals.views) === 0 ? (
                <Card className="p-6 text-[14px] text-ink-3">No paywall was recorded with these filters. Only app versions that send usage events are counted: until they are released, the numbers here come from test builds.</Card>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-4 md:grid-cols-5">
                    <Tile label="Paywall views" value={Number(d.totals.views).toLocaleString("en")} />
                    <Tile label="Viewers" value={Number(d.totals.viewers).toLocaleString("en")} />
                    <Tile label="Purchases started" value={Number(d.totals.purchases_started).toLocaleString("en")} />
                    <Tile label="Purchases" value={Number(d.totals.purchases_completed).toLocaleString("en")} />
                    <Tile label="Conversion" value={percent(conversion(d.totals))} />
                  </div>
                  <p className="text-[13px] text-ink-3">Viewers are distinct people per day, added up over the period: someone who sees a paywall on two days counts twice. A purchase is a trial or a subscription that the store confirmed. Conversion is purchases divided by viewers.</p>

                  <Card className="flex flex-col gap-4 p-6">
                    <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Paywall views per day</h3>
                    <DayBars series={d.series.map((p) => ({ day: p.day, value: Number(p.views) }))} unit="views" label="Paywall views per day" />
                  </Card>

                  <Card className="flex flex-col gap-3 p-6">
                    <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">By paywall</h3>
                    <CountsTable first="Paywall" rows={d.by_paywall.map((r) => ({ key: r.paywall_id, ...r }))} detailed />
                  </Card>

                  <Card className="flex flex-col gap-4 p-6">
                    <div className="flex flex-col gap-1">
                      <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">A/B tests</h3>
                      <p className="text-[13px] text-ink-3">Each variant against the others of its test. Under {MIN_VARIANT_VIEWERS} viewers per variant, a gap in conversion is noise.</p>
                    </div>
                    {experiments.length === 0 ? (
                      <p className="text-[14px] text-ink-3">No paywall carried a test variant on this period.</p>
                    ) : (
                      experiments.map((group) => (
                        <div key={group.experiment} className="flex flex-col gap-2">
                          <div className="flex flex-wrap items-center gap-2">
                            <code className="rounded-md bg-paper px-2 py-0.5 text-[13px] font-bold text-navy">{group.experiment}</code>
                            {group.variants.some((v) => Number(v.viewers) < MIN_VARIANT_VIEWERS) && <span className="rounded-full bg-amber-bg px-2.5 py-0.5 text-[12px] font-bold text-amber">Too few viewers to conclude</span>}
                          </div>
                          <CountsTable first="Variant" rows={group.variants.map((r) => ({ key: r.variant, ...r }))} />
                        </div>
                      ))
                    )}
                  </Card>

                  <Card className="flex flex-col gap-3 p-6">
                    <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">By offering</h3>
                    <CountsTable first="Offering" rows={d.by_offering.map((r) => ({ key: r.offering, ...r }))} />
                  </Card>

                  <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
                    <Card className="flex flex-col gap-3 p-6">
                      <h3 className="text-[16px] font-extrabold">By language</h3>
                      <CountsTable first="Language" rows={d.by_language.map((r) => ({ key: r.lang, ...r }))} compact />
                    </Card>
                    <Card className="flex flex-col gap-3 p-6">
                      <h3 className="text-[16px] font-extrabold">By platform</h3>
                      <CountsTable first="Platform" rows={d.by_platform.map((r) => ({ key: PLATFORM_LABEL[r.platform] ?? r.platform, ...r }))} compact />
                    </Card>
                  </div>
                </>
              )}
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle
                title="Revenue"
                note={`From RevenueCat, every app version, in US dollars${revenue.first_day ? `, since ${shortDay(revenue.first_day)}` : ""}. Follows the period and the platform, not the language.`}
              />
              <div className="grid grid-cols-2 gap-4 md:grid-cols-5">
                <Tile label="Revenue" value={dollars(revenue.totals.revenue)} />
                <Tile label="After store fees" value={dollars(revenue.totals.proceeds)} />
                <Tile label="Trials started" value={Number(revenue.totals.trials).toLocaleString("en")} />
                <Tile label="Trials converted" value={Number(revenue.totals.trial_conversions).toLocaleString("en")} />
                <Tile label="Bought without trial" value={Number(revenue.totals.direct_purchases).toLocaleString("en")} />
              </div>
              <Card className="flex flex-col gap-4 p-6">
                <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Revenue per day</h3>
                <DayBars series={revenue.series.map((p) => ({ day: p.day, value: Number(p.revenue) }))} unit="dollars" label="Revenue per day" money color="#387d5a" />
              </Card>
              <Card className="flex flex-col gap-3 p-6">
                <div className="flex flex-col gap-1">
                  <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">By offering</h3>
                  <p className="text-[13px] text-ink-3">The offering the customer was shown when they first subscribed. Refunds are already taken out of revenue.</p>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full min-w-[720px] text-[14px]">
                    <thead>
                      <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
                        <th className="py-2 pr-3 font-bold">Offering</th>
                        <Th>Trials started</Th>
                        <Th>Trials converted</Th>
                        <Th>Without trial</Th>
                        <Th>Renewals</Th>
                        <Th>Refunds</Th>
                        <Th>Revenue</Th>
                        <Th>After fees</Th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-line">
                      {revenue.by_offering.map((r) => (
                        <tr key={r.offering}>
                          <td className="py-2 pr-3 font-semibold whitespace-nowrap">{r.offering}</td>
                          <Td>{Number(r.trials).toLocaleString("en")}</Td>
                          <Td>{Number(r.trial_conversions).toLocaleString("en")}</Td>
                          <Td>{Number(r.direct_purchases).toLocaleString("en")}</Td>
                          <Td>{Number(r.renewals).toLocaleString("en")}</Td>
                          <Td>{Number(r.refunds).toLocaleString("en")}</Td>
                          <Td strong>{dollars(r.revenue)}</Td>
                          <Td>{dollars(r.proceeds)}</Td>
                        </tr>
                      ))}
                      {revenue.by_offering.length === 0 && (
                        <tr>
                          <td colSpan={8} className="py-4 text-ink-3">
                            No subscription event on this period.
                          </td>
                        </tr>
                      )}
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

function shortDay(day: string): string {
  return new Date(`${day}T00:00:00Z`).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" });
}

function Th({ children }: { children: React.ReactNode }) {
  return <th className="py-2 pl-3 text-right font-bold">{children}</th>;
}

function Td({ children, strong }: { children: React.ReactNode; strong?: boolean }) {
  return <td className={`py-2 pl-3 text-right tabular-nums ${strong ? "font-extrabold text-ink" : "text-ink-2"}`}>{children}</td>;
}

/** Affichages, personnes, achats et conversion, une ligne par valeur de la première colonne.
 *  `detailed` ajoute les achats lancés et abandonnés ; `compact` ne garde que l'essentiel. */
function CountsTable({ first, rows, detailed, compact }: { first: string; rows: (PaywallCounts & { key: string })[]; detailed?: boolean; compact?: boolean }) {
  if (rows.length === 0) return <p className="text-[14px] text-ink-3">Nothing on this period.</p>;
  return (
    <div className="overflow-x-auto">
      <table className={`w-full text-[14px] ${compact ? "min-w-[340px]" : "min-w-[560px]"}`}>
        <thead>
          <tr className="border-b border-line text-left text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">
            <th className="py-2 pr-3 font-bold">{first}</th>
            {!compact && <Th>Views</Th>}
            <Th>Viewers</Th>
            {!compact && <Th>Started</Th>}
            {detailed && <Th>Cancelled</Th>}
            <Th>Purchases</Th>
            <Th>Conversion</Th>
          </tr>
        </thead>
        <tbody className="divide-y divide-line">
          {rows.map((r) => (
            <tr key={r.key}>
              <td className="py-2 pr-3 font-semibold whitespace-nowrap">{r.key}</td>
              {!compact && <Td>{Number(r.views).toLocaleString("en")}</Td>}
              <Td>{Number(r.viewers).toLocaleString("en")}</Td>
              {!compact && <Td>{Number(r.purchases_started).toLocaleString("en")}</Td>}
              {detailed && <Td>{Number(r.purchases_cancelled ?? 0).toLocaleString("en")}</Td>}
              <Td>{Number(r.purchases_completed).toLocaleString("en")}</Td>
              <Td strong>{percent(conversion(r))}</Td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
