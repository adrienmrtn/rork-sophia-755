# Parcours iOS — l'onglet « Duolingo infini »

L'onglet **Parcours** remplace l'onglet Collections (même emplacement, 3e onglet). La page
Collections n'a pas disparu : elle est accessible par le bouton « Collections » en haut du
Parcours, en attendant que le Parcours la remplace pour de bon. iOS uniquement pour l'instant.

## Ce que voit l'utilisateur

- **Un niveau = une collection**, dans l'ordre des collections du catalogue. Chaque niveau a
  sa bannière (couverture, numéro, titre, progression) puis ses **pods** sur un chemin
  sinueux : un pod par cours, et un **pod quiz** (trophée doré) pour finir. Le chemin est
  un seul scroll qui descend sur tous les niveaux.
- **Déblocage linéaire.** Dans un niveau, les cours s'ouvrent l'un après l'autre. Un cours
  déjà terminé ailleurs (accueil, Biblio) compte comme pod terminé. Le pod quiz s'ouvre
  quand tous les cours du niveau sont terminés. Le niveau suivant s'ouvre quand le quiz
  est réussi. Un pod verrouillé secoue la tête et affiche pourquoi (toast).
- **Quiz de niveau** : 20 questions tirées au sort dans les cours du niveau, réparties
  entre les cours, nouveau tirage à chaque essai. Réussite à **11/20** (strictement plus de
  la moitié, `LearningPathRules.passMark`). Essais illimités. Gratuit pour tout le monde
  (décision du 28/09 : les mini-quiz de cours restent Premium, pas celui-ci). Une seule
  question compte comme juste si elle est entièrement juste (le crédit partiel des
  frises et curseurs ne suffit pas).
- **Récompense** : +100 XP globaux la première fois qu'un niveau est réussi
  (`GlobalXPReason.pathLevelPassed`), avec la célébration de rang si le seuil est franchi.
- **Animations** : à chaque retour sur l'onglet, ce qui a changé depuis la dernière visite
  est rejoué dans l'ordre du chemin : le pod terminé se remplit et « pop », le connecteur
  se colore, le cadenas du pod suivant tremble puis cède, la bulle « Commencer » se pose
  dessus ; un niveau qui s'ouvre voit sa bannière repasser en couleur sous des confettis,
  avec un toast « Niveau N débloqué ! ». Le quiz réussi lance une pluie de confettis.
  Haptique à chaque étape.
- Première ouverture : explication « Ton parcours » (`TutorialFlags.path`).

## Où c'est dans le code

| Fichier | Rôle |
|---|---|
| `Models/LearningPath.swift` | Règles (`LearningPathRules`), nœuds et niveaux (`PathNode`, `PathLevel`, `LearningPathSnapshot`), moteur qui dérive l'état du chemin de la progression (`LearningPathEngine`), tirage du quiz (`PathQuizBuilder`), mémoire de ce que l'utilisateur a déjà vu (`LearningPathSeenStore`, UserDefaults, non synchronisé). |
| `Views/Path/LearningPathView.swift` | L'onglet : en-tête (niveau en cours, bouton Collections), scroll des niveaux, gestion des taps, toasts, séquence d'animations de révélation, auto-scroll. |
| `Views/Path/PathNodeViews.swift` | Géométrie du chemin (`PathLayout`), palette (`PathPalette`), pods 3D (`PathPodPressStyle`, `PathPodFace`, `PathQuizPodFace`), bulle, halo, secousse, connecteurs, bannière de niveau. |
| `Views/Path/PathQuizView.swift` | Écran du quiz de niveau : règles, session, résultat réussi/raté, XP, rang. |
| `Views/Path/QuizQuestionPane.swift` | Une question avec ses réponses et sa barre de feedback, tous types de questions. Même interaction que `QuizView` / `TrainingView`, réutilisable. |
| `Views/Path/PathConfettiBurst.swift` | Confettis (`Canvas` + `TimelineView`). |
| `Views/CollectionViews.swift` | `CollectionsArchiveView` : l'ancienne page Collections, poussée depuis l'en-tête du Parcours. `CollectionsView` est conservée telle quelle. |
| `Models/UserProgress.swift` | `pathLevelResults` (par collection : meilleur score, essais, date de réussite, XP versée). Décodage tolérant : les anciennes progressions se chargent sans ce champ. |
| `Services/ProgressManager.swift` | `recordPathQuizAttempt`, `isPathLevelPassed`, `pathLevelResult(for:)`, raison XP `pathLevelPassed` (+100, une fois). |
| `Services/AnalyticsService.swift` | `path_quiz_started`, `path_quiz_completed`, `path_level_unlocked`. |
| `Utilities/AppLocalizable.swift` | Clés `tab.path`, `path.*`, `explain.path.*` dans les 26 langues. |

## Points d'attention

- **Synchronisation Supabase.** `pathLevelResults` voyage dans le JSON `user_progress.progress`
  comme le reste. Android ignore les clés inconnues à la lecture, mais **ré-encode son propre
  modèle** à l'écriture : une progression poussée depuis Android après une session iOS
  écrase les résultats de quiz de niveau. À traiter le jour où Android reçoit le Parcours
  (ou en ajoutant le champ au modèle Android, même sans l'afficher).
- Les états « déjà vus » (`LearningPathSeenStore`) sont par appareil : sur un nouvel appareil,
  la première ouverture affiche le chemin tel quel, sans rejouer l'historique.
- Un cours retiré d'une langue (`ContentCatalog.withheldCourseIds`) disparaît aussi du
  niveau : le quiz ne tire que dans les cours visibles.
- Le pod quiz d'un niveau réussi reste jouable (« Toujours au niveau »), sans nouvelle XP.

## Suite envisagée

- Remplacer complètement la page Collections par le Parcours (retirer le bouton et
  `CollectionsArchiveView`).
- Faire adopter `QuizQuestionPane` par `QuizView` et `TrainingView`, qui portent chacun leur
  copie du même code.
- Android.
