-- Les apps affichent le portrait hébergé d'un créateur du Studio (creators.photo_url) quand il
-- n'a pas de ressource embarquée (photo) : le fichier catalogue le sert sous la clé photoUrl.
-- Redéfinition de catalog_file à l'identique, plus cette clé dans creators[].

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
          'photoUrl', cr.photo_url,
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

-- Les hash des catalogues changent (nouvelle clé) : on les recalcule pour toutes les langues
-- qui ont un contenu, pour que le manifeste fasse retélécharger le fichier aux apps.
select public.catalog_finalize_language(l.lang)
from (select distinct lang from public.course_contents) l;
