# RevenueCat : connexion MCP et remise à plat du catalogue

Audit fait le 26/09/2026 avec le MCP RevenueCat (clé API v2 en lecture seule), croisé avec le
code iOS et Android. Coche les cases des actions que tu valides.

**Contexte constaté**

- Projet « Sophia » (`proj3f496a80`) : 3 apps (App Store, Play Store, Test Store), 1 entitlement
  `premium`, 24 offerings, 42 paywalls, 19 produits, 5 expériences (toutes arrêtées), 0 webhook.
- Offering courante : `fin_onboarding` (paywall publié le 16/07). Les apps référencent 4 offerings :
  `fin_onboarding`, `quizz` (aussi pour le contexte `entrainement`), `debloquer_cours`, `offre_discount`.
- Prix FR : iOS annuel 39,99 € et mensuel 9,99 € (essai 3 jours), discount 19,99 € ;
  Android annuel 47,99 €, mensuel 11,99 €, promo 23,99 € (TVA ajoutée par erreur ; alignés sur iOS le 13/10).
- 28 derniers jours : 5 199 abonnements actifs, 698 essais actifs, MRR 17 574, revenus 74 838.

**Ce qui va changer**

- [x] La connexion MCP RevenueCat fonctionne en session cloud : `.mcp.json` lit la variable
  d'environnement `REVENUECAT_API_KEY` (clé lecture seule à stocker dans les réglages de l'environnement).
- [ ] L'ancien plan « remplacer le paywall maison par "Paywall Sophia" » est abandonné : il est
  obsolète (constat 1). Les paywalls restent natifs.
- [ ] Nettoyage du catalogue RevenueCat : archiver les offerings et paywalls hérités des tests
  terminés, et les produits iOS fantômes (constats 3 à 5).
- [ ] Sécuriser l'entitlement `premium` : rattacher ou archiver les 2 produits actifs non reliés (constat 2).
- [ ] Option : webhook RevenueCat vers Supabase pour connaître le statut Premium côté serveur (constat 8).
- [ ] Programme d'A/B tests prix, **cinq tests lancés le même jour** dès validation Apple des
  produits soumis lundi 28/09 (détail dans `docs/plan-ab-tests-prix.md`) : fort pouvoir d'achat
  39,99 / 49,99 / 59,99 / 69,99 € ; Europe du Sud 49,99 × mensuel sans essai ; Europe centrale
  29,99 / 39,99 / 49,99 ; Türkiye 1 999 / 999 / 499 TRY ; émergents 100 / 50 / 25 %. Vague 2 à
  J+45 avec R1 : hebdo, discount, essai 7 jours. Android aligné sur iOS dès lundi.

**Constats**

1. « Paywall Sophia » (`pwef84b494d12c4449`) existe, mais il est rattaché à l'offering `default`,
   qui n'est pas la courante, et n'a jamais été publié (946 révisions). Les apps iOS et Android
   affichent des paywalls natifs par contexte et déclarent elles-mêmes les impressions
   (`trackCustomPaywallImpression`) pour que les expériences RevenueCat restent mesurables.
   Repasser au paywall RevenueCat défait les PR #186, #190 et #195 et supprime les paywalls
   spécifiques (quiz, déblocage de cours, offre flash, rétention). Recommandation : rester natif.
2. Entitlement `premium` : 16 produits rattachés. Deux produits iOS actifs ne le sont pas :
   `Sophia_yearly_5999` (offering `price_test_annual_5999`) et `Sophia_monthly_notrial`
   (offering `trial_test_monthly_notrial`). Si l'un de ces tests est relancé tel quel, l'achat
   ne débloque pas Premium.
3. Produits iOS fantômes : `sophia_annual` est introuvable dans App Store Connect
   (`store_status: not_found`) ; `sophia_monthly`, `Sophia_offre`, `Sophia_pro_mensuel`,
   `sophia_annual_promo` et `Sophia_yearly_5999` présentent le même symptôme (durée inconnue côté
   RevenueCat). Ils sont rattachés à `premium` mais absents des offerings utilisées.
4. Offerings orphelines (aucune référence dans le code, expériences arrêtées) : `fin_onboarding2`,
   `fin_onboarding3`, `fin_onboarding4`, `copy fin_onboarding`, `A/B test 2`, `default 2`, `defaut3`,
   `matiere_block_art`, `matiere_block_histoire`, `matiere_block_litterature`,
   `matiere_block_monde_actuel`, `matiere_block_mythologie`, `matiere_block_sciences`,
   `cours_gratuit`, `special_promo`, `debloquer_cours2`, `trial_test_monthly_notrial`,
   `trial_test_annual_notrial` (déjà inactive), `price_test_annual_5999`. `default` peut rester
   comme filet, ou être archivée si « Paywall Sophia » est abandonné.
