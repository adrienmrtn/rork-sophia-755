import "server-only";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { createAnonClient } from "@/lib/supabase/server";
import { DATA_SOURCE, STORAGE_PUBLIC } from "@/lib/env";
import { countWords } from "./inline";
import { courseNumber } from "./slugs";
import type { Block, CatalogSource, CourseDetail, CourseSummary, Creator, Credit, GlossaryEntry, Lang, Section, Source, Subject } from "./types";

/* ------------------------------------------------------------------ communs */

function coverUrl(slug: string | null | undefined): string | null {
  return slug ? `${STORAGE_PUBLIC}/course-images/${slug}.jpg` : null;
}

/** Les portraits des seize premiers auteurs sont dans le site (public/authors), ceux des créateurs du
 *  Studio sont hébergés (creators.photo_url). */
function creatorPhoto(photo: string | null | undefined, photoUrl: string | null | undefined): string | null {
  if (photo) return `/authors/${photo}.jpg`;
  return photoUrl ?? null;
}

function pickLang(table: unknown, lang: string): string | null {
  if (!table || typeof table !== "object") return typeof table === "string" ? table : null;
  const t = table as Record<string, string>;
  for (const code of [lang, "en", "fr"]) {
    const v = t[code]?.trim();
    if (v) return v;
  }
  const first = Object.values(t).find((v) => v && v.trim());
  return first ?? null;
}

function sectionWords(sections: Section[]): number {
  let n = 0;
  for (const s of sections) {
    n += countWords(s.title ?? "");
    for (const b of s.blocks ?? []) {
      if ("text" in b && typeof b.text === "string") n += countWords(b.text);
      if (b.type === "timeline") for (const e of b.events ?? []) n += countWords(`${e.title} ${e.detail ?? ""}`);
    }
  }
  return n;
}

/** Minutes de lecture : 180 mots par minute, 3 au moins, 12 au plus. */
export function minutesFor(words: number): number {
  return Math.max(3, Math.min(12, Math.round(words / 180)));
}

/* ----------------------------------------------------------------- Supabase */

type ContentRow = {
  course_id: string;
  title: string;
  subtitle: string | null;
  description: string;
  subcategory: string | null;
  hook: string | null;
  section_ids: string[] | null;
  bytes: number | null;
  content?: { sections?: Section[]; sources?: Source[] } | null;
  courses: { subject: Subject; creator_slug: string | null; cover_slug: string | null; status: string } | null;
};

function summaryFromRow(row: ContentRow, quizCount: number, words: number | null): CourseSummary | null {
  const number = courseNumber(row.course_id);
  if (number === null || !row.courses) return null;
  const sectionCount = row.section_ids?.length ?? row.content?.sections?.length ?? 0;
  // Sans le texte, on estime les mots depuis la taille du paquet servi aux apps.
  const estimatedWords = words ?? Math.round((row.bytes ?? 0) / 9);
  return {
    id: row.course_id,
    number,
    title: row.title,
    subtitle: row.subtitle,
    description: row.description,
    hook: row.hook,
    subject: row.courses.subject,
    subcategory: row.subcategory,
    creatorSlug: row.courses.creator_slug,
    coverUrl: coverUrl(row.courses.cover_slug),
    sectionCount,
    quizCount,
    minutes: minutesFor(estimatedWords),
  };
}

class SupabaseCatalog implements CatalogSource {
  async listCourses(lang: Lang): Promise<CourseSummary[]> {
    const sb = createAnonClient();
    const { data, error } = await sb
      .from("course_contents")
      .select("course_id,title,subtitle,description,subcategory,hook,section_ids,bytes,courses!inner(subject,creator_slug,cover_slug,status)")
      .eq("lang", lang)
      .eq("status", "published")
      .eq("courses.status", "published")
      .order("course_id");
    if (error) throw new Error(`catalogue : ${error.message}`);
    return (data as unknown as ContentRow[]).map((row) => summaryFromRow(row, 0, null)).filter((c): c is CourseSummary => c !== null);
  }

