# Cours écrits par des profs : état des lieux et plan d'intégration

Analyse du 27/09/2026, avant réception du CSV des cours « V1 » (bruts). Objectif : savoir
exactement à quoi doit ressembler un cours dans l'app aujourd'hui, ce qu'il faut toucher pour
ajouter ou remplacer un cours, et où brancher « Cours écrit par… », les sources et la page prof.

---

## 1. Où vit un cours aujourd'hui

| Quoi | Où | Rôle |
| --- | --- | --- |
| Source de vérité FR | `content/courses/fr/<id>.json` (238 fichiers) | Blocs typés, éditable à la main. Charte : `content/CHARTE_REFONTE.md`. |
| Traductions | `content/courses/<lang>/<id>.json` (25 langues) | Même squelette que le FR, seul le texte change. Produites par briefs (`make_translation_briefs.py` → `apply_translation_briefs.py` → `check_course_translation.py`). |
| Bundle iOS | `ios/Sophia/Resources/CoursesV2/<id>.<lang>.json` (6 188 fichiers) | Écrit par `scripts/build_courses.py`. C'est ce que l'app lit, pas `content/`. |
| Bundle Android | `android/app/src/main/assets/courses_v2/<lang>/<id>.json` | Écrit par `scripts/export_ios_content_for_android.py`. |
| Catalogue legacy FR | `ios/Sophia/Services/CourseData.swift` (5 900 lignes, généré) | Liste des cours côté FR : titre, description, matière, sous-catégorie, **ids et titres des leçons**, **quiz**, et l'ancien texte (repli si pas de V2). |
| Catalogues legacy autres langues | `ios/Sophia/Resources/Locales/courses.<lang>.json` + `glossary.<lang>.json` + `collections.<lang>.json` | Même rôle pour les 25 autres langues. Android en tire `course_index.<lang>.json`. |
| Glossaire FR | `ios/Sophia/Services/GlossaryData.swift` (2 242 entrées, clé `"<titre FR du cours>|<terme>"`) | Fiches ouvertes au tap sur `[[Terme]]`. Résolution exacte puis floue (`GlossaryStore.fuzzyEntry`). |
| Images | `ios/Sophia/CourseImages/*.jpg` (833 fichiers, JPEG, dossier synchronisé Xcode : un fichier déposé est embarqué) | iOS lit le bundle. Android lit le bucket Supabase public `course-images` (même noms de fichiers ; upload via `scripts/upload_course_images_to_supabase.py`, clé service_role requise, 2 Mo max). |
| Image de couverture (carte home) | `ios/Sophia/Utilities/CourseImageMap.swift` + `android/app/src/main/assets/course_image_map.json` | `courseId → slug`. Distinct du hero (souvent le même fichier). |
| Alias d'images | `ios/Sophia/Utilities/CourseImageAliases.swift` + `android/.../course_block_images.json` (généré par `build_block_image_map.py`) | Quand le slug écrit dans le JSON ne correspond pas au nom du fichier (accents `_u0301`, casse). |
| Crédits images | `ios/Sophia/Resources/image_credits.json` (594 entrées : title / author / license / source) | Affiché sous l'image : `Titre — Auteur (Licence)`. Un `credit` dans le bloc prend le dessus. |

Le lecteur (`CourseView.swift`) pagine sur `course.lessons` du catalogue legacy et, pour chaque
leçon, cherche la section V2 de **même id**. Si elle existe : rendu `BlockContentView` ; sinon
repli sur l'ancien rendu texte. **Un cours dont la langue n'a pas de V2 n'affiche jamais le FR**
(choix explicite dans `CourseContentStore`).

Supabase ne connaît pas le catalogue (ni titres, ni auteurs) : tout est embarqué dans l'app.

---

## 2. Le format d'un cours V2, tel qu'il est réellement appliqué

Chiffres sur les 238 cours FR.

