// Le pont Studio → app : POST /publish-course reçoit un cours dans sa langue d'origine, le
// valide (CHARTE_REFONTE §4, CHARTE_QUIZ §3), l'écrit en base (créateur, cours, contenu
// d'origine) et crée un job de production que l'usine GitHub Actions exécutera (traductions,
// quiz, glossaire, couverture, audio, publication langue par langue).
// GET /publish-course?job_id=… rend l'état du job et de ses étapes.
// Authentification : en-tête x-api-key = secret PUBLISH_API_KEY. Contrat : docs/publish-contract.md.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const LANGS = [
  "fr", "en", "es", "de", "pt", "pt-PT", "it", "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg",
  "cs", "da", "nb", "ru", "hr", "sl", "sk", "sr", "ar", "he", "fi", "et", "lt", "lv", "ja",
];
const SUBJECTS = ["histoire", "sciences", "litterature", "art", "mythologie", "comprendreLeMonde"];
const BLOCKS: Record<string, string[]> = {
  heading: ["text"],
  paragraph: ["text"],
  image: [],
  timeline: ["events"],
  funFact: ["text"],
  takeaway: ["text"],
  quote: ["text"],
};
const QUESTION_TYPES = ["mcq", "trueFalse", "chronological", "numericSlider", "percentageSlider"];
const CLASSIFICATIONS = ["referenceHistorique", "concept", "evenementConnexe", "personnage", "lieuInstitution"];
const COURSE_ID = /^course_[0-9]+_[a-z0-9_]+$/;
const SLUG = /^[a-z0-9][a-z0-9-]{1,59}$/;
const ASSET = /^[a-z0-9][a-z0-9_]{1,120}$/;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-api-key",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

/** `course_<n>_<slug>` : le slug du titre, sans accents ni ponctuation, comme les 309 cours existants. */
function slugify(title: string): string {
  const folded = title.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
  const slug = folded.replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
  return slug.slice(0, 48).replace(/_+$/g, "") || "cours";
}

function isString(value: unknown, min = 1, max = 100_000): value is string {
  return typeof value === "string" && value.trim().length >= min && value.length <= max;
}

function checkText(text: unknown, where: string, errors: string[], max = 5000) {
  if (!isString(text, 1, max)) {
    errors.push(`${where} : texte manquant ou trop long (${max} caractères au plus)`);
    return;
  }
  if (text.includes("—")) errors.push(`${where} : pas de tiret cadratin (—) dans les textes (CHARTE_REFONTE §4)`);
  const opens = (text.match(/\[\[/g) ?? []).length;
  const closes = (text.match(/\]\]/g) ?? []).length;
  if (opens !== closes) errors.push(`${where} : balises de glossaire [[…]] déséquilibrées`);
  if ((text.match(/\*\*/g) ?? []).length % 2 !== 0) errors.push(`${where} : gras **…** déséquilibré`);
}

