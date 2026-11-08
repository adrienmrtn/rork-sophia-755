-- Catalogue de cours en ligne (prompt 3) : les cours, leurs contenus par langue, quiz,
-- glossaire, collections, créateurs et ressources quittent les bundles des apps pour
-- Supabase. Les apps lisent un manifeste (fonction catalog_manifest, servie par l'Edge
-- Function catalog-manifest) puis téléchargent les JSON depuis le bucket public
-- `course-content`, à des adresses qui contiennent le hash du contenu (cache immuable).
-- Appliqué à distance via Supabase MCP (projet afnmcoovdvbtkgohtdij). Voir docs/catalogue-en-ligne.md.

-- ---------- créateurs ----------

create table if not exists public.creators (
  slug text primary key,
  name text not null,
  photo text,
  institution text,
  country text,
  links jsonb not null default '{}'::jsonb,
  title jsonb not null default '{}'::jsonb,
  bio jsonb not null default '{}'::jsonb,
  verified boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.creators is 'Les créateurs de cours (ex content/authors.json). title et bio sont des objets par code langue.';

-- ---------- cours ----------

create table if not exists public.courses (
  id text primary key,
  subject text not null,
  creator_slug text references public.creators(slug) on delete set null,
  status text not null default 'published' check (status in ('draft', 'published', 'archived')),
  tier text not null default 'standard' check (tier in ('standard', 'premium')),
  origin_lang text not null default 'fr',
  cover_slug text,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.courses is 'Identité d''un cours, indépendante de la langue. L''id est le slug historique (course_NN_…), partagé par toutes les langues et par la progression des lecteurs.';
comment on column public.courses.subject is 'Clé de stockage : histoire, sciences, litterature, art, mythologie, comprendreLeMonde.';
comment on column public.courses.cover_slug is 'Nom de l''objet de couverture dans le bucket course-images (sans .jpg).';

create index if not exists courses_status_idx on public.courses (status);
create index if not exists courses_creator_idx on public.courses (creator_slug);

-- ---------- contenu par langue ----------

create table if not exists public.course_contents (
  course_id text not null references public.courses(id) on delete cascade,
  lang text not null,
  version integer not null default 1,
  status text not null default 'published' check (status in ('draft', 'published', 'withheld')),
  title text not null,
  subtitle text,
  description text not null default '',
  subcategory text not null default '',
  hook text,
  section_ids text[] not null default '{}'::text[],
  content jsonb not null,
  hash text not null,
  bytes integer,
  updated_at timestamptz not null default now(),
  primary key (course_id, lang)
);
comment on table public.course_contents is 'Le contenu V2 complet d''un cours dans une langue (même format que les anciens fichiers CoursesV2). hash = sha256 tronqué du paquet {content, quiz, glossary, credits} servi aux apps.';
comment on column public.course_contents.status is 'withheld : le cours n''est pas distribué dans cette langue (ex. listes ContentCatalog.withheldCourseIds).';

create index if not exists course_contents_lang_idx on public.course_contents (lang, status);

-- ---------- quiz ----------

create table if not exists public.quizzes (
  course_id text not null references public.courses(id) on delete cascade,
  lang text not null,
  questions jsonb not null default '[]'::jsonb,
  hash text not null,
  updated_at timestamptz not null default now(),
  primary key (course_id, lang)
);
comment on table public.quizzes is 'Les questions d''un cours dans une langue (format QuizQuestion des apps ; les ids <courseId>_qN sont stables, l''Entraînement s''y réfère).';

-- ---------- glossaire ----------

create table if not exists public.glossary_entries (
  course_id text not null references public.courses(id) on delete cascade,
  lang text not null,
  term text not null,
  display_term text not null,
  classification text,
  explanation text not null,
  updated_at timestamptz not null default now(),
  primary key (course_id, lang, term)
);
comment on table public.glossary_entries is 'Un terme de glossaire lié [[terme]] dans un cours. Clé historique des apps : "<courseId>|<term>".';

create index if not exists glossary_entries_lang_idx on public.glossary_entries (lang);

-- ---------- collections ----------

create table if not exists public.collections (
  id text primary key,
  sort_index integer not null default 0,
  cover_slug text,
  status text not null default 'published' check (status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.collections is 'Les collections du Parcours (ex CollectionData). sort_index est l''ordre des niveaux : il verrouille la progression des lecteurs, ne pas le changer à la légère.';

create table if not exists public.collection_courses (
  collection_id text not null references public.collections(id) on delete cascade,
  course_id text not null references public.courses(id) on delete cascade,
  position integer not null default 0,
  primary key (collection_id, course_id)
);

create table if not exists public.collection_translations (
  collection_id text not null references public.collections(id) on delete cascade,
  lang text not null,
  title text not null,
  description text not null default '',
  updated_at timestamptz not null default now(),
  primary key (collection_id, lang)
);

-- ---------- ressources ----------

create table if not exists public.course_assets (
  id bigint generated always as identity primary key,
  course_id text not null references public.courses(id) on delete cascade,
  slug text not null,
  kind text not null check (kind in ('cover', 'image', 'audio')),
  lang text,
  url text not null,
  credit jsonb,
  created_at timestamptz not null default now()
);
comment on table public.course_assets is 'Images (couverture, images des blocs) et narrations audio d''un cours, avec leur crédit (ex image_credits.json).';

create unique index if not exists course_assets_unique_idx
  on public.course_assets (course_id, kind, slug, coalesce(lang, ''));

-- ---------- fichiers par langue et retenues ----------

create table if not exists public.catalog_files (
  lang text not null,
  kind text not null check (kind in ('catalog', 'quizzes', 'glossary')),
  hash text not null,
  bytes integer,
  updated_at timestamptz not null default now(),
  primary key (lang, kind)
);
comment on table public.catalog_files is 'Les trois fichiers par langue servis aux apps depuis le bucket course-content : <lang>/catalog.<hash>.json, <lang>/quizzes.<hash>.json, <lang>/glossary.<hash>.json.';

-- ---------- configuration distante ----------

create table if not exists public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);
comment on table public.app_config is 'Réglages lus par les apps au lancement (lecture publique). catalog : {"enabled": true, "refresh_hours": 6, "share": 1.0}.';

insert into public.app_config (key, value)
values ('catalog', '{"enabled": true, "refresh_hours": 6, "share": 1.0}'::jsonb)
on conflict (key) do nothing;

-- ---------- RLS : lecture publique de ce qui est publié, écriture réservée au service ----------

alter table public.creators enable row level security;
alter table public.courses enable row level security;
alter table public.course_contents enable row level security;
alter table public.quizzes enable row level security;
alter table public.glossary_entries enable row level security;
alter table public.collections enable row level security;
alter table public.collection_courses enable row level security;
alter table public.collection_translations enable row level security;
alter table public.course_assets enable row level security;
alter table public.catalog_files enable row level security;
alter table public.app_config enable row level security;

drop policy if exists creators_public_read on public.creators;
create policy creators_public_read on public.creators for select to anon, authenticated using (true);

drop policy if exists courses_public_read on public.courses;
create policy courses_public_read on public.courses for select to anon, authenticated using (status = 'published');

drop policy if exists course_contents_public_read on public.course_contents;
create policy course_contents_public_read on public.course_contents for select to anon, authenticated
  using (status = 'published' and exists (select 1 from public.courses c where c.id = course_id and c.status = 'published'));

drop policy if exists quizzes_public_read on public.quizzes;
create policy quizzes_public_read on public.quizzes for select to anon, authenticated
  using (exists (select 1 from public.courses c where c.id = course_id and c.status = 'published'));

drop policy if exists glossary_public_read on public.glossary_entries;
create policy glossary_public_read on public.glossary_entries for select to anon, authenticated
  using (exists (select 1 from public.courses c where c.id = course_id and c.status = 'published'));

drop policy if exists collections_public_read on public.collections;
create policy collections_public_read on public.collections for select to anon, authenticated using (status = 'published');

drop policy if exists collection_courses_public_read on public.collection_courses;
create policy collection_courses_public_read on public.collection_courses for select to anon, authenticated using (true);

drop policy if exists collection_translations_public_read on public.collection_translations;
create policy collection_translations_public_read on public.collection_translations for select to anon, authenticated using (true);

drop policy if exists course_assets_public_read on public.course_assets;
create policy course_assets_public_read on public.course_assets for select to anon, authenticated using (true);

drop policy if exists catalog_files_public_read on public.catalog_files;
create policy catalog_files_public_read on public.catalog_files for select to anon, authenticated using (true);

drop policy if exists app_config_public_read on public.app_config;
create policy app_config_public_read on public.app_config for select to anon, authenticated using (true);

-- ---------- bucket public course-content ----------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('course-content', 'course-content', true, 5242880, array['application/json']::text[])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists course_content_public_read on storage.objects;
create policy course_content_public_read on storage.objects
  for select to public using (bucket_id = 'course-content');

-- ---------- manifeste ----------

-- Ce qu'une app doit avoir pour une langue : les trois fichiers de la langue et le paquet de
-- chaque cours publié, avec le hash qui sert de nom d'objet. Les chemins sont relatifs à
-- <SUPABASE_URL>/storage/v1/object/public/course-content/.
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
        'path', format('%s/%s.%s.json', p_lang, f.kind, f.hash)
      ))
      from public.catalog_files f
      where f.lang = p_lang
    ), '{}'::jsonb),
    'courses', coalesce((
      select jsonb_object_agg(cc.course_id, jsonb_build_object(
        'hash', cc.hash,
        'bytes', cc.bytes,
        'path', format('%s/courses/%s.%s.json', p_lang, cc.course_id, cc.hash)
      ))
      from public.course_contents cc
      join public.courses c on c.id = cc.course_id
      where cc.lang = p_lang and cc.status = 'published' and c.status = 'published'
    ), '{}'::jsonb)
  );
$$;

revoke all on function public.catalog_manifest(text) from public;
grant execute on function public.catalog_manifest(text) to anon, authenticated, service_role;
