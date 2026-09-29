# Question du jour (iOS)

État au 29/09/2026. iOS uniquement.

## Décisions

- La question du jour **ne s'ajoute pas** au cours gratuit du jour : pour un gratuit, elle
  compte comme n'importe quel cours (le premier ouvert dans la journée est le gratuit).
- **Premium en essai gratuit : aucune notification** (pas même un rappel de fin d'essai) et
  pas de widget. Les notifications démarrent le lendemain de la fin de l'essai.
- Notifications pour : Premium payant (après l'essai ou sans essai), gratuit sans essai,
  gratuit qui a résilié son essai.
- Widget : oui, sauf pour les Premium en essai (ni affiché ni proposé).
- Parcours « une étape par jour » : validé, **pas fait pour l'instant**.

## Ce qui est fait

- **Astérisques** : la carte « À la une » affiche la description sans `**`, `*` ni `[[ ]]`
  (`Course.plainDescription`) ; les titres de collections allemands et portugais sont nettoyés.
- **Question du jour** (`Services/DailyQuestion.swift`) : les 254 cours dont le titre est une
  question, dans un ordre fixe où les matières alternent (jamais deux fois la même d'affilée).
  Jour N = question N depuis le 1er octobre 2026, la même pour tout le monde ; un cours déjà lu
  est sauté. Le plan des jours est mémorisé : la notification, le widget et la Biblio annoncent
  le même cours le même jour. Le blocker TikTok ouvre aussi la question du jour quand elle
  n'est pas lue.
- **« À la une »** (Biblio) : carte 1 = question du jour (pastille « Question du jour »), puis
  5 questions non lues, une par matière, intérêts de l'onboarding d'abord. Change à minuit.
  L'ancienne liste figée (`CuratedStarterCourses`) est supprimée.
- **Notifications** (`Services/DailyCourseReminder.swift`) : titre = la question, texte =
  l'accroche du cours, toucher = le cours s'ouvre. 30 notifications datées (une question
  différente par jour) remplacent l'ancienne notification répétée au texte générique.
  Recalculées à chaque ouverture, changement d'abonnement, de langue, d'heure, et après chaque
  cours lu. Pas de notification le jour où la question est déjà lue. Statut d'essai lu dans
  RevenueCat (`periodType == .trial`, `expirationDate`).
- **Réglage de l'heure** : Profil › Réglages › Rappel quotidien (caché pendant l'essai).
- **Aperçu de l'onboarding** : la notification montrée avant la demande d'autorisation est la
  vraie (question du jour + accroche).
- **Widget** (`ios/SophiaWidget`, code partagé `ios/SophiaWidgetShared`) : petit, moyen, écran
  verrouillé (rectangulaire et en ligne). L'app écrit dans l'App Group `group.app.rork.sophia`
  les questions des 30 prochains jours et leurs vignettes ; le widget change seul à minuit et
  ouvre le cours au toucher. Pendant l'essai, il n'affiche que « Sophia ».
- **Carte « Ajoute le widget »** dans la Biblio, après la première question du jour lue ; jamais
  pendant l'essai, ni quand le widget est déjà posé, ni après fermeture.
- Textes dans les 26 langues.

## Ce que tu dois faire

1. **Avant le prochain build Xcode Cloud** : créer l'App ID du widget. Sur
   developer.apple.com › Certificates, Identifiers & Profiles › Identifiers › « + » › App IDs ›
   App : description « Sophia Widget », Bundle ID explicite
   `app.rork.assvmps5x7hpyq0ezcsut.DailyQuestionWidget`, cocher **App Groups**, Register. Puis
   rouvrir cet identifiant › App Groups › Configure › cocher `group.app.rork.sophia` › Save.
2. **Lancer le build Xcode Cloud** sur `main`. S'il en était parti un avant l'étape 1 et qu'il
   a échoué sur la signature de `SophiaWidget`, le relancer. Si la signature échoue encore :
   ouvrir le projet dans Xcode › cible `SophiaWidget` › Signing & Capabilities › équipe
   `K792T8TQ4X`, « Automatically manage signing » coché, App Groups avec
   `group.app.rork.sophia` coché › commit › relancer le build.
3. **Version** : rien à faire. `ci_scripts/ci_pre_xcodebuild.sh` recopie la version de l'app
   sur toutes les cibles (widget et extensions du blocker) à chaque build Xcode Cloud.
4. **À trancher** : l'onboarding promet encore « Tu recevras un rappel 1 jour avant la fin de
   ton essai » (`onboardingV2.trial.*`). Aucune notification ne part pendant l'essai.

## Tester

**Build Debug (lancé depuis Xcode)** : Profil › Réglages › Développeur › **Tester les
notifications**. On y voit l'autorisation iOS, le statut RevenueCat (essai, payant, gratuit),
le jour à partir duquel la question du jour part, l'heure et la langue. On peut envoyer,
après 5 à 60 s, la question du jour, celle de demain, une au hasard, les 5 prochaines (une
toutes les 10 s) et la notification du blocker TikTok, avec le même contenu et le même lien
que les vraies. Le même écran reprogramme, efface, et liste les notifications programmées.
Les notifications de test ont leur préfixe (`sophia.debug.`) et ne touchent pas à la
programmation réelle. Cet écran n'existe pas dans TestFlight ni sur l'App Store.


- Nouveau compte gratuit : la Biblio montre la question du jour en premier ; Réglages › Rappel
  quotidien → choisir la prochaine heure pleine, sortir de l'app ; à l'heure dite la
  notification arrive avec la question et ouvre le cours.
- Compte en essai : aucune notification pendant l'essai, pas de réglage d'heure, pas de carte
  widget ; un widget posé n'affiche que « Sophia ».
- Lire la question du jour : la carte « Ajoute le widget » apparaît ; poser le widget, il
  montre la même question que la Biblio.
