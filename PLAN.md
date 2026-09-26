# RevenueCat : connexion MCP et remise à plat du catalogue

Audit fait le 26/09/2026 avec le MCP RevenueCat (clé API v2 en lecture seule), croisé avec le
code iOS et Android. Coche les cases des actions que tu valides.

**Contexte constaté**

- Projet « Sophia » (`proj3f496a80`) : 3 apps (App Store, Play Store, Test Store), 1 entitlement
  `premium`, 24 offerings, 42 paywalls, 19 produits, 5 expériences (toutes arrêtées), 0 webhook.
- Offering courante : `fin_onboarding` (paywall publié le 16/07). Les apps référencent 4 offerings :
  `fin_onboarding`, `quizz` (aussi pour le contexte `entrainement`), `debloquer_cours`, `offre_discount`.
- Prix FR : iOS annuel 39,99 € et mensuel 9,99 € (essai 3 jours), discount 19,99 € ;
  Android annuel 47,99 €, mensuel 9,99 €, promo 23,99 €.
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
- [ ] Programme d'A/B tests prix sur 13 semaines (détail, chiffres et calendrier dans
  `docs/plan-ab-tests-prix.md`) : annuel 39,99 / 49,99 / 59,99 € (Tier A), palier Türkiye
  (1 999 / 999 / 499 TRY), mensuel avec ou sans essai vs hebdo 6,99 €, discount 19,99 vs 29,99 €,
  puis grille de prix par pays. Rien n'est lancé tant que ce point n'est pas coché.

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
7. Offre de rétention `retention_14_99` (offre promotionnelle App Store lue par
   `StoreViewModel.retentionOffer`) : invisible via le MCP. L'annuel iOS `Sophia_yearly` est bien
   APPROVED avec un essai de 3 jours. À confirmer dans App Store Connect.
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
- [ ] App Store Connect : confirmer l'offre promotionnelle `retention_14_99` sur `Sophia_yearly`.
- [ ] Code iOS : retirer les `import RevenueCatUI` morts de `ContentView.swift` et `CourseView.swift`
  (aucun `PaywallView` ni Customer Center utilisé) et, si plus rien ne l'utilise, le produit
  `RevenueCatUI` du projet Xcode.
- [ ] Option : webhook RevenueCat vers une edge function Supabase (`is_premium`, `expires_at`).
- [ ] Tests prix, prérequis code (iOS + Android) : lire les offerings par *Placement*
  (`onboarding`, `quizz`, `debloquer_cours`, `offre_discount`) avec repli sur l'identifiant
  actuel ; supporter `$rc_weekly` et un libellé « par semaine » ; retirer les prix codés en dur
  des textes de repli.
- [ ] Tests prix, prérequis stores : créer les produits listés au § 5.3 du plan (annuel 49,99,
  hebdo 6,99, discount 29,99, paliers Türkiye), les rattacher à `premium`, et aligner le prix
  Android sur iOS (47,99 → 39,99 €).
- [ ] Tests prix, prérequis RevenueCat : 4 placements + règle « Any audience », offerings
  variantes, audiences par pays, vérification des impressions des paywalls natifs au jour 1.
- [ ] Sécurité : régénérer la clé API v2 RevenueCat après l'avoir mise dans l'environnement.
