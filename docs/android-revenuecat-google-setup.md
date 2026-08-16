# Brancher RevenueCat et Google OAuth (Android)

Tout le code est en place. Il ne reste que de la configuration côté consoles, plus une clé à
poser dans `android/local.properties` (fichier git-ignoré).

## 0. Où vont les clés

`android/app/build.gradle.kts` lit chaque secret dans cet ordre : `local.properties` →
propriété Gradle (`-P`) → variable d'environnement → valeur par défaut du dépôt.

Crée `android/local.properties` :

```properties
# SDK Android (déjà présent si tu ouvres le projet dans Android Studio)
sdk.dir=/chemin/vers/Android/sdk

# RevenueCat
REVENUECAT_API_KEY=goog_xxxxxxxxxxxxxxxxxxxxx
REVENUECAT_TEST_API_KEY=goog_xxxxxxxxxxxxxxxxxxxxx

# Optionnel : uniquement si tu changes de projet Google/Supabase
# GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com
# SUPABASE_URL=https://xxxx.supabase.co
# SUPABASE_ANON_KEY=sb_publishable_xxx
```

Tant que `REVENUECAT_API_KEY` vaut `goog_REPLACE_ME`, le SDK n'est pas configuré : l'app
reste utilisable et le bouton d'achat débloque Premium **en local** pour tester les écrans.
Dès qu'une vraie clé est posée, ce raccourci disparaît et les vrais achats prennent le relais.

---

## 1. RevenueCat

### 1.1 Play Console (prérequis)

1. Crée l'application avec le package `app.rork.sophia`.
2. Envoie un premier build signé (AAB) sur une piste **test interne**. Les abonnements ne
   sont configurables qu'après un premier envoi.
3. Renseigne le compte marchand (Paiements) : sans lui, pas d'abonnement.
4. **Monétisation → Abonnements** : crée un produit d'abonnement, par exemple
   `sophia_pro`, avec deux plans de base :
   - `annual` (P1Y) — le plan principal,
   - `monthly` (P1M) — affiché dans le comparatif.
5. Sur le plan annuel, ajoute une **offre** d'essai gratuit de 3 jours. Le code lit l'essai
   sur le produit servi : s'il n'y a pas d'offre d'essai, les écrans basculent
   automatiquement sur la formulation « sans essai » (rien à changer dans le code).
