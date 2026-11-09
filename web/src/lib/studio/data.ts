import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { GlossaryEntry, Section, Source } from "@/lib/catalog/types";
import type { Hero } from "@/lib/studio/course-format";

/** Ce que le Studio lit en base : le tableau de bord, les brouillons, les jobs. Typé à la main
 *  d'après supabase/migrations/20261109000000_studio.sql. */

export type DraftStatus = "draft" | "submitted" | "changes_requested" | "accepted" | "publishing" | "published" | "failed" | "archived";

export interface DraftRow {
  id: string;
  user_id: string;
  app_course_id: string | null;
  origin_lang: string;
  title: string;
  subtitle: string | null;
  subject: string | null;
  subcategory: string | null;
  description: string;
  hero: Hero;
  sections: Section[];
  sources: Source[];
  glossary: GlossaryEntry[];
  quiz: unknown[] | null;
  status: DraftStatus;
  review_comment: string | null;
  precheck: unknown;
  submitted_at: string | null;
  accepted_at: string | null;
  published_at: string | null;
  version: number;
  last_job_id: string | null;
  created_at: string;
  updated_at: string;
}

export type DraftListRow = Pick<DraftRow, "id" | "title" | "subject" | "status" | "updated_at" | "submitted_at" | "published_at" | "app_course_id" | "last_job_id" | "sections" | "hero" | "review_comment" | "origin_lang" | "user_id">;

export const DRAFT_LIST_COLUMNS = "id,title,subject,status,updated_at,submitted_at,published_at,app_course_id,last_job_id,sections,hero,review_comment,origin_lang,user_id";

export interface DashboardCourse {
  id: string;
  subject: string | null;
  status: string;
  published_at: string | null;
  title: string | null;
  impressions: number;
  reads: number;
  completes: number;
  likes: number;
  readers: number;
  per_1000: number | null;
  completion: number | null;
  quiz_score: number | null;
  languages: { lang: string; reads: number }[];
  published_langs: number;
}

export interface Payout {
  month: string;
  current: boolean;
  minutes: number;
  readers: number;
  share: number;
  pool_net: number;
  pool_share: number;
  currency: string;
  amount: number;
}

export interface Dashboard {
  slug: string | null;
  days: number;
  reads: number;
  reads_prev: number;
  impressions: number;
  completes: number;
  likes: number;
  per_1000: number | null;
  subject_per_1000: Record<string, number>;
  followers_gained: number;
  languages_read: number;
  series: { day: string; reads: number }[];
  courses: DashboardCourse[];
  payouts: Payout[];
}

const EMPTY: Dashboard = { slug: null, days: 28, reads: 0, reads_prev: 0, impressions: 0, completes: 0, likes: 0, per_1000: null, subject_per_1000: {}, followers_gained: 0, languages_read: 0, series: [], courses: [], payouts: [] };

export async function loadDashboard(supabase: SupabaseClient, days: number): Promise<Dashboard> {
  const { data, error } = await supabase.rpc("creator_dashboard", { p_days: days });
  if (error || !data) return { ...EMPTY, days };
  const d = data as Partial<Dashboard>;
  return {
    ...EMPTY,
    ...d,
    days,
    reads: Number(d.reads ?? 0),
    reads_prev: Number(d.reads_prev ?? 0),
    impressions: Number(d.impressions ?? 0),
    completes: Number(d.completes ?? 0),
    likes: Number(d.likes ?? 0),
    followers_gained: Number(d.followers_gained ?? 0),
    languages_read: Number(d.languages_read ?? 0),
    per_1000: d.per_1000 == null ? null : Number(d.per_1000),
    series: (d.series ?? []).map((p) => ({ day: p.day, reads: Number(p.reads) })),
    courses: (d.courses ?? []).map((c) => ({ ...c, reads: Number(c.reads), impressions: Number(c.impressions), completes: Number(c.completes), likes: Number(c.likes), readers: Number(c.readers), published_langs: Number(c.published_langs ?? 0) })),
    payouts: (d.payouts ?? []).map((p) => ({ ...p, amount: Number(p.amount), minutes: Number(p.minutes), readers: Number(p.readers), share: Number(p.share), pool_net: Number(p.pool_net) })),
  };
}

export async function listDrafts(supabase: SupabaseClient, userId?: string): Promise<DraftListRow[]> {
  let q = supabase.from("studio_drafts").select(DRAFT_LIST_COLUMNS).order("updated_at", { ascending: false });
  if (userId) q = q.eq("user_id", userId);
  const { data } = await q;
  return (data ?? []) as unknown as DraftListRow[];
}

export async function getDraft(supabase: SupabaseClient, id: string): Promise<DraftRow | null> {
  const { data } = await supabase.from("studio_drafts").select("*").eq("id", id).maybeSingle();
  return (data as DraftRow | null) ?? null;
}

export interface JobRow {
  id: string;
  course_id: string;
  origin_lang: string;
  status: "queued" | "dispatched" | "running" | "done" | "partial" | "failed";
  summary: Record<string, unknown>;
  error: string | null;
  options: Record<string, unknown>;
  created_at: string;
  dispatched_at: string | null;
  started_at: string | null;
  finished_at: string | null;
}

export interface StepRow {
  id: number;
  step: "translate" | "gate" | "quiz" | "glossary" | "cover" | "audio" | "publish";
  lang: string | null;
  status: "pending" | "running" | "done" | "failed" | "skipped";
  detail: Record<string, unknown>;
  started_at: string | null;
  finished_at: string | null;
}

export async function getJob(supabase: SupabaseClient, id: string): Promise<{ job: JobRow; steps: StepRow[] } | null> {
  const { data: job } = await supabase.from("production_jobs").select("id,course_id,origin_lang,status,summary,error,options,created_at,dispatched_at,started_at,finished_at").eq("id", id).maybeSingle();
  if (!job) return null;
  const { data: steps } = await supabase.from("production_steps").select("id,step,lang,status,detail,started_at,finished_at").eq("job_id", id).order("id");
  return { job: job as JobRow, steps: (steps ?? []) as StepRow[] };
}

export interface ReviewRow {
  id: number;
  draft_id: string;
  reviewer_id: string | null;
  decision: string;
  comment: string | null;
  created_at: string;
}

export async function listReviews(supabase: SupabaseClient, draftId: string): Promise<ReviewRow[]> {
  const { data } = await supabase.from("studio_reviews").select("*").eq("draft_id", draftId).order("created_at", { ascending: false });
  return (data ?? []) as ReviewRow[];
}

/** Une date courte, en anglais, sans heure. */
export function shortDate(iso: string | null | undefined): string {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
}

export function shortDateTime(iso: string | null | undefined): string {
  if (!iso) return "";
  return new Date(iso).toLocaleString("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });
}

export function pct(value: number | null | undefined, digits = 0): string {
  if (value == null) return "–";
  return `${(value * 100).toFixed(digits)}%`;
}

export function money(amount: number, currency: string): string {
  try {
    return new Intl.NumberFormat("en", { style: "currency", currency, maximumFractionDigits: 2 }).format(amount);
  } catch {
    return `${amount.toFixed(2)} ${currency}`;
  }
}
