-- Onboarding : collecte sans compte, synthèse quotidienne et tableau de bord (docs/events.md).
--
-- course_events n'accepte que les lignes d'un utilisateur connecté, et la connexion arrive
-- au vingt-sixième écran de l'onboarding : quelqu'un qui abandonne avant n'y laisse aucune
-- trace. Les étapes et les réponses de l'onboarding passent donc par une fonction ouverte
-- sans compte, qui écrit dans une table à part, rattachée à l'identifiant d'installation
-- (un UUID tiré au hasard par l'app : ni nom, ni adresse).

-- ---------- journal brut (90 jours) ----------

create table if not exists public.onboarding_events (
  event_id uuid primary key,
  install_id uuid not null,
  user_id uuid,
  session_id uuid,
  name text not null,
  step text,
  step_index integer,
  question text,
  answer text,
  lang text,
  country text,
  platform text not null,
  app_version text,
  ts timestamptz not null,
  received_at timestamptz not null default now(),
  constraint onboarding_events_name_check check (name in ('onboarding_step', 'onboarding_answer')),
  constraint onboarding_events_platform_check check (platform in ('ios', 'android'))
);

comment on table public.onboarding_events is 'Étapes et réponses de l''onboarding, par installation, envoyées avec ou sans compte par log_onboarding_events. Conservé 90 jours ; la synthèse est dans daily_onboarding_stats.';

create index if not exists onboarding_events_ts on public.onboarding_events (ts);
create index if not exists onboarding_events_install_ts on public.onboarding_events (install_id, ts);

alter table public.onboarding_events enable row level security;
revoke all on public.onboarding_events from anon, authenticated;

-- ---------- entrée ----------

-- Les apps envoient leurs lignes telles qu'elles les gardent en file (les colonnes de
-- course_events, la réponse dans props). Tout ce qui n'a pas la forme attendue est écarté
-- sans erreur : un lot n'est jamais refusé pour une ligne. Garde-fous, la fonction étant
-- appelable sans compte : 200 lignes par appel, horodatage plausible, textes bornés, et
-- 2 000 lignes au plus par installation.
create or replace function public.log_onboarding_events(p_events jsonb)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer;
  v_uuid constant text := '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
  v_ts constant text := '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?(Z|[+-]\d{2}:\d{2})$';
