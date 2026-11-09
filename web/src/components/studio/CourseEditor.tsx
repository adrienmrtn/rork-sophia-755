"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState, useTransition } from "react";
import { BlockView } from "@/components/CourseBlocks";
import { renderInline, countWords } from "@/lib/catalog/inline";
import { SUBJECTS, type Block, type Credit, type Section } from "@/lib/catalog/types";
import { SUBJECT_LABEL } from "@/lib/catalog/slugs";
import { s } from "@/lib/copy/studio-en";
import { BLOCK_LABEL, BLOCK_TYPES, CLASSIFICATIONS, CLASSIFICATION_LABEL, citedTerms, courseWords, emptyBlock, validateCourse, type BlockType, type DraftCourse, type Finding } from "@/lib/studio/course-format";
import { saveDraft, submitDraft } from "@/app/studio/courses/[id]/actions";
import type { CommonsImage } from "@/app/api/commons/search/route";

/** L'éditeur de cours : le plan à gauche, le contenu par blocs au centre, les vérifications,
 *  les images et l'aperçu à droite. Enregistrement automatique, envoi en relecture. */

type Props = {
  draftId: string;
  initial: DraftCourse;
  status: "draft" | "changes_requested";
  reviewComment: string | null;
  updatedAt: string;
  originLang: string;
  blockers: string[];
  onboardingHref: string | null;
};

type SaveState = { kind: "saved"; at: string } | { kind: "dirty" } | { kind: "saving" } | { kind: "error"; message: string };
type Tab = "checks" | "images" | "preview";
type ImageTarget = { kind: "cover" } | { kind: "block"; s: number; b: number } | { kind: "new"; s: number };

const input = "h-11 w-full rounded-xl border border-line bg-white px-3.5 text-[15px] text-ink outline-none focus:border-blue";
const textarea = "w-full resize-none rounded-xl border border-line bg-white px-3.5 py-2.5 text-[15px] leading-[1.55] text-ink outline-none focus:border-blue";
const small = "h-9 w-full rounded-lg border border-line bg-white px-3 text-[13px] text-ink outline-none focus:border-blue";
const iconBtn = "inline-flex h-8 w-8 items-center justify-center rounded-lg text-ink-3 hover:bg-paper hover:text-navy disabled:opacity-30 disabled:hover:bg-transparent";
const label = "flex flex-col gap-1.5 text-[13px] font-bold text-ink-2";

function rowsFor(text: string, min = 2): number {
  const lines = text.split("\n").reduce((n, l) => n + Math.max(1, Math.ceil(l.length / 90)), 0);
  return Math.max(min, Math.min(18, lines + 1));
}

function timeOf(iso: string): string {
  return new Date(iso).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
}

function pathToId(path: string): string {
  let m = /^sections\[(\d+)\]\.blocks\[(\d+)\]/.exec(path);
  if (m) return `blk-${m[1]}-${m[2]}`;
  m = /^sections\[(\d+)\]/.exec(path);
  if (m) return `sec-${m[1]}`;
  if (path === "sections") return "sections";
  if (path.startsWith("sources")) return "sources";
  if (path.startsWith("glossary")) return "glossary";
  return "meta";
}

