-- Filtre par version de l'app sur les pages /admin/data (paywalls, onboarding, usage, retours).
--
-- Les synthèses quotidiennes gagnent la version de l'app dans leur clé ; les tableaux de bord
-- prennent p_version et renvoient la liste des versions connues. Les duels, les revenus
-- (RevenueCat), les amis et la rétention ne connaissent pas la version : ils ne la suivent pas.

alter table public.daily_paywall_stats add column if not exists app_version text not null default '';
alter table public.daily_paywall_stats drop constraint daily_paywall_stats_pkey;
alter table public.daily_paywall_stats add primary key (day, platform, app_version, lang, paywall_id, offering, experiment, variant);

alter table public.daily_onboarding_stats add column if not exists app_version text not null default '';
alter table public.daily_onboarding_stats drop constraint daily_onboarding_stats_pkey;
alter table public.daily_onboarding_stats add primary key (day, platform, app_version, lang, kind, key, value);

alter table public.daily_usage_stats add column if not exists app_version text not null default '';
alter table public.daily_usage_stats drop constraint daily_usage_stats_pkey;
alter table public.daily_usage_stats add primary key (day, platform, app_version, lang);

alter table public.daily_course_usage add column if not exists app_version text not null default '';
alter table public.daily_course_usage drop constraint daily_course_usage_pkey;
alter table public.daily_course_usage add primary key (day, platform, app_version, lang, course_id);

alter table public.daily_quiz_question_stats add column if not exists app_version text not null default '';
alter table public.daily_quiz_question_stats drop constraint daily_quiz_question_stats_pkey;
alter table public.daily_quiz_question_stats add primary key (day, platform, app_version, lang, question_id);

-- Les anciennes signatures disparaissent : avec un paramètre de plus et des valeurs par défaut,
-- PostgREST ne saurait plus laquelle appeler.
drop function if exists public.admin_paywall_dashboard(integer, text, text);
drop function if exists public.admin_onboarding_dashboard(integer, text, text);
drop function if exists public.admin_feedback_dashboard(integer, text, text);
drop function if exists public.admin_usage_dashboard(integer, text, text, integer);

