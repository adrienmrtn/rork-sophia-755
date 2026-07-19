# Charte du quiz — Sophia

Document de référence pour la refonte du contenu des quiz (1195 questions, 239 cours).
Décrit le schéma technique (déjà implémenté côté app) et les règles d'écriture pour la
réécriture complète du contenu, qui suit cette infrastructure.

**Statut : infrastructure technique livrée (types de question, notation, UI). Les 239
cours (FR, `CourseData.swift`) ont été réécrits selon cette charte — voir §6. Les
catalogues localisés non-FR (`Resources/Locales/courses.<lang>.json`) restent en
`.mcq` d'origine (5 questions), non encore synchronisés avec la refonte FR.**

---

## 1. Pourquoi cette refonte

L'ancien format était figé : exactement 5 questions par cours, exactement 4 options,
générées en une fois depuis un fichier Excel (`scripts/import_quiz_from_excel.py`) et
jamais retouchées alors que le contenu des leçons, lui, a été réécrit plusieurs fois
(voir `CHARTE_REFONTE.md`). Résultat : des questions parfois disproportionnées par
rapport à un cours court, parfois décalées par rapport à un texte de leçon mis à jour,
et un seul type d'interaction possible.

---

## 2. Les 5 types de question

| Type | Usage | Points max |
|---|---|---|
| `mcq` | Question à choix multiple classique (3 à 5 options) | 2 (tout ou rien) |
| `trueFalse` | Affirmation vraie ou fausse (exactement 2 options) | 2 (tout ou rien) |
| `chronological` | Remettre 3 à 5 événements dans l'ordre chronologique | 3 (barème à paliers) |
| `numericSlider` | Deviner une valeur numérique (année, quantité...) avec un curseur | 3 (barème à paliers) |
| `percentageSlider` | Variante de `numericSlider`, plage fixe 0-100 % | 3 (barème à paliers) |

**Règle d'or : on choisit le type qui a du sens pour la question posée, pas l'inverse.**
Il n'y a **aucun quota** à respecter par cours (ex. "toujours 1 vrai/faux, toujours 1
slider..."). Un cours peut n'avoir que des QCM s'ils sont les plus pertinents ; un autre
peut mélanger 2 QCM, un vrai/faux et un slider de date. Le nombre de questions par cours
varie aussi selon sa densité (voir §5).

### Quand utiliser quel type

- **`mcq`** : par défaut, dès qu'il y a plusieurs réponses plausibles à distinguer
  (mécanisme, cause, personnage, définition...).
- **`trueFalse`** : pour une affirmation simple, souvent une idée reçue à confirmer ou
  infirmer (« Vrai ou faux : ... »). Éviter les affirmations ambiguës ou à nuancer.
- **`chronological`** : quand le cours présente une **séquence d'événements** avec un
  ordre clair et non-trivial (bataille → conséquence → conséquence...). Inutile si les
  événements n'ont pas de rapport chronologique fort entre eux.
- **`numericSlider`** : quand une **date précise, une durée, une quantité, une distance,
  une température...** a été donnée dans le cours et vaut la peine d'être retenue. Le
  curseur doit couvrir une plage réaliste (pas 10 fois trop large).
- **`percentageSlider`** : quand le cours cite une **proportion, un taux, un pourcentage**
  (ex. "quelle part de la population...", "quel pourcentage du PIB...").

---

## 3. Schéma technique

Modèle Swift : `QuizQuestion` (`ios/Sophia/Models/Course.swift`). Tous les champs
au-delà de `id`/`type`/`question`/`explanation` sont optionnels ; seuls ceux pertinents
pour le `type` choisi sont à renseigner.

