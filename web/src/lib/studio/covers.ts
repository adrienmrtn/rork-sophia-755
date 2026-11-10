import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { STORAGE_PUBLIC } from "@/lib/env";

/** Les couvertures de cours : trois illustrations 16:9 générées à partir du titre, parmi lesquelles
 *  l'auteur choisit avant l'envoi. Deux appels fal.ai : Gemini (texte) écrit le prompt d'image avec
 *  la consigne de direction artistique ci-dessous, puis Gemini (image) dessine. Les images sont
 *  copiées dans le bucket public course-images sous studio/<brouillon>/ ; l'usine importera la
 *  couverture choisie sous le slug du cours. */

const FAL_KEY = process.env.FAL_KEY ?? process.env.FAL_API_KEY ?? "";
export const TEXT_MODEL = process.env.FAL_TEXT_MODEL ?? "google/gemini-2.5-flash";
const IMAGE_MODEL = process.env.FAL_COVER_MODEL ?? "fal-ai/gemini-25-flash-image";

/** La consigne de direction artistique (celle d'Adrien), passée telle quelle au modèle de texte. */
export const ART_DIRECTOR_SYSTEM_PROMPT = `You are an expert illustrator art director specializing in educational course covers. Given a course title, write ONE highly detailed image-generation prompt.

OUTPUT: Only the prompt text. No explanations, no prefixes, no quotes.

MANDATORY FORMAT — follow this structure exactly:

"A landscape (16:9) illustration in a clean, modern flat design style. The entire image is filled edge-to-edge with [SPECIFIC SCENE]. [DETAILED DESCRIPTION OF 2-4 KEY VISUAL ELEMENTS WITH COLORS, POSITIONS, AND STYLE DETAILS]. The background is [COLORFUL BACKGROUND THAT FITS THE THEME]. The composition is clean and focused. The style uses bold flat colors, simple geometric shapes, and stylized figures. Without any text."

YOUR JOB:
- The illustration must fill the ENTIRE landscape rectangle with NO margins, NO borders, NO frames
- Choose a rich, colorful background that fits the course theme (deep blue sky, warm desert orange, lush green, etc.)
- Research what the course topic is REALLY about and pick THE most iconic, recognizable visual representation
- Describe specific figures, objects, landmarks, or symbols — not abstract concepts
- Include specific colors for each element (gold, emerald green, slate blue, etc.)
- Describe positions and spatial relationships (to the left, above, in the foreground, etc.)
- Characters should be stylized silhouettes with identifiable clothing/accessories

STRICT RULES:
- NO text, letters, numbers, words, logos, or watermarks anywhere
- The prompt must be in English
- NO cream, beige, or white backgrounds — use vibrant thematic colors
- NEVER use circular medallions, frames, badges, coins, or icon containers
- NEVER use borders or any kind of container around the illustration
- The scene must fill the entire landscape rectangle naturally, edge to edge`;

export function coversConfigured(): boolean {
  return Boolean(FAL_KEY);
}

