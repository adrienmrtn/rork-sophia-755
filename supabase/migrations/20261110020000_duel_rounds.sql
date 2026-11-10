-- Duels en quatre manches de cinq questions.
--
--   Manche 1 : questions de toutes les matières.
--   Manche 2 : le joueur choisit la matière parmi trois (entre amis : celui qui a lancé le défi).
--   Manche 3 : l'adversaire choisit la matière parmi trois autres.
--   Manche 4 : sprint, des QCM et des vrai/faux aux chronos courts (60 % du temps habituel).
--   Égalité : la question décisive, comme avant.
--
-- Les cinq questions de chaque matière proposée sont tirées au lancement de la partie : le choix
-- d'une matière ne demande aucun aller-retour de plus. Duel classé : duel_start_match_v2 et
-- duel_finish_match_v2 (les fonctions d'avant restent, pour les apps pas encore à jour).
-- Duel entre amis : mêmes fonctions qu'avant, plus duel_friend_pick.
-- Le contenu (137 questions, une vingtaine par matière) est dans 20261110020100_duels_seed_v2.sql.

ALTER TABLE public.duel_matches ADD COLUMN IF NOT EXISTS rounds jsonb;
ALTER TABLE public.duel_friend_matches ADD COLUMN IF NOT EXISTS round_options jsonb;
ALTER TABLE public.duel_friend_matches ADD COLUMN IF NOT EXISTS picks jsonb NOT NULL DEFAULT '{}'::jsonb;

-- ---------- helpers ----------

-- Temps accordé à une question selon sa place : les questions 16 à 20 (index 15 à 19) sont le sprint.
CREATE OR REPLACE FUNCTION public.duel_round_time_limit_ms(p_kind text, p_index int)
RETURNS int
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE WHEN p_index BETWEEN 15 AND 19
    THEN round(public.duel_time_limit_ms(p_kind) * 0.6)::int
    ELSE public.duel_time_limit_ms(p_kind) END;
$$;

CREATE OR REPLACE FUNCTION public.duel_shuffle(p_ids text[])
RETURNS text[]
LANGUAGE sql
VOLATILE
SET search_path TO 'public'
AS $$
  SELECT coalesce(array_agg(x ORDER BY random()), '{}') FROM unnest(p_ids) AS x;
$$;

-- Tire des questions proches d'un niveau, en évitant celles vues récemment et celles déjà
-- retenues pour la partie ; p_subject et p_kinds restreignent le tirage quand ils sont donnés.
CREATE OR REPLACE FUNCTION public.duel_pick_questions(
  p_level numeric, p_recent text[], p_exclude text[], p_subject text, p_kinds text[], p_count int
)
RETURNS text[]
LANGUAGE sql
VOLATILE
SET search_path TO 'public'
AS $$
  SELECT coalesce(array_agg(x.id), '{}')
  FROM (
    SELECT q.id
    FROM public.duel_questions q
    WHERE q.active AND q.lang = 'en'
      AND (p_subject IS NULL OR q.subject = p_subject)
      AND (p_kinds IS NULL OR q.kind = ANY (p_kinds))
      AND NOT (q.id = ANY (coalesce(p_exclude, '{}')))
    ORDER BY abs(q.level - p_level) + random() * 1.2
      + CASE
          WHEN array_position(p_recent, q.id) IS NULL THEN 0
          WHEN array_position(p_recent, q.id) <= 21 THEN 4
          ELSE 2
        END
    LIMIT p_count
  ) x;
$$;

-- Des questions dans l'ordre donné, avec leur temps multiplié par p_time_scale (0,6 pour le sprint).
CREATE OR REPLACE FUNCTION public.duel_questions_json(p_ids text[], p_time_scale numeric)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT coalesce(jsonb_agg(
    jsonb_set(public.duel_question_json(q), '{time_limit_ms}',
      to_jsonb(round(public.duel_time_limit_ms(q.kind) * p_time_scale)::int))
    ORDER BY t.ord), '[]'::jsonb)
  FROM unnest(p_ids) WITH ORDINALITY AS t(id, ord)
  JOIN public.duel_questions q ON q.id = t.id;
$$;

-- Les réponses de l'adversaire simulé à une suite de questions, dans le même ordre.
CREATE OR REPLACE FUNCTION public.duel_bot_answers(p_ids text[], p_accuracy numeric, p_level numeric, p_time_scale numeric)
RETURNS jsonb
LANGUAGE sql
VOLATILE
SET search_path TO 'public'
AS $$
  SELECT coalesce(jsonb_agg(
    jsonb_set(a.answer, '{time_ms}', to_jsonb(round((a.answer ->> 'time_ms')::numeric * p_time_scale)::int))
    ORDER BY a.ord), '[]'::jsonb)
  FROM (
    SELECT t.ord, public.duel_bot_answer(q, p_accuracy, p_level) AS answer
    FROM unnest(p_ids) WITH ORDINALITY AS t(id, ord)
    JOIN public.duel_questions q ON q.id = t.id
  ) a;
$$;

-- Les matières proposées pour une manche d'un duel entre amis, avec leurs questions.
CREATE OR REPLACE FUNCTION public.duel_round_options_json(p_round jsonb)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'subject', s.subject,
      'questions', public.duel_questions_json(
        ARRAY(SELECT jsonb_array_elements_text(p_round -> 'options' -> s.subject)), 1))
    ORDER BY s.ord), '[]'::jsonb)
  FROM jsonb_array_elements_text(p_round -> 'order') WITH ORDINALITY AS s(subject, ord);
