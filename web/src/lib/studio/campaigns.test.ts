import { describe, expect, it } from "vitest";
import { campaignFromForm, campaignFromRow, emptyCampaign, hardErrors, languagesFilled, languagesMissing, localized, phase, publishProblems, type Campaign } from "./campaigns";

function form(entries: Record<string, string | string[]>): FormData {
  const f = new FormData();
  for (const [k, v] of Object.entries(entries)) for (const x of Array.isArray(v) ? v : [v]) f.append(k, x);
  return f;
}

const known = { courseIds: new Set(["course_1_a", "course_2_b", "course_3_c"]) };

function movember(): Campaign {
  return {
    ...emptyCampaign(),
    slug: "movember-2026",
    kind: "month",
    status: "draft",
    symbol: "mustache.fill",
    starts_at: "2026-11-01",
    ends_at: "2026-11-30",
    challenge_target: 3,
    course_ids: ["course_1_a", "course_2_b", "course_3_c"],
    title: { en: "Movember", fr: "Movember" },
    tagline: { en: "Men's health, let's talk about it.", fr: "La santé des hommes, on en parle." },
    description: { en: "A month to talk about it.", fr: "Un mois pour en parler." },
    badge_name: { en: "Moustache", fr: "Moustache" },
  };
}

describe("localized", () => {
  it("falls back to English then French", () => {
    expect(localized({ fr: "Bonjour", en: "Hello" }, "de")).toBe("Hello");
    expect(localized({ fr: "Bonjour" }, "de")).toBe("Bonjour");
    expect(localized({ fr: "Bonjour", de: "Hallo" }, "de")).toBe("Hallo");
    expect(localized({}, "de")).toBe("");
  });
});

describe("campaignFromForm", () => {
  it("builds a new event from the form and keeps only the listed symbols and kinds", () => {
    const c = campaignFromForm(form({ slug: "Armistice-2026", kind: "day", status: "draft", symbol: "flag.fill", starts_at: "2026-11-08", ends_at: "2026-11-11", challenge_target: "2", course_ids: ["course_1_a", "course_1_a", "course_2_b"], title_en: "Armistice", title_fr: "Armistice", upcoming_0_title_en: "The last day of the war", upcoming_0_creator: "jane-doe", upcoming_0_date: "2026-11-10" }), null);
    expect(c.slug).toBe("armistice-2026");
    expect(c.kind).toBe("day");
    expect(c.symbol).toBe("flag.fill");
    expect(c.course_ids).toEqual(["course_1_a", "course_2_b"]);
    expect(c.challenge_target).toBe(2);
    // Les cours annoncés « en écriture » n'existent plus : les anciens champs du formulaire sont ignorés.
    expect(c).not.toHaveProperty("upcoming");
    expect(c.title).toEqual({ en: "Armistice" });
  });

  it("keeps translated languages when English and French are edited, and removes an emptied field", () => {
    const existing = { ...movember(), title: { en: "Movember", fr: "Movember", de: "Movember" }, tagline: { en: "Old", fr: "Vieux", de: "Alt" } };
    const c = campaignFromForm(form({ kind: "month", status: "published", symbol: "mustache.fill", starts_at: "2026-11-01", ends_at: "2026-11-30", challenge_target: "3", course_ids: ["course_1_a"], title_en: "Movember 2026", title_fr: "", tagline_en: "New", tagline_fr: "Nouveau" }), existing);
    expect(c.slug).toBe("movember-2026");
    // Le français n'est plus saisi à la main : il est gardé tel quel, comme toute langue traduite.
    expect(c.title).toEqual({ en: "Movember 2026", fr: "Movember", de: "Movember" });
    expect(c.tagline).toEqual({ en: "New", fr: "Vieux", de: "Alt" });
    expect(c.status).toBe("published");
    expect(c.course_ids).toEqual(["course_1_a"]);
  });

  it("reads the common goal, empty meaning none", () => {
    expect(campaignFromForm(form({ starts_at: "2026-01-01", ends_at: "2026-01-05", goal_target: "10 000" }), null).goal_target).toBe(10000);
    expect(campaignFromForm(form({ starts_at: "2026-01-01", ends_at: "2026-01-05", goal_target: "" }), null).goal_target).toBeNull();
    expect(campaignFromForm(form({ starts_at: "2026-01-01", ends_at: "2026-01-05", goal_target: "0" }), null).goal_target).toBeNull();
  });

  it("reads the countries as upper-case two-letter codes, empty meaning everywhere", () => {
    expect(campaignFromForm(form({ starts_at: "2026-01-01", ends_at: "2026-01-05", countries: "fr, be ch" }), null).countries).toEqual(["FR", "BE", "CH"]);
    expect(campaignFromForm(form({ starts_at: "2026-01-01", ends_at: "2026-01-05", countries: "" }), null).countries).toBeNull();
    expect(hardErrors({ ...movember(), countries: ["FR", "FRA"] })).toEqual(["Countries must be two-letter codes (FR, BE, CH…): FRA."]);
  });

  it("ignores an unknown symbol or kind and keeps the previous one", () => {
    const c = campaignFromForm(form({ kind: "party", symbol: "poop", status: "secret", starts_at: "2026-01-01", ends_at: "2026-01-02" }), movember());
    expect(c.kind).toBe("month");
    expect(c.symbol).toBe("mustache.fill");
    expect(c.status).toBe("draft");
  });
});

