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
/** Identifiant numérique de l'app sur l'App Store (bannière Safari « Ouvrir dans l'app »). */
export const APP_STORE_ID = process.env.NEXT_PUBLIC_APP_STORE_ID ?? "6744889213";
/** `<Team ID>.<bundle id>` de l'app iOS, pour le fichier d'association des liens universels. */
export const IOS_APP_ID = process.env.IOS_APP_ID ?? "K792T8TQ4X.app.rork.assvmps5x7hpyq0ezcsut";
/** Identifiant de l'app Android, pour le fichier d'association des liens d'app. */
export const ANDROID_PACKAGE = process.env.ANDROID_PACKAGE ?? "app.rork.sophia";
/** Empreintes SHA-256 des certificats qui signent l'app Android (Play Console, Intégrité de
 *  l'application : clé de signature d'application et clé d'importation), séparées par des
 *  virgules. Vide : aucun lien d'app n'est déclaré. */
export const ANDROID_APP_FINGERPRINTS = (process.env.ANDROID_APP_FINGERPRINTS ?? "")
  .split(",")
  .map((value) => value.trim().toUpperCase())
  .filter(Boolean);
