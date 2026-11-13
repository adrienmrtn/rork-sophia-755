-- Conservation du détail ramenée de 90 à 60 jours, et suivi de santé de la collecte
-- (page /admin/data/health, docs/events.md).
--
-- Les synthèses quotidiennes sont gardées sans limite : seuls les journaux bruts
-- (course_events, onboarding_events) sont concernés. À plein régime, c'est eux qui
-- remplissent le disque.

-- ---------- 60 jours ----------

create or replace function public.ensure_course_events_partitions()
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  d date;
  part text;
  r record;
begin
  for d in select generate_series((now() at time zone 'utc')::date - 1, (now() at time zone 'utc')::date + 7, interval '1 day')::date loop
    part := format('course_events_p%s', to_char(d, 'YYYYMMDD'));
    if to_regclass('analytics.' || part) is null then
      execute format(
        'create table analytics.%I partition of public.course_events for values from (%L) to (%L)',
        part, d::timestamptz, (d + 1)::timestamptz
      );
      execute format('alter table analytics.%I enable row level security', part);
      execute format('revoke all on analytics.%I from anon, authenticated', part);
    end if;
  end loop;

  for r in
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'analytics'
      and c.relname ~ '^course_events_p\d{8}$'
      and to_date(substr(c.relname, 16, 8), 'YYYYMMDD') < (now() at time zone 'utc')::date - 60
  loop
    execute format('drop table analytics.%I', r.relname);
  end loop;
end;
$$;

revoke all on function public.ensure_course_events_partitions() from public, anon, authenticated;

create or replace function public.refresh_recent_onboarding_stats()
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.refresh_daily_onboarding_stats((now() at time zone 'utc')::date);
  perform public.refresh_daily_onboarding_stats((now() at time zone 'utc')::date - 1);
  perform public.refresh_daily_onboarding_stats((now() at time zone 'utc')::date - 2);
  delete from public.onboarding_events where ts < now() - interval '60 days';
end;
$$;

revoke all on function public.refresh_recent_onboarding_stats() from public, anon, authenticated;

comment on table public.course_events is 'Journal brut des événements produit envoyés par les apps (docs/events.md). Partitionné par jour, conservé 60 jours.';
comment on table public.onboarding_events is 'Étapes et réponses de l''onboarding, par installation, envoyées avec ou sans compte par log_onboarding_events. Conservé 60 jours ; la synthèse est dans daily_onboarding_stats.';

-- ---------- volume par jour ----------

-- Combien d'événements arrivent, par jour UTC, plateforme, version de l'app et nom. La page
-- de santé lit cette petite table plutôt que de compter dans le journal à chaque affichage.
create table if not exists public.daily_event_volume (
  day date not null,
  platform text not null,
  app_version text not null default '',
  name text not null,
  events integer not null default 0,
  users integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, app_version, name)
);
comment on table public.daily_event_volume is 'Volume d''événements reçus par jour UTC, plateforme, version de l''app et nom (course_events et onboarding_events). users : utilisateurs ou installations distincts. Conservée sans limite.';

alter table public.daily_event_volume enable row level security;
revoke all on public.daily_event_volume from anon, authenticated;

