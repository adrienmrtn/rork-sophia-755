import "server-only";
import type { SupabaseClient, User } from "@supabase/supabase-js";
import type { CreatorAccount, StudioSession } from "@/lib/studio/account";

/** Une session factice pour regarder le Studio hors ligne (captures, maquettage).
 *  Activée seulement par SOPHIA_MOCK_STUDIO=new|onboarding|author en développement ;
 *  jamais définie en production. Le faux client Supabase répond des données plausibles. */

export const MOCK_STUDIO = process.env.NODE_ENV !== "production" || process.env.SOPHIA_DATA === "starter" ? process.env.SOPHIA_MOCK_STUDIO ?? null : null;

const USER_ID = "00000000-0000-4000-8000-000000000001";
const DRAFT_IDS = ["11111111-1111-4111-8111-111111111111", "22222222-2222-4222-8222-222222222222", "33333333-3333-4333-8333-333333333333"];
const JOB_ID = "44444444-4444-4444-8444-444444444444";

const account: CreatorAccount = {
  user_id: USER_ID,
  slug: "marie-dupont",
  status: "approved",
  first_name: "Marie",
  last_name: "Dupont",
  display_name: "Marie Dupont",
  email: "marie.dupont@example.org",
  writing_lang: "fr",
  title: "Senior lecturer in contemporary history, Université Lumière Lyon 2",
  institution: "Université Lumière Lyon 2",
  country: "FR",
  links: { website: "https://example.org" },
  bio: "Historian of the First World War, she works on everyday life in the trenches and the spontaneous truces of 1914.",
  long_bio: null,
  education: [],
  photo_path: null,
  onboarding_step: "done",
  guide_read_at: "2026-11-02T10:00:00Z",
  approved_at: "2026-11-03T09:00:00Z",
  suspended_reason: null,
  created_at: "2026-11-01T09:00:00Z",
};

