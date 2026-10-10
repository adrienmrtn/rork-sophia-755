# Plan d'A/B tests prix — Sophia (lancement simultané, v3)

Analyse faite les 26–27/09/2026 à partir des données RevenueCat (projet `proj3f496a80`, clé lecture
seule), du code iOS/Android et d'une veille concurrentielle. Version 3 : **cinq tests de prix
lancés le même jour**, dès validation Apple des produits soumis lundi 28/09, avec un groupe de
pays à fort pouvoir d'achat qui teste jusqu'à **69,99 €**. L'hebdo, le discount et l'essai de
7 jours forment la vague 2 (J+45), portée par la version R1 de l'app. **Rien n'a encore été
modifié** : ni dans RevenueCat, ni dans App Store Connect / Play Console, ni dans le code.

Sommaire : 0. Résumé · 1. Photographie chiffrée · 2. Leçons des 5 expériences passées ·
3. Grille de prix actuelle par pays · 4. Concurrents · 5. Architecture · 6. Plan d'action jour
par jour · 7. Matrice produits et offerings · 8. Version R1 (code) · 9. Lecture des résultats et
décisions · 10. Grille de prix par pays · 11. Risques · Annexes.

---

## 0. Résumé

- **Le contexte** (§ 1 à 4) : ~3 100 nouveaux clients par jour, annuel = 95 % du revenu, paywall
  de fin d'onboarding = 84 % des essais, remboursements 10,8 %, conversion d'essai 32 %. 39,99 €
  est dans le bas de la fourchette Éducation (médiane 44,99 $ ; Headway, Blinkist, Imprint entre
  80 et 100 €, donc 69,99 € reste sous les références « savoir »). La grille par pays est une
  simple conversion de change ; la Türkiye paie 2 à 10 fois plus cher que chez les concurrents.
- **Deux règles RevenueCat dictent l'architecture** : pas de chevauchement d'audiences entre
  expériences actives, et 4 variantes maximum. Donc **cinq groupes de pays disjoints**, un test
  par groupe, et deux variables par test quand le volume le permet (plan 2×2).
- **Les cinq tests, lancés le même jour** (J0 = jour de validation Apple, attendu entre le 29/09
  et le 01/10) :

| Groupe | Pays | Test | Question |
| --- | --- | --- | --- |
| **P** fort pouvoir d'achat | FR DE AT CH NL BE LU US GB IE CA AU NZ Nordiques | annuel **39,99 / 49,99 / 59,99 / 69,99 €** | où la demande décroche-t-elle chez les plus solvables ? |
| **S** Europe du Sud | IT ES PT GR CY MT | annuel 39,99 vs **49,99 €** × mensuel **avec vs sans essai** | 49,99 rapporte-t-il plus ? l'essai sur le mensuel sert-il ? |
| **B** Europe centrale | PL RO HU CZ SK HR SI BG RS BA ME MK AL MD LT LV EE | annuel **29,99 / 39,99 / 49,99 €** | faut-il un palier plus bas, ou pas ? |
| **TR** Türkiye | TR | annuel **1 999 / 999 / 499 TRY** | quel prix rapporte le plus en Türkiye ? |
| **C** émergents | LatAm, MENA, Asie du Sud et du Sud-Est, Afrique, UA, RU | annuel **100 / 50 / 25 %** du prix actuel | quel palier pour les pays à faible pouvoir d'achat ? |

- **Ce qu'il faut pour lancer** : soumettre 5 produits à Apple lundi (49,99 ; 69,99 ; 29,99 ;
  palier 50 % ; palier 25 %), rattacher à l'entitlement `premium` les deux produits déjà validés
  (`Sophia_yearly_5999`, `Sophia_monthly_notrial`) et les nouveaux, créer 12 offerings, 5 audiences,
  5 expériences. Aucune nouvelle version d'app n'est nécessaire pour ces cinq tests.
- **Vague 2 à J+45, avec la version R1** : hebdo 6,99 €, discount 19,99 vs 29,99 €, essai 7 jours,
  et 59,99 € en Europe du Sud si 49,99 gagne. R1 est développée dès cette semaine parce qu'elle
  règle aussi une fuite des tests de prix : les paywalls quiz et cours affichent 39,99 € quel que
  soit le groupe.
- **Quand on saura** : garde-fous J+21 ; premières décisions J+30 (Türkiye, émergents) ; décisions
  J+45 (Europe du Sud, Europe centrale, Türkiye, émergents, et 69,99 / 59,99 dans le groupe P) ;
  confirmation fine du groupe P à J+60.

