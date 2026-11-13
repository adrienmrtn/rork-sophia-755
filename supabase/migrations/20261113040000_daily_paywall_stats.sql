-- Synthèse quotidienne des paywalls et tableau de bord /admin/data (docs/events.md).
--
-- course_events n'est gardé que 90 jours ; cette table garde pour toujours, par jour UTC,
-- plateforme, langue, paywall, offre et variante de test A/B : les affichages, les achats
-- lancés, réussis et non aboutis. Les revenus viennent de subscription_events (webhook
-- RevenueCat), conservé sans limite, et sont lus directement.

-- ---------- table ----------

create table if not exists public.daily_paywall_stats (
  day date not null,
  platform text not null,
  lang text not null,
  paywall_id text not null,
  offering text not null default '',
  experiment text not null default '',
  variant text not null default '',
  views integer not null default 0,
  viewers integer not null default 0,
  purchases_started integer not null default 0,
  purchases_completed integer not null default 0,
  buyers integer not null default 0,
  purchases_cancelled integer not null default 0,
  purchases_failed integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, lang, paywall_id, offering, experiment, variant)
);

comment on table public.daily_paywall_stats is 'Synthèse des paywalls par jour UTC, plateforme, langue, paywall, offre et variante A/B, calculée depuis course_events. Conservée sans limite. viewers et buyers sont des utilisateurs distincts par jour.';

alter table public.daily_paywall_stats enable row level security;
revoke all on public.daily_paywall_stats from anon, authenticated;

-- ---------- calcul d'un jour ----------

-- Un achat est rattaché à son paywall par la propriété paywall_id de l'événement d'achat.
-- Les versions qui ne l'envoient pas encore sont rattachées au dernier paywall affiché au
-- même utilisateur dans l'heure qui précède ; à défaut, le paywall est « unknown ».
-- L'offre et la variante viennent de l'affichage, pour que les lignes d'achat tombent sur
-- les mêmes clés que les lignes d'affichage.
create or replace function public.refresh_daily_paywall_stats(target_day date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  delete from public.daily_paywall_stats where day = target_day;

  insert into public.daily_paywall_stats
    (day, platform, lang, paywall_id, offering, experiment, variant,
     views, viewers, purchases_started, purchases_completed, buyers,
     purchases_cancelled, purchases_failed, updated_at)
  with ev as (
    select
      e.name,
      e.user_id,
      e.platform,
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
    target_day, platform, lang, paywall_id, offering, experiment, variant,
    count(*) filter (where name = 'paywall_view'),
    count(distinct user_id) filter (where name = 'paywall_view'),
    count(*) filter (where name = 'purchase_started'),
    count(*) filter (where name = 'purchase_completed'),
    count(distinct user_id) filter (where name = 'purchase_completed'),
    count(*) filter (where name = 'purchase_failed' and reason = 'cancelled'),
    count(*) filter (where name = 'purchase_failed' and reason is distinct from 'cancelled'),
    now()
  from ev
  group by platform, lang, paywall_id, offering, experiment, variant;
end;
$$;

-- Aujourd'hui et les deux jours précédents : la journée en cours se remplit d'heure en
-- heure, et un événement arrivé en retard (file hors ligne) est rattrapé pendant deux jours.
create or replace function public.refresh_recent_paywall_stats()
returns void
language sql
security definer
set search_path to 'public'
as $$
  select public.refresh_daily_paywall_stats((now() at time zone 'utc')::date);
  select public.refresh_daily_paywall_stats((now() at time zone 'utc')::date - 1);
  select public.refresh_daily_paywall_stats((now() at time zone 'utc')::date - 2);
$$;

revoke all on function public.refresh_daily_paywall_stats(date) from public, anon, authenticated;
revoke all on function public.refresh_recent_paywall_stats() from public, anon, authenticated;

-- Reprise de tout ce que course_events contient encore.
do $$
declare d date;
begin
  for d in
    select generate_series(
      coalesce((select min(ts at time zone 'utc')::date from public.course_events where name = 'paywall_view'), (now() at time zone 'utc')::date),
      (now() at time zone 'utc')::date,
      interval '1 day'
    )::date
  loop
    perform public.refresh_daily_paywall_stats(d);
  end loop;
end $$;

select cron.unschedule(jobid) from cron.job where jobname = 'daily_paywall_stats';
select cron.schedule('daily_paywall_stats', '25 * * * *', $$select public.refresh_recent_paywall_stats()$$);

-- ---------- tableau de bord ----------

-- Tout ce que la page /admin/data affiche, en un appel. Réservé à l'équipe.
-- p_platform : 'ios', 'android' ou null (toutes) ; p_lang : une langue ou null (toutes).
-- Les revenus (RevenueCat) ne connaissent pas la langue de l'app : ils suivent la période
-- et la plateforme, pas le filtre de langue.
create or replace function public.admin_paywall_dashboard(
  p_days integer default 28,
  p_platform text default null,
  p_lang text default null
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

revoke all on function public.admin_paywall_dashboard(integer, text, text) from public, anon;
grant execute on function public.admin_paywall_dashboard(integer, text, text) to authenticated;
