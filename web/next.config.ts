import type { NextConfig } from "next";

/** Le Hub des créateurs vidéo (Lovable, équipe de Maximilien) répondait sur sophia-culture.com
 *  jusqu'au passage du domaine à ce site. Ses adresses en circulation (emails de contrat et de
 *  paiement, pubs, bannière des apps, webhooks) sont renvoyées vers son nouveau domaine ; ses pages
 *  légales viennent ici. Redirections permanentes (308 : la méthode et le corps des POST suivent). */
const HUB = "https://vik-studios-creators.com";
const HUB_REDIRECTS = [
  { source: "/creators", destination: `${HUB}/` },
  { source: "/creators/:path*", destination: `${HUB}/creators/:path*` },
  { source: "/:lang([a-z]{2})/creators/:path*", destination: `${HUB}/:lang/creators/:path*` },
  { source: "/:lang([a-z]{2}-[A-Za-z]{2,4})/creators/:path*", destination: `${HUB}/:lang/creators/:path*` },
  { source: "/fr/createurs/:path*", destination: `${HUB}/fr/creators/:path*` },
  { source: "/fr/candidature-slideshow", destination: `${HUB}/fr/creators/slideshow/apply` },
  { source: "/en/slideshow-application", destination: `${HUB}/en/creators/slideshow/apply` },
  { source: "/payout/:token", destination: `${HUB}/payout/:token` },
  { source: "/poster-unsubscribe", destination: `${HUB}/poster-unsubscribe` },
  { source: "/auth", destination: `${HUB}/auth` },
  { source: "/reset-password", destination: `${HUB}/reset-password` },
  { source: "/account-not-set-up", destination: `${HUB}/account-not-set-up` },
  { source: "/hub", destination: `${HUB}/hub` },
  { source: "/hub/:path*", destination: `${HUB}/hub/:path*` },
  { source: "/api/public/:path*", destination: `${HUB}/api/public/:path*` },
];
const LEGACY_REDIRECTS = [
  { source: "/fr", destination: "/" },
  { source: "/en", destination: "/" },
  { source: "/fr/auteurs", destination: "/write" },
  { source: "/en/auteurs", destination: "/write" },
  { source: "/confidentialite", destination: "/legal/privacy" },
  { source: "/fr/confidentialite", destination: "/legal/privacy" },
  { source: "/en/privacy", destination: "/legal/privacy" },
  { source: "/privacy", destination: "/legal/privacy" },
  { source: "/mentions-legales", destination: "/legal/notice" },
  { source: "/fr/mentions-legales", destination: "/legal/notice" },
  { source: "/en/legal-notice", destination: "/legal/notice" },
  { source: "/legal/terms", destination: "/legal/notice" },
  { source: "/terms", destination: "/legal/notice" },
];

const nextConfig: NextConfig = {
  async redirects() {
    return [...HUB_REDIRECTS, ...LEGACY_REDIRECTS].map((r) => ({ ...r, permanent: true }));
  },
  // Tout le site lit le catalogue à la demande (SSR) : pas de pré-rendu au build, qui n'a pas
  // accès à Supabase ici, et des pages toujours à jour. La mise en cache viendra avec Vercel.
  cacheComponents: false,
  // L'image d'un événement part par une action serveur (1 Mo par défaut).
  experimental: { serverActions: { bodySizeLimit: "8mb" } },
  // Les avatars du Studio sont lus sur disque par l'action chooseAvatar : embarqués avec les fonctions.
  outputFileTracingIncludes: { "/studio/**": ["./public/avatars/**"] },
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
