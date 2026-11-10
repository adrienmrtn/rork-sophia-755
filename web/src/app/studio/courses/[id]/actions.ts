"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { LANGS } from "@/lib/catalog/types";
import { getStudioSession } from "@/lib/studio/account";
import { MAX_COVER_GENERATIONS, type Hero } from "@/lib/studio/course-format";
import { sanitizeCourse } from "@/lib/studio/sanitize";
import { coversConfigured, generateCoverImages, storeCovers, writeCoverPrompt } from "@/lib/studio/covers";
import { MOCK_STUDIO } from "@/lib/studio/mock";

type SaveResult = { ok: true; updatedAt: string } | { ok: false; error: string };

const MAX_BYTES = 600_000;

/** L'enregistrement automatique de l'éditeur. La règle d'accès ne laisse passer que l'auteur, en draft ou changes_requested. */
export async function saveDraft(id: string, raw: unknown): Promise<SaveResult> {
  const session = await getStudioSession();
  if (!session) return { ok: false, error: "Signed out. Sign in again to keep saving." };
  if (JSON.stringify(raw ?? {}).length > MAX_BYTES) return { ok: false, error: "The course is too large to save (600 KB)." };
  const course = await sanitizeCourse(raw);
  // La langue d'écriture du cours (elle vient du profil à la création, l'auteur peut la changer).
  const lang = typeof (raw as { origin_lang?: unknown })?.origin_lang === "string" ? String((raw as { origin_lang: string }).origin_lang) : null;
  const { data, error } = await session.supabase
    .from("studio_drafts")
    .update({ title: course.title, subtitle: course.subtitle, subject: course.subject, subcategory: course.subcategory, description: course.description, hero: course.hero, sections: course.sections, sources: course.sources, glossary: course.glossary, ...(lang && (LANGS as readonly string[]).includes(lang) ? { origin_lang: lang } : {}) })
    .eq("id", id)
    .eq("user_id", session.user.id)
    .in("status", ["draft", "changes_requested"])
    .select("updated_at")
    .maybeSingle();
  if (error) return { ok: false, error: error.message };
  if (!data) return { ok: false, error: "This course can no longer be edited (it may be in review)." };
  return { ok: true, updatedAt: (data as { updated_at: string }).updated_at };
}

export async function submitDraft(id: string, raw: unknown): Promise<{ ok: true } | { ok: false; error: string }> {
  const saved = await saveDraft(id, raw);
  if (!saved.ok) return saved;
  const session = await getStudioSession();
  if (!session) return { ok: false, error: "Signed out." };
  const { error } = await session.supabase.rpc("studio_submit_draft", { p_id: id });
  if (error) return { ok: false, error: translateDbError(error.message) };
  revalidatePath("/studio");
  revalidatePath("/studio/courses");
  return { ok: true };
}

export async function withdrawAndEdit(form: FormData): Promise<void> {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio");
  const id = String(form.get("id") ?? "");
  const { error } = await session.supabase.rpc("studio_withdraw_draft", { p_id: id });
  revalidatePath("/studio/courses");
  redirect(error ? `/studio/courses/${id}/status?error=${encodeURIComponent(translateDbError(error.message))}` : `/studio/courses/${id}`);
}

/** Les messages des fonctions SQL sont en français ; l'éditeur parle anglais. */
function translateDbError(message: string): string {
  const map: [RegExp, string][] = [
    [/Complétez votre profil/i, "Complete your author profile before sending a course."],
    [/Compte suspendu/i, "Your account is suspended. Contact the team."],
    [/contrat créateur doit être signé/i, "Sign the creator agreement before sending a course."],
    [/cours est incomplet/i, "The course is incomplete: a title and at least two sections."],
    [/pas modifiable/i, "This course is not editable in its current status."],
    [/Brouillon introuvable/i, "Draft not found."],
    [/Seul un cours envoyé/i, "Only a course that is in review and not yet read can be withdrawn."],
  ];
  for (const [re, en] of map) if (re.test(message)) return en;
  return message;
}

type CoversResult = { ok: true; candidates: string[]; prompt: string } | { ok: false; error: string };

/** Trois couvertures 16:9 générées à partir du titre ; l'auteur en choisira une avant l'envoi.
 *  Trois tirages au plus par brouillon. Les candidates sont gardées sur le brouillon. */
export async function generateCovers(id: string, raw: unknown): Promise<CoversResult> {
  const session = await getStudioSession();
  if (!session) return { ok: false, error: "Signed out. Sign in again." };
  const saved = await saveDraft(id, raw);
  if (!saved.ok) return saved;
  const course = await sanitizeCourse(raw);
  if (course.title.trim().length < 3) return { ok: false, error: "Give the course a title first: the cover is drawn from it." };
  const generations = course.hero.generations ?? 0;
  if (generations >= MAX_COVER_GENERATIONS) return { ok: false, error: `You have used the ${MAX_COVER_GENERATIONS} rounds of covers for this course. Pick one of them, or ask the team.` };
  if (MOCK_STUDIO) return { ok: true, candidates: ["/art/poster_histoire.webp", "/art/poster_art.webp", "/art/poster_sciences.webp"], prompt: "Mock prompt" };
  if (!coversConfigured()) return { ok: false, error: "Cover generation is not configured on the server (FAL_KEY)." };
  try {
    const prompt = await writeCoverPrompt({ title: course.title, subject: course.subject, subtitle: course.subtitle, description: course.description });
    const urls = await generateCoverImages(prompt, 3);
    const stored = await storeCovers(id, urls);
    const hero: Hero = { ...course.hero, candidates: [...(course.hero.candidates ?? []), ...stored.map((url) => ({ url }))].slice(-9), generations: generations + 1, prompt };
    await session.supabase.from("studio_drafts").update({ hero }).eq("id", id).eq("user_id", session.user.id).in("status", ["draft", "changes_requested"]);
    return { ok: true, candidates: stored, prompt };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : "Cover generation failed." };
  }
}
