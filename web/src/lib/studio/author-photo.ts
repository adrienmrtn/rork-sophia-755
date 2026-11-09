import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";
import { STORAGE_PUBLIC } from "@/lib/env";
import type { CreatorAccount } from "./account";

/** La photo privée du Studio (bucket studio-photos) copiée dans le bucket public course-images sous
 *  le nom que les apps attendent (author_<slug>.<ext>). Rend l'adresse publique, ou null sans photo.
 *  Appelée à l'approbation du compte et à chaque publication, pour suivre une photo changée. */
export async function publishAuthorPhoto(admin: SupabaseClient, account: Pick<CreatorAccount, "slug" | "photo_path">): Promise<string | null> {
  if (!account.photo_path || !account.slug) return null;
  const { data: file } = await admin.storage.from("studio-photos").download(account.photo_path);
  if (!file) return null;
  const lower = account.photo_path.toLowerCase();
  const ext = lower.endsWith(".png") ? "png" : lower.endsWith(".webp") ? "webp" : "jpg";
  // Un nom horodaté : les apps gardent l'ancienne adresse en cache, une photo changée doit changer d'adresse.
  const dest = `author_${account.slug}_${Date.now().toString(36)}.${ext}`;
  const { error } = await admin.storage.from("course-images").upload(dest, file, { upsert: true, contentType: file.type || `image/${ext === "jpg" ? "jpeg" : ext}`, cacheControl: "86400" });
  if (error) return null;
  return `${STORAGE_PUBLIC}/course-images/${dest}`;
}

/** Après un changement de photo ou d'avatar dans le Studio : si le compte est approuvé, la page
 *  publique (creators.photo_url) et donc les apps suivent tout de suite. Sans clé serveur, rien. */
export async function syncPublicPhoto(account: Pick<CreatorAccount, "slug" | "photo_path" | "status">): Promise<void> {
  if (account.status !== "approved" || !account.slug || !account.photo_path) return;
  try {
    const { createAdminClient } = await import("@/lib/supabase/admin");
    const admin = createAdminClient();
    const url = await publishAuthorPhoto(admin, account);
    if (url) await admin.from("creators").update({ photo_url: url, updated_at: new Date().toISOString() }).eq("slug", account.slug);
  } catch {
    // Développement sans SUPABASE_SECRET_KEY : la photo publique attendra l'approbation ou la publication.
  }
}
