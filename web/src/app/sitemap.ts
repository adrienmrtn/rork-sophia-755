import type { MetadataRoute } from "next";
import { catalog } from "@/lib/catalog/source";
import { authorPath, coursePath } from "@/lib/catalog/slugs";
import { SITE_URL } from "@/lib/env";

export const dynamic = "force-dynamic";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [courses, creators] = await Promise.all([catalog.listCourses("en"), catalog.listCreators("en")]);
  const staticPages = ["", "/courses", "/authors", "/write", "/about"].map((p) => ({ url: `${SITE_URL}${p}`, changeFrequency: "weekly" as const, priority: p === "" ? 1 : 0.7 }));
  return [
    ...staticPages,
    ...courses.map((c) => ({ url: `${SITE_URL}${coursePath(c)}`, changeFrequency: "monthly" as const, priority: 0.8 })),
    ...creators.filter((c) => c.courseIds.length).map((c) => ({ url: `${SITE_URL}${authorPath(c.slug)}`, changeFrequency: "monthly" as const, priority: 0.6 })),
  ];
}
