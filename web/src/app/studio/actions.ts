"use server";

import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { headers } from "next/headers";
import { getStudioSession, slugFromName, type OnboardingStep } from "@/lib/studio/account";
import { LANGS } from "@/lib/catalog/types";
import { avatarUrl, isAvatarName } from "@/lib/studio/avatars";

type ActionResult = { ok: true } | { ok: false; error: string };

function text(form: FormData, key: string, max = 400): string {
  const v = form.get(key);
  return typeof v === "string" ? v.trim().slice(0, max) : "";
}

async function requireSession() {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio");
  return session;
}

/** Avance le parcours d'accueil d'un cran, sans jamais revenir en arrière. */
function advance(current: OnboardingStep | undefined, done: OnboardingStep, next: OnboardingStep): OnboardingStep {
  const order: OnboardingStep[] = ["identity", "credentials", "profile", "agreement", "guide", "done"];
  if (!current) return next;
  return order.indexOf(current) <= order.indexOf(done) ? next : current;
}

export async function saveIdentity(form: FormData): Promise<void> {
  const { supabase, user, account } = await requireSession();
  const first = text(form, "first_name", 80);
  const last = text(form, "last_name", 80);
  const display = text(form, "display_name", 120) || `${first} ${last}`.trim();
  const lang = text(form, "writing_lang", 8);
  if (!first || !last) redirect("/studio/onboarding/identity?error=name");
  if (!(LANGS as readonly string[]).includes(lang)) redirect("/studio/onboarding/identity?error=lang");
  const slug = account?.slug ?? slugFromName(first, last);
  const row = {
    user_id: user.id,
    first_name: first,
    last_name: last,
    display_name: display,
    email: user.email ?? null,
    writing_lang: lang,
    slug,
    onboarding_step: advance(account?.onboarding_step, "identity", "credentials"),
  };
  const { error } = account ? await supabase.from("creator_accounts").update(row).eq("user_id", user.id) : await supabase.from("creator_accounts").insert(row);
  if (error) {
    // Slug déjà pris : on suffixe.
    if (error.code === "23505" && !account) {
      const { error: retry } = await supabase.from("creator_accounts").insert({ ...row, slug: `${slug}-${Math.random().toString(36).slice(2, 6)}` });
      if (retry) redirect(`/studio/onboarding/identity?error=${encodeURIComponent(retry.message)}`);
    } else redirect(`/studio/onboarding/identity?error=${encodeURIComponent(error.message)}`);
  }
  revalidatePath("/studio");
  redirect("/studio/onboarding/credentials");
}