```swift
// .mcq — 3 à 5 options, correctIndex avant mélange à l'affichage.
QuizQuestion(
    id: "course_X_qN",
    type: .mcq, // valeur par défaut, peut être omise
    question: "Quel événement déclenche la crise ?",
    options: ["La bonne réponse", "Un leurre plausible", "Un autre leurre", "Un dernier leurre"],
    correctIndex: 0, // toujours la bonne réponse en position 0 dans les données ; le mélange se fait à l'affichage
    explanation: "Pourquoi c'est la bonne réponse, en une phrase."
)

// .trueFalse — exactement 2 options, dans l'ordre "Vrai" puis "Faux" (non mélangé à l'affichage).
QuizQuestion(
    id: "course_X_qN",
    type: .trueFalse,
    question: "Vrai ou faux : Napoléon mesurait 1,50 m.",
    options: ["Vrai", "Faux"], // ou options: [languageManager equivalent localisé]
    correctIndex: 1,
    explanation: "Napoléon mesurait environ 1,68 m, une taille moyenne pour l'époque."
)

// .chronological — `items` DANS L'ORDRE CORRECT (mélangés à l'affichage).
// IMPORTANT : ne jamais mettre la date entre parenthèses dans le libellé d'un item —
// cela révèle la réponse et vide l'exercice de son sens. Le libellé décrit l'événement,
// sans aucune indication temporelle.
QuizQuestion(
    id: "course_X_qN",
    type: .chronological,
    question: "Remets ces étapes de la Révolution française dans l'ordre.",
    items: ["Prise de la Bastille", "Exécution de Louis XVI", "Coup d'État de Napoléon"],
    explanation: "Trois jalons majeurs de la décennie révolutionnaire, dans l'ordre : 1789, 1793, 1799."
)

// .numericSlider — deviner une valeur, avec tolérance pour le plein de points.
QuizQuestion(
    id: "course_X_qN",
    type: .numericSlider,
    question: "En quelle année a eu lieu la bataille de Waterloo ?",
    correctValue: 1815,
    sliderMin: 1700,
    sliderMax: 1900,
    tolerance: 5, // ±5 ans = 3 points ; ±12 ans = 2 points ; ±25 ans = 1 point ; au-delà = 0
    unit: "", // ou "ans" si la légende du curseur doit le préciser
    explanation: "La bataille de Waterloo s'est déroulée le 18 juin 1815."
)

// .percentageSlider — même mécanisme, plage 0-100 fixée par convention.
QuizQuestion(
    id: "course_X_qN",
    type: .percentageSlider,
    question: "Quelle part de la population mondiale vivait en zone rurale en 1800 ?",
    correctValue: 97,
    sliderMin: 0,
    sliderMax: 100,
    tolerance: 5,
    unit: "%",
    explanation: "Environ 97 % de la population mondiale vivait à la campagne en 1800."
)
```

### Notation (barème à paliers)

Implémentée dans `ios/Sophia/Models/QuizScoring.swift` (`QuizScoring.points`).

- **`mcq` / `trueFalse`** : tout ou rien — **2 points** si la bonne réponse est choisie,
  **0** sinon.
- **`chronological`** : compte le nombre d'éléments correctement placés (position exacte) —
  **3 points** si l'ordre est parfait, **2** si au moins la moitié des éléments sont bien
  placés, **1** si au moins un élément est bien placé, **0** sinon.
- **`numericSlider` / `percentageSlider`** : distance entre la réponse et `correctValue`,
  comparée à `tolerance` — **3 points** si l'écart est ≤ `tolerance`, **2** si ≤ 2,5×,
  **1** si ≤ 5×, **0** au-delà.

Le total de points d'un cours (`course.quiz.maxPoints`) varie donc selon son nombre de
questions et leur mix de types — ce n'est jamais un simple `nombre de questions × 2`.

### Rétrocompatibilité

- Les 1195 questions existantes (toutes `.mcq`) n'ont **pas besoin d'être modifiées** :
  `type` a une valeur par défaut (`.mcq`) dans l'initialiseur Swift, donc les appels
  `QuizQuestion(id:question:options:correctIndex:explanation:)` déjà présents dans
  `CourseData.swift` compilent sans changement.
