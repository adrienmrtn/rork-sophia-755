# TikTok blocker iOS — « Cultive-toi avant de scroller »

Réservé aux abonnés Premium. TikTok reste bloqué tant que l'utilisateur n'a pas
terminé un cours Sophia **et** son quiz ; ensuite TikTok s'ouvre pendant 15, 30 ou
60 minutes, puis le blocage revient tout seul.

## Comment ça marche (technique)

iOS n'autorise qu'une seule façon de bloquer une autre app : l'API **Screen Time**
(FamilyControls + ManagedSettings + DeviceActivity). On ne « détecte » pas l'ouverture
de TikTok, on pose un **bouclier système** dessus. Quand l'utilisateur ouvre TikTok,
iOS affiche notre écran plein à la place.

1. **Réglages › Concentration › TikTok blocker.** Toggle. Premier tap : paywall si
   non-abonné, sinon autorisation Temps d'écran (pop-up Apple), puis le sélecteur
   d'apps Apple avec la consigne « Coche TikTok ». Apple ne nous dit jamais quelle app
   a été cochée (jetons opaques) : c'est la consigne qui garantit que c'est TikTok.
2. **Bouclier.** L'extension `SophiaShieldConfiguration` dessine l'écran plein :
   « Cultive-toi avant de scroller », sous-titre, bouton « Ouvrir Sophia », bouton
   « Fermer ». Couleurs, icône, textes et deux boutons : c'est tout ce qu'Apple laisse
   personnaliser, la mise en page est la sienne.
3. **« Ouvrir Sophia ».** Une extension n'a pas le droit de lancer une app. L'extension
   `SophiaShieldAction` écrit un tampon dans l'App Group, envoie une notification locale
   « Un cours, puis tu scrolles » et ferme TikTok. L'utilisateur tape la notification
   (ou ouvre Sophia à la main dans les 10 minutes, le tampon suffit).
