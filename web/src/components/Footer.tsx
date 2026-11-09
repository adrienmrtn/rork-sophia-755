import Image from "next/image";
import { links } from "@/lib/site";
import { Logo, Phi, Spark, Starburst, StoreBadges } from "./ui";

export function FinalCta() {
  return (
    <section className="relative overflow-hidden border-b-[3px] border-ink bg-violet py-24 text-center sm:py-32">
      <div className="grid-paper absolute inset-0 opacity-50" aria-hidden />
      <Starburst className="absolute left-[6%] top-12 h-20 w-20 animate-spin-slow sm:h-28 sm:w-28" fill="var(--color-saffron)" />
      <Spark className="absolute bottom-10 right-[8%] h-16 w-16 animate-float sm:h-24 sm:w-24" fill="var(--color-pink)" />
      <Phi className="absolute -bottom-6 left-[12%] hidden h-28 w-24 rotate-12 md:block" fill="var(--color-mint)" />

      <div className="relative mx-auto max-w-3xl px-4 sm:px-6">
        <Image
          src="/img/brand/app_icon.webp"
          alt=""
          width={96}
          height={96}
          className="brutal mx-auto h-20 w-20 rounded-[22px] sm:h-24 sm:w-24"
        />
        <h2 className="mt-8 font-display text-5xl font-extrabold leading-[1.02] tracking-tight text-white sm:text-7xl">
          Ta version la plus cultivée commence ici.
        </h2>
        <p className="mx-auto mt-6 max-w-xl text-lg text-white/90 sm:text-xl">
          Télécharge Sophia, lis ton premier cours en 10 minutes, et vois ta culture générale grandir
          semaine après semaine.
        </p>
        <StoreBadges className="mt-10 justify-center" />
      </div>
    </section>
  );
}

export function Footer() {
  return (
    <footer className="bg-ink py-14 text-cream">
      <div className="mx-auto flex max-w-6xl flex-col gap-10 px-4 sm:px-6 md:flex-row md:items-start md:justify-between">
        <div className="max-w-sm">
          <Logo white />
          <p className="mt-4 text-cream/70">Moins de scroll, plus de culture. 10 minutes par jour pour comprendre le monde.</p>
        </div>
        <div className="grid grid-cols-2 gap-10 text-sm">
          <div>
            <p className="font-display font-bold text-saffron">L&apos;app</p>
            <ul className="mt-3 space-y-2 text-cream/80">
              <li><a href="#cours" className="hover:text-cream">Les cours</a></li>
              <li><a href="#methode" className="hover:text-cream">La méthode</a></li>
              <li><a href="#profs" className="hover:text-cream">Les profs</a></li>
              <li><a href="#faq" className="hover:text-cream">FAQ</a></li>
            </ul>
          </div>
          <div>
            <p className="font-display font-bold text-saffron">Sophia</p>
            <ul className="mt-3 space-y-2 text-cream/80">
              <li><a href={links.writeForUs} className="hover:text-cream">Écrire pour Sophia</a></li>
              <li><a href={links.support} className="hover:text-cream">Support</a></li>
              <li><a href={links.support} className="hover:text-cream">Confidentialité</a></li>
              <li><a href={links.appStore} className="hover:text-cream">Télécharger</a></li>
            </ul>
          </div>
        </div>
      </div>
      <p className="mx-auto mt-12 max-w-6xl px-4 text-xs text-cream/50 sm:px-6">
        © {new Date().getFullYear()} Sophia. Tous droits réservés.
      </p>
    </footer>
  );
}
