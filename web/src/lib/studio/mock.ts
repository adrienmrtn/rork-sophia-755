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
  weekly_quota: null,
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
    pitch: "The Christmas truce of 1914, told from the trenches: who started it, what the soldiers did, and why the high commands made sure it never happened again.",
    proposal_note: null,
    proposed_at: "2026-11-01T10:00:00Z",
    proposal_decided_at: "2026-11-01T15:00:00Z",
    validated_at: null,
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
    pitch: "",
    proposal_note: null,
    proposed_at: "2026-11-02T10:00:00Z",
    proposal_decided_at: "2026-11-02T12:00:00Z",
    validated_at: null,
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
    pitch: "",
    proposal_note: null,
    proposed_at: "2026-10-28T10:00:00Z",
    proposal_decided_at: "2026-10-28T12:00:00Z",
    validated_at: "2026-11-03T11:00:00Z",
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
drafts.push({
  id: "55555555-5555-4555-8555-555555555555",
  user_id: USER_ID,
  app_course_id: null,
  origin_lang: "fr",
  title: "Why did Europe fear the potato for two centuries?",
  subtitle: null,
  subject: "histoire",
  subcategory: null,
  description: "",
  hero: { ratio: "16:9" },
  sections: [],
  sources: [],
  glossary: [],
  quiz: null,
  status: "proposed",
  pitch: "From the Andes to Parmentier's fields at Neuilly: how a tuber suspected of leprosy became the food that fed the industrial revolution, and what the Irish famine owes to a single variety.",
  proposal_note: null,
  proposed_at: "2026-11-08T09:30:00Z",
  proposal_decided_at: null,
  validated_at: null,
  review_comment: null,
  precheck: null,
  submitted_at: null,
  accepted_at: null,
  published_at: null,
  version: 1,
  last_job_id: null,
  created_at: "2026-11-08T09:30:00Z",
  updated_at: "2026-11-08T09:30:00Z",
} as unknown as (typeof drafts)[number]);

const mockQuota = { limit: 1, used: 1, open: 2, can_propose: false, can_validate: false, first_week: false, period_start: "2026-11-02T23:00:00Z", period_end: "2026-11-09T23:00:00Z", next_slot_at: "2026-11-09T23:00:00Z", blocked: false, custom: false, fee_cents: 1500, currency: "USD" };

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
    fee_cents: 1500,
    currency: "USD",
    pot_cents: 1500,
    paid_cents: 3000,
    credits: [
      { id: 3, draft_id: DRAFT_IDS[2], title: drafts[2].title, amount_cents: 1500, created_at: "2026-11-03T11:00:00Z", paid_at: null },
      { id: 2, draft_id: null, title: "Why did the war end at eleven o'clock?", amount_cents: 1500, created_at: "2026-10-20T10:00:00Z", paid_at: "2026-10-26T09:00:00Z" },
      { id: 1, draft_id: null, title: "Who were the Vikings, really?", amount_cents: 1500, created_at: "2026-10-14T10:00:00Z", paid_at: "2026-10-19T09:00:00Z" },
    ],
    payouts: [
      { id: 2, amount_cents: 1500, credits_count: 1, paid_at: "2026-10-26T09:00:00Z" },
      { id: 1, amount_cents: 1500, credits_count: 1, paid_at: "2026-10-19T09:00:00Z" },
    ],
    quota: mockQuota,
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
  image_candidates: [],
  badge_image_url: null,
  badge_candidates: [],
  countries: null,
  starts_at: "2026-11-01",
  ends_at: "2026-11-30",
  challenge_target: 3,
  participants: 8412,
  goal_target: 10000,
  goal_count: 6230,
  course_ids: ["course_101_1984_george_orwell", "course_107_crime_et_chatiment_dostoievski", "course_116_la_metamorphose_kafka"],
  title: { en: "Movember", fr: "Movember" },
  tagline: { en: "Men's health, let's talk about it.", fr: "La santé des hommes, on en parle." },
  description: { en: "Mental health, prevention, male cancers: a month to talk about it, one course at a time.", fr: "Santé mentale, prévention, cancers masculins : un mois pour en parler, un cours à la fois." },
  badge_name: { en: "Moustache", fr: "Moustache" },
  created_at: "2026-11-01T09:00:00Z",
  updated_at: "2026-11-08T17:30:00Z",
};