// deno-lint-ignore no-explicit-any
function validateCourse(course: any, errors: string[]) {
  if (!course || typeof course !== "object") {
    errors.push("course : objet manquant");
    return;
  }
  if (course.id !== undefined && !(isString(course.id) && COURSE_ID.test(course.id))) {
    errors.push("course.id : doit suivre course_<n>_<slug> (ou être omis pour un nouveau cours)");
  }
  if (!isString(course.title, 3, 160)) errors.push("course.title : 3 à 160 caractères");
  else checkText(course.title, "course.title", errors, 160);
  if (course.subtitle !== undefined && course.subtitle !== null && !isString(course.subtitle, 1, 80)) {
    errors.push("course.subtitle : 80 caractères au plus");
  }
  if (!SUBJECTS.includes(course.subject)) errors.push(`course.subject : une de ${SUBJECTS.join(", ")}`);
  if (course.subcategory !== undefined && !isString(course.subcategory, 1, 80)) errors.push("course.subcategory : 80 caractères au plus");
  if (!isString(course.description, 20, 600)) errors.push("course.description : 20 à 600 caractères (accroche de la carte)");
  else checkText(course.description, "course.description", errors, 600);
  if (course.hero !== undefined && course.hero !== null) {
    if (typeof course.hero !== "object") errors.push("course.hero : objet {image?, image_url?, ratio?, hook?, credit?}");
    else {
      if (course.hero.image !== undefined && !(isString(course.hero.image) && ASSET.test(course.hero.image))) {
        errors.push("course.hero.image : slug [a-z0-9_] d'un objet du bucket course-images");
      }
      if (course.hero.image_url !== undefined && !(isString(course.hero.image_url) && /^https:\/\//.test(course.hero.image_url))) {
        errors.push("course.hero.image_url : URL https d'une image à importer");
      }
      if (course.hero.hook !== undefined) checkText(course.hero.hook, "course.hero.hook", errors, 200);
    }
  }
  if (!Array.isArray(course.sections) || course.sections.length < 2 || course.sections.length > 12) {
    errors.push("course.sections : 2 à 12 sections (introduction comprise)");
    return;
  }
  let takeaways = 0;
  course.sections.forEach((section: Record<string, unknown>, s: number) => {
    const where = `sections[${s}]`;
    if (!isString(section.title, 1, 120)) errors.push(`${where}.title : 1 à 120 caractères`);
    if (section.id !== undefined && !isString(section.id, 3, 200)) errors.push(`${where}.id : chaîne`);
    if (!Array.isArray(section.blocks) || section.blocks.length === 0) {
      errors.push(`${where}.blocks : au moins un bloc`);
      return;
    }
    section.blocks.forEach((block: Record<string, unknown>, b: number) => {
      const bw = `${where}.blocks[${b}]`;
      const type = String(block.type ?? "");
      if (!(type in BLOCKS)) {
        errors.push(`${bw}.type : un de ${Object.keys(BLOCKS).join(", ")}`);
        return;
      }
      for (const field of BLOCKS[type]) {
        if (block[field] === undefined) errors.push(`${bw}.${field} : requis pour un bloc ${type}`);
      }
      if (["heading", "paragraph", "funFact", "takeaway", "quote"].includes(type)) checkText(block.text, `${bw}.text`, errors);
      if (type === "takeaway") takeaways += 1;
      if (type === "image") {
        const hasAsset = isString(block.asset) && ASSET.test(block.asset as string);
        const hasUrl = isString(block.image_url) && /^https:\/\//.test(block.image_url as string);
        if (!hasAsset && !hasUrl) errors.push(`${bw} : asset (slug du bucket) ou image_url (https) requis`);
        if (block.caption !== undefined) checkText(block.caption, `${bw}.caption`, errors, 400);
      }
      if (type === "timeline") {
        const events = block.events;
        if (!Array.isArray(events) || events.length < 2) errors.push(`${bw}.events : au moins deux repères {date, title, detail?}`);
        else events.forEach((event: Record<string, unknown>, e: number) => {
          if (!isString(event.date, 1, 40)) errors.push(`${bw}.events[${e}].date : requis`);
          if (!isString(event.title, 1, 160)) errors.push(`${bw}.events[${e}].title : requis`);
        });
      }
      if (type === "quote" && block.attribution !== undefined && !isString(block.attribution, 1, 160)) {
        errors.push(`${bw}.attribution : 160 caractères au plus`);
      }
    });
  });
  if (takeaways > 1) errors.push("course : un seul bloc takeaway (« À retenir »), en fin de cours");
  if (course.sources !== undefined) {
    if (!Array.isArray(course.sources)) errors.push("course.sources : tableau de {text, url?}");
    else course.sources.forEach((source: Record<string, unknown>, i: number) => {
      if (!isString(source.text, 3, 400)) errors.push(`sources[${i}].text : 3 à 400 caractères`);
      if (source.url !== undefined && !(isString(source.url) && /^https?:\/\//.test(source.url as string))) errors.push(`sources[${i}].url : URL`);
    });
  }
  if (course.glossary !== undefined) {
    if (!Array.isArray(course.glossary)) errors.push("course.glossary : tableau de {term, classification, explanation}");
    else course.glossary.forEach((entry: Record<string, unknown>, i: number) => {
      if (!isString(entry.term, 1, 120)) errors.push(`glossary[${i}].term : requis`);
      if (!CLASSIFICATIONS.includes(String(entry.classification))) errors.push(`glossary[${i}].classification : un de ${CLASSIFICATIONS.join(", ")}`);
      if (!isString(entry.explanation, 10, 600)) errors.push(`glossary[${i}].explanation : 10 à 600 caractères`);
    });
  }
}

// deno-lint-ignore no-explicit-any
function validateQuiz(quiz: any, errors: string[]) {
  if (quiz === undefined || quiz === null) return;
  if (!Array.isArray(quiz) || quiz.length < 6 || quiz.length > 10) {
    errors.push("quiz : 6 à 10 questions (CHARTE_QUIZ §5), ou omettre pour que l'usine les écrive");
    return;
  }
  quiz.forEach((q: Record<string, unknown>, i: number) => {
    const where = `quiz[${i}]`;
    const type = String(q.type ?? "mcq");
    if (!QUESTION_TYPES.includes(type)) errors.push(`${where}.type : un de ${QUESTION_TYPES.join(", ")}`);
    if (!isString(q.question, 5, 400)) errors.push(`${where}.question : 5 à 400 caractères`);
    if (!isString(q.explanation, 5, 600)) errors.push(`${where}.explanation : 5 à 600 caractères`);
    const options = q.options as unknown[] | undefined;
    if (type === "mcq") {
      if (!Array.isArray(options) || options.length < 3 || options.length > 5) errors.push(`${where}.options : 3 à 5 options`);
      if (q.correctIndex !== 0) errors.push(`${where}.correctIndex : 0 (la bonne réponse en premier, mélangée à l'affichage)`);
    }
    if (type === "trueFalse") {
      if (!Array.isArray(options) || options.length !== 2) errors.push(`${where}.options : exactement deux options (Vrai, Faux)`);
      if (q.correctIndex !== 0 && q.correctIndex !== 1) errors.push(`${where}.correctIndex : 0 ou 1`);
    }
    if (type === "chronological") {
      const items = q.items as unknown[] | undefined;
      if (!Array.isArray(items) || items.length < 3 || items.length > 6) errors.push(`${where}.items : 3 à 6 repères dans l'ordre correct`);
      if (Array.isArray(items) && items.some((item) => /\(\s*\d{3,4}\s*\)/.test(String(item)))) {
        errors.push(`${where}.items : pas de date entre parenthèses (elle révèle la réponse)`);
      }
    }
    if (type === "numericSlider" || type === "percentageSlider") {
      for (const field of ["correctValue", "sliderMin", "sliderMax", "tolerance"]) {
        if (typeof q[field] !== "number") errors.push(`${where}.${field} : nombre requis`);
      }
      if (type === "percentageSlider" && (q.sliderMin !== 0 || q.sliderMax !== 100)) errors.push(`${where} : plage 0-100 pour un pourcentage`);
    }
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const apiKey = Deno.env.get("PUBLISH_API_KEY");
  if (!apiKey) return json({ error: "not_configured", detail: "Secret PUBLISH_API_KEY absent de la fonction." }, 500);
  if (req.headers.get("x-api-key") !== apiKey) return json({ error: "unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  if (req.method === "GET") {
    const jobId = new URL(req.url).searchParams.get("job_id");
    if (!jobId) return json({ error: "job_id requis" }, 400);
    const { data: job, error } = await supabase.from("production_jobs")
      .select("id, course_id, origin_lang, kind, status, summary, error, options, created_at, dispatched_at, started_at, finished_at")
      .eq("id", jobId).maybeSingle();
    if (error) return json({ error: "query_failed", detail: error.message }, 500);
    if (!job) return json({ error: "not_found" }, 404);
    const { data: steps } = await supabase.from("production_steps")
      .select("step, lang, status, detail, started_at, finished_at").eq("job_id", jobId).order("id");
    return json({ job, steps: steps ?? [] });
  }
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_json" }, 400);
  }
  const errors: string[] = [];
  const kind = String(body.kind ?? "course");
  if (!["course", "video"].includes(kind)) errors.push("kind : course ou video");
  if (kind === "video") return json({ error: "not_implemented", detail: "Les vidéos arrivent au prompt 10." }, 501);
  const originLang = String(body.origin_lang ?? "fr");
  if (!LANGS.includes(originLang)) errors.push(`origin_lang : une des ${LANGS.length} langues de l'app`);
  // deno-lint-ignore no-explicit-any
  const course = body.course as any;
  validateCourse(course, errors);
  validateQuiz(body.quiz, errors);
  // deno-lint-ignore no-explicit-any
  const creator = body.creator as any;
  if (creator !== undefined && creator !== null) {
    if (typeof creator !== "object") errors.push("creator : objet {slug, name, title?, bio?, photo_url?, verified?}");
    else {
      if (!(isString(creator.slug) && SLUG.test(creator.slug))) errors.push("creator.slug : minuscules, chiffres et tirets (2 à 60)");
      if (!isString(creator.name, 2, 120)) errors.push("creator.name : 2 à 120 caractères");
      if (creator.photo_url !== undefined && !(isString(creator.photo_url) && /^https:\/\//.test(creator.photo_url))) errors.push("creator.photo_url : URL https");
    }
  }
  const options = (body.options && typeof body.options === "object" ? body.options : {}) as Record<string, unknown>;
  let targets = LANGS.filter((l) => l !== originLang);
  if (Array.isArray(options.languages)) {
    const asked = options.languages.map(String);
    const unknown = asked.filter((l) => !LANGS.includes(l));
    if (unknown.length) errors.push(`options.languages : langues inconnues ${unknown.join(", ")}`);
    targets = asked.filter((l) => l !== originLang);
  }
  if (errors.length) return json({ error: "invalid", errors }, 400);

  // L'identifiant : celui fourni (mise à jour), sinon le prochain numéro libre et le slug du titre.
  let courseId: string = course.id ?? "";
  if (!courseId) {
    const { data: ids } = await supabase.from("courses").select("id");
    const max = (ids ?? []).reduce((acc: number, row: { id: string }) => {
      const match = /^course_(\d+)_/.exec(row.id);
      return match ? Math.max(acc, parseInt(match[1], 10)) : acc;
    }, 0);
    courseId = `course_${max + 1}_${slugify(course.title)}`;
  }
  course.id = courseId;
  // Les sections gardent leurs ids historiques quand il y en a ; sinon <id>_intro, <id>_p1…
  const used = new Set<string>();
  course.sections.forEach((section: Record<string, unknown>, index: number) => {
    let id = typeof section.id === "string" && section.id.startsWith(`${courseId}_`) ? section.id : "";
    if (!id || used.has(id)) id = index === 0 ? `${courseId}_intro` : `${courseId}_p${index}`;
    while (used.has(id)) id = `${id}_b`;
    used.add(id);
    section.id = id;
    if (index === 0 && section.free === undefined) section.free = true;
  });
  // Les images fournies par URL seront importées par l'usine ; le slug est fixé maintenant.
  const imagesToImport: { slug: string; url: string }[] = [];
  if (course.hero?.image_url && !course.hero.image) {
    course.hero.image = slugify(course.title);
    imagesToImport.push({ slug: course.hero.image, url: course.hero.image_url });
    delete course.hero.image_url;
  }
  course.sections.forEach((section: Record<string, unknown>, s: number) => {
    (section.blocks as Record<string, unknown>[]).forEach((block, b) => {
      if (block.type === "image" && block.image_url && !block.asset) {
        block.asset = `${slugify(course.title)}_s${s}_b${b}`;
        imagesToImport.push({ slug: String(block.asset), url: String(block.image_url) });
        delete block.image_url;
      }
    });
  });

  const { data: existing } = await supabase.from("course_contents")
    .select("content, status").eq("course_id", courseId).eq("lang", originLang).maybeSingle();
  const { data: existingCourse } = await supabase.from("courses").select("status").eq("id", courseId).maybeSingle();
  const isNew = !existingCourse;

  if (creator) {
    const { data: current } = await supabase.from("creators").select("title, bio, links, photo_url").eq("slug", creator.slug).maybeSingle();
    const { error: creatorError } = await supabase.from("creators").upsert({
      slug: creator.slug,
      name: creator.name,
      // La photo publique est tenue par author-photo-sync : sans valeur dans la demande, on garde l'actuelle.
      photo_url: creator.photo_url ?? current?.photo_url ?? null,
      institution: creator.institution ?? null,
      country: creator.country ?? null,
      links: creator.links ?? current?.links ?? {},
      title: { ...(current?.title ?? {}), ...(creator.title ? { [originLang]: creator.title } : {}) },
      bio: { ...(current?.bio ?? {}), ...(creator.bio ? { [originLang]: creator.bio } : {}) },
      verified: creator.verified ?? false,
      updated_at: new Date().toISOString(),
    }, { onConflict: "slug" });
    if (creatorError) return json({ error: "creator_failed", detail: creatorError.message }, 500);
    course.author = creator.slug;
  }

  // Un cours nouveau n'est pas visible tant que l'usine n'a pas livré son quiz et son glossaire ;
  // une correction d'un cours publié remplace tout de suite le texte d'origine.
  const contentStatus = isNew ? "in_production" : (existing?.status === "published" ? "published" : "in_production");
  const glossary: Record<string, unknown> = {};
  for (const entry of (course.glossary ?? []) as { term: string; classification: string; explanation: string }[]) {
    glossary[entry.term] = { displayTerm: entry.term, classification: entry.classification, explanation: entry.explanation };
  }
  const { data: upsert, error: upsertError } = await supabase.rpc("catalog_upsert_course", {
    p_lang: originLang,
    p_course: course,
    p_quiz: body.quiz ?? [],
    p_glossary: glossary,
    p_status: contentStatus,
    p_creator_slug: creator?.slug ?? null,
    p_cover_slug: course.hero?.image ?? null,
    p_with_assets: true,
  });
  if (upsertError) return json({ error: "upsert_failed", detail: upsertError.message }, 500);
  if (isNew) {
    await supabase.from("courses").update({ status: "in_production", origin_lang: originLang, published_at: null }).eq("id", courseId);
  }

  const { data: job, error: jobError } = await supabase.from("production_jobs").insert({
    course_id: courseId,
    origin_lang: originLang,
    kind,
    status: "queued",
    requested_by: typeof body.requested_by === "string" ? body.requested_by : "studio",
    payload: {
      course,
      creator: creator ?? null,
      sources: course.sources ?? null,
      quiz: body.quiz ?? null,
      glossary: course.glossary ?? null,
      images_to_import: imagesToImport,
      previous_content: existing?.content ?? null,
    },
    options: { languages: targets, skip_audio: options.skip_audio === true, is_new: isNew },
  }).select("id").single();
  if (jobError || !job) return json({ error: "job_failed", detail: jobError?.message }, 500);

  const steps: { job_id: string; step: string; lang: string | null }[] = [
    { job_id: job.id, step: "quiz", lang: null },
    { job_id: job.id, step: "glossary", lang: null },
    { job_id: job.id, step: "cover", lang: null },
  ];
  for (const lang of targets) {
    steps.push({ job_id: job.id, step: "translate", lang }, { job_id: job.id, step: "gate", lang });
  }
  steps.push({ job_id: job.id, step: "audio", lang: "fr" }, { job_id: job.id, step: "audio", lang: "en" });
  steps.push({ job_id: job.id, step: "publish", lang: null });
  const { error: stepsError } = await supabase.from("production_steps").insert(steps);
  if (stepsError) return json({ error: "steps_failed", detail: stepsError.message }, 500);

  return json({
    course_id: courseId,
    job_id: job.id,
    status: "queued",
    origin_lang: originLang,
    languages: targets,
    content: upsert,
    steps: steps.length,
    note: "L'usine démarre dans les cinq minutes (jobs-dispatch) ; chaque étape est annoncée au webhook du Studio.",
  }, 202);
});
