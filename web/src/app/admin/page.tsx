import Link from "next/link";
import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { ReadsChart } from "@/components/studio/ReadsChart";
import { StatusPill } from "@/components/studio/StudioChrome";
import { Card, container } from "@/components/ui";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { dayLabel, moneyCents } from "@/lib/studio/payments";

export const dynamic = "force-dynamic";

interface Overview {
  days: number;
  review_queue: number;
  proposals_waiting: number;
  drafts_by_status: Record<string, number>;
  creators_pending: number;
  creators_approved: number;
  creators_published: number;
  agreements_missing: number;
  jobs: Record<string, number>;
  courses_published: number;
  courses_in_production: number;
  reads: number;
  completes: number;
  readers: number;
  series: { day: string; completes: number; reads: number }[];
  by_language: { lang: string; reads: number }[];
  by_subject: { subject: string; reads: number; completes: number; courses: number }[];
  payouts: { fee_cents: number; currency: string; due_cents: number; creators_due: number; validated_period: number; paid_total_cents: number; next_monday: string | null };
}

const PERIODS = [7, 28, 90];

export default async function AdminOverview({ searchParams }: PageProps<"/admin">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const sp = await searchParams;
  const days = PERIODS.includes(Number(sp.days)) ? Number(sp.days) : 28;
  const [{ data, error }, { data: recent }] = await Promise.all([
    session.supabase.rpc("studio_admin_overview", { p_days: days }),
    session.supabase.from("studio_reviews").select("id,decision,comment,created_at,draft_id,studio_drafts(title)").order("created_at", { ascending: false }).limit(20),
  ]);
  const o = (data ?? null) as Overview | null;
  type Recent = { id: number; decision: string; comment: string | null; created_at: string; draft_id: string; studio_drafts: { title: string } | { title: string }[] | null };
  const activity = (recent ?? []) as unknown as Recent[];
  const pay = o?.payouts;
  const currency = pay?.currency ?? "USD";
  const queue = (o?.review_queue ?? 0) + (o?.proposals_waiting ?? 0);

  return (
    <>
      <AdminHeader session={session} active="overview" queue={queue} />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Overview" lead="Proposals, review, creators, payouts, production and reading, across the whole catalogue.">
          <div className="flex items-center gap-1 rounded-xl border border-line bg-white p-1">
            {PERIODS.map((p) => (
              <Link key={p} href={p === 28 ? "/admin" : `/admin?days=${p}`} className={`rounded-lg px-3 py-1.5 text-[13px] font-bold ${p === days ? "bg-navy text-white" : "text-ink-3 hover:bg-paper"}`}>
                {p === 90 ? "3 months" : `${p} days`}
              </Link>
            ))}
          </div>
        </AdminTitle>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}
        {o && (
          <>
            <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
              <Tile label="Proposals to decide" value={o.proposals_waiting} href="/admin/review" tone={o.proposals_waiting ? "amber" : undefined} />
              <Tile label="Courses to review" value={o.review_queue} href="/admin/review" tone={o.review_queue ? "coral" : undefined} />
              <Tile label="Creators waiting" value={o.creators_pending} href="/admin/creators" tone={o.creators_pending ? "amber" : undefined} />
              <Tile label="Agreements missing" value={o.agreements_missing} href="/admin/creators" />
              <Tile label="In production" value={o.courses_in_production} href="/admin/production" />
              <Tile label="Courses published" value={o.courses_published} />
              <Tile label={`Reads · ${days} days`} value={o.reads} />
              <Tile label="Completed" value={o.completes} />
            </div>
            <div className="grid grid-cols-1 gap-5 lg:grid-cols-[2fr_1fr]">
              <Card className="flex flex-col gap-4 p-6">
                <div className="flex flex-col gap-0.5">
                  <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Reads per day</h2>
                  <span className="text-[13px] text-ink-3">Every course, every language</span>
                </div>
                <ReadsChart series={o.series.map((p) => ({ day: p.day, reads: Number(p.reads) }))} />
              </Card>
              <Card className="flex flex-col gap-3 border-cream-2 bg-cream p-6">
                <div className="flex items-start justify-between gap-3">
                  <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Monday payouts</h2>
                  <Link href="/admin/payouts" className="text-[13px] font-bold text-blue">
                    Pay →
                  </Link>
                </div>
                <strong className="text-[34px] font-extrabold tracking-[-0.9px] text-navy tabular-nums">{moneyCents(Number(pay?.due_cents ?? 0), currency)}</strong>
                <dl className="grid grid-cols-2 gap-x-4 gap-y-2 text-[14px]">
                  <dt className="text-ink-3">Authors to pay</dt>
                  <dd className="text-right font-bold tabular-nums">{pay?.creators_due ?? 0}</dd>
                  <dt className="text-ink-3">Next Monday</dt>
                  <dd className="text-right font-bold">{pay?.next_monday ? dayLabel(pay.next_monday).replace(/^Monday /, "") : "–"}</dd>
                  <dt className="text-ink-3">Validated · {days} days</dt>
                  <dd className="text-right font-bold tabular-nums">{pay?.validated_period ?? 0}</dd>
                  <dt className="text-ink-3">Fee per course</dt>
                  <dd className="text-right font-bold tabular-nums">{moneyCents(Number(pay?.fee_cents ?? 1500), currency)}</dd>
                  <dt className="text-ink-3">Paid so far</dt>
                  <dd className="text-right font-bold tabular-nums">{moneyCents(Number(pay?.paid_total_cents ?? 0), currency)}</dd>
                </dl>
              </Card>
            </div>
            <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
              <Card className="flex flex-col gap-3 p-6">
                <h2 className="text-[16px] font-extrabold">By subject</h2>
                <ul className="flex flex-col divide-y divide-line text-[13px]">
                  {o.by_subject.map((x) => (
                    <li key={x.subject} className="flex items-center justify-between py-1.5">
                      <span className="font-semibold">{SUBJECT_LABEL[x.subject as keyof typeof SUBJECT_LABEL] ?? x.subject}</span>
                      <span className="tabular-nums text-ink-3">
                        {Number(x.reads).toLocaleString("en")} reads · {x.courses} courses
                      </span>
                    </li>
                  ))}
                  {o.by_subject.length === 0 && <li className="py-1.5 text-muted">No reading recorded yet.</li>}
                </ul>
              </Card>
              <Card className="flex flex-col gap-3 p-6">
                <h2 className="text-[16px] font-extrabold">By language</h2>
                <ul className="grid grid-cols-2 gap-x-4 text-[13px]">
                  {o.by_language.slice(0, 16).map((x) => (
                    <li key={x.lang} className="flex items-center justify-between border-b border-line py-1.5">
                      <span className="font-semibold uppercase">{x.lang}</span>
                      <span className="tabular-nums text-ink-3">{Number(x.reads).toLocaleString("en")}</span>
                    </li>
                  ))}
                  {o.by_language.length === 0 && <li className="py-1.5 text-muted">No reading recorded yet.</li>}
                </ul>
              </Card>
              <Card className="flex flex-col gap-3 p-6">
                <h2 className="text-[16px] font-extrabold">Pipeline</h2>
                <div className="flex flex-wrap gap-1.5">
                  {Object.entries(o.drafts_by_status).map(([st, n]) => (
                    <span key={st} className="inline-flex items-center gap-1.5">
                      <StatusPill status={st} />
                      <span className="text-[13px] font-bold tabular-nums">{n}</span>
                    </span>
                  ))}
                  {Object.keys(o.drafts_by_status).length === 0 && <span className="text-[13px] text-muted">No course yet.</span>}
                </div>
                <dl className="grid grid-cols-2 gap-x-4 gap-y-1 border-t border-line pt-3 text-[13px]">
                  {Object.entries(o.jobs).map(([st, n]) => (
                    <div key={st} className="contents">
                      <dt className="text-ink-3">Jobs {st}</dt>
                      <dd className="text-right font-bold tabular-nums">{n}</dd>
                    </div>
                  ))}
                  <dt className="text-ink-3">Creators approved</dt>
                  <dd className="text-right font-bold tabular-nums">{o.creators_approved}</dd>
                  <dt className="text-ink-3">Authors in the app</dt>
                  <dd className="text-right font-bold tabular-nums">{o.creators_published}</dd>
                  <dt className="text-ink-3">Readers · {days} days</dt>
                  <dd className="text-right font-bold tabular-nums">{Number(o.readers).toLocaleString("en")}</dd>
                </dl>
              </Card>
            </div>
          </>
        )}
        <Card className="flex flex-col gap-3 p-6">
          <h2 className="text-[16px] font-extrabold">Recent activity</h2>
          <ul className="flex flex-col divide-y divide-line text-[13px]">
            {activity.length === 0 && <li className="py-2 text-muted">Nothing yet.</li>}
            {activity.map((a) => {
              const draft = Array.isArray(a.studio_drafts) ? a.studio_drafts[0] : a.studio_drafts;
              const pill =
                a.decision === "published" ? "published"
                : a.decision === "publish_failed" ? "failed"
                : a.decision === "rejected" ? "archived"
                : a.decision === "reopened" || a.decision === "withdrawn" ? "draft"
                : a.decision === "note" || a.decision === "validated" ? "accepted"
                : a.decision === "proposal_accepted" ? "draft"
                : a.decision;
              return (
                <li key={a.id} className="flex flex-wrap items-center gap-x-3 gap-y-1 py-2">
                  <span className="w-[120px] shrink-0 text-muted">{shortDateTime(a.created_at)}</span>
                  <StatusPill status={pill} />
                  <Link href={`/admin/review/${a.draft_id}`} className="font-bold text-ink hover:text-navy">
                    {draft?.title || "Untitled course"}
                  </Link>
                  {a.comment && a.decision !== "proposed" && <span className="min-w-0 flex-1 truncate text-ink-3">{a.comment}</span>}
                </li>
              );
            })}
          </ul>
        </Card>
      </main>
    </>
  );
}

function Tile({ label, value, href, tone }: { label: string; value: number; href?: string; tone?: "coral" | "amber" }) {
  const inner = (
    <Card className={`flex h-full flex-col gap-1 p-5 ${href ? "hover:border-line-2" : ""}`}>
      <span className="text-[13px] font-bold text-ink-3">{label}</span>
      <strong className={`text-[28px] font-extrabold tracking-[-0.7px] tabular-nums ${tone === "coral" ? "text-coral" : tone === "amber" ? "text-amber" : "text-ink"}`}>{Number(value).toLocaleString("en")}</strong>
    </Card>
  );
  return href ? <Link href={href}>{inner}</Link> : inner;
}
