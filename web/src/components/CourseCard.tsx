import Image from "next/image";
import Link from "next/link";
import { coursePath, SUBJECT_LABEL } from "@/lib/catalog/slugs";
import type { CourseSummary, Creator } from "@/lib/catalog/types";

const TILE_TONES = ["bg-tint text-navy", "bg-cream border border-cream-2 text-navy", "bg-green-bg text-green", "bg-amber-bg text-amber"];

/** Une carte de cours : couverture (ou tuile de couleur), matière et durée, titre-question, auteur. */
export function CourseCard({ course, creator, index = 0, priority = false }: { course: CourseSummary; creator?: Creator | null; index?: number; priority?: boolean }) {
  const tone = TILE_TONES[index % TILE_TONES.length];
  return (
    <Link href={coursePath(course)} className="group flex flex-col gap-3">
      {course.coverUrl ? (
        <Image
          src={course.coverUrl}
          alt=""
          width={600}
          height={450}
          priority={priority}
          className="aspect-[4/3] w-full rounded-[18px] bg-tint object-cover"
        />
      ) : (
        <span className={`flex aspect-[4/3] w-full items-end rounded-[18px] p-[18px] ${tone}`}>
          <span className="text-[22px] font-extrabold leading-tight">{course.subtitle ?? SUBJECT_LABEL[course.subject]}</span>
        </span>
      )}
      <span className="text-[12px] font-bold uppercase tracking-[.6px] text-blue">
        {SUBJECT_LABEL[course.subject]} · {course.minutes} min
      </span>
      <strong className="text-[17px] font-bold leading-[1.3] text-ink group-hover:text-navy">{course.title}</strong>
      {(creator?.name || course.subtitle) && (
        <span className="text-[13px] text-ink-3">{[course.subtitle, creator?.name].filter(Boolean).join(" · ")}</span>
      )}
    </Link>
  );
}