/** Un appel synchrone à fal.run ; partagé avec la traduction des événements (translate.ts). */
export async function fal<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`https://fal.run/${path}`, {
    method: "POST",
    headers: { Authorization: `Key ${FAL_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
    cache: "no-store",
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`fal ${path} → ${res.status} ${text.slice(0, 300)}`);
  }
  return (await res.json()) as T;
}

/** Le prompt d'image, écrit par le modèle de texte à partir du titre (et du contexte du cours). */
export async function writeCoverPrompt(course: { title: string; subject?: string | null; subtitle?: string | null; description?: string | null }): Promise<string> {
  const context = [`Course title: ${course.title}`, course.subtitle ? `Subtitle: ${course.subtitle}` : null, course.subject ? `Subject area: ${course.subject}` : null, course.description ? `What the course is about: ${course.description}` : null].filter(Boolean).join("\n");
  const out = await fal<{ output?: string; error?: string }>("fal-ai/any-llm", { model: TEXT_MODEL, system_prompt: ART_DIRECTOR_SYSTEM_PROMPT, prompt: context, temperature: 0.8 });
  const text = (out.output ?? "").trim().replace(/^["“]|["”]$/g, "").trim();
  if (!text) throw new Error(out.error ?? "The art director returned an empty prompt.");
  return text;
}

/** Trois images 16:9 pour un prompt. */
export async function generateCoverImages(prompt: string, count = 3): Promise<string[]> {
  const out = await fal<{ images?: { url: string }[]; error?: string }>(IMAGE_MODEL, { prompt, num_images: count, aspect_ratio: "16:9", output_format: "jpeg" });
  const urls = (out.images ?? []).map((i) => i.url).filter(Boolean);
  if (urls.length === 0) throw new Error(out.error ?? "No image was generated.");
  return urls;
}

/** Copie les images dans course-images/studio/<brouillon>/, rend leurs adresses publiques. */
export async function storeCovers(draftId: string, urls: string[]): Promise<string[]> {
  const admin = createAdminClient();
  const stamp = Date.now().toString(36);
  const stored: string[] = [];
  await Promise.all(
    urls.map(async (url, i) => {
      const res = await fetch(url, { cache: "no-store" });
      if (!res.ok) throw new Error(`Could not download a generated image (${res.status}).`);
      const bytes = new Uint8Array(await res.arrayBuffer());
      const path = `studio/${draftId}/${stamp}_${i + 1}.jpg`;
      const { error } = await admin.storage.from("course-images").upload(path, bytes, { contentType: "image/jpeg", upsert: true, cacheControl: "31536000" });
      if (error) throw new Error(`Could not store a generated image: ${error.message}`);
      stored[i] = `${STORAGE_PUBLIC}/course-images/${path}`;
    }),
  );
  return stored.filter(Boolean);
}

/** Copie une image distante dans le bucket public course-images, à ce chemin ; rend son adresse publique.
 *  Sert aux images d'événement générées (events/<slug>_ai_<horodatage>.jpg). */
export async function storeImageAt(path: string, url: string, contentType = "image/jpeg"): Promise<string> {
  const admin = createAdminClient();
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error(`Could not download the generated image (${res.status}).`);
  const bytes = new Uint8Array(await res.arrayBuffer());
  const { error } = await admin.storage.from("course-images").upload(path, bytes, { contentType, upsert: true, cacheControl: "31536000" });
  if (error) throw new Error(`Could not store the image: ${error.message}`);
  return `${STORAGE_PUBLIC}/course-images/${path}`;
}

/** La direction artistique des illustrations du site (design/site-art/manifest-*.json) : aplats en
 *  papier découpé, palette marine, safran, corail, crème. Le modèle de texte écrit la scène, Recraft
 *  dessine. */
const POSTER_MODEL = process.env.FAL_POSTER_MODEL ?? "fal-ai/recraft-v3";
const POSTER_SUFFIX = "Flat poster illustration, paper-cut shapes, limited palette of deep navy blue, saffron yellow, coral red and cream, bold simple forms, subtle paper grain, centered on a navy background, no text, no outlines.";
const POSTER_COLORS = [
  { r: 26, g: 58, b: 107 },
  { r: 242, g: 177, b: 52 },
  { r: 224, g: 90, b: 58 },
  { r: 251, g: 247, b: 239 },
];
export const POSTER_SCENE_SYSTEM_PROMPT = `You write the scene of a flat paper-cut poster illustration for an educational app. Given a theme (title, tagline, description), answer with ONE sentence of at most 30 words that lists two to four iconic, concrete objects or figures that stand for the theme (no people's faces unless the theme is about people), with their arrangement. No style words, no colors, no text in the image, no quotes, no prefix.`;

/** La scène d'affiche, écrite par le modèle de texte à partir du thème. */
export async function writePosterScene(theme: { title: string; subtitle?: string | null; description?: string | null }): Promise<string> {
  const context = [`Title: ${theme.title}`, theme.subtitle ? `Tagline: ${theme.subtitle}` : null, theme.description ? `About: ${theme.description}` : null].filter(Boolean).join("\n");
  const out = await fal<{ output?: string; error?: string }>("fal-ai/any-llm", { model: TEXT_MODEL, system_prompt: POSTER_SCENE_SYSTEM_PROMPT, prompt: context, temperature: 0.7 });
  const text = (out.output ?? "").trim().replace(/^["“]|["”]$/g, "").trim();
  if (!text) throw new Error(out.error ?? "The poster art director returned an empty scene.");
  return text;
}

const BADGE_SUFFIX = "Single centred emblem filling most of the frame, like a merit badge. Flat poster illustration, paper-cut shapes, limited palette of deep navy blue, saffron yellow, coral red and cream, bold simple forms, subtle paper grain, plain navy background, no text, no letters, no numbers, no outlines.";
export const BADGE_EMBLEM_SYSTEM_PROMPT = `You design the emblem of an achievement badge for an educational app, in flat paper-cut style. Given an event (title, tagline, description) and the badge's name, answer with THREE different emblem ideas, one per line, nothing else. Each line is ONE sentence of at most 20 words describing a single iconic, concrete object or a tight group of two objects that stands for the theme (no people's faces unless the theme is a person). No style words, no colors, no text in the image, no numbering, no quotes.`;

/** Trois idées d'emblème pour le badge d'un événement, écrites par le modèle de texte. */
export async function writeBadgeEmblems(theme: { title: string; badge?: string | null; subtitle?: string | null; description?: string | null }): Promise<string[]> {
  const context = [`Event: ${theme.title}`, theme.badge ? `Badge name: ${theme.badge}` : null, theme.subtitle ? `Tagline: ${theme.subtitle}` : null, theme.description ? `About: ${theme.description}` : null].filter(Boolean).join("\n");
  const out = await fal<{ output?: string; error?: string }>("fal-ai/any-llm", { model: TEXT_MODEL, system_prompt: BADGE_EMBLEM_SYSTEM_PROMPT, prompt: context, temperature: 0.9 });
  const lines = (out.output ?? "")
    .split("\n")
    .map((l) => l.trim().replace(/^[-*\d.)\s]+/, "").replace(/^["“]|["”]$/g, "").trim())
    .filter(Boolean)
    .slice(0, 3);
  if (lines.length === 0) throw new Error(out.error ?? "The badge art director returned no emblem.");
  // Moins de trois idées : la première est redessinée, Recraft ne rend jamais deux fois la même image.
  while (lines.length < 3) lines.push(lines[0]);
  return lines;
}

/** Une illustration carrée de badge, dans la direction papier découpé des avatars et des ligues. */
export async function generateBadgeImage(emblem: string): Promise<{ url: string; contentType: string }> {
  const out = await fal<{ images?: { url: string; content_type?: string }[]; error?: string }>(POSTER_MODEL, {
    prompt: `${emblem.replace(/\.$/, "")}. ${BADGE_SUFFIX}`,
    image_size: "square_hd",
    style: "digital_illustration/2d_art_poster",
    colors: POSTER_COLORS,
    enable_safety_checker: true,
  });
  const image = (out.images ?? [])[0];
  if (!image?.url) throw new Error(out.error ?? "No badge image was generated.");
  return { url: image.url, contentType: image.content_type ?? "image/webp" };
}

/** Une image 16:9 dans la direction affiche du site (Recraft v3, style 2d_art_poster, palette du site). */
export async function generatePosterImage(scene: string): Promise<{ url: string; contentType: string }> {
  const out = await fal<{ images?: { url: string; content_type?: string }[]; error?: string }>(POSTER_MODEL, {
    prompt: `${scene.replace(/\.$/, "")}. ${POSTER_SUFFIX}`,
    image_size: "landscape_16_9",
    style: "digital_illustration/2d_art_poster",
    colors: POSTER_COLORS,
    enable_safety_checker: true,
  });
  const image = (out.images ?? [])[0];
  if (!image?.url) throw new Error(out.error ?? "No poster image was generated.");
  return { url: image.url, contentType: image.content_type ?? "image/webp" };
}
