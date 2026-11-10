import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { SiteHeader } from "@/components/SiteChrome";
import { Eyebrow, container } from "@/components/ui";
import { createAnonClient } from "@/lib/supabase/server";
import { NOTICE_MD, PRIVACY_MD } from "@/lib/legal/texts";
import { renderMarkdown } from "@/lib/markdown";

export const dynamic = "force-dynamic";

/** Le contrat vient de la base (versionné, signé dans le Studio) ; la confidentialité et les mentions
 *  légales sont des textes du site (src/lib/legal/texts.ts). */
const DOCS: Record<string, { title: string; slug: string | null; md?: string }> = {
  "creator-agreement": { title: "Creator agreement", slug: "creator-agreement" },
  privacy: { title: "Privacy policy", slug: null, md: PRIVACY_MD },
  notice: { title: "Legal notice", slug: null, md: NOTICE_MD },
};

export async function generateMetadata({ params }: PageProps<"/legal/[doc]">): Promise<Metadata> {
  const { doc } = await params;
  return { title: DOCS[doc]?.title ?? "Legal" };
}

export default async function LegalPage({ params }: PageProps<"/legal/[doc]">) {
  const { doc } = await params;
  const entry = DOCS[doc];
  if (!entry) notFound();
  let body: string | null = entry.md ?? null;
  let version: number | null = null;
  if (entry.slug) {
    const sb = createAnonClient();
    const { data } = await sb.from("studio_documents").select("version,body_md").eq("slug", entry.slug).eq("lang", "en").order("version", { ascending: false }).limit(1).maybeSingle();
    body = (data?.body_md as string | undefined) ?? null;
    version = (data?.version as number | undefined) ?? null;
  }
  return (
    <>
      <SiteHeader />
      <main className={`${container} flex flex-col gap-6 pt-12 pb-24`}>
        <Eyebrow>Legal</Eyebrow>
        <h1 className="text-[40px] font-extrabold tracking-[-1px]">{entry.title}</h1>
        {body ? (
          <article className="prose-legal max-w-[760px] text-[16px] leading-[1.65] text-ink-2">
            {version && <p className="text-[13px] text-muted">Version {version}</p>}
            {renderMarkdown(body)}
          </article>
        ) : (
          entry.slug && <p className="text-[16px] text-ink-3">The agreement is available to signed-in authors in the Studio.</p>
        )}
      </main>
    </>
  );
}