const paragraph = (text: string) => ({ type: "paragraph", text });
const drafts = [
  {
    id: DRAFT_IDS[0],
    user_id: USER_ID,
    app_course_id: null,
    origin_lang: "fr",
    title: "Why did soldiers stop fighting on Christmas 1914?",
    subtitle: "December 1914",
    subject: "histoire",
    subcategory: "First World War",
    description: "On the first Christmas of the war, thousands of soldiers left their trenches to meet the enemy. Here is how it happened, and why it never happened again.",
    hero: { image_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Christmas_Truce_1914_IWM_HU_35801.jpg/1600px-Christmas_Truce_1914_IWM_HU_35801.jpg", ratio: "16:9", credit: { title: "Christmas Truce 1914", author: "Imperial War Museum", license: "Public domain", source: "Wikimedia Commons" } },
    sections: [
      { title: "Introduction", free: true, blocks: [paragraph("In December 1914, the war was five months old and already stuck in the mud of [[Flanders]]. Nobody expected what happened on the night of the 24th."), paragraph("Along several kilometres of the front, **German** and **British** soldiers sang, then climbed out of their trenches.")] },
      { title: "What the soldiers did", free: false, blocks: [paragraph("They exchanged cigarettes, buttons and addresses. Some buried their dead together. A football match is reported in at least one sector."), { type: "funFact", text: "The truce was never ordered. It started with carols and candles on small Christmas trees sent to German units." }] },
      { title: "Why it never happened again", free: false, blocks: [paragraph("The high commands on both sides were alarmed. Orders followed, artillery barrages were scheduled for the following Christmas, and units were rotated."), { type: "takeaway", text: "A truce can start from the bottom; keeping it needs the top, and the top refused." }] },
    ],
    sources: [{ text: "Malcolm Brown and Shirley Seaton, Christmas Truce, 1984" }],
    glossary: [{ term: "Flanders", classification: "lieuInstitution", explanation: "A region straddling Belgium and northern France where the Western Front settled in late 1914." }],
    quiz: null,
    status: "draft",
    review_comment: null,
    precheck: null,
    submitted_at: null,
    accepted_at: null,
    published_at: null,
    version: 1,
    last_job_id: null,
    created_at: "2026-11-07T10:00:00Z",
    updated_at: "2026-11-09T09:12:00Z",
  },
  {
    id: DRAFT_IDS[1],
    user_id: USER_ID,
    app_course_id: null,
    origin_lang: "fr",
    title: "How did Verdun become the symbol of the Great War?",
    subtitle: "1916",
    subject: "histoire",
    subcategory: "First World War",
    description: "Ten months, three hundred days, and a hill that changed hands sixteen times. Why this battle, of all battles, became France's memory of the war.",
    hero: { ratio: "16:9" },
    sections: [
      { title: "Introduction", free: true, blocks: [paragraph("In February 1916 the German army attacked a fortress city everyone thought secondary.")] },
      { title: "The grinding mill", free: false, blocks: [paragraph("The battle was designed to bleed the French army white."), { type: "takeaway", text: "Verdun was a battle about symbols as much as ground." }] },
    ],
    sources: [],
    glossary: [],
    quiz: null,
    status: "submitted",
    review_comment: null,
    precheck: null,
    submitted_at: "2026-11-08T17:30:00Z",
    accepted_at: null,
    published_at: null,
    version: 1,
    last_job_id: null,
    created_at: "2026-11-05T10:00:00Z",
    updated_at: "2026-11-08T17:30:00Z",
  },
  {
    id: DRAFT_IDS[2],
    user_id: USER_ID,
    app_course_id: "course_311_qu_est_ce_que_la_grippe_espagnole",
    origin_lang: "fr",
    title: "Where did the Spanish flu really come from?",
    subtitle: "1918",
    subject: "histoire",
    subcategory: "First World War",
    description: "It killed more people than the war itself, and it did not come from Spain. The story of a name, a virus and a silence.",
    hero: { ratio: "16:9" },
    sections: [{ title: "Introduction", free: true, blocks: [paragraph("Spain was neutral, so its newspapers were free to report the epidemic.")] }, { title: "Kansas, 1918", free: false, blocks: [paragraph("The first documented cases appeared in a military camp."), { type: "takeaway", text: "Names travel faster than facts." }] }],
    sources: [],
    glossary: [],
    quiz: null,
    status: "published",
    review_comment: null,
    precheck: null,
    submitted_at: "2026-11-02T09:00:00Z",
    accepted_at: "2026-11-03T11:00:00Z",
    published_at: "2026-11-03T13:40:00Z",
    version: 1,
    last_job_id: JOB_ID,
    created_at: "2026-10-30T10:00:00Z",
    updated_at: "2026-11-03T13:40:00Z",
  },
];

const LANGS = ["fr", "en", "es", "de", "pt", "pt-PT", "it", "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs", "da", "nb", "ru", "hr", "sl", "sk", "sr", "ar", "he", "fi", "et", "lt", "lv", "ja"];
const job = { id: JOB_ID, course_id: drafts[2].app_course_id, origin_lang: "fr", status: "partial", summary: { published: LANGS.filter((l) => l !== "he"), failed: { he: ["terminology: 2 findings"] } }, error: null, options: { languages: LANGS.filter((l) => l !== "fr"), skip_audio: true, is_new: true }, created_at: "2026-11-03T11:02:00Z", dispatched_at: "2026-11-03T11:05:00Z", started_at: "2026-11-03T11:06:00Z", finished_at: "2026-11-03T13:40:00Z" };
let stepId = 0;
const steps = [
  { id: ++stepId, step: "quiz", lang: null, status: "done", detail: { questions: 8 }, started_at: job.started_at, finished_at: job.started_at },
  { id: ++stepId, step: "glossary", lang: null, status: "done", detail: {}, started_at: job.started_at, finished_at: job.started_at },
  { id: ++stepId, step: "cover", lang: null, status: "done", detail: {}, started_at: job.started_at, finished_at: job.started_at },
  ...LANGS.filter((l) => l !== "fr").flatMap((lang) => [
    { id: ++stepId, step: "translate", lang, status: "done", detail: {}, started_at: job.started_at, finished_at: job.finished_at },
    { id: ++stepId, step: "gate", lang, status: lang === "he" ? "failed" : "done", detail: lang === "he" ? { findings: ["term", "term"] } : {}, started_at: job.started_at, finished_at: job.finished_at },
  ]),
  { id: ++stepId, step: "audio", lang: "fr", status: "skipped", detail: {}, started_at: null, finished_at: null },
  { id: ++stepId, step: "audio", lang: "en", status: "skipped", detail: {}, started_at: null, finished_at: null },
  { id: ++stepId, step: "publish", lang: null, status: "done", detail: {}, started_at: job.finished_at, finished_at: job.finished_at },
];

const reviews = [
  { id: 4, draft_id: DRAFT_IDS[2], reviewer_id: null, decision: "published", comment: `Job ${JOB_ID} : partial`, created_at: "2026-11-03T13:40:00Z" },
  { id: 3, draft_id: DRAFT_IDS[2], reviewer_id: "team", decision: "note", comment: `Production launched · job ${JOB_ID}`, created_at: "2026-11-03T11:02:00Z" },
  { id: 2, draft_id: DRAFT_IDS[2], reviewer_id: "team", decision: "accepted", comment: "Clear and well sourced. Thank you!", created_at: "2026-11-03T11:00:00Z" },
  { id: 1, draft_id: DRAFT_IDS[2], reviewer_id: USER_ID, decision: "submitted", comment: null, created_at: "2026-11-02T09:00:00Z" },
  { id: 5, draft_id: DRAFT_IDS[1], reviewer_id: USER_ID, decision: "submitted", comment: null, created_at: "2026-11-08T17:30:00Z" },
];

function series(days: number) {
  const out: { day: string; reads: number }[] = [];
  const today = new Date("2026-11-09T00:00:00Z");
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(today.getTime() - i * 86400000);
    const base = 140 + Math.round(60 * Math.sin(i / 3)) + ((i * 37) % 50);
    out.push({ day: d.toISOString().slice(0, 10), reads: base });
  }
  return out;
}

