import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Site 100 % statique : déployable partout (Vercel, Netlify, simple hébergement de fichiers).
  output: "export",
  images: { unoptimized: true },
};

export default nextConfig;
