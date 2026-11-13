import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, SectionTitle, Tile } from "@/components/admin/DataChrome";
import { DayBars } from "@/components/admin/DayBars";
import { Card, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { percent, readDataFilters } from "@/lib/studio/paywalls";
import { DUEL_INVITE_STATUS_LABEL, ratio, type SocialDashboard } from "@/lib/studio/usage";

export const dynamic = "force-dynamic";

const n = (value: number) => Number(value).toLocaleString("en");

/** Amis, invitations en duel, parrainage et abonnements aux créateurs. Tout vient d'un appel
 *  à admin_social_dashboard, réservé à l'équipe ; ces données ne suivent que la période. */
export default async function SocialDataPage({ searchParams }: PageProps<"/admin/data/social">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const filters = readDataFilters(await searchParams);

  const { data, error } = await session.supabase.rpc("admin_social_dashboard", { p_days: filters.days });
  const d = (data ?? null) as SocialDashboard | null;
  const answered = d ? Number(d.friends.accepted) + Number(d.friends.declined) : 0;

  return (
    <>
      <AdminHeader session={session} active="data" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Data" lead="What people do in the app: paywalls, onboarding, usage, friends and feedback." />
        <DataNav active="social" filters={filters} languages={[]} periodOnly />

        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}

        {d && (
          <>
            <section className="flex flex-col gap-4">
              <SectionTitle title="Friends" note="Counted by the server, every app version, live. These numbers follow the period only: the server does not know the platform or the language of a friend request." />
              <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                <Tile label="Friend requests sent" value={n(d.friends.requests)} />
                <Tile label="Accepted" value={`${n(d.friends.accepted)} · ${percent(ratio(d.friends.accepted, d.friends.requests))}`} />
                <Tile label="Still waiting" value={`${n(d.friends.pending)} · ${percent(ratio(d.friends.pending, d.friends.requests))}`} />
                <Tile label="New friendships" value={n(d.friends.new_friendships)} />
              </div>
              <p className="text-[13px] text-ink-3">
                {n(d.friends.senders)} people sent at least one request on this period. Of the requests that got an answer, {percent(ratio(d.friends.accepted, answered))} were accepted and {n(d.friends.declined)} declined.
              </p>
              <div className="grid grid-cols-1 gap-5 lg:grid-cols-[2fr_1fr]">
                <Card className="flex flex-col gap-4 p-6">
                  <h3 className="text-[18px] font-extrabold tracking-[-0.3px]">Friend requests per day</h3>
                  <DayBars series={d.friends.series.map((p) => ({ day: p.day, value: Number(p.requests) }))} unit="requests" label="Friend requests per day" />
                </Card>
                <Card className="flex flex-col gap-3 p-6">
                  <h3 className="text-[16px] font-extrabold">Since the beginning</h3>
                  <dl className="grid grid-cols-[1fr_auto] gap-x-4 gap-y-2.5 text-[14px]">
                    <dt className="text-ink-3">Friendships</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.friends.total_friendships)}</dd>
                    <dt className="text-ink-3">People with at least one friend</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.friends.users_with_friends)}</dd>
                    <dt className="text-ink-3">People with three friends or more</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.friends.users_with_3_friends)}</dd>
                  </dl>
                </Card>
              </div>
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle title="Invitations" note="Duel invitations between friends, and new accounts that came through someone's invitation link." />
              <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
                <Card className="flex flex-col gap-3 p-6">
                  <div className="flex items-baseline justify-between gap-3">
                    <h3 className="text-[16px] font-extrabold">Duel invitations sent</h3>
                    <strong className="text-[22px] font-extrabold text-ink tabular-nums">{n(d.duel_invites.sent)}</strong>
                  </div>
                  {d.duel_invites.by_status.length === 0 ? (
                    <p className="text-[14px] text-ink-3">No invitation on this period.</p>
                  ) : (
                    <ul className="flex flex-col divide-y divide-line text-[14px]">
                      {d.duel_invites.by_status.map((s) => (
                        <li key={s.status} className="flex items-baseline justify-between gap-3 py-2">
                          <span className="font-semibold">{DUEL_INVITE_STATUS_LABEL[s.status] ?? s.status}</span>
                          <span className="tabular-nums text-ink-2">
                            {n(s.count)} · <strong className="text-ink">{percent(ratio(s.count, d.duel_invites.sent))}</strong>
                          </span>
                        </li>
                      ))}
                    </ul>
                  )}
                </Card>
                <Card className="flex flex-col gap-3 p-6">
                  <div className="flex items-baseline justify-between gap-3">
                    <h3 className="text-[16px] font-extrabold">Accounts brought by an invitation</h3>
                    <strong className="text-[22px] font-extrabold text-ink tabular-nums">{n(d.referrals.new)}</strong>
                  </div>
                  <dl className="grid grid-cols-[1fr_auto] gap-x-4 gap-y-2.5 text-[14px]">
                    <dt className="text-ink-3">People who brought someone, on this period</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.referrals.inviters)}</dd>
                    <dt className="text-ink-3">Since the beginning</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.referrals.total)}</dd>
                  </dl>
                </Card>
              </div>
            </section>

            <section className="flex flex-col gap-4 border-t border-line pt-6">
              <SectionTitle title="Creators followed" note="Follows of an author saved on the server." />
              <div className="grid grid-cols-1 gap-5 lg:grid-cols-[1fr_2fr]">
                <Card className="flex flex-col gap-3 p-6">
                  <dl className="grid grid-cols-[1fr_auto] gap-x-4 gap-y-2.5 text-[14px]">
                    <dt className="text-ink-3">New follows</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.follows.new)}</dd>
                    <dt className="text-ink-3">People who followed someone</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.follows.followers)}</dd>
                    <dt className="text-ink-3">Follows since the beginning</dt>
                    <dd className="text-right font-extrabold tabular-nums">{n(d.follows.total)}</dd>
                  </dl>
                </Card>
                <Card className="flex flex-col gap-3 p-6">
                  <h3 className="text-[16px] font-extrabold">Most followed on this period</h3>
                  {d.follows.top_creators.length === 0 ? (
                    <p className="text-[14px] text-ink-3">No follow on this period.</p>
                  ) : (
                    <ol className="grid grid-cols-1 gap-x-8 text-[14px] sm:grid-cols-2">
                      {d.follows.top_creators.map((c) => (
                        <li key={c.creator} className="flex items-baseline justify-between gap-3 border-b border-line py-2">
                          <span className="font-semibold">{c.name ?? c.creator}</span>
                          <span className="tabular-nums text-ink-2">{n(c.new)}</span>
                        </li>
                      ))}
                    </ol>
                  )}
                </Card>
              </div>
            </section>
          </>
        )}
      </main>
    </>
  );
}
