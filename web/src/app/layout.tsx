import type { Metadata, Viewport } from "next";
import { Bricolage_Grotesque, Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const bricolage = Bricolage_Grotesque({
  subsets: ["latin"],
  variable: "--font-bricolage",
  weight: ["600", "700", "800"],
  display: "swap",
});

const jakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-jakarta",
  weight: ["400", "500", "600", "700", "800"],
  display: "swap",
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://sophia-culture.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "Sophia : moins de scroll, plus de culture",
  description:
    "Des cours de 10 minutes écrits par des profs, un quiz pour que ça reste et un bloqueur d'apps pour tenir le rythme. Histoire, sciences, littérature, art, mythologie et géopolitique.",
  openGraph: {
    title: "Sophia : moins de scroll, plus de culture",
    description:
      "10 minutes par jour pour comprendre le monde. Des cours écrits par des profs, des quiz, et un bloqueur d'apps.",
    locale: "fr_FR",
    type: "website",
    images: ["/img/collections/collection_l_epopee_d_ulysse.webp"],
  },
};

export const viewport: Viewport = {
  themeColor: "#845eed",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr" className={`${bricolage.variable} ${jakarta.variable}`}>
      <body>{children}</body>
    </html>
  );
}
