# Charte du quiz — Sophia

Document de référence pour la refonte du contenu des quiz (1195 questions, 239 cours).
Décrit le schéma technique (déjà implémenté côté app) et les règles d'écriture pour la
réécriture complète du contenu, qui suit cette infrastructure.

**Statut : infrastructure technique livrée (types de question, notation, UI). Un pilote
de 6 cours (le premier de chaque matière) a été réécrit selon cette charte — voir §6.
Les 233 cours restants sont encore en `.mcq` d'origine, en attente de la généralisation
du pilote.**

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
QuizQuestion(
    id: "course_X_qN",
    type: .chronological,
    question: "Remets ces étapes de la Révolution française dans l'ordre.",
    items: ["Prise de la Bastille (1789)", "Exécution de Louis XVI (1793)", "Coup d'État de Napoléon (1799)"],
    explanation: "Trois jalons majeurs de la décennie révolutionnaire, dans l'ordre."
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
- Pour les QCM : les 3 leurres doivent être **plausibles** (pas absurdes), sinon la
  question devient trop facile et perd son intérêt pédagogique.
- Pour le vrai/faux : éviter les questions à trous ("environ", "parfois") qui rendent le
  vrai/faux ambigu.
- Pour le chronologique : 3 à 5 événements maximum (au-delà, l'exercice devient long et
  frustrant sur mobile).
- Pour les sliders : la plage (`sliderMin`/`sliderMax`) doit rester resserrée autour
  d'une fourchette plausible — un curseur trop large rend la question trop facile
  (deviner "à peu près au milieu" suffit à approcher le plein de points).
- `explanation` : toujours une phrase, jamais vide, qui justifie la bonne réponse.

---

## 5. Nombre de questions par cours

**Pas de nombre fixe.** Le nombre de questions (et le mix de types) suit la densité et
la richesse factuelle du cours, pas un quota :

- Un cours court et simple (ex. une notion scientifique en 4 écrans) peut n'avoir que
  3-4 questions.
- Un cours dense (ex. une bataille avec plusieurs dates, acteurs, conséquences) peut en
  avoir 7-8, avec un mélange de types pertinents.

L'objectif : chaque question a du sens et teste un point réellement enseigné — jamais
une question ajoutée seulement pour « faire le nombre ».

---

## 6. Journal des itérations

### Itération 1 (pilote — un cours par matière)

Réécriture complète du quiz des 6 premiers cours de chaque matière, pour valider le
mélange de types avant de généraliser :

- **Histoire** — *La naissance de l'islam* (`course_1`) : 6 questions — 3 QCM, 1
  vrai/faux, 1 curseur de date (mort de Muhammad, 632), 1 remise en ordre
  chronologique (Hégire → Badr → prise de La Mecque → mort de Muhammad).
- **Sciences** — *Pourquoi le ciel est-il bleu ?* (`course_41`) : 6 questions — 3 QCM,
  2 vrai/faux, 1 curseur numérique (« combien de fois plus » la diffusion du bleu).
  Pas de remise en ordre chronologique : le cours n'a pas de séquence d'événements à
  ordonner, conformément à la règle « le type doit avoir du sens ».
- **Littérature** — *L'Odyssée, Homère* (`course_81`) : 6 questions — 4 QCM, 2
  vrai/faux. Ni curseur ni chronologie : les repères temporels du cours (VIIIe siècle
  av. J.-C., 1922) ne se prêtaient pas à un exercice fiable.
- **Art** — *La Renaissance italienne* (`course_121`) : 6 questions — 3 QCM, 1
  vrai/faux, 1 curseur de date (fin de la Chapelle Sixtine, 1512), 1 remise en ordre
  chronologique (perspective linéaire → chute de Constantinople → David → Chapelle
  Sixtine).
- **Mythologie** — *La naissance des dieux grecs* (`course_161`) : 6 questions — 4
  QCM, 1 vrai/faux, 1 remise en ordre chronologique (Chaos → Titans → règne de Cronos
  → victoire de Zeus). Pas de curseur numérique : aucune date réelle dans un récit
  mythologique.
- **Comprendre le monde actuel** — *La naissance du conflit israélo-palestinien*
  (`course_201`) : 7 questions (cours dense, beaucoup de repères) — 3 QCM, 1 curseur
  de date (Déclaration Balfour, 1917), 1 curseur de pourcentage (part de la
  population juive de Palestine en 1918, 8 %), 1 vrai/faux, 1 remise en ordre
  chronologique (congrès de Bâle → Déclaration Balfour → plan de partage de l'ONU →
  indépendance/Nakba).

Chaque question a été construite à partir du contenu réel des leçons (V2, FR), pas
d'un canevas générique. Les 233 cours restants suivront le même principe, matière par
matière.
