-- Vraies couvertures pour les deux cours publiés qui n'en avaient pas (docs/cours-sans-couverture.md) :
--   255 · Comment un roman a-t-il sauvé Notre-Dame ?  (bandeau photo 1200x203 de la galerie des rois)
--   312 · Qu'est-ce que la machine d'Anticythère ?    (photo Wikimedia du fragment A)
--
-- À LANCER APRÈS avoir déposé dans le bucket public course-images, à la racine :
--   comment_un_roman_a_t_il_sauve_notre_dame.jpg
--   la_machine_d_anticythere.jpg
-- (fichiers dans design/covers-a-publier/). Le script refuse de tourner si l'un des deux manque.
--
-- Il pointe le cours (courses.cover_slug), sa ligne course_assets et le hero de ses 30 langues sur
-- la nouvelle image, retire le crédit photo du hero (création maison, sans crédit, comme les 310
-- autres couvertures), recalcule le hash des paquets, puis marque le catalogue : le cron
-- catalog-refinalize recalcule les fichiers de chaque langue dans la minute. Idempotent.
-- L'ancienne photo notre_dame_de_paris_cathedral_facade reste dans le bucket : c'est aussi une
-- image de bloc du cours 147.

do $$
declare
  r record;
  v_missing text;
begin
  select string_agg(t.new_slug || '.jpg', ', ') into v_missing
  from (values ('comment_un_roman_a_t_il_sauve_notre_dame'), ('la_machine_d_anticythere')) as t(new_slug)
  where not exists (
    select 1 from storage.objects o where o.bucket_id = 'course-images' and o.name = t.new_slug || '.jpg'
  );
  if v_missing is not null then
    raise exception 'Déposer d''abord dans le bucket course-images : %', v_missing;
  end if;

  for r in
    select * from (values
      ('course_255_comment_un_roman_a_t_il_sauve_notre_dame', 'comment_un_roman_a_t_il_sauve_notre_dame'),
      ('course_312_qu_est_ce_que_la_machine_d_anticythere', 'la_machine_d_anticythere')
    ) as t(course_id, new_slug)
  loop
    update public.courses
       set cover_slug = r.new_slug, updated_at = now()
     where id = r.course_id and cover_slug is distinct from r.new_slug;

    update public.course_assets
       set slug = r.new_slug,
           url = 'https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/' || r.new_slug || '.jpg',
           credit = null
     where course_id = r.course_id and kind = 'cover';

    update public.course_contents
       set content = jsonb_set(content #- '{hero,credit}', '{hero,image}', to_jsonb(r.new_slug), true),
           version = version + 1,
           updated_at = now()
     where course_id = r.course_id
       and (content -> 'hero' ->> 'image' is distinct from r.new_slug or content -> 'hero' ? 'credit');

    update public.course_contents cc
       set hash = left(md5((public.course_bundle(cc.lang, cc.course_id) - 'hash')::text), 16),
           bytes = length((public.course_bundle(cc.lang, cc.course_id) - 'hash')::text)
     where cc.course_id = r.course_id;
  end loop;

  update public.catalog_dirty set dirty_at = now() where id;
end;
$$;

-- Contrôle : deux lignes, cover_slug = slug de l'asset = image du hero, 30 langues chacune.
select c.id, c.cover_slug, a.slug as asset_slug, a.credit,
       (select count(*) from public.course_contents cc where cc.course_id = c.id and cc.content -> 'hero' ->> 'image' = c.cover_slug) as langs_ok
from public.courses c
left join public.course_assets a on a.course_id = c.id and a.kind = 'cover'
where c.id in ('course_255_comment_un_roman_a_t_il_sauve_notre_dame', 'course_312_qu_est_ce_que_la_machine_d_anticythere');