  async getCourse(lang: Lang, number: number): Promise<CourseDetail | null> {
    const sb = createAnonClient();
    const { data: ids } = await sb.from("courses").select("id").like("id", `course_${number}_%`).eq("status", "published").limit(1);
    const id = ids?.[0]?.id as string | undefined;
    if (!id) return null;
    const [contentRes, glossaryRes, quizRes, assetsRes, langsRes] = await Promise.all([
      sb
        .from("course_contents")
        .select("course_id,title,subtitle,description,subcategory,hook,section_ids,bytes,content,courses!inner(subject,creator_slug,cover_slug,status)")
        .eq("lang", lang)
        .eq("course_id", id)
        .eq("status", "published")
        .maybeSingle(),
      sb.from("glossary_entries").select("term,display_term,classification,explanation").eq("course_id", id).eq("lang", lang),
      sb.from("quizzes").select("questions").eq("course_id", id).eq("lang", lang).maybeSingle(),
      sb.from("course_assets").select("slug,kind,credit").eq("course_id", id),
      sb.from("course_contents").select("lang").eq("course_id", id).eq("status", "published"),
    ]);
    const row = contentRes.data as unknown as ContentRow | null;
    if (!row) return null;
    const sections = (row.content?.sections ?? []) as Section[];
    const words = sectionWords(sections);
    const quizCount = Array.isArray(quizRes.data?.questions) ? (quizRes.data.questions as unknown[]).length : 0;
    const summary = summaryFromRow(row, quizCount, words);
    if (!summary) return null;
    const glossary: GlossaryEntry[] = (glossaryRes.data ?? []).map((g) => ({
      term: (g.display_term as string) || (g.term as string),
      classification: g.classification as string,
      explanation: g.explanation as string,
    }));
    const credits: Record<string, Credit> = {};
    for (const a of assetsRes.data ?? []) if (a.credit) credits[a.slug as string] = a.credit as Credit;
    return {
      ...summary,
      sections,
      glossary,
      sources: (row.content?.sources ?? []) as Source[],
      credits,
      languages: (langsRes.data ?? []).map((l) => l.lang as string),
    };
  }

  async listCreators(lang: Lang): Promise<Creator[]> {
    const sb = createAnonClient();
    const [{ data: creators, error }, { data: courses }] = await Promise.all([
      sb.from("creators").select("slug,name,photo,photo_url,institution,country,links,title,bio,verified").order("name"),
      sb.from("courses").select("id,creator_slug").eq("status", "published").not("creator_slug", "is", null),
    ]);
    if (error) throw new Error(`créateurs : ${error.message}`);
    const byCreator = new Map<string, string[]>();
    for (const c of courses ?? []) {
      const slug = c.creator_slug as string;
      byCreator.set(slug, [...(byCreator.get(slug) ?? []), c.id as string]);
    }
    return (creators ?? []).map((c) => ({
      slug: c.slug as string,
      name: c.name as string,
      photoUrl: creatorPhoto(c.photo as string | null, c.photo_url as string | null),
      institution: (c.institution as string | null) ?? null,
      country: (c.country as string | null) ?? null,
      title: pickLang(c.title, lang),
      bio: pickLang(c.bio, lang),
      verified: c.verified !== false,
      links: (c.links as Record<string, string> | null) ?? {},
      courseIds: byCreator.get(c.slug as string) ?? [],
    }));
  }

  async getCreator(lang: Lang, slug: string): Promise<Creator | null> {
    const all = await this.listCreators(lang);
    return all.find((c) => c.slug === slug) ?? null;
  }
}

/* -------------------------------------------------------- pack de départ */

/** Le pack embarqué dans les apps (ios/Sophia/Resources/StarterPack/<lang>) : la même forme de
 *  données, sans réseau. Pour travailler sur le site hors ligne et pour les captures. */
class StarterPackCatalog implements CatalogSource {
  private root = path.resolve(process.cwd(), "..", "ios", "Sophia", "Resources", "StarterPack");