create or replace function public.refresh_daily_paywall_stats(target_day date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  delete from public.daily_paywall_stats where day = target_day;

  insert into public.daily_paywall_stats
    (day, platform, app_version, lang, paywall_id, offering, experiment, variant,
     views, viewers, purchases_started, purchases_completed, buyers,
     purchases_cancelled, purchases_failed, updated_at)
  with ev as (
    select
      e.name,
      e.user_id,
      e.platform,
      coalesce(e.app_version, '') as app_version,
      coalesce(e.lang, 'unknown') as lang,
      coalesce(e.props ->> 'paywall_id', 'unknown') as paywall_id,
      coalesce(e.props ->> 'offering', '') as offering,
      coalesce(e.props ->> 'experiment', '') as experiment,
      coalesce(e.props ->> 'variant', '') as variant,
      null::text as reason
    from public.course_events e
    where e.name = 'paywall_view'
      and e.ts >= target_day::timestamptz
      and e.ts < (target_day + 1)::timestamptz
    union all
    select
      e.name,
      e.user_id,
      e.platform,
      coalesce(e.app_version, ''),
      coalesce(e.lang, 'unknown'),
      coalesce(v.paywall_id, e.props ->> 'paywall_id', 'unknown'),
      coalesce(v.offering, e.props ->> 'offering', ''),
      coalesce(v.experiment, e.props ->> 'experiment', ''),
      coalesce(v.variant, e.props ->> 'variant', ''),
      e.props ->> 'reason'
    from public.course_events e
    left join lateral (
      select
        pv.props ->> 'paywall_id' as paywall_id,
        coalesce(pv.props ->> 'offering', '') as offering,
        coalesce(pv.props ->> 'experiment', '') as experiment,
        coalesce(pv.props ->> 'variant', '') as variant
      from public.course_events pv
      where pv.name = 'paywall_view'
        and pv.user_id = e.user_id
        and pv.ts <= e.ts
        and pv.ts > e.ts - interval '1 hour'
        and (e.props ->> 'paywall_id' is null or pv.props ->> 'paywall_id' = e.props ->> 'paywall_id')
      order by pv.ts desc
      limit 1
    ) v on true
    where e.name in ('purchase_started', 'purchase_completed', 'purchase_failed')
      and e.ts >= target_day::timestamptz
      and e.ts < (target_day + 1)::timestamptz
  )
  select
    target_day, platform, app_version, lang, paywall_id, offering, experiment, variant,
    count(*) filter (where name = 'paywall_view'),
    count(distinct user_id) filter (where name = 'paywall_view'),
    count(*) filter (where name = 'purchase_started'),
    count(*) filter (where name = 'purchase_completed'),
    count(distinct user_id) filter (where name = 'purchase_completed'),
    count(*) filter (where name = 'purchase_failed' and reason = 'cancelled'),
    count(*) filter (where name = 'purchase_failed' and reason is distinct from 'cancelled'),
    now()
  from ev
  group by platform, app_version, lang, paywall_id, offering, experiment, variant;
end;
$$;

create or replace function public.refresh_daily_onboarding_stats(target_day date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  delete from public.daily_onboarding_stats where day = target_day;

  insert into public.daily_onboarding_stats (day, platform, app_version, lang, kind, key, value, installs, updated_at)
  with ev as (
    select e.install_id, e.platform, coalesce(e.app_version, '') as app_version, coalesce(e.lang, 'unknown') as lang, e.name, e.step, e.question, e.answer, e.ts
    from public.onboarding_events e
    where e.ts >= target_day::timestamptz
      and e.ts < (target_day + 1)::timestamptz
  ),
  last_answers as (
    select distinct on (install_id, question) install_id, platform, app_version, lang, question, answer
    from ev
    where name = 'onboarding_answer'
    order by install_id, question, ts desc
  )
  select target_day, platform, app_version, lang, 'step', step, '', count(distinct install_id), now()
  from ev where name = 'onboarding_step'
  group by platform, app_version, lang, step
  union all
  select target_day, platform, app_version, lang, 'answered', question, '', count(distinct install_id), now()
  from last_answers
  group by platform, app_version, lang, question
  union all
  select target_day, a.platform, a.app_version, a.lang, 'answer', a.question, o.option, count(distinct a.install_id), now()
  from last_answers a
  cross join lateral (select distinct trim(x) as option from unnest(string_to_array(a.answer, ',')) as x where trim(x) <> '') o
  group by a.platform, a.app_version, a.lang, a.question, o.option;
end;
$$;

create or replace function public.refresh_daily_usage_stats(target_day date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_from timestamptz := target_day::timestamptz;
  v_to timestamptz := (target_day + 1)::timestamptz;
begin
  delete from public.daily_usage_stats where day = target_day;
  delete from public.daily_course_usage where day = target_day;
  delete from public.daily_quiz_question_stats where day = target_day;
  delete from public.daily_duel_stats where day = target_day;
  delete from public.daily_version_usage where day = target_day;

  insert into public.daily_usage_stats
    (day, platform, app_version, lang, active_users, sessions, course_opens, readers, pages_read, completes,
     likes, saves, shares, quiz_answers, quiz_correct, updated_at)
  select
    target_day, e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown'),
    count(distinct e.user_id),
    count(distinct e.session_id),
    count(*) filter (where e.name = 'course_open'),
    count(distinct e.user_id) filter (where e.name = 'course_open'),
    count(*) filter (where e.name = 'section_view'),
    count(*) filter (where e.name = 'course_complete'),
    count(*) filter (where e.name = 'like'),
    count(*) filter (where e.name = 'save'),
    count(*) filter (where e.name = 'share'),
    count(*) filter (where e.name = 'quiz_answer'),
    count(*) filter (where e.name = 'quiz_answer' and e.props ->> 'correct' = 'true'),
    now()
  from public.course_events e
  where e.ts >= v_from and e.ts < v_to
  group by e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown');

  insert into public.daily_course_usage
    (day, platform, app_version, lang, course_id, opens, readers, pages_read, completes, likes, impressions, card_opens, updated_at)
  select
    target_day, e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown'), e.course_id,
    count(*) filter (where e.name = 'course_open'),
    count(distinct e.user_id) filter (where e.name = 'course_open'),
    count(*) filter (where e.name = 'section_view'),
    count(*) filter (where e.name = 'course_complete'),
    count(*) filter (where e.name = 'like'),
    count(*) filter (where e.name = 'card_impression'),
    count(*) filter (where e.name = 'card_open'),
    now()
  from public.course_events e
  where e.ts >= v_from and e.ts < v_to
    and e.course_id is not null
    and e.name in ('course_open', 'section_view', 'course_complete', 'like', 'card_impression', 'card_open')
  group by e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown'), e.course_id;

  insert into public.daily_quiz_question_stats
    (day, platform, app_version, lang, question_id, course_id, answers, correct, updated_at)
  select
    target_day, e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown'), e.props ->> 'question_id',
    coalesce(max(e.course_id), regexp_replace(e.props ->> 'question_id', '_q\d+$', '')),
    count(*),
    count(*) filter (where e.props ->> 'correct' = 'true'),
    now()
  from public.course_events e
  where e.ts >= v_from and e.ts < v_to
    and e.name = 'quiz_answer'
    and e.props ->> 'question_id' is not null
  group by e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown'), e.props ->> 'question_id';

  insert into public.daily_duel_stats
    (day, platform, lang, kind, started, finished, abandoned, players, updated_at)
  with platform_of as (
    select distinct on (e.user_id) e.user_id, e.platform
    from public.course_events e
    where e.ts >= v_from and e.ts < v_to
    order by e.user_id, e.ts desc
  ),
  duels as (
    select m.user_id, 'match'::text as kind,
           (m.finished_at is not null and m.status <> 'abandoned') as finished,
           (m.status = 'abandoned') as abandoned
    from public.duel_matches m
    where m.started_at >= v_from and m.started_at < v_to
    union all
    select f.player_a, 'friend',
           (f.status = 'finished' and not (coalesce(f.left_a, false) or coalesce(f.left_b, false))),
           (coalesce(f.left_a, false) or coalesce(f.left_b, false))
    from public.duel_friend_matches f
    where f.created_at >= v_from and f.created_at < v_to
  )
  select
    target_day, coalesce(p.platform, 'unknown'), coalesce(dp.lang, 'unknown'), d.kind,
    count(*), count(*) filter (where d.finished), count(*) filter (where d.abandoned),
    count(distinct d.user_id), now()
  from duels d
  left join platform_of p on p.user_id = d.user_id
  left join public.duel_profiles dp on dp.user_id = d.user_id
  group by coalesce(p.platform, 'unknown'), coalesce(dp.lang, 'unknown'), d.kind;

  insert into public.daily_version_usage
    (day, platform, app_version, lang, active_users, course_opens, pages_read, completes,
     impressions, card_opens, quiz_answers, quiz_correct, updated_at)
  select
    target_day, e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown'),
    count(distinct e.user_id),
    count(*) filter (where e.name = 'course_open'),
    count(*) filter (where e.name = 'section_view'),
    count(*) filter (where e.name = 'course_complete'),
    count(*) filter (where e.name = 'card_impression'),
    count(*) filter (where e.name = 'card_open'),
    count(*) filter (where e.name = 'quiz_answer'),
    count(*) filter (where e.name = 'quiz_answer' and e.props ->> 'correct' = 'true'),
    now()
  from public.course_events e
  where e.ts >= v_from and e.ts < v_to
  group by e.platform, coalesce(e.app_version, ''), coalesce(e.lang, 'unknown');
end;
$$;

create or replace function public.admin_paywall_dashboard(
  p_days integer default 28,
  p_platform text default null,
  p_lang text default null,
  p_version text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := least(greatest(coalesce(p_days, 28), 1), 365);
  v_from date := (now() at time zone 'utc')::date - (v_days - 1);
  v_store text := case p_platform when 'ios' then 'APP_STORE' when 'android' then 'PLAY_STORE' else null end;
  v_result jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;

  with s as (
    select * from public.daily_paywall_stats d
    where d.day >= v_from
      and (p_platform is null or d.platform = p_platform)
      and (p_lang is null or d.lang = p_lang)
      and (p_version is null or d.app_version = p_version)
  ),
  rc as (
    select
      (e.event_ts at time zone 'utc')::date as day,
      coalesce(nullif(e.presented_offering_id, ''), 'unknown') as offering,
      e.type, e.period_type, e.is_trial_conversion,
      coalesce(e.price, 0) as price,
      coalesce(e.price, 0) * coalesce(e.takehome_percentage, 1) as proceeds
    from public.subscription_events e
    where e.environment = 'PRODUCTION'
      and e.event_ts >= v_from::timestamptz
      and (v_store is null or e.store = v_store)
  ),
  rc_days as (
    select
      day,
      count(*) filter (where type = 'INITIAL_PURCHASE' and period_type = 'TRIAL') as trials,
      count(*) filter (where type = 'INITIAL_PURCHASE' and period_type <> 'TRIAL') as direct_purchases,
      count(*) filter (where type = 'RENEWAL' and is_trial_conversion) as trial_conversions,
      count(*) filter (where type = 'RENEWAL' and not coalesce(is_trial_conversion, false) and period_type <> 'TRIAL') as renewals,
      count(*) filter (where price < 0) as refunds,
      round(sum(price)::numeric, 2) as revenue,
      round(sum(proceeds)::numeric, 2) as proceeds
    from rc group by day
  ),
  rc_offerings as (
    select
      offering,
      count(*) filter (where type = 'INITIAL_PURCHASE' and period_type = 'TRIAL') as trials,
      count(*) filter (where type = 'INITIAL_PURCHASE' and period_type <> 'TRIAL') as direct_purchases,
      count(*) filter (where type = 'RENEWAL' and is_trial_conversion) as trial_conversions,
      count(*) filter (where type = 'RENEWAL' and not coalesce(is_trial_conversion, false) and period_type <> 'TRIAL') as renewals,
      count(*) filter (where price < 0) as refunds,
      round(sum(price)::numeric, 2) as revenue,
      round(sum(proceeds)::numeric, 2) as proceeds
    from rc group by offering
  )
  select jsonb_build_object(
    'days', v_days,
    'from', v_from,
    'updated_at', (select max(updated_at) from public.daily_paywall_stats),
    'versions', coalesce((select jsonb_agg(jsonb_build_object('platform', platform, 'app_version', app_version) order by platform, app_version desc) from (select distinct platform, app_version from public.daily_paywall_stats where app_version <> '') x), '[]'::jsonb),
    'languages', coalesce((select jsonb_agg(l order by l) from (select distinct lang as l from public.daily_paywall_stats) x), '[]'::jsonb),
    'totals', (select jsonb_build_object(
      'views', coalesce(sum(views), 0),
      'viewers', coalesce(sum(viewers), 0),
      'purchases_started', coalesce(sum(purchases_started), 0),
      'purchases_completed', coalesce(sum(purchases_completed), 0),
      'purchases_cancelled', coalesce(sum(purchases_cancelled), 0),
      'purchases_failed', coalesce(sum(purchases_failed), 0)
    ) from s),
    'series', coalesce((
      select jsonb_agg(jsonb_build_object('day', g.day, 'views', coalesce(t.views, 0), 'purchases', coalesce(t.purchases, 0)) order by g.day)
      from (select generate_series(v_from, (now() at time zone 'utc')::date, interval '1 day')::date as day) g
      left join (select day, sum(views) as views, sum(purchases_completed) as purchases from s group by day) t using (day)
    ), '[]'::jsonb),
    'by_paywall', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.views desc, t.paywall_id)
      from (
        select paywall_id, sum(views) as views, sum(viewers) as viewers, sum(purchases_started) as purchases_started,
               sum(purchases_completed) as purchases_completed, sum(purchases_cancelled) as purchases_cancelled,
               sum(purchases_failed) as purchases_failed
        from s group by paywall_id
      ) t
    ), '[]'::jsonb),
    'by_experiment', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.experiment, t.variant)
      from (
        select experiment, variant, sum(views) as views, sum(viewers) as viewers, sum(purchases_started) as purchases_started,
               sum(purchases_completed) as purchases_completed
        from s where experiment <> '' group by experiment, variant
      ) t
    ), '[]'::jsonb),
    'by_offering', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.views desc, t.offering)
      from (
        select case when offering = '' then 'unknown' else offering end as offering, sum(views) as views, sum(viewers) as viewers,
               sum(purchases_started) as purchases_started, sum(purchases_completed) as purchases_completed
        from s group by 1
      ) t
    ), '[]'::jsonb),
    'by_language', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.views desc, t.lang)
      from (
        select lang, sum(views) as views, sum(viewers) as viewers, sum(purchases_started) as purchases_started,
               sum(purchases_completed) as purchases_completed
        from s group by lang
      ) t
    ), '[]'::jsonb),
    'by_platform', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.platform)
      from (
        select platform, sum(views) as views, sum(viewers) as viewers, sum(purchases_started) as purchases_started,
               sum(purchases_completed) as purchases_completed
        from s group by platform
      ) t
    ), '[]'::jsonb),
    'revenue', jsonb_build_object(
      'totals', (select jsonb_build_object(
        'trials', coalesce(sum(trials), 0),
        'direct_purchases', coalesce(sum(direct_purchases), 0),
        'trial_conversions', coalesce(sum(trial_conversions), 0),
        'renewals', coalesce(sum(renewals), 0),
        'refunds', coalesce(sum(refunds), 0),
        'revenue', coalesce(sum(revenue), 0),
        'proceeds', coalesce(sum(proceeds), 0)
      ) from rc_days),
      'series', coalesce((
        select jsonb_agg(jsonb_build_object('day', g.day, 'revenue', coalesce(t.revenue, 0), 'trials', coalesce(t.trials, 0)) order by g.day)
        from (select generate_series(v_from, (now() at time zone 'utc')::date, interval '1 day')::date as day) g
        left join rc_days t using (day)
      ), '[]'::jsonb),
      'by_offering', coalesce((select jsonb_agg(to_jsonb(t) order by t.revenue desc nulls last, t.trials desc) from rc_offerings t), '[]'::jsonb),
      'first_day', (select min(event_ts at time zone 'utc')::date from public.subscription_events where environment = 'PRODUCTION')
    )
  ) into v_result;

  return v_result;
