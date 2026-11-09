import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { SUPABASE_KEY, SUPABASE_URL } from "@/lib/env";

/** Le client Supabase d'une requête serveur : la session de l'utilisateur, donc ses droits (RLS). */
export async function createClient() {
  const store = await cookies();
  return createServerClient(SUPABASE_URL, SUPABASE_KEY, {
    cookies: {
      getAll() {
        return store.getAll();
      },
      setAll(list) {
        try {
          for (const { name, value, options } of list) store.set(name, value, options);
        } catch {
          // Appelé depuis un composant serveur : le proxy rafraîchit la session, rien à faire ici.
        }
      },
    },
  });
}

/** Le client sans session : lecture publique du catalogue (politiques « public_read »). */
export function createAnonClient() {
  return createServerClient(SUPABASE_URL, SUPABASE_KEY, {
    cookies: { getAll: () => [], setAll: () => {} },
  });
}