$$;

-- ---------- duel classé ----------

-- Lance une partie en quatre manches. La manche 3 est celle de l'adversaire : sa matière est
-- tirée ici, parmi les trois que le joueur ne se voit pas proposer.
CREATE OR REPLACE FUNCTION public.duel_start_match_v2()
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
    'avatar_id', bot.avatar_id,
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

  -- La partie est enregistrée avec la première matière proposée ; duel_finish_match_v2 la
  -- remplace par celle que le joueur a réellement choisie.
  INSERT INTO public.duel_matches (user_id, bot_id, opponent, question_ids, tiebreak_id, bot_script, trophies_before, rounds)
  VALUES (uid, bot.id, opponent, r1 || r2 || r3 || r4, tb_id, b1 || b2 || b3 || b4 || jsonb_build_array(btb), prof.trophies,
    jsonb_build_object('pick', jsonb_build_object('round', 2, 'options', pick_options)))
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
    'search_ms', 2600 + floor(random() * 3200)::int
  );
END;
$$;

-- Termine une partie en manches. `p_pick` : la matière que le joueur a choisie pour la manche 2
-- (absente ou inconnue : la première proposée). Le reste est le travail de duel_finish_match.
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
      UPDATE public.duel_matches SET
        question_ids = m.question_ids[1:5] || ids || m.question_ids[11:20],
        bot_script = (
          SELECT jsonb_agg(CASE WHEN t.ord BETWEEN 6 AND 10 THEN option -> 'bot' -> (t.ord - 6)::int ELSE t.e END ORDER BY t.ord)
          FROM jsonb_array_elements(m.bot_script) WITH ORDINALITY AS t(e, ord)
        )
      WHERE id = m.id
      RETURNING * INTO m;
    END IF;
    -- Les questions réellement posées rejoignent les questions vues récemment.
    UPDATE public.duel_profiles SET
      recent_question_ids = ((m.question_ids || m.tiebreak_id) || recent_question_ids)[1:60]
    WHERE user_id = uid;
  END IF;

  RETURN public.duel_finish_match(p_match_id, p_answers, p_abandoned);
END;
$$;

-- ---------- duel entre amis ----------

-- Avance une partie entre amis : comme avant, plus les chronos courts du sprint, le temps
-- d'annonce entre deux manches et la matière par défaut d'une manche que personne n'a choisie.
CREATE OR REPLACE FUNCTION public.duel_friend_advance(p_match uuid)
RETURNS public.duel_friend_matches
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  m public.duel_friend_matches;
  q public.duel_questions;
  total int;
  i int;
  time_limit int;
  deadline timestamptz;
  a jsonb;
  b jsonb;
  a_done boolean;
  b_done boolean;
  resolved_at timestamptz;
  gap_a numeric;
  gap_b numeric;
  point_a boolean;
  point_b boolean;
  finish boolean;
  tiebreak_winner uuid;
