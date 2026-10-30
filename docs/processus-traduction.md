# Processus de traduction : ne plus régresser

Étape 5 du plan de remise en ordre des traductions (voir `docs/audit-traductions-naturel.md`, `docs/corrections-mecaniques.md` et `docs/post-edition-native.md`). Les étapes 1 à 3 ont corrigé l'existant. Ce document fixe le chemin que suit désormais tout texte affiché, et la porte automatique qui refuse ce qui ferait régresser une langue.

**Règle : aucune traduction automatique brute n'est publiée.** Tout texte nouveau passe par le français, une traduction automatique (brouillon), une post-édition cadrée par le guide de la langue, la porte, puis la mise en ligne.

## 1. La porte (`scripts/i18n_gate.py`)

Elle tourne dans GitHub Actions (`.github/workflows/i18n-gate.yml`) sur chaque push et chaque pull request qui touche un texte affiché : tables d'interface, cours, quiz, glossaire, catalogue, textes légaux, fiche App Store. Un run rouge veut dire qu'un changement fait régresser une langue. À lancer aussi à la main avant de pousser :

```
python3 scripts/i18n_gate.py                       # tout, 26 langues (3 à 6 minutes)
python3 scripts/i18n_gate.py --only cles,temoins   # les vérifications rapides
python3 scripts/i18n_gate.py --lang fi             # une langue
```

| Vérification | Ce qu'elle refuse | Baseline |
|---|---|---|
| `cles` | une clé d'interface française absente d'une langue (iOS ou Android) ; des placeholders (`%@`, `%d`, `{n}`…) différents du français | non |
| `copies` | un cours absent d'une langue ; une copie iOS ou Android différente de la source `content/courses` ; un glossaire ou un catalogue différent entre iOS et Android ; un lien `[[terme]]` sans entrée de glossaire | oui |
| `validateur` | un nouveau constat de `scripts/check_course_translation.py` (anglais ou français résiduel, liens de glossaire perdus ou déplacés, balisage, ponctuation) | oui |
| `terminologie` | une nouvelle occurrence d'un mot piège, d'une variante de terme produit ou d'un titre d'œuvre traduit littéralement (`content/terminology/`) | oui |
| `quiz` | un quiz dont la structure ou la bonne réponse diffère du français, ou une option restée en anglais | oui |
| `fiche` | un champ de la fiche App Store trop long ou une locale inconnue | non |
| `temoins` | une chaîne témoin qui n'a plus sa traduction attendue | non |

**Le baseline** (`content/terminology/i18n_gate_baseline.json`) liste les constats qui existaient quand la porte a été posée. Ils ne bloquent pas ; seuls les nouveaux bloquent. Quand vous en corrigez, la porte affiche « N corrigés depuis le baseline » : lancez alors `python3 scripts/i18n_gate.py --update-baseline` et commitez le fichier, pour que la porte se resserre. N'ajoutez jamais un constat au baseline pour faire passer un commit : corrigez le texte, ou, si c'est un faux positif, corrigez la règle (`check_course_translation.py`, `content/terminology/*.json`).

**Les chaînes témoins** (`content/terminology/sentinelles.json`) sont les 30 textes d'interface qui ont le plus trahi pendant l'audit (essai gratuit, mensuel, Premium, « Fin de l'essai », « Léger », « Impossible de charger l'offre »…). Leur traduction attendue est figée dans les 26 langues après une relecture native et une contre-relecture. Pour en changer une volontairement, modifiez sa valeur dans `sentinelles.json` dans le même commit que le texte, et dites pourquoi dans le message.

## 2. Ajouter ou modifier un texte

Les trois copies d'un même texte (source `content/`, bundle iOS, copie Android) restent identiques : on corrige une fois, on recopie partout (`scripts/postedit_i18n.py apply` le fait, `scripts/i18n_copies.py` pour une correction mot à mot).

### Une chaîne d'interface

