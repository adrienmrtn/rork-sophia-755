import type { Metadata } from "next";
import Image from "next/image";
import { coursesOf, getCreator, guestCreators, stats, universities } from "@/lib/catalog";
import { FollowButton } from "@/components/interactive";
import { IconVerified } from "@/components/icons";
import { Arrow, Avatar, Button } from "@/components/ui";

export const metadata: Metadata = { title: "Les auteurs · Sophia", description: "Les profs, chercheurs et auteurs qui écrivent les cours de Sophia." };

export default function AuthorsPage() {
  const house = getCreator("redaction")!;
  const all = [...guestCreators, house];
  return (
    <div className="mx-auto max-w-[1000px] px-4 py-10 sm:px-8 lg:py-14">
      <p className="fade-up eyebrow">Les auteurs</p>
      <h1 className="fade-up mt-3 max-w-2xl text-[36px] font-extrabold leading-[1.06] tracking-[-0.03em] sm:text-[48px]" style={{ "--d": "60ms" } as React.CSSProperties}>
        Écrits par des profs et des chercheurs
      </h1>
      <p className="fade-up mt-4 max-w-2xl font-serif text-[20px] leading-relaxed text-ink-2" style={{ "--d": "140ms" } as React.CSSProperties}>
        {stats.creators} auteurs invités, venus d&apos;universités du monde entier, et une rédaction qui relit chaque cours avant publication.
      </p>
      <div className="mt-6 flex flex-wrap items-center gap-x-8 gap-y-4 opacity-70">
        {universities.map((u) => (
          <Image key={u} src={u} alt="" width={140} height={56} className="h-10 w-auto object-contain grayscale" />
        ))}
      </div>

      <ul className="mt-12 grid gap-4 sm:grid-cols-2">
        {all.map((a, i) => {
          const latest = coursesOf(a.courses)[0];
          return (
            <li
              key={a.slug}
              className="fade-up group relative rounded-[22px] bg-paper p-5 ring-1 ring-line transition-shadow hover:shadow-[0_24px_48px_-28px_rgba(22,38,61,0.4)]"
              style={{ "--d": `${120 + i * 40}ms` } as React.CSSProperties}
            >
              <div className="flex items-center gap-4">
                <Avatar author={a} size={60} className="!ring-0" />
                <div className="min-w-0 flex-1">
                  <a href={`/auteurs/${a.slug}`} className="flex items-center gap-1 text-[17px] font-extrabold after:absolute after:inset-0 group-hover:text-navy">
                    <span className="truncate">{a.name}</span>
                    {a.slug !== "redaction" && <IconVerified className="h-4 w-4 shrink-0 text-sky" />}
                  </a>
                  <p className="text-[13px] font-semibold text-sky">{a.courses.length} cours</p>
                </div>
                <FollowButton slug={a.slug} size="sm" />
              </div>
              <p className="mt-3 line-clamp-2 font-serif text-[16px] leading-snug text-ink-2">{a.title}</p>
              {latest && (
                <p className="mt-3 flex items-center gap-2 border-t border-line pt-3 text-[13px] text-ink-2">
                  <span className="relative h-8 w-11 shrink-0 overflow-hidden rounded-md">
                    <Image src={latest.image} alt="" fill sizes="44px" className="object-cover" />
                  </span>
                  <span className="line-clamp-1 font-semibold text-ink">{latest.title}</span>
                </p>
              )}
            </li>
          );
        })}
      </ul>

      <section className="mt-14 flex flex-col items-start justify-between gap-6 rounded-[24px] bg-navy-deep p-8 text-white sm:flex-row sm:items-center">
        <div>
          <p className="text-[24px] font-extrabold tracking-tight">Vous enseignez ou faites de la recherche ?</p>
          <p className="mt-1 font-serif text-[18px] text-white/80">Écrivez un cours, Sophia le traduit en {stats.languages} langues.</p>
        </div>
        <Button href="/devenir-createur" variant="saffron">
          Devenir créateur <Arrow />
        </Button>
      </section>
    </div>
  );
}
