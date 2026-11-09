"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { STORAGE_PUBLIC } from "@/lib/env";
import { createAdminClient } from "@/lib/supabase/admin";
import { getStudioSession } from "@/lib/studio/account";
import { campaignFromForm, campaignFromRow, hardErrors, languagesMissing, localized, publishProblems, type Campaign, type Known } from "@/lib/studio/campaigns";
import { coversConfigured, generateCoverImages, generatePosterImage, storeImageAt, writeCoverPrompt, writePosterScene } from "@/lib/studio/covers";
import { translateCampaign, translationConfigured } from "@/lib/studio/translate";

const IMAGE_TYPES: Record<string, string> = { "image/jpeg": "jpg", "image/png": "png", "image/webp": "webp" };
const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

/** Les événements éditoriaux : création, enregistrement, traduction, suppression. Tout passe par
 *  la session de l'admin (la règle d'accès de la table n'accepte que studio_admins). */

async function requireAdmin() {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/admin/events");
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

async function loadKnown(supabase: Awaited<ReturnType<typeof requireAdmin>>["supabase"]): Promise<Known> {
  const [{ data: courses }, { data: creators }] = await Promise.all([supabase.from("courses").select("id").eq("status", "published"), supabase.from("creators").select("slug")]);
  return {
    courseIds: new Set(((courses ?? []) as { id: string }[]).map((c) => c.id)),
    creatorSlugs: new Set(((creators ?? []) as { slug: string }[]).map((c) => c.slug)),
  };
}

function toRow(c: Campaign) {
  return { kind: c.kind, status: c.status, symbol: c.symbol, image_url: c.image_url, starts_at: c.starts_at, ends_at: c.ends_at, challenge_target: c.challenge_target, goal_target: c.goal_target, course_ids: c.course_ids, upcoming: c.upcoming, title: c.title, tagline: c.tagline, description: c.description, badge_name: c.badge_name };
}

/** L'image envoyée par le formulaire, copiée dans le bucket public course-images sous events/.
 *  Un nom horodaté à chaque fois : les apps gardent l'ancienne adresse en cache. */
async function uploadEventImage(slug: string, file: File): Promise<string> {
  const ext = IMAGE_TYPES[file.type];
  if (!ext) throw new Error("The image must be a JPEG, PNG or WebP file.");
  if (file.size > MAX_IMAGE_BYTES) throw new Error("The image is too large (6 MB max).");
  const admin = createAdminClient();
  const path = `events/${slug}_${Date.now().toString(36)}.${ext}`;
  const { error } = await admin.storage.from("course-images").upload(path, new Uint8Array(await file.arrayBuffer()), { contentType: file.type, upsert: true, cacheControl: "31536000" });
  if (error) throw new Error(`Could not store the image: ${error.message}`);
  return `${STORAGE_PUBLIC}/course-images/${path}`;
}

function revalidate(slug: string) {
  revalidatePath("/admin/events");
  revalidatePath(`/admin/events/${slug}`);
  revalidatePath("/admin");
}

/** Enregistre l'événement. Un brouillon s'enregistre toujours ; la publication exige que la
 *  liste de contrôle soit vide, sinon l'événement reste dans son statut précédent. */
export async function saveCampaign(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const existingSlug = text(form, "existing_slug", 60);
  let existing: Campaign | null = null;
  if (existingSlug) {
    const { data } = await session.supabase.from("campaigns").select("*").eq("slug", existingSlug).maybeSingle();
    if (!data) back("/admin/events", { error: "This event no longer exists." });
    existing = campaignFromRow(data as Record<string, unknown>);
  }
  const campaign = campaignFromForm(form, existing);
  const errors = hardErrors(campaign);
  if (errors.length > 0) back(existing ? `/admin/events/${existing.slug}` : "/admin/events/new", { error: errors.join(" ") });

  // L'image : retirée, ou remplacée par le fichier envoyé (jamais dans un try qui avalerait la redirection).
  if (form.get("remove_image") === "on") campaign.image_url = null;
  const upload = form.get("image");
  if (upload instanceof File && upload.size > 0) {
    let uploaded: string | null = null;
    let failure: string | null = null;
    try {
      uploaded = await uploadEventImage(campaign.slug, upload);
    } catch (e) {
      failure = e instanceof Error ? e.message : "Image upload failed.";
    }
    if (failure || !uploaded) back(existing ? `/admin/events/${existing.slug}` : "/admin/events/new", { error: failure ?? "Image upload failed." });
    campaign.image_url = uploaded;
  }

  let note = "saved";
  if (campaign.status === "published") {
    const problems = publishProblems(campaign, await loadKnown(session.supabase));
    if (problems.length > 0) {
      // Enregistré quand même, en brouillon, pour ne rien perdre ; la page montre ce qui manque.
      const wasLive = existing?.status === "published";
      campaign.status = "draft";
      const { error } = existing ? await session.supabase.from("campaigns").update(toRow(campaign)).eq("slug", existing.slug) : await session.supabase.from("campaigns").insert({ slug: campaign.slug, created_by: session.user.id, ...toRow(campaign) });
      revalidate(campaign.slug);
      if (error) back(existing ? `/admin/events/${existing.slug}` : "/admin/events/new", { error: error.message });
      back(`/admin/events/${campaign.slug}`, { error: `${wasLive ? "Saved and taken offline (draft)" : "Saved as a draft"}, not published: ${problems.join(" ")}` });
    }
    note = "published";
  }

  const { error } = existing ? await session.supabase.from("campaigns").update(toRow(campaign)).eq("slug", existing.slug) : await session.supabase.from("campaigns").insert({ slug: campaign.slug, created_by: session.user.id, ...toRow(campaign) });
  revalidate(campaign.slug);
  if (error) {
    const message = error.code === "23505" ? `An event with the slug “${campaign.slug}” already exists.` : error.message;
    back(existing ? `/admin/events/${existing.slug}` : "/admin/events/new", { error: message });
  }
  back(`/admin/events/${campaign.slug}`, { done: note });
}

/** Traduit les textes dans les langues qui manquent (jamais par-dessus une langue remplie). */
export async function translateCampaignAction(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  if (!translationConfigured()) back(`/admin/events/${slug}`, { error: "Translation is not configured on the server (FAL_KEY)." });
  const campaign = campaignFromRow(data as Record<string, unknown>);
  if (!campaign.title.en?.trim() && !campaign.title.fr?.trim()) back(`/admin/events/${slug}`, { error: "Write the English texts first, then translate." });
  const targets = languagesMissing(campaign).filter((l) => l !== "en" && l !== "fr");
  if (targets.length === 0) back(`/admin/events/${slug}`, { done: "translated-none" });
  try {
    const { fields, added } = await translateCampaign(campaign, targets);
    const { error } = await session.supabase.from("campaigns").update(fields).eq("slug", slug);
    revalidate(slug);
    if (error) back(`/admin/events/${slug}`, { error: error.message });
    back(`/admin/events/${slug}`, { done: `translated-${added.length}` });
  } catch (e) {
    if (e && typeof e === "object" && "digest" in e) throw e; // redirect()
    back(`/admin/events/${slug}`, { error: e instanceof Error ? e.message : "Translation failed." });
  }
}

/** Deux images 16:9 à partir du titre et de l'accroche, en parallèle : l'une dans la direction
 *  artistique des couvertures de cours (Gemini), l'autre dans celle des illustrations du site
 *  (Recraft, papier découpé). Les deux rejoignent les candidates ; la première devient l'image
 *  de l'événement s'il n'en a pas encore. Chaque échec est journalisé et montré tel quel. */
export async function generateEventImage(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  if (!coversConfigured()) back(`/admin/events/${slug}`, { error: "Image generation is not configured on the server (FAL_KEY)." });
  const campaign = campaignFromRow(data as Record<string, unknown>);
  const title = localized(campaign.title, "en");
  if (!title) back(`/admin/events/${slug}`, { error: "Write the title first: the images are drawn from it." });
  const theme = { title, subtitle: localized(campaign.tagline, "en") || null, description: localized(campaign.description, "en") || null };
  const stamp = Date.now().toString(36);

  const coverJob = (async () => {
    const prompt = await writeCoverPrompt({ ...theme, subject: null });
    const [generated] = await generateCoverImages(prompt, 1);
    return storeImageAt(`events/${slug}_cover_${stamp}.jpg`, generated, "image/jpeg");
  })();
  const posterJob = (async () => {
    const scene = await writePosterScene(theme);
    const image = await generatePosterImage(scene);
    const ext = image.contentType.includes("png") ? "png" : image.contentType.includes("jpeg") ? "jpg" : "webp";
    return storeImageAt(`events/${slug}_poster_${stamp}.${ext}`, image.url, image.contentType);
  })();
  const [cover, poster] = await Promise.allSettled([coverJob, posterJob]);
  const failures: string[] = [];
  const created: { url: string; style: "cover" | "poster"; created_at: string }[] = [];
  const now = new Date().toISOString();
  if (cover.status === "fulfilled") created.push({ url: cover.value, style: "cover", created_at: now });
  else {
    console.error("[events] cover-style image failed", slug, cover.reason);
    failures.push(`Cover style: ${cover.reason instanceof Error ? cover.reason.message : String(cover.reason)}`);
  }
  if (poster.status === "fulfilled") created.push({ url: poster.value, style: "poster", created_at: now });
  else {
    console.error("[events] poster-style image failed", slug, poster.reason);
    failures.push(`Poster style: ${poster.reason instanceof Error ? poster.reason.message : String(poster.reason)}`);
  }
  if (created.length === 0) back(`/admin/events/${slug}`, { error: `No image could be generated. ${failures.join(" · ")}` });

  const candidates = [...created, ...campaign.image_candidates].slice(0, 8);
  const { error } = await session.supabase.from("campaigns").update({ image_candidates: candidates, ...(campaign.image_url ? {} : { image_url: created[0].url }) }).eq("slug", slug);
  revalidate(slug);
  if (error) back(`/admin/events/${slug}`, { error: error.message });
  back(`/admin/events/${slug}`, failures.length > 0 ? { error: `One image generated, one failed. ${failures.join(" ")}`, done: "image" } : { done: "image" });
}

/** L'équipe retient une des images générées (ou remet l'image envoyée à la main). */
export async function chooseEventImage(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const url = text(form, "url", 1000);
  const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  const campaign = campaignFromRow(data as Record<string, unknown>);
  if (!campaign.image_candidates.some((c) => c.url === url)) back(`/admin/events/${slug}`, { error: "This image is not one of the event's candidates." });
  const { error } = await session.supabase.from("campaigns").update({ image_url: url }).eq("slug", slug);
  revalidate(slug);
  if (error) back(`/admin/events/${slug}`, { error: error.message });
  back(`/admin/events/${slug}`, { done: "saved" });
}

/** Supprime un brouillon ou un événement archivé. Un événement publié s'archive d'abord. */
export async function deleteCampaign(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const { data } = await session.supabase.from("campaigns").select("status").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  if ((data as { status: string }).status === "published") back(`/admin/events/${slug}`, { error: "Archive the event before deleting it: readers may still hold its badge." });
  const { error } = await session.supabase.from("campaigns").delete().eq("slug", slug);
  revalidate(slug);
  if (error) back(`/admin/events/${slug}`, { error: error.message });
  back("/admin/events", { done: "deleted" });
}
