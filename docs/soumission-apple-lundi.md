# Soumission App Store Connect — lundi 28/09/2026

Sept abonnements à créer dans **Mes apps → Sophia → Monétisation → Abonnements → groupe
« Sophia Premium »** (bouton « + » dans le groupe existant, jamais un nouveau groupe). Chaque
produit est une copie de `Sophia_yearly` (ou de `Sophia_monthly` / `discount_yearly` pour les
deux derniers) : seul le prix, et pour deux d'entre eux la durée ou l'essai, changent. Aucun
nouveau binaire : le bouton « Soumettre pour examen » sur chaque produit suffit (1 à 3 jours).

Deux produits déjà approuvés n'ont rien à faire chez Apple : `Sophia_yearly_5999` et
`Sophia_monthly_notrial` (à rattacher à l'entitlement dans RevenueCat seulement).

## 1. Les sept produits

| # | Product ID (exact) | Nom de référence (interne) | Durée | Prix de base, France | Offre d'introduction | Copié de |
| --- | --- | --- | --- | ---: | --- | --- |
| 1 | `Sophia_yearly_4999` | Sophia Premium Annual 49.99 (price test) | 1 an | **49,99 €** | Essai gratuit 3 jours | `Sophia_yearly` |
| 2 | `Sophia_yearly_6999` | Sophia Premium Annual 69.99 (price test) | 1 an | **69,99 €** | Essai gratuit 3 jours | `Sophia_yearly` |
| 3 | `Sophia_yearly_2999` | Sophia Premium Annual 29.99 (price test) | 1 an | **29,99 €** | Essai gratuit 3 jours | `Sophia_yearly` |
| 4 | `Sophia_yearly_t50` | Sophia Premium Annual tier 50 (regional) | 1 an | **19,99 €** | Essai gratuit 3 jours | `Sophia_yearly` |
| 5 | `Sophia_yearly_t25` | Sophia Premium Annual tier 25 (regional) | 1 an | **9,99 €** | Essai gratuit 3 jours | `Sophia_yearly` |
| 6 | `Sophia_weekly_699` | Sophia Premium Weekly 6.99 | **1 semaine** | **6,99 €** | **aucune** | `Sophia_monthly` |
| 7 | `discount_yearly_2999` | Sophia Premium Annual Offer 29.99 | 1 an | **29,99 €** | **aucune** | `discount_yearly` |

Identifiants : respecter la casse exacte (majuscule à `Sophia_`, minuscule à `discount_`). Un
Product ID est définitif, il ne peut ni être renommé ni réutilisé.

## 2. Réglages identiques pour les sept

| Réglage | Valeur |
| --- | --- |
| Groupe d'abonnement | **Sophia Premium** (existant) |
| Niveau dans le groupe | **le même niveau que `Sophia_yearly` et `Sophia_monthly`** (tous les produits donnent le même service ; un niveau différent transformerait les changements de plan en upgrades payants ou laisserait deux abonnements actifs) |
| Disponibilité | tous les pays ou régions (175), case « Rendre disponible dans les nouveaux pays » cochée |
| Prix | onglet Prix → « Ajouter un prix » → pays de base **France** → prix du tableau → laisser Apple générer les autres storefronts. Pour #4 et #5, vérifier ensuite Türkiye, Mexique, Brésil, Inde (attendu ≈ 999,99 TRY et 499,99 TRY) et corriger le storefront à la main si Apple s'écarte de 50 % / 25 % |
| Offre d'introduction (#1 à #5) | « + » → tous les pays → type **Gratuit** → durée **3 jours** → sans date de fin → nouveaux abonnés |
| Partage familial | même réglage que `Sophia_yearly` (désactivé) |
| Informations pour l'examen | même capture d'écran que `Sophia_yearly` (paywall avec les prix StoreKit chargés) + les notes du § 4 |
| Catégorie fiscale, conformité | identiques aux produits existants (héritées du groupe) |

## 3. Localisations (nom affiché / description), 12 langues

À saisir sans espace avant ni après. Mêmes descriptions que `Sophia_yearly_5999`.

### Produits annuels #1 à #5

| Langue | Nom affiché | Description |
| --- | --- | --- |
| fr-FR | Sophia Premium Annuel | Débloque tout le contenu premium de Sophia |
| en-US | Sophia Premium Annual | Unlocks all of Sophia's premium features |
| en-GB | Sophia Premium Annual | Unlocks all of Sophia's premium features |
| en-CA | Sophia Premium Annual | Unlocks all of Sophia's premium features |
| en-AU | Sophia Premium Annual | Unlocks all of Sophia's premium features |
| de-DE | Sophia Premium Jährlich | Alle Premium-Funktionen von Sophia |
| es-ES | Sophia Premium Anual | Desbloquea el contenido premium de Sophia |
| es-MX | Sophia Premium Anual | Desbloquea el contenido premium de Sophia |
| it | Sophia Premium Annuale | Sblocca il contenuto premium di Sophia |
| pt-PT | Sophia Premium Anual | Desbloqueia o conteúdo premium da Sophia |
| pt-BR | Sophia Premium Anual | Desbloqueia o conteúdo premium da Sophia |
| hu | Sophia Premium Éves | Feloldja a Sophia összes prémium funkcióját |

### Produit hebdomadaire #6

| Langue | Nom affiché | Description |
| --- | --- | --- |
| fr-FR | Sophia Premium Hebdomadaire | Débloque tout le contenu premium de Sophia |
| en-US / en-GB / en-CA / en-AU | Sophia Premium Weekly | Unlocks all of Sophia's premium features |
| de-DE | Sophia Premium Wöchentlich | Alle Premium-Funktionen von Sophia |
| es-ES / es-MX | Sophia Premium Semanal | Desbloquea el contenido premium de Sophia |
| it | Sophia Premium Settimanale | Sblocca il contenuto premium di Sophia |
| pt-PT / pt-BR | Sophia Premium Semanal | Desbloqueia o conteúdo premium da Sophia |
| hu | Sophia Premium Heti | Feloldja a Sophia összes prémium funkcióját |

### Produit discount #7

| Langue | Nom affiché | Description |
| --- | --- | --- |
| fr-FR | Offre Sophia Premium Annuel | Débloque tout le contenu premium de Sophia |
| en-US / en-GB / en-CA / en-AU | Sophia Premium Annual Plan | Unlocks all of Sophia's premium features |
| de-DE | Sophia Premium Jahresangebot | Alle Premium-Funktionen von Sophia |
| es-ES / es-MX | Oferta Sophia Premium Anual | Desbloquea el contenido premium de Sophia |
| it | Offerta Sophia Premium Annuale | Sblocca il contenuto premium di Sophia |
| pt-PT / pt-BR | Oferta Sophia Premium Anual | Desbloqueia o conteúdo premium da Sophia |
| hu | Sophia Premium Éves Ajánlat | Feloldja a Sophia összes prémium funkcióját |

## 4. Notes pour l'examen (à coller telles quelles, en anglais)

- #1, #2, #3 : `Price test variant (<49.99|69.99|29.99> EUR/year) of the existing Sophia Premium annual subscription (Sophia_yearly). Same content and features as the approved annual product, only the price differs. Unlocks all premium courses, quizzes and training.`
- #4, #5 : `Regional price variant (base <19.99|9.99> EUR/year, intended for lower purchasing-power storefronts) of the existing Sophia Premium annual subscription (Sophia_yearly). Same content and features, only the price differs. Unlocks all premium courses, quizzes and training.`
- #6 : `Weekly billing variant of the existing Sophia Premium subscription. Same content and features as the approved monthly product (Sophia_monthly); only the billing period and price differ. No free trial.`
- #7 : `Promotional price variant (29.99 EUR/year, no trial) of the existing Sophia Premium annual offer (discount_yearly). Same content and features, only the price differs.`

## 5. Ordre des opérations, produit par produit

1. Groupe « Sophia Premium » → « + » → Nom de référence + Product ID → Créer.
2. Durée d'abonnement (1 an, ou 1 semaine pour #6).
3. Disponibilité → tous les pays → enregistrer.
4. Prix → Ajouter un prix → France → montant → Suivant → vérifier la grille → Confirmer.
5. Offre d'introduction (#1 à #5 seulement) → Gratuit → 3 jours → tous les pays → sans fin.
6. Localisations → ajouter les 12 langues du § 3.
7. Informations pour l'examen → capture + note du § 4.
8. Enregistrer → **Soumettre pour examen** (en haut à droite du produit).
9. Après les 7 : ouvrir le groupe → « Modifier l'ordre des niveaux » → vérifier que les
   nouveaux produits sont **au même niveau** que `Sophia_yearly` / `Sophia_monthly`.

Temps estimé : 15 minutes par produit, 2 heures en tout. Statut attendu après soumission :
« En attente d'examen », puis « Approuvé » ; c'est ce statut qui déclenche le lancement des tests.

## 6. Ce qui se passe ensuite (pas chez Apple)

- Play Console, le même jour : base plans `p1y-4999`, `p1y-6999`, `p1y-2999`, `p1y-t50`,
  `p1y-t25`, `monthly-notrial`, `weekly-699`, `annual-promo-2999` dans `sophia_pro` (essai 3 j en
  offre sur les annuels), et baisse de `p1y` 47,99 → 39,99 €, `annual-promo` 23,99 → 19,99 €.
- RevenueCat, le même jour : rattacher `Sophia_yearly_5999` et `Sophia_monthly_notrial` à
  `premium`, créer audiences, offerings et expériences en brouillon (§ 6 du plan).
- Le jour de l'approbation Apple : rattacher chaque produit à `premium`, un achat sandbox par
  offering, lancement des cinq tests.