end;
$$;

create or replace function public.admin_onboarding_dashboard(
  p_days integer default 28,
  p_platform text default null,
  p_lang text default null,
  p_version text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := least(greatest(coalesce(p_days, 28), 1), 365);
  v_from date := (now() at time zone 'utc')::date - (v_days - 1);
  v_result jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;

  with s as (
    select * from public.daily_onboarding_stats d
    where d.day >= v_from
      and (p_platform is null or d.platform = p_platform)
      and (p_lang is null or d.lang = p_lang)
      and (p_version is null or d.app_version = p_version)
  )
  select jsonb_build_object(
    'days', v_days,
    'from', v_from,
    'updated_at', (select max(updated_at) from public.daily_onboarding_stats),
    'versions', coalesce((select jsonb_agg(jsonb_build_object('platform', platform, 'app_version', app_version) order by platform, app_version desc) from (select distinct platform, app_version from public.daily_onboarding_stats where app_version <> '') x), '[]'::jsonb),
    'languages', coalesce((select jsonb_agg(l order by l) from (select distinct lang as l from public.daily_onboarding_stats) x), '[]'::jsonb),
    'steps', coalesce((
      select jsonb_agg(jsonb_build_object('step', t.key, 'installs', t.installs, 'ios', t.ios, 'android', t.android))
      from (
        select key, sum(installs) as installs,
               coalesce(sum(installs) filter (where platform = 'ios'), 0) as ios,
               coalesce(sum(installs) filter (where platform = 'android'), 0) as android
        from s where kind = 'step' group by key
      ) t
    ), '[]'::jsonb),
    'series', coalesce((
      select jsonb_agg(jsonb_build_object('day', g.day, 'installs', coalesce(t.installs, 0)) order by g.day)
      from (select generate_series(v_from, (now() at time zone 'utc')::date, interval '1 day')::date as day) g
      left join (select day, sum(installs) as installs from s where kind = 'step' and key = 'welcome' group by day) t using (day)
    ), '[]'::jsonb),
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'question', q.key,
        'answered', q.installs,
        'options', coalesce((
          select jsonb_agg(jsonb_build_object('value', o.value, 'installs', o.installs) order by o.installs desc, o.value)
          from (select value, sum(installs) as installs from s where kind = 'answer' and key = q.key group by value) o
        ), '[]'::jsonb)
      ) order by q.key)
      from (select key, sum(installs) as installs from s where kind = 'answered' group by key) q
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

