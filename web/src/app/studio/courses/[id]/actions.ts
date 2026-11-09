"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { SUBJECTS, type Block, type GlossaryEntry, type Section, type Source } from "@/lib/catalog/types";
import { getStudioSession } from "@/lib/studio/account";
import { BLOCK_TYPES, CLASSIFICATIONS, type DraftCourse, type Hero } from "@/lib/studio/course-format";

type SaveResult = { ok: true; updatedAt: string } | { ok: false; error: string };

const MAX_BYTES = 600_000;

function str(v: unknown, max = 5000): string {
  return typeof v === "string" ? v.slice(0, max) : "";
}
function opt(v: unknown, max = 400): string | undefined {
  const s = str(v, max);
  return s ? s : undefined;
}

/** Nettoie ce que le navigateur envoie : seuls les champs du format passent, bornés. */
async function sanitizeCourse(raw: unknown): Promise<DraftCourse> {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const heroRaw = (r.hero && typeof r.hero === "object" ? r.hero : {}) as Record<string, unknown>;
  const creditRaw = (heroRaw.credit && typeof heroRaw.credit === "object" ? heroRaw.credit : null) as Record<string, unknown> | null;
  const hero: Hero = {
    ...(opt(heroRaw.image, 120) ? { image: opt(heroRaw.image, 120) } : {}),
    ...(opt(heroRaw.image_url, 1000) ? { image_url: opt(heroRaw.image_url, 1000) } : {}),
    ratio: opt(heroRaw.ratio, 10) ?? "16:9",
    ...(opt(heroRaw.hook, 200) ? { hook: opt(heroRaw.hook, 200) } : {}),
    ...(creditRaw ? { credit: { title: opt(creditRaw.title, 300), author: opt(creditRaw.author, 300), license: opt(creditRaw.license, 120), source: opt(creditRaw.source, 300) } } : {}),
  };
  const sections: Section[] = (Array.isArray(r.sections) ? r.sections : []).slice(0, 12).map((sec: unknown, i: number) => {
    const s = (sec && typeof sec === "object" ? sec : {}) as Record<string, unknown>;
    const blocks: Block[] = (Array.isArray(s.blocks) ? s.blocks : []).slice(0, 60).flatMap((bl: unknown): Block[] => {
      const b = (bl && typeof bl === "object" ? bl : {}) as Record<string, unknown>;
      const type = String(b.type ?? "");
      if (!(BLOCK_TYPES as readonly string[]).includes(type)) return [];
      switch (type) {
        case "image": {
          const credit = (b.credit && typeof b.credit === "object" ? b.credit : null) as Record<string, unknown> | null;
          return [
            {
              type: "image",
              ...(opt(b.asset, 120) ? { asset: opt(b.asset, 120) } : {}),
              ...(opt(b.image_url, 1000) ? { image_url: opt(b.image_url, 1000) } : {}),
              caption: str(b.caption, 400),
              ...(credit ? { credit: { title: opt(credit.title, 300), author: opt(credit.author, 300), license: opt(credit.license, 120), source: opt(credit.source, 300) } } : {}),
            },
          ];
        }
        case "timeline":
          return [
            {
              type: "timeline",
              events: (Array.isArray(b.events) ? b.events : []).slice(0, 20).map((ev: unknown) => {
                const e = (ev && typeof ev === "object" ? ev : {}) as Record<string, unknown>;
                return { date: str(e.date, 40), title: str(e.title, 160), ...(opt(e.detail, 400) ? { detail: opt(e.detail, 400) } : {}) };
              }),
            },
          ];
        case "quote":
          return [{ type: "quote", text: str(b.text, 2000), attribution: str(b.attribution, 160) }];
        default:
          return [{ type: type as "paragraph" | "heading" | "funFact" | "takeaway", text: str(b.text, 5000) }];
      }
    });
    return { ...(opt(s.id, 200) ? { id: opt(s.id, 200) } : {}), title: str(s.title, 120), free: i === 0 ? s.free !== false : Boolean(s.free), blocks };
  });
  const sources: Source[] = (Array.isArray(r.sources) ? r.sources : []).slice(0, 40).map((so: unknown) => {
    const x = (so && typeof so === "object" ? so : {}) as Record<string, unknown>;
    return { text: str(x.text, 400), ...(opt(x.url, 1000) ? { url: opt(x.url, 1000) } : {}) };
  });
  const glossary: GlossaryEntry[] = (Array.isArray(r.glossary) ? r.glossary : []).slice(0, 60).map((g: unknown) => {
    const x = (g && typeof g === "object" ? g : {}) as Record<string, unknown>;
    const cls = String(x.classification ?? "concept");
    return { term: str(x.term, 120), classification: (CLASSIFICATIONS as readonly string[]).includes(cls) ? cls : "concept", explanation: str(x.explanation, 600) };
  });
  const subject = str(r.subject, 40);
  return {
    title: str(r.title, 160),
    subtitle: opt(r.subtitle, 80) ?? null,
    subject: (SUBJECTS as readonly string[]).includes(subject) ? subject : null,
    subcategory: opt(r.subcategory, 80) ?? null,
    description: str(r.description, 600),
    hero,
    sections,
    sources,
    glossary,
  };
}

/** L'enregistrement automatique de l'éditeur. La règle d'accès ne laisse passer que l'auteur, en draft ou changes_requested. */
export async function saveDraft(id: string, raw: unknown): Promise<SaveResult> {
  const session = await getStudioSession();
  if (!session) return { ok: false, error: "Signed out. Sign in again to keep saving." };
  if (JSON.stringify(raw ?? {}).length > MAX_BYTES) return { ok: false, error: "The course is too large to save (600 KB)." };
  const course = await sanitizeCourse(raw);
  const { data, error } = await session.supabase
    .from("studio_drafts")
    .update({ title: course.title, subtitle: course.subtitle, subject: course.subject, subcategory: course.subcategory, description: course.description, hero: course.hero, sections: course.sections, sources: course.sources, glossary: course.glossary })
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
