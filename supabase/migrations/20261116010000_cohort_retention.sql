-- Rétention par cohorte d'inscription (page /admin/data/retention, docs/events.md).
--
-- Une cohorte : les comptes créés un même jour UTC. Pour chaque cohorte, combien sont
-- actifs le jour même (J0), puis exactement 1, 3, 7, 14 et 30 jours plus tard.
--
-- « Actif » un jour donné : le compte a gagné de l'XP ce jour-là (xp_events : cours ou quiz
-- terminé, progression, depuis juillet 2026 et quelle que soit la version de l'app) ou son
-- app a envoyé au moins un événement (course_events, versions récentes seulement, gardé
-- 60 jours). La synthèse est gardée sans limite.

create table if not exists public.daily_cohort_retention (
  cohort_day date primary key,
  signups integer not null default 0,
  d0 integer not null default 0,
  d1 integer not null default 0,
  d3 integer not null default 0,
  d7 integer not null default 0,
  d14 integer not null default 0,
  d30 integer not null default 0,
  updated_at timestamptz not null default now()
);
comment on table public.daily_cohort_retention is 'Rétention par cohorte d''inscription (jour UTC de création du compte) : comptes actifs à J0, J+1, J+3, J+7, J+14 et J+30. Actif : XP gagné (xp_events) ou événement envoyé par l''app (course_events) ce jour-là. Conservée sans limite.';

alter table public.daily_cohort_retention enable row level security;
revoke all on public.daily_cohort_retention from anon, authenticated;

-- ---------- calcul d'une plage de cohortes ----------

create or replace function public.refresh_cohort_retention(p_from date, p_to date)
returns void
language sql
security definer
set search_path to 'public'
as $$
  with u as (
    select id, created_at, (created_at at time zone 'utc')::date as d
    from auth.users
    where created_at >= p_from::timestamp at time zone 'utc'
      and created_at < (p_to + 1)::timestamp at time zone 'utc'
  ),
  act as (
    select u.id, (x.created_at at time zone 'utc')::date - u.d as n
    from u join public.xp_events x on x.user_id = u.id and x.created_at >= u.created_at
    union
    select u.id, (e.ts at time zone 'utc')::date - u.d
    from u join public.course_events e on e.user_id = u.id and e.ts >= u.created_at
  ),
  per_user as (
    select id,
           bool_or(n = 0) as d0, bool_or(n = 1) as d1, bool_or(n = 3) as d3,
           bool_or(n = 7) as d7, bool_or(n = 14) as d14, bool_or(n = 30) as d30
    from act
    where n in (0, 1, 3, 7, 14, 30)
    group by id
  )
  insert into public.daily_cohort_retention (cohort_day, signups, d0, d1, d3, d7, d14, d30, updated_at)
  select u.d, count(*),
         count(*) filter (where a.d0), count(*) filter (where a.d1), count(*) filter (where a.d3),
         count(*) filter (where a.d7), count(*) filter (where a.d14), count(*) filter (where a.d30),
         now()
  from u left join per_user a using (id)
  group by u.d
  on conflict (cohort_day) do update set
    signups = excluded.signups, d0 = excluded.d0, d1 = excluded.d1, d3 = excluded.d3,
    d7 = excluded.d7, d14 = excluded.d14, d30 = excluded.d30, updated_at = excluded.updated_at;
$$;

-- Toutes les heures : les cohortes dont un jalon peut encore bouger (J+30 au plus).
create or replace function public.refresh_recent_cohort_retention()
returns void
language sql
security definer
set search_path to 'public'
as $$
  select public.refresh_cohort_retention((now() at time zone 'utc')::date - 31, (now() at time zone 'utc')::date);
$$;

revoke all on function public.refresh_cohort_retention(date, date) from public, anon, authenticated;
revoke all on function public.refresh_recent_cohort_retention() from public, anon, authenticated;

-- Reprise de l'historique : xp_events remonte au lancement.
select public.refresh_cohort_retention(date '2026-07-01', (now() at time zone 'utc')::date);

select cron.unschedule(jobid) from cron.job where jobname = 'daily_cohort_retention';
select cron.schedule('daily_cohort_retention', '55 * * * *', $$select public.refresh_recent_cohort_retention()$$);

-- ---------- tableau de bord ----------

-- Tout ce que la page /admin/data/retention affiche, en un appel. Réservé à l'équipe.
-- Un jalon n'est rendu que pour les cohortes dont le jour J+N est terminé (UTC) : avant,
-- la part serait sous-estimée. Les totaux ne comptent, pour chaque jalon, que ces cohortes.
create or replace function public.admin_retention_dashboard(p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := least(greatest(coalesce(p_days, 28), 1), 365);
  v_today date := (now() at time zone 'utc')::date;
  v_from date := v_today - (v_days - 1);
  v_result jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;

  with c as (
    select cohort_day, signups, d0,
           case when cohort_day + 1 < v_today then d1 end as d1,
           case when cohort_day + 3 < v_today then d3 end as d3,
           case when cohort_day + 7 < v_today then d7 end as d7,
           case when cohort_day + 14 < v_today then d14 end as d14,
           case when cohort_day + 30 < v_today then d30 end as d30
    from public.daily_cohort_retention
    where cohort_day >= v_from and cohort_day <= v_today
  )
  select jsonb_build_object(
    'days', v_days,
    'from', v_from,
    'today', v_today,
    'updated_at', (select max(updated_at) from public.daily_cohort_retention),
    'cohorts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'day', cohort_day, 'signups', signups, 'd0', d0, 'd1', d1, 'd3', d3, 'd7', d7, 'd14', d14, 'd30', d30
      ) order by cohort_day desc) from c
    ), '[]'::jsonb),
    'totals', (
      select jsonb_build_object(
        'signups', coalesce(sum(signups), 0),
        'd0', coalesce(sum(d0), 0),
        'd1', jsonb_build_object('active', coalesce(sum(d1), 0), 'signups', coalesce(sum(signups) filter (where d1 is not null), 0)),
        'd3', jsonb_build_object('active', coalesce(sum(d3), 0), 'signups', coalesce(sum(signups) filter (where d3 is not null), 0)),
        'd7', jsonb_build_object('active', coalesce(sum(d7), 0), 'signups', coalesce(sum(signups) filter (where d7 is not null), 0)),
        'd14', jsonb_build_object('active', coalesce(sum(d14), 0), 'signups', coalesce(sum(signups) filter (where d14 is not null), 0)),
        'd30', jsonb_build_object('active', coalesce(sum(d30), 0), 'signups', coalesce(sum(signups) filter (where d30 is not null), 0))
      ) from c
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.admin_retention_dashboard(integer) from public, anon;
grant execute on function public.admin_retention_dashboard(integer) to authenticated;