Effet minimum détectable (baisse relative de conversion payante, puissance 80 %) :

| Test | Exposés / j | J+30 | J+45 | J+60 | Seuil de neutralité de la variante |
| --- | ---: | ---: | ---: | ---: | --- |
| P · échelle 4 prix | 479 | 35 % | 28 % | 25 % | 49,99 rentable si conv. ≥ 80 % du contrôle ; 59,99 ≥ 67 % ; **69,99 ≥ 57 %** |
| S · 49,99 × essai mensuel (2×2) | 713 | 23 % | 18 % | 16 % | 49,99 ≥ 80 % |
| B · 29,99 / 39,99 / 49,99 | 519 | 32 % | 26 % | 23 % | 29,99 ≥ 133 % ; 49,99 ≥ 80 % |
| TR · 1 999 / 999 / 499 TRY | 416 | 45 % | 37 % | 32 % | 999 ≥ ×2 ; 499 ≥ ×4 |
| C · 100 / 50 / 25 % | 541 | 38 % | 31 % | 27 % | idem |

Lecture : le groupe P tranche 69,99 € (il est perdant dès que la conversion baisse de plus de
43 %, on détecte 28 % à J+45) et 59,99 € ; il ne tranche pas seul 49,99 €, que le groupe S mesure
avec la meilleure puissance du programme (18 % à J+45 pour un seuil à 20 %).

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

---

## 5. Architecture

### 5.1 Les règles RevenueCat qui contraignent le design

1. **Pas de chevauchement d'audiences** entre expériences actives : l'interface refuse le
   lancement. Un client n'est enrôlé que dans une expérience. → Audiences définies par **pays**,
   disjointes par construction.
2. **4 variantes maximum**. → Une échelle de 4 prix (groupe P), un plan factoriel 2×2 (groupe S :
   chaque effet se lit sur 2 bras contre 2, ce qui double la puissance), ou 3 paliers (B, TR, C).
3. **Une expérience remplace l'offering courante.** Les paywalls d'onboarding lisent
   `offerings.current` : aucune modification d'app pour les tests de prix et d'essai mensuel.
   L'hebdo demande du code (`$rc_weekly` inconnu des apps), d'où la vague 2.
4. **Enrôlement « nouveaux clients uniquement »**, 100 % du groupe. Les abonnés existants ne
   voient jamais un autre prix que le leur.
5. **Le discount** passera par un tirage côté app (vague 2), pour toucher 100 % du trafic sans
   entrer en conflit avec les audiences.

### 5.2 Les cinq groupes (nouveaux clients / jour, septembre 2026)

| Groupe | Pays (codes storefront) | Nouveaux / j | Exposés / j | Part du revenu sept. |
| --- | --- | ---: | ---: | ---: |
| **P** | FR, DE, AT, CH, NL, BE, LU, US, GB, IE, CA, AU, NZ, SE, NO, DK, FI, IS | 564 | 479 | 31 % |
| **S** | IT, ES, PT, GR, CY, MT | 839 | 713 | 25 % |
| **B** | PL, RO, HU, CZ, SK, HR, SI, BG, RS, BA, ME, MK, AL, MD, LT, LV, EE | 611 | 519 | 24 % |
| **TR** | TR | 489 | 416 | 11 % |
| **C** | MX, CO, AR, PE, BR, CL, EC, VE, BO, GT, DO, PY, CR, UY, HN, PA, SV, NI ; EG, MA, DZ, TN, JO, LB, IQ, SA, AE, QA, KW ; IN, ID, PH, VN, TH, MY, PK, BD, KZ, AZ, UZ, GE, AM ; NG, ZA, KE, GH, SN, CI, CM ; UA, RU, BY ; JP, KR, IL, SG, HK, TW | 637 | 541 | 8 % |

