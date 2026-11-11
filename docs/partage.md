# Partage d'un cours ou d'un auteur

Depuis le 10 novembre, partager un cours ou un auteur depuis l'app iOS envoie la phrase
habituelle **suivie d'un lien du site** : `https://sophia-culture.com/courses/150` (le site redirige
vers l'adresse lisible) ou `https://sophia-culture.com/authors/<slug>`.

| La personne qui reçoit le lien | Ce qui se passe |
| --- | --- |
| a Sophia sur son iPhone | le lien ouvre le cours (ou la page de l'auteur) **dans l'app** : lien universel |
| n'a pas Sophia | la page du site : couverture, titre, accroche, première partie, boutons des stores. L'aperçu (titre, couverture) s'affiche dans iMessage, WhatsApp… |
| installe l'app depuis cette page | à la fin de l'onboarding, l'app ouvre le cours partagé (reprise après installation) |
| ouvre la page dans Safari, app installée | bannière « Ouvrir » en haut de la page, qui mène au cours dans l'app |

## Les pièces

- **App iOS** : `SophiaDeepLink` fabrique et reconnaît les adresses du site (`courseWebURL`,
  `authorWebURL`, `webTarget`) ; `DeepLinkRouter.open` les traite comme les liens `sophia://`.
  Le droit `applinks:sophia-culture.com` est dans `Sophia.entitlements`. Boutons de partage :
  carte du fil d'accueil, fiche du cours, page du créateur. Une ouverture par lien compte
  `course_open` avec `source = shared_link`.
- **Site** : `/.well-known/apple-app-site-association` (route Next) déclare l'app
  (`IOS_APP_ID` = Team ID + bundle id) pour `/courses/*`, `/c/*` et `/authors/*`. `/c/<identifiant>`
  redirige vers la fiche. Les fiches portent l'aperçu (Open Graph, Twitter) et la bannière Safari
  (`apple-itunes-app` avec l'adresse de la page).
- **Reprise après installation** : l'App Store ne transmet rien à l'app installée. Sur la page
  d'un cours ou d'un auteur, le bouton du store copie l'adresse de la page dans le presse-papiers
  (`StoreLink`). Au tout premier lancement, `DeferredLink` regarde si le presse-papiers contient
  une adresse web, sans la lire ; si oui il la lit, **ce qui affiche la demande « Autoriser le
  collage » d'iOS**, et ne garde qu'une adresse de cours ou d'auteur du site. Elle est ouverte à la
  fin de l'onboarding. Le contrôle n'a lieu qu'une fois, jamais pour une app déjà utilisée.

## À faire hors du code

- Activer **Associated Domains** sur l'identifiant de l'app (Apple Developer, Identifiers) : sans
  cela le build signé refuse le droit `applinks`.
- Déployer le site **avant** la version de l'app : iOS lit le fichier d'association à
  l'installation ou à la mise à jour de l'app.
- Vérifier après déploiement : `https://sophia-culture.com/.well-known/apple-app-site-association`
  répond en JSON, sans redirection.

## Limites

- Le site est en anglais : un cours partagé depuis l'app en français mène à sa fiche anglaise.
- Android : le partage envoie le lien et l'app ouvre les liens du site (voir « Android » plus bas) ;
  la reprise après installation n'y existe pas encore.
- Un cours sans numéro dans son identifiant n'a pas de fiche sur le site : `/c/<identifiant>` mène
  alors à l'exploration.

## Android

- **App** : `SophiaLinks` (domaine) fabrique et reconnaît les adresses du site, comme
  `SophiaDeepLink` sur iOS. Le partage de la fiche d'un cours et de la page d'un créateur envoie
  la phrase habituelle suivie du lien. `MainActivity` reçoit les liens `https://sophia-culture.com`
  (`/courses/*`, `/c/*`, `/authors/*`, filtre `autoVerify` du manifeste) ; un lien `/courses/150`
  ne porte que le numéro, l'identifiant est retrouvé dans le catalogue. Une ouverture par lien
  compte `course_open` avec `source = shared_link`.
- **Site** : `/.well-known/assetlinks.json` (route Next) déclare l'app (`ANDROID_PACKAGE`) et les
  empreintes de ses certificats (`ANDROID_APP_FINGERPRINTS`, séparées par des virgules). Tant que
  la variable est vide, le fichier est une liste vide et les liens restent dans le navigateur.
- **À faire hors du code** : copier les deux empreintes SHA-256 de la Play Console (Intégrité de
  l'application : clé de signature d'application et clé d'importation) dans
  `ANDROID_APP_FINGERPRINTS` sur Vercel, déployer le site, puis publier l'app. Vérifier ensuite que
  `https://sophia-culture.com/.well-known/assetlinks.json` répond en JSON, sans redirection.
- **Pas encore fait** : la reprise après installation (ouvrir le cours partagé à la fin de
  l'onboarding). Sur Android elle passerait par le paramètre `referrer` du lien Play Store et la
  bibliothèque Install Referrer.
