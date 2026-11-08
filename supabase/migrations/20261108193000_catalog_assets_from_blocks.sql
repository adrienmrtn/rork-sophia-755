-- Les blocs image des cours nomment leur objet dans `asset` (format V2), pas `image` :
-- l'import ne retenait que la couverture. Correction de la fonction, rattrapage des
-- ressources depuis les contenus déjà importés, et recalcul des hash des paquets (les
-- crédits en font partie).

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

  -- Les ressources (couverture, images des blocs : `asset`) et leurs crédits, depuis le français.
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
      select coalesce(b->>'asset', b->>'image')
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

-- Rattrapage : les images des blocs de tous les cours français déjà importés.
insert into public.course_assets (course_id, slug, kind, lang, url, credit)
select distinct on (cc.course_id, x.slug) cc.course_id, x.slug, 'image', null,
       'https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/' || x.slug || '.jpg',
       (select g.value->x.slug from public.catalog_import_globals g where g.key = 'credits')
from public.course_contents cc,
     lateral (
       select coalesce(b->>'asset', b->>'image') as slug
       from jsonb_array_elements(cc.content->'sections') sec, jsonb_array_elements(sec->'blocks') b
       where b->>'type' = 'image'
     ) x
where cc.lang = 'fr' and x.slug is not null and x.slug <> coalesce(cc.content->'hero'->>'image', '')
on conflict do nothing;

-- Les crédits font partie des paquets : hash et taille recalculés pour tout ce qui est importé.
update public.course_contents cc
set hash = left(md5((public.course_bundle(cc.lang, cc.course_id) - 'hash')::text), 16),
    bytes = length((public.course_bundle(cc.lang, cc.course_id) - 'hash')::text)
where cc.hash <> 'pending';

-- Les langues déjà finalisées le seront de nouveau au prochain passage du travailleur.
update public.catalog_import_state set finalized_at = null where finalized_at is not null;