/** Des amis et des invitations plausibles, pour regarder /admin/data/social hors ligne. */
function socialDashboard(days: number) {
  const today = Date.UTC(2026, 10, 13);
  const day = (i: number) => new Date(today - (days - 1 - i) * 86_400_000).toISOString().slice(0, 10);
  const series = Array.from({ length: days }, (_, i) => ({ day: day(i), requests: Math.round(620 * (0.8 + 0.4 * Math.abs(Math.sin(i * 0.9)))), friendships: Math.round(410 * (0.8 + 0.4 * Math.abs(Math.sin(i * 0.9)))) }));
  const requests = series.reduce((t, p) => t + p.requests, 0);
  const invites = Math.round(requests * 0.9);
  return {
    days,
    from: day(0),
    friends: { requests, senders: Math.round(requests * 0.62), accepted: Math.round(requests * 0.66), declined: Math.round(requests * 0.03), pending: Math.round(requests * 0.31), new_friendships: Math.round(requests * 0.66), total_friendships: 48200, users_with_friends: 61400, users_with_3_friends: 9300, series },
    duel_invites: { sent: invites, by_status: [["accepted", 0.58], ["expired", 0.17], ["cancelled", 0.12], ["busy", 0.08], ["declined", 0.05]].map(([status, share]) => ({ status, count: Math.round(invites * Number(share)) })) },
    referrals: { new: Math.round(requests * 0.11), inviters: Math.round(requests * 0.08), total: 5400 },
    follows: { new: Math.round(requests * 1.4), followers: Math.round(requests * 0.5), total: 88000, top_creators: [["marie-dupont", "Marie Dupont", 0.21], ["simon-lea", "Simon Lea", 0.17], ["rana-abdalla", "Rana Abdalla", 0.14], ["kate-waddams", "Kate Waddams", 0.11]].map(([creator, name, share]) => ({ creator, name, new: Math.round(requests * 1.4 * Number(share)) })) },
  };
}

