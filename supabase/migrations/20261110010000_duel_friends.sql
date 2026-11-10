-- Duels entre amis, profil d'ami enrichi, pénalité d'abandon.
--
-- 1. Abandon d'un duel classé : toujours 20 trophées de moins (jamais sous 0), sans faire
--    redescendre de ligue. Une défaite jouée jusqu'au bout garde ses protections.
-- 2. Présence : chaque app ouverte (en anglais, là où les duels existent) se signale toutes
--    les quelques secondes par duel_ping ; c'est la pastille verte, et c'est aussi par cette
--    réponse qu'une invitation arrive (l'app n'a pas de notifications push).
-- 3. Invitations : 15 secondes pour répondre.
-- 4. Partie entre amis : les deux joueurs reçoivent les mêmes 20 questions et répondent en
--    même temps. Le serveur tient l'horloge : une question est close quand les deux ont
--    répondu ou quand son temps est écoulé, puis la suivante démarre après la révélation.
--    Aucun trophée en jeu. Celui qui quitte a perdu ; l'autre finit la partie.
-- 5. Profil d'un ami : trophées, ligue, avatar, créateurs suivis, bilan des duels amicaux.

-- ---------- 1. abandon d'un duel classé ----------

CREATE OR REPLACE FUNCTION public.duel_apply_result(
  p_match_id uuid,
  p_won boolean,
  p_player_score int,
  p_opponent_score int,
  p_tiebreak boolean,
  p_answers jsonb,
  p_abandoned boolean,
  p_accuracy numeric
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  m public.duel_matches;
  prof public.duel_profiles;
  delta int;
  league_floor int;
BEGIN
  SELECT * INTO m FROM public.duel_matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;
  IF m.status <> 'active' THEN
    RETURN public.duel_match_result_json(m);
  END IF;

  prof := public.duel_ensure_profile(m.user_id);
  IF p_abandoned THEN
    -- Quitter coûte 20 trophées, même dans les premières ligues, sans descendre sous le
    -- seuil de la ligue où l'on se trouve.
    SELECT coalesce(max(l.min_trophies), 0) INTO league_floor
      FROM public.duel_leagues l WHERE l.min_trophies <= prof.trophies;
    delta := greatest(prof.trophies - 20, league_floor) - prof.trophies;
  ELSE
    delta := public.duel_trophy_delta(p_won, prof.trophies, (m.opponent ->> 'trophies')::int, prof.best_trophies);
  END IF;

  UPDATE public.duel_profiles SET
    trophies = prof.trophies + delta,
    best_trophies = greatest(prof.best_trophies, prof.trophies + delta),
    games = prof.games + 1,
    wins = prof.wins + CASE WHEN p_won THEN 1 ELSE 0 END,
    losses = prof.losses + CASE WHEN p_won THEN 0 ELSE 1 END,
    win_streak = CASE WHEN p_won THEN prof.win_streak + 1 ELSE 0 END,
    best_win_streak = greatest(prof.best_win_streak, CASE WHEN p_won THEN prof.win_streak + 1 ELSE 0 END),
    loss_streak = CASE WHEN p_won THEN 0 ELSE prof.loss_streak + 1 END,
    accuracy = CASE WHEN p_accuracy IS NULL THEN prof.accuracy
      ELSE round(greatest(0.20, least(0.98, 0.7 * prof.accuracy + 0.3 * p_accuracy)), 3) END,
    level = CASE WHEN p_accuracy IS NULL THEN prof.level
      ELSE round(greatest(1, least(8, prof.level + greatest(-0.75, least(0.75, (p_accuracy - 0.62) * 2.5)))), 2) END,
    updated_at = now()
  WHERE user_id = m.user_id;

  UPDATE public.duel_matches SET
    status = CASE WHEN p_abandoned THEN 'abandoned' WHEN p_won THEN 'won' ELSE 'lost' END,
    player_score = p_player_score,
    opponent_score = p_opponent_score,
    tiebreak = coalesce(p_tiebreak, false),
    answers = p_answers,
    trophies_before = prof.trophies,
    trophies_delta = delta,
    trophies_after = prof.trophies + delta,
    finished_at = now()
  WHERE id = p_match_id
  RETURNING * INTO m;

  RETURN public.duel_match_result_json(m);
END;
$$;

REVOKE ALL ON FUNCTION public.duel_apply_result(uuid, boolean, int, int, boolean, jsonb, boolean, numeric) FROM PUBLIC, anon, authenticated;

-- ---------- tables ----------

CREATE TABLE IF NOT EXISTS public.duel_presence (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  lang text NOT NULL DEFAULT 'en',
  -- En pleine partie : une invitation reçue est refusée d'office (« occupé »).
  busy boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS public.duel_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invitee_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined', 'busy', 'cancelled', 'expired')),
  match_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  CONSTRAINT duel_invites_not_self CHECK (inviter_id <> invitee_id)
);

CREATE INDEX IF NOT EXISTS duel_invites_invitee_pending_idx
  ON public.duel_invites (invitee_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS duel_invites_inviter_idx
  ON public.duel_invites (inviter_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.duel_friend_matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- player_a a lancé l'invitation, player_b l'a acceptée.
  player_a uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  player_b uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question_ids text[] NOT NULL,
  tiebreak_id text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'finished')),
  -- La question en cours (0 à 19, 20 pour la question décisive) et l'instant où elle démarre :
  -- dans le futur tant que la révélation de la précédente (ou le compte à rebours) dure.
  current_index int NOT NULL DEFAULT 0,
  question_started_at timestamptz NOT NULL,
  -- Une case par question, dans l'ordre : null tant que le joueur n'a pas répondu, puis
  -- {"c": index choisi ou null, "v": valeur du curseur ou null, "t": temps en ms}.
  answers_a jsonb NOT NULL,
  answers_b jsonb NOT NULL,
  score_a int NOT NULL DEFAULT 0,
  score_b int NOT NULL DEFAULT 0,
  -- Une case par question close : le joueur a-t-il marqué ? (question décisive : l'a-t-il gagnée ?)
  points_a jsonb NOT NULL DEFAULT '[]'::jsonb,
  points_b jsonb NOT NULL DEFAULT '[]'::jsonb,
  tiebreak boolean NOT NULL DEFAULT false,
  left_a boolean NOT NULL DEFAULT false,
  left_b boolean NOT NULL DEFAULT false,
  winner uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz
);

CREATE INDEX IF NOT EXISTS duel_friend_matches_a_idx ON public.duel_friend_matches (player_a, created_at DESC);
CREATE INDEX IF NOT EXISTS duel_friend_matches_b_idx ON public.duel_friend_matches (player_b, created_at DESC);

ALTER TABLE public.duel_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duel_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duel_friend_matches ENABLE ROW LEVEL SECURITY;

-- Aucune policy : seules les fonctions ci-dessous y touchent.
REVOKE ALL ON TABLE public.duel_presence FROM anon, authenticated;
REVOKE ALL ON TABLE public.duel_invites FROM anon, authenticated;
REVOKE ALL ON TABLE public.duel_friend_matches FROM anon, authenticated;

-- ---------- helpers internes ----------

-- Un joueur est « en ligne » s'il s'est signalé dans les 20 dernières secondes.
CREATE OR REPLACE FUNCTION public.duel_is_online(p_uid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.duel_presence pr
    WHERE pr.user_id = p_uid AND pr.last_seen_at > now() - interval '20 seconds'
  );
$$;

-- Un joueur peut être défié si son app a les duels (elle s'est signalée en anglais).
CREATE OR REPLACE FUNCTION public.duel_can_challenge(p_uid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.duel_presence pr WHERE pr.user_id = p_uid AND pr.lang = 'en'
  );
$$;

-- Durée de la révélation des réponses avant la question suivante (ms).
CREATE OR REPLACE FUNCTION public.duel_friend_reveal_ms(p_kind text)
RETURNS int
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE WHEN p_kind = 'slider' THEN 3600 ELSE 2800 END;
$$;

-- Le joueur tel que son adversaire le voit.
CREATE OR REPLACE FUNCTION public.duel_player_card(p_uid uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT jsonb_build_object(
    'user_id', p.id,
    'handle', p.handle,
    'country_code', '',
    'avatar_id', up.progress ->> 'avatarId',
    'trophies', coalesce(dp.trophies, 0),
    'league_position', public.duel_league_position(coalesce(dp.trophies, 0))
  )
  FROM public.profiles p
  LEFT JOIN public.user_progress up ON up.user_id = p.id
  LEFT JOIN public.duel_profiles dp ON dp.user_id = p.id
  WHERE p.id = p_uid;
$$;

-- Fait avancer une partie entre amis jusqu'à l'instant présent : clôt la question en cours si
-- les deux joueurs ont répondu (un joueur parti est réputé avoir répondu) ou si son temps est
-- écoulé, compte les points, programme la suivante, et termine la partie après la dernière.
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
    time_limit := public.duel_time_limit_ms(q.kind);
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
        m.question_started_at := resolved_at + public.duel_friend_reveal_ms(q.kind) * interval '1 millisecond';
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

-- L'état d'une partie entre amis, vu par l'un des deux joueurs.
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
    'opponent_left', CASE WHEN is_a THEN m.left_b ELSE m.left_a END,
    'won', m.status = 'finished' AND coalesce(m.winner = p_uid, false),
    'draw', m.status = 'finished' AND m.winner IS NULL
  );
END;
$$;

-- Ce que chaque joueur reçoit au lancement d'une partie entre amis.
CREATE OR REPLACE FUNCTION public.duel_friend_start_json(m public.duel_friend_matches, p_uid uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  questions jsonb;
  tiebreak jsonb;
BEGIN
  SELECT jsonb_agg(public.duel_question_json(q) ORDER BY t.ord)
    INTO questions
    FROM unnest(m.question_ids) WITH ORDINALITY AS t(id, ord)
    JOIN public.duel_questions q ON q.id = t.id;
  SELECT public.duel_question_json(q) INTO tiebreak
    FROM public.duel_questions q WHERE q.id = m.tiebreak_id;

  RETURN jsonb_build_object(
    'match_id', m.id,
    'me', public.duel_player_card(p_uid),
    'opponent', public.duel_player_card(CASE WHEN m.player_a = p_uid THEN m.player_b ELSE m.player_a END),
    'questions', questions,
    'tiebreak', tiebreak,
    'starts_in_ms', round(extract(epoch FROM (m.question_started_at - clock_timestamp())) * 1000)::bigint
  );
END;
$$;

-- ---------- RPC : présence et invitations ----------

-- Appelée toutes les quelques secondes par une app ouverte : « je suis là », et en retour
-- l'invitation en attente s'il y en a une. `p_busy` : le joueur est en pleine partie, une
-- invitation est alors refusée d'office.
CREATE OR REPLACE FUNCTION public.duel_ping(p_lang text DEFAULT 'en', p_busy boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  inv public.duel_invites;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Une écriture toutes les 8 secondes suffit à tenir la pastille verte.
  INSERT INTO public.duel_presence (user_id, last_seen_at, lang, busy)
  VALUES (uid, now(), coalesce(p_lang, 'en'), coalesce(p_busy, false))
  ON CONFLICT (user_id) DO UPDATE SET
    last_seen_at = EXCLUDED.last_seen_at,
    lang = EXCLUDED.lang,
    busy = EXCLUDED.busy
  WHERE duel_presence.last_seen_at < now() - interval '8 seconds'
     OR duel_presence.lang IS DISTINCT FROM EXCLUDED.lang
     OR duel_presence.busy IS DISTINCT FROM EXCLUDED.busy;

  SELECT * INTO inv
    FROM public.duel_invites i
    WHERE i.invitee_id = uid AND i.status = 'pending' AND i.expires_at > now()
    ORDER BY i.created_at
    LIMIT 1
    FOR UPDATE SKIP LOCKED;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('invite', NULL);
  END IF;

  IF coalesce(p_busy, false) THEN
    UPDATE public.duel_invites SET status = 'busy' WHERE id = inv.id;
    RETURN jsonb_build_object('invite', NULL);
  END IF;

  RETURN jsonb_build_object('invite', jsonb_build_object(
    'invite_id', inv.id,
    'from', public.duel_player_card(inv.inviter_id),
    'expires_in_ms', round(extract(epoch FROM (inv.expires_at - clock_timestamp())) * 1000)::bigint
  ));
END;
$$;

-- Le joueur quitte l'app : il n'est plus « en ligne ».
CREATE OR REPLACE FUNCTION public.duel_go_offline()
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE public.duel_presence
    SET last_seen_at = now() - interval '1 hour', busy = false
    WHERE user_id = auth.uid();
END;
$$;

-- Défie un ami : il a 15 secondes pour répondre.
CREATE OR REPLACE FUNCTION public.duel_invite_friend(p_friend uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  new_id uuid;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  IF p_friend IS NULL OR p_friend = uid OR NOT public.are_friends(uid, p_friend) THEN
    RAISE EXCEPTION 'not_friends';
  END IF;
  IF NOT public.duel_can_challenge(p_friend) THEN
    RAISE EXCEPTION 'friend_unavailable';
  END IF;

  -- Une seule invitation à la fois par joueur : la précédente tombe.
  UPDATE public.duel_invites SET status = 'cancelled'
    WHERE inviter_id = uid AND status = 'pending';
  UPDATE public.duel_invites SET status = 'expired'
    WHERE invitee_id = p_friend AND status = 'pending' AND expires_at <= now();

  -- L'ami est déjà pris : en pleine partie, ou déjà devant une autre invitation.
  IF EXISTS (
       SELECT 1 FROM public.duel_presence pr
       WHERE pr.user_id = p_friend AND pr.busy AND pr.last_seen_at > now() - interval '20 seconds')
     OR EXISTS (
       SELECT 1 FROM public.duel_invites i
       WHERE i.invitee_id = p_friend AND i.status = 'pending')
  THEN
    RAISE EXCEPTION 'friend_busy';
  END IF;

  INSERT INTO public.duel_invites (inviter_id, invitee_id, expires_at)
  VALUES (uid, p_friend, now() + interval '15 seconds')
  RETURNING id INTO new_id;

  RETURN jsonb_build_object(
    'invite_id', new_id,
    'expires_in_ms', 15000,
    'me', public.duel_player_card(uid),
    'friend', public.duel_player_card(p_friend),
    'online', public.duel_is_online(p_friend)
  );
END;
$$;

-- Où en est l'invitation que j'ai envoyée ; la partie à lancer dès qu'elle est acceptée.
CREATE OR REPLACE FUNCTION public.duel_invite_status(p_invite uuid)
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
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  SELECT * INTO inv FROM public.duel_invites WHERE id = p_invite AND inviter_id = uid FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_not_found';
  END IF;

  -- 2 s de marge : une acceptation de dernière seconde est peut-être en route.
  IF inv.status = 'pending' AND now() > inv.expires_at + interval '2 seconds' THEN
    UPDATE public.duel_invites SET status = 'expired' WHERE id = inv.id RETURNING * INTO inv;
  END IF;

  IF inv.status = 'accepted' AND inv.match_id IS NOT NULL THEN
    SELECT * INTO m FROM public.duel_friend_matches WHERE id = inv.match_id;
    RETURN jsonb_build_object('status', inv.status, 'match', public.duel_friend_start_json(m, uid));
  END IF;
  RETURN jsonb_build_object('status', inv.status, 'match', NULL);
END;
$$;

CREATE OR REPLACE FUNCTION public.duel_invite_cancel(p_invite uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE public.duel_invites SET status = 'cancelled'
    WHERE id = p_invite AND inviter_id = auth.uid() AND status = 'pending';
END;
$$;

-- Réponse à une invitation reçue. Acceptée : la partie est créée, avec 20 questions tirées
-- au niveau moyen des deux joueurs, et démarre 5 secondes plus tard pour les deux.
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

  WITH scored AS (
    SELECT q.id, q.kind,
      row_number() OVER (PARTITION BY q.kind ORDER BY abs(q.level - avg_level) + random() * 1.6) AS rn
    FROM public.duel_questions q
    WHERE q.active AND q.lang = 'en'
  ),
  picked AS (
    SELECT s.id, s.kind, s.rn
    FROM scored s
    WHERE (s.kind = 'mcq' AND s.rn <= 9)
       OR (s.kind = 'true_false' AND s.rn <= 4)
       OR (s.kind = 'portrait' AND s.rn <= 4)
       OR (s.kind = 'slider' AND s.rn <= 4)
  )
  SELECT
    array_agg(p.id ORDER BY random()) FILTER (WHERE NOT (p.kind = 'slider' AND p.rn = 4)),
    max(p.id) FILTER (WHERE p.kind = 'slider' AND p.rn = 4)
  INTO q_ids, tb_id
  FROM picked p;

  IF coalesce(array_length(q_ids, 1), 0) < 20 OR tb_id IS NULL THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;

  SELECT jsonb_agg('null'::jsonb) INTO empty_answers FROM generate_series(1, array_length(q_ids, 1) + 1);

  INSERT INTO public.duel_friend_matches (player_a, player_b, question_ids, tiebreak_id, question_started_at, answers_a, answers_b)
  VALUES (inv.inviter_id, uid, q_ids, tb_id, now() + interval '5 seconds', empty_answers, empty_answers)
  RETURNING * INTO m;

  UPDATE public.duel_invites SET status = 'accepted', match_id = m.id WHERE id = inv.id;

  RETURN jsonb_build_object('status', 'accepted', 'match', public.duel_friend_start_json(m, uid));
END;
$$;

-- ---------- RPC : la partie entre amis ----------

CREATE OR REPLACE FUNCTION public.duel_friend_state(p_match uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  m public.duel_friend_matches;
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
  RETURN public.duel_friend_state_json(m, uid);
END;
$$;

-- Ma réponse à la question en cours : {"c": index ou null, "v": valeur ou null, "t": ms}.
-- Une réponse pour une autre question que celle en cours est ignorée.
CREATE OR REPLACE FUNCTION public.duel_friend_answer(p_match uuid, p_index int, p_answer jsonb)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  m public.duel_friend_matches;
  is_a boolean;
  answer jsonb;
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
  is_a := m.player_a = uid;

  IF m.status = 'active'
     AND p_index = m.current_index
     AND now() >= m.question_started_at - interval '500 milliseconds'
     AND jsonb_typeof(CASE WHEN is_a THEN m.answers_a ELSE m.answers_b END -> p_index) IS DISTINCT FROM 'object'
  THEN
    answer := jsonb_build_object(
      'c', (p_answer ->> 'c')::int,
      'v', (p_answer ->> 'v')::numeric,
      't', greatest(coalesce((p_answer ->> 't')::int, 0), 0)
    );
    IF is_a THEN
      UPDATE public.duel_friend_matches
        SET answers_a = jsonb_set(answers_a, ARRAY[p_index::text], answer) WHERE id = p_match;
    ELSE
      UPDATE public.duel_friend_matches
        SET answers_b = jsonb_set(answers_b, ARRAY[p_index::text], answer) WHERE id = p_match;
    END IF;
    m := public.duel_friend_advance(p_match);
  END IF;

  RETURN public.duel_friend_state_json(m, uid);
END;
$$;

-- Je quitte la partie : j'ai perdu ; mon ami la finit seul, sans attendre mes réponses.
CREATE OR REPLACE FUNCTION public.duel_friend_leave(p_match uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  m public.duel_friend_matches;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  SELECT * INTO m FROM public.duel_friend_matches
    WHERE id = p_match AND uid IN (player_a, player_b) FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;

  IF m.status = 'active' THEN
    UPDATE public.duel_friend_matches SET
      left_a = left_a OR player_a = uid,
      left_b = left_b OR player_b = uid
    WHERE id = p_match
    RETURNING * INTO m;
    IF m.left_a AND m.left_b THEN
      -- Plus personne : la partie s'arrête là, sans vainqueur.
      UPDATE public.duel_friend_matches SET status = 'finished', finished_at = now()
        WHERE id = p_match RETURNING * INTO m;
    ELSE
      m := public.duel_friend_advance(p_match);
    END IF;
  END IF;

  RETURN public.duel_friend_state_json(m, uid);
END;
$$;

-- ---------- RPC : amis ----------

-- Le classement des trophées entre amis gagne deux colonnes : en ligne, et défiable.
DROP FUNCTION IF EXISTS public.duel_friends_leaderboard();
CREATE FUNCTION public.duel_friends_leaderboard()
RETURNS TABLE (
  user_id uuid,
  handle text,
  avatar_id text,
  trophies int,
  league_position int,
  is_me boolean,
  online boolean,
  can_challenge boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  RETURN QUERY
  WITH cohort AS (
    SELECT uid AS id
    UNION
    SELECT CASE WHEN f.user_id = uid THEN f.friend_id ELSE f.user_id END
    FROM public.friendships f
    WHERE f.user_id = uid OR f.friend_id = uid
  )
  SELECT
    c.id,
    p.handle,
    up.progress ->> 'avatarId',
    coalesce(dp.trophies, 0),
    public.duel_league_position(coalesce(dp.trophies, 0)),
    c.id = uid,
    c.id <> uid AND public.duel_is_online(c.id),
    c.id <> uid AND public.duel_can_challenge(c.id)
  FROM cohort c
  JOIN public.profiles p ON p.id = c.id
  LEFT JOIN public.user_progress up ON up.user_id = c.id
  LEFT JOIN public.duel_profiles dp ON dp.user_id = c.id
  ORDER BY coalesce(dp.trophies, 0) DESC, p.handle;
END;
$$;

-- Le profil d'un ami : ce que friend_public_stats donnait déjà (XP, série, cours et quiz
-- terminés), plus son avatar, ses trophées et sa ligue, les créateurs qu'il suit, sa présence
-- et le bilan de nos duels amicaux.
CREATE OR REPLACE FUNCTION public.friend_profile(target uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  prog jsonb;
  dp public.duel_profiles;
  target_handle text;
  follows jsonb;
  played int;
  won int;
  lost int;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  IF target <> uid AND NOT public.are_friends(uid, target) THEN
    RAISE EXCEPTION 'not_friends';
  END IF;

  SELECT p.handle INTO target_handle FROM public.profiles p WHERE p.id = target;
  IF target_handle IS NULL THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;
  SELECT coalesce(up.progress, '{}'::jsonb) INTO prog FROM public.user_progress up WHERE up.user_id = target;
  prog := coalesce(prog, '{}'::jsonb);
  SELECT * INTO dp FROM public.duel_profiles x WHERE x.user_id = target;

  SELECT coalesce(jsonb_agg(f.creator_slug ORDER BY f.followed_at DESC), '[]'::jsonb)
    INTO follows
    FROM public.follows f WHERE f.user_id = target;

  SELECT count(*), count(*) FILTER (WHERE fm.winner = uid), count(*) FILTER (WHERE fm.winner = target)
    INTO played, won, lost
    FROM public.duel_friend_matches fm
    WHERE fm.status = 'finished'
      AND ((fm.player_a = uid AND fm.player_b = target) OR (fm.player_a = target AND fm.player_b = uid));

  RETURN jsonb_build_object(
    'user_id', target,
    'handle', target_handle,
    'avatar_id', prog ->> 'avatarId',
    'global_xp', coalesce((prog ->> 'globalXP')::int, 0),
    'streak', coalesce((prog ->> 'streak')::int, 0),
    'courses_completed', coalesce((
      SELECT count(*)::int
      FROM jsonb_each(coalesce(prog -> 'courseProgress', '{}'::jsonb)) AS cp(key, value)
      WHERE (cp.value ->> 'isCompleted')::boolean IS TRUE
    ), 0),
    'quizzes_completed', coalesce(jsonb_array_length(coalesce(prog -> 'completedQuizCourseIds', '[]'::jsonb)), 0),
    'trophies', coalesce(dp.trophies, 0),
    'best_trophies', coalesce(dp.best_trophies, 0),
    'league_position', public.duel_league_position(coalesce(dp.trophies, 0)),
    'duel_games', coalesce(dp.games, 0),
    'duel_wins', coalesce(dp.wins, 0),
    'follows', follows,
    'online', target <> uid AND public.duel_is_online(target),
    'can_challenge', target <> uid AND public.duel_can_challenge(target),
    'friendly_played', played,
    'friendly_won', won,
    'friendly_lost', lost
  );
END;
$$;

-- ---------- droits d'exécution ----------

REVOKE ALL ON FUNCTION public.duel_is_online(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_can_challenge(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_reveal_ms(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_player_card(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_advance(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_state_json(public.duel_friend_matches, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_start_json(public.duel_friend_matches, uuid) FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.duel_ping(text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_ping(text, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_go_offline() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_go_offline() TO authenticated;
REVOKE ALL ON FUNCTION public.duel_invite_friend(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_invite_friend(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_invite_status(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_invite_status(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_invite_cancel(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_invite_cancel(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_invite_respond(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_invite_respond(uuid, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_state(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_friend_state(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_answer(uuid, int, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_friend_answer(uuid, int, jsonb) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_friend_leave(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_friend_leave(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_friends_leaderboard() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_friends_leaderboard() TO authenticated;
REVOKE ALL ON FUNCTION public.friend_profile(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.friend_profile(uuid) TO authenticated;
