-- L'équipe gère le catalogue depuis le site (10 novembre) : modifier le texte et les images d'un
-- cours dans une langue, retirer ou remettre une langue, archiver ou supprimer un cours.
-- Toutes les écritures passent par ces fonctions (admin seulement) ; les hash des fichiers que les
-- apps téléchargent sont recalculés dans la foulée, pour que la modification arrive au prochain
-- manifeste (une heure au plus).

-- La liste des cours pour l'équipe : titre d'origine, créateur, langues en ligne.
create or replace function public.catalog_admin_courses()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case when public.is_studio_admin() then coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', c.id,
      'subject', c.subject,
      'status', c.status,
      'tier', c.tier,
      'origin_lang', c.origin_lang,
      'cover_slug', c.cover_slug,
      'creator_slug', c.creator_slug,
      'creator_name', cr.name,
      'published_at', c.published_at,
      'updated_at', greatest(c.updated_at, (select max(cc.updated_at) from public.course_contents cc where cc.course_id = c.id)),
      'title', coalesce((select cc.title from public.course_contents cc where cc.course_id = c.id and cc.lang = c.origin_lang),
                        (select cc.title from public.course_contents cc where cc.course_id = c.id order by cc.lang limit 1)),
      'langs_published', (select count(*) from public.course_contents cc where cc.course_id = c.id and cc.status = 'published'),
      'langs_total', (select count(*) from public.course_contents cc where cc.course_id = c.id)
    ) order by c.updated_at desc)
    from public.courses c left join public.creators cr on cr.slug = c.creator_slug
  ), '[]'::jsonb) else null end;
$$;
revoke all on function public.catalog_admin_courses() from public;
grant execute on function public.catalog_admin_courses() to authenticated;

