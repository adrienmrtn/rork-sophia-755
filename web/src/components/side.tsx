import Image from "next/image";
import QRCode from "qrcode";
import { links } from "@/lib/config";
import { Avatar } from "./ui";
import { FollowButton } from "./interactive";
import { IconVerified } from "./icons";

/** Encart « Téléchargez l'app » avec un QR code vers le lien de téléchargement. */
export async function AppCard() {
  const svg = await QRCode.toString(links.download, { type: "svg", margin: 0, color: { dark: "#16263d", light: "#00000000" } });
  return (
    <div className="rounded-[22px] bg-navy-deep p-5 text-white">
      <div className="flex items-center gap-3">
        <Image src="/img/brand/app_icon.webp" alt="" width={44} height={44} className="h-11 w-11 rounded-xl" />
        <div>
          <p className="font-extrabold">Sophia sur votre téléphone</p>
          <p className="text-[13px] text-white/70">iPhone et Android</p>
        </div>
      </div>
      <div className="mt-4 flex items-center gap-4">
        <div className="h-24 w-24 shrink-0 rounded-xl bg-paper p-2" dangerouslySetInnerHTML={{ __html: svg }} aria-label="QR code de téléchargement" role="img" />
        <p className="font-serif text-[15px] leading-snug text-white/85">Scannez pour télécharger, ou ouvrez le lien sur votre téléphone.</p>
      </div>
      <a href={links.download} target="_blank" rel="noopener" className="mt-4 flex h-10 items-center justify-center rounded-xl bg-saffron text-[14px] font-extrabold text-ink">
        taap.it/sophia
      </a>
    </div>
  );
}

type A = { slug: string; name: string; title: string; photo: string | null; courses: string[] };

export function AuthorsToFollow({ authors }: { authors: A[] }) {
  return (
    <div>
      <p className="text-[15px] font-extrabold">Auteurs à suivre</p>
      <ul className="mt-3 space-y-3.5">
        {authors.map((a) => (
          <li key={a.slug} className="relative flex items-center gap-3">
            <Avatar author={a} size={40} className="!ring-0" />
            <div className="min-w-0 flex-1">
              <a href={`/auteurs/${a.slug}`} className="flex items-center gap-1 truncate text-[14px] font-bold after:absolute after:inset-0 hover:underline">
                <span className="truncate">{a.name}</span> <IconVerified className="h-3.5 w-3.5 shrink-0 text-sky" />
              </a>
              <p className="truncate text-[12.5px] text-ink-2">{a.courses.length} cours · {a.title}</p>
            </div>
            <FollowButton slug={a.slug} size="sm" />
          </li>
        ))}
      </ul>
      <a href="/auteurs" className="mt-4 inline-block text-[14px] font-bold text-navy hover:underline">
        Voir tous les auteurs
      </a>
    </div>
  );
}

type Col = { slug: string; title: string; image: string; courses: string[] };

export function CollectionsMini({ items }: { items: Col[] }) {
  return (
    <div>
      <p className="text-[15px] font-extrabold">Collections</p>
      <ul className="mt-3 space-y-3">
        {items.map((c) => (
          <li key={c.slug} className="group relative flex items-center gap-3">
            <div className="relative h-12 w-16 shrink-0 overflow-hidden rounded-lg">
              <Image src={c.image} alt="" fill sizes="64px" className="object-cover" />
            </div>
            <div className="min-w-0">
              <a href={`/collections/${c.slug}`} className="line-clamp-2 text-[14px] font-bold leading-snug after:absolute after:inset-0 group-hover:text-navy">
                {c.title}
              </a>
              <p className="text-[12.5px] text-ink-3">{c.courses.length} cours</p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
