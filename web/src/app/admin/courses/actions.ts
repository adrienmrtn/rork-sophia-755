"use server";

import { createHash } from "node:crypto";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import sharp from "sharp";
import { LANGS } from "@/lib/catalog/types";
import { STORAGE_PUBLIC } from "@/lib/env";
import { getStudioSession } from "@/lib/studio/account";
import type { DraftCourse } from "@/lib/studio/course-format";
import { sanitizeCourse } from "@/lib/studio/sanitize";
import { createAdminClient } from "@/lib/supabase/admin";

/** L'équipe modifie le catalogue depuis le site : le contenu d'une langue (éditeur du Studio en
 *  mode catalogue), le statut d'une langue, le statut d'un cours, la suppression. Les écritures
 *  passent par les fonctions SQL catalog_admin_* (docs/site-web.md). */

type SaveResult = { ok: true; updatedAt: string } | { ok: false; error: string };

const MAX_BYTES = 600_000;
const COURSE_ID = /^course_[0-9]+_[a-z0-9_]+$/;
const BUCKET_IMAGE = new RegExp(`^${STORAGE_PUBLIC.replace(/[.*+?^${}()|[\]\\/]/g, "\\$&")}/course-images/([a-z0-9][a-z0-9_]{1,120})\\.jpg$`);

async function requireAdmin() {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/admin/courses");
  if (!session.isAdmin) redirect("/studio");
  return session;
}

function back(path: string, params: Record<string, string>): never {
  const qs = new URLSearchParams(params).toString();
  redirect(qs ? `${path}?${qs}` : path);
}

function text(form: FormData, key: string, max = 200): string {
  const v = form.get(key);
  return typeof v === "string" ? v.trim().slice(0, max) : "";
}

function slugBase(courseId: string): string {
  return courseId.replace(/^course_/, "c").replace(/[^a-z0-9_]/g, "_").slice(0, 60);
}

/** Les images choisies dans l'éditeur (adresse Commons) deviennent des objets du bucket, en JPEG
 *  de 1600 px au plus, comme le fait l'usine. Le nom dérive de l'adresse : la même image n'est
 *  téléchargée qu'une fois, même si l'éditeur renvoie encore son adresse à chaque enregistrement. */
