# Plan d'A/B tests prix — Sophia

Analyse faite le 26/09/2026 à partir des données RevenueCat (projet `proj3f496a80`, clé lecture
seule), du code iOS/Android et d'une veille concurrentielle. **Rien n'a été modifié** : ni dans
RevenueCat, ni dans App Store Connect / Play Console, ni dans le code. Ce document est le plan
d'action à valider avant toute exécution.

Sommaire : 0. Résumé · 1. Photographie chiffrée · 2. Leçons des 5 expériences passées ·
3. Grille de prix actuelle par pays · 4. Concurrents · 5. Prérequis techniques ·
6. Programme de tests · 7. Grille de prix par pays proposée · 8. Règles de décision ·
9. Suivi · 10. Résultat attendu · Annexes.

---

## 0. Résumé

- **Le contexte a changé en août.** Nouveaux utilisateurs ×5 (14 980 en juillet → 71 915 en août
  → 77 904 du 1er au 26 septembre), abonnements actifs 1 153 → 5 150, MRR 4,5 k€ → 17,4 k€.
  L'app est devenue internationale : la Türkiye est le 1er pays d'acquisition, la France n'est
  plus que 4 % des nouveaux utilisateurs en septembre.
- **L'annuel fait 95 % du revenu**, le mensuel 5 %. Le paywall de fin d'onboarding génère 84 %
  des essais et 70 % du revenu. La question « quel prix annuel » pèse donc dix fois plus que
  « mensuel ou hebdo ».
