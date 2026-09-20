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

# 3. Où en est chaque chantier

| # | Chantier | État |
| --- | --- | --- |
| 1 | Modèle de deck (quotas + voisins + qualité), 24 IDs en dur supprimés | **livré** |
| 2 | Compteur local des cartes passées (`DeckSkipStore`) | **livré** |
| 3 | Détection `willRenew == false` + paywall de rétention natif | **livré**, bloqué sur l'offre ASC |
| 4 | « Gérer mon abonnement » → paywall → `showManageSubscriptions` | **livré** |
| 5 | Offre promotionnelle `retention_14_99` dans App Store Connect + clé In-App Purchase dans RevenueCat | **à faire côté ASC** |
| 6 | Test sandbox du « next renewal » | **à faire, obligatoire avant prod** |
| 7 | Accès Retention Messaging API à demander à Apple | **à lancer maintenant** |
| 8 | Win-back offers | à faire |
| 9 | Table `course_events` (vrai log d'impressions) | à faire |
| 10 | Modèle appris sur les impressions | après 4–6 semaines de log |

---

## Sources

- [Customer Center — RevenueCat](https://www.revenuecat.com/docs/tools/customer-center)
- [Configuring Apple Promotional Offers for Customer Center](https://www.revenuecat.com/docs/tools/customer-center/customer-center-promo-offers-apple)
- [Apple Retention Messaging API — RevenueCat](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-retention-messaging-api)
- [The beginner's guide to Apple win-back offers](https://www.revenuecat.com/blog/growth/guide-to-apple-win-back-offers)
- [iOS Subscription Offers — RevenueCat](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers/ios-subscription-offers)