- Le contenu traduit (`Resources/Locales/courses.<lang>.json`, non-FR) ne contient pas de
  champ `type` non plus : le décodeur JSON (`Codable` custom sur `QuizQuestion`) le
  déduit à `.mcq` quand la clé est absente. Rien à migrer là non plus.

---

## 4. Style d'écriture (reprend les principes de `CHARTE_REFONTE.md`)

- **Une question doit être répondable avec ce que le cours a réellement enseigné.**
  Pas de détail qui n'a jamais été mentionné dans la leçon.
- **Français courant**, pas de piège de vocabulaire.
- **Pas de point final sur les options courtes** (`options` des `.mcq`/`.trueFalse`,
  `items` des `.chronological`) — ce sont des libellés courts, pas des phrases ; un point
  final y fait bizarre. `explanation`, elle, reste une phrase complète normalement
  ponctuée.
- Pour les QCM : les 3 leurres doivent être **plausibles** (pas absurdes), sinon la
  question devient trop facile et perd son intérêt pédagogique.
- Pour le vrai/faux : éviter les questions à trous ("environ", "parfois") qui rendent le
  vrai/faux ambigu.
- Pour le chronologique : 3 à 5 événements maximum (au-delà, l'exercice devient long et
  frustrant sur mobile) ; **jamais de date entre parenthèses dans le libellé** (voir §3).
  L'interaction combine tap et glisser-déposer : des cases numérotées vides, et un
  réservoir de cartes en dessous ; toucher une carte la place dans la première case
  vide, ou on peut la glisser directement dans une case précise ; une fois placées, on
  glisse les cartes entre elles (ou on retouche une case remplie pour la remettre dans
  le réservoir) pour réorganiser.
- Pour les sliders : la plage (`sliderMin`/`sliderMax`) doit rester resserrée autour
  d'une fourchette plausible — un curseur trop large rend la question trop facile
  (deviner "à peu près au milieu" suffit à approcher le plein de points).
- `explanation` : toujours une phrase, jamais vide, qui justifie la bonne réponse.

---

## 5. Nombre de questions par cours

**Entre 6 et 10 questions par cours**, selon sa densité et sa richesse factuelle — pas
un nombre fixe, mais pas un minimum symbolique non plus :

