-- Compteurs réels des cours (ouvertures, j'aime) et vraie langue d'écriture, servis par le
-- manifeste du catalogue. À coller tel quel dans l'éditeur SQL de Supabase ; rejouable.
--
-- 1. `course_counters` : une ligne par cours publié.
--    - `opens` : le nombre de comptes qui ont ouvert le cours, compté dans
--      `user_progress.progress -> courseProgress` (les vraies ouvertures, tout l'historique ;
--      `course_events` ne remonte qu'au 10/11/2026). Recalculé chaque lundi.
--    - `likes` : fixé une fois à partir des ouvertures (6 à 12 % selon le cours, taux stable par
--      identifiant) plus les vrais j'aime ; il ne bouge plus ensuite, sauf à relancer la
--      requête « j'aime » du point 3. Un nouveau cours reçoit son chiffre à sa première ligne.
-- 2. `catalog_manifest` gagne deux clés, que les apps récentes lisent et que les anciennes
--    ignorent : `stats` (`{cours: [ouvertures, j'aime]}`) et `origins` (`{cours: langue}` pour
--    les cours qui n'ont pas été écrits en français).
-- 3. Les cours des profs ont été écrits en anglais (docs/cours-profs-analyse.md) mais importés
--    avec `origin_lang = 'fr'` : « Voir l'original » ouvrait donc le français. On corrige.

-- ---------- 1. compteurs ----------

create table if not exists public.course_counters (
  course_id text primary key references public.courses (id) on delete cascade,
  opens integer not null default 0 check (opens >= 0),
  likes integer not null default 0 check (likes >= 0),
  updated_at timestamptz not null default now()
);
comment on table public.course_counters is 'Compteurs affichés sur les cartes des apps : ouvertures réelles (user_progress, recalculées chaque lundi) et j''aime (fixés à la main par SQL). Servis par catalog_manifest → stats.';

alter table public.course_counters enable row level security;
revoke all on public.course_counters from anon, authenticated;

-- Le taux de j'aime d'un cours : entre 6 % et 12 % de ses ouvertures, stable par identifiant.
create or replace function public.course_like_ratio(p_course_id text)
returns numeric
language sql
immutable
as $$ select 0.06 + (abs(hashtext(p_course_id || '|likes')) % 61) / 1000.0 $$;

create or replace function public.refresh_course_counters()
returns void
language sql
security definer
set search_path = public
as $$
  with opened as (
    select k.course_id, count(*)::int as opens
    from public.user_progress up
    cross join lateral jsonb_object_keys(
      case when jsonb_typeof(up.progress::jsonb -> 'courseProgress') = 'object'
           then up.progress::jsonb -> 'courseProgress' else '{}'::jsonb end
    ) as k(course_id)
    group by k.course_id
  ),
  liked as (
    select l.course_id, count(*)::int as likes
    from public.user_progress up
    cross join lateral jsonb_array_elements_text(
      case when jsonb_typeof(up.progress::jsonb -> 'likedCourseIds') = 'array'
           then up.progress::jsonb -> 'likedCourseIds' else '[]'::jsonb end
    ) as l(course_id)
    group by l.course_id
  )
  insert into public.course_counters as cc (course_id, opens, likes, updated_at)
  select c.id,
         coalesce(o.opens, 0),
         coalesce(l.likes, 0) + round(coalesce(o.opens, 0) * public.course_like_ratio(c.id))::int,
         now()
  from public.courses c
  left join opened o on o.course_id = c.id
  left join liked l on l.course_id = c.id
  where c.status = 'published'
  -- Les j'aime déjà posés ne sont pas touchés : seules les ouvertures suivent la réalité.
  on conflict (course_id) do update set opens = excluded.opens, updated_at = now();
$$;
revoke all on function public.refresh_course_counters() from public, anon, authenticated;

-- Chaque lundi à 03:10 UTC (une fois par semaine : le manifeste change, les apps le retéléchargent).
select cron.unschedule('course-counters') where exists (select 1 from cron.job where jobname = 'course-counters');
select cron.schedule('course-counters', '10 3 * * 1', $$select public.refresh_course_counters()$$);

-- ---------- 2. le manifeste ----------

create or replace function public.catalog_manifest(p_lang text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'lang', p_lang,
    'generated_at', now(),
    'files', coalesce((
      select jsonb_object_agg(f.kind, jsonb_build_object(
        'hash', f.hash,
        'bytes', f.bytes,
        'path', format('%s/%s.%s.json', p_lang, f.kind, f.hash),
        'storage', exists (select 1 from storage.objects o where o.bucket_id = 'course-content' and o.name = format('%s/%s.%s.json', p_lang, f.kind, f.hash))
      ))
      from public.catalog_files f
      where f.lang = p_lang
    ), '{}'::jsonb),
    'courses', coalesce((
      select jsonb_object_agg(cc.course_id, jsonb_build_object(
        'hash', cc.hash,
        'bytes', cc.bytes,
        'path', format('%s/courses/%s.%s.json', p_lang, cc.course_id, cc.hash),
        'storage', exists (select 1 from storage.objects o where o.bucket_id = 'course-content' and o.name = format('%s/courses/%s.%s.json', p_lang, cc.course_id, cc.hash))
      ))
      from public.course_contents cc
      join public.courses c on c.id = cc.course_id
      where cc.lang = p_lang and cc.status = 'published' and c.status = 'published' and cc.hash <> 'pending'
    ), '{}'::jsonb),
    'events', public.campaigns_for_manifest(),
    'trending', coalesce((select to_jsonb(t.course_ids) from public.trending_courses t where t.lang = p_lang), '[]'::jsonb),
    'stats', coalesce((
      select jsonb_object_agg(k.course_id, jsonb_build_array(k.opens, k.likes))
      from public.course_counters k
      join public.courses c on c.id = k.course_id
      where c.status = 'published'
    ), '{}'::jsonb),
    'origins', coalesce((
      select jsonb_object_agg(c.id, c.origin_lang)
      from public.courses c
      where c.status = 'published' and c.origin_lang <> 'fr'
    ), '{}'::jsonb)
  );
$$;

-- ---------- 3. données ----------

-- La vraie langue d'écriture des cours des profs : l'anglais. (Les cours d'Adrien Martinot,
-- écrits depuis le Studio, gardent la langue déclarée à l'envoi.)
update public.courses
   set origin_lang = 'en', updated_at = now()
 where creator_slug is not null
   and creator_slug <> 'adrien-martinot'
   and origin_lang = 'fr'
   and exists (select 1 from public.course_contents cc where cc.course_id = courses.id and cc.lang = 'en');

-- Premier calcul (quelques dizaines de secondes sur 326 000 comptes).
set statement_timeout = '10min';
select public.refresh_course_counters();

-- Les j'aime, (re)fixés à partir des ouvertures du moment. C'est LA requête à relancer pour
-- les rafraîchir plus tard ; sans elle ils restent figés.
with liked as (
  select l.course_id, count(*)::int as likes
  from public.user_progress up
  cross join lateral jsonb_array_elements_text(
    case when jsonb_typeof(up.progress::jsonb -> 'likedCourseIds') = 'array'
         then up.progress::jsonb -> 'likedCourseIds' else '[]'::jsonb end
  ) as l(course_id)
  group by l.course_id
)
update public.course_counters k
   set likes = coalesce((select l.likes from liked l where l.course_id = k.course_id), 0)
               + round(k.opens * public.course_like_ratio(k.course_id))::int,
       updated_at = now();

reset statement_timeout;

-- Contrôle : les dix cours les plus ouverts.
select k.course_id, k.opens, k.likes from public.course_counters k order by k.opens desc limit 10;
