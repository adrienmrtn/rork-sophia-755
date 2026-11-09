"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { savePhotoPath } from "@/app/studio/actions";
import { s } from "@/lib/copy/studio-en";
import { Initials } from "@/components/ui";

/** La photo de profil : téléversée par le navigateur dans le bucket privé studio-photos, sous le
 *  dossier de l'utilisateur (seule place où la règle d'accès l'autorise), puis le chemin est gardé. */
export function PhotoUpload({ userId, name, currentUrl }: { userId: string; name: string; currentUrl: string | null }) {
  const [preview, setPreview] = useState<string | null>(currentUrl);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const o = s.onboarding.profile;

  async function onFile(file: File | undefined) {
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      setError("The photo is heavier than 5 MB.");
      return;
    }
    setBusy(true);
    setError(null);
    const supabase = createClient();
    const ext = file.type === "image/png" ? "png" : file.type === "image/webp" ? "webp" : "jpg";
    const path = `${userId}/photo.${ext}`;
    const { error: upErr } = await supabase.storage.from("studio-photos").upload(path, file, { upsert: true, contentType: file.type, cacheControl: "3600" });
    if (upErr) {
      setError(upErr.message);
      setBusy(false);
      return;
    }
    const saved = await savePhotoPath(path);
    if (!saved.ok) setError(saved.error);
    else setPreview(URL.createObjectURL(file));
    setBusy(false);
  }

  return (
    <div className="flex flex-wrap items-center gap-5 border-b border-line pb-5">
      {preview ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={preview} alt="" className="h-24 w-24 shrink-0 rounded-full object-cover" />
      ) : (
        <Initials name={name} size={96} />
      )}
      <div className="flex min-w-[280px] flex-1 flex-col gap-2">
        <strong className="text-[15px] font-bold">{o.photo}</strong>
        <span className="text-[13px] leading-[1.5] text-ink-3">{o.photoHelp}</span>
        <div className="flex flex-wrap items-center gap-2">
          <label className={`inline-flex h-10 cursor-pointer items-center rounded-xl bg-navy px-3.5 text-[13px] font-bold text-white ${busy ? "opacity-60" : ""}`}>
            {busy ? "…" : o.choose}
            <input type="file" accept="image/jpeg,image/png,image/webp" className="sr-only" disabled={busy} onChange={(e) => onFile(e.target.files?.[0])} />
          </label>
          <span className="text-[13px] text-muted">{o.formats}</span>
        </div>
        {error && (
          <span role="alert" className="text-[13px] font-semibold text-red">
            {error}
          </span>
        )}
      </div>
    </div>
  );
}
