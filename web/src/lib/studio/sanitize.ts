import { SUBJECTS, type Block, type GlossaryEntry, type Section, type Source } from "@/lib/catalog/types";
import { BLOCK_TYPES, CLASSIFICATIONS, type DraftCourse, type Hero } from "@/lib/studio/course-format";

/** Ce que le navigateur envoie à l'enregistrement d'un cours (Studio ou édition admin du
 *  catalogue) : seuls les champs du format passent, bornés. */

function str(v: unknown, max = 5000): string {
  return typeof v === "string" ? v.slice(0, max) : "";
}
function opt(v: unknown, max = 400): string | undefined {
  const s = str(v, max);
  return s ? s : undefined;
}

/** Nettoie ce que le navigateur envoie : seuls les champs du format passent, bornés. */
export async function sanitizeCourse(raw: unknown): Promise<DraftCourse> {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const heroRaw = (r.hero && typeof r.hero === "object" ? r.hero : {}) as Record<string, unknown>;
  const creditRaw = (heroRaw.credit && typeof heroRaw.credit === "object" ? heroRaw.credit : null) as Record<string, unknown> | null;
  const hero: Hero = {
    ...(opt(heroRaw.image, 120) ? { image: opt(heroRaw.image, 120) } : {}),
    ...(opt(heroRaw.image_url, 1000) ? { image_url: opt(heroRaw.image_url, 1000) } : {}),
    ratio: opt(heroRaw.ratio, 10) ?? "16:9",
    ...(opt(heroRaw.hook, 200) ? { hook: opt(heroRaw.hook, 200) } : {}),
    ...(creditRaw ? { credit: { title: opt(creditRaw.title, 300), author: opt(creditRaw.author, 300), license: opt(creditRaw.license, 120), source: opt(creditRaw.source, 300) } } : {}),
    ...(Array.isArray(heroRaw.candidates) ? { candidates: heroRaw.candidates.slice(0, 12).map((c: unknown) => ({ url: str((c as Record<string, unknown>)?.url, 1000) })).filter((c: { url: string }) => /^(https:\/\/|\/)/.test(c.url)) } : {}),
    ...(typeof heroRaw.generations === "number" ? { generations: Math.max(0, Math.min(10, Math.round(heroRaw.generations))) } : {}),
    ...(opt(heroRaw.prompt, 2000) ? { prompt: opt(heroRaw.prompt, 2000) } : {}),
  };
  const sections: Section[] = (Array.isArray(r.sections) ? r.sections : []).slice(0, 12).map((sec: unknown, i: number) => {
    const s = (sec && typeof sec === "object" ? sec : {}) as Record<string, unknown>;
    const blocks: Block[] = (Array.isArray(s.blocks) ? s.blocks : []).slice(0, 60).flatMap((bl: unknown): Block[] => {
      const b = (bl && typeof bl === "object" ? bl : {}) as Record<string, unknown>;
      const type = String(b.type ?? "");
      if (!(BLOCK_TYPES as readonly string[]).includes(type)) return [];
      switch (type) {
        case "image": {
          const credit = (b.credit && typeof b.credit === "object" ? b.credit : null) as Record<string, unknown> | null;
          return [
            {
              type: "image",
              ...(opt(b.asset, 120) ? { asset: opt(b.asset, 120) } : {}),
              ...(opt(b.image_url, 1000) ? { image_url: opt(b.image_url, 1000) } : {}),
              ...(opt(b.ratio, 10) ? { ratio: opt(b.ratio, 10) } : {}),
              caption: str(b.caption, 400),
              ...(credit ? { credit: { title: opt(credit.title, 300), author: opt(credit.author, 300), license: opt(credit.license, 120), source: opt(credit.source, 300) } } : {}),
            },
          ];
        }
        case "timeline":
          return [
            {
              type: "timeline",
              events: (Array.isArray(b.events) ? b.events : []).slice(0, 20).map((ev: unknown) => {
                const e = (ev && typeof ev === "object" ? ev : {}) as Record<string, unknown>;
                return { date: str(e.date, 40), title: str(e.title, 160), ...(opt(e.detail, 400) ? { detail: opt(e.detail, 400) } : {}) };
              }),
            },
          ];
        case "quote":
          return [{ type: "quote", text: str(b.text, 2000), attribution: str(b.attribution, 160) }];
        default:
          return [{ type: type as "paragraph" | "heading" | "funFact" | "takeaway", text: str(b.text, 5000) }];
      }
    });
    return { ...(opt(s.id, 200) ? { id: opt(s.id, 200) } : {}), title: str(s.title, 120), free: i === 0, blocks };
  });
  const sources: Source[] = (Array.isArray(r.sources) ? r.sources : []).slice(0, 40).map((so: unknown) => {
    const x = (so && typeof so === "object" ? so : {}) as Record<string, unknown>;
    return { text: str(x.text, 400), ...(opt(x.url, 1000) ? { url: opt(x.url, 1000) } : {}) };
  });
  const glossary: GlossaryEntry[] = (Array.isArray(r.glossary) ? r.glossary : []).slice(0, 60).map((g: unknown) => {
    const x = (g && typeof g === "object" ? g : {}) as Record<string, unknown>;
    const cls = String(x.classification ?? "concept");
    return { term: str(x.term, 120), classification: (CLASSIFICATIONS as readonly string[]).includes(cls) ? cls : "concept", explanation: str(x.explanation, 600) };
  });
  const subject = str(r.subject, 40);
  return {
    title: str(r.title, 160),
    subtitle: opt(r.subtitle, 80) ?? null,
    subject: (SUBJECTS as readonly string[]).includes(subject) ? subject : null,
    subcategory: opt(r.subcategory, 80) ?? null,
    description: str(r.description, 600),
    hero,
    sections,
    sources,
    glossary,
  };
}
