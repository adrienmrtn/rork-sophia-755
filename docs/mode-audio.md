# Mode audio (iOS et Android)

Chaque cours peut être écouté comme un podcast, en 2 langues : **français et anglais**. Réservé
aux Premium. Mêmes fonctions, mêmes fichiers Supabase et mêmes textes sur iOS et Android.

L'espagnol, l'allemand et le turc ont été retirés le 30/09/2026 : l'app ne les connaît plus, une
file d'attente ou un téléchargement resté dans l'une de ces langues est ignoré ou effacé au
lancement, et `--purge-other-languages` vide les dossiers `es/`, `de/`, `tr/` du bucket.

## Ce que voit l'utilisateur

- **Lancer un audio** : bouton casque dans l'en-tête du cours, bouton casque sur la couverture des
  cartes (accueil et bibliothèque ; un appui lance la lecture, un appui long ouvre le menu), et
  appui long sur les cartes de la bibliothèque (« Écouter », « Lire ensuite », « Ajouter à la
  file », « Télécharger »). Rien n'apparaît sur un cours qui n'a pas d'audio.
- **Lecteur plein écran** : couverture, position, ±15 s, vitesse de 0,5× à 2× (curseur, pas de
  0,05, bouton « 1× »), langue de l'audio, téléchargement, AirPlay, file d'attente.
- **Ajouter à la file depuis le lecteur** : section « Ensuite, écoute… » sous le lecteur (suite
  de la collection, puis même matière, cours non terminés d'abord) avec un **＋** par cours ; appui
  long sur une ligne = « Lire ensuite ». « Parcourir tous les audios » ouvre la liste complète
  (recherche, filtre par matière), avec le même **＋**.
- **Un autre audio joue déjà** : le casque d'un autre cours (lecteur de cours ou carte) propose
  « Écouter maintenant », « Lire ensuite » ou « Ajouter à la file » au lieu de couper l'audio.
- **Mini-lecteur** au-dessus des onglets tant qu'un audio est chargé (lecture/pause, fermer).
- **Natif** : l'audio continue écran verrouillé et dans une autre app ; écran verrouillé, Centre
  de contrôle, Dynamic Island, AirPods, CarPlay et Apple Watch affichent la couverture, le titre et
  le professeur, et pilotent la lecture (lecture/pause, ±15 s, suivant, barre de position,
  vitesse). Un appel met en pause, la fin de l'appel relance.
- **File d'attente** : manuelle, réordonnable, conservée entre deux lancements. À la fin d'un
  audio, le suivant démarre ; file vide = le lecteur se ferme.
- **Langue** : le français si l'app est en français, sinon l'anglais. Le dernier choix fait
  dans le lecteur est mémorisé. Chaque langue a sa propre position de reprise.
- **Progression** : écouter 90 % d'un audio termine le cours (mêmes XP matière et globaux, série,
  bloqueur TikTok, XP de collection), sans les écrans de célébration.
- **Hors ligne** : téléchargement depuis le lecteur ou le menu ; Réglages › Audio ›
  Téléchargements audio pour voir l'espace utilisé et supprimer.
- **Gratuit** : les mêmes boutons avec un cadenas ouvrent le paywall `audio`
  (`SophiaAudioPaywall`, avec la couverture du cours demandé). Après achat, l'audio démarre.

## Ajouter les vrais MP3

