import { describe, expect, it } from "vitest";
import { moneyCents, parseQuota, quotaBadge, quotaSummary, type Quota } from "./payments";

const base: Quota = {
  limit: 1,
  used: 0,
  open: 0,
  can_propose: true,
  can_validate: true,
  first_week: false,
  period_start: "2026-11-08T23:00:00Z",
  period_end: "2026-11-15T23:00:00Z",
  next_slot_at: "2026-11-10T10:00:00Z",
  blocked: false,
  custom: false,
  fee_cents: 1500,
  currency: "USD",
};

describe("moneyCents", () => {
  it("writes whole dollars without cents and fractions with two decimals", () => {
    expect(moneyCents(1500)).toBe("$15");
    expect(moneyCents(4500)).toBe("$45");
    expect(moneyCents(1250)).toBe("$12.50");
    expect(moneyCents(0)).toBe("$0");
  });
});

describe("parseQuota", () => {
  it("reads numbers sent as text and fills the defaults", () => {
    const q = parseQuota({ limit: "3", used: "1", open: 2, can_propose: true, first_week: true, period_end: "2026-11-15T23:00:00Z" });
    expect(q).toMatchObject({ limit: 3, used: 1, open: 2, can_propose: true, can_validate: false, first_week: true, fee_cents: 1500, currency: "USD" });
    expect(parseQuota(null)).toBeNull();
  });
});

describe("quotaSummary", () => {
  it("tells a new author what the first week allows", () => {
    const out = quotaSummary({ ...base, limit: 3, used: 1, open: 1, first_week: true });
    expect(out.headline).toBe("First week: 1 of 3 courses validated.");
    expect(out.detail).toContain("1 in progress");
    expect(out.detail).toContain("then one course a week from Monday 16 Nov");
    expect(out.tone).toBe("ok");
  });
  it("names the next Monday once the week is used", () => {
    const out = quotaSummary({ ...base, used: 1, can_validate: false });
    expect(out.headline).toBe("This week: 1 of 1 course validated.");
    expect(out.detail).toBe("next validation from Monday 16 Nov");
    expect(out.tone).toBe("full");
  });
  it("explains a blocked account", () => {
    const out = quotaSummary({ ...base, limit: 0, blocked: true, can_propose: false, can_validate: false });
    expect(out.tone).toBe("blocked");
    expect(out.headline).toMatch(/paused/);
  });
  it("asks to finish the open course before proposing another", () => {
    const out = quotaSummary({ ...base, open: 1, can_propose: false });
    expect(out.detail).toBe("1 in progress · finish a course before proposing another");
  });
});

describe("quotaBadge", () => {
  it("summarises for the team", () => {
    expect(quotaBadge({ ...base, used: 1, open: 0, custom: true })).toBe("1/1 validated this week · 0 in progress · next from Monday 16 Nov · custom limit");
    expect(quotaBadge({ ...base, limit: 0, blocked: true })).toBe("blocked (limit 0)");
  });
});
