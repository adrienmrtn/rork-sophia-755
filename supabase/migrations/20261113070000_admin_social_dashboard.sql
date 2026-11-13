-- Amis, invitations et parrainage : tableau de bord /admin/data/social (docs/events.md).
--
-- Tout vient des tables du produit (friend_requests, friendships, duel_invites, referrals,
-- follows), conservées sans limite : le serveur connaît chaque demande et chaque invitation,
-- quelle que soit la version de l'app. Ces tables ne portent ni plateforme ni langue : la
-- page ne suit que la période.

create index if not exists friend_requests_created_at on public.friend_requests (created_at);
create index if not exists friendships_created_at on public.friendships (created_at);
create index if not exists duel_invites_created_at on public.duel_invites (created_at);
create index if not exists referrals_created_at on public.referrals (created_at);
create index if not exists follows_followed_at on public.follows (followed_at);

create or replace function public.admin_social_dashboard(p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := least(greatest(coalesce(p_days, 28), 1), 365);
  v_day date := (now() at time zone 'utc')::date - (v_days - 1);
  v_from timestamptz := v_day::timestamptz;
  v_result jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;

  with days as (
    select generate_series(v_day, (now() at time zone 'utc')::date, interval '1 day')::date as day
  ),
  fr as (
    select * from public.friend_requests r where r.created_at >= v_from
  ),
  fs as (
    select * from public.friendships f where f.created_at >= v_from
  ),
  friend_counts as (
    select user_id, count(*) as friends
    from (select user_id from public.friendships union all select friend_id from public.friendships) x
    group by user_id
  )
  select jsonb_build_object(
    'days', v_days,
    'from', v_day,
    'friends', jsonb_build_object(
      'requests', (select count(*) from fr),
      'senders', (select count(distinct sender_id) from fr),
      'accepted', (select count(*) from fr where status = 'accepted'),
      'declined', (select count(*) from fr where status = 'declined'),
      'pending', (select count(*) from fr where status = 'pending'),
      'new_friendships', (select count(*) from fs),
      'total_friendships', (select count(*) from public.friendships),
      'users_with_friends', (select count(*) from friend_counts),
      'users_with_3_friends', (select count(*) from friend_counts where friends >= 3),
      'series', coalesce((
        select jsonb_agg(jsonb_build_object('day', g.day, 'requests', coalesce(a.n, 0), 'friendships', coalesce(b.n, 0)) order by g.day)
        from days g
        left join (select (created_at at time zone 'utc')::date as day, count(*) as n from fr group by 1) a using (day)
        left join (select (created_at at time zone 'utc')::date as day, count(*) as n from fs group by 1) b using (day)
      ), '[]'::jsonb)
    ),
    'duel_invites', jsonb_build_object(
      'sent', (select count(*) from public.duel_invites i where i.created_at >= v_from),
      'by_status', coalesce((
        select jsonb_agg(jsonb_build_object('status', status, 'count', n) order by n desc, status)
        from (select status, count(*) as n from public.duel_invites i where i.created_at >= v_from group by status) t
      ), '[]'::jsonb)
    ),
    'referrals', jsonb_build_object(
      'new', (select count(*) from public.referrals r where r.created_at >= v_from),
      'inviters', (select count(distinct inviter_id) from public.referrals r where r.created_at >= v_from),
      'total', (select count(*) from public.referrals)
    ),
    'follows', jsonb_build_object(
      'new', (select count(*) from public.follows f where f.followed_at >= v_from),
      'followers', (select count(distinct user_id) from public.follows f where f.followed_at >= v_from),
      'total', (select count(*) from public.follows),
      'top_creators', coalesce((
        select jsonb_agg(jsonb_build_object('creator', t.creator_slug, 'name', t.name, 'new', t.n) order by t.n desc, t.creator_slug)
        from (
          select f.creator_slug, c.name, count(*) as n
          from public.follows f
          left join public.creators c on c.slug = f.creator_slug
          where f.followed_at >= v_from
          group by f.creator_slug, c.name
          order by count(*) desc, f.creator_slug
          limit 10
        ) t
      ), '[]'::jsonb)
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.admin_social_dashboard(integer) from public, anon;
grant execute on function public.admin_social_dashboard(integer) to authenticated;
