-- Événements éditoriaux pilotés à distance (docs/evenements.md).
--
-- Un événement (« Movember », « 11 novembre », une semaine thématique, le lancement d'une
-- série) est une collection de cours à lire pendant une période, un défi avec un badge, et des
-- cours annoncés en écriture. L'équipe le crée et le publie depuis l'admin du site
-- (sophia-culture.com/admin/events) ; les apps le reçoivent par le manifeste du catalogue
-- (`catalog_manifest` → clé `events`), donc dans l'heure, sans nouvelle version.
--
-- Le format est le même partout : table, manifeste, modèles iOS (`Campaign.swift`) et Android
-- (`Campaign.kt`). Les textes sont donnés par langue ({"en": …, "fr": …}) ; les apps retombent
-- sur l'anglais puis le français.

create table if not exists public.campaigns (
  slug text primary key
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(slug) between 3 and 60),
  -- month : mois thématique · week : semaine thématique · day : journée de commémoration ·
  -- series : lancement d'une série (collection, auteur) sur quelques semaines.
  kind text not null default 'month' check (kind in ('month', 'week', 'day', 'series')),
  -- draft : invisible des apps · published : servi par le manifeste · archived : retiré, gardé.
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  -- Un symbole de la liste standard (nom SF Symbols ; Android a l'icône Material correspondante).
  symbol text not null default 'sparkles' check (symbol in (
    'mustache.fill', 'heart.fill', 'star.fill', 'flame.fill', 'leaf.fill', 'globe.europe.africa.fill',
    'book.fill', 'flag.fill', 'sparkles', 'drop.fill', 'sun.max.fill', 'moon.fill', 'graduationcap.fill',
    'brain.head.profile', 'figure.run', 'music.note', 'paintpalette.fill', 'building.columns.fill',
    'snowflake', 'gift.fill', 'trophy.fill', 'atom'
  )),
  starts_at date not null,
  ends_at date not null check (ends_at >= starts_at),
  -- Cours de la collection à terminer pour obtenir le badge.
  challenge_target integer not null default 1 check (challenge_target between 1 and 50),
  -- Lecteurs ayant terminé au moins un cours de la collection pendant l'événement
  -- (recalculé toutes les heures par campaigns_refresh_participants).
  participants integer not null default 0 check (participants >= 0),
  course_ids text[] not null default '{}' check (array_length(course_ids, 1) is null or array_length(course_ids, 1) <= 40),
  -- [{"title": {"en": …, "fr": …}, "creator": "slug-auteur" | null, "date": "YYYY-MM-DD"}]
  upcoming jsonb not null default '[]'::jsonb check (jsonb_typeof(upcoming) = 'array'),
  title jsonb not null default '{}'::jsonb check (jsonb_typeof(title) = 'object'),
  tagline jsonb not null default '{}'::jsonb check (jsonb_typeof(tagline) = 'object'),
  description jsonb not null default '{}'::jsonb check (jsonb_typeof(description) = 'object'),
  badge_name jsonb not null default '{}'::jsonb check (jsonb_typeof(badge_name) = 'object'),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.campaigns is 'Événements éditoriaux (Movember, 11 novembre…) : collection de cours, défi, badge, cours annoncés. Publiés aux apps par catalog_manifest → events. Édités depuis l''admin du site.';

create index if not exists campaigns_status_dates on public.campaigns (status, starts_at, ends_at);

create or replace function public.campaigns_touch()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists campaigns_touch on public.campaigns;
create trigger campaigns_touch before update on public.campaigns
  for each row execute function public.campaigns_touch();

-- Lecture et écriture réservées à l'équipe (studio_admins). Les apps ne lisent jamais la table :
-- elles reçoivent les événements publiés par le manifeste (fonction security definer).
alter table public.campaigns enable row level security;
grant select, insert, update, delete on public.campaigns to authenticated;
drop policy if exists campaigns_admin_select on public.campaigns;
create policy campaigns_admin_select on public.campaigns for select to authenticated
  using (public.is_studio_admin());
drop policy if exists campaigns_admin_insert on public.campaigns;
create policy campaigns_admin_insert on public.campaigns for insert to authenticated
  with check (public.is_studio_admin());
drop policy if exists campaigns_admin_update on public.campaigns;
create policy campaigns_admin_update on public.campaigns for update to authenticated
  using (public.is_studio_admin()) with check (public.is_studio_admin());
drop policy if exists campaigns_admin_delete on public.campaigns;
create policy campaigns_admin_delete on public.campaigns for delete to authenticated
  using (public.is_studio_admin());

-- ---------- participants ----------

-- Lecteurs distincts ayant terminé au moins un cours de la collection entre le premier et le
-- dernier jour de l'événement. Les événements terminés depuis plus d'une semaine gardent leur
-- dernier chiffre (le journal course_events ne remonte qu'à 90 jours).
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
  ), 0)
  where c.status = 'published' and c.ends_at >= current_date - 7;
end;
$$;

revoke all on function public.campaigns_refresh_participants() from public, anon, authenticated;
select cron.schedule('campaign-participants', '25 * * * *', $$select public.campaigns_refresh_participants()$$);

-- ---------- manifeste ----------

-- Les événements publiés, dans le format exact que les apps décodent. Tous les événements sont
-- dans chaque manifeste, quelle que soit la langue : les textes portent chaque langue. Un
-- événement terminé reste servi un an, le temps que le badge gagné reste affiché dans le profil.
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
    'starts_at', to_char(c.starts_at, 'YYYY-MM-DD'),
    'ends_at', to_char(c.ends_at, 'YYYY-MM-DD'),
    'challenge_target', c.challenge_target,
    'participants', c.participants,
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

-- Même définition qu'avant (20261108190000), plus la clé events.
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
    'events', public.campaigns_for_manifest()
  );
$$;

-- ---------- exemple ----------

-- Le Movember de la maquette, en brouillon : l'équipe le relit et le publie depuis l'admin.
insert into public.campaigns (slug, kind, status, symbol, starts_at, ends_at, challenge_target, course_ids, upcoming, title, tagline, description, badge_name)
values (
  'movember-2026', 'month', 'draft', 'mustache.fill', '2026-11-01', '2026-11-30', 3,
  array['course_228_la_sante_mentale_comme_enjeu_de_societe', 'course_42_pourquoi_reve_t_on', 'course_73_comment_le_cerveau_stocke_t_il_les_souve'],
  '[{"title": {"fr": "Pourquoi les hommes vont-ils moins chez le médecin ?", "en": "Why do men see a doctor less often?"}, "creator": "ezgi-gizem-berkay", "date": "2026-11-14"},
    {"title": {"fr": "D''où vient la mode de la moustache ?", "en": "Where does the moustache fashion come from?"}, "creator": "angela-bouma", "date": "2026-11-18"},
    {"title": {"fr": "La prostate : pourquoi faut-il en parler ?", "en": "The prostate: why should we talk about it?"}, "creator": "stacy-jankowski", "date": "2026-11-21"}]'::jsonb,
  '{"fr": "Movember", "en": "Movember"}'::jsonb,
  '{"fr": "La santé des hommes, on en parle.", "en": "Men''s health, let''s talk about it."}'::jsonb,
  '{"fr": "Santé mentale, prévention, cancers masculins : un mois pour en parler, un cours à la fois.", "en": "Mental health, prevention, male cancers: a month to talk about it, one course at a time."}'::jsonb,
  '{"fr": "Moustache", "en": "Moustache"}'::jsonb
)
on conflict (slug) do nothing;
