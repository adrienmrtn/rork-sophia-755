import type { Metadata } from "next";
import { SiteHeader } from "@/components/SiteChrome";
import { StoreButtons } from "@/components/StoreButtons";
import { Eyebrow, container } from "@/components/ui";

export const metadata: Metadata = { title: "About Sophia", description: "Sophia is a general-knowledge app: one five-minute course a day, written by professors and researchers, in 30 languages." };

export default function AboutPage() {
  return (
    <>
      <SiteHeader active="about" />
      <main className={`${container} flex flex-col gap-10 pt-12 pb-24`}>
        <div className="flex max-w-[720px] flex-col gap-3">
          <Eyebrow>About</Eyebrow>
          <h1 className="text-[44px] font-extrabold leading-[1.08] tracking-[-1.2px]">Learning something true, every day, should take five minutes.</h1>
          <p className="text-[18px] leading-[1.6] text-ink-3">
            Sophia is a general-knowledge app. Every course answers one real question in five short parts, ends with an open-book quiz, explains its difficult words and cites its sources. The courses are written by professors and researchers, reviewed before publication, and translated into 30 languages so that a reader in Tokyo and a reader in Lyon learn the same thing.
          </p>
          <p className="text-[18px] leading-[1.6] text-ink-3">500,000 people have read courses on Sophia. The app is free to start; Premium unlocks the full catalogue.</p>
        </div>
        <div id="help" className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div className="flex flex-col gap-2 rounded-card border border-line p-6">
            <strong className="text-[18px] font-extrabold">Help</strong>
            <p className="text-[15px] leading-[1.55] text-ink-3">Questions about your subscription, your account or a course go to our support address. We answer within two working days.</p>
            <a href="mailto:support@sophia-culture.com" className="text-[15px] font-bold text-blue">
              support@sophia-culture.com
            </a>
          </div>
          <div id="contact" className="flex flex-col gap-2 rounded-card border border-line p-6">
            <strong className="text-[18px] font-extrabold">Press and partnerships</strong>
            <p className="text-[15px] leading-[1.55] text-ink-3">For interviews, screenshots, or a partnership with your institution.</p>
            <a href="mailto:hello@sophia-culture.com" className="text-[15px] font-bold text-blue">
              hello@sophia-culture.com
            </a>
          </div>
        </div>
        <div className="flex flex-wrap items-center justify-between gap-6 rounded-card bg-ink px-8 py-7 text-white">
          <strong className="text-[20px] font-extrabold">Try Sophia today.</strong>
          <StoreButtons size="compact" />
        </div>
      </main>
    </>
  );
}