6. **Utilisateurs et autorisations** : crée un compte de service Google Cloud, donne-lui
   l'accès à l'API Google Play Developer, télécharge le JSON (il sert à l'étape suivante).
7. **Configuration → Test de licence** : ajoute ton compte Google pour acheter sans être
   débité.

### 1.2 Tableau de bord RevenueCat

1. Crée un projet, puis une app **Google Play** avec le package `app.rork.sophia`.
2. Colle le JSON du compte de service (Play Service Credentials). Attends la validation
   verte — c'est ce qui permet à RC de vérifier les achats.
3. **Entitlements** : crée l'entitlement d'identifiant exact `premium`. C'est lui que l'app
   lit (`AppConfig.PREMIUM_ENTITLEMENT`).
4. **Products** : importe `sophia_pro:annual` et `sophia_pro:monthly`, rattache-les à
   l'entitlement `premium`.
5. **Offerings** : crée quatre offerings, avec ces identifiants exacts (l'app les demande
   par nom) :

   | Offering | Packages attendus | Écran |
   |---|---|---|
   | `fin_onboarding` | `$rc_annual` + `$rc_monthly` | fin d'onboarding + comparatif |
   | `debloquer_cours` | `$rc_annual` | cours du jour déjà lu |
   | `quizz` | `$rc_annual` | quiz et entraînement |
   | `offre_discount` | `$rc_annual` (produit au prix promo) | offre flash 60 min |

   Pour `offre_discount`, crée un second produit annuel moins cher côté Play et rattache-le
   à cet offering : le paywall affiche le prix barré du plan annuel normal et le prix promo.
6. **API keys** : copie la clé publique Android (`goog_…`) dans `local.properties`.

### 1.3 Vérifier

1. Installe un build **debug** sur un appareil connecté avec le compte testeur de licence.
2. Ouvre un deuxième cours dans la journée : le paywall « cours débloqué » doit afficher
   de **vrais prix** (et non `39,99 €`, qui est le repli codé en dur).
3. Achète : l'app doit passer Premium immédiatement (`Purchases.logIn` est déjà appelé à la
   connexion, donc l'achat suit le compte).
4. Réinstalle puis « Restaurer » dans Réglages → Légal.

Si les prix restent au repli : l'offering demandé n'existe pas ou n'a pas de package annuel.
Si l'achat échoue avec « produit indisponible » : le build installé n'est pas signé avec la
même clé que celui envoyé sur la piste de test.

---

## 2. Google OAuth (connexion Supabase)

L'app utilise **Credential Manager** avec un jeton d'identité Google, transmis à Supabase.
Il faut donc deux clients OAuth dans le même projet Google Cloud : un **Web** (celui dont
l'ID est déjà dans le dépôt, utilisé comme `serverClientId`) et un **Android** (qui autorise
ton APK à demander le jeton).

### 2.1 Google Cloud Console

1. Ouvre le projet qui contient déjà le client Web
   `716867958674-…apps.googleusercontent.com` (ou crée le tien et mets son ID dans
   `local.properties`).
2. **API et services → Identifiants → Créer des identifiants → ID client OAuth → Android**.
3. Nom du package : `app.rork.sophia`.
4. Empreinte SHA-1 : il en faut **deux**, une par clé de signature.
   - Debug :
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```
   - Release : Play Console → **Intégrité de l'app → Signature d'app** → copie le SHA-1 de
     la clé de signature d'application (celle générée par Google, pas seulement celle
     d'importation).
   Crée un client Android par empreinte.
5. Écran de consentement OAuth : renseigne le nom de l'app et l'email de support. Tant qu'il
   est en mode Test, seuls les comptes ajoutés comme testeurs peuvent se connecter.

### 2.2 Supabase

1. **Authentication → Providers → Google** : active le provider.
2. Colle le **Client ID Web** et son **Client Secret**.
3. Dans **Authorized Client IDs**, ajoute le **Client ID Web**. C'est l'étape qu'on oublie :
   sans elle, la connexion native par jeton d'identité est rejetée alors que le flux web
   fonctionne.
4. Vérifie que `SUPABASE_URL` et `SUPABASE_ANON_KEY` correspondent bien à ce projet.

### 2.3 Vérifier

1. Sur un appareil avec les services Google Play et un compte Google ajouté.
2. Onboarding → écran « Crée ton compte » → Continue with Google, ou Réglages → Compte.
3. Supabase → Authentication → Users : une ligne doit apparaître.
4. RevenueCat → Customers : l'identifiant utilisateur Supabase doit apparaître (l'app appelle
   `Purchases.logIn` après la connexion), ce qui permet de retrouver l'abonnement sur un
   autre appareil.

### Erreurs fréquentes

| Symptôme | Cause |
|---|---|
| `GetCredentialException: No credentials available` | Aucun compte Google sur l'appareil, ou client Android OAuth absent pour ce SHA-1 |
| `Caller not authorized` / erreur 16 | Le SHA-1 ou le package ne correspond pas au client Android |
| Supabase répond `invalid_client` | Le Client ID Web n'est pas dans « Authorized Client IDs » |
| Connexion OK mais Premium perdu au changement d'appareil | L'utilisateur n'était pas connecté au moment de l'achat |

---

## 3. Ce que fait déjà le freemium

Pour tester sans attendre : **Réglages → Données → « Reset cours du jour »** rend le cours
gratuit quotidien, ce qui permet de rejouer toutes les barrières.

| Barrière | Règle |
|---|---|
| Cours du jour | Le premier cours ouvert dans la journée est intégralement gratuit |
| Autres cours | Page 1 lisible, pages suivantes floutées avec le cadenas → paywall `debloquer_cours` |
| Fin de cours | Réservée au cours du jour ou aux abonnés |
| Quiz | Toujours Premium → paywall `quizz` |
| Entraînement | Toujours Premium → paywall `entrainement` (offering `quizz`) |
| Offre flash | 3 swipes sur l'accueil → cadeau à ouvrir en 3 taps → 60 minutes de promo, une fois par jour |
| Seconde chance | Fermer un paywall contextuel ouvre le comparatif annuel/mensuel avant de sortir |
