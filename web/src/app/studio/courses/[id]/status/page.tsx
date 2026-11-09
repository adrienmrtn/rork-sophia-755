import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Art, type ArtName } from "@/components/studio/Art";
import { StatusPill, StudioHeader } from "@/components/studio/StudioChrome";
import { JobSteps, JobSummary } from "@/components/studio/JobSteps";
import { ButtonLink, Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { getStudioSession } from "@/lib/studio/account";
import { getDraft, getJob, listReviews, shortDate, shortDateTime } from "@/lib/studio/data";
import { moneyCents } from "@/lib/studio/payments";
import { deleteProposal, updateProposal } from "@/app/studio/actions";
import { withdrawAndEdit } from "@/app/studio/courses/[id]/actions";

export const dynamic = "force-dynamic";

const DECISION_LABEL: Record<string, string> = {
  proposed: "Proposal sent",
  proposal_accepted: "Proposal accepted: you can write",
  proposal_returned: "Proposal returned by the team",
  submitted: "Sent for review",
  withdrawn: "Withdrawn by the author",
  changes_requested: "Changes requested",
  accepted: "Validated by the team",
  validated: "Added to your pot",
  rejected: "Declined",
  reopened: "Reopened for editing",
  published: "Production finished",
  publish_failed: "Production failed",
  note: "Note from the team",
};

const STATUS_LEAD: Record<string, string> = {
  proposed: "The team reads proposals within 72 hours. Accepted, the editor opens; returned, you will find their note here.",
  proposal_returned: "The team returned your proposal with a note. Edit the title or the pitch and send it again, or delete it.",
  draft: "A draft only you can see.",
  submitted: "The team reads it within 72 hours. You will see their decision here, and by email.",
  changes_requested: "The team asks for changes. Open the editor, fix, and send again.",
  accepted: "Validated: $15 are in your pot. The team launches production; the factory then translates it into 29 languages.",
  publishing: "The factory is working: glossary, quiz, cover, translations, quality gates, publication.",
  published: "Published in the app. Readers' statistics appear on your dashboard within a day.",
  failed: "Production stopped on an error. The team has been notified and will relaunch it.",
  archived: "Archived.",
};

const STATUS_ART: Record<string, ArtName> = { proposed: "studio_review", proposal_returned: "studio_review", draft: "studio_desk", submitted: "studio_review", changes_requested: "studio_review", accepted: "studio_review", publishing: "studio_production", published: "studio_stats", failed: "studio_production", archived: "studio_empty" };

/** Le suivi d'un cours : la proposition et la réponse de l'équipe, puis l'historique des
 *  décisions et la production langue par langue. */
export default async function StatusPage({ params, searchParams }: PageProps<"/studio/courses/[id]/status">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/courses");
  const { id } = await params;
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const draft = await getDraft(session.supabase, id);
  if (!draft) notFound();
  const [reviews, job] = await Promise.all([listReviews(session.supabase, id), draft.last_job_id ? getJob(session.supabase, draft.last_job_id) : null]);
  const editable = draft.status === "draft" || draft.status === "changes_requested";
  const isProposal = draft.status === "proposed" || draft.status === "proposal_returned";
  const p = s.proposal;
  const fee = moneyCents(session.quota?.fee_cents ?? 1500, session.quota?.currency ?? "USD");

  return (
    <>
      <StudioHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-7 pb-20`}>
        <Link href="/studio/courses" className="text-[13px] font-bold text-blue">
          ← {s.courses.title}
        </Link>
        <section className="grid grid-cols-1 items-center gap-6 rounded-[28px] border border-cream-2 bg-cream p-7 md:grid-cols-[minmax(0,1fr)_200px] md:p-8">
          <div className="flex flex-col gap-3">
            <StatusPill status={draft.status} />
            <h1 className="text-[30px] font-extrabold leading-[1.1] tracking-[-0.7px] text-ink">{draft.title || s.courses.untitled}</h1>
            <p className="max-w-[640px] text-[15px] leading-[1.55] text-ink-2">{STATUS_LEAD[draft.status]}</p>
            <div className="flex flex-wrap items-center gap-2 pt-1">
              {editable && (
                <ButtonLink href={`/studio/courses/${draft.id}`} variant="primary" className="!rounded-full">
                  {s.courses.openEditor}
                </ButtonLink>
              )}
              {draft.status === "submitted" && (
                <form action={withdrawAndEdit}>
                  <input type="hidden" name="id" value={draft.id} />
                  <button type="submit" className="inline-flex h-11 items-center rounded-full border border-line bg-white px-5 text-[15px] font-bold text-navy transition-colors hover:bg-paper">
                    Withdraw and edit
                  </button>
                </form>
              )}
              {draft.status === "published" && draft.app_course_id && (
                <ButtonLink href={`/studio/courses/app/${encodeURIComponent(draft.app_course_id)}`} variant="secondary" className="!rounded-full">
                  Readers and statistics
                </ButtonLink>
              )}
            </div>
            {draft.validated_at && (
              <p className="text-[13px] font-bold text-green">
                Validated {shortDate(draft.validated_at)} · {fee} in your pot, paid on Monday.
              </p>
            )}
          </div>
          <Art name={STATUS_ART[draft.status] ?? "studio_desk"} size={200} className="mx-auto md:mx-0" />
        </section>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {done === "proposed" && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">{p.sent}</p>}
        {draft.status === "changes_requested" && draft.review_comment && (
          <Card className="flex flex-col gap-2 border-red-bg bg-red-bg/40 p-6">
            <strong className="text-[13px] font-bold uppercase tracking-[1px] text-red">The team asks</strong>
            <p className="whitespace-pre-wrap text-[15px] leading-[1.55] text-ink">{draft.review_comment}</p>
          </Card>
        )}
        {draft.status === "proposal_returned" && draft.proposal_note && (
          <Card className="flex flex-col gap-2 border-red-bg bg-red-bg/40 p-6">
            <strong className="text-[13px] font-bold uppercase tracking-[1px] text-red">{p.returnedTitle}</strong>
            <p className="whitespace-pre-wrap text-[15px] leading-[1.55] text-ink">{draft.proposal_note}</p>
            <span className="text-[13px] text-ink-2">{p.returnedLead}</span>
          </Card>
        )}
        {!isProposal && draft.proposal_note && draft.status === "draft" && (
          <Card className="flex flex-col gap-2 border-tint bg-tint/50 p-6">
            <strong className="text-[13px] font-bold uppercase tracking-[1px] text-navy">{p.acceptedNote}</strong>
            <p className="whitespace-pre-wrap text-[15px] leading-[1.55] text-ink">{draft.proposal_note}</p>
          </Card>
        )}

        <div className="grid grid-cols-1 gap-5 lg:grid-cols-[3fr_2fr]">
          {isProposal ? (
            <Card className="flex flex-col gap-5 p-6">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Your proposal</h2>
              <form action={updateProposal} className="flex flex-col gap-4">
                <input type="hidden" name="id" value={draft.id} />
                <label className="flex flex-col gap-1.5">
                  <span className="text-[13px] font-bold text-ink-2">{p.titleField}</span>
                  <input name="title" defaultValue={draft.title} required minLength={8} maxLength={160} className="h-12 w-full rounded-xl border border-line bg-white px-4 text-[17px] font-bold text-ink outline-none focus:border-blue" />
                </label>
                <label className="flex flex-col gap-1.5">
                  <span className="text-[13px] font-bold text-ink-2">{p.pitchField}</span>
                  <textarea name="pitch" defaultValue={draft.pitch ?? ""} required minLength={40} maxLength={600} rows={6} className="w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-[15px] leading-[1.55] text-ink outline-none focus:border-blue" />
                  <span className="text-[12px] text-ink-3">{p.pitchHelp}</span>
                </label>
                <div className="flex flex-wrap items-center gap-3">
                  <button type="submit" className="inline-flex h-11 items-center rounded-full bg-navy px-5 text-[15px] font-bold text-white transition-colors hover:bg-ink">
                    {p.resend}
                  </button>
                  <button type="submit" formAction={deleteProposal} className="inline-flex h-11 items-center rounded-full border border-line bg-white px-5 text-[15px] font-bold text-red transition-colors hover:bg-red-bg">
                    {p.deleteIt}
                  </button>
                </div>
              </form>
            </Card>
          ) : (
            <Card className="flex flex-col gap-5 p-6">
              <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Production</h2>
              {job ? (
                <>
                  <JobSummary job={job.job} />
                  <JobSteps steps={job.steps} />
                </>
              ) : (
                <div className="flex items-center gap-4 rounded-2xl bg-paper p-4">
                  <Art name="studio_production" size={72} className="!rounded-xl" />
                  <p className="text-[14px] leading-[1.5] text-ink-3">{draft.status === "accepted" ? "The team will launch production shortly. Glossary, quiz, cover, then 29 translations checked one by one." : "Production starts once the team validates the course. It then runs about an hour."}</p>
                </div>
              )}
            </Card>
          )}
          <Card className="flex flex-col gap-4 p-6">
            <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">History</h2>
            <ol className="flex flex-col gap-3">
              {reviews.length === 0 && <li className="text-[14px] text-muted">Nothing yet.</li>}
              {reviews.map((r) => (
                <li key={r.id} className="flex gap-3">
                  <span aria-hidden="true" className={`mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full ${r.decision === "accepted" || r.decision === "validated" || r.decision === "published" || r.decision === "proposal_accepted" ? "bg-green-2" : r.decision === "changes_requested" || r.decision === "publish_failed" || r.decision === "rejected" || r.decision === "proposal_returned" ? "bg-coral" : "bg-line-2"}`} />
                  <span className="flex flex-col gap-0.5">
                    <span className="text-[14px] font-bold text-ink">{DECISION_LABEL[r.decision] ?? r.decision}</span>
                    <span className="text-[12px] text-muted">{shortDateTime(r.created_at)}</span>
                    {r.comment && r.decision !== "proposed" && <p className="mt-1 whitespace-pre-wrap text-[14px] leading-[1.5] text-ink-2">{r.comment}</p>}
                  </span>
                </li>
              ))}
            </ol>
          </Card>
        </div>
      </main>
    </>
  );
}
