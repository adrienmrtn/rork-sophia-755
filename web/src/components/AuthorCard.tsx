import Image from "next/image";
import Link from "next/link";
import { authorPath } from "@/lib/catalog/slugs";
import type { Creator } from "@/lib/catalog/types";
import { Initials } from "./ui";

export function AuthorAvatar({ creator, size = 56, className = "" }: { creator: Pick<Creator, "name" | "photoUrl">; size?: number; className?: string }) {
  if (creator.photoUrl) {
    return <Image src={creator.photoUrl} alt="" width={size} height={size} className={`shrink-0 rounded-full object-cover ${className}`} style={{ width: size, height: size }} />;
  }
  return <Initials name={creator.name} size={size} className={className} />;
}

/** Une carte compacte d'auteur : portrait, nom, titre court. */
export function AuthorCard({ creator }: { creator: Creator }) {
  return (
    <Link href={authorPath(creator.slug)} className="flex items-center gap-3.5 rounded-[18px] border border-line bg-white p-4 hover:border-line-2">
      <AuthorAvatar creator={creator} size={56} />
      <span className="flex min-w-0 flex-col gap-0.5">
        <strong className="text-[15px] font-bold text-ink">{creator.name}</strong>
        {creator.title && <span className="line-clamp-2 text-[13px] leading-[1.35] text-ink-3">{creator.title}</span>}
      </span>
    </Link>
  );
}
