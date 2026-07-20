// Edge Function: delete-user
//
// Supprime définitivement le compte de l'utilisateur appelant (Sign in with Apple exige une
// suppression de compte in-app). L'utilisateur est identifié via son JWT (transmis
// automatiquement par `supabase.functions.invoke("delete-user")` côté iOS). La suppression
// est faite avec la clé `service_role` (jamais exposée au client) ; la cascade DB retire
// aussi les lignes `public.profiles` et `public.user_progress`.
//
// Déploiement (à faire côté projet Supabase, non exécuté par l'agent) :
//   supabase functions deploy delete-user
// Les variables SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY sont injectées
// automatiquement dans le runtime des Edge Functions.

import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing authorization header" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Client "utilisateur" : sert uniquement à résoudre l'identité depuis le JWT.
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return json({ error: "Invalid or expired session" }, 401);
    }

    // Client admin : suppression effective (cascade sur profiles / user_progress).
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);

    if (deleteError) {
      return json({ error: deleteError.message }, 500);
    }

    return json({ success: true }, 200);
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
