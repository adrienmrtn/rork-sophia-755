# Lecture pas à pas : ce que fait Sapio, ce qu'on propose pour Sophia

Compte rendu du 10/11/2026. Point de départ : « les 5 pages sont trop boring ». Référence
donnée : la lecture d'une leçon dans Sapio (Thetys Lab, « le Duolingo de la culture générale »).

Prototype cliquable, avec le contenu réel du cours « Pourquoi les États-Unis n'ont-ils pas gagné
au Vietnam ? » : https://claude.ai/artifact/KeejMReVqGNRYAPgquRXYR

**Décision du 10/11/2026, après relecture.** Le mécanisme de révélation au tap est retenu. Les
questions intercalées (§3) sont abandonnées : pour être justes, elles exigent que le paragraphe
qu'on vient de lire contienne la réponse, ce qui ne tient pas à l'échelle de 311 cours écrits sans
cette contrainte ; les quiz restent à la fin du cours. Le lecteur pas à pas est **livré sur iOS**
(`CourseReadingMode`, `CourseStepReaderView`, `ReadingModePickerControl`), par défaut, avec
l'ancien lecteur par pages conservé : le choix se fait dans l'en-tête du lecteur (menu) ou dans
Réglages, et vaut pour tous les cours. Android reste par pages pour l'instant. Pas d'A/B : le
mode est un choix du lecteur, lu dans `section_view.mode`. Le code n'a pas été compilé dans la
session qui l'a écrit (pas de Xcode) : à vérifier au premier build.

---

## 1. Ce qu'on a aujourd'hui

- Un cours = 5 sections (intro gratuite + 4 parties), rendues comme 5 pages d'un `TabView`
  horizontal sur iOS (`CourseView.lessonsBody`) et d'un `HorizontalPager` sur Android
  (`CourseScreen`).
- Chaque page est un défilement vertical qui affiche d'un coup tous les blocs de la section
  (`BlockContentView`, `ReaderBlockView`). « Continuer » glisse vers la page suivante et la remet
  en haut.
- Retour haptique : un `.light` à chaque changement de page, un `.medium` sur le bouton. Le seul
  élément qui se révèle est « Le savais-tu ? » (replié, ressort au tap, iOS seulement).
- Chiffres sur les 311 cours FR : 5 sections par cours, 3,1 blocs par section (15,5 par cours),
  paragraphes de 47 mots en médiane. Un cours, c'est donc 5 écrans de 3 blocs : quatre taps,
  aucun événement entre l'ouverture et l'écran de fin, rien qui récompense la lecture elle-même.

## 2. Ce que j'ai pu établir sur Sapio

Sources : la fiche App Store FR (captures, notes de version, avis), la fiche Google Play (avis),
la page agrégée mwm.ai, et le code de nos deux lecteurs pour la comparaison. Ce que je n'ai pas
pu faire : ouvrir l'app (pas de téléphone dans cette session) ni regarder une vidéo. La seule
vidéo trouvée, « Je teste le Duolingo de la culture G (Sapio) » de Mr Surgelés, a un an, donc
montre la version 1, et YouTube en refuse le téléchargement depuis la session. Les mécaniques
fines (geste exact, vitesse du défilement, ce qui vibre) viennent de ta description et du modèle
Duolingo Stories dont Sapio s'inspire ouvertement ; les avis parlent de « l'imitation de
l'interface de Duolingo ». À confirmer en dix minutes sur un iPhone, voir §5.

### L'écran de leçon (capture App Store, version 2.x)

- En-tête : flèche retour, compteur de vies (cœur + chiffre), barre de progression fine et
  continue.
- Titre de la leçon en capitales grasses : « LE T-REX, TERREUR FINALE DES DINOSAURES ».
- Une illustration pleine largeur, coins arrondis (dessinée en interne, c'est leur argument).
- Un paragraphe court (une cinquantaine de mots), cinq ou six mots-clés en gras.
- Juste en dessous, l'étiquette « QUESTION », la mascotte (un koala) et une bulle : « Quelle était
  la vitesse maximale du T. rex ? », puis les réponses sous forme de cartes. La question porte sur
  le paragraphe qu'on vient de lire (la vitesse, 30 km/h, est en gras trois lignes plus haut).

L'unité de lecture n'est donc pas la page : c'est le triplet image + paragraphe + question, qui
s'enchaîne dans un fil vertical. Nos paragraphes font la même longueur que les leurs, le
découpage bloc par bloc est donc faisable sans réécrire une ligne de contenu.

### Le déroulé (ta description, cohérente avec la capture et le modèle Duolingo Stories)

- Un seul fil vertical par leçon ; le contenu n'est pas visible d'avance.
- Un bouton « Continuer » fixe en bas. Chaque tap ajoute l'élément suivant (paragraphe, image,
  question) en bas du fil, avec une animation d'entrée, et le fil défile tout seul pour amener le
  nouvel élément dans la zone de lecture.
