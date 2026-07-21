-- Friend requests (pending -> accepted / declined) instead of instant friendship.
-- Applied remotely via Supabase MCP (project afnmcoovdvbtkgohtdij).

CREATE TABLE IF NOT EXISTS public.friend_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,
  CONSTRAINT friend_requests_not_self CHECK (sender_id <> receiver_id),
  CONSTRAINT friend_requests_status_check CHECK (status IN ('pending','accepted','declined')),
  CONSTRAINT friend_requests_unique_direction UNIQUE (sender_id, receiver_id)
);

CREATE INDEX IF NOT EXISTS friend_requests_receiver_idx ON public.friend_requests (receiver_id, status);
CREATE INDEX IF NOT EXISTS friend_requests_sender_idx ON public.friend_requests (sender_id, status);

ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS friend_requests_select_own ON public.friend_requests;
CREATE POLICY friend_requests_select_own
  ON public.friend_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

REVOKE ALL ON TABLE public.friend_requests FROM anon;
GRANT SELECT ON TABLE public.friend_requests TO authenticated;

COMMENT ON TABLE public.friend_requests IS 'Directed friend requests; accepted ones create a row in friendships.';

-- ---------- send a request (or auto-accept a reverse pending one) ----------

CREATE OR REPLACE FUNCTION public.send_friend_request(target_handle text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  cleaned text;
  receiver uuid;
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

  SELECT p.id INTO receiver FROM public.profiles p WHERE p.handle = cleaned;

  IF receiver IS NULL THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF receiver = uid THEN
    RAISE EXCEPTION 'cannot_add_self';
  END IF;

  IF public.are_friends(uid, receiver) THEN
    RAISE EXCEPTION 'already_friends';
  END IF;

  -- Reverse pending request already exists -> accept it immediately (mutual add).
  IF EXISTS (
    SELECT 1 FROM public.friend_requests r
    WHERE r.sender_id = receiver AND r.receiver_id = uid AND r.status = 'pending'
  ) THEN
    a := LEAST(uid, receiver);
    b := GREATEST(uid, receiver);
    INSERT INTO public.friendships (user_id, friend_id)
    VALUES (a, b)
    ON CONFLICT (user_id, friend_id) DO NOTHING;

    UPDATE public.friend_requests
    SET status = 'accepted', responded_at = now()
    WHERE sender_id = receiver AND receiver_id = uid AND status = 'pending';

    RETURN 'accepted';
  END IF;

  -- Existing outgoing pending request -> nothing to do.
  IF EXISTS (
    SELECT 1 FROM public.friend_requests r
    WHERE r.sender_id = uid AND r.receiver_id = receiver AND r.status = 'pending'
  ) THEN
    RAISE EXCEPTION 'request_already_sent';
  END IF;

  INSERT INTO public.friend_requests (sender_id, receiver_id, status, created_at, responded_at)
  VALUES (uid, receiver, 'pending', now(), NULL)
  ON CONFLICT (sender_id, receiver_id)
  DO UPDATE SET status = 'pending', created_at = now(), responded_at = NULL;

  RETURN 'sent';
END;
$$;

-- ---------- respond to an incoming request ----------

CREATE OR REPLACE FUNCTION public.respond_friend_request(request_id uuid, accept boolean)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  req record;
  a uuid;
  b uuid;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO req
  FROM public.friend_requests r
  WHERE r.id = request_id AND r.receiver_id = uid AND r.status = 'pending';

  IF req IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;

  IF accept THEN
    a := LEAST(req.sender_id, req.receiver_id);
    b := GREATEST(req.sender_id, req.receiver_id);
    INSERT INTO public.friendships (user_id, friend_id)
    VALUES (a, b)
    ON CONFLICT (user_id, friend_id) DO NOTHING;

    UPDATE public.friend_requests
    SET status = 'accepted', responded_at = now()
    WHERE id = request_id;

    RETURN 'accepted';
  ELSE
    UPDATE public.friend_requests
    SET status = 'declined', responded_at = now()
    WHERE id = request_id;

    RETURN 'declined';
  END IF;
END;
$$;

-- ---------- cancel an outgoing pending request ----------

CREATE OR REPLACE FUNCTION public.cancel_friend_request(target uuid)
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

  DELETE FROM public.friend_requests
  WHERE sender_id = uid AND receiver_id = target AND status = 'pending';
END;
$$;

-- ---------- incoming pending requests ----------

CREATE OR REPLACE FUNCTION public.pending_friend_requests()
RETURNS TABLE (
  request_id uuid,
  user_id uuid,
  handle text,
  created_at timestamptz
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
  SELECT r.id, p.id, p.handle, r.created_at
  FROM public.friend_requests r
  JOIN public.profiles p ON p.id = r.sender_id
  WHERE r.receiver_id = uid AND r.status = 'pending'
  ORDER BY r.created_at DESC;
END;
$$;

-- ---------- outgoing pending handles (so the UI can show 'requested') ----------

CREATE OR REPLACE FUNCTION public.outgoing_pending_handles()
RETURNS TABLE (
  user_id uuid,
  handle text
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
  SELECT p.id, p.handle
  FROM public.friend_requests r
  JOIN public.profiles p ON p.id = r.receiver_id
  WHERE r.sender_id = uid AND r.status = 'pending'
  ORDER BY r.created_at DESC;
END;
$$;

-- Remove the old instant-add RPC.
DROP FUNCTION IF EXISTS public.add_friend_by_handle(text);

-- Grants: authenticated only.
REVOKE ALL ON FUNCTION public.send_friend_request(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.send_friend_request(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.send_friend_request(text) TO authenticated;

REVOKE ALL ON FUNCTION public.respond_friend_request(uuid, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.respond_friend_request(uuid, boolean) FROM anon;
GRANT EXECUTE ON FUNCTION public.respond_friend_request(uuid, boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.cancel_friend_request(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_friend_request(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.cancel_friend_request(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.pending_friend_requests() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pending_friend_requests() FROM anon;
GRANT EXECUTE ON FUNCTION public.pending_friend_requests() TO authenticated;

REVOKE ALL ON FUNCTION public.outgoing_pending_handles() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.outgoing_pending_handles() FROM anon;
GRANT EXECUTE ON FUNCTION public.outgoing_pending_handles() TO authenticated;