create or replace function public.admin_usage_dashboard(
  p_days integer default 28,
  p_platform text default null,
  p_lang text default null,
  p_min_answers integer default 20,
  p_version text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := least(greatest(coalesce(p_days, 28), 1), 365);
  v_from date := (now() at time zone 'utc')::date - (v_days - 1);
  v_lang text := coalesce(p_lang, 'fr');
  v_min integer := greatest(coalesce(p_min_answers, 20), 1);
  v_result jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;

  with u as (
    select * from public.daily_usage_stats d
    where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang) and (p_version is null or d.app_version = p_version)
  ),
  c as (
    select course_id, sum(opens) as opens, sum(readers) as readers, sum(pages_read) as pages_read,
           sum(completes) as completes, sum(likes) as likes,
           sum(impressions) as impressions, sum(card_opens) as card_opens
    from public.daily_course_usage d
    where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang) and (p_version is null or d.app_version = p_version)
    group by course_id
  ),
  q as (
    select question_id, max(course_id) as course_id, sum(answers) as answers, sum(correct) as correct
    from public.daily_quiz_question_stats d
    where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang) and (p_version is null or d.app_version = p_version)
    group by question_id
  ),
  du as (
    select * from public.daily_duel_stats d
    where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang)
  ),
  days as (
    select generate_series(v_from, (now() at time zone 'utc')::date, interval '1 day')::date as day
  )
  select jsonb_build_object(
    'days', v_days,
    'from', v_from,
    'min_answers', v_min,
    'updated_at', (select max(updated_at) from public.daily_usage_stats),
    'versions', coalesce((select jsonb_agg(jsonb_build_object('platform', platform, 'app_version', app_version) order by platform, app_version desc) from (select distinct platform, app_version from public.daily_usage_stats where app_version <> '') x), '[]'::jsonb),
    'languages', coalesce((select jsonb_agg(l order by l) from (select distinct lang as l from public.daily_usage_stats) x), '[]'::jsonb),
    'totals', (select jsonb_build_object(
      'user_days', coalesce(sum(active_users), 0),
      'sessions', coalesce(sum(sessions), 0),
      'course_opens', coalesce(sum(course_opens), 0),
      'pages_read', coalesce(sum(pages_read), 0),
      'completes', coalesce(sum(completes), 0),
      'likes', coalesce(sum(likes), 0),
      'saves', coalesce(sum(saves), 0),
      'shares', coalesce(sum(shares), 0),
      'quiz_answers', coalesce(sum(quiz_answers), 0),
      'quiz_correct', coalesce(sum(quiz_correct), 0)
    ) from u),
    'series', coalesce((
      select jsonb_agg(jsonb_build_object(
        'day', g.day, 'active_users', coalesce(t.active_users, 0), 'course_opens', coalesce(t.course_opens, 0),
        'pages_read', coalesce(t.pages_read, 0), 'duels', coalesce(dd.started, 0)) order by g.day)
      from days g
      left join (select day, sum(active_users) as active_users, sum(course_opens) as course_opens, sum(pages_read) as pages_read from u group by day) t using (day)
      left join (select day, sum(started) as started from du group by day) dd using (day)
    ), '[]'::jsonb),
    'by_language', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.user_days desc, t.lang)
      from (select lang, sum(active_users) as user_days, sum(course_opens) as course_opens, sum(pages_read) as pages_read,
                   sum(completes) as completes, sum(likes) as likes, sum(quiz_answers) as quiz_answers, sum(quiz_correct) as quiz_correct
            from u group by lang) t
    ), '[]'::jsonb),
    'by_platform', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.platform)
      from (select platform, sum(active_users) as user_days, sum(course_opens) as course_opens, sum(pages_read) as pages_read,
                   sum(completes) as completes, sum(likes) as likes, sum(quiz_answers) as quiz_answers, sum(quiz_correct) as quiz_correct
            from u group by platform) t
    ), '[]'::jsonb),
    'by_version', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.platform, t.last_day desc, t.app_version desc)
      from (select platform, app_version, min(day) as first_day, max(day) as last_day,
                   sum(active_users) as user_days, sum(course_opens) as course_opens, sum(pages_read) as pages_read,
                   sum(completes) as completes, sum(impressions) as impressions, sum(card_opens) as card_opens,
                   sum(quiz_answers) as quiz_answers, sum(quiz_correct) as quiz_correct
            from public.daily_version_usage d
            where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang) and (p_version is null or d.app_version = p_version)
            group by platform, app_version) t
    ), '[]'::jsonb),
    'top_courses', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.opens desc, t.course_id)
      from (
        select c.course_id, n.title, c.opens, c.readers, c.pages_read, c.completes, c.likes, c.impressions, c.card_opens
        from c
        left join lateral (
          select cc.title from public.course_contents cc
          where cc.course_id = c.course_id and cc.lang in (v_lang, 'fr', 'en')
          order by (cc.lang = v_lang) desc, (cc.lang = 'fr') desc
          limit 1
        ) n on true
        order by c.opens desc, c.course_id
        limit 25
      ) t
    ), '[]'::jsonb),
    'quiz', jsonb_build_object(
      'questions_seen', (select count(*) from q),
      'questions_ranked', (select count(*) from q where answers >= v_min),
      'hardest', coalesce((
        select jsonb_agg(to_jsonb(t) order by t.rate, t.answers desc, t.question_id)
        from (
          select h.question_id, h.course_id, h.answers, h.correct,
                 round(h.correct::numeric / h.answers, 4) as rate, n.title, qq.question
          from (select * from q where answers >= v_min order by correct::numeric / answers, answers desc, question_id limit 25) h
          left join lateral (
            select cc.title from public.course_contents cc
            where cc.course_id = h.course_id and cc.lang in (v_lang, 'fr', 'en')
            order by (cc.lang = v_lang) desc, (cc.lang = 'fr') desc
            limit 1
          ) n on true
          left join lateral (
            select item ->> 'question' as question
            from public.quizzes z, jsonb_array_elements(z.questions) as item
            where z.course_id = h.course_id and z.lang in (v_lang, 'fr', 'en') and item ->> 'id' = h.question_id
            order by (z.lang = v_lang) desc, (z.lang = 'fr') desc
            limit 1
          ) qq on true
        ) t
      ), '[]'::jsonb)
    ),
    'duels', jsonb_build_object(
      'by_kind', coalesce((
        select jsonb_agg(to_jsonb(t) order by t.kind)
        from (select kind, sum(started) as started, sum(finished) as finished, sum(abandoned) as abandoned, sum(players) as player_days from du group by kind) t
      ), '[]'::jsonb),
      'unknown_platform', (select coalesce(sum(started), 0) from public.daily_duel_stats d where d.day >= v_from and d.platform = 'unknown' and (p_lang is null or d.lang = p_lang))
    )
  ) into v_result;

  return v_result;