function dashboard(days: number) {
  const s = series(days);
  const reads = s.reduce((n, p) => n + p.reads, 0);
  return {
    slug: account.slug,
    days,
    reads,
    reads_prev: Math.round(reads * 0.84),
    impressions: reads * 7,
    completes: Math.round(reads * 0.61),
    likes: Math.round(reads * 0.12),
    per_1000: 87.4,
    subject_per_1000: { histoire: 71.2 },
    followers_gained: 41,
    languages_read: 14,
    series: s,
    courses: [
      { id: drafts[2].app_course_id, subject: "histoire", status: "published", published_at: "2026-11-03T13:40:00Z", title: drafts[2].title, impressions: reads * 4, reads: Math.round(reads * 0.6), completes: Math.round(reads * 0.4), likes: 230, readers: Math.round(reads * 0.5), per_1000: 92.1, completion: 0.66, quiz_score: 0.78, languages: [{ lang: "fr", reads: 900 }, { lang: "en", reads: 640 }, { lang: "es", reads: 210 }], published_langs: 29 },
      { id: "course_298_l_armistice_de_1918", subject: "histoire", status: "published", published_at: "2026-10-20T10:00:00Z", title: "Why did the war end at eleven o'clock?", impressions: reads * 3, reads: Math.round(reads * 0.4), completes: Math.round(reads * 0.21), likes: 120, readers: Math.round(reads * 0.3), per_1000: 80.3, completion: 0.53, quiz_score: 0.71, languages: [{ lang: "fr", reads: 500 }, { lang: "en", reads: 300 }], published_langs: 30 },
    ],
    payouts: [
      { month: "2026-11", current: true, minutes: 1284, readers: 63, share: 0.0412, pool_net: 906.36, pool_share: 0.3, currency: "USD", amount: 11.2 },
      { month: "2026-10", current: false, minutes: 4210, readers: 188, share: 0.0598, pool_net: 1240.1, pool_share: 0.3, currency: "USD", amount: 22.25 },
      { month: "2026-09", current: false, minutes: 2980, readers: 141, share: 0.0455, pool_net: 1180.4, pool_share: 0.3, currency: "USD", amount: 16.11 },
    ],
  };
}

