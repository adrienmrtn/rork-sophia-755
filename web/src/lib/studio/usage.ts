/** Ce que renvoient les fonctions SQL admin_usage_dashboard et admin_feedback_dashboard
 *  (docs/events.md), et les calculs que les pages /admin/data/usage et /feedback font dessus. */

export interface UsageCounts {
  /** Utilisateurs distincts par jour, additionnés : quelqu'un d'actif trois jours compte trois fois. */
  user_days: number;
  course_opens: number;
  pages_read: number;
  completes: number;
  likes: number;
  quiz_answers: number;
  quiz_correct: number;
}

export interface UsageDashboard {
  days: number;
  from: string;
  min_answers: number;
  updated_at: string | null;
  languages: string[];
  totals: UsageCounts & { sessions: number; saves: number; shares: number };
  series: { day: string; active_users: number; course_opens: number; pages_read: number; duels: number }[];
  by_language: (UsageCounts & { lang: string })[];
  by_platform: (UsageCounts & { platform: string })[];
  top_courses: { course_id: string; title: string | null; opens: number; readers: number; pages_read: number; completes: number; likes: number }[];
  quiz: {
    questions_seen: number;
    questions_ranked: number;
    hardest: { question_id: string; course_id: string; answers: number; correct: number; rate: number; title: string | null; question: string | null }[];
  };
  duels: {
    by_kind: { kind: string; started: number; finished: number; abandoned: number; player_days: number }[];
    unknown_platform: number;
  };
}

export interface FeedbackItem {
  id: string;
  created_at: string;
  category: string;
  message: string;
  has_email: boolean;
  lang: string | null;
  platform: string;
  app_version: string | null;
  os_version: string | null;
  device: string | null;
  is_premium: boolean | null;
}

export interface FeedbackDashboard {
  days: number;
  total: number;
  languages: string[];
  by_category: { category: string; count: number }[];
  items: FeedbackItem[];
}

export interface SocialDashboard {
  days: number;
  from: string;
  friends: {
    requests: number;
    senders: number;
    accepted: number;
    declined: number;
    pending: number;
    new_friendships: number;
    total_friendships: number;
    users_with_friends: number;
    users_with_3_friends: number;
    series: { day: string; requests: number; friendships: number }[];
  };
  duel_invites: { sent: number; by_status: { status: string; count: number }[] };
  referrals: { new: number; inviters: number; total: number };
  follows: { new: number; followers: number; total: number; top_creators: { creator: string; name: string | null; new: number }[] };
}

export const DUEL_INVITE_STATUS_LABEL: Record<string, string> = {
  accepted: "Accepted",
  pending: "Waiting for an answer",
  declined: "Declined",
  expired: "Expired without an answer",
  cancelled: "Cancelled by the sender",
  busy: "Friend already in a duel",
};

/** Une part, ou null quand il n'y a rien à rapporter. */
export function ratio(part: number, whole: number): number | null {
  const w = Number(whole);
  return w ? Number(part) / w : null;
}

/** Une moyenne par jour sur la période, arrondie à l'entier. */
export function perDay(total: number, days: number): number {
  return days > 0 ? Math.round(Number(total) / days) : 0;
}

export const DUEL_KIND_LABEL: Record<string, string> = { match: "Against a drawn opponent", friend: "Between friends" };

export const FEEDBACK_CATEGORY_LABEL: Record<string, string> = {
  bug: "Bug",
  idea: "Idea",
  feature: "Feature request",
  content: "Content",
  translation: "Translation",
  other: "Other",
};

/** Le titre d'un cours, ou à défaut son identifiant rendu lisible (`course_42_pourquoi_reve_t_on`
 *  → « pourquoi reve t on »). */
export function courseName(row: { course_id: string; title: string | null }): string {
  if (row.title) return row.title;
  return row.course_id.replace(/^course_\d+_/, "").replace(/_/g, " ") || row.course_id;
}
