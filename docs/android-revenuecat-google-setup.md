# Brancher l'Android sur le RevenueCat existant + Google OAuth

Point de départ : **RevenueCat est déjà configuré pour iOS.** Le projet existe, l'entitlement
`premium` existe, et les offerings `fin_onboarding`, `debloquer_cours`, `quizz`,
`offre_discount` contiennent déjà les packages `$rc_annual` / `$rc_monthly` avec les produits
App Store.

Le code Android lit exactement les mêmes identifiants (`StoreViewModel.annualPackage()` prend
`offering.annual`, c'est-à-dire `$rc_annual`), donc **il n'y a rien à recréer côté
RevenueCat**. Il manque seulement, dans ce même projet, une app Google Play, les produits
Play, et la clé publique Android.

## Ce qu'il ne faut pas faire

- ❌ Créer un **nouveau projet** RevenueCat pour Android. L'entitlement ne serait plus partagé
  et un abonné iOS ne serait pas reconnu sur Android.
- ❌ Créer de nouveaux offerings ou renommer les existants : les identifiants sont codés dans
  `PaywallContext`.
- ❌ Changer l'identifiant de l'entitlement : `AppConfig.PREMIUM_ENTITLEMENT` vaut `premium`.

Une app Play s'ajoute **dans le projet existant** ; chaque app a sa propre clé publique, mais
les offerings, packages et entitlements sont communs aux deux plateformes.

---

## Étape 1 — Play Console : créer les produits

Les produits ne se partagent pas entre Apple et Google : il faut les recréer, avec des
identifiants Play qui leur sont propres. Prérequis : app publiée sur une piste **test
interne** avec un build signé, et compte marchand renseigné (sans ça, l'onglet Abonnements
reste vide).

1. **Monétisation → Produits → Abonnements → Créer**, par exemple `sophia_pro`.
2. Créer trois **plans de base**, tous en **renouvellement automatique** :

   | Plan de base | Période | Rôle |
   |---|---|---|
   | `p1y` | 1 an | `$rc_annual` |
   | `monthly` | 1 mois | `$rc_monthly` |
   | `annual-promo` | 1 an, prix plus bas | `$rc_annual` de `offre_discount` |

   Le type de renouvellement est **figé à la création** : un plan créé en prépayé par erreur
   ne se corrige pas, et son ID est brûlé dès qu'il a été activé. Il faut le désactiver et en
   créer un autre sous un ID différent. Le champ **Tags** reste vide : rien dans l'app ni dans
   RevenueCat ne le lit.

   `annual-promo` doit être **strictement moins cher** que `p1y`, sinon
   `StoreViewModel.percentOff` renvoie null et le paywall flash retombe sur un pourcentage
   codé en dur, donc faux.

3. L'essai gratuit se crée en **Offre**, et une offre appartient à un seul plan de base : il
   en faut donc une sur `p1y` **et** une sur `monthly`. Éligibilité « Acquisition de nouveaux
   clients → N'a jamais eu cet abonnement », une phase **Essai gratuit** de 3 jours (le
   minimum autorisé par Play), puis **Activer**.

   Google n'accorde qu'un essai par abonnement : qui l'utilise en mensuel n'y a plus droit en
   annuel. Sans offre d'essai, rien ne casse — les paywalls passent aux formulations « sans
   essai » (`paywall.price.yearlyNoTrial`, `onboardingV2.pw.priceNoTrial`) — mais les écrans
   d'essai de l'onboarding disparaissent, car ils lisent l'essai de l'**annuel** de l'offering
   courant.

4. **Paramètres du compte développeur → Test de licence** : ajoute ton compte Google pour
   acheter sans être débité. C'est au niveau du compte, pas de l'app.

## Étape 2 — RevenueCat : ajouter l'app Play au projet existant

⚠️ La page Play Console **« Paramètres → Accès à l'API » n'existe plus** : Google l'a
supprimée. Il n'y a plus de projet Google Cloud à lier explicitement, le rattachement se fait
uniquement par l'e-mail du compte de service.

**Dans Google Cloud**, un seul projet pour tout :

1. **API et services → Bibliothèque** → activer **Google Play Android Developer API**,
   **Google Play Developer Reporting API** et **Cloud Pub/Sub API**. La troisième est
   obligatoire : sans elle, RevenueCat refuse le JSON avec « Google Cloud Pub/Sub API must
   first be enabled ».
2. **IAM et administration → Comptes de service → Créer**.
3. Lui accorder deux rôles — c'est **IAM → Accorder l'accès**, pas l'onglet « Autorisations »
   du compte de service, qui gère l'inverse (qui peut utiliser ce compte). Un compte sans rôle
   n'apparaît pas dans la liste IAM, il faut donc créer la liaison :
   - `roles/pubsub.editor` — passer à `roles/pubsub.admin` si la création du topic échoue,
     cas documenté par RevenueCat,
   - `roles/monitoring.viewer`.
