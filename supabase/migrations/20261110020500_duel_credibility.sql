-- Duels : deux détails qui rendent les adversaires plus crédibles.
--
-- 1. Un adversaire sur dix n'a pas d'avatar (ses initiales à la place), toujours les mêmes.
-- 2. Très rarement (2,5 % des parties, jamais dans les cinq premières), l'adversaire se
--    déconnecte en cours de partie : le joueur gagne par déconnexion. Le serveur le décide au
--    lancement (duel_matches.forfeit_at) et l'annonce à l'app (opponent_leaves_after) ; à la fin,
--    il ne compte que les questions jouées avant le départ et donne la victoire. L'app le
--    demande (p_can_forfeit) : une app plus ancienne, qui ne saurait pas le montrer, n'y a pas droit.

ALTER TABLE public.duel_matches
  ADD COLUMN IF NOT EXISTS forfeit_at int CHECK (forfeit_at IS NULL OR forfeit_at BETWEEN 1 AND 19);

COMMENT ON COLUMN public.duel_matches.forfeit_at IS 'L''adversaire se déconnecte après cette question (1 à 19) : victoire par déconnexion. Null : partie normale.';

-- Le paramètre s'ajoute : l'ancienne signature est retirée pour qu'il n'y ait qu'une fonction
-- (un appel sans paramètre, celui des apps déjà publiées, continue de marcher).
DROP FUNCTION IF EXISTS public.duel_start_match_v2();

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
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  prof := public.duel_ensure_profile(uid);
  PERFORM public.duel_resolve_stale(uid, interval '0 seconds');
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = uid FOR UPDATE;

  SELECT * INTO bot
    FROM public.duel_bots b
    WHERE b.active AND NOT (b.id = ANY (prof.recent_bot_ids))
    ORDER BY random()
    LIMIT 1;
  IF NOT FOUND THEN
    SELECT * INTO bot FROM public.duel_bots b WHERE b.active ORDER BY random() LIMIT 1;
  END IF;
  IF NOT FOUND THEN
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
    bot_accuracy := prof.accuracy - 0.035
      + 0.03 * least(prof.win_streak, 4)
      - 0.04 * least(prof.loss_streak, 3)
      + 0.004 * (public.duel_league_position(prof.trophies) - 1);
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

  -- Les matières : trois proposées au joueur (manche 2), une choisie par l'adversaire (manche 3).
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
        r2 := part;
        b2 := option_bot;
      END IF;
    ELSE
      r3 := part;
      b3 := option_bot;
    END IF;
  END LOOP;

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
  -- remplace par celle que le joueur a réellement choisie.
  INSERT INTO public.duel_matches (user_id, bot_id, opponent, question_ids, tiebreak_id, bot_script, trophies_before, rounds, forfeit_at)
  VALUES (uid, bot.id, opponent, r1 || r2 || r3 || r4, tb_id, b1 || b2 || b3 || b4 || jsonb_build_array(btb), prof.trophies,
    jsonb_build_object('pick', jsonb_build_object('round', 2, 'options', pick_options)), forfeit)
  RETURNING id INTO new_id;

  UPDATE public.duel_profiles SET
    recent_bot_ids = (bot.id || recent_bot_ids)[1:25],
    updated_at = now()
  WHERE user_id = uid;

  RETURN jsonb_build_object(
    'match_id', new_id,
    'opponent', opponent,
    'rounds', jsonb_build_array(
      jsonb_build_object('number', 1, 'kind', 'mixed', 'questions', public.duel_questions_json(r1, 1), 'bot', b1),
      jsonb_build_object('number', 2, 'kind', 'pick', 'picker', 'me', 'options', payload_options),
      jsonb_build_object('number', 3, 'kind', 'pick', 'picker', 'opponent', 'subject', subjects[4],
        'questions', public.duel_questions_json(r3, 1), 'bot', b3),
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

-- Le compte des points : inchangé, sauf pour une partie où l'adversaire s'est déconnecté.
CREATE OR REPLACE FUNCTION public.duel_finish_match(
  p_match_id uuid,
  p_answers jsonb DEFAULT '[]'::jsonb,
  p_abandoned boolean DEFAULT false
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
  answers jsonb := CASE WHEN jsonb_typeof(p_answers) = 'array' THEN p_answers ELSE '[]'::jsonb END;
  r record;
  a jsonb;
  b jsonb;
  player_score int := 0;
  opponent_score int := 0;
  choice_total int := 0;
  choice_right int := 0;
  player_gap numeric;
  bot_gap numeric;
  used_tiebreak boolean := false;
  won boolean;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO m FROM public.duel_matches WHERE id = p_match_id AND user_id = uid FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;
  IF m.status <> 'active' THEN
    RETURN public.duel_match_result_json(m);
  END IF;

  IF p_abandoned THEN
    RETURN public.duel_apply_result(m.id, false, 0, 0, false, answers, true, NULL);
  END IF;

  FOR r IN
    SELECT t.ord::int AS ord, q.kind, q.correct_index, q.correct_value
    FROM unnest(m.question_ids) WITH ORDINALITY AS t(id, ord)
    JOIN public.duel_questions q ON q.id = t.id
    ORDER BY t.ord
  LOOP
    -- L'adversaire s'est déconnecté après la question forfeit_at : la partie s'arrête là.
    EXIT WHEN m.forfeit_at IS NOT NULL AND r.ord > m.forfeit_at;
    a := coalesce(answers -> (r.ord - 1), '{}'::jsonb);
    b := coalesce(m.bot_script -> (r.ord - 1), '{}'::jsonb);
    IF r.kind = 'slider' THEN
      player_gap := abs((a ->> 'v')::numeric - r.correct_value);
      bot_gap := abs((b ->> 'value')::numeric - r.correct_value);
      -- Le plus proche marque ; à distance égale, les deux marquent.
      IF player_gap IS NOT NULL AND (bot_gap IS NULL OR player_gap <= bot_gap) THEN
        player_score := player_score + 1;
      END IF;
      IF bot_gap IS NOT NULL AND (player_gap IS NULL OR bot_gap <= player_gap) THEN
        opponent_score := opponent_score + 1;
      END IF;
    ELSE
      choice_total := choice_total + 1;
      IF (a ->> 'c')::int = r.correct_index THEN
        player_score := player_score + 1;
        choice_right := choice_right + 1;
      END IF;
      IF coalesce((b ->> 'correct')::boolean, false) THEN
        opponent_score := opponent_score + 1;
      END IF;
    END IF;
  END LOOP;

  IF m.forfeit_at IS NOT NULL THEN
    -- Victoire par déconnexion, quel que soit le score au moment du départ.
    won := true;
  ELSIF player_score <> opponent_score THEN
    won := player_score > opponent_score;
  ELSE
    -- Égalité : la question décisive, au plus proche ; à distance égale, au plus rapide.
    used_tiebreak := true;
    a := coalesce(answers -> array_length(m.question_ids, 1), '{}'::jsonb);
    b := coalesce(m.bot_script -> array_length(m.question_ids, 1), '{}'::jsonb);
    SELECT abs((a ->> 'v')::numeric - q.correct_value), abs((b ->> 'value')::numeric - q.correct_value)
      INTO player_gap, bot_gap
      FROM public.duel_questions q WHERE q.id = m.tiebreak_id;
    won := player_gap IS NOT NULL AND (
      bot_gap IS NULL
      OR player_gap < bot_gap
      OR (player_gap = bot_gap AND coalesce((a ->> 't')::numeric, 1e9) <= coalesce((b ->> 'time_ms')::numeric, 0))
    );
  END IF;

  RETURN public.duel_apply_result(
    m.id, won, player_score, opponent_score, used_tiebreak, answers, false,
    CASE WHEN choice_total > 0 THEN choice_right::numeric / choice_total ELSE NULL END
  );
END;
$$;

REVOKE ALL ON FUNCTION public.duel_finish_match(uuid, jsonb, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_finish_match(uuid, jsonb, boolean) TO authenticated;
