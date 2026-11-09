/** Les lectures par jour : une série, des barres fines en bleu nuit, une grille discrète.
 *  Rendu côté serveur, en SVG, avec une infobulle native par barre. */
export function ReadsChart({ series, height = 220 }: { series: { day: string; reads: number }[]; height?: number }) {
  if (series.length === 0) {
    return <div className="flex h-[220px] items-center justify-center rounded-2xl bg-paper text-[14px] text-muted">No reading data yet.</div>;
  }
  const width = 760;
  const pad = { top: 12, right: 8, bottom: 28, left: 44 };
  const w = width - pad.left - pad.right;
  const h = height - pad.top - pad.bottom;
  const max = Math.max(1, ...series.map((p) => p.reads));
  const nice = niceMax(max);
  const ticks = [0, nice / 2, nice];
  const n = series.length;
  const slot = w / n;
  const bar = Math.max(2, Math.min(18, slot - 2));
  const y = (v: number) => pad.top + h - (v / nice) * h;
  const labelEvery = n > 40 ? 14 : n > 10 ? 7 : 1;
  return (
    <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label="Reads per day" className="h-auto w-full">
      {ticks.map((t) => (
        <g key={t}>
          <line x1={pad.left} x2={width - pad.right} y1={y(t)} y2={y(t)} stroke="#e4e7ec" strokeWidth="1" />
          <text x={pad.left - 8} y={y(t) + 4} textAnchor="end" fontSize="11" fill="#8994a6">
            {formatTick(t)}
          </text>
        </g>
      ))}
      {series.map((p, i) => {
        const x = pad.left + i * slot + (slot - bar) / 2;
        const top = y(p.reads);
        const barH = Math.max(0, pad.top + h - top);
        const r = Math.min(4, bar / 2, barH);
        const d = barH <= 0 ? "" : `M${x} ${pad.top + h} V${top + r} Q${x} ${top} ${x + r} ${top} H${x + bar - r} Q${x + bar} ${top} ${x + bar} ${top + r} V${pad.top + h} Z`;
        return (
          <g key={p.day}>
            <rect x={pad.left + i * slot} y={pad.top} width={slot} height={h} fill="transparent">
              <title>{`${formatDay(p.day)} · ${p.reads.toLocaleString("en")} reads`}</title>
            </rect>
            {d && <path d={d} fill="#1a3a6b" className="pointer-events-none" />}
            {i % labelEvery === 0 && (
              <text x={pad.left + i * slot + slot / 2} y={height - 8} textAnchor="middle" fontSize="11" fill="#8994a6">
                {formatDay(p.day, n > 10)}
              </text>
            )}
          </g>
        );
      })}
      <line x1={pad.left} x2={width - pad.right} y1={pad.top + h} y2={pad.top + h} stroke="#c4ccd8" strokeWidth="1" />
    </svg>
  );
}

function niceMax(v: number): number {
  const mag = Math.pow(10, Math.floor(Math.log10(v)));
  const norm = v / mag;
  const step = norm <= 1 ? 1 : norm <= 2 ? 2 : norm <= 5 ? 5 : 10;
  return step * mag;
}

function formatTick(v: number): string {
  if (v >= 1000) return `${(v / 1000).toFixed(v % 1000 === 0 ? 0 : 1)}k`;
  return String(v);
}

function formatDay(day: string, short = false): string {
  const d = new Date(`${day}T00:00:00Z`);
  return d.toLocaleDateString("en-GB", short ? { day: "numeric", month: "short", timeZone: "UTC" } : { weekday: "short", day: "numeric", timeZone: "UTC" });
}