5. Paywalls brouillons : 6 « Screen for … in Workflow … », 3 « rcb_paywall layout », « rcb_paywall »,
   « Container », « Section », « Frame 67 », « Untitled Paywall », « Paywall », « Paywall 2 »,
   « Paywall R », « Paywall Test », « A/B test 4 », « Paywall fin de l'OB », « Paywall fin de l'OB A/B
   test ». Seuls 4 paywalls sont publiés (`fin_onboarding`, `debloquer_cours`, `paywall quizz`,
   `Offre_discount`) ; aucun n'est rendu par l'app, mais ils portent les offerings actives.
6. Android : chaque package `$rc_annual` contient aussi `sophia_pro:monthly` avec le critère
   `google_sdk_lt_6`. C'est volontaire (compatibilité SDK Google < 6), et sans effet : 100 % des
   abonnés Android sont sur le SDK 9.26.
7. Offre de rétention `retention_14_99` : **retirée de l'app le 27/09** (écran « Sure you want to
   leave? », déclenchement au lancement et entrée dans les réglages supprimés) ; l'offre
   promotionnelle peut rester côté App Store Connect sans effet.
8. Aucun webhook RevenueCat : Supabase ignore le statut Premium, tout repose sur `CustomerInfo`
   côté client.
9. La clé API utilisée pour cet audit a transité par le chat : à régénérer une fois stockée dans
   l'environnement.

**Détails**

- [x] `.mcp.json` : header `Authorization: Bearer ${REVENUECAT_API_KEY:-}`. Effet de bord : le
  repli OAuth est désactivé tant que le header est présent (voir `docs/revenuecat-mcp.md`).
- [x] `docs/revenuecat-mcp.md` : mode d'emploi de la connexion et instantané du catalogue.
- [ ] Dashboard : archiver les offerings du constat 4. La clé actuelle est en lecture seule : soit
  tu le fais dans le dashboard, soit tu mets une clé `read_write` dans l'environnement et je le fais via le MCP.
- [ ] Dashboard : supprimer les paywalls brouillons du constat 5.
- [ ] Dashboard : rattacher `Sophia_yearly_5999` et `Sophia_monthly_notrial` à `premium`, ou les
  archiver avec leurs offerings de test.
- [ ] Dashboard : archiver les produits iOS fantômes du constat 3 après vérification dans App Store Connect.
- [x] ~~App Store Connect : confirmer l'offre promotionnelle `retention_14_99` sur `Sophia_yearly`.~~ Sans objet : écran de rétention retiré le 27/09.
- [ ] Code iOS : retirer les `import RevenueCatUI` morts de `ContentView.swift` et `CourseView.swift`
  (aucun `PaywallView` ni Customer Center utilisé) et, si plus rien ne l'utilise, le produit
  `RevenueCatUI` du projet Xcode.
- [ ] Option : webhook RevenueCat vers une edge function Supabase (`is_premium`, `expires_at`).
- [ ] Tests prix, version R1 (iOS + Android, soumission 01/10) — **code livré sur la branche le 27/09, à compiler et tester (`docs/r1-notes-de-test.md`)** : paywalls quiz / cours /
  entraînement alignés sur l'offering servie par l'expérience (urgent) ; textes de repli sans
  prix codé en dur ; impressions vérifiées ; puis pour la vague 2 : package `$rc_weekly`, test
  discount côté app (bucket + attribut `discount_bucket`), durée d'essai dynamique.
- [x] Tests prix, App Store Connect — **fait le 27/09 par le workflow « Pricing tests »** : les 7
  produits (49,99 ; 69,99 ; 29,99 ; paliers 50 % et 25 % ; hebdo 6,99 ; discount 29,99) existent
  avec 12 localisations, 175 pays, grille Apple vérifiée (`prices` : paliers à 50–57 % et 25–29 %
  de `Sophia_yearly` en TR, MX, BR, IN), essai 3 jours sur les annuels, capture d'examen.
  Türkiye forcée à 999,99 / 499,99 TRY. Soumission du groupe lancée (`submit`) ; à confirmer par
  `status` = `WAITING_FOR_REVIEW`, puis attendre la validation Apple (1 à 3 jours).
