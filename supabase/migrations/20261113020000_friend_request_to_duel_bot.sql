-- Demande d'ami à un adversaire de duel. Les adversaires des duels classés ne sont pas de vrais
-- comptes : leur envoyer une demande répondait « cet utilisateur n'existe pas », ce qui les
-- trahissait. La demande répond maintenant « envoyée », comme pour un vrai compte qui ne
-- l'accepte jamais ; rien n'est enregistré. À coller tel quel dans l'éditeur SQL de Supabase ;
-- rejouable. Rien à mettre à jour côté apps (iOS et Android lisent déjà la réponse « sent »).
--
-- Le reste de la fonction est celui en base au 11/11 (20260721134800), inchangé.

CREATE OR REPLACE FUNCTION public.send_friend_request(target_handle text)
RETURNS text
LANGUAGE plpgsql
VOLATILE
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
    -- Un adversaire de duel : la demande « part », personne ne la reçoit.
    IF EXISTS (SELECT 1 FROM public.duel_bots d WHERE d.handle = cleaned) THEN
      RETURN 'sent';
    END IF;
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
