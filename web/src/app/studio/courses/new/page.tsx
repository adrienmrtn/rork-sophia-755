import { redirect } from "next/navigation";
import { StudioHeader } from "@/components/studio/StudioChrome";
import { ButtonLink, Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { getStudioSession } from "@/lib/studio/account";
import { createDraft } from "@/app/studio/actions";

export const dynamic = "force-dynamic";

/** Une page de confirmation : un GET (ou un préchargement) ne doit pas créer de brouillon. */
export default async function NewCoursePage() {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/courses/new");
  if (!session.account) redirect("/studio/onboarding/identity");
  return (
    <>
      <StudioHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col items-start gap-6 pt-10 pb-20`}>
        <Card className="flex max-w-[640px] flex-col gap-5 p-8">
          <h1 className="text-[28px] font-extrabold tracking-[-0.6px] text-ink">{s.courses.newCourse}</h1>
          <p className="text-[16px] leading-[1.55] text-ink-3">{s.courses.empty}</p>
          <ul className="flex flex-col gap-1.5 text-[15px] text-ink-2">
            <li>· Write in your language; Sophia translates into the 29 others.</li>
            <li>· 2 to 12 sections, 500 to 900 words, one key takeaway at the end.</li>
            <li>· Images from Wikimedia Commons, with their credit.</li>
            <li>· The team reviews within 72 hours and the factory writes the quiz.</li>
          </ul>
          <div className="flex flex-wrap items-center gap-3">
            <form action={createDraft}>
              <button type="submit" className="inline-flex h-11 items-center gap-2 rounded-btn bg-navy px-[18px] text-[15px] font-bold text-white hover:bg-ink">
                Start writing
              </button>
            </form>
            <ButtonLink href="/studio/guide" variant="secondary">
              {s.nav.guide}
            </ButtonLink>
          </div>
        </Card>
      </main>
    </>
  );
}
