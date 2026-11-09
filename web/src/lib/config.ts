/** Réglages du site, modifiables par variables d'environnement au moment du build. */

/** Lien unique de téléchargement (redirige vers l'App Store ou Google Play selon l'appareil). */
export const DOWNLOAD_URL = process.env.NEXT_PUBLIC_DOWNLOAD_URL ?? "https://taap.it/sophia";

export const links = {
  download: DOWNLOAD_URL,
  /** Mentions légales et support (valeurs de la fiche App Store). */
  support: "http://vikstudios.com",
  privacy: "http://vikstudios.com",
  terms: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
};

export type PlanId = "annuel" | "mensuel";

/**
 * Offres affichées sur le site (prix France TTC de l'App Store, voir PLAN.md).
 * Le paiement web se fait sur une page de paiement externe (RevenueCat Web Billing ou Stripe Checkout) :
 * renseigner NEXT_PUBLIC_CHECKOUT_URL_ANNUEL et NEXT_PUBLIC_CHECKOUT_URL_MENSUEL.
 */
export const plans: Record<PlanId, {
  id: PlanId;
  name: string;
  price: string;
  period: string;
  perMonth: string;
  trialDays: number;
  badge?: string;
  checkoutUrl: string | undefined;
}> = {
  annuel: {
    id: "annuel",
    name: "Annuel",
    price: "39,99 €",
    period: "par an",
    perMonth: "3,33 € par mois",
    trialDays: 3,
    badge: "Le plus choisi",
    checkoutUrl: process.env.NEXT_PUBLIC_CHECKOUT_URL_ANNUEL,
  },
  mensuel: {
    id: "mensuel",
    name: "Mensuel",
    price: "9,99 €",
    period: "par mois",
    perMonth: "9,99 € par mois",
    trialDays: 3,
    checkoutUrl: process.env.NEXT_PUBLIC_CHECKOUT_URL_MENSUEL,
  },
};

/** Adresse du site (balises de partage). */
export const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? "https://sophia-culture.com";
