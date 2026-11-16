import { describe, expect, it } from "vitest";
import { heat, retained } from "./retention";

describe("retained", () => {
  it("is null while the milestone is not known or the cohort is empty", () => {
    expect(retained(null, 100)).toBeNull();
    expect(retained(5, 0)).toBeNull();
    expect(retained(25, 100)).toBe(0.25);
    expect(retained(0, 100)).toBe(0);
  });
});

describe("heat", () => {
  it("gets darker as the rate nears the column's best", () => {
    expect(heat(null, 0.2)).toBeUndefined();
    expect(heat(0.1, 0)).toBeUndefined();
    expect(heat(0, 0.2)).toBe("rgba(26, 58, 107, 0.06)");
    expect(heat(0.2, 0.2)).toBe("rgba(26, 58, 107, 0.40)");
  });
});
