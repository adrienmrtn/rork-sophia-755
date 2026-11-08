-- Import du catalogue côté serveur et fichiers servis depuis la base (prompt 3, suite).
--
-- Le dépôt GitHub est public : Postgres lit lui-même content/ (extension http), cours par
-- cours, par lots d'une minute sous pg_cron ; aucune clé ne circule. Les fichiers que les
-- apps téléchargent (catalogue, quiz, glossaire par langue ; paquet par cours) sont produits
-- par des fonctions SQL et servis par l'Edge Function catalog-file. Un objet déposé dans le
-- bucket course-content (par scripts/import_catalog_to_supabase.py) prend le dessus : le
-- manifeste renvoie l'URL Storage quand l'objet existe, sinon celle de la fonction.
-- Appliqué à distance via Supabase MCP. Voir docs/catalogue-en-ligne.md.

create extension if not exists http with schema extensions;

-- ---------- file d'attente et état de l'import ----------

create table if not exists public.catalog_import_jobs (
  lang text not null,
  course_id text not null,
  status text not null default 'pending' check (status in ('pending', 'done', 'error')),
  attempts integer not null default 0,
  error text,
  updated_at timestamptz not null default now(),
  primary key (lang, course_id)
);
comment on table public.catalog_import_jobs is 'Un cours × une langue à importer depuis content/ du dépôt GitHub. Traité par catalog_import_run (pg_cron, toutes les minutes).';

create table if not exists public.catalog_import_state (
  lang text primary key,
  quizzes jsonb,
  glossary jsonb,
  collection_translations jsonb,
  finalized_at timestamptz,
  fetched_at timestamptz not null default now()
);
comment on table public.catalog_import_state is 'Les trois fichiers par langue de content/ (quiz, glossaire, collections traduites), lus une fois par import ; finalized_at quand les fichiers de la langue (catalog_files) ont été calculés.';

create table if not exists public.catalog_import_globals (
  key text primary key,
  value jsonb not null,
  fetched_at timestamptz not null default now()
);
comment on table public.catalog_import_globals is 'Fichiers communs de content/ lus une fois par import : credits, cover_map, withheld, collections.';

alter table public.catalog_import_jobs enable row level security;
alter table public.catalog_import_state enable row level security;
alter table public.catalog_import_globals enable row level security;

-- ---------- lecture du dépôt ----------

create or replace function public.catalog_github_fetch(p_path text, p_ref text default 'main')
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_status integer;
  v_content text;
  v_url text;
begin
  v_url := 'https://raw.githubusercontent.com/adrienmrtn/rork-sophia-755/' || p_ref || '/' || p_path;
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '20000');
  select status, content into v_status, v_content from extensions.http_get(v_url);
  if v_status <> 200 then
    raise exception 'GET % → HTTP %', p_path, v_status;
  end if;
  return v_content;
end;
$$;
revoke all on function public.catalog_github_fetch(text, text) from public;

-- ---------- fichiers servis aux apps ----------

-- Le paquet d'un cours dans une langue : tout ce qu'il faut pour le lire hors ligne.
create or replace function public.course_bundle(p_lang text, p_course_id text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id', cc.course_id,
    'lang', cc.lang,
    'hash', cc.hash,
    'content', cc.content,
    'quiz', coalesce((select q.questions from public.quizzes q where q.course_id = cc.course_id and q.lang = cc.lang), '[]'::jsonb),
    'glossary', coalesce((
      select jsonb_object_agg(g.term, jsonb_build_object(
        'displayTerm', g.display_term, 'classification', g.classification, 'explanation', g.explanation))
      from public.glossary_entries g where g.course_id = cc.course_id and g.lang = cc.lang
    ), '{}'::jsonb),
    'credits', coalesce((
      select jsonb_object_agg(a.slug, a.credit)
      from public.course_assets a
      where a.course_id = cc.course_id and a.kind in ('cover', 'image') and a.credit is not null
    ), '{}'::jsonb)
  )
  from public.course_contents cc
  where cc.course_id = p_course_id and cc.lang = p_lang;
$$;
grant execute on function public.course_bundle(text, text) to anon, authenticated, service_role;