/** Un usage plausible, pour regarder /admin/data/usage hors ligne. */
function usageDashboard(days: number) {
  const today = Date.UTC(2026, 10, 13);
  const day = (i: number) => new Date(today - (days - 1 - i) * 86_400_000).toISOString().slice(0, 10);
  const wave = (i: number, base: number) => Math.round(base * (0.8 + 0.4 * Math.abs(Math.sin(i * 0.9))));
  const series = Array.from({ length: days }, (_, i) => ({ day: day(i), active_users: wave(i, 18500), course_opens: wave(i, 31000), pages_read: wave(i, 96000), duels: wave(i, 7400) }));
  const sum = (key: "active_users" | "course_opens" | "pages_read" | "duels") => series.reduce((t, p) => t + p[key], 0);
  const counts = (share: number, correct: number) => ({ user_days: Math.round(sum("active_users") * share), course_opens: Math.round(sum("course_opens") * share), pages_read: Math.round(sum("pages_read") * share), completes: Math.round(sum("course_opens") * share * 0.41), likes: Math.round(sum("course_opens") * share * 0.07), quiz_answers: Math.round(sum("course_opens") * share * 1.8), quiz_correct: Math.round(sum("course_opens") * share * 1.8 * correct) });
  const all = counts(1, 0.68);
  const courses: [string, string, number, number][] = [
    ["course_42_pourquoi_reve_t_on", "Pourquoi rêve-t-on ?", 0.031, 0.52], ["course_1_la_naissance_de_l_islam_622", "Comment l'islam est-il né en 622 ?", 0.027, 0.44],
    ["course_150_la_nuit_etoilee_van_gogh", "Pourquoi le ciel de « La Nuit étoilée » tourbillonne-t-il ?", 0.024, 0.49], ["course_121_la_renaissance_italienne", "Pourquoi la Renaissance est-elle née en Italie ?", 0.021, 0.38],
    ["course_77_qu_est_ce_qu_un_trou_noir", "Qu'est-ce qu'un trou noir ?", 0.019, 0.46], ["course_12_la_peste_noire_en_europe", "Comment la peste noire a-t-elle changé l'Europe ?", 0.017, 0.41],
    ["course_203_le_mythe_de_sisyphe_camus", "Pourquoi faut-il imaginer Sisyphe heureux ?", 0.014, 0.33], ["course_88_la_joconde", "Pourquoi la Joconde est-elle si célèbre ?", 0.013, 0.47],
  ];
  const questions: [string, string, string, number, number][] = [
    ["course_122_la_naissance_de_l_impressionnisme_q2", "Comment l'impressionnisme est-il né contre le Salon ?", "Quel tableau de Manet scandalise le Salon des Refusés en 1863 ?", 1840, 0.21],
    ["course_12_la_peste_noire_en_europe_q4", "Comment la peste noire a-t-elle changé l'Europe ?", "Quelle part de la population européenne meurt entre 1347 et 1352 ?", 2610, 0.27],
    ["course_77_qu_est_ce_qu_un_trou_noir_q3", "Qu'est-ce qu'un trou noir ?", "Comment appelle-t-on la limite au-delà de laquelle rien ne s'échappe ?", 3120, 0.31],
    ["course_203_le_mythe_de_sisyphe_camus_q1", "Pourquoi faut-il imaginer Sisyphe heureux ?", "Vrai ou faux : pour Camus, l'absurde conduit au renoncement.", 1490, 0.34],
    ["course_1_la_naissance_de_l_islam_622_q5", "Comment l'islam est-il né en 622 ?", "Dans quelle ville Muhammad s'installe-t-il après l'Hégire ?", 4050, 0.38],
  ];
  return {
    days,
    from: day(0),
    min_answers: 20,
    updated_at: "2026-11-13T09:45:00Z",
    languages: ["de", "en", "es", "fr", "it", "pt"],
    totals: { ...all, sessions: Math.round(all.user_days * 1.7), saves: Math.round(all.likes * 0.6), shares: Math.round(all.likes * 0.2) },
    series,
    by_language: [["fr", 0.54, 0.7], ["en", 0.21, 0.66], ["es", 0.12, 0.65], ["de", 0.07, 0.69], ["it", 0.04, 0.64], ["pt", 0.02, 0.62]].map(([lang, share, correct]) => ({ lang, ...counts(Number(share), Number(correct)) })),
    by_platform: [{ platform: "android", ...counts(0.24, 0.66) }, { platform: "ios", ...counts(0.76, 0.69) }],
    top_courses: courses.map(([course_id, title, share, finished]) => { const opens = Math.round(all.course_opens * share); return { course_id, title, opens, readers: Math.round(opens * 0.86), pages_read: Math.round(opens * 3.4), completes: Math.round(opens * finished), likes: Math.round(opens * 0.08) }; }),
    quiz: { questions_seen: 2140, questions_ranked: 1675, hardest: questions.map(([question_id, title, question, answers, rate]) => ({ question_id, course_id: question_id.replace(/_q\d+$/, ""), answers: Math.round(answers * (days / 28)), correct: Math.round(answers * (days / 28) * rate), rate, title, question })) },
    duels: { by_kind: [{ kind: "friend", started: Math.round(sum("duels") * 0.18), finished: Math.round(sum("duels") * 0.15), abandoned: Math.round(sum("duels") * 0.03), player_days: Math.round(sum("duels") * 0.09) }, { kind: "match", started: Math.round(sum("duels") * 0.82), finished: Math.round(sum("duels") * 0.61), abandoned: Math.round(sum("duels") * 0.21), player_days: Math.round(sum("duels") * 0.3) }], unknown_platform: 0 },
  };
}

