"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createAdminClient } from "@/lib/supabase/admin";
import { getStudioSession } from "@/lib/studio/account";
import { toPublishBody, validateCourse, hasErrors, type DraftCourse } from "@/lib/studio/course-format";
import type { CreatorAccount } from "@/lib/studio/account";
import type { DraftRow } from "@/lib/studio/data";
import { SUPABASE_URL } from "@/lib/env";
import { LANGS } from "@/lib/catalog/types";

function text(form: FormData, key: string, max = 2000): string {
  const v = form.get(key);
  return typeof v === "string" ? v.trim().slice(0, max) : "";
}

async function requireAdmin() {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/admin");
  if (!session.isAdmin) redirect("/studio");
  return session;
}

function back(path: string, params: Record<string, string>): never {
  const qs = new URLSearchParams(params).toString();
  redirect(qs ? `${path}?${qs}` : path);
}

/** Une décision de relecture : changes_requested (commentaire requis), accepted, rejected, reopened, note. */
export async function reviewDraft(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const id = text(form, "id", 64);
  const decision = text(form, "decision", 40);
  const comment = text(form, "comment", 4000);
  const { error } = await session.supabase.rpc("studio_review_draft", { p_id: id, p_decision: decision, p_comment: comment || null });
  revalidatePath("/admin");
  revalidatePath("/admin/review");
  revalidatePath("/studio");
  if (error) back(`/admin/review/${id}`, { error: error.message });
  back(`/admin/review/${id}`, { done: decision });
}

/** Approuver, suspendre, remettre en attente une personne. L'approbation crée la page publique
 *  (ligne creators, dans la fonction SQL) ; la photo du Studio devient publique dans la foulée,
 *  côté base (trigger creator_accounts_approved_photo → Edge Function author-photo-sync). */
export async function setCreatorStatus(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const user = text(form, "user_id", 64);
  const status = text(form, "status", 20);
  const reason = text(form, "reason", 600);
  const { error } = await session.supabase.rpc("studio_set_creator_status", { p_user: user, p_status: status, p_reason: reason || null });
  revalidatePath("/admin/creators");
  revalidatePath("/studio");
  revalidatePath("/authors");
  if (error) back("/admin/creators", { error: error.message });
  back("/admin/creators", { done: status });
}

/** Accepter et lancer la production : le cours part à publish-course avec la clé de l'usine,
 *  le brouillon passe « publishing » avec son job, la photo de l'auteur devient publique. */
