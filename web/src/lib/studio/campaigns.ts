import { LANGS, type Lang } from "@/lib/catalog/types";

/** Le format standard d'un événement éditorial (table `campaigns`, manifeste du catalogue, apps).
 *  La référence est docs/evenements.md ; ce fichier porte les listes fermées et la validation
 *  que l'admin applique avant de publier. */

export const CAMPAIGN_KINDS = [
  { id: "month", label: "Thematic month", hint: "A whole month around a cause or a theme (Movember, Black History Month).", days: 30 },
  { id: "week", label: "Thematic week", hint: "Seven days around a theme or an anniversary.", days: 7 },
  { id: "day", label: "Commemoration day", hint: "One date (11 November, 8 March) with a few days of lead-up.", days: 4 },
  { id: "series", label: "Series launch", hint: "A new collection or a new author, released over a few weeks.", days: 21 },
] as const;
export type CampaignKind = (typeof CAMPAIGN_KINDS)[number]["id"];

/** Les symboles autorisés : des noms SF Symbols (iOS) ; Android a l'icône Material correspondante. */
export const CAMPAIGN_SYMBOLS = [
  { id: "mustache.fill", label: "Moustache" },
  { id: "heart.fill", label: "Heart" },
  { id: "star.fill", label: "Star" },
  { id: "flame.fill", label: "Flame" },
  { id: "leaf.fill", label: "Leaf" },
  { id: "globe.europe.africa.fill", label: "Globe" },
  { id: "book.fill", label: "Book" },
  { id: "flag.fill", label: "Flag" },
  { id: "sparkles", label: "Sparkles" },
  { id: "drop.fill", label: "Drop" },
  { id: "sun.max.fill", label: "Sun" },
  { id: "moon.fill", label: "Moon" },
  { id: "graduationcap.fill", label: "Graduation cap" },
  { id: "brain.head.profile", label: "Brain" },
  { id: "figure.run", label: "Runner" },
  { id: "music.note", label: "Music note" },
  { id: "paintpalette.fill", label: "Palette" },
  { id: "building.columns.fill", label: "Columns" },
  { id: "snowflake", label: "Snowflake" },
  { id: "gift.fill", label: "Gift" },
  { id: "trophy.fill", label: "Trophy" },
  { id: "atom", label: "Atom" },
] as const;
export type CampaignSymbol = (typeof CAMPAIGN_SYMBOLS)[number]["id"];

export const CAMPAIGN_STATUSES = ["draft", "published", "archived"] as const;
export type CampaignStatus = (typeof CAMPAIGN_STATUSES)[number];

/** Un texte par langue : {"en": "…", "fr": "…"}. Les apps retombent sur l'anglais puis le français. */
export type Localized = Record<string, string>;

/** Une image générée pour l'événement : direction « couvertures » (Gemini) ou « affiche » du site (Recraft). */
export type ImageCandidate = { url: string; style: "cover" | "poster"; created_at: string };

/** Une illustration de badge générée (Recraft, papier découpé). */
export type BadgeCandidate = { url: string; created_at: string };

export type Campaign = {
  slug: string;
  kind: CampaignKind;
  status: CampaignStatus;
  symbol: CampaignSymbol;
  /** Image 16:9 hébergée (course-images/events/), en tête de la carte du fil et de la page ; null : bleu nuit et symbole. */
  image_url: string | null;
  /** Les images générées, les plus récentes en premier ; l'équipe en choisit une. */
  image_candidates: ImageCandidate[];
  /** L'illustration du badge (carrée, papier découpé) ; null : les apps montrent le symbole. */
  badge_image_url: string | null;
  /** Les illustrations de badge générées, les plus récentes en premier ; l'équipe en choisit une. */
  badge_candidates: BadgeCandidate[];
  /** Pays où l'événement est montré (ISO 3166-1 alpha-2, la région du téléphone) ; null : partout. */
  countries: string[] | null;
  starts_at: string;
  ends_at: string;
  challenge_target: number;
  participants: number;
  /** L'objectif commun : cours de la collection à terminer tous lecteurs confondus ; null : pas d'objectif. */
  goal_target: number | null;
  /** Où en est l'objectif commun (recalculé toutes les heures côté serveur). */
  goal_count: number;
  course_ids: string[];
  title: Localized;
  tagline: Localized;
  description: Localized;
  badge_name: Localized;
  created_at?: string;
  updated_at?: string;
};

