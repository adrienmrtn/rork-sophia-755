# Plan d'A/B tests prix — Sophia (lancement simultané)

Analyse faite le 26/09/2026 à partir des données RevenueCat (projet `proj3f496a80`, clé lecture
seule), du code iOS/Android et d'une veille concurrentielle. Version 2 : **tous les tests partent
en parallèle**, en trois vagues rapprochées (J0, J+3, J+14), au lieu d'un programme séquentiel de
13 semaines. **Rien n'a encore été modifié** : ni dans RevenueCat, ni dans App Store Connect /
Play Console, ni dans le code.

Sommaire : 0. Résumé · 1. Photographie chiffrée · 2. Leçons des 5 expériences passées ·
3. Grille de prix actuelle par pays · 4. Concurrents · 5. Architecture du lancement simultané ·
6. Plan d'action jour par jour · 7. Matrice produits et offerings · 8. Version R1 (code) ·
9. Lecture des résultats et décisions · 10. Grille de prix par pays · 11. Risques · Annexes.

---

## 0. Résumé

- **Le contexte** (détail § 1 à 4) : ×5 de nouveaux utilisateurs en août, ~3 100 nouveaux
  clients par jour en septembre, annuel = 95 % du revenu, paywall de fin d'onboarding = 84 % des
  essais, remboursements 10,8 %, conversion d'essai 32 %. 39,99 € est dans le bas de la fourchette
  Éducation ; la grille par pays est une simple conversion de change ; la Türkiye (1er pays
  d'acquisition) paie 2 à 10 fois plus cher que chez Duolingo, Elevate ou Impulse.
- **La contrainte qui dicte l'architecture** : RevenueCat refuse deux expériences actives sur des
  audiences qui se chevauchent, et plafonne à 4 variantes par expérience. On découpe donc le
  trafic en **5 audiences pays disjointes**, on empile **deux variables par expérience** (plans
  factoriels 2×2 à 4 bras), et le test discount passe **côté app** (tirage aléatoire), ce qui lui
  donne 100 % du trafic sans entrer en conflit avec les expériences.
- **Ce qui part aujourd'hui (J0), sans nouvelle version de l'app** : l'expérience A1 (annuel
  39,99 vs 59,99 × mensuel avec vs sans essai) sur Italie, France, Benelux, Suisse, US, UK,
  Canada, Nordiques. Les deux produits nécessaires (`Sophia_yearly_5999`, `Sophia_monthly_notrial`)
  sont déjà approuvés par Apple ; il manque seulement leur rattachement à l'entitlement `premium`,
  trois offerings, une audience et l'expérience.
- **J+3, dès validation Apple des nouveaux produits** : B (Europe centrale : 29,99 / 39,99 /
  49,99 €), TR (Türkiye : 1 999 / 999 / 499 TRY), C (LatAm, MENA, Asie, Afrique : 100 / 50 / 25 %
  du prix). Toujours sans nouvelle version.
- **J+14, version R1 déployée** : A2 (Espagne, Allemagne, Autriche, Portugal, Grèce : annuel
  39,99 vs 49,99 × mensuel vs hebdo 6,99 €) et le test discount 19,99 vs 29,99 € sur tout le
  monde. R1 apporte aussi la cohérence de prix entre paywalls (les paywalls quiz / cours lisent
  l'offering servie par l'expérience) et l'alignement Android.
