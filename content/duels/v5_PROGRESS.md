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

## File d'attente des traductions (20 agents max en même temps)
- Vague 1 (parts 1–7) lancée : fr es(fini) sk de pt pt-PT it tr pl ro nl el sv hu bg cs da nb ru hr sl
- Vague 1 à lancer : (aucune)
- Vague 2 = parts 8–14 (texte) : à lancer langue par langue quand une place se libère. Lancées : es pt-PT nb cs nl tr
- Vague 3 = part 15 (images) + part 16 (questions de remplacement des retirées, pour finir à 1 500) :
  quelques agents multi-langues à la fin.
- Retirées (intraduisibles / donnent la réponse) : dq_en_2_284, dq_en_4_309, dq_en_1_276, dq_en_2_277 (voir _excluded.json)
(Une langue est finie pour une vague quand out/<lang>/part<N>.json existe et passe `check` pour toutes ses parts.)

## 12/11 03:20 UTC : reprise après la limite d'usage
Les 20 agents interrompus ont été relancés (ils reprennent où ils étaient) :
- vague 1 (parts 1–7) : ar el et fi he hu ja lt lv pl sk sr
- vague 2 (parts 8–14) : es pt-PT nb cs nl tr
- images a et b
Restent à lancer ensuite : vague 1 rien d'autre ; vague 2 pour fr de pt it ro bg da sv ru hr sl hu el pl
  sk sr ar he fi et lt lv ja (au fil des places libres) ; puis images (part 15) et remplacements (part 16).
- 03:25 : pl et hu parts 1–7 finis ; vague 2 lancée aussi pour fr de
- el parts 1–7 fini ; vague 2 lancée pour pt
- es parts 8–14 fini (es complet pour le texte) ; vague 2 lancée pour it
- pt-PT parts 8–14 fini ; vague 2 lancée pour ro
- sr parts 1–7 fini ; vague 2 lancée pour bg
- nl parts 8–14 fini (nl complet texte) ; vague 2 lancée pour da
- ja parts 1–7 fini ; vague 2 lancée pour sv
- fr parts 8–14 fini (fr complet texte) ; vague 2 lancée pour ru
- cs parts 8–14 fini ; dq_en_2_337 retirée ; vague 2 lancée pour hr
- nb parts 8–14 fini ; vague 2 lancée pour sl
- de, tr parts 8–14 finis ; vague 2 lancée pour pl hu (el en attente)
- sk parts 1–7 fini ; vague 2 lancée pour el
- ar parts 1–7 fini ; vague 2 lancée pour sr
