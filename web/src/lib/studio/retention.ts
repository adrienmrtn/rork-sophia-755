/** Ce que renvoie la fonction SQL admin_retention_dashboard (docs/events.md), et les calculs
 *  que la page /admin/data/retention fait dessus. */

export const RETENTION_MILESTONES = ["d1", "d3", "d7", "d14", "d30"] as const;
export type RetentionMilestone = (typeof RETENTION_MILESTONES)[number];

export const MILESTONE_LABEL: Record<RetentionMilestone, string> = { d1: "D+1", d3: "D+3", d7: "D+7", d14: "D+14", d30: "D+30" };

/** Une cohorte : les comptes créés un jour UTC. Un jalon est null tant que son jour n'est pas terminé. */
export type RetentionCohort = { day: string; signups: number; d0: number } & Record<RetentionMilestone, number | null>;

export interface RetentionDashboard {
  days: number;
  from: string;
  today: string;
  updated_at: string | null;
  cohorts: RetentionCohort[];
  /** Pour chaque jalon, les actifs et les inscrits des seules cohortes où il est connu. */
  totals: { signups: number; d0: number } & Record<RetentionMilestone, { active: number; signups: number }>;
}

/** La part d'une cohorte encore active à un jalon, ou null si le jalon n'est pas connu. */
export function retained(active: number | null | undefined, signups: number): number | null {
  if (active == null) return null;
  const s = Number(signups);
  return s ? Number(active) / s : null;
}

/** Le fond d'une case, d'autant plus soutenu que la part est haute par rapport à `max`
 *  (la plus haute part de la colonne) : on lit d'un coup d'œil les bonnes et les mauvaises cohortes. */
export function heat(rate: number | null, max: number): string | undefined {
  if (rate == null || max <= 0) return undefined;
  const alpha = 0.06 + 0.34 * Math.min(1, rate / max);
  return `rgba(26, 58, 107, ${alpha.toFixed(2)})`;
}
