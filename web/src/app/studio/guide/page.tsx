import { redirect } from "next/navigation";
import { StudioHeader } from "@/components/studio/StudioChrome";
import { Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { renderMarkdown } from "@/lib/markdown";
import { getStudioSession } from "@/lib/studio/account";

export const dynamic = "force-dynamic";

export default async function GuidePage() {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/guide");
  const { data } = await session.supabase.from("studio_documents").select("version,title,body_md").eq("slug", "writing-guide").eq("lang", "en").order("version", { ascending: false }).limit(1).maybeSingle();
  const doc = data as { version: number; title: string; body_md: string } | null;
  return (
    <>
      <StudioHeader session={session} active="guide" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <div className="flex flex-col gap-1.5">
          <h1 className="text-[32px] font-extrabold tracking-[-0.8px] text-ink">{doc?.title ?? s.guidePage.title}</h1>
          <p className="text-[16px] text-ink-3">{s.onboarding.guide.lead}</p>
        </div>
        <Card className="prose-course max-w-[820px] p-8">{doc ? renderMarkdown(doc.body_md) : <p className="text-muted">The guide is not available yet.</p>}</Card>
      </main>
    </>
  );
}
