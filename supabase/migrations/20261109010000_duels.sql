-- Duels : ligues, questions, adversaires simulés, profils de duel, parties, et les RPC que
-- l'app appelle (duel_home, duel_start_match, duel_finish_match, duel_friends_leaderboard).
--
-- Tout le calcul est côté serveur : tirage de l'adversaire et des 20 questions (+ 1 question
-- décisive), script de réponses de l'adversaire, score, trophées, ligue, statistiques, niveau
-- caché du joueur. L'app n'a aucun accès direct aux tables de questions, d'adversaires, de
-- profils ni de parties : elle passe par les fonctions SECURITY DEFINER ci-dessous.
-- Le contenu (ligues, adversaires, questions) est posé par 20261109010100_duels_seed.sql.

-- ---------- tables ----------

CREATE TABLE IF NOT EXISTS public.duel_leagues (
  position int PRIMARY KEY CHECK (position >= 1),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  min_trophies int NOT NULL UNIQUE CHECK (min_trophies >= 0),
  background_url text NOT NULL,
  thumb_url text NOT NULL,
  accent_hex text NOT NULL DEFAULT '#1A3A6B'
);

CREATE TABLE IF NOT EXISTS public.duel_questions (
  id text PRIMARY KEY,
  lang text NOT NULL DEFAULT 'en',
  level int NOT NULL CHECK (level BETWEEN 1 AND 8),
  kind text NOT NULL CHECK (kind IN ('mcq', 'true_false', 'portrait', 'slider')),
  subject text NOT NULL,
  question text NOT NULL,
  options jsonb,
  correct_index int,
  image_url text,
  image_credit text,
  slider_min numeric,
  slider_max numeric,
  slider_step numeric,
  correct_value numeric,
  unit text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT duel_questions_choice_shape CHECK (
    kind = 'slider'
    OR (
      jsonb_typeof(options) = 'array'
      AND jsonb_array_length(options) BETWEEN 2 AND 4
      AND correct_index >= 0
      AND correct_index < jsonb_array_length(options)
    )
  ),
  CONSTRAINT duel_questions_slider_shape CHECK (
    kind <> 'slider'
    OR (
      slider_min < slider_max
      AND slider_step > 0
      AND correct_value BETWEEN slider_min AND slider_max
    )
  ),
  CONSTRAINT duel_questions_portrait_image CHECK (kind <> 'portrait' OR image_url IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS duel_questions_pick_idx
  ON public.duel_questions (lang, kind, level) WHERE active;

CREATE TABLE IF NOT EXISTS public.duel_bots (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  handle text NOT NULL UNIQUE,
  country_code text NOT NULL CHECK (country_code ~ '^[A-Z]{2}$'),
  avatar_id text,
  active boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.duel_profiles (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  trophies int NOT NULL DEFAULT 0 CHECK (trophies >= 0),
  best_trophies int NOT NULL DEFAULT 0,
  games int NOT NULL DEFAULT 0,
  wins int NOT NULL DEFAULT 0,
  losses int NOT NULL DEFAULT 0,
  win_streak int NOT NULL DEFAULT 0,
  best_win_streak int NOT NULL DEFAULT 0,
  loss_streak int NOT NULL DEFAULT 0,
  -- Niveau caché (1 à 8) qui choisit la difficulté des questions, et précision lissée
  -- du joueur sur les questions à choix, qui règle la force de l'adversaire.
  level numeric(4, 2) NOT NULL DEFAULT 2.5,
  accuracy numeric(4, 3) NOT NULL DEFAULT 0.62,
  recent_question_ids text[] NOT NULL DEFAULT '{}',
  recent_bot_ids int[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.duel_matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  bot_id int REFERENCES public.duel_bots(id) ON DELETE SET NULL,
  opponent jsonb NOT NULL,
  question_ids text[] NOT NULL,
  tiebreak_id text NOT NULL,
  bot_script jsonb NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'won', 'lost', 'abandoned')),
  player_score int,
  opponent_score int,
  tiebreak boolean NOT NULL DEFAULT false,
  answers jsonb,
  trophies_before int,
  trophies_delta int,
  trophies_after int,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz
);

CREATE INDEX IF NOT EXISTS duel_matches_user_started_idx
  ON public.duel_matches (user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS duel_matches_active_idx
  ON public.duel_matches (user_id) WHERE status = 'active';

-- ---------- accès ----------

ALTER TABLE public.duel_leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duel_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duel_bots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duel_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duel_matches ENABLE ROW LEVEL SECURITY;

-- Les ligues sont publiques (noms, seuils, images). Tout le reste n'a aucune policy :
-- seules les fonctions ci-dessous (et le rôle de service) y touchent.
DROP POLICY IF EXISTS duel_leagues_read ON public.duel_leagues;
CREATE POLICY duel_leagues_read ON public.duel_leagues
  FOR SELECT TO anon, authenticated USING (true);

REVOKE ALL ON TABLE public.duel_leagues FROM anon, authenticated;
GRANT SELECT ON TABLE public.duel_leagues TO anon, authenticated;
REVOKE ALL ON TABLE public.duel_questions FROM anon, authenticated;
REVOKE ALL ON TABLE public.duel_bots FROM anon, authenticated;
REVOKE ALL ON TABLE public.duel_profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.duel_matches FROM anon, authenticated;

-- ---------- helpers internes ----------

CREATE OR REPLACE FUNCTION public.duel_league_position(p_trophies int)
RETURNS int
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT coalesce(max(l.position), 1)
  FROM public.duel_leagues l
  WHERE l.min_trophies <= greatest(coalesce(p_trophies, 0), 0);
$$;

-- Temps accordé par type de question (ms).
CREATE OR REPLACE FUNCTION public.duel_time_limit_ms(p_kind text)
RETURNS int
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE p_kind
    WHEN 'true_false' THEN 8000
    WHEN 'portrait' THEN 10000
    WHEN 'slider' THEN 15000
    ELSE 12000
  END;
$$;

-- Façon Clash Royale : +25 à +35 pour une victoire, -15 à -25 pour une défaite selon
-- l'écart de trophées ; aucune perte avant la 5e ligue, et on ne redescend jamais sous
-- le seuil de la meilleure ligue atteinte.
CREATE OR REPLACE FUNCTION public.duel_trophy_delta(p_won boolean, p_mine int, p_theirs int, p_best int)
RETURNS int
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  diff int := greatest(-5, least(5, round((coalesce(p_theirs, p_mine) - p_mine) / 20.0)::int));
  safe_below int;
  floor_trophies int;
BEGIN
  IF p_won THEN
    RETURN 30 + diff;
  END IF;
  SELECT coalesce((SELECT l.min_trophies FROM public.duel_leagues l WHERE l.position = 5), 400)
    INTO safe_below;
  IF p_mine < safe_below THEN
    RETURN 0;
  END IF;
  SELECT coalesce(max(l.min_trophies), 0)
    INTO floor_trophies
    FROM public.duel_leagues l
    WHERE l.min_trophies <= greatest(p_best, p_mine);
  RETURN greatest(p_mine - (20 - diff), floor_trophies) - p_mine;
END;
$$;

CREATE OR REPLACE FUNCTION public.duel_question_json(q public.duel_questions)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT jsonb_build_object(
    'id', q.id,
    'kind', q.kind,
    'question', q.question,
    'options', q.options,
    'correct_index', q.correct_index,
    'image_url', q.image_url,
    'image_credit', q.image_credit,
    'slider_min', q.slider_min,
    'slider_max', q.slider_max,
    'slider_step', q.slider_step,
    'correct_value', q.correct_value,
    'unit', q.unit,
    'time_limit_ms', public.duel_time_limit_ms(q.kind)
  );
$$;

-- La réponse de l'adversaire à une question : juste ou non, son choix (ou sa valeur
-- au curseur) et son temps de réponse.
CREATE OR REPLACE FUNCTION public.duel_bot_answer(q public.duel_questions, p_accuracy numeric, p_level numeric)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  time_limit int := public.duel_time_limit_ms(q.kind);
  p numeric;
  is_correct boolean;
  n int;
  choice int;
  spread numeric;
  noise numeric;
  val numeric;
BEGIN
  IF q.kind = 'slider' THEN
    spread := (q.slider_max - q.slider_min) * (0.08 + 0.60 * (1 - p_accuracy));
    noise := (random() + random() + random() - 1.5) / 1.5;
    val := q.correct_value + spread * noise;
    val := q.slider_min + round((val - q.slider_min) / q.slider_step) * q.slider_step;
    val := greatest(q.slider_min, least(q.slider_max, val));
    RETURN jsonb_build_object(
      'correct', val = q.correct_value,
      'choice', NULL,
      'value', val,
      'time_ms', round(time_limit * (0.35 + 0.50 * random()))::int
    );
  END IF;

  p := p_accuracy + (p_level - q.level) * 0.04;
  IF q.kind = 'true_false' THEN
    p := p + 0.08;
  END IF;
  p := greatest(0.10, least(0.97, p));
  is_correct := random() < p;
  n := jsonb_array_length(q.options);
  IF is_correct THEN
    choice := q.correct_index;
  ELSE
    choice := (q.correct_index + 1 + floor(random() * (n - 1))::int) % n;
  END IF;
  RETURN jsonb_build_object(
    'correct', is_correct,
    'choice', choice,
    'value', NULL,
    'time_ms', round(time_limit * (0.20 + 0.60 * random()))::int
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.duel_profile_json(p public.duel_profiles)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT jsonb_build_object(
    'trophies', p.trophies,
    'best_trophies', p.best_trophies,
    'games', p.games,
    'wins', p.wins,
    'losses', p.losses,
    'win_streak', p.win_streak,
    'best_win_streak', p.best_win_streak,
    'league_position', public.duel_league_position(p.trophies)
  );
$$;

CREATE OR REPLACE FUNCTION public.duel_ensure_profile(p_uid uuid)
RETURNS public.duel_profiles
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  prof public.duel_profiles;
BEGIN
  INSERT INTO public.duel_profiles (user_id) VALUES (p_uid)
  ON CONFLICT (user_id) DO NOTHING;
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = p_uid FOR UPDATE;
  RETURN prof;
END;
$$;

CREATE OR REPLACE FUNCTION public.duel_match_result_json(m public.duel_matches)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  prof public.duel_profiles;
BEGIN
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = m.user_id;
  RETURN jsonb_build_object(
    'match_id', m.id,
    'won', m.status = 'won',
    'abandoned', m.status = 'abandoned',
    'player_score', coalesce(m.player_score, 0),
    'opponent_score', coalesce(m.opponent_score, 0),
    'tiebreak', m.tiebreak,
    'trophies_before', coalesce(m.trophies_before, 0),
    'trophies_delta', coalesce(m.trophies_delta, 0),
    'trophies_after', coalesce(m.trophies_after, 0),
    'league_before', public.duel_league_position(m.trophies_before),
    'league_after', public.duel_league_position(m.trophies_after),
    'profile', public.duel_profile_json(prof)
  );
END;
$$;

-- Clôt une partie : trophées, statistiques, séries, niveau caché. `p_accuracy` est la part
-- de bonnes réponses du joueur aux questions à choix (NULL pour un abandon : le niveau et la
-- précision ne bougent pas).
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
BEGIN
  SELECT * INTO m FROM public.duel_matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;
  IF m.status <> 'active' THEN
    RETURN public.duel_match_result_json(m);
  END IF;

  prof := public.duel_ensure_profile(m.user_id);
  delta := public.duel_trophy_delta(p_won, prof.trophies, (m.opponent ->> 'trophies')::int, prof.best_trophies);

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

-- Une partie laissée en plan (app fermée en plein duel) compte comme une défaite.
CREATE OR REPLACE FUNCTION public.duel_resolve_stale(p_uid uuid, p_min_age interval)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  stale uuid;
BEGIN
  FOR stale IN
    SELECT id FROM public.duel_matches
    WHERE user_id = p_uid AND status = 'active' AND started_at <= now() - p_min_age
    ORDER BY started_at
  LOOP
    PERFORM public.duel_apply_result(stale, false, 0, 0, false, NULL, true, NULL);
  END LOOP;
END;
$$;

-- ---------- RPC appelées par l'app ----------

-- La page Duels : profil (trophées, statistiques, ligue), les ligues, les dernières parties.
CREATE OR REPLACE FUNCTION public.duel_home()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  prof public.duel_profiles;
  leagues jsonb;
  recent jsonb;
  my_handle text;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  PERFORM public.duel_ensure_profile(uid);
  PERFORM public.duel_resolve_stale(uid, interval '12 minutes');
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = uid;
  SELECT p.handle INTO my_handle FROM public.profiles p WHERE p.id = uid;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
      'position', l.position,
      'slug', l.slug,
      'name', l.name,
      'min_trophies', l.min_trophies,
      'background_url', l.background_url,
      'thumb_url', l.thumb_url,
      'accent_hex', l.accent_hex
    ) ORDER BY l.position), '[]'::jsonb)
    INTO leagues
    FROM public.duel_leagues l;

  SELECT coalesce(jsonb_agg(r.item ORDER BY r.finished_at DESC), '[]'::jsonb)
    INTO recent
    FROM (
      SELECT m.finished_at, jsonb_build_object(
        'match_id', m.id,
        'opponent', m.opponent,
        'won', m.status = 'won',
        'abandoned', m.status = 'abandoned',
        'player_score', coalesce(m.player_score, 0),
        'opponent_score', coalesce(m.opponent_score, 0),
        'trophies_delta', coalesce(m.trophies_delta, 0),
        'finished_at', m.finished_at
      ) AS item
      FROM public.duel_matches m
      WHERE m.user_id = uid AND m.status <> 'active'
      ORDER BY m.finished_at DESC
      LIMIT 10
    ) r;

  RETURN jsonb_build_object(
    'handle', my_handle,
    'profile', public.duel_profile_json(prof),
    'leagues', leagues,
    'recent', recent
  );
