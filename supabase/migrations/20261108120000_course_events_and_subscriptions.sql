-- Journal d'événements produit (course_events), synthèses quotidiennes et statut
-- d'abonnement connu du serveur (webhook RevenueCat + instantané envoyé par l'app).
-- Appliqué à distance via Supabase MCP (projet afnmcoovdvbtkgohtdij). Voir docs/events.md.

-- ---------- extensions ----------

create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;

-- Les partitions vivent dans un schéma que PostgREST n'expose pas : seule la table
-- parente public.course_events est visible par l'API, avec ses règles RLS.
create schema if not exists analytics;
revoke all on schema analytics from anon, authenticated;

-- ---------- course_events ----------

create table if not exists public.course_events (
  event_id uuid not null,
  user_id uuid not null,
  install_id uuid,
  session_id uuid,
  name text not null,
  course_id text,
  lang text,
  country text,
  platform text not null,
  app_version text,
  premium_status text,
  screen text,
  position integer,
  algo_version text,
  props jsonb not null default '{}'::jsonb,
  ts timestamptz not null,
  received_at timestamptz not null default now(),
  primary key (ts, event_id),
  constraint course_events_name_check check (name in (
    'app_open', 'onboarding_step',
    'card_impression', 'card_skip', 'card_open',
    'course_open', 'section_view', 'course_complete',
    'glossary_open', 'funfact_open', 'audio_play',
    'quiz_start', 'quiz_answer', 'quiz_complete',
    'like', 'unlike', 'save', 'unsave', 'share',
    'follow', 'unfollow', 'not_interested', 'report',
    'paywall_view', 'purchase_started', 'purchase_completed', 'purchase_failed'
  )),
  constraint course_events_platform_check check (platform in ('ios', 'android')),
  constraint course_events_premium_check check (premium_status is null or premium_status in ('free', 'trial', 'paid', 'unknown')),
  constraint course_events_lang_check check (lang is null or char_length(lang) between 2 and 5),
  constraint course_events_country_check check (country is null or char_length(country) = 2),
  constraint course_events_props_size check (pg_column_size(props) <= 2048),
  constraint course_events_position_check check (position is null or position between 0 and 10000)
) partition by range (ts);

comment on table public.course_events is 'Journal brut des événements produit envoyés par les apps (docs/events.md). Partitionné par jour, conservé 90 jours.';

create index if not exists course_events_course_name_ts on public.course_events (course_id, name, ts);
create index if not exists course_events_user_ts on public.course_events (user_id, ts);
create index if not exists course_events_name_ts on public.course_events (name, ts);

alter table public.course_events enable row level security;

-- L'app insère ses propres événements, et rien d'autre : pas de lecture, pas de
-- mise à jour. L'horodatage doit être plausible (file hors ligne de 30 jours max).
drop policy if exists course_events_insert_own on public.course_events;
create policy course_events_insert_own on public.course_events
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and ts > now() - interval '30 days'
    and ts < now() + interval '15 minutes'
  );

revoke all on public.course_events from anon;
revoke select, update, delete, truncate, references, trigger on public.course_events from authenticated;
grant insert on public.course_events to authenticated;

-- Partitions : une par jour UTC, créées 7 jours à l'avance, supprimées après 90 jours.
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
      and to_date(substr(c.relname, 16, 8), 'YYYYMMDD') < (now() at time zone 'utc')::date - 90
  loop
    execute format('drop table analytics.%I', r.relname);
  end loop;
end;
$$;

revoke all on function public.ensure_course_events_partitions() from public, anon, authenticated;

select public.ensure_course_events_partitions();

-- ---------- synthèses quotidiennes ----------

create table if not exists public.daily_course_stats (
  day date not null,
  course_id text not null,
  lang text not null,
  impressions integer not null default 0,
  skips integer not null default 0,
  opens integer not null default 0,
  section_views integer not null default 0,
  completes integer not null default 0,
  quiz_answers integer not null default 0,
  quiz_correct integer not null default 0,
  likes integer not null default 0,
  saves integer not null default 0,
  shares integer not null default 0,
  viewers integer not null default 0,
  readers integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, course_id, lang)
);