- **Quand on saura** : garde-fous à J+21 ; premières décisions à J+30 (Türkiye et Tier C si
  l'effet est grand, A1 provisoire) ; décisions finales à J+45 pour A1, B, TR, C ; A2 et discount
  à J+45–60. Puis vague suivante à J+45 : essai 7 jours, affinage ± 5 €, plans courts par palier.

Effet minimum détectable (baisse relative de conversion payante, puissance 80 %) :

| Expérience | Départ | Exposés / j | MDE à J+30 | MDE à J+45 | MDE à J+60 | Seuil de neutralité de la variante |
| --- | :---: | ---: | ---: | ---: | ---: | --- |
| A1 · 59,99 × mensuel sans essai (2×2) | J0 | 608 | 24 % | 19 % | 17 % | 59,99 rentable si conv. ≥ 67 % du contrôle |
| A2 · 49,99 × hebdo 6,99 (2×2) | J+14 | 572 | 33 % | 24 % | 20 % | 49,99 rentable si conv. ≥ 80 % |
| B · 29,99 / 39,99 / 49,99 (3 bras) | J+3 | 511 | 34 % | 28 % | 24 % | 29,99 rentable si conv. ≥ 133 % ; 49,99 si ≥ 80 % |
| TR · 1 999 / 999 / 499 TRY (3 bras) | J+3 | 416 | 48 % | 38 % | 33 % | 999 rentable si conv. ×2 ; 499 si ×4 |
| C · 100 / 50 / 25 % (3 bras) | J+3 | 541 | 40 % | 32 % | 27 % | idem TR |
| Discount 19,99 vs 29,99 (côté app, 2 bras) | J+14 | ≈ 556 vues | 48 % | 35 % | 28 % | 29,99 rentable si conv. ≥ 67 % |

Lecture : à J+45, A1 tranche 59,99 € (il faut voir une baisse de 33 % pour que ce soit perdant, on
détecte 19 %) ; TR et C tranchent leurs paliers si l'effet attendu (×2 à ×4) est là ; B et A2
donnent une direction nette, une confirmation fine demande J+60.

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
n° 2 après le prix, il ouvre la vague suivante dès J+45 ; (3) l'hebdo se teste **comme ancre** avec
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

---

## 5. Architecture du lancement simultané

### 5.1 Les règles RevenueCat qui contraignent le design

1. **Pas de chevauchement d'audiences** entre expériences actives : l'interface refuse de lancer
   ou reprendre une expérience dont l'audience recoupe une expérience en cours. Un client n'est
   enrôlé que dans une expérience. → Les audiences sont définies par **pays** (condition de
   ciblage), et elles sont disjointes.
2. **4 variantes maximum** par expérience. → Chaque expérience teste **deux variables à deux
   niveaux** (plan factoriel 2×2 : chaque effet principal se lit sur 2 bras contre 2, ce qui
   double la puissance par rapport à un test « une variable à la fois »), ou trois niveaux d'une
   seule variable (paliers de prix).
3. **Une expérience remplace l'offering courante** servie au client. Les paywalls d'onboarding
   lisent `offerings.current` : aucune modification d'app n'est nécessaire pour les tests de
   prix et de plan mensuel. L'hebdo, lui, demande du code (`$rc_weekly` inconnu des apps).
4. **Enrôlement « nouveaux clients uniquement »**, à la première ouverture ; minimum 10 % de
   l'audience, ici 100 %. Les clients existants ne voient jamais un prix différent du leur.
5. **Le discount ne passe pas par une expérience RevenueCat** (il entrerait en conflit avec
   toutes les audiences) : l'app tire un bucket au hasard à la première ouverture, le mémorise,
   l'envoie à RevenueCat comme attribut client `discount_bucket`, et charge l'offering
   `offre_discount` ou `offre_discount_2999` en conséquence. Lecture : graphiques *Revenue* et
   *Trial/Paid conversion* segmentés par `offering_identifier` et par attribut client.

### 5.2 Les cinq audiences (nouveaux clients / jour, septembre 2026)

| Audience | Pays (codes storefront) | Nouveaux / j | Exposés au paywall / j | Ce qu'on y teste |
| --- | --- | ---: | ---: | --- |
| **A1** | IT, FR, NL, BE, CH, LU, US, GB, IE, CA, AU, NZ, SE, NO, DK, FI, IS | 715 | 608 | annuel 59,99 × mensuel sans essai |
| **A2** | ES, DE, AT, PT, GR, CY, MT, JP, KR, IL, SG, HK, TW, AE, SA, QA, KW | 673 | 572 | annuel 49,99 × hebdo 6,99 |
| **B** | PL, RO, HU, CZ, SK, HR, SI, BG, RS, BA, ME, MK, AL, MD, LT, LV, EE | 601 | 511 | palier 75 / 100 / 125 % |
| **TR** | TR | 489 | 416 | palier 100 / 50 / 25 % |
| **C** | MX, CO, AR, PE, BR, CL, EC, VE, BO, GT, DO, PY, CR, UY, HN, PA, SV, NI, et MENA (EG, MA, DZ, TN, JO, LB, IQ), Asie (IN, ID, PH, VN, TH, MY, PK, BD, KZ, AZ, UZ, GE, AM), Afrique (NG, ZA, KE, GH, SN, CI, CM), UA, RU, BY | 637 | 541 | palier 100 / 50 / 25 % |

Tout pays absent des listes tombe dans « aucune expérience » et garde l'offering courante ; on
complète les listes au lancement à partir de la liste complète des pays RevenueCat.

Le partage A1 / A2 mélange volontairement des pays à forte LTV (FR, DE) et à LTV moyenne (IT, ES)
dans chaque moitié, pour que les deux expériences soient comparables. La Hongrie (2,37 € par
nouveau client, meilleur pays d'Europe) et la Grèce (1,79 €) sont des anomalies de leur palier
PPP : la Grèce est mise en A2, la Hongrie reste en B et son bras 49,99 dira si elle supporte un
prix plein.

### 5.3 Matrice des expériences

| Expérience | Audience | Bras (annuel · plan court) | Produits iOS | Variables lues | Départ |
| --- | --- | --- | --- | --- | :---: |
| **A1** | A1 | ① 39,99 · mensuel 9,99 essai 3 j (contrôle = `fin_onboarding`) ② 59,99 · mensuel essai ③ 39,99 · mensuel **sans essai** ④ 59,99 · mensuel sans essai | `Sophia_yearly`, `Sophia_yearly_5999`, `Sophia_monthly`, `Sophia_monthly_notrial` | effet prix 59,99 = (②+④) vs (①+③) ; effet « sans essai » = (③+④) vs (①+②) ; interaction = ④ | **J0** |
| **A2** | A2 | ① 39,99 · mensuel essai (contrôle) ② 49,99 · mensuel essai ③ 39,99 · **hebdo 6,99** sans essai ④ 49,99 · hebdo | `Sophia_yearly_4999`, `Sophia_weekly_699` | effet prix 49,99 ; effet hebdo ; combo 49,99 + hebdo | J+14 (R1) |
| **B** | B | ① 39,99 (contrôle) ② **29,99** ③ **49,99** — mensuel 9,99 essai partout | `Sophia_yearly_2999`, `Sophia_yearly_4999` | élasticité Europe centrale | J+3 |
| **TR** | TR | ① 1 999,99 TRY (contrôle) ② ≈ 999,99 TRY ③ ≈ 499,99 TRY — mensuel local partout | `Sophia_yearly_t50`, `Sophia_yearly_t25` | palier Türkiye | J+3 |
| **C** | C | ① prix équilibré actuel (≈ 40 €) ② 50 % ③ 25 % | mêmes produits `_t50` / `_t25` (Apple équilibre 19,99 € et 9,99 € dans chaque devise) | palier pays émergents | J+3 |
| **Discount** | tous | ① `offre_discount` 19,99 € ② `offre_discount_2999` 29,99 € — tirage côté app | `discount_yearly`, `discount_yearly_2999` | profondeur de remise | J+14 (R1) |

Métrique de décision partout : **LTV réalisée par client à 30 jours (proceeds)**, avec lecture
provisoire à 14 jours. Diagnostics : conversion initiale, conversion d'essai, conversion payante,
part annuel / plan court, remboursements par bras. Les paliers TR et C se lisent aussi en
« revenu par client » en devise locale convertie, et en remboursements.

### 5.4 Ce qui ne bouge pas pendant les tests

- Les abonnés existants : aucun produit existant ne change de prix (sauf la baisse Android,
  § 6, qui ne peut que leur être favorable).
- Les paywalls `quizz`, `debloquer_cours` et `entrainement` : jusqu'à R1 ils continuent d'afficher
  39,99 € via leur offering propre ; à partir de R1 ils affichent le prix de l'offering servie
  par l'expérience (cohérence pour l'utilisateur, plus de fuite vers un prix plus bas).
- Le paywall de rétention (offre promotionnelle Apple `retention_14_99`) : inchangé.

---

## 6. Plan d'action jour par jour

### J0 — aujourd'hui

**RevenueCat (≈ 1 h, dashboard ou MCP avec une clé `read_write`)**

1. Entitlement `premium` → rattacher `Sophia_yearly_5999` (`prod2ad0152b81`) et
   `Sophia_monthly_notrial` (`prodbc71e740f7`). Sans ça, un achat dans ces bras encaisse sans
   débloquer Premium.
2. Créer 3 offerings copiées de `fin_onboarding` (mêmes packages `$rc_annual` / `$rc_monthly`,
   mêmes produits Test Store et Android) en changeant seulement le produit iOS visé :
   `a1__5999_mtrial`, `a1__3999_mnotrial`, `a1__5999_mnotrial`. Métadonnées : `experiment=A1`,
   `annual=5999|3999`, `monthly_trial=yes|no`.
3. Tester chaque offering sur un vrai appareil via *Customer → Offering override* (un achat
   sandbox par offering : prix affiché, essai affiché ou non, Premium débloqué).
4. Créer l'audience A1 (condition pays = liste § 5.2).
5. Créer l'expérience A1 : nouveaux clients, 100 %, 4 variantes, métrique primaire
   « Realized LTV per customer », notes = hypothèses et seuils (§ 9). **Lancer.**
6. Créer les audiences A2, B, TR, C (prêtes), et archiver les 19 offerings et ~20 paywalls
   orphelins pour garder l'écran des expériences lisible.

**App Store Connect (≈ 2 h)**

7. Créer 7 abonnements dans le groupe « Sophia Premium » (§ 7.1), localisations copiées de
   `Sophia_yearly`, prix de base FR, essai 3 j via offre d'introduction sauf mention contraire,
   captures et notes de revue identiques aux produits existants. Soumettre pour revue
   (sans binaire : 1 à 3 jours).
8. Vérifier la grille générée pour `Sophia_yearly_t50` et `Sophia_yearly_t25` en Türkiye
   (attendu ≈ 999,99 et 499,99 TRY) ; corriger le storefront TR à la main si Apple arrondit ailleurs.

**Play Console (≈ 1 h)**

9. Abonnement `sophia_pro` : créer les base plans `p1y-4999`, `p1y-5999`, `p1y-2999`, `p1y-t50`,
   `p1y-t25`, `monthly-notrial`, `weekly-699`, `annual-promo-2999` (§ 7.1), essai 3 j en offre
   sur les annuels. **Aligner** `p1y` 47,99 → 39,99 € et `annual-promo` 23,99 → 19,99 € (baisse :
   sans impact négatif pour les abonnés existants). Aucune revue.
10. Dans RevenueCat, importer les nouveaux produits Play et les rattacher à `premium`.

**Développement (démarrage de R1, § 8)** — objectif : soumission J+7.

### J+1 → J+3 — validation Apple, deuxième vague

11. À chaque produit approuvé : rattacher à `premium`, l'ajouter au package correspondant.
12. Créer les offerings B (`b__2999`, `b__4999`), TR (`tr__t50`, `tr__t25`), C (`c__t50`, `c__t25`),
    test appareil par override, puis créer et **lancer B, TR, C**.
13. Contrôles du jour 1 sur A1 (puis sur chacune) : dans *Results*, « Customers » et « Paywall
    viewers » qui montent sur les 4 bras (viewers ≈ 85 % des customers ; si 0, le tracking
    d'impressions des paywalls natifs est en cause et se corrige dans R1), premiers essais sur
    chaque bras dans les 24 h, aucun ticket support « j'ai payé mais rien n'est débloqué ».

### J+7 → J+14 — version R1

14. Soumission R1 iOS + Android à J+7 ; mise en ligne J+9 ; déploiement 100 % ; suivi de
    l'adoption dans RevenueCat (*App version*). À ≥ 80 % des nouveaux clients sur R1 : créer les
    offerings A2 (`a2__4999_mtrial`, `a2__3999_weekly`, `a2__4999_weekly`) et **lancer A2**.
15. Le test discount démarre de lui-même avec R1 (le tirage est dans l'app) ; créer avant J+9
    l'offering `offre_discount_2999` et vérifier que l'attribut `discount_bucket` remonte.

### J+21 — garde-fous

16. Par bras : remboursements, tickets support, taux de « set to cancel » des essais. Arrêt
    d'un bras seulement si remboursements > contrôle + 3 points ou conversion < 60 % du contrôle.
    Pas de décision positive à cette date.

### J+30 — premières décisions

17. TR et C : si un palier bas double (ou plus) la conversion payante, l'effet dépasse largement
    le MDE (48 % / 40 %) → décision. Sinon, on attend J+45.
18. A1 : lecture provisoire (MDE 24 %) ; décision si 59,99 € est clairement perdant (conv. < 60 %
    du contrôle) ou clairement neutre-gagnant sur la LTV 14 j.

### J+45 — décisions finales et vague suivante

19. A1, B, TR, C : décision sur la LTV 30 j (MDE 19 à 38 %). A2 et discount : provisoire (final J+60).
20. Déploiement : l'offering gagnante devient l'offering courante (Tier A) ou est servie par une
    règle de ciblage pays (B, TR, C) ; les offerings perdantes sont archivées ; les produits
    perdants retirés de la vente ; grille § 10 mise à jour.
21. Vague suivante, lancée le même jour sur les audiences libérées : essai 3 vs 7 jours sur
    l'annuel gagnant (A1), affinage ± 5 € autour du gagnant (B ou A1), plan court par palier
    (TR : hebdo local ?), mensuel sans essai généralisé si ③/④ l'emportent.

---

## 7. Matrice produits et offerings

### 7.1 Produits à créer (tous rattachés à `premium`)

| iOS (App Store Connect) | Play (base plan de `sophia_pro`) | Test Store | Prix de base FR | Essai | Sert à | État |
| --- | --- | --- | ---: | :---: | --- | --- |
| `Sophia_yearly_5999` | `p1y-5999` | `sophia_annual_5999` | 59,99 € | 3 j | A1 | **iOS approuvé** ; à rattacher |
| `Sophia_monthly_notrial` | `monthly-notrial` | `sophia_monthly_notrial` | 9,99 € | aucun | A1 | **iOS approuvé** ; à rattacher |
| `Sophia_yearly_4999` | `p1y-4999` | `sophia_annual_4999` | 49,99 € | 3 j | A2, B | à créer |
| `Sophia_weekly_699` | `weekly-699` | `sophia_weekly_699` | 6,99 € / semaine | aucun | A2 | à créer |
| `Sophia_yearly_2999` | `p1y-2999` | `sophia_annual_2999` | 29,99 € | 3 j | B | à créer |
| `Sophia_yearly_t50` | `p1y-t50` | `sophia_annual_t50` | 19,99 € (≈ 999,99 TRY) | 3 j | TR, C | à créer |
| `Sophia_yearly_t25` | `p1y-t25` | `sophia_annual_t25` | 9,99 € (≈ 499,99 TRY) | 3 j | TR, C | à créer |
| `discount_yearly_2999` | `annual-promo-2999` | `discount_yearly_2999` | 29,99 € | aucun | Discount | à créer |
| `Sophia_yearly_trial7` | `p1y-trial7` | — | prix gagnant A1/A2 | **7 j** | vague suivante | à créer à J+30 |

Règles : jamais de changement de prix sur `Sophia_yearly`, `Sophia_monthly`, `discount_yearly`
(abonnés existants) ; identifiants immuables ; un produit par point de prix ; localisations et
captures copiées ; les paliers `_t50` / `_t25` utilisent l'équilibrage Apple et Google à partir
de 19,99 € / 9,99 €, ce qui donne automatiquement ≈ 50 % / 25 % dans chaque devise (Türkiye,
Mexique, Brésil, Inde…), avec vérification manuelle des 5 plus gros storefronts.

### 7.2 Offerings par expérience

| Offering | `$rc_annual` (iOS / Play / Test) | `$rc_monthly` ou `$rc_weekly` | Expérience · bras |
| --- | --- | --- | --- |
| `fin_onboarding` (existante, courante) | `Sophia_yearly` / `p1y` / `sophia_annual` | `$rc_monthly` : `Sophia_monthly` / `monthly` / `sophia_monthly` | contrôle de A1, A2, B, TR, C |
| `a1__5999_mtrial` | `Sophia_yearly_5999` / `p1y-5999` | `$rc_monthly` : `Sophia_monthly` | A1 · ② |
| `a1__3999_mnotrial` | `Sophia_yearly` / `p1y` | `$rc_monthly` : `Sophia_monthly_notrial` / `monthly-notrial` | A1 · ③ |
| `a1__5999_mnotrial` | `Sophia_yearly_5999` | `$rc_monthly` : `Sophia_monthly_notrial` | A1 · ④ |
| `a2__4999_mtrial` | `Sophia_yearly_4999` / `p1y-4999` | `$rc_monthly` : `Sophia_monthly` | A2 · ② |
| `a2__3999_weekly` | `Sophia_yearly` | `$rc_weekly` : `Sophia_weekly_699` / `weekly-699` | A2 · ③ |
| `a2__4999_weekly` | `Sophia_yearly_4999` | `$rc_weekly` : `Sophia_weekly_699` | A2 · ④ |
| `b__2999` | `Sophia_yearly_2999` / `p1y-2999` | `$rc_monthly` : `Sophia_monthly` | B · ② |
| `b__4999` | `Sophia_yearly_4999` | `$rc_monthly` : `Sophia_monthly` | B · ③ |
| `tr__t50`, `c__t50` | `Sophia_yearly_t50` / `p1y-t50` | `$rc_monthly` : `Sophia_monthly` | TR · ②, C · ② |
| `tr__t25`, `c__t25` | `Sophia_yearly_t25` / `p1y-t25` | `$rc_monthly` : `Sophia_monthly` | TR · ③, C · ③ |
| `offre_discount` (existante) | `discount_yearly` / `annual-promo` | — | Discount · ① |
| `offre_discount_2999` | `discount_yearly_2999` / `annual-promo-2999` | — | Discount · ② |

Le mensuel des paliers TR / C reste `Sophia_monthly` (≈ 499,99 TRY / mois) : volontairement, pour
que l'annuel à 999 ou 499 TRY paraisse imbattable. Un mensuel de palier sera testé en vague suivante.

### 7.3 Réglages de chaque expérience

Type « Custom » (2×2) ou « Price point » (paliers) ; enrôlement **nouveaux clients uniquement** ;
**100 %** de l'audience ; audience = règle pays ; variantes nommées comme les offerings ; métrique
primaire *Realized LTV per customer* ; secondaires *initial conversion*, *trial conversion*,
*conversion to paying*, *refunds* ; notes = hypothèse, seuil de neutralité, date de lecture.

---

## 8. Version R1 (iOS + Android) — soumission J+7

| # | Changement | iOS | Android | Pourquoi |
| --- | --- | --- | --- | --- |
| 1 | Paywalls `quizz`, `debloquer_cours`, `entrainement` : prendre `$rc_annual` / `$rc_monthly` dans `offerings.current` (offering servie par l'expérience), repli sur l'offering du contexte ; garder l'attribution d'impression au contexte | `StoreViewModel.annualPackage(forOfferingIdentifier:)`, `SophiaNativePaywalls.swift` | `StoreViewModel.kt`, `PaywallScreen.kt` | Prix cohérent pour l'utilisateur ; plus de fuite vers 39,99 € pour les bras 49,99 / 59,99 |
| 2 | Package hebdo : `weeklyPackage` (`$rc_weekly`), paywall comparatif « Annuel vs Hebdo » quand le mensuel est absent, prix ramené à la semaine, CTA sans mention d'essai | `StoreViewModel.swift`, `OnboardingV2Paywalls.swift`, `SophiaNativePaywalls.swift` | `StoreViewModel.kt`, `PaywallScreen.kt` | A2 |
| 3 | Test discount côté app : bucket `A`/`B` tiré à la première ouverture (UserDefaults / DataStore), attribut RevenueCat `discount_bucket`, offering `offre_discount` ou `offre_discount_2999`, impression trackée avec la bonne offering | `DiscountOfferManager.swift`, `StoreViewModel.promoPackage` | `DiscountOfferManager.kt` (équivalent) | Discount sur 100 % du trafic sans conflit d'audience |
| 4 | Durée d'essai dynamique : lire `introductoryDiscount.subscriptionPeriod` et l'injecter dans les 21 textes « 3 jours » (clé paramétrée `{days}`), rappel J-1 calé sur la vraie durée | `AppLocalizable.swift`, `OnboardingV2TrialSteps.swift`, `SophiaNativePaywalls.swift` | `OnboardingV2Screen.kt`, `TrialReminderScheduler.kt` | Prêt pour l'essai 7 jours (vague suivante) sans nouvelle version |
| 5 | Textes de repli sans prix codé en dur (26 occurrences iOS, clés `paywall.plan.fallback.*` Android) : afficher « — » ou masquer le prix tant que StoreKit / Billing n'a pas répondu | `AppLocalizable.swift`, `StoreViewModel.swift` | `strings/*.json` | Un bras à 59,99 € ne doit jamais afficher « 39,99 € » en secours |
| 6 | Vérifier que `trackCustomPaywallImpression` est appelé une fois par présentation avec l'offering réellement servie | `SophiaNativePaywalls.swift` | `PaywallScreen.kt` | « Paywall viewers » des expériences |

Estimation : 3 jours iOS, 2 jours Android, 1 jour de QA (achats sandbox sur chaque offering
listée en § 7.2, y compris Test Store). Pas de Placements RevenueCat dans R1 : ils ne sont pas
nécessaires avec le point 1 et ajouteraient un risque d'interaction avec les expériences déjà
lancées. À reconsidérer après la vague 1.

---

## 9. Lecture des résultats et décisions

### 9.1 Lire un plan 2×2 dans RevenueCat

RevenueCat compare chaque variante au contrôle. Pour A1 et A2, on lit aussi les **effets
principaux** en regroupant les bras (je les calcule chaque semaine via le MCP) :

- effet du prix = LTV/client moyenne pondérée de (② + ④) contre (① + ③) ;
- effet du plan court = (③ + ④) contre (① + ②) ;
- interaction = ④ comparé à ce que ① + les deux effets laisseraient attendre. Si ④ est meilleur
  que la somme des effets, le combo est retenu tel quel.

### 9.2 Règles

1. Décision sur la **LTV réalisée par client à 30 jours (proceeds)**. Les conversions sont des
   diagnostics.
2. **Victoire** : probabilité de battre le contrôle ≥ 95 % et intervalle du lift excluant 0, ou,
   pour un effet principal 2×2, différence supérieure au MDE du jour (tableau § 0). **Match nul**
   sur la LTV : on garde le prix le plus élevé si les remboursements ne montent pas (moins de
   clients à servir pour le même revenu), sinon le contrôle.
3. **Arrêt d'un bras** avant la date : remboursements > contrôle + 3 points, ou conversion
   payante < 60 % du contrôle après 4 000 exposés. Un bras arrêté = expérience mise en pause,
   pas stoppée (les données continuent de mûrir).
4. **Pas de lecture positive avant J+30**, garde-fous exceptés.
5. **Déploiement** : Tier A → l'offering gagnante devient courante ; B, TR, C → règle de ciblage
   pays servant l'offering gagnante ; discount → l'app fixe le bucket gagnant pour tous.
6. **Journal** : une ligne par expérience dans ce fichier (départ, taille, décision, offering
   déployée), l'offering perdante archivée le jour même.

### 9.3 Suivi hebdomadaire (lecture seule, via le MCP)

Chaque lundi : tableau par expérience et par bras (customers, viewers, essais, conversions,
LTV 14 j / 30 j, remboursements), effets principaux 2×2, remboursements et conversion d'essai par
pays, taux d'adoption de R1, anomalies (« Unknown », attribution, produits manquants). Une page
dans `docs/` par semaine.

---

## 10. Grille de prix par pays (hypothèse, mise à jour à J+45)

| Palier | Pays | Annuel | Plan court | Discount | Décidé par |
| --- | --- | --- | --- | --- | --- |
| A | A1 + A2 (§ 5.2) | 39,99 → 49,99 ou 59,99 | mensuel 9,99 (avec / sans essai) ou hebdo 6,99 | 19,99 ou 29,99 | A1, A2, Discount |
| B | Europe centrale et Balkans | 29,99 / 39,99 / 49,99 | mensuel 9,99 | 50 % de l'annuel retenu | B |
| C-TR | Türkiye | 1 999 / 999 / 499 TRY | mensuel ≈ 499 TRY (à tester ensuite) | 50 % de l'annuel retenu | TR |
| C | LatAm, MENA, Asie, Afrique | 100 / 50 / 25 % | mensuel local | 50 % de l'annuel retenu | C |

Android aligné sur iOS dès J0 (47,99 → 39,99 €, promo 23,99 → 19,99 €), puis suit les décisions.
Les prix fixés par storefront ne suivent pas l'inflation : revue trimestrielle pour la Türkiye et
l'Argentine.

---

## 11. Risques et parades

| Risque | Parade |
| --- | --- |
| Un bras encaisse sans débloquer Premium (produit non rattaché) | Rattachement vérifié par achat sandbox avant chaque lancement (§ 6, étapes 3 et 12) |
| « Paywall viewers » à zéro (impressions natives non comptées) | Contrôle J+1 ; correctif dans R1 (§ 8, point 6) ; les métriques « Customers » restent exploitables |
| Fuite de prix : un utilisateur du bras 59,99 achète à 39,99 sur le paywall quiz | Biais conservateur jusqu'à R1 (16 % des essais), supprimé par R1 point 1 |
| Remboursements en hausse sur les bras chers | Garde-fou J+21 (+3 points) ; rappel J-1 de fin d'essai actif ; texte du CTA explicite sur le montant |
| Revue Apple des produits > 3 jours | A1 part sans attendre ; B, TR, C décalés d'autant, rien d'autre ne bouge |
| Adoption lente de R1 | A2 et discount démarrent à 80 % d'adoption, pas avant ; les utilisateurs sur l'ancienne version restent hors A2 (audience pays + version d'app si besoin) |
| Chevauchement d'audiences refusé par RevenueCat | Listes de pays disjointes par construction ; un pays ne figure que dans une audience |
| Inflation TRY / ARS | Prix TR et AR revus tous les trimestres |
| Trafic qui retombe (fin de viralité) | Les dates de lecture sont recalculées chaque semaine sur le volume réel |
| Décisions contradictoires entre A1 (59,99) et A2 (49,99) | Les deux se comparent à leur contrôle 39,99 : on retient le lift de LTV le plus élevé, puis on confronte 49,99 et 59,99 en tête-à-tête en vague suivante si les deux gagnent |

---

## Annexes

### A. Identifiants utiles

- Projet `proj3f496a80` · apps `app152440cc2e` (App Store), `app3dcadd8517` (Play), `app257be138ae` (Test Store).
- Entitlement `premium` = `entl5b0c63b9a1`.
- Offerings : `fin_onboarding` = `ofrngb1bfff7210` (courante), `offre_discount` = `ofrng8974f13d40`,
  `quizz` = `ofrng2d26aa3789`, `debloquer_cours` = `ofrng0b892fe7f7`.
- Produits iOS : `Sophia_yearly` = `prodf40359e7e1`, `Sophia_monthly` = `prodf59fa512ae`,
  `Sophia_yearly_5999` = `prod2ad0152b81` (approuvé), `Sophia_monthly_notrial` = `prodbc71e740f7`
  (approuvé), `discount_yearly` = `prod87ca86a482`.
- Produits Play : `sophia_pro:p1y` = `prod4d34542d2a`, `sophia_pro:monthly` = `prod7460a66c69`,
  `sophia_pro:annual-promo` = `prod707c4e8f3a`.

### B. Contrôles du jour 1 d'une expérience

1. « Customers » répartis à ± 5 % entre les bras au bout de 24 h.
2. « Paywall viewers » ≈ 85 % des customers sur chaque bras.
3. Au moins un essai démarré et un achat direct visibles sur chaque bras.
4. Le prix affiché correspond au bras (capture depuis un appareil avec override).
5. Aucun achat attribué à « Unknown » en hausse.

### C. Ce que je peux faire moi-même

- Avec la clé actuelle (lecture seule) : suivi hebdomadaire, effets 2×2, alertes garde-fous,
  mise à jour de ce document.
- Avec une clé `read_write` dans l'environnement : rattachements à l'entitlement, création des
  offerings et des packages, audiences et expériences si le MCP les expose, archivage des
  offerings orphelines. La création des produits reste dans App Store Connect et Play Console.
- Dans le repo : la version R1 (§ 8) sur cette branche, prête pour revue.