begin
  if p_events is null or jsonb_typeof(p_events) <> 'array' or jsonb_array_length(p_events) > 200 then
    raise exception 'events: un tableau de 200 lignes au plus' using errcode = '22023';
  end if;

  with raw as materialized (
    select e
    from jsonb_array_elements(p_events) as t(e)
    where jsonb_typeof(e) = 'object'
      and e ->> 'event_id' ~ v_uuid
      and e ->> 'install_id' ~ v_uuid
      and e ->> 'ts' ~ v_ts
      and e ->> 'name' in ('onboarding_step', 'onboarding_answer')
      and e ->> 'platform' in ('ios', 'android')
  ),
  parsed as materialized (
    select
      (e ->> 'event_id')::uuid as event_id,
      (e ->> 'install_id')::uuid as install_id,
      case when e ->> 'session_id' ~ v_uuid then (e ->> 'session_id')::uuid end as session_id,
      e ->> 'name' as name,
      left(nullif(e #>> '{props,step}', ''), 40) as step,
      case when e #>> '{props,index}' ~ '^\d{1,4}$' then (e #>> '{props,index}')::integer end as step_index,
      left(nullif(e #>> '{props,question}', ''), 40) as question,
      left(nullif(e #>> '{props,answer}', ''), 200) as answer,
      case when char_length(e ->> 'lang') between 2 and 5 then e ->> 'lang' end as lang,
      case when char_length(e ->> 'country') = 2 then upper(e ->> 'country') end as country,
      e ->> 'platform' as platform,
      left(e ->> 'app_version', 32) as app_version,
      (e ->> 'ts')::timestamptz as ts
    from raw
  ),
  inserted as (
    insert into public.onboarding_events
      (event_id, install_id, user_id, session_id, name, step, step_index, question, answer,
       lang, country, platform, app_version, ts)
    select
      p.event_id, p.install_id, auth.uid(), p.session_id, p.name, p.step, p.step_index, p.question, p.answer,
      p.lang, p.country, p.platform, p.app_version, p.ts
    from parsed p
    where p.ts > now() - interval '30 days'
      and p.ts < now() + interval '15 minutes'
      and ((p.name = 'onboarding_step' and p.step is not null)
        or (p.name = 'onboarding_answer' and p.question is not null and p.answer is not null))
      and (select count(*) from public.onboarding_events x where x.install_id = p.install_id) < 2000
    on conflict (event_id) do nothing
    returning 1
  )
  select count(*) into v_inserted from inserted;
  return v_inserted;
end;
$$;

revoke all on function public.log_onboarding_events(jsonb) from public;
grant execute on function public.log_onboarding_events(jsonb) to anon, authenticated;

-- Reprise des étapes que les versions de test ont déjà envoyées dans course_events.
insert into public.onboarding_events
  (event_id, install_id, user_id, session_id, name, step, step_index, question, answer,
   lang, country, platform, app_version, ts, received_at)
select
  e.event_id, e.install_id, e.user_id, e.session_id,
  case when e.props ->> 'step' = 'loading_question' then 'onboarding_answer' else 'onboarding_step' end,
  case when e.props ->> 'step' = 'loading_question' then 'loading' else e.props ->> 'step' end,
  case when e.props ->> 'index' ~ '^\d{1,4}$' then (e.props ->> 'index')::integer end,
  case when e.props ->> 'step' = 'loading_question' then e.props ->> 'question' end,
  case when e.props ->> 'step' = 'loading_question' then e.props ->> 'answer' end,
  e.lang, e.country, e.platform, e.app_version, e.ts, e.received_at
from public.course_events e
where e.name = 'onboarding_step'
  and e.install_id is not null
  and e.props ->> 'step' is not null
on conflict (event_id) do nothing;

-- ---------- synthèse quotidienne (sans limite) ----------

-- kind = 'step'     : key = l'écran, value = '' ; installations qui l'ont vu ce jour-là.
-- kind = 'answered' : key = la question, value = '' ; installations qui y ont répondu.
-- kind = 'answer'   : key = la question, value = une option ; installations qui l'ont
--                     choisie (une réponse à choix multiples compte dans chacune de ses options).
-- La réponse retenue est la dernière donnée par l'installation ce jour-là.
create table if not exists public.daily_onboarding_stats (
  day date not null,
  platform text not null,
  lang text not null,
  kind text not null,
  key text not null,
  value text not null default '',
  installs integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, lang, kind, key, value),
  constraint daily_onboarding_stats_kind_check check (kind in ('step', 'answered', 'answer'))
);

comment on table public.daily_onboarding_stats is 'Synthèse de l''onboarding par jour UTC, plateforme et langue : installations par écran, par question et par réponse. Conservée sans limite.';

alter table public.daily_onboarding_stats enable row level security;
revoke all on public.daily_onboarding_stats from anon, authenticated;

create or replace function public.refresh_daily_onboarding_stats(target_day date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  delete from public.daily_onboarding_stats where day = target_day;

  insert into public.daily_onboarding_stats (day, platform, lang, kind, key, value, installs, updated_at)
  with ev as (
    select e.install_id, e.platform, coalesce(e.lang, 'unknown') as lang, e.name, e.step, e.question, e.answer, e.ts
    from public.onboarding_events e
    where e.ts >= target_day::timestamptz
      and e.ts < (target_day + 1)::timestamptz
  ),
  last_answers as (
    select distinct on (install_id, question) install_id, platform, lang, question, answer
    from ev
    where name = 'onboarding_answer'
    order by install_id, question, ts desc
  )
  select target_day, platform, lang, 'step', step, '', count(distinct install_id), now()
  from ev where name = 'onboarding_step'
  group by platform, lang, step
  union all
  select target_day, platform, lang, 'answered', question, '', count(distinct install_id), now()
  from last_answers
  group by platform, lang, question
  union all
  select target_day, a.platform, a.lang, 'answer', a.question, o.option, count(distinct a.install_id), now()
  from last_answers a
  cross join lateral (select distinct trim(x) as option from unnest(string_to_array(a.answer, ',')) as x where trim(x) <> '') o
  group by a.platform, a.lang, a.question, o.option;
end;
$$;

-- Toutes les heures : le jour en cours et les deux précédents, puis la purge du brut.
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
  delete from public.onboarding_events where ts < now() - interval '90 days';
end;
$$;

revoke all on function public.refresh_daily_onboarding_stats(date) from public, anon, authenticated;
revoke all on function public.refresh_recent_onboarding_stats() from public, anon, authenticated;

do $$
declare d date;
begin
  for d in
    select generate_series(
      coalesce((select min(ts at time zone 'utc')::date from public.onboarding_events), (now() at time zone 'utc')::date),
      (now() at time zone 'utc')::date,
      interval '1 day'
    )::date
  loop
    perform public.refresh_daily_onboarding_stats(d);
  end loop;
end $$;

select cron.unschedule(jobid) from cron.job where jobname = 'daily_onboarding_stats';
select cron.schedule('daily_onboarding_stats', '35 * * * *', $$select public.refresh_recent_onboarding_stats()$$);

-- ---------- tableau de bord ----------

-- Ce que la page /admin/data/onboarding affiche, en un appel. Réservé à l'équipe.
create or replace function public.admin_onboarding_dashboard(
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
  )
  select jsonb_build_object(
    'days', v_days,
    'from', v_from,
    'updated_at', (select max(updated_at) from public.daily_onboarding_stats),
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

revoke all on function public.admin_onboarding_dashboard(integer, text, text) from public, anon;
grant execute on function public.admin_onboarding_dashboard(integer, text, text) to authenticated;
