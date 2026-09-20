# Propositions — reco de cours & offres de rétention

Document de propositions uniquement : rien n'a été modifié dans l'app.
Chiffres tirés de Supabase (`afnmcoovdvbtkgohtdij`, snapshot du 20/09/2026, 114 888 comptes).

---

# 1. Proposer les cours les plus pertinents

## 1.1 Ce qu'il y a aujourd'hui

| Surface | Ce qui décide de l'ordre |
| --- | --- |
| Deck Home (TikTok / Tinder / Legacy) | `HomeDeckBuilder.deck()` → `courses.filter{ !completed }.shuffled()` — **100 % aléatoire, re-tiré à chaque visite** |
| Swipe d'onboarding (5 cartes) | `OnboardingCourseRecommender` — 24 IDs écrits en dur, round-robin par matière |
| Bibliothèque, section « Recommandés » | même fonction, `limit: 10` |
| « À la une » | `CuratedStarterCourses.ids`, liste figée |

Les « intérêts » ne sont jamais demandés : ils sont **déduits de l'objectif** d'onboarding
(`OnboardingV2ViewModel.subjects(for:)`), écrits une fois dans `UserDefaults`, et plus jamais
mis à jour. Ce que la personne lit réellement ensuite ne change rien à ce qu'on lui propose.

Trois conséquences mesurables :

**a) Tout le monde voit les mêmes 5 cartes.** Le round-robin prend l'index 0 de chaque matière,
dans l'ordre de `Subject.allCases`. Avec `limit: 5` et 6 matières, `comprendreLeMonde` n'est
jamais atteint. Les objectifs les plus choisis (`cultivate`, `reduceScreen`) mappent sur *toutes*
les matières → strictement le même deck pour tous.

**b) Le signal « favori » est détruit.** `persistAndComplete()` écrit les likes du swipe
directement dans `favoriteCourseIds`. Résultat :

| Cours | Favoris | % des comptes |
| --- | --- | --- |
| Qu'est-ce qu'un trou noir | 71 025 | 61,8 % |
| La Nuit étoilée, Van Gogh | 66 278 | 57,7 % |
| Romulus et Rémus | 58 508 | 50,9 % |
| Le Mythe de Sisyphe, Camus | 55 914 | 48,7 % |
| Napoléon à Ulm | 43 329 | 37,7 % |
| *(6ᵉ)* Pourquoi rêve-t-on | **1 471** | 1,3 % |

Ce sont exactement les 5 cartes du swipe. **77,6 % de tous les favoris de la base** sont un
artefact de l'onboarding, pas une préférence. Le seul signal explicite de goût est inutilisable
en l'état.

**c) Il n'y a aucun log d'impression.** Le swipe gauche/droite (`commitSwipeLeft/Right`) et le
scroll TikTok n'alimentent que `discountManager.registerSwipe()`. Rien dans Mixpanel, rien dans
Supabase. Le signal le plus riche de l'app — « on lui a montré ce cours et il a passé » — est jeté.
`course_session_ended` (durée, `engagement_tier`, `exit_reason`) existe mais ne part que dans
Mixpanel, donc inexploitable en requête.

Et comme un gratuit n'a **qu'un cours par jour** (`FreemiumGate`), la première carte du deck est
une loterie qui décide de sa journée — et de sa conversion.

## 1.2 Ce que disent les données

**Le volume est là.** 70 023 comptes ont lu ≥ 1 cours, 39 590 ≥ 2, 22 018 ≥ 3 (moyenne 1,62).
186 204 lectures au total, réparties sur les 239 cours — **aucun cours sous 100 lecteurs**, le
top 20 ne pèse que 26,4 % des lectures.

**Le feed aléatoire est un cadeau.** C'est un log d'exposition non biaisé : pas de biais de
popularité à défaire, et une baseline A/B triviale. À exposition égale, l'écart de demande est
réel :

| Matière | Lectures / cours | Complétion |
| --- | --- | --- |
| sciences | 1 568 | 57,3 % |
| comprendreLeMonde | 834 | 55,2 % |
| histoire | 712 | 51,9 % |
| littérature | 543 | 53,5 % |
| art | 542 | 54,5 % |
| mythologie | 467 | 55,1 % |

Sciences fait **3,4×** mythologie sans avantage d'exposition.