  private async json<T>(rel: string): Promise<T | null> {
    try {
      return JSON.parse(await readFile(path.join(this.root, rel), "utf8")) as T;
    } catch {
      return null;
    }
  }

  private async catalog(lang: Lang) {
    const lang2 = (await this.json<StarterCatalog>(`${lang}/catalog.json`)) ?? (await this.json<StarterCatalog>("en/catalog.json"));
    return lang2;
  }

  async listCourses(lang: Lang): Promise<CourseSummary[]> {
    const cat = await this.catalog(lang);
    if (!cat) return [];
    return cat.courses
      .map((c) => {
        const number = courseNumber(c.id);
        if (number === null) return null;
        return {
          id: c.id,
          number,
          title: c.title,
          subtitle: c.subtitle ?? null,
          description: c.description,
          hook: c.hook ?? null,
          subject: c.subject,
          subcategory: c.subcategory ?? null,
          creatorSlug: c.creator ?? null,
          coverUrl: coverUrl(c.cover),
          sectionCount: c.sections.length,
          quizCount: c.quizCount ?? 0,
          minutes: Math.max(3, Math.min(12, c.sections.length + 1)),
        } satisfies CourseSummary;
      })
      .filter((c): c is CourseSummary => c !== null);
  }

  async getCourse(lang: Lang, number: number): Promise<CourseDetail | null> {
    const list = await this.listCourses(lang);
    const summary = list.find((c) => c.number === number);
    if (!summary) return null;
    const bundle = (await this.json<StarterBundle>(`${lang}/courses/${summary.id}.json`)) ?? (await this.json<StarterBundle>(`en/courses/${summary.id}.json`));
    const sections = bundle?.content?.sections ?? [];
    const glossary = Object.entries(bundle?.glossary ?? {}).map(([term, g]) => ({ term: g.displayTerm || term, classification: g.classification, explanation: g.explanation }));
    return {
      ...summary,
      minutes: sections.length ? minutesFor(sectionWords(sections)) : summary.minutes,
      sections,
      glossary,
      sources: bundle?.content?.sources ?? [],
      credits: bundle?.credits ?? {},
      languages: ["en", "fr"],
    };
  }

  async listCreators(lang: Lang): Promise<Creator[]> {
    const cat = await this.catalog(lang);
    return (cat?.creators ?? []).map((c) => ({
      slug: c.slug,
      name: c.name,
      photoUrl: creatorPhoto(c.photo, c.photoUrl),
      institution: c.institution ?? null,
      country: c.country ?? null,
      title: c.title ?? null,
      bio: c.bio ?? null,
      verified: c.verified !== false,
      links: c.links ?? {},
      courseIds: c.courseIds ?? [],
    }));
  }

  async getCreator(lang: Lang, slug: string): Promise<Creator | null> {
    return (await this.listCreators(lang)).find((c) => c.slug === slug) ?? null;
  }
}

type StarterCatalog = {
  courses: { id: string; title: string; subtitle?: string | null; description: string; hook?: string | null; subject: Subject; subcategory?: string | null; creator?: string | null; cover?: string | null; sections: { id: string; title: string }[]; quizCount?: number }[];
  creators: { slug: string; name: string; photo?: string | null; photoUrl?: string | null; institution?: string | null; country?: string | null; title?: string | null; bio?: string | null; verified?: boolean | null; links?: Record<string, string> | null; courseIds?: string[] | null }[];
};
type StarterBundle = {
  content?: { sections?: Section[]; sources?: Source[] };
  glossary?: Record<string, { displayTerm: string; classification: string; explanation: string }>;
  credits?: Record<string, Credit>;
};

export const catalog: CatalogSource = DATA_SOURCE === "starter" ? new StarterPackCatalog() : new SupabaseCatalog();

/** La partie gratuite d'un cours : la première section. */
export function freeSection(course: CourseDetail): Section | null {
  return course.sections[0] ?? null;
}

export function isTextBlock(block: Block): block is Extract<Block, { text: string }> {
  return "text" in block && typeof block.text === "string";
}
