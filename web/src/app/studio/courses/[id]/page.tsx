import { notFound, redirect } from "next/navigation";
import { CourseEditor } from "@/components/studio/CourseEditor";
import { getStudioSession } from "@/lib/studio/account";
import { getDraft } from "@/lib/studio/data";
import type { DraftCourse } from "@/lib/studio/course-format";

export const dynamic = "force-dynamic";

/** L'éditeur d'un cours : la page charge le brouillon, le composant client fait le reste. */
export default async function EditorPage({ params }: PageProps<"/studio/courses/[id]">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/courses");
  const { id } = await params;
  const { account, agreementSigned } = session;
  if (!account) redirect("/studio/onboarding/identity");
  const draft = await getDraft(session.supabase, id);
  if (!draft) notFound();
  if (draft.status !== "draft" && draft.status !== "changes_requested") redirect(`/studio/courses/${id}/status`);

  const blockers: string[] = [];
  if (!account.slug || !account.display_name) blockers.push("Complete your author profile (name) before sending.");
  if (!agreementSigned) blockers.push("Sign the creator agreement before sending.");
  if (account.status === "suspended") blockers.push("Your account is suspended.");

  const course: DraftCourse = {
    title: draft.title,
    subtitle: draft.subtitle,
    subject: draft.subject,
    subcategory: draft.subcategory,
    description: draft.description,
    hero: draft.hero ?? {},
    sections: draft.sections ?? [],
    sources: draft.sources ?? [],
    glossary: draft.glossary ?? [],
  };

  return <CourseEditor draftId={draft.id} initial={course} status={draft.status} reviewComment={draft.review_comment} updatedAt={draft.updated_at} originLang={draft.origin_lang} blockers={blockers} onboardingHref={!agreementSigned ? "/studio/onboarding/agreement" : null} />;
}