export async function publishDraft(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const id = text(form, "id", 64);
  const apiKey = process.env.PUBLISH_API_KEY;
  if (!apiKey) back(`/admin/review/${id}`, { error: "PUBLISH_API_KEY is not set on the server (Vercel environment variables)." });

  let admin;
  try {
    admin = createAdminClient();
  } catch (e) {
    back(`/admin/review/${id}`, { error: e instanceof Error ? e.message : "SUPABASE_SECRET_KEY missing" });
  }
  const { data: draftRow } = await admin.from("studio_drafts").select("*").eq("id", id).maybeSingle();
  const draft = draftRow as DraftRow | null;
  if (!draft) back("/admin/review", { error: "Draft not found." });
  const pickedRaw = form.getAll("languages").map(String);
  const addingLanguages = draft.status === "published" && pickedRaw.length > 0;
  if (!["submitted", "accepted", "failed", "changes_requested"].includes(draft.status) && !addingLanguages) back(`/admin/review/${id}`, { error: `Cannot publish a course in status ${draft.status}.` });

  const { data: accountRow } = await admin.from("creator_accounts").select("*").eq("user_id", draft.user_id).maybeSingle();
  const account = accountRow as CreatorAccount | null;
  if (!account?.slug || !account.display_name) back(`/admin/review/${id}`, { error: "The author's profile is incomplete (name or slug)." });
  if (account.status === "suspended") back(`/admin/review/${id}`, { error: "The author's account is suspended." });

  const course: DraftCourse = { title: draft.title, subtitle: draft.subtitle, subject: draft.subject, subcategory: draft.subcategory, description: draft.description, hero: draft.hero ?? {}, sections: draft.sections ?? [], sources: draft.sources ?? [], glossary: draft.glossary ?? [] };
  const findings = validateCourse(course);
  if (hasErrors(findings)) back(`/admin/review/${id}`, { error: `The course has ${findings.filter((f) => f.severity === "error").length} format problems; ask the author to fix them.` });

  // La photo publique est tenue à jour par la base (author-photo-sync) ; on reprend l'adresse courante
  // pour que publish-course ne l'efface pas.
  const { data: creatorRow } = await admin.from("creators").select("photo_url").eq("slug", account.slug).maybeSingle();
  const photoUrl = (creatorRow?.photo_url as string | null | undefined) ?? null;

  // Si le cours n'était pas encore accepté, on trace la décision.
  if (draft.status === "submitted" || draft.status === "changes_requested") {
    const { error } = await session.supabase.rpc("studio_review_draft", { p_id: id, p_decision: "accepted", p_comment: null });
    if (error) back(`/admin/review/${id}`, { error: error.message });
  }

  // Les langues de distribution : celles cochées par l'équipe (toutes par défaut), jamais l'origine.
  const picked = pickedRaw.filter((l) => (LANGS as readonly string[]).includes(l) && l !== draft.origin_lang);
  const allOthers = LANGS.filter((l) => l !== draft.origin_lang);
  // Toutes cochées : on laisse l'usine prendre les 29 ; un sous-ensemble (ou un ajout) : on le nomme.
  const languages = picked.length > 0 && (picked.length < allOthers.length || addingLanguages) ? picked : null;
  const body = toPublishBody(
    course,
    draft.origin_lang,
    { slug: account.slug, name: account.display_name, title: account.title, bio: account.bio, photo_url: photoUrl, institution: account.institution, country: account.country, links: account.links ?? {}, verified: account.status === "approved" },
    { appCourseId: draft.app_course_id, skipAudio: true, requestedBy: `studio:${session.user.email ?? session.user.id}`, languages },
  );
  let out: { job_id?: string; course_id?: string; error?: string; errors?: string[]; detail?: string } = {};
  let status = 0;
  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/publish-course`, { method: "POST", headers: { "x-api-key": apiKey, "Content-Type": "application/json" }, body: JSON.stringify(body), cache: "no-store" });
    status = res.status;
    out = (await res.json().catch(() => ({}))) as typeof out;
  } catch (e) {
    back(`/admin/review/${id}`, { error: `publish-course unreachable: ${e instanceof Error ? e.message : "network"}` });
  }
  if (status !== 202 || !out.job_id || !out.course_id) {
    const detail = out.errors?.join(" · ") ?? out.detail ?? out.error ?? `HTTP ${status}`;
    await admin.from("studio_reviews").insert({ draft_id: id, reviewer_id: session.user.id, decision: "publish_failed", comment: `publish-course refused: ${detail}`.slice(0, 2000) });
    revalidatePath(`/admin/review/${id}`);
    back(`/admin/review/${id}`, { error: `publish-course refused: ${detail}` });
  }

  const now = new Date().toISOString();
  await admin.from("studio_drafts").update({ status: "publishing", last_job_id: out.job_id, app_course_id: out.course_id, accepted_at: draft.accepted_at ?? now, review_comment: null }).eq("id", id);
  await admin.from("studio_reviews").insert({ draft_id: id, reviewer_id: session.user.id, decision: "note", comment: `${addingLanguages ? "More languages launched" : "Production launched"} · job ${out.job_id} · course ${out.course_id} · ${languages ? `${languages.length} languages: ${languages.join(", ")}` : "all 29 languages"}` });
  await admin.from("creators").update({ user_id: draft.user_id }).eq("slug", account.slug);
  // L'usine démarre tout de suite plutôt qu'au prochain passage du cron (cinq minutes).
  await admin.rpc("jobs_dispatch", { p_limit: 5 });

  revalidatePath("/admin");
  revalidatePath("/admin/review");
  revalidatePath("/admin/production");
  revalidatePath("/studio");
  back(`/admin/review/${id}`, { done: "published" });
}

/** La décision sur une proposition : accepter (le cours passe en rédaction), renvoyer avec un mot
 *  ou un contre-titre (requis), supprimer. */
export async function decideProposal(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const id = text(form, "id", 64);
  const decision = text(form, "decision", 20);
  const note = text(form, "note", 1200);
  const { error } = await session.supabase.rpc("studio_decide_proposal", { p_id: id, p_decision: decision, p_note: note || null });
  revalidatePath("/admin");
  revalidatePath("/admin/review");
  revalidatePath("/studio");
  revalidatePath("/studio/courses");
  if (error) back(`/admin/review/${id}`, { error: error.message });
  if (decision === "deleted") back("/admin/review", { done: "proposal_deleted" });
  back(`/admin/review/${id}`, { done: decision === "accepted" ? "proposal_accepted" : "proposal_returned" });
}

/** La limite hebdomadaire d'un auteur : vide = la règle commune, 0 = bloqué. */
export async function setCreatorQuota(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const user = text(form, "user_id", 64);
  const raw = text(form, "weekly_quota", 4);
  const quota = raw === "" ? null : Number(raw);
  if (quota !== null && (!Number.isInteger(quota) || quota < 0 || quota > 50)) back("/admin/creators", { error: "The weekly limit is a whole number from 0 to 50, or empty for the default." });
  const { error } = await session.supabase.rpc("studio_set_creator_quota", { p_user: user, p_quota: quota });
  revalidatePath("/admin/creators");
  revalidatePath("/studio");
  if (error) back("/admin/creators", { error: error.message });
  back("/admin/creators", { done: quota === null ? "quota reset to the default" : `limit set to ${quota} a week` });
}

/** « Virement fait » : regroupe les crédits non versés de l'auteur dans un versement daté. */
export async function markPaid(form: FormData): Promise<void> {
  const session = await requireAdmin();
  const user = text(form, "user_id", 64);
  const note = text(form, "note", 300);
  const { data, error } = await session.supabase.rpc("studio_mark_paid", { p_user: user, p_note: note || null });
  revalidatePath("/admin");
  revalidatePath("/admin/payouts");
  revalidatePath("/studio");
  if (error) back("/admin/payouts", { error: error.message });
  const paid = data as { amount_cents?: number } | null;
  back("/admin/payouts", { done: String(paid?.amount_cents ?? "") });
}
