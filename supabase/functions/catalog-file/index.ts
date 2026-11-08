// Un fichier du catalogue, produit par la base : GET /catalog-file?lang=fr&kind=catalog&h=<hash>
//   kind = catalog | quizzes | glossary        (fonction SQL catalog_file)
//   kind = course&id=<courseId>                (fonction SQL course_bundle)
//
// Le manifeste (catalog-manifest) donne ces URL quand aucun objet Storage n'existe pour le
// fichier. Avec `h` (le hash courant du fichier, dans l'URL), la réponse est immuable et peut
// être gardée un an par le client ; sans `h`, cinq minutes.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const LANG = /^[a-z]{2}(-[A-Z]{2})?$/;
const COURSE_ID = /^[a-z0-9_]{3,120}$/;
const HASH = /^[a-f0-9]{8,64}$/;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, if-none-match",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

function json(body: unknown, status: number, extra: Record<string, string> = {}): Response {
  return new Response(typeof body === "string" ? body : JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8", ...extra },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405);

  const params = new URL(req.url).searchParams;
  const lang = params.get("lang") ?? "";
  const kind = params.get("kind") ?? "";
  const id = params.get("id") ?? "";
  const hash = params.get("h") ?? "";
  if (!LANG.test(lang)) return json({ error: "bad_lang" }, 400);
  if (!["catalog", "quizzes", "glossary", "course"].includes(kind)) return json({ error: "bad_kind" }, 400);
  if (kind === "course" && !COURSE_ID.test(id)) return json({ error: "bad_id" }, 400);
  if (hash && !HASH.test(hash)) return json({ error: "bad_hash" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const { data, error } = kind === "course"
    ? await supabase.rpc("course_bundle", { p_lang: lang, p_course_id: id })
    : await supabase.rpc("catalog_file", { p_lang: lang, p_kind: kind });
  if (error) {
    console.error("catalog-file", kind, lang, id, error);
    return json({ error: "file_failed" }, 500);
  }
  if (data === null || data === undefined) return json({ error: "not_found" }, 404);

  const body = JSON.stringify(data);
  const etag = `"${hash || (kind === "course" ? (data as { hash?: string }).hash ?? "" : "")}"`;
  const headers: Record<string, string> = {
    // Le hash est dans l'URL : le contenu ne change jamais pour cette adresse.
    "Cache-Control": hash ? "public, max-age=31536000, immutable" : "public, max-age=300",
    "X-Catalog-Bytes": String(body.length),
  };
  if (etag !== '""') {
    headers["ETag"] = etag;
    if (req.headers.get("if-none-match") === etag) {
      return new Response(null, { status: 304, headers: { ...corsHeaders, ...headers } });
    }
  }
  return json(body, 200, headers);
});
