/** Ce que renvoie la fonction SQL admin_data_health (docs/events.md), et ce que la page
 *  /admin/data/health en tire : des alertes et une projection de la taille du journal. */

export interface DataHealth {
  checked_at: string;
  retention_days: number;
  database_bytes: number;
  journal: {
    bytes: number;
    /** Estimation du planificateur de Postgres, pas un comptage. */
    rows: number;
    days_kept: number;
    oldest_day: string | null;
    onboarding_bytes: number;
    summaries_bytes: number;
  };
  series: { day: string; events: number; ios: number; android: number }[];
  last_7_days: {
    events: number;
    by_name: { name: string; events: number }[];
    by_version: { platform: string; app_version: string; events: number; last_day: string }[];
  };
  platforms: { platform: string; last_day: string | null; events_yesterday: number }[];
  jobs: { name: string; schedule: string; active: boolean; status: string | null; started_at: string | null; seconds: number | null; message: string | null }[];
}

/** Une taille lisible : octets, Mo ou Go. */
export function bytesLabel(bytes: number): string {
  const b = Number(bytes);
  if (b >= 1e9) return `${(b / 1e9).toFixed(b >= 1e10 ? 0 : 1)} GB`;
  if (b >= 1e6) return `${(b / 1e6).toFixed(b >= 1e7 ? 0 : 1)} MB`;
  if (b >= 1e3) return `${Math.round(b / 1e3)} kB`;
  return `${b} B`;
}

/** Taille d'une ligne du journal, index compris, quand il n'y a pas encore assez de lignes
 *  pour la mesurer : les pages presque vides d'un petit journal la surestiment. */
export const DEFAULT_ROW_BYTES = 650;
const MIN_ROWS_TO_MEASURE = 100_000;

/** La taille que le journal atteindra une fois la période de conservation remplie, au rythme
 *  des sept derniers jours complets. */
export function projectedJournalBytes(health: Pick<DataHealth, "journal" | "last_7_days" | "retention_days">): number {
  const perDay = Number(health.last_7_days.events) / 7;
  const rows = Number(health.journal.rows);
  const rowBytes = rows >= MIN_ROWS_TO_MEASURE ? Number(health.journal.bytes) / rows : DEFAULT_ROW_BYTES;
  return Math.round(perDay * health.retention_days * rowBytes);
}

export interface HealthAlert {
  level: "red" | "amber";
  text: string;
}

/** Au-delà, la taille recommandée par Supabase pour la machine « Small » est dépassée. */
export const SMALL_COMPUTE_MAX_BYTES = 50e9;

/** Ce qui demande une action : une tâche en échec ou jamais passée, une plateforme muette,
 *  une base qui approche la limite de sa machine. */
export function healthAlerts(health: DataHealth, now: Date = new Date(health.checked_at)): HealthAlert[] {
  const alerts: HealthAlert[] = [];
  for (const job of health.jobs) {
    if (!job.active) alerts.push({ level: "red", text: `The scheduled task ${job.name} is switched off: its numbers no longer refresh.` });
    else if (job.status === "failed") alerts.push({ level: "red", text: `The scheduled task ${job.name} failed on its last run${job.message ? `: ${job.message}` : "."}` });
    else if (!job.started_at) alerts.push({ level: "amber", text: `The scheduled task ${job.name} has not run in the last three days.` });
    else if (now.getTime() - new Date(job.started_at).getTime() > 26 * 3600 * 1000) alerts.push({ level: "amber", text: `The scheduled task ${job.name} last ran more than a day ago.` });
  }
  for (const p of health.platforms) {
    const name = p.platform === "ios" ? "iOS" : "Android";
    if (!p.last_day) alerts.push({ level: "amber", text: `${name} has never sent an event. Expected until a version that collects usage is released; a problem after.` });
    else if (Number(p.events_yesterday) === 0) alerts.push({ level: "red", text: `${name} sent nothing yesterday (last event on ${p.last_day}).` });
  }
  const projected = projectedJournalBytes(health);
  const total = Number(health.database_bytes) - Number(health.journal.bytes) + Math.max(projected, Number(health.journal.bytes));
  if (total > SMALL_COMPUTE_MAX_BYTES) alerts.push({ level: "red", text: `At this pace the database will reach about ${bytesLabel(total)}, past what a Small machine is recommended for (50 GB). Move to Medium or shorten the retention.` });
  else if (total > SMALL_COMPUTE_MAX_BYTES * 0.7) alerts.push({ level: "amber", text: `At this pace the database will reach about ${bytesLabel(total)}, close to what a Small machine is recommended for (50 GB).` });
  return alerts;
}

/** `25 * * * *` → « every hour », `5 0 * * *` → « every day ». */
export function scheduleLabel(schedule: string): string {
  const [minute, hour, dayOfMonth, , dayOfWeek] = schedule.trim().split(/\s+/);
  if (!/^\d+$/.test(minute ?? "")) return schedule;
  if (hour === "*") return "Every hour";
  if (/^\d+$/.test(hour ?? "") && dayOfMonth === "*" && dayOfWeek === "*") return "Every day";
  return schedule;
}