**Le signal item-item existe déjà, et il est fort.** Lift de co-lecture (support ≥ 50) :

| Paire | Lift |
| --- | --- |
| Stalingrad × Blitzkrieg | 14,3× |
| La République × L'Apologie de Socrate (Platon) | 11,9× |
| Rosa Parks × Marie Curie | 10,3× |
| Pénicilline × Structure de l'ADN | 8,7× |
| L'Odyssée × L'Iliade | 7,7× |
| Pétrole & conflits × Prix du pétrole | 6,0× |

Un simple modèle de co-lecture battrait le hasard **aujourd'hui, sans ML**.

**La qualité des cours varie beaucoup** : 68,4 % de complétion sur « Pourquoi bâille-t-on »
contre 36,3 % sur « Napoléon à Ulm »… qui est justement la carte n°1 imposée à tout le monde en
histoire.

## 1.3 Proposition

### Étape 0 — Logguer (prérequis, ~1 j)

Sans impressions, pas d'exemples négatifs, donc pas de modèle. Le reste en dépend.

- Table Supabase `course_events (user_id, course_id, surface, action, dwell_ms, position, ts)`
  avec `action ∈ {impression, open, complete, skip, save, quiz_done}`. Envoi par batch.
- Découpler les likes d'onboarding des favoris : `onboardingLikedCourseIds` séparé de
  `favoriteCourseIds`. (Les 5 IDs pollués sont identifiables et nettoyables rétroactivement.)
- Reconnecter le MCP Mixpanel sur `mcp-eu.mixpanel.com` — le projet « Sophia ios » est en EU,
  je n'ai pas pu tirer les funnels d'ici.

### Étape 1 — Modèle de co-lecture côté serveur (~2–3 j)

- Job SQL nocturne → table `course_neighbors (course_id, neighbor_id, score)`, top 20 voisins
  par cours (~4 800 lignes). La requête de lift ci-dessus est déjà écrite, elle tourne en
  quelques secondes.
- L'app télécharge cette table au lancement et range le deck localement :

  ```
  score(c) =  w₁ · affinité_matière(user)          // lectures/complétions réelles, pas l'objectif
            + w₂ · max voisinage(c, N derniers lus)
            + w₃ · qualité(c)                      // complétion observée, prior bayésien
            − w₄ · fatigue(c)                      // impressions sans ouverture, avec decay
  ```

- **Garder 20–30 % d'aléatoire** dans le deck. C'est ce qui maintient le log non biaisé et
  permet de continuer à apprendre. On réduit le hasard, on ne le supprime pas.
- Cold start (le cas majoritaire — 1,62 cours lus en moyenne) : les 3 premières cartes = les
  meilleurs cours **par complétion observée** dans les matières de l'objectif, pas une liste
  écrite en dur. Un cours à 36 % de complétion n'a rien à faire en carte n°1.

### Étape 2 — Apprentissage (après 4–6 semaines de log)

Régression logistique ou gradient boosting sur (features user, features cours, contexte) →
P(ouverture) et P(complétion), recalculé en batch, servi via la même table. Inutile d'y aller
avant : sans impressions il n'y a pas de négatifs, et le modèle n'apprendrait que la popularité.

### Mesure

A/B par feature flag serveur. Primaire : **cours complétés par session**. Secondaires :
lectures/DAU, D7, conversion paywall. La baseline est mesurable immédiatement puisque le
comportement actuel *est* le bras de contrôle.

---

# 2. Offres de rétention à l'annulation

## 2.1 La contrainte

L'app **ne peut pas intercepter** l'annulation : elle se fait dans Réglages › Abonnements, hors
de l'app. Pas de « Vous êtes sûr ? » maison par-dessus l'écran Apple. Quatre leviers réels :

**a) Sortie maison, avant de renvoyer vers Apple** — ~1–2 j, aucune dépendance.
Aujourd'hui `SettingsView` n'a même pas de ligne « Gérer mon abonnement », et
`showManageSubscriptions` n'est appelé nulle part. Ajouter la ligne → écran maison « Tu es sûr de
vouloir partir ? » (streak, XP, cours finis, cours en cours) + offre → *ensuite seulement*
`AppStore.showManageSubscriptions`. N'attrape que ceux qui passent par l'app.