4. **Cours direct.** `ContentView` lit le tampon au premier plan et ouvre immédiatement
   un cours (reco de l'accueil, restreinte aux cours avec quiz). Le lecteur affiche un
   bandeau « TikTok est bloqué · termine le cours et le quiz ». Si l'utilisateur
   ressort du cours, le même cours lui sera reproposé au prochain passage.
5. **Quiz terminé.** `QuizView` prévient `TikTokBlockerManager`. Le bouclier est levé
   sur-le-champ (avant même l'écran de résultat), et un intervalle DeviceActivity d'une
   durée = durée de déblocage est armé. Un quiz fait spontanément (sans passer par le
   bouclier) débloque aussi TikTok : le deal est « un cours + un quiz = du TikTok ».
6. **Écran « Tu t'es cultivé, bien joué ».** Affiché sur l'accueil à la sortie du
   quiz quand la visite venait du bouclier : compte à rebours, bouton **« Retourner
   sur TikTok »** (`tiktok://`), bouton « Rester sur Sophia ».
7. **Fin du délai.** iOS réveille l'extension `SophiaDeviceActivityMonitor`, qui
   remet le bouclier, Sophia ouverte ou non. Par sécurité l'app refait la même
   vérification à chaque retour au premier plan.

## Fichiers

| Où | Quoi |
| --- | --- |
| `ios/SophiaBlockerShared/TikTokBlockerShared.swift` | État partagé (App Group), pose/retrait du bouclier, textes du bouclier fr/en/es/de/it/pt. Compilé dans l'app **et** les 3 extensions. |
| `ios/Sophia/Services/TikTokBlocker/TikTokBlockerManager.swift` | Autorisation, activation, session « visite depuis le bouclier », déblocage, timer. |
| `ios/Sophia/Views/TikTokBlocker/TikTokBlockerSettingsView.swift` | Écran de réglages (toggle, app choisie, durée, état, avertissements, « comment ça marche »). |
| `ios/Sophia/Views/TikTokBlocker/TikTokUnlockedView.swift` | Écran « bien joué » + bandeau du lecteur. |
| `ios/SophiaShieldConfiguration/` | Extension : apparence du bouclier. |
| `ios/SophiaShieldAction/` | Extension : boutons du bouclier + notification. |
| `ios/SophiaDeviceActivityMonitor/` | Extension : fin de la fenêtre de déblocage. |
| `SettingsView`, `ContentView`, `CourseView`, `QuizView`, `SophiaApp`, `DeepLinkRouter`, `SophiaDeepLink` | Branchements. |
| `Sophia.entitlements`, `Info.plist`, `project.pbxproj` | Family Controls, App Group `group.app.rork.sophia`, schéma `tiktok`, 3 cibles d'extension, phase « Embed Foundation Extensions ». |

Analytics Mixpanel : `tiktok_blocker_toggled`, `tiktok_blocker_course_opened`,
`tiktok_blocker_unlocked` (minutes, course_id, from_shield),
`tiktok_blocker_returned_to_tiktok`.

## Ce que tu dois faire

### 1. Demander l'entitlement Family Controls à Apple (chemin critique)

Sans lui, tout ça ne fonctionne qu'en développement (Xcode le donne automatiquement
pour les builds de dev). Pour TestFlight et l'App Store il faut la version
« Distribution », accordée sur demande, en général en quelques jours à quelques
semaines.

- Formulaire : https://developer.apple.com/contact/request/family-controls-distribution
- Compte : le compte titulaire (Account Holder) de l'équipe `K792T8TQ4X`.
- Bundle IDs à déclarer : l'app **et** les 3 extensions
  (`app.rork.assvmps5x7hpyq0ezcsut`, `.ShieldConfiguration`, `.ShieldAction`,
  `.DeviceActivityMonitor`).
- Description à donner : app d'éducation ; l'utilisateur choisit lui-même de
  bloquer TikTok sur son propre iPhone (autorisation `.individual`, pas de contrôle
  parental) et débloque en terminant un cours et un quiz ; il peut désactiver le
  blocage à tout moment sans abonnement. Aucune donnée Temps d'écran n'est
  collectée ni envoyée (les jetons restent sur l'appareil).

### 2. Certificates, Identifiers & Profiles

Une fois l'entitlement accordé :

- App ID principal : activer **Family Controls** et **App Groups**, y attacher le
  groupe `group.app.rork.sophia` (à créer dans Identifiers › App Groups).
- Créer les 3 App IDs des extensions (mêmes deux capabilities, même groupe). Avec la
  signature automatique, Xcode les crée seul si le compte a les droits.

### 3. Xcode

- Ouvrir le projet : les 3 nouvelles cibles apparaissent, avec le dossier
  `SophiaBlockerShared` partagé par les 4 cibles.
- Signing & Capabilities sur chacune des 4 cibles : équipe `K792T8TQ4X`, signature
  automatique. Vérifier que Family Controls et App Groups sont cochés (les fichiers
  `.entitlements` sont déjà là).
- Si Xcode signale que `Info.plist` d'une extension est aussi copié en ressource,
  retirer `Info.plist` de l'appartenance à la cible (File inspector) : le projet
  contient déjà l'exception, ce point est là au cas où.
- Le `MARKETING_VERSION` des extensions doit rester identique à celui de l'app
  (`1.1.6` aujourd'hui) : à bumper ensemble. Le `CURRENT_PROJECT_VERSION` est déjà
  aligné sur toutes les cibles par `ci_scripts/ci_pre_xcodebuild.sh`.

### 4. Tester

- **iPhone physique obligatoire**, le simulateur ne pose pas de bouclier.
- TikTok installé, Sophia avec un compte Premium (ou build DEBUG).
- Réglages › Concentration › TikTok blocker › toggle › autoriser › cocher TikTok.
- Ouvrir TikTok : bouclier bleu. « Ouvrir Sophia » : TikTok se ferme, notification,
  tap : Sophia s'ouvre directement sur un cours avec le bandeau.
- Finir le cours et le quiz : écran « bien joué », « Retourner sur TikTok » ouvre
  TikTok sans bouclier. Attendre la fin du compte à rebours : bouclier de retour.
- Vérifier aussi : « Reverrouiller » dans les réglages, toggle off qui lève tout,
  et le cas notifications refusées (avertissement dans les réglages ; ouvrir Sophia
  à la main après « Ouvrir Sophia » doit quand même mener au cours).

Trois points à confirmer sur l'appareil au premier build, je n'ai pas pu compiler ici :

- la notification envoyée depuis l'extension d'action (pratique courante des apps
  du genre, mais à voir en vrai sur cet iOS) ;
- l'intervalle DeviceActivity avec des composants année/mois/jour/heure/minute
  (one-shot). En cas de refus, repli : `intervalStart`/`intervalEnd` en heure/minute
  seulement ;
- le premier build Xcode avec les 3 cibles ajoutées à la main dans le `pbxproj`.

### 5. App Store

- Notes de review : expliquer l'usage de Screen Time comme ci-dessus, préciser que
  le blocage est désactivable gratuitement à tout moment (le toggle et « Fermer »
  sur le bouclier ne demandent aucun abonnement) et fournir un compte Premium de
  test.
- Politique de confidentialité : ajouter un paragraphe Temps d'écran (aucune
  donnée d'usage collectée, sélection stockée uniquement sur l'appareil).
- Fiche App Store : la fonctionnalité mérite une capture, c'est un argument
  d'abonnement.

## Limites connues

- Le bouclier ne peut pas ouvrir Sophia directement : passage par une notification
  (ou ouverture manuelle). Compromis identique chez Opal, one sec, ScreenZen.
- On ne peut pas vérifier que c'est bien TikTok qui a été coché. Si l'utilisateur
  coche autre chose, le blocage marche mais le bouton de retour ouvre TikTok.
- Minimum 15 minutes de déblocage (contrainte DeviceActivity).
- Un abonnement qui expire laisse le blocage en place (le quiz redevient payant) :
  l'utilisateur peut toujours le désactiver depuis les réglages.
- Le bouclier disparaît avec la désinstallation de Sophia (comportement iOS).
