# R1 — notes de livraison et de test

Version R1 = les changements de code prévus au § 8 de `docs/plan-ab-tests-prix.md`, livrés sur la
branche `claude/revenue-cat-mcp-connexion-orffsf` le 27/09/2026 en huit commits (cinq iOS, un
Android, deux de préparation). **Aucune compilation n'a été possible dans l'environnement de
travail** (pas de toolchain Swift ni de SDK Android) : les diffs ont été relus et vérifiés
statiquement (équilibre des accolades, symboles renommés, appels mis à jour), mais un build
Xcode et un build Gradle sont le premier point de la QA.

## Ce que R1 change, en une ligne chacun

| # | Changement | iOS | Android |
| --- | --- | --- | --- |
| 1 | Les paywalls quiz / cours / entraînement vendent et déclarent l'offering servie par RevenueCat (celle que les expériences remplacent), repli sur l'offering du contexte | `StoreViewModel.displayedOffering(forContextIdentifier:)`, attribution via `presentedOfferingContext` | `StoreViewModel.displayedOffering()`, `offeringIdOf()` |
| 2 | Plus de prix de repli codé en dur : « … » tant que le store n'a pas répondu, pas de badge « -58 % » mémorisé ; sous-titre de rétention FR sans « 39,99 € » | `StoreViewModel.unknownPrice`, 130 clés retirées | `StoreViewModel.UNKNOWN_PRICE`, badge discount optionnel |
| 3 | Plan court mensuel **ou** hebdo (`$rc_weekly`) sur le paywall comparatif, prix de l'annuel par semaine face à un hebdo, badge d'économie sur 52 périodes, libellés hebdo dans 26 langues | `shortPlanPackage`, `PaywallPriceDisplay.yearlyPerShortPeriod` | `shortPlanPackage()`, `perWeekLabel()` |
| 4 | Test discount côté app : bucket A/B tiré une fois par installation, attribut RevenueCat `discount_bucket`, propriété Mixpanel, offering `offre_discount` (A) ou `offre_discount_2999` (B) | `StoreViewModel.discountBucket`, `promoOffering` | `DiscountBucket`, `promoOffering()` |
| 5 | Durée d'essai lue sur le produit (offre d'introduction) et injectée dans les six textes qui la nomment (`{n}`, `{dayWord}` pour ru/cs/sk), timeline d'onboarding et rappel J-1 calés dessus | `trialDays(for:)`, `AppLocalizable.trialString` | `trialDays()`, `StringStore.trialText`, `TrialReminderScheduler(assumedTrialDays:)` |

Prérequis RevenueCat créés par R1 pour la vague 2 : une offering `offre_discount_2999`
(package `$rc_annual` → `discount_yearly_2999`) et, dans les offerings variantes hebdo, un
package `$rc_weekly` à la place de `$rc_monthly`. Tant qu'elles n'existent pas, l'app se
comporte exactement comme avant (repli sur `offre_discount`, mensuel affiché).

## Deux points à confirmer au premier build

- iOS : `Purchases.shared.attribution.setAttributes([String: String])` et
  `Package.presentedOfferingContext.offeringIdentifier` (SDK 5.81.1 : les deux existent, à
  confirmer par le compilateur).
- Android : `Package.presentedOfferingContext.offeringIdentifier`, `Offering.weekly`,
  `SubscriptionOption.freePhase?.billingPeriod` (SDK 9.26.1).

## QA sur appareil (sandbox), par override d'offering dans RevenueCat

Pour chaque ligne : *Customer → Offering override* sur le compte de test, relancer l'app,
vérifier le paywall d'onboarding **et** un paywall de contexte (ouvrir un quiz).

| Offering servie | Attendu partout | Attendu en plus |
| --- | --- | --- |
| `fin_onboarding` (contrôle) | prix annuel 39,99 €, mensuel 9,99 €, « 3 jours » dans les textes | inchangé par rapport à la version en prod |
| `p__5999` / `a1__5999_*` | **59,99 € affiché et 59,99 € facturé**, aussi sur le paywall quiz et le paywall cours | l'achat apparaît attribué à l'offering `p__5999` dans RevenueCat |
| `s__3999_mnotrial` | carte mensuelle sans badge d'essai, CTA « S'abonner » quand le mensuel est sélectionné | annuel toujours avec essai |
| offering avec `$rc_weekly` | carte « Hebdomadaire · facturé chaque semaine · 6,99 € », annuel affiché « 0,77 € / semaine », badge « -89 % » | achat hebdo possible, pas de mention d'essai |
| produit annuel à 7 jours d'essai | « Essaie 7 jours gratuitement », « 7 jours offerts », timeline « Jour 6 : rappel / Jour 7 : fin », date de fin à J+7 | ru / cs / sk : « 7 дней », « 7 dní », « 7 dní » |
| bucket B (forcer `sophia_discount_bucket = B` dans UserDefaults / SharedPreferences) | paywall discount à 29,99 € si `offre_discount_2999` existe, badge « -25 % », sinon 19,99 € | attribut `discount_bucket = B` visible sur le client RevenueCat |
| réseau coupé au premier lancement | prix « … », aucune mention « facturé … », pas de badge | le bouton recharge les offres au lieu de rester mort |

Après la QA : sur chaque expérience RevenueCat, « Paywall viewers » doit monter pour les
utilisateurs de R1 (impressions déclarées sur l'offering servie).

## Hors périmètre de R1

Placements RevenueCat (inutiles avec le point 1), mensuel de palier pour la Türkiye, écran de
rétention (inchangé), version et numéro de build (à incrémenter à la soumission).
