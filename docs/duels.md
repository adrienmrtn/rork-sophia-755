# Duels

Des parties de 20 questions contre un adversaire, avec des trophées et 30 ligues. Version bêta :
iOS seulement, questions en anglais seulement, donc onglet visible quand l'app est en anglais
(`FeatureFlags.duelsVisible`, lu au lancement : après un changement de langue, l'onglet suit au
prochain lancement). Les adversaires sont simulés par le serveur ; rien dans l'app ne
le dit, et le niveau de difficulté du joueur n'est jamais affiché.

## Règles

- **20 questions**, quatre types : QCM (12 s), vrai/faux (8 s), portrait « qui est-ce ? » (10 s),
  curseur (15 s). Une partie compte 9 QCM, 4 vrai/faux, 4 portraits et 3 curseurs.
- **1 point par bonne réponse.** Au curseur, le plus proche de la bonne valeur marque (les deux
  à distance égale).
- **Égalité après 20 questions** : une 21e question au curseur, en mort subite. Le plus proche
  gagne ; à distance égale, le plus rapide.
- **Quitter en pleine partie** (bouton, ou app fermée) compte comme une défaite.
- **Trophées**, façon Clash Royale : +25 à +35 pour une victoire, −15 à −25 pour une défaite,
  selon l'écart de trophées avec l'adversaire. Aucune perte avant la 5e ligue (400 trophées), et
  on ne redescend jamais sous le seuil de la meilleure ligue atteinte.
- **30 ligues**, une figure par ligue, de l'Antiquité à aujourd'hui (Aesop à 0 trophée … Vermeer
  à 3 100 … Sophia à 7 000). Chaque ligue a son illustration de fond. Pas de saison pour l'instant.
- **Niveau caché** de 1 à 8 : il monte quand le joueur dépasse 62 % de bonnes réponses sur une
  partie, descend en dessous, et choisit la difficulté des questions tirées.
- **Force de l'adversaire** : très accessible les trois premières parties, puis calée juste sous
  la précision du joueur (environ 55 % de victoires pour lui) ; elle monte avec les séries de
  victoires et avec la ligue, baisse après des défaites.

## Serveur (Supabase)

`supabase/migrations/20261109010000_duels.sql` crée les tables et les fonctions ;
`20261109010100_duels_seed.sql` pose le contenu (rejouable : chaque ligne est insérée ou mise à jour).

| Table | Contenu | Accès de l'app |
| --- | --- | --- |
| `duel_leagues` | 30 ligues : nom, seuil, image de fond, vignette, couleur | lecture publique |
| `duel_questions` | questions (langue, niveau 1 à 8, type, réponse) | aucun (fonctions) |
| `duel_bots` | adversaires simulés : @, pays, avatar | aucun (fonctions) |
| `duel_profiles` | par joueur : trophées, record, parties, victoires, défaites, séries, niveau caché | aucun (fonctions) |
| `duel_matches` | chaque partie : adversaire, questions, réponses des deux camps, score, trophées | aucun (fonctions) |

Fonctions appelées par l'app (réservées aux comptes connectés) :

- `duel_home()` : trophées, statistiques, ligues, dix dernières parties.
- `duel_start_match()` : tire l'adversaire, les 20 questions et la question décisive au niveau du
  joueur (en évitant celles vues récemment), et écrit d'avance les réponses de l'adversaire.
- `duel_finish_match(p_match_id, p_answers, p_abandoned)` : recompte le score depuis les réponses
  du joueur, applique trophées, statistiques et niveau. Rappelée pour une partie déjà close, elle
  renvoie son résultat sans rien changer.
- `duel_friends_leaderboard()` : trophées du joueur et de ses amis.

Une partie restée ouverte est close comme un abandon au lancement de la suivante, ou au bout de
12 minutes au prochain passage sur la page.

## Contenu

- Questions : `scripts/duels_questions_source.py` (80 questions, 10 par niveau).
- Ligues, adversaires et SQL : `python3 scripts/build_duels_seed.py` écrit `content/duels/*.json`
  et `supabase/migrations/20261109010100_duels_seed.sql`.
- Pour ajouter des questions : les écrire dans la source, relancer le script, exécuter le SQL généré.
- Portraits : Wikimedia Commons, domaine public, crédits dans `content/duels/portraits.json` et
  dans `duel_questions.image_credit`.

## Images

- Fonds de ligue et 40 avatars de plus (21 à 60) : fal.ai, Recraft v3, même direction affiche que
  les avatars (`design/site-art/manifest-duel-leagues.json`, `manifest-avatars-duels.json`,
  `scripts/site_art.py`).
- `scripts/duels_assets.py` met en forme et range : fonds et vignettes de ligue et portraits sur
  Supabase Storage (`course-images/duels/…`), avatars dans les apps (iOS et Android, le sélecteur
  d'avatar en propose donc 60), illustration du trophée dans l'app iOS.

## App iOS

- `Models/DuelModels.swift`, `Services/DuelService.swift` : les réponses des fonctions et leurs appels.
- `Views/Duels/` : la page (`DuelsHomeView`), la route des ligues (`DuelLeagueRoadView`), puis en
  plein écran la recherche d'adversaire, la partie (`DuelGameModel` en règle le déroulé) et le
  résultat avec la montée de ligue (`DuelFlowView` les enchaîne).
- Six onglets : la barre du système n'en montre que cinq sur iPhone, l'app dessine donc la sienne
  quand l'onglet Duels est visible (`Views/NewGen/SophiaTabScaffold.swift`), dans les deux navigations.
  Accueil, Explorer (ou Biblio), Entraînement et Duels y restent en vie d'un onglet à l'autre ;
  Parcours et Profil sont reconstruits à chaque visite, ce qui rejoue leur `onAppear`.
- Un compte est requis ; sans compte la page propose la connexion.
- Un résultat qui n'a pas pu partir (réseau coupé) est gardé sur l'appareil et renvoyé au
  prochain passage.

## Pas encore fait

Android, les questions dans les autres langues, les saisons, les sons, un gain d'XP par duel.
