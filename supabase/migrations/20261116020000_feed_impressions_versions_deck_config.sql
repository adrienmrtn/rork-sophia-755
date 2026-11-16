-- Affichages dans le fil par cours, usage par version de l'app, et réglage du fil à distance
-- (pages /admin/data/usage, docs/events.md).

-- ---------- affichages et ouvertures depuis le fil, par cours ----------

-- impressions : cartes affichées dans le fil (card_impression). card_opens : cartes ouvertes
-- depuis le fil (card_open). Leur rapport est le taux d'ouverture : il dit si un cours attire,
-- là où le nombre d'ouvertures dit surtout s'il a été montré.
alter table public.daily_course_usage add column if not exists impressions integer not null default 0;
alter table public.daily_course_usage add column if not exists card_opens integer not null default 0;

-- ---------- usage par version de l'app ----------

create table if not exists public.daily_version_usage (
  day date not null,
  platform text not null,
  app_version text not null default '',
  lang text not null,
  active_users integer not null default 0,
  course_opens integer not null default 0,
  pages_read integer not null default 0,
  completes integer not null default 0,
  impressions integer not null default 0,
  card_opens integer not null default 0,
  quiz_answers integer not null default 0,
  quiz_correct integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (day, platform, app_version, lang)
);
comment on table public.daily_version_usage is 'Usage de l''app par jour UTC, plateforme, version de l''app et langue, depuis course_events. active_users : utilisateurs distincts par jour. Conservée sans limite.';

alter table public.daily_version_usage enable row level security;
revoke all on public.daily_version_usage from anon, authenticated;

-- ---------- calcul d'un jour (remplace celui de 20261113060000) ----------

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
    (day, platform, lang, course_id, opens, readers, pages_read, completes, likes, impressions, card_opens, updated_at)
  select
    target_day, e.platform, coalesce(e.lang, 'unknown'), e.course_id,
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

revoke all on function public.refresh_daily_usage_stats(date) from public, anon, authenticated;

-- Reprise de tout ce que le journal garde encore.
select public.refresh_daily_usage_stats(d::date)
from generate_series(
  (select coalesce(min(ts), now()) from public.course_events)::date,
  (now() at time zone 'utc')::date,
  interval '1 day'
) as d;

-- ---------- tableau de bord : usage (remplace celui de 20261113060000) ----------

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
           sum(completes) as completes, sum(likes) as likes,
           sum(impressions) as impressions, sum(card_opens) as card_opens
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
    'by_version', coalesce((
      select jsonb_agg(to_jsonb(t) order by t.platform, t.last_day desc, t.app_version desc)
      from (select platform, app_version, min(day) as first_day, max(day) as last_day,
                   sum(active_users) as user_days, sum(course_opens) as course_opens, sum(pages_read) as pages_read,
                   sum(completes) as completes, sum(impressions) as impressions, sum(card_opens) as card_opens,
                   sum(quiz_answers) as quiz_answers, sum(quiz_correct) as quiz_correct
            from public.daily_version_usage d
            where d.day >= v_from and (p_platform is null or d.platform = p_platform) and (p_lang is null or d.lang = p_lang)
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

revoke all on function public.admin_usage_dashboard(integer, text, text, integer) from public, anon;
grant execute on function public.admin_usage_dashboard(integer, text, text, integer) to authenticated;

-- ---------- réglage du fil d'accueil ----------

-- Lu par les apps au lancement (HomeDeckConfig, iOS et Android, à partir de l'algorithme
-- local-v2). head_pool : pour un lecteur qui n'a encore rien terminé, chaque carte est tirée
-- parmi ce nombre de meilleurs cours de sa matière (1 : toujours le meilleur, donc le même
-- pour tous). exploration_every : une carte sur N est tirée au hasard.
insert into public.app_config (key, value)
values ('home_deck', '{"head_pool": 5, "exploration_every": 4}'::jsonb)
on conflict (key) do nothing;