-- Remplace le contenu d'une langue (format V2 : titre, description, sections et blocs, sources) et
-- son glossaire ; recalcule le hash du paquet et celui du fichier catalogue de la langue.
create or replace function public.catalog_admin_update_content(p_course_id text, p_lang text, p_course jsonb, p_glossary jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  c public.courses;
  cc public.course_contents;
  v_content jsonb;
  v_sections jsonb;
  v_ids text[];
  v_bundle jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  select * into c from public.courses where id = p_course_id;
  if c.id is null then
    raise exception 'Course not found: %', p_course_id;
  end if;
  select * into cc from public.course_contents where course_id = p_course_id and lang = p_lang;
  if cc.course_id is null then
    raise exception 'This course has no content in %. The factory produces the languages; this page edits them.', p_lang;
  end if;
  if jsonb_typeof(p_course -> 'sections') <> 'array' or jsonb_array_length(p_course -> 'sections') < 1 then
    raise exception 'A course needs at least one section.';
  end if;
  v_content := p_course || jsonb_build_object('id', p_course_id);
  if (cc.content ? 'author') and not (v_content ? 'author') then
    v_content := v_content || jsonb_build_object('author', cc.content -> 'author');
  end if;
  -- Chaque partie garde son identifiant (les statistiques de décrochage s'y accrochent) ; une partie nouvelle en reçoit un.
  select jsonb_agg(case when coalesce(s ->> 'id', '') <> '' then s else s || jsonb_build_object('id', p_course_id || '_p' || (ord - 1)::text || '_' || to_char(now(), 'YYMMDDHH24MI')) end order by ord)
    into v_sections
  from jsonb_array_elements(v_content -> 'sections') with ordinality t(s, ord);
  v_content := jsonb_set(v_content, '{sections}', coalesce(v_sections, '[]'::jsonb));
  select coalesce(array_agg(s ->> 'id' order by ord), '{}'::text[]) into v_ids
  from jsonb_array_elements(v_content -> 'sections') with ordinality t(s, ord);

  update public.course_contents
     set title = coalesce(p_course ->> 'title', title),
         subtitle = p_course ->> 'subtitle',
         description = coalesce(p_course ->> 'description', ''),
         subcategory = coalesce(p_course ->> 'subcategory', ''),
         hook = p_course -> 'hero' ->> 'hook',
         section_ids = v_ids,
         content = v_content,
         version = version + 1,
         updated_at = now()
   where course_id = p_course_id and lang = p_lang;

  delete from public.glossary_entries where course_id = p_course_id and lang = p_lang;
  insert into public.glossary_entries (course_id, lang, term, display_term, classification, explanation)
  select p_course_id, p_lang, e.key, coalesce(nullif(e.value ->> 'displayTerm', ''), e.key), coalesce(nullif(e.value ->> 'classification', ''), 'concept'), coalesce(e.value ->> 'explanation', '')
  from jsonb_each(coalesce(p_glossary, '{}'::jsonb)) e
  where e.key <> '';

  if p_lang = c.origin_lang then
    update public.courses
       set subject = coalesce(nullif(p_course ->> 'subject', ''), subject),
           cover_slug = coalesce(nullif(p_course -> 'hero' ->> 'image', ''), cover_slug),
           updated_at = now()
     where id = p_course_id;
  end if;

  v_bundle := public.course_bundle(p_lang, p_course_id) - 'hash';
  update public.course_contents
     set hash = left(md5(v_bundle::text), 16), bytes = length(v_bundle::text)
   where course_id = p_course_id and lang = p_lang
  returning * into cc;
  perform public.catalog_finalize_language(p_lang);
  return jsonb_build_object('updated_at', cc.updated_at, 'version', cc.version, 'hash', cc.hash);
end;
$$;
revoke all on function public.catalog_admin_update_content(text, text, jsonb, jsonb) from public;
grant execute on function public.catalog_admin_update_content(text, text, jsonb, jsonb) to authenticated;

-- Retirer une langue des apps (withheld) ou la remettre en ligne.
create or replace function public.catalog_admin_set_content_status(p_course_id text, p_lang text, p_status text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  if p_status not in ('published', 'withheld') then
    raise exception 'Status must be published or withheld';
  end if;
  update public.course_contents set status = p_status, updated_at = now()
   where course_id = p_course_id and lang = p_lang and status in ('published', 'withheld')
  returning status into v_status;
  if v_status is null then
    raise exception 'No published or withheld content in % for this course', p_lang;
  end if;
  perform public.catalog_finalize_language(p_lang);
  return v_status;
end;
$$;
revoke all on function public.catalog_admin_set_content_status(text, text, text) from public;
grant execute on function public.catalog_admin_set_content_status(text, text, text) to authenticated;

-- Archiver un cours (il disparaît des apps dans toutes les langues, rien n'est perdu) ou le remettre.
create or replace function public.catalog_admin_set_course_status(p_course_id text, p_status text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  if p_status not in ('published', 'archived') then
    raise exception 'Status must be published or archived';
  end if;
  update public.courses set status = p_status, updated_at = now(), published_at = coalesce(published_at, case when p_status = 'published' then now() end)
   where id = p_course_id returning status into v_status;
  if v_status is null then
    raise exception 'Course not found: %', p_course_id;
  end if;
  update public.catalog_dirty set dirty_at = now() where id;
  return v_status;
end;
$$;
revoke all on function public.catalog_admin_set_course_status(text, text) from public;
grant execute on function public.catalog_admin_set_course_status(text, text) to authenticated;

-- Supprimer un cours pour de bon : ses contenus, quiz, glossaires, collections et jobs suivent
-- (cascades) ; le brouillon du Studio qui le portait reste, détaché. Les images du bucket restent.
create or replace function public.catalog_admin_delete_course(p_course_id text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_title text;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  select coalesce((select cc.title from public.course_contents cc where cc.course_id = c.id and cc.lang = c.origin_lang), c.id)
    into v_title from public.courses c where c.id = p_course_id;
  if v_title is null then
    raise exception 'Course not found: %', p_course_id;
  end if;
  update public.studio_drafts set status = 'archived' where app_course_id = p_course_id and status in ('published', 'publishing', 'failed');
  delete from public.courses where id = p_course_id;
  update public.catalog_dirty set dirty_at = now() where id;
  return v_title;
end;
$$;
revoke all on function public.catalog_admin_delete_course(text) from public;
grant execute on function public.catalog_admin_delete_course(text) to authenticated;
