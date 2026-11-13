import Link from "next/link";
import { Card } from "@/components/ui";
import { PAYWALL_PERIODS, PAYWALL_PLATFORMS, dataHref, type DataFilters } from "@/lib/studio/paywalls";

/** Ce que partagent les pages de /admin/data : les onglets, les filtres, les tuiles. */

export const PLATFORM_LABEL: Record<string, string> = { ios: "iOS", android: "Android" };

const TABS = [
  { key: "paywalls", href: "/admin/data", label: "Paywalls" },
  { key: "onboarding", href: "/admin/data/onboarding", label: "Onboarding" },
  { key: "usage", href: "/admin/data/usage", label: "Usage" },
  { key: "social", href: "/admin/data/social", label: "Friends" },
  { key: "feedback", href: "/admin/data/feedback", label: "Feedback" },
  { key: "health", href: "/admin/data/health", label: "Health" },
] as const;

export type DataTab = (typeof TABS)[number]["key"];

/** Les onglets et les trois filtres. Changer d'onglet garde les filtres. `periodOnly` : la
 *  page ne connaît ni plateforme ni langue, seuls les choix de période sont montrés. `noFilters` : la page n'a aucun filtre. */
export function DataNav({ active, filters, languages, periodOnly = false, noFilters = false }: { active: DataTab; filters: DataFilters; languages: string[]; periodOnly?: boolean; noFilters?: boolean }) {
  const base = TABS.find((t) => t.key === active)?.href ?? "/admin/data";
  const langs = [...new Set([...languages, ...(filters.lang ? [filters.lang] : [])])].sort();
  return (
    <div className="flex flex-col gap-4">
      <nav aria-label="Data pages" className="flex gap-6 overflow-x-auto border-b border-line">
        {TABS.map((t) => (
          <Link
            key={t.key}
            href={dataHref(filters, t.href)}
            aria-current={t.key === active ? "page" : undefined}
            className={`border-b-2 pb-2.5 text-[15px] font-bold whitespace-nowrap ${t.key === active ? "border-navy text-navy" : "border-transparent text-ink-3 hover:text-navy"}`}
          >
            {t.label}
          </Link>
        ))}
      </nav>
      {!noFilters && (
        <div className="flex flex-wrap items-center gap-3">
          <Segmented label="Period">
            {PAYWALL_PERIODS.map((p) => (
              <Choice key={p} href={dataHref({ ...filters, days: p }, base)} active={p === filters.days}>
                {p === 90 ? "3 months" : `${p} days`}
              </Choice>
            ))}
          </Segmented>
          {!periodOnly && (
            <>
              <Segmented label="Platform">
                <Choice href={dataHref({ ...filters, platform: null }, base)} active={filters.platform === null}>
                  All
                </Choice>
                {PAYWALL_PLATFORMS.map((p) => (
                  <Choice key={p} href={dataHref({ ...filters, platform: p }, base)} active={filters.platform === p}>
                    {PLATFORM_LABEL[p]}
                  </Choice>
                ))}
              </Segmented>
              {(langs.length > 1 || filters.lang) && (
                <Segmented label="Language">
                  <Choice href={dataHref({ ...filters, lang: null }, base)} active={filters.lang === null}>
                    All
                  </Choice>
                  {langs.map((l) => (
                    <Choice key={l} href={dataHref({ ...filters, lang: l }, base)} active={filters.lang === l}>
                      {l}
                    </Choice>
                  ))}
                </Segmented>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}

function Segmented({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-2">
      <span className="text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">{label}</span>
      <div className="flex flex-wrap items-center gap-1 rounded-xl border border-line bg-white p-1">{children}</div>
    </div>
  );
}

function Choice({ href, active, children }: { href: string; active: boolean; children: React.ReactNode }) {
  return (
    <Link href={href} aria-current={active ? "true" : undefined} className={`rounded-lg px-3 py-1.5 text-[13px] font-bold ${active ? "bg-navy text-white" : "text-ink-3 hover:bg-paper"}`}>
      {children}
    </Link>
  );
}

export function SectionTitle({ title, note }: { title: string; note: string }) {
  return (
    <div className="flex flex-col gap-1">
      <h2 className="text-[22px] font-extrabold tracking-[-0.5px] text-ink">{title}</h2>
      <p className="text-[13px] text-ink-3">{note}</p>
    </div>
  );
}

export function Tile({ label, value }: { label: string; value: string }) {
  return (
    <Card className="flex h-full flex-col gap-1 p-5">
      <span className="text-[13px] font-bold text-ink-3">{label}</span>
      <strong className="text-[28px] font-extrabold tracking-[-0.7px] text-ink tabular-nums">{value}</strong>
    </Card>
  );
}
