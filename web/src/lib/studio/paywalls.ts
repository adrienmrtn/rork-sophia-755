/** Ce que renvoie la fonction SQL admin_paywall_dashboard (docs/events.md), et les calculs
 *  que la page /admin/data fait dessus. */

export interface PaywallCounts {
  views: number;
  viewers: number;
  purchases_started: number;
  purchases_completed: number;
  purchases_cancelled?: number;
  purchases_failed?: number;
}

export interface RevenueCounts {
  trials: number;
  direct_purchases: number;
  trial_conversions: number;
  renewals: number;
  refunds: number;
  revenue: number;
  proceeds: number;
}

export interface PaywallDashboard {
  days: number;
  from: string;
  updated_at: string | null;
  languages: string[];
  /** Absent tant que la migration 20261116030000 n'est pas appliquée. */
  versions?: AppVersion[];
  totals: PaywallCounts;
  series: { day: string; views: number; purchases: number }[];
  by_paywall: (PaywallCounts & { paywall_id: string })[];
  by_experiment: (PaywallCounts & { experiment: string; variant: string })[];
  by_offering: (PaywallCounts & { offering: string })[];
  by_language: (PaywallCounts & { lang: string })[];
  by_platform: (PaywallCounts & { platform: string })[];
  revenue: {
    totals: RevenueCounts;
    series: { day: string; revenue: number; trials: number }[];
    by_offering: (RevenueCounts & { offering: string })[];
    first_day: string | null;
  };
}

export const PAYWALL_PERIODS = [7, 28, 90];
export const PAYWALL_PLATFORMS = ["ios", "android"] as const;
export type PaywallPlatform = (typeof PAYWALL_PLATFORMS)[number];

/** Achats réussis rapportés aux personnes qui ont vu le paywall ; null sans audience. */
export function conversion(row: Pick<PaywallCounts, "viewers" | "purchases_completed">): number | null {
  const viewers = Number(row.viewers);
  if (!viewers) return null;
  return Number(row.purchases_completed) / viewers;
}

export function percent(rate: number | null): string {
  if (rate === null) return "–";
  const value = rate * 100;
  return `${value >= 10 || value === 0 ? value.toFixed(0) : value.toFixed(1)}%`;
}

/** En dessous de ce nombre de personnes par variante, un écart de conversion ne dit rien. */
export const MIN_VARIANT_VIEWERS = 100;

/** Les variantes regroupées par test, dans l'ordre reçu. */
export function groupExperiments<T extends { experiment: string }>(rows: T[]): { experiment: string; variants: T[] }[] {
  const groups: { experiment: string; variants: T[] }[] = [];
  for (const row of rows) {
    const group = groups.find((g) => g.experiment === row.experiment);
    if (group) group.variants.push(row);
    else groups.push({ experiment: row.experiment, variants: [row] });
  }
  return groups;
}

export interface DataFilters {
  days: number;
  platform: string | null;
  lang: string | null;
  /** Version de l'app (« 1.0.6 »), toujours avec sa plateforme : un numéro n'a de sens que là. */
  version: string | null;
}

/** Une version connue d'un tableau de bord (champ `versions` des fonctions admin_*_dashboard). */
export interface AppVersion {
  platform: string;
  app_version: string;
}

/** Les versions par plateforme, la plus récente d'abord, comparées nombre par nombre
 *  (« 1.0.10 » après « 1.0.9 », ce que l'ordre alphabétique rate). */
export function sortVersions(versions: AppVersion[]): AppVersion[] {
  const parts = (v: string) => v.split(/[^0-9]+/).filter(Boolean).map(Number);
  return [...versions].sort((a, b) => {
    if (a.platform !== b.platform) return a.platform < b.platform ? -1 : 1;
    const x = parts(a.app_version);
    const y = parts(b.app_version);
    for (let i = 0; i < Math.max(x.length, y.length); i++) {
      const diff = (y[i] ?? 0) - (x[i] ?? 0);
      if (diff) return diff;
    }
    return a.app_version < b.app_version ? 1 : a.app_version > b.app_version ? -1 : 0;
  });
}

/** Les arguments communs des fonctions admin_*_dashboard. p_version n'est envoyé que
 *  lorsqu'une version est choisie : sans filtre, l'appel reste celui d'avant. */
export function dataRpcArgs(filters: DataFilters): { p_days: number; p_platform: string | null; p_lang: string | null; p_version?: string } {
  return { p_days: filters.days, p_platform: filters.platform, p_lang: filters.lang, ...(filters.version ? { p_version: filters.version } : {}) };
}

/** L'adresse d'une page de /admin/data pour un jeu de filtres ; les valeurs par défaut
 *  restent hors de l'URL. */
export function dataHref(filters: DataFilters, base = "/admin/data"): string {
  const params = new URLSearchParams();
  if (filters.days !== 28) params.set("days", String(filters.days));
  if (filters.platform) params.set("platform", filters.platform);
  if (filters.lang) params.set("lang", filters.lang);
  if (filters.version && filters.platform) params.set("v", filters.version);
  const query = params.toString();
  return query ? `${base}?${query}` : base;
}

/** Les filtres lus dans l'adresse, ramenés aux valeurs admises. */
export function readDataFilters(sp: Record<string, string | string[] | undefined>): DataFilters {
  const days = PAYWALL_PERIODS.includes(Number(sp.days)) ? Number(sp.days) : 28;
  const platform = PAYWALL_PLATFORMS.includes(sp.platform as PaywallPlatform) ? (sp.platform as PaywallPlatform) : null;
  const lang = typeof sp.lang === "string" && /^[A-Za-z-]{2,7}$/.test(sp.lang) ? sp.lang : null;
  const version = platform && typeof sp.v === "string" && /^[0-9A-Za-z._-]{1,20}$/.test(sp.v) ? sp.v : null;
  return { days, platform, lang, version };
}

export function dollars(value: number): string {
  return Number(value).toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });
}
