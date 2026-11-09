import { redirect } from "next/navigation";
import { ArtPanel } from "@/components/studio/Art";
import { PageTitle, StudioHeader } from "@/components/studio/StudioChrome";
import { Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { renderMarkdown } from "@/lib/markdown";
import { getStudioSession } from "@/lib/studio/account";
import { createDraft } from "@/app/studio/actions";

export const dynamic = "force-dynamic";

export default async function GuidePage() {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/guide");
  const { data } = await session.supabase.from("studio_documents").select("version,title,body_md").eq("slug", "writing-guide").eq("lang", "en").order("version", { ascending: false }).limit(1).maybeSingle();
  const doc = data as { version: number; title: string; body_md: string } | null;
  return (
    <>
      <StudioHeader session={session} active="guide" />
      <main className={`${container} flex flex-1 flex-col gap-7 pt-7 pb-20`}>
        <PageTitle eyebrow="Reference" title={doc?.title ?? s.guidePage.title} lead={s.onboarding.guide.lead} />
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
          <Card className="prose-course p-8 md:p-10">{doc ? renderMarkdown(doc.body_md) : <p className="text-muted">The guide is not available yet.</p>}</Card>
          <div className="flex flex-col gap-5 lg:sticky lg:top-24 lg:self-start">
            <ArtPanel name="studio_guide" title="The rules, in one line" size={240}>
              One question, one answer. 500 to 900 words in two to twelve sections, the first one free. Sources, royalty-free images, one key takeaway at the end.
            </ArtPanel>
            <form action={createDraft}>
              <button type="submit" className="inline-flex h-11 w-full items-center justify-center rounded-full bg-navy px-5 text-[15px] font-bold text-white transition-colors hover:bg-ink">
                {s.nav.write}
              </button>
            </form>
          </div>
        </div>
      </main>
    </>
  );
}
