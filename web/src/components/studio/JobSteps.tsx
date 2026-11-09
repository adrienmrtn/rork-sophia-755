import type { JobRow, StepRow } from "@/lib/studio/data";
import { shortDateTime } from "@/lib/studio/data";

/** L'état d'un job de production, lisible par un auteur : les étapes globales, puis les langues. */

const STEP_LABEL: Record<StepRow["step"], string> = {
  glossary: "Glossary",
  quiz: "Quiz",
  cover: "Cover image",
  translate: "Translation",
  gate: "Quality gate",
  audio: "Narration",
  publish: "Publication",
};

export const JOB_LABEL: Record<JobRow["status"], string> = {
  queued: "Waiting for the factory",
  dispatched: "Sent to the factory",
  running: "In production",
  done: "Published in every language",
  partial: "Published, some languages held back",
  failed: "Production failed",
};

const STATUS_LOOK: Record<StepRow["status"], string> = {
  pending: "bg-paper text-muted",
  running: "bg-tint text-navy",
  done: "bg-green-bg text-green",
  failed: "bg-red-bg text-red",
  skipped: "bg-paper text-muted",
};

export function JobSummary({ job }: { job: JobRow }) {
  const tone = job.status === "failed" ? "bg-red-bg text-red" : job.status === "done" ? "bg-green-bg text-green" : job.status === "partial" ? "bg-amber-bg text-amber" : "bg-tint text-navy";
  return (
    <div className="flex flex-wrap items-center gap-3">
      <span className={`inline-flex items-center rounded-full px-3 py-1.5 text-[13px] font-bold ${tone}`}>{JOB_LABEL[job.status] ?? job.status}</span>
      <span className="text-[13px] text-ink-3">
        Started {shortDateTime(job.created_at)}
        {job.finished_at ? ` · finished ${shortDateTime(job.finished_at)}` : ""}
      </span>
      {job.error && <span className="w-full text-[13px] font-semibold text-red">{job.error}</span>}
    </div>
  );
}

export function JobSteps({ steps }: { steps: StepRow[] }) {
  const global = steps.filter((s) => s.lang === null || s.step === "audio");
  const langs = [...new Set(steps.filter((s) => s.step === "translate" || s.step === "gate").map((s) => s.lang as string))];
  const byLang = (lang: string, step: StepRow["step"]) => steps.find((s) => s.lang === lang && s.step === step);
  const done = steps.filter((s) => s.status === "done" || s.status === "skipped").length;
  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-col gap-1.5">
        <div className="flex items-center justify-between text-[13px] text-ink-3">
          <span>Progress</span>
          <span className="tabular-nums">
            {done} / {steps.length} steps
          </span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-tint">
          <div className="h-full rounded-full bg-navy" style={{ width: `${steps.length ? Math.round((done / steps.length) * 100) : 0}%` }} />
        </div>
      </div>
      <ul className="flex flex-wrap gap-2">
        {global.map((s) => (
          <li key={s.id} className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-[13px] font-bold ${STATUS_LOOK[s.status]}`}>
            {STEP_LABEL[s.step]}
            {s.lang ? ` ${s.lang.toUpperCase()}` : ""}
            <span className="font-medium opacity-80">· {s.status}</span>
          </li>
        ))}
      </ul>
      {langs.length > 0 && (
        <div className="flex flex-col gap-2">
          <span className="text-[13px] font-bold text-ink-3">Languages</span>
          <ul className="grid grid-cols-2 gap-1.5 sm:grid-cols-3 md:grid-cols-5 lg:grid-cols-6">
            {langs.map((lang) => {
              const t = byLang(lang, "translate");
              const g = byLang(lang, "gate");
              const state: StepRow["status"] = g?.status === "done" ? "done" : t?.status === "failed" || g?.status === "failed" ? "failed" : t?.status === "running" || g?.status === "running" ? "running" : t?.status === "done" ? "running" : "pending";
              const findings = (g?.detail?.findings as unknown[] | undefined)?.length ?? 0;
              return (
                <li key={lang} className={`flex items-center justify-between rounded-xl px-3 py-2 text-[13px] font-bold ${STATUS_LOOK[state]}`} title={findings ? `${findings} findings` : undefined}>
                  <span className="uppercase">{lang}</span>
                  <span className="text-[12px] font-medium">{state === "done" ? "published" : state === "running" ? "…" : state === "failed" ? "held back" : ""}</span>
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
}