1. Écrire la clé en français dans la table `french` d'`ios/Sophia/Utilities/AppLocalizable.swift` (et dans `android/app/src/main/assets/strings/fr.json` si Android l'affiche).
2. Brouillon dans les 26 langues : `python3 scripts/translate_ui_strings.py translate --lang all` (depuis le français, jamais depuis l'anglais).
3. Post-édition des seules clés nouvelles (voir la section 3) : `packs --keys <clé> …`.
4. `python3 scripts/i18n_gate.py --only cles,terminologie,temoins`, puis la porte complète.

### Un cours

1. Le cours en français dans `content/courses/fr/<id>.json`, son quiz et son glossaire.
2. Brouillon dans les 26 langues (`scripts/translate_courses_v2.py --lang all` pour le corps ; quiz et glossaire par leurs scripts habituels), puis recopie vers iOS et Android.
3. Post-édition du cours, de son quiz et de son glossaire (section 3) : `packs --courses <id>`.
4. Passe de cohérence sur ce cours (section 3).
5. La porte complète.

## 3. La post-édition cadrée

C'est la méthode de l'étape 3 (voir `docs/post-edition-native.md`), outillée dans le dépôt. Elle s'exécute avec Claude Code, qui lance les workflows enregistrés dans `.claude/workflows/`. Choisir un dossier de travail `W` hors du dépôt.

```
# 1. Lots de travail et fiche de terminologie, par langue
python3 scripts/postedit_i18n.py packs --lang it --out W/packs/it --courses course_312_mon_cours
python3 scripts/postedit_i18n.py packs --lang it --out W/packs/it --keys paywall.nouveau.titre "offer.*"
python3 scripts/postedit_i18n.py termsheet --lang it --out W/term/it.md
#    (sans --courses ni --keys : toutes les surfaces de la langue, comme à l'étape 3)

# 2. Post-édition : workflow .claude/workflows/post-edition-native.js
#    args : {"work": "W", "lots": ["it/cours_000", "it/quiz_000", "it/glossaire_000", "it/ui4"]}
#    Chaque lot donne W/out/<lang>/<lot>.json ; le post-éditeur corrige jusqu'à zéro refus de
python3 scripts/postedit_i18n.py check --lang it --file W/out/it/cours_000.json

# 3. Application sur les trois copies (renommages de termes et liens compris)
python3 scripts/postedit_i18n.py apply --lang it --from W/out/it --report W/report_it.json

# 4. Cohérence leçon / quiz / glossaire : workflow .claude/workflows/coherence-cours.js
#    args : {"work": "W", "groups": [{"lang": "it", "g": 0, "courses": ["course_312_mon_cours"]}]}
python3 scripts/postedit_i18n.py apply --lang it --from W/cohe/it

# 5. La porte
python3 scripts/i18n_gate.py
```

Pour un gros lot (une langue entière, une nouvelle langue), ajouter la relecture adverse entre les étapes 3 et 4 :

```
python3 scripts/postedit_review.py sample --work W --lang it
# workflow .claude/workflows/relecture-native.js, args {"work": "W", "langs": ["it"]}
python3 scripts/postedit_review.py collect --work W --lang it --journal <journal.jsonl du workflow>
python3 scripts/postedit_i18n.py apply --lang it --from W/review_out/it
```

Les relecteurs sont des modèles de langue cadrés par le guide, la terminologie et la porte. Avant une mise en avant commerciale dans un pays, une relecture humaine de l'onboarding, du paywall et de la fiche App Store reste la meilleure garantie.

## 4. Écouter les utilisateurs, langue par langue

- **Retours.** Le formulaire de retour de l'app (iOS et Android) a une catégorie « Traduction ». Chaque envoi arrive sur Formspree avec `category: translation` et la langue de l'app (`language`) : on lit les plaintes langue par langue.
- **Conversion.** L'app envoie la langue de l'utilisateur à RevenueCat comme attribut client `app_language`, au lancement et à chaque changement de langue. On peut ainsi filtrer et exporter les clients RevenueCat par langue, et comparer essais et abonnements avant et après une correction.
- **Limite.** L'app n'a pas d'outil d'analyse produit (seulement RevenueCat et Meta Ads) : le taux de passage de l'onboarding par langue n'est pas mesuré aujourd'hui. Il faudrait un événement « onboarding terminé » portant la langue dans un outil d'analyse.
