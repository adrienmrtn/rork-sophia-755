-- Handles (@), friendships, XP events, leaderboard RPCs
-- Applied remotely via Supabase MCP (project afnmcoovdvbtkgohtdij).

-- ---------- helpers ----------

CREATE OR REPLACE FUNCTION public.normalize_handle_base(raw text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  cleaned text;
BEGIN
  cleaned := lower(coalesce(raw, ''));
  cleaned := regexp_replace(cleaned, '[^a-z0-9]', '', 'g');
  IF length(cleaned) < 3 THEN
    RETURN NULL;
  END IF;
  RETURN left(cleaned, 20);
END;
$$;

CREATE OR REPLACE FUNCTION public.random_handle_base()
RETURNS text
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  alphabet constant text := 'abcdefghijklmnopqrstuvwxyz0123456789';
  result text := '';
  i int;
BEGIN
  result := substr(alphabet, 1 + floor(random() * 26)::int, 1);
  FOR i IN 1..7 LOOP
    result := result || substr(alphabet, 1 + floor(random() * 36)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.allocate_unique_handle(preferred_base text)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  base text;
  candidate text;
  suffix int := 1;
BEGIN
  base := public.normalize_handle_base(preferred_base);
  IF base IS NULL THEN
    base := public.random_handle_base();
  END IF;

  candidate := base;
  WHILE EXISTS (SELECT 1 FROM public.profiles p WHERE p.handle = candidate) LOOP
    candidate := base || suffix::text;
    suffix := suffix + 1;
    IF suffix > 10000 THEN
      base := public.random_handle_base();
      candidate := base;
      suffix := 1;
    END IF;
  END LOOP;

  RETURN candidate;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_from_email(email text)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  local_part text;
BEGIN
  IF email IS NULL OR btrim(email) = '' THEN
    RETURN public.allocate_unique_handle(NULL);
  END IF;

  IF email ILIKE '%@privaterelay.appleid.com' THEN
    RETURN public.allocate_unique_handle(NULL);
  END IF;

  local_part := split_part(email, '@', 1);
  RETURN public.allocate_unique_handle(local_part);
END;
$$;

-- ---------- profiles.handle ----------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS handle text;

UPDATE public.profiles
SET handle = public.handle_from_email(email)
WHERE handle IS NULL OR btrim(handle) = '';

ALTER TABLE public.profiles
  ALTER COLUMN handle SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_handle_key ON public.profiles (handle);

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_handle_format_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_handle_format_check
  CHECK (handle ~ '^[a-z][a-z0-9]{2,19}$');

COMMENT ON COLUMN public.profiles.handle IS 'Unique public @handle for the user.';

-- ---------- friendships ----------

CREATE TABLE IF NOT EXISTS public.friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  friend_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT friendships_not_self CHECK (user_id <> friend_id),
  CONSTRAINT friendships_ordered_pair CHECK (user_id < friend_id),
  CONSTRAINT friendships_unique_pair UNIQUE (user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS friendships_user_id_idx ON public.friendships (user_id);
CREATE INDEX IF NOT EXISTS friendships_friend_id_idx ON public.friendships (friend_id);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS friendships_select_own ON public.friendships;
CREATE POLICY friendships_select_own
  ON public.friendships
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS friendships_delete_own ON public.friendships;
CREATE POLICY friendships_delete_own
  ON public.friendships
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

COMMENT ON TABLE public.friendships IS 'Undirected friendships (user_id < friend_id).';

-- ---------- xp_events ----------

CREATE TABLE IF NOT EXISTS public.xp_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount int NOT NULL CHECK (amount > 0),
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS xp_events_user_created_idx
  ON public.xp_events (user_id, created_at DESC);

ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS xp_events_select_own ON public.xp_events;
CREATE POLICY xp_events_select_own
  ON public.xp_events
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS xp_events_insert_own ON public.xp_events;
CREATE POLICY xp_events_insert_own
  ON public.xp_events
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

COMMENT ON TABLE public.xp_events IS 'Global XP awards for weekly friend leaderboards.';

-- ---------- auth trigger ----------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  provider_name text;
  new_handle text;
BEGIN
  SELECT coalesce(i.provider, new.raw_app_meta_data ->> 'provider')
  INTO provider_name
  FROM auth.identities i
  WHERE i.user_id = new.id
  ORDER BY i.created_at ASC
  LIMIT 1;

  new_handle := public.handle_from_email(new.email);

  INSERT INTO public.profiles (id, email, auth_provider, handle)
  VALUES (new.id, new.email, provider_name, new_handle);

  INSERT INTO public.user_progress (user_id, progress)
  VALUES (new.id, '{}'::jsonb)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN new;
END;
$$;

-- ---------- RPCs ----------

CREATE OR REPLACE FUNCTION public.update_my_handle(new_handle text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  cleaned text;
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  cleaned := lower(btrim(coalesce(new_handle, '')));
  cleaned := regexp_replace(cleaned, '^@+', '');
  cleaned := regexp_replace(cleaned, '[^a-z0-9]', '', 'g');

  IF cleaned !~ '^[a-z][a-z0-9]{2,19}$' THEN
    RAISE EXCEPTION 'invalid_handle';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.handle = cleaned AND p.id <> uid
  ) THEN
    RAISE EXCEPTION 'handle_taken';
  END IF;

  UPDATE public.profiles
  SET handle = cleaned
  WHERE id = uid;

  RETURN cleaned;
END;
$$;

CREATE OR REPLACE FUNCTION public.add_friend_by_handle(target_handle text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  cleaned text;
  friend uuid;
  a uuid;
  b uuid;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  cleaned := lower(btrim(coalesce(target_handle, '')));
  cleaned := regexp_replace(cleaned, '^@+', '');
  cleaned := regexp_replace(cleaned, '[^a-z0-9]', '', 'g');

  IF cleaned = '' THEN
    RAISE EXCEPTION 'invalid_handle';
  END IF;

  SELECT p.id INTO friend
  FROM public.profiles p
  WHERE p.handle = cleaned;

  IF friend IS NULL THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF friend = uid THEN
    RAISE EXCEPTION 'cannot_add_self';
  END IF;

  a := LEAST(uid, friend);
  b := GREATEST(uid, friend);

  INSERT INTO public.friendships (user_id, friend_id)
  VALUES (a, b)
  ON CONFLICT (user_id, friend_id) DO NOTHING;

  RETURN friend;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_friend(friend uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  DELETE FROM public.friendships f
  WHERE (f.user_id = LEAST(uid, friend) AND f.friend_id = GREATEST(uid, friend));
END;
$$;

CREATE OR REPLACE FUNCTION public.are_friends(a uuid, b uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.friendships f
    WHERE f.user_id = LEAST(a, b)
      AND f.friend_id = GREATEST(a, b)
  );
$$;

CREATE OR REPLACE FUNCTION public.friends_leaderboard(period text DEFAULT 'week')
RETURNS TABLE (
  user_id uuid,
  handle text,
  xp bigint,
  is_me boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  use_week boolean := lower(coalesce(period, 'week')) IN ('week', 'weekly');
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  RETURN QUERY
  WITH my_friends AS (
    SELECT CASE WHEN f.user_id = uid THEN f.friend_id ELSE f.user_id END AS fid
    FROM public.friendships f
    WHERE f.user_id = uid OR f.friend_id = uid
  ),
  cohort AS (
    SELECT uid AS id
    UNION
    SELECT mf.fid FROM my_friends mf
  )
  SELECT
    c.id AS user_id,
    p.handle,
    CASE
      WHEN use_week THEN coalesce((
        SELECT sum(e.amount)::bigint
        FROM public.xp_events e
        WHERE e.user_id = c.id
          AND e.created_at >= (now() - interval '7 days')
      ), 0)
      ELSE coalesce((up.progress ->> 'globalXP')::bigint, 0)
    END AS xp,
    (c.id = uid) AS is_me
  FROM cohort c
  JOIN public.profiles p ON p.id = c.id
  LEFT JOIN public.user_progress up ON up.user_id = c.id
  ORDER BY xp DESC, p.handle ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.friend_public_stats(target uuid)
RETURNS TABLE (
  user_id uuid,
  handle text,
  global_xp int,
  streak int,
  courses_completed int,
  quizzes_completed int
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  prog jsonb;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF target <> uid AND NOT public.are_friends(uid, target) THEN
    RAISE EXCEPTION 'not_friends';
  END IF;

  SELECT up.progress INTO prog
  FROM public.user_progress up
  WHERE up.user_id = target;

  prog := coalesce(prog, '{}'::jsonb);

  RETURN QUERY
  SELECT
    target AS user_id,
    p.handle,
    coalesce((prog ->> 'globalXP')::int, 0) AS global_xp,
    coalesce((prog ->> 'streak')::int, 0) AS streak,
    coalesce((
      SELECT count(*)::int
      FROM jsonb_each(coalesce(prog -> 'courseProgress', '{}'::jsonb)) AS cp(key, value)
      WHERE (cp.value ->> 'isCompleted')::boolean IS TRUE
    ), 0) AS courses_completed,
    coalesce(jsonb_array_length(coalesce(prog -> 'completedQuizCourseIds', '[]'::jsonb)), 0) AS quizzes_completed
  FROM public.profiles p
  WHERE p.id = target;
END;
$$;

CREATE OR REPLACE FUNCTION public.log_xp_event(amount int, reason text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  IF amount IS NULL OR amount <= 0 THEN
    RETURN;
  END IF;

  INSERT INTO public.xp_events (user_id, amount, reason)
  VALUES (uid, amount, reason);
END;
$$;

REVOKE ALL ON FUNCTION public.update_my_handle(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_my_handle(text) TO authenticated;

REVOKE ALL ON FUNCTION public.add_friend_by_handle(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_friend_by_handle(text) TO authenticated;

REVOKE ALL ON FUNCTION public.remove_friend(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.remove_friend(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.friends_leaderboard(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.friends_leaderboard(text) TO authenticated;

REVOKE ALL ON FUNCTION public.friend_public_stats(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.friend_public_stats(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.log_xp_event(int, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.log_xp_event(int, text) TO authenticated;
