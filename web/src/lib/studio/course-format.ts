/** Les règles du format V2 d'un cours (docs/publish-contract.md, CHARTE_REFONTE §4), côté Studio.
 *  Les mêmes vérifications que publish-course, écrites en anglais pour l'éditeur : l'auteur voit
 *  les problèmes pendant qu'il écrit, et l'équipe ne reçoit pas de cours que l'usine refuserait. */

import { LANGS, SUBJECTS, type Block, type GlossaryEntry, type Section, type Source } from "@/lib/catalog/types";
import { countWords } from "@/lib/catalog/inline";

export const CLASSIFICATIONS = ["referenceHistorique", "concept", "evenementConnexe", "personnage", "lieuInstitution"] as const;
export type Classification = (typeof CLASSIFICATIONS)[number];
export const CLASSIFICATION_LABEL: Record<Classification, string> = {
  referenceHistorique: "Historical reference",
  concept: "Concept",
  evenementConnexe: "Related event",
  personnage: "Person",
  lieuInstitution: "Place or institution",
};

export const BLOCK_TYPES = ["paragraph", "heading", "image", "timeline", "funFact", "takeaway", "quote"] as const;
export type BlockType = (typeof BLOCK_TYPES)[number];
export const BLOCK_LABEL: Record<BlockType, string> = {
  paragraph: "Paragraph",
  heading: "Heading",
  image: "Image",
  timeline: "Timeline",
  funFact: "Did you know?",
  takeaway: "Key takeaway",
  quote: "Quote",
};

export type Hero = {
  image?: string;
  image_url?: string;
  ratio?: string;
  hook?: string;
  credit?: { title?: string; author?: string; license?: string; source?: string };
  /** Les couvertures générées parmi lesquelles choisir (adresses publiques), et le nombre de tirages. */
  candidates?: { url: string }[];
  generations?: number;
  prompt?: string;
};

/** Le crédit d'une couverture générée pour Sophia. */
export const COVER_CREDIT = { author: "Sophia", license: "Illustration generated for Sophia", source: "Sophia" } as const;
export const MAX_COVER_GENERATIONS = 3;

/** Un cours tel qu'il vit dans studio_drafts (les colonnes éditables). */
export interface DraftCourse {
  title: string;
  subtitle: string | null;
  subject: string | null;
  subcategory: string | null;
  description: string;
  hero: Hero;
  sections: Section[];
  sources: Source[];
  glossary: GlossaryEntry[];
}

export type Severity = "error" | "warning";
export interface Finding {
  severity: Severity;
  /** Où : "title", "description", "sections[2].blocks[0]", "glossary[1]"… */
  path: string;
  message: string;
}

const ASSET = /^[a-z0-9][a-z0-9_]{1,120}$/;
const HTTPS = /^https:\/\//;

function len(value: unknown): number {
  return typeof value === "string" ? value.trim().length : 0;
}

/** Les contrôles d'un texte : longueur, tiret cadratin, [[…]] et **…** équilibrés. */
export function checkText(text: unknown, path: string, out: Finding[], max = 5000, min = 1) {
  if (typeof text !== "string" || text.trim().length < min) {
    out.push({ severity: "error", path, message: min > 1 ? `At least ${min} characters.` : "Empty text." });
    return;
  }
  if (text.length > max) out.push({ severity: "error", path, message: `Too long: ${text.length} characters, ${max} at most.` });
  if (text.includes("—")) out.push({ severity: "error", path, message: "No em dash (—) in texts. Use a comma, a colon or a full stop." });
  const opens = (text.match(/\[\[/g) ?? []).length;
  const closes = (text.match(/\]\]/g) ?? []).length;
  if (opens !== closes) out.push({ severity: "error", path, message: "Unbalanced glossary markers [[…]]." });
  if ((text.match(/\*\*/g) ?? []).length % 2 !== 0) out.push({ severity: "error", path, message: "Unbalanced bold markers **…**." });
}