- **Deux signaux d'alerte à surveiller pendant les tests** : le taux de remboursement est à
  10,8 % en août (pire décile des apps Éducation sur l'App Store) et la conversion d'essai est
  tombée de 44–48 % à 32 % avec l'arrivée des pays à faible pouvoir d'achat.
- **La grille de prix actuelle est une simple conversion de change** : l'annuel iOS vaut entre 29 €
  et 44 € partout (médiane 31 €), dont 36 € en Türkiye. Android est 20 % plus cher qu'iOS. Aucun
  ajustement au pouvoir d'achat.
- **Les 5 expériences passées n'ont rien prouvé** : arrêtées après 1 à 6 jours avec moins de
  700 utilisateurs par variante. Avec ~3 000 nouveaux utilisateurs/jour, un test bien dimensionné
  se lit désormais en 3 à 5 semaines.
- **Programme proposé (≈ 13 semaines)** : une semaine de prérequis, puis
  1. prix annuel 39,99 / 49,99 / 59,99 € sur les pays « Tier A » (Europe de l'Ouest, UK, CH,
     Amérique du Nord) ;
  2. en parallèle, sur une audience disjointe, test de prix Türkiye (1 999 vs 999 vs 499 TRY) ;
  3. plan secondaire : mensuel 9,99 € avec essai (contrôle) vs mensuel sans essai vs hebdo 6,99 € ;
  4. en parallèle, sur le placement discount : 19,99 vs 29,99 € ;
  5. consolidation en une grille par pays et deuxième vague (Tier B, 44,99 €, durée d'essai).
- **Ce que dit le marché** : 39,99 € est dans le bas de la fourchette Éducation (médiane 44,99 $,
  Elevate 45,99 €, Headway/Blinkist 80 €), l'essai standard est 7 jours (un essai ≤ 4 jours
  convertit 24 % contre 33 % à 5–9 jours), et Sophia est 2 à 10 fois plus chère que Duolingo,
  Elevate ou Impulse en Türkiye.
- **Prérequis bloquants** : passer les 4 contextes de paywall aux *Placements* RevenueCat (sinon
  seuls les paywalls d'onboarding voient les expériences), créer les produits (et les rattacher
  à l'entitlement `premium`, oubli constaté sur les produits de test existants), supporter un
  package hebdo dans les apps.

---

## 1. Photographie chiffrée (RevenueCat, 26/09/2026)

### 1.1 Trajectoire mensuelle

| Mois 2026 | Nouveaux clients | Essais démarrés | Conv. essai → payant | Abonnés actifs (fin) | MRR (€) | Revenu (€) | Remboursements |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Mai | 8 581 | 597 | 48,7 % | 485 | 2 088 | — | 8,4 % |
| Juin | 8 994 | 747 | 44,9 % | 678 | 2 927 | 7 359 | 10,3 % |
| Juillet | 14 980 | 966 | 44,0 % | 1 153 | 4 525 | 16 300 | 7,9 % |
| Août | 71 915 | 5 867 | 32,0 % | 3 027 | 10 750 | 57 777 | 10,8 % |
| Sept. (1–26) | 77 904 | 5 844 | en cours | 5 150 | 17 433 | 67 322 | — |

Funnel août (cohorte) : conversion initiale à 7 j **8,6 %** (essai ou achat), conversion payante à
7 j **2,8 %**, LTV réalisée à 30 j **0,91 € / nouveau client** (1,07 € en juin).

### 1.2 Benchmarks RevenueCat (App Store, catégorie Éducation, 12 derniers mois)

| Métrique | Sophia | Percentile vs pairs | Lecture |
| --- | ---: | ---: | --- |
| Conversion initiale 14 j | 8,3 % | 80–90 | Le paywall convainc d'essayer : très bon |
| Conversion payante 30 j | 3,1 % | 70–80 | Bon |
| Conversion d'essai (non bornée) | 30,9 % | 40–50 | Médian, en baisse depuis août |
| LTV / client 30 j | 1,09 $ | 80–90 | Très bon |
| LTV / client payant 30 j | 34,9 $ | 80–90 | Très bon (annuel dominant) |
| Churn mensuel | 20,6 % | 30–40 | Moins bon que la médiane |
| **Taux de remboursement** | **9,0 %** | **0–10** | **Pire décile** |

### 1.3 Mix produit et mix paywall (août)

| | Revenu | Transactions | Essais démarrés | Actifs (sept.) |
| --- | ---: | ---: | ---: | ---: |
| Annuel (P1Y) | 54 675 € (95 %) | 1 912 | 5 199 (89 %) | 4 683 (91 %) |
| Mensuel (P1M) | 3 102 € (5 %) | 328 | 668 (11 %) | 467 (9 %) |

| Offering (placement) | Revenu août | Essais août | Conv. essai août |
| --- | ---: | ---: | ---: |
| `fin_onboarding` (onboarding, courante) | 40 201 € (70 %) | 4 904 (84 %) | 32,8 % |
| `offre_discount` (offre flash 60 min, 19,99 €) | 9 092 € (16 %) | 0 (pas d'essai) | — |
| « Unknown » (renouvellements, restaurations) | 5 735 € | 639 | 30,5 % |
| `quizz` (quiz + entraînement) | 1 261 € | 171 | 22,2 % |
| `debloquer_cours` | 834 € | 153 | 20,9 % |

Churn mensuel par plan (août) : **annuel 21 %** (inclut les remboursements), **mensuel 53 %**
(50 à 81 % selon les mois). Le mensuel ne retient personne : il sert surtout d'ancre de prix.

### 1.4 Par pays (12 premiers pays de septembre)

| Pays | Nouveaux clients sept. | Revenu sept. (€) | Conv. essai août | Conv. payante 7 j août | LTV 30 j / client août (€) | Prix annuel iOS local (≈ €) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Türkiye | 12 236 | 7 306 | 25,7 % | 1,75 % | 0,52 | 1 999,99 TRY (36) |
| Italie | 10 903 | 7 974 | 28,3 % | 3,70 % | 1,14 | 39,99 € (40) |
| Espagne | 8 351 | 6 506 | 20,2 % | 2,10 % | 0,73 | 39,99 € (40) |
| Pologne | 8 134 | 7 202 | 39,2 % | 2,77 % | 0,77 | 149,99 PLN (34) |
| Allemagne | 6 196 | 9 560 | 39,2 % | 3,83 % | 1,32 | 39,99 € (40) |
| Mexique | 4 548 | 3 005 | 33,6 % | 3,25 % | 0,98 | 799 MXN (40) |
| France | 3 344 | 5 015 | 44,7 % | 3,04 % | 1,07 | 39,99 € (40) |
| Roumanie | 3 277 | 2 829 | — | — | — | 199,99 RON (38) |
| Hongrie | 1 928 | 4 563 | 36,7 % | 5,45 % | 2,17 | — |
| Colombie | 1 701 | — | — | — | — | 149 900 COP (40) |
| Brésil | 1 094 | — | — | 0,60 % | — | 229,90 BRL (39) |
| Pays-Bas | 1 053 | 1 756 | 41,0 % | 5,09 % | 1,83 | 39,99 € (40) |
| Belgique / Suisse / États-Unis | 745 / 556 / 593 (août) | 650 / 935 / — | — | 5,1 % / 8,3 % / — | 2,08 / 2,51 / 2,06 | 40 / 32 / 31 |

Lecture : à prix quasi identique, la Türkiye rapporte 0,52 € par nouvel utilisateur contre 1,3 à
2,5 € en Allemagne, Benelux, Suisse ou États-Unis. C'est l'écart de pouvoir d'achat, pas un
problème de produit : un tiers d'essais en moins convertis et une conversion payante deux fois
plus faible. Android reste marginal (964 nouveaux clients en août sur 71 915, 2 169 € de revenu
en septembre).

---

## 2. Ce que les 5 expériences passées ont appris

| Expérience | Dates | Variantes (utilisateurs / bras) | Résultat brut | Verdict RevenueCat |
| --- | --- | --- | --- | --- |
| Paywall design test | 19–20 avril | default vs default 2 (385 / 386) | conv. initiale 3,4 % → 6,2 %, LTV/client 0,44 → 1,04 $ | insufficient data |
| A/B test wording | 20 avril | A/B test 2 vs default 2 (5 / 8) | rien | — |
| wording | 20–21 avril | default vs default 2 (229 / 217) | −33 % conv. initiale | insufficient data |
| wording paywall fin OB | 8–14 juillet | fin_onboarding vs fin_onboarding2/3/4 (≈ 620 chacun) | contrôle meilleur en conv. initiale (7,8 % vs 5,1–6,1 %) ; variante 3 « prix par semaine » meilleure en conv. d'essai (55 % vs 41 %) et en LTV / payant (+10 %) | insufficient data |
| annual vs annual/monthly | 14–15 juillet | fin_onboarding vs « annual only » (193 / 195) | LTV/client 1,14 → 0,39 $ | insufficient data |

Trois leçons :

1. **Aucun test n'a atteint la significativité** : les intervalles de crédibilité se recouvrent
   tous. Avec 200 à 650 utilisateurs par bras il faut des effets de +100 % pour conclure.
2. **Un signal faible mais cohérent** : afficher un prix ramené à la semaine (variante 3) a
   amélioré la conversion d'essai et le revenu par payant, mais fait baisser le nombre d'essais.
   C'est exactement l'arbitrage qu'un test hebdo/mensuel doit trancher proprement.
3. **Le volume actuel change tout** : ~3 000 nouveaux clients/jour, dont ~2 550 exposés au
   paywall d'onboarding. Les tailles d'échantillon de la section 6 deviennent atteignables en
   quelques semaines, à condition de ne pas arrêter les tests au premier écart visible.

Deux offerings de test créées le 27 juillet (`price_test_annual_5999` avec `Sophia_yearly_5999`,
`trial_test_monthly_notrial` avec `Sophia_monthly_notrial`) n'ont jamais été lancées. Leurs
produits ne sont **pas rattachés à l'entitlement `premium`** : lancées telles quelles, elles
encaisseraient sans débloquer Premium. À corriger avant réutilisation.

---

## 3. Grille de prix actuelle par pays

Prix relevés dans App Store Connect (produit `Sophia_yearly`, 175 pays) et Play Console
(`sophia_pro:p1y`, 173 pays), convertis en euros aux taux du 26/09/2026.

| Pays | iOS annuel | ≈ € | Play annuel | ≈ € | Play promo | ≈ € |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| France / Allemagne / Espagne / Italie | 39,99 € | 40 | 47,99 € | 48 | 23,99 € | 24 |
| Royaume-Uni | 34,99 GBP | 41 | 40,99 GBP | 48 | 20,49 GBP | 24 |
| Suisse | 30 CHF | 32 | 38 CHF | 40 | 19 CHF | 20 |
| États-Unis | 34,99 USD | 31 | 45,99 USD | 40 | 22,99 USD | 20 |
| Canada | 49,99 CAD | 31 | 63,99 CAD | 40 | 31,99 CAD | 20 |
| Pologne | 149,99 PLN | 34 | 209,99 PLN | 48 | 104,99 PLN | 24 |
| Roumanie | 199,99 RON | 38 | 254,99 RON | 48 | 124,99 RON | 24 |
| **Türkiye** | **1 999,99 TRY** | **36** | **2 659,99 TRY** | **48** | 1 329,99 TRY | 24 |
| Mexique | 799 MXN | 40 | 919 MXN | 46 | 459 MXN | 23 |
| Brésil | 229,90 BRL | 39 | 239,99 BRL | 41 | 119,99 BRL | 20 |
| Colombie | 149 900 COP | 40 | 145 000 COP | 39 | 73 000 COP | 20 |
| Inde | 3 499 INR | 32 | 5 200 INR | 48 | 2 600 INR | 24 |
| Indonésie | 599 000 IDR | 29 | 790 000 IDR | 39 | 409 000 IDR | 20 |
| Égypte | 1 999,99 EGP | 34 | 2 649,99 EGP | 45 | 1 349,99 EGP | 23 |
| Maroc / Algérie / Tunisie | 34,99 USD | 31 | 519,99 MAD / 6 150 DZD / 46,29 USD | 48 / 40 / 41 | — | 24 / 20 / 20 |
| Sénégal / Côte d'Ivoire | 39,99 USD | 35 | 31 000 XOF | 47 | 15 500 XOF | 24 |
| Nigeria | 59 900 NGN | 38 | 67 000 NGN | 43 | 33 500 NGN | 22 |

Constats :

- **Aucune différenciation par pouvoir d'achat.** iOS : 175 pays entre 29 € et 44 €, médiane 31 €.
  C'est l'équilibrage automatique d'Apple à partir de 39,99 €, jamais retouché.
- **Android est 20 % plus cher qu'iOS partout** (base 47,99 € contre 39,99 €), sans raison connue,
  alors que le revenu par installation Play vaut environ la moitié d'iOS dans les données
  RevenueCat. À aligner, quel que soit le résultat des tests.
- **La Türkiye paie 36 € (iOS) et 48 € (Android)** pour un salaire minimum net d'environ 22 000 TRY
  (≈ 400 €) : l'annuel représente 9 % d'un mois de salaire minimum, contre 2 % en France.
- Le discount est partout un −50 % (19,99 € / 23,99 €), ce qui borne le test 29,99 € : c'est un
  « −25 % » et non plus une « offre flash à moitié prix ».

---

## 4. Concurrents

Veille faite le 26/09/2026 sur les fiches App Store (France et États-Unis, plus Türkiye, Brésil et
Inde pour quelques apps) et sur les rapports RevenueCat et Adapty 2026. Les fiches App Store
listent les prix sans toujours préciser la période : « n.p. » = période non précisée. Les pages
Play Store n'ont pas pu être lues : prix Android des concurrents non relevés.

### 4.1 Applications comparables (App Store, 26/09/2026)

| App | Pays | Hebdo | Mensuel | Annuel | Essai | Plan mis en avant |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| **Sophia (référence)** | FR | — | 9,99 € | 39,99 € (flash 19,99 €) | 3 j | Annuel |
| Elevate (brain training) | US / FR | 4,99 (n.p.) | 9,99 $ / 9,99 € | 39,99 $ / 45,99 € | 7 j | Annuel + essai 7 j, badge remise |
| Peak | US / FR | — | 4,99 $ / 4,99 € | 34,99 $ / 34,99 € (−40 % : 19,99) | — | — |
| Impulse (brain training, ≈ 2,75 M$/mois) | US / FR | 9,99 $ / 6,99–8,99 € | 15,99 $ / 17,49 € | 29,49 $ « special offer » / 29,99 € ; plein 39,99–59,99 | 3 j | **Hebdo + essai 3 j**, puis annuel « −92 % » |
| Headway | US / FR | n.p. | 12,99 $ / 11,49 € | 89,99 $ / 79,99 € | 7 j | Annuel |
| Blinkist | US / FR | — | 15,99 $ / 12,99 € | 99,99 $ / 79,99 € (intro 79,99 $) | 7 j | Annuel |
| Imprint | US / FR | — | 15,99 $ / 14,99 € | 99,99 $ / 89,99 € (promo 74,99 $ / 54,99 €) | 7 j | Annuel « −48 % » |
| Brilliant | US / FR | — | 24,99 $ / 16,49 € | 149,99 $ / 95,99 € | 7 j | Annuel |
| Duolingo Super | US / FR | — | 12,99 $ / — | 83,99 $ / 94,99 € | 14 j | Annuel, pas d'hebdo |
| Lumosity | US / FR | — | 11,99 $ / 11,99 € | 59,99 $ / 54,99–99,99 € | 7 j | — |
| Uptime | US / FR | 3,99 $ / 4,99 € (n.p.) | 11,99 $ / 16,99 € | 79,99 $ / 34,99–69,99 € | 7 j | — |
| Deepstash | US / FR | — | 12,99 $ / 22,99 € | 89,99 $ / 34,99–99,99 € | — | — |
| Nibble (micro-learning) | US / FR | — | 19,99 $ / 20,99 € | 59,99 $ / 62,99 € | 7 j | — |
| Noji (flashcards) | US / FR | — | 4,99 $ / 4,99 € | 44,99 $ / 29,99–49,99 € (lifetime 74,99 $) | 3 j | Annuel présélectionné |
| Qulture – Quiz culture générale | FR | — | 3,99 € | 29,99 € (lifetime 34,99 €) | — | — |
| Erudit – jeu de culture générale | FR | 5,99 € | 4,99 € | — (lifetime 14,99–19,99 €) | — | — |
| Le Monde Mémorable – Culture G | FR | — | — | 79 € (3 mois 22,99 €) | oui | — |

Lecture : **39,99 € est dans le bas de la fourchette Éducation.** Les apps « savoir / résumés »
(Headway, Blinkist, Imprint, Brilliant, Duolingo) vendent l'annuel 80 à 150 € ; les apps
d'entraînement cérébral (Elevate, Peak, Lumosity) 35 à 60 € ; seuls les quiz indépendants
français sont à 30 €. L'essai standard de la catégorie est **7 jours** ; un mensuel **avec** essai
est rare ; l'hebdo avec essai de 3 jours est le modèle de l'app la plus rentable du brain
training (Impulse).

### 4.2 Concurrents dans les pays émergents (App Store TR / BR / IN)

| App | Türkiye | Brésil | Inde |
| --- | --- | --- | --- |
| **Sophia (actuel)** | annuel 1 999,99 TRY (≈ 36 €) | 229,90 BRL (≈ 39 €) | 3 499 INR (≈ 32 €) |
| Duolingo Super | annuel 329,99–1 209,99 TRY ; mensuel 139,99 TRY | annuel 179,90–224,90 BRL | annuel 1 199–1 749 INR |
| Elevate | annuel 149,99 TRY (essai) / 399,99 TRY premium | 129,90–164,90 BRL | 1 099–3 049 INR |
| Impulse | hebdo 62,99 TRY ; annuel « special » 199,99 TRY (plein 939,99) | hebdo 26,90 BRL ; annuel special 122,90 BRL | hebdo 849 INR ; annuel special 2 499 INR |
| Headway | 199,99–3 999,99 TRY | 49,90–479,90 BRL | 1 209–8 300 INR |
| Deepstash (mensuel) | 59,99 TRY | 9,90 BRL | 199 INR |

En Türkiye, Sophia est **2 à 10 fois plus chère** que les références locales de Duolingo, Elevate
ou Impulse. Les grilles de parité de pouvoir d'achat publiées (Pricepush, mai 2026) : palier 2
≈ 70 % du prix US (ES, IT, PT, PL, KR), palier 3 ≈ 50 % (BR, MX, TR, AR, ZA), palier 4 ≈ 35 % (IN,
ID, PH, VN). Médianes RevenueCat 2026 de l'annuel par région : Amérique du Nord 39,99 $, Europe de
l'Ouest 39,44 $, APAC 32,99 $, Moyen-Orient/Afrique 24,99 $, LatAm 23,99 $, Inde/Asie du Sud-Est
18,32 $. Apple ne réajuste jamais le prix d'un abonnement après coup : les prix par storefront se
fixent à la main.

### 4.3 Repères de la catégorie (RevenueCat State of Subscription Apps 2026, Adapty 2026)

- Éducation : essai → payant médian **37,7 %** (Sophia 32 % en août, 44–48 % avant) ;
  téléchargement → payant à J35 médian 2,5 % (Sophia 2,8–3,1 %) ; annuel médian **44,99 $**, le
  plus élevé de toutes les catégories ; mensuel 9,99 $ ; hebdo ≈ 5,9 $.
- Durée d'essai sur plan annuel (17 000 apps) : **≤ 4 jours convertit 24 %, 5–9 jours 33 %,
  10–16 jours 43 %** ; premier renouvellement 18 % après un essai ≤ 4 jours contre 47 % après
  17–32 jours. La moitié des essais Éducation durent 5 à 9 jours. Avec 3 jours, 55 % des
  annulations ont lieu le jour même.
- Renouvellement Éducation : hebdo **58 %** (meilleur de toutes les catégories), mensuel 56 %,
  annuel **24 %** (le pire). Chez Adapty, l'hebdo pèse 52 % du revenu Éducation, l'annuel 22 %.
- Les apps « chères » convertissent mieux à J35 que les apps « pas chères » (2,7 % vs 1,5 %,
  RevenueCat 2025) : le prix n'est pas le premier frein à la conversion.
- Les tests de localisation de prix ont le meilleur taux de victoire sur la LTV (62 %, Adapty) ;
  les prix européens ont augmenté de 18 % en un an.

### 4.4 Tests A/B publiés avec résultats mesurés

| Test | Résultat | Source |
| --- | --- | --- |
| Annuel +50 % (BuyBye) | conversion −19 %, **revenu par utilisateur +25 %** | Superwall, avr. 2026 |
| Annuel +30 % (app voyage) | conversion −5 % ; « mensuel + annuel » bat les combos avec hebdo sur l'ARPU | Adapty, 2025 |
| Annuel 59,99 → 44,99 $ (SellRaze) | ARPU +10 % : **la baisse a gagné** | Superwall, déc. 2025 |
| Hebdo 6,99 → 9,99 $ (PropGPT) | revenu par utilisateur +47 %, conversion quasi stable | Superwall, janv. 2026 |
| Ajout d'un hebdo (Apphud) | conversion onboarding 16 → 22 %, mais **revenu total en baisse** (cannibalise l'annuel) | Apphud, févr. 2025 |
| Hebdo comme ancre + annuel relevé (app productivité) | revenu +50 % en 8 semaines | Adapty |
| 3 plans hebdo/mensuel/annuel vs 2 (Rash ID) | ARPU +20 %, conversion payante +50 % | Superwall, janv. 2026 |
| Retrait du mensuel du paywall principal | +31 % d'essais, +64 % de revenu | RevenueCat, mars 2025 |
| Sans essai, premier mois remisé, vs essai 3 j (Flibbo) | revenu +20 % | Superwall, mars 2026 |
| Essai 7 j + « −71 % » sur l'annuel (ABBYY) | revenu annuel +58 % | Adapty |
| Profondeur de remise (The Economist) | une offre vs aucune ≈ +20 % ; « se termine dans » bat « −50 % » ; **aucun test 50 % vs 25 % publié** | Funnelfox, juin 2026 |

Ce que la veille change dans le plan : (1) 49,99 € est un test à faible risque et 59,99 € reste
dans la fourchette du marché ; (2) l'essai de 3 jours sur l'annuel est probablement le levier
n° 2 après le prix, il monte en tête de la vague 2 ; (3) l'hebdo se teste **comme ancre** avec
l'annuel présélectionné, jamais comme plan principal ; (4) la Türkiye se teste avec des paliers
plus bas que prévu (999 et 499 TRY) ; (5) Android à 47,99 € est à l'envers du marché, où le
revenu par installation Play vaut environ la moitié d'iOS.

Sources : fiches apps.apple.com (US, FR, TR, BR, IN), revenuecat.com/state-of-subscription-apps
et /state-of-subscription-apps-2026-education (mars 2026), revenuecat.com/blog/growth/free-trial-length,
revenuecat.com/blog/growth/average-subscription-renewal-rates-by-app-category,
adapty.io/blog/education-app-subscription-benchmarks, pricepush.app/blog/app-price-localization-cheat-sheet,
superwall.com/case-studies (BuyBye, SellRaze, PropGPT, Rash ID, Flibbo), apphud.com/blog,
blog.funnelfox.com.

---

## 5. Prérequis techniques (semaine 0)

Sans ces étapes, les tests ne mesurent pas ce qu'on croit.

### 5.1 Faire remonter les expériences jusqu'aux paywalls (code, iOS + Android)

Une expérience RevenueCat fonctionne en remplaçant l'offering **courante** servie à l'utilisateur.
Aujourd'hui :

- les paywalls d'onboarding (`OnboardingV2PaywallAnnual` / `Comparison`) lisent
  `offerings.current` → **les expériences les atteignent** (84 % des essais) ;
- les paywalls `quizz`, `debloquer_cours`, `offre_discount`, `entrainement` lisent
  `offerings.offering(identifier:)` (iOS `SophiaPaywallView`, Android `PaywallContext.offeringId`)
  → **aucune expérience ne les atteint**, y compris le test discount.

À faire : déclarer 4 Placements RevenueCat (`onboarding`, `quizz`, `debloquer_cours`,
`offre_discount`), une règle de ciblage « Any audience » qui sert l'offering actuelle de chaque
placement, et remplacer les appels par `offerings.currentOffering(forPlacement:)` (iOS) /
`getCurrentOfferingForPlacement` (Android), avec repli sur l'identifiant historique si le
placement ne renvoie rien (anciennes versions). Fichiers : `StoreViewModel.swift`,
`SophiaPaywallView.swift`, `SophiaNativePaywalls.swift`, `PaywallScreen.kt`, `StoreViewModel.kt`.

### 5.2 Supporter un package hebdomadaire

Les deux apps ne connaissent que `$rc_annual` et `$rc_monthly`. Le test hebdo demande :
`$rc_weekly` dans `StoreViewModel` (iOS/Android), un libellé « par semaine » sur le paywall
comparatif, le calcul du prix ramené à la semaine (`perMonthPrice` → généraliser), et des textes
de repli qui ne disent plus « 9,99 € / mois » en dur (26 occurrences de prix codés en dur côté
iOS, clés `paywall.plan.fallback.*` côté Android). La détection d'essai est déjà dynamique
(`hasFreeTrial`) : rien à changer pour « avec / sans essai ».

### 5.3 Produits à créer (App Store Connect, Play Console, Test Store RevenueCat)

Toujours de **nouveaux identifiants** (jamais de changement de prix sur `Sophia_yearly`, qui
toucherait les abonnés existants). Tous rattachés à l'entitlement `premium`.

| Usage | iOS (groupe « Sophia Premium ») | Android (`sophia_pro`, nouveau base plan / offre) | Essai | Prix FR |
| --- | --- | --- | --- | --- |
| Annuel 49,99 | `Sophia_yearly_4999` | base plan `p1y-4999` | 3 j | 49,99 € |
| Annuel 59,99 | `Sophia_yearly_5999` (existe, à rattacher à `premium`) | `p1y-5999` | 3 j | 59,99 € |
| Mensuel sans essai | `Sophia_monthly_notrial` (existe, à rattacher) | `monthly-notrial` | aucun | 9,99 € |
| Hebdo | `Sophia_weekly_699` | `weekly-699` | aucun | 6,99 € |
| Discount 29,99 | `discount_yearly_2999` | `annual-promo-2999` | aucun | 29,99 € |
| Türkiye palier 2 | `Sophia_yearly_tr2` (prix personnalisé TR uniquement) | `p1y-tr2` | 3 j | 999,99 TRY |
| Türkiye palier 3 | `Sophia_yearly_tr3` | `p1y-tr3` | 3 j | 499,99 TRY |

Les achats intégrés se soumettent à la revue Apple sans nouveau binaire (compter 1 à 3 jours).
Côté Play, aucune revue. Créer aussi les équivalents Test Store pour les builds de debug.

### 5.4 Offerings et expériences RevenueCat

- Une offering par variante, nommée `<placement>__<variable>_<valeur>` : `onboarding__annual_4999`,
  `onboarding__annual_5999`, `onboarding__secondary_monthly_notrial`, `onboarding__secondary_weekly_699`,
  `discount__2999`, `onboarding__tr_999`, `onboarding__tr_599`. Métadonnées : `experiment`,
  `variant`, `hypothesis` (comme sur les offerings de juillet).
- Expériences : enrôlement **nouveaux clients uniquement**, 100 % de l'audience ciblée, 2 à 4
  variantes, type « Price point » ou « Free trial ». Audiences par pays (Targeting → condition
  pays) pour faire tourner deux tests en parallèle sans recouvrement.
- Vérifier au jour 1 que « Paywall viewers » se remplit : les paywalls natifs déclarent leurs
  impressions via `trackCustomPaywallImpression` ; depuis leur mise en ligne début août, le
  graphique *Paywall Conversion* ne compte plus que les templates RevenueCat (159 vues en août
  contre 23 876 en juillet). Si les viewers restent à zéro, corriger le tracking avant de continuer.
- Archiver les 19 offerings et ~20 paywalls orphelins (voir `PLAN.md`) pour que le dashboard
  des expériences reste lisible.

### 5.5 Garde-fou remboursements

Le taux de remboursement (10,8 %) sera lu **par variante** dans les résultats d'expérience
(« Refunded customers »). Avant de lancer, activer la notification J-1 de fin d'essai pour 100 %
des essais (déjà présente côté app : `trialExpiresInOneDay`) et vérifier le texte du CTA
« Continuer pour 0,00 € » : un prix plus élevé rend chaque oubli plus coûteux et plus contesté.

---

## 6. Programme de tests

Tailles d'échantillon calculées sur la conversion payante (α = 5 %, puissance 80 %), exposition
≈ 85 % des nouveaux clients au paywall d'onboarding, volumes de septembre.

| Baseline conv. payante | Détecter −15 % | −20 % | −25 % | −33 % | −50 % |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 3,0 % (Tier A) | 20 915 / bras | 11 456 | 7 133 | 3 912 | 1 534 |
| 1,8 % (Türkiye) | 35 256 | 19 305 | 12 017 | 6 586 | 2 581 |
| 1,5 % (discount) | 49 046 | 26 852 | 16 713 | 9 158 | 3 587 |

Volumes exposés par jour : Tier A (FR ES DE IT NL) ≈ 980, Tier B (PL RO HU) ≈ 440, Tier C
(TR MX CO BR) ≈ 640 dont Türkiye ≈ 400, total ≈ 2 550.

### Test A — Prix annuel (Tier A) · semaines 1 → 5

| | |
| --- | --- |
| Question | Le revenu par nouvel utilisateur monte-t-il à 49,99 € ou 59,99 € ? |
| Audience | Nouveaux clients, pays Tier A : FR, DE, ES, IT, NL, BE, AT, IE, PT, FI, LU, CH, GB, US, CA, AU, NZ, JP, pays nordiques. Un seul placement : `onboarding` (offering courante). |
| Variantes | Contrôle 39,99 € (3 j d'essai) · B 49,99 € · C 59,99 €. Mensuel inchangé (9,99 €, essai) dans les trois. |
| Métrique de décision | LTV réalisée par client à 30 jours (proceeds), lue sur RevenueCat. |
| Secondaires | Conversion initiale (essais démarrés), conversion d'essai, conversion payante, refunds par variante, part annuel/mensuel. |
| Seuils de neutralité | 49,99 € est rentable si sa conversion payante reste ≥ 80 % du contrôle (2,4 % vs 3,0 %) ; 59,99 € si ≥ 67 % (2,0 %). |
| Taille | 11 456 par bras pour détecter −20 % → 34 000 exposés → **≈ 5 semaines** d'enrôlement à 980/j, puis 30 jours de maturation pour la LTV 30 j (lecture provisoire à J+14). |
| Arrêt anticipé | Uniquement pour dégradation : remboursements d'une variante > contrôle + 3 points, ou conv. payante < 60 % du contrôle après 4 000 exposés. |
| Issue attendue | Un prix retenu pour le Tier A. Si 49,99 € gagne, tester 44,99 vs 49,99 vs 54,99 en vague 2. |

### Test T — Palier Türkiye · semaines 1 → 7 (en parallèle, audience disjointe)

| | |
| --- | --- |
| Question | À quel prix la Türkiye rapporte-t-elle le plus par utilisateur ? |
| Audience | Nouveaux clients, pays = TR, placement `onboarding`. |
| Variantes | Contrôle 1 999,99 TRY (≈ 36 €) · B 999,99 TRY (≈ 18 €, palier PPP « 50 % ») · C 499,99 TRY (≈ 9 €, entre Elevate 399,99 et Duolingo 329,99–1 209,99). Prix fixés par storefront sur des produits dédiés (§ 5.3). |
| Métrique | LTV / client 30 j ; secondaires conversion d'essai (aujourd'hui 25,7 %), refunds. |
| Seuils | 999 TRY gagne s'il double la conversion payante (break-even ×2,0) ; 499 TRY s'il la quadruple (×4,0). Si aucun n'y arrive, la Türkiye reste au prix plein et on réduit plutôt l'acquisition. |
| Taille | 6 586 par bras pour détecter un écart de 33 % → **≈ 7 semaines** à 400/j en 3 bras, 5 semaines en 2 bras. Les effets attendus étant grands (×2 à ×4), une lecture provisoire à 3 000 exposés par bras est possible. |
| Issue attendue | Un multiplicateur de pouvoir d'achat à appliquer au Tier C (MX, BR, CO, EG, IN, ID, PH, PK, NG, MA, DZ, TN, UA…). |

### Test B — Plan secondaire : mensuel avec essai vs sans essai vs hebdo · semaines 6 → 9

| | |
| --- | --- |
| Question | Quel plan « court » maximise le revenu total : mensuel 9,99 € avec essai (actuel), mensuel sans essai, ou hebdo 6,99 € ? |
| Pourquoi après le Test A | Le plan court sert d'ancre : il faut le tester face au prix annuel retenu. Le mensuel ne pèse que 5 % du revenu et churne à 53 %/mois : l'effet se mesure surtout sur la part annuel et le revenu global du paywall. Le marché est partagé : l'hebdo renouvelle le mieux de la catégorie (58 %) et fait 52 % du revenu Éducation chez Adapty, mais il cannibalise l'annuel quand il devient le plan principal (Apphud). D'où : hebdo comme ancre, annuel présélectionné. |
| Audience | Nouveaux clients Tier A + Tier B, placement `onboarding` (paywall comparatif). |
| Variantes | Contrôle : annuel gagnant + mensuel 9,99 € essai 3 j · B : annuel + mensuel 9,99 € sans essai · C : annuel + hebdo 6,99 € sans essai (= 363 €/an affiché, l'annuel paraît −89 %). |
| Métriques | LTV / client 30 j ; part des achats annuels ; refunds (les hebdos sont les plus contestés) ; rétention à 4 semaines de la cohorte hebdo. |
| Taille | 20 915 par bras (détecter ±15 % sur la conversion payante globale) → **≈ 16 jours** à 1 400/j avec 3 bras, + 30 j de maturation. |
| Garde-fous | Refunds hebdo > 15 % ou plaintes : arrêter la variante. Apple accepte l'hebdo mais ces plans concentrent les litiges. |

### Test D — Discount 19,99 vs 29,99 € · semaines 6 → 9 (en parallèle, placement `offre_discount`)

| | |
| --- | --- |
| Question | L'offre flash rapporte-t-elle plus à 29,99 € (−25 %) qu'à 19,99 € (−50 %) ? |
| Prérequis | Placement `offre_discount` en prod (§ 5.1). Sans lui, ce test est impossible. |
| Audience | Utilisateurs gratuits qui ouvrent le cadeau après 3 swipes (déclencheur actuel), tous pays Tier A/B. |
| Variantes | Contrôle 19,99 € · B 29,99 €. |
| Métriques | Revenu par vue du paywall discount ; conversion (1,5 % en juillet) ; refunds. |
| Seuil | 29,99 € gagne si sa conversion reste ≥ 67 % du contrôle. |
| Taille | 7 924 par bras → **≈ 20 jours** à ~800 vues/j. |
| Note | Si le Test A relève l'annuel à 49,99 €, un discount à 24,99 € (−50 %) devient une 3ᵉ variante naturelle. |

### Vague 2 — semaines 10 → 13

- **Durée d'essai sur l'annuel : 3 vs 7 jours** (Tier A, au prix retenu). C'est le levier le mieux
  documenté après le prix : un essai ≤ 4 jours convertit 24 % contre 33 % à 5–9 jours, et
  renouvelle 18 % contre 33–47 % ; la catégorie est à 7 jours (Elevate, Headway, Blinkist,
  Imprint). Sophia est à 32 % avec 3 jours et 10,8 % de remboursements : un essai de 7 jours peut
  améliorer les deux. À lancer dès la fin du Test A si le volume le permet.
- **Tier B** (PL, RO, HU, CZ, SK, HR, BG, GR, PT si besoin) : annuel Tier A retenu vs −25 %.
- **Affinage** autour du gagnant du Test A (± 5 €). Une variable à la fois.
- **Déploiement** de la grille par pays (§ 7) hors expérience, via prix par storefront + règles de
  ciblage RevenueCat, puis mesure avant/après par pays.

Calendrier récapitulatif :

| Semaine | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Prérequis (§ 5) | ■ | | | | | | | | | | | | | |
| A · annuel Tier A | | ■ | ■ | ■ | ■ | ■ | lecture J+14 → J+30 | | | | | | | |
| T · Türkiye | | ■ | ■ | ■ | ■ | ■ | ■ | ■ | lecture | | | | | |
| B · plan secondaire | | | | | | | ■ | ■ | ■ | lecture | | | | |
| D · discount | | | | | | | ■ | ■ | ■ | lecture | | | | |
| Vague 2 + grille pays | | | | | | | | | | | ■ | ■ | ■ | ■ |

---

## 7. Grille de prix par pays proposée (hypothèses à tester, pas à appliquer en l'état)

Principe : trois paliers indexés sur le pouvoir d'achat, mis en œuvre par **prix personnalisés par
storefront** (App Store Connect et Play Console le permettent sur un même produit) pour le
déploiement, et par produits dédiés uniquement le temps des tests. Android aligné sur iOS.

| Palier | Pays (selon acquisition actuelle) | Annuel | Mensuel / hebdo | Discount | Base de la recommandation |
| --- | --- | --- | --- | --- | --- |
| A | Zone euro Ouest, UK, CH, US, CA, AU, NZ, JP, Nordiques | 39,99 → **test 49,99 / 59,99 €** | 9,99 € ou 6,99 €/sem | 19,99 → test 29,99 € | LTV/client 1,1–2,5 €, conv. d'essai 40–45 % |
| B | PL, RO, HU, CZ, SK, HR, BG, GR, Baltes, PT | **≈ 29,99 €** (test vs Tier A) | 6,99 € | 14,99 € | Conv. d'essai 37–39 % mais LTV 0,77 € : prix plein trop haut pour une partie de l'audience |
| C | TR, MX, BR, CO, AR, CL, PE, EG, MA, DZ, TN, IN, ID, PH, VN, PK, NG, UA, ZA, MENA hors Golfe | **≈ 30–50 % du Tier A** (Türkiye : test 999 TRY) | 2,99–3,99 € | 9,99 € | Conv. d'essai 20–26 %, LTV 0,5 €, refunds probablement concentrés ici (à vérifier par pays) |

Points d'attention :

- Les prix personnalisés par storefront **ne suivent pas l'inflation** : en Türkiye, prévoir une
  révision trimestrielle (Apple révise ses grilles équilibrées, pas les prix fixés à la main).
- Un prix plus bas en Türkiye ou en Inde n'ouvre pas la porte au contournement : le storefront
  dépend du moyen de paiement du compte, et le volume concerné est déjà là.
- Le Golfe (SA, AE, QA) reste en Tier A malgré des prix équilibrés à 31–35 €.

---

## 8. Règles de décision et garde-fous

1. **Une variable par test**, 2 à 4 variantes, nouveaux clients uniquement, audiences disjointes
   pour les tests parallèles (pays ou placement différents).
2. **Métrique de décision unique** définie avant le lancement : LTV réalisée par client à 30 jours
   (proceeds). Les conversions sont des diagnostics, pas des critères de victoire.
3. **Pas de lecture avant la taille cible**, sauf garde-fous : remboursements d'une variante
   supérieurs au contrôle de plus de 3 points, ou effondrement de conversion (< 60 % du contrôle)
   après 4 000 exposés.
4. **Victoire** : probabilité de battre le contrôle ≥ 95 % sur la LTV 30 j **et** intervalle de
   crédibilité du lift qui exclut 0. Sinon, prolonger ou conserver le contrôle.
5. **Jamais de changement de prix sur un produit existant** : les abonnés actuels gardent leur prix,
   les tests passent par de nouveaux identifiants.
6. **Deux plateformes** : lancer les expériences sur iOS et Android, mais décider sur iOS (Android
   représente 1,3 % des nouveaux clients) et appliquer la décision aux deux.
7. **Journal de bord** : pour chaque test, une ligne dans ce document (date de début, taille
   atteinte, décision, offering déployée), et l'offering perdante archivée le jour même.

---

## 9. Suivi

- Hebdomadaire : résultats d'expérience (LTV 30 j, conversion, refunds par variante), graphique
  *Refund Rate* filtré par pays, *Trial Conversion Rate* par pays, *Realized LTV per Customer*
  par pays (`first_country`). Tout est lisible via le MCP RevenueCat en lecture seule ; je peux
  produire ce point chaque semaine sans rien toucher.
- À la fin de chaque test : capture des résultats dans `docs/`, décision consignée, offering
  déployée comme courante (Test A/B) ou via la règle de placement (Test D), produits perdants
  retirés de la vente.

---

## 10. Résultat attendu

Ordres de grandeur, à confirmer par les tests :

- **Annuel 49,99 € en Tier A** : les tests publiés vont dans les deux sens (+50 % de prix →
  −19 % de conversion et +25 % de revenu par utilisateur chez BuyBye ; +30 % → −5 % de conversion
  sur une app voyage ; mais 59,99 → 44,99 $ a gagné chez SellRaze). Avec un prix de départ sous
  la médiane de la catégorie, le pari est : 49,99 € gagne (conversion −10 à −15 %, revenu +5 à
  +12 %), 59,99 € perd ou fait match nul, avec des remboursements en hausse sur le montant contesté.
- **Türkiye à 999 TRY** : doubler la conversion payante (1,75 % → 3,5 %) est plausible vu l'écart
  avec l'Allemagne (3,8 %) et les prix locaux des concurrents (Elevate 149–399 TRY, Duolingo
  330–1 210 TRY) ; le revenu par utilisateur passerait de 0,52 € à ≈ 0,6–0,7 €, avec moins de
  remboursements. Pari : 999 TRY gagne, 499 TRY neutre ou légèrement gagnant.
- **Hebdo 6,99 €** : augmente la part d'annuel (effet d'ancre) et capte des impulsifs ; le marché
  montre +20 à +50 % d'ARPU quand l'hebdo sert d'ancre, et une perte nette quand il devient le
  plan principal. Pari : léger gain de LTV 30 j, à confirmer sur 90 j.
- **Mensuel sans essai** : baisse des essais, hausse des conversions directes ; effet global
  probablement neutre à légèrement positif (Flibbo +20 %, et la catégorie vend le mensuel sans
  essai). Utile surtout s'il réduit les remboursements.
- **Discount 29,99 €** : à −25 % l'offre perd son effet « moitié prix » ; pari : perte de
  conversion supérieure à 33 %, donc 19,99 € conservé (ou 24,99 € si l'annuel passe à 49,99 €).

Le « meilleur combo » se lira à la semaine 13 : un prix annuel par palier, un plan court, un
discount, et une grille par pays écrite dans ce document.

---

## Annexes

### A. Identifiants existants utiles

- Projet `proj3f496a80` · apps `app152440cc2e` (App Store), `app3dcadd8517` (Play), `app257be138ae` (Test Store).
- Entitlement `premium` = `entl5b0c63b9a1`.
- Offerings : `fin_onboarding` = `ofrngb1bfff7210` (courante), `quizz` = `ofrng2d26aa3789`,
  `debloquer_cours` = `ofrng0b892fe7f7`, `offre_discount` = `ofrng8974f13d40`,
  `price_test_annual_5999` = `ofrng2e73869147`, `trial_test_monthly_notrial` = `ofrng1f98dd206a`.
- Produits iOS : `Sophia_yearly` = `prodf40359e7e1`, `Sophia_monthly` = `prodf59fa512ae`,
  `discount_yearly` (iOS) = `prod87ca86a482`, `Sophia_yearly_5999` = `prod2ad0152b81`.

### B. Checklist de lancement d'une expérience

1. Produits créés dans les 3 stores, approuvés, rattachés à `premium`.
2. Offerings variantes créées avec les mêmes packages que le contrôle, seule la variable change.
3. Placement en prod dans la version d'app diffusée à ≥ 90 % des utilisateurs (vérifier
   *SDK versions* et *App version* dans RevenueCat).
4. Audience pays définie, absence de recouvrement avec les tests en cours.
5. Expérience créée : nouveaux clients, 100 %, métrique primaire LTV, notes = hypothèse et seuils.
6. Jour 1 : « Paywall viewers » ≈ 85 % des « Customers » ; achats visibles sur chaque variante.
7. Date de lecture inscrite au calendrier (taille cible + 30 jours).

### C. Changements de code à prévoir (aucun fait à ce stade)

| Fichier | Changement |
| --- | --- |
| `ios/Sophia/ViewModels/StoreViewModel.swift` | `offering(forPlacement:)` avec repli ; `weeklyPackage` ; prix ramené à la semaine générique ; impression trackée avec l'offering réellement servie |
| `ios/Sophia/Views/SophiaPaywallView.swift`, `SophiaNativePaywalls.swift` | Contexte → placement ; affichage hebdo sur le comparatif |
| `ios/Sophia/Views/Onboarding/OnboardingV2Paywalls.swift` | Plan secondaire dynamique (mensuel ou hebdo), libellés d'essai déjà dynamiques |
| `ios/Sophia/Utilities/AppLocalizable.swift` (+ 20 langues) | Textes de repli sans prix codé en dur |
| `android/.../ui/paywall/PaywallScreen.kt`, `StoreViewModel.kt` | Idem : placements, `$rc_weekly`, libellés |
| `PLAN.md` | Cases à cocher correspondantes |