Un MP3 par cours et par langue, nommé d'après l'id du cours, avec ou sans le suffixe de langue :
`course_243_pourquoi_a_t_on_invente_les_vampires_fr.mp3` convient tel quel. Les ids sont les
mêmes en français et en anglais (`course_243_…_en.mp3` pour l'anglais).

Le bucket `course-audio` est public en lecture (migration
`supabase/migrations/20260912120000_course_audio_public_bucket.sql`) ; le script le crée s'il
manque. Un fichier y vit à `course-audio/<fr|en>/<course_id>.mp3`, et `manifest.json` (à la
racine du bucket) dit à l'app quels cours ont un audio.

**Ne pas glisser les MP3 dans le tableau de bord Supabase** : ils garderaient leur suffixe `_fr`
(l'app cherche `fr/<course_id>.mp3` et tomberait sur un 404) et `manifest.json` ne serait pas mis
à jour (l'app ne les afficherait pas). Toujours passer par le script.

### Pas à pas (sur le Mac)

1. **Le code sur le Mac** : `git clone https://github.com/adrienmrtn/rork-sophia-755.git`
   (ou GitHub › Code › Download ZIP), puis ouvrir le Terminal dans ce dossier :
   `cd ~/chemin/vers/rork-sophia-755`. Le script vérifie les noms contre `content/courses/`.
2. **Deux dossiers** : un avec les MP3 français (`…_fr.mp3`), un avec les anglais (`…_en.mp3`).
3. **La clé secrète** : supabase.com › projet `afnmcoovdvbtkgohtdij` › Project Settings ›
   API Keys › *Secret keys* (`sb_secret_…`), ou onglet *Legacy API Keys* › `service_role`.
   Elle donne tous les droits sur le projet : ne jamais la mettre dans le code ni la partager.
   ```sh
   export SUPABASE_SERVICE_ROLE_KEY='sb_secret_…'
   ```
4. **Une seule fois, le ménage** : supprime `es/`, `de/`, `tr/` du bucket et réécrit le manifest.
   ```sh
   python3 scripts/upload_course_audio_to_supabase.py --purge-other-languages
   ```
5. **Vérifier sans rien envoyer** (glisser le dossier depuis le Finder dans le Terminal colle son
   chemin) : liste chaque cours reconnu et la taille totale, s'arrête sur un nom inconnu.
   ```sh
   python3 scripts/upload_course_audio_to_supabase.py ~/Desktop/fr --language fr --dry-run
   ```
6. **Envoyer** :
   ```sh
   python3 scripts/upload_course_audio_to_supabase.py ~/Desktop/fr --language fr
   python3 scripts/upload_course_audio_to_supabase.py ~/Desktop/en --language en
   ```
   Si ça coupe (Wi-Fi, veille), relancer la même commande : un fichier déjà dans le bucket avec
   la même taille est sauté. `--force` renvoie tout.
7. **Contrôler** : la dernière ligne (`sample: https://…mp3`) s'ouvre dans un navigateur et joue.
   Dans l'app, l'audio apparaît en 5 à 10 minutes, sans mise à jour (le manifest est relu au
   lancement et au retour au premier plan).

Un audio corrigé se renvoie de la même façon (il écrase l'ancien). Un audio déjà téléchargé sur un
téléphone reste l'ancienne version jusqu'à ce qu'il soit supprimé et retéléchargé.

**Quota** : le plan Free de Supabase s'arrête à 1 Go de fichiers et 5 Go de trafic par mois ; le
plan Pro inclut 100 Go de fichiers et 250 Go de trafic. Le `--dry-run` affiche la taille totale
d'une langue : au-delà de 1 Go pour les deux langues, passer en Pro avant l'envoi.

**Faux audios encore en place (écrasés par les vrais)** : voix de synthèse qui lit l'intro de
`course_67_qu_est_ce_qu_un_trou_noir` (FR, EN), `course_150_la_nuit_etoilee_van_gogh` (FR, EN) et
`course_12_la_strategie_de_napoleon_a_ulm_1805` (FR). Les 5 MP3 FR des cours 1 à 5 (12/09) sont
de vrais audios.

## RevenueCat

Le paywall `audio` vend l'offering courante (les expériences de prix s'appliquent), comme les
autres paywalls de contexte. Une offering `audio` n'est qu'un repli : inutile de la créer tant que
l'offering courante a un package annuel. Impression déclarée sous `native_audio`.

## Code

- `Services/Audio/CourseAudioCatalog.swift` : manifest, langues, URL publiques.
- `Services/Audio/CourseAudioDownloads.swift` : fichiers hors ligne
  (`Application Support/CourseAudio`, exclus de la sauvegarde iCloud).
- `Services/Audio/CourseAudioPlayer.swift` : `AVPlayer`, session `.playback`/`.spokenAudio`,
  Now Playing, commandes à distance, file, vitesse, reprise, complétion, garde Premium.
- `Views/Audio/` : lecteur, mini-lecteur, menus, téléchargements, paywall, et
  `CourseAudioHost` (branchement dans `ContentView`).
- `Info.plist` : `UIBackgroundModes` = `audio`.

Pas de suivi d'usage : Mixpanel a été retiré de l'app le 29/09/2026.

## À tester sur un iPhone

1. Premium : ouvrir « Qu'est-ce qu'un trou noir ? », casque → le lecteur s'ouvre et joue.
2. Verrouiller l'écran : l'audio continue, la couverture et les commandes sont là.
3. Changer la vitesse (curseur et depuis l'écran verrouillé), passer de FR à EN.
4. Appui long sur une carte de la bibliothèque → « Ajouter à la file » ; réordonner la file ;
   laisser finir l'audio → le suivant démarre, le cours passe en « Terminé ».
5. Télécharger, passer en mode avion, relancer l'app, rejouer.
6. Compte gratuit : le casque avec cadenas ouvre le paywall audio.
7. Tuer l'app pendant une écoute, relancer : le mini-lecteur est là, la lecture reprend au bon
   endroit.

## Android

Même parcours que sur iOS, avec les équivalents natifs :

- **Lecture** : Media3 (ExoPlayer) dans un `MediaSessionService` (`audio/CourseAudioService.kt`,
  `foregroundServiceType="mediaPlayback"`) : notification média, écran verrouillé, casques
  Bluetooth, Android Auto et Wear. Focus audio géré (pause pendant un appel, reprise après),
  pause quand on débranche le casque, contenu déclaré comme parole.
- **File** : c'est la playlist d'ExoPlayer, donc « suivant » marche aussi depuis la notification.
- **Où** : casque sur la couverture des cartes (accueil, bibliothèque) — appui = écouter,
  appui long = menu —, casque dans l'en-tête du cours, mini-lecteur au-dessus des onglets,
  lecteur plein écran (vitesse, langue, téléchargement, file réordonnable, « Ensuite,
  écoute… » avec ＋, « Parcourir tous les audios »), Réglages › Audio › Téléchargements.
- **Gratuit** : paywall `PaywallContext.AUDIO` (impression `native_audio`), l'audio démarre
  après l'achat.
- **Code** : `android/app/src/main/java/app/rork/sophia/audio/` (catalogue, téléchargements
  dans `filesDir/course_audio`, lecteur, service) et `ui/audio/` (écrans). Textes dans
  `assets/strings/*.json`, mêmes clés qu'iOS.
- **Pas d'équivalent AirPlay** dans le lecteur : le choix de la sortie audio passe par le
  sélecteur système de la notification.
