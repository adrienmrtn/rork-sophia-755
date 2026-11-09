-- Trois changements demandés le 9 novembre (docs/site-web.md, docs/studio.md) :
--
-- 1. La page publique d'un auteur existe dès l'approbation de son compte : studio_set_creator_status
--    crée (ou met à jour) sa ligne creators à partir de creator_accounts. Avant, elle n'apparaissait
--    qu'à la première publication. La photo publique est copiée par le site au même moment.
-- 2. Les lectures du jour en direct : course_stats_window(p_since) fond la synthèse quotidienne
--    (jours déjà agrégés) et le journal brut des jours pas encore agrégés ; creator_dashboard,
--    creator_course_detail et studio_admin_overview lisent cette fenêtre au lieu de la seule
--    synthèse de la veille.
-- 3. Les images générées pour un événement sont gardées comme candidates (campaigns.image_candidates)
--    pour que l'équipe choisisse entre la direction « couvertures » et la direction « affiche ».

-- ---------- 1. page publique dès l'approbation ----------

create or replace function public.studio_set_creator_status(p_user uuid, p_status text, p_reason text default null)
returns public.creator_accounts
language plpgsql
security definer
set search_path = public
as $$
declare
  a public.creator_accounts;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  if p_status not in ('pending', 'approved', 'suspended') then
    raise exception 'Statut inconnu : %', p_status;
  end if;
  update public.creator_accounts
     set status = p_status,
         approved_at = case when p_status = 'approved' then coalesce(approved_at, now()) else approved_at end,
         approved_by = case when p_status = 'approved' then coalesce(approved_by, auth.uid()) else approved_by end,
         suspended_reason = case when p_status = 'suspended' then nullif(trim(coalesce(p_reason, '')), '') else null end
   where user_id = p_user
  returning * into a;
  if a.user_id is null then
    raise exception 'Compte introuvable';
  end if;

  -- Approuvé : la page publique existe (ligne creators), les textes dans la langue d'écriture.
  if p_status = 'approved' and a.slug is not null then
    insert into public.creators (slug, name, title, bio, institution, country, links, verified, user_id)
    values (
      a.slug,
      coalesce(nullif(trim(a.display_name), ''), nullif(trim(concat_ws(' ', a.first_name, a.last_name)), ''), a.slug),
      case when nullif(trim(a.title), '') is not null then jsonb_build_object(a.writing_lang, trim(a.title)) else '{}'::jsonb end,
      case when nullif(trim(coalesce(a.long_bio, a.bio)), '') is not null then jsonb_build_object(a.writing_lang, trim(coalesce(a.long_bio, a.bio))) else '{}'::jsonb end,
      nullif(trim(a.institution), ''),
      nullif(trim(a.country), ''),
      coalesce(a.links, '{}'::jsonb),
      true,
      a.user_id
    )
    on conflict (slug) do update set
      name = excluded.name,
      title = public.creators.title || excluded.title,
      bio = public.creators.bio || excluded.bio,
      institution = coalesce(excluded.institution, public.creators.institution),
      country = coalesce(excluded.country, public.creators.country),
      links = case when excluded.links = '{}'::jsonb then public.creators.links else excluded.links end,
      verified = true,
      user_id = excluded.user_id,
      updated_at = now();
  elsif p_status = 'suspended' and a.slug is not null then
    update public.creators set verified = false, updated_at = now() where slug = a.slug;
  end if;
  return a;
end;
$$;
revoke all on function public.studio_set_creator_status(uuid, text, text) from public;
grant execute on function public.studio_set_creator_status(uuid, text, text) to authenticated;

-- ---------- 2. lectures en direct ----------

