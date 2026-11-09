import Image from "next/image";
import { renderInline } from "@/lib/catalog/inline";
import type { Block, Credit } from "@/lib/catalog/types";
import { STORAGE_PUBLIC } from "@/lib/env";

/** Le rendu d'un bloc de cours, partagé par la page publique, l'aperçu de l'éditeur et la relecture. */

export function imageUrl(block: { asset?: string; image_url?: string }): string | null {
  if (block.image_url) return block.image_url;
  if (block.asset) return `${STORAGE_PUBLIC}/course-images/${block.asset}.jpg`;
  return null;
}

export function creditLine(credit?: Credit | null): string | null {
  if (!credit) return null;
  return [credit.author, credit.title, credit.license, credit.source].filter(Boolean).join(" · ") || null;
}

export function BlockView({ block, credits = {}, plain = false }: { block: Block; credits?: Record<string, Credit>; plain?: boolean }) {
  const glossaryHref = () => "#glossary";
  switch (block.type) {
    case "paragraph":
      return <p>{renderInline(block.text, glossaryHref)}</p>;
    case "heading":
      return <h3 className="mt-2 text-[22px] font-extrabold tracking-[-0.4px]">{renderInline(block.text)}</h3>;
    case "funFact":
      return (
        <aside className="my-2 rounded-[18px] border border-amber-bg bg-amber-bg/60 p-5">
          <strong className="mb-1 block text-[12px] font-bold uppercase tracking-[1px] text-amber">Did you know?</strong>
          <p className="!text-[16px]">{renderInline(block.text, glossaryHref)}</p>
        </aside>
      );
    case "takeaway":
      return (
        <aside className="my-2 rounded-[18px] bg-tint p-5">
          <strong className="mb-1 block text-[12px] font-bold uppercase tracking-[1px] text-navy">Key takeaway</strong>
          <p className="!text-[16px] font-semibold">{renderInline(block.text, glossaryHref)}</p>
        </aside>
      );
    case "quote":
      return (
        <blockquote className="my-2 border-l-4 border-navy pl-5 text-[19px] italic leading-[1.6] text-ink-2">
          {renderInline(block.text)}
          {block.attribution && <footer className="mt-1 text-[14px] not-italic text-ink-3">{block.attribution}</footer>}
        </blockquote>
      );
    case "timeline":
      return (
        <ol className="my-2 flex flex-col gap-3 border-l-2 border-line pl-5">
          {(block.events ?? []).map((e, i) => (
            <li key={i} className="flex flex-col gap-0.5">
              <span className="text-[13px] font-bold uppercase tracking-[.6px] text-blue">{e.date}</span>
              <strong className="text-[16px] font-bold">{e.title}</strong>
              {e.detail && <span className="text-[15px] text-ink-3">{renderInline(e.detail)}</span>}
            </li>
          ))}
        </ol>
      );
    case "image": {
      const src = imageUrl(block);
      if (!src) return null;
      const credit = creditLine(block.credit ?? (block.asset ? credits[block.asset] : null));
      return (
        <figure className="my-2 flex flex-col gap-2">
          {plain ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={src} alt={block.caption ?? ""} className="w-full rounded-[18px] object-cover" />
          ) : (
            <Image src={src} alt={block.caption ?? ""} width={1200} height={800} className="w-full rounded-[18px] object-cover" />
          )}
          {(block.caption || credit) && (
            <figcaption className="text-[13px] text-ink-3">
              {block.caption}
              {block.caption && credit ? " · " : ""}
              {credit && <span className="text-muted">{credit}</span>}
            </figcaption>
          )}
        </figure>
      );
    }
    default:
      return null;
  }
}
