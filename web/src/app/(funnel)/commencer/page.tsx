import type { Metadata } from "next";
import { coursesOf, feedFor, stats, subjects, toCard } from "@/lib/catalog";
import { plans } from "@/lib/config";
import { Funnel } from "@/components/Funnel";

export const metadata: Metadata = {
  title: "Commencer · Sophia",
  description: "Quelques questions pour composer votre programme, puis trois jours gratuits pour tout lire.",
};

export default function StartPage() {
  const subjectOptions = subjects.map((s) => ({
    slug: s.slug,
    label: s.label,
    image: coursesOf(s.subcategories.flatMap((g) => g.courses))[0].image,
  }));
  const picks = Object.fromEntries(subjects.map((s) => [s.slug, feedFor(s.slug, 3).map(toCard)]));
  const planList = Object.values(plans).map((p) => ({ ...p, checkoutUrl: p.checkoutUrl ?? null }));
  return <Funnel subjects={subjectOptions} picks={picks} plans={planList} stats={stats} />;
}
