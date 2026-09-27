# Propositions — reco de cours & offres de rétention

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

## 1.3 Ce qui est livré

Des **quotas, jamais de filtre**. Aucune matière n'est exclue, quel que soit l'objectif.

### Les parts de matière

Dérivées du nombre de finishers par cours — sous exposition uniforme, c'est
`P(ouvre × termine)`, exactement ce qu'une première carte doit maximiser :

| | sciences | comprendreLeMonde | histoire | art | littérature | mythologie |
| --- | --- | --- | --- | --- | --- | --- |
| Part de base | **35,3 %** | 17,8 % | 14,3 % | 11,4 % | 11,2 % | 9,9 % |

Puis déformées par le comportement réel :

```
poids(m) = base(m) × (1 + 1,5 × affinité(m))      plancher 5 % par matière
affinité = part des cours finis dans m − part attendue, bornée à ±1
```

Un lecteur qui ne termine que des sciences monte à 57,5 % de sciences, et la
mythologie tient quand même son plancher à 7 %. **Le plancher compte** : sans lui une
matière disparaît, on n'apprend plus rien dessus, et 40 cours meurent. Il est appliqué
en une passe exacte (les matières au-dessus paient au prorata), pas par un
`max(poids, 5 %)` suivi d'une renormalisation qui les ferait repasser dessous.

L'objectif d'onboarding **ne filtre plus rien** : +20 % sur ses matières, et il
s'efface dès 3 cours terminés.

### Le cours dans la matière tirée

```
score(c) = qualité(c) + voisinage(c) − fatigue(c)
```

- `qualité` : finishers observés, normalisés **à l'intérieur de la matière** — les
  poids portent déjà la préférence entre matières, la compter deux fois empêcherait
  les humanités de gagner un créneau que le quota venait de leur donner ;
- `voisinage` : meilleur lift avec les 5 derniers cours lus, dans les deux sens (les
  listes sont tronquées aux 8 meilleurs, A peut être chez B sans que B soit chez A) ;
- `fatigue` : cartes montrées et passées, plafonnée — on rétrograde, on ne bannit pas.

### L'ordre : un motif, pas un tri

Trier par score donnerait dix cartes de sciences d'affilée. Les matières sont tirées
au poids, **jamais trois fois de suite**, et une carte sur quatre est tirée au hasard
hors matière dominante.

Cette exploration dilue le quota : **28 % de sciences sur les 20 premières cartes**,
contre 35 % de quota brut et 16,7 % pour le shuffle qu'elle remplace. C'est le prix à
payer pour que le log reste non biaisé — sans quoi le prochain rafraîchissement du
modèle serait entraîné sur ses propres recommandations.

### Les fichiers

| Fichier | Rôle |
| --- | --- |
| `supabase/queries/course_quality.sql`, `course_neighbours.sql` | les deux exports à lancer dans l'éditeur SQL |
| `scripts/data/*.csv` | l'export commité, pour que la régénération soit reproductible |
| `scripts/build_course_affinity.py` | génère le Swift à partir des CSV |
| `ios/Sophia/Utilities/CourseAffinity.swift` | **généré** — 238 cours notés, 228 avec voisins (lift ≥ ×2) |
| `ios/Sophia/Utilities/HomeDeckBuilder.swift` | l'algo (quotas, score, motif) |
| `ios/Sophia/Utilities/DeckContextBuilder.swift` | lit les signaux dans `ProgressManager` |
| `ios/Sophia/Utilities/DeckSkipStore.swift` | compte les cartes montrées et passées |
| `ios/Sophia/Utilities/OnboardingCourseRecommender.swift` | les 24 IDs en dur remplacés par le même modèle |

Zéro backend, zéro migration. À régénérer une fois par mois :
`python3 scripts/build_course_affinity.py`.

### Ce qui reste à faire

Le modèle est **figé** : il ne s'améliore pas tout seul. `DeckSkipStore` est la moitié
bon marché du log d'impressions — local, par appareil, non synchronisé. La moitié utile
reste une table `course_events` côté Supabase. Sans elle, pas d'exemples négatifs,
donc pas de modèle appris.

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

