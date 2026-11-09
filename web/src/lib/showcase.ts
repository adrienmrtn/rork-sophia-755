import data from "@/data/showcase.json";

/** Petit extrait du catalogue, assez léger pour les composants interactifs (envoyé au navigateur). */
export const showcase = data;
export type ShowcaseCard = (typeof data.heroFeed)[number];
