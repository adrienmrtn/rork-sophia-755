import { notFound, redirect } from "next/navigation";
import { CourseEditor } from "@/components/studio/CourseEditor";
import { LANGS, type GlossaryEntry, type Section, type Source } from "@/lib/catalog/types";
import { getStudioSession } from "@/lib/studio/account";
import type { DraftCourse, Hero } from "@/lib/studio/course-format";

export const dynamic = "force-dynamic";
/** Les imports d'images Commons à l'enregistrement peuvent prendre quelques secondes chacun. */
export const maxDuration = 60;

interface ContentRow {
  course_id: string;
  lang: string;
  status: string;
  title: string;
  subtitle: string | null;
  description: string;
  subcategory: string | null;
  hook: string | null;
  content: Record<string, unknown> | null;
  updated_at: string;
}

/** L'éditeur du Studio, branché sur le contenu publié d'un cours dans une langue. Même format,
 *  mêmes vérifications ; « Publish changes » écrit la langue et recalcule ses hash. */
export default async function AdminCourseLanguagePage({ params }: PageProps<"/admin/courses/[courseId]/[lang]">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const { courseId: rawId, lang } = await params;
  const courseId = decodeURIComponent(rawId);
  if (!(LANGS as readonly string[]).includes(lang)) notFound();
  const { supabase } = session;
  const [{ data: courseRow }, { data: contentRow }, { data: glossaryRows }] = await Promise.all([
    supabase.from("courses").select("id,subject").eq("id", courseId).maybeSingle(),
    supabase.from("course_contents").select("course_id,lang,status,title,subtitle,description,subcategory,hook,content,updated_at").eq("course_id", courseId).eq("lang", lang).maybeSingle(),
    supabase.from("glossary_entries").select("term,display_term,classification,explanation").eq("course_id", courseId).eq("lang", lang).order("term"),
  ]);
  const course = (courseRow as { id: string; subject: string | null } | null) ?? null;
  const row = (contentRow as ContentRow | null) ?? null;
  if (!course || !row) notFound();
  const content = row.content ?? {};
  const heroRaw = (content.hero && typeof content.hero === "object" ? content.hero : {}) as Record<string, unknown>;
  const hero: Hero = {
    ...(typeof heroRaw.image === "string" && heroRaw.image ? { image: heroRaw.image } : {}),
    ...(typeof heroRaw.image_url === "string" && heroRaw.image_url ? { image_url: heroRaw.image_url } : {}),
    ratio: typeof heroRaw.ratio === "string" && heroRaw.ratio ? heroRaw.ratio : "16:9",
    ...(row.hook ? { hook: row.hook } : typeof heroRaw.hook === "string" && heroRaw.hook ? { hook: heroRaw.hook } : {}),
    ...(heroRaw.credit && typeof heroRaw.credit === "object" ? { credit: heroRaw.credit as Hero["credit"] } : {}),
  };
  const initial: DraftCourse = {
    title: row.title ?? "",
    subtitle: row.subtitle ?? null,
    subject: (typeof content.subject === "string" ? content.subject : course.subject) ?? null,
    subcategory: row.subcategory || null,
    description: row.description ?? "",
    hero,
    sections: (Array.isArray(content.sections) ? (content.sections as Section[]) : []).map((s, i) => ({ ...s, free: i === 0 || Boolean(s.free), blocks: Array.isArray(s.blocks) ? s.blocks : [] })),
    sources: Array.isArray(content.sources) ? (content.sources as Source[]) : [],
    glossary: ((glossaryRows ?? []) as { term: string; display_term: string | null; classification: string; explanation: string }[]).map<GlossaryEntry>((g) => ({ term: g.display_term || g.term, classification: g.classification, explanation: g.explanation })),
  };

  return <CourseEditor draftId={`${courseId}:${lang}`} initial={initial} status="published" reviewComment={null} updatedAt={row.updated_at} originLang={lang} blockers={[]} onboardingHref={null} catalog={{ kind: "catalog", courseId, lang }} />;
}
