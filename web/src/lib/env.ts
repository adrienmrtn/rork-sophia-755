/** Réglages lus côté serveur et côté client. Les clés publiques ont une valeur par défaut :
 *  ce sont celles du projet Supabase de l'app, publiques par construction (RLS fait le reste). */
export const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "https://afnmcoovdvbtkgohtdij.supabase.co";
export const SUPABASE_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  "sb_publishable_eNzCyPFfEuKC0tKWr0Hjag_lJ_qsWRw";
export const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? "https://sophia-culture.com";
export const STORAGE_PUBLIC = `${SUPABASE_URL}/storage/v1/object/public`;
/** "supabase" (défaut) ou "starter" : le pack de départ des apps, pour travailler sans réseau. */
export const DATA_SOURCE = process.env.SOPHIA_DATA ?? "supabase";
export const APP_STORE_URL = process.env.NEXT_PUBLIC_APP_STORE_URL ?? "https://apps.apple.com/app/id6744889213";
export const PLAY_STORE_URL = process.env.NEXT_PUBLIC_PLAY_STORE_URL ?? "https://play.google.com/store/apps/details?id=app.rork.sophia";