async function importImages(course: DraftCourse, courseId: string): Promise<DraftCourse> {
  const needsWork = (course.hero.image_url && !course.hero.image) || course.sections.some((sec) => sec.blocks.some((b) => b.type === "image" && b.image_url && !b.asset));
  if (!needsWork) return course;
  const admin = createAdminClient();
  const base = slugBase(courseId);

  async function store(url: string, kind: string): Promise<string> {
    const already = BUCKET_IMAGE.exec(url);
    if (already) return already[1];
    if (!/^https:\/\//.test(url)) throw new Error("Only https image addresses can be imported.");
    const slug = `${base}_${kind}_${createHash("md5").update(url).digest("hex").slice(0, 10)}`;
    const head = await fetch(`${STORAGE_PUBLIC}/course-images/${slug}.jpg`, { method: "HEAD", cache: "no-store" }).catch(() => null);
    if (head?.ok) return slug;
    const res = await fetch(url, { cache: "no-store", headers: { "User-Agent": "SophiaStudio/1.0 (https://sophia-culture.com; hello@sophia-culture.com)" } });
    if (!res.ok) throw new Error(`Could not download the image (${res.status}).`);
    const input = Buffer.from(await res.arrayBuffer());
    const jpeg = await sharp(input).rotate().resize({ width: 1600, withoutEnlargement: true }).jpeg({ quality: 85, mozjpeg: true }).toBuffer();
    const { error } = await admin.storage.from("course-images").upload(`${slug}.jpg`, jpeg, { contentType: "image/jpeg", upsert: true, cacheControl: "86400" });
    if (error) throw new Error(`Could not store the image: ${error.message}`);
    return slug;
  }

  let hero = course.hero;
  if (hero.image_url && !hero.image) {
    const slug = await store(hero.image_url, "cover");
    hero = { ...hero, image: slug, image_url: undefined };
  }
  const sections = await Promise.all(
    course.sections.map(async (sec) => ({
      ...sec,
      blocks: await Promise.all(
        sec.blocks.map(async (b) => {
          if (b.type !== "image" || !b.image_url || b.asset) return b;
          const slug = await store(b.image_url, "img");
          const next = { ...b, asset: slug };
          delete next.image_url;
          return next;
        }),
      ),
    })),
  );
  return { ...course, hero, sections };
}

/** L'enregistrement automatique de l'éditeur en mode catalogue, et « Publish changes ». */
export async function saveCatalogContent(courseId: string, lang: string, raw: unknown): Promise<SaveResult> {
  const session = await getStudioSession();
  if (!session?.isAdmin) return { ok: false, error: "Signed out, or not on the team. Sign in again." };
  if (!COURSE_ID.test(courseId) || !(LANGS as readonly string[]).includes(lang)) return { ok: false, error: "Unknown course or language." };
  if (JSON.stringify(raw ?? {}).length > MAX_BYTES) return { ok: false, error: "The course is too large to save (600 KB)." };
  let course = await sanitizeCourse(raw);
  try {
    course = await importImages(course, courseId);
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : "Image import failed." };
  }
  const glossary: Record<string, unknown> = {};
  for (const g of course.glossary) {
    const term = g.term.trim();
    if (term) glossary[term] = { displayTerm: term, classification: g.classification, explanation: g.explanation };
  }
  const { data, error } = await session.supabase.rpc("catalog_admin_update_content", { p_course_id: courseId, p_lang: lang, p_course: { ...course, id: courseId }, p_glossary: glossary });
  if (error) return { ok: false, error: error.message };
  revalidatePath(`/admin/courses/${courseId}`);
  revalidatePath("/admin/courses");
  revalidatePath("/courses");
  const out = (data ?? {}) as { updated_at?: string };
  return { ok: true, updatedAt: out.updated_at ?? new Date().toISOString() };
}

/** Retirer une langue des apps, ou la remettre. */
export async function setContentStatus(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const courseId = text(form, "course_id", 160);
  const lang = text(form, "lang", 8);
  const status = text(form, "status", 20);
  const { error } = await session.supabase.rpc("catalog_admin_set_content_status", { p_course_id: courseId, p_lang: lang, p_status: status });
  revalidatePath(`/admin/courses/${courseId}`);
  revalidatePath("/admin/courses");
  if (error) back(`/admin/courses/${courseId}`, { error: error.message });
  back(`/admin/courses/${courseId}`, { done: `${lang}-${status}` });
}

/** Archiver un cours (hors des apps, rien de perdu) ou le remettre en ligne. */
export async function setCourseStatus(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const courseId = text(form, "course_id", 160);
  const status = text(form, "status", 20);
  const { error } = await session.supabase.rpc("catalog_admin_set_course_status", { p_course_id: courseId, p_status: status });
  revalidatePath(`/admin/courses/${courseId}`);
  revalidatePath("/admin/courses");
  revalidatePath("/courses");
  if (error) back(`/admin/courses/${courseId}`, { error: error.message });
  back(`/admin/courses/${courseId}`, { done: status });
}

/** Supprimer un cours pour de bon. L'identifiant doit être retapé dans le formulaire. */
export async function deleteCourse(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const courseId = text(form, "course_id", 160);
  const confirm = text(form, "confirm", 160);
  if (confirm !== courseId) back(`/admin/courses/${courseId}`, { error: "Type the course identifier exactly to confirm the deletion." });
  const { data, error } = await session.supabase.rpc("catalog_admin_delete_course", { p_course_id: courseId });
  revalidatePath("/admin/courses");
  revalidatePath("/admin");
  revalidatePath("/courses");
  if (error) back(`/admin/courses/${courseId}`, { error: error.message });
  back("/admin/courses", { done: `deleted:${String(data ?? courseId)}` });
}