-- Un des trois fichiers d'une langue : catalog, quizzes ou glossary.
create or replace function public.catalog_file(p_lang text, p_kind text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case p_kind
    when 'quizzes' then coalesce((
      select jsonb_object_agg(q.course_id, q.questions)
      from public.quizzes q
      join public.course_contents cc on cc.course_id = q.course_id and cc.lang = q.lang
      join public.courses c on c.id = q.course_id
      where q.lang = p_lang and cc.status = 'published' and c.status = 'published'
    ), '{}'::jsonb)
    when 'glossary' then coalesce((
      select jsonb_object_agg(g.course_id || '|' || g.term, jsonb_build_object(
        'displayTerm', g.display_term, 'classification', g.classification, 'explanation', g.explanation))
      from public.glossary_entries g
      join public.course_contents cc on cc.course_id = g.course_id and cc.lang = g.lang
      join public.courses c on c.id = g.course_id
      where g.lang = p_lang and cc.status = 'published' and c.status = 'published'
    ), '{}'::jsonb)
    when 'catalog' then jsonb_build_object(
      'lang', p_lang,
      'hash', coalesce((select f.hash from public.catalog_files f where f.lang = p_lang and f.kind = 'catalog'), ''),
      'courses', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', cc.course_id,
          'title', cc.title,
          'subtitle', cc.subtitle,
          'description', cc.description,
          'subject', c.subject,
          'subcategory', cc.subcategory,
          'hook', cc.hook,
          'creator', c.creator_slug,
          'cover', c.cover_slug,
          'tier', c.tier,
          'sections', (
            select coalesce(jsonb_agg(jsonb_build_object(
              'id', s->>'id', 'title', s->>'title', 'free', coalesce((s->>'free')::boolean, false)) order by ord), '[]'::jsonb)
            from jsonb_array_elements(cc.content->'sections') with ordinality t(s, ord)
          ),
          'quizCount', coalesce((select jsonb_array_length(q.questions) from public.quizzes q where q.course_id = cc.course_id and q.lang = cc.lang), 0),
          'hash', cc.hash
        ) order by cc.course_id)
        from public.course_contents cc
        join public.courses c on c.id = cc.course_id
        where cc.lang = p_lang and cc.status = 'published' and c.status = 'published'
      ), '[]'::jsonb),
      'collections', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', col.id,
          'title', ct.title,
          'description', ct.description,
          'cover', col.cover_slug,
          'courseIds', (
            select coalesce(jsonb_agg(ccs.course_id order by ccs.position), '[]'::jsonb)
            from public.collection_courses ccs
            join public.course_contents cc2 on cc2.course_id = ccs.course_id and cc2.lang = p_lang and cc2.status = 'published'
            where ccs.collection_id = col.id
          )
        ) order by col.sort_index)
        from public.collections col
        join public.collection_translations ct on ct.collection_id = col.id and ct.lang = p_lang
        where col.status = 'published'
      ), '[]'::jsonb),
      'creators', coalesce((
        select jsonb_agg(jsonb_build_object(
          'slug', cr.slug,
          'name', cr.name,
          'photo', cr.photo,
          'institution', cr.institution,
          'country', cr.country,
          'links', cr.links,
          'title', coalesce(cr.title->>p_lang, cr.title->>'fr'),
          'bio', coalesce(cr.bio->>p_lang, cr.bio->>'fr'),
          'verified', cr.verified,
          'courseIds', (
            select coalesce(jsonb_agg(c.id order by c.id), '[]'::jsonb)
            from public.courses c
            join public.course_contents cc3 on cc3.course_id = c.id and cc3.lang = p_lang and cc3.status = 'published'
            where c.creator_slug = cr.slug and c.status = 'published'
          )
        ) order by cr.slug)
        from public.creators cr
      ), '[]'::jsonb)
    )
    else null
  end;
$$;
grant execute on function public.catalog_file(text, text) to anon, authenticated, service_role;

-- Le manifeste dit désormais, pour chaque fichier, si un objet Storage existe (storage = true :
-- l'Edge Function catalog-manifest renvoie alors l'URL du bucket, sinon celle de catalog-file).
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
    ), '{}'::jsonb)
  );
$$;

-- ---------- import ----------

-- Les fichiers communs : créateurs, crédits, couvertures, cours retenus, structure des collections.
create or replace function public.catalog_import_prepare_globals(p_ref text default 'main')
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  a jsonb;
  c jsonb;
  i integer := 0;
