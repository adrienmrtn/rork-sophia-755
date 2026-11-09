import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { Card, Initials, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDate, shortDateTime } from "@/lib/studio/data";
import { dayLabel, moneyCents } from "@/lib/studio/payments";
import { markPaid } from "@/app/admin/actions";

export const dynamic = "force-dynamic";

interface DueCredit {
  id: number;
  draft_id: string | null;
  title: string;
  amount_cents: number;
  created_at: string;
}
interface DueCreator {
  user_id: string;
  name: string;
  slug: string | null;
  email: string | null;
  amount_cents: number;
  oldest_at: string;
  credits: DueCredit[];
}
interface PayoutHistory {
  id: number;
  user_id: string;
  name: string;
  amount_cents: number;
  credits_count: number;
  paid_at: string;
  note: string | null;
}
interface Due {
  due_cents: number;
  creators: DueCreator[];
  history: PayoutHistory[];
  paid_total_cents: number;
}

/** Le lundi : ce qui est dû à chaque auteur (15 $ par cours validé), et « Virement fait ». */
export default async function PayoutsPage({ searchParams }: PageProps<"/admin/payouts">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const { data, error: rpcError } = await session.supabase.rpc("studio_payouts_due");
  const due = (data ?? null) as Due | null;
  const creators = due?.creators ?? [];
  const nextMonday = (() => {
    const now = new Date();
    const paris = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Paris" }));
    const day = paris.getDay();
    const add = day === 1 ? 7 : (8 - day) % 7 || 7;
    const d = new Date(paris);
    d.setDate(paris.getDate() + add);
    return d.toISOString();
  })();

  return (
    <>
      <AdminHeader session={session} active="payouts" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Monday payouts" lead="Every validated course puts $15 in its author's pot. Pay the pot on Monday, by the means agreed with each author, then mark it paid here: the pot goes back to zero and the payment is kept in the history." />
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
        {done && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">Payment recorded{done && !Number.isNaN(Number(done)) && done !== "" ? `: ${moneyCents(Number(done))}` : ""}. The author&apos;s pot is back to zero.</p>}

        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          <Tile label="Due now" value={moneyCents(due?.due_cents ?? 0)} tone={due?.due_cents ? "amber" : undefined} />
          <Tile label="Authors to pay" value={String(creators.length)} />
          <Tile label="Next Monday" value={dayLabel(nextMonday).replace(/^Monday /, "")} />
          <Tile label="Paid so far" value={moneyCents(due?.paid_total_cents ?? 0)} />
        </div>

        <section className="flex flex-col gap-3">
          <h2 className="text-[13px] font-bold uppercase tracking-[1px] text-muted">To pay · {creators.length}</h2>
          <Card className="divide-y divide-line">
            {creators.length === 0 && <p className="p-8 text-[15px] text-muted">Nothing due. Every validated course has been paid.</p>}
            {creators.map((c) => (
              <div key={c.user_id} className="flex flex-wrap items-start gap-x-5 gap-y-3 px-5 py-4">
                <Initials name={c.name} size={44} />
                <div className="flex min-w-[260px] flex-1 flex-col gap-1.5">
                  <div className="flex flex-wrap items-center gap-2">
                    <strong className="text-[15px] font-bold text-ink">{c.name}</strong>
                    {c.slug && (
                      <Link href={`/authors/${c.slug}`} className="text-[12px] font-bold text-blue">
                        /authors/{c.slug}
                      </Link>
                    )}
                    {c.email && <span className="text-[12px] text-ink-3">{c.email}</span>}
                  </div>
                  <ul className="flex flex-col gap-0.5 text-[13px] text-ink-2">
                    {c.credits.map((cr) => (
                      <li key={cr.id} className="flex flex-wrap items-center gap-x-2">
                        <span className="text-muted">{shortDate(cr.created_at)}</span>
                        {cr.draft_id ? (
                          <Link href={`/admin/review/${cr.draft_id}`} className="font-semibold text-ink hover:text-navy">
                            {cr.title || "Untitled course"}
                          </Link>
                        ) : (
                          <span className="font-semibold">{cr.title || "Untitled course"}</span>
                        )}
                        <span className="tabular-nums text-ink-3">{moneyCents(cr.amount_cents)}</span>
                      </li>
                    ))}
                  </ul>
                  <span className="text-[12px] text-muted">Oldest credit {shortDateTime(c.oldest_at)}</span>
                </div>
                <form action={markPaid} className="flex flex-col items-end gap-2">
                  <input type="hidden" name="user_id" value={c.user_id} />
                  <strong className="text-[24px] font-extrabold tracking-[-0.6px] text-navy tabular-nums">{moneyCents(c.amount_cents)}</strong>
                  <input name="note" placeholder="Reference (optional)" maxLength={300} className="h-9 w-56 rounded-lg border border-line bg-white px-3 text-[12px] outline-none focus:border-blue" />
                  <button type="submit" className="rounded-xl bg-navy px-4 py-2 text-[13px] font-bold text-white hover:bg-ink">
                    Transfer done
                  </button>
                </form>
              </div>
            ))}
          </Card>
        </section>

        <section className="flex flex-col gap-3">
          <h2 className="text-[13px] font-bold uppercase tracking-[1px] text-muted">History</h2>
          <Card className="divide-y divide-line">
            {(due?.history ?? []).length === 0 && <p className="p-6 text-[14px] text-muted">No payment recorded yet.</p>}
            {(due?.history ?? []).map((h) => (
              <div key={h.id} className="flex flex-wrap items-center gap-x-5 gap-y-1 px-5 py-3 text-[14px]">
                <span className="w-[150px] shrink-0 text-muted">{shortDateTime(h.paid_at)}</span>
                <strong className="min-w-[200px] flex-1 font-bold text-ink">{h.name}</strong>
                <span className="text-ink-3">
                  {h.credits_count} {h.credits_count === 1 ? "course" : "courses"}
                </span>
                {h.note && <span className="text-[12px] text-muted">{h.note}</span>}
                <strong className="tabular-nums text-navy">{moneyCents(h.amount_cents)}</strong>
              </div>
            ))}
          </Card>
        </section>
      </main>
    </>
  );
}

function Tile({ label, value, tone }: { label: string; value: string; tone?: "amber" }) {
  return (
    <Card className="flex h-full flex-col gap-1 p-5">
      <span className="text-[13px] font-bold text-ink-3">{label}</span>
      <strong className={`text-[26px] font-extrabold tracking-[-0.6px] tabular-nums ${tone === "amber" ? "text-amber" : "text-ink"}`}>{value}</strong>
    </Card>
  );
}
