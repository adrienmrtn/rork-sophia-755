import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { JOB_LABEL } from "@/components/studio/JobSteps";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime, type JobRow } from "@/lib/studio/data";

export const dynamic = "force-dynamic";

const LOOK: Record<JobRow["status"], string> = { queued: "bg-paper text-muted", dispatched: "bg-tint text-navy", running: "bg-tint text-navy", done: "bg-green-bg text-green", partial: "bg-amber-bg text-amber", failed: "bg-red-bg text-red" };

export default async function ProductionPage() {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const { supabase } = session;
  const [{ data: jobs }, { data: drafts }, { data: courses }] = await Promise.all([
    supabase.from("production_jobs").select("id,course_id,origin_lang,status,summary,error,options,created_at,dispatched_at,started_at,finished_at,requested_by").order("created_at", { ascending: false }).limit(60),
    supabase.from("studio_drafts").select("id,title,last_job_id").not("last_job_id", "is", null),
    supabase.from("courses").select("id,status,creator_slug,published_at,origin_lang").order("published_at", { ascending: false, nullsFirst: true }).limit(400),
  ]);
  const byJob = new Map(((drafts ?? []) as { id: string; title: string; last_job_id: string }[]).map((d) => [d.last_job_id, d]));
  const rows = (jobs ?? []) as (JobRow & { requested_by: string | null })[];
  const courseRows = (courses ?? []) as { id: string; status: string; creator_slug: string | null; published_at: string | null; origin_lang: string }[];
  const inProduction = courseRows.filter((c) => c.status === "in_production");
  const published = courseRows.filter((c) => c.status === "published").length;

  return (
    <>
      <AdminHeader session={session} active="production" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Production" lead={`${published} courses published in the app · ${inProduction.length} in production. Each job is one course through the factory (translations, quiz, glossary, cover, publication).`}>
          <a href="https://github.com/adrienmrtn/rork-sophia-755/actions/workflows/produce-course.yml" target="_blank" rel="noreferrer" className="text-[13px] font-bold text-blue">
            GitHub Actions → Produce course
          </a>
        </AdminTitle>
        <Card className="overflow-x-auto">
          <table className="w-full min-w-[860px] border-collapse text-[14px]">
            <thead>
              <tr className="text-left text-[12px] font-bold uppercase tracking-[.8px] text-muted">
                <th className="px-5 py-3 font-bold">Job</th>
                <th className="px-3 py-3 font-bold">Course</th>
                <th className="px-3 py-3 font-bold">Status</th>
                <th className="px-3 py-3 font-bold">Languages</th>
                <th className="px-3 py-3 font-bold">Created</th>
                <th className="px-5 py-3 text-right font-bold">Finished</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {rows.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-5 py-8 text-center text-muted">
                    No production job yet.
                  </td>
                </tr>
              )}
              {rows.map((j) => {
                const draft = byJob.get(j.id);
                const publishedLangs = (j.summary?.published as string[] | undefined)?.length;
                const failedLangs = j.summary?.failed ? Object.keys(j.summary.failed as Record<string, unknown>).length : 0;
                const targets = (j.options?.languages as string[] | undefined)?.length ?? 0;
                return (
                  <tr key={j.id} className="hover:bg-paper">
                    <td className="px-5 py-3">
                      <Link href={`/admin/production/${j.id}`} className="font-mono text-[12px] font-bold text-blue">
                        {j.id.slice(0, 8)}
                      </Link>
                      <span className="block text-[11px] text-muted">{j.requested_by ?? ""}</span>
                    </td>
                    <td className="px-3 py-3">
                      {draft ? (
                        <Link href={`/admin/review/${draft.id}`} className="font-bold text-ink hover:text-navy">
                          {draft.title || "Untitled course"}
                        </Link>
                      ) : (
                        <span className="font-semibold text-ink-2">{j.course_id}</span>
                      )}
                      <span className="block text-[11px] text-muted">
                        {j.course_id} · {j.origin_lang.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-3 py-3">
                      <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[12px] font-bold ${LOOK[j.status]}`}>{JOB_LABEL[j.status] ?? j.status}</span>
                      {j.error && <span className="mt-1 block max-w-[260px] truncate text-[11px] text-red">{j.error}</span>}
                    </td>
                    <td className="px-3 py-3 text-[13px] tabular-nums text-ink-2">
                      {publishedLangs != null ? `${publishedLangs} published` : `${targets} targets`}
                      {failedLangs ? <span className="text-red"> · {failedLangs} held</span> : null}
                    </td>
                    <td className="px-3 py-3 text-[13px] text-ink-3">{shortDateTime(j.created_at)}</td>
                    <td className="px-5 py-3 text-right text-[13px] text-ink-3">{j.finished_at ? shortDateTime(j.finished_at) : j.started_at ? "running…" : "–"}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </Card>
        {inProduction.length > 0 && (
          <Card className="flex flex-col gap-2 p-6">
            <h2 className="text-[16px] font-extrabold">Courses still in production</h2>
            <ul className="flex flex-wrap gap-2 text-[13px]">
              {inProduction.map((c) => (
                <li key={c.id} className="rounded-full bg-tint px-3 py-1 font-semibold text-navy">
                  {c.id}
                  {c.creator_slug ? ` · ${c.creator_slug}` : ""}
                </li>
              ))}
            </ul>
          </Card>
        )}
      </main>
    </>
  );
}