export function CourseEditor({ draftId, initial, status, reviewComment, updatedAt, originLang, blockers, onboardingHref }: Props) {
  const router = useRouter();
  const [course, setCourse] = useState<DraftCourse>(initial);
  const [save, setSave] = useState<SaveState>({ kind: "saved", at: updatedAt });
  const [tab, setTab] = useState<Tab>("checks");
  const [active, setActive] = useState(0);
  const [target, setTarget] = useState<ImageTarget | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [flash, setFlash] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const latest = useRef(course);
  const dirty = useRef(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const findings = useMemo(() => validateCourse(course), [course]);
  const errorCount = findings.filter((f) => f.severity === "error").length;
  const words = courseWords(course);
  const missingTerms = useMemo(() => {
    const have = new Set(course.glossary.map((g) => g.term.toLowerCase()));
    return citedTerms(course).filter((t) => !have.has(t.toLowerCase()));
  }, [course]);

  const flush = useCallback(async () => {
    if (!dirty.current) return;
    dirty.current = false;
    setSave({ kind: "saving" });
    const res = await saveDraft(draftId, latest.current);
    if (res.ok) setSave(dirty.current ? { kind: "dirty" } : { kind: "saved", at: res.updatedAt });
    else {
      dirty.current = true;
      setSave({ kind: "error", message: res.error });
    }
  }, [draftId]);

  const update = useCallback(
    (fn: (c: DraftCourse) => DraftCourse) => {
      setCourse((prev) => {
        const next = fn(prev);
        latest.current = next;
        return next;
      });
      dirty.current = true;
      setSave((st) => (st.kind === "saving" ? st : { kind: "dirty" }));
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(() => void flush(), 1500);
    },
    [flush],
  );

  useEffect(() => {
    const warn = (e: BeforeUnloadEvent) => {
      if (dirty.current) {
        e.preventDefault();
        void flush();
      }
    };
    const hidden = () => {
      if (document.visibilityState === "hidden") void flush();
    };
    window.addEventListener("beforeunload", warn);
    document.addEventListener("visibilitychange", hidden);
    return () => {
      window.removeEventListener("beforeunload", warn);
      document.removeEventListener("visibilitychange", hidden);
    };
  }, [flush]);

  function jumpTo(path: string) {
    const id = pathToId(path);
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "center" });
    setFlash(id);
    setTimeout(() => setFlash(null), 1600);
  }

  // ----- sections et blocs
  const setSection = (i: number, patch: Partial<Section>) => update((c) => ({ ...c, sections: c.sections.map((sec, k) => (k === i ? { ...sec, ...patch } : sec)) }));
  const addSection = () =>
    update((c) => {
      if (c.sections.length >= 12) return c;
      return { ...c, sections: [...c.sections, { title: "", free: false, blocks: [{ type: "paragraph", text: "" }] }] };
    });
  const removeSection = (i: number) => {
    const sec = course.sections[i];
    const hasText = sec.blocks.some((b) => ("text" in b && b.text.trim()) || b.type === "image" || b.type === "timeline");
    if (hasText && !window.confirm(`Delete section ${i + 1} "${sec.title || "untitled"}" and its content?`)) return;
    update((c) => ({ ...c, sections: c.sections.filter((_, k) => k !== i) }));
    setActive((a) => Math.max(0, Math.min(a, course.sections.length - 2)));
  };
  const moveSection = (i: number, dir: -1 | 1) =>
    update((c) => {
      const j = i + dir;
      if (j < 0 || j >= c.sections.length) return c;
      const arr = [...c.sections];
      [arr[i], arr[j]] = [arr[j], arr[i]];
      return { ...c, sections: arr };
    });
  const setBlock = (si: number, bi: number, patch: Partial<Block>) => update((c) => ({ ...c, sections: c.sections.map((sec, k) => (k === si ? { ...sec, blocks: sec.blocks.map((b, j) => (j === bi ? ({ ...b, ...patch } as Block) : b)) } : sec)) }));
  const addBlock = (si: number, type: BlockType) => {
    if (type === "image") {
      setTarget({ kind: "new", s: si });
      setTab("images");
      return;
    }
    update((c) => ({ ...c, sections: c.sections.map((sec, k) => (k === si ? { ...sec, blocks: [...sec.blocks, emptyBlock(type)] } : sec)) }));
  };
  const removeBlock = (si: number, bi: number) => update((c) => ({ ...c, sections: c.sections.map((sec, k) => (k === si ? { ...sec, blocks: sec.blocks.filter((_, j) => j !== bi) } : sec)) }));
  const moveBlock = (si: number, bi: number, dir: -1 | 1) =>
    update((c) => ({
      ...c,
      sections: c.sections.map((sec, k) => {
        if (k !== si) return sec;
        const j = bi + dir;
        if (j < 0 || j >= sec.blocks.length) return sec;
        const arr = [...sec.blocks];
        [arr[bi], arr[j]] = [arr[j], arr[bi]];
        return { ...sec, blocks: arr };
      }),
    }));

  // ----- images
  function placeImage(img: CommonsImage) {
    const credit: Credit = { title: img.title.replace(/\.[a-z0-9]+$/i, ""), author: img.author || undefined, license: img.license || undefined, source: "Wikimedia Commons" };
    const t = target ?? { kind: "new" as const, s: active };
    if (t.kind === "cover") update((c) => ({ ...c, hero: { ...c.hero, image_url: img.large, image: undefined, credit } }));
    else if (t.kind === "block") setBlock(t.s, t.b, { image_url: img.large, asset: undefined, credit } as Partial<Block>);
    else update((c) => ({ ...c, sections: c.sections.map((sec, k) => (k === t.s ? { ...sec, blocks: [...sec.blocks, { type: "image", image_url: img.large, caption: "", credit }] } : sec)) }));
    setTarget(null);
    setTab("checks");
    if (t.kind !== "cover") jumpTo(`sections[${t.s}]`);
    else jumpTo("hero");
  }

  // ----- envoi
  const canSubmit = errorCount === 0 && blockers.length === 0 && !pending && save.kind !== "saving";
  function submit() {
    setSubmitError(null);
    if (!window.confirm("Send this course to the Sophia team for review? You will not be able to edit it until they answer.")) return;
    startTransition(async () => {
      if (timer.current) clearTimeout(timer.current);
      dirty.current = true;
      const res = await submitDraft(draftId, latest.current);
      if (res.ok) router.push(`/studio/courses/${draftId}/status`);
      else setSubmitError(res.error);
    });
  }

  const flashClass = (id: string) => (flash === id ? "ring-2 ring-blue ring-offset-2" : "");

  return (
    <div className="flex min-h-full flex-1 flex-col bg-paper">
      {/* Barre */}
      <header className="sticky top-0 z-20 border-b border-line bg-white/95 backdrop-blur">
        <div className="mx-auto flex w-full max-w-[1480px] flex-wrap items-center gap-x-5 gap-y-2 px-5 py-2.5">
          <Link href="/studio/courses" className="text-[13px] font-bold text-blue">
            ← {s.courses.title}
          </Link>
          <span className="min-w-0 flex-1 truncate text-[15px] font-extrabold text-ink">{course.title || s.courses.untitled}</span>
          <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[12px] font-bold ${status === "changes_requested" ? "bg-red-bg text-red" : "bg-tint text-ink-2"}`}>{s.dashboard.statuses[status]}</span>
          <span className="text-[12px] text-muted tabular-nums">
            {words.toLocaleString("en")} words · {course.sections.length} sections
          </span>
          <span className={`text-[12px] font-semibold ${save.kind === "error" ? "text-red" : "text-muted"}`} aria-live="polite">
            {save.kind === "saved" ? `Saved · ${timeOf(save.at)}` : save.kind === "saving" ? "Saving…" : save.kind === "dirty" ? "Unsaved changes" : `Not saved: ${save.message}`}
          </span>
          <button type="button" onClick={submit} disabled={!canSubmit} title={blockers[0] ?? (errorCount ? `${errorCount} problems to fix first` : "")} className="inline-flex h-10 items-center rounded-xl bg-navy px-4 text-[14px] font-bold text-white hover:bg-ink disabled:cursor-not-allowed disabled:opacity-40">
            {pending ? "Sending…" : status === "changes_requested" ? "Send again" : "Send for review"}
          </button>
        </div>
      </header>

      <div className="mx-auto grid w-full max-w-[1480px] flex-1 grid-cols-1 gap-6 px-5 pt-6 pb-24 lg:grid-cols-[220px_minmax(0,1fr)_360px]">
        {/* Plan */}
        <aside className="lg:sticky lg:top-[68px] lg:self-start">
          <nav className="flex flex-col gap-1 rounded-card border border-line bg-white p-3">
            <span className="px-2 pb-1 text-[12px] font-bold uppercase tracking-[1px] text-muted">Outline</span>
            <button type="button" onClick={() => jumpTo("title")} className="rounded-lg px-2 py-1.5 text-left text-[13px] font-semibold text-ink-2 hover:bg-paper">
              Title and card
            </button>
            {course.sections.map((sec, i) => {
              const w = sec.blocks.reduce((n, b) => n + ("text" in b ? countWords(b.text) : 0), 0);
              return (
                <button key={i} type="button" onClick={() => { setActive(i); jumpTo(`sections[${i}]`); }} className={`flex items-center justify-between gap-2 rounded-lg px-2 py-1.5 text-left text-[13px] hover:bg-paper ${active === i ? "bg-tint font-bold text-navy" : "font-semibold text-ink-2"}`}>
                  <span className="truncate">
                    {i + 1}. {sec.title || "Untitled section"}
                  </span>
                  <span className="shrink-0 text-[11px] font-medium text-muted tabular-nums">{w}</span>
                </button>
              );
            })}
            <button type="button" onClick={addSection} disabled={course.sections.length >= 12} className="mt-1 rounded-lg px-2 py-1.5 text-left text-[13px] font-bold text-blue hover:bg-paper disabled:opacity-40">
              + Add a section
            </button>
            <div className="my-1 border-t border-line" />
            <button type="button" onClick={() => jumpTo("glossary")} className="rounded-lg px-2 py-1.5 text-left text-[13px] font-semibold text-ink-2 hover:bg-paper">
              Glossary ({course.glossary.length})
            </button>
            <button type="button" onClick={() => jumpTo("sources")} className="rounded-lg px-2 py-1.5 text-left text-[13px] font-semibold text-ink-2 hover:bg-paper">
              Sources ({course.sources.length})
            </button>
          </nav>
          <p className="mt-3 px-2 text-[12px] leading-[1.5] text-muted">
            Markup: <code>**bold**</code>, <code>*italic*</code>, <code>[[Term]]</code> links a glossary entry. No em dash.
          </p>
        </aside>

        {/* Contenu */}
        <div className="flex min-w-0 flex-col gap-5">
          {status === "changes_requested" && reviewComment && (
            <div className="flex flex-col gap-1.5 rounded-card border border-red-bg bg-red-bg/40 p-5">
              <strong className="text-[12px] font-bold uppercase tracking-[1px] text-red">The team asks</strong>
              <p className="whitespace-pre-wrap text-[15px] leading-[1.55] text-ink">{reviewComment}</p>
            </div>
          )}
          {submitError && (
            <p role="alert" className="rounded-xl bg-red-bg px-4 py-3 text-[14px] font-semibold text-red">
              {submitError}
            </p>
          )}

          {/* Métadonnées */}
          <section id="meta" className={`flex flex-col gap-4 rounded-card border border-line bg-white p-6 ${flashClass("meta")}`}>
            <div id="title" className="flex flex-col gap-1.5">
              <input value={course.title} onChange={(e) => update((c) => ({ ...c, title: e.target.value }))} placeholder="Course title" maxLength={160} className="w-full border-0 bg-transparent text-[30px] font-extrabold tracking-[-0.7px] text-ink outline-none placeholder:text-line-2" />
              <input value={course.subtitle ?? ""} onChange={(e) => update((c) => ({ ...c, subtitle: e.target.value || null }))} placeholder="Subtitle, a date or a place (optional)" maxLength={80} className="w-full border-0 bg-transparent text-[16px] font-semibold text-ink-3 outline-none placeholder:text-line-2" />
            </div>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <label className={label}>
                Subject
                <select value={course.subject ?? ""} onChange={(e) => update((c) => ({ ...c, subject: e.target.value || null }))} className={input}>
                  <option value="">Choose…</option>
                  {SUBJECTS.map((sub) => (
                    <option key={sub} value={sub}>
                      {SUBJECT_LABEL[sub]}
                    </option>
                  ))}
                </select>
              </label>
              <label className={label}>
                Subcategory (optional)
                <input value={course.subcategory ?? ""} onChange={(e) => update((c) => ({ ...c, subcategory: e.target.value || null }))} placeholder="Iconic works, Ancient Greece, Cosmology…" maxLength={80} className={input} />
              </label>
            </div>
            <label className={label}>
              <span className="flex items-center justify-between">
                Card hook <span className="font-medium text-muted tabular-nums">{course.description.length} / 600</span>
              </span>
              <textarea value={course.description} onChange={(e) => update((c) => ({ ...c, description: e.target.value }))} rows={3} maxLength={600} placeholder="Two or three sentences that make a reader open the course." className={textarea} />
            </label>
            <div id="hero" className={`flex flex-wrap items-start gap-4 rounded-2xl bg-paper p-4 ${flashClass("hero")}`}>
              {course.hero.image_url || course.hero.image ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={course.hero.image_url ?? `https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/${course.hero.image}.jpg`} alt="" className="h-28 w-44 shrink-0 rounded-xl object-cover" />
              ) : (
                <div className="flex h-28 w-44 shrink-0 items-center justify-center rounded-xl border border-dashed border-line-2 text-[12px] font-semibold text-muted">No cover</div>
              )}
              <div className="flex min-w-[220px] flex-1 flex-col gap-2">
                <strong className="text-[13px] font-bold text-ink-2">Cover image</strong>
                {course.hero.credit && (course.hero.credit.author || course.hero.credit.title) && (
                  <span className="text-[12px] text-ink-3">
                    {[course.hero.credit.title, course.hero.credit.author, course.hero.credit.license].filter(Boolean).join(" · ")}
                  </span>
                )}
                <input value={course.hero.hook ?? ""} onChange={(e) => update((c) => ({ ...c, hero: { ...c.hero, hook: e.target.value || undefined } }))} placeholder="One-line hook shown over the cover (optional, 200 characters)" maxLength={200} className={small} />
                <div className="flex flex-wrap gap-2">
                  <button type="button" onClick={() => { setTarget({ kind: "cover" }); setTab("images"); }} className="rounded-lg border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-navy hover:bg-tint">
                    {course.hero.image_url || course.hero.image ? "Replace" : "Choose from Commons"}
                  </button>
                  {(course.hero.image_url || course.hero.image) && (
                    <button type="button" onClick={() => update((c) => ({ ...c, hero: { ratio: c.hero.ratio, hook: c.hero.hook } }))} className="rounded-lg px-3 py-1.5 text-[13px] font-bold text-red hover:bg-red-bg">
                      Remove
                    </button>
                  )}
                </div>
              </div>
            </div>
          </section>

          {/* Sections */}
          <div id="sections" className={`flex flex-col gap-5 rounded-card ${flashClass("sections")}`}>
            {course.sections.map((sec, si) => (
              <section key={si} id={`sec-${si}`} onFocusCapture={() => setActive(si)} className={`flex flex-col gap-4 rounded-card border bg-white p-6 ${active === si ? "border-line-2" : "border-line"} ${flashClass(`sec-${si}`)}`}>
                <div className="flex flex-wrap items-center gap-3">
                  <span className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-tint text-[13px] font-extrabold text-navy">{si + 1}</span>
                  <input value={sec.title} onChange={(e) => setSection(si, { title: e.target.value })} placeholder={si === 0 ? "Introduction" : "Section title"} maxLength={120} className="min-w-[200px] flex-1 border-0 bg-transparent text-[20px] font-extrabold tracking-[-0.3px] text-ink outline-none placeholder:text-line-2" />
                  <label className="flex items-center gap-1.5 text-[12px] font-bold text-ink-3">
                    <input type="checkbox" checked={si === 0 ? sec.free !== false : Boolean(sec.free)} onChange={(e) => setSection(si, { free: e.target.checked })} className="h-4 w-4 accent-navy" />
                    Free to read
                  </label>
                  <div className="flex items-center">
                    <button type="button" aria-label="Move up" onClick={() => moveSection(si, -1)} disabled={si === 0} className={iconBtn}>
                      ↑
                    </button>
                    <button type="button" aria-label="Move down" onClick={() => moveSection(si, 1)} disabled={si === course.sections.length - 1} className={iconBtn}>
                      ↓
                    </button>
                    <button type="button" aria-label="Delete section" onClick={() => removeSection(si)} disabled={course.sections.length <= 2} className={`${iconBtn} hover:text-red`}>
                      ×
                    </button>
                  </div>
                </div>
                <div className="flex flex-col gap-3">
                  {sec.blocks.map((block, bi) => (
                    <BlockEditor key={bi} id={`blk-${si}-${bi}`} block={block} flash={flash === `blk-${si}-${bi}`} first={bi === 0} last={bi === sec.blocks.length - 1} onChange={(patch) => setBlock(si, bi, patch)} onMove={(dir) => moveBlock(si, bi, dir)} onRemove={() => removeBlock(si, bi)} onReplaceImage={() => { setTarget({ kind: "block", s: si, b: bi }); setTab("images"); }} />
                  ))}
                </div>
                <div className="flex flex-wrap items-center gap-1.5 border-t border-line pt-3">
                  <span className="mr-1 text-[12px] font-bold text-muted">Add</span>
                  {BLOCK_TYPES.map((type) => (
                    <button key={type} type="button" onClick={() => addBlock(si, type)} className="rounded-lg border border-line bg-white px-2.5 py-1 text-[12px] font-bold text-ink-2 hover:border-line-2 hover:text-navy">
                      {BLOCK_LABEL[type]}
                    </button>
                  ))}
                </div>
              </section>
            ))}
            <button type="button" onClick={addSection} disabled={course.sections.length >= 12} className="rounded-card border border-dashed border-line-2 bg-white/60 py-4 text-[14px] font-bold text-blue hover:bg-white disabled:opacity-40">
              + Add a section
            </button>
          </div>

          {/* Glossaire */}
          <section id="glossary" className={`flex flex-col gap-4 rounded-card border border-line bg-white p-6 ${flashClass("glossary")}`}>
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div className="flex flex-col">
                <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Glossary</h2>
                <span className="text-[13px] text-ink-3">Every [[term]] in the text opens a short explanation in the app. Missing entries are written by the factory.</span>
              </div>
              <div className="flex gap-2">
                {missingTerms.length > 0 && (
                  <button type="button" onClick={() => update((c) => ({ ...c, glossary: [...c.glossary, ...missingTerms.map((term) => ({ term, classification: "concept", explanation: "" }))] }))} className="rounded-lg border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-navy hover:bg-tint">
                    Add {missingTerms.length} cited {missingTerms.length === 1 ? "term" : "terms"}
                  </button>
                )}
                <button type="button" onClick={() => update((c) => ({ ...c, glossary: [...c.glossary, { term: "", classification: "concept", explanation: "" }] }))} className="rounded-lg border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-navy hover:bg-tint">
                  + Entry
                </button>
              </div>
            </div>
            {course.glossary.length === 0 && <p className="text-[14px] text-muted">No entry yet.</p>}
            <div className="flex flex-col gap-3">
              {course.glossary.map((g, i) => (
                <div key={i} className="grid grid-cols-1 gap-2 rounded-2xl bg-paper p-3 sm:grid-cols-[1fr_190px_auto]">
                  <input value={g.term} onChange={(e) => update((c) => ({ ...c, glossary: c.glossary.map((x, k) => (k === i ? { ...x, term: e.target.value } : x)) }))} placeholder="Term, as written in the text" maxLength={120} className={small} />
                  <select value={g.classification} onChange={(e) => update((c) => ({ ...c, glossary: c.glossary.map((x, k) => (k === i ? { ...x, classification: e.target.value } : x)) }))} className={small}>
                    {CLASSIFICATIONS.map((cl) => (
                      <option key={cl} value={cl}>
                        {CLASSIFICATION_LABEL[cl]}
                      </option>
                    ))}
                  </select>
                  <button type="button" aria-label="Remove entry" onClick={() => update((c) => ({ ...c, glossary: c.glossary.filter((_, k) => k !== i) }))} className={`${iconBtn} hover:text-red`}>
                    ×
                  </button>
                  <textarea value={g.explanation} onChange={(e) => update((c) => ({ ...c, glossary: c.glossary.map((x, k) => (k === i ? { ...x, explanation: e.target.value } : x)) }))} rows={2} maxLength={600} placeholder="One or two sentences, 10 to 600 characters." className={`${textarea} sm:col-span-3`} />
                </div>
              ))}
            </div>
          </section>

          {/* Sources */}
          <section id="sources" className={`flex flex-col gap-4 rounded-card border border-line bg-white p-6 ${flashClass("sources")}`}>
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div className="flex flex-col">
                <h2 className="text-[18px] font-extrabold tracking-[-0.3px]">Sources</h2>
                <span className="text-[13px] text-ink-3">Books, articles, museum pages. Shown at the end of the course.</span>
              </div>
              <button type="button" onClick={() => update((c) => ({ ...c, sources: [...c.sources, { text: "" }] }))} className="rounded-lg border border-line bg-white px-3 py-1.5 text-[13px] font-bold text-navy hover:bg-tint">
                + Source
              </button>
            </div>
            {course.sources.length === 0 && <p className="text-[14px] text-muted">No source yet.</p>}
            <div className="flex flex-col gap-2">
              {course.sources.map((src, i) => (
                <div key={i} className="grid grid-cols-1 gap-2 sm:grid-cols-[1fr_260px_auto]">
                  <input value={src.text} onChange={(e) => update((c) => ({ ...c, sources: c.sources.map((x, k) => (k === i ? { ...x, text: e.target.value } : x)) }))} placeholder="Author, Title, publisher, year" maxLength={400} className={small} />
                  <input value={src.url ?? ""} onChange={(e) => update((c) => ({ ...c, sources: c.sources.map((x, k) => (k === i ? { ...x, url: e.target.value || undefined } : x)) }))} placeholder="https:// (optional)" maxLength={1000} className={small} />
                  <button type="button" aria-label="Remove source" onClick={() => update((c) => ({ ...c, sources: c.sources.filter((_, k) => k !== i) }))} className={`${iconBtn} hover:text-red`}>
                    ×
                  </button>
                </div>
              ))}
            </div>
          </section>
        </div>

        {/* Panneau */}
        <aside className="lg:sticky lg:top-[68px] lg:max-h-[calc(100vh-84px)] lg:self-start lg:overflow-y-auto">
          <div className="flex flex-col rounded-card border border-line bg-white">
            <div className="flex border-b border-line p-1.5">
              {(["checks", "images", "preview"] as Tab[]).map((tb) => (
                <button key={tb} type="button" onClick={() => setTab(tb)} className={`flex-1 rounded-xl px-2 py-2 text-[13px] font-bold ${tab === tb ? "bg-navy text-white" : "text-ink-3 hover:bg-paper"}`}>
                  {tb === "checks" ? `Checks${errorCount ? ` · ${errorCount}` : ""}` : tb === "images" ? "Images" : "Preview"}
                </button>
              ))}
            </div>
            <div className="p-4">
              {tab === "checks" && <ChecksPanel findings={findings} blockers={blockers} onboardingHref={onboardingHref} words={words} onJump={jumpTo} />}
              {tab === "images" && <ImagesPanel target={target} active={active} sections={course.sections} onPick={placeImage} onCancel={() => setTarget(null)} />}
              {tab === "preview" && <PreviewPanel course={course} originLang={originLang} />}
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}

// ------------------------------------------------------------------ un bloc

function BlockEditor({ id, block, flash, first, last, onChange, onMove, onRemove, onReplaceImage }: { id: string; block: Block; flash: boolean; first: boolean; last: boolean; onChange: (patch: Partial<Block>) => void; onMove: (dir: -1 | 1) => void; onRemove: () => void; onReplaceImage: () => void }) {
  const tone: Record<BlockType, string> = { paragraph: "text-ink-3", heading: "text-navy", image: "text-blue", timeline: "text-blue", funFact: "text-amber", takeaway: "text-green-2", quote: "text-ink-3" };
  return (
    <div id={id} className={`group flex flex-col gap-2 rounded-2xl border border-transparent p-2 hover:border-line ${flash ? "ring-2 ring-blue ring-offset-2" : ""}`}>
      <div className="flex items-center justify-between">
        <span className={`text-[11px] font-bold uppercase tracking-[1px] ${tone[block.type as BlockType] ?? "text-ink-3"}`}>{BLOCK_LABEL[block.type as BlockType] ?? block.type}</span>
        <div className="flex items-center opacity-40 group-hover:opacity-100 group-focus-within:opacity-100">
          <button type="button" aria-label="Move up" onClick={() => onMove(-1)} disabled={first} className={iconBtn}>
            ↑
          </button>
          <button type="button" aria-label="Move down" onClick={() => onMove(1)} disabled={last} className={iconBtn}>
            ↓
          </button>
          <button type="button" aria-label="Delete block" onClick={onRemove} className={`${iconBtn} hover:text-red`}>
            ×
          </button>
        </div>
      </div>
      {block.type === "paragraph" && <textarea value={block.text} onChange={(e) => onChange({ text: e.target.value })} rows={rowsFor(block.text, 3)} placeholder="Write here. Short sentences, one idea each." className={textarea} />}
      {block.type === "heading" && <input value={block.text} onChange={(e) => onChange({ text: e.target.value })} placeholder="A heading inside the section" maxLength={160} className={`${input} text-[18px] font-extrabold`} />}
      {block.type === "funFact" && <textarea value={block.text} onChange={(e) => onChange({ text: e.target.value })} rows={rowsFor(block.text)} placeholder="A surprising fact, two sentences at most." className={`${textarea} border-amber-bg bg-amber-bg/40`} />}
      {block.type === "takeaway" && <textarea value={block.text} onChange={(e) => onChange({ text: e.target.value })} rows={rowsFor(block.text)} placeholder="What the reader should remember. One per course, at the end." className={`${textarea} bg-tint/60`} />}
      {block.type === "quote" && (
        <div className="flex flex-col gap-2">
          <textarea value={block.text} onChange={(e) => onChange({ text: e.target.value })} rows={rowsFor(block.text)} placeholder="The quotation, without quotation marks." className={`${textarea} italic`} />
          <input value={block.attribution ?? ""} onChange={(e) => onChange({ attribution: e.target.value } as Partial<Block>)} placeholder="Who said it, when (optional)" maxLength={160} className={small} />
        </div>
      )}
      {block.type === "image" && (
        <div className="flex flex-wrap gap-3">
          {block.image_url || block.asset ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={block.image_url ?? `https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/${block.asset}.jpg`} alt="" className="h-32 w-48 shrink-0 rounded-xl bg-paper object-cover" />
          ) : (
            <button type="button" onClick={onReplaceImage} className="flex h-32 w-48 shrink-0 items-center justify-center rounded-xl border border-dashed border-line-2 text-[13px] font-bold text-blue hover:bg-paper">
              Choose an image
            </button>
          )}
          <div className="flex min-w-[220px] flex-1 flex-col gap-2">
            <input value={block.caption ?? ""} onChange={(e) => onChange({ caption: e.target.value } as Partial<Block>)} placeholder="Caption shown under the image" maxLength={400} className={small} />
            <div className="grid grid-cols-2 gap-2">
              <input value={block.credit?.author ?? ""} onChange={(e) => onChange({ credit: { ...block.credit, author: e.target.value } } as Partial<Block>)} placeholder="Author" className={small} />
              <input value={block.credit?.license ?? ""} onChange={(e) => onChange({ credit: { ...block.credit, license: e.target.value } } as Partial<Block>)} placeholder="Licence (CC BY-SA 4.0, Public domain…)" className={small} />
            </div>
            <div className="flex gap-2">
              <button type="button" onClick={onReplaceImage} className="rounded-lg border border-line bg-white px-3 py-1.5 text-[12px] font-bold text-navy hover:bg-tint">
                {block.image_url || block.asset ? "Replace" : "Search Commons"}
              </button>
            </div>
          </div>
        </div>
      )}
      {block.type === "timeline" && (
        <div className="flex flex-col gap-2">
          {(block.events ?? []).map((ev, i) => (
            <div key={i} className="grid grid-cols-[110px_1fr_auto] gap-2">
              <input value={ev.date} onChange={(e) => onChange({ events: block.events.map((x, k) => (k === i ? { ...x, date: e.target.value } : x)) } as Partial<Block>)} placeholder="1503" maxLength={40} className={small} />
              <div className="flex flex-col gap-1.5">
                <input value={ev.title} onChange={(e) => onChange({ events: block.events.map((x, k) => (k === i ? { ...x, title: e.target.value } : x)) } as Partial<Block>)} placeholder="What happened" maxLength={160} className={small} />
                <input value={ev.detail ?? ""} onChange={(e) => onChange({ events: block.events.map((x, k) => (k === i ? { ...x, detail: e.target.value || undefined } : x)) } as Partial<Block>)} placeholder="Detail (optional)" maxLength={400} className={small} />
              </div>
              <button type="button" aria-label="Remove event" onClick={() => onChange({ events: block.events.filter((_, k) => k !== i) } as Partial<Block>)} disabled={block.events.length <= 2} className={`${iconBtn} hover:text-red`}>
                ×
              </button>
            </div>
          ))}
          <button type="button" onClick={() => onChange({ events: [...block.events, { date: "", title: "" }] } as Partial<Block>)} disabled={block.events.length >= 20} className="self-start rounded-lg px-2 py-1 text-[12px] font-bold text-blue hover:bg-paper disabled:opacity-40">
            + Event
          </button>
        </div>
      )}
    </div>
  );
}

// ------------------------------------------------------------------ vérifications

function ChecksPanel({ findings, blockers, onboardingHref, words, onJump }: { findings: Finding[]; blockers: string[]; onboardingHref: string | null; words: number; onJump: (path: string) => void }) {
  const errors = findings.filter((f) => f.severity === "error");
  const warnings = findings.filter((f) => f.severity === "warning");
  return (
    <div className="flex flex-col gap-4">
      <div className={`rounded-2xl p-4 ${errors.length ? "bg-red-bg/60" : blockers.length ? "bg-amber-bg/60" : "bg-green-bg"}`}>
        <strong className={`block text-[14px] font-extrabold ${errors.length ? "text-red" : blockers.length ? "text-amber" : "text-green"}`}>{errors.length ? `${errors.length} ${errors.length === 1 ? "problem" : "problems"} to fix` : blockers.length ? "Almost ready" : "Ready to send"}</strong>
        <span className="text-[13px] text-ink-2">{errors.length ? "The factory would refuse the course as it is." : blockers.length ? blockers[0] : `${words.toLocaleString("en")} words. The team reviews within 72 hours.`}</span>
        {!errors.length && onboardingHref && (
          <Link href={onboardingHref} className="mt-2 block text-[13px] font-bold text-navy">
            Sign the agreement →
          </Link>
        )}
      </div>
      {errors.length > 0 && <FindingList title="Problems" items={errors} tone="red" onJump={onJump} />}
      {warnings.length > 0 && <FindingList title="Advice" items={warnings} tone="amber" onJump={onJump} />}
      {findings.length === 0 && <p className="text-[13px] text-muted">Nothing to report. Read the course once more as a reader would, then send it.</p>}
    </div>
  );
}

function FindingList({ title, items, tone, onJump }: { title: string; items: Finding[]; tone: "red" | "amber"; onJump: (path: string) => void }) {
  return (
    <div className="flex flex-col gap-1.5">
      <span className="text-[12px] font-bold uppercase tracking-[1px] text-muted">{title}</span>
      <ul className="flex flex-col gap-1">
        {items.map((f, i) => (
          <li key={i}>
            <button type="button" onClick={() => onJump(f.path)} className="flex w-full items-start gap-2 rounded-xl px-2 py-1.5 text-left text-[13px] leading-[1.45] text-ink-2 hover:bg-paper">
              <span aria-hidden="true" className={`mt-[7px] h-2 w-2 shrink-0 rounded-full ${tone === "red" ? "bg-red-2" : "bg-saffron"}`} />
              <span>{f.message}</span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

// ------------------------------------------------------------------ images

function ImagesPanel({ target, active, sections, onPick, onCancel }: { target: ImageTarget | null; active: number; sections: Section[]; onPick: (img: CommonsImage) => void; onCancel: () => void }) {
  const [q, setQ] = useState("");
  const [results, setResults] = useState<CommonsImage[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  async function search(e?: React.FormEvent) {
    e?.preventDefault();
    if (q.trim().length < 2) return;
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/commons/search?q=${encodeURIComponent(q.trim())}`);
      const body = (await res.json()) as { results?: CommonsImage[]; error?: string };
      if (!res.ok) throw new Error(body.error ?? `Error ${res.status}`);
      setResults(body.results ?? []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Search failed");
    } finally {
      setBusy(false);
    }
  }
  const where = target?.kind === "cover" ? "the cover" : target?.kind === "block" ? `the image in section ${target.s + 1}` : `section ${(target?.kind === "new" ? target.s : active) + 1}${sections[target?.kind === "new" ? target.s : active]?.title ? ` (${sections[target?.kind === "new" ? target.s : active].title})` : ""}`;
  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-start justify-between gap-2 rounded-2xl bg-tint p-3 text-[13px] text-navy">
        <span>
          Pick a picture for <strong>{where}</strong>. Wikimedia Commons only: free licences, credit kept automatically.
        </span>
        {target && (
          <button type="button" onClick={onCancel} className="shrink-0 text-[12px] font-bold text-blue">
            Cancel
          </button>
        )}
      </div>
      <form onSubmit={search} className="flex gap-2">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Mona Lisa, Antikythera mechanism…" className={small} />
        <button type="submit" disabled={busy} className="h-9 shrink-0 rounded-lg bg-navy px-3 text-[13px] font-bold text-white disabled:opacity-50">
          {busy ? "…" : "Search"}
        </button>
      </form>
      {error && <p className="text-[13px] font-semibold text-red">{error}</p>}
      <div className="grid grid-cols-2 gap-2">
        {results.map((img) => (
          <button key={img.pageUrl} type="button" onClick={() => onPick(img)} className="flex flex-col gap-1 rounded-xl border border-line p-1.5 text-left hover:border-navy">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={img.thumb} alt="" loading="lazy" className="aspect-[4/3] w-full rounded-lg bg-paper object-cover" />
            <span className="line-clamp-2 text-[11px] font-semibold leading-[1.3] text-ink-2">{img.title.replace(/\.[a-z0-9]+$/i, "")}</span>
            <span className="truncate text-[10px] text-muted">
              {img.license || "licence?"}
              {img.author ? ` · ${img.author}` : ""}
            </span>
          </button>
        ))}
      </div>
      {results.length === 0 && !busy && q && !error && <p className="text-[13px] text-muted">No result yet. Try the name in English or the original language.</p>}
    </div>
  );
}

