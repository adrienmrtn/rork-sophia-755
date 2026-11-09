import type { Metadata, Viewport } from "next";
import { Newsreader, Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const jakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-jakarta",
  weight: ["400", "500", "600", "700", "800"],
  display: "swap",
});

const newsreader = Newsreader({
  subsets: ["latin"],
  variable: "--font-newsreader",
  weight: ["400", "500", "600"],
  style: ["normal", "italic"],
  display: "swap",
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://sophia-culture.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "Sophia : moins de scroll, plus de culture",
  description:
    "Chaque jour, un cours de 10 minutes écrit par un spécialiste, un quiz pour retenir l'essentiel, et un bloqueur d'apps pour tenir le rythme.",
  openGraph: {
    title: "Sophia : moins de scroll, plus de culture",
    description: "Chaque jour, un cours de 10 minutes écrit par un spécialiste. Histoire, sciences, littérature, art, mythologie, géopolitique.",
    locale: "fr_FR",
    type: "website",
    images: ["/img/collections/collection_l_epopee_d_ulysse.webp"],
  },
};

export const viewport: Viewport = {
  themeColor: "#fbf7ef",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr" className={`${jakarta.variable} ${newsreader.variable}`}>
      <body>{children}</body>
    </html>
  );
}
