// Envoie les jobs de production en file à GitHub Actions (repository_dispatch « produce-course »)
// sans attendre le passage de pg_cron (toutes les cinq minutes) : POST /jobs-dispatch avec
// l'en-tête x-api-key = PUBLISH_API_KEY. Appuie la fonction SQL jobs_dispatch, qui lit le jeton
// GitHub dans le Vault (github_dispatch_token).

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-api-key",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const apiKey = Deno.env.get("PUBLISH_API_KEY");
  if (!apiKey) return json({ error: "not_configured", detail: "Secret PUBLISH_API_KEY absent de la fonction." }, 500);
  if (req.headers.get("x-api-key") !== apiKey) return json({ error: "unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const { data, error } = await supabase.rpc("jobs_dispatch", { p_limit: 10 });
  if (error) return json({ error: "dispatch_failed", detail: error.message }, 500);
  return json(data);
});
