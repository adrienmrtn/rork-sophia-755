import { SUBJECTS, type CourseSummary, type Creator, type Subject } from "./types";

/** Les cours mis en avant : une couverture, un titre-question, une matière différente à chaque fois. */
export function featuredCourses(list: CourseSummary[], n = 4): CourseSummary[] {
  const out: CourseSummary[] = [];
  const seen = new Set<Subject>();
  const sorted = [...list].sort((a, b) => b.number - a.number);
  for (const c of sorted) {
    if (!c.coverUrl || !c.title.trim().endsWith("?") || seen.has(c.subject)) continue;
    seen.add(c.subject);
    out.push(c);
    if (out.length === n) break;
  }
  for (const c of sorted) {
    if (out.length === n) break;
    if (!out.includes(c) && c.coverUrl) out.push(c);
  }
  return out;
}

export function subjectCounts(list: CourseSummary[]): Record<Subject, number> {
  const counts = Object.fromEntries(SUBJECTS.map((s) => [s, 0])) as Record<Subject, number>;
  for (const c of list) counts[c.subject] = (counts[c.subject] ?? 0) + 1;
  return counts;
}

/** Deux titres-questions d'exemple par matière. */
export function sampleTitles(list: CourseSummary[], subject: Subject, n = 2): string[] {
  return list
    .filter((c) => c.subject === subject && c.title.trim().endsWith("?"))
    .slice(0, n)
    .map((c) => c.title);
}

export function creatorsWithPhoto(creators: Creator[], n = 8): Creator[] {
  return [...creators].filter((c) => c.photoUrl && c.courseIds.length).sort((a, b) => b.courseIds.length - a.courseIds.length).slice(0, n);
}

export function creatorMap(creators: Creator[]): Map<string, Creator> {
  return new Map(creators.map((c) => [c.slug, c]));
}
