# Duels v5 : 1 500 questions de plus (dont 100 à image), traduites dans les 29 langues

Demande (12/11/2026 ~0h) : 1 500 questions de qualité, non répétitives, sur de nombreux sujets ;
traductions natives (du sens, pas du mot à mot) ; une question qui n'a pas de sens dans une langue
est SUPPRIMÉE dans toutes les langues ; 100 questions avec images ; Supabase en LECTURE seule ;
à la fin, le SQL à copier-coller. Images : choix du propriétaire = dossier à déposer dans le Storage
(content/duels/v5/upload/duels → bucket course-images, fusionne avec duels/).

La v4 (400 questions) est terminée : supabase/duels_v4_a_coller/1..3 (voir content/duels/v4_PROGRESS.md).

## Plan
- Texte : 12 rédacteurs (2 par matière, couloirs distincts) → content/duels/v5/draft_<matière>_<a|b>.json
  (125 brouillons chacun) ; consignes v4_BRIEF_WRITER.md + v5/BRIEF_V5.md.
- Vérification indépendante → content/duels/v5/final_<matière>_<a|b>.json, 117 chacune (≈1 400 au total ;
  ajuster pour avoir 1 400 pile).
- Images : 2 agents (a, b), 50 chacun : content/duels/v5/images_<a|b>.json, credits_<a|b>.json,
  draft_images_<a|b>.json, fichiers dans content/duels/v5/upload/duels/ ; outil scripts/duels_v5_images.py.
  Puis vérification → final_images_<a|b>.json ; crédits réunis dans content/duels/images.json.
- Dédoublonnage global (texte vs vivier + entre lots), puis scripts/duels_source/40_v5_*.json,
  python3 scripts/build_duels_seed.py.
- Traduction : work dir content/duels/i18n/lots_v5 (packs --new --parts 15), un agent par langue et
  par tiers (≈500 questions), TASK.md comme lots_v4 ; intraduisible → retiré de partout (pas inséré).
- SQL : scripts/build_duels_add_sql.py --baseline content/duels/v5/baseline_ids.txt
  --migration supabase/migrations/20261115010000_duels_v5_add.sql --paste-dir supabase/duels_v5_a_coller
  ; test sur Postgres local (/var/lib/postgresql/duelstest, port 5499).

## État
- [x] rédaction texte  - [x] vérification texte (12 × final_*.json, dédoublonnage global fait)
- [x] intégration texte : scripts/duels_source/40_v5_*.json → 1 400 questions (ids dans questions_en.json, absents de v5/baseline_ids.txt)
- [ ] images (agents a et b en cours) → vérifier, réduire/compléter à 100, scripts/duels_source/41_v5_images.json, crédits dans images.json, rebuild, pack part15
- [ ] traduction : packs part1..14 (texte) ; vague 1 = parts 1–7 (29 agents), vague 2 = parts 8–15 (29 agents)
- [ ] merge --new --parts 15, SQL, test Postgres local
