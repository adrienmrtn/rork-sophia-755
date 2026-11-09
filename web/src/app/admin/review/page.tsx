import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { StatusPill } from "@/components/studio/StudioChrome";
import { Card, container } from "@/components/ui";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { getStudioSession, type CreatorAccount } from "@/lib/studio/account";
import { listDrafts, shortDateTime } from "@/lib/studio/data";
import { courseWords, type DraftCourse } from "@/lib/studio/course-format";

export const dynamic = "force-dynamic";

const ORDER = ["submitted", "failed", "accepted", "publishing", "changes_requested", "published", "draft", "archived"];
const GROUP: Record<string, string> = { submitted: "Waiting for review", failed: "Production failed", accepted: "Accepted, to launch", publishing: "In production", changes_requested: "Back with the author", published: "Published", draft: "Drafts in progress", archived: "Archived" };

export default async function ReviewQueue({ searchParams }: PageProps<"/admin/review">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const showAll = sp.all === "1";
  const [drafts, { data: accounts }] = await Promise.all([listDrafts(session.supabase), session.supabase.from("creator_accounts").select("user_id,display_name,slug,status,institution")]);
  const byUser = new Map((accounts ?? []).map((a) => [a.user_id as string, a as Pick<CreatorAccount, "user_id" | "display_name" | "slug" | "status" | "institution">]));
  const visible = showAll ? drafts : drafts.filter((d) => d.status !== "draft" && d.status !== "archived");
  const queue = drafts.filter((d) => d.status === "submitted").length;

  return (
    <>
      <AdminHeader session={session} active="review" queue={queue} />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Review queue" lead="Courses sent by authors, oldest first. Open one to read it, decide, and launch production.">
          <Link href={showAll ? "/admin/review" : "/admin/review?all=1"} className="text-[13px] font-bold text-blue">
            {showAll ? "Hide drafts and archives" : "Show drafts and archives"}
          </Link>
        </AdminTitle>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {ORDER.map((st) => {
          const rows = visible.filter((d) => d.status === st).sort((a, b) => (a.submitted_at ?? a.updated_at).localeCompare(b.submitted_at ?? b.updated_at));
          if (rows.length === 0) return null;
          return (
            <section key={st} className="flex flex-col gap-3">
              <h2 className="text-[13px] font-bold uppercase tracking-[1px] text-muted">
                {GROUP[st]} · {rows.length}
              </h2>
              <Card className="divide-y divide-line">
                {rows.map((d) => {
                  const a = byUser.get(d.user_id);
                  const words = courseWords({ sections: d.sections } as DraftCourse);
                  return (
                    <Link key={d.id} href={`/admin/review/${d.id}`} className="flex flex-wrap items-center gap-x-5 gap-y-2 px-5 py-3.5 hover:bg-paper">
                      <StatusPill status={d.status} />
                      <div className="flex min-w-[240px] flex-1 flex-col">
                        <strong className="text-[15px] font-bold text-ink">{d.title || "Untitled course"}</strong>
                        <span className="text-[12px] text-ink-3">
                          {a?.display_name ?? "Unknown author"}
                          {a?.institution ? ` · ${a.institution}` : ""}
                          {a?.status === "pending" ? " · account pending" : ""}
                        </span>
                      </div>
                      <span className="text-[12px] text-ink-3">
                        {d.subject ? `${SUBJECT_LABEL[d.subject as keyof typeof SUBJECT_LABEL] ?? d.subject} · ` : ""}
                        {d.origin_lang.toUpperCase()} · {d.sections?.length ?? 0} sections · {words} words
                      </span>
                      <span className="w-[150px] text-right text-[12px] text-muted">{st === "submitted" ? `Sent ${shortDateTime(d.submitted_at)}` : `Edited ${shortDateTime(d.updated_at)}`}</span>
                    </Link>
                  );
                })}
              </Card>
            </section>
          );
        })}
        {visible.length === 0 && <Card className="p-8 text-[15px] text-muted">Nothing to review.</Card>}
      </main>
    </>
  );
}