const guideMd = `# Writing a Sophia course\n\n## One question, one answer\n\nA Sophia course answers a question a curious reader could ask. The title is that question.\n\n## 500 to 900 words, in two to twelve sections\n\nThe first section is free: it must make the reader want the rest. Short sentences, one idea each.\n\n## What the app adds\n\nA quiz, a glossary, translations into 29 languages. You write the text; Sophia produces the rest.`;
const agreementMd = `# Creator agreement\n\n## 1. The parties\n\nThis agreement is between Sophia and the Author.\n\n## 2. Purpose\n\nThe Author writes courses; Sophia reviews, translates and publishes them in the app.\n\n## 3. What the Author provides\n\nOriginal texts, sources, images under free licences.`;

type Op = { m: string; a: unknown[] };

function has(ops: Op[], m: string) {
  return ops.some((o) => o.m === m);
}
function eqArg(ops: Op[], col: string): unknown {
  return ops.find((o) => o.m === "eq" && o.a[0] === col)?.a[1];
}

/** Un événement de démonstration pour l'admin hors ligne (docs/evenements.md). */
const mockCampaign = {
  slug: "movember-2026",
  kind: "month",
  status: "published",
  symbol: "mustache.fill",
  image_url: null,
  starts_at: "2026-11-01",
  ends_at: "2026-11-30",
  challenge_target: 3,
  participants: 8412,
  goal_target: 10000,
  goal_count: 6230,
  course_ids: ["course_101_1984_george_orwell", "course_107_crime_et_chatiment_dostoievski", "course_116_la_metamorphose_kafka"],
  upcoming: [{ title: { en: "Why do men see a doctor less often?", fr: "Pourquoi les hommes vont-ils moins chez le médecin ?" }, creator: "dusan-nikolic", date: "2026-11-14" }],
  title: { en: "Movember", fr: "Movember" },
  tagline: { en: "Men's health, let's talk about it.", fr: "La santé des hommes, on en parle." },
  description: { en: "Mental health, prevention, male cancers: a month to talk about it, one course at a time.", fr: "Santé mentale, prévention, cancers masculins : un mois pour en parler, un cours à la fois." },
  badge_name: { en: "Moustache", fr: "Moustache" },
  created_at: "2026-11-01T09:00:00Z",
  updated_at: "2026-11-08T17:30:00Z",
};