**En-tête**
- `id` : `course_<n>_<slug>` (slug tronqué à ~40 caractères). Numéros libres : 70, 190, puis 241+.
- `title` : depuis septembre, **une question** (« Comment Christophe Colomb a-t-il découvert l'Amérique ? »).
- `subtitle` : une année (131 cours) ou une accroche de 2-4 mots (107).
- `subject` : `histoire`, `sciences`, `litterature`, `art`, `mythologie`, `comprendreLeMonde`.
- `subcategory` : chaîne fixe par matière (ex. histoire : « Antiquité & Moyen Âge », « Révolutions & conflits modernes », « Guerre froide & monde contemporain »). Sert au regroupement dans la bibliothèque.
- `description` : teaser de la carte, 2 phrases.
- `hero` : `{ image, ratio: "16:9", hook }`. 238/238 en 16:9. Le hook est une phrase choc.

**Sections** : 5 dans 236 cours (intro + 4 parties, ids `_intro`, `_p1` … `_p4`). Seule
l'intro est `free: true`. Titre de section compréhensible seul. 235 à 866 mots par cours,
médiane 517.

**Blocs** (`type`) et usage réel :

| Bloc | Occurrences | Règle observée |
| --- | --- | --- |
| `paragraph` | 2 424 | 2 à 3 par section. Inline : `**gras**` (chiffres, noms clés), `*italique*` (titres d'œuvres), `[[Terme]]` (glossaire). Jamais de tiret cadratin, jamais de `==`. |
| `image` | 463 | ~2 par cours, **jamais dans l'intro** (le hero suffit), 1 par section max, `ratio` 4:3 (373), 16:9 (60), auto (21), 1:1 (9). `caption` toujours présente, courte. Placée après le 1er ou le 2e paragraphe. |
| `funFact` (« Le savais-tu ? ») | 424 | 0 ou 1 par section, au milieu (222) ou en fin (202) de section, là où il éclaire le passage. Carte repliée, tap pour révéler. Jamais après le takeaway. |
| `takeaway` (« À retenir ») | 238 | **Toujours le dernier bloc de la dernière section** (238/238). Une phrase, en gras. |
| `timeline` | 89 | Frise datée, 3 à 5 événements, dans la dernière section (71) ou l'avant-dernière (17). |
| `quote` | 19 | Littérature uniquement. `text` + `attribution`. |
| `heading` | 0 | Supporté mais inutilisé. |

Gabarits les plus fréquents (P = paragraphe, I = image, F = funFact, L = frise, T = takeaway) :
`PP | PIFP | PIP | PIFP | PPT`, `PP | PIFP | PIP | PP | PLT`.

**Glossaire** : 3 à 8 `[[Terme]]` par cours en général. Un terme doit exister dans
`GlossaryData.swift` sous le titre FR du cours (ou s'en approcher assez pour la résolution floue).

**Rendu** : `BlockContentView.swift` (iOS) et `CourseBlocks.kt` (Android). Les deux ignorent
les clés JSON inconnues : ajouter `author` ou `sources` au JSON ne casse rien tant que le
rendu n'est pas livré.

---

## 3. Ce qu'il faut toucher, selon le cas

**Cours existant, contenu remplacé par la version du prof**
1. Réécrire `content/courses/fr/<id>.json` au format ci-dessus (mêmes ids de sections si le
   nombre de parties ne change pas ; sinon aligner `lessons` dans `CourseData.swift`).
2. Nouveaux termes `[[…]]` → entrées dans `GlossaryData.swift`.
3. Nouvelles images → `.jpg` dans `CourseImages/`, crédit dans `image_credits.json`, upload
   Supabase, `build_block_image_map.py`.
4. `build_courses.py` (bundle iOS), puis les 25 traductions (les anciennes deviennent fausses
   dès que le FR change ; `check_course_translation.py` le signale), puis
   `sync_locale_catalog_titles.py`, puis `export_ios_content_for_android.py`.
5. Quiz : conservé tel quel sauf si le CSV en fournit un nouveau (format `CHARTE_QUIZ.md`).

**Cours nouveau** : tout ce qui précède, plus :
- une entrée dans `CourseData.swift` (FR) et dans les 25 `courses.<lang>.json`, avec quiz ;
- `CourseImageMap.swift` et `course_image_map.json` (couverture) ;
- éventuellement une collection (`CollectionData.swift`) et `CourseAffinity` (un cours absent
  y est simplement servi sans score, ce n'est pas bloquant).

Il n'existe **aucun script qui crée un cours de zéro** : les importeurs existants
(`import_content_from_csv.py`, `import_*_from_excel.py`) mettent à jour des cours déjà
présents, par titre, dans l'ancien format Swift. Il faudra un `scripts/add_course.py` qui, à
partir du JSON V2 et du quiz, génère l'entrée Swift, les entrées catalogue et les maps d'images.

Contraintes de l'environnement de travail : pas de toolchain Swift ni de Gradle ici, donc pas de
compilation. Les vérifications mécaniques disponibles : `build_courses.py --check`,
`check_course_translation.py`, `check_quiz_structure.py`, et un contrôle maison des images
référencées (35 slugs passent aujourd'hui par les alias, 0 manquant réel).

---

## 4. Proposition : auteur, sources, page prof

Rien de tel n'existe aujourd'hui (aucune notion d'auteur dans le code iOS, Android ou Supabase).

**Données**
- `content/authors.json` : un objet par prof, clé `slug`
  (`{ "slug": "marie-dupont", "name": "Marie Dupont", "title": "Docteure en histoire médiévale, Sorbonne Université", "bio": "…", "photo": "author_marie_dupont" (optionnel), "links": [] }`).
  `title` et `bio` sont traduisibles : `content/locales/<lang>/authors.json` sur le même modèle que
  `ui_strings.json`.
- Dans chaque cours : `"author": "marie-dupont"` (structurel, copié tel quel dans les traductions,
  à ajouter à `STRUCTURAL_KEYS` de `course_translation_io.py`) et
  `"sources": [{ "title": "…", "author": "…", "year": "…", "url": "…" }]` (facultatif ; titres
  d'ouvrages conservés dans la langue d'origine, pas traduits).
- `build_courses.py` : valider que `author` existe dans `authors.json`, et émettre
  `Resources/course_authors.json` (`courseId → slug`) pour que « Autres cours de ce prof » se
  calcule sans décoder 238 JSON. Export Android identique.

**Rendu**
- Intro (gratuite, donc visible par tout le monde) : une ligne discrète sous le hook,
  « Par Marie Dupont · Docteure en histoire médiévale », cliquable. C'est le signal de
  crédibilité au moment où le lecteur décide de continuer.
- Fin de cours, après « À retenir » : une carte auteur (photo ou initiales, nom, pedigree, bouton
  « Autres cours de ce prof ») puis, si présentes, les sources en liste repliée sur le modèle du
  « Le savais-tu ? ». Le takeaway reste le dernier bloc *de contenu* ; la carte auteur et les
  sources sont un pied de page rendu par la vue, pas des blocs du JSON.
- Page prof (`AuthorView` iOS, `AuthorScreen` Android) : photo, nom, pedigree, bio, liste des
  cours de ce prof avec l'état de progression, réutilisant les cartes de `SubjectCoursesView`.
- Chaînes UI à ajouter dans `AppLocalizable.swift` (26 langues) puis export Android :
  `course.writtenBy`, `course.sources`, `author.otherCourses`, `author.courseCount`.

**Modèles** : `CourseContentV2` gagne `author: String?` et `sources: [CourseSourceV2]?` ;
nouveau `AuthorStore` (chargement de `authors.<lang>.json`, repli sur le FR pour le nom et sur
l'anglais pour le pedigree) ; `Course` legacy inchangé.

---

## 5. Ce que j'attends du CSV

Pour brancher le tout sans aller-retour, il me faut savoir, colonne par colonne :

1. Comment on relie une ligne à un cours : titre exact actuel, id, ou « nouveau cours » (avec
   matière et sous-catégorie).
2. Le découpage : intro + parties titrées, ou un texte continu à structurer.
3. Les images : fichiers joints, URLs, ou seulement des placeholders (« [IMAGE : Colomb
   débarquant] ») à sourcer côté app. Et leur licence si elles sont fournies.
4. Le prof : nom, pedigree tel qu'il doit s'afficher, bio, photo, et si un même prof signe
   plusieurs cours (pour la page « Autres cours »).
5. Les sources : format libre ou champ structuré (titre, auteur, année, lien).
6. Un quiz est-il fourni, ou on garde l'existant / on en écrit un ?
7. Langue : FR seul (attendu), les autres langues étant produites ensuite par la chaîne de
   traduction.

Une fois le CSV en main, l'ordre de travail : (a) parseur CSV → JSON V2 brouillon par cours,
(b) réécriture éditoriale à la charte (typos, tirets, `[[Terme]]`, placement des images et des
« Le savais-tu ? », takeaway), (c) images et crédits, (d) glossaire, (e) `add_course.py` et
catalogues, (f) modèle auteur/sources + rendu iOS et Android, (g) traductions, (h) exports.
