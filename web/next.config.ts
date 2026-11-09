import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Tout le site lit le catalogue à la demande (SSR) : pas de pré-rendu au build, qui n'a pas
  // accès à Supabase ici, et des pages toujours à jour. La mise en cache viendra avec Vercel.
  cacheComponents: false,
  // L'image d'un événement part par une action serveur (1 Mo par défaut).
  experimental: { serverActions: { bodySizeLimit: "8mb" } },
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "afnmcoovdvbtkgohtdij.supabase.co" },
      { protocol: "https", hostname: "upload.wikimedia.org" },
    ],
  },
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