/** Des retours plausibles, pour regarder /admin/data/feedback hors ligne. */
function feedbackDashboard(days: number) {
  const item = (id: number, created_at: string, category: string, message: string, platform: string, lang: string, extra: Partial<{ has_email: boolean; is_premium: boolean }> = {}) => ({ id: `f${id}`, created_at, category, message, has_email: false, lang, platform, app_version: platform === "ios" ? "2" : "1.0.7", os_version: platform === "ios" ? "27.2" : "15", device: platform === "ios" ? "iPhone" : "Pixel 8", is_premium: false, ...extra });
  const items = [
    item(1, "2026-11-13T08:12:00Z", "bug", "Le son de la narration se coupe quand je verrouille l'écran, il faut relancer le cours.", "ios", "fr", { has_email: true, is_premium: true }),
    item(2, "2026-11-13T07:40:00Z", "feature", "Would love a dark mode for reading at night.", "android", "en"),
    item(3, "2026-11-12T21:05:00Z", "translation", "En el curso sobre Van Gogh, «remolino» aparece dos veces mal escrito.", "ios", "es"),
    item(4, "2026-11-12T18:30:00Z", "content", "Un cours sur l'histoire du Japon serait génial !\nMerci pour l'app, je l'utilise tous les matins.", "ios", "fr", { is_premium: true }),
    item(5, "2026-11-12T09:02:00Z", "idea", "Pouvoir défier un ami sur un cours précis.", "android", "fr", { has_email: true }),
  ];
  return { days, total: 128, languages: ["en", "es", "fr"], by_category: [{ category: "bug", count: 41 }, { category: "feature", count: 33 }, { category: "content", count: 24 }, { category: "idea", count: 16 }, { category: "translation", count: 9 }, { category: "other", count: 5 }], items };
}

/** Un onboarding plausible, pour regarder /admin/data/onboarding hors ligne. */
function onboardingDashboard(days: number) {
  const today = Date.UTC(2026, 10, 13);
  const day = (i: number) => new Date(today - (days - 1 - i) * 86_400_000).toISOString().slice(0, 10);
  const scale = days / 28;
  const start = Math.round(42000 * scale);
  // Part des installations encore là à chaque écran ; iOS seul pour quelques-uns.
  const keep: [string, number, "all" | "ios" | "android"][] = [
    ["welcome", 1, "all"], ["language", 0.93, "all"], ["lessons", 0.9, "all"], ["researchers", 0.88, "all"], ["intro", 0.86, "all"], ["social_proof", 0.81, "all"],
    ["name", 0.79, "all"], ["age", 0.74, "all"], ["knowledge", 0.72, "all"], ["motivation", 0.71, "all"], ["objective", 0.7, "all"], ["topics", 0.68, "all"],
    ["objective_intro", 0.67, "all"], ["phone_time", 0.66, "all"], ["years_grid", 0.65, "all"], ["transform", 0.64, "all"], ["questions", 0.63, "all"],
    ["mission", 0.62, "all"], ["personalize", 0.61, "all"], ["swipe_courses", 0.6, "all"], ["reading_time", 0.57, "ios"], ["curve_90", 0.56, "all"],
    ["notifications", 0.44, "all"], ["review", 0.54, "all"], ["loading", 0.53, "all"], ["profile", 0.52, "all"], ["login", 0.51, "all"], ["account", 0.3, "ios"],
    ["follow_creators", 0.37, "all"], ["welcome_aboard", 0.36, "all"], ["features", 0.35, "all"], ["trial_steps", 0.34, "all"], ["reminder", 0.33, "all"],
    ["paywall_annual", 0.32, "ios"], ["paywall_comparison", 0.2, "ios"], ["paywall", 0.31, "android"],
  ];
  const iosShare = 0.78;
  const steps = keep.map(([name, rate, where]) => {
    const ios = where === "android" ? 0 : Math.round(start * iosShare * rate);
    const android = where === "ios" ? 0 : Math.round(start * (1 - iosShare) * rate);
    return { step: name, installs: ios + android, ios, android };
  });
  const question = (name: string, answered: number, options: [string, number][]) => ({ question: name, answered: Math.round(answered * scale), options: options.map(([value, share]) => ({ value, installs: Math.round(answered * scale * share) })) });
  return {
    days,
    from: day(0),
    updated_at: "2026-11-13T09:35:00Z",
    languages: ["de", "en", "es", "fr", "it", "pt"],
    steps,
    series: Array.from({ length: days }, (_, i) => ({ day: day(i), installs: Math.round(1500 * (0.8 + 0.4 * Math.abs(Math.sin(i * 0.9)))) })),
    questions: [
      question("age", 30200, [["under18", 0.11], ["18to24", 0.34], ["25to34", 0.27], ["35to44", 0.14], ["45to54", 0.08], ["55plus", 0.06]]),
      question("knowledge", 29800, [["0", 0.18], ["1", 0.47], ["2", 0.28], ["3", 0.07]]),
      question("motivation", 29400, [["grow", 0.31], ["conversations", 0.24], ["world", 0.21], ["career", 0.14], ["sharp", 0.1]]),
      question("objectives", 29000, [["cultivate", 0.72], ["curiosity", 0.48], ["reduceScreen", 0.39], ["impress", 0.22], ["exams", 0.17]]),
      question("topics", 28400, [["histoire", 0.61], ["sciences", 0.52], ["philosophie", 0.38], ["art", 0.33], ["geopolitique", 0.31], ["economie", 0.24]]),
      question("phone_time", 27600, [["60", 0.04], ["120", 0.12], ["180", 0.31], ["240", 0.26], ["300", 0.17], ["360", 0.1]]),
      question("reads_monthly", 17200, [["true", 0.58], ["false", 0.42]]),
      question("too_much_phone", 17100, [["true", 0.81], ["false", 0.19]]),
    ],
  };
}

