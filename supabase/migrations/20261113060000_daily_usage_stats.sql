-- Usage, quiz, duels et retours : synthèses quotidiennes et tableaux de bord
-- /admin/data/usage et /admin/data/feedback (docs/events.md).
--
-- course_events n'est gardé que 90 jours et daily_course_stats ne connaît pas la plateforme.
-- Ces quatre tables gardent sans limite, par jour UTC, plateforme et langue : l'usage global,
-- l'usage par cours, les réponses par question de quiz, et les duels. Les duels sont comptés
-- depuis les tables du jeu (duel_matches, duel_friend_matches), pas depuis des événements de
-- l'app : le serveur connaît chaque partie, quelle que soit la version de l'app.

create table if not exists public.daily_usage_stats (
  day date not null,
  platform text not null,
  lang text not null,
  active_users integer not null default 0,
  sessions integer not null default 0,
  course_opens integer not null default 0,
  readers integer not null default 0,
  pages_read integer not null default 0,
  completes integer not null default 0,
  likes integer not null default 0,
  saves integer not null default 0,
  shares integer not null default 0,
  quiz_answers integer not null default 0,
  quiz_correct integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, lang)
);
comment on table public.daily_usage_stats is 'Usage de l''app par jour UTC, plateforme et langue, depuis course_events. active_users et readers sont des utilisateurs distincts par jour ; pages_read compte les section_view. Conservée sans limite.';

create table if not exists public.daily_course_usage (
  day date not null,
  platform text not null,
  lang text not null,
  course_id text not null,
  opens integer not null default 0,
  readers integer not null default 0,
  pages_read integer not null default 0,
  completes integer not null default 0,
  likes integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, lang, course_id)
);
comment on table public.daily_course_usage is 'Usage par cours, jour UTC, plateforme et langue, depuis course_events. Conservée sans limite.';
create index if not exists daily_course_usage_course on public.daily_course_usage (course_id, day);

create table if not exists public.daily_quiz_question_stats (
  day date not null,
  platform text not null,
  lang text not null,
  question_id text not null,
  course_id text not null default '',
  answers integer not null default 0,
  correct integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, lang, question_id)
);
comment on table public.daily_quiz_question_stats is 'Réponses et bonnes réponses par question de quiz, jour UTC, plateforme et langue (événement quiz_answer, tous contextes). Conservée sans limite.';
create index if not exists daily_quiz_question_stats_question on public.daily_quiz_question_stats (question_id, day);

-- kind : 'match' (adversaire tiré par le jeu) ou 'friend' (duel entre amis, compté pour
-- celui qui le lance). platform est celle des événements de l'utilisateur ce jour-là,
-- 'unknown' quand son app n'en envoie pas encore.
create table if not exists public.daily_duel_stats (
  day date not null,
  platform text not null,
  lang text not null,
  kind text not null,
  started integer not null default 0,
  finished integer not null default 0,
  abandoned integer not null default 0,
  players integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, lang, kind),
  constraint daily_duel_stats_kind_check check (kind in ('match', 'friend'))
);
comment on table public.daily_duel_stats is 'Duels lancés, terminés et abandonnés par jour UTC, plateforme, langue et type, depuis duel_matches et duel_friend_matches. Conservée sans limite.';

alter table public.daily_usage_stats enable row level security;
alter table public.daily_course_usage enable row level security;
alter table public.daily_quiz_question_stats enable row level security;
alter table public.daily_duel_stats enable row level security;
revoke all on public.daily_usage_stats, public.daily_course_usage, public.daily_quiz_question_stats, public.daily_duel_stats from anon, authenticated;

create index if not exists duel_matches_started_at on public.duel_matches (started_at);
create index if not exists duel_friend_matches_created_at on public.duel_friend_matches (created_at);
create index if not exists app_feedback_platform_created on public.app_feedback (platform, created_at desc);

