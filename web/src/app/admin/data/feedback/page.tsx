import { redirect } from "next/navigation";
import { AdminHeader, AdminTitle } from "@/components/admin/AdminChrome";
import { DataNav, PLATFORM_LABEL, SectionTitle } from "@/components/admin/DataChrome";
import { Card, Pill, container } from "@/components/ui";
import { getStudioSession } from "@/lib/studio/account";
import { shortDateTime } from "@/lib/studio/data";
import { feedbackTranslations } from "@/lib/studio/feedback-translation";
import { dataRpcArgs, readDataFilters } from "@/lib/studio/paywalls";
import { FEEDBACK_CATEGORY_LABEL, type FeedbackDashboard } from "@/lib/studio/usage";

export const dynamic = "force-dynamic";

/** Les retours envoyés depuis le formulaire de l'app, les plus récents d'abord. Tout vient
 *  d'un appel à admin_feedback_dashboard, réservé à l'équipe. */
export default async function FeedbackDataPage({ searchParams }: PageProps<"/admin/data/feedback">) {
  const session = await getStudioSession();
  if (!session?.isAdmin) redirect("/studio");
  const filters = readDataFilters(await searchParams);

  const { data, error } = await session.supabase.rpc("admin_feedback_dashboard", dataRpcArgs(filters));
  const d = (data ?? null) as FeedbackDashboard | null;
  const translations = await feedbackTranslations(d?.items ?? []);

  return (
    <>
      <AdminHeader session={session} active="data" />
      <main className={`${container} flex flex-1 flex-col gap-6 pt-8 pb-20`}>
        <AdminTitle title="Data" lead="What people do in the app: paywalls, onboarding, usage, friends and feedback." />
        <DataNav active="feedback" filters={filters} languages={d?.languages ?? []} versions={d?.versions ?? []} />

        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
            {error.message}
          </p>
        )}

        {d && (
          <section className="flex flex-col gap-4">
            <SectionTitle title="Feedback" note="Messages sent from the form in the app settings, most recent first. To answer one, use the email it also sent: the address is not kept here. Messages in another language come with a French translation, written by a model the first time the page shows them." />
            {d.total === 0 ? (
              <Card className="p-6 text-[14px] text-ink-3">No feedback with these filters. Messages are copied here by the next app versions; until then they only arrive by email.</Card>
            ) : (
              <>
                <div className="flex flex-wrap items-center gap-2 text-[14px]">
                  <strong className="font-extrabold text-ink tabular-nums">{d.total.toLocaleString("en")} messages</strong>
                  {d.by_category.map((c) => (
                    <span key={c.category} className="rounded-full border border-line bg-white px-3 py-1 font-semibold text-ink-2">
                      {FEEDBACK_CATEGORY_LABEL[c.category] ?? c.category} <span className="tabular-nums text-ink-3">{Number(c.count).toLocaleString("en")}</span>
                    </span>
                  ))}
                </div>
                {d.items.length < d.total && <p className="text-[13px] text-ink-3">Showing the {d.items.length} most recent.</p>}
                <ul className="flex flex-col gap-3">
                  {d.items.map((item) => (
                    <li key={item.id}>
                      <Card className="flex flex-col gap-2.5 p-5">
                        <div className="flex flex-wrap items-center gap-2 text-[13px] text-ink-3">
                          <Pill tone={item.category === "bug" ? "red" : item.category === "translation" ? "amber" : "tint"}>{FEEDBACK_CATEGORY_LABEL[item.category] ?? item.category}</Pill>
                          <span className="font-semibold text-ink-2">{shortDateTime(item.created_at)}</span>
                          <span>
                            {[PLATFORM_LABEL[item.platform] ?? item.platform, item.app_version ? `v${item.app_version}` : null, item.lang, item.device, item.os_version].filter(Boolean).join(" · ")}
                          </span>
                          {item.is_premium && <Pill tone="green">Premium</Pill>}
                          {item.has_email && <span>Left an email</span>}
                        </div>
                        <p className="text-[15px] leading-relaxed break-words whitespace-pre-wrap text-ink">{item.message}</p>
                        {translations.get(item.id) && (
                          <div className="flex flex-col gap-1 border-l-2 border-line pl-3">
                            <span className="text-[12px] font-bold uppercase tracking-[0.6px] text-ink-3">French translation</span>
                            <p lang="fr" className="text-[15px] leading-relaxed break-words whitespace-pre-wrap text-ink-2">
                              {translations.get(item.id)}
                            </p>
                          </div>
                        )}
                      </Card>
                    </li>
                  ))}
                </ul>
              </>
            )}
          </section>
        )}
      </main>
    </>
  );
}
