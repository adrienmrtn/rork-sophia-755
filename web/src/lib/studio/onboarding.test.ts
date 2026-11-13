import { describe, expect, it } from "vitest";
import { funnel, questionViews } from "./onboarding";

const step = (name: string, installs: number) => ({ step: name, installs, ios: installs, android: 0 });

describe("funnel", () => {
  it("orders the screens as the flow does and measures them against the first", () => {
    const steps = funnel([step("login", 40), step("welcome", 100), step("age", 80), step("brand_new_screen", 5)]);
    expect(steps.map((s) => s.step)).toEqual(["welcome", "age", "login", "brand_new_screen"]);
    expect(steps.map((s) => s.share)).toEqual([1, 0.8, 0.4, 0.05]);
    expect(steps[1].label).toBe("Age");
  });

  it("marks the screens part of the people never see", () => {
    const steps = funnel([step("welcome", 10), step("reading_time", 6), step("paywall", 2)]);
    expect(steps.map((s) => s.note)).toEqual([null, "iOS only", "Android only"]);
  });

  it("has no share without anyone", () => {
    expect(funnel([step("welcome", 0)])[0].share).toBeNull();
    expect(funnel([])).toEqual([]);
  });
});

describe("questionViews", () => {
  it("keeps the natural order of ages and labels them", () => {
    const [age] = questionViews([{ question: "age", answered: 10, options: [{ value: "25to34", installs: 6 }, { value: "under18", installs: 1 }, { value: "18to24", installs: 3 }] }]);
    expect(age.options.map((o) => o.label)).toEqual(["Under 18", "18–24", "25–34"]);
    expect(age.options.map((o) => o.share)).toEqual([0.1, 0.3, 0.6]);
  });

  it("orders numeric answers by value and reads phone time in hours", () => {
    const [phone] = questionViews([{ question: "phone_time", answered: 4, options: [{ value: "180", installs: 2 }, { value: "30", installs: 1 }, { value: "90", installs: 1 }] }]);
    expect(phone.options.map((o) => o.label)).toEqual(["30 min", "1 h 30", "3 h"]);
  });

  it("orders the other answers by how often they were chosen", () => {
    const views = questionViews([
      { question: "reads_monthly", answered: 3, options: [{ value: "false", installs: 1 }, { value: "true", installs: 2 }] },
      { question: "objectives", answered: 2, options: [{ value: "exams", installs: 1 }, { value: "cultivate", installs: 2 }] },
    ]);
    expect(views.map((v) => v.question)).toEqual(["objectives", "reads_monthly"]);
    expect(views[0].options.map((o) => o.label)).toEqual(["Get cultured every day", "Studies and exams"]);
    // Choix multiples : les parts dépassent 100 % au total.
    expect(views[0].options.map((o) => o.share)).toEqual([1, 0.5]);
    expect(views[1].options.map((o) => o.label)).toEqual(["Yes", "No"]);
  });

  it("names the courses of the swipe by their number", () => {
    const [liked] = questionViews([{ question: "swipe_liked", answered: 3, options: [{ value: "42", installs: 3 }, { value: "150", installs: 1 }] }]);
    expect(liked.options.map((o) => o.label)).toEqual(["Course 42", "Course 150"]);
  });
});
