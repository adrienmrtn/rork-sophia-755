import { describe, expect, it } from "vitest";
import { conversion, dataHref, dataRpcArgs, groupExperiments, percent, readDataFilters, sortVersions } from "./paywalls";

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
    expect(dataHref({ days: 28, platform: null, lang: null, version: null })).toBe("/admin/data");
    expect(dataHref({ days: 7, platform: "ios", lang: "fr", version: null })).toBe("/admin/data?days=7&platform=ios&lang=fr");
    expect(dataHref({ days: 7, platform: null, lang: null, version: null }, "/admin/data/onboarding")).toBe("/admin/data/onboarding?days=7");
  });
});

describe("readDataFilters", () => {
  it("falls back to the defaults on anything unexpected", () => {
    expect(readDataFilters({ days: "12", platform: "windows", lang: "fr;drop" })).toEqual({ days: 28, platform: null, lang: null, version: null });
    expect(readDataFilters({ days: "90", platform: "android", lang: "pt-PT" })).toEqual({ days: 90, platform: "android", lang: "pt-PT", version: null });
  });
});

describe("version filter", () => {
  it("travels in the address only with its platform", () => {
    expect(dataHref({ days: 28, platform: "android", lang: null, version: "1.0.6" })).toBe("/admin/data?platform=android&v=1.0.6");
    expect(dataHref({ days: 28, platform: null, lang: null, version: "1.0.6" })).toBe("/admin/data");
    expect(readDataFilters({ platform: "android", v: "1.0.6" }).version).toBe("1.0.6");
    expect(readDataFilters({ v: "1.0.6" }).version).toBeNull();
    expect(readDataFilters({ platform: "ios", v: "2;drop" }).version).toBeNull();
  });

  it("is sent to the database only when chosen", () => {
    expect(dataRpcArgs({ days: 7, platform: null, lang: null, version: null })).toEqual({ p_days: 7, p_platform: null, p_lang: null });
    expect(dataRpcArgs({ days: 7, platform: "ios", lang: "fr", version: "2" })).toEqual({ p_days: 7, p_platform: "ios", p_lang: "fr", p_version: "2" });
  });

  it("sorts versions number by number, newest first", () => {
    const sorted = sortVersions([
      { platform: "ios", app_version: "2" },
      { platform: "android", app_version: "1.0.9" },
      { platform: "android", app_version: "1.0.10" },
      { platform: "android", app_version: "1.0.6" },
    ]);
    expect(sorted.map((v) => `${v.platform} ${v.app_version}`)).toEqual(["android 1.0.10", "android 1.0.9", "android 1.0.6", "ios 2"]);
  });
});
