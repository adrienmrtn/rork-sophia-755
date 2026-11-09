import Image from "next/image";

/** Une illustration « affiche » du Studio (web/public/art/studio_*.webp), dans une carte crème. */
export type ArtName = "studio_desk" | "studio_identity" | "studio_credentials" | "studio_agreement" | "studio_guide" | "studio_review" | "studio_production" | "studio_stats" | "studio_empty" | "studio_photo" | "poster_ecrire" | "poster_langues" | "poster_quiz" | "poster_premium";

export function Art({ name, size = 220, className = "", priority = false }: { name: ArtName; size?: number; className?: string; priority?: boolean }) {
  return <Image src={`/art/${name}.webp`} alt="" width={size} height={size} priority={priority} className={`aspect-square shrink-0 rounded-[22px] object-cover ${className}`} />;
}

/** Un panneau d'accompagnement : l'illustration, un titre court, une ou deux phrases. */
export function ArtPanel({ name, title, children, tone = "cream", size = 200 }: { name: ArtName; title: string; children?: React.ReactNode; tone?: "cream" | "tint" | "white"; size?: number }) {
  const bg = tone === "cream" ? "border-cream-2 bg-cream" : tone === "tint" ? "border-tint bg-tint" : "border-line bg-white";
  return (
    <aside className={`flex flex-col gap-4 rounded-card border p-5 ${bg}`}>
      <Art name={name} size={size} className="w-full" />
      <div className="flex flex-col gap-1.5">
        <strong className="text-[16px] font-extrabold tracking-[-0.2px] text-ink">{title}</strong>
        {children && <div className="text-[14px] leading-[1.55] text-ink-2">{children}</div>}
      </div>
    </aside>
  );
}
