import Link from "next/link";
import { redirect } from "next/navigation";
import { StatusPill, StudioHeader } from "@/components/studio/StudioChrome";
import { Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { getStudioSession } from "@/lib/studio/account";
import { listDrafts, shortDate } from "@/lib/studio/data";
import { courseWords, type DraftCourse } from "@/lib/studio/course-format";
import { createDraft } from "@/app/studio/actions";

export const dynamic = "force-dynamic";

export default async function CoursesPage({ searchParams }: PageProps<"/studio/courses">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/courses");
  if (!session.account) redirect("/studio/onboarding/identity");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const drafts = await listDrafts(session.supabase, session.user.id);
  const c = s.courses;
  const groups: [string, typeof drafts][] = [
    ["In progress", drafts.filter((d) => d.status === "draft" || d.status === "changes_requested")],
    ["In review and production", drafts.filter((d) => ["submitted", "accepted", "publishing", "failed"].includes(d.status))],
    ["Published", drafts.filter((d) => d.status === "published")],
    ["Archived", drafts.filter((d) => d.status === "archived")],
  ];

  return (
    <>
      <StudioHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col gap-7 pt-8 pb-20`}>
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div className="flex flex-col gap-1.5">
            <h1 className="text-[32px] font-extrabold tracking-[-0.8px] text-ink">{c.title}</h1>
            <p className="text-[16px] text-ink-3">{c.lead}</p>
          </div>
          <form action={createDraft}>
            <button type="submit" className="inline-flex h-11 items-center gap-2 rounded-btn bg-navy px-[18px] text-[15px] font-bold text-white hover:bg-ink">
              {c.newCourse}
            </button>
          </form>
        </div>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {drafts.length === 0 && (
          <Card className="flex flex-col items-start gap-4 p-8">
            <p className="max-w-[560px] text-[16px] text-ink-3">{c.empty}</p>
            <form action={createDraft}>
              <button type="submit" className="inline-flex h-11 items-center gap-2 rounded-btn bg-navy px-[18px] text-[15px] font-bold text-white hover:bg-ink">
                {c.newCourse}
              </button>
            </form>
          </Card>
        )}
        {groups.map(([title, rows]) =>
          rows.length === 0 ? null : (
            <section key={title} className="flex flex-col gap-3">
              <h2 className="text-[13px] font-bold uppercase tracking-[1px] text-muted">{title}</h2>
              <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
                {rows.map((d) => {
                  const words = courseWords({ sections: d.sections } as DraftCourse);
                  const editable = d.status === "draft" || d.status === "changes_requested";
                  const href = editable ? `/studio/courses/${d.id}` : `/studio/courses/${d.id}/status`;
                  return (
                    <Link key={d.id} href={href} className="flex flex-col gap-3 rounded-card border border-line bg-white p-5 hover:border-line-2 hover:shadow-[0_10px_30px_rgba(22,38,61,.06)]">
                      <div className="flex items-start justify-between gap-3">
                        <StatusPill status={d.status} />
                        <span className="text-[12px] text-muted">{c.updated(shortDate(d.updated_at))}</span>
                      </div>
                      <strong className="line-clamp-2 text-[18px] font-extrabold leading-[1.25] tracking-[-0.3px] text-ink">{d.title || c.untitled}</strong>
                      <span className="text-[13px] text-ink-3">
                        {d.subject ? `${SUBJECT_LABEL[d.subject as keyof typeof SUBJECT_LABEL] ?? d.subject} · ` : ""}
                        {c.sections(d.sections?.length ?? 0)} · {c.words(words)}
                      </span>
                      {d.status === "changes_requested" && d.review_comment && <p className="line-clamp-3 rounded-xl bg-red-bg/60 px-3 py-2 text-[13px] text-red">{d.review_comment}</p>}
                      <span className="mt-auto text-[13px] font-bold text-blue">{editable ? c.openEditor : c.track} →</span>
                    </Link>
                  );
                })}
              </div>
            </section>
          ),
        )}
      </main>
    </>
  );
}
