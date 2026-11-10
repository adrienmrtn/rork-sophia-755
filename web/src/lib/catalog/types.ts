/** Le catalogue tel que le site le lit : les mêmes données que les apps (docs/catalogue-en-ligne.md). */

export const SUBJECTS = ["histoire", "sciences", "litterature", "art", "mythologie", "comprendreLeMonde"] as const;
export type Subject = (typeof SUBJECTS)[number];

export const LANGS = [
  "fr", "en", "es", "de", "pt", "pt-PT", "it", "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg",
  "cs", "da", "nb", "ru", "hr", "sl", "sk", "sr", "ar", "he", "fi", "et", "lt", "lv", "ja",
] as const;
export type Lang = (typeof LANGS)[number];

export type Credit = { title?: string; author?: string; license?: string; source?: string };

export type Block =
  | { type: "paragraph"; text: string }
  | { type: "heading"; text: string }
  | { type: "image"; asset?: string; image_url?: string; caption?: string; credit?: Credit; fullBleed?: boolean; ratio?: string }
  | { type: "timeline"; events: { date: string; title: string; detail?: string }[] }
  | { type: "funFact"; text: string }
  | { type: "takeaway"; text: string }
  | { type: "quote"; text: string; attribution?: string };

export type Section = { id?: string; title: string; free?: boolean; blocks: Block[] };

export type GlossaryEntry = { term: string; classification: string; explanation: string };
export type Source = { text: string; url?: string };

export interface CourseSummary {
  id: string;
  /** Le numéro du cours, celui de l'adresse publique : course_150_… → 150. */
  number: number;
  title: string;
  subtitle: string | null;
  description: string;
  hook: string | null;
  subject: Subject;
  subcategory: string | null;
  creatorSlug: string | null;
  coverUrl: string | null;
  sectionCount: number;
  quizCount: number;
  /** Durée de lecture estimée, en minutes. */
  minutes: number;
}

export interface CourseDetail extends CourseSummary {
  sections: Section[];
  glossary: GlossaryEntry[];
  sources: Source[];
  /** Crédit des images du cours, par slug de ressource. */
  credits: Record<string, Credit>;
  /** Les langues dans lesquelles le cours est publié. */
  languages: string[];
}

export interface Creator {
  slug: string;
  name: string;
  photoUrl: string | null;
  institution: string | null;
  country: string | null;
  title: string | null;
  bio: string | null;
  verified: boolean;
  links: Record<string, string>;
  courseIds: string[];
}

export interface CatalogSource {
  listCourses(lang: Lang): Promise<CourseSummary[]>;
  getCourse(lang: Lang, number: number): Promise<CourseDetail | null>;
  listCreators(lang: Lang): Promise<Creator[]>;
  getCreator(lang: Lang, slug: string): Promise<Creator | null>;
}
