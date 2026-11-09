// La photo publique d'un auteur : copie la photo du Studio (bucket privé studio-photos) dans le
// bucket public course-images sous author_<slug>_<horodatage>.<ext>, puis met creators.photo_url
// à jour (page du site tout de suite ; apps au prochain manifeste, le catalogue étant recalculé
// dans la minute par catalog_refinalize_if_dirty).
//
// Appelée par la base (triggers creator_accounts_photo_sync / creator_accounts_approved_photo →
// author_photo_sync_request → pg_net) : POST {"request_id": "<uuid>"}. La demande
// (author_photo_requests) est à usage unique et vaut quinze minutes ; elle tient lieu
// d'authentification, d'où verify_jwt désactivé et aucun secret partagé. Clé serveur : celle que
// la plateforme donne à la fonction (SUPABASE_SERVICE_ROLE_KEY).

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const VALID_FOR_MS = 15 * 60_000;

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json; charset=utf-8" } });
}

async function fail(supabase: SupabaseClient, requestId: string, error: string, status: number): Promise<Response> {
  await supabase.from("author_photo_requests").update({ done_at: new Date().toISOString(), error }).eq("id", requestId);
  return json({ error }, status);
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let requestId = "";
  try {
    const body = (await req.json()) as { request_id?: unknown };
    requestId = typeof body?.request_id === "string" ? body.request_id : "";
  } catch {
    return json({ error: "bad_json" }, 400);
  }
  if (!UUID.test(requestId)) return json({ error: "bad_request_id" }, 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabase = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });

  const { data: request, error: reqErr } = await supabase
    .from("author_photo_requests")
    .select("id, user_id, created_at, done_at")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr) return json({ error: "request_lookup_failed", detail: reqErr.message }, 500);
  if (!request) return json({ error: "unknown_request" }, 404);
  if (request.done_at) return json({ error: "already_done" }, 409);
  if (Date.now() - new Date(request.created_at).getTime() > VALID_FOR_MS) return fail(supabase, requestId, "expired", 410);

  const { data: account } = await supabase
    .from("creator_accounts")
    .select("slug, photo_path, status")
    .eq("user_id", request.user_id)
    .maybeSingle();
  if (!account || account.status !== "approved" || !account.slug || !account.photo_path) {
    return fail(supabase, requestId, "account_not_ready", 422);
  }

  const { data: file, error: dlErr } = await supabase.storage.from("studio-photos").download(account.photo_path);
  if (dlErr || !file) return fail(supabase, requestId, `download: ${dlErr?.message ?? "empty"}`, 502);

  const lower = account.photo_path.toLowerCase();
  const ext = lower.endsWith(".png") ? "png" : lower.endsWith(".webp") ? "webp" : "jpg";
  const contentType = file.type || (ext === "jpg" ? "image/jpeg" : `image/${ext}`);
  // Un nom horodaté : les apps gardent l'ancienne adresse en cache, une photo changée change d'adresse.
  const dest = `author_${account.slug}_${Date.now().toString(36)}.${ext}`;
  const { error: upErr } = await supabase.storage.from("course-images").upload(dest, file, { upsert: true, contentType, cacheControl: "86400" });
  if (upErr) return fail(supabase, requestId, `upload: ${upErr.message}`, 502);

  const photoUrl = `${supabaseUrl}/storage/v1/object/public/course-images/${dest}`;
  const { data: updated, error: updErr } = await supabase
    .from("creators")
    .update({ photo_url: photoUrl, updated_at: new Date().toISOString() })
    .eq("slug", account.slug)
    .select("slug");
  if (updErr) return fail(supabase, requestId, `creators: ${updErr.message}`, 502);
  if (!updated || updated.length === 0) return fail(supabase, requestId, "no_public_page", 422);

  await supabase.from("author_photo_requests").update({ done_at: new Date().toISOString(), photo_url: photoUrl }).eq("id", requestId);
  return json({ ok: true, slug: account.slug, photo_url: photoUrl }, 200);
});