create or replace function public.refresh_daily_event_volume(target_day date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_from timestamptz := target_day::timestamptz;
  v_to timestamptz := (target_day + 1)::timestamptz;
begin
  delete from public.daily_event_volume where day = target_day;

  insert into public.daily_event_volume (day, platform, app_version, name, events, users, updated_at)
  select target_day, platform, app_version, name, sum(events), sum(users), now()
  from (
    select e.platform, coalesce(e.app_version, '') as app_version, e.name, count(*) as events, count(distinct e.user_id) as users
    from public.course_events e
    where e.ts >= v_from and e.ts < v_to
    group by 1, 2, 3
    union all
    select o.platform, coalesce(o.app_version, ''), o.name, count(*), count(distinct o.install_id)
    from public.onboarding_events o
    where o.ts >= v_from and o.ts < v_to
    group by 1, 2, 3
  ) t
  group by platform, app_version, name;
end;
$$;

-- Le recalcul horaire de l'usage emporte le volume avec lui.
create or replace function public.refresh_recent_usage_stats()
returns void
language sql
security definer
set search_path to 'public'
as $$
  select public.refresh_daily_usage_stats((now() at time zone 'utc')::date);
  select public.refresh_daily_usage_stats((now() at time zone 'utc')::date - 1);
  select public.refresh_daily_usage_stats((now() at time zone 'utc')::date - 2);
  select public.refresh_daily_event_volume((now() at time zone 'utc')::date);
  select public.refresh_daily_event_volume((now() at time zone 'utc')::date - 1);
  select public.refresh_daily_event_volume((now() at time zone 'utc')::date - 2);
$$;

revoke all on function public.refresh_daily_event_volume(date) from public, anon, authenticated;
revoke all on function public.refresh_recent_usage_stats() from public, anon, authenticated;

do $$
declare d date;
begin
  for d in
    select generate_series(
      coalesce((select min(ts at time zone 'utc')::date from public.course_events), (now() at time zone 'utc')::date),
      (now() at time zone 'utc')::date,
      interval '1 day'
    )::date
  loop
    perform public.refresh_daily_event_volume(d);
  end loop;
end $$;

-- ---------- tableau de bord : santé ----------

-- Ce que la page /admin/data/health affiche, en un appel. Réservé à l'équipe.
-- Les tailles viennent du catalogue de Postgres (aucun comptage dans le journal) ; le nombre
-- de lignes du journal est l'estimation du planificateur.
create or replace function public.admin_data_health()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'utc')::date;
  v_result jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;

  with parts as (
    select c.oid, c.relname, greatest(c.reltuples, 0) as tuples, pg_total_relation_size(c.oid) as bytes,
           to_date(substr(c.relname, 16, 8), 'YYYYMMDD') as day
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'analytics' and c.relname ~ '^course_events_p\d{8}$'
  ),
  vol as (
    select * from public.daily_event_volume where day >= v_today - 29
  ),
  runs as (
    select distinct on (j.jobname) j.jobname, j.schedule, j.active, d.status, d.start_time, d.end_time, d.return_message
    from cron.job j
    left join cron.job_run_details d on d.jobid = j.jobid and d.start_time > now() - interval '3 days'
    where j.jobname in ('course_events_partitions', 'daily_course_stats', 'daily_paywall_stats', 'daily_onboarding_stats', 'daily_usage_stats')
    order by j.jobname, d.start_time desc nulls last
  )
  select jsonb_build_object(
    'checked_at', now(),
    'retention_days', 60,
    'database_bytes', pg_database_size(current_database()),
    'journal', jsonb_build_object(
      'bytes', coalesce((select sum(bytes) from parts), 0),
      'rows', coalesce((select sum(tuples)::bigint from parts), 0),
      'days_kept', (select count(*) from parts where day <= v_today and bytes > 32768),
      'oldest_day', (select min(day) from parts where day <= v_today and tuples > 0),
      'onboarding_bytes', pg_total_relation_size('public.onboarding_events'::regclass),
      'summaries_bytes', (
        select coalesce(sum(pg_total_relation_size(c.oid)), 0)
        from pg_class c join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'public' and c.relkind = 'r' and c.relname like 'daily\_%'
      )
    ),
    'series', coalesce((
      select jsonb_agg(jsonb_build_object('day', g.day, 'events', coalesce(t.events, 0), 'ios', coalesce(t.ios, 0), 'android', coalesce(t.android, 0)) order by g.day)
      from (select generate_series(v_today - 29, v_today, interval '1 day')::date as day) g
      left join (
        select day, sum(events) as events,
               sum(events) filter (where platform = 'ios') as ios,
               sum(events) filter (where platform = 'android') as android
        from vol group by day
      ) t using (day)
    ), '[]'::jsonb),
    'last_7_days', jsonb_build_object(
      'events', (select coalesce(sum(events), 0) from vol where day >= v_today - 7 and day < v_today),
      'by_name', coalesce((
        select jsonb_agg(jsonb_build_object('name', name, 'events', events) order by events desc, name)
        from (select name, sum(events) as events from vol where day >= v_today - 7 and day < v_today group by name) t
      ), '[]'::jsonb),
      'by_version', coalesce((
        select jsonb_agg(jsonb_build_object('platform', platform, 'app_version', app_version, 'events', events, 'last_day', last_day) order by platform, events desc)
        from (select platform, app_version, sum(events) as events, max(day) as last_day from vol where day >= v_today - 7 group by platform, app_version) t
      ), '[]'::jsonb)
    ),
    'platforms', coalesce((
      select jsonb_agg(jsonb_build_object('platform', p.platform, 'last_day', t.last_day, 'events_yesterday', coalesce(t.yesterday, 0)) order by p.platform)
      from (values ('ios'), ('android')) as p(platform)
      left join (
        select platform, max(day) as last_day, sum(events) filter (where day = v_today - 1) as yesterday
        from public.daily_event_volume group by platform
      ) t using (platform)
    ), '[]'::jsonb),
    'jobs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', jobname, 'schedule', schedule, 'active', active, 'status', status, 'started_at', start_time,
        'seconds', round(extract(epoch from (end_time - start_time))::numeric, 1),
        'message', case when status = 'failed' then left(return_message, 300) end
      ) order by jobname)
      from runs
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.admin_data_health() from public, anon;
grant execute on function public.admin_data_health() to authenticated;
