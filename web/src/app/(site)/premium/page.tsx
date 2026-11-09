import type { Metadata } from "next";
import Image from "next/image";
import { featured, stats } from "@/lib/catalog";
import { plans } from "@/lib/config";
import { Faq, Testimonials } from "@/components/Closing";
import { IconCheck } from "@/components/icons";
import { Arrow, Button } from "@/components/ui";

export const metadata: Metadata = { title: "Premium · Sophia", description: "Tous les cours, toutes les langues, sans publicité. Trois jours d'essai gratuits." };

const rows: [string, boolean, boolean][] = [
  ["L'introduction de chaque cours", true, true],
  ["Le cours du jour", true, true],
  [`Les ${stats.courses} cours en entier`, false, true],
  ["Tous les quiz et la révision espacée", false, true],
  ["La narration audio", false, true],
  ["Le Parcours et les collections", false, true],
  ["Le bloqueur d'apps", false, true],
  ["Sans publicité", false, true],
];

export default function PremiumPage() {
  const covers = featured.slice(0, 5);
  return (
    <div className="pb-4">
      <section className="relative overflow-hidden bg-navy-deep px-4 pb-16 pt-12 text-white sm:px-8 lg:pt-16">
        <div className="mx-auto grid max-w-[1000px] items-center gap-10 lg:grid-cols-[1.1fr_1fr]">
          <div>
            <p className="fade-up eyebrow !text-saffron">Sophia Premium</p>
            <h1 className="fade-up mt-3 text-[38px] font-extrabold leading-[1.04] tracking-[-0.035em] sm:text-[54px]" style={{ "--d": "60ms" } as React.CSSProperties}>
              Tous les cours, toutes les langues, sans publicité.
            </h1>
            <p className="fade-up mt-5 max-w-lg font-serif text-[20px] leading-relaxed text-white/80" style={{ "--d": "140ms" } as React.CSSProperties}>
              L&apos;introduction de chaque cours est gratuite. Premium ouvre la suite : les {stats.courses} cours, les quiz, la
              narration audio, le Parcours, et le bloqueur qui garde vos autres apps fermées jusqu&apos;au cours du jour.
            </p>
          </div>
          <div className="relative mx-auto h-[260px] w-full max-w-[380px] sm:h-[300px]" aria-hidden>
            {covers.map((c, i) => {
              const o = i - 2;
              return (
                <div
                  key={c.slug}
                  className="absolute left-1/2 top-2 w-[150px] origin-bottom sm:w-[170px]"
                  style={{ marginLeft: -85, transform: `translateX(${o * 52}px) rotate(${o * 8}deg) translateY(${Math.abs(o) * 14}px)`, zIndex: 10 - Math.abs(o) }}
                >
                  <div className="fade-up relative aspect-[4/5] overflow-hidden rounded-2xl shadow-2xl" style={{ "--d": `${200 + i * 80}ms` } as React.CSSProperties}>
                    <Image src={c.image} alt="" fill sizes="170px" className="object-cover" />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <section className="mx-auto -mt-8 grid max-w-[860px] gap-5 px-4 sm:grid-cols-2 sm:px-8">
        {Object.values(plans).map((p, i) => (
          <div
            key={p.id}
            className={`fade-up relative flex flex-col rounded-[24px] bg-paper p-6 shadow-[0_30px_60px_-30px_rgba(22,38,61,0.4)] sm:p-7 ${i === 0 ? "ring-2 ring-navy" : "ring-1 ring-line"}`}
            style={{ "--d": `${300 + i * 100}ms` } as React.CSSProperties}
          >
            {p.badge && <span className="absolute -top-3 left-6 rounded-full bg-saffron px-3 py-1 text-[12px] font-extrabold text-ink">{p.badge}</span>}
            <p className="text-[15px] font-bold text-ink-2">{p.name}</p>
            <p className="mt-2 text-[40px] font-extrabold tracking-tight">
              {p.price} <span className="text-[16px] font-semibold text-ink-2">{p.period}</span>
            </p>
            <p className="text-[14px] font-semibold text-sky">{p.id === "annuel" ? `Soit ${p.perMonth}` : "Sans engagement"}</p>
            <p className="mt-4 font-serif text-[16px] leading-snug text-ink-2">
              {p.trialDays} jours d&apos;essai gratuits, puis {p.price} {p.period}. Annulable à tout moment.
            </p>
            <div className="mt-6">
              <Button href={`/commencer?offre=${p.id}`} variant={i === 0 ? "primary" : "secondary"} className="w-full">
                Essayer {p.trialDays} jours gratuits <Arrow />
              </Button>
            </div>
          </div>
        ))}
      </section>
      <p className="mt-4 text-center text-[13px] text-ink-3">Prix en euros, TTC. L&apos;abonnement donne accès à Premium sur le web et dans l&apos;app.</p>

      <section className="mx-auto mt-16 max-w-[760px] px-4 sm:px-8">
        <h2 className="text-[28px] font-extrabold tracking-tight">Gratuit ou Premium</h2>
        <div className="mt-6 overflow-x-auto rounded-[20px] ring-1 ring-line">
          <table className="w-full min-w-[480px] text-left text-[15px]">
            <thead className="bg-cream text-[13px] font-bold uppercase tracking-wider text-ink-3">
              <tr>
                <th className="px-5 py-3.5 font-bold">Ce qui est inclus</th>
                <th className="w-28 px-5 py-3.5 text-center font-bold">Gratuit</th>
                <th className="w-28 px-5 py-3.5 text-center font-bold text-navy">Premium</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {rows.map(([label, free, prem]) => (
                <tr key={label}>
                  <td className="px-5 py-3.5 font-semibold">{label}</td>
                  <td className="px-5 py-3.5 text-center">{free ? <IconCheck className="mx-auto h-5 w-5 text-sage" /> : <span className="text-ink-3">·</span>}</td>
                  <td className="px-5 py-3.5 text-center">{prem && <IconCheck className="mx-auto h-5 w-5 text-navy" />}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <div className="mt-16">
        <Testimonials />
        <Faq />
      </div>
    </div>
  );
}
