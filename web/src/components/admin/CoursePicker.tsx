"use client";

import { useMemo, useState } from "react";

export type PickableCourse = { id: string; title: string; subject: string; creator: string | null };

/** La collection d'un événement : toutes les cases restent dans le formulaire (celles qui ne
 *  répondent pas au filtre sont seulement cachées), pour qu'un cours coché puis filtré soit
 *  bien envoyé. */
export function CoursePicker({ courses, selected, inputClass }: { courses: PickableCourse[]; selected: string[]; inputClass: string }) {
  const [query, setQuery] = useState("");
  const [checked, setChecked] = useState<Set<string>>(() => new Set(selected));
  const ordered = useMemo(() => {
    const initial = new Set(selected);
    return [...courses].sort((a, b) => Number(initial.has(b.id)) - Number(initial.has(a.id)) || a.title.localeCompare(b.title));
  }, [courses, selected]);
  const q = query.trim().toLowerCase();
  const matches = (c: PickableCourse) => !q || c.title.toLowerCase().includes(q) || c.id.toLowerCase().includes(q) || c.subject.toLowerCase().includes(q) || (c.creator ?? "").toLowerCase().includes(q);
  const toggle = (id: string, on: boolean) =>
    setChecked((prev) => {
      const next = new Set(prev);
      if (on) next.add(id);
      else next.delete(id);
      return next;
    });

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-3">
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Filter by title, subject, author or id…" className={`${inputClass} max-w-[420px]`} aria-label="Filter courses" />
        <span className="text-[13px] font-bold text-ink-2">
          {checked.size} selected · {courses.length} published
        </span>
      </div>
      <div className="max-h-[380px] overflow-y-auto rounded-xl border border-line">
        {ordered.map((c) => (
          <label key={c.id} className={`flex cursor-pointer items-start gap-3 border-b border-line px-3.5 py-2.5 text-[14px] last:border-b-0 hover:bg-paper ${matches(c) ? "" : "hidden"}`}>
            <input type="checkbox" name="course_ids" value={c.id} checked={checked.has(c.id)} onChange={(e) => toggle(c.id, e.target.checked)} className="mt-1 h-4 w-4 accent-navy" />
            <span className="flex min-w-0 flex-1 flex-col">
              <span className="font-semibold text-ink">{c.title}</span>
              <span className="truncate text-[12px] text-muted">
                {c.subject}
                {c.creator ? ` · ${c.creator}` : ""} · {c.id}
              </span>
            </span>
          </label>
        ))}
        {ordered.every((c) => !matches(c)) && <p className="px-3.5 py-4 text-[14px] text-muted">No course matches.</p>}
      </div>
    </div>
  );
}
