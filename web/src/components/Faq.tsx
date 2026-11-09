import { site } from "@/lib/site";
import { Reveal } from "./Reveal";

const faq = [
  {
    q: "C'est quoi, Sophia ?",
    a: "Une app de culture générale : chaque jour, un cours court écrit par un spécialiste, suivi d'un quiz pour retenir l'essentiel. Histoire, sciences, littérature, art, mythologie et actualité du monde.",
  },
  {
    q: "Combien de temps faut-il par jour ?",
    a: "Environ 10 minutes. Les cours sont pensés pour se lire d'une traite : dans les transports, à la pause déjeuner ou avant de dormir.",
  },
  {
    q: "Qui écrit les cours ?",
    a: `Des profs, des chercheurs et des auteurs spécialisés (${site.stats.creators} à ce jour), venus d'universités comme Oxford, Queen's University Belfast ou l'université de Belgrade. Chaque cours est relu avant publication.`,
  },
  {
    q: "Comment marche le bloqueur d'apps ?",
    a: "Tu choisis les apps qui te distraient. Sophia les verrouille jusqu'à ce que ton cours du jour soit terminé, puis les libère. Tu gardes la main sur la liste à tout moment.",
  },
  {
    q: "Sophia est-elle gratuite ?",
    a: "Tu peux télécharger Sophia et lire des cours gratuitement. L'abonnement Premium débloque toute la bibliothèque, les quiz illimités et toutes les fonctionnalités, avec un essai gratuit pour tester.",
  },
  {
    q: "Sur quels appareils et dans quelles langues ?",
    a: `Sur iPhone et Android, en ${site.stats.languages} langues, dont le français, l'anglais, l'espagnol, l'allemand, l'italien, le portugais et le japonais.`,
  },
];

export function Faq() {
  return (
    <section id="faq" className="scroll-mt-20 border-b-[3px] border-ink bg-sky py-20 sm:py-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <Reveal>
          <h2 className="text-center font-display text-4xl font-extrabold tracking-tight sm:text-5xl">
            Des questions ? On a les réponses.
          </h2>
        </Reveal>
        <div className="mt-12 space-y-4">
          {faq.map((item, i) => (
            <Reveal key={item.q} delay={i * 50}>
              <details className="brutal group rounded-2xl bg-paper [&_summary::-webkit-details-marker]:hidden" open={i === 0}>
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4 p-5 font-display text-lg font-bold">
                  {item.q}
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 border-ink bg-saffron transition-transform duration-300 group-open:rotate-45">
                    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round">
                      <path d="M12 5v14M5 12h14" />
                    </svg>
                  </span>
                </summary>
                <p className="px-5 pb-5 leading-relaxed text-ink-soft">{item.a}</p>
              </details>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
