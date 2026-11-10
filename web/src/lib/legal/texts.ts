/** Les textes légaux du site, en Markdown (rendus par renderMarkdown). Le Hub de Lovable n'en avait
 *  que des gabarits « TO BE COMPLETED » ; ceux-ci décrivent ce que le site, le Studio et les apps
 *  font réellement. Les champs d'identification de la société, vides tant qu'Adrien ne les a pas
 *  renseignés, ne s'affichent pas. */

export const LEGAL_CONTACT = "maximilien@vikstudios.com";
export const CREATORS_HUB_URL = "https://vik-studios-creators.com";

/** À renseigner par l'équipe ; une ligne vide n'est pas affichée. */
const COMPANY = {
  name: "Vik Studios SAS",
  registeredOffice: "",
  siren: "",
  vat: "",
  shareCapital: "",
  publicationDirector: "",
};

const LAST_UPDATED = "10 November 2026";

function companyLines(): string {
  const lines = [
    `**Publisher**: ${COMPANY.name}, a simplified joint-stock company under French law, publisher of the website sophia-culture.com, of the authors' Studio and of the Sophia mobile apps.`,
    COMPANY.registeredOffice && `**Registered office**: ${COMPANY.registeredOffice}.`,
    COMPANY.siren && `**Company number**: ${COMPANY.siren}.`,
    COMPANY.vat && `**EU VAT number**: ${COMPANY.vat}.`,
    COMPANY.shareCapital && `**Share capital**: ${COMPANY.shareCapital}.`,
    COMPANY.publicationDirector && `**Publication director**: ${COMPANY.publicationDirector}.`,
    `**Contact**: ${LEGAL_CONTACT}.`,
  ];
  return lines.filter(Boolean).join("\n\n");
}

export const NOTICE_MD = `
*Last updated ${LAST_UPDATED}.*

## Publisher

${companyLines()}

## Hosting

The website is hosted by Vercel Inc., 440 N Barranca Avenue #4133, Covina, CA 91723, United States.

Accounts, course data and files are stored with Supabase Inc., 970 Toa Payoh North #07-04, Singapore 318992, on servers it operates for us.

## Intellectual property

The courses, quizzes, glossaries, images, texts, trademarks, logos and interfaces of the website and of the Sophia apps are protected by copyright and trademark law. They belong to ${COMPANY.name} or to the authors who wrote them: an author keeps the copyright on a course and grants ${COMPANY.name} the right to publish and translate it, under the creator agreement published on this site. Images from Wikimedia Commons are reproduced under their own licence, credited on each course.

No part of the website or of the apps may be reproduced or redistributed without written permission, except for private use and short quotations with attribution.

## Video creators

The programme for video creators (UGC and slideshows) is run on a separate site, ${CREATORS_HUB_URL}, with its own terms.

## Name

Sophia: General Knowledge is a mobile learning app. It has no connection with the Sophia humanoid robot, with Sophia University in Tokyo, or with the sophia health programme run by France's Assurance Maladie.
`.trim();

export const PRIVACY_MD = `
*Last updated ${LAST_UPDATED}.*

This policy explains what ${COMPANY.name} (“we”) does with personal data on the website sophia-culture.com, in the authors' Studio on that site, and in the Sophia apps for iPhone and Android. For questions or to exercise your rights, write to ${LEGAL_CONTACT}.

## What we collect, and why

**Your account.** You sign in with Apple, Google or an email address. We keep the email address, the sign-in provider and a public handle. We need them to run your account (performance of the contract).

**Reading in the apps.** Your progress, the courses you finished, liked or saved, the authors you follow, and your quiz answers, so that the app remembers where you are and brings your progress back on a new phone. The apps also send usage events: which courses were shown, opened, read and finished, and quiz answers, with the app version, the language of the app, the platform and the country of the phone. They let us run the feed, give each author the reading statistics of their courses, and improve the catalogue (legitimate interest). They never contain your name or your email address, and they are kept raw for 90 days, then only as aggregated figures per course.

**Subscription.** Premium subscriptions are sold by Apple and Google and managed with RevenueCat. We receive your subscription status (free, trial, paid) and an anonymous subscriber identifier. We never see your card or your payment details.

**Authors' Studio.** If you create an author account, we keep the name, title, institution, biography and photo you give us (name, title and photo are shown publicly on your courses and on your author page), your course drafts, the creator agreement you signed online (with its version and the date), and the information needed to pay you. Payments are made by bank transfer, by the means agreed with the team.

**Email.** We write to you only about your account, your courses and their review, and about events in the app. Every message about events carries an unsubscribe link.

**Technical data.** Our hosts keep server logs (IP address, browser, pages requested) for security and to keep the service running. The website sets only the cookies needed to keep you signed in. It uses no advertising tracker and no analytics cookie.

## How long we keep it

Your account and its data stay while the account exists. You can delete your account at any time from the app (Profile, Settings, Delete my account) or by writing to us; deletion removes your account, your progress and your usage events. Raw usage events are kept for 90 days. The aggregated statistics of a course (number of readers per day, by language) carry no identifier and are kept. An author's signed agreement and payment records are kept as long as the law requires for accounting.

## Who processes the data for us

Supabase (database, authentication and file storage), Vercel (website hosting), RevenueCat (subscription status), Apple and Google (sign-in and app distribution), and an email delivery service for the messages we send you. Some of these providers are established outside the European Union; each one is bound by a data processing agreement and by the safeguards required by the GDPR. We do not sell personal data and we share none of it with advertisers.

## Your rights

Under the General Data Protection Regulation you can access the data we hold about you, correct it, have it deleted, object to its processing, restrict it or receive a copy of it. Write to ${LEGAL_CONTACT}; we answer within one month. You can also complain to the CNIL (Commission nationale de l'informatique et des libertés), the French data protection authority.

## Children

The apps and the Studio are not meant for children under 15. If you believe a child gave us personal data, write to us and we will delete it.

## Changes

We update this page when our practices change; the date at the top tells you when. Significant changes are announced in the app or by email.
`.trim();
