import type { MetadataRoute } from "next";
import { SITE_URL } from "@/lib/env";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: ["/studio", "/admin", "/auth", "/join"] }],
    sitemap: `${SITE_URL}/sitemap.xml`,
  };
}