begin
  for a in select * from jsonb_array_elements((public.catalog_github_fetch('content/authors.json', p_ref)::jsonb)->'authors') loop
    insert into public.creators (slug, name, photo, institution, country, links, title, bio, verified)
    values (a->>'slug', a->>'name', a->>'photo', a->>'institution', a->>'country',
            coalesce(a->'links', '{}'::jsonb), coalesce(a->'title', '{}'::jsonb), coalesce(a->'bio', '{}'::jsonb), true)
    on conflict (slug) do update set
      name = excluded.name, photo = excluded.photo, institution = excluded.institution, country = excluded.country,
      links = excluded.links, title = excluded.title, bio = excluded.bio, updated_at = now();
  end loop;
  insert into public.catalog_import_globals (key, value) values
    ('credits', public.catalog_github_fetch('content/image_credits.json', p_ref)::jsonb),
    ('cover_map', public.catalog_github_fetch('content/course_image_map.json', p_ref)::jsonb),
    ('withheld', public.catalog_github_fetch('content/catalog_withheld.json', p_ref)::jsonb),
    ('collections', public.catalog_github_fetch('content/collections/collections.json', p_ref)::jsonb)
  on conflict (key) do update set value = excluded.value, fetched_at = now();
  for c in select * from jsonb_array_elements((select value from public.catalog_import_globals where key = 'collections')) loop
    insert into public.collections (id, sort_index, cover_slug, status)
    values (c->>'id', i, nullif(c->>'coverAssetName', ''), 'published')
    on conflict (id) do update set sort_index = excluded.sort_index, cover_slug = excluded.cover_slug, updated_at = now();
    i := i + 1;
  end loop;
end;
$$;

-- Les trois fichiers d'une langue, lus une fois.
create or replace function public.catalog_import_prepare_language(p_lang text, p_ref text default 'main')
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  insert into public.catalog_import_state (lang, quizzes, glossary, collection_translations)
  values (
    p_lang,
    (select coalesce(jsonb_object_agg(e->>'courseId', e->'quiz'), '{}'::jsonb)
     from jsonb_array_elements(public.catalog_github_fetch('content/locales/' || p_lang || '/quizzes_v2.json', p_ref)::jsonb) e),
    public.catalog_github_fetch('content/glossary/' || p_lang || '.json', p_ref)::jsonb,
    public.catalog_github_fetch('content/collections/' || p_lang || '.json', p_ref)::jsonb
  )
  on conflict (lang) do update set
    quizzes = excluded.quizzes, glossary = excluded.glossary, collection_translations = excluded.collection_translations,
    fetched_at = now(), finalized_at = null;
  insert into public.collection_translations (collection_id, lang, title, description)
  select t->>'id', p_lang, replace(t->>'title', '**', ''), replace(coalesce(t->>'description', ''), '**', '')
  from jsonb_array_elements((select collection_translations from public.catalog_import_state where lang = p_lang)) t
  where exists (select 1 from public.collections col where col.id = t->>'id')
  on conflict (collection_id, lang) do update set title = excluded.title, description = excluded.description, updated_at = now();
end;
$$;

-- Un cours dans une langue : identité, contenu, quiz, glossaire, ressources, hash du paquet.
create or replace function public.catalog_import_course(p_lang text, p_course_id text, p_ref text default 'main')
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_course jsonb;
  v_quiz jsonb;
  v_withheld jsonb;
  v_status text;
  v_cover text;
  v_author text;
  v_sections text[];
  v_bundle jsonb;
