import type { Metadata } from "next";
import { AuthorCard } from "@/components/AuthorCard";
import { SiteHeader } from "@/components/SiteChrome";
import { Eyebrow, container } from "@/components/ui";
import { catalog } from "@/lib/catalog/source";
import { t } from "@/lib/copy/en";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "The authors", description: "Doctors, researchers and professors who write for Sophia." };

export default async function AuthorsPage() {
  // Tous les auteurs approuvés, y compris ceux dont le premier cours s'écrit encore (page publique dès l'approbation).
  const creators = (await catalog.listCreators("en")).sort((a, b) => b.courseIds.length - a.courseIds.length || a.name.localeCompare(b.name));
  return (
    <>
      <SiteHeader />
      <main className={`${container} flex flex-col gap-10 pt-12 pb-24`}>
        <div className="flex max-w-[720px] flex-col gap-2.5">
          <Eyebrow>{t.author.breadcrumb}</Eyebrow>
          <h1 className="text-[44px] font-extrabold leading-[1.08] tracking-[-1.2px]">{t.author.listTitle}</h1>
          <p className="text-[17px] leading-[1.5] text-ink-3">{t.author.listLead}</p>
        </div>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {creators.map((c) => (
            <AuthorCard key={c.slug} creator={c} />
          ))}
        </div>
      </main>
    </>
  );
}
