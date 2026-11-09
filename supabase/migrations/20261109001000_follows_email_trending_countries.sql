-- Demandes du 9 novembre (soir) :
--
-- 1. Abonnements côté serveur : public.follows, dérivée du JSON que les apps poussent déjà dans
--    user_progress.progress (followedCreatorSlugs). Aucun changement d'app : la table suit chaque
--    synchronisation, et un remplissage initial reprend les lignes existantes.
-- 2. La page publique d'un auteur suit son profil : creators est resynchronisée à chaque
--    modification du compte approuvé (nom, titre, bio, institution, pays, liens).
-- 3. E-mail « nouveau cours » aux abonnés d'un auteur quand un cours passe publié : préférences,
--    journal d'envoi, destinataires, envoi par l'API Resend depuis la base (pg_net), clé dans le
--    Vault (resend_api_key). Désinscription par jeton (page /unsubscribe du site).
-- 4. Tendances : les cours les plus ouverts des sept derniers jours, par langue, recalculés chaque
--    nuit et servis par le manifeste du catalogue (clé trending).
-- 5. Événements : ciblage par pays (campaigns.countries, ISO 3166-1 alpha-2 ; null = partout).
-- 6. Le bucket course-images accepte PNG et WebP (images d'événement Recraft, avatars).

-- ---------- 1. abonnements ----------

create table if not exists public.follows (
  user_id uuid not null references auth.users (id) on delete cascade,
  creator_slug text not null,
  followed_at timestamptz not null default now(),
  primary key (user_id, creator_slug)
);
comment on table public.follows is 'Qui suit quel créateur. Dérivée de user_progress.progress->followedCreatorSlugs par trigger : les apps ne l''écrivent pas directement.';
create index if not exists follows_creator on public.follows (creator_slug);

alter table public.follows enable row level security;
drop policy if exists follows_own_select on public.follows;
create policy follows_own_select on public.follows for select to authenticated using (user_id = auth.uid());
grant select on public.follows to authenticated;

create or replace function public.user_progress_sync_follows()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_slugs text[];
begin
  select coalesce(array_agg(distinct x), '{}'::text[]) into v_slugs
  from jsonb_array_elements_text(case when jsonb_typeof(new.progress -> 'followedCreatorSlugs') = 'array' then new.progress -> 'followedCreatorSlugs' else '[]'::jsonb end) x
  where x <> '';
  insert into public.follows (user_id, creator_slug)
  select new.user_id, unnest(v_slugs)
  on conflict do nothing;
  delete from public.follows f where f.user_id = new.user_id and not (f.creator_slug = any (v_slugs));
  return new;
end;
$$;

drop trigger if exists user_progress_sync_follows on public.user_progress;
create trigger user_progress_sync_follows
after insert or update of progress on public.user_progress
for each row when (new.progress is not null)
execute function public.user_progress_sync_follows();

insert into public.follows (user_id, creator_slug)
select up.user_id, x
from public.user_progress up,
     jsonb_array_elements_text(case when jsonb_typeof(up.progress -> 'followedCreatorSlugs') = 'array' then up.progress -> 'followedCreatorSlugs' else '[]'::jsonb end) x
where x <> ''
on conflict do nothing;

-- ---------- 2. la page publique suit le profil ----------

create or replace function public.creator_sync_public(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  a public.creator_accounts;
begin
  select * into a from public.creator_accounts where user_id = p_user;
  if a.user_id is null or a.slug is null or a.status <> 'approved' then
    return;
  end if;
  insert into public.creators (slug, name, title, bio, institution, country, links, verified, user_id)
  values (
    a.slug,
    coalesce(nullif(trim(a.display_name), ''), nullif(trim(concat_ws(' ', a.first_name, a.last_name)), ''), a.slug),
    case when nullif(trim(a.title), '') is not null then jsonb_build_object(a.writing_lang, trim(a.title)) else '{}'::jsonb end,
    case when nullif(trim(coalesce(a.long_bio, a.bio)), '') is not null then jsonb_build_object(a.writing_lang, trim(coalesce(a.long_bio, a.bio))) else '{}'::jsonb end,
    nullif(trim(a.institution), ''),
    nullif(trim(a.country), ''),
    coalesce(a.links, '{}'::jsonb),
    true,
    a.user_id
  )
  on conflict (slug) do update set
    name = excluded.name,
    title = public.creators.title || excluded.title,
    bio = public.creators.bio || excluded.bio,
    institution = coalesce(excluded.institution, public.creators.institution),
    country = coalesce(excluded.country, public.creators.country),
    links = case when excluded.links = '{}'::jsonb then public.creators.links else excluded.links end,
    verified = true,
    user_id = excluded.user_id,
    updated_at = now();
end;
$$;
revoke all on function public.creator_sync_public(uuid) from public, anon, authenticated;

create or replace function public.studio_set_creator_status(p_user uuid, p_status text, p_reason text default null)
returns public.creator_accounts
language plpgsql
security definer
set search_path = public
as $$
declare
  a public.creator_accounts;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  if p_status not in ('pending', 'approved', 'suspended') then
    raise exception 'Statut inconnu : %', p_status;
  end if;
  update public.creator_accounts
     set status = p_status,
         approved_at = case when p_status = 'approved' then coalesce(approved_at, now()) else approved_at end,
         approved_by = case when p_status = 'approved' then coalesce(approved_by, auth.uid()) else approved_by end,
         suspended_reason = case when p_status = 'suspended' then nullif(trim(coalesce(p_reason, '')), '') else null end
   where user_id = p_user
  returning * into a;
  if a.user_id is null then
    raise exception 'Compte introuvable';
  end if;
  if p_status = 'approved' then
    perform public.creator_sync_public(p_user);
  elsif p_status = 'suspended' and a.slug is not null then
    update public.creators set verified = false, updated_at = now() where slug = a.slug;
  end if;
  return a;
end;
$$;
revoke all on function public.studio_set_creator_status(uuid, text, text) from public;
grant execute on function public.studio_set_creator_status(uuid, text, text) to authenticated;

create or replace function public.creator_accounts_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and new.slug is not null then
    perform public.creator_sync_public(new.user_id);
  end if;
  return new;
end;
$$;
drop trigger if exists creator_accounts_sync on public.creator_accounts;
create trigger creator_accounts_sync
after update of display_name, first_name, last_name, title, bio, long_bio, institution, country, links, slug, writing_lang on public.creator_accounts
for each row execute function public.creator_accounts_changed();

-- ---------- 3. e-mail « nouveau cours » ----------

create table if not exists public.notification_prefs (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email_new_course boolean not null default true,
  unsubscribe_token uuid not null default gen_random_uuid() unique,
  updated_at timestamptz not null default now()
);
comment on table public.notification_prefs is 'Préférences de notification d''un lecteur. email_new_course : e-mail quand un auteur suivi publie. Le jeton sert au lien de désinscription.';
alter table public.notification_prefs enable row level security;
drop policy if exists notification_prefs_own on public.notification_prefs;
create policy notification_prefs_own on public.notification_prefs for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
grant select, insert, update on public.notification_prefs to authenticated;

create table if not exists public.notification_log (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  course_id text not null,
  channel text not null check (channel in ('email', 'push')),
  sent_at timestamptz not null default now(),
  unique (user_id, course_id, channel)
);
comment on table public.notification_log is 'Ce qui a été envoyé, pour ne jamais prévenir deux fois du même cours.';
alter table public.notification_log enable row level security;

-- Les abonnés d'un auteur à prévenir pour ce cours : avec un e-mail, qui n'ont pas refusé, pas
-- encore prévenus. La langue est celle de l'app (dernier événement), sinon celle du cours.
create or replace function public.notify_course_recipients(p_course_id text)
returns table (user_id uuid, email text, lang text, token uuid)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.notification_prefs (user_id)
  select f.user_id from public.follows f join public.courses c on c.creator_slug = f.creator_slug where c.id = p_course_id
  on conflict do nothing;
  return query
  select f.user_id, u.email::text,
         coalesce((select e.lang from public.course_events e where e.user_id = f.user_id and e.lang is not null order by e.ts desc limit 1), c.origin_lang, 'en'),
         p.unsubscribe_token
  from public.follows f
  join public.courses c on c.creator_slug = f.creator_slug and c.id = p_course_id
  join auth.users u on u.id = f.user_id
  join public.notification_prefs p on p.user_id = f.user_id
  where u.email is not null and p.email_new_course
    and not exists (select 1 from public.notification_log l where l.user_id = f.user_id and l.course_id = p_course_id and l.channel = 'email');
end;
$$;
revoke all on function public.notify_course_recipients(text) from public, anon, authenticated;

create or replace function public.html_escape(p text)
returns text
language sql
immutable
as $$ select replace(replace(replace(coalesce(p, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') $$;

-- Le corps de l'e-mail : anglais ou français (les autres langues reçoivent l'anglais).
create or replace function public.notify_email_html(p_lang text, p_author text, p_title text, p_url text, p_unsubscribe text)
returns text
language sql
immutable
as $$
  select format(
    '<!doctype html><html><body style="margin:0;background:#f6f7f9;font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;color:#141a26">'
    '<div style="max-width:560px;margin:0 auto;padding:32px 20px">'
    '<div style="font-size:22px;font-weight:800;color:#1a3a6b;margin-bottom:24px">Sophia</div>'
    '<div style="background:#ffffff;border-radius:20px;padding:28px">'
    '<p style="margin:0 0 8px;font-size:14px;color:#5b6472">%1$s</p>'
    '<h1 style="margin:0 0 16px;font-size:24px;line-height:1.25">%2$s</h1>'
    '<p style="margin:0 0 24px;font-size:15px;line-height:1.55;color:#3a4352">%3$s</p>'
    '<a href="%4$s" style="display:inline-block;background:#1a3a6b;color:#ffffff;text-decoration:none;font-weight:700;padding:14px 22px;border-radius:14px">%5$s</a>'
    '</div>'
    '<p style="margin:24px 0 0;font-size:12px;color:#8a93a3;line-height:1.5">%6$s <a href="%7$s" style="color:#8a93a3">%8$s</a></p>'
    '</div></body></html>',
    case when p_lang = 'fr' then format('%s vient de publier un nouveau cours', public.html_escape(p_author)) else format('%s just published a new course', public.html_escape(p_author)) end,
    public.html_escape(p_title),
    case when p_lang = 'fr' then 'Cinq parties, un quiz à livre ouvert, un glossaire. L''introduction se lit sur le site, la suite dans l''app Sophia.' else 'Five parts, an open-book quiz, a glossary. Read the introduction on the site, the rest in the Sophia app.' end,
    p_url,
    case when p_lang = 'fr' then 'Lire le cours' else 'Read the course' end,
    case when p_lang = 'fr' then 'Vous recevez cet e-mail parce que vous suivez cet auteur dans Sophia.' else 'You receive this email because you follow this author in Sophia.' end,
    p_unsubscribe,
    case when p_lang = 'fr' then 'Ne plus recevoir ces e-mails.' else 'Stop these emails.' end
  )
$$;

-- Envoie l'e-mail aux abonnés par paquets de 100 (API Resend, clé resend_api_key dans le Vault).
-- Rend le nombre de destinataires. Sans clé : rien n'est envoyé ni journalisé.
create or replace function public.notify_course_published(p_course_id text)
returns integer
language plpgsql
security definer
set search_path = public, extensions, vault
as $$
declare
  v_key text;
  v_from text;
  v_reply text;
  v_site text;
  v_author text;
  v_origin text;
  v_url text;
  v_title text;
  v_lang text;
  v_batch jsonb := '[]'::jsonb;
  v_count integer := 0;
  r record;
begin
  select decrypted_secret into v_key from vault.decrypted_secrets where name = 'resend_api_key' order by created_at desc limit 1;
  if coalesce(v_key, '') = '' then
    return 0;
  end if;
  select coalesce(nullif(value ->> 'email_from', ''), 'Sophia <hello@sophia-culture.com>'),
         coalesce(nullif(value ->> 'email_reply_to', ''), 'maximilien@vikstudios.com'),
         coalesce(nullif(value ->> 'site_url', ''), 'https://sophia-culture.com')
    into v_from, v_reply, v_site
  from public.app_config where key = 'studio';
  select cr.name, c.origin_lang into v_author, v_origin
  from public.courses c left join public.creators cr on cr.slug = c.creator_slug
  where c.id = p_course_id;
  if v_author is null then
    return 0;
  end if;
  v_url := v_site || '/courses/' || regexp_replace(p_course_id, '^course_(\d+)_.*$', '\1') || '-course';

  for r in select * from public.notify_course_recipients(p_course_id) loop
    v_lang := case when r.lang = 'fr' then 'fr' else 'en' end;
    select coalesce(
      (select cc.title from public.course_contents cc where cc.course_id = p_course_id and cc.lang = r.lang and cc.status = 'published'),
      (select cc.title from public.course_contents cc where cc.course_id = p_course_id and cc.lang = v_origin),
      p_course_id) into v_title;
    v_batch := v_batch || jsonb_build_object(
      'from', v_from,
      'to', jsonb_build_array(r.email),
      'reply_to', v_reply,
      'subject', case when v_lang = 'fr' then format('Nouveau cours de %s : %s', v_author, v_title) else format('New course by %s: %s', v_author, v_title) end,
      'html', public.notify_email_html(v_lang, v_author, v_title, v_url, v_site || '/unsubscribe?token=' || r.token::text),
      'text', case when v_lang = 'fr'
                   then format(E'%s vient de publier un nouveau cours : %s\n\nLire le cours : %s\n\nNe plus recevoir ces e-mails : %s', v_author, v_title, v_url, v_site || '/unsubscribe?token=' || r.token::text)
                   else format(E'%s just published a new course: %s\n\nRead the course: %s\n\nStop these emails: %s', v_author, v_title, v_url, v_site || '/unsubscribe?token=' || r.token::text) end
    );
    insert into public.notification_log (user_id, course_id, channel) values (r.user_id, p_course_id, 'email') on conflict do nothing;
    v_count := v_count + 1;
    if jsonb_array_length(v_batch) >= 100 then
      perform net.http_post(
        url := 'https://api.resend.com/emails/batch',
        body := v_batch,
        headers := jsonb_build_object('Authorization', 'Bearer ' || v_key, 'Content-Type', 'application/json'),
        timeout_milliseconds := 10000);
      v_batch := '[]'::jsonb;
    end if;
  end loop;
  if jsonb_array_length(v_batch) > 0 then
    perform net.http_post(
      url := 'https://api.resend.com/emails/batch',
      body := v_batch,
      headers := jsonb_build_object('Authorization', 'Bearer ' || v_key, 'Content-Type', 'application/json'),
      timeout_milliseconds := 10000);
  end if;
  return v_count;
end;
$$;
revoke all on function public.notify_course_published(text) from public, anon, authenticated;

-- Le lien « ne plus recevoir » : le site appelle cette fonction avec le jeton de l'e-mail.
create or replace function public.notification_unsubscribe(p_token uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.notification_prefs set email_new_course = false, updated_at = now() where unsubscribe_token = p_token;
  return found;
end;
$$;
revoke all on function public.notification_unsubscribe(uuid) from public, anon, authenticated;

-- Quand un cours passe publié (première langue en ligne), ses abonnés sont prévenus.
create or replace function public.courses_published_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'published' and old.status is distinct from 'published' and new.creator_slug is not null then
    perform public.notify_course_published(new.id);
  end if;
  return new;
end;
$$;
drop trigger if exists courses_published_notify on public.courses;
create trigger courses_published_notify
after update of status on public.courses
for each row execute function public.courses_published_notify();

-- ---------- 4. tendances ----------

create table if not exists public.trending_courses (
  lang text primary key,
  course_ids text[] not null default '{}',
  computed_at timestamptz not null default now()
);
comment on table public.trending_courses is 'Les cours les plus ouverts des sept derniers jours, par langue (course_events · course_open), recalculés chaque nuit. Servis aux apps par catalog_manifest → trending.';

create or replace function public.refresh_trending_courses()
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.trending_courses (lang, course_ids, computed_at)
  select t.lang, (array_agg(t.course_id order by t.n desc, t.course_id))[1:8], now()
  from (
    select e.lang, e.course_id, count(*) as n
    from public.course_events e
    join public.courses c on c.id = e.course_id and c.status = 'published'
    where e.name = 'course_open' and e.ts >= now() - interval '7 days' and e.lang is not null
    group by 1, 2
  ) t
  group by t.lang
  on conflict (lang) do update set course_ids = excluded.course_ids, computed_at = now();
$$;
revoke all on function public.refresh_trending_courses() from public, anon, authenticated;
select cron.schedule('trending-courses', '40 2 * * *', $$select public.refresh_trending_courses()$$);

-- ---------- 5. événements : pays ----------

create or replace function public.iso2_codes(p text[])
returns boolean
language sql
immutable
as $$ select coalesce(bool_and(c ~ '^[A-Z]{2}$'), true) from unnest(p) c $$;

alter table public.campaigns
  add column if not exists countries text[] check (countries is null or (array_length(countries, 1) >= 1 and public.iso2_codes(countries)));
comment on column public.campaigns.countries is 'Pays où l''événement est montré (ISO 3166-1 alpha-2, la région du téléphone). Null : partout.';

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
    'countries', case when c.countries is null then null else to_jsonb(c.countries) end,
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

-- Le manifeste : events et trending en plus des fichiers et des paquets.
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
    'trending', coalesce((select to_jsonb(t.course_ids) from public.trending_courses t where t.lang = p_lang), '[]'::jsonb)
  );
$$;

-- ---------- 6. stockage ----------

update storage.buckets
   set allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'],
       file_size_limit = greatest(coalesce(file_size_limit, 0), 6291456)
 where id = 'course-images';
