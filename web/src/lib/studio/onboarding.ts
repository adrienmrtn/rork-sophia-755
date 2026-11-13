/** Ce que renvoie la fonction SQL admin_onboarding_dashboard (docs/events.md), et la mise en
 *  ordre que la page /admin/data/onboarding fait dessus. */

export interface OnboardingStepRow {
  step: string;
  installs: number;
  ios: number;
  android: number;
}

export interface OnboardingQuestionRow {
  question: string;
  answered: number;
  options: { value: string; installs: number }[];
}

export interface OnboardingDashboard {
  days: number;
  from: string;
  updated_at: string | null;
  languages: string[];
  steps: OnboardingStepRow[];
  series: { day: string; installs: number }[];
  questions: OnboardingQuestionRow[];
}

/** Les écrans dans l'ordre du déroulé (`analyticsName` des deux apps). Android enchaîne ses
 *  deux paywalls dans un seul écran, `paywall`. */
export const STEP_ORDER = [
  "welcome", "language", "lessons", "researchers", "intro", "social_proof", "name", "age", "knowledge", "motivation",
  "objective", "topics", "objective_intro", "phone_time", "years_grid", "transform", "questions", "mission", "personalize",
  "swipe_courses", "reading_time", "curve_90", "notifications", "review", "loading", "profile", "login", "account",
  "follow_creators", "welcome_aboard", "features", "trial_steps", "reminder", "paywall_annual", "paywall_comparison", "paywall",
];

const STEP_LABEL: Record<string, string> = {
  welcome: "Welcome",
  language: "Language",
  lessons: "Lessons",
  researchers: "Researchers",
  intro: "Presentation carousel",
  social_proof: "Social proof",
  name: "First name",
  age: "Age",
  knowledge: "General knowledge",
  motivation: "Motivation",
  objective: "Objectives",
  topics: "Subjects",
  objective_intro: "“Sophia will help you”",
  phone_time: "Phone time",
  years_grid: "Life in years",
  transform: "“Turn that time”",
  questions: "Questions",
  mission: "Mission",
  personalize: "Personalize",
  swipe_courses: "Swipe courses",
  reading_time: "Reading time",
  curve_90: "90-day curve",
  notifications: "Notifications",
  review: "Reviews",
  loading: "Loading",
  profile: "Profile",
  login: "Login",
  account: "Account (avatar, handle)",
  follow_creators: "Follow creators",
  welcome_aboard: "Welcome aboard",
  features: "Strengths",
  trial_steps: "Trial timeline",
  reminder: "Reminder",
  paywall_annual: "Paywall (annual)",
  paywall_comparison: "Paywall (comparison)",
  paywall: "Paywall",
};

/** Les écrans qu'une partie des gens ne voit pas par construction : un creux à cet endroit
 *  n'est pas un abandon. */
const STEP_NOTE: Record<string, string> = {
  reading_time: "iOS only",
  account: "iOS only, new accounts",
  paywall_annual: "iOS only",
  paywall_comparison: "iOS only",
  paywall: "Android only",
  notifications: "Skipped when already decided",
  trial_steps: "Only when the offer has a trial",
  follow_creators: "Only when creators exist",
};

export interface FunnelStep extends OnboardingStepRow {
  label: string;
  note: string | null;
  /** Part des installations entrées dans l'onboarding qui ont vu cet écran. */
  share: number | null;
}

/** Les écrans dans l'ordre du déroulé, rapportés au premier (l'accueil). Un écran inconnu
 *  de la liste (ajouté dans une app avant d'être ajouté ici) passe à la fin. */
export function funnel(rows: OnboardingStepRow[]): FunnelStep[] {
  const rank = (step: string) => {
    const index = STEP_ORDER.indexOf(step);
    return index === -1 ? STEP_ORDER.length : index;
  };
  const ordered = [...rows].sort((a, b) => rank(a.step) - rank(b.step) || a.step.localeCompare(b.step));
  const start = Math.max(0, ...ordered.map((r) => Number(r.installs)));
  return ordered.map((r) => ({
    ...r,
    installs: Number(r.installs),
    label: STEP_LABEL[r.step] ?? r.step,
    note: STEP_NOTE[r.step] ?? null,
    share: start ? Number(r.installs) / start : null,
  }));
}

