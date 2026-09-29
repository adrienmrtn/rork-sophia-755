# Plan : un cours par jour (iOS)

Proposition du 29/09/2026, iOS uniquement. Coche les décisions que tu valides.

**Fait dans cette branche**

- [x] Astérisques. Les descriptions traduites (25 langues, environ 65 cours par langue ; le
  français n'en a aucune) gardent le gras `**…**`, l'italique `*…*` et les `[[termes]]` du
  cours. La carte « À la une » les affiche maintenant sans balisage
  (`Course.plainDescription`). Les titres de collections allemands et portugais qui
  portaient des `**` dans l'onglet Parcours sont nettoyés eux aussi.

**Ce qui existe aujourd'hui**

- « À la une » (Biblio) : les 6 premiers cours d'une liste figée (`CuratedStarterCourses`).
  C'est le même ordre pour tout le monde, cours déjà lus compris.
- La notif quotidienne existe déjà (`DailyCourseReminder`, à l'heure choisie dans l'OB). Ses
  limites :
  - le texte est générique et ne mène à aucun cours ;
  - elle n'est programmée qu'à la fin de l'OB et n'est jamais reprogrammée ;
  - tout le monde la reçoit, essais compris, même quand le cours est déjà lu ;
  - aucun réglage ne permet de changer l'heure.
- L'OB promet « un rappel 1 jour avant la fin de ton essai », mais ce rappel n'est jamais envoyé.
- Aucun « cours du jour » n'est calculé. Le cours gratuit du jour est le premier cours ouvert,
  et le blocker TikTok en tire un au hasard.
- 254 cours sur 309 ont un titre en forme de question, dans les 26 langues. Les 55 autres
  (« Hamlet, Shakespeare », « La Commune de Paris (1871) »…) ne seront jamais la question du
  jour ni « À la une ».
- L'app connaît déjà le statut d'essai (`StoreViewModel.isInFreeTrial`, `expiresAt`) mais ne
  s'en sert pas.

## 1. La question du jour, une seule source

`DailyQuestion.course(for: date)` alimente la Biblio, la notif, le widget, le Parcours et le
blocker TikTok.

- Les 254 questions suivent un ordre fixe, mélangé une fois par script en alternant les
  matières : le jour N affiche la question N, soit environ 8 mois sans répétition.
- La question change à minuit, heure locale.
- Tout le monde a la même question le même jour. Si la personne l'a déjà lue, elle passe à la
  suivante qu'elle n'a pas lue.
- [ ] La question du jour est toujours lisible en entier, **en plus** du cours gratuit du jour.
  Sinon, la notif du soir mène au paywall quand le cours gratuit a déjà servi. *(Recommandé.)*

## 2. « À la une » change chaque jour

- La carte 1 est la question du jour, avec le badge « Question du jour ».
- Les cartes 2 à 6 sont 5 questions non lues, tirées à partir de la date, une par matière, en
  priorité dans les intérêts de l'OB. Elles restent les mêmes toute la journée et changent le
  lendemain.

## 3. La notif quotidienne devient la question du jour

- Contenu :
  - titre : la question (« Pourquoi le savon tue-t-il les bactéries ? ») ;
  - texte : l'accroche du cours ;
  - au tap, le cours s'ouvre. Il faut pour cela un lien profond et un délégué de
    notifications, qui manquent aujourd'hui.
- Destinataires :

| Statut | Reçoit la notif |
| --- | --- |
| Premium en essai | Non. Seulement le rappel J-1 de fin d'essai promis dans l'OB |
| Premium payant (après l'essai, ou sans essai) | Oui, dès le lendemain de la fin d'essai |
| Gratuit, jamais d'essai | Oui |
| Gratuit, essai résilié | [ ] Oui *(recommandé, sinon ces personnes ne reçoivent plus rien)* |

- Mécanisme, uniquement des notifications locales :
  - 30 notifs datées, avec une question différente chaque jour, remplacent la notif répétée
    actuelle ;
  - elles sont recalculées à chaque ouverture de l'app, à chaque changement de statut
    RevenueCat, de langue ou d'heure, et après chaque cours lu ;
  - pendant l'essai, elles démarrent au lendemain de `expiresAt` ;
  - elles sont sautées le jour où la question a déjà été lue.
- Pas de push serveur : Supabase ne connaît pas le statut Premium (pas de webhook RevenueCat).
  Le local suffit tant que l'app est ouverte au moins une fois par mois.
- En plus : l'heure devient modifiable dans Profil > Réglages.

## 4. Widget « Question du jour » : faisable

- Formats (WidgetKit, cible iOS 18) : petit (la question), moyen (image et question), écran
  verrouillé et StandBy.
- Données : le widget ne peut pas charger le catalogue de 1,6 Mo. L'app écrit donc dans
  l'App Group existant (`group.app.rork.sophia`) les 30 prochaines questions (date, id, titre,
  matière) et leurs vignettes réduites.
- Rafraîchissement : l'app appelle `WidgetCenter.reloadAllTimelines()`. Le widget change seul à
  minuit, et un tap ouvre le cours.
- Hors code :
  - créer une cible Widget Extension et cocher l'App Group ;
  - régler la signature Xcode Cloud ;
  - comme il n'y a pas de Xcode ici, soit tu crées la cible dans Xcode (5 min), soit j'édite le
    pbxproj et un build Xcode Cloud le valide.
- iOS ne permet pas d'ajouter le widget à la place de l'utilisateur. Une carte « Ajoute la
  question du jour à ton écran d'accueil » apparaît donc après la première question lue.

## 5. Parcours : une étape par jour

- L'étape à jouer porte la mention « Aujourd'hui ». La terminer, ou lire la question du jour,
  valide la journée et la série.
- [ ] Pour les gratuits : 1 étape par jour. L'étape suivante affiche « Prochaine étape demain à
  8 h » et « Continuer maintenant avec Premium » au lieu du flou actuel. Les Premium avancent
  sans limite. *(Recommandé.)*

## Ordre de travail (une PR par lot, testée sur TestFlight)

1. Question du jour et « À la une » : ½ jour.
2. Notifications (y compris le rappel J-1 d'essai) : 1 jour.
3. Widget : 1,5 jour, plus la création de la cible.
4. Parcours : 1 jour.

Suivi dans Mixpanel : `daily_question_notification_opened`, `widget_opened`,
`daily_question_completed`, et rétention J7 / J30 avant et après.
