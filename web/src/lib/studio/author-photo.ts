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
  const dest = `author_${account.slug}.${ext}`;
  const { error } = await admin.storage.from("course-images").upload(dest, file, { upsert: true, contentType: file.type || `image/${ext === "jpg" ? "jpeg" : ext}`, cacheControl: "86400" });
  if (error) return null;
  return `${STORAGE_PUBLIC}/course-images/${dest}`;
}
