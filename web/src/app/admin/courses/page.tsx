import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { Card, Pill, container } from "@/components/ui";
import { STORAGE_PUBLIC } from "@/lib/env";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { LANGS } from "@/lib/catalog/types";
import { getStudioSession } from "@/lib/studio/account";
import { shortDate } from "@/lib/studio/data";

export const dynamic = "force-dynamic";

interface Row {
  id: string;
  subject: string | null;
  status: string;
  tier: string;
  origin_lang: string;
  cover_slug: string | null;
  creator_slug: string | null;
  creator_name: string | null;
  published_at: string | null;
  updated_at: string | null;
  title: string | null;
  langs_published: number;
  langs_total: number;
}

const STATUS_TONE: Record<string, "green" | "amber" | "red" | "tint"> = { published: "green", in_production: "amber", archived: "red", draft: "tint" };

/** Tous les cours du catalogue, pour l'équipe : ouvrir un cours pour éditer une langue, retirer,
 *  archiver ou supprimer. */
export default async function AdminCoursesPage({ searchParams }: PageProps<"/admin/courses">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const q = (typeof sp.q === "string" ? sp.q : "").trim().toLowerCase();
  const status = typeof sp.status === "string" ? sp.status : "";
  const done = typeof sp.done === "string" ? sp.done : null;
  const error = typeof sp.error === "string" ? sp.error : null;
  const { data, error: rpcError } = await session.supabase.rpc("catalog_admin_courses");
  const all = ((data ?? []) as Row[]).map((r) => ({ ...r, langs_published: Number(r.langs_published), langs_total: Number(r.langs_total) }));
  const rows = all.filter((r) => (!status || r.status === status) && (!q || r.id.includes(q) || (r.title ?? "").toLowerCase().includes(q) || (r.creator_name ?? "").toLowerCase().includes(q)));
  const counts = all.reduce<Record<string, number>>((acc, r) => ({ ...acc, [r.status]: (acc[r.status] ?? 0) + 1 }), {});

  return (
    <>
      <AdminHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Courses" lead="Every course in the catalogue, in every language. Open one to edit its text and images in a given language, take a language offline, archive the course or delete it. Changes reach the apps within the hour.">
          <form className="flex flex-wrap items-center gap-2" action="/admin/courses" method="get">
            <input name="q" defaultValue={q} placeholder="Title, identifier or author" className="h-10 w-64 rounded-xl border border-line bg-white px-3 text-[14px] outline-none focus:border-blue" />
            <select name="status" defaultValue={status} className="h-10 rounded-xl border border-line bg-white px-3 text-[14px] outline-none focus:border-blue">
              <option value="">Every status</option>
              {Object.entries(counts).map(([st, n]) => (
                <option key={st} value={st}>
                  {st} ({n})
                </option>
              ))}
            </select>
            <button type="submit" className="h-10 rounded-xl bg-navy px-4 text-[14px] font-bold text-white hover:bg-ink">
              Search
            </button>
          </form>
        </AdminTitle>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {rpcError && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {rpcError.message}
          </p>
        )}
        {done?.startsWith("deleted:") && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">Course deleted: {done.slice("deleted:".length)}. The apps drop it at their next catalogue refresh.</p>}
        <div className="flex flex-wrap gap-3 text-[13px] text-ink-3">
          <span className="rounded-full bg-paper px-3 py-1.5 font-semibold">{rows.length} of {all.length} courses</span>
          <span className="rounded-full bg-paper px-3 py-1.5">{LANGS.length} languages per course</span>
        </div>
        <Card className="divide-y divide-line">
          {rows.length === 0 && <p className="p-8 text-[15px] text-muted">No course matches.</p>}
          {rows.map((r) => (
            <Link key={r.id} href={`/admin/courses/${encodeURIComponent(r.id)}`} className="flex flex-wrap items-center gap-x-5 gap-y-2 px-5 py-3.5 hover:bg-paper">
              {r.cover_slug ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={`${STORAGE_PUBLIC}/course-images/${r.cover_slug}.jpg`} alt="" className="h-12 w-20 shrink-0 rounded-lg object-cover" />
              ) : (
                <span className="h-12 w-20 shrink-0 rounded-lg bg-tint" />
              )}
              <div className="flex min-w-[260px] flex-1 flex-col">
                <strong className="text-[15px] font-bold text-ink">{r.title || r.id}</strong>
                <span className="text-[12px] text-ink-3">
                  {r.id} · {r.subject ? (SUBJECT_LABEL[r.subject as keyof typeof SUBJECT_LABEL] ?? r.subject) : "no subject"} · {r.origin_lang.toUpperCase()}
                  {r.creator_name ? ` · ${r.creator_name}` : ""}
                </span>
              </div>
              <span className="text-[13px] text-ink-2">
                {r.langs_published}/{r.langs_total} languages live
              </span>
              <Pill tone={STATUS_TONE[r.status] ?? "tint"}>{r.status}</Pill>
              <span className="w-[110px] text-right text-[12px] text-muted">{shortDate(r.updated_at ?? r.published_at)}</span>
            </Link>
          ))}
        </Card>
      </main>
    </>
  );
}
