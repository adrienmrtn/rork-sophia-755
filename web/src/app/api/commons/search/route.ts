import { NextResponse } from "next/server";
import { getStudioSession } from "@/lib/studio/account";

export const dynamic = "force-dynamic";

/** La recherche d'images sur Wikimedia Commons pour l'éditeur : titre, aperçu, grande taille,
 *  auteur, licence, page. Réservée aux comptes connectés (le Studio), 24 résultats. */

export interface CommonsImage {
  title: string;
  thumb: string;
  large: string;
  width: number;
  height: number;
  author: string;
  license: string;
  description: string;
  /** La légende prête à l'emploi, dérivée de la description Commons. */
  caption: string;
  pageUrl: string;
}

const UA = "SophiaStudio/1.0 (https://sophia-culture.com; studio image search)";

function stripTags(html: string | undefined): string {
  return (html ?? "").replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

/** La légende affichée sous l'image : la description Commons, sans balisage ni tiret cadratin,
 *  coupée à la première phrase au-delà de 160 caractères, 240 au plus. */
function captionFrom(description: string, title: string): string {
  let text = description.replace(/[—–]/g, ", ").replace(/\[\[|\]\]|\*\*/g, "").replace(/\s+,/g, ",").replace(/\s+/g, " ").trim();
  if (!text) text = title.replace(/^File:/, "").replace(/\.[a-z0-9]+$/i, "").replace(/[_]+/g, " ").trim();
  if (text.length > 160) {
    const cut = text.slice(0, 240);
    const end = Math.max(cut.lastIndexOf(". "), cut.lastIndexOf("; "));
    text = end > 60 ? cut.slice(0, end + 1) : cut.replace(/\s+\S*$/, "") + "…";
  }
  return text;
}

export async function GET(request: Request) {
  const session = await getStudioSession();
  if (!session) return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  const q = new URL(request.url).searchParams.get("q")?.trim().slice(0, 200) ?? "";
  if (q.length < 2) return NextResponse.json({ results: [] });
  const params = new URLSearchParams({
    action: "query",
    generator: "search",
    gsrsearch: `filetype:bitmap ${q}`,
    gsrnamespace: "6",
    gsrlimit: "24",
    prop: "imageinfo",
    iiprop: "url|extmetadata|size",
    iiurlwidth: "1600",
    iiextmetadatafilter: "Artist|LicenseShortName|ImageDescription|ObjectName|Credit",
    format: "json",
    formatversion: "2",
  });
  try {
    const res = await fetch(`https://commons.wikimedia.org/w/api.php?${params}`, { headers: { "User-Agent": UA, Accept: "application/json" }, next: { revalidate: 0 } });
    if (!res.ok) return NextResponse.json({ error: `commons_${res.status}` }, { status: 502 });
    const body = (await res.json()) as { query?: { pages?: Record<string, unknown>[] } };
    const pages = body.query?.pages ?? [];
    const results: CommonsImage[] = [];
    for (const page of pages) {
      const p = page as { title?: string; imageinfo?: { thumburl?: string; url?: string; width?: number; height?: number; descriptionurl?: string; extmetadata?: Record<string, { value?: string }> }[] };
      const info = p.imageinfo?.[0];
      if (!info?.thumburl) continue;
      if (/\.(svg|tiff?|pdf|djvu)$/i.test(p.title ?? "") && !info.thumburl) continue;
      const meta = info.extmetadata ?? {};
      const large = info.thumburl;
      const thumb = large.replace(/\/1600px-/, "/400px-");
      results.push({
        title: (p.title ?? "").replace(/^File:/, ""),
        thumb,
        large,
        width: info.width ?? 0,
        height: info.height ?? 0,
        author: stripTags(meta.Artist?.value).slice(0, 200),
        license: stripTags(meta.LicenseShortName?.value).slice(0, 80),
        description: stripTags(meta.ImageDescription?.value || meta.ObjectName?.value).slice(0, 300),
        caption: captionFrom(stripTags(meta.ImageDescription?.value || meta.ObjectName?.value), p.title ?? ""),
        pageUrl: info.descriptionurl ?? `https://commons.wikimedia.org/wiki/${encodeURIComponent(p.title ?? "")}`,
      });
    }
    return NextResponse.json({ results }, { headers: { "Cache-Control": "private, max-age=300" } });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "fetch_failed" }, { status: 502 });
  }
}
