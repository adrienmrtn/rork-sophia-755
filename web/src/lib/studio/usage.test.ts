import { describe, expect, it } from "vitest";
import { courseName, openRate, perDay, ratio } from "./usage";

describe("ratio", () => {
  it("is null when there is nothing to compare against", () => {
    expect(ratio(3, 0)).toBeNull();
    expect(ratio(3, 12)).toBe(0.25);
  });
});

describe("perDay", () => {
  it("averages over the period", () => {
    expect(perDay(2800, 28)).toBe(100);
    expect(perDay(10, 7)).toBe(1);
    expect(perDay(10, 0)).toBe(0);
  });
});

describe("courseName", () => {
  it("prefers the title and falls back to a readable id", () => {
    expect(courseName({ course_id: "course_42_pourquoi_reve_t_on", title: "Pourquoi rêve-t-on ?" })).toBe("Pourquoi rêve-t-on ?");
    expect(courseName({ course_id: "course_42_pourquoi_reve_t_on", title: null })).toBe("pourquoi reve t on");
    expect(courseName({ course_id: "odd", title: null })).toBe("odd");
  });
});

describe("openRate", () => {
  it("needs enough impressions to mean something", () => {
    expect(openRate(5, 10)).toBeNull();
    expect(openRate(undefined, undefined)).toBeNull();
    expect(openRate(10, 40)).toBe(0.25);
    expect(openRate(0, 40)).toBe(0);
  });
});