begin
  if not exists (select 1 from public.catalog_import_state where lang = p_lang) then
    perform public.catalog_import_prepare_language(p_lang, p_ref);
  end if;
  v_course := public.catalog_github_fetch('content/courses/' || p_lang || '/' || p_course_id || '.json', p_ref)::jsonb;

  select value into v_withheld from public.catalog_import_globals where key = 'withheld';
  v_status := case when coalesce(v_withheld->'by_language'->p_lang, '[]'::jsonb) ? p_course_id then 'withheld' else 'published' end;
  select value->>p_course_id into v_cover from public.catalog_import_globals where key = 'cover_map';
  v_cover := coalesce(v_cover, v_course->'hero'->>'image');
  v_author := case when jsonb_typeof(v_course->'author') = 'string' then v_course->>'author' else v_course->'author'->>'slug' end;
  if v_author is not null and not exists (select 1 from public.creators where slug = v_author) then
    v_author := null;
  end if;

  insert into public.courses (id, subject, creator_slug, status, tier, origin_lang, cover_slug, published_at)
  values (p_course_id, v_course->>'subject', v_author, 'published', 'standard', 'fr', v_cover, '2026-01-01T00:00:00Z')
  on conflict (id) do update set
    subject = excluded.subject,
    creator_slug = case when p_lang = 'fr' then excluded.creator_slug else public.courses.creator_slug end,
    cover_slug = case when p_lang = 'fr' then excluded.cover_slug else public.courses.cover_slug end,
    updated_at = now();

  select coalesce(array_agg(s->>'id' order by ord), '{}'::text[]) into v_sections
  from jsonb_array_elements(v_course->'sections') with ordinality t(s, ord);

  insert into public.course_contents (course_id, lang, status, title, subtitle, description, subcategory, hook, section_ids, content, hash, bytes)
  values (p_course_id, p_lang, v_status, v_course->>'title', v_course->>'subtitle', coalesce(v_course->>'description', ''),
          coalesce(v_course->>'subcategory', ''), v_course->'hero'->>'hook', v_sections, v_course, 'pending', null)
  on conflict (course_id, lang) do update set
    status = excluded.status, title = excluded.title, subtitle = excluded.subtitle, description = excluded.description,
    subcategory = excluded.subcategory, hook = excluded.hook, section_ids = excluded.section_ids, content = excluded.content,
    version = public.course_contents.version + 1, updated_at = now();

  select coalesce(s.quizzes->p_course_id, '[]'::jsonb) into v_quiz from public.catalog_import_state s where s.lang = p_lang;
  insert into public.quizzes (course_id, lang, questions, hash)
  values (p_course_id, p_lang, v_quiz, left(md5(v_quiz::text), 16))
  on conflict (course_id, lang) do update set questions = excluded.questions, hash = excluded.hash, updated_at = now();

  delete from public.glossary_entries where course_id = p_course_id and lang = p_lang;
  insert into public.glossary_entries (course_id, lang, term, display_term, classification, explanation)
  select p_course_id, p_lang, substr(e.key, length(p_course_id) + 2),
         coalesce(e.value->>'displayTerm', substr(e.key, length(p_course_id) + 2)),
         e.value->>'classification', coalesce(e.value->>'explanation', '')
  from public.catalog_import_state s, jsonb_each(s.glossary) e
  where s.lang = p_lang and e.key like p_course_id || '|%'
  on conflict do nothing;

  -- Les ressources (couverture, images des blocs) et leurs crédits, depuis le français.
  if p_lang = 'fr' then
    delete from public.course_assets where course_id = p_course_id and kind in ('cover', 'image');
    insert into public.course_assets (course_id, slug, kind, lang, url, credit)
    select distinct on (x.slug) p_course_id, x.slug,
           case when x.slug = v_course->'hero'->>'image' then 'cover' else 'image' end, null,
           'https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/' || x.slug || '.jpg',
           (select g.value->x.slug from public.catalog_import_globals g where g.key = 'credits')
    from (
      select v_course->'hero'->>'image' as slug
      union all
      select b->>'image'
      from jsonb_array_elements(v_course->'sections') sec, jsonb_array_elements(sec->'blocks') b
      where b->>'type' = 'image'
    ) x
    where x.slug is not null
    on conflict do nothing;
  end if;

  v_bundle := public.course_bundle(p_lang, p_course_id) - 'hash';
  update public.course_contents
  set hash = left(md5(v_bundle::text), 16), bytes = length(v_bundle::text)
  where course_id = p_course_id and lang = p_lang;
end;
$$;