- [ ] Tests prix, Play Console — **reporté après les résultats iOS** (décision du 27/09) : abonnement `sophia_pro`, 9 base plans
  `p1y-4999`, `p1y-5999`, `p1y-6999`, `p1y-2999`, `p1y-t50`, `p1y-t25`, `monthly-notrial`,
  `weekly-699`, `annual-promo-2999` (essai 3 j en offre sur les annuels). L'alignement de `p1y`,
  `monthly` et `annual-promo` sur iOS est fait (13/10, ci-dessous). Les produits RevenueCat
  correspondants existent déjà, rien à importer ensuite.
- [x] Tests prix, RevenueCat catalogue — **fait le 27/09 par le workflow** (`revenuecat · apply`) :
  14 produits créés (7 App Store, 7 Play), 16 produits rattachés à `premium` dont
  `Sophia_yearly_5999` et `Sophia_monthly_notrial`, 13 offerings avec leurs packages
  (`p__4999`, `p__5999`, `p__6999`, `s__4999_mtrial`, `s__3999_mnotrial`, `s__4999_mnotrial`,
  `b__2999`, `b__4999`, `tr__t50`, `tr__t25`, `c__t50`, `c__t25`, `offre_discount_2999`).
- [x] Tests prix v1 (5 audiences iOS, 5 expériences) — démarrés le 01/10 à 09:54, **à arrêter le jour
  même** : la moitié des nouveaux clients recevaient encore la 1.1.6, qui affiche le prix de la
  variante sur les paywalls cours et quiz mais facture 39,99 €.
- [ ] Tests prix v2 — mêmes variantes, audiences limitées à la **version 1.1.7 et plus**
  (`appVersion >= 1.1.7`, comparaison numérique vérifiée), créées par `revenuecat-experiments ·
  apply`. Ordre : Stop sur les 5 expériences v1 dans le dashboard, puis Start sur les 5 « · v2 ».
  Lecture à J+21 / J+30 / J+45 depuis le démarrage de la v2.
- [x] Test discount 19,99 vs 29,99 — **terminé le 07/10, 19,99 gagne** : du 01/10 au 07/10, groupe A
  (19,99) 130 achats et 2 850 $, groupe B (29,99) 69 achats et 2 195 $, pour des groupes de même
  taille (13 210 et 13 026) ; 19,99 rapporte plus avec 93 % de certitude, sans perte d'achats au
  prix plein (104 abonnés payants en A, 95 en B). L'offering `offre_discount_2999` vend désormais
  `discount_yearly` (iOS) et `sophia_pro:annual-promo` (Play) : tout le monde voit 19,99, sans
  mise à jour de l'app. Le tirage et l'attribut `discount_bucket` restent dans l'app, sans effet.
- [x] Paliers bas retirés (décision du 08/10, **exécutée le 10/10 à 14:08 UTC** par `revenuecat-experiments · switch` : C v2 et TR v2 arrêtés, C v3 démarré dans la même seconde ; lecture C v3 à J+21 le 31/10) : prix à 25 % et 50 % en Türkiye, prix à 25 % dans
  le groupe C. Cadeau compris, ils rapportent probablement moins que le prix actuel (≈ 75-87 % selon les
  modèles, pas une certitude) ; sans le cadeau, ils sont à égalité ou devant. RevenueCat ne permet pas de
  retirer une variante : Stop sur TR v2 et C v2 (dashboard), puis Start sur « Prix C · palier 50 % · v3 »
  (contrôle contre palier 50 %, brouillon créé par `revenuecat-experiments · apply`), sans les laisser
  tourner en même temps. Les abonnés déjà aux paliers gardent leur prix.
- [x] Pays riches : 69,99 retiré le 11/10 à 13:50 UTC (P v3 `expecf89281b0` arrêtée, P v4 `expeff5486efd`
  démarrée la seconde suivante par `revenuecat-experiments · switch` : 39,99 contre 49,99). Le 69,99 lançait
  moins d'essais (11,1 % contre 15,1 %) et moins d'essais payaient (21 % contre 39 %), chacun sûr à plus de
  99 % ; revenu par visiteur plus bas avec 76-96 % de certitude. Les données 49,99 de la v3 s'additionnent à
  la v4 dans nos calculs. Lecture P v4 à J+21 le 01/11.