- Une vibration courte accompagne chaque apparition ; une autre, différente, la bonne ou la
  mauvaise réponse.
- On peut remonter pour relire ; le fil ne saute jamais.

### Ce que disent les avis (et ce qu'on en retient)

- « les leçons proposées sous la forme de chapitres sont très ludiques, ça en devient addictif »,
  « une manière vraiment amusante d'apprendre, étape par étape » : le format marche.
- Depuis la 2.0 (refonte complète du 23/04/2026) : « ça bug quand je fais défiler » (le
  défilement est bien le geste central) ; « les leçons sont trop simplifiées, on apprend moins de
  choses qu'avant » (on ne découpe pas jusqu'à vider le texte : nos paragraphes restent entiers) ;
  « les questions ne portent même pas sur la leçon en cours » (une question intercalée doit porter
  sur ce qu'on vient de lire, sinon elle punit) ; vies limitées, 4 h d'attente, pubs pour en
  regagner : très mal vécu (on n'en met pas).
- Notes de version : « nouveau header » (2.0.3), « mini révision » (2.1.0), « jokers utilisables
  dans les leçons » (2.4.2). Les leçons sont le cœur de leur produit et ils y itèrent chaque mois.

## 3. La proposition : le lecteur pas à pas

### Principes

1. **Un seul fil vertical par cours.** Les 5 sections ne sont plus 5 pages : ce sont des chapitres
   dans le fil, chacun ouvert par un marqueur (« Partie 2 sur 4 » puis le titre de la section).
2. **L'unité de révélation est le bloc** : un paragraphe, une frise, une citation, un savais-tu,
   un à-retenir. Une image s'affiche avec le paragraphe qui la suit (jamais seule, il n'y aurait
   rien à lire) ; si elle ferme une section, avec le paragraphe qui la précède. Un `heading`
   s'affiche avec le bloc qui le suit.
3. **« Continuer » fixe en bas**, posé sur un fondu du fond. Quand le dernier bloc est révélé, il
   devient « Terminer » et enchaîne sur l'écran de fin existant (XP, quiz, série).
4. **Rien ne change dans les JSON** : contenu, quiz, glossaire, auteurs, sources, images.

### Animation

- Entrée d'un bloc : opacité 0 → 1 et translation de 18 pt vers le haut, ressort de 0,42 s
  (le ressort du savais-tu, `response 0.42, dampingFraction 0.8`). Les images y ajoutent une
  montée d'échelle de 0,97 à 1.
- Frise : les événements apparaissent en cascade, 90 ms d'écart.
- Défilement automatique : le haut du nouveau bloc se pose à 20 % de la hauteur du lecteur
  (16 % pour un marqueur de chapitre). Si le bloc est plus haut que les deux tiers de l'écran,
  son haut s'aligne à 20 pt du bord. Jamais de défilement automatique quand on remonte lire.
- À l'ouverture, le hero et le premier paragraphe sont déjà là, sans animation : on arrive sur
  quelque chose à lire, pas sur un bouton.
- Réglage système « Réduire les animations » : pas de translation, défilement instantané.

### Haptique

| Moment | iOS | Android (Compose) |
| --- | --- | --- |
| Nouveau bloc | `UIImpactFeedbackGenerator(.light)` | `HapticFeedbackType.TextHandleMove` |
| Marqueur de chapitre | `.medium` | `HapticFeedbackType.LongPress` |
| Bonne réponse | `UINotificationFeedbackGenerator(.success)` | `HapticFeedbackType.Confirm` |
| Mauvaise réponse | `.error` | `HapticFeedbackType.Reject` |
| Fin du cours | `.success` | `Confirm` |
| Savais-tu | `.medium` (inchangé) | idem, une fois aligné |

### Progression

La barre segmentée reste (un segment par section) ; le segment courant se remplit bloc par bloc
au lieu de basculer d'un coup. Le compteur « 2 / 5 » reste.

### Questions intercalées (abandonné le 10/11, voir la décision en tête)

- Après les parties 1 et 2 (jamais après l'intro, jamais entre la dernière partie et
  « À retenir »), une question du quiz du cours est posée dans le fil, types `mcq` et `trueFalse`
  seulement (les curseurs et le chronologique restent au quiz de fin). Réponse → verdict +
  explication (déjà écrite dans `quizzes_v2.json`). « Continuer » ne redevient actif qu'après la
  réponse. Pas de vies, pas de score : c'est de la lecture active, pas un examen.
- Prérequis contenu : savoir quelle question va avec quelle section. Aujourd'hui les questions ne
  portent aucune référence de section. Deux options : un champ `"section": "<id de section>"`
  ajouté à l'écriture (règle à ajouter à `CHARTE_QUIZ.md`), ou un rattachement automatique dans
  `build_courses.py` par mots-clés communs entre la question et le texte de la section, avec
  repli « pas de question » quand rien ne matche. Le quiz de fin garde toutes ses questions :
  en revoir deux quelques minutes plus tard est une répétition utile, pas un doublon.

### Freemium

La règle ne change pas : intro lisible par tous, suite réservée (premium ou cours gratuit du
jour). Dans le fil, après l'intro, le marqueur « Partie 1 sur 4 » apparaît, puis le bloc suivant
flouté avec le cadenas existant (`CourseLessonLockOverlay`) ; « Continuer » ouvre le paywall
`debloquer_cours`. Le moment de conversion devient plus net : on est arrêté au milieu d'une
histoire plutôt qu'au bout d'une page.

### Ce qui ne bouge pas

- Termes `[[...]]` du glossaire : même overlay, sans déplacement du texte.
- Double-tap « j'aime » : sur tout le fil.
- Audio : inchangé. Plus tard, option : révéler les blocs au rythme de la narration.
- Carte auteur et sources : derniers blocs du fil, après « À retenir ».

### Réglage « Révéler bloc par bloc »

Dans Réglages, un interrupteur actif par défaut. Désactivé : tout le fil est affiché, lecture
libre, un seul « Terminer » en bas. C'est aussi le repli accessibilité (VoiceOver, TalkBack).
Le prototype montre les deux modes côte à côte (« Pas à pas » / « D'une traite »).

### Mesure

- `section_view` conservé : déclenché quand le marqueur de chapitre suivant est révélé, ou à la
  fermeture du lecteur.
- Nouveau `block_reveal` : `section_index`, `block_index`, `block_type`, `seconds` depuis la
  révélation précédente. C'est la mesure du rythme de lecture qui manque aujourd'hui.
- `quiz_answer` avec `context = reader` pour les questions intercalées.
- A/B 50 % derrière un drapeau `FeatureFlags.readerStepByStep`, comme la navigation à 4 onglets.
  À lire : `course_complete` / `course_open`, temps par section, `quiz_start` après le cours,
  rétention J1 et J7, et le taux de conversion du paywall `debloquer_cours`.

## 4. Implémentation

**iOS, `CourseView.swift`** (fait le 10/11/2026, voir la décision en tête)

- `lessonsBody` : remplacer le `TabView` paginé par un `ScrollView` + `LazyVStack` des blocs
  révélés, un `ScrollViewReader` pour le défilement, une transition
  `.opacity.combined(with: .offset(y: 18))` avec le ressort ci-dessus.
- `BlockContentView` : exposer le rendu d'un bloc (`blockView(_:)`) et l'en-tête pour composer le
  fil bloc par bloc ; `ProseTextView`, les cartes et la frise sont réutilisés tels quels.
- `FreemiumGate.isLessonContentLocked` raisonne déjà par index de section : il s'applique à chaque
  bloc selon sa section.
- 2 à 3 jours, dont une demi-journée pour le drapeau et les événements.

**Android, `CourseScreen.kt`**

- Remplacer `HorizontalPager` par `LazyColumn` + `animateItem()`, et
  `LazyListState.animateScrollToItem` avec le décalage de 20 %.
- `ReaderBlockView` réutilisé bloc par bloc. Au passage, aligner « Le savais-tu ? » sur iOS
  (replié, tap pour révéler), écart déjà noté dans `docs/events.md`.
- 2 jours.

**Contenu** : rien à migrer. Si les questions intercalées sont retenues : champ `section` sur les
questions (ou rattachement automatique) et un contrôle dans `check_course_translation.py`.

## 5. Ce qu'il reste à vérifier

- Installer Sapio sur un iPhone et filmer une leçon : le geste exact (bouton seul, ou tap
  n'importe où sur l'écran), la vitesse et la cible du défilement, ce qui vibre et quand. Dix
  minutes, et le §2 passe de « déduit » à « observé ».
- Tester le prototype sur téléphone. Sur Android, les vibrations marchent dans le navigateur ; sur
  iPhone elles ne marchent pas sur le web (dans l'app, elles marcheront).
- Décider : questions intercalées dès la première version ou dans un second temps ; réglage
  « Révéler bloc par bloc » exposé ou pas.

## Sources

- App Store FR, Sapio - Culture Générale (fiche, notes de version, avis) :
  https://apps.apple.com/fr/app/sapio-culture-g%C3%A9n%C3%A9rale/id6741903694
- Google Play, Sapio - Culture Générale (avis cités au §2) :
  https://play.google.com/store/apps/details?id=com.thetyslab.sapio&hl=fr
- Page agrégée mwm.ai (description, avis) : https://mwm.ai/apps/sapio-culture-g-n-rale/6741903694
- Vidéo de test (version 1, non visionnée) : https://www.youtube.com/watch?v=vwrvtbJK2ng
