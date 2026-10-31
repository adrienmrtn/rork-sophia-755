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

## Les quinze autres langues (option B, 30/10/2026)

Anglais, espagnol, allemand, italien, portugais (Brésil et Portugal), turc, polonais, roumain, néerlandais, grec, suédois, hongrois, bulgare, tchèque. Ces langues étaient en meilleur état que les onze premières (3 à 4 sur 5 à l'audit, contre 1 à 2 pour les cours des onze). Plutôt que de tout relire, on a :

- **post-édité en entier ce que l'utilisateur voit avant de payer** : l'interface (onboarding, paywall, réglages, hors chaînes témoins déjà figées), le catalogue (collections, rubriques), la fiche App Store et les textes légaux ;
- **corrigé dans les cours, quiz et glossaires seulement les segments signalés** par la terminologie, le validateur ou l'audit (`packs --hinted`), une question de quiz signalée venant entière ;
- **relu un échantillon par langue** (environ 80 segments changés et 40 laissés), en trois regards comme pour les onze premières ;
- passé chaque correction par la porte (`scripts/i18n_gate.py`).

| Langue | Interface | Catalogue, fiche, légal | Cours, quiz, glossaire (ciblé) | Corrections de la relecture | Terminologie avant → après |
|---|---|---|---|---|---|
| Bulgare | 283 | 85 | 415 | 11 | 393 → 16 |
| Polonais | 303 | 85 | 385 | 6 | 358 → 56 |
| Roumain | 247 | 82 | 278 | 14 | 334 → 10 |
| Hongrois | 296 | 93 | 268 | 11 | 249 → 7 |
| Tchèque | 236 | 87 | 141 | 7 | 178 → 8 |
| Turc | 272 | 82 | 233 | 10 | 174 → 19 |
| Espagnol | 209 | 79 | 175 | 6 | 161 → 14 |
| Suédois | 260 | 87 | 139 | 7 | 144 → 4 |
| Anglais | 169 | 76 | 133 | 6 | 127 → 9 |
| Néerlandais | 246 | 96 | 140 | 7 | 117 → 2 |
| Italien | 188 | 56 | 85 | 4 | 100 → 5 |
| Allemand | 215 | 66 | 67 | 6 | 71 → 4 |
| Grec | 262 | 95 | 76 | 8 | 68 → 6 |
| Portugais (Brésil) | 146 | 65 | 13 | 2 | 64 → 6 |
| Portugais (Portugal) | 167 | 41 | 17 | 6 | 43 → 9 |
| **Total** | **3 499** | **1 175** | **2 565** | **111** | **2 581 → 175** |

Les chiffres des quatre premières colonnes sont des segments réécrits. La relecture adverse a corrigé 111 segments sur environ 1 800 relus, dont 10 majeurs ou bloquants, par exemple « Le Milt de Paris » (la rate) au lieu de *Le Spleen de Paris* en néerlandais, « Πολιορκία Επικίνδυνη » (un siège militaire) pour le Siège périlleux en grec, « Two loves » ajouté à un sous-titre anglais, un titre d'œuvre calqué en roumain. Les 175 occurrences de terminologie qui restent sont en grande partie des faux positifs vérifiés (un nombre pris pour une année, le tutoiement allemand « du », le nom d'un menu Apple) ; le polonais garde le plus de reste réel.

Ce que l'option B ne couvre pas : le reste des cours, quiz et glossaires de ces quinze langues n'a pas été relu segment par segment, et la passe de cohérence leçon / quiz / glossaire n'a pas été faite. Les défauts qui y restent sont ceux que les contrôles automatiques ne savent pas voir.

## Mesure de ce qui reste dans les cours (phase 1, 30/10/2026)

Pour décider où relire en entier, un relecteur natif par langue a évalué 150 segments tirés au hasard parmi les cours, quiz et glossaires que personne n'avait retouchés (90 de cours, 40 de quiz, 20 de glossaire). Le finnois et le danois, relus en entier à l'étape 3, servent d'étalon : c'est le niveau d'une langue finie.