comment on table public.daily_course_stats is 'Synthèse par cours, langue et jour UTC, calculée chaque nuit depuis course_events. Conservée sans limite.';

alter table public.daily_course_stats enable row level security;
revoke all on public.daily_course_stats from anon, authenticated;

create or replace function public.refresh_daily_course_stats(target_day date)
returns void
language sql
security definer
set search_path to 'public'
as $$
  insert into public.daily_course_stats as d
    (day, course_id, lang, impressions, skips, opens, section_views, completes,
     quiz_answers, quiz_correct, likes, saves, shares, viewers, readers, updated_at)
  select
    target_day,
    e.course_id,
    coalesce(e.lang, 'unknown'),
    count(*) filter (where e.name = 'card_impression'),
    count(*) filter (where e.name = 'card_skip'),
    count(*) filter (where e.name = 'course_open'),
    count(*) filter (where e.name = 'section_view'),
    count(*) filter (where e.name = 'course_complete'),
    count(*) filter (where e.name = 'quiz_answer'),
    count(*) filter (where e.name = 'quiz_answer' and (e.props ->> 'correct')::boolean),
    count(*) filter (where e.name = 'like'),
    count(*) filter (where e.name = 'save'),
    count(*) filter (where e.name = 'share'),
    count(distinct e.user_id) filter (where e.name = 'card_impression'),
    count(distinct e.user_id) filter (where e.name = 'course_open'),
    now()
  from public.course_events e
  where e.ts >= target_day::timestamptz
    and e.ts < (target_day + 1)::timestamptz
    and e.course_id is not null
  group by e.course_id, coalesce(e.lang, 'unknown')
  on conflict (day, course_id, lang) do update set
    impressions = excluded.impressions,
    skips = excluded.skips,
    opens = excluded.opens,
    section_views = excluded.section_views,
    completes = excluded.completes,
    quiz_answers = excluded.quiz_answers,
    quiz_correct = excluded.quiz_correct,
    likes = excluded.likes,
    saves = excluded.saves,
    shares = excluded.shares,
    viewers = excluded.viewers,
    readers = excluded.readers,
    updated_at = now();
$$;

create or replace function public.refresh_recent_course_stats()
returns void
language sql
security definer
set search_path to 'public'
as $$
  select public.refresh_daily_course_stats((now() at time zone 'utc')::date - 1);
  select public.refresh_daily_course_stats((now() at time zone 'utc')::date - 2);
$$;

revoke all on function public.refresh_daily_course_stats(date) from public, anon, authenticated;
revoke all on function public.refresh_recent_course_stats() from public, anon, authenticated;

-- Contrôle de la collecte : événements par jour, plateforme et version (30 derniers jours).
create or replace view public.events_health
with (security_invoker = false)
as
select
  (ts at time zone 'utc')::date as day,
  platform,
  app_version,
  count(*) as events,
  count(distinct user_id) as users,
  count(*) filter (where name = 'card_impression') as impressions,
  count(*) filter (where name = 'course_open') as opens,
  count(*) filter (where name = 'course_complete') as completes,
  count(*) filter (where name = 'quiz_answer') as quiz_answers,
  count(*) filter (where name = 'paywall_view') as paywall_views
from public.course_events
where ts > now() - interval '30 days'
group by 1, 2, 3
order by 1 desc, 2, 3;

revoke all on public.events_health from anon, authenticated;

-- ---------- abonnements : webhook RevenueCat ----------

create table if not exists public.subscription_events (
  id bigint generated always as identity primary key,
  rc_event_id text not null unique,
  type text not null,
  app_user_id text not null,
  original_app_user_id text,
  user_id uuid,
  aliases text[] not null default '{}',
  product_id text,
  entitlement_ids text[] not null default '{}',
  period_type text,
  store text,
  environment text,
  price numeric,
  currency text,
  price_in_purchased_currency numeric,
  takehome_percentage numeric,
  country_code text,
  offer_code text,
  cancel_reason text,
  is_trial_conversion boolean,
  renewal_number integer,
  presented_offering_id text,
  transaction_id text,
  original_transaction_id text,
  purchased_at timestamptz,
  expiration_at timestamptz,
  event_ts timestamptz not null,
  raw jsonb not null,
  received_at timestamptz not null default now()
);

