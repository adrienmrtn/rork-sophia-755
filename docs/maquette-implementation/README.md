# Maquette « Sophia nouvelle génération » : implémentation (prompt 2)

Ce dossier met côte à côte la maquette (artefact Claude Design, rendu statique de chaque
écran à 390 × 844) et l'implémentation dans les deux apps. Les captures d'app s'ajoutent
depuis un simulateur iOS et un émulateur Android (aucun des deux n'était disponible dans
la session qui a écrit le code) : `ios/<ecran>.png` et `android/<ecran>.png`, mêmes noms
que dans `maquette/`.

| Écran | Maquette | iOS | Android |
| --- | --- | --- | --- |
| Accueil (fil Pour toi, cartes cours / événement / Deviens créateur) | `maquette/home.png` | `HomeFeedView` | `ui/newgen/HomeFeedScreen` |
| Fiche cours | `maquette/course.png` | `CourseDetailView` | `ui/newgen/CourseDetailScreen` |
| Page créateur | `maquette/creator.png` | `CreatorPageView` | `ui/newgen/CreatorPageScreen` |
| Profil | `maquette/profile.png` | `ProfileV2View` | `ui/newgen/ProfileV2Screen` |
| Explorer | `maquette/explorer.png` | `ExploreView` | `ui/newgen/ExploreScreen` |
| Apprendre | `maquette/learn.png` | `LearnHubView` | `ui/newgen/LearnHubScreen` |
| Événement | `maquette/event.png` | `EventPageView` | `ui/newgen/EventPageScreen` |
| Cours ouvert (lecteur) | `maquette/reader.png` | `CourseView` (barre en segments, Suivre, Traduit de) | `ui/course/CourseScreen` |

## Ce qui diffère volontairement de la maquette

- **Compteurs** (lectures, j'aime, abonnés, participants) : valeurs locales stables dérivées
  d'un hash de l'identifiant tant que le serveur ne les fournit pas (prompt 6). Le geste de
  l'utilisateur (j'aime, suivre) s'ajoute par-dessus.
- **Vidéos** : aucune carte vidéo n'est affichée (prompt 10) ; l'emplacement typé existe
  (`FeedItem.video`, `VideoFeedCard`).
- **« Suivi par Léa et 2 amis »** : pas affiché, les abonnements des amis n'existent pas
  encore côté serveur.
- **Séries** d'un créateur : onglet présent, vide pour l'instant (pas de données).
- **« Traduit de l'anglais · Voir l'original »** : la ligne n'apparaît que lorsque le JSON
  du cours porte `originalLanguage` (prévu pour les cours de créateurs, prompt 3).
- **Événement** : servi par le manifeste du catalogue depuis la table `campaigns`, éditée dans
  l'admin du site (docs/evenements.md). `content/events/movember.json` n'est plus embarqué : il
  reste l'exemple du format, et l'amorce de la ligne `movember-2026` (en brouillon).
- **Navigation** : les 4 onglets sont derrière un drapeau tiré au sort à l'installation
  (`FeatureFlags.navigationVariant`, A/B 50 %) ; les 5 onglets historiques restent la
  variante témoin. Réglages → section développeur pour forcer l'une ou l'autre.

## Comment capturer

1. iOS : simulateur iPhone 15 Pro (390 × 844 pt), réglage développeur « Navigation (A/B) »
   sur `newgen`, relancer l'app, `⌘S` sur chaque écran, enregistrer dans `ios/`.
2. Android : émulateur Pixel 7 (412 × 915 dp), même réglage, capture depuis Android Studio,
   enregistrer dans `android/`.

## Retouches après la première relecture (novembre 2026)

- **Fil d'accueil paginé** : une carte par écran, défilement vertical avec snap (comme un
  réseau vidéo), la carte suivante dépasse de 44 pt en bas. L'en-tête et le segment
  « Pour toi / Abonnements » restent fixes au-dessus du fil. Un double-tap sur la carte
  l'aime ; le cœur rebondit et lâche un éclat de particules à chaque « j'aime ».
- **Fin de cours** : deux boutons sous la carte XP, « Aimer ce cours » et « Suivre {prénom} »
  (événements `like` / `follow` avec `screen = course_end`).
- **Explorer** : c'est la variante B « univers » de la maquette (`ExplorerB.dc.html`) qui est
  retenue : chips « On cherche beaucoup cette semaine » (six titres courts tirés par semaine,
  avec résultats sous la rangée), grille « Univers » (les six plus grandes sous-catégories de
  la langue, couverture du cours le plus lu), carrousel « Créateurs à suivre ». La rangée
  « En moins d'une minute » attend les vidéos (prompt 10).
- **Avatar du lecteur** : dans le profil, le rond bleu à l'initiale s'ouvre sur une feuille de
  vingt avatars illustrés (les mêmes fichiers que le Studio, `design/site-art/manifest-avatars.json`,
  embarqués : iOS `Assets.xcassets/avatar_NN`, Android `drawable-nodpi/avatar_NN.webp`). Un lecteur
  n'a que ce choix, ou « pas d'avatar » pour revenir à ses initiales : jamais de vraie photo. Le
  choix (`UserProgress.avatarId`) voyage avec la progression, donc d'un appareil à l'autre ; un
  identifiant inconnu retombe sur les initiales. Textes `profile.avatar.title` et
  `profile.avatar.none` dans les 30 langues.
- **Tendances** : l'onglet Explorer lit d'abord `trending` du manifeste (les cours les plus ouverts
  de la langue sur sept jours, recalculés chaque nuit, docs/notifications.md) et ne retombe sur le
  tirage local hebdomadaire que si la liste est vide.