/** Un tableau de bord des paywalls plausible, pour regarder /admin/data hors ligne. */
function paywallDashboard(days: number) {
  const today = Date.UTC(2026, 10, 13);
  const day = (i: number) => new Date(today - (days - 1 - i) * 86_400_000).toISOString().slice(0, 10);
  const wave = (i: number, base: number) => Math.round(base * (0.8 + 0.4 * Math.abs(Math.sin(i * 0.9))));
  const counts = (views: number, rate: number) => ({ views, viewers: Math.round(views * 0.72), purchases_started: Math.round(views * rate * 1.9), purchases_completed: Math.round(views * rate), purchases_cancelled: Math.round(views * rate * 0.8), purchases_failed: Math.round(views * rate * 0.1) });
  const scale = days / 28;
  const paywalls: [string, number, number][] = [["onboarding_annual", 41200, 0.052], ["onboarding_comparison", 30900, 0.021], ["native_course_unlock_bonhomme", 6400, 0.018], ["native_course_unlock_reviews", 6350, 0.024], ["native_discount_percent", 5100, 0.031], ["native_discount_graduate", 5040, 0.027], ["native_quiz", 2300, 0.012], ["native_audio", 1250, 0.009]];
  const by_paywall = paywalls.map(([paywall_id, views, rate]) => ({ paywall_id, ...counts(Math.round(views * scale), rate) }));
  const sum = (key: keyof ReturnType<typeof counts>) => by_paywall.reduce((total, row) => total + row[key], 0);
  const revenueDays = Array.from({ length: days }, (_, i) => ({ day: day(i), revenue: wave(i, 6400), trials: wave(i, 460) }));
  const offering = (name: string, trials: number, converted: number, direct: number, revenue: number) => ({ offering: name, trials: Math.round(trials * scale), trial_conversions: Math.round(converted * scale), direct_purchases: Math.round(direct * scale), renewals: Math.round(converted * 0.05 * scale), refunds: Math.round(converted * 0.08 * scale), revenue: Math.round(revenue * scale), proceeds: Math.round(revenue * 0.74 * scale) });
  const by_offering = [offering("fin_onboarding", 10400, 3400, 0, 121000), offering("offre_discount_2999", 0, 90, 650, 15400), offering("offre_discount", 0, 60, 630, 14500), offering("debloquer_cours", 120, 20, 0, 700), offering("quizz", 50, 5, 0, 210)];
  const total = (key: "trials" | "trial_conversions" | "direct_purchases" | "renewals" | "refunds" | "revenue" | "proceeds") => by_offering.reduce((t, row) => t + row[key], 0);
  return {
    days,
    from: day(0),
    updated_at: "2026-11-13T09:25:00Z",
    languages: ["de", "en", "es", "fr", "it", "pt"],
    totals: { views: sum("views"), viewers: sum("viewers"), purchases_started: sum("purchases_started"), purchases_completed: sum("purchases_completed"), purchases_cancelled: sum("purchases_cancelled"), purchases_failed: sum("purchases_failed") },
    series: Array.from({ length: days }, (_, i) => ({ day: day(i), views: wave(i, 3500), purchases: wave(i, 120) })),
    by_paywall,
    by_experiment: [
      { experiment: "course_paywall_ab", variant: "bonhomme", ...counts(Math.round(6400 * scale), 0.018) },
      { experiment: "course_paywall_ab", variant: "reviews", ...counts(Math.round(6350 * scale), 0.024) },
      { experiment: "discount_paywall_ab", variant: "graduate", ...counts(Math.round(110 * scale), 0.027) },
      { experiment: "discount_paywall_ab", variant: "percent", ...counts(Math.round(120 * scale), 0.031) },
    ],
    by_offering: [{ offering: "fin_onboarding", ...counts(Math.round(88000 * scale), 0.037) }, { offering: "offre_discount", ...counts(Math.round(5200 * scale), 0.03) }, { offering: "offre_discount_2999", ...counts(Math.round(4940 * scale), 0.028) }],
    by_language: [["fr", 52000, 0.041], ["en", 21000, 0.033], ["es", 11800, 0.027], ["de", 6900, 0.036], ["it", 4100, 0.03], ["pt", 2740, 0.022]].map(([lang, views, rate]) => ({ lang, ...counts(Math.round(Number(views) * scale), Number(rate)) })),
    by_platform: [{ platform: "android", ...counts(Math.round(21500 * scale), 0.026) }, { platform: "ios", ...counts(Math.round(77040 * scale), 0.039) }],
    revenue: { totals: { trials: total("trials"), trial_conversions: total("trial_conversions"), direct_purchases: total("direct_purchases"), renewals: total("renewals"), refunds: total("refunds"), revenue: total("revenue"), proceeds: total("proceeds") }, series: revenueDays, by_offering, first_day: "2026-11-08" },
  };
}

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
        return { data: 2, error: null };
      case "studio_quota":
        return { data: mockQuota, error: null };
      case "studio_payouts_due":
        return {
          data: {
            due_cents: 1500,
            creators: [{ user_id: USER_ID, name: account.display_name, slug: account.slug, email: account.email, amount_cents: 1500, oldest_at: "2026-11-03T11:00:00Z", credits: [{ id: 3, draft_id: DRAFT_IDS[2], title: drafts[2].title, amount_cents: 1500, created_at: "2026-11-03T11:00:00Z" }] }],
            history: [{ id: 2, user_id: USER_ID, name: account.display_name, amount_cents: 1500, credits_count: 1, paid_at: "2026-10-26T09:00:00Z", note: null }],
            paid_total_cents: 3000,
          },
          error: null,
        };
      case "admin_social_dashboard":
        return { data: socialDashboard(Number(p.p_days ?? 28)), error: null };
      case "admin_usage_dashboard":
        return { data: usageDashboard(Number(p.p_days ?? 28)), error: null };
      case "admin_feedback_dashboard":
        return { data: feedbackDashboard(Number(p.p_days ?? 28)), error: null };
      case "admin_onboarding_dashboard":
        return { data: onboardingDashboard(Number(p.p_days ?? 28)), error: null };
      case "admin_paywall_dashboard":
        return { data: paywallDashboard(Number(p.p_days ?? 28)), error: null };
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
      return list([{ version: 2, title: slug === "writing-guide" ? "Writing a Sophia course" : "Creator agreement", body_md: slug === "writing-guide" ? guideMd : agreementMd }]);
    }
    case "creator_agreements":
      return list(MOCK_STUDIO === "author" ? [{ user_id: USER_ID, version: 2, signed_at: "2026-11-02T10:00:00Z" }] : []);
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
  if (MOCK_STUDIO === "new") return { supabase, user, account: null, isAdmin: false, agreementSigned: false, publicPage: false, quota: null, potCents: 0 };
  if (MOCK_STUDIO === "onboarding") return { supabase, user, account: { ...account, status: "pending", onboarding_step: "profile", display_name: null, title: null, bio: null, approved_at: null, guide_read_at: null }, isAdmin: false, agreementSigned: false, publicPage: false, quota: { ...mockQuota, limit: 3, used: 0, open: 0, can_propose: true, first_week: true, period_end: null }, potCents: 0 };
  return { supabase, user, account, isAdmin: true, agreementSigned: true, publicPage: true, quota: mockQuota, potCents: 1500 };
}

export const MOCK_DRAFT_IDS = DRAFT_IDS;
