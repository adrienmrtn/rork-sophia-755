import type { Metadata } from "next";
import Image from "next/image";
import { coursesOf, guestCreators, stats, universities } from "@/lib/catalog";
import { CreatorForm, EditorMock } from "@/components/creator";
import { Arrow, Avatar, Button } from "@/components/ui";

export const metadata: Metadata = {
  title: "Devenir créateur · Sophia",
  description: "Vous savez quelque chose que le monde devrait savoir ? Écrivez un cours, Sophia le traduit en 30 langues et vous reverse une part des revenus.",
};

const steps = [
  { title: "Compte auteur", text: "nom, titre, institution, photo, contrat signé en ligne." },
  { title: "500 à 900 mots", text: "cinq parties, une frise, un « Le savais-tu ? », des images libres de droits." },
  { title: "Relecture sous 72 h", text: "l'équipe relit, demande au besoin une retouche, puis accepte." },
  { title: `Publié en ${stats.languages} langues`, text: "quiz, glossaire, couverture, traductions et audio faits pour vous." },
];

const perks = [
  { title: "Une part des revenus Premium", text: "Chaque mois, selon le temps que les abonnés passent sur vos cours." },
  { title: `Lu dans ${stats.languages} langues`, text: "Vos cours sont traduits, relus par des natifs, et mis en voix." },
  { title: "Votre page d'auteur", text: "Photo, biographie, liens vers vos travaux, et des lecteurs qui vous suivent." },
  { title: "Des chiffres clairs", text: "Lectures, temps passé, taux de réussite aux quiz, cours par cours." },
];

const faq = [
  ["Faut-il être universitaire ?", "Non. Nous cherchons des personnes qui connaissent leur sujet en profondeur : enseignants, chercheurs, doctorants, conservateurs, journalistes spécialisés, auteurs."],
  ["Dans quelle langue écrire ?", "Dans la vôtre. L'équipe traduit et fait relire chaque version par un locuteur natif."],
  ["Combien de temps prend un cours ?", "Comptez une à deux heures d'écriture pour 500 à 900 mots. L'éditeur vous guide partie par partie."],
  ["Qui s'occupe des quiz et des images ?", "Sophia prépare le quiz, le glossaire, la couverture et la version audio. Vous validez avant publication."],
];

