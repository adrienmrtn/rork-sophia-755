import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { Card, Pill, container } from "@/components/ui";
import { STORAGE_PUBLIC } from "@/lib/env";
import { LANG_NAMES } from "@/lib/catalog/lang-names";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { LANGS } from "@/lib/catalog/types";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { deleteCourse, setContentStatus, setCourseStatus } from "@/app/admin/courses/actions";

export const dynamic = "force-dynamic";

interface CourseRow {
  id: string;
  subject: string | null;
  status: string;
  tier: string;
  origin_lang: string;
  cover_slug: string | null;
  creator_slug: string | null;
  published_at: string | null;
  updated_at: string;
}
interface ContentRow {
  lang: string;
  status: string;
  title: string;
  version: number;
  hash: string;
  updated_at: string;
  section_ids: string[] | null;
}

const CONTENT_TONE: Record<string, "green" | "amber" | "red" | "tint"> = { published: "green", in_production: "amber", withheld: "red", failed: "red", draft: "tint" };

/** La fiche d'un cours pour l'équipe : chaque langue, son statut, son titre, l'édition ; puis
 *  les actions sur le cours entier (archiver, remettre, supprimer). */
export default async function AdminCoursePage({ params, searchParams }: PageProps<"/admin/courses/[courseId]">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const { courseId: rawId } = await params;
  const courseId = decodeURIComponent(rawId);
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const { supabase } = session;
  const [{ data: courseRow }, { data: contents }] = await Promise.all([
    supabase.from("courses").select("id,subject,status,tier,origin_lang,cover_slug,creator_slug,published_at,updated_at").eq("id", courseId).maybeSingle(),
    supabase.from("course_contents").select("lang,status,title,version,hash,updated_at,section_ids").eq("course_id", courseId),
  ]);
  const course = (courseRow as CourseRow | null) ?? null;
  if (!course) notFound();
  const byLang = new Map(((contents ?? []) as ContentRow[]).map((c) => [c.lang, c]));
  const origin = byLang.get(course.origin_lang) ?? null;
  const { data: creator } = course.creator_slug ? await supabase.from("creators").select("name,slug").eq("slug", course.creator_slug).maybeSingle() : { data: null };
  const published = [...byLang.values()].filter((c) => c.status === "published").length;
  const langsOrdered = [course.origin_lang, ...LANGS.filter((l) => l !== course.origin_lang)];
  const doneMessage = (() => {
    if (!done) return null;
    if (done === "archived") return "Course archived: it leaves the apps at their next catalogue refresh. Nothing is lost; restore it any time.";
    if (done === "published") return "Course back online.";
    if (done.endsWith("-withheld")) return `${LANG_NAMES[done.split("-")[0]] ?? done} taken offline. The other languages stay live.`;
    if (done.endsWith("-published")) return `${LANG_NAMES[done.split("-")[0]] ?? done} back online.`;
    if ((LANGS as readonly string[]).includes(done)) return `${LANG_NAMES[done] ?? done} saved and published. The apps pick the new text up within the hour.`;
    return null;
  })();

  return (
    <>
      <AdminHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <Link href="/admin/courses" className="text-[13px] font-bold text-blue">
          ← Courses
        </Link>
        <div className="flex flex-wrap items-start gap-6">
          {course.cover_slug ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={`${STORAGE_PUBLIC}/course-images/${course.cover_slug}.jpg`} alt="" className="aspect-video w-full max-w-[320px] rounded-card object-cover" />
          ) : (
            <div className="flex aspect-video w-full max-w-[320px] items-center justify-center rounded-card bg-tint text-[13px] font-semibold text-ink-3">No cover</div>
          )}
          <div className="flex min-w-[280px] flex-1 flex-col gap-2">
            <AdminTitle title={origin?.title || course.id} lead={`${course.id} · ${course.subject ? (SUBJECT_LABEL[course.subject as keyof typeof SUBJECT_LABEL] ?? course.subject) : "no subject"} · written in ${LANG_NAMES[course.origin_lang] ?? course.origin_lang}${creator ? ` · ${(creator as { name: string }).name}` : ""}`} />
            <div className="flex flex-wrap items-center gap-2 text-[13px] text-ink-3">
              <Pill tone={course.status === "published" ? "green" : course.status === "archived" ? "red" : "amber"}>{course.status}</Pill>
              <span>
                {published}/{byLang.size} languages live
              </span>
              {course.published_at && <span>· published {shortDateTime(course.published_at)}</span>}
              {creator && (
                <Link href={`/authors/${(creator as { slug: string }).slug}`} className="font-bold text-blue">
                  /authors/{(creator as { slug: string }).slug}
                </Link>
              )}
              <Link href={`/courses/${course.id.replace(/^course_(\d+)_.*$/, "$1")}-course`} className="font-bold text-blue">
                Public page →
              </Link>
            </div>
          </div>
        </div>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {doneMessage && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">{doneMessage}</p>}

        <section className="flex flex-col gap-3">
          <h2 className="text-[13px] font-bold uppercase tracking-[1px] text-muted">Languages · {byLang.size}</h2>
          <Card className="divide-y divide-line">
            {langsOrdered.map((lang) => {
              const c = byLang.get(lang);
              return (
                <div key={lang} className="flex flex-wrap items-center gap-x-5 gap-y-2 px-5 py-3">
                  <span className="w-[120px] shrink-0 text-[14px] font-bold text-ink">
                    {LANG_NAMES[lang] ?? lang} <span className="text-[11px] font-semibold uppercase text-muted">{lang}</span>
                    {lang === course.origin_lang && <span className="ml-1 rounded-full bg-cream px-2 py-0.5 text-[11px] font-bold text-amber">original</span>}
                  </span>
                  {c ? (
                    <>
                      <Pill tone={CONTENT_TONE[c.status] ?? "tint"}>{c.status}</Pill>
                      <span className="min-w-[240px] flex-1 truncate text-[14px] text-ink-2">{c.title || "Untitled"}</span>
                      <span className="text-[12px] text-muted">
                        v{c.version} · {c.section_ids?.length ?? 0} sections · {shortDateTime(c.updated_at)}
                      </span>
                      <div className="flex items-center gap-2">
                        <Link href={`/admin/courses/${encodeURIComponent(course.id)}/${lang}`} className="rounded-xl bg-navy px-3 py-1.5 text-[13px] font-bold text-white hover:bg-ink">
                          Edit
                        </Link>
                        {(c.status === "published" || c.status === "withheld") && (
                          <form action={setContentStatus}>
                            <input type="hidden" name="course_id" value={course.id} />
                            <input type="hidden" name="lang" value={lang} />
                            <input type="hidden" name="status" value={c.status === "published" ? "withheld" : "published"} />
                            <button type="submit" className={`rounded-xl border border-line bg-white px-3 py-1.5 text-[13px] font-bold ${c.status === "published" ? "text-red hover:bg-red-bg" : "text-green hover:bg-green-bg"}`}>
                              {c.status === "published" ? "Take offline" : "Put back online"}
                            </button>
                          </form>
                        )}
                      </div>
                    </>
                  ) : (
                    <span className="text-[13px] text-muted">Not produced yet. The factory adds languages from the review page of the Studio course.</span>
                  )}
                </div>
              );
            })}
          </Card>
        </section>

        <section className="grid grid-cols-1 gap-5 lg:grid-cols-2">
          <Card className="flex flex-col gap-3 p-6">
            <h2 className="text-[16px] font-extrabold">{course.status === "archived" ? "Put the course back online" : "Archive the course"}</h2>
            <p className="text-[13px] leading-[1.5] text-ink-3">{course.status === "archived" ? "The course returns to the apps in every language that is live, at their next catalogue refresh." : "The course leaves the apps in every language, at their next catalogue refresh. Texts, quizzes, glossaries and statistics are kept; restore it any time."}</p>
            <form action={setCourseStatus}>
              <input type="hidden" name="course_id" value={course.id} />
              <input type="hidden" name="status" value={course.status === "archived" ? "published" : "archived"} />
              <button type="submit" className={`rounded-xl border border-line bg-white px-4 py-2 text-[14px] font-bold ${course.status === "archived" ? "text-green hover:bg-green-bg" : "text-amber hover:bg-cream"}`}>
                {course.status === "archived" ? "Put back online" : "Archive"}
              </button>
            </form>
          </Card>
          <Card className="flex flex-col gap-3 border-red-bg p-6">
            <h2 className="text-[16px] font-extrabold text-red">Delete the course</h2>
            <p className="text-[13px] leading-[1.5] text-ink-3">For good: every language, the quizzes, the glossaries, the reading statistics attached to it. The Studio draft it came from is archived, the images stay in storage. Type the identifier to confirm.</p>
            <form action={deleteCourse} className="flex flex-wrap items-center gap-2">
              <input type="hidden" name="course_id" value={course.id} />
              <input name="confirm" placeholder={course.id} required className="h-10 min-w-[280px] flex-1 rounded-xl border border-line bg-white px-3 font-mono text-[13px] outline-none focus:border-red" />
              <button type="submit" className="rounded-xl bg-red px-4 py-2 text-[14px] font-bold text-white hover:opacity-90">
                Delete for good
              </button>
            </form>
          </Card>
        </section>
      </main>
    </>
  );
}
