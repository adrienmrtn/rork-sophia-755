import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { Card, Initials, container } from "@/components/ui";
import { getStudioSession, type CreatorAccount } from "@/lib/studio/account";
import { shortDate } from "@/lib/studio/data";
import { setCreatorStatus } from "@/app/admin/actions";

export const dynamic = "force-dynamic";

const STATUS_LOOK: Record<string, string> = { pending: "bg-amber-bg text-amber", approved: "bg-green-bg text-green", suspended: "bg-red-bg text-red" };

export default async function CreatorsPage({ searchParams }: PageProps<"/admin/creators">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const { supabase } = session;
  const [{ data: accounts }, { data: agreements }, { data: version }, { data: drafts }] = await Promise.all([
    supabase.from("creator_accounts").select("*").order("created_at", { ascending: false }),
    supabase.from("creator_agreements").select("user_id,version,signed_at"),
    supabase.rpc("studio_document_version", { p_slug: "creator-agreement" }),
    supabase.from("studio_drafts").select("user_id,status"),
  ]);
  const current = Number(version ?? 0);
  const signed = new Map<string, number>();
  for (const a of (agreements ?? []) as { user_id: string; version: number }[]) signed.set(a.user_id, Math.max(signed.get(a.user_id) ?? 0, a.version));
  const counts = new Map<string, { total: number; published: number }>();
  for (const d of (drafts ?? []) as { user_id: string; status: string }[]) {
    const c = counts.get(d.user_id) ?? { total: 0, published: 0 };
    c.total += 1;
    if (d.status === "published") c.published += 1;
    counts.set(d.user_id, c);
  }
  const rows = (accounts ?? []) as CreatorAccount[];
  const order = { pending: 0, approved: 1, suspended: 2 };
  rows.sort((a, b) => order[a.status] - order[b.status] || b.created_at.localeCompare(a.created_at));

  return (
    <>
      <AdminHeader session={session} active="creators" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Creators" lead="Every author account. Approve once the credentials check out; a suspended account can no longer send courses." />
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {done && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">Account {done}.</p>}
        <Card className="divide-y divide-line">
          {rows.length === 0 && <p className="p-8 text-[15px] text-muted">No author account yet.</p>}
          {rows.map((a) => {
            const name = a.display_name || [a.first_name, a.last_name].filter(Boolean).join(" ") || a.email || a.user_id;
            const v = signed.get(a.user_id) ?? 0;
            const c = counts.get(a.user_id);
            return (
              <div key={a.user_id} className="flex flex-wrap items-start gap-x-5 gap-y-3 px-5 py-4">
                <Initials name={name} size={44} />
                <div className="flex min-w-[260px] flex-1 flex-col gap-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <strong className="text-[15px] font-bold text-ink">{name}</strong>
                    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-[12px] font-bold ${STATUS_LOOK[a.status]}`}>{a.status}</span>
                    {a.slug && (
                      <Link href={`/authors/${a.slug}`} className="text-[12px] font-bold text-blue">
                        /authors/{a.slug}
                      </Link>
                    )}
                  </div>
                  <span className="text-[13px] text-ink-2">{[a.title, a.institution, a.country].filter(Boolean).join(" · ") || "No credentials yet"}</span>
                  <span className="text-[12px] text-ink-3">
                    {a.email} · writes in {a.writing_lang.toUpperCase()} · joined {shortDate(a.created_at)} · onboarding: {a.onboarding_step}
                  </span>
                  <span className="text-[12px] text-ink-3">
                    Agreement: {v === 0 ? <span className="font-bold text-red">not signed</span> : v >= current ? <span className="font-bold text-green">v{v} signed</span> : <span className="font-bold text-amber">v{v} (current is v{current})</span>}
                    {" · "}
                    {c ? `${c.total} courses, ${c.published} published` : "no course yet"}
                    {Object.entries(a.links ?? {}).map(([k, url]) => (
                      <span key={k}>
                        {" · "}
                        <a href={url} target="_blank" rel="noreferrer" className="font-bold text-blue">
                          {k}
                        </a>
                      </span>
                    ))}
                  </span>
                  {a.bio && <p className="text-[13px] text-ink-3">{a.bio}</p>}
                  {a.status === "suspended" && a.suspended_reason && <p className="text-[13px] font-semibold text-red">Reason: {a.suspended_reason}</p>}
                </div>
                <form action={setCreatorStatus} className="flex flex-col items-end gap-2">
                  <input type="hidden" name="user_id" value={a.user_id} />
                  <div className="flex flex-wrap justify-end gap-2">
                    {a.status !== "approved" && (
                      <button type="submit" name="status" value="approved" className="rounded-xl border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-green hover:bg-green-bg">
                        Approve
                      </button>
                    )}
                    {a.status !== "suspended" && (
                      <button type="submit" name="status" value="suspended" className="rounded-xl border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-red hover:bg-red-bg">
                        Suspend
                      </button>
                    )}
                    {a.status !== "pending" && (
                      <button type="submit" name="status" value="pending" className="rounded-xl border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-ink-3 hover:bg-paper">
                        Set pending
                      </button>
                    )}
                  </div>
                  <input name="reason" placeholder="Reason (kept for suspensions)" maxLength={600} className="h-9 w-64 rounded-lg border border-line bg-white px-3 text-[12px] outline-none focus:border-blue" />
                </form>
              </div>
            );
          })}
        </Card>
      </main>
    </>
  );
}