- Un cours plus court ou plus simple reste autour de **6-7** questions.
- Un cours dense (beaucoup de dates, d'acteurs, de mécanismes) va vers **8-10**
  questions.

Le mix de types suit la même logique que le nombre : on choisit le type qui a du sens
pour chaque fait à tester, on ne cherche jamais à caser un type "pour la forme". Un
cours peut légitimement n'avoir aucun `.numericSlider`/`.chronological` si rien ne s'y
prête (ex. un texte littéraire sans repères temporels fiables) — mais il ne doit pas
non plus rester bloqué à 6 questions par facilité : si le cours contient assez de
matière factuelle pour aller plus loin, on y va.

---

## 6. Journal des itérations

### Itération 1 (pilote — un cours par matière)

Réécriture complète du quiz des 6 premiers cours de chaque matière, pour valider le
mélange de types avant de généraliser. Chaque question a été construite à partir du
contenu réel des leçons (V2, FR), pas d'un canevas générique.

- **Histoire** — *La naissance de l'islam* (`course_1`) : 8 questions.
- **Sciences** — *Pourquoi le ciel est-il bleu ?* (`course_41`) : 8 questions. Pas de
  remise en ordre chronologique : le cours n'a pas de séquence d'événements à ordonner,
  conformément à la règle « le type doit avoir du sens ».
- **Littérature** — *L'Odyssée, Homère* (`course_81`) : 8 questions. Pas de remise en
  ordre chronologique : les repères temporels du cours (VIIIe siècle av. J.-C., 1922)
  ne se prêtaient pas à un exercice fiable.
- **Art** — *La Renaissance italienne* (`course_121`) : 9 questions (cours dense).
- **Mythologie** — *La naissance des dieux grecs* (`course_161`) : 8 questions. Pas de
  curseur numérique : aucune date réelle dans un récit mythologique.
- **Comprendre le monde actuel** — *La naissance du conflit israélo-palestinien*
  (`course_201`) : 9 questions (cours dense, beaucoup de repères).

### Itération 2 (corrections après relecture)

- **Dates révélées dans les items chronologiques** : les libellés (ex. « La bataille de
  Badr (624) ») indiquaient la date entre parenthèses, ce qui donnait la réponse et
  videait l'exercice de son sens. Corrigé : les items ne portent plus aucune date ; les
  dates apparaissent uniquement dans `explanation`, une fois la question validée.
- **Interaction chronologique** : passage du tap-to-order à un vrai **glisser-déposer**
  (drag & drop). Faire glisser une carte sur une autre échange leurs positions.
- **Points finaux sur les options courtes** : supprimés (voir §4) — ils ne doivent
  apparaître que dans `explanation`, jamais dans `options`/`items`.
- **Nombre de questions** : les 6 cours étaient tous groupés à 6-7 questions. Relevé à
  8-9 selon la densité (voir §5), en ajoutant des questions sur des faits du cours pas
  encore couverts plutôt qu'en délayant les questions existantes.

### Itération 3 (retour terrain sur l'interaction chronologique)

- Le glisser-déposer pur (cartes déjà toutes affichées, à faire glisser les unes sur les
  autres) a été jugé peu fluide et peu compréhensible en usage réel.
- Remplacé par un modèle **cases vides + réservoir** : N cases numérotées vides en haut,
  les cartes-événements mélangées en dessous. Toucher une carte l'envoie dans la case
  vide la plus à gauche ; on peut aussi la glisser directement dans une case précise
  (vide ou déjà occupée, ce qui renvoie l'occupant au réservoir). Une fois deux cases
  remplies, les glisser l'une sur l'autre échange leur contenu pour réordonner ; toucher
  une case remplie la vide et renvoie sa carte au réservoir (annulation rapide).

### Itération 4 (généralisation aux 233 cours restants)

Réécriture complète du quiz des 233 cours restants (tous sauf les 6 pilotes de
l'itération 1), en appliquant strictement les règles ci-dessus. Chaque question a été
construite à partir du contenu réel des leçons V2 FR (`content/courses/fr/*.json`), en
lisant systématiquement le fichier source de chaque cours plutôt qu'en généralisant un
canevas.

- Les 239 cours (6 pilotes + 233 nouveaux) sont désormais dans la fourchette **8-10
  questions**, avec un mix de types choisi au cas par cas (aucun cours n'a de type
  « forcé » sans pertinence — ex. pas de `.chronological` pour un texte sans séquence
  fiable, pas de `.numericSlider` pour un récit mythologique sans date réelle).
- `percentageSlider` : plage normalisée à 0-100 sur tout le corpus, conformément à la
  convention du §3 (certaines questions avaient été rédigées avec une plage resserrée,
  ex. 0-50 — la tolérance et la valeur cible restent inchangées, seule la plage
  d'affichage du curseur a été élargie pour rester cohérente d'un cours à l'autre).
- Validation automatisée sur l'ensemble du fichier après fusion : bornes de
  `correctIndex`, options `trueFalse` strictement `["Vrai", "Faux"]`, absence de dates
  entre parenthèses dans les `items` chronologiques, absence de point final sur les
  `options`/`items`, unicité des identifiants de question sur les 2122 questions du
  fichier, équilibre des parenthèses/crochets/guillemets.
- Portée : uniquement le catalogue FR (`CourseData.swift`), comme pour le pilote. Les
  catalogues localisés non-FR n'ont pas été touchés (voir note de statut en tête de
  document) et restent à synchroniser dans une passe ultérieure dédiée.