| Langue | Note | Défauts majeurs ou bloquants | Tout défaut, mineurs compris | Principaux types |
|---|---|---|---|---|
| Tchèque | 3 | 37.3 % | 64.7 % | calque, grammaire, sens, nom_propre |
| Polonais | 3 | 33.3 % | 54.7 % | calque, grammaire, nom_propre, terminologie |
| Grec | 3 | 30.7 % | 48.7 % | calque, grammaire, nom_propre, sens |
| Suédois | 3 | 30.0 % | 60.0 % | calque, terminologie, grammaire, sens |
| Turc | 3 | 28.0 % | 58.0 % | calque, grammaire, sens, nom_propre |
| Hongrois | 3 | 27.3 % | 60.0 % | sens, calque, grammaire, terminologie |
| Roumain | 3.5 | 23.3 % | 52.0 % | grammaire, calque, sens, terminologie |
| Bulgare | 3 | 22.7 % | 51.3 % | calque, grammaire, sens, nom_propre |
| Allemand | 3.5 | 22.7 % | 48.7 % | calque, grammaire, sens, nom_propre |
| Néerlandais | 3 | 21.3 % | 51.3 % | calque, grammaire, sens, terminologie |
| Espagnol | 3.5 | 16.7 % | 42.0 % | calque, terminologie, sens, grammaire |
| Italien | 3.5 | 16.7 % | 46.7 % | calque, sens, grammaire, nom_propre |
| Anglais | 4 | 8.0 % | 35.3 % | calque, sens, grammaire, typographie |
| Portugais (Portugal) | 4 | 6.7 % | 27.3 % | sens, typographie, grammaire, registre |
| Portugais (Brésil) | 4 | 5.3 % | 24.0 % | calque, terminologie, sens |
| Finnois (étalon) | 4 | 4.0 % | 26.7 % | sens, grammaire, typographie |
| Danois (étalon) | 4 | 3.3 % | 18.0 % | grammaire, sens, calque |

Sur 150 segments, la marge d'erreur est d'environ ±7 points autour de 30 %, ±4 points autour de 5 %. Lecture : l'anglais et les deux portugais sont proches de l'étalon ; les douze autres langues gardent dans leurs cours un défaut visible pour un lecteur natif dans un segment sur six à un sur trois, surtout des calques et des fautes de grammaire. Les 499 corrections proposées par les relecteurs pour les défauts majeurs de l'échantillon ont été appliquées (2 refusées par le contrôle : un nombre ajouté).

## Portugais du Brésil et du Portugal en entier (phase 3, 30/10/2026)

Les deux portugais ont eu le même traitement que les onze langues de l'étape 3 : post-édition de tous les segments de cours, de quiz et de glossaire, relecture adverse d'un échantillon, puis passe de cohérence leçon / quiz / glossaire, huit cours à la fois.

| | Portugais (Brésil) | Portugais (Portugal) |
|---|---|---|
| Post-édition : cours | 2 777 | 2 645 |
| Post-édition : quiz | 2 739 | 3 131 |
| Post-édition : glossaire | 768 | 614 |
| Relecture adverse : corrections | 12 (1 majeure) | 8 (1 bloquante) |
| Cohérence : cours | 149 | 242 |
| Cohérence : quiz | 438 | 457 |
| Cohérence : glossaire | 98 | 124 |
| Cohérence : termes renommés | 147 | 279 |

Les chiffres sont des segments réécrits. La passe de cohérence aligne surtout les noms propres et les termes entre la leçon, ses questions et ses définitions, par exemple « Mjölnir » partout au lieu de deux graphies, ou « Hércules » au lieu d’« Héracles » dans un distracteur de quiz, comme dans la leçon. Elle a aussi rouvert deux défauts, rattrapés avant publication. Le premier est en brésilien : le tableau de Manet était devenu « Almoço sobre a Relva », alors que le titre retenu est « Almoço na Relva » (le guide pt donnait l'autre forme, il est aligné). Le second est en portugais du Portugal : une définition corrigée par la relecture gardait le mot français « economiquement ». La relecture adverse a trouvé en pt-PT une définition restée à moitié en français, avec une balise visible (Paul Durand-Ruel).

Les corrections de la passe de cohérence qui touchaient un segment déjà corrigé par la relecture ont été écartées : la relecture garde la main. La porte est ouverte sur les 26 langues après application.

## Tchèque, polonais et turc (phase 3, 30/10/2026)

Les trois langues que la mesure de la phase 1 plaçait parmi les plus abîmées ont eu la post-édition complète de leurs cours, quiz et glossaires. Le tchèque et le turc ont aussi eu la relecture adverse et la passe de cohérence ; pour le polonais, ces deux étapes restent à faire (elles ont été interrompues par la limite d'usage et pas relancées).

| | Tchèque | Polonais | Turc |
|---|---|---|---|
| Post-édition : cours | 4 025 | 4 013 | 3 841 |
| Post-édition : quiz | 6 143 | 5 427 | 5 996 |
| Post-édition : glossaire | 2 390 | 2 224 | 2 333 |
| Relecture adverse : corrections | 11 (1 majeure) | à faire | 24 (6 majeures) |
| Cohérence : cours / quiz / glossaire | 295 / 803 / 233 | à faire | 346 / 926 / 210 |

Deux corrections de fond en chemin. Le guide tchèque imposait des guillemets „…” ; le signe fermant tchèque est “ : environ 1 800 guillemets corrigés dans les cours, quiz, glossaire et catalogue, et le guide aligné. Ce remplacement avait fondu deux variantes de glossaire en une même clé : la porte refuse désormais toute clé en double dans un glossaire.

Le grec, le suédois et le hongrois n'ont pas encore eu la phase 3.