END;
$$;

-- Lance une partie : tire un adversaire, 20 questions au niveau du joueur et une question
-- décisive, et écrit d'avance les réponses de l'adversaire.
CREATE OR REPLACE FUNCTION public.duel_start_match()
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
  q_ids text[];
  tb_id text;
  questions jsonb;
  tiebreak jsonb;
  script jsonb;
  new_id uuid;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  prof := public.duel_ensure_profile(uid);
  PERFORM public.duel_resolve_stale(uid, interval '0 seconds');
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = uid FOR UPDATE;

  -- L'adversaire : un profil pas croisé récemment, à quelques dizaines de trophées près.
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

  -- Sa force : très accessible les trois premières parties, puis calée juste sous la
  -- précision du joueur ; elle monte avec les séries de victoires et la ligue, et baisse
  -- après des défaites.
  IF prof.games < 3 THEN
    bot_accuracy := greatest(0.25, prof.accuracy - 0.28);
  ELSE
    bot_accuracy := prof.accuracy - 0.035
      + 0.03 * least(prof.win_streak, 4)
      - 0.04 * least(prof.loss_streak, 3)
      + 0.004 * (public.duel_league_position(prof.trophies) - 1);
  END IF;
  bot_accuracy := greatest(0.20, least(0.95, bot_accuracy));

  -- Les questions : proches du niveau caché du joueur, en évitant celles vues récemment.
  -- 9 QCM, 4 vrai/faux, 4 portraits, 3 curseurs, et un 4e curseur gardé pour l'égalité.
  WITH scored AS (
    SELECT q.id, q.kind,
      row_number() OVER (
        PARTITION BY q.kind
        ORDER BY abs(q.level - prof.level) + random() * 1.2
          + CASE
              WHEN array_position(prof.recent_question_ids, q.id) IS NULL THEN 0
              WHEN array_position(prof.recent_question_ids, q.id) <= 21 THEN 4
              ELSE 2
            END
      ) AS rn
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

  SELECT jsonb_agg(public.duel_question_json(q) ORDER BY t.ord)
    INTO questions
    FROM unnest(q_ids) WITH ORDINALITY AS t(id, ord)
    JOIN public.duel_questions q ON q.id = t.id;

  SELECT public.duel_question_json(q) INTO tiebreak
    FROM public.duel_questions q WHERE q.id = tb_id;

  SELECT jsonb_agg(public.duel_bot_answer(q, bot_accuracy, prof.level) ORDER BY t.ord)
    INTO script
    FROM unnest(q_ids || tb_id) WITH ORDINALITY AS t(id, ord)
    JOIN public.duel_questions q ON q.id = t.id;

  INSERT INTO public.duel_matches (user_id, bot_id, opponent, question_ids, tiebreak_id, bot_script, trophies_before)
  VALUES (uid, bot.id, opponent, q_ids, tb_id, script, prof.trophies)
  RETURNING id INTO new_id;

  UPDATE public.duel_profiles SET
    recent_question_ids = ((q_ids || tb_id) || recent_question_ids)[1:60],
    recent_bot_ids = (bot.id || recent_bot_ids)[1:25],
    updated_at = now()
  WHERE user_id = uid;

  RETURN jsonb_build_object(
    'match_id', new_id,
    'opponent', opponent,
    'questions', questions,
    'tiebreak', tiebreak,
    'bot', script,
    'search_ms', 2600 + floor(random() * 3200)::int
  );
END;
$$;

-- Termine une partie. `p_answers` : un tableau, une entrée par question dans l'ordre
-- (la 21e est la question décisive), chacune {"c": index choisi ou null, "v": valeur du
-- curseur ou null, "t": temps de réponse en ms}. Le serveur recompte le score ; rappeler
-- la fonction pour une partie déjà close renvoie son résultat sans rien changer.
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

  IF player_score <> opponent_score THEN
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

-- Classement des trophées entre amis (moi + mes amis), avec l'avatar choisi par chacun.
CREATE OR REPLACE FUNCTION public.duel_friends_leaderboard()
RETURNS TABLE (
  user_id uuid,
  handle text,
  avatar_id text,
  trophies int,
  league_position int,
  is_me boolean
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
    c.id = uid
  FROM cohort c
  JOIN public.profiles p ON p.id = c.id
  LEFT JOIN public.user_progress up ON up.user_id = c.id
  LEFT JOIN public.duel_profiles dp ON dp.user_id = c.id
  ORDER BY coalesce(dp.trophies, 0) DESC, p.handle;
END;
$$;

-- ---------- droits d'exécution ----------

REVOKE ALL ON FUNCTION public.duel_league_position(int) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_time_limit_ms(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_trophy_delta(boolean, int, int, int) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_question_json(public.duel_questions) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_bot_answer(public.duel_questions, numeric, numeric) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_profile_json(public.duel_profiles) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_ensure_profile(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_match_result_json(public.duel_matches) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_apply_result(uuid, boolean, int, int, boolean, jsonb, boolean, numeric) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.duel_resolve_stale(uuid, interval) FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.duel_home() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_home() TO authenticated;
REVOKE ALL ON FUNCTION public.duel_start_match() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_start_match() TO authenticated;
REVOKE ALL ON FUNCTION public.duel_finish_match(uuid, jsonb, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_finish_match(uuid, jsonb, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.duel_friends_leaderboard() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_friends_leaderboard() TO authenticated;