-- La fenêtre de statistiques depuis p_since : la synthèse quotidienne pour les jours déjà agrégés,
-- le journal brut (course_events) pour les jours qui ne le sont pas encore (aujourd'hui, et la
-- veille avant 02:20 UTC). Mêmes colonnes et mêmes définitions que refresh_daily_course_stats.
create or replace function public.course_stats_window(p_since date)
returns table (
  day date, course_id text, lang text,
  impressions bigint, opens bigint, completes bigint, likes bigint, readers bigint,
  quiz_answers bigint, quiz_correct bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with cutoff as (
    select coalesce(max(d.day), p_since - 1) + 1 as live_from from public.daily_course_stats d
  )
  select d.day, d.course_id, d.lang,
         d.impressions::bigint, d.opens::bigint, d.completes::bigint, d.likes::bigint, d.readers::bigint,
         d.quiz_answers::bigint, d.quiz_correct::bigint
  from public.daily_course_stats d, cutoff
  where d.day >= p_since and d.day < cutoff.live_from
  union all
  select (e.ts at time zone 'utc')::date, e.course_id, e.lang,
         count(*) filter (where e.name = 'card_impression'),
         count(*) filter (where e.name = 'course_open'),
         count(*) filter (where e.name = 'course_complete'),
         count(*) filter (where e.name = 'like'),
         count(distinct e.user_id) filter (where e.name = 'course_open'),
         count(*) filter (where e.name = 'quiz_answer'),
         count(*) filter (where e.name = 'quiz_answer' and coalesce((e.props ->> 'correct')::boolean, false))
  from public.course_events e, cutoff
  where e.course_id is not null and e.lang is not null
    and e.ts >= greatest(cutoff.live_from, p_since)::timestamptz
    and e.name in ('card_impression', 'course_open', 'course_complete', 'like', 'quiz_answer')
  group by 1, 2, 3
$$;
revoke all on function public.course_stats_window(date) from public, anon, authenticated;

create or replace function public.creator_dashboard(p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_slug text := public.studio_creator_slug(auth.uid());
  v_days integer := greatest(1, least(coalesce(p_days, 28), 365));
  v_since date := current_date - v_days;
  v_prev date := current_date - 2 * v_days;
  v_pool numeric := coalesce((select (value ->> 'payout_share')::numeric from public.app_config where key = 'studio'), 0.30);
  v_month date := date_trunc('month', current_date)::date;
  v_payouts jsonb := '[]'::jsonb;
  v_minutes jsonb;
  v_revenue jsonb;
  v_mine jsonb;
  v_net numeric;
  v_m date;
  result jsonb;
begin
  if v_slug is null then
    return jsonb_build_object('slug', null, 'days', v_days, 'courses', '[]'::jsonb, 'series', '[]'::jsonb, 'payouts', '[]'::jsonb);
  end if;

  -- Trois mois de cagnotte : le mois en cours (estimation) et les deux précédents.
  for i in 0..2 loop
    v_m := (v_month - (i || ' months')::interval)::date;
    v_minutes := public.creator_premium_minutes(v_m);
    v_revenue := public.creator_premium_revenue(v_m);
    v_net := coalesce((v_revenue ->> 'net')::numeric, 0);
    select c into v_mine from jsonb_array_elements(v_minutes -> 'creators') c where c ->> 'creator' = v_slug;
    v_payouts := v_payouts || jsonb_build_object(
      'month', to_char(v_m, 'YYYY-MM'),
      'current', i = 0,
      'minutes', coalesce((v_mine ->> 'minutes')::numeric, 0),
      'readers', coalesce((v_mine ->> 'readers')::integer, 0),
      'share', coalesce((v_mine ->> 'share')::numeric, 0),
      'pool_net', v_net,
      'pool_share', v_pool,
      'currency', coalesce(v_revenue ->> 'currency', 'USD'),
      'amount', round(v_net * v_pool * coalesce((v_mine ->> 'share')::numeric, 0), 2)
    );
  end loop;

  with mine as (
    select c.id, c.subject, c.status, c.published_at, c.origin_lang
    from public.courses c where c.creator_slug = v_slug
  ),
  cur as (
    select d.course_id, sum(d.impressions) impressions, sum(d.opens) opens, sum(d.completes) completes,
           sum(d.likes) likes, sum(d.readers) readers, sum(d.quiz_answers) quiz_answers, sum(d.quiz_correct) quiz_correct
    from public.course_stats_window(v_since) d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1
  ),
  prev as (
    select sum(d.opens) opens from public.course_stats_window(v_prev) d join mine m on m.id = d.course_id
    where d.day >= v_prev and d.day < v_since
  ),
  langs as (
    select d.course_id, d.lang, sum(d.opens) opens
    from public.course_stats_window(v_since) d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1, 2
  ),
  series as (
    select d.day, sum(d.opens) opens from public.course_stats_window(v_since) d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1
  ),
  follows as (
    select coalesce(sum(case when e.name = 'follow' then 1 when e.name = 'unfollow' then -1 else 0 end), 0) n
    from public.course_events e
    where e.name in ('follow', 'unfollow') and e.ts >= v_since and e.props ->> 'creator' = v_slug
  ),
  subj as (
    select c.subject, case when sum(d.impressions) > 0 then round(sum(d.completes)::numeric * 1000 / sum(d.impressions), 1) end as per1000
    from public.course_stats_window(v_since) d join public.courses c on c.id = d.course_id
    where d.day >= v_since group by 1
  )
  select jsonb_build_object(
    'slug', v_slug,
    'days', v_days,
    'reads', coalesce((select sum(opens) from cur), 0),
    'reads_prev', coalesce((select opens from prev), 0),
    'impressions', coalesce((select sum(impressions) from cur), 0),
    'completes', coalesce((select sum(completes) from cur), 0),
    'likes', coalesce((select sum(likes) from cur), 0),
    'per_1000', (select case when sum(impressions) > 0 then round(sum(completes)::numeric * 1000 / sum(impressions), 1) end from cur),
    'subject_per_1000', coalesce((select jsonb_object_agg(subject, per1000) from subj where per1000 is not null), '{}'::jsonb),
    'followers_gained', (select n from follows),
    'languages_read', (select count(distinct lang) from langs where opens > 0),
    'series', (select coalesce(jsonb_agg(jsonb_build_object('day', day, 'reads', opens) order by day), '[]'::jsonb) from series),
    'courses', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', m.id,
        'subject', m.subject,
        'status', m.status,
        'published_at', m.published_at,
        'title', (select cc.title from public.course_contents cc where cc.course_id = m.id and cc.lang = m.origin_lang),
        'impressions', coalesce(cur.impressions, 0),
        'reads', coalesce(cur.opens, 0),
        'completes', coalesce(cur.completes, 0),
        'likes', coalesce(cur.likes, 0),
        'readers', coalesce(cur.readers, 0),
        'per_1000', case when coalesce(cur.impressions, 0) > 0 then round(cur.completes::numeric * 1000 / cur.impressions, 1) end,
        'completion', case when coalesce(cur.opens, 0) > 0 then round(cur.completes::numeric / cur.opens, 3) end,
        'quiz_score', case when coalesce(cur.quiz_answers, 0) > 0 then round(cur.quiz_correct::numeric / cur.quiz_answers, 3) end,
        'languages', (select coalesce(jsonb_agg(jsonb_build_object('lang', l.lang, 'reads', l.opens) order by l.opens desc), '[]'::jsonb) from langs l where l.course_id = m.id),
        'published_langs', (select count(*) from public.course_contents cc where cc.course_id = m.id and cc.status = 'published')
      ) order by m.published_at desc nulls last, m.id), '[]'::jsonb)
      from mine m left join cur on cur.course_id = m.id
    ),
    'payouts', v_payouts
  ) into result;
  return result;