export default function CreatorPage() {
  const writers = guestCreators.filter((c) => c.photo).slice(0, 6);
  return (
    <div className="pb-8">
      <section className="bg-cream px-4 pb-16 pt-12 sm:px-8 lg:pt-16">
        <div className="mx-auto grid max-w-[1040px] items-center gap-12 lg:grid-cols-[1.1fr_1fr]">
          <div>
            <p className="fade-up eyebrow">Pour les enseignants et les chercheurs</p>
            <h1 className="fade-up mt-3 text-[36px] font-extrabold leading-[1.06] tracking-[-0.035em] sm:text-[50px]" style={{ "--d": "60ms" } as React.CSSProperties}>
              Vous savez quelque chose que le monde devrait savoir ? Écrivez un cours.
            </h1>
            <p className="fade-up mt-5 font-serif text-[20px] leading-relaxed text-ink-2" style={{ "--d": "140ms" } as React.CSSProperties}>
              Vous écrivez dans votre langue, dans un éditeur qui vous guide. Sophia relit, traduit en {stats.languages} langues, met
              en voix et publie. Vous suivez vos lectures et recevez chaque mois une part des revenus Premium, selon le temps que
              les abonnés passent sur vos cours.
            </p>
            <div className="fade-up mt-7 flex flex-wrap gap-3" style={{ "--d": "220ms" } as React.CSSProperties}>
              <Button href="#candidature" size="lg">
                Devenir auteur <Arrow />
              </Button>
              <Button href="/auteurs" variant="secondary" size="lg">
                Voir les auteurs
              </Button>
            </div>
            <div className="fade-up mt-8 flex items-center gap-3" style={{ "--d": "300ms" } as React.CSSProperties}>
              <div className="flex -space-x-2">
                {writers.map((a) => (
                  <Avatar key={a.slug} author={a} size={34} className="!ring-cream" />
                ))}
              </div>
              <p className="text-[13px] leading-snug text-ink-2">
                Rejoignez {stats.creators} auteurs d&apos;Oxford, Boston, Belgrade, Istanbul…
              </p>
            </div>
          </div>
          <div className="fade-up" style={{ "--d": "200ms" } as React.CSSProperties}>
            <EditorMock />
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-[1040px] px-4 py-16 sm:px-8">
        <h2 className="text-[28px] font-extrabold tracking-tight sm:text-[34px]">Comment ça marche</h2>
        <ol className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((s, i) => (
            <li key={s.title} className="fade-up rounded-[20px] p-6 ring-1 ring-line" style={{ "--d": `${i * 80}ms` } as React.CSSProperties}>
              <span className="flex h-9 w-9 items-center justify-center rounded-full bg-navy text-[15px] font-extrabold text-white">{i + 1}</span>
              <p className="mt-4 text-[18px] font-extrabold">{s.title}</p>
              <p className="mt-1 font-serif text-[16px] leading-snug text-ink-2">{s.text}</p>
            </li>
          ))}
        </ol>

        <div className="mt-14 grid gap-5 sm:grid-cols-2">
          {perks.map((p) => (
            <div key={p.title} className="rounded-[20px] bg-cream p-6">
              <p className="text-[18px] font-extrabold">{p.title}</p>
              <p className="mt-1 font-serif text-[17px] leading-snug text-ink-2">{p.text}</p>
            </div>
          ))}
        </div>

        <div className="mt-14 flex flex-wrap items-center justify-center gap-x-10 gap-y-5 opacity-70">
          {universities.map((u) => (
            <Image key={u} src={u} alt="" width={140} height={56} className="h-11 w-auto object-contain grayscale" />
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-[1040px] px-4 sm:px-8">
        <h2 className="text-[28px] font-extrabold tracking-tight sm:text-[34px]">Ils écrivent déjà sur Sophia</h2>
        <ul className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {writers.map((a) => {
            const c = coursesOf(a.courses)[0];
            return (
              <li key={a.slug} className="group relative overflow-hidden rounded-[20px] ring-1 ring-line">
                <div className="relative aspect-[16/8]">
                  <Image src={c.image} alt="" fill sizes="340px" className="object-cover transition-transform duration-700 group-hover:scale-105" />
                </div>
                <div className="flex items-center gap-3 p-4">
                  <Avatar author={a} size={42} className="!ring-0" />
                  <div className="min-w-0">
                    <a href={`/auteurs/${a.slug}`} className="block truncate text-[15px] font-extrabold after:absolute after:inset-0 group-hover:text-navy">
                      {a.name}
                    </a>
                    <p className="line-clamp-1 text-[13px] text-ink-2">« {c.title} »</p>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      </section>

      <section id="candidature" className="mx-auto mt-16 max-w-[820px] scroll-mt-20 px-4 sm:px-8">
        <p className="eyebrow">Candidature</p>
        <h2 className="mt-2 text-[30px] font-extrabold tracking-tight sm:text-[38px]">Proposez votre premier cours</h2>
        <p className="mt-2 font-serif text-[18px] text-ink-2">L&apos;équipe éditoriale lit chaque candidature et répond sous une semaine.</p>
        <div className="mt-6">
          <CreatorForm />
        </div>
      </section>

      <section className="mx-auto mt-16 max-w-[820px] px-4 sm:px-8">
        <h2 className="text-[24px] font-extrabold tracking-tight">Questions fréquentes</h2>
        <dl className="mt-4 divide-y divide-line border-y border-line">
          {faq.map(([q, a]) => (
            <div key={q} className="py-5">
              <dt className="text-[17px] font-extrabold">{q}</dt>
              <dd className="mt-1.5 font-serif text-[17px] leading-relaxed text-ink-2">{a}</dd>
            </div>
          ))}
        </dl>
      </section>
    </div>
  );
}
