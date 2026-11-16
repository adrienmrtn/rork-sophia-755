-- Rétention par cohorte : « a appris » et « a rouvert l'app » séparés (page /admin/data/retention).
--
-- La première version comptait actif un compte qui avait gagné de l'XP *ou* dont l'app avait
-- envoyé un événement. Seules les versions récentes envoient des événements : d'un jour à
-- l'autre la mesure changeait de sens, et le jour de l'inscription tout le monde ouvre l'app.
--
-- - learned_N : comptes qui ont gagné de l'XP (xp_events) le jour J+N. Toutes versions, depuis
--   juillet 2026 : c'est la mesure comparable dans le temps. learned_0 est l'activation.
-- - tracked : comptes dont l'app a envoyé au moins un événement (course_events) le jour de
--   l'inscription, donc qu'on peut voir revenir.
-- - reopened_N : parmi eux, ceux dont l'app a envoyé un événement le jour J+N.
--
-- Les colonnes d0…d30 de la première version restent remplies, pour la fonction
-- admin_retention_dashboard que l'ancienne page appelle encore ; plus rien d'autre ne les lit.

alter table public.daily_cohort_retention
  add column if not exists learned_0 integer not null default 0,
  add column if not exists learned_1 integer not null default 0,
  add column if not exists learned_3 integer not null default 0,
  add column if not exists learned_7 integer not null default 0,
  add column if not exists learned_14 integer not null default 0,
  add column if not exists learned_30 integer not null default 0,
  add column if not exists tracked integer not null default 0,
  add column if not exists reopened_1 integer not null default 0,
  add column if not exists reopened_3 integer not null default 0,
  add column if not exists reopened_7 integer not null default 0,
  add column if not exists reopened_14 integer not null default 0,
  add column if not exists reopened_30 integer not null default 0;

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
  xp as (
    select distinct u.id, (x.created_at at time zone 'utc')::date - u.d as n
    from u join public.xp_events x on x.user_id = u.id and x.created_at >= u.created_at
  ),
  ev as (
    select distinct u.id, (e.ts at time zone 'utc')::date - u.d as n
    from u join public.course_events e on e.user_id = u.id and e.ts >= u.created_at
  ),
  per_user as (
    select id,
           bool_or(learned and n = 0) as l0, bool_or(learned and n = 1) as l1, bool_or(learned and n = 3) as l3,
           bool_or(learned and n = 7) as l7, bool_or(learned and n = 14) as l14, bool_or(learned and n = 30) as l30,
           bool_or(opened and n = 0) as t0, bool_or(opened and n = 1) as o1, bool_or(opened and n = 3) as o3,
           bool_or(opened and n = 7) as o7, bool_or(opened and n = 14) as o14, bool_or(opened and n = 30) as o30
    from (
      select id, n, true as learned, false as opened from xp where n in (0, 1, 3, 7, 14, 30)
      union all
      select id, n, false, true from ev where n in (0, 1, 3, 7, 14, 30)
    ) a
    group by id
  )
  insert into public.daily_cohort_retention
    (cohort_day, signups, d0, d1, d3, d7, d14, d30,
     learned_0, learned_1, learned_3, learned_7, learned_14, learned_30,
     tracked, reopened_1, reopened_3, reopened_7, reopened_14, reopened_30, updated_at)
  select u.d, count(*),
         count(*) filter (where a.l0 or a.t0), count(*) filter (where a.l1 or a.o1), count(*) filter (where a.l3 or a.o3),
         count(*) filter (where a.l7 or a.o7), count(*) filter (where a.l14 or a.o14), count(*) filter (where a.l30 or a.o30),
         count(*) filter (where a.l0), count(*) filter (where a.l1), count(*) filter (where a.l3),
         count(*) filter (where a.l7), count(*) filter (where a.l14), count(*) filter (where a.l30),
         count(*) filter (where a.t0),
         count(*) filter (where a.t0 and a.o1), count(*) filter (where a.t0 and a.o3), count(*) filter (where a.t0 and a.o7),
         count(*) filter (where a.t0 and a.o14), count(*) filter (where a.t0 and a.o30),
         now()
  from u left join per_user a using (id)
  group by u.d
  on conflict (cohort_day) do update set
    signups = excluded.signups, d0 = excluded.d0, d1 = excluded.d1, d3 = excluded.d3,
    d7 = excluded.d7, d14 = excluded.d14, d30 = excluded.d30,
    learned_0 = excluded.learned_0, learned_1 = excluded.learned_1, learned_3 = excluded.learned_3,
    learned_7 = excluded.learned_7, learned_14 = excluded.learned_14, learned_30 = excluded.learned_30,
    tracked = excluded.tracked, reopened_1 = excluded.reopened_1, reopened_3 = excluded.reopened_3,
    reopened_7 = excluded.reopened_7, reopened_14 = excluded.reopened_14, reopened_30 = excluded.reopened_30,
    updated_at = excluded.updated_at;
