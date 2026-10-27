# Étape 2 : corrections mécaniques (27/10/2026)

Étape 2 du plan de remise en ordre des traductions (voir `docs/audit-traductions-naturel.md` et `docs/terminologie-etat-des-lieux.md`). Elle corrige par script les artefacts de traduction automatique dont la correction ne dépend pas du sens de la phrase. Le reste (« on » rendu par « nous », contresens, termes de glossaire perdus) relève de la post-édition de l'étape 3.

## Ce qui a été corrigé

| Langue | Dates | Siècles | Pourcentages | Ponctuation | Artefacts | Total |
|---|---|---|---|---|---|---|
| Bulgare (`bg`) | 476 | 458 | – | 1 | – | **935** |
| Russe (`ru`) | 308 | 98 | – | – | – | **406** |
| Serbe (`sr`) | 324 | – | – | 1 | 6 | **331** |
| Croate (`hr`) | 295 | – | – | 1 | – | **296** |
| Slovaque (`sk`) | 278 | – | – | 1 | 8 | **287** |
| Grec (`el`) | – | – | – | 270 | – | **270** |
| Tchèque (`cs`) | 244 | – | – | 1 | – | **245** |
| Finnois (`fi`) | 194 | 15 | – | 1 | 29 | **239** |
| Slovène (`sl`) | 198 | – | – | 1 | 3 | **202** |
| Estonien (`et`) | 128 | – | – | 1 | 11 | **140** |
| Turc (`tr`) | – | – | 91 | – | – | **91** |
| Arabe (`ar`) | – | – | – | – | 75 | **75** |
| Norvégien (`nb`) | – | 17 | – | 1 | 6 | **24** |
| Suédois (`sv`) | – | 3 | – | 1 | 4 | **8** |
| Danois (`da`) | – | 1 | – | 1 | 4 | **6** |
| Hébreu (`he`) | – | – | – | 1 | 1 | **2** |
| Polonais (`pl`) | – | – | – | 1 | – | **1** |
| Hongrois (`hu`) | – | – | – | 1 | – | **1** |
| **Total** | 2445 | 592 | 91 | 284 | 147 | **3559** |

- **Dates.** Le français « En 1857, … » avait été rendu par une préposition de lieu, sans le mot « année » : « В 1857 » devient « В 1857 году » (russe), « V 1857 » « V roce 1857 » (tchèque) ou « V roku 1857 » (slovaque), « V 1857 » « Leta 1857 » (slovène), « U 1857 » « Godine 1857. » (croate et serbe ; « 1857. godine » en milieu de phrase serbe), « През 1857 » « През 1857 г. » (bulgare), « 1857:ssä » ou « Julkaisussa 1857 » (« dans la publication 1857 ») « Vuonna 1857 » (finnois), « Filmis 1984 » (« dans le film 1984 ») ou « 624-s » « Aastal 1984 » / « aastal 624 » (estonien). Une date n'est touchée que si le français du même segment l'introduit par « En » ou « Vers » : « Dans *1984* » (le roman) reste intact, et « En 100 jours » n'est pas une date.
- **Siècles.** Bulgare « 20. век » → « XX век » et russe « 20-го века » → « XX века », bornes d'intervalle comprises. Le siècle décalé d'un cran (finnois « 700-luvulla », norvégien « 700-tallet », suédois, danois pour le VIIe siècle, qui est le « 600 ») est corrigé quand le français ne nomme qu'un siècle.
- **Pourcentages turcs.** « 25% » → « %25 », et « 30 ile 99% » → « %30 ile %99 ».
- **Ponctuation exigée par les guides et le validateur.** Titres grecs entre guillemets français → « „ ” » (`TRANSLATION_GUIDE_EL.md`), tiret du titre de la guerre de Sécession remplacé par la virgule du français dans 14 langues. Jamais à l'intérieur d'un terme de glossaire.
- **Trois artefacts corrigés segment par segment par un relecteur natif**, avec contrôle automatique (balisage, termes de glossaire et nombres inchangés) : le résidu « **ز** » laissé par la machine à la place d'un passage en gras en arabe (74 segments), « katselukertaa » (« visionnages ») au lieu de « ans » en finnois (18), et la forme d'« Hégire » alignée entre leçons et quiz en estonien, finnois, slovaque, norvégien, serbe, suédois, danois, slovène et hébreu.

Chaque correction est faite une seule fois, sur la source, puis recopiée telle quelle dans le bundle iOS et la copie Android (`scripts/i18n_copies.py`) : les cours iOS et Android restent identiques. La liste complète avant/après est dans `docs/audit-traductions/_corrections_mecaniques.json`.

## Comment c'est vérifié

1. **Garde française.** Chaque règle ne s'applique que si le segment français correspondant le justifie (date introduite par « En », siècle nommé).
2. **Relecture native d'un échantillon** : 40 changements par langue tirés par règle, relus par un relecteur natif par langue. Ses réserves ont été codées avant application : virgule conservée après l'année en croate et en serbe, « u 2022. godini » laissé tel quel, intervalles convertis aux deux bornes, années coordonnées (« 1880 и 1913 г. ») non touchées.
3. **Contrôles après application** : les copies source, iOS et Android sont identiques (0 écart) ; le validateur de cours ne régresse dans aucune langue ; un second passage du script ne change plus rien.

## Résultat

| Indicateur | Avant | Après |
|---|---|---|
| Langues sans constat au validateur de cours (26) | 8 | 13 |
| Occurrences relevées par `check_terminology.py` | 9 985 | 8 174 |
| dont dates calquées | 2 416 | 1 277 |
| dont siècles | 621 | 91 |
| dont forme d'« Hégire » | 73 | 18 |
| Constats du validateur en grec | 46 | 2 |

Les 1 277 dates restantes sont celles que le français n'introduit pas par « En » (« Le 14 juillet 1789 », « dès 1945 », « de 1914 à 1918 ») ou que les règles ne couvrent pas sans risque ; elles passent à l'étape 3 avec le reste.

## Relancer

```bash
python3 scripts/fix_mechanical_i18n.py --dry-run -v      # ce qui changerait, sans rien écrire
python3 scripts/fix_mechanical_i18n.py                   # appliquer (idempotent)
python3 scripts/check_course_translation.py --lang all   # validateur, 26 langues
python3 scripts/check_terminology.py                     # mots pièges, termes produit, œuvres
```