describe("validation", () => {
  it("refuses a bad slug or inverted dates outright", () => {
    expect(hardErrors({ ...movember(), slug: "Mo vember" })).toHaveLength(1);
    expect(hardErrors({ ...movember(), ends_at: "2026-10-01" })).toEqual(["The event cannot end before it starts."]);
    expect(hardErrors(movember())).toEqual([]);
  });

  it("lists what blocks publication", () => {
    expect(publishProblems(movember(), known)).toEqual([]);
    const problems = publishProblems({ ...movember(), course_ids: ["course_1_a", "course_9_z"], badge_name: {} }, known);
    expect(problems).toContain("Badge name in English is required.");
    expect(problems.some((p) => p.startsWith("1 course is not published"))).toBe(true);
    expect(problems).toContain("The challenge asks for 3 courses but the collection has 2.");
    expect(problems.some((p) => p.startsWith("Announced course"))).toBe(false);
  });

  it("checks the duration against the kind", () => {
    expect(publishProblems({ ...movember(), kind: "day" }, known)).toEqual(["Commemoration day events last 1 to 10 days; this one lasts 30."]);
  });
});

describe("languages and phase", () => {
  it("counts the languages whose four texts are filled", () => {
    expect(languagesFilled(movember())).toEqual(["fr", "en"]);
    expect(languagesMissing(movember())).toHaveLength(28);
  });

  it("tells whether the event is upcoming, live or over", () => {
    expect(phase(movember(), "2026-10-31")).toBe("upcoming");
    expect(phase(movember(), "2026-11-15")).toBe("live");
    expect(phase(movember(), "2026-12-01")).toBe("over");
  });

  it("reads a table row defensively", () => {
    const c = campaignFromRow({ slug: "x-1", kind: "nope", status: "published", symbol: "atom", image_url: "http://insecure/x.jpg", goal_target: "500", goal_count: 42, starts_at: "2026-01-01T00:00:00", ends_at: "2026-01-05", challenge_target: "2", course_ids: ["a"], upcoming: [{ title: { en: "T" }, creator: "", date: "2026-01-03" }], title: { en: "X", bad: 3 } });
    expect(c.kind).toBe("month");
    expect(c.symbol).toBe("atom");
    expect(c.starts_at).toBe("2026-01-01");
    expect(c.challenge_target).toBe(2);
    expect(c).not.toHaveProperty("upcoming");
    expect(c.title).toEqual({ en: "X" });
    expect(c.image_url).toBeNull();
    expect(c.goal_target).toBe(500);
    expect(c.goal_count).toBe(42);
  });
});
