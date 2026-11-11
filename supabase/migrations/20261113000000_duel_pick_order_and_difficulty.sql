-- Duels : l'adversaire choisit sa matière en premier une partie sur deux, et la progression
-- est plus douce au début. À coller tel quel dans l'éditeur SQL de Supabase ; rejouable.
--
-- 1. Qui choisit en premier. Jusqu'ici le joueur choisissait toujours sa matière à la manche 2
--    et l'adversaire à la manche 3. L'ordre est maintenant tiré au sort à chaque partie. Les
--    apps iOS et Android lisent déjà `picker` manche par manche : rien à mettre à jour côté app.
--    duel_finish_match_v2 remplace les questions de la manche où le joueur a choisi (2 ou 3) ;
--    une partie lancée avant ce script (manche 2) se termine normalement.
-- 2. Difficulté. L'adversaire joue un peu en dessous du joueur. Cette avance passait de 55 % de
--    victoires environ à moins de 50 % dès 300 trophées, puis vers 45 % (un bonus de ligue
--    durcissait l'adversaire à chaque palier). Elle vise maintenant 60 % au début et descend
--    en douceur vers 52 % à 1 500 trophées, où elle reste. Les trois premières parties, très
--    faciles, ne changent pas. Chiffres obtenus par simulation : il n'y a que 19 parties
--    classées en base au 11/11, trop peu pour mesurer.
--
-- duel_start_match_v2 repart de 20261112010000_duel_bot_names.sql (tirage des adversaires
-- inchangé) ; duel_finish_match_v2 de 20261111020100_duel_long_memory.sql.

-- La fin de partie d'abord : elle doit savoir lire une manche 3 avant qu'il en existe.
CREATE OR REPLACE FUNCTION public.duel_finish_match_v2(
  p_match_id uuid,
  p_answers jsonb DEFAULT '[]'::jsonb,
  p_abandoned boolean DEFAULT false,
  p_pick text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  m public.duel_matches;
  option jsonb;
  ids text[];
  first_q int;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  SELECT * INTO m FROM public.duel_matches WHERE id = p_match_id AND user_id = uid FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;

  IF m.status = 'active' AND m.rounds IS NOT NULL THEN
    option := m.rounds -> 'pick' -> 'options' -> p_pick;
    IF option IS NOT NULL THEN
      ids := ARRAY(SELECT jsonb_array_elements_text(option -> 'ids'));
      -- La première question de la manche où le joueur a choisi : 6 (manche 2) ou 11 (manche 3).
      first_q := CASE WHEN (m.rounds -> 'pick' ->> 'round') = '3' THEN 11 ELSE 6 END;
      UPDATE public.duel_matches SET
        question_ids = m.question_ids[1:first_q - 1] || ids || m.question_ids[first_q + 5:20],
        bot_script = (
          SELECT jsonb_agg(CASE WHEN t.ord BETWEEN first_q AND first_q + 4 THEN option -> 'bot' -> (t.ord - first_q)::int ELSE t.e END ORDER BY t.ord)
          FROM jsonb_array_elements(m.bot_script) WITH ORDINALITY AS t(e, ord)
        )
      WHERE id = m.id
      RETURNING * INTO m;
    END IF;
    -- Les questions réellement posées rejoignent les questions vues récemment.
    UPDATE public.duel_profiles SET
      recent_question_ids = ((m.question_ids || m.tiebreak_id) || recent_question_ids)[1:1500]
    WHERE user_id = uid;
  END IF;

  RETURN public.duel_finish_match(p_match_id, p_answers, p_abandoned);
END;
$$;

CREATE OR REPLACE FUNCTION public.duel_start_match_v2(p_can_forfeit boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  prof public.duel_profiles;
  bot public.duel_bots;
  bot_accuracy numeric;
  opponent_trophies int;
  opponent jsonb;
  kind_plan text[];
  part text[];
  used text[] := '{}';
  r1 text[] := '{}';
  r2 text[];
  r3 text[];
  r4 text[] := '{}';
  tb_id text;
  subjects text[];
  k int;
  b1 jsonb;
  b2 jsonb;
  b3 jsonb;
  b4 jsonb;
  btb jsonb;
  option_bot jsonb;
  pick_options jsonb := '{}'::jsonb;
  payload_options jsonb := '[]'::jsonb;
  new_id uuid;
  forfeit int;
  -- Qui choisit sa matière en premier : une partie sur deux, c'est l'adversaire.
  me_first boolean := random() < 0.5;
  my_round int;
  mine_ids text[];
  mine_bot jsonb;
  theirs_ids text[];
  theirs_bot jsonb;
  mine_json jsonb;
  theirs_json jsonb;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  prof := public.duel_ensure_profile(uid);
  PERFORM public.duel_resolve_stale(uid, interval '0 seconds');
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = uid FOR UPDATE;

  -- L'adversaire : jamais un des 150 derniers, ni un @ qui ressemble à ceux qu'on vient de croiser.
  bot := public.duel_pick_bot(prof.recent_bot_ids);
  IF bot.id IS NULL THEN
    RAISE EXCEPTION 'no_opponent';
  END IF;
  opponent_trophies := greatest(0, prof.trophies + round((random() * 2 - 1) * 60)::int);
  opponent := jsonb_build_object(
    'handle', bot.handle,
    'country_code', bot.country_code,
    -- Un adversaire sur dix n'a pas choisi d'avatar : ses initiales, comme un vrai compte neuf.
    -- Toujours les mêmes (selon le pseudo), pour qu'un adversaire recroisé ne change pas de tête.
    'avatar_id', CASE WHEN abs(hashtext(bot.handle)) % 10 = 0 THEN NULL ELSE bot.avatar_id END,
    'trophies', opponent_trophies,
    'league_position', public.duel_league_position(opponent_trophies)
  );

  IF prof.games < 3 THEN
    bot_accuracy := greatest(0.25, prof.accuracy - 0.28);
  ELSE
    -- L'avance laissée au joueur : large au début (environ 60 % de victoires), resserrée à
    -- mesure que les trophées montent (environ 52 % à partir de 1 500). Une série de victoires
    -- durcit un peu l'adversaire, une série de défaites l'adoucit davantage.
    bot_accuracy := prof.accuracy
      - (0.068 - 0.044 * least(1, prof.trophies / 1500.0))
      + 0.02 * least(prof.win_streak, 3)
      - 0.04 * least(prof.loss_streak, 3);
  END IF;
  bot_accuracy := greatest(0.20, least(0.95, bot_accuracy));

  -- Manche 1 (mixte), manche 4 (sprint) et question décisive d'abord : elles imposent leurs types.
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '2'], ['true_false', '1'], ['portrait', '1'], ['slider', '1']] LOOP
    part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r1 := r1 || part;
    used := used || part;
  END LOOP;
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '3'], ['true_false', '2']] LOOP
    part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r4 := r4 || part;
    used := used || part;
  END LOOP;
  part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, NULL, ARRAY['slider'], 1);
  tb_id := part[1];
  used := used || part;
  r1 := public.duel_shuffle(r1);
  r4 := public.duel_shuffle(r4);

  -- Les matières : trois proposées au joueur, une choisie par l'adversaire. L'ordre des deux
  -- manches (2 et 3) est tiré au sort.
  SELECT array_agg(s.subject ORDER BY random()) INTO subjects
    FROM (SELECT DISTINCT q.subject FROM public.duel_questions q WHERE q.active AND q.lang = 'en') s;
  IF coalesce(array_length(subjects, 1), 0) < 4 THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;
  FOR k IN 1..4 LOOP
    part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, subjects[k], NULL, 5);
    IF coalesce(array_length(part, 1), 0) < 5 THEN
      RAISE EXCEPTION 'not_enough_questions';
    END IF;
    used := used || part;
    option_bot := public.duel_bot_answers(part, bot_accuracy, prof.level, 1);
    IF k <= 3 THEN
      pick_options := pick_options || jsonb_build_object(subjects[k], jsonb_build_object('ids', to_jsonb(part), 'bot', option_bot));
      payload_options := payload_options || jsonb_build_array(jsonb_build_object(
        'subject', subjects[k],
        'questions', public.duel_questions_json(part, 1),
        'bot', option_bot));
      IF k = 1 THEN
        mine_ids := part;
        mine_bot := option_bot;
      END IF;
    ELSE
      theirs_ids := part;
      theirs_bot := option_bot;
    END IF;
  END LOOP;

  IF me_first THEN
    my_round := 2;
    r2 := mine_ids;
    b2 := mine_bot;
    r3 := theirs_ids;
    b3 := theirs_bot;
  ELSE
    my_round := 3;
    r2 := theirs_ids;
    b2 := theirs_bot;
    r3 := mine_ids;
    b3 := mine_bot;
  END IF;

  IF coalesce(array_length(r1, 1), 0) < 5 OR coalesce(array_length(r4, 1), 0) < 5 OR tb_id IS NULL THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;

  b1 := public.duel_bot_answers(r1, bot_accuracy, prof.level, 1);
  b4 := public.duel_bot_answers(r4, bot_accuracy, prof.level, 0.6);
  btb := public.duel_bot_answers(ARRAY[tb_id], bot_accuracy, prof.level, 1) -> 0;

  -- Très rarement (une partie sur quarante, jamais dans les cinq premières), l'adversaire
  -- « se déconnecte » en cours de partie : après la question forfeit (entre la 6e et la 17e),
  -- le joueur gagne par déconnexion. Seulement pour une app qui sait le montrer.
  IF coalesce(p_can_forfeit, false) AND prof.games >= 5 AND random() < 0.025 THEN
    forfeit := 6 + floor(random() * 12)::int;
  END IF;

  -- La partie est enregistrée avec la première matière proposée ; duel_finish_match_v2 la
  -- remplace par celle que le joueur a réellement choisie (dans la manche my_round).
  INSERT INTO public.duel_matches (user_id, bot_id, opponent, question_ids, tiebreak_id, bot_script, trophies_before, rounds, forfeit_at)
  VALUES (uid, bot.id, opponent, r1 || r2 || r3 || r4, tb_id, b1 || b2 || b3 || b4 || jsonb_build_array(btb), prof.trophies,
    jsonb_build_object('pick', jsonb_build_object('round', my_round, 'options', pick_options)), forfeit)
  RETURNING id INTO new_id;

  UPDATE public.duel_profiles SET
    recent_bot_ids = (bot.id || recent_bot_ids)[1:150],
    updated_at = now()
  WHERE user_id = uid;

  mine_json := jsonb_build_object('number', my_round, 'kind', 'pick', 'picker', 'me', 'options', payload_options);
  theirs_json := jsonb_build_object('number', 5 - my_round, 'kind', 'pick', 'picker', 'opponent', 'subject', subjects[4],
    'questions', public.duel_questions_json(theirs_ids, 1), 'bot', theirs_bot);

  RETURN jsonb_build_object(
    'match_id', new_id,
    'opponent', opponent,
    'rounds', jsonb_build_array(
      jsonb_build_object('number', 1, 'kind', 'mixed', 'questions', public.duel_questions_json(r1, 1), 'bot', b1),
      CASE WHEN me_first THEN mine_json ELSE theirs_json END,
      CASE WHEN me_first THEN theirs_json ELSE mine_json END,
      jsonb_build_object('number', 4, 'kind', 'sprint', 'questions', public.duel_questions_json(r4, 0.6), 'bot', b4)
    ),
    'tiebreak', (SELECT public.duel_question_json(q) FROM public.duel_questions q WHERE q.id = tb_id),
    'tiebreak_bot', btb,
    'opponent_leaves_after', forfeit,
    'search_ms', 2600 + floor(random() * 3200)::int
  );
END;
$$;

REVOKE ALL ON FUNCTION public.duel_start_match_v2(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_start_match_v2(boolean) TO authenticated;
