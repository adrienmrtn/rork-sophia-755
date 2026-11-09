/** La rémunération des auteurs : 15 $ par cours validé, cagnotte versée le lundi, quota de cours.
 *  Les règles vivent en base (studio_quota, creator_credits) ; ici, les types et les textes. */

export interface Quota {
  limit: number;
  used: number;
  open: number;
  can_propose: boolean;
  can_validate: boolean;
  first_week: boolean;
  period_start: string | null;
  period_end: string | null;
  next_slot_at: string | null;
  blocked: boolean;
  custom: boolean;
  fee_cents: number;
  currency: string;
}

export interface Credit {
  id: number;
  draft_id: string | null;
  title: string;
  amount_cents: number;
  created_at: string;
  paid_at: string | null;
}

export interface PayoutRow {
  id: number;
  amount_cents: number;
  credits_count: number;
  paid_at: string;
}

export const DEFAULT_FEE_CENTS = 1500;

/** 1500 → "$15", 1250 → "$12.50". */
export function moneyCents(cents: number, currency = "USD"): string {
  const whole = Number.isInteger(cents / 100);
  return new Intl.NumberFormat("en-US", { style: "currency", currency, minimumFractionDigits: whole ? 0 : 2, maximumFractionDigits: 2 }).format(cents / 100);
}

/** « Monday 17 Nov », dans le fuseau du Studio. */
export function dayLabel(iso: string | null | undefined): string {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "short", timeZone: "Europe/Paris" });
}

/** Lit ce que la base renvoie (nombres parfois en texte) ; null si absent. */
export function parseQuota(raw: unknown): Quota | null {
  if (!raw || typeof raw !== "object") return null;
  const q = raw as Record<string, unknown>;
  const n = (v: unknown, d = 0) => (v == null || v === "" ? d : Number(v));
  return {
    limit: n(q.limit),
    used: n(q.used),
    open: n(q.open),
    can_propose: Boolean(q.can_propose),
    can_validate: Boolean(q.can_validate),
    first_week: Boolean(q.first_week),
    period_start: typeof q.period_start === "string" ? q.period_start : null,
    period_end: typeof q.period_end === "string" ? q.period_end : null,
    next_slot_at: typeof q.next_slot_at === "string" ? q.next_slot_at : null,
    blocked: Boolean(q.blocked),
    custom: Boolean(q.custom),
    fee_cents: n(q.fee_cents, DEFAULT_FEE_CENTS),
    currency: typeof q.currency === "string" && q.currency ? q.currency : "USD",
  };
}

export type QuotaTone = "ok" | "full" | "blocked";

/** Le bandeau du quota, pour l'auteur : une ligne de titre, une ligne de détail, une couleur. */
export function quotaSummary(q: Quota | null): { headline: string; detail: string; tone: QuotaTone } {
  if (!q) return { headline: "Your limit will appear once your account is created.", detail: "", tone: "ok" };
  if (q.blocked) {
    return { headline: "Proposals are paused on your account.", detail: "The team set your limit to zero. Write to them to start again.", tone: "blocked" };
  }
  const period = q.first_week ? "First week" : "This week";
  const validated = `${q.used} of ${q.limit} ${q.limit === 1 ? "course" : "courses"} validated`;
  const headline = `${period}: ${validated}.`;
  const parts: string[] = [];
  if (q.open > 0) parts.push(`${q.open} in progress`);
  if (q.used >= q.limit && q.period_end) parts.push(`next validation from ${dayLabel(q.period_end)}`);
  else if (q.first_week && q.period_end) parts.push(`then one course a week from ${dayLabel(q.period_end)}`);
  if (!q.can_propose && q.used < q.limit) parts.push("finish a course before proposing another");
  return { headline, detail: parts.join(" · "), tone: q.used >= q.limit ? "full" : "ok" };
}

/** Ce que l'équipe lit sur un auteur : « 1/1 this week · next from Monday 17 Nov ». */
export function quotaBadge(q: Quota | null): string {
  if (!q) return "no quota yet";
  if (q.blocked) return "blocked (limit 0)";
  const period = q.first_week ? "first week" : "this week";
  const next = q.used >= q.limit && q.period_end ? ` · next from ${dayLabel(q.period_end)}` : "";
  return `${q.used}/${q.limit} validated ${period} · ${q.open} in progress${next}${q.custom ? " · custom limit" : ""}`;
}