4. **Clés → Ajouter une clé → JSON**. Toujours régénérer la clé **après** une modification de
   rôles : RevenueCat met la validation en cache.

**Dans Play Console**, [Utilisateurs et autorisations](https://play.google.com/console/users-and-permissions)
(niveau compte développeur, pas dans une app) → **Inviter un nouvel utilisateur** → l'e-mail
du compte de service, avec les autorisations de consultation des informations de l'app, des
données financières, et de gestion des commandes et abonnements. Un compte de service n'a pas
de boîte mail : rien à accepter, le lien est immédiat.

**Dans RevenueCat**, projet Sophia existant → **Project settings → Apps → New app → Google
Play Store**, package `app.rork.sophia`, puis téléverse le JSON. La validation côté Play peut
prendre jusqu'à **36 h** : une erreur d'identifiants pendant ce délai n'est pas forcément une
mauvaise configuration.

## Étape 2 bis — Notifications temps réel (RTDN)

Play n'envoie rien à RevenueCat directement : il **publie dans un topic Pub/Sub de ton
projet**, que RevenueCat vient lire via sa propre subscription.

1. Sous le champ du JSON, choisis un topic ou laisse RevenueCat en créer un, puis **Connect to
   Google** et copie le chemin complet (`projects/<projet>/topics/<topic>`).
2. Play Console → l'app → **Monétisation → Configuration de la monétisation → Notifications
   aux développeurs en temps réel** : colle ce chemin, contenu « Abonnements, achats annulés
   et tous les produits ponctuels », **Enregistrer**.
3. **Envoyer une notification de test**, puis vérifier le libellé **« Last received »** dans
   RevenueCat. Son existence suffit à prouver le circuit ; il ne se réhorodate pas forcément à
   chaque test, et le tableau de bord ne se rafraîchit pas seul.
4. Sur un topic préexistant, Play n'a pas forcément le droit d'y écrire. Lui accorder
   `roles/pubsub.publisher` **sur le topic** :

   ```bash
   gcloud pubsub topics add-iam-policy-binding <TOPIC_ID> --project=<PROJET> \
     --member="serviceAccount:google-play-developer-notifications@system.gserviceaccount.com" \
     --role="roles/pubsub.publisher"
   ```

   Cette adresse est la même pour tous, il n'y a rien à y adapter. En français les libellés de
   `pubsub.editor` et `pubsub.publisher` se ressemblent : se fier à l'identifiant technique.

Sans RTDN, l'abonnement expire quand même à sa date — RevenueCat revérifie. Ce qu'on perd :
les **remboursements** ne sont pas détectés, les annulations et échecs de paiement arrivent en
retard, et les statistiques sont fausses.

Un topic **sans subscription détruit les messages** à la publication. Play signale un succès
et rien n'est conservé. Pour trancher entre « Play n'écrit pas » et « RevenueCat ne lit pas »,
créer une subscription de test **avant** l'envoi, puis `gcloud pubsub subscriptions pull`.

## Étape 3 — Rattacher les produits Play à l'entitlement existant

1. **Products → Import** : importe les produits Play créés à l'étape 1.
2. **Entitlements → `premium`** (celui qui existe déjà) → attache les nouveaux produits Play,
   à côté des produits App Store. C'est ce partage qui rend l'abonnement multi-plateforme.

## Étape 4 — Ajouter les produits Play dans les packages existants

N'ajoute aucun offering. Ouvre chacun de ceux qui existent et, dans chaque package, ajoute le
produit Play à côté du produit App Store — un package peut contenir un produit par store.

| Offering existant | Package | Produit Play à y ajouter | Écran Android |
|---|---|---|---|
| `fin_onboarding` | `$rc_annual` | `sophia_pro:p1y` | fin d'onboarding |
| `fin_onboarding` | `$rc_monthly` | `sophia_pro:monthly` | comparatif des plans |
| `debloquer_cours` | `$rc_annual` | `sophia_pro:p1y` | cours du jour déjà lu |
| `quizz` | `$rc_annual` | `sophia_pro:p1y` | quiz et entraînement |
| `offre_discount` | `$rc_annual` | `sophia_pro:annual-promo` | offre flash 60 min |

Un produit Play s'écrit `abonnement:plan_de_base`.

**Un offering doit être marqué « Current »**, et ce n'est pas cosmétique : `offering(null)`
renvoie l'offering courant, qui sert à la fois de repli quand un identifiant est introuvable,
de prix barré du paywall flash, et de source de vérité pour l'affichage des écrans d'essai de
l'onboarding. Mettre `fin_onboarding`.

Le badge d'économie du comparatif est calculé à l'exécution en comparant l'annuel à douze
mensualités (`StoreViewModel.discountBadge`) : il n'y a rien à saisir pour lui, mais il ne
s'affichera que si `$rc_monthly` a bien un produit Play.

**Project settings → transfer behavior : « Transfer to new App User ID ».** La connexion étant
optionnelle sur Android, beaucoup achèteront en anonyme puis créeront un compte ; l'autre
réglage leur ferait perdre Premium en se connectant.

## Étape 5 — La clé Android

Elle est **déjà dans le dépôt** : `goog_BMgnkFLoHMpayyrxjzVKqTUJvst`, en valeur par défaut de
`REVENUECAT_API_KEY` et `REVENUECAT_TEST_API_KEY` dans `android/app/build.gradle.kts`. C'est
la clé publique du SDK, embarquée dans chaque APK de toute façon. Google n'a pas de clé
sandbox distincte, d'où la même valeur des deux côtés.

Pour pointer vers un autre projet RevenueCat depuis un poste ou en CI, `local.properties`
prend le dessus sur le défaut :

```properties
REVENUECAT_API_KEY=goog_xxxxxxxxxxxxxxxxxxxxx
REVENUECAT_TEST_API_KEY=goog_xxxxxxxxxxxxxxxxxxxxx
```

Conséquence du passage à une vraie clé : `purchasePackage` ne simulait Premium en local que
tant que `Purchases` n'était pas configuré. Le SDK se configure maintenant, donc sur un
appareil qui n'atteint pas Play Billing — émulateur, APK installé à la main — le bouton
d'achat répond « Offre indisponible » au lieu de débloquer. Les écrans Premium se testent sur
un build installé **depuis Play**.

## Étape 6 — Vérifier

Les achats ne se testent pas hors Play : il faut un build sur la piste **test interne**,
installé depuis le Play Store, avec un compte inscrit au test de licence.

1. Ouvre un **deuxième** cours dans la journée. Le paywall « cours débloqué » doit afficher un
   **vrai prix** ; `39,99 €` signifie que le repli codé en dur s'applique, donc que l'offering
   demandé n'a pas de produit Play dans `$rc_annual`.
2. Achète : l'app passe Premium immédiatement, sans redémarrage.
3. Ferme un paywall contextuel : le comparatif annuel/mensuel doit s'ouvrir, avec un prix
   mensuel réel et un badge d'essai sur les deux cartes.
4. Annule l'abonnement depuis le Play Store, **sans ouvrir l'app**, puis regarde
   RevenueCat → **Customers → Customer History**. L'annulation doit y apparaître : c'est le
   seul vrai test des RTDN, qu'aucune notification de test ne peut démontrer.

Pour diagnostiquer, un build **debug** suffit : les logs RevenueCat y sont en niveau DEBUG,
donc les offerings récupérés et les erreurs de configuration apparaissent dans `logcat`.

---

## Étape 7 — Google OAuth

Le client **Web** existe déjà (son ID est dans le dépôt et sert de `serverClientId`). Il
manque le client **Android**, sans lequel Credential Manager ne peut pas produire de jeton.

1. Google Cloud → **API et services → Identifiants → ID client OAuth → Android**, package
   `app.rork.sophia`.
2. Une empreinte SHA-1 par clé de signature, donc **deux clients** :
   - debug :
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```
   - release : Play Console → **Intégrité de l'app → Signature d'app**, SHA-1 de la clé de
     signature d'application (celle générée par Google, pas seulement celle d'importation).
3. Supabase → **Authentication → Providers → Google** : active le provider, colle le Client ID
   Web et son secret, **et ajoute ce Client ID Web dans « Authorized Client IDs »**. C'est
   l'étape qu'on oublie : sans elle, le flux web marche mais la connexion native par jeton est
   rejetée.

| Symptôme | Cause |
|---|---|
| `GetCredentialException: No credentials available` | Aucun compte Google sur l'appareil, ou pas de client Android pour ce SHA-1 |
| Erreur 16 / `Caller not authorized` | Package ou SHA-1 différent de celui déclaré |
| Supabase `invalid_client` | Client ID Web absent de « Authorized Client IDs » |
| Le bouton ne fait rien, aucune fenêtre | One Tap n'a rien à proposer. `AuthService` bascule alors sur `GetSignInWithGoogleOption`, et un toast affiche l'erreur en debug |

---

## Diagnostic RevenueCat

| Message | Ce qu'il faut faire |
|---|---|
| « Google Cloud Pub/Sub API must first be enabled » | Activer **Cloud Pub/Sub API** dans le projet du compte de service |
| « credentials do not have permission to create a Pub/Sub topic » | Attendre la propagation IAM (5–10 min), vérifier la liaison avec `gcloud projects get-iam-policy`, puis passer à `roles/pubsub.admin` et régénérer le JSON |
| « credentials do not have permissions to access the needed Google resources » | Rôles manquants, ou JSON émis avant l'ajout des rôles |
| Prix `39,99 €` ou `19,99 €` sur un paywall | Repli codé en dur : pas de produit Play dans le `$rc_annual` de cet offering |
| Offerings vides, aucun prix | Validation des identifiants pas terminée (jusqu'à 36 h) |
| « Offre indisponible » à l'achat | Build pas installé depuis Play, plan de base non activé, ou `versionCode` différent du build publié |
| Achat réussi mais Premium inactif | Produit Play pas attaché à l'entitlement `premium` |
| Premium actif après annulation | RTDN non configurées (étape 2 bis) |
| Premium perdu en se connectant | Transfer behavior sur « Keep with original » |

---

## Étape 8 — Multi-plateforme : le point qui compte

L'entitlement `premium` suit l'**App User ID**, et l'app utilise l'identifiant Supabase
(`Purchases.logIn(uid)` à la connexion). Concrètement :

- Un abonné iOS retrouve son accès sur Android **en se connectant avec le même compte
  Supabase**. `StoreViewModel` écoute désormais les mises à jour de customer info, donc
  Premium s'active dès que `logIn` remonte l'entitlement, sans redémarrage.
- **« Restaurer les achats » n'y changera rien** : sur Android, la restauration n'interroge que
  Google Play, qui ne connaît pas un achat App Store. Pour un abonné iOS, c'est la connexion
  qui transfère l'accès, pas la restauration. À savoir pour le support.
- ⚠️ Piège d'identité : si quelqu'un s'est connecté en **Apple** sur iOS et se connecte en
  **Google** sur Android, Supabase crée deux utilisateurs distincts (sauf si tu actives la
  liaison d'identités par email), donc deux App User ID, donc pas de transfert. Deux options :
  activer Google Sign-In sur iOS aussi pour que les deux plateformes partagent la même
  identité, ou activer la liaison d'identités côté Supabase.

### La connexion est optionnelle sur Android

Contrairement à iOS, l'onboarding Android laisse passer l'étape de connexion. Il faut donc
que tout fonctionne sans compte, et que la bascule vers un compte ne perde rien :

- **Sans compte**, RevenueCat tourne sur un identifiant anonyme (`$RCAnonymousID:…`). L'achat
  et l'entitlement `premium` marchent normalement : ils sont liés au compte Google Play de
  l'appareil. Ce qui ne marche pas : le multi-appareil, la sync de progression, les amis.
- **À la première connexion**, l'app appelle `Purchases.logIn(uid)` puis `syncPurchases()`.
  Le second appel est celui qui compte : il repousse les reçus Play vers l'utilisateur
  identifié, donc un achat fait *avant* de se connecter suit bien le compte.
- **Vérifie le « transfer behavior »** du projet RevenueCat (Project settings). Sur
  « Transfer to new App User ID », l'abonnement anonyme rejoint le compte. Sur « Keep with
  original », il reste sur l'identifiant anonyme et l'utilisateur perd Premium en se
  connectant.
- **À la déconnexion**, retour à un identifiant anonyme. Un abonnement acheté sur *cet*
  appareil reste restaurable via Play ; un abonnement acheté ailleurs, non — c'est le sens
  même de la déconnexion.

Une conséquence à assumer côté support : un utilisateur qui achète sans compte, change de
téléphone et n'a jamais créé de compte n'a aucun moyen de récupérer son abonnement en dehors
du même compte Google Play.

---

## Rappel : les barrières freemium en place

Pour tester sans attendre minuit : **Réglages → Données → « Reset cours du jour »**.

| Barrière | Règle |
|---|---|
| Cours du jour | Le premier cours ouvert dans la journée est intégralement gratuit |
| Autres cours | Page 1 lisible, pages suivantes floutées avec cadenas → paywall `debloquer_cours` |
| Fin de cours | Réservée au cours du jour ou aux abonnés |
| Quiz | Toujours Premium → paywall `quizz` |
| Entraînement | Toujours Premium → paywall `entrainement` (offering `quizz`) |
| Offre flash | 3 swipes sur l'accueil → cadeau en 3 taps → 60 min de promo, une fois par jour |
| Seconde chance | Fermer un paywall contextuel ouvre le comparatif avant de sortir |