/** Les termes [[…]] cités dans tous les textes du cours. */
export function citedTerms(course: DraftCourse): string[] {
  const terms = new Set<string>();
  const scan = (text?: string | null) => {
    if (!text) return;
    for (const m of text.matchAll(/\[\[([^\]]+)\]\]/g)) terms.add(m[1].trim());
  };
  scan(course.description);
  scan(course.hero?.hook);
  for (const section of course.sections ?? []) {
    for (const block of section.blocks ?? []) {
      if ("text" in block) scan(block.text);
      if (block.type === "image") scan(block.caption);
      if (block.type === "timeline") for (const e of block.events ?? []) scan(e.detail);
    }
  }
  return [...terms];
}

/** Le nombre de mots du corps du cours (textes des blocs, repères compris). */
export function courseWords(course: DraftCourse): number {
  let words = 0;
  for (const section of course.sections ?? []) {
    for (const block of section.blocks ?? []) {
      if ("text" in block) words += countWords(block.text);
      if (block.type === "timeline") for (const e of block.events ?? []) words += countWords(`${e.title} ${e.detail ?? ""}`);
    }
  }
  return words;
}

/** Toutes les vérifications. Les erreurs bloquent l'envoi ; les avertissements sont des conseils. */
export function validateCourse(course: DraftCourse): Finding[] {
  const out: Finding[] = [];
  if (len(course.title) < 3) out.push({ severity: "error", path: "title", message: "A title of 3 to 160 characters." });
  else checkText(course.title, "title", out, 160);
  if (course.subtitle && course.subtitle.length > 80) out.push({ severity: "error", path: "subtitle", message: "Subtitle: 80 characters at most." });
  if (!course.subject || !(SUBJECTS as readonly string[]).includes(course.subject)) out.push({ severity: "error", path: "subject", message: "Choose a subject." });
  if (course.subcategory && course.subcategory.length > 80) out.push({ severity: "error", path: "subcategory", message: "Subcategory: 80 characters at most." });
  if (len(course.description) < 20) out.push({ severity: "error", path: "description", message: "The card hook needs 20 to 600 characters." });
  else checkText(course.description, "description", out, 600);

  const hero = course.hero ?? {};
  if (hero.image !== undefined && hero.image !== "" && !ASSET.test(hero.image)) out.push({ severity: "error", path: "hero", message: "Cover slug: lowercase letters, digits and underscores." });
  if (hero.image_url && !HTTPS.test(hero.image_url)) out.push({ severity: "error", path: "hero", message: "Cover image: an https URL." });
  if (!hero.image && !hero.image_url) out.push({ severity: "error", path: "hero", message: "Choose a cover before sending: generate three from the title and pick one." });
  if (hero.hook) checkText(hero.hook, "hero.hook", out, 200);

  const sections = course.sections ?? [];
  if (sections.length < 2 || sections.length > 12) {
    out.push({ severity: "error", path: "sections", message: "2 to 12 sections, introduction included." });
  }
  let takeaways = 0;
  let images = 0;
  sections.forEach((section, s) => {
    const where = `sections[${s}]`;
    if (len(section.title) < 1) out.push({ severity: "error", path: where, message: `Section ${s + 1} has no title.` });
    else if (section.title.length > 120) out.push({ severity: "error", path: where, message: `Section ${s + 1}: title of 120 characters at most.` });
    const blocks = section.blocks ?? [];
    if (blocks.length === 0) {
      out.push({ severity: "error", path: where, message: `Section ${s + 1} is empty.` });
      return;
    }
    const words = blocks.reduce((n, b) => n + ("text" in b ? countWords(b.text) : 0), 0);
    if (words > 300) out.push({ severity: "warning", path: where, message: `Section ${s + 1} is long (${words} words). Readers follow best under 250 words per section.` });
    blocks.forEach((block, b) => {
      const bw = `${where}.blocks[${b}]`;
      if (!(BLOCK_TYPES as readonly string[]).includes(block.type)) {
        out.push({ severity: "error", path: bw, message: `Unknown block type ${String(block.type)}.` });
        return;
      }
      if ("text" in block) checkText(block.text, bw, out, block.type === "heading" ? 160 : 5000);
      if (block.type === "takeaway") takeaways += 1;
      if (block.type === "image") {
        images += 1;
        const ok = (block.asset && ASSET.test(block.asset)) || (block.image_url && HTTPS.test(block.image_url));
        if (!ok) out.push({ severity: "error", path: bw, message: `Section ${s + 1}: an image needs a picture (Commons URL or bucket slug).` });
        if (block.caption) checkText(block.caption, `${bw}.caption`, out, 400);
      }
      if (block.type === "timeline") {
        const events = block.events ?? [];
        if (events.length < 2) out.push({ severity: "error", path: bw, message: `Section ${s + 1}: a timeline needs at least two dated events.` });
        events.forEach((e, i) => {
          if (len(e.date) < 1) out.push({ severity: "error", path: `${bw}.events[${i}]`, message: `Section ${s + 1}, event ${i + 1}: a date is required.` });
          if (len(e.title) < 1) out.push({ severity: "error", path: `${bw}.events[${i}]`, message: `Section ${s + 1}, event ${i + 1}: a title is required.` });
          if (e.detail) checkText(e.detail, `${bw}.events[${i}]`, out, 400);
        });
      }
      if (block.type === "quote" && block.attribution && block.attribution.length > 160) out.push({ severity: "error", path: bw, message: "Quote attribution: 160 characters at most." });
    });
  });
  if (takeaways > 1) out.push({ severity: "error", path: "sections", message: "Only one key takeaway, at the end of the course." });
  if (sections.length >= 2 && takeaways === 0) out.push({ severity: "warning", path: "sections", message: "No key takeaway yet. Readers remember a course that ends with one." });
  if (sections.length >= 2 && images === 0) out.push({ severity: "warning", path: "sections", message: "No image in the text. One or two well-chosen pictures from Commons help." });

  (course.sources ?? []).forEach((source, i) => {
    if (len(source.text) < 3) out.push({ severity: "error", path: `sources[${i}]`, message: `Source ${i + 1}: a reference of 3 to 400 characters.` });
    else if (source.text.length > 400) out.push({ severity: "error", path: `sources[${i}]`, message: `Source ${i + 1}: 400 characters at most.` });
    if (source.url && !/^https?:\/\//.test(source.url)) out.push({ severity: "error", path: `sources[${i}]`, message: `Source ${i + 1}: the link must start with http(s)://.` });
  });
  if ((course.sources ?? []).length === 0 && sections.length >= 2) out.push({ severity: "warning", path: "sources", message: "No source listed. Two or three references make the course trustworthy." });

  const glossaryTerms = new Set<string>();
  (course.glossary ?? []).forEach((entry, i) => {
    if (len(entry.term) < 1) out.push({ severity: "error", path: `glossary[${i}]`, message: `Glossary entry ${i + 1}: a term is required.` });
    else if (glossaryTerms.has(entry.term.toLowerCase())) out.push({ severity: "error", path: `glossary[${i}]`, message: `Glossary: "${entry.term}" appears twice.` });
    glossaryTerms.add((entry.term ?? "").toLowerCase());
    if (!(CLASSIFICATIONS as readonly string[]).includes(entry.classification)) out.push({ severity: "error", path: `glossary[${i}]`, message: `Glossary entry ${i + 1}: choose a type.` });
    if (len(entry.explanation) < 10) out.push({ severity: "error", path: `glossary[${i}]`, message: `Glossary "${entry.term || i + 1}": an explanation of 10 to 600 characters.` });
    else if (entry.explanation.length > 600) out.push({ severity: "error", path: `glossary[${i}]`, message: `Glossary "${entry.term}": 600 characters at most.` });
  });
  for (const term of citedTerms(course)) {
    if (!glossaryTerms.has(term.toLowerCase())) out.push({ severity: "warning", path: "glossary", message: `[[${term}]] has no glossary entry. The factory will write one; you can write it yourself.` });
  }
  const totalWords = courseWords(course);
  if (sections.length >= 2 && totalWords < 400) out.push({ severity: "warning", path: "sections", message: `Short course (${totalWords} words). Sophia courses run 500 to 900 words.` });
  if (totalWords > 1100) out.push({ severity: "warning", path: "sections", message: `Long course (${totalWords} words). The guide asks for 500 to 900; consider splitting it in two courses.` });
  return out;
}

export function hasErrors(findings: Finding[]): boolean {
  return findings.some((f) => f.severity === "error");
}

/** Le corps de publish-course à partir d'un brouillon et de son auteur. */
export function toPublishBody(
  course: DraftCourse,
  originLang: string,
  creator: { slug: string; name: string; title?: string | null; bio?: string | null; photo_url?: string | null; institution?: string | null; country?: string | null; links?: Record<string, string> | null; verified?: boolean },
  options: { appCourseId?: string | null; skipAudio?: boolean; requestedBy?: string; languages?: string[] | null } = {},
) {
  if (!(LANGS as readonly string[]).includes(originLang)) throw new Error(`Unknown language ${originLang}`);
  const hero: Hero = {};
  if (course.hero?.image) hero.image = course.hero.image;
  else if (course.hero?.image_url) hero.image_url = course.hero.image_url;
  hero.ratio = course.hero?.ratio || "16:9";
  if (course.hero?.hook) hero.hook = course.hero.hook;
  if (course.hero?.credit) hero.credit = course.hero.credit;
  const sections = course.sections.map((section, i) => ({
    ...(section.id ? { id: section.id } : {}),
    title: section.title.trim(),
    free: i === 0,
    blocks: section.blocks.map(cleanBlock),
  }));
  return {
    kind: "course" as const,
    origin_lang: originLang,
    requested_by: options.requestedBy ?? "studio",
    course: {
      ...(options.appCourseId ? { id: options.appCourseId } : {}),
      title: course.title.trim(),
      ...(course.subtitle ? { subtitle: course.subtitle.trim() } : {}),
      subject: course.subject,
      ...(course.subcategory ? { subcategory: course.subcategory.trim() } : {}),
      description: course.description.trim(),
      hero,
      sections,
      sources: (course.sources ?? []).filter((s) => s.text?.trim()).map((s) => ({ text: s.text.trim(), ...(s.url ? { url: s.url.trim() } : {}) })),
      glossary: (course.glossary ?? []).filter((g) => g.term?.trim()).map((g) => ({ term: g.term.trim(), classification: g.classification, explanation: g.explanation.trim() })),
    },
    creator: {
      slug: creator.slug,
      name: creator.name,
      ...(creator.title ? { title: creator.title } : {}),
      ...(creator.bio ? { bio: creator.bio } : {}),
      ...(creator.photo_url ? { photo_url: creator.photo_url } : {}),
      ...(creator.institution ? { institution: creator.institution } : {}),
      ...(creator.country && creator.country !== "OTHER" ? { country: creator.country } : {}),
      links: creator.links ?? {},
      verified: creator.verified ?? false,
    },
    options: { skip_audio: options.skipAudio ?? true, ...(options.languages && options.languages.length ? { languages: options.languages.filter((l) => l !== originLang) } : {}) },
  };
}

function cleanBlock(block: Block): Block {
  switch (block.type) {
    case "image": {
      const b: Extract<Block, { type: "image" }> = { type: "image" };
      if (block.asset) b.asset = block.asset;
      else if (block.image_url) b.image_url = block.image_url;
      if (block.caption?.trim()) b.caption = block.caption.trim();
      if (block.credit && Object.values(block.credit).some(Boolean)) b.credit = block.credit;
      if (block.fullBleed) b.fullBleed = true;
      return b;
    }
    case "timeline":
      return { type: "timeline", events: (block.events ?? []).map((e) => ({ date: e.date.trim(), title: e.title.trim(), ...(e.detail?.trim() ? { detail: e.detail.trim() } : {}) })) };
    case "quote":
      return { type: "quote", text: block.text.trim(), ...(block.attribution?.trim() ? { attribution: block.attribution.trim() } : {}) };
    default:
      return { type: block.type, text: block.text.trim() };
  }
}

/** Un bloc neuf de chaque type, pour l'éditeur. */
export function emptyBlock(type: BlockType): Block {
  switch (type) {
    case "image":
      return { type: "image", caption: "" };
    case "timeline":
      return { type: "timeline", events: [{ date: "", title: "" }, { date: "", title: "" }] };
    case "quote":
      return { type: "quote", text: "", attribution: "" };
    default:
      return { type, text: "" };
  }
}
