// Le manifeste du catalogue pour une langue : GET /catalog-manifest?lang=fr
//
// Renvoie le JSON de la fonction SQL public.catalog_manifest(lang) (fichiers de la langue et
// paquet de chaque cours publié, avec leur hash et leur chemin dans le bucket course-content),
// avec un cache de cinq minutes et un ETag : les apps relisent le manifeste au lancement et
// toutes les six heures, un 304 leur suffit quand rien n'a bougé. Pas de JWT exigé : le
// catalogue publié est public, comme les buckets d'images et d'audio.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const LANG = /^[a-z]{2}(-[A-Z]{2})?$/;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, if-none-match",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const lang = new URL(req.url).searchParams.get("lang") ?? "";
  if (!LANG.test(lang)) {
    return new Response(JSON.stringify({ error: "bad_lang" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const { data, error } = await supabase.rpc("catalog_manifest", { p_lang: lang });
  if (error) {
    console.error("catalog_manifest", error);
    return new Response(JSON.stringify({ error: "manifest_failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const manifest = data as Record<string, unknown>;
  // Chaque entrée reçoit son URL : l'objet Storage quand il existe (CDN, cache immuable),
  // sinon la fonction catalog-file qui produit le fichier depuis la base.
  const base = Deno.env.get("SUPABASE_URL")!.replace(/\/$/, "");
  type Entry = { hash: string; bytes?: number; path: string; storage?: boolean; url?: string };
  const withUrl = (entries: Record<string, Entry>, kindFor: (key: string) => string, idFor?: (key: string) => string) => {
    for (const [key, entry] of Object.entries(entries)) {
      entry.url = entry.storage
        ? `${base}/storage/v1/object/public/course-content/${entry.path}`
        : `${base}/functions/v1/catalog-file?lang=${encodeURIComponent(lang)}&kind=${kindFor(key)}` +
          (idFor ? `&id=${encodeURIComponent(idFor(key))}` : "") + `&h=${entry.hash}`;
      delete entry.storage;
    }
  };
  withUrl((manifest.files as Record<string, Entry>) ?? {}, (key) => key);
  withUrl((manifest.courses as Record<string, Entry>) ?? {}, () => "course", (key) => key);
  const courses = Object.keys((manifest.courses as Record<string, unknown>) ?? {}).length;
  // L'ETag ne dépend que du contenu, pas de generated_at : deux manifestes identiques
  // donnent le même ETag et le client garde sa copie.
  const stable = { ...manifest };
  delete stable.generated_at;
  const etag = `"${(await sha256Hex(JSON.stringify(stable))).slice(0, 32)}"`;
  const headers = {
    ...corsHeaders,
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "public, max-age=300, s-maxage=300",
    "ETag": etag,
    "X-Catalog-Courses": String(courses),
  };
  if (req.headers.get("if-none-match") === etag) {
    return new Response(null, { status: 304, headers });
  }
  return new Response(JSON.stringify(manifest), { status: 200, headers });
});
