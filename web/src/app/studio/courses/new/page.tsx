import { redirect } from "next/navigation";
import { Art } from "@/components/studio/Art";
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
        <Card className="grid w-full max-w-[860px] grid-cols-1 gap-8 border-cream-2 bg-cream p-8 md:grid-cols-[240px_minmax(0,1fr)] md:p-10">
          <Art name="studio_desk" size={240} className="mx-auto md:mx-0" priority />
          <div className="flex flex-col gap-5">
            <h1 className="text-[30px] font-extrabold leading-[1.1] tracking-[-0.7px] text-ink">{s.courses.newCourse}</h1>
            <p className="text-[16px] leading-[1.55] text-ink-2">{s.courses.empty}</p>
            <ul className="flex flex-col gap-2 text-[15px] text-ink-2">
              {["Write in your language; Sophia translates into the 29 others.", "2 to 12 sections, 500 to 900 words, one key takeaway at the end.", "Images from Wikimedia Commons, with their credit.", "The team reviews within 72 hours and the factory writes the quiz."].map((line) => (
                <li key={line} className="flex items-start gap-2.5">
                  <span aria-hidden="true" className="mt-[9px] h-1.5 w-1.5 shrink-0 rounded-full bg-saffron" />
                  {line}
                </li>
              ))}
            </ul>
            <div className="flex flex-wrap items-center gap-3 pt-1">
              <form action={createDraft}>
                <button type="submit" className="inline-flex h-11 items-center gap-2 rounded-full bg-navy px-5 text-[15px] font-bold text-white transition-colors hover:bg-ink">
                  Start writing
                </button>
              </form>
              <ButtonLink href="/studio/guide" variant="secondary" className="!rounded-full">
                {s.nav.guide}
              </ButtonLink>
            </div>
          </div>
        </Card>
      </main>
    </>
  );
}
