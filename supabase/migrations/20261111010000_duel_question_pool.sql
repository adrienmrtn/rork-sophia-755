-- Duels : une base de questions bien plus large (1 200 et plus), et une mémoire plus longue
-- de ce que chaque joueur a déjà vu, pour qu'il ne retombe pas sur les mêmes questions.
--
-- - duel_pick_questions : une question vue dans les 120 dernières est presque exclue, une
--   question vue dans les 300 dernières est nettement défavorisée (avant : 21 et 60).
-- - duel_finish_match_v2 : la mémoire d'un joueur passe de 60 à 300 questions (15 parties).
-- - duel_invite_respond : un duel entre amis évite ce que l'un ou l'autre a vu récemment, et
--   ses questions entrent dans la mémoire des deux joueurs.
--
-- Rien d'autre ne change : mêmes signatures, mêmes droits (CREATE OR REPLACE les conserve).
-- Les nouvelles questions à image (drapeaux, tableaux, monuments) sont des « portrait » pour
-- l'app, et les comparaisons des QCM à deux réponses : toutes les versions les affichent.

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
          WHEN array_position(p_recent, q.id) <= 120 THEN 6
          ELSE 3
        END
    LIMIT p_count
  ) x;
$$;

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
      recent_question_ids = ((m.question_ids || m.tiebreak_id) || recent_question_ids)[1:300]
    WHERE user_id = uid;
  END IF;

  RETURN public.duel_finish_match(p_match_id, p_answers, p_abandoned);
END;
$$;

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
  recent text[] := '{}';
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
  -- Ce que l'un ou l'autre a vu récemment en duel classé ou entre amis est évité.
  SELECT coalesce(array_agg(x.id), '{}') INTO recent
    FROM public.duel_profiles dp
    CROSS JOIN LATERAL unnest(dp.recent_question_ids[1:120]) AS x(id)
    WHERE dp.user_id IN (inv.inviter_id, uid);

  -- Quatre manches de cinq questions : mixte, matière au choix de celui qui a lancé le défi,
  -- matière au choix de l'autre, sprint (QCM et vrai/faux, chronos courts). Les cinq questions
  -- de chacune des six matières sont tirées d'avance : choisir une matière ne coûte rien.
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '2'], ['true_false', '1'], ['portrait', '1'], ['slider', '1']] LOOP
    part := public.duel_pick_questions(avg_level, recent, used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r1 := r1 || part;
    used := used || part;
  END LOOP;
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '3'], ['true_false', '2']] LOOP
    part := public.duel_pick_questions(avg_level, recent, used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r4 := r4 || part;
    used := used || part;
  END LOOP;
  part := public.duel_pick_questions(avg_level, recent, used, NULL, ARRAY['slider'], 1);
  tb_id := part[1];
  used := used || part;

  SELECT array_agg(s.subject ORDER BY random()) INTO subjects
    FROM (SELECT DISTINCT q.subject FROM public.duel_questions q WHERE q.active AND q.lang = 'en') s;
  IF coalesce(array_length(subjects, 1), 0) < 6 THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;
  FOR k IN 1..6 LOOP
    part := public.duel_pick_questions(avg_level, recent, used, subjects[k], NULL, 5);
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

  -- Les questions de la partie rejoignent les questions vues récemment des deux joueurs
  -- (avec la matière proposée par défaut aux manches au choix).
  UPDATE public.duel_profiles SET
    recent_question_ids = ((q_ids || tb_id) || recent_question_ids)[1:300]
  WHERE user_id IN (inv.inviter_id, uid);

  RETURN jsonb_build_object('status', 'accepted', 'match', public.duel_friend_start_json(m, uid));
END;
$$;