end;
$$;
revoke all on function public.creator_dashboard(integer) from public;
grant execute on function public.creator_dashboard(integer) to authenticated;

create or replace function public.creator_course_detail(p_course_id text, p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_slug text := public.studio_creator_slug(auth.uid());
  v_days integer := greatest(1, least(coalesce(p_days, 28), 365));
  v_since date := current_date - v_days;
begin
  if not public.is_studio_admin()
     and not exists (select 1 from public.courses c where c.id = p_course_id and c.creator_slug = v_slug) then
    raise exception 'Cours introuvable' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'course_id', p_course_id,
    'days', v_days,
    'stats', public.course_stats_export(v_days, p_course_id),
    'languages', (
      select coalesce(jsonb_agg(jsonb_build_object('lang', t.lang, 'reads', t.opens, 'completes', t.completes) order by t.opens desc), '[]'::jsonb)
      from (select d.lang, sum(d.opens) opens, sum(d.completes) completes from public.course_stats_window(v_since) d
            where d.course_id = p_course_id and d.day >= v_since group by 1) t
    ),
    'quiz', (
      select jsonb_build_object('answers', coalesce(sum(d.quiz_answers), 0), 'correct', coalesce(sum(d.quiz_correct), 0))
      from public.course_stats_window(v_since) d where d.course_id = p_course_id and d.day >= v_since
    ),
    'sections', (
      select cc.section_ids from public.course_contents cc join public.courses c on c.id = cc.course_id
      where cc.course_id = p_course_id and cc.lang = c.origin_lang
    )
  );
