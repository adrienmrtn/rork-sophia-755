// Les statistiques pour le Studio : GET /course-stats-export?days=90&month=2026-11&course_id=…&creator=…
// (en-tête x-api-key = PUBLISH_API_KEY). Par cours et par langue sur la fenêtre : impressions,
// ouvertures, terminés, terminés pour 1 000 impressions, j'aime, abonnés gagnés, décrochage par
// section. Par créateur et par mois : minutes de lecture des abonnés Premium (lectures
// plausibles seulement, jamais celles du créateur sur ses cours) et revenu net Premium du mois.
// Appuie la fonction SQL course_stats_bundle. Contrat : docs/publish-contract.md.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-api-key",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

function json(body: unknown, status = 200, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8", ...extra },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405);
  const apiKey = Deno.env.get("PUBLISH_API_KEY");
  if (!apiKey) return json({ error: "not_configured", detail: "Secret PUBLISH_API_KEY absent de la fonction." }, 500);
  if (req.headers.get("x-api-key") !== apiKey) return json({ error: "unauthorized" }, 401);

  const params = new URL(req.url).searchParams;
  const days = Math.max(1, Math.min(365, parseInt(params.get("days") ?? "90", 10) || 90));
  const monthParam = params.get("month");
  if (monthParam && !/^\d{4}-\d{2}$/.test(monthParam)) return json({ error: "bad_month", detail: "month = AAAA-MM" }, 400);
  const month = monthParam ? `${monthParam}-01` : new Date().toISOString().slice(0, 8) + "01";
  const courseId = params.get("course_id");
  const creator = params.get("creator");
  if (courseId && !/^course_[0-9]+_[a-z0-9_]+$/.test(courseId)) return json({ error: "bad_course_id" }, 400);
  if (creator && !/^[a-z0-9][a-z0-9-]{1,59}$/.test(creator)) return json({ error: "bad_creator" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const { data, error } = await supabase.rpc("course_stats_bundle", {
    p_days: days,
    p_month: month,
    p_course_id: courseId,
    p_creator: creator,
  });
  if (error) return json({ error: "stats_failed", detail: error.message }, 500);
  return json(data, 200, { "Cache-Control": "private, max-age=300" });
});
