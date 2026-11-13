import { describe, expect, it } from "vitest";
import { courseName, perDay, ratio } from "./usage";

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