export const TEXT_FIELDS = ["title", "tagline", "description", "badge_name"] as const;
export type TextField = (typeof TEXT_FIELDS)[number];
export const TEXT_LIMITS: Record<TextField, number> = { title: 60, tagline: 90, description: 300, badge_name: 40 };
export const TEXT_LABELS: Record<TextField, string> = { title: "Title", tagline: "Tagline", description: "Description", badge_name: "Badge name" };
/** La langue saisie à la main dans l'admin : l'anglais. Toutes les autres, français compris, sont
 *  traduites depuis l'anglais (jamais de double traduction). */
export const EDITED_LANGS = ["en"] as const;
export const MAX_COURSES = 40;
export const SLUG_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const DAY_RE = /^\d{4}-\d{2}-\d{2}$/;

export function localized(table: Localized | null | undefined, lang: string): string {
  if (!table) return "";
  for (const code of [lang, "en", "fr"]) {
    const v = table[code]?.trim();
    if (v) return v;
  }
  return Object.values(table).find((v) => v?.trim())?.trim() ?? "";
}

export function kindLabel(kind: string): string {
  return CAMPAIGN_KINDS.find((k) => k.id === kind)?.label ?? kind;
}

export function symbolLabel(symbol: string): string {
  return CAMPAIGN_SYMBOLS.find((s) => s.id === symbol)?.label ?? symbol;
}

export function emptyCampaign(): Campaign {
  return { slug: "", kind: "month", status: "draft", symbol: "sparkles", image_url: null, image_candidates: [], badge_image_url: null, badge_candidates: [], countries: null, starts_at: "", ends_at: "", challenge_target: 3, participants: 0, goal_target: null, goal_count: 0, course_ids: [], title: {}, tagline: {}, description: {}, badge_name: {} };
}