-- Les fichiers d'une langue, une fois tous ses cours importés.
create or replace function public.catalog_finalize_language(p_lang text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_catalog jsonb;
  v_quizzes jsonb;
  v_glossary jsonb;
begin
  insert into public.collection_courses (collection_id, course_id, position)
  select c->>'id', t.cid, t.ord - 1
  from public.catalog_import_globals g, jsonb_array_elements(g.value) c, jsonb_array_elements_text(c->'courseIds') with ordinality t(cid, ord)
  where g.key = 'collections'
    and exists (select 1 from public.courses where id = t.cid)
    and exists (select 1 from public.collections where id = c->>'id')
  on conflict (collection_id, course_id) do update set position = excluded.position;

  v_catalog := public.catalog_file(p_lang, 'catalog') || jsonb_build_object('hash', '');
  v_quizzes := public.catalog_file(p_lang, 'quizzes');
  v_glossary := public.catalog_file(p_lang, 'glossary');
  insert into public.catalog_files (lang, kind, hash, bytes) values
    (p_lang, 'catalog', left(md5(v_catalog::text), 16), length(v_catalog::text)),
    (p_lang, 'quizzes', left(md5(v_quizzes::text), 16), length(v_quizzes::text)),
    (p_lang, 'glossary', left(md5(v_glossary::text), 16), length(v_glossary::text))
  on conflict (lang, kind) do update set hash = excluded.hash, bytes = excluded.bytes, updated_at = now();
  update public.catalog_import_state set finalized_at = now() where lang = p_lang;
end;
$$;

-- Met en file tous les cours (content/courses/index.json) pour les langues demandées.
create or replace function public.catalog_import_enqueue(p_langs text[], p_ref text default 'main')
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_ids jsonb;
  v_count integer;
begin
  v_ids := (public.catalog_github_fetch('content/courses/index.json', p_ref)::jsonb)->'courses';
  insert into public.catalog_import_jobs (lang, course_id)
  select l, cid from unnest(p_langs) l, jsonb_array_elements_text(v_ids) cid
  on conflict (lang, course_id) do update set status = 'pending', attempts = 0, error = null, updated_at = now();
  update public.catalog_import_state set finalized_at = null where lang = any (p_langs);
  get diagnostics v_count = row_count;
  return (select count(*) from public.catalog_import_jobs where status = 'pending');
end;
$$;

-- Le travailleur : traite la file pendant p_seconds, finalise les langues terminées, et se
-- déprogramme de pg_cron quand il n'y a plus rien à faire.
create or replace function public.catalog_import_run(p_seconds integer default 50, p_ref text default 'main')
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_started timestamptz := clock_timestamp();
  v_job record;
  v_done integer := 0;
  v_failed integer := 0;
  v_lang text;
begin
  if not exists (select 1 from public.catalog_import_globals where key = 'credits') then
    perform public.catalog_import_prepare_globals(p_ref);
  end if;
  loop
    exit when clock_timestamp() - v_started > make_interval(secs => p_seconds);
    select * into v_job from public.catalog_import_jobs
    where status = 'pending' and attempts < 3
    order by case lang when 'fr' then 0 when 'en' then 1 else 2 end, lang, course_id
    limit 1 for update skip locked;
    exit when not found;
    begin
      perform public.catalog_import_course(v_job.lang, v_job.course_id, p_ref);
      update public.catalog_import_jobs set status = 'done', attempts = attempts + 1, error = null, updated_at = now()
      where lang = v_job.lang and course_id = v_job.course_id;
      v_done := v_done + 1;
    exception when others then
      update public.catalog_import_jobs
      set status = case when attempts + 1 >= 3 then 'error' else 'pending' end,
          attempts = attempts + 1, error = left(sqlerrm, 500), updated_at = now()
      where lang = v_job.lang and course_id = v_job.course_id;
      v_failed := v_failed + 1;
    end;
  end loop;
  for v_lang in
    select s.lang from public.catalog_import_state s
    where s.finalized_at is null
      and exists (select 1 from public.catalog_import_jobs j where j.lang = s.lang)
      and not exists (select 1 from public.catalog_import_jobs j where j.lang = s.lang and j.status = 'pending' and j.attempts < 3)
  loop
    perform public.catalog_finalize_language(v_lang);
  end loop;
  if not exists (select 1 from public.catalog_import_jobs where status = 'pending' and attempts < 3) then
    perform cron.unschedule(jobid) from cron.job where jobname = 'catalog-import';
  end if;
  return jsonb_build_object(
    'done', v_done, 'failed', v_failed,
    'pending', (select count(*) from public.catalog_import_jobs where status = 'pending' and attempts < 3),
    'errors', (select count(*) from public.catalog_import_jobs where status = 'error'));
end;
$$;

revoke all on function public.catalog_import_prepare_globals(text) from public;
revoke all on function public.catalog_import_prepare_language(text, text) from public;
revoke all on function public.catalog_import_course(text, text, text) from public;
revoke all on function public.catalog_finalize_language(text) from public;
revoke all on function public.catalog_import_enqueue(text[], text) from public;
revoke all on function public.catalog_import_run(integer, text) from public;
