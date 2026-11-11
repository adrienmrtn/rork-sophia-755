-- Compteurs des cartes : les ouvertures affichées sont les ouvertures réelles multipliées par
-- un facteur propre à chaque cours, entre 4 et 10. À coller tel quel dans l'éditeur SQL de
-- Supabase ; rejouable (la conversion ne se fait qu'une fois).
--
-- Pourquoi un facteur par cours plutôt qu'un seul : avec x5 partout, tous les cours gardent
-- exactement les mêmes écarts. Entre x4 et x10, deux cours aussi lus l'un que l'autre peuvent
-- afficher du simple au double : les écarts se creusent. Le facteur est stable (tiré de
-- l'identifiant du cours), donc un cours ne change pas de facteur d'une semaine à l'autre.
--
-- - `real_opens` garde le vrai chiffre (comptes ayant ouvert le cours) ; `opens` est le chiffre
--   affiché. Le recalcul du lundi met à jour les deux.
-- - `likes` suit : les vrais j'aime, plus 6 à 12 % des ouvertures affichées (même taux par
--   cours qu'avant). La conversion se fait à partir des chiffres déjà en table, sans relire
--   `user_progress` (la relecture a tourné plus de 6 minutes le 11/11).
-- - `catalog_manifest` n'est pas touché : la clé `stats` sert toujours `[opens, likes]`.

alter table public.course_counters add column if not exists real_opens integer check (real_opens >= 0);
comment on column public.course_counters.real_opens is 'Ouvertures réelles (comptes ayant ouvert le cours). `opens` est le chiffre affiché : real_opens x course_open_boost.';
comment on table public.course_counters is 'Compteurs affichés sur les cartes des apps : ouvertures (réelles x 4 à 10 selon le cours, recalculées chaque lundi ; le vrai chiffre est dans real_opens) et j''aime (fixés par SQL). Servis par catalog_manifest → stats.';

-- Le facteur d'un cours : entre 4,00 et 10,00, stable par identifiant.
create or replace function public.course_open_boost(p_course_id text)
returns numeric
language sql
immutable
as $$ select 4 + (abs(hashtext(p_course_id || '|opens')) % 601) / 100.0 $$;

-- Conversion, une seule fois (les lignes déjà converties ont real_opens renseigné). À droite du
-- signe égal, `opens` et `likes` sont les valeurs d'avant : opens = ouvertures réelles,
-- likes = vrais j'aime + part des ouvertures réelles.
update public.course_counters k
   set real_opens = k.opens,
       opens = round(k.opens * public.course_open_boost(k.course_id))::int,
       likes = greatest(0, k.likes - round(k.opens * public.course_like_ratio(k.course_id))::int)
               + round(round(k.opens * public.course_open_boost(k.course_id)) * public.course_like_ratio(k.course_id))::int,
       updated_at = now()
 where k.real_opens is null;

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
  insert into public.course_counters as cc (course_id, real_opens, opens, likes, updated_at)
  select c.id,
         coalesce(o.opens, 0),
         round(coalesce(o.opens, 0) * public.course_open_boost(c.id))::int,
         coalesce(l.likes, 0)
           + round(round(coalesce(o.opens, 0) * public.course_open_boost(c.id)) * public.course_like_ratio(c.id))::int,
         now()
  from public.courses c
  left join opened o on o.course_id = c.id
  left join liked l on l.course_id = c.id
  where c.status = 'published'
  -- Les j'aime déjà posés ne sont pas touchés : seules les ouvertures suivent la réalité.
  on conflict (course_id) do update
    set real_opens = excluded.real_opens, opens = excluded.opens, updated_at = now();
$$;
revoke all on function public.refresh_course_counters() from public, anon, authenticated;

-- Contrôle : les dix cours les plus affichés, avec le vrai chiffre et le facteur.
select k.course_id, k.real_opens, round(public.course_open_boost(k.course_id), 2) as facteur, k.opens, k.likes
from public.course_counters k
order by k.opens desc
limit 10;
