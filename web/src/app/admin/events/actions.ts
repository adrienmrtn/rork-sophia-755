"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { getStudioSession } from "@/lib/studio/account";
import { campaignFromForm, campaignFromRow, hardErrors, languagesMissing, publishProblems, type Campaign, type Known } from "@/lib/studio/campaigns";
import { translateCampaign, translationConfigured } from "@/lib/studio/translate";

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
  return { kind: c.kind, status: c.status, symbol: c.symbol, starts_at: c.starts_at, ends_at: c.ends_at, challenge_target: c.challenge_target, course_ids: c.course_ids, upcoming: c.upcoming, title: c.title, tagline: c.tagline, description: c.description, badge_name: c.badge_name };
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
