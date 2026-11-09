import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { ButtonLink, Card, Pill, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { campaignFromRow, kindLabel, languagesFilled, localized, phase, statusTone, symbolLabel, type Campaign } from "@/lib/studio/campaigns";
import { shortDate, shortDateTime } from "@/lib/studio/data";

export const dynamic = "force-dynamic";

const PHASE: Record<ReturnType<typeof phase>, string> = { upcoming: "Starts", live: "Live until", over: "Ended" };

export default async function EventsPage({ searchParams }: PageProps<"/admin/events">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const done = typeof sp.done === "string" ? sp.done : null;
  const { data } = await session.supabase.from("campaigns").select("*").order("starts_at", { ascending: false });
  const campaigns: Campaign[] = ((data ?? []) as Record<string, unknown>[]).map(campaignFromRow);
  const live = campaigns.filter((c) => c.status === "published" && phase(c) === "live").length;

  return (
    <>
      <AdminHeader session={session} active="events" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Events" lead="Movember, a commemoration day, a thematic week: a collection of courses, a challenge, a badge, announced courses. Published events reach the apps within the hour, with no app update.">
          <ButtonLink href="/admin/events/new" className="h-11 px-5">
            New event
          </ButtonLink>
        </AdminTitle>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error}
          </p>
        )}
        {done === "deleted" && <p className="rounded-xl bg-green-bg px-4 py-3 text-[14px] font-semibold text-green">Event deleted.</p>}
        <div className="flex flex-wrap gap-3 text-[13px] text-ink-3">
          <span className="rounded-full bg-paper px-3 py-1.5 font-semibold">{live} live now</span>
          <span className="rounded-full bg-paper px-3 py-1.5 font-semibold">{campaigns.filter((c) => c.status === "draft").length} drafts</span>
          <span className="rounded-full bg-paper px-3 py-1.5">Participants are recounted every hour from the reading log.</span>
        </div>
        <Card className="divide-y divide-line">
          {campaigns.length === 0 && <p className="p-8 text-[15px] text-muted">No event yet. Create the first one.</p>}
          {campaigns.map((c) => {
            const ph = phase(c);
            return (
              <Link key={c.slug} href={`/admin/events/${c.slug}`} className="flex flex-wrap items-center gap-x-5 gap-y-2 px-5 py-4 hover:bg-paper">
                <div className="flex min-w-[260px] flex-1 flex-col gap-1">
                  <span className="text-[16px] font-extrabold text-ink">{localized(c.title, "en") || c.slug}</span>
                  <span className="text-[13px] text-ink-3">
                    {kindLabel(c.kind)} · {symbolLabel(c.symbol)} · {c.slug}
                  </span>
                </div>
                <div className="flex min-w-[200px] flex-col gap-0.5 text-[13px] text-ink-2">
                  <span className="font-semibold">
                    {shortDate(c.starts_at)} → {shortDate(c.ends_at)}
                  </span>
                  <span className="text-muted">
                    {PHASE[ph]} {ph === "upcoming" ? shortDate(c.starts_at) : shortDate(c.ends_at)}
                  </span>
                </div>
                <div className="flex min-w-[220px] flex-col gap-0.5 text-[13px] text-ink-2">
                  <span>
                    {c.course_ids.length} course{c.course_ids.length === 1 ? "" : "s"} · challenge {c.challenge_target} · {c.upcoming.length} announced
                  </span>
                  <span className="text-muted">
                    {languagesFilled(c).length}/30 languages · {c.participants.toLocaleString("en-GB")} participants · {c.countries ? c.countries.join(", ") : "every country"}
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  <Pill tone={statusTone(c.status)}>{c.status}</Pill>
                  <span className="hidden text-[12px] text-muted md:inline">{shortDateTime(c.updated_at)}</span>
                </div>
              </Link>
            );
          })}
        </Card>
      </main>
    </>
  );
}
