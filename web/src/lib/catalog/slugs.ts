import type { CourseSummary, Subject } from "./types";

/** `course_150_la_nuit_etoilee_van_gogh` → 150 ; null si l'identifiant n'a pas cette forme. */
export function courseNumber(id: string): number | null {
  const m = /^course_(\d+)_/.exec(id);
  return m ? Number(m[1]) : null;
}

/** Une adresse lisible depuis un titre, dans la langue de la page : accents retirés, 60 caractères. */
export function slugify(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60)
    .replace(/-+$/g, "") || "course";
}

/** `/courses/150-why-does-the-sky-in-the-starry-night-swirl` : le numéro identifie, le reste se lit. */
export function coursePath(course: Pick<CourseSummary, "number" | "title">): string {
  return `/courses/${course.number}-${slugify(course.title)}`;
}

/** Le numéro au début d'un paramètre d'adresse (`150-why-does…` → 150), null sinon. */
export function parseCourseParam(param: string): number | null {
  const m = /^(\d+)(?:-|$)/.exec(param);
  return m ? Number(m[1]) : null;
}

export function authorPath(slug: string): string {
  return `/authors/${slug}`;
}

export const SUBJECT_LABEL: Record<Subject, string> = {
  histoire: "History",
  sciences: "Science",
  litterature: "Literature",
  art: "Art",
  mythologie: "Mythology",
  comprendreLeMonde: "Understanding the world",
};

export const SUBJECT_ART: Record<Subject, string> = {
  histoire: "/art/poster_histoire.webp",
  sciences: "/art/poster_sciences.webp",
  litterature: "/art/poster_litterature.webp",
  art: "/art/poster_art.webp",
  mythologie: "/art/poster_mythologie.webp",
  comprendreLeMonde: "/art/poster_monde.webp",
};

export function subjectFromParam(param: string | undefined): Subject | null {
  if (!param) return null;
  const direct = (Object.keys(SUBJECT_LABEL) as Subject[]).find((s) => s === param);
  if (direct) return direct;
  const bySlug = (Object.keys(SUBJECT_LABEL) as Subject[]).find((s) => slugify(SUBJECT_LABEL[s]) === param);
  return bySlug ?? null;
}

export function subjectParam(subject: Subject): string {
  return slugify(SUBJECT_LABEL[subject]);
}
