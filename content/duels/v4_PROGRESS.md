# Duels v4 : 400 nouvelles questions, traduites dans les 29 langues

Demande (11/11/2026) : 400 nouvelles questions variées, traduites dans toutes les langues, puis
le SQL à copier-coller. Supabase en LECTURE seule (rien n'est écrit dans la base par Claude).

État de la base au 11/11 22h UTC (lecture) : 1 321 questions (ids max par niveau :
163/165/170/170/177/163/163/150), 1 312 traductions par langue (9 retirées). Conforme au dépôt.

## Étapes
1. [ ] Rédaction : 6 matières, ~72 brouillons chacune → content/duels/v4/draft_<matière>.json
   (consigne : content/duels/v4/v4_BRIEF_WRITER.md ; existant : content/duels/v4/existing_<matière>.txt)
2. [ ] Vérification indépendante → content/duels/v4/final_<matière>.json
   (history 67, science 67, literature 66, art 66, mythology 66, world 68 = 400)
3. [ ] scripts/duels_source/30_v4_<matière>.json, build_duels_seed.py → ids nouveaux
4. [ ] Traduction : work dir content/duels/i18n/lots_v4 (packs --new), out/<lang>/part*.json
5. [ ] Fusion dans content/duels/i18n/<lang>.json (merge --new)
6. [ ] SQL : supabase/migrations/20261114010000_duels_v4.sql + supabase/duels_v4_a_coller/
