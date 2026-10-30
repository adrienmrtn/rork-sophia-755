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
| `cles` | une clé d'interface française absente d'une langue (iOS ou Android) ; des placeholders différents du français, ou des arguments `%@` / `%d` non numérotés dans un autre ordre (l'app planterait) ; une clé en double dans une table Swift ; un `content/locales/<lang>/ui_strings.json` qui ne correspond plus à la table publiée | non |
| `copies` | un cours absent d'une langue ; une copie iOS ou Android différente de la source `content/courses` ; un glossaire, un catalogue, des collections ou l'index Android différents entre iOS et Android, ou absents d'un côté ; un lien `[[terme]]` sans entrée de glossaire (même règle que les apps : casse et ponctuation ignorées) | oui |
| `validateur` | un nouveau constat de `scripts/check_course_translation.py` (anglais ou français résiduel, liens de glossaire perdus ou déplacés, balisage, ponctuation) | oui |
| `terminologie` | une nouvelle occurrence d'un mot piège, d'une variante de terme produit ou d'un titre d'œuvre traduit littéralement (`content/terminology/`) | oui |
| `quiz` | un quiz dont la structure ou la bonne réponse diffère du français, ou une option restée en anglais | oui |
| `fiche` | un champ de la fiche App Store trop long ou une locale inconnue | non |
| `temoins` | une chaîne témoin qui n'a plus sa traduction attendue | non |

**Le baseline** (`content/terminology/i18n_gate_baseline.json`) liste les constats qui existaient quand la porte a été posée. Ils ne bloquent pas ; seuls les nouveaux bloquent. Quand vous en corrigez, la porte affiche « N corrigés depuis le baseline » : lancez alors `python3 scripts/i18n_gate.py --update-baseline` et commitez le fichier, pour que la porte se resserre. Cette commande refuse d'écrire s'il reste des constats NOUVEAU : corrigez le texte, ou, si c'est un faux positif, corrigez la règle (`check_course_translation.py`, `content/terminology/*.json`). Un seul cas justifie `--update-baseline --accept-new` : un cours restructuré, dont les constats connus changent d'emplacement (`s2.b1` devient `s3.b0`) ; dites-le dans le message de commit.

Deux limites à connaître : un constat est identifié par son emplacement et sa règle, donc une deuxième faute de même règle dans un segment qui en a déjà une connue ne ressort pas ; et la porte ne lit pas les textes légaux affichés par iOS (`LegalDocumentContent.swift`), seulement leur copie `content/locales/<lang>/legal.json`.

**Les chaînes témoins** (`content/terminology/sentinelles.json`) sont les 30 textes d'interface qui ont le plus trahi pendant l'audit (essai gratuit, mensuel, Premium, « Fin de l'essai », « Léger », « Impossible de charger l'offre »…). Leur traduction attendue est figée dans les 26 langues après une relecture native et une contre-relecture. Pour en changer une volontairement, modifiez sa valeur dans `sentinelles.json` dans le même commit que le texte, et dites pourquoi dans le message.

## 2. Ajouter ou modifier un texte

Les trois copies d'un même texte (source `content/`, bundle iOS, copie Android) restent identiques : on corrige une fois, on recopie partout (`scripts/postedit_i18n.py apply` le fait, `scripts/i18n_copies.py` pour une correction mot à mot).

### Une chaîne d'interface

1. Écrire la clé en français dans la table `french` d'`ios/Sophia/Utilities/AppLocalizable.swift` (et dans `android/app/src/main/assets/strings/fr.json` si Android l'affiche).
2. Brouillon machine (facultatif) : `python3 scripts/translate_ui_strings.py translate --lang all`. Il part du français et ne traduit que les clés absentes de la table publiée ; il écrit dans `content/locales/<lang>/ui_strings.json`. Il ne couvre pas l'anglais, l'espagnol, l'allemand, le portugais et l'italien.
3. `python3 scripts/postedit_i18n.py ui-insert --keys <clé> …` : ajoute la clé à chaque langue, sur iOS et Android, avec le brouillon s'il existe, sinon le texte français. Rien d'autre n'est touché. (L'ancienne commande `translate_ui_strings.py inject` est retirée : elle réécrivait tout le fichier Swift.)
4. Post-édition de ces clés (section 3) : `packs --keys <clé> …`. Tant qu'elle n'est pas faite, la clé affiche du français ou un brouillon machine.
5. `python3 scripts/i18n_gate.py --only cles,terminologie,temoins`, puis la porte complète.

