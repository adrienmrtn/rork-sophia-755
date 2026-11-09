import "server-only";
import fs from "node:fs";
import path from "node:path";
import catalog from "@/data/catalog.json";

/** Accès au catalogue complet. Réservé aux pages générées au build : rien de ce fichier n'est envoyé au navigateur. */

export type Course = (typeof catalog.courses)[number];
export type Creator = (typeof catalog.creators)[number];
export type Collection = (typeof catalog.collections)[number];
export type Subject = (typeof catalog.subjects)[number];

export type CourseBody = {
  intro: { type: "paragraph" | "funFact"; text: string }[];
  sections: string[];
  teaser: string;
  quiz: { question: string; options: string[]; correctIndex: number; explanation: string } | null;
};

export const stats = catalog.stats;
export const universities = catalog.universities;
export const courses = catalog.courses;
export const creators = catalog.creators;
export const collections = catalog.collections;
export const subjects = catalog.subjects;

const courseBySlug = new Map(courses.map((c) => [c.slug, c]));
const creatorBySlug = new Map(creators.map((c) => [c.slug, c]));
const collectionBySlug = new Map(collections.map((c) => [c.slug, c]));

export const getCourse = (slug: string) => courseBySlug.get(slug);
export const getCreator = (slug: string) => creatorBySlug.get(slug);
export const getCollection = (slug: string) => collectionBySlug.get(slug);
export const getSubject = (slug: string) => subjects.find((s) => s.slug === slug);

export function getCourseBody(slug: string): CourseBody {
  const file = path.join(process.cwd(), "src/data/courses", `${slug}.json`);
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

export const coursesOf = (slugs: string[]) => slugs.map((s) => courseBySlug.get(s)).filter((c): c is Course => Boolean(c));

/** Les auteurs invités (hors rédaction), ceux avec photo d'abord. */
export const guestCreators = creators
  .filter((c) => c.slug !== "redaction")
  .sort((a, b) => Number(Boolean(b.photo)) - Number(Boolean(a.photo)) || b.courses.length - a.courses.length);

export const featured = coursesOf(catalog.featured);

/** Carte de cours prête à afficher, avec son auteur. Sûre à passer aux composants client. */
export function toCard(c: Course) {
  const a = creatorBySlug.get(c.author)!;
  return {
    slug: c.slug,
    title: c.title,
    hook: c.hook,
    subtitle: c.subtitle,
    image: c.image,
    subject: c.subjectLabel,
    subjectSlug: c.subject,
    quizCount: c.quizCount,
    author: { slug: a.slug, name: a.name, title: a.title, photo: a.photo },
  };
}
export type CourseCard = ReturnType<typeof toCard>;

/** Cours mis en avant dans le fil : d'abord ceux signés par un auteur invité, puis la rédaction. */
export function feedFor(subjectSlug?: string, limit = 10) {
  const pool = subjectSlug ? courses.filter((c) => c.subject === subjectSlug) : courses;
  const signed = pool.filter((c) => c.author !== "redaction");
  const house = pool.filter((c) => c.author === "redaction");
  const out: Course[] = [];
  let i = 0;
  let j = 0;
  while (out.length < limit && (i < signed.length || j < house.length)) {
    if (i < signed.length) out.push(signed[i++]);
    if (out.length < limit && j < house.length) out.push(house[j++ * 7 % house.length]);
  }
  return [...new Map(out.map((c) => [c.slug, c])).values()].slice(0, limit);
}
