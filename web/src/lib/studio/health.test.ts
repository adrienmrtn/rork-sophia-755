import { describe, expect, it } from "vitest";
import { bytesLabel, healthAlerts, projectedJournalBytes, scheduleLabel, type DataHealth } from "./health";

const base: DataHealth = {
  checked_at: "2026-11-13T10:00:00Z",
  retention_days: 60,
  database_bytes: 2_200_000_000,
  journal: { bytes: 1_800_000, rows: 1565, days_kept: 4, oldest_day: "2026-11-10", onboarding_bytes: 190_000, summaries_bytes: 450_000 },
  series: [],
  last_7_days: { events: 7000, by_name: [], by_version: [] },
  platforms: [
    { platform: "android", last_day: "2026-11-12", events_yesterday: 300 },
    { platform: "ios", last_day: "2026-11-12", events_yesterday: 700 },
  ],
  jobs: [{ name: "daily_usage_stats", schedule: "45 * * * *", active: true, status: "succeeded", started_at: "2026-11-13T09:45:00Z", seconds: 0.4, message: null }],
};

describe("bytesLabel", () => {
  it("picks a readable unit", () => {
    expect(bytesLabel(512)).toBe("512 B");
    expect(bytesLabel(450_000)).toBe("450 kB");
    expect(bytesLabel(2_200_000_000)).toBe("2.2 GB");
    expect(bytesLabel(35_000_000_000)).toBe("35 GB");
  });
});

describe("projectedJournalBytes", () => {
  it("uses a default row size while the journal is too small to measure", () => {
    // 1 000 événements par jour, 60 jours, 650 octets.
    expect(projectedJournalBytes(base)).toBe(1000 * 60 * 650);
  });

  it("measures the row size once the journal is large enough", () => {
    const big = { ...base, journal: { ...base.journal, rows: 10_000_000, bytes: 5_000_000_000 }, last_7_days: { ...base.last_7_days, events: 7_000_000 } };
    expect(projectedJournalBytes(big)).toBe(1_000_000 * 60 * 500);
  });
});

describe("healthAlerts", () => {
  it("says nothing when everything runs", () => {
    expect(healthAlerts(base)).toEqual([]);
  });

  it("flags a failed task, a silent platform and a platform that never sent", () => {
    const alerts = healthAlerts({
      ...base,
      jobs: [{ ...base.jobs[0], status: "failed", message: "boom" }],
      platforms: [
        { platform: "android", last_day: null, events_yesterday: 0 },
        { platform: "ios", last_day: "2026-11-10", events_yesterday: 0 },
      ],
    });
    expect(alerts.map((a) => a.level)).toEqual(["red", "amber", "red"]);
    expect(alerts[0].text).toContain("boom");
    expect(alerts[2].text).toContain("iOS sent nothing yesterday");
  });

  it("flags a task that stopped running", () => {
    expect(healthAlerts({ ...base, jobs: [{ ...base.jobs[0], started_at: "2026-11-11T09:45:00Z" }] })[0].level).toBe("amber");
    expect(healthAlerts({ ...base, jobs: [{ ...base.jobs[0], started_at: null, status: null }] })[0].text).toContain("has not run");
  });

  it("warns before the database outgrows the machine", () => {
    const heavy = { ...base, last_7_days: { ...base.last_7_days, events: 7 * 1_400_000 } };
    expect(healthAlerts(heavy).some((a) => a.level === "red" && a.text.includes("Medium"))).toBe(true);
  });
});

describe("scheduleLabel", () => {
  it("reads the two schedules in use", () => {
    expect(scheduleLabel("45 * * * *")).toBe("Every hour");
    expect(scheduleLabel("5 0 * * *")).toBe("Every day");
    expect(scheduleLabel("*/5 * * * *")).toBe("*/5 * * * *");
  });
});
