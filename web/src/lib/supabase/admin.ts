import "server-only";
import { createClient } from "@supabase/supabase-js";
import { SUPABASE_URL } from "@/lib/env";

/** Le client à pleins droits : réservé aux actions de l'équipe (publication, photo publique).
 *  La clé est une « secret key » Supabase (sb_secret_…, Settings → API Keys), ou l'ancienne
 *  service_role. Jamais importé côté client (server-only). */
export function createAdminClient() {
  const key = process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!key) throw new Error("SUPABASE_SECRET_KEY manquant : la publication depuis le Studio est indisponible.");
  return createClient(SUPABASE_URL, key, { auth: { persistSession: false, autoRefreshToken: false } });
}
