-- Duels : plus de question déjà vue tant qu'il en reste de nouvelles.
--
-- Constat : après un duel entre amis, la partie suivante reposait des questions qu'on venait
-- de voir. Deux causes :
-- - duel_pick_questions ne faisait que défavoriser une question vue (un malus ajouté à
--   l'écart de niveau et au hasard) : une question proche du niveau du joueur pouvait passer
--   quand même. Désormais une question en mémoire ne sort que s'il ne reste aucune question
--   jamais vue pour la matière et le type demandés ; dans ce cas, la plus ancienne d'abord.
-- - duel_friend_pick : quand un joueur choisit une autre matière que celle proposée par
--   défaut, ses cinq questions n'entraient dans la mémoire de personne.
-- - duel_invite_respond : évite toute la mémoire des deux joueurs (300 questions chacun),
--   plus seulement les 120 dernières.
--
-- Mêmes signatures, mêmes droits (CREATE OR REPLACE les conserve). À passer après
-- 20261111010000_duel_question_pool.sql.

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
    ORDER BY
      -- D'abord les questions jamais vues, au plus près du niveau, avec une part de hasard.
      (array_position(p_recent, q.id) IS NOT NULL),
      CASE
        WHEN array_position(p_recent, q.id) IS NULL THEN abs(q.level - p_level) + random() * 1.2
        -- Faute de mieux, la question vue il y a le plus longtemps.
        ELSE -array_position(p_recent, q.id)::numeric
      END
    LIMIT p_count
  ) x;
$$;

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
    -- La matière choisie remplace celle par défaut : ses cinq questions entrent aussi dans
    -- la mémoire des deux joueurs, sinon la partie suivante pouvait les reposer.
    UPDATE public.duel_profiles SET
      recent_question_ids = (ids || recent_question_ids)[1:300]
    WHERE user_id IN (m.player_a, m.player_b);
  END IF;

  RETURN public.duel_friend_state_json(m, uid);
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
  -- Tout ce que l'un ou l'autre a en mémoire (duel classé ou entre amis) est évité, les
  -- questions vues le plus récemment en tête de liste.
  SELECT coalesce(array_agg(x.id ORDER BY x.pos), '{}') INTO recent
    FROM public.duel_profiles dp
    CROSS JOIN LATERAL unnest(dp.recent_question_ids) WITH ORDINALITY AS x(id, pos)
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
