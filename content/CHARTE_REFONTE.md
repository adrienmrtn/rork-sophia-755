# Charte de refonte des cours — Sophia

Document de référence pour la refonte du contenu des cours (FR d'abord, traductions ensuite).
Il définit le ton éditorial, les gabarits, la charte visuelle, le schéma de blocs et les règles de rendu.

---

## 1. Principes éditoriaux

Objectif : des cours **courts, vivants, séduisants**, à l'opposé du texte « bloc » long et « très IA » actuel.

- **Accroche immédiate.** L'intro s'ouvre sur une image hero + une phrase d'accroche forte (le « hook »). C'est la vitrine freemium : elle doit donner envie de débloquer la suite.
- **Concision.** ~400 à 700 mots par cours (contre ~1000-1500 aujourd'hui). Phrases courtes. Zéro remplissage.
- **1 idée = 1 écran.** Chaque section porte une seule idée claire, titrée.
- **Concret et incarné.** Anecdotes, personnages, chiffres marquants, dates clés. On raconte, on n'énumère pas.
- **Rythme visuel.** Toujours au moins une image par cours ; idéalement une image ou un élément visuel (frise, dates clés, citation) tous les 1-2 écrans.
- **Ton.** Direct, curieux, un brin complice. On tutoie l'intérêt du lecteur sans être infantilisant.

### Règles de placement (strictes)

- **Hero** : uniquement en tête de la section d'introduction.
- **Le saviez-vous (funFact)** : au fil du contenu, jamais après la conclusion.
- **À retenir (takeaway)** : toujours en toute fin de la dernière section, jamais ailleurs.
- **Frise / dates clés** : là où elles éclairent le récit (souvent en intro ou en fin de section historique).

---

## 2. Gabarits de cours

Gabarit par défaut : **Introduction + 3 sections** (4 écrans). Longueur variable tolérée (3 à 5 écrans) selon le sujet.

1. **Introduction** (gratuite) : hero + hook + 1-2 paragraphes qui plantent le décor et la tension. Optionnel : frise ou dates clés.
2. **Section 1** : le contexte / le déclencheur. 1 image inline pertinente.
3. **Section 2** : le cœur / le tournant. funFact possible.
4. **Section 3 (conclusion)** : la portée / l'héritage, close par un bloc « À retenir ».

Le quiz existant est **conservé tel quel** (hors périmètre de cette refonte).

---

## 3. Charte visuelle

### Images
- **Fini le crop fixe 200px.** Les images respectent leur ratio réel.
- Ratios recommandés : `16:9` (hero, paysages), `4:3` (scènes, œuvres), `1:1` (portraits, objets), `auto` (respect du ratio natif).
- Chaque image : **légende** courte optionnelle + **crédit** (réutilise `image_credits.json`).
- Coins arrondis, contour néobrutaliste conservé (cohérence avec l'app).
- Source : réutiliser en priorité les 834 images de `ios/Sophia/CourseImages`, sinon sourcer sous licence (Wikimedia Commons / domaine public / Unsplash) avec crédit.

### Hero
- Image large en tête d'intro (ratio `16:9` ou `3:2`), titre + sous-titre (ex. année) en surimpression ou juste dessous, + hook.

### Frise chronologique / dates clés
- **Frise** : suite d'événements datés (date, titre, détail court), rendu vertical scrollable, style néobrutaliste.
- **Dates clés** : encart compact « points de repère » (année → libellé).

### Typographie et texte
- Police arrondie existante (`.rounded`).
- **Justification** : texte de prose justifié (bords gauche et droit alignés) pour un rendu « éditorial » propre, avec césure activée pour éviter les trous.
- Interlignage confortable.

### Surlignage (refonte)
Deux mécanismes distincts, tous deux au rendu **fiable** (fini les sauts de ligne / désalignements du moteur maison) :
- **Surlignage marqueur** (`==texte==`) : fond coloré translucide type surligneur, **non cliquable**, pour les mots/expressions clés.
- **Terme de glossaire** (`[[Terme]]`) : soulignement coloré épais (style « lien savant »), **cliquable**, ouvre la fiche glossaire existante. Fini les pastilles capsule.
- **Gras** (`**texte**`) : emphase simple.

---

## 4. Schéma de blocs (source de vérité)

Un fichier JSON par cours : `content/courses/fr/<course_id>.json`.

```jsonc
{
  "id": "course_1_la_naissance_de_l_islam_622",   // ID stable (inchangé, FR-dérivé)
  "title": "La naissance de l'islam",
  "subtitle": "622",                               // optionnel (année, accroche courte)
  "subject": "histoire",                           // storageKey du Subject
  "subcategory": "Antiquité & Moyen Âge",
  "description": "...",                             // teaser carte (peut contenir **gras**)
  "hero": {                                         // optionnel, affiché en tête d'intro
    "image": "mecca_7th_century",                  // slug dans CourseImages
    "ratio": "16:9",
    "credit": "…",                                 // optionnel
    "hook": "En 622, un homme réfugié va changer le cours du monde."
  },
  "keyDates": [                                      // optionnel
    { "date": "570", "label": "Naissance de Muhammad à La Mecque" },
    { "date": "622", "label": "L'Hégire : départ vers Médine" }
  ],
  "sections": [
    {
      "id": "course_1_la_naissance_de_l_islam_622_intro",  // = id de la LessonPage legacy
      "title": "Introduction",
      "free": true,
      "blocks": [ /* blocs ordonnés */ ]
    }
    // … autres sections
  ],
  "glossary": [                                      // optionnel (sinon glossaire global)
    { "term": "Hégire", "classification": "concept", "explanation": "…" }
  ],
  "quiz": [ /* inchangé, format QuizQuestion existant */ ]
}
```

### Types de blocs

| type        | champs                                                        | rendu |
|-------------|---------------------------------------------------------------|-------|
| `heading`   | `text`                                                        | titre de sous-partie |
| `paragraph` | `text` (avec inline `**gras**`, `==surlignage==`, `[[Terme]]`)| prose justifiée |
| `image`     | `asset`, `ratio?`, `caption?`, `credit?`, `fullBleed?`        | image à vrai ratio + légende |
| `timeline`  | `events: [{ date, title, detail? }]`                          | frise chronologique |
| `funFact`   | `text`                                                        | encart « Le saviez-vous ? » |
| `takeaway`  | `text`                                                        | encart « À retenir » (fin de cours) |
| `quote`     | `text`, `attribution?`                                        | citation stylée |

### Balisage inline (dans `paragraph`, `funFact`, `takeaway`)
- `**gras**`
- `==surlignage==` (marqueur, non cliquable)
- `[[Terme]]` (glossaire cliquable ; le terme doit exister dans `glossary` du cours ou le glossaire global)

---

## 5. Architecture technique

- **Source FR** : `content/courses/fr/<id>.json` (format ci-dessus), humain/IA-éditable, versionné.
- **Build** : `scripts/build_courses.py` lit ces JSON et émet :
  - la ressource structurée bundlée `ios/Sophia/Resources/CoursesV2/<id>.fr.json` (blocs),
  - la mise à jour de l'entrée legacy `CourseData.swift` (paging / quiz / freemium / progression conservés),
  - (ultérieurement) les JSON de langue à partir du FR.
- **Rendu** : `BlockContentView` (SwiftUI) consomme les blocs. Prose rendue via `AttributedString` dans un `UITextView` encapsulé (`UIViewRepresentable`) pour un wrapping / une justification / des liens glossaire natifs et fiables — le `FlowInlineLayout` maison est abandonné pour les cours v2.
- **Coexistence** : un cours s'affiche en v2 si sa ressource `CoursesV2/<id>` existe ; sinon fallback sur `RichContentView` legacy. Migration cours par cours.

---

## 6. Non-goals

- Pas de modification d'Android.
- Pas de modification des quiz.
- Abandon d'Excel comme format d'édition.
- Les traductions ne sont générées qu'après validation du contenu FR d'un cours.