function resolve(kind: "from" | "rpc", name: string, args: unknown[], ops: Op[]): { data: unknown; error: null } {
  const single = has(ops, "maybeSingle") || has(ops, "single");
  const list = (rows: unknown[]) => ({ data: single ? (rows[0] ?? null) : rows, error: null });
  if (kind === "rpc") {
    const p = (args[0] ?? {}) as Record<string, unknown>;
    switch (name) {
      case "creator_dashboard":
        return { data: dashboard(Number(p.p_days ?? 28)), error: null };
      case "creator_course_detail":
        return { data: { course_id: p.p_course_id, days: Number(p.p_days ?? 28), stats: [{ course_id: p.p_course_id, lang: "fr", impressions: 12840, opens: 1930, completes: 1210, completes_per_1000_impressions: 94.2, likes: 310, saves: 88, shares: 12, readers: 1702, followers_gained: 41, sections: [0, 1, 2, 3].map((i) => ({ index: i, viewers: Math.round(1930 * (1 - i * 0.14)), reach: Math.round(1000 * (1 - i * 0.14)) / 1000 })) }], languages: [{ lang: "fr", reads: 900, completes: 610 }, { lang: "en", reads: 640, completes: 400 }, { lang: "es", reads: 210, completes: 120 }], quiz: { answers: 2100, correct: 1640 }, sections: null }, error: null };
      case "studio_document_version":
        return { data: 1, error: null };
      default:
        return { data: null, error: null };
    }
  }
  switch (name) {
    case "studio_drafts": {
      const id = eqArg(ops, "id");
      const jobId = eqArg(ops, "last_job_id");
      let rows: typeof drafts = drafts;
      if (id) rows = drafts.filter((d) => d.id === id);
      if (jobId) rows = drafts.filter((d) => d.last_job_id === jobId);
      if (has(ops, "not")) rows = rows.filter((d) => d.last_job_id);
      return list(rows);
    }
    case "studio_documents": {
      const slug = eqArg(ops, "slug");
      return list([{ version: 1, title: slug === "writing-guide" ? "Writing a Sophia course" : "Creator agreement", body_md: slug === "writing-guide" ? guideMd : agreementMd }]);
    }
    case "creator_agreements":
      return list(MOCK_STUDIO === "author" ? [{ user_id: USER_ID, version: 1, signed_at: "2026-11-02T10:00:00Z" }] : []);
    case "studio_reviews": {
      const draftId = eqArg(ops, "draft_id");
      return list(reviews.filter((r) => !draftId || r.draft_id === draftId));
    }
    case "production_jobs":
      return list([job]);
    case "production_steps":
      return list(steps);
    case "creator_accounts":
      return list([account]);
    case "campaigns": {
      const slug = eqArg(ops, "slug");
      const rows = [mockCampaign].filter((c) => !slug || c.slug === slug);
      return list(rows);
    }
    case "courses":
      return list([{ id: drafts[2].app_course_id, subject: "histoire", status: "published", origin_lang: "fr", published_at: "2026-11-03T13:40:00Z", course_contents: [{ lang: "fr", title: drafts[2].title, status: "published", content: { sections: drafts[2].sections.map((s) => ({ title: s.title })) } }, { lang: "en", title: drafts[2].title, status: "published", content: null }] }]);
    default:
      return list([]);
  }
}

function chain(kind: "from" | "rpc", name: string, args: unknown[]) {
  const ops: Op[] = [];
  const target = () => undefined;
  const proxy: unknown = new Proxy(target, {
    get(_t, prop) {
      if (prop === "then") return (res: (v: unknown) => unknown, rej: (e: unknown) => unknown) => Promise.resolve(resolve(kind, name, args, ops)).then(res, rej);
      return (...a: unknown[]) => {
        ops.push({ m: String(prop), a });
        return proxy;
      };
    },
  });
  return proxy;
}

function mockClient(): SupabaseClient {
  return {
    from: (table: string) => chain("from", table, []),
    rpc: (fn: string, params?: unknown) => chain("rpc", fn, [params]),
    storage: { from: () => ({ createSignedUrl: async () => ({ data: { signedUrl: null }, error: null }), upload: async () => ({ data: null, error: null }), download: async () => ({ data: null, error: null }) }) },
    auth: { signOut: async () => ({ error: null }) },
  } as unknown as SupabaseClient;
}

export function mockSession(): StudioSession | null {
  if (!MOCK_STUDIO) return null;
  const user = { id: USER_ID, email: account.email, user_metadata: { full_name: "Marie Dupont" }, app_metadata: {}, aud: "authenticated", created_at: "" } as unknown as User;
  const supabase = mockClient();
  if (MOCK_STUDIO === "new") return { supabase, user, account: null, isAdmin: false, agreementSigned: false, publicPage: false };
  if (MOCK_STUDIO === "onboarding") return { supabase, user, account: { ...account, status: "pending", onboarding_step: "profile", display_name: null, title: null, bio: null, approved_at: null, guide_read_at: null }, isAdmin: false, agreementSigned: false, publicPage: false };
  return { supabase, user, account, isAdmin: true, agreementSigned: true, publicPage: true };
}

export const MOCK_DRAFT_IDS = DRAFT_IDS;