end;
$$;
revoke all on function public.creator_course_detail(text, integer) from public;
grant execute on function public.creator_course_detail(text, integer) to authenticated;

create or replace function public.studio_admin_overview(p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := greatest(1, least(coalesce(p_days, 28), 365));
  v_since date := current_date - v_days;
  v_month date := date_trunc('month', current_date)::date;
  v_pool numeric := coalesce((select (value ->> 'payout_share')::numeric from public.app_config where key = 'studio'), 0.30);
  v_minutes jsonb;
  v_revenue jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  v_minutes := public.creator_premium_minutes(v_month);
  v_revenue := public.creator_premium_revenue(v_month);
  return jsonb_build_object(
    'days', v_days,
    'review_queue', (select count(*) from public.studio_drafts where status = 'submitted'),
    'drafts_by_status', coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from public.studio_drafts group by 1) t), '{}'::jsonb),
    'creators_pending', (select count(*) from public.creator_accounts where status = 'pending'),
    'creators_approved', (select count(*) from public.creator_accounts where status = 'approved'),
    'creators_published', (select count(*) from public.creators),
    'agreements_missing', (select count(*) from public.creator_accounts a where a.status <> 'suspended' and not public.creator_agreement_current(a.user_id)),
    'jobs', coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from public.production_jobs group by 1) t), '{}'::jsonb),
    'courses_published', (select count(*) from public.courses where status = 'published'),
    'courses_in_production', (select count(*) from public.courses where status = 'in_production'),
    'reads', coalesce((select sum(opens) from public.course_stats_window(v_since) where day >= v_since), 0),
    'completes', coalesce((select sum(completes) from public.course_stats_window(v_since) where day >= v_since), 0),
    'readers', coalesce((select sum(readers) from public.course_stats_window(v_since) where day >= v_since), 0),
    'series', (select coalesce(jsonb_agg(jsonb_build_object('day', day, 'completes', c, 'reads', o) order by day), '[]'::jsonb)
               from (select day, sum(completes) c, sum(opens) o from public.course_stats_window(v_since) where day >= v_since group by 1) t),
    'by_language', (select coalesce(jsonb_agg(jsonb_build_object('lang', lang, 'reads', o) order by o desc), '[]'::jsonb)
                    from (select lang, sum(opens) o from public.course_stats_window(v_since) where day >= v_since group by 1) t),
    'by_subject', (select coalesce(jsonb_agg(jsonb_build_object('subject', subject, 'reads', o, 'completes', c, 'courses', n) order by o desc), '[]'::jsonb)
                   from (select c.subject, sum(d.opens) o, sum(d.completes) c, count(distinct d.course_id) n
                         from public.course_stats_window(v_since) d join public.courses c on c.id = d.course_id where d.day >= v_since group by 1) t),
    'premium', jsonb_build_object('month', v_revenue ->> 'month', 'currency', v_revenue ->> 'currency', 'gross', v_revenue ->> 'gross', 'net', v_revenue ->> 'net',
                                  'transactions', v_revenue ->> 'transactions', 'pool_share', v_pool,
                                  'pool', round(coalesce((v_revenue ->> 'net')::numeric, 0) * v_pool, 2),
                                  'total_minutes', v_minutes ->> 'total_minutes', 'creators', v_minutes -> 'creators')
  );
end;
$$;
revoke all on function public.studio_admin_overview(integer) from public;
grant execute on function public.studio_admin_overview(integer) to authenticated;

-- ---------- 3. candidates d'image d'un événement ----------

alter table public.campaigns
  add column if not exists image_candidates jsonb not null default '[]'::jsonb check (jsonb_typeof(image_candidates) = 'array');
comment on column public.campaigns.image_candidates is 'Les images générées, les plus récentes en premier : [{"url", "style": "cover" | "poster", "created_at"}]. L''équipe en choisit une (image_url).';
