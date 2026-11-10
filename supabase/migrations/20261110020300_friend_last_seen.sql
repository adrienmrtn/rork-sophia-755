-- « Vu il y a… » sur le profil d'un ami.
--
-- duel_presence.last_seen_at sert à la pastille verte : en quittant l'app, duel_go_offline le
-- recule d'une heure pour l'éteindre tout de suite, ce qui efface le vrai moment du départ. La
-- colonne last_active_at le garde. Le dernier passage d'un ami est donc le plus récent des
-- deux : last_seen_at tant que l'app se signale (ou si elle a été tuée sans prévenir),
-- last_active_at après un départ normal.

ALTER TABLE public.duel_presence
  ADD COLUMN IF NOT EXISTS last_active_at timestamptz;

-- Le joueur quitte l'app : il n'est plus « en ligne », et on retient quand il est parti.
CREATE OR REPLACE FUNCTION public.duel_go_offline()
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE public.duel_presence
    SET last_active_at = now(), last_seen_at = now() - interval '1 hour', busy = false
    WHERE user_id = auth.uid();
END;
$$;

-- Le profil d'un ami, avec en plus last_seen_seconds. Le reste est inchangé
-- (20261110010000_duel_friends.sql).
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
    -- Secondes écoulées depuis sa dernière présence dans l'app ; null s'il n'a jamais été vu.
    'last_seen_seconds', (
      SELECT greatest(0, extract(epoch FROM (now() - greatest(pr.last_seen_at, coalesce(pr.last_active_at, pr.last_seen_at)))))::int
      FROM public.duel_presence pr WHERE pr.user_id = target
    ),
    'can_challenge', target <> uid AND public.duel_can_challenge(target),
    'friendly_played', played,
    'friendly_won', won,
    'friendly_lost', lost
  );
END;
$$;

REVOKE ALL ON FUNCTION public.duel_go_offline() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_go_offline() TO authenticated;
REVOKE ALL ON FUNCTION public.friend_profile(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.friend_profile(uuid) TO authenticated;
