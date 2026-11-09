import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { Card, Initials, container } from "@/components/ui";
import { getStudioSession, type CreatorAccount } from "@/lib/studio/account";
import { shortDate } from "@/lib/studio/data";
import { moneyCents, parseQuota, quotaBadge } from "@/lib/studio/payments";
import { setCreatorQuota, setCreatorStatus } from "@/app/admin/actions";

export const dynamic = "force-dynamic";

const STATUS_LOOK: Record<string, string> = { pending: "bg-amber-bg text-amber", approved: "bg-green-bg text-green", suspended: "bg-red-bg text-red" };

export default async function CreatorsPage({ searchParams }: PageProps<"/admin/creators">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const { supabase } = session;
  const [{ data: accounts }, { data: agreements }, { data: version }, { data: drafts }, { data: due }] = await Promise.all([
    supabase.from("creator_accounts").select("*").order("created_at", { ascending: false }),
    supabase.from("creator_agreements").select("user_id,version,signed_at"),
    supabase.rpc("studio_document_version", { p_slug: "creator-agreement" }),
    supabase.from("studio_drafts").select("user_id,status,validated_at"),
    supabase.rpc("studio_payouts_due"),
  ]);
  const current = Number(version ?? 0);
  const signed = new Map<string, number>();
  for (const a of (agreements ?? []) as { user_id: string; version: number }[]) signed.set(a.user_id, Math.max(signed.get(a.user_id) ?? 0, a.version));
  const counts = new Map<string, { total: number; published: number; validated: number }>();
  for (const d of (drafts ?? []) as { user_id: string; status: string; validated_at: string | null }[]) {
    const c = counts.get(d.user_id) ?? { total: 0, published: 0, validated: 0 };
    c.total += 1;
    if (d.status === "published") c.published += 1;
    if (d.validated_at) c.validated += 1;
    counts.set(d.user_id, c);
  }
  const dueByUser = new Map<string, number>();
  for (const c of ((due as { creators?: { user_id: string; amount_cents: number }[] } | null)?.creators ?? [])) dueByUser.set(c.user_id, Number(c.amount_cents));
  const rows = (accounts ?? []) as CreatorAccount[];
  const order = { pending: 0, approved: 1, suspended: 2 };
  rows.sort((a, b) => order[a.status] - order[b.status] || b.created_at.localeCompare(a.created_at));
  const quotas = new Map(await Promise.all(rows.map(async (a) => [a.user_id, parseQuota((await supabase.rpc("studio_quota", { p_user: a.user_id })).data)] as const)));

  return (
    <>
      <AdminHeader session={session} active="creators" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Creators" lead="Every author account. Approve once the credentials check out; a suspended account can no longer propose or send courses. The weekly limit is the number of courses you can validate for an author: three in their first week, then one, unless you set a limit here (0 blocks them)." />
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
            const q = quotas.get(a.user_id) ?? null;
            const pot = dueByUser.get(a.user_id) ?? 0;
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
                    {pot > 0 && <span className="inline-flex items-center rounded-full bg-cream px-2.5 py-0.5 text-[12px] font-bold text-amber">{moneyCents(pot)} to pay Monday</span>}
                  </div>
                  <span className="text-[13px] text-ink-2">{[a.title, a.institution, a.country].filter(Boolean).join(" · ") || "No credentials yet"}</span>
                  <span className="text-[12px] text-ink-3">
                    {a.email} · writes in {a.writing_lang.toUpperCase()} · joined {shortDate(a.created_at)}
                    {a.approved_at ? ` · approved ${shortDate(a.approved_at)}` : ""} · onboarding: {a.onboarding_step}
                  </span>
                  <span className="text-[12px] text-ink-3">
                    Agreement: {v === 0 ? <span className="font-bold text-red">not signed</span> : v >= current ? <span className="font-bold text-green">v{v} signed</span> : <span className="font-bold text-amber">v{v} (current is v{current})</span>}
                    {" · "}
                    {c ? `${c.total} courses, ${c.validated} validated, ${c.published} published` : "no course yet"}
                    {Object.entries(a.links ?? {}).map(([k, url]) => (
                      <span key={k}>
                        {" · "}
                        <a href={url} target="_blank" rel="noreferrer" className="font-bold text-blue">
                          {k}
                        </a>
                      </span>
                    ))}
                  </span>
                  <span className={`text-[12px] ${q?.blocked ? "font-bold text-red" : "text-ink-3"}`}>Quota: {quotaBadge(q)}</span>
                  {a.bio && <p className="text-[13px] text-ink-3">{a.bio}</p>}
                  {a.status === "suspended" && a.suspended_reason && <p className="text-[13px] font-semibold text-red">Reason: {a.suspended_reason}</p>}
                </div>
                <div className="flex flex-col items-end gap-3">
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
                  <form action={setCreatorQuota} className="flex items-center gap-2">
                    <input type="hidden" name="user_id" value={a.user_id} />
                    <label className="flex items-center gap-2 text-[12px] font-semibold text-ink-3">
                      Weekly limit
                      <input name="weekly_quota" type="number" min={0} max={50} step={1} defaultValue={a.weekly_quota ?? ""} placeholder="default" className="h-9 w-20 rounded-lg border border-line bg-white px-2 text-center text-[13px] font-bold text-ink outline-none focus:border-blue" />
                    </label>
                    <button type="submit" className="rounded-xl border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-navy hover:bg-tint">
                      Save
                    </button>
                  </form>
                </div>
              </div>
            );
          })}
        </Card>
      </main>
    </>
  );
}
