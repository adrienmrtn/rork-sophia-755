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

1. **Monétisation → Abonnements → Créer**, par exemple `sophia_pro`, avec deux plans de base :
   - `annual`, période P1Y — correspondra à `$rc_annual`,
   - `monthly`, période P1M — correspondra à `$rc_monthly`.
2. Sur `annual`, ajoute une **offre** d'essai gratuit de 3 jours, pour refléter iOS. Le code
   lit l'essai sur le produit réellement servi : sans offre d'essai, les paywalls passent
   automatiquement aux formulations « sans essai » (`paywall.price.yearlyNoTrial`,
   `onboardingV2.pw.priceNoTrial`), il n'y a rien à changer.
3. Pour l'offre flash, crée le pendant Play du produit promo utilisé sur iOS : soit un second
   abonnement `sophia_pro_promo` avec un plan `annual`, soit un plan de base annuel moins cher
   dans `sophia_pro`. C'est lui qui alimentera `offre_discount`.
4. **Configuration → Test de licence** : ajoute ton compte Google pour acheter sans être
   débité.

## Étape 2 — RevenueCat : ajouter l'app Play au projet existant

1. Ouvre le projet Sophia existant → **Project settings → Apps → New app → Google Play Store**.
2. Package : `app.rork.sophia`.
3. **Service Account Credentials** : dans Google Cloud, crée un compte de service, puis dans
   Play Console → **Utilisateurs et autorisations**, invite ce compte avec les droits de
   consultation des données financières et de gestion des commandes. Téléverse son JSON dans
   RevenueCat et attends la pastille verte : c'est ce qui autorise RC à valider les achats
   Play.

## Étape 3 — Rattacher les produits Play à l'entitlement existant

1. **Products → Import** : importe les produits Play créés à l'étape 1.
2. **Entitlements → `premium`** (celui qui existe déjà) → attache les nouveaux produits Play,
   à côté des produits App Store. C'est ce partage qui rend l'abonnement multi-plateforme.

## Étape 4 — Ajouter les produits Play dans les packages existants

N'ajoute aucun offering. Ouvre chacun de ceux qui existent et, dans chaque package, ajoute le
produit Play à côté du produit App Store — un package peut contenir un produit par store.

| Offering existant | Package | Produit Play à y ajouter | Écran Android |
|---|---|---|---|
| `fin_onboarding` | `$rc_annual` | `sophia_pro:annual` | fin d'onboarding |
| `fin_onboarding` | `$rc_monthly` | `sophia_pro:monthly` | comparatif des plans |
| `debloquer_cours` | `$rc_annual` | `sophia_pro:annual` | cours du jour déjà lu |
| `quizz` | `$rc_annual` | `sophia_pro:annual` | quiz et entraînement |
| `offre_discount` | `$rc_annual` | produit promo | offre flash 60 min |

Le badge d'économie du comparatif est calculé à l'exécution en comparant l'annuel à douze
mensualités (`StoreViewModel.discountBadge`) : il n'y a rien à saisir pour lui, mais il ne
s'affichera que si `$rc_monthly` a bien un produit Play.

## Étape 5 — La clé Android

**Project settings → API keys** : l'app Google Play a sa propre clé publique `goog_…` (la clé
`appl_…` d'iOS ne fonctionne pas ici). Mets-la dans `android/local.properties`, fichier
git-ignoré que le build lit avant toute valeur par défaut :

```properties
sdk.dir=/chemin/vers/Android/sdk

REVENUECAT_API_KEY=goog_xxxxxxxxxxxxxxxxxxxxx
REVENUECAT_TEST_API_KEY=goog_xxxxxxxxxxxxxxxxxxxxx
```

Tant que la clé vaut `goog_REPLACE_ME`, le SDK n'est pas configuré : l'app tourne en mode
gratuit et le bouton d'achat débloque Premium **localement** pour visiter les écrans. Dès
qu'une vraie clé est là, ce raccourci disparaît.

## Étape 6 — Vérifier

1. Build **debug** sur un appareil connecté avec le compte testeur de licence. Les logs
   RevenueCat sont en niveau DEBUG dans cette variante, donc les offerings récupérés et les
   erreurs de configuration apparaissent dans `logcat`.
2. Ouvre un deuxième cours dans la journée. Le paywall « cours débloqué » doit afficher un
   **vrai prix** ; `39,99 €` signifie que le repli codé en dur s'applique, donc que l'offering
   demandé n'a pas de produit Play dans `$rc_annual`.
3. Achète : l'app passe Premium immédiatement.
4. Ferme un paywall contextuel : le comparatif annuel/mensuel doit s'ouvrir, avec un prix
   mensuel réel.

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
