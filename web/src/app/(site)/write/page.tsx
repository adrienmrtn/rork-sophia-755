import Image from "next/image";
import type { Metadata } from "next";
import { SiteHeader } from "@/components/SiteChrome";
import { ArrowIcon, ButtonLink, CheckIcon, Eyebrow, container } from "@/components/ui";
import { t } from "@/lib/copy/en";

export const metadata: Metadata = {
  title: "Write for Sophia",
  description: "Write a five-minute course in your language. Sophia reviews, translates into 30 languages, publishes, and pays you for every validated course.",
};

export default function WritePage() {
  const w = t.write;
  return (
    <>
      <SiteHeader active="write" />
      <main>
        <section className={`${container} flex flex-wrap items-center gap-x-14 gap-y-10 pt-16 pb-[72px]`}>
          <div className="flex min-w-0 flex-[1_1_520px] flex-col gap-[22px]">
            <Eyebrow>{w.eyebrow}</Eyebrow>
            <h1 className="text-[42px] font-extrabold leading-[1.05] tracking-[-1.3px] md:text-[56px] md:tracking-[-1.7px]">{w.title}</h1>
            <p className="max-w-[580px] text-[19px] leading-[1.55] text-ink-3">{w.lead}</p>
            <div className="flex flex-wrap items-center gap-3 pt-1">
              <ButtonLink href="/join" className="h-[54px] px-6 text-[16px] font-extrabold">
                {w.cta}
              </ButtonLink>
              <ButtonLink href="/studio" variant="secondary" className="h-[54px] px-5 text-[16px]">
                {w.seeEditor} <ArrowIcon />
              </ButtonLink>
            </div>
            <span className="text-[14px] text-ink-3">{w.reassurance}</span>
          </div>
          <div className="flex min-w-0 flex-[1_1_440px] justify-center">
            <Image src="/art/poster_ecrire.webp" alt={t.home.ecrireAlt} width={1365} height={1024} priority className="aspect-[4/3] w-full max-w-[560px] rounded-[28px] object-cover shadow-[0_24px_60px_rgba(22,38,61,.16)]" />
          </div>
        </section>

        <section className="border-y border-line bg-paper">
          <div className={`${container} flex flex-col gap-9 py-[72px]`}>
            <div className="flex max-w-[720px] flex-col gap-2.5">
              <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px]">{w.howTitle}</h2>
              <p className="text-[17px] leading-[1.5] text-ink-3">{w.howLead}</p>
            </div>
            <div className="grid grid-cols-1 gap-[18px] sm:grid-cols-2 lg:grid-cols-4">
              {w.steps.map(([title, detail], i) => (
                <div key={title} className="flex flex-col gap-3.5 rounded-card border border-line bg-white p-6">
                  <span className="flex h-9 w-9 items-center justify-center rounded-full bg-navy text-[15px] font-extrabold text-white">{i + 1}</span>
                  <strong className="text-[18px] font-extrabold">{title}</strong>
                  <span className="text-[14px] leading-[1.55] text-ink-3">{detail}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className={`${container} flex flex-wrap items-center gap-x-14 gap-y-10 pt-20 pb-6`}>
          <div className="grid min-w-0 flex-[1_1_460px] grid-cols-2 gap-4">
            <Image src="/art/poster_langues.webp" alt="" width={600} height={600} className="aspect-square w-full rounded-card object-cover" />
            <Image src="/art/poster_quiz.webp" alt="" width={600} height={600} className="aspect-square w-full rounded-card object-cover" />
          </div>
          <div className="flex min-w-0 flex-[1_1_460px] flex-col gap-[18px]">
            <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px]">{w.onceTitle}</h2>
            <p className="text-[17px] leading-[1.55] text-ink-3">{w.onceLead}</p>
            <ul className="flex flex-col gap-3 text-[15px] font-semibold text-ink-2">
              {w.onceItems.map((item) => (
                <li key={item} className="flex items-start gap-2.5">
                  <CheckIcon className="mt-0.5 shrink-0 text-green-2" /> {item}
                </li>
              ))}
            </ul>
          </div>
        </section>

        <section className={`${container} pt-20 pb-6`}>
          <div className="flex flex-wrap gap-x-12 gap-y-8 rounded-[28px] bg-ink p-8 text-white md:p-12">
            <div className="flex min-w-0 flex-[1_1_460px] flex-col gap-4">
              <span className="text-[13px] font-bold uppercase tracking-[1.2px] text-saffron">{w.payEyebrow}</span>
              <h2 className="text-[36px] font-extrabold leading-[1.1] tracking-[-0.9px] text-white">{w.payTitle}</h2>
              <p className="text-[17px] leading-[1.55] text-[#DDE3EC]">{w.payLead}</p>
              <p className="text-[15px] leading-[1.5] text-[#C4CCD8]">{w.payNote}</p>
            </div>
            <div className="flex min-w-0 flex-[1_1_320px] flex-col gap-3.5 rounded-card border border-white/15 bg-white/[.08] p-6">
              <strong className="text-[13px] font-bold uppercase tracking-[1px] text-saffron">{w.exampleTitle}</strong>
              <div className="flex flex-col gap-2.5 text-[15px]">
                {w.exampleRows.map(([step, outcome], i) => (
                  <div key={step} className={`flex justify-between gap-3 ${i < w.exampleRows.length - 1 ? "border-b border-white/15 pb-2.5" : ""}`}>
                    <span className="text-[#DDE3EC]">{step}</span>
                    <strong className={i === w.exampleRows.length - 1 ? "text-saffron" : ""}>{outcome}</strong>
                  </div>
                ))}
              </div>
              <span className="text-[13px] leading-[1.5] text-[#C4CCD8]">{w.exampleNote}</span>
            </div>
          </div>
        </section>

        <section id="guide" className={`${container} flex flex-wrap items-start gap-x-14 gap-y-10 pt-20 pb-6`}>
          <div className="flex min-w-0 flex-[1_1_380px] flex-col gap-4">
            <h2 className="text-[32px] font-extrabold leading-[1.1] tracking-[-0.8px]">{w.whoTitle}</h2>
            <p className="text-[16px] leading-[1.55] text-ink-3">{w.whoLead}</p>
            <p className="text-[16px] leading-[1.55] text-ink-3">
              {w.whoVideo}{" "}
              <a href="https://sophia-culture.com/creators" className="font-bold text-blue">
                {w.hubLink}
              </a>
              .
            </p>
            <div className="flex flex-wrap gap-3 pt-2">
              <ButtonLink href="/join" className="h-[50px] px-[22px] font-extrabold">
                {w.cta}
              </ButtonLink>
              <ButtonLink href="/studio/guide" variant="secondary" className="h-[50px] px-5">
                {w.guide}
              </ButtonLink>
            </div>
          </div>
          <dl className="flex min-w-0 flex-[1_1_560px] flex-col border-t border-line">
            {w.faq.map(([q, a]) => (
              <div key={q} className="flex flex-col gap-1.5 border-b border-line py-[18px]">
                <dt className="text-[17px] font-bold">{q}</dt>
                <dd className="m-0 text-[15px] leading-[1.55] text-ink-3">{a}</dd>
              </div>
            ))}
          </dl>
        </section>

        <section className={`${container} pt-16 pb-24`}>
          <div className="flex flex-wrap items-center justify-between gap-x-8 gap-y-5 rounded-[28px] border border-cream-2 bg-cream px-10 py-9">
            <div className="flex max-w-[640px] flex-col gap-1.5">
              <strong className="text-[24px] font-extrabold tracking-[-0.5px]">{w.finalTitle}</strong>
              <span className="text-[15px] leading-[1.5] text-ink-3">{w.finalLead}</span>
            </div>
            <ButtonLink href="/join" className="h-[54px] px-6 text-[16px] font-extrabold">
              {w.cta}
            </ButtonLink>
          </div>
        </section>
      </main>
    </>
  );
}