// ------------------------------------------------------------------ aperçu

function PreviewPanel({ course, originLang }: { course: DraftCourse; originLang: string }) {
  return (
    <div className="mx-auto flex w-full max-w-[330px] flex-col gap-4 rounded-[28px] border-[6px] border-ink bg-white p-4 shadow-[0_20px_50px_rgba(22,38,61,.18)]">
      <span className="text-[11px] font-bold uppercase tracking-[1px] text-blue">{course.subject ? SUBJECT_LABEL[course.subject as keyof typeof SUBJECT_LABEL] : "Course"} · {originLang.toUpperCase()}</span>
      {(course.hero.image_url || course.hero.image) && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={course.hero.image_url ?? `https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/${course.hero.image}.jpg`} alt="" className="aspect-[16/10] w-full rounded-2xl object-cover" />
      )}
      <h2 className="text-[22px] font-extrabold leading-[1.15] tracking-[-0.5px] text-ink">{course.title || "Untitled course"}</h2>
      {course.description && <p className="text-[14px] leading-[1.5] text-ink-3">{renderInline(course.description)}</p>}
      <div className="prose-course flex flex-col gap-3 text-[15px]">
        {course.sections.map((sec, i) => (
          <section key={i} className="flex flex-col gap-2 border-t border-line pt-3">
            <h3 className="text-[17px] font-extrabold tracking-[-0.2px] text-ink">
              {sec.title || `Section ${i + 1}`}
              {i === 0 || sec.free ? "" : " 🔒"}
            </h3>
            {sec.blocks.map((b, j) => (
              <BlockView key={j} block={b} plain />
            ))}
          </section>
        ))}
      </div>
    </div>
  );
}