/** Une ligne de la table, telle que Supabase la renvoie, remise dans le type. */
export function campaignFromRow(row: Record<string, unknown>): Campaign {
  const obj = (v: unknown): Localized => (v && typeof v === "object" && !Array.isArray(v) ? Object.fromEntries(Object.entries(v as Record<string, unknown>).filter(([, x]) => typeof x === "string")) as Localized : {});
  return {
    slug: String(row.slug ?? ""),
    kind: (CAMPAIGN_KINDS.some((k) => k.id === row.kind) ? row.kind : "month") as CampaignKind,
    status: (CAMPAIGN_STATUSES as readonly string[]).includes(String(row.status)) ? (row.status as CampaignStatus) : "draft",
    symbol: (CAMPAIGN_SYMBOLS.some((s) => s.id === row.symbol) ? row.symbol : "sparkles") as CampaignSymbol,
    image_url: typeof row.image_url === "string" && /^https:\/\//.test(row.image_url) ? row.image_url : null,
    image_candidates: Array.isArray(row.image_candidates)
      ? (row.image_candidates as unknown[])
          .map((c) => (c && typeof c === "object" ? (c as Record<string, unknown>) : {}))
          .filter((c) => typeof c.url === "string" && /^https:\/\//.test(c.url))
          .map((c) => ({ url: c.url as string, style: c.style === "poster" ? ("poster" as const) : ("cover" as const), created_at: typeof c.created_at === "string" ? c.created_at : "" }))
      : [],
    badge_image_url: typeof row.badge_image_url === "string" && /^https:\/\//.test(row.badge_image_url) ? row.badge_image_url : null,
    badge_candidates: Array.isArray(row.badge_candidates)
      ? (row.badge_candidates as unknown[])
          .map((c) => (c && typeof c === "object" ? (c as Record<string, unknown>) : {}))
          .filter((c) => typeof c.url === "string" && /^https:\/\//.test(c.url))
          .map((c) => ({ url: c.url as string, created_at: typeof c.created_at === "string" ? c.created_at : "" }))
      : [],
    countries: Array.isArray(row.countries) && row.countries.length > 0 ? (row.countries as unknown[]).map(String).filter((c) => /^[A-Z]{2}$/.test(c)) : null,
    starts_at: String(row.starts_at ?? "").slice(0, 10),
    ends_at: String(row.ends_at ?? "").slice(0, 10),
    challenge_target: Number(row.challenge_target ?? 1) || 1,
    participants: Number(row.participants ?? 0) || 0,
    goal_target: row.goal_target == null || row.goal_target === "" ? null : Math.max(1, Math.round(Number(row.goal_target)) || 1),
    goal_count: Math.max(0, Math.round(Number(row.goal_count ?? 0)) || 0),
    course_ids: Array.isArray(row.course_ids) ? (row.course_ids as unknown[]).map(String) : [],
    title: obj(row.title),
    tagline: obj(row.tagline),
    description: obj(row.description),
    badge_name: obj(row.badge_name),
    created_at: typeof row.created_at === "string" ? row.created_at : undefined,
    updated_at: typeof row.updated_at === "string" ? row.updated_at : undefined,
  };
}

function text(form: FormData, key: string, max: number): string {
  const v = form.get(key);
  return typeof v === "string" ? v.trim().slice(0, max) : "";
}

/** Ce que le formulaire de l'admin envoie, fondu dans l'événement existant : les langues autres
 *  que l'anglais et le français (traduites) sont conservées, un champ vidé est retiré. */
export function campaignFromForm(form: FormData, existing: Campaign | null): Campaign {
  const base = existing ?? emptyCampaign();
  const kind = text(form, "kind", 20);
  const status = text(form, "status", 20);
  const symbol = text(form, "symbol", 40);
  const merge = (field: TextField): Localized => {
    const out: Localized = { ...base[field] };
    for (const lang of EDITED_LANGS) {
      const v = text(form, `${field}_${lang}`, TEXT_LIMITS[field]);
      if (v) out[lang] = v;
      else delete out[lang];
    }
    return out;
  };
  const courseIds = Array.from(new Set(form.getAll("course_ids").map(String).map((s) => s.trim()).filter(Boolean))).slice(0, MAX_COURSES);
  const goalRaw = text(form, "goal_target", 12).replace(/[\s,.]/g, "");
  const goal = goalRaw ? Math.round(Number(goalRaw)) : NaN;
  const countries = Array.from(new Set(text(form, "countries", 400).toUpperCase().split(/[\s,;]+/).map((c) => c.trim()).filter(Boolean)));
  return {
    ...base,
    slug: existing ? existing.slug : text(form, "slug", 60).toLowerCase(),
    kind: (CAMPAIGN_KINDS.some((k) => k.id === kind) ? kind : base.kind) as CampaignKind,
    status: ((CAMPAIGN_STATUSES as readonly string[]).includes(status) ? status : base.status) as CampaignStatus,
    symbol: (CAMPAIGN_SYMBOLS.some((s) => s.id === symbol) ? symbol : base.symbol) as CampaignSymbol,
    starts_at: text(form, "starts_at", 10),
    ends_at: text(form, "ends_at", 10),
    challenge_target: Math.max(1, Math.min(50, Math.round(Number(text(form, "challenge_target", 3)) || 1))),
    goal_target: Number.isFinite(goal) && goal >= 1 ? Math.min(100_000_000, goal) : null,
    countries: countries.length > 0 ? countries : null,
    course_ids: courseIds,
    title: merge("title"),
    tagline: merge("tagline"),
    description: merge("description"),
    badge_name: merge("badge_name"),
  };
}

export type Known = { courseIds: Set<string> };

/** Ce qui empêche d'enregistrer du tout : un slug ou des dates qui ne passeraient pas la base. */
export function hardErrors(c: Campaign): string[] {
  const errors: string[] = [];
  if (!SLUG_RE.test(c.slug) || c.slug.length < 3 || c.slug.length > 60) errors.push("The slug must be 3 to 60 characters: lowercase letters, digits and single hyphens (movember-2026).");
  if (!DAY_RE.test(c.starts_at) || Number.isNaN(Date.parse(c.starts_at))) errors.push("The start date is missing or invalid.");
  if (!DAY_RE.test(c.ends_at) || Number.isNaN(Date.parse(c.ends_at))) errors.push("The end date is missing or invalid.");
  if (errors.length === 0 && c.ends_at < c.starts_at) errors.push("The event cannot end before it starts.");
  if (c.course_ids.length > MAX_COURSES) errors.push(`At most ${MAX_COURSES} courses.`);
  const badCountries = (c.countries ?? []).filter((x) => !/^[A-Z]{2}$/.test(x));
  if (badCountries.length > 0) errors.push(`Countries must be two-letter codes (FR, BE, CH…): ${badCountries.join(", ")}.`);
  return errors;
}

/** Ce qui manque pour publier : l'événement s'enregistre en brouillon malgré tout. */
export function publishProblems(c: Campaign, known: Known): string[] {
  const problems: string[] = [];
  for (const field of TEXT_FIELDS) if (!c[field].en?.trim()) problems.push(`${TEXT_LABELS[field]} in English is required.`);
  if (c.course_ids.length === 0) problems.push("Pick at least one course for the collection.");
  const unknown = c.course_ids.filter((id) => !known.courseIds.has(id));
  if (unknown.length > 0) problems.push(`${unknown.length} course${unknown.length > 1 ? "s are" : " is"} not published: ${unknown.slice(0, 3).join(", ")}${unknown.length > 3 ? "…" : ""}.`);
  if (c.course_ids.length > 0 && c.challenge_target > c.course_ids.length) problems.push(`The challenge asks for ${c.challenge_target} courses but the collection has ${c.course_ids.length}.`);
  const monthKinds: Record<CampaignKind, [number, number]> = { month: [20, 62], week: [5, 14], day: [1, 10], series: [7, 90] };
  if (DAY_RE.test(c.starts_at) && DAY_RE.test(c.ends_at)) {
    const days = Math.round((Date.parse(c.ends_at) - Date.parse(c.starts_at)) / 86_400_000) + 1;
    const [min, max] = monthKinds[c.kind];
    if (days < min || days > max) problems.push(`${kindLabel(c.kind)} events last ${min} to ${max} days; this one lasts ${days}.`);
  }
  return problems;
}

/** Les langues dont les quatre textes sont remplis (celles que les lecteurs verront dans leur langue). */
export function languagesFilled(c: Campaign): Lang[] {
  return LANGS.filter((lang) => TEXT_FIELDS.every((f) => c[f][lang]?.trim()));
}

export function languagesMissing(c: Campaign): Lang[] {
  const filled = new Set(languagesFilled(c));
  return LANGS.filter((lang) => !filled.has(lang));
}

export function statusTone(status: CampaignStatus): "tint" | "green" | "amber" | "red" | "cream" {
  return status === "published" ? "green" : status === "archived" ? "tint" : "amber";
}

/** En cours, à venir, terminé, par rapport à aujourd'hui (dates civiles). */
export function phase(c: Campaign, today = new Date().toISOString().slice(0, 10)): "upcoming" | "live" | "over" {
  if (c.starts_at > today) return "upcoming";
  if (c.ends_at < today) return "over";
  return "live";
}
