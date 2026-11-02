# Terminologie : la source est le français, et les mots pièges sont surveillés

Ce dossier porte la règle numéro un de la traduction de Sophia et les listes
qui la font respecter.

## La règle

**Toute traduction automatique et toute post-édition partent du texte
français.** Jamais de la table anglaise, jamais d'une langue intermédiaire.
`scripts/i18n_languages.py` fixe `MT_SOURCE_LANG = "fr"` et tous les pipelines
le lisent : chaînes d'interface (`translate_ui_strings.py`, depuis le
dictionnaire `french` d'`AppLocalizable.swift`), cours (`translate_courses_v2.py`),
quiz (`translate_quizzes_v2.py`), catalogue, glossaire et collections
(`translate_locale_catalog.py`, depuis les fichiers `*.fr.json`), textes
légaux iOS (`translate_legal_docs.py`, depuis `termsFrench` / `privacyFrench`)
et Android (`translate_android_legal.py`, depuis `legal/fr.json`), InfoPlist.

Pourquoi : jusqu'ici l'interface des vingt langues ajoutées après les six
premières était traduite depuis l'anglais, et le moteur pivote par l'anglais
pour la plupart des paires. Les mots français étaient donc pris dans leur sens
anglais le plus fréquent : essai → *trial* → procès, léger → *light* →
lumière, mensuel → *monthly* → magazine, flâneur → *stroller* → poussette,
caravane → *caravan* → camping-car, spleen → la rate, Premium → prime. Les
mêmes contresens se retrouvaient dans l'hébreu, l'arabe, l'estonien, le
finnois, le roumain, le slovaque. Le moteur pivote encore par l'anglais en
interne ; la liste ci-dessous sert à attraper ce qu'il rate.

## Les trois listes

- `mots_pieges.json` : 60 mots ou tournures que la machine prend dans le
  mauvais sens. Pour chaque entrée : le mot français avec son sens voulu, le
  pivot anglais qui trahit, les surfaces où il apparaît, les faux sens
  observés, et par langue la **forme imposée** et les **formes fautives**
  (expressions régulières) à signaler. Entrées de règle (pas de mot unique) :
  `on_impersonnel`, `en_annee`, `siecle`, `voici_comment`, `polysemie_courante`.
- `termes_produit.json` : les 20 termes de l'interface (quiz, cours, parcours,
  collection, niveau, série, essai gratuit, Premium, Sophia, bloqueur…) avec,
  par langue, le **terme canonique** à employer partout et les variantes à
  signaler. Premium et Sophia restent en latin, jamais traduits ni
  translittérés.
- `oeuvres.json` : 68 œuvres citées dans les cours (romans, pièces, tableaux,
  films, musique) avec, par langue, le titre sous lequel l'œuvre est connue
  (`etabli` : titre publié ; `original` : titre d'origine conservé ;
  `traduction_courante`) et les traductions littérales à signaler.

Les formes par langue ont été remplies par un relecteur natif par langue à
partir des constats de l'audit (`docs/audit-traductions/`). Un second
relecteur natif a ensuite passé chaque expression sur ses occurrences réelles
dans l'app et retiré ou resserré celles qui attrapaient du texte correct (le
nom établi d'un personnage, une syllabe commune, un usage légitime) :
642 décisions sur les 26 langues, consignées dans `elagage.json` et déjà
appliquées aux listes.

Elles se complètent comme `scripts/proper_nouns.json` : on ajoute une entrée
la première fois qu'un mot trahit, jamais deux fois ; une expression qui
attrape du texte correct se resserre plutôt qu'elle ne s'ignore.

## Le contrôle

```bash
python3 scripts/check_terminology.py                # résumé par langue
python3 scripts/check_terminology.py --lang he -v   # chaque occurrence, avec le contexte
python3 scripts/check_terminology.py --json /tmp/term.json
python3 scripts/check_terminology.py --gate         # code retour 1 s'il reste une occurrence
```

Le script balaye, pour chaque langue, toutes les surfaces affichées : chaînes
iOS et Android, corps de cours, quiz, glossaire, collections, catalogue
(titres, descriptions, titres de leçons), fiche App Store, textes légaux. Il
sert d'état des lieux ; la porte de sortie de toute traduction est
`scripts/i18n_gate.py` (étape 5 du plan, `docs/processus-traduction.md`), qui
l'appelle avec le validateur de cours et les autres contrôles, en CI.

## La porte : baseline et chaînes témoins

- `i18n_gate_baseline.json` : les constats (terminologie, validateur, quiz,
  copies) qui existaient quand la porte a été posée. Ils ne bloquent pas, les
  nouveaux bloquent. Après des corrections, `python3 scripts/i18n_gate.py
  --update-baseline` resserre la porte. On n'y ajoute jamais un constat pour
  faire passer un commit.
- `sentinelles.json` : 30 chaînes d'interface qui ont trahi pendant l'audit
  (essai, léger, mensuel, Premium, l'offre…), avec leur traduction attendue
  dans les 26 langues. La porte refuse tout écart, sur iOS et sur Android.

`scripts/proper_nouns.json` reste l'endroit où protéger un nom propre **avant**
la traduction ; ce dossier vérifie le résultat **après**.