$$;

revoke all on function public.refresh_cohort_retention(date, date) from public, anon, authenticated;

select public.refresh_cohort_retention(date '2026-07-01', (now() at time zone 'utc')::date);

-- Tout ce que la page /admin/data/retention affiche, en un appel. Réservé à l'équipe.
-- Un jalon n'est rendu que pour les cohortes dont le jour J+N est terminé (UTC). Chaque total
-- porte son propre dénominateur : les inscrits (learned) ou les comptes suivis (reopened) des
-- seules cohortes où le jalon est connu.
create or replace function public.admin_cohort_retention(p_days integer default 28)
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
    select r.cohort_day, r.signups, r.tracked, r.learned_0, m.n,
           (r.cohort_day + m.n < v_today) as known,
           case m.n when 1 then r.learned_1 when 3 then r.learned_3 when 7 then r.learned_7 when 14 then r.learned_14 else r.learned_30 end as learned,
           case m.n when 1 then r.reopened_1 when 3 then r.reopened_3 when 7 then r.reopened_7 when 14 then r.reopened_14 else r.reopened_30 end as reopened
    from public.daily_cohort_retention r
    cross join (values (1), (3), (7), (14), (30)) as m(n)
    where r.cohort_day >= v_from and r.cohort_day <= v_today
  )
  select jsonb_build_object(
    'days', v_days,
    'from', v_from,
    'today', v_today,
    'updated_at', (select max(updated_at) from public.daily_cohort_retention),
    'cohorts', coalesce((
      select jsonb_agg(t.row order by t.cohort_day desc)
      from (
        select cohort_day, jsonb_build_object(
          'day', cohort_day, 'signups', max(signups), 'tracked', max(tracked), 'learned_0', max(learned_0),
          'learned', jsonb_object_agg('d' || n, case when known then learned end),
          'reopened', jsonb_object_agg('d' || n, case when known then reopened end)
        ) as row
        from c group by cohort_day
      ) t
    ), '[]'::jsonb),
    'totals', jsonb_build_object(
      'signups', (select coalesce(sum(signups), 0) from c where n = 1),
      'tracked', (select coalesce(sum(tracked), 0) from c where n = 1),
      'learned_0', (select coalesce(sum(learned_0), 0) from c where n = 1),
      'learned', coalesce((
        select jsonb_object_agg('d' || n, jsonb_build_object('active', active, 'base', base))
        from (select n, coalesce(sum(learned) filter (where known), 0) as active, coalesce(sum(signups) filter (where known), 0) as base from c group by n) t
      ), '{}'::jsonb),
      'reopened', coalesce((
        select jsonb_object_agg('d' || n, jsonb_build_object('active', active, 'base', base))
        from (select n, coalesce(sum(reopened) filter (where known), 0) as active, coalesce(sum(tracked) filter (where known), 0) as base from c group by n) t
      ), '{}'::jsonb)
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.admin_cohort_retention(integer) from public, anon;
grant execute on function public.admin_cohort_retention(integer) to authenticated;
