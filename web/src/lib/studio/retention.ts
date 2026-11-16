/** Ce que renvoie la fonction SQL admin_cohort_retention (docs/events.md), et les calculs
 *  que la page /admin/data/retention fait dessus. */

export const RETENTION_MILESTONES = ["d1", "d3", "d7", "d14", "d30"] as const;
export type RetentionMilestone = (typeof RETENTION_MILESTONES)[number];

export const MILESTONE_LABEL: Record<RetentionMilestone, string> = { d1: "D+1", d3: "D+3", d7: "D+7", d14: "D+14", d30: "D+30" };

type Milestones<T> = Record<RetentionMilestone, T>;

/** Une cohorte : les comptes créés un jour UTC. Un jalon est null tant que son jour n'est pas terminé. */
export interface RetentionCohort {
  day: string;
  signups: number;
  /** Comptes qui ont gagné de l'XP le jour de l'inscription. */
  learned_0: number;
  /** Comptes qui ont gagné de l'XP le jour J+N. */
  learned: Milestones<number | null>;
  /** Comptes dont l'app envoie des événements : les seuls qu'on peut voir rouvrir l'app. */
  tracked: number;
  /** Parmi les comptes suivis, ceux dont l'app a envoyé un événement le jour J+N. */
  reopened: Milestones<number | null>;
}

export interface RetentionDashboard {
  days: number;
  from: string;
  today: string;
  updated_at: string | null;
  cohorts: RetentionCohort[];
  /** Pour chaque jalon, les actifs et leur base (inscrits ou comptes suivis) dans les seules
   *  cohortes où il est connu. */
  totals: { signups: number; tracked: number; learned_0: number; learned: Milestones<{ active: number; base: number }>; reopened: Milestones<{ active: number; base: number }> };
}

/** La part d'une cohorte active à un jalon, ou null si le jalon n'est pas connu ou la base vide. */
export function retained(active: number | null | undefined, base: number): number | null {
  if (active == null) return null;
  const b = Number(base);
  return b ? Number(active) / b : null;
}

/** Le fond d'une case, d'autant plus soutenu que la part est haute par rapport à `max`
 *  (la plus haute part de la colonne) : on lit d'un coup d'œil les bonnes et les mauvaises cohortes. */
export function heat(rate: number | null, max: number): string | undefined {
  if (rate == null || max <= 0) return undefined;
  const alpha = 0.06 + 0.34 * Math.min(1, rate / max);
  return `rgba(26, 58, 107, ${alpha.toFixed(2)})`;
}

/** En dessous de ce nombre de comptes, une part ne dit rien : la case est montrée en clair. */
export const MIN_COHORT = 30;