### Un cours

1. Le cours en français dans `content/courses/fr/<id>.json`, son quiz et son glossaire.
2. Brouillon dans les 26 langues (`scripts/translate_courses_v2.py --lang all` pour le corps : sans `--force`, il ne traduit que les cours qui n'existent pas encore dans la langue ; quiz et glossaire par leurs scripts habituels), puis recopie vers iOS et Android.
3. Post-édition du cours, de son quiz, de son glossaire et de sa rubrique si elle est nouvelle (section 3) : `packs --courses <id>`. La commande s'arrête en erreur si un cours ou une clé demandés n'existent pas dans la langue.
4. Passe de cohérence sur ce cours (section 3).
5. La porte complète.

## 3. La post-édition cadrée

C'est la méthode de l'étape 3 (voir `docs/post-edition-native.md`), outillée dans le dépôt. Elle s'exécute avec Claude Code, qui lance les workflows enregistrés dans `.claude/workflows/`. Choisir un dossier de travail `W` hors du dépôt.

```
# 1. Lots de travail et fiche de terminologie, par langue
python3 scripts/postedit_i18n.py packs --lang it --out W/packs/it --courses course_312_mon_cours --keys paywall.nouveau.titre "offer.*"
#    affiche les lots écrits, par exemple {"ui2": 4, "cours_000": 35, "quiz_000": 52, "glossaire_000": 9}
#    (sans --courses ni --keys : toutes les surfaces de la langue, comme à l'étape 3 ;
#     --surfaces ui,catalogue,store,legal limite aux lots nommés ; --hinted ne garde, dans les
#     cours, quiz et glossaire, que les segments que la terminologie, le validateur ou l'audit
#     signalent. Les chaînes témoins ne sont jamais proposées, et apply refuse de les changer.)
python3 scripts/postedit_i18n.py termsheet --lang it --out W/term/it.md

# 2. Post-édition : workflow .claude/workflows/post-edition-native.js, avec les lots affichés
#    args : {"work": "W", "lots": ["it/ui2", "it/cours_000", "it/quiz_000", "it/glossaire_000"]}
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
#    s'arrête en erreur si un des cinq relecteurs n'a rien rendu : relancer celui-là
python3 scripts/postedit_i18n.py apply --lang it --from W/review_out/it
```

Les relecteurs sont des modèles de langue cadrés par le guide, la terminologie et la porte. Avant une mise en avant commerciale dans un pays, une relecture humaine de l'onboarding, du paywall et de la fiche App Store reste la meilleure garantie.

## 4. Écouter les utilisateurs, langue par langue

- **Retours.** Le formulaire de retour de l'app (iOS et Android) a une catégorie « Traduction ». Chaque envoi arrive sur Formspree avec `category: translation` et la langue de l'app (`language`) : on lit les plaintes langue par langue.
- **Conversion.** L'app envoie la langue de l'utilisateur à RevenueCat comme attribut client `app_language`, au lancement et à chaque changement de langue. On peut ainsi filtrer et exporter les clients RevenueCat par langue, et comparer essais et abonnements avant et après une correction.
- **Limite.** L'app n'a pas d'outil d'analyse produit (seulement RevenueCat et Meta Ads) : le taux de passage de l'onboarding par langue n'est pas mesuré aujourd'hui. Il faudrait un événement « onboarding terminé » portant la langue dans un outil d'analyse.
