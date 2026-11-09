-- Événements : image de couverture et objectif commun (docs/evenements.md).
--
-- image_url : une image 16:9 (bucket public course-images, dossier events/), affichée en tête de la
-- carte du fil et de la page de l'événement. goal_target : l'objectif commun, le nombre de cours de
-- la collection à terminer tous lecteurs confondus pendant l'événement ; goal_count : où on en est,
-- recalculé toutes les heures avec participants.

alter table public.campaigns
  add column if not exists image_url text check (image_url is null or image_url ~ '^https://'),
  add column if not exists goal_target integer check (goal_target is null or goal_target between 1 and 100000000),
  add column if not exists goal_count integer not null default 0 check (goal_count >= 0);

comment on column public.campaigns.image_url is 'Image 16:9 de l''événement (bucket course-images, dossier events/), en tête de la carte du fil et de la page. Null : la carte reste bleu nuit avec le symbole.';
comment on column public.campaigns.goal_target is 'Objectif commun : cours de la collection à terminer, tous lecteurs confondus, pendant l''événement. Null : pas d''objectif affiché.';
comment on column public.campaigns.goal_count is 'Cours de la collection terminés pendant l''événement, tous lecteurs confondus (course_events · course_complete), recalculé toutes les heures.';

-- Participants (lecteurs distincts) et compteur commun (fins de cours), en une passe.
create or replace function public.campaigns_refresh_participants()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.campaigns c
  set participants = coalesce((
        select count(distinct e.user_id)
        from public.course_events e
        where e.name = 'course_complete'
          and e.course_id = any (c.course_ids)
          and e.ts >= c.starts_at::timestamptz
          and e.ts < (c.ends_at + 1)::timestamptz
      ), 0),
      goal_count = coalesce((
        select count(*)
        from public.course_events e
        where e.name = 'course_complete'
          and e.course_id = any (c.course_ids)
          and e.ts >= c.starts_at::timestamptz
          and e.ts < (c.ends_at + 1)::timestamptz
      ), 0)
  where c.status = 'published' and c.ends_at >= current_date - 7;
end;
$$;

revoke all on function public.campaigns_refresh_participants() from public, anon, authenticated;

create or replace function public.campaigns_for_manifest()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'slug', c.slug,
    'kind', c.kind,
    'symbol', c.symbol,
    'image_url', c.image_url,
    'starts_at', to_char(c.starts_at, 'YYYY-MM-DD'),
    'ends_at', to_char(c.ends_at, 'YYYY-MM-DD'),
    'challenge_target', c.challenge_target,
    'participants', c.participants,
    'goal_target', c.goal_target,
    'goal_count', c.goal_count,
    'course_ids', to_jsonb(c.course_ids),
    'upcoming', c.upcoming,
    'title', c.title,
    'tagline', c.tagline,
    'description', c.description,
    'badge_name', c.badge_name
  ) order by c.starts_at, c.slug), '[]'::jsonb)
  from public.campaigns c
  where c.status = 'published' and c.ends_at >= current_date - 400;
$$;

revoke all on function public.campaigns_for_manifest() from public;
grant execute on function public.campaigns_for_manifest() to anon, authenticated, service_role;
