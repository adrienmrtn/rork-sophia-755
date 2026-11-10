-- Badges (docs/badges.md).
--
-- 1. Badge d'un événement : une illustration carrée en papier découpé, générée depuis l'admin du
--    site (trois propositions, on en choisit une). badge_candidates garde les propositions,
--    badge_image_url celle qui est retenue ; le manifeste la donne aux apps.
-- 2. Profil d'un ami : les badges qu'il a choisi d'afficher (featured_badges), lus dans sa
--    progression (featuredBadgeIds, limités à ceux présents dans earnedBadges).

alter table public.campaigns
  add column if not exists badge_image_url text check (badge_image_url is null or badge_image_url ~ '^https://'),
  add column if not exists badge_candidates jsonb not null default '[]'::jsonb check (jsonb_typeof(badge_candidates) = 'array');

comment on column public.campaigns.badge_image_url is 'Illustration du badge de l''événement (carrée, papier découpé ; bucket course-images, dossier events/badges/). Null : les apps montrent le symbole.';
comment on column public.campaigns.badge_candidates is 'Les illustrations de badge générées, les plus récentes en premier : [{"url", "created_at"}].';

create or replace function public.campaigns_for_manifest()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'slug', c.slug,
    'kind', c.kind,
    'symbol', c.symbol,
    'image_url', c.image_url,
    'countries', case when c.countries is null then null else to_jsonb(c.countries) end,
    'starts_at', to_char(c.starts_at, 'YYYY-MM-DD'),
    'ends_at', to_char(c.ends_at, 'YYYY-MM-DD'),
    'challenge_target', c.challenge_target,
    'participants', c.participants,
    'goal_target', c.goal_target,
    'goal_count', c.goal_count,
    'course_ids', to_jsonb(c.course_ids),
    'upcoming', c.upcoming,
    'title', c.title,
    'tagline', c.tagline,
    'description', c.description,
    'badge_name', c.badge_name,
    'badge_image_url', c.badge_image_url
  ) order by c.starts_at, c.slug), '[]'::jsonb)
  from public.campaigns c
  where c.status = 'published' and c.ends_at >= current_date - 400;
$$;
revoke all on function public.campaigns_for_manifest() from public;
grant execute on function public.campaigns_for_manifest() to anon, authenticated, service_role;

-- Le profil d'un ami, avec en plus featured_badges. Le reste est inchangé
-- (20261110020300_friend_last_seen.sql).
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
    'friendly_lost', lost,
    -- Les badges qu'il affiche sur son profil (trois au plus), parmi ceux qu'il a gagnés.
    'featured_badges', coalesce((
      SELECT jsonb_agg(b.id ORDER BY b.ord)
      FROM (
        SELECT f.id, f.ord
        FROM jsonb_array_elements_text(
          CASE WHEN jsonb_typeof(prog -> 'featuredBadgeIds') = 'array' THEN prog -> 'featuredBadgeIds' ELSE '[]'::jsonb END
        ) WITH ORDINALITY AS f(id, ord)
        WHERE coalesce(prog -> 'earnedBadges', '{}'::jsonb) ? f.id
        ORDER BY f.ord
        LIMIT 3
      ) b
    ), '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.friend_profile(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.friend_profile(uuid) TO authenticated;
