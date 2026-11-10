"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { STORAGE_PUBLIC } from "@/lib/env";
import { createAdminClient } from "@/lib/supabase/admin";
import { getStudioSession } from "@/lib/studio/account";
import { campaignFromForm, campaignFromRow, hardErrors, languagesMissing, localized, publishProblems, type Campaign, type Known } from "@/lib/studio/campaigns";
import { coversConfigured, generateBadgeImage, generateCoverImages, generatePosterImage, storeImageAt, writeBadgeEmblems, writeCoverPrompt, writePosterScene } from "@/lib/studio/covers";
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
  const { data: courses } = await supabase.from("courses").select("id").eq("status", "published");
  return { courseIds: new Set(((courses ?? []) as { id: string }[]).map((c) => c.id)) };
}

/** Les colonnes enregistrées. `upcoming` (les cours annoncés « en écriture ») n'existe plus dans
 *  le produit : la colonne reste en base (non nulle), on y remet toujours une liste vide. */
function toRow(c: Campaign) {
  return { kind: c.kind, status: c.status, symbol: c.symbol, image_url: c.image_url, starts_at: c.starts_at, ends_at: c.ends_at, challenge_target: c.challenge_target, goal_target: c.goal_target, course_ids: c.course_ids, upcoming: [], title: c.title, tagline: c.tagline, description: c.description, badge_name: c.badge_name };
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
  if (text(form, "intent", 20) === "generate") {
    // Le bouton de la carte Image : l'événement est enregistré (ou créé), puis les deux images sont dessinées.
    const { data: saved } = await session.supabase.from("campaigns").select("*").eq("slug", campaign.slug).maybeSingle();
    const outcome = saved ? await generateImagesFor(session, campaignFromRow(saved as Record<string, unknown>)) : { error: "Saved, but the event could not be read back." };
    back(`/admin/events/${campaign.slug}`, outcome.error ? { ...outcome, error: `Saved. ${outcome.error}` } : outcome);
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
  if (!campaign.title.en?.trim()) back(`/admin/events/${slug}`, { error: "Write the English texts first, then translate." });
  const targets = languagesMissing(campaign).filter((l) => l !== "en");
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
/** Deux images 16:9 depuis le titre et l'accroche en anglais : une dans la direction artistique
 *  des couvertures, une dans le style papier découpé du site. Rend les paramètres de la redirection. */
async function generateImagesFor(session: Awaited<ReturnType<typeof requireAdmin>>, campaign: Campaign): Promise<Record<string, string>> {
  const slug = campaign.slug;
  const title = localized(campaign.title, "en");
  if (!coversConfigured()) return { error: "Image generation is not configured on the server (FAL_KEY)." };
  if (!title) return { error: "Write the English title first: the images are drawn from it." };
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
  if (created.length === 0) return { error: `No image could be generated. ${failures.join(" · ")}` };

  const candidates = [...created, ...campaign.image_candidates].slice(0, 8);
  const { error } = await session.supabase.from("campaigns").update({ image_candidates: candidates, ...(campaign.image_url ? {} : { image_url: created[0].url }) }).eq("slug", slug);
  revalidate(slug);
  if (error) return { error: error.message };
  return failures.length > 0 ? { error: `One image generated, one failed. ${failures.join(" ")}`, done: "image" } : { done: "image" };
}

/** Le bouton « Generate 2 images with AI » d'un événement déjà enregistré (formulaire séparé). */
export async function generateEventImage(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  back(`/admin/events/${slug}`, await generateImagesFor(session, campaignFromRow(data as Record<string, unknown>)));
}

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

/** Le bouton « Generate 3 badges with AI » : trois emblèmes en papier découpé (carrés), dessinés
 *  depuis le titre, l'accroche et le nom du badge en anglais. Ils rejoignent les propositions ;
 *  le premier devient le badge de l'événement s'il n'en a pas encore. */
export async function generateEventBadge(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  const campaign = campaignFromRow(data as Record<string, unknown>);
  const title = localized(campaign.title, "en");
  if (!coversConfigured()) back(`/admin/events/${slug}`, { error: "Image generation is not configured on the server (FAL_KEY)." });
  if (!title) back(`/admin/events/${slug}`, { error: "Write the English title first: the badge is drawn from it." });

  let outcome: Record<string, string>;
  try {
    const emblems = await writeBadgeEmblems({ title, badge: localized(campaign.badge_name, "en") || null, subtitle: localized(campaign.tagline, "en") || null, description: localized(campaign.description, "en") || null });
    const stamp = Date.now().toString(36);
    const results = await Promise.allSettled(
      emblems.map(async (emblem, i) => {
        const image = await generateBadgeImage(emblem);
        const ext = image.contentType.includes("png") ? "png" : image.contentType.includes("jpeg") ? "jpg" : "webp";
        return storeImageAt(`events/badges/${slug}_${stamp}_${i + 1}.${ext}`, image.url, image.contentType);
      }),
    );
    const now = new Date().toISOString();
    const created = results.flatMap((r) => (r.status === "fulfilled" ? [{ url: r.value, created_at: now }] : []));
    const failed = results.filter((r) => r.status === "rejected") as PromiseRejectedResult[];
    for (const f of failed) console.error("[events] badge image failed", slug, f.reason);
    if (created.length === 0) {
      outcome = { error: `No badge could be generated. ${failed.map((f) => (f.reason instanceof Error ? f.reason.message : String(f.reason))).join(" · ")}` };
    } else {
      const candidates = [...created, ...campaign.badge_candidates].slice(0, 9);
      const { error } = await session.supabase.from("campaigns").update({ badge_candidates: candidates, ...(campaign.badge_image_url ? {} : { badge_image_url: created[0].url }) }).eq("slug", slug);
      revalidate(slug);
      outcome = error ? { error: error.message } : failed.length > 0 ? { error: `${created.length} of 3 badges generated.`, done: "badge" } : { done: "badge" };
    }
  } catch (e) {
    console.error("[events] badge generation failed", slug, e);
    outcome = { error: e instanceof Error ? e.message : "Badge generation failed." };
  }
  back(`/admin/events/${slug}`, outcome);
}

/** « Use this badge » : une des propositions devient le badge de l'événement. */
export async function chooseEventBadge(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const url = text(form, "url", 1000);
  const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  const campaign = campaignFromRow(data as Record<string, unknown>);
  if (!campaign.badge_candidates.some((c) => c.url === url)) back(`/admin/events/${slug}`, { error: "This image is not one of the event's badge candidates." });
  const { error } = await session.supabase.from("campaigns").update({ badge_image_url: url }).eq("slug", slug);
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

/** Publier, dépublier, archiver ou remettre en brouillon : le statut seul change, avec les textes
 *  déjà enregistrés. Publier exige une liste de contrôle vide (textes en anglais, collection…). */
export async function setCampaignStatus(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const slug = text(form, "slug", 60);
  const status = text(form, "status", 20);
  if (!["draft", "published", "archived"].includes(status)) back(`/admin/events/${slug}`, { error: "Unknown status." });
  const { data } = await session.supabase.from("campaigns").select("*").eq("slug", slug).maybeSingle();
  if (!data) back("/admin/events", { error: "This event no longer exists." });
  const campaign = campaignFromRow(data as Record<string, unknown>);
  if (status === "published") {
    const problems = publishProblems(campaign, await loadKnown(session.supabase));
    if (problems.length > 0) back(`/admin/events/${slug}`, { error: `Not published yet: ${problems.join(" ")}` });
  }
  const { error } = await session.supabase.from("campaigns").update({ status }).eq("slug", slug);
  revalidate(slug);
  if (error) back(`/admin/events/${slug}`, { error: error.message });
  back(`/admin/events/${slug}`, { done: status === "published" ? "published" : status === "archived" ? "archived" : campaign.status === "archived" ? "restored" : "unpublished" });
}
