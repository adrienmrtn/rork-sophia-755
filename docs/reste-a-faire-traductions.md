# Traductions : ce qu'il reste à faire (passation, 31/10/2026)

Branche `claude/dreamy-davinci-kx68tp`, PR draft #275 (vérifications vertes, à ne pas fusionner sans décision du propriétaire). Méthode et outils : `docs/processus-traduction.md` (section 3) et `docs/post-edition-native.md`. Les workflows sont dans `.claude/workflows/` ; un dossier de travail `W` hors du dépôt est à recréer (les lots se régénèrent avec `scripts/postedit_i18n.py packs`).

## 1. Ajout du lituanien (lt), du letton (lv) et du japonais (ja)

Les trois langues sont dans `PENDING_LANGS` (`scripts/i18n_languages.py`) : elles ont toutes leurs surfaces, amorcées en français par `scripts/seed_new_language.py`, et restent hors des apps et de la porte tant qu'elles ne sont pas finies. Les guides `content/TRANSLATION_GUIDE_{LT,LV,JA}.md` existent. Une langue amorcée se traduit avec le workflow de post-édition, qui sait que l'ACTUEL est encore du français.

| Surface | lt | lv | ja |
|---|---|---|---|
| Glossaire | fait (2 entrées refusées, restées en français) | fait (3 refusées) | fait (12 refusées) |
| Cours | 61 lots sur 78 faits ; restent `cours_054`, `cours_060` à `062`, `cours_065` à `077` | à faire | à faire |
| Quiz | à faire (31 lots) | à faire | à faire |
| Interface (ui), catalogue, fiche App Store, textes légaux | à faire | à faire | à faire |

Pour chaque langue, dans l'ordre :

1. `python3 scripts/postedit_i18n.py packs --lang <l> --out W/packs/<l> --surfaces cours,quiz` (puis `ui,catalogue,store,legal`) et `termsheet --lang <l> --out W/term/<l>.md`. Les lots de cours déjà traduits en lituanien n'ont plus de français : un lot entièrement traduit peut être sauté.
2. Workflow `post-edition-native.js`, args `{"work": "W", "argsFile": "W/<fichier>.json"}` où le fichier contient `{"lots": ["lt/cours_054", …]}`. Quatre workflows en parallèle au plus (au-delà, la limite d'usage de 5 heures tombe).
3. `python3 scripts/postedit_i18n.py apply --lang <l> --from W/out/<l>`, puis `python3 scripts/i18n_gate.py --only cles,copies`, commit, push, après chaque workflow.
4. Reprendre les entrées de glossaire restées en français (refusées pour « terme déjà pris dans ce cours » : choisir une autre forme).
5. Relecture adverse (`postedit_review.py sample`, workflow `relecture-native.js`, `collect`, `apply`), puis cohérence (`coherence-cours.js`, 39 groupes de 8 cours ; filtrer les segments déjà corrigés par la relecture avant `apply`).
6. Fiche App Store : créer `appstore/metadata/lt`, `lv`, `ja` (voir `scripts/appstore_metadata.py`).
7. Brancher dans les apps (quand tout est traduit) :
   - iOS `AppLanguage.swift` : cases `lithuanian = "lt"`, `latvian = "lv"`, `japanese = "ja"`, locale (`lt_LT`, `lv_LV`, `ja_JP`), drapeau, autonyme (Lietuvių, Latviešu, 日本語) ; `AppLocalizable.swift` : `table(for:)`, clés `language.lithuanian` etc. dans toutes les tables, pluriels dans `yearsString` (lt : one/few/many ; lv : zero/one/other ; ja : une seule forme) ; `LegalDocumentContent.swift` (terms/privacy), `GlossaryStore.swift` (libellés de catégorie), `TikTokBlockerShared.swift`, dossiers `lt.lproj`, `lv.lproj`, `ja.lproj` avec `InfoPlist.strings`, `knownRegions` du projet Xcode.
   - Android `AppLanguage.kt` (+ tests `PluralStringsTest.kt`, règles de pluriel), `assets/authors.json` et `content/authors.json` (champs lt/lv/ja).
   - `scripts/i18n_languages.py` : passer les trois codes de `PENDING_LANGS` à `NON_FR_LANGS` ; ajouter des chaînes témoins (`content/terminology/sentinelles.json`) et la terminologie de base ; vérifier que `check_course_translation.py` gère le japonais (pas d'espaces, ponctuation pleine chasse).
   - Porte complète : `python3 scripts/i18n_gate.py`.

Coût observé : environ 2,2 M de tokens par tranche de 19 lots de glossaire ; une langue entière (cours, quiz, glossaire, relecture, cohérence) coûte environ 20 à 25 M.

## 2. Phase 3 des langues existantes (post-édition complète)

| Langue | État |
|---|---|
| pt, pt-PT, cs, tr | terminées (post-édition, relecture, cohérence) |
| pl | post-édition faite ; relecture adverse et cohérence à faire |
| el, sv, hu | à faire en entier (lots prêts à régénérer) |
| autres langues | voir `docs/post-edition-native.md`, mesure de la phase 1 |
