import { describe, expect, it } from "vitest";
import { citedTerms, courseWords, hasErrors, toPublishBody, validateCourse, type DraftCourse } from "./course-format";

const good: DraftCourse = {
  title: "The Antikythera mechanism",
  subtitle: "Around 100 BC",
  subject: "sciences",
  subcategory: "Ancient technology",
  description: "A corroded lump of bronze pulled from a shipwreck turned out to be the first known analogue computer. Here is what it did.",
  hero: { image_url: "https://upload.wikimedia.org/wikipedia/commons/x.jpg", ratio: "16:9", credit: { author: "Marsyas", license: "CC BY 2.5", source: "Wikimedia Commons" } },
  sections: [
    { title: "Introduction", free: true, blocks: [{ type: "paragraph", text: "In 1901, sponge divers found a wreck off [[Antikythera]]. Among the statues lay a **bronze** box." }] },
    { title: "What it computed", free: false, blocks: [{ type: "paragraph", text: "The gears followed the Moon and the Sun." }, { type: "timeline", events: [{ date: "1901", title: "Discovery" }, { date: "2005", title: "CT scans" }] }, { type: "takeaway", text: "A machine of gears modelled the sky two thousand years ago." }] },
  ],
  sources: [{ text: "Freeth, T. et al., Nature, 2006", url: "https://www.nature.com/" }],
  glossary: [{ term: "Antikythera", classification: "lieuInstitution", explanation: "A small Greek island between Crete and the Peloponnese." }],
};

describe("validateCourse", () => {
  it("accepts a well-formed course", () => {
    const findings = validateCourse(good);
    expect(hasErrors(findings)).toBe(false);
  });

  it("flags the format rules the factory enforces", () => {
    const bad: DraftCourse = {
      ...good,
      title: "Ab",
      subject: "cooking",
      description: "Too short",
      sections: [
        { title: "", free: true, blocks: [{ type: "paragraph", text: "An em dash — is forbidden and [[unbalanced" }] },
        { title: "Two takeaways", blocks: [{ type: "takeaway", text: "One" }, { type: "takeaway", text: "Two" }, { type: "image", caption: "no picture" }] },
      ],
      glossary: [{ term: "X", classification: "nope", explanation: "short" }],
    };
    const messages = validateCourse(bad).filter((f) => f.severity === "error").map((f) => f.message);
    expect(messages).toEqual(
      expect.arrayContaining([
        expect.stringContaining("3 to 160"),
        expect.stringContaining("Choose a subject"),
        expect.stringContaining("20 to 600"),
        expect.stringContaining("no title"),
        expect.stringContaining("em dash"),
        expect.stringContaining("[[…]]"),
        expect.stringContaining("Only one key takeaway"),
        expect.stringContaining("needs a picture"),
        expect.stringContaining("choose a type"),
        expect.stringContaining("10 to 600"),
      ]),
    );
  });

  it("warns, without blocking, about missing glossary entries and short courses", () => {
    const course: DraftCourse = { ...good, glossary: [] };
    const findings = validateCourse(course);
    expect(hasErrors(findings)).toBe(false);
    expect(findings.some((f) => f.severity === "warning" && f.message.includes("[[Antikythera]]"))).toBe(true);
    expect(findings.some((f) => f.severity === "warning" && f.message.includes("Short course"))).toBe(true);
  });

  it("requires between 2 and 12 sections", () => {
    expect(validateCourse({ ...good, sections: good.sections.slice(0, 1) }).some((f) => f.path === "sections" && f.severity === "error")).toBe(true);
  });
});

describe("helpers", () => {
  it("lists the cited glossary terms once", () => {
    expect(citedTerms({ ...good, description: "See [[Antikythera]] and [[Gear train]]." })).toEqual(["Antikythera", "Gear train"]);
  });
  it("counts words across blocks and timelines", () => {
    expect(courseWords(good)).toBeGreaterThan(30);
  });
});

describe("toPublishBody", () => {
  it("builds the publish-course body with the creator and no narration", () => {
    const body = toPublishBody(good, "en", { slug: "jane-doe", name: "Jane Doe", title: "Historian", photo_url: "https://x/y.jpg", country: "OTHER", links: { website: "https://jane.example" } }, { skipAudio: true, requestedBy: "studio:test" });
    expect(body.kind).toBe("course");
    expect(body.origin_lang).toBe("en");
    expect(body.options).toEqual({ skip_audio: true });
    expect(body.course.id).toBeUndefined();
    expect(body.course.hero).toEqual({ image_url: "https://upload.wikimedia.org/wikipedia/commons/x.jpg", ratio: "16:9", credit: good.hero.credit });
    expect(body.course.sections[0].free).toBe(true);
    expect(body.course.sections[1].free).toBe(false);
    expect(body.creator).toEqual({ slug: "jane-doe", name: "Jane Doe", title: "Historian", photo_url: "https://x/y.jpg", links: { website: "https://jane.example" }, verified: false });
    expect(body.creator).not.toHaveProperty("country");
  });
  it("keeps the app course id for an update", () => {
    const body = toPublishBody(good, "fr", { slug: "a-b", name: "A B" }, { appCourseId: "course_310_antikythera" });
    expect(body.course.id).toBe("course_310_antikythera");
  });
  it("refuses an unknown language", () => {
    expect(() => toPublishBody(good, "xx", { slug: "a-b", name: "A B" })).toThrow();
  });
});
