-- La photo publique d'un auteur et la fraîcheur du catalogue, côté serveur (9 novembre, soir).
--
-- Constat : la copie de la photo du Studio vers le bucket public se faisait dans une action du
-- site (clé serveur sur Vercel), en silence quand elle échouait, et jamais quand la session
-- tournait encore sur un ancien déploiement. Et même à jour, creators.photo_url n'atteignait pas
-- les apps : elles lisent photoUrl dans le fichier catalogue, dont le hash n'était recalculé
-- qu'à la publication d'un cours.
--
-- 1. Photo publique : un changement de photo, ou l'approbation du compte, crée une demande
--    (author_photo_requests) et appelle l'Edge Function author-photo-sync par pg_net. La
--    fonction copie studio-photos/<uid>/… vers course-images/author_<slug>_<horodatage>.<ext>
--    et met creators.photo_url à jour. La demande (uuid, usage unique, quinze minutes) tient lieu
--    d'authentification : aucun secret partagé.
-- 2. Catalogue : toute modification de creators marque le catalogue « à rafraîchir » ; chaque
--    minute (pg_cron), les hash des fichiers de toutes les langues sont recalculés si besoin. Les
--    apps retéléchargent le fichier au prochain manifeste (six heures au plus).

-- ---------- 1. photo publique ----------

create table if not exists public.author_photo_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  created_at timestamptz not null default now(),
  done_at timestamptz,
  photo_url text,
  error text
);
comment on table public.author_photo_requests is 'Demandes de copie de la photo d''un auteur vers le bucket public, traitées par l''Edge Function author-photo-sync. L''identifiant sert de jeton à usage unique.';
create index if not exists author_photo_requests_user on public.author_photo_requests (user_id, created_at desc);
alter table public.author_photo_requests enable row level security;
-- Aucune politique : seule la clé serveur (Edge Function) lit et écrit.

create or replace function public.author_photo_sync_request(p_user uuid)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
  v_base text;
begin
  insert into public.author_photo_requests (user_id) values (p_user) returning id into v_id;
  select coalesce(nullif(value ->> 'functions_url', ''), 'https://afnmcoovdvbtkgohtdij.supabase.co/functions/v1')
    into v_base
  from public.app_config where key = 'studio';
  v_base := coalesce(v_base, 'https://afnmcoovdvbtkgohtdij.supabase.co/functions/v1');
  perform net.http_post(
    url := v_base || '/author-photo-sync',
    body := jsonb_build_object('request_id', v_id),
    headers := jsonb_build_object('Content-Type', 'application/json'),
    timeout_milliseconds := 15000);
  return v_id;
end;
$$;
revoke all on function public.author_photo_sync_request(uuid) from public, anon, authenticated;
comment on function public.author_photo_sync_request(uuid) is 'Crée une demande de photo publique pour ce compte et appelle l''Edge Function author-photo-sync. Rend l''identifiant de la demande.';

-- La photo du Studio a changé (chemin posé par le site, même identique : l''avatar garde le même nom).
create or replace function public.creator_accounts_photo_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and new.slug is not null and coalesce(new.photo_path, '') <> '' then
    perform public.author_photo_sync_request(new.user_id);
  end if;
  return new;
end;
$$;
create or replace trigger creator_accounts_photo_sync
after update of photo_path on public.creator_accounts
for each row execute function public.creator_accounts_photo_changed();

-- Le compte vient d'être approuvé (ou son slug change) : sa photo devient publique.
create or replace function public.creator_accounts_approved_photo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and new.slug is not null and coalesce(new.photo_path, '') <> ''
     and (new.status is distinct from old.status or new.slug is distinct from old.slug) then
    perform public.author_photo_sync_request(new.user_id);
  end if;
  return new;
end;
$$;
create or replace trigger creator_accounts_approved_photo
after update of status, slug on public.creator_accounts
for each row execute function public.creator_accounts_approved_photo();

-- ---------- 2. fraîcheur du catalogue ----------

create table if not exists public.catalog_dirty (
  id boolean primary key default true check (id),
  dirty_at timestamptz,
  refreshed_at timestamptz
);
comment on table public.catalog_dirty is 'Une ligne : dirty_at posé quand creators change ; catalog_refinalize_if_dirty (cron, chaque minute) recalcule alors les hash des fichiers catalogue de toutes les langues.';
insert into public.catalog_dirty (id) values (true) on conflict do nothing;

create or replace function public.catalog_mark_dirty()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.catalog_dirty set dirty_at = now() where id;
  return null;
end;
$$;
create or replace trigger creators_catalog_dirty
after insert or update or delete on public.creators
for each statement execute function public.catalog_mark_dirty();

-- Recalcule les hash (catalog_finalize_language, environ une seconde par langue) si le catalogue
-- est marqué ; le marqueur est levé d'abord, pour qu'un changement pendant le calcul le repose.
create or replace function public.catalog_refinalize_if_dirty()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dirty timestamptz;
  v_n integer := 0;
  l record;
begin
  select dirty_at into v_dirty from public.catalog_dirty where id;
  if v_dirty is null then
    return 0;
  end if;
  update public.catalog_dirty set dirty_at = null, refreshed_at = now() where id;
  for l in select distinct lang from public.course_contents where status = 'published' order by lang loop
    perform public.catalog_finalize_language(l.lang);
    v_n := v_n + 1;
  end loop;
  return v_n;
end;
$$;
revoke all on function public.catalog_refinalize_if_dirty() from public, anon, authenticated;
select cron.schedule('catalog-refinalize', '* * * * *', $$select public.catalog_refinalize_if_dirty()$$);
