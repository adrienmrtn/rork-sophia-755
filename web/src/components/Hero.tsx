import Image from "next/image";
import { site, links } from "@/lib/site";
import { Button, Flower, Spark, Starburst, StoreBadges } from "./ui";
import { RichText } from "./RichText";

function PhoneFrame({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`brutal-lg relative w-[230px] rounded-[38px] bg-ink p-[7px] sm:w-[260px] ${className}`}>
      <div className="relative h-[470px] overflow-hidden rounded-[31px] bg-paper sm:h-[530px]">
        <div className="absolute left-1/2 top-2 z-20 h-6 w-24 -translate-x-1/2 rounded-full bg-ink" />
        {children}
      </div>
    </div>
  );
}

function CoursePhone() {
  const c = site.phoneCourse;
  return (
    <PhoneFrame>
      <div className="relative h-[46%]">
        <Image src={c.image} alt="" fill sizes="260px" className="object-cover" priority />
        <div className="absolute inset-0 bg-gradient-to-t from-ink/85 via-ink/20 to-transparent" />
        <div className="absolute bottom-3 left-3 right-3 text-cream">
          <span className="mb-2 inline-block rounded-full border-2 border-ink bg-sky px-2 py-0.5 text-[10px] font-bold text-ink">
            📚 Littérature · {c.subtitle}
          </span>
          <p className="font-display text-[15px] font-bold leading-tight">{c.title}</p>
        </div>
      </div>
      <div className="space-y-2.5 px-4 pt-3 text-[11.5px] leading-relaxed text-ink-soft">
        <p className="text-[10px] font-bold uppercase tracking-widest text-violet">Introduction · 10 min</p>
        {c.paragraphs.map((p, i) => (
          <p key={i} className={i === 1 ? "line-clamp-4" : ""}>
            <RichText text={p} />
          </p>
        ))}
      </div>
      <div className="absolute inset-x-0 bottom-0 flex items-center gap-2 border-t-2 border-ink bg-paper px-4 py-3">
        <div className="h-2 flex-1 overflow-hidden rounded-full border-2 border-ink bg-cream">
          <div className="h-full w-[38%] bg-violet" />
        </div>
        <span className="text-[10px] font-bold">3/8</span>
      </div>
    </PhoneFrame>
  );
}

function QuizPhone() {
  const q = site.quiz[1];
  return (
    <PhoneFrame>
      <div className="flex h-full flex-col bg-saffron-soft px-4 pb-4 pt-12">
        <div className="mb-3 flex items-center justify-between text-[10px] font-bold">
          <span className="rounded-full border-2 border-ink bg-paper px-2 py-0.5">Quiz · 2/10</span>
          <span className="rounded-full border-2 border-ink bg-pink px-2 py-0.5">🔥 12 jours</span>
        </div>
        <p className="font-display text-[17px] font-bold leading-snug">{q.question}</p>
        <div className="mt-4 space-y-2">
          {q.options.map((o, i) => (
            <div
              key={o}
              className={`flex items-center gap-2 rounded-2xl border-2 border-ink px-3 py-2.5 text-[11.5px] font-semibold ${
                i === q.correctIndex ? "bg-mint shadow-[3px_3px_0_0_var(--color-ink)]" : "bg-paper"
              }`}
            >
              <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full border-2 border-ink bg-cream text-[9px]">
                {i === q.correctIndex ? "✓" : String.fromCharCode(65 + i)}
              </span>
              <span className="line-clamp-2">{o}</span>
            </div>
          ))}
        </div>
        <div className="mt-auto rounded-2xl border-2 border-ink bg-paper p-3 text-[10.5px] leading-snug text-ink-soft">
          <span className="font-bold text-ink">Bien joué ! </span>
          <span className="line-clamp-3">{q.explanation}</span>
        </div>
      </div>
    </PhoneFrame>
  );
}

export function Hero() {
  return (
    <section className="relative overflow-hidden border-b-[3px] border-ink bg-violet">
      <div className="grid-paper absolute inset-0 opacity-60" aria-hidden />
      <Flower className="absolute -left-10 top-10 hidden h-28 w-28 animate-spin-slow lg:block" />
      <Spark className="absolute right-[4%] top-8 h-16 w-16 animate-float sm:h-20 sm:w-20" fill="var(--color-saffron)" />
      <Starburst className="absolute -bottom-10 left-[38%] hidden h-28 w-28 animate-spin-slow md:block" fill="var(--color-mint)" />

      <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-4 pb-20 pt-14 sm:px-6 lg:grid-cols-[1.1fr_1fr] lg:pb-28 lg:pt-20">
        <div>
          <span className="brutal-sm mb-6 inline-flex items-center gap-2 rounded-full bg-paper px-3 py-1.5 text-sm font-bold">
            <span className="relative flex h-2.5 w-2.5">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-pink opacity-75" />
              <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-pink" />
            </span>
            Ton cours du jour t&apos;attend
          </span>

          <h1 className="font-display text-[42px] font-extrabold leading-[1] tracking-tight text-white sm:text-6xl lg:text-[62px] xl:text-[68px]">
            <span className="whitespace-nowrap">Moins de scroll,</span>
            <br />
            <span className="whitespace-nowrap">plus de</span>{" "}
            <span className="brutal relative inline-block -rotate-2 rounded-2xl bg-saffron px-3 pb-1 text-ink">
              culture.
            </span>
          </h1>

          <p className="mt-7 max-w-xl text-lg leading-relaxed text-white/90 sm:text-xl">
            Des cours de 10 minutes écrits par des profs, un quiz pour que ça reste, et un bloqueur
            d&apos;apps pour tenir le rythme. Histoire, sciences, littérature, art, mythologie et
            géopolitique.
          </p>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <Button href={links.appStore} tone="pink" size="lg">
              Je me cultive
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12h14M13 6l6 6-6 6" />
              </svg>
            </Button>
          </div>
          <StoreBadges className="mt-5" />
        </div>

        <div className="relative mx-auto flex h-[520px] w-full max-w-[520px] items-center justify-center sm:h-[600px]">
          <div className="absolute left-0 top-6 z-10 -rotate-6 transition-transform duration-500 hover:-rotate-3 sm:left-2">
            <CoursePhone />
          </div>
          <div className="absolute right-0 top-20 z-20 rotate-[5deg] transition-transform duration-500 hover:rotate-2 sm:right-2">
            <QuizPhone />
          </div>
          <div className="brutal absolute -bottom-2 left-6 z-30 rotate-[-4deg] rounded-2xl bg-mint px-4 py-2 font-display text-sm font-bold sm:left-12">
            ✓ 10 minutes, c&apos;est fait
          </div>
        </div>
      </div>
    </section>
  );
}