const QUESTION_ORDER = ["age", "knowledge", "motivation", "objectives", "topics", "phone_time", "reading_time", "reads_monthly", "forgets_reading", "too_much_phone", "likes_learning_daily"];

const QUESTION_LABEL: Record<string, string> = {
  age: "Age",
  knowledge: "General knowledge, self-rated",
  motivation: "Why they want to progress",
  objectives: "Objectives (several possible)",
  topics: "Subjects (several possible)",
  phone_time: "Daily phone time",
  reading_time: "Preferred reading hour (iOS)",
  reads_monthly: "“I read at least once a month” (iOS)",
  forgets_reading: "“I forget what I read” (iOS)",
  too_much_phone: "“I spend too much time on my phone” (iOS)",
  likes_learning_daily: "“I like learning something every day” (iOS)",
};

const OPTION_LABEL: Record<string, Record<string, string>> = {
  age: { under18: "Under 18", "18to24": "18–24", "25to34": "25–34", "35to44": "35–44", "45to54": "45–54", "55plus": "55 and over" },
  knowledge: { "0": "Not great", "1": "Decent", "2": "Good", "3": "Very good" },
  motivation: { grow: "To grow as a person", conversations: "To shine in conversations", career: "Studies or career", sharp: "To keep a sharp mind", world: "To understand the world better" },
  objectives: { cultivate: "Get cultured every day", reduceScreen: "Reduce screen time", exams: "Studies and exams", impress: "Impress in company", curiosity: "Learn out of curiosity" },
};

const AGE_ORDER = ["under18", "18to24", "25to34", "35to44", "45to54", "55plus"];
/** Les questions dont les réponses ont un ordre naturel, à garder à l'affichage. */
const NUMERIC_QUESTIONS = new Set(["knowledge", "phone_time", "reading_time"]);
const BOOLEAN_LABEL: Record<string, string> = { true: "Yes", false: "No" };

function optionLabel(question: string, value: string): string {
  const known = OPTION_LABEL[question]?.[value];
  if (known) return known;
  if (question === "phone_time" && /^\d+$/.test(value)) {
    const minutes = Number(value);
    const hours = Math.floor(minutes / 60);
    const rest = minutes % 60;
    return hours ? `${hours} h${rest ? ` ${rest}` : ""}` : `${rest} min`;
  }
  if (question === "reading_time" && /^\d+$/.test(value)) return `${value.padStart(2, "0")}:00`;
  return BOOLEAN_LABEL[value] ?? value;
}

export interface QuestionView {
  question: string;
  label: string;
  answered: number;
  options: { value: string; label: string; installs: number; share: number | null }[];
}

/** Les questions dans l'ordre du déroulé, leurs réponses en clair et en part des installations
 *  qui ont répondu. Dans une question à choix multiples, les parts dépassent 100 % au total. */
export function questionViews(rows: OnboardingQuestionRow[]): QuestionView[] {
  const rank = (question: string) => {
    const index = QUESTION_ORDER.indexOf(question);
    return index === -1 ? QUESTION_ORDER.length : index;
  };
  return [...rows]
    .sort((a, b) => rank(a.question) - rank(b.question) || a.question.localeCompare(b.question))
    .map((row) => {
      const answered = Number(row.answered);
      const options = row.options.map((o) => ({ value: o.value, label: optionLabel(row.question, o.value), installs: Number(o.installs), share: answered ? Number(o.installs) / answered : null }));
      if (row.question === "age") options.sort((a, b) => AGE_ORDER.indexOf(a.value) - AGE_ORDER.indexOf(b.value));
      else if (NUMERIC_QUESTIONS.has(row.question)) options.sort((a, b) => Number(a.value) - Number(b.value));
      else options.sort((a, b) => b.installs - a.installs || a.value.localeCompare(b.value));
      return { question: row.question, label: QUESTION_LABEL[row.question] ?? row.question, answered, options };
    });
}
