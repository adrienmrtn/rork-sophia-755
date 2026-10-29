# Étape 3 : post-édition native des onze langues sans guide (29/10/2026)

Étape 3 du plan de remise en ordre des traductions (voir `docs/audit-traductions-naturel.md`, `docs/terminologie-etat-des-lieux.md` et `docs/corrections-mecaniques.md`). Les onze langues dont les utilisateurs se plaignaient le plus, et qui n'avaient pas de guide de traduction, ont été entièrement post-éditées, segment par segment, contre le français : hébreu, estonien, arabe, finnois, russe, slovène, slovaque, croate, serbe, danois, norvégien.

## Ce qui a été fait

Toutes les surfaces ont été relues, dans chaque langue :

- **Interface** iOS et Android (1 066 clés, onboarding et paywall compris).
- **Catalogue** : titres et descriptions des collections, libellés de rubriques.
- **Cours** : les 309 cours, segment par segment.
- **Quiz** : questions, options, explications.
- **Glossaire** : définitions, et le terme lui-même quand il était faux (contresens, calque, titre d'œuvre non établi).
- **Fiche App Store** (sauf estonien et serbe, sans fiche) et **textes légaux** (conditions d'utilisation, confidentialité, versions iOS et Android).

Résultat par langue :

| Langue | Segments réécrits | Termes de glossaire renommés | Corrections de cohérence | Termes harmonisés | Validateur | Terminologie |
|---|---|---|---|---|---|---|
| Hébreu (`he`) | 14 685 | 605 | 1 504 | 100 | 85 → 4 | 603 → 32 |
| Estonien (`et`) | 15 262 | 519 | 1 377 | 228 | 10 → 1 | 355 → 28 |
| Arabe (`ar`) | 14 881 | 524 | 1 489 | 129 | 111 → 2 | 609 → 57 |
| Finnois (`fi`) | 14 439 | 566 | 1 263 | 293 | 24 → 0 | 1 080 → 20 |
| Russe (`ru`) | 14 807 | 436 | 946 | 169 | 68 → 2 | 938 → 66 |
| Slovène (`sl`) | 13 492 | 386 | 1 429 | 188 | 15 → 0 | 335 → 35 |
| Slovaque (`sk`) | 13 876 | 398 | 1 386 | 211 | 52 → 6 | 297 → 27 |
| Croate (`hr`) | 13 932 | 296 | 1 258 | 162 | 6 → 0 | 231 → 16 |
| Serbe (`sr`) | 14 570 | 645 | 1 258 | 166 | 30 → 1 | 416 → 44 |
| Danois (`da`) | 14 696 | 526 | 1 316 | 313 | 32 → 2 | 257 → 18 |
| Norvégien (`nb`) | 15 211 | 530 | 1 311 | 228 | 14 → 4 | 406 → 30 |
| **Total** | **159 851** | **5 431** | **14 537** | **2 187** | **447 → 22** | **5 527 → 373** |

- **Segments réécrits** : segments que le post-éditeur a changés. Les autres ont été lus et jugés publiables tels quels.
- **Termes de glossaire renommés** : le terme affiché et ses liens `[[…]]` dans la leçon changent ensemble, dans les trois copies.
- **Validateur** : constats de `scripts/check_course_translation.py --lang <code>` (anglais ou français résiduel, liens de glossaire, balisage, ponctuation). Ceux qui restent sont des faux positifs (titre ou citation française voulus, comme « les abaissés » ou « Meursault, contre-enquête » ; initiales en gras comme « Joseph K. ») ou un lien de glossaire en plus que le français.
- **Terminologie** : occurrences des mots pièges et des écarts à la terminologie produit (`content/terminology/`). Celles qui restent sont pour l'essentiel des emplois justes en contexte (un mot piège pris dans son vrai sens, un titre d'œuvre cité tel quel) ; elles n'ont pas toutes été revues une à une.

Cinq liens de glossaire que la traduction automatique avait perdus (arabe, hébreu, danois) ont aussi été rétablis à la main : sans lien, l'entrée est invisible dans l'app.

Chaque correction est faite une fois, sur la source (`content/`), puis recopiée à l'identique dans le bundle iOS et la copie Android. Les cours iOS et Android restent identiques ; un contrôle d'intégrité le vérifie à chaque application (copies divergentes, glossaires, liens morts, catalogue iOS ≠ Android : zéro partout).

## Comment c'est fait

1. **Un guide par langue**, sur le modèle bulgare : `content/TRANSLATION_GUIDE_<LANGUE>.md`. Registre (tutoiement de l'app, registre du texte légal), rendu du « on » impersonnel français, dates et siècles, typographie, translittération des noms propres, pièges de la traduction automatique propres à la langue.
2. **Des lots de travail** (`scripts/postedit_i18n.py packs`) : pour chaque segment, le français, le texte actuel, et les constats de l'audit et de la terminologie en indices. Lots de 4 cours, 10 quiz ou 150 entrées de glossaire.
3. **Un post-éditeur natif par lot** (modèle de langue chargé du guide et de la terminologie), qui ne réécrit que ce qu'un éditeur natif ne publierait pas : contresens, calque, faute de grammaire, mauvais registre, terminologie contraire à la fiche.
4. **Une porte automatique** (`postedit_i18n.py check` puis `apply`) qui refuse toute réécriture qui perd un placeholder, un saut de ligne, un passage en gras, un terme de glossaire, qui ajoute un nombre, ou dont la longueur sort de l'ordre de grandeur. Le post-éditeur corrige jusqu'à zéro refus.
5. **Une relecture adverse** d'un échantillon par langue, en trois regards successifs : fidélité au français, puis langue, puis segments laissés tels quels (les oublis). Ses corrections sont appliquées.
6. **Une passe de cohérence par cours** : un relecteur par groupe de huit cours vérifie que chaque nom propre, titre et terme s'écrit de la même façon dans la leçon, le quiz et le glossaire, et que l'option juste du quiz reprend le nom de la leçon.

## Ce que dit la relecture adverse

| Langue | Échantillon post-édité | Corrigés (fidélité) | Corrigés (langue) | Dont majeurs | Échantillon laissé tel quel | Oublis trouvés |
|---|---|---|---|---|---|---|
| Hébreu | 108 | 2 | 7 | 3 | 80 | 6 (8 %) |
| Estonien | 119 | 1 | 8 | 5 | 80 | 6 (8 %) |
| Arabe | 107 | 2 | 8 | 0 | 68 | 4 (6 %) |
| Finnois | 107 | 5 | 9 | 4 | 68 | 4 (6 %) |
| Russe | 107 | 2 | 7 | 1 | 68 | 4 (6 %) |
| Slovène | 108 | 4 | 12 | 4 | 80 | 4 (5 %) |
| Slovaque | 108 | 10 | 9 | 2 | 80 | 3 (4 %) |
| Croate | 108 | 4 | 11 | 0 | 80 | 4 (5 %) |
| Serbe | 119 | 2 | 4 | 0 | 80 | 2 (2 %) |
| Danois | 108 | 5 | 10 | 2 | 80 | 3 (4 %) |
| Norvégien | 108 | 5 | 11 | 1 | 80 | 3 (4 %) |
| **Total** | **1 207** | **42** | **96** | **22** | **844** | **43** |

Sur les segments réécrits, la relecture corrige 11 % de l'échantillon, presque tous pour des aspérités mineures (un ordre de mots, une préposition, une virgule). Sur les segments laissés tels quels, elle trouve un oubli dans 5 % des cas. Les constats majeurs sont rares et ont été corrigés (le contrôle automatique n'en a refusé qu'une poignée, pour collision avec un terme existant). Exemples : en hébreu, « הבהלה » (« la panique ») pour la ruée vers l'or ; en russe, « nous ne collectons sciemment pas » devenu un engagement absolu dans la politique de confidentialité ; en estonien, « kuradi ball » (« ce foutu bal ») au lieu du titre établi « Saatana ball » ; en slovène, des fautes d'aspect et d'accord ; en danois, « Unge tyrkere » (« de jeunes Turcs ») au lieu de « Ungtyrkerne » ; ailleurs, un terme de glossaire au mauvais cas ou réduit à une date, ou une option de quiz qui n'écrivait pas le nom comme la leçon.

## Limites

- **La relecture est un échantillon**, d'environ 190 segments par langue sur près de 15 000. Le taux d'aspérités mineures mesuré (quelques pour cent) devrait valoir pour le reste du corpus, qui n'a pas été relu une seconde fois.
- **Les relecteurs sont des modèles de langue**, cadrés par un guide, une terminologie et un contrôle automatique, pas des locuteurs humains. Une relecture humaine de l'onboarding, du paywall et de la fiche App Store reste la meilleure garantie avant une mise en avant commerciale dans un pays.
- **Entrées de glossaire orphelines** : quelques clés anciennes (dates, fragments) ne sont liées depuis aucune leçon. Elles sont invisibles dans l'app et n'ont pas été nettoyées.

## Outils ajoutés ou modifiés

- `scripts/postedit_i18n.py` : construction des lots, contrôle, application sur les trois copies (renommage de termes, rubriques, textes légaux Swift et Android), extraction d'un cours (`dump`).
- `scripts/check_course_translation.py` : abréviations finnoises, slovènes et estoniennes (« eKr. », « pr. n. št. »), ordinaux et numéros de règne, « into » finnois et estonien, qui donnaient de faux constats.
- `content/terminology/mots_pieges.json` : règles de dates russes, serbes et croates affinées (années en gras, quantités, « 1857. godine »).
