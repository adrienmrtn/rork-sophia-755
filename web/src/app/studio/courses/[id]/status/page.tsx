import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { StatusPill, StudioHeader } from "@/components/studio/StudioChrome";
import { JobSteps, JobSummary } from "@/components/studio/JobSteps";
import { ButtonLink, Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { getStudioSession } from "@/lib/studio/account";
import { getDraft, getJob, listReviews, shortDateTime } from "@/lib/studio/data";
import { withdrawAndEdit } from "@/app/studio/courses/[id]/actions";

export const dynamic = "force-dynamic";

const DECISION_LABEL: Record<string, string> = {
  submitted: "Sent for review",
  withdrawn: "Withdrawn by the author",
  changes_requested: "Changes requested",
  accepted: "Accepted by the team",
  rejected: "Declined",
  reopened: "Reopened for editing",
  published: "Production finished",
  publish_failed: "Production failed",
  note: "Note from the team",
};

const STATUS_LEAD: Record<string, string> = {
  draft: "A draft only you can see.",
  submitted: "The team reads it within 72 hours. You will see their decision here, and by email.",
  changes_requested: "The team asks for changes. Open the editor, fix, and send again.",
  accepted: "Accepted. The team launches production; the factory then translates it into 29 languages.",
  publishing: "The factory is working: glossary, quiz, cover, translations, quality gates, publication.",
  published: "Published in the app. Readers' statistics appear on your dashboard within a day.",
  failed: "Production stopped on an error. The team has been notified and will relaunch it.",
  archived: "Archived.",
};

/** Le suivi d'un cours envoyé : l'historique des décisions, puis la production langue par langue. */
export default async function StatusPage({ params, searchParams }: PageProps<"/studio/courses/[id]/status">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/courses");
  const { id } = await params;
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const draft = await getDraft(session.supabase, id);
  if (!draft) notFound();
  const [reviews, job] = await Promise.all([listReviews(session.supabase, id), draft.last_job_id ? getJob(session.supabase, draft.last_job_id) : null]);
  const editable = draft.status === "draft" || draft.status === "changes_requested";

  return (
    <>
      <StudioHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <Link href="/studio/courses" className="text-[13px] font-bold text-blue">
          ← {s.courses.title}
        </Link>
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="flex flex-col gap-2">
            <StatusPill status={draft.status} />
            <h1 className="text-[30px] font-extrabold tracking-[-0.7px] text-ink">{draft.title || s.courses.untitled}</h1>
            <p className="max-w-[640px] text-[15px] text-ink-3">{STATUS_LEAD[draft.status]}</p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {editable && (
              <ButtonLink href={`/studio/courses/${draft.id}`} variant="primary">
                {s.courses.openEditor}
              </ButtonLink>
            )}
            {draft.status === "submitted" && (
              <form action={withdrawAndEdit}>
                <input type="hidden" name="id" value={draft.id} />
                <button type="submit" className="inline-flex h-11 items-center rounded-btn border border-line bg-white px-[18px] text-[15px] font-bold text-navy hover:bg-paper">
                  Withdraw and edit
                </button>
              </form>
            )}
            {draft.status === "published" && draft.app_course_id && (
              <ButtonLink href={`/studio/courses/app/${encodeURIComponent(draft.app_course_id)}`} variant="secondary">
                Readers and statistics
              </ButtonLink>
            )}
          </div>
        </div>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {draft.status === "changes_requested" && draft.review_comment && (
          <Card className="flex flex-col gap-2 border-red-bg bg-red-bg/40 p-6">
            <strong className="text-[13px] font-bold uppercase tracking-[1px] text-red">The team asks</strong>
            <p className="whitespace-pre-wrap text-[15px] leading-[1.55] text-ink">{draft.review_comment}</p>
          </Card>
        )}

        <div className="grid grid-cols-1 gap-5 lg:grid-cols-[3fr_2fr]">
          <Card className="flex flex-col gap-5 p-6">
            <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Production</h2>
            {job ? (
              <>
                <JobSummary job={job.job} />
                <JobSteps steps={job.steps} />
              </>
            ) : (
              <p className="text-[14px] text-muted">{draft.status === "accepted" ? "The team will launch production shortly." : "Production starts once the team accepts the course."}</p>
            )}
          </Card>
          <Card className="flex flex-col gap-4 p-6">
            <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">History</h2>
            <ol className="flex flex-col gap-3">
              {reviews.length === 0 && <li className="text-[14px] text-muted">Nothing yet. Send the course for review when it is ready.</li>}
              {reviews.map((r) => (
                <li key={r.id} className="flex flex-col gap-0.5 border-l-2 border-line pl-3">
                  <span className="text-[14px] font-bold text-ink">{DECISION_LABEL[r.decision] ?? r.decision}</span>
                  <span className="text-[12px] text-muted">{shortDateTime(r.created_at)}</span>
                  {r.comment && <p className="mt-1 whitespace-pre-wrap text-[14px] leading-[1.5] text-ink-2">{r.comment}</p>}
                </li>
              ))}
            </ol>
          </Card>
        </div>
      </main>
    </>
  );
}
