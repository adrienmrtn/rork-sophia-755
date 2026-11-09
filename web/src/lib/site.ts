import data from "@/data/site.json";

export type Course = (typeof data.subjects)[number]["courses"][number];
export type Subject = (typeof data.subjects)[number];
export type QuizQuestion = (typeof data.quiz)[number];
export type Creator = (typeof data.creators)[number];

export const site = data;

/**
 * Liens des stores. L'identifiant App Store n'est pas dans le repo :
 * renseigner NEXT_PUBLIC_APP_STORE_URL (ex. https://apps.apple.com/fr/app/id0000000000).
 */
export const links = {
  appStore:
    process.env.NEXT_PUBLIC_APP_STORE_URL ??
    "https://apps.apple.com/fr/search?term=Sophia%20culture%20g%C3%A9n%C3%A9rale",
  playStore:
    process.env.NEXT_PUBLIC_PLAY_STORE_URL ??
    "https://play.google.com/store/apps/details?id=app.rork.sophia",
  /** Candidatures auteurs (site actuel). */
  writeForUs: process.env.NEXT_PUBLIC_WRITE_URL ?? "https://sophia-culture.com",
  support: "http://vikstudios.com",
};