**b) Servir l'offre promotionnelle Apple depuis les paywalls natifs** — c'est ce qui est
livré. Les paywalls de l'app sont natifs, pas des templates RevenueCat, donc **Customer
Center est inutile** : le SDK ne sert qu'à signer l'offre côté serveur, aucune UI n'est
imposée. `SophiaRetentionPaywall` est le 6ᵉ paywall natif, dans le même fichier et le même
dispatcher que les cinq autres. Customer Center resterait utile pour une seule chose — le
motif d'annulation — mais un sondage maison à trois boutons le donne aussi.

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

**Ce que fait une offre, exactement.** Annuler ne rembourse rien : c'est couper le renouvellement
automatique. L'accès court jusqu'à `expirationDate`, le paiement déjà encaissé reste encaissé, et
seul Apple peut rembourser (reportaproblem.apple.com, à sa discrétion). Une offre promotionnelle
redéemée sur **le même produit** s'applique **au renouvellement suivant**, sans débit immédiat.

Conséquence directe, et elle commande tout le reste : sur un **annuel** annulé au jour 4, l'offre
ne sauve rien aujourd'hui — elle brade un renouvellement qui est à 361 jours. Sur un **mensuel**,
le prochain paiement est à ≤ 30 jours : c'est là que l'offre mord. Le seul cas où elle est le bon
geste immédiat sur un annuel, c'est l'annulation **pendant l'essai** : rien n'a été débité, l'essai
continue et se facture au prix de l'offre à son terme (comportement à confirmer en sandbox,
chantier 10 — s'il débitait tout de suite il couperait l'essai et prendrait l'argent).

**Le plancher.** La promo flash est à 19,99 € (`offre_discount` / `discount_yearly` ; 29,99 € dans
le bucket B du test de prix), et elle se redéclenche tous les jours pour les gratuits
(`DiscountOfferManager` : 3 swipes → cadeau → 60 min). La rétention doit passer **sous** ce prix,
sinon elle ne dit rien de neuf à quelqu'un qui l'a déjà vue.

Une offre par produit : elles se rattachent au produit, plusieurs par produit, et le *Promotional
Offer Product Code* n'a pas besoin d'être unique à l'échelle de l'app. Garder **le même code sur
tous les produits** (`retention_annual`, `retention_monthly`) évite de toucher au code : le SDK lit
l'offre portée par le produit servi par l'expérience, et `RetentionOffer.price` vient de
`discount.localizedPriceString`. `retention_14_99` mentirait sur six produits sur sept.

**Annuels** — pay-up-front, 1 an, puis plein tarif. Perte bornée à une année.

| Produit | Plein | Rétention | Écart |
| --- | --- | --- | --- |
| `Sophia_yearly_t25` | 9,99 | 3,99 | −60 % |
| `Sophia_yearly_t50` | 19,99 | 6,99 | −65 % |
| `Sophia_yearly_2999` | 29,99 | 9,99 | −67 % |
| `Sophia_yearly` | 39,99 | 12,99 | −68 % |
| `Sophia_yearly_4999` | 49,99 | 14,99 | −70 % |
| `Sophia_yearly_5999` | 59,99 | 16,99 | −72 % |
| `Sophia_yearly_6999` | 69,99 | 18,99 | −73 % |

Overrides Türkiye à aligner comme pour les produits : `t50` 999,99 → ~349,99 TRY, `t25`
499,99 → ~199,99 TRY, sur les price points Apple réellement disponibles (`price_point()` les résout).

**Mensuels** — pay-as-you-go, retour au plein tarif après. Perte bornée à 15 €.

| Produit | Plein | Rétention | Écart |
| --- | --- | --- | --- |
| `Sophia_monthly` | 9,99 /mois | 4,99 €/mois × 3 mois | −50 % |
| `Sophia_monthly_notrial` | 9,99 /mois | 4,99 €/mois × 3 mois | −50 % |