comment on table public.subscription_events is 'Événements RevenueCat reçus par la fonction revenuecat-webhook. user_id = app_user_id (ou un alias) quand c''est un uuid Supabase.';

create index if not exists subscription_events_user_ts on public.subscription_events (user_id, event_ts desc);
create index if not exists subscription_events_app_user_ts on public.subscription_events (app_user_id, event_ts desc);
create index if not exists subscription_events_ts on public.subscription_events (event_ts);

alter table public.subscription_events enable row level security;
revoke all on public.subscription_events from anon, authenticated;

-- ---------- abonnements : instantané envoyé par l'app ----------

create table if not exists public.subscriber_snapshots (
  user_id uuid primary key references auth.users (id) on delete cascade,
  is_active boolean not null,
  period_type text,
  product_id text,
  store text,
  expires_at timestamptz,
  will_renew boolean,
  platform text,
  app_version text,
  reported_at timestamptz not null default now(),
  constraint subscriber_snapshots_period_check check (period_type is null or period_type in ('trial', 'intro', 'normal', 'promotional'))
);

comment on table public.subscriber_snapshots is 'Statut d''abonnement tel que l''app le connaît (CustomerInfo RevenueCat), envoyé à chaque lancement. Complète le webhook pour les abonnés déjà actifs.';

alter table public.subscriber_snapshots enable row level security;

drop policy if exists subscriber_snapshots_own on public.subscriber_snapshots;
create policy subscriber_snapshots_own on public.subscriber_snapshots
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

revoke all on public.subscriber_snapshots from anon;
revoke delete, truncate, references, trigger on public.subscriber_snapshots from authenticated;

-- Statut Premium courant par utilisateur : la source la plus récente l'emporte.
create or replace view public.premium_status
with (security_invoker = false)
as
with webhook as (
  select distinct on (user_id)
    user_id,
    coalesce(expiration_at > now(), false) and type <> 'EXPIRATION' as is_active,
    lower(period_type) as period_type,
    product_id,
    store,
    expiration_at as expires_at,
    event_ts as as_of
  from public.subscription_events
  where user_id is not null
  order by user_id, event_ts desc
)
select
  coalesce(w.user_id, s.user_id) as user_id,
  case
    when w.user_id is not null and (s.user_id is null or w.as_of >= s.reported_at) then w.is_active
    else s.is_active
  end as is_active,
  case
    when w.user_id is not null and (s.user_id is null or w.as_of >= s.reported_at) then w.period_type
    else s.period_type
  end as period_type,
  case
    when w.user_id is not null and (s.user_id is null or w.as_of >= s.reported_at) then w.product_id
    else s.product_id
  end as product_id,
  case
    when w.user_id is not null and (s.user_id is null or w.as_of >= s.reported_at) then w.store
    else s.store
  end as store,
  case
    when w.user_id is not null and (s.user_id is null or w.as_of >= s.reported_at) then w.expires_at
    else s.expires_at
  end as expires_at,
  case
    when w.user_id is not null and (s.user_id is null or w.as_of >= s.reported_at) then 'webhook'
    else 'snapshot'
  end as source,
  greatest(coalesce(w.as_of, '-infinity'::timestamptz), coalesce(s.reported_at, '-infinity'::timestamptz)) as as_of
from webhook w
full outer join public.subscriber_snapshots s on s.user_id = w.user_id;

revoke all on public.premium_status from anon, authenticated;

-- ---------- tâches planifiées ----------

select cron.unschedule(jobid) from cron.job where jobname in ('course_events_partitions', 'daily_course_stats');
select cron.schedule('course_events_partitions', '5 0 * * *', $$select public.ensure_course_events_partitions()$$);
select cron.schedule('daily_course_stats', '20 2 * * *', $$select public.refresh_recent_course_stats()$$);
