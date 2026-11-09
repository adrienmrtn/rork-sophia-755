-- 1. Les apps installées lisent le crédit d'une image comme une chaîne (« auteur · titre · licence ·
--    source ») ; l'usine écrit un objet {title, author, license, source}. Un paquet qui porte un
--    objet ne se décode pas et l'app affiche « ce cours n'est pas encore sur ton téléphone ».
--    course_bundle sert désormais le contenu avec des crédits en chaîne, et verse l'objet dans la
--    carte `credits` du paquet (clé : slug de l'image), que les apps savent lire.
-- 2. Le brouillon du Studio suivait un job « partial » comme publié, même quand rien n'a été
--    publié (quiz refusé) : on regarde maintenant le statut réel du cours.

create or replace function public.catalog_credit_line(p_credit jsonb)
returns text
language sql
immutable
as $$
  select nullif(concat_ws(' · ',
    nullif(p_credit->>'author', ''), nullif(p_credit->>'title', ''),
    nullif(p_credit->>'license', ''), nullif(p_credit->>'source', '')), '');
$$;

create or replace function public.catalog_content_for_apps(p_content jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  v jsonb := p_content;
  sections jsonb := '[]'::jsonb;
  sec jsonb;
  blocks jsonb;
  blk jsonb;
begin
  if v is null then
    return null;
  end if;
  if jsonb_typeof(v->'hero'->'credit') = 'object' then
    v := jsonb_set(v, '{hero,credit}', coalesce(to_jsonb(public.catalog_credit_line(v->'hero'->'credit')), 'null'::jsonb), true);
  end if;
  if jsonb_typeof(v->'sections') = 'array' then
    for sec in select * from jsonb_array_elements(v->'sections') loop
      blocks := '[]'::jsonb;
      if jsonb_typeof(sec->'blocks') = 'array' then
        for blk in select * from jsonb_array_elements(sec->'blocks') loop
          if jsonb_typeof(blk->'credit') = 'object' then
            blk := jsonb_set(blk, '{credit}', coalesce(to_jsonb(public.catalog_credit_line(blk->'credit')), 'null'::jsonb), true);
          end if;
          blocks := blocks || jsonb_build_array(blk);
        end loop;
        sec := jsonb_set(sec, '{blocks}', blocks, true);
      end if;
      sections := sections || jsonb_build_array(sec);
    end loop;
    v := jsonb_set(v, '{sections}', sections, true);
  end if;
  return v;
end;
$$;

-- Un crédit tel que les apps le décodent : les quatre champs toujours présents (chaînes, vides sinon).
create or replace function public.catalog_credit_object(p_credit jsonb)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'title', coalesce(p_credit->>'title', ''),
    'author', coalesce(p_credit->>'author', ''),
    'license', coalesce(p_credit->>'license', ''),
    'source', coalesce(p_credit->>'source', ''));
$$;

-- Les crédits structurés portés par le contenu lui-même, par slug d'image.
create or replace function public.catalog_content_credits(p_content jsonb)
returns jsonb
language sql
immutable
as $$
  select coalesce((
    select jsonb_object_agg(slug, public.catalog_credit_object(credit))
    from (
      select p_content->'hero'->>'image' as slug, p_content->'hero'->'credit' as credit
      where jsonb_typeof(p_content->'hero'->'credit') = 'object' and coalesce(p_content->'hero'->>'image', '') <> ''
      union all
      select b->>'asset', b->'credit'
      from jsonb_array_elements(coalesce(p_content->'sections', '[]'::jsonb)) s,
           jsonb_array_elements(coalesce(s->'blocks', '[]'::jsonb)) b
      where b->>'type' = 'image' and jsonb_typeof(b->'credit') = 'object' and coalesce(b->>'asset', '') <> ''
    ) t
  ), '{}'::jsonb);
$$;

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
    'content', public.catalog_content_for_apps(cc.content),
    'quiz', coalesce((select q.questions from public.quizzes q where q.course_id = cc.course_id and q.lang = cc.lang), '[]'::jsonb),
    'glossary', coalesce((
      select jsonb_object_agg(g.term, jsonb_build_object(
        'displayTerm', g.display_term, 'classification', g.classification, 'explanation', g.explanation))
      from public.glossary_entries g where g.course_id = cc.course_id and g.lang = cc.lang
    ), '{}'::jsonb),
    'credits', public.catalog_content_credits(cc.content) || coalesce((
      select jsonb_object_agg(a.slug, public.catalog_credit_object(a.credit))
      from public.course_assets a
      where a.course_id = cc.course_id and a.kind in ('cover', 'image') and a.credit is not null and jsonb_typeof(a.credit) = 'object'
    ), '{}'::jsonb)
  )
  from public.course_contents cc
  where cc.course_id = p_course_id and cc.lang = p_lang;
$$;
grant execute on function public.course_bundle(text, text) to anon, authenticated, service_role;

-- 2. Le brouillon suit l'état réel du cours à la fin du job.
create or replace function public.studio_sync_draft_from_job()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_published boolean;
begin
  if new.status is distinct from old.status and new.status in ('done', 'partial', 'failed') then
    select c.status = 'published' into v_published from public.courses c where c.id = new.course_id;
    if new.status in ('done', 'partial') and coalesce(v_published, false) then
      update public.studio_drafts
         set status = 'published', published_at = coalesce(published_at, now())
       where last_job_id = new.id and status in ('publishing', 'accepted', 'failed');
      insert into public.studio_reviews (draft_id, decision, comment)
      select d.id, 'published', 'Job ' || new.id::text || ' : ' || new.status
      from public.studio_drafts d where d.last_job_id = new.id;
    else
      update public.studio_drafts set status = 'failed' where last_job_id = new.id and status in ('publishing', 'accepted', 'published');
      insert into public.studio_reviews (draft_id, decision, comment)
      select d.id, 'publish_failed', left(coalesce(new.error, 'the factory published nothing (job ' || new.status || ')'), 600)
      from public.studio_drafts d where d.last_job_id = new.id;
    end if;
  end if;
  return new;
end;
$$;

-- Le cours Manchester United : rien n'a été publié (quiz refusé), le brouillon doit le dire.
update public.studio_drafts d
   set status = 'failed'
  from public.production_jobs j
 where d.last_job_id = j.id and d.status = 'published'
   and not exists (select 1 from public.courses c where c.id = j.course_id and c.status = 'published');
