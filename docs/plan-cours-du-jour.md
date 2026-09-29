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
- **Mixpanel** : `daily_question_notification_opened`, `daily_question_widget_opened`,
  `daily_question_widget_promo_dismissed` ; `course_opened` porte la source
  `notification_daily_question` ou `widget_daily_question`.
- Textes dans les 26 langues.

## Ce que tu dois faire

1. **Apple Developer › Identifiers** : l'App ID du widget
   `app.rork.assvmps5x7hpyq0ezcsut.DailyQuestionWidget` avec la capability **App Groups** et le
   groupe `group.app.rork.sophia`. Avec la signature automatique, Xcode le crée seul si le
   compte a les droits ; sinon le créer à la main avant le build Xcode Cloud.
2. **Build** : la cible `SophiaWidget` a été ajoutée au projet à la main (comme les extensions
   du blocker), sans Xcode dans la session. Le premier build Xcode Cloud la valide ; au premier
   passage dans Xcode, vérifier Signing & Capabilities de la cible (équipe `K792T8TQ4X`).
3. **Version** : le `MARKETING_VERSION` du widget (`1.1.7`) doit suivre celui de l'app, comme
   ceux des extensions du blocker.
4. **À trancher** : l'onboarding promet encore « Tu recevras un rappel 1 jour avant la fin de
   ton essai » (`onboardingV2.trial.*`). Aucune notification ne part pendant l'essai.

## Tester

- Nouveau compte gratuit : la Biblio montre la question du jour en premier ; Réglages › Rappel
  quotidien → choisir la prochaine heure pleine, sortir de l'app ; à l'heure dite la
  notification arrive avec la question et ouvre le cours.
- Compte en essai : aucune notification pendant l'essai, pas de réglage d'heure, pas de carte
  widget ; un widget posé n'affiche que « Sophia ».
- Lire la question du jour : la carte « Ajoute le widget » apparaît ; poser le widget, il
  montre la même question que la Biblio.
