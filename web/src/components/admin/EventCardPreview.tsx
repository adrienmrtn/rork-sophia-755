import Image from "next/image";
import { localized, symbolLabel, type Campaign } from "@/lib/studio/campaigns";

export type PreviewCover = { id: string; title: string; coverUrl: string | null };

/** La carte de l'événement telle que le fil « Pour toi » des apps la dessine (en anglais, avec les
 *  textes et l'image enregistrés) : bleu nuit, image en tête, symbole, dates, titre, résumé, trois
 *  couvertures, barre du défi (propre à chaque lecteur, donc à zéro ici) et barre de l'objectif
 *  commun. Une maquette fidèle, pas un rendu des apps. */
export function EventCardPreview({ campaign, covers }: { campaign: Campaign; covers: PreviewCover[] }) {
  const title = localized(campaign.title, "en") || "Event title";
  const tagline = localized(campaign.tagline, "en");
  const end = campaign.ends_at ? new Date(campaign.ends_at).toLocaleDateString("en-GB", { day: "numeric", month: "short" }) : "";
  const goal = campaign.goal_target;
  const pct = goal ? Math.min(100, Math.round((campaign.goal_count / goal) * 100)) : 0;
  return (
    <div className="w-full max-w-[360px] rounded-[22px] bg-ink p-5 text-white shadow-[0_12px_32px_rgba(10,20,40,0.28)]">
      <div className="flex flex-col gap-3.5">
        {campaign.image_url && <Image src={campaign.image_url} alt="" width={640} height={360} unoptimized className="h-[140px] w-full rounded-[14px] bg-white/10 object-cover" />}
        <div className="flex items-center justify-between gap-2">
          <span className="rounded-full bg-[#F2B134]/15 px-2.5 py-1 text-[12px] font-bold text-[#F2B134]">{symbolLabel(campaign.symbol)}</span>
          {end && <span className="rounded-full bg-white/15 px-2.5 py-1 text-[12px] font-semibold">Event · until {end}</span>}
        </div>
        <strong className="text-[26px] font-extrabold leading-[1.1]">{title}</strong>
        <p className="text-[14px] leading-[1.45] text-white/85">
          {tagline} {campaign.course_ids.length} {campaign.course_ids.length === 1 ? "course" : "courses"} to read.
        </p>
        <div className="flex items-center gap-2.5">
          {covers.slice(0, 3).map((c) =>
            c.coverUrl ? (
              <Image key={c.id} src={c.coverUrl} alt="" width={64} height={64} unoptimized className="h-16 w-16 rounded-[14px] border-2 border-white/60 object-cover" />
            ) : (
              <span key={c.id} className="flex h-16 w-16 items-center justify-center rounded-[14px] border-2 border-white/60 bg-white/10 text-[20px] font-extrabold">
                {c.title.charAt(0)}
              </span>
            ),
          )}
        </div>
        <div className="flex items-center gap-3">
          <span className="h-1.5 flex-1 overflow-hidden rounded-full bg-white/20">
            <span className="block h-full w-0 rounded-full bg-[#F2B134]" />
          </span>
          <span className="text-[12px] font-semibold">Challenge: 0 of {campaign.challenge_target} courses</span>
        </div>
        {goal && (
          <div className="flex items-center gap-3">
            <span className="h-1.5 flex-1 overflow-hidden rounded-full bg-white/20">
              <span className="block h-full rounded-full bg-white" style={{ width: `${pct}%` }} />
            </span>
            <span className="text-[12px] font-semibold text-white/90">
              Together: {campaign.goal_count.toLocaleString("en-GB")} of {goal.toLocaleString("en-GB")} courses read
            </span>
          </div>
        )}
        <span className="text-[14px] font-bold text-[#F2B134]">See the collection ›</span>
      </div>
    </div>
  );
}