**Hebdo** (vague 2) — renouvellement à ≤ 7 jours, l'offre mord immédiatement. Perte bornée à 14 €.

| Produit | Plein | Rétention | Écart |
| --- | --- | --- | --- |
| `Sophia_weekly_699` | 6,99 /sem | 3,49 €/sem × 4 semaines | −50 % |

À côté du rabais, l'alternative **« 1 mois offert »** (format *free*, 1 mois) : c'est la réponse au
motif « je ne l'utilise pas assez », pour lequel baisser le prix ne sauve rien. Une pause déguisée,
9,99 € de manque à gagner, et elle n'apprend pas à la personne qu'annuler fait baisser le prix.

Deux risques qui restent :

1. L'ancre réelle est déjà 19,99 pour beaucoup. Une rétention au-dessus n'est pas une offre.
2. Une offre de rétention systématique s'apprend vite — annuler devient le moyen d'obtenir le
   prix bas. D'où : **une seule fois par compte**, et **réservée aux profils qui ont de l'usage**
   (≥ 3 cours lus, ou streak > n). Pour les autres, le rabais ne sauve rien.

Segmenter par motif du sondage : « trop cher » → offre prix ; « je ne l'utilise pas assez » → pause
ou switch, pas de rabais. Et mesurer le save rate par motif **avec un groupe témoin sans offre** :
sans témoin, on ne sait pas si on a sauvé un client ou bradé un renouvellement qui aurait eu lieu.

## 2.3 Le switch mensuel → annuel : le seul levier qui ne dépend pas d'Apple

Pour un mensuel qui annule, « passe à l'annuel » bat le rabais mensuel sur les trois axes.

**L'encaissement.** 39,99 € d'un coup contre 14,97 € étalés sur trois mois, et 12 mois verrouillés
au lieu d'un renouvellement mensuel à reconquérir.

**L'argument.** 9,99 €/mois → 39,99 €/an, c'est **3,33 €/mois, −67 %** sans aucun rabais consenti.
Le plein tarif annuel suffit. `perMonthPrice()` (`StoreViewModel.swift:494`) fabrique déjà la copie.

**La dépendance.** Aucune. Pas d'offre promotionnelle à créer dans App Store Connect, pas de clé
In-App Purchase dans RevenueCat, pas de signature, pas d'App Review, pas d'accès Retention
Messaging à demander. C'est l'achat d'un produit déjà APPROVED. **Tout le reste du chantier 2 est
bloqué côté ASC ; celui-ci est livrable tout de suite.**

La mécanique tombe juste : `appstore_subscriptions.py:419` crée tous les produits au **même
`groupLevel`** que le produit de référence. Mensuel → annuel est donc un **crossgrade de même
niveau, durées différentes → effet au prochain renouvellement**. Pas de débit immédiat, pas de
prorata : au jour 30 la personne est débitée de l'annuel et bascule.

**Le piège.** Ne pas y accrocher l'offre de rétention annuelle : 119,88 €/an → 12,99 €/an. Pour le
switch, c'est le **plein tarif annuel**, et rien d'autre.

## 2.4 Quand montrer quoi

Le déclencheur compte plus que le prix, et une seule règle suffit :

```
offre de prix  si  isInFreeTrial || jours(expiresAt) <= 45
écran de valeur seul  sinon
```

Elle couvre le mensuel en permanence (renouvellement toujours à ≤ 31 jours) et l'annuel seulement
près de l'échéance — sans branche par produit. `expiresAt` est déjà là
(`StoreViewModel.swift:45`, et dans `RetentionSummary`).

Deux conséquences sur le code livré :

- `ContentView.swift:322` tire sur `willNotRenew`, **une fois à vie**, dès la prochaine ouverture.
  Pour l'annuel du jour 4, c'est 361 jours trop tôt et la cartouche est grillée. Il faut deux clés
  (`écran de valeur vu` / `offre de prix vue`) au lieu du booléen `sophia_retention_offer_shown`,
  pour que l'offre puisse revenir près du renouvellement.