export async function saveCredentials(form: FormData): Promise<void> {
  const { supabase, user, account } = await requireSession();
  if (!account) redirect("/studio/onboarding/identity");
  const links: Record<string, string> = {};
  for (const key of ["website", "scholar"]) {
    const v = text(form, key, 300);
    if (v && /^https:\/\//.test(v)) links[key] = v;
  }
  const { error } = await supabase
    .from("creator_accounts")
    .update({
      title: text(form, "title", 160) || null,
      institution: text(form, "institution", 160) || null,
      country: text(form, "country", 2).toUpperCase() || null,
      links,
      onboarding_step: advance(account.onboarding_step, "credentials", "profile"),
    })
    .eq("user_id", user.id);
  if (error) redirect(`/studio/onboarding/credentials?error=${encodeURIComponent(error.message)}`);
  revalidatePath("/studio");
  redirect("/studio/onboarding/profile");
}

export async function saveProfile(form: FormData): Promise<void> {
  const { supabase, user, account } = await requireSession();
  if (!account) redirect("/studio/onboarding/identity");
  const fromOnboarding = form.get("from") === "onboarding";
  const { error } = await supabase
    .from("creator_accounts")
    .update({
      display_name: text(form, "display_name", 120) || account.display_name,
      title: text(form, "title", 160) || null,
      bio: text(form, "bio", 300) || null,
      long_bio: text(form, "long_bio", 1200) || null,
      ...(fromOnboarding ? { onboarding_step: advance(account.onboarding_step, "profile", "agreement") } : {}),
    })
    .eq("user_id", user.id);
  if (error) redirect(`${fromOnboarding ? "/studio/onboarding/profile" : "/studio/profile"}?error=${encodeURIComponent(error.message)}`);
  // La page publique suit le profil (trigger SQL creator_accounts_sync).
  revalidatePath("/studio");
  revalidatePath("/authors");
  redirect(fromOnboarding ? "/studio/onboarding/agreement" : "/studio/profile?saved=1");
}

/** Un avatar illustré à la place d'une photo : le fichier du site (public/avatars) est copié dans la
 *  photo du Studio de l'auteur, et suit ensuite le même chemin qu'une photo : la base la rend
 *  publique (trigger creator_accounts_photo_sync → Edge Function author-photo-sync) si le compte
 *  est approuvé, et le catalogue des apps est recalculé dans la minute. */
export async function chooseAvatar(name: string): Promise<ActionResult & { url?: string }> {
  const { supabase, user } = await requireSession();
  if (!isAvatarName(name)) return { ok: false, error: "Unknown avatar." };
  let bytes: Uint8Array;
  try {
    bytes = new Uint8Array(await readFile(join(process.cwd(), "public", "avatars", `${name}.webp`)));
  } catch {
    return { ok: false, error: "This avatar is not available on the server." };
  }
  const path = `${user.id}/avatar.webp`;
  const { error: upErr } = await supabase.storage.from("studio-photos").upload(path, bytes, { upsert: true, contentType: "image/webp", cacheControl: "3600" });
  if (upErr) return { ok: false, error: upErr.message };
  const { error } = await supabase.from("creator_accounts").update({ photo_path: path }).eq("user_id", user.id);
  if (error) return { ok: false, error: error.message };
  revalidatePath("/studio");
  revalidatePath("/authors");
  return { ok: true, url: avatarUrl(name) };
}

/** La photo est téléversée par le navigateur dans studio-photos/<uid>/… ; on enregistre le chemin. */
export async function savePhotoPath(path: string): Promise<ActionResult> {
  const { supabase, user } = await requireSession();
  if (!path.startsWith(`${user.id}/`)) return { ok: false, error: "Invalid path" };
  const { error } = await supabase.from("creator_accounts").update({ photo_path: path }).eq("user_id", user.id);
  if (error) return { ok: false, error: error.message };
  // Compte approuvé : la base rend la photo publique (page auteur tout de suite, apps au prochain catalogue).
  revalidatePath("/studio");
  revalidatePath("/authors");
  return { ok: true };
}

export async function signAgreement(form: FormData): Promise<void> {
  const { supabase } = await requireSession();
  const name = text(form, "signed_name", 160);
  if (form.get("accept") !== "on" || name.length < 3) redirect("/studio/onboarding/agreement?error=incomplete");
  const h = await headers();
  const ip = (h.get("x-forwarded-for") ?? "").split(",")[0].trim() || null;
  const ua = h.get("user-agent")?.slice(0, 300) ?? null;
  const { error } = await supabase.rpc("studio_sign_agreement", { p_lang: "en", p_signed_name: name, p_ip: ip, p_user_agent: ua });
  if (error) redirect(`/studio/onboarding/agreement?error=${encodeURIComponent(error.message)}`);
  revalidatePath("/studio");
  redirect("/studio/onboarding/guide");
}

export async function finishGuide(): Promise<void> {
  const { supabase, user, account } = await requireSession();
  if (!account) redirect("/studio/onboarding/identity");
  const { error } = await supabase.from("creator_accounts").update({ guide_read_at: new Date().toISOString(), onboarding_step: "done" }).eq("user_id", user.id);
  if (error) redirect(`/studio/onboarding/guide?error=${encodeURIComponent(error.message)}`);
  revalidatePath("/studio");
  redirect("/studio");
}

/** Proposer un cours : un titre et un pitch. La base vérifie le quota (studio_propose) et crée la
 *  ligne en statut « proposed » ; l'équipe décide, puis l'auteur écrit. */
export async function proposeCourse(form: FormData): Promise<void> {
  const { supabase, account } = await requireSession();
  if (!account) redirect("/studio/onboarding/identity");
  const title = text(form, "title", 160);
  const pitch = text(form, "pitch", 600);
  const { data, error } = await supabase.rpc("studio_propose", { p_title: title, p_pitch: pitch });
  if (error || !data) {
    const qs = new URLSearchParams({ error: error?.message ?? "The proposal could not be sent.", title, pitch });
    redirect(`/studio/courses/new?${qs.toString()}`);
  }
  revalidatePath("/studio");
  revalidatePath("/studio/courses");
  redirect(`/studio/courses/${(data as { id: string }).id}/status?done=proposed`);
}

/** Reprendre une proposition renvoyée (ou pas encore lue) et la renvoyer à l'équipe. */
export async function updateProposal(form: FormData): Promise<void> {
  const { supabase } = await requireSession();
  const id = text(form, "id", 64);
  const title = text(form, "title", 160);
  const pitch = text(form, "pitch", 600);
  const { error } = await supabase.rpc("studio_update_proposal", { p_id: id, p_title: title, p_pitch: pitch });
  revalidatePath("/studio/courses");
  redirect(`/studio/courses/${id}/status?${error ? `error=${encodeURIComponent(error.message)}` : "done=proposed"}`);
}

/** Supprimer sa proposition tant qu'elle n'est pas acceptée. */
export async function deleteProposal(form: FormData): Promise<void> {
  const { supabase } = await requireSession();
  const id = text(form, "id", 64);
  await supabase.from("studio_drafts").delete().eq("id", id).in("status", ["proposed", "proposal_returned"]);
  revalidatePath("/studio");
  revalidatePath("/studio/courses");
  redirect("/studio/courses?done=deleted");
}

export async function deleteDraft(form: FormData): Promise<void> {
  const { supabase } = await requireSession();
  const id = text(form, "id", 64);
  await supabase.from("studio_drafts").delete().eq("id", id).eq("status", "draft");
  revalidatePath("/studio/courses");
  redirect("/studio/courses");
}

export async function withdrawDraft(form: FormData): Promise<void> {
  const { supabase } = await requireSession();
  const id = text(form, "id", 64);
  const { error } = await supabase.rpc("studio_withdraw_draft", { p_id: id });
  revalidatePath("/studio/courses");
  redirect(`/studio/courses/${id}${error ? `?error=${encodeURIComponent(error.message)}` : ""}`);
}

export async function signOut(): Promise<void> {
  const session = await getStudioSession();
  if (session) await session.supabase.auth.signOut();
  redirect("/");
}