- [x] Europe du Sud : gagnant du test S appliqué le 13/10 — test S arrêté à 08:34 UTC, règle de ciblage
  `1ae80bc2cd` créée à 08:38 par `revenuecat-experiments · rollout` : audience S (IT, ES, PT, GR, CY, MT,
  iOS 1.1.7+) -> offering `s__3999_mnotrial` (annuel 39,99 avec essai, mensuel 9,99 sans essai). Au 13/10 :
  90 % de chances de rapporter plus cadeau compris (88-91 %), 97-98 % hors cadeau ; essais annuels +28 %
  (98 %), essais payés 39 % contre 31 % (89 %). Android inchangé.
- [x] Android aligné sur l'App Store le 13/10 à 10:05 UTC (`play · apply`, `scripts/play_pricing.py`) :
  les prix Play avaient été saisis hors taxe et Google ajoutait la TVA (France 47,99 / 11,99 / 23,99 €).
  376 prix mis au prix App Store du même pays, même devise : annuel 39,99 €, mensuel 9,99 €, cadeau
  19,99 € (US 34,99 / 8,99 / 17,99 $ ; Pologne 149,99 zł ; Türkiye 1 999,99 ₺ à l'année). Relu par
  Google puis via RevenueCat : aucun pays au-dessus d'iOS. Inchangés : Colombie et Pérou (déjà moins
  chers), 30 pays facturés dans une autre devise sur Play (AR, UA, MA, KE…, passe ultérieure avec
  conversion), 17 sans prix iOS. Les abonnés Android existants gardent leur prix. Détail : §9.9 de
  `docs/plan-ab-tests-prix.md`.
- [x] Europe de l'Est (B v2 `expaaff2977ef`) et reste du monde (C v3 `expc04e8ff651`) arrêtés le 15/10 à
  14:58 UTC (`revenuecat-experiments · switch`) : aucune variante ne bat le prix actuel. Lecture finale,
  essais tous terminés (18/10, cadeau compris) : B 29,99 77 % (médiane +8 %), B 49,99 32 % ; C palier
  50 % 78 % seul, 59 % cumulé avec la v2 (médiane +3 %). Sous la barre de 95 % : on garde 39,99 et le prix
  actuel. Il ne reste que P v4 (39,99 contre 49,99), décision le 22/10. Détail : §9.10.
- [x] Offre par défaut rétablie le 18/10 à 15:53 UTC (`revenuecat-experiments · default`) : depuis la
  clôture du test S dans le tableau de bord le 13/10 (entre 08:35 et 09:20 UTC), l'offre courante du
  projet était `s__3999_mnotrial` au lieu de `fin_onboarding`. Tout le monde hors test et hors règle
  voyait le mensuel sans essai, et sur Android le mensuel disparaissait (le base plan `monthly-notrial`
  n'existe pas sur Play). `fin_onboarding` est de nouveau l'offre par défaut ; l'Europe du Sud garde
  `s__3999_mnotrial` par la règle `1ae80bc2cd`. Les témoins des tests affichaient explicitement
  `fin_onboarding` : résultats non touchés. La comparaison Android avant/après le 13/10 est brouillée.
- [x] Pays riches : P v4 (`expeff5486efd`, 39,99 contre 49,99) arrêté le 21/10 à 13:43 UTC, on garde
  39,99. À J+10 : essais 16,0 % contre 14,3 %, essais payés 38 % contre 30 %, remboursés 4 contre 8 ;
  le 49,99 rapporte plus avec 54 % de chances cadeau compris (68 % en cumulant la v3, médiane +4 %),
  29 % hors cadeau. Égalité de revenu, environ 20 % d'abonnés en plus au 39,99, remboursements en
  hausse : contrôle gardé (règle 2, § 9.3). Plus aucun test en cours. Détail : §9.11.
- [ ] Disponibilité des produits de test limitée aux pays de leur test (`available_in` du
  manifeste) : le 01/10, un abonné suédois est passé de `Sophia_yearly` (39,99 €) au palier 25 %
  depuis les réglages d'abonnement d'Apple, qui listent tous les produits du groupe vendus dans
  le pays. Paliers 25 % et 50 % : Türkiye et groupe C ; 29,99 : groupe B ; 49,99 : P, S, B ;
  69,99 : P. Trou préexistant, non corrigé : `discount_yearly` (19,99 €) est vendu partout.
- [ ] Prochaine mise à jour iOS : recharger les offerings à chaque changement d'identité RevenueCat
  (`logIn`) et partager un seul `StoreViewModel` entre l'onboarding et l'app, pour qu'un passage
  d'un compte à un autre en cours de session ne montre jamais deux variantes.
- [ ] Sécurité : régénérer la clé API v2 RevenueCat après l'avoir mise dans l'environnement.