- `StoreViewModel.retentionOffer()` (`:330`) part de `annualPackage` en dur. Un abonné **mensuel**
  qui annule se voit donc proposer l'offre de l'**annuel**. Il faut le produit réellement actif :
  `applyCustomerInfo` (`:36-45`) ne stocke pas `entitlement.productIdentifier` — une ligne à
  ajouter, puis chercher le package qui le porte dans l'offering servie.

**La fuite du chemin Réglages.** `SettingsView.swift:339` ouvre le paywall de rétention sur la
ligne « Gérer mon abonnement », et le paywall va chercher l'offre immédiatement. Un mensuel
parfaitement content qui tape cette ligne par curiosité se voit donc offrir −50 %, ou l'annuel à
−67 %. À cet endroit `willNotRenew` est encore `false` : rien ne distingue la curiosité de
l'intention de partir. Le remède est un écran de plus, pas une condition : écran 1 = la valeur
(série, XP, cours finis) et « Continuer la résiliation » ; écran 2 = le save (offre de prix, ou
switch annuel) puis `showManageSubscriptions`. Le rabais reste derrière une intention prouvée, et
l'ordre colle à celui de l'écran Apple.

---

# 3. Où en est chaque chantier

| # | Chantier | État |
| --- | --- | --- |
| 1 | Modèle de deck (quotas + voisins + qualité), 24 IDs en dur supprimés | **livré** |
| 2 | Compteur local des cartes passées (`DeckSkipStore`) | **livré** |
| 3 | Détection `willRenew == false` + paywall de rétention natif | **livré**, bloqué sur l'offre ASC |
| 4 | « Gérer mon abonnement » → paywall → `showManageSubscriptions` | **livré** |
| 5 | **Switch mensuel → annuel au plein tarif** dans le paywall de rétention (§ 2.3) | à faire — **aucune dépendance Apple, livrable tout de suite** |
| 6 | Déclencheur : `isInFreeTrial || jours(expiresAt) <= 45`, deux clés au lieu d'une (§ 2.4) | à faire |
| 7 | `retentionOffer()` sur le produit réellement actif, pas `annualPackage` en dur (§ 2.4) | à faire |
| 8 | Écran 1 valeur / écran 2 save sur le chemin Réglages (§ 2.4) | à faire |
| 9 | 10 offres promotionnelles en ASC (7 annuelles, 2 mensuelles, 1 hebdo) + clé In-App Purchase dans RevenueCat | **à faire côté ASC** — à scripter sur `subscriptionPromotionalOffers` |
| 10 | Test sandbox du « next renewal » | **à faire, obligatoire avant prod** |
| 11 | Accès Retention Messaging API à demander à Apple | **à lancer maintenant** |
| 12 | Win-back offers | à faire |
| 13 | Table `course_events` (vrai log d'impressions) | à faire |
| 14 | Modèle appris sur les impressions | après 4–6 semaines de log |

---

## Sources

- [Customer Center — RevenueCat](https://www.revenuecat.com/docs/tools/customer-center)
- [Configuring Apple Promotional Offers for Customer Center](https://www.revenuecat.com/docs/tools/customer-center/customer-center-promo-offers-apple)
- [Apple Retention Messaging API — RevenueCat](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-retention-messaging-api)
- [The beginner's guide to Apple win-back offers](https://www.revenuecat.com/blog/growth/guide-to-apple-win-back-offers)
- [iOS Subscription Offers — RevenueCat](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers/ios-subscription-offers)
- [Implementing promotional offers — Apple](https://developer.apple.com/documentation/storekit/implementing-promotional-offers-in-your-app)
- [Upgrades, downgrades & crossgrades — RevenueCat](https://www.revenuecat.com/docs/subscription-guidance/managing-subscriptions)
- [Offer auto-renewable subscriptions — App Store Connect Help](https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions/)
- [Explore Retention Messaging in App Store Connect — WWDC26 session 309](https://developer.apple.com/videos/play/wwdc2026/309/)
