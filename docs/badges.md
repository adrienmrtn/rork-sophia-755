# Badges

Depuis le 10 novembre, les badges sont une collection : 35 badges permanents, un badge par ligue
de duel atteinte (30), un badge par événement. iOS seulement pour l'instant.

## Ce que voit le lecteur

- **Profil** : trois badges (ceux qu'il a choisi d'afficher, complétés par ses derniers gagnés,
  puis par les plus proches d'être obtenus) et « Tout voir ».
- **Page Badges** : les trois emplacements « Sur ton profil », puis chaque famille en grille. Un
  badge gagné est en couleur, cerclé d'or ; les autres sont grisés avec leur avancement (« 4 sur 10 »).
  Toucher un badge ouvre son détail : condition, date d'obtention, et le bouton qui l'affiche sur
  le profil ou l'en retire (trois au plus).
- **Profil d'un ami** : les badges qu'il affiche.
- Les familles Duels et Ligues n'apparaissent que là où l'onglet Duels est ouvert.

## La liste

| Famille | Badge (identifiant) | Condition |
| --- | --- | --- |
| Série | Étincelle (`streak_3`), Flamme (`streak_7`), Brasier (`streak_30`), Feu sacré (`streak_100`), Phénix (`streak_365`) | 3, 7, 30, 100, 365 jours de suite |
| Lecture | Premier pas (`courses_1`), Lecteur (`courses_10`), Rat de bibliothèque (`courses_50`), Bibliothèque vivante (`courses_100`) | 1, 10, 50, 100 cours terminés |
| Lecture | Lève-tôt (`early`), Oiseau de nuit (`late`), Boulimique (`binge`) | un cours terminé avant 8 h ; après 23 h ; 5 cours le même jour |
| Matières | Historien, Scientifique, Lettré, Esthète, Conteur, Citoyen du monde (`subject_<matière>`) | 10 cours terminés dans la matière |
| Matières | Touche-à-tout (`all_subjects`) | un cours terminé dans chacune des six matières |
| Quiz | Bon élève (`quiz_10`), Major de promo (`quiz_50`) | 10, 50 quiz terminés |
| Duels | Premier duel (`duel_first`), Duelliste (`duel_wins_10`), Champion (`duel_wins_50`), Légende de l'arène (`duel_wins_200`) | 1, 10, 50, 200 duels classés gagnés |
| Duels | Sans-faute (`duel_perfect`), Presque parfait (`duel_near`) | 20/20 ; au moins 18/20 à un duel classé gagné |
| Duels | Raz-de-marée (`duel_margin`), Sang-froid (`duel_tiebreak`) | gagner avec 10 points d'écart ; gagner à la question décisive |
| Duels | Invaincu (`duel_streak_5`), Intouchable (`duel_streak_10`) | 5, 10 victoires d'affilée |
| Duels | Rival (`duel_rival`) | gagner un duel amical |
| Ligues | un par ligue (`league_<figure>`), le buste de la figure | atteindre la ligue (meilleure ligue atteinte) |
| Social | Disciple (`follows_3`), Coup de cœur (`likes_10`), Bande d'amis (`friends_3`) | suivre 3 profs ; aimer 10 cours ; avoir 3 amis |
| Événements | un par événement (`event_<slug>`) | terminer le nombre de cours demandé par l'événement |

## Comment un badge est gagné

- `ios/Sophia/Models/Badges.swift` : le catalogue (`BadgeCatalog`), ce que chaque badge mesure
  (`BadgeMetric`), les valeurs courantes (`BadgeStats`).
- `ProgressManager.refreshBadges()` enregistre dans la progression les badges dont la cible est
  atteinte (`UserProgress.earnedBadges` : identifiant → date). Il tourne quand le profil ou la
  page des badges s'affiche : la date est celle où l'app l'a constaté. **Un badge gagné reste**,
  même si la série casse. À la première ouverture après la mise à jour, tout ce qui est déjà
  atteint est attribué d'un coup.
- Les exploits de duel (meilleur score, plus grand écart, question décisive, duel amical gagné)
  sont comptés à la fin de chaque partie par `BadgeCounters`, sur l'appareil : **ils ne comptent
  qu'à partir de cette version**. Victoires, série de victoires et meilleure ligue sont reprises du
  serveur. Score, écart et question décisive ne comptent qu'en duel classé.
- Le nombre d'amis est relevé quand le classement des amis est lu.
- Les badges affichés sur le profil sont dans `UserProgress.featuredBadgeIds` ; `friend_profile`
  les renvoie aux amis (`featured_badges`), limités à ceux réellement gagnés.

## Illustrations

- Badges permanents et de ligue : `design/site-art/manifest-badges.json`, dessinés par l'atelier
  d'images du dépôt (workflow « Illustrations du site », Recraft, papier découpé), puis ajoutés au
  catalogue d'images de l'app sous `badge_<identifiant>` et `badge_league_<n>_<figure>` (384 px).
  Pour en redessiner un : changer son prompt, relancer le workflow avec `only`, remplacer l'image.
- Badge d'un événement : dans l'admin du site, page de l'événement, carte **Badge** :
  « Generate 3 badges with AI » dessine trois emblèmes depuis le titre, l'accroche et le nom du
  badge en anglais ; « Use this badge » en retient un (`campaigns.badge_image_url`, donné aux apps
  par le manifeste). Sans image, l'app montre le symbole de l'événement.

## Base

`supabase/migrations/20261110020400_badges.sql` : colonnes `badge_image_url` et `badge_candidates`
sur `campaigns`, le manifeste des événements, `friend_profile` avec `featured_badges`.

## Limites

- Android n'affiche pas encore la collection.
- Pas d'animation au moment où un badge est gagné.
- Les compteurs d'exploits de duel vivent sur l'appareil : sur un nouveau téléphone, un exploit
  déjà récompensé garde son badge (il est dans la progression), mais un compteur en cours repart.
