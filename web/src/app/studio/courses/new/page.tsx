import { redirect } from "next/navigation";
import { Art } from "@/components/studio/Art";
import { StudioHeader } from "@/components/studio/StudioChrome";
import { ButtonLink, Card, container } from "@/components/ui";
import { s } from "@/lib/copy/studio-en";
import { getStudioSession } from "@/lib/studio/account";
import { moneyCents, quotaSummary, type QuotaTone } from "@/lib/studio/payments";
import { proposeCourse } from "@/app/studio/actions";

export const dynamic = "force-dynamic";

const TONE: Record<QuotaTone, string> = { ok: "bg-tint text-navy", full: "bg-cream text-amber", blocked: "bg-red-bg text-red" };

/** La proposition d'un cours : un titre et un pitch, dans la limite du quota. Le brouillon n'existe
 *  qu'une fois la proposition acceptée par l'équipe. */
export default async function NewCoursePage({ searchParams }: PageProps<"/studio/courses/new">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio/courses/new");
  if (!session.account) redirect("/studio/onboarding/identity");
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const title = typeof sp.title === "string" ? sp.title : "";
  const pitch = typeof sp.pitch === "string" ? sp.pitch : "";
  const p = s.proposal;
  const quota = session.quota;
  const q = quotaSummary(quota);
  const canPropose = quota ? quota.can_propose : true;
  const fee = moneyCents(quota?.fee_cents ?? 1500, quota?.currency ?? "USD");

  return (
    <>
      <StudioHeader session={session} active="courses" />
      <main className={`${container} flex flex-1 flex-col items-start gap-6 pt-10 pb-20`}>
        <Card className="grid w-full max-w-[920px] grid-cols-1 gap-8 border-cream-2 bg-cream p-8 md:grid-cols-[220px_minmax(0,1fr)] md:p-10">
          <div className="flex flex-col items-center gap-5 md:items-start">
            <Art name="studio_desk" size={220} priority />
            <div className={`w-full rounded-2xl px-4 py-3 text-[13px] font-semibold leading-[1.45] ${TONE[q.tone]}`}>
              <span className="block font-extrabold">{q.headline}</span>
              {q.detail && <span className="block opacity-90">{q.detail}</span>}
            </div>
            <p className="text-[13px] leading-[1.5] text-ink-3">{p.fee(fee)}</p>
          </div>
          <div className="flex flex-col gap-5">
            <div className="flex flex-col gap-2">
              <h1 className="text-[30px] font-extrabold leading-[1.1] tracking-[-0.7px] text-ink">{p.title}</h1>
              <p className="text-[16px] leading-[1.55] text-ink-2">{p.lead}</p>
            </div>
            {error && (
              <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
                {error}
              </p>
            )}
            {canPropose ? (
              <form action={proposeCourse} className="flex flex-col gap-5">
                <label className="flex flex-col gap-1.5">
                  <span className="text-[13px] font-bold text-ink-2">{p.titleField}</span>
                  <input name="title" defaultValue={title} required minLength={8} maxLength={160} placeholder="Why did soldiers stop fighting on Christmas 1914?" className="h-12 w-full rounded-xl border border-line bg-white px-4 text-[17px] font-bold text-ink outline-none focus:border-blue" />
                  <span className="text-[12px] text-ink-3">{p.titleHelp}</span>
                </label>
                <label className="flex flex-col gap-1.5">
                  <span className="text-[13px] font-bold text-ink-2">{p.pitchField}</span>
                  <textarea name="pitch" defaultValue={pitch} required minLength={40} maxLength={600} rows={6} placeholder="The question the course answers, the angle you take, what the reader knows at the end." className="w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-[15px] leading-[1.55] text-ink outline-none focus:border-blue" />
                  <span className="text-[12px] text-ink-3">{p.pitchHelp}</span>
                </label>
                <div className="flex flex-wrap items-center gap-3 pt-1">
                  <button type="submit" className="inline-flex h-11 items-center gap-2 rounded-full bg-navy px-5 text-[15px] font-bold text-white transition-colors hover:bg-ink">
                    {p.send}
                  </button>
                  <ButtonLink href="/studio/guide" variant="secondary" className="!rounded-full">
                    {s.nav.guide}
                  </ButtonLink>
                </div>
              </form>
            ) : (
              <div className="flex flex-col items-start gap-4 rounded-2xl bg-white/70 p-5">
                <p className="text-[15px] font-semibold text-ink">{p.cannot}</p>
                <p className="text-[14px] leading-[1.5] text-ink-2">{q.detail || q.headline}</p>
                <ButtonLink href="/studio/courses" variant="secondary" className="!rounded-full">
                  {s.courses.title}
                </ButtonLink>
              </div>
            )}
          </div>
        </Card>
      </main>
    </>
  );
}
