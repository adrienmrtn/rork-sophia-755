import { collections, featured, feedFor, guestCreators, stats, subjects, toCard } from "@/lib/catalog";
import { links } from "@/lib/config";
import { FeaturedPost, PostRow } from "@/components/posts";
import { FeedTabs } from "@/components/interactive";
import { AppCard, AuthorsToFollow, CollectionsMini } from "@/components/side";
import { Arrow, Avatar, Button } from "@/components/ui";

export default function Home() {
  const tabs = [{ key: "pour-vous", label: "Pour vous" }, ...subjects.map((s) => ({ key: s.slug, label: s.label }))];
  const lists = [feedFor(undefined, 12), ...subjects.map((s) => feedFor(s.slug, 10))];
  const writers = guestCreators.filter((c) => c.photo).slice(0, 5);

  return (
    <div className="mx-auto flex max-w-[1140px] gap-12 px-4 py-6 sm:px-8 lg:py-10">
      <main className="min-w-0 max-w-[680px] flex-1">
        <section className="relative overflow-hidden rounded-[24px] bg-cream px-6 py-8 sm:px-9 sm:py-10">
          <p className="fade-up eyebrow" style={{ "--d": "0ms" } as React.CSSProperties}>
            Un cours par jour · 10 minutes
          </p>
          <h1 className="mt-3 text-[38px] font-extrabold leading-[1.02] tracking-[-0.035em] sm:text-[52px]">
            <span className="rise-line">
              <span style={{ "--d": "60ms" } as React.CSSProperties}>Moins de scroll,</span>
            </span>{" "}
            <span className="rise-line">
              <span style={{ "--d": "160ms" } as React.CSSProperties}>plus de</span>
            </span>{" "}
            <span className="relative inline-block">
              <span className="rise-line">
                <span className="text-navy" style={{ "--d": "260ms" } as React.CSSProperties}>
                  culture.
                </span>
              </span>
              <svg className="draw absolute -bottom-1.5 left-0 h-3.5 w-full" viewBox="0 0 300 20" preserveAspectRatio="none" aria-hidden>
                <path d="M3 14C60 4 130 3 297 10" fill="none" stroke="var(--color-saffron)" strokeWidth="7" strokeLinecap="round" pathLength={1} />
              </svg>
            </span>
          </h1>
          <p className="fade-up mt-5 max-w-[34rem] font-serif text-[19px] leading-[1.5] text-ink-2 sm:text-[21px]" style={{ "--d": "380ms" } as React.CSSProperties}>
            Des cours courts écrits par des historiens, des médecins et des philosophes, un quiz pour retenir
            l&apos;essentiel, et vos apps bloquées tant que vous n&apos;avez pas lu.
          </p>
          <div className="fade-up mt-6 flex flex-wrap gap-3" style={{ "--d": "500ms" } as React.CSSProperties}>
            <Button href="/commencer">
              Commencer gratuitement <Arrow />
            </Button>
            <Button href={links.download} variant="secondary">
              Télécharger l&apos;app
            </Button>
          </div>
          <div className="fade-up mt-7 flex items-center gap-3" style={{ "--d": "620ms" } as React.CSSProperties}>
            <div className="flex -space-x-2">
              {writers.map((a) => (
                <Avatar key={a.slug} author={a} size={32} className="!ring-cream" />
              ))}
            </div>
            <p className="text-[13px] leading-snug text-ink-2">
              <strong className="text-ink">{stats.creators} auteurs</strong> · {stats.courses} cours · 500 000 lecteurs par mois
            </p>
          </div>
        </section>

        <div className="mt-8">
          <FeaturedPost c={toCard(featured[0])} />
        </div>

        <div className="mt-8">
          <FeedTabs tabs={tabs}>
            {lists.map((list, i) => (
              <div key={tabs[i].key}>
                <div className="divide-y divide-line">
                  {list.map((c) => (
                    <PostRow key={c.slug} c={toCard(c)} showSubject={i === 0} />
                  ))}
                </div>
                <a
                  href={i === 0 ? "/explorer" : `/matieres/${tabs[i].key}`}
                  className="group mt-2 flex items-center justify-between rounded-2xl bg-cream px-5 py-4 text-[15px] font-bold text-navy"
                >
                  {i === 0 ? `Explorer les ${stats.courses} cours` : `Tous les cours de ${tabs[i].label.toLowerCase()} (${subjects[i - 1].count})`}
                  <Arrow className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                </a>
              </div>
            ))}
          </FeedTabs>
        </div>
      </main>

      <aside className="hidden w-[300px] shrink-0 xl:block">
        <div className="sticky top-8 space-y-9">
          <AppCard />
          <AuthorsToFollow authors={writers} />
          <CollectionsMini items={collections.slice(0, 4)} />
        </div>
      </aside>
    </div>
  );
}