-- ---------- calcul d'un jour ----------

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

  insert into public.daily_usage_stats
    (day, platform, lang, active_users, sessions, course_opens, readers, pages_read, completes,
     likes, saves, shares, quiz_answers, quiz_correct, updated_at)
  select
    target_day, e.platform, coalesce(e.lang, 'unknown'),
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
  group by e.platform, coalesce(e.lang, 'unknown');

  insert into public.daily_course_usage
    (day, platform, lang, course_id, opens, readers, pages_read, completes, likes, updated_at)
  select
    target_day, e.platform, coalesce(e.lang, 'unknown'), e.course_id,
    count(*) filter (where e.name = 'course_open'),
    count(distinct e.user_id) filter (where e.name = 'course_open'),
    count(*) filter (where e.name = 'section_view'),
    count(*) filter (where e.name = 'course_complete'),
    count(*) filter (where e.name = 'like'),
    now()
  from public.course_events e
  where e.ts >= v_from and e.ts < v_to
    and e.course_id is not null
    and e.name in ('course_open', 'section_view', 'course_complete', 'like')
  group by e.platform, coalesce(e.lang, 'unknown'), e.course_id;

  insert into public.daily_quiz_question_stats
    (day, platform, lang, question_id, course_id, answers, correct, updated_at)
  select
    target_day, e.platform, coalesce(e.lang, 'unknown'), e.props ->> 'question_id',
    coalesce(max(e.course_id), regexp_replace(e.props ->> 'question_id', '_q\d+$', '')),
    count(*),
    count(*) filter (where e.props ->> 'correct' = 'true'),
    now()
  from public.course_events e
  where e.ts >= v_from and e.ts < v_to
    and e.name = 'quiz_answer'
    and e.props ->> 'question_id' is not null
  group by e.platform, coalesce(e.lang, 'unknown'), e.props ->> 'question_id';

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
end;
$$;

create or replace function public.refresh_recent_usage_stats()
returns void
language sql
security definer
set search_path to 'public'
as $$
  select public.refresh_daily_usage_stats((now() at time zone 'utc')::date);
  select public.refresh_daily_usage_stats((now() at time zone 'utc')::date - 1);
  select public.refresh_daily_usage_stats((now() at time zone 'utc')::date - 2);
$$;

revoke all on function public.refresh_daily_usage_stats(date) from public, anon, authenticated;
revoke all on function public.refresh_recent_usage_stats() from public, anon, authenticated;

-- Reprise depuis le premier événement ou la première partie encore en base.
do $$
declare d date;
begin
  for d in
    select generate_series(
      least(
        coalesce((select min(ts at time zone 'utc')::date from public.course_events), (now() at time zone 'utc')::date),
        coalesce((select min(started_at at time zone 'utc')::date from public.duel_matches), (now() at time zone 'utc')::date),
        coalesce((select min(created_at at time zone 'utc')::date from public.duel_friend_matches), (now() at time zone 'utc')::date)
      ),
      (now() at time zone 'utc')::date,
      interval '1 day'
    )::date
  loop
    perform public.refresh_daily_usage_stats(d);
  end loop;
end $$;

select cron.unschedule(jobid) from cron.job where jobname = 'daily_usage_stats';
select cron.schedule('daily_usage_stats', '45 * * * *', $$select public.refresh_recent_usage_stats()$$);

-- ---------- tableau de bord : usage ----------

-- Tout ce que la page /admin/data/usage affiche, en un appel. Réservé à l'équipe.
-- Les titres de cours et les énoncés de quiz sont lus dans la langue filtrée, à défaut en
-- français puis en anglais. Une question n'entre dans « les plus ratées » qu'à partir de
-- p_min_answers réponses.
create or replace function public.admin_usage_dashboard(
  p_days integer default 28,
  p_platform text default null,
  p_lang text default null,
  p_min_answers integer default 20
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
    where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang)
  ),
  c as (
    select course_id, sum(opens) as opens, sum(readers) as readers, sum(pages_read) as pages_read,
           sum(completes) as completes, sum(likes) as likes
    from public.daily_course_usage d
    where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang)
    group by course_id
  ),
  q as (
    select question_id, max(course_id) as course_id, sum(answers) as answers, sum(correct) as correct
    from public.daily_quiz_question_stats d
    where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang)
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
    'top_courses', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.opens desc, t.course_id)
      from (
        select c.course_id, n.title, c.opens, c.readers, c.pages_read, c.completes, c.likes
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

revoke all on function public.admin_usage_dashboard(integer, text, text, integer) from public, anon;
grant execute on function public.admin_usage_dashboard(integer, text, text, integer) to authenticated;

-- ---------- tableau de bord : retours ----------

-- Les retours du formulaire de l'app (public.app_feedback), les plus récents d'abord.
create or replace function public.admin_feedback_dashboard(
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
  )
  select jsonb_build_object(
    'days', v_days,
    'total', (select count(*) from f),
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

revoke all on function public.admin_feedback_dashboard(integer, text, text) from public, anon;
grant execute on function public.admin_feedback_dashboard(integer, text, text) to authenticated;
