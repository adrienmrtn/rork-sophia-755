import "server-only";
import { LANG_NAMES } from "@/lib/catalog/lang-names";
import type { Lang } from "@/lib/catalog/types";
import { coversConfigured, fal, TEXT_MODEL } from "./covers";
import { TEXT_FIELDS, type Campaign, type Localized } from "./campaigns";

/** Les textes d'un événement traduits dans les langues qui leur manquent, par le même modèle de
 *  texte que les couvertures (fal any-llm). Les langues déjà remplies ne sont jamais écrasées ;
 *  l'équipe relit ensuite l'anglais et le français elle-même. */

const SYSTEM = `You translate the short texts of an editorial event for Sophia, a general-knowledge app read in 30 languages. The texts are shown in the app's feed, on the event page and on a badge.

Rules:
- Translate faithfully, in the natural register of each language, as an editor would write it (not word for word).
- Keep proper nouns, brand names and campaign names unchanged (Movember, Sophia).
- Keep each text about as long as the source. Titles stay short; the badge name is one or two words.
- Output ONLY a JSON object, no markdown, no comments. Keys: the language codes requested. Each value: an object with "title", "tagline", "description", "badge_name" (strings).`;

type Translated = Partial<Record<"title" | "tagline" | "description" | "badge_name", string>>;

export function translationConfigured(): boolean {
  return coversConfigured();
}

function sourceOf(c: Campaign): { lang: string; texts: Record<string, string> } {
  const lang = TEXT_FIELDS.every((f) => c[f].en?.trim()) ? "en" : "fr";
  return {
    lang,
    texts: Object.fromEntries(TEXT_FIELDS.map((f) => [f, (c[f][lang] ?? c[f].en ?? c[f].fr ?? "").trim()])),
  };
}

function parseJson(text: string): Record<string, Translated> {
  const cleaned = text.trim().replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  if (start < 0 || end < start) throw new Error("The translator did not return JSON.");
  return JSON.parse(cleaned.slice(start, end + 1)) as Record<string, Translated>;
}

/** Les quatre tables, complétées pour `targets`. Renvoie aussi les langues effectivement ajoutées. */
export async function translateCampaign(c: Campaign, targets: Lang[]): Promise<{ fields: Pick<Campaign, "title" | "tagline" | "description" | "badge_name">; added: Lang[] }> {
  const fields = { title: { ...c.title }, tagline: { ...c.tagline }, description: { ...c.description }, badge_name: { ...c.badge_name } };
  if (targets.length === 0) return { fields, added: [] };
  const source = sourceOf(c);
  const sourceJson = JSON.stringify(source.texts, null, 2);
  // Les langues par paquets de dix : une réponse plus courte est plus sûre à analyser.
  const added: Lang[] = [];
  for (let i = 0; i < targets.length; i += 10) {
    const batch = targets.slice(i, i + 10);
    const prompt = [
      `Source language: ${LANG_NAMES[source.lang] ?? source.lang} (${source.lang}).`,
      `Target languages (use these exact codes as keys): ${batch.map((t) => `${t} = ${LANG_NAMES[t] ?? t}`).join(", ")}.`,
      "Source texts:",
      sourceJson,
    ].join("\n");
    const out = await fal<{ output?: string; error?: string }>("fal-ai/any-llm", { model: TEXT_MODEL, system_prompt: SYSTEM, prompt, temperature: 0.2 });
    if (!out.output) throw new Error(out.error ?? "The translator returned nothing.");
    const parsed = parseJson(out.output);
    for (const lang of batch) {
      const t = parsed[lang];
      if (!t || typeof t !== "object") continue;
      let touched = false;
      for (const f of TEXT_FIELDS) {
        const v = typeof t[f] === "string" ? t[f].trim() : "";
        if (v && !fields[f][lang]?.trim()) {
          (fields[f] as Localized)[lang] = v;
          touched = true;
        }
      }
      if (touched) added.push(lang);
    }
  }
  return { fields, added };
}
