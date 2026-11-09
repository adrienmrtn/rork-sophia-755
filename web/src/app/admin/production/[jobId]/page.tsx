import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { AdminHeader } from "@/components/admin/AdminChrome";
import { JobSteps, JobSummary } from "@/components/studio/JobSteps";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { getJob, shortDateTime } from "@/lib/studio/data";

export const dynamic = "force-dynamic";

/** Un job de l'usine dans le détail : chaque étape, son état, ce qu'elle a rapporté. */
export default async function JobPage({ params }: PageProps<"/admin/production/[jobId]">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const { jobId } = await params;
  const res = await getJob(session.supabase, jobId);
  if (!res) notFound();
  const { job, steps } = res;
  const { data: draft } = await session.supabase.from("studio_drafts").select("id,title").eq("last_job_id", jobId).maybeSingle();
  const d = draft as { id: string; title: string } | null;
  const summary = job.summary ?? {};
  const failed = (summary.failed ?? {}) as Record<string, string[]>;

  return (
    <>
      <AdminHeader session={session} active="production" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <Link href="/admin/production" className="text-[13px] font-bold text-blue">
          ← Production
        </Link>
        <div className="flex flex-col gap-2">
          <span className="font-mono text-[12px] text-muted">{job.id}</span>
          <h1 className="text-[28px] font-extrabold tracking-[-0.6px] text-ink">
            {d ? (
              <Link href={`/admin/review/${d.id}`} className="hover:text-navy">
                {d.title || "Untitled course"}
              </Link>
            ) : (
              job.course_id
            )}
          </h1>
          <span className="text-[13px] text-ink-3">
            {job.course_id} · origin {job.origin_lang.toUpperCase()} · {(job.options?.languages as string[] | undefined)?.length ?? 0} target languages · {job.options?.skip_audio ? "no narration" : "narration"} · {job.options?.is_new ? "new course" : "update"}
          </span>
          <JobSummary job={job} />
        </div>
        <Card className="flex flex-col gap-4 p-6">
          <JobSteps steps={steps} />
        </Card>
        {Object.keys(failed).length > 0 && (
          <Card className="flex flex-col gap-2 border-red-bg p-6">
            <h2 className="text-[16px] font-extrabold text-red">Languages held back</h2>
            <ul className="flex flex-col gap-1 text-[13px] text-ink-2">
              {Object.entries(failed).map(([lang, reasons]) => (
                <li key={lang}>
                  <strong className="uppercase">{lang}</strong> · {Array.isArray(reasons) ? reasons.join(" ; ") : String(reasons)}
                </li>
              ))}
            </ul>
            <p className="text-[12px] text-muted">Relaunch from the course page once the text is fixed, or run the workflow with this job id to retry the held languages.</p>
          </Card>
        )}
        <Card className="flex flex-col gap-3 p-6">
          <h2 className="text-[16px] font-extrabold">Steps in detail</h2>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] border-collapse text-[13px]">
              <thead>
                <tr className="text-left text-[11px] font-bold uppercase tracking-[.8px] text-muted">
                  <th className="py-2 pr-3 font-bold">Step</th>
                  <th className="py-2 pr-3 font-bold">Lang</th>
                  <th className="py-2 pr-3 font-bold">Status</th>
                  <th className="py-2 pr-3 font-bold">Started</th>
                  <th className="py-2 pr-3 font-bold">Finished</th>
                  <th className="py-2 font-bold">Detail</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line align-top">
                {steps.map((s) => (
                  <tr key={s.id}>
                    <td className="py-2 pr-3 font-semibold">{s.step}</td>
                    <td className="py-2 pr-3 uppercase">{s.lang ?? "–"}</td>
                    <td className={`py-2 pr-3 font-bold ${s.status === "failed" ? "text-red" : s.status === "done" ? "text-green" : "text-ink-3"}`}>{s.status}</td>
                    <td className="py-2 pr-3 text-ink-3">{s.started_at ? shortDateTime(s.started_at) : "–"}</td>
                    <td className="py-2 pr-3 text-ink-3">{s.finished_at ? shortDateTime(s.finished_at) : "–"}</td>
                    <td className="py-2">
                      {Object.keys(s.detail ?? {}).length > 0 && <pre className="max-h-40 max-w-[520px] overflow-auto whitespace-pre-wrap rounded-lg bg-paper p-2 font-mono text-[11px] text-ink-2">{JSON.stringify(s.detail, null, 1)}</pre>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
        {Object.keys(summary).length > 0 && (
          <Card className="flex flex-col gap-2 p-6">
            <h2 className="text-[16px] font-extrabold">Summary</h2>
            <pre className="max-h-[420px] overflow-auto whitespace-pre-wrap rounded-lg bg-paper p-3 font-mono text-[11px] text-ink-2">{JSON.stringify(summary, null, 2)}</pre>
          </Card>
        )}
      </main>
    </>
  );
}
