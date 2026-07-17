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
- **Accessible sans être simpliste.** Le contenu reste sérieux et de même longueur, mais se comprend facilement : on limite le jargon et les mots savants « hors contexte ». Quand un terme technique est nécessaire, il est soit expliqué en clair juste après, soit transformé en terme de glossaire cliquable `[[Terme]]`. On préfère la phrase simple à la tournure alambiquée.
- **Rythme visuel.** Toujours au moins une image par cours ; idéalement une image ou un élément visuel (frise, citation) tous les 1-2 écrans.
- **Ton.** Direct, curieux, un brin complice. On tutoie l'intérêt du lecteur sans être infantilisant.
- **Ponctuation.** **Pas de tirets cadratins (`—`)** dans le texte. On utilise des virgules, des deux-points, des parenthèses ou on refait la phrase.

### Navigation & lecture
- **Bouton « Continuer »** : passe à l'écran suivant avec l'**animation de swipe** (pagination), et toujours **positionné en haut** du nouvel écran (jamais au milieu ni en bas d'un contenu déjà scrollé).
- **Repositionnement en haut uniquement vers l'avant.** Quand on **revient en arrière** (swipe retour), on **conserve la position de lecture** de la page (on ne la remet PAS en haut), sinon la navigation « beugue ».
- L'**animation de swipe doit fonctionner pour toutes les transitions**, y compris entre l'avant-dernier et le dernier écran (pas de saut sec).

### Règles de placement (strictes)

- **Hero** : uniquement en tête de la section d'introduction.
- **Le saviez-vous (funFact)** : placé de façon **logique**, au plus près du passage qu'il enrichit. **Règle stricte : ce n'est JAMAIS le dernier bloc d'une section.** Il est toujours **suivi d'au moins un contenu** (paragraphe, image ou frise) : on lit un passage, on découvre l'anecdote liée, puis le récit **continue**. On ne le colle jamais en fin d'écran ni après la conclusion. Idéalement 0 ou 1 par section. Les enchaînements de blocs doivent rester **fluides et logiques** (pas de bloc « posé » sans lien avec ce qui l'entoure).
- **À retenir (takeaway)** : toujours en toute fin de la dernière section, jamais ailleurs.
- **Frise chronologique** : là où elle éclaire le récit (souvent en fin de section historique). **Plus de tableau « Repères / dates clés » en introduction** (retiré : rendu jugé peu esthétique). Les dates importantes sont soit dans le texte, soit dans la frise.

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

### Frise chronologique
- **Frise** : suite d'événements datés (date, titre, détail court), rendu vertical, style néobrutaliste.
- Le tableau « Repères / dates clés » en tête d'intro est **abandonné**.

### Le saviez-vous ? (funFact) — refonte DA + interaction
- **Direction artistique harmonisée** avec le reste du cours (carte néobrutaliste blanche, contour noir, coins arrondis), au lieu de l'ancien encart trop « à part ». Pastille badge sobre à l'accent du sujet, sans emoji criard.
- **Interactif** : la carte s'affiche d'abord **repliée** (titre « Le saviez-vous ? » + invite « toucher pour révéler »). Un tap la **déplie** avec une animation ressort douce et satisfaisante (chevron qui pivote, retour haptique). Le contenu apparaît **en fondu sur place** (la carte grandit vers le bas) : **pas de glissement depuis le haut** (l'effet « le texte descend de plus haut » est proscrit).

### Typographie et texte
- Police arrondie existante (`.rounded`).
- **Justification** : texte de prose justifié (bords gauche et droit alignés) pour un rendu « éditorial » propre, avec césure activée pour éviter les trous.
- Interlignage confortable.

### Emphase & glossaire (refonte)
- **Plus de surlignage marqueur.** Le fond coloré type surligneur (`==texte==`) est **supprimé** (jugé peu esthétique). Le balisage `==...==` éventuellement présent est ignoré au rendu.
- **Terme de glossaire** (`[[Terme]]`) : **conservé** — soulignement coloré épais (style « lien savant »), **cliquable**, ouvre la fiche glossaire existante. C'est le seul mécanisme de « surlignage » retenu.
  - **Couleur du texte identique au reste** (couleur d'encre normale), **jamais bleu** : seul le soulignement porte la couleur d'accent. On n'utilise pas l'attribut `.link` d'`UITextView` (qui force le bleu et un léger décalage au tap) ; l'URL du glossaire est portée par un attribut custom lu par la gestuelle de tap.
  - **Aucun décalage / effet de sélection** du mot au moment du tap.
- **Gras** (`**texte**`) : emphase simple, pour les mots-clés et les chiffres marquants.
- **Réactivité du glossaire** : l'ouverture de la fiche au tap sur un terme doit être **instantanée** (gestuelle native custom, sans le délai de sélection d'`UITextView`).

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
  // "keyDates" : DÉPRÉCIÉ — le tableau de repères en intro a été retiré.
  //              Utiliser une "timeline" dans une section à la place.
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
| `paragraph` | `text` (avec inline `**gras**`, `[[Terme]]`)                 | prose justifiée |
| `image`     | `asset`, `ratio?`, `caption?`, `credit?`, `fullBleed?`        | image à vrai ratio + légende |
| `timeline`  | `events: [{ date, title, detail? }]`                          | frise chronologique |
| `funFact`   | `text`                                                        | encart « Le saviez-vous ? » |
| `takeaway`  | `text`                                                        | encart « À retenir » (fin de cours) |
| `quote`     | `text`, `attribution?`                                        | citation stylée |

### Balisage inline (dans `paragraph`, `funFact`, `takeaway`)
- `**gras**`
- `[[Terme]]` (glossaire cliquable ; le terme doit exister dans `glossary` du cours ou le glossaire global)
- `==surlignage==` : **déprécié** — n'a plus d'effet visuel, à ne plus utiliser.
- Aucun tiret cadratin (`—`) dans les textes.

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

---

## 7. Journal des itérations

### Itération 1 (retours sur le pilote)
- Langage rendu **plus accessible** (moins de mots savants hors contexte), à longueur et sérieux constants.
- **Surlignage marqueur `==...==` supprimé** ; seul le glossaire cliquable souligné `[[Terme]]` est conservé.
- **Tableau « Repères / dates clés » retiré** de l'introduction.
- **Le saviez-vous ?** : placement plus logique, DA harmonisée, et **carte interactive** (tap pour révéler, animation ressort + haptique).
- **Latence du tap glossaire corrigée** (gestuelle native custom).
- **Interdiction des tirets cadratins (`—`)** dans les textes.
- Cours mis à jour : « La naissance de l'islam (622) », « Pourquoi le ciel est-il bleu ? », « La Renaissance italienne ».

### Itération 2 (retours sur les 3 cours V2)
- **Terme de glossaire** : couleur du texte = encre normale (**plus de bleu**), seul le soulignement est coloré ; **plus de décalage du mot au tap** (attribut custom au lieu de `.link`).
- **« Le saviez-vous ? »** : le contenu apparaît **en fondu sur place**, sans glissement depuis le haut.
- **Navigation** : « Continuer » amène en **haut** de l'écran suivant, en **swipe** ; correction du **saut sans animation** entre l'avant-dernier et le dernier écran.

### Itération 3 (retours)
- **Tap glossaire** : plus aucun **décalage du paragraphe** au tap (on ne réécrit plus l'`attributedText` de l'`UITextView` quand le contenu n'a pas changé, ce qui évitait un re-calcul de hauteur au moment de l'ouverture de la fiche).
- **Le saviez-vous ?** : repositionné **au milieu** des sections dans « Pourquoi le ciel est-il bleu ? » et « La Renaissance italienne » (jamais dernier bloc). Charte clarifiée sur les enchaînements logiques.
- **Navigation** : le **retour en arrière conserve la position de lecture** (repositionnement en haut réservé à l'avancée).