end;
$$;

create or replace function public.admin_feedback_dashboard(
  p_days integer default 28,
  p_platform text default null,
  p_lang text default null,
  p_version text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := least(greatest(coalesce(p_days, 28), 1), 365);
  v_from timestamptz := ((now() at time zone 'utc')::date - (v_days - 1))::timestamptz;
  v_result jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;

  with f as (
    select * from public.app_feedback a
    where a.created_at >= v_from
      and (p_platform is null or a.platform = p_platform)
      and (p_lang is null or a.lang = p_lang)
      and (p_version is null or a.app_version = p_version)
  )
  select jsonb_build_object(
    'days', v_days,
    'total', (select count(*) from f),
    'versions', coalesce((select jsonb_agg(jsonb_build_object('platform', platform, 'app_version', app_version) order by platform, app_version desc) from (select distinct platform, app_version from public.app_feedback where coalesce(app_version, '') <> '') x), '[]'::jsonb),
    'languages', coalesce((select jsonb_agg(l order by l) from (select distinct lang as l from public.app_feedback where lang is not null) x), '[]'::jsonb),
    'by_category', coalesce((select jsonb_agg(jsonb_build_object('category', category, 'count', n) order by n desc, category) from (select category, count(*) as n from f group by category) t), '[]'::jsonb),
    'items', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.created_at desc)
      from (
        select id, created_at, category, message, has_email, lang, platform, app_version, os_version, device, is_premium
        from f order by created_at desc limit 200
      ) t
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.refresh_daily_paywall_stats(date) from public, anon, authenticated;
revoke all on function public.refresh_daily_onboarding_stats(date) from public, anon, authenticated;
revoke all on function public.refresh_daily_usage_stats(date) from public, anon, authenticated;
revoke all on function public.admin_paywall_dashboard(integer, text, text, text) from public, anon;
grant execute on function public.admin_paywall_dashboard(integer, text, text, text) to authenticated;
revoke all on function public.admin_onboarding_dashboard(integer, text, text, text) from public, anon;
grant execute on function public.admin_onboarding_dashboard(integer, text, text, text) to authenticated;
revoke all on function public.admin_feedback_dashboard(integer, text, text, text) from public, anon;
grant execute on function public.admin_feedback_dashboard(integer, text, text, text) to authenticated;
revoke all on function public.admin_usage_dashboard(integer, text, text, integer, text) from public, anon;
grant execute on function public.admin_usage_dashboard(integer, text, text, integer, text) to authenticated;

-- Reprise de tout ce que les journaux gardent encore.
select public.refresh_daily_paywall_stats(d::date), public.refresh_daily_usage_stats(d::date)
from generate_series((select coalesce(min(ts), now()) from public.course_events)::date, (now() at time zone 'utc')::date, interval '1 day') as d;
select public.refresh_daily_onboarding_stats(d::date)
from generate_series((select coalesce(min(ts), now()) from public.onboarding_events)::date, (now() at time zone 'utc')::date, interval '1 day') as d;