Choix à assumer : la Hongrie (2,37 € par nouveau client, meilleur pays d'Europe) et la Grèce
(1,79 €) contredisent leur palier PPP ; la Grèce va en S (elle y teste 49,99), la Hongrie reste en
B où le bras 49,99 dira si elle supporte un prix plein. Japon, Corée, Israël, Singapour et le
Golfe sont à fort pouvoir d'achat mais quasi absents du trafic : ils vont en C pour ne pas
brouiller P, et suivront la grille finale de P. Tout pays absent des listes garde l'offering
courante.

### 5.3 Matrice des expériences

| Test | Groupe | Bras (annuel · mensuel) | Produits iOS nécessaires | Ce qu'on lit | Départ |
| --- | --- | --- | --- | --- | :---: |
| **P** | P | ① 39,99 (contrôle `fin_onboarding`) ② 49,99 ③ 59,99 ④ **69,99** — mensuel 9,99 essai 3 j partout | `Sophia_yearly_4999`, `Sophia_yearly_5999` (validé), `Sophia_yearly_6999` | courbe de demande à 4 points, revenu par exposé à chaque prix | J0 |
| **S** | S | ① 39,99 · essai (contrôle) ② 49,99 · essai ③ 39,99 · **sans essai** ④ 49,99 · sans essai | `Sophia_yearly_4999`, `Sophia_monthly_notrial` (validé) | effet prix = (②+④) vs (①+③) ; effet essai = (③+④) vs (①+②) ; combo = ④ | J0 |
| **B** | B | ① 39,99 (contrôle) ② 29,99 ③ 49,99 | `Sophia_yearly_2999`, `Sophia_yearly_4999` | élasticité Europe centrale | J0 |
| **TR** | TR | ① 1 999,99 TRY (contrôle) ② ≈ 999,99 ③ ≈ 499,99 | `Sophia_yearly_t50`, `Sophia_yearly_t25` | palier Türkiye | J0 |
| **C** | C | ① prix équilibré actuel ② 50 % ③ 25 % | mêmes `_t50` / `_t25` (Apple équilibre 19,99 € et 9,99 € dans chaque devise) | palier émergents | J0 |

J0 = jour où Apple a validé les 5 nouveaux produits ; les cinq tests partent le même jour pour
partager la même saisonnalité. Métrique de décision partout : **LTV réalisée par client à
30 jours (proceeds)**, lecture provisoire à 14 jours. Diagnostics : conversion initiale, conversion
d'essai, conversion payante, part annuel / mensuel, remboursements par bras.

### 5.4 Vague 2 (J+45, avec R1)

Sur les groupes libérés par les décisions de J+45 :

| Test | Groupe pressenti | Bras | Prérequis |
| --- | --- | --- | --- |
| Hebdo | S ou P (au prix annuel retenu) | mensuel 9,99 vs **hebdo 6,99** sans essai (× annuel retenu) | R1 (`$rc_weekly`), `Sophia_weekly_699` |
| Discount | tous | 19,99 vs **29,99 €** (ou 24,99 si l'annuel monte), tirage côté app | R1 (bucket), `discount_yearly_2999` |
| Essai 7 jours | P (au prix retenu) | essai **3 vs 7 jours** sur l'annuel | R1 (textes dynamiques), `Sophia_yearly_trial7` |
| 59,99 en Europe du Sud | S | si 49,99 gagne à J+45 : 49,99 vs 59,99 | `Sophia_yearly_5999` |
| Affinage P | P | ± 5 € autour du gagnant (ex. 54,99 / 64,99) | nouveaux produits |

### 5.5 Ce qui ne bouge pas

Aucun produit existant ne change de prix (sauf la baisse Android, favorable aux abonnés). Le
paywall de rétention (`retention_14_99`) reste tel quel. Jusqu'à R1, les paywalls quiz, cours et
entraînement affichent 39,99 € pour tout le monde : biais conservateur (un utilisateur du bras
69,99 peut acheter à 39,99 ailleurs, 16 % des essais), corrigé par R1.

---

## 6. Plan d'action jour par jour

### Lundi 28/09 — soumission et préparation

**App Store Connect (≈ 2 h)** — groupe d'abonnement « Sophia Premium », localisations et captures
copiées de `Sophia_yearly`, essai 3 jours en offre d'introduction sauf mention contraire :

| Identifiant | Prix de base FR | Essai | Sert à |
| --- | ---: | :---: | --- |
| `Sophia_yearly_4999` | 49,99 € | 3 j | P, S, B |
| `Sophia_yearly_6999` | 69,99 € | 3 j | P |
| `Sophia_yearly_2999` | 29,99 € | 3 j | B |
| `Sophia_yearly_t50` | 19,99 € (≈ 999,99 TRY) | 3 j | TR, C |
| `Sophia_yearly_t25` | 9,99 € (≈ 499,99 TRY) | 3 j | TR, C |
| `Sophia_weekly_699` | 6,99 € / semaine | aucun | vague 2 |
| `discount_yearly_2999` | 29,99 € | aucun | vague 2 |

**Ou automatisé** : workflow GitHub « Pricing tests » (`.github/workflows/pricing-tests.yml`,
manifeste `appstore/subscriptions/price_tests.json`) : `appstore · plan` puis `apply` créent les 7
abonnements avec localisations, disponibilité, grille de prix et essai ; `status` puis `submit`
soumettent le groupe. Détail dans `docs/soumission-apple-lundi.md` § 0.

Soumettre les 7 d'un coup (revue sans binaire, 1 à 3 jours). Vérifier la grille générée pour
`_t50` et `_t25` en Türkiye, Mexique, Brésil, Inde ; corriger le storefront à la main si Apple
arrondit loin de 50 % / 25 %.

**Play Console (≈ 1 h)** — abonnement `sophia_pro` : base plans `p1y-4999`, `p1y-5999`, `p1y-6999`,
`p1y-2999`, `p1y-t50`, `p1y-t25`, `monthly-notrial`, `weekly-699`, `annual-promo-2999` (essai 3 j
en offre sur les annuels ; `p1y-5999` et `monthly-notrial` n'existaient que côté iOS). **Aligner** `p1y` 47,99 → 39,99 € et `annual-promo` 23,99 → 19,99 €.
Aucune revue. Puis importer les produits Play dans RevenueCat.

**RevenueCat (≈ 2 h, dashboard ou MCP avec une clé `read_write`)** — les points 1 et 3 sont
couverts par le workflow (`revenuecat · plan` puis `apply`, secret `REVENUECAT_SECRET_API_KEY`) ;
les points 2 et 4 aussi (`revenuecat-experiments · plan` puis `apply`, l'API v2 crée audiences et
expériences en brouillon ; il n'y a pas d'endpoint pour les démarrer, le Start reste un clic).
Décision du 27/09 : Play Console est reporté après les résultats iOS, les audiences portent donc
une condition `platform = ios` et Android garde l'offering courante pendant les tests.

1. Entitlement `premium` → rattacher `Sophia_yearly_5999` (`prod2ad0152b81`) et
   `Sophia_monthly_notrial` (`prodbc71e740f7`), ainsi que tous les produits Play créés.
2. Créer les 5 audiences (listes § 5.2).
3. Créer les 12 offerings (§ 7.2) : copie de `fin_onboarding`, seul le produit visé change ; les
   packages dont le produit iOS n'est pas encore validé restent en attente.
4. Créer les 5 expériences en brouillon (§ 7.3), sans les lancer.
5. Archiver les 19 offerings et ~20 paywalls orphelins (lisibilité de l'écran des expériences).

**Code** — démarrage de R1 (§ 8), objectif soumission jeudi 01/10.

### J0 — le jour de la validation Apple (attendu 29/09 → 01/10)

6. Pour chaque produit validé : rattacher à `premium`, l'ajouter à son package.
7. Pour chaque offering : un achat sandbox sur appareil réel via *Customer → Offering override*
   (prix affiché, essai affiché ou non, Premium débloqué). 12 achats, une heure.
8. **Lancer les 5 expériences le même jour.** Si un produit traîne en revue, on attend qu'il
   soit validé plutôt que de lancer en ordre dispersé, sauf au-delà de 3 jours : on lance alors
   ce qui est prêt et le test manquant suit.
9. Contrôles J0+24 h sur chaque test : « Customers » répartis à ± 5 % entre bras, « Paywall
   viewers » ≈ 85 % des customers, un essai et un achat visibles par bras, aucun ticket
   « payé mais rien débloqué ».

### J+3 → J+10 — R1

10. Soumission R1 iOS + Android le 01/10 ; en ligne vers le 03/10 ; suivi de l'adoption
    (*App version* dans RevenueCat). R1 ne modifie pas les tests en cours : elle rend les prix
    cohérents entre paywalls et prépare la vague 2.

### J+21 — garde-fous

11. Par bras : remboursements, tickets, essais « set to cancel ». Pause d'un bras seulement si
    remboursements > contrôle + 3 points ou conversion < 60 % du contrôle après 4 000 exposés.
    Le bras 69,99 est le premier candidat : surveillance quotidienne de ses remboursements.

### J+30 — premières décisions

12. TR et C : si un palier bas double au moins la conversion payante, décision (l'effet dépasse
    le MDE de 45 % / 38 %). Sinon J+45.
13. P et S : lecture provisoire sur la LTV 14 j. Décision anticipée seulement si un bras est
    clairement perdant (conv. < 60 % du contrôle).

### J+45 — décisions et vague 2

14. S, B, TR, C : décision sur la LTV 30 j. P : décision sur 69,99 et 59,99 ; 49,99 confirmé par S.
15. Déploiement : offering gagnante servie par règle de ciblage pays pour chaque groupe (P, S,
    B, TR, C peuvent avoir chacun leur prix) ; offerings perdantes archivées ; produits perdants
    retirés de la vente ; grille § 10 mise à jour.
16. Lancement de la vague 2 (§ 5.4) le même jour sur les groupes libérés.

### J+60 — confirmation P

17. Lecture finale du groupe P (MDE 25 %) et de l'affinage éventuel.

---

## 7. Matrice produits et offerings

### 7.1 Produits (tous rattachés à `premium`)

| iOS | Play (base plan `sophia_pro`) | Test Store | Prix de base | Essai | Sert à | État |
| --- | --- | --- | ---: | :---: | --- | --- |
| `Sophia_yearly` | `p1y` | `sophia_annual` | 39,99 € (Play 47,99 → **39,99**) | 3 j | contrôle partout | existe |
| `Sophia_monthly` | `monthly` | `sophia_monthly` | 9,99 € | 3 j | mensuel partout | existe |
| `Sophia_yearly_5999` | `p1y-5999` | `sophia_annual_5999` | 59,99 € | 3 j | P | iOS validé, **à rattacher** |
| `Sophia_monthly_notrial` | `monthly-notrial` | `sophia_monthly_notrial` | 9,99 € | aucun | S | iOS validé, **à rattacher** |
| `Sophia_yearly_4999` | `p1y-4999` | `sophia_annual_4999` | 49,99 € | 3 j | P, S, B | à créer |
| `Sophia_yearly_6999` | `p1y-6999` | `sophia_annual_6999` | 69,99 € | 3 j | P | à créer |
| `Sophia_yearly_2999` | `p1y-2999` | `sophia_annual_2999` | 29,99 € | 3 j | B | à créer |
| `Sophia_yearly_t50` | `p1y-t50` | `sophia_annual_t50` | 19,99 € (≈ 999,99 TRY) | 3 j | TR, C | à créer |
| `Sophia_yearly_t25` | `p1y-t25` | `sophia_annual_t25` | 9,99 € (≈ 499,99 TRY) | 3 j | TR, C | à créer |
| `Sophia_weekly_699` | `weekly-699` | `sophia_weekly_699` | 6,99 € / sem. | aucun | vague 2 | à créer |
| `discount_yearly_2999` | `annual-promo-2999` | `discount_yearly_2999` | 29,99 € | aucun | vague 2 | à créer |
| `Sophia_yearly_trial7` | `p1y-trial7` | — | prix retenu | 7 j | vague 2 | à créer à J+30 |

Règles : jamais de changement de prix sur un produit existant (hors baisse Android) ; un produit
par point de prix ; identifiants immuables ; les paliers `_t50` / `_t25` s'appuient sur
l'équilibrage Apple / Google à partir de 19,99 € / 9,99 €.

### 7.2 Offerings (copies de `fin_onboarding`, packages `$rc_annual` + `$rc_monthly`, produits iOS + Play + Test Store)

| Offering | `$rc_annual` | `$rc_monthly` | Test · bras |
| --- | --- | --- | --- |
| `fin_onboarding` (existante, courante) | `Sophia_yearly` | `Sophia_monthly` | contrôle de P, S, B, TR, C |
| `p__4999` | `Sophia_yearly_4999` | `Sophia_monthly` | P · ② |
| `p__5999` | `Sophia_yearly_5999` | `Sophia_monthly` | P · ③ |
| `p__6999` | `Sophia_yearly_6999` | `Sophia_monthly` | P · ④ |
| `s__4999_mtrial` | `Sophia_yearly_4999` | `Sophia_monthly` | S · ② |
| `s__3999_mnotrial` | `Sophia_yearly` | `Sophia_monthly_notrial` | S · ③ |
| `s__4999_mnotrial` | `Sophia_yearly_4999` | `Sophia_monthly_notrial` | S · ④ |
| `b__2999` | `Sophia_yearly_2999` | `Sophia_monthly` | B · ② |
| `b__4999` | `Sophia_yearly_4999` | `Sophia_monthly` | B · ③ |
| `tr__t50` / `c__t50` | `Sophia_yearly_t50` | `Sophia_monthly` | TR · ②, C · ② |
| `tr__t25` / `c__t25` | `Sophia_yearly_t25` | `Sophia_monthly` | TR · ③, C · ③ |

`p__4999` et `b__4999` pointent sur le même produit mais restent deux offerings, pour que
l'attribution par offering reste lisible test par test. Le mensuel des paliers TR / C reste
`Sophia_monthly` (≈ 499,99 TRY) : volontairement, l'annuel à 999 ou 499 TRY paraît imbattable ;
un mensuel de palier est une question de vague 2.

### 7.3 Réglages des expériences

| Réglage | Valeur |
| --- | --- |
| Type | « Price point » (P, B, TR, C) ; « Custom » (S) |
| Enrôlement | nouveaux clients uniquement, 100 % de l'audience |
| Audience | règle pays du groupe (§ 5.2) |
| Variantes | nommées comme les offerings ; contrôle = `fin_onboarding` |
| Métrique primaire | Realized LTV per customer |
| Secondaires | initial conversion, trial conversion, conversion to paying, refunds |
| Notes | hypothèse, seuil de neutralité, dates de lecture J+21 / J+30 / J+45 |

---

## 8. Version R1 (iOS + Android) — soumission jeudi 01/10

> **État au 27/09** : les six points ci-dessous sont implémentés sur la branche (voir
> `docs/r1-notes-de-test.md` pour le détail, les deux API SDK à confirmer au build et la grille
> de QA sur appareil). Compilation et QA restent à faire avant soumission.

| # | Changement | iOS | Android | Pourquoi |
| --- | --- | --- | --- | --- |
| 1 | Paywalls `quizz`, `debloquer_cours`, `entrainement` : prendre `$rc_annual` / `$rc_monthly` dans `offerings.current` (offering servie par l'expérience), repli sur l'offering du contexte ; garder l'attribution d'impression au contexte | `StoreViewModel.annualPackage(forOfferingIdentifier:)`, `SophiaNativePaywalls.swift` | `StoreViewModel.kt`, `PaywallScreen.kt` | **Urgent pour la vague 1** : prix cohérent, plus de fuite vers 39,99 € |
| 2 | Textes de repli sans prix codé en dur (26 occurrences iOS, clés `paywall.plan.fallback.*` Android) : masquer le prix tant que le store n'a pas répondu | `AppLocalizable.swift`, `StoreViewModel.swift` | `strings/*.json` | Un bras 69,99 ne doit jamais afficher « 39,99 € » |
| 3 | Vérifier que `trackCustomPaywallImpression` part une fois par présentation avec l'offering réellement servie | `SophiaNativePaywalls.swift` | `PaywallScreen.kt` | « Paywall viewers » des expériences |
| 4 | Package hebdo : `weeklyPackage` (`$rc_weekly`), paywall comparatif « Annuel vs Hebdo », prix ramené à la semaine, CTA sans mention d'essai | `StoreViewModel.swift`, `OnboardingV2Paywalls.swift`, `SophiaNativePaywalls.swift` | `StoreViewModel.kt`, `PaywallScreen.kt` | Vague 2 |
| 5 | Discount côté app : bucket `A`/`B` tiré à la première ouverture, attribut RevenueCat `discount_bucket`, offering `offre_discount` ou `offre_discount_2999`, impression trackée avec la bonne offering | `DiscountOfferManager.swift`, `StoreViewModel.promoPackage` | équivalent Kotlin | Vague 2 |
| 6 | Durée d'essai dynamique : lire `introductoryDiscount.subscriptionPeriod` et l'injecter dans les 21 textes « 3 jours », rappel J-1 calé sur la vraie durée | `AppLocalizable.swift`, `OnboardingV2TrialSteps.swift` | `OnboardingV2Screen.kt`, `TrialReminderScheduler.kt` | Vague 2 (essai 7 j) |

Estimation : 3 jours iOS, 2 jours Android, 1 jour de QA (achat sandbox sur chaque offering, y
compris Test Store). Pas de Placements RevenueCat : inutiles avec le point 1, et ils
interagiraient avec des expériences déjà lancées.

---

## 9. Lecture des résultats et décisions

### 9.1 Lire l'échelle de prix du groupe P

Quatre points (39,99 · 49,99 · 59,99 · 69,99) donnent une **courbe de demande** : conversion
payante et revenu par exposé à chaque prix. On retient le prix qui maximise le revenu par exposé
à 30 jours, à remboursements égaux. Repères : à conversion égale, 69,99 rapporte +75 % ; il reste
gagnant tant que la conversion ne baisse pas de plus de 43 % ; 59,99 tant qu'elle ne baisse pas
de plus de 33 % ; 49,99 de plus de 20 %. Si la courbe est plate jusqu'à 59,99 et casse à 69,99,
la vague 2 teste 64,99. Si elle casse dès 49,99, on garde 39,99 et on teste 44,99.

### 9.2 Lire le plan 2×2 du groupe S

RevenueCat compare chaque bras au contrôle ; on lit aussi les effets principaux en regroupant
(je les calcule chaque semaine via le MCP) : effet prix = (② + ④) vs (① + ③) ; effet « sans
essai » = (③ + ④) vs (① + ②) ; interaction = ④ contre ce que ① plus les deux effets laisseraient
attendre. Si ④ dépasse la somme des effets, le combo est retenu tel quel.

### 9.3 Règles

1. Décision sur la **LTV réalisée par client à 30 jours (proceeds)**. Les conversions sont des
   diagnostics.
2. **Victoire** : probabilité de battre le contrôle ≥ 95 % et intervalle du lift excluant 0, ou
   écart supérieur au MDE du jour (tableau § 0). **Match nul** sur la LTV : on garde le prix le
   plus élevé si les remboursements ne montent pas, sinon le contrôle.
3. **Pause d'un bras** avant la date : remboursements > contrôle + 3 points, ou conversion
   payante < 60 % du contrôle après 4 000 exposés. Pause, pas arrêt : les données mûrissent.
4. **Pas de lecture positive avant J+30**, garde-fous exceptés.
5. **Déploiement** par règle de ciblage pays : chaque groupe peut finir avec son propre prix.
6. **Journal** : une ligne par test dans ce fichier (départ, taille, décision, offering déployée).

### 9.4 Suivi hebdomadaire (lecture seule, via le MCP)

Chaque lundi : par test et par bras, customers, viewers, essais, conversions, LTV 14 j / 30 j,
remboursements ; courbe de demande P ; effets 2×2 S ; remboursements et conversion d'essai par
pays ; adoption de R1 ; anomalies. Une page par semaine dans `docs/`.

---

### 9.5 Décision du test discount (07/10)

19,99 € gagne contre 29,99 €. Mesure du 01/10 08:00 au 07/10 07:40 UTC, achats App Store lus
client par client dans RevenueCat :

| | A · 19,99 € | B · 29,99 € |
|---|---|---|
| Clients du groupe (attribut `discount_bucket`) | 13 210 | 13 026 |
| Achats de l'offre | 130 | 69 |
| Encaissé | 2 850 $ | 2 195 $ |
| Renouvellement coupé ensuite | 17 % | 26 % |
| Abonnés payants au prix plein (nouveaux depuis le 01/10) | 104 | 95 |

19,99 vend plus (certitude ~100 %) et rapporte plus (93 %), sans retirer d'achats au prix plein.
Mise en œuvre sans version d'app : le package `$rc_annual` de `offre_discount_2999` vend
`discount_yearly` et `sophia_pro:annual-promo`, comme `offre_discount`. Les abonnés déjà à
`discount_yearly_2999` gardent leur produit, qui reste rattaché à `premium`.

### 9.6 Paliers bas retirés avant J+30 (08/10)

Décision produit, prise avant les dates de lecture du § 9.3. Chance que la variante rapporte plus que le
prix actuel, cadeau compris, au 08/10 (trois modèles indépendants) :

| Variante | Cadeau compris | Sans le cadeau | Décision |
|---|---|---|---|
| Türkiye, palier 25 % | 11-16 % | 56-75 % | retirée |
| Türkiye, palier 50 % | 16-25 % | 55-74 % | retirée (cadeau au même prix que l'annuel : variante incohérente telle quelle) |
| C, palier 25 % | 16-34 % | 43-60 % | retirée |
| C, palier 50 % | 44-55 % | 64-80 % | continue en v3, contre le prix actuel |

L'écart vient du cadeau : au prix actuel, une part des visiteurs le prend (environ 18-20 €) ; aux
paliers bas, il coûte autant ou plus que l'annuel et ne se vend pas. Le test ne dit donc pas que ces pays
refusent un annuel moins cher, seulement que « palier bas + ce cadeau » fait moins bien que « prix actuel
+ cadeau ». Mise en œuvre le 10/10 à 14:08 UTC, par le workflow « Pricing tests » (`revenuecat-experiments ·
switch`, `stop:expaa99dcbc5d,start:expc04e8ff651,stop:expe2a6836f94`) : C v2 et TR v2 arrêtés, C v3
(`expc04e8ff651`) démarré dans la même seconde. Lecture C v3 à J+21 / J+30 / J+45 depuis son démarrage. Les paliers restent en
vente dans App Store Connect (restriction `available_in` non appliquée) : les abonnés existants les
gardent, et les réglages d'abonnement d'Apple permettent toujours d'y passer.

## 10. Grille de prix par pays (hypothèse, arrêtée à J+45)

| Groupe | Annuel | Mensuel / hebdo | Discount | Décidé par |
| --- | --- | --- | --- | --- |
| P | 39,99 → 49,99 / 59,99 / 69,99 | mensuel 9,99 (hebdo en vague 2) | 50 % de l'annuel retenu | P, vague 2 |
| S | 39,99 → 49,99 | mensuel 9,99 avec ou sans essai | idem | S |
| B | 29,99 / 39,99 / 49,99 | mensuel 9,99 | idem | B |
| TR | 1 999 / 999 / 499 TRY | mensuel ≈ 499 TRY (palier en vague 2) | idem | TR |
| C | 100 / 50 / 25 % | mensuel local | idem | C |

Android aligné sur iOS dès lundi, puis suit les décisions. Prix TR et AR revus chaque trimestre
(les prix fixés par storefront ne suivent pas l'inflation).

---

## 11. Risques et parades

| Risque | Parade |
| --- | --- |
| Un bras encaisse sans débloquer Premium (produit non rattaché) | Rattachement + achat sandbox par offering avant J0 (§ 6, étapes 1, 6, 7) |
| Remboursements du bras 69,99 | Suivi quotidien de ce bras, garde-fou +3 points, rappel J-1 de fin d'essai, CTA explicite sur le montant |
| « Paywall viewers » à zéro (impressions natives non comptées) | Contrôle J0+24 h ; correctif R1 point 3 ; « Customers » reste exploitable |
| Fuite vers 39,99 € via les paywalls quiz / cours | Biais conservateur jusqu'à R1 (16 % des essais), supprimé par R1 point 1 |
| Revue Apple > 3 jours sur un produit | On lance ce qui est prêt au 4ᵉ jour, le test manquant suit |
| Groupe P trop petit pour trancher 49,99 | Assumé : 49,99 est tranché par S (MDE 18 % à J+45), P tranche 59,99 et 69,99 |
| Chevauchement d'audiences refusé | Un pays n'apparaît que dans un groupe ; vérification de la liste avant chaque lancement |
| Trafic qui retombe | Dates de lecture recalculées chaque semaine sur le volume réel |
| Inflation TRY / ARS | Revue trimestrielle |

---

## Annexes

### A. Identifiants utiles

- Projet `proj3f496a80` · apps `app152440cc2e` (App Store), `app3dcadd8517` (Play), `app257be138ae` (Test Store).
- Entitlement `premium` = `entl5b0c63b9a1`.
- Offerings : `fin_onboarding` = `ofrngb1bfff7210` (courante), `offre_discount` = `ofrng8974f13d40`,
  `quizz` = `ofrng2d26aa3789`, `debloquer_cours` = `ofrng0b892fe7f7`.
- Produits iOS : `Sophia_yearly` = `prodf40359e7e1`, `Sophia_monthly` = `prodf59fa512ae`,
  `Sophia_yearly_5999` = `prod2ad0152b81` (validé), `Sophia_monthly_notrial` = `prodbc71e740f7`
  (validé), `discount_yearly` = `prod87ca86a482`.
- Produits Play : `sophia_pro:p1y` = `prod4d34542d2a`, `sophia_pro:monthly` = `prod7460a66c69`,
  `sophia_pro:annual-promo` = `prod707c4e8f3a`.

### B. Contrôles du jour 1 d'un test

1. « Customers » répartis à ± 5 % entre les bras au bout de 24 h.
2. « Paywall viewers » ≈ 85 % des customers sur chaque bras.
3. Au moins un essai démarré et un achat direct visibles sur chaque bras.
4. Le prix affiché correspond au bras (capture depuis un appareil avec override).
5. Aucune hausse des achats attribués à « Unknown ».

### C. Ce que je peux faire moi-même

- Clé actuelle (lecture seule) : suivi hebdomadaire, courbe P, effets 2×2, alertes garde-fous,
  mise à jour de ce document.
- Clé `read_write` dans l'environnement : rattachements à l'entitlement, offerings et packages,
  audiences et expériences si le MCP les expose, archivage des offerings orphelines, achats de
  test à valider avec toi avant chaque lancement. La création des produits reste dans App Store
  Connect et Play Console.
- Dans le repo : la version R1 (§ 8) sur cette branche, prête pour revue.