**b) RevenueCat Customer Center** — le meilleur rapport effort/résultat vu la stack
(RevenueCat + RevenueCatUI sont déjà intégrés). Écran drop-in (iOS 15+) : sondage d'annulation
puis promotional offer Apple servie automatiquement selon la réponse — « trop cher » → offre
prix, « acheté par erreur » → refund. Tout se configure depuis le dashboard
(Lifecycle → Retention), pas dans le code. Prérequis : créer les promotional offers dans App
Store Connect.

**c) Apple Retention Messaging API** — c'est le « depuis Apple » de ta question, et **le seul
levier qui attrape les gens qui annulent depuis Réglages iOS**. Apple affiche ton message sur
son propre écran de confirmation d'annulation : texte, texte + image, proposition de changement
de plan, ou promotional offer. Supporté par RevenueCat (ciblage, traductions, reporting de save
rate). Contraintes : accès à demander à Apple (pre-release), **textes pré-approuvés par Apple —
donc aucune personnalisation au runtime**, titre ≤ 66 car., sous-titre ≤ 144 car., image
3840 × 2160 PNG sans transparence.

**d) Win-back offers** (iOS 18+, StoreKit 2) — pour ceux déjà partis. Apple les pousse aussi sur
l'App Store, hors de l'app. Éligibilité paramétrable (durée d'abonnement passé, temps écoulé
depuis la fin, temps depuis le dernier win-back). Le SDK RevenueCat les présente automatiquement.
Le produit doit avoir été approuvé par App Review.

## 2.2 Le prix : attention à l'échelle

Grille actuelle : **39,99 €/an** (essai 3 j) · **9,99 €/mois** · **19,99 €/an** en promo flash —
promo qui se redéclenche *tous les jours* pour les gratuits (`DiscountOfferManager` : 3 swipes →
cadeau → 60 min). Ajouter 15 € donne une échelle 39,99 → 19,99 → 15. Deux risques :

1. L'ancre réelle est déjà 19,99 pour beaucoup : 15 € n'est plus un −62 %, c'est un −25 %.
2. Une offre de rétention systématique s'apprend vite — annuler devient le moyen d'obtenir le
   prix bas.

Proposition :

- Promotional offer Apple **« renouvellement à 14,99 € la première année, puis plein tarif »**,
  pay-up-front, **une seule fois par compte**, et **réservée aux profils qui ont de l'usage**
  (≥ 3 cours lus, ou streak > n). Pour les autres, le rabais ne sauve rien.
- Segmenter par motif du sondage : « trop cher » → offre prix ; **« je ne l'utilise pas assez » →
  surtout pas un rabais**, mais une pause d'un mois ou un passage annuel → mensuel.
- Mesurer le save rate par motif, et surtout la **LTV à 12 mois du groupe sauvé vs un groupe
  témoin sans offre**. Sans témoin, on ne sait pas si on a sauvé un client ou bradé un
  renouvellement qui aurait eu lieu de toute façon.

---

# 3. Ordre suggéré

| # | Chantier | Effort | Débloque |
| --- | --- | --- | --- |
| 1 | Log d'impressions + découplage favoris/onboarding | ~1 j | tout le reste |
| 2 | « Gérer mon abonnement » + écran de sortie maison | 1–2 j | premières saves, mesurables |
| 3 | `course_neighbors` + scoring du deck, A/B vs aléatoire | 2–3 j | le vrai gain produit |
| 4 | Customer Center + promotional offers App Store Connect | 2–3 j | saves automatisées |
| 5 | Demande d'accès Retention Messaging API à Apple | à lancer **maintenant** | le délai court en parallèle |
| 6 | Win-back offers | 1 j | récupération des partis |
| 7 | Modèle appris sur les impressions | après 4–6 sem. | |

---

## Sources

- [Customer Center — RevenueCat](https://www.revenuecat.com/docs/tools/customer-center)
- [Configuring Apple Promotional Offers for Customer Center](https://www.revenuecat.com/docs/tools/customer-center/customer-center-promo-offers-apple)
- [Apple Retention Messaging API — RevenueCat](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-retention-messaging-api)
- [The beginner's guide to Apple win-back offers](https://www.revenuecat.com/blog/growth/guide-to-apple-win-back-offers)
- [iOS Subscription Offers — RevenueCat](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers/ios-subscription-offers)