BEGIN
  SELECT * INTO m FROM public.duel_friend_matches WHERE id = p_match FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;
  total := array_length(m.question_ids, 1);

  LOOP
    EXIT WHEN m.status <> 'active';
    EXIT WHEN now() < m.question_started_at;

    i := m.current_index;
    SELECT * INTO q FROM public.duel_questions
      WHERE id = CASE WHEN i < total THEN m.question_ids[i + 1] ELSE m.tiebreak_id END;
    -- La matière d'une manche au choix que personne n'a choisie à temps : celle par défaut.
    IF m.round_options IS NOT NULL AND i IN (5, 10) AND NOT (m.picks ? ((i / 5) + 1)::text) THEN
      m.picks := m.picks || jsonb_build_object(((i / 5) + 1)::text, m.round_options -> ((i / 5) + 1)::text ->> 'default');
      UPDATE public.duel_friend_matches SET picks = m.picks WHERE id = m.id;
    END IF;
    time_limit := public.duel_round_time_limit_ms(q.kind, CASE WHEN m.round_options IS NOT NULL THEN i ELSE 0 END);
    -- 1,5 s de marge après la fin du chrono : le temps qu'une réponse de dernière seconde arrive.
    deadline := m.question_started_at + (time_limit + 1500) * interval '1 millisecond';

    a := m.answers_a -> i;
    b := m.answers_b -> i;
    a_done := jsonb_typeof(a) = 'object' OR m.left_a;
    b_done := jsonb_typeof(b) = 'object' OR m.left_b;
    EXIT WHEN NOT (a_done AND b_done) AND now() < deadline;

    resolved_at := CASE WHEN a_done AND b_done THEN least(now(), deadline) ELSE deadline END;
    IF jsonb_typeof(a) IS DISTINCT FROM 'object' THEN
      a := jsonb_build_object('c', NULL, 'v', NULL, 't', time_limit);
    END IF;
    IF jsonb_typeof(b) IS DISTINCT FROM 'object' THEN
      b := jsonb_build_object('c', NULL, 'v', NULL, 't', time_limit);
    END IF;

    IF q.kind = 'slider' THEN
      gap_a := abs((a ->> 'v')::numeric - q.correct_value);
      gap_b := abs((b ->> 'v')::numeric - q.correct_value);
      point_a := gap_a IS NOT NULL AND (gap_b IS NULL OR gap_a <= gap_b);
      point_b := gap_b IS NOT NULL AND (gap_a IS NULL OR gap_b <= gap_a);
    ELSE
      point_a := coalesce((a ->> 'c')::int = q.correct_index, false);
      point_b := coalesce((b ->> 'c')::int = q.correct_index, false);
    END IF;

    m.answers_a := jsonb_set(m.answers_a, ARRAY[i::text], a);
    m.answers_b := jsonb_set(m.answers_b, ARRAY[i::text], b);

    finish := false;
    IF i < total THEN
      m.score_a := m.score_a + CASE WHEN point_a THEN 1 ELSE 0 END;
      m.score_b := m.score_b + CASE WHEN point_b THEN 1 ELSE 0 END;
      IF i < total - 1 THEN
        m.current_index := i + 1;
        -- Entre deux manches, le temps de l'annonce : 9 s pour choisir une matière (manches 2
        -- et 3), 3,5 s avant le sprint.
        m.question_started_at := resolved_at + (public.duel_friend_reveal_ms(q.kind)
          + CASE WHEN m.round_options IS NULL THEN 0 WHEN i + 1 IN (5, 10) THEN 9000 WHEN i + 1 = 15 THEN 3500 ELSE 0 END
          ) * interval '1 millisecond';
      ELSIF m.score_a = m.score_b AND NOT (m.left_a OR m.left_b) THEN
        -- Égalité après la dernière question : la question décisive, après son annonce.
        m.tiebreak := true;
        m.current_index := total;
        m.question_started_at := resolved_at + (public.duel_friend_reveal_ms(q.kind) + 2600) * interval '1 millisecond';
      ELSE
        finish := true;
      END IF;
    ELSE
      -- Question décisive : au plus proche ; à distance égale, au plus rapide.
      tiebreak_winner := CASE
        WHEN gap_a IS NULL AND gap_b IS NULL THEN NULL
        WHEN gap_b IS NULL THEN m.player_a
        WHEN gap_a IS NULL THEN m.player_b
        WHEN gap_a < gap_b THEN m.player_a
        WHEN gap_b < gap_a THEN m.player_b
        WHEN coalesce((a ->> 't')::numeric, 1e9) <= coalesce((b ->> 't')::numeric, 1e9) THEN m.player_a
        ELSE m.player_b
      END;
      point_a := coalesce(tiebreak_winner = m.player_a, false);
      point_b := coalesce(tiebreak_winner = m.player_b, false);
      finish := true;
    END IF;
    m.points_a := m.points_a || to_jsonb(coalesce(point_a, false));
    m.points_b := m.points_b || to_jsonb(coalesce(point_b, false));

    IF finish THEN
      m.status := 'finished';
      m.finished_at := resolved_at;
      m.winner := CASE
        WHEN m.left_a AND NOT m.left_b THEN m.player_b
        WHEN m.left_b AND NOT m.left_a THEN m.player_a
        WHEN m.score_a > m.score_b THEN m.player_a
        WHEN m.score_b > m.score_a THEN m.player_b
        ELSE tiebreak_winner
      END;
    END IF;

    UPDATE public.duel_friend_matches SET
      status = m.status,
      current_index = m.current_index,
      question_started_at = m.question_started_at,
      answers_a = m.answers_a,
      answers_b = m.answers_b,
      score_a = m.score_a,
      score_b = m.score_b,
      points_a = m.points_a,
      points_b = m.points_b,
      tiebreak = m.tiebreak,
      winner = m.winner,
      finished_at = m.finished_at
    WHERE id = m.id;
  END LOOP;

  RETURN m;
