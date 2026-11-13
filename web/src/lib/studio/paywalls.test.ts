import { describe, expect, it } from "vitest";
import { conversion, dataHref, groupExperiments, percent } from "./paywalls";

describe("conversion", () => {
  it("divides purchases by viewers", () => {
    expect(conversion({ viewers: 200, purchases_completed: 5 })).toBe(0.025);
  });
  it("is null without viewers", () => {
    expect(conversion({ viewers: 0, purchases_completed: 0 })).toBeNull();
  });
});

describe("percent", () => {
  it("keeps one decimal under 10%", () => {
    expect(percent(0.025)).toBe("2.5%");
    expect(percent(0.4)).toBe("40%");
    expect(percent(0)).toBe("0%");
    expect(percent(null)).toBe("–");
  });
});

describe("groupExperiments", () => {
  it("groups variants by experiment, in order", () => {
    const rows = [
      { experiment: "a", variant: "x" },
      { experiment: "b", variant: "y" },
      { experiment: "a", variant: "z" },
    ];
    expect(groupExperiments(rows)).toEqual([
      { experiment: "a", variants: [rows[0], rows[2]] },
      { experiment: "b", variants: [rows[1]] },
    ]);
  });
});

describe("dataHref", () => {
  it("leaves defaults out of the address", () => {
    expect(dataHref({ days: 28, platform: null, lang: null })).toBe("/admin/data");
    expect(dataHref({ days: 7, platform: "ios", lang: "fr" })).toBe("/admin/data?days=7&platform=ios&lang=fr");
  });
});