END;
$$;

CREATE OR REPLACE FUNCTION public.duel_friend_state_json(m public.duel_friend_matches, p_uid uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  is_a boolean := m.player_a = p_uid;
  mine jsonb := CASE WHEN is_a THEN m.answers_a ELSE m.answers_b END;
  theirs jsonb := CASE WHEN is_a THEN m.answers_b ELSE m.answers_a END;
  -- Les questions closes : toutes celles d'avant la question en cours, et elle aussi une
  -- fois la partie finie.
  resolved int := CASE WHEN m.status = 'finished' THEN m.current_index + 1 ELSE m.current_index END;
  opponent_answers jsonb;
BEGIN
  -- Une case restée vide (partie arrêtée parce que les deux joueurs sont partis) est rendue
  -- comme une question sans réponse.
  SELECT coalesce(jsonb_agg(
      CASE WHEN jsonb_typeof(t.x) = 'object' THEN t.x ELSE jsonb_build_object('c', NULL, 'v', NULL, 't', 0) END
      ORDER BY t.ord), '[]'::jsonb)
    INTO opponent_answers
    FROM jsonb_array_elements(theirs) WITH ORDINALITY AS t(x, ord)
    WHERE t.ord <= resolved;

  RETURN jsonb_build_object(
    'match_id', m.id,
    'finished', m.status = 'finished',
    'index', m.current_index,
    'resolved', resolved,
    -- Positif : la question démarre dans tant de ms ; négatif : elle tourne depuis tant de ms.
    'question_starts_in_ms', round(extract(epoch FROM (m.question_started_at - clock_timestamp())) * 1000)::bigint,
    'my_score', CASE WHEN is_a THEN m.score_a ELSE m.score_b END,
    'opponent_score', CASE WHEN is_a THEN m.score_b ELSE m.score_a END,
    'my_answered', m.status = 'active' AND jsonb_typeof(mine -> m.current_index) = 'object',
    'opponent_answered', m.status = 'active' AND jsonb_typeof(theirs -> m.current_index) = 'object',
    'opponent_answers', opponent_answers,
    'my_points', CASE WHEN is_a THEN m.points_a ELSE m.points_b END,
    'opponent_points', CASE WHEN is_a THEN m.points_b ELSE m.points_a END,
    'tiebreak', m.tiebreak,
    -- Les matières choisies pour les manches 2 et 3 : {"2": "art", "3": "science"}.
    'picks', m.picks,
    'opponent_left', CASE WHEN is_a THEN m.left_b ELSE m.left_a END,
    'won', m.status = 'finished' AND coalesce(m.winner = p_uid, false),
    'draw', m.status = 'finished' AND m.winner IS NULL
  );
END;
$$;

-- Ce que chaque joueur reçoit au lancement : les quatre manches, vues de son côté.
CREATE OR REPLACE FUNCTION public.duel_friend_start_json(m public.duel_friend_matches, p_uid uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  is_a boolean := m.player_a = p_uid;
  questions jsonb;
  tiebreak jsonb;
  rounds jsonb;
BEGIN
  -- Les 20 questions à plat, avec les matières par défaut (apps d'avant les manches).
  SELECT jsonb_agg(
      jsonb_set(public.duel_question_json(q), '{time_limit_ms}',
        to_jsonb(public.duel_round_time_limit_ms(q.kind, CASE WHEN m.round_options IS NOT NULL THEN (t.ord - 1)::int ELSE 0 END)))
      ORDER BY t.ord)
    INTO questions
    FROM unnest(m.question_ids) WITH ORDINALITY AS t(id, ord)
    JOIN public.duel_questions q ON q.id = t.id;
  SELECT public.duel_question_json(q) INTO tiebreak
    FROM public.duel_questions q WHERE q.id = m.tiebreak_id;

  IF m.round_options IS NOT NULL THEN
    -- Manche 2 : la matière est choisie par celui qui a lancé le défi ; manche 3 : par l'autre.
    rounds := jsonb_build_array(
      jsonb_build_object('number', 1, 'kind', 'mixed',
        'questions', public.duel_questions_json(m.question_ids[1:5], 1)),
      jsonb_build_object('number', 2, 'kind', 'pick', 'picker', CASE WHEN is_a THEN 'me' ELSE 'opponent' END,
        'options', public.duel_round_options_json(m.round_options -> '2')),
      jsonb_build_object('number', 3, 'kind', 'pick', 'picker', CASE WHEN is_a THEN 'opponent' ELSE 'me' END,
        'options', public.duel_round_options_json(m.round_options -> '3')),
      jsonb_build_object('number', 4, 'kind', 'sprint',
        'questions', public.duel_questions_json(m.question_ids[16:20], 0.6))
    );
  END IF;

  RETURN jsonb_build_object(
    'match_id', m.id,
    'me', public.duel_player_card(p_uid),
    'opponent', public.duel_player_card(CASE WHEN is_a THEN m.player_b ELSE m.player_a END),
    'rounds', rounds,
    'questions', questions,
    'tiebreak', tiebreak,
    'starts_in_ms', round(extract(epoch FROM (m.question_started_at - clock_timestamp())) * 1000)::bigint
  );
END;
$$;

-- Réponse à une invitation reçue. Acceptée : la partie est créée, en quatre manches, au niveau
-- moyen des deux joueurs, et démarre 5 secondes plus tard pour les deux.
CREATE OR REPLACE FUNCTION public.duel_invite_respond(p_invite uuid, p_accept boolean)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  inv public.duel_invites;
  m public.duel_friend_matches;
  avg_level numeric;
  q_ids text[];
  tb_id text;
  empty_answers jsonb;
  kind_plan text[];
  part text[];
  used text[] := '{}';
  r1 text[] := '{}';
  r2 text[];
  r3 text[];
  r4 text[] := '{}';
  subjects text[];
  options_2 jsonb := '{}'::jsonb;
  options_3 jsonb := '{}'::jsonb;
  k int;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  SELECT * INTO inv FROM public.duel_invites WHERE id = p_invite AND invitee_id = uid FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_not_found';
  END IF;
  IF inv.status <> 'pending' OR now() > inv.expires_at + interval '2 seconds' THEN
    IF inv.status = 'pending' THEN
      UPDATE public.duel_invites SET status = 'expired' WHERE id = inv.id;
    END IF;
    RETURN jsonb_build_object('status', 'expired', 'match', NULL);
  END IF;

  IF NOT coalesce(p_accept, false) THEN
    UPDATE public.duel_invites SET status = 'declined' WHERE id = inv.id;
    RETURN jsonb_build_object('status', 'declined', 'match', NULL);
  END IF;

  PERFORM public.duel_ensure_profile(inv.inviter_id);
  PERFORM public.duel_ensure_profile(uid);
  SELECT avg(dp.level) INTO avg_level
    FROM public.duel_profiles dp WHERE dp.user_id IN (inv.inviter_id, uid);

  -- Quatre manches de cinq questions : mixte, matière au choix de celui qui a lancé le défi,
  -- matière au choix de l'autre, sprint (QCM et vrai/faux, chronos courts). Les cinq questions
  -- de chacune des six matières sont tirées d'avance : choisir une matière ne coûte rien.
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '2'], ['true_false', '1'], ['portrait', '1'], ['slider', '1']] LOOP
    part := public.duel_pick_questions(avg_level, '{}', used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r1 := r1 || part;
    used := used || part;
  END LOOP;
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '3'], ['true_false', '2']] LOOP
    part := public.duel_pick_questions(avg_level, '{}', used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r4 := r4 || part;
    used := used || part;
  END LOOP;
  part := public.duel_pick_questions(avg_level, '{}', used, NULL, ARRAY['slider'], 1);
  tb_id := part[1];
  used := used || part;

  SELECT array_agg(s.subject ORDER BY random()) INTO subjects
    FROM (SELECT DISTINCT q.subject FROM public.duel_questions q WHERE q.active AND q.lang = 'en') s;
  IF coalesce(array_length(subjects, 1), 0) < 6 THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;
  FOR k IN 1..6 LOOP
    part := public.duel_pick_questions(avg_level, '{}', used, subjects[k], NULL, 5);
    IF coalesce(array_length(part, 1), 0) < 5 THEN
      RAISE EXCEPTION 'not_enough_questions';
    END IF;
    used := used || part;
    IF k <= 3 THEN
      options_2 := options_2 || jsonb_build_object(subjects[k], to_jsonb(part));
    ELSE
      options_3 := options_3 || jsonb_build_object(subjects[k], to_jsonb(part));
    END IF;
    IF k = 1 THEN r2 := part; END IF;
    IF k = 4 THEN r3 := part; END IF;
  END LOOP;

  r1 := public.duel_shuffle(r1);
  r4 := public.duel_shuffle(r4);
  q_ids := r1 || r2 || r3 || r4;
  IF coalesce(array_length(q_ids, 1), 0) < 20 OR tb_id IS NULL THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;

  SELECT jsonb_agg('null'::jsonb) INTO empty_answers FROM generate_series(1, array_length(q_ids, 1) + 1);

  INSERT INTO public.duel_friend_matches (player_a, player_b, question_ids, tiebreak_id, question_started_at, answers_a, answers_b, round_options)
  VALUES (inv.inviter_id, uid, q_ids, tb_id, now() + interval '5 seconds', empty_answers, empty_answers,
    jsonb_build_object(
      '2', jsonb_build_object('default', subjects[1], 'order', to_jsonb(subjects[1:3]), 'options', options_2),
      '3', jsonb_build_object('default', subjects[4], 'order', to_jsonb(subjects[4:6]), 'options', options_3)))
  RETURNING * INTO m;

  UPDATE public.duel_invites SET status = 'accepted', match_id = m.id WHERE id = inv.id;

  RETURN jsonb_build_object('status', 'accepted', 'match', public.duel_friend_start_json(m, uid));
END;
$$;

-- Le choix de la matière d'une manche (2 : celui qui a lancé le défi ; 3 : l'autre). Possible
-- seulement pendant l'annonce de la manche, avant sa première question.
CREATE OR REPLACE FUNCTION public.duel_friend_pick(p_match uuid, p_round int, p_subject text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  m public.duel_friend_matches;
  ids text[];
  slot int;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.duel_friend_matches x
    WHERE x.id = p_match AND uid IN (x.player_a, x.player_b)
  ) THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;

  m := public.duel_friend_advance(p_match);
  slot := (p_round - 1) * 5;

  IF m.status = 'active'
     AND m.round_options IS NOT NULL
     AND p_round IN (2, 3)
     AND uid = (CASE WHEN p_round = 2 THEN m.player_a ELSE m.player_b END)
     AND NOT (m.picks ? p_round::text)
     AND m.current_index = slot
     AND now() < m.question_started_at
     AND m.round_options -> p_round::text -> 'options' ? p_subject
  THEN
    ids := ARRAY(SELECT jsonb_array_elements_text(m.round_options -> p_round::text -> 'options' -> p_subject));
    UPDATE public.duel_friend_matches SET
      question_ids = question_ids[1:slot] || ids || question_ids[slot + 6:20],
      picks = picks || jsonb_build_object(p_round::text, p_subject)
    WHERE id = p_match
    RETURNING * INTO m;
  END IF;

  RETURN public.duel_friend_state_json(m, uid);
END;
$$;

-- ---------- droits d'exécution ----------

REVOKE ALL ON FUNCTION public.duel_round_time_limit_ms(text, int) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_shuffle(text[]) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_pick_questions(numeric, text[], text[], text, text[], int) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_questions_json(text[], numeric) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_bot_answers(text[], numeric, numeric, numeric) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_round_options_json(jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_advance(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_state_json(public.duel_friend_matches, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_start_json(public.duel_friend_matches, uuid) FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.duel_start_match_v2() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_start_match_v2() TO authenticated;
REVOKE ALL ON FUNCTION public.duel_finish_match_v2(uuid, jsonb, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_finish_match_v2(uuid, jsonb, boolean, text) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_invite_respond(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_invite_respond(uuid, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_pick(uuid, int, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_friend_pick(uuid, int, text) TO authenticated;
