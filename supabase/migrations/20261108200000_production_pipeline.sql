-- Pont Studio ↔ app (prompt 4) : le Studio (sophia-culture.com) envoie un cours dans sa langue
-- d'origine ; l'app le produit (traductions, quiz, glossaire, couverture, audio) dans l'usine
-- GitHub Actions, le publie langue par langue, puis renvoie des statistiques.
--
-- Ici : les jobs de production et leurs étapes, l'upsert direct d'un cours (sans passer par
-- GitHub), le dispatch des jobs vers GitHub Actions (repository_dispatch, jeton dans le Vault),
-- le webhook vers le Studio à chaque étape (pg_net), et les fonctions d'export de statistiques.
-- Appliqué à distance via Supabase MCP. Contrat : docs/publish-contract.md.

create extension if not exists pg_net with schema extensions;

-- ---------- statuts et créateurs ----------

alter table public.courses drop constraint if exists courses_status_check;
alter table public.courses add constraint courses_status_check
  check (status in ('draft', 'in_production', 'published', 'archived'));

alter table public.course_contents drop constraint if exists course_contents_status_check;
alter table public.course_contents add constraint course_contents_status_check
  check (status in ('draft', 'in_production', 'published', 'withheld', 'failed'));

alter table public.creators add column if not exists photo_url text;
alter table public.creators add column if not exists user_id uuid;
comment on column public.creators.photo_url is 'Portrait hébergé (Studio) quand il n''est pas dans le bundle des apps (photo).';
comment on column public.creators.user_id is 'Compte Supabase du créateur quand il est connu : ses lectures de ses propres cours ne comptent pas dans creator_premium_minutes.';

-- ---------- jobs de production ----------

create table if not exists public.production_jobs (
  id uuid primary key default gen_random_uuid(),
  course_id text not null references public.courses(id) on delete cascade,
  origin_lang text not null default 'fr',
  kind text not null default 'course' check (kind in ('course', 'video')),
  status text not null default 'queued' check (status in ('queued', 'dispatched', 'running', 'done', 'partial', 'failed')),
  requested_by text,
  payload jsonb not null default '{}'::jsonb,
  options jsonb not null default '{}'::jsonb,
  summary jsonb not null default '{}'::jsonb,
  error text,
  dispatched_at timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.production_jobs is 'Une demande de production reçue par publish-course : le cours dans sa langue d''origine (payload), les options, et l''état global. Les étapes sont dans production_steps.';

create table if not exists public.production_steps (
  id bigint generated always as identity primary key,
  job_id uuid not null references public.production_jobs(id) on delete cascade,
  step text not null check (step in ('translate', 'gate', 'quiz', 'glossary', 'cover', 'audio', 'publish')),
  lang text,
  status text not null default 'pending' check (status in ('pending', 'running', 'done', 'failed', 'skipped')),
  detail jsonb not null default '{}'::jsonb,
  started_at timestamptz,
  finished_at timestamptz,
  updated_at timestamptz not null default now()
);
comment on table public.production_steps is 'Une étape d''un job, par langue quand ça a un sens (translate, gate, audio). detail : constats de la porte, nombre de questions, erreurs.';
create unique index if not exists production_steps_unique on public.production_steps (job_id, step, coalesce(lang, ''));
create index if not exists production_jobs_status_idx on public.production_jobs (status, created_at);

alter table public.production_jobs enable row level security;
alter table public.production_steps enable row level security;

-- ---------- upsert direct d'un cours (utilisé par l'import GitHub et par l'usine) ----------

-- Écrit un cours dans une langue : identité, contenu, quiz, glossaire (clés « terme » ou
-- « <courseId>|terme »), ressources et crédits (quand p_with_assets, par défaut pour le
-- français), puis le hash du paquet. Rend {course_id, lang, hash, bytes, status}.
create or replace function public.catalog_upsert_course(
  p_lang text,
  p_course jsonb,
  p_quiz jsonb default '[]'::jsonb,
  p_glossary jsonb default '{}'::jsonb,
  p_status text default 'published',
  p_creator_slug text default null,
  p_cover_slug text default null,
  p_with_assets boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_course_id text := p_course->>'id';
  v_cover text;
  v_author text;
  v_sections text[];
  v_bundle jsonb;
  v_with_assets boolean := coalesce(p_with_assets, p_lang = 'fr');
begin
  if v_course_id is null or v_course_id !~ '^course_[0-9]+_[a-z0-9_]+$' then
    raise exception 'id de cours invalide : %', v_course_id;
  end if;
  v_author := coalesce(p_creator_slug,
    case when jsonb_typeof(p_course->'author') = 'string' then p_course->>'author' else p_course->'author'->>'slug' end);
  if v_author is not null and not exists (select 1 from public.creators where slug = v_author) then
    v_author := null;
  end if;
  v_cover := coalesce(p_cover_slug, p_course->'hero'->>'image');

  insert into public.courses (id, subject, creator_slug, status, tier, origin_lang, cover_slug, published_at)
  values (v_course_id, p_course->>'subject', v_author, 'published', 'standard', 'fr', v_cover, now())
  on conflict (id) do update set
    subject = excluded.subject,
    creator_slug = case when v_with_assets or public.courses.creator_slug is null then coalesce(excluded.creator_slug, public.courses.creator_slug) else public.courses.creator_slug end,
    cover_slug = case when v_with_assets or public.courses.cover_slug is null then coalesce(excluded.cover_slug, public.courses.cover_slug) else public.courses.cover_slug end,
    updated_at = now();

  select coalesce(array_agg(s->>'id' order by ord), '{}'::text[]) into v_sections
  from jsonb_array_elements(p_course->'sections') with ordinality t(s, ord);

  insert into public.course_contents (course_id, lang, status, title, subtitle, description, subcategory, hook, section_ids, content, hash, bytes)
  values (v_course_id, p_lang, p_status, p_course->>'title', p_course->>'subtitle', coalesce(p_course->>'description', ''),
          coalesce(p_course->>'subcategory', ''), p_course->'hero'->>'hook', v_sections, p_course, 'pending', null)
  on conflict (course_id, lang) do update set
    status = excluded.status, title = excluded.title, subtitle = excluded.subtitle, description = excluded.description,
    subcategory = excluded.subcategory, hook = excluded.hook, section_ids = excluded.section_ids, content = excluded.content,
    version = public.course_contents.version + 1, updated_at = now();

  insert into public.quizzes (course_id, lang, questions, hash)
  values (v_course_id, p_lang, coalesce(p_quiz, '[]'::jsonb), left(md5(coalesce(p_quiz, '[]'::jsonb)::text), 16))
  on conflict (course_id, lang) do update set questions = excluded.questions, hash = excluded.hash, updated_at = now();

  delete from public.glossary_entries where course_id = v_course_id and lang = p_lang;
  insert into public.glossary_entries (course_id, lang, term, display_term, classification, explanation)
  select v_course_id, p_lang,
         case when position('|' in e.key) > 0 then substr(e.key, position('|' in e.key) + 1) else e.key end,
         coalesce(e.value->>'displayTerm', case when position('|' in e.key) > 0 then substr(e.key, position('|' in e.key) + 1) else e.key end),
         e.value->>'classification', coalesce(e.value->>'explanation', '')
  from jsonb_each(coalesce(p_glossary, '{}'::jsonb)) e
  where position('|' in e.key) = 0 or split_part(e.key, '|', 1) = v_course_id
  on conflict do nothing;

  if v_with_assets then
    delete from public.course_assets where course_id = v_course_id and kind in ('cover', 'image');
    insert into public.course_assets (course_id, slug, kind, lang, url, credit)
    select distinct on (x.slug) v_course_id, x.slug,
           case when x.slug = p_course->'hero'->>'image' then 'cover' else 'image' end, null,
           'https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/' || x.slug || '.jpg',
           coalesce(x.credit, (select g.value->x.slug from public.catalog_import_globals g where g.key = 'credits'))
    from (
      select p_course->'hero'->>'image' as slug, p_course->'hero'->'credit' as credit
      union all
      select coalesce(b->>'asset', b->>'image'), case when jsonb_typeof(b->'credit') = 'object' then b->'credit' else null end
      from jsonb_array_elements(p_course->'sections') sec, jsonb_array_elements(sec->'blocks') b
      where b->>'type' = 'image'
    ) x
    where x.slug is not null
    on conflict do nothing;
  end if;

  v_bundle := public.course_bundle(p_lang, v_course_id) - 'hash';
  update public.course_contents
  set hash = left(md5(v_bundle::text), 16), bytes = length(v_bundle::text)
  where course_id = v_course_id and lang = p_lang;

  return jsonb_build_object('course_id', v_course_id, 'lang', p_lang, 'status', p_status,
                            'hash', left(md5(v_bundle::text), 16), 'bytes', length(v_bundle::text));
end;
$$;
revoke all on function public.catalog_upsert_course(text, jsonb, jsonb, jsonb, text, text, text, boolean) from public;
grant execute on function public.catalog_upsert_course(text, jsonb, jsonb, jsonb, text, text, text, boolean) to service_role;

-- L'import depuis GitHub passe par le même chemin.
create or replace function public.catalog_import_course(p_lang text, p_course_id text, p_ref text default 'main')
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_course jsonb;
  v_quiz jsonb;
  v_glossary jsonb;
  v_withheld jsonb;
  v_status text;
  v_cover text;
begin
  if not exists (select 1 from public.catalog_import_state where lang = p_lang) then
    perform public.catalog_import_prepare_language(p_lang, p_ref);
  end if;
  v_course := public.catalog_github_fetch('content/courses/' || p_lang || '/' || p_course_id || '.json', p_ref)::jsonb;
  select value into v_withheld from public.catalog_import_globals where key = 'withheld';
  v_status := case when coalesce(v_withheld->'by_language'->p_lang, '[]'::jsonb) ? p_course_id then 'withheld' else 'published' end;
  select value->>p_course_id into v_cover from public.catalog_import_globals where key = 'cover_map';
  select coalesce(s.quizzes->p_course_id, '[]'::jsonb) into v_quiz from public.catalog_import_state s where s.lang = p_lang;
  select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb) into v_glossary
  from public.catalog_import_state s, jsonb_each(s.glossary) e
  where s.lang = p_lang and e.key like p_course_id || '|%';
  perform public.catalog_upsert_course(p_lang, v_course, v_quiz, v_glossary, v_status, null, v_cover, p_lang = 'fr');
end;
$$;

-- ---------- dispatch vers GitHub Actions ----------

-- Envoie chaque job en file à GitHub (repository_dispatch « produce-course »). Le jeton est
-- dans le Vault sous le nom github_dispatch_token :
--   select vault.create_secret('<token>', 'github_dispatch_token');
create or replace function public.jobs_dispatch(p_limit integer default 5)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, vault
as $$
declare
  v_token text;
  v_job record;
  v_status integer;
  v_content text;
  v_count integer := 0;
begin
  select decrypted_secret into v_token from vault.decrypted_secrets where name = 'github_dispatch_token' order by created_at desc limit 1;
  if v_token is null then
    return jsonb_build_object('dispatched', 0, 'error', 'github_dispatch_token absent du Vault');
  end if;
  for v_job in
    select * from public.production_jobs where status = 'queued' order by created_at limit p_limit
  loop
    select status, content into v_status, v_content from extensions.http((
      'POST',
      'https://api.github.com/repos/adrienmrtn/rork-sophia-755/dispatches',
      array[
        extensions.http_header('Authorization', 'Bearer ' || v_token),
        extensions.http_header('Accept', 'application/vnd.github+json'),
        extensions.http_header('X-GitHub-Api-Version', '2022-11-28'),
        extensions.http_header('User-Agent', 'sophia-supabase')
      ],
      'application/json',
      jsonb_build_object('event_type', 'produce-course',
                         'client_payload', jsonb_build_object('job_id', v_job.id, 'course_id', v_job.course_id))::text
    )::extensions.http_request);
    if v_status = 204 then
      update public.production_jobs set status = 'dispatched', dispatched_at = now(), error = null, updated_at = now() where id = v_job.id;
      v_count := v_count + 1;
    else
      update public.production_jobs set error = 'dispatch GitHub : HTTP ' || v_status || ' ' || left(coalesce(v_content, ''), 200), updated_at = now() where id = v_job.id;
    end if;
  end loop;
  return jsonb_build_object('dispatched', v_count,
                            'queued', (select count(*) from public.production_jobs where status = 'queued'));
end;
$$;
revoke all on function public.jobs_dispatch(integer) from public;
grant execute on function public.jobs_dispatch(integer) to service_role;

select cron.unschedule(jobid) from cron.job where jobname = 'catalog-jobs-dispatch';
select cron.schedule('catalog-jobs-dispatch', '*/5 * * * *', $$select public.jobs_dispatch(5)$$);

-- ---------- état du job et webhook vers le Studio ----------

-- À chaque changement d'étape : l'état global du job est recalculé, et le Studio est prévenu
-- (app_config.studio.webhook_url, secret Vault studio_webhook_secret dans l'en-tête x-api-key).
create or replace function public.production_steps_changed()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, vault
as $$
declare
  v_job public.production_jobs%rowtype;
  v_total integer;
  v_done integer;
  v_failed integer;
  v_active integer;
  v_url text;
  v_secret text;
begin
  select * into v_job from public.production_jobs where id = new.job_id;
  select count(*),
         count(*) filter (where status in ('done', 'skipped')),
         count(*) filter (where status = 'failed'),
         count(*) filter (where status <> 'pending')
  into v_total, v_done, v_failed, v_active
  from public.production_steps where job_id = new.job_id;

  if v_active > 0 then
    update public.production_jobs set
      status = case
        when v_done + v_failed < v_total then 'running'
        when v_failed = 0 then 'done'
        when v_done > 0 then 'partial'
        else 'failed' end,
      started_at = coalesce(started_at, now()),
      finished_at = case when v_done + v_failed = v_total then now() else null end,
      updated_at = now()
    where id = new.job_id;
  end if;

  if tg_op = 'UPDATE' and new.status is distinct from old.status and new.status <> 'pending' then
    select value->>'webhook_url' into v_url from public.app_config where key = 'studio';
    if coalesce(v_url, '') <> '' then
      select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'studio_webhook_secret' order by created_at desc limit 1;
      perform net.http_post(
        url := v_url,
        body := jsonb_build_object(
          'event', 'job-step', 'job_id', new.job_id, 'course_id', v_job.course_id,
          'step', new.step, 'lang', new.lang, 'status', new.status, 'detail', new.detail, 'at', now()),
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-api-key', coalesce(v_secret, '')),
        timeout_milliseconds := 8000);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists production_steps_changed on public.production_steps;
create trigger production_steps_changed
after insert or update on public.production_steps
for each row execute function public.production_steps_changed();

-- Fin de job : un dernier message « job-done ».
create or replace function public.production_jobs_finished()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, vault
as $$
declare
  v_url text;
  v_secret text;
begin
  if new.status in ('done', 'partial', 'failed') and (old.status is distinct from new.status) then
    select value->>'webhook_url' into v_url from public.app_config where key = 'studio';
    if coalesce(v_url, '') <> '' then
      select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'studio_webhook_secret' order by created_at desc limit 1;
      perform net.http_post(
        url := v_url,
        body := jsonb_build_object(
          'event', 'job-done', 'job_id', new.id, 'course_id', new.course_id, 'status', new.status,
          'summary', new.summary, 'error', new.error, 'at', now(),
          'steps', (select coalesce(jsonb_agg(jsonb_build_object('step', s.step, 'lang', s.lang, 'status', s.status) order by s.id), '[]'::jsonb)
                    from public.production_steps s where s.job_id = new.id)),
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-api-key', coalesce(v_secret, '')),
        timeout_milliseconds := 8000);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists production_jobs_finished on public.production_jobs;
create trigger production_jobs_finished
after update on public.production_jobs
for each row execute function public.production_jobs_finished();

insert into public.app_config (key, value)
values ('studio', '{"webhook_url": ""}'::jsonb)
on conflict (key) do nothing;

-- ---------- statistiques pour le Studio ----------

-- Par cours et par langue, sur p_days jours : impressions, ouvertures, terminés, terminés pour
-- 1 000 impressions, j'aime, abonnés gagnés depuis le cours, et la part des ouvertures qui
-- atteint chaque section (décrochage).
create or replace function public.course_stats_export(p_days integer default 90, p_course_id text default null)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with since as (select (current_date - greatest(1, least(coalesce(p_days, 90), 365)))::date as day),
  base as (
    select d.course_id, d.lang,
           sum(d.impressions) as impressions, sum(d.opens) as opens, sum(d.completes) as completes,
           sum(d.likes) as likes, sum(d.saves) as saves, sum(d.shares) as shares, sum(d.readers) as readers
    from public.daily_course_stats d, since
    where d.day >= since.day and (p_course_id is null or d.course_id = p_course_id)
    group by d.course_id, d.lang
  ),
  sections as (
    select e.course_id, e.lang, (e.props->>'section_index')::integer as section_index, count(distinct e.user_id) as viewers
    from public.course_events e, since
    where e.name = 'section_view' and e.ts >= since.day and e.course_id is not null
      and (p_course_id is null or e.course_id = p_course_id)
      and coalesce(e.props->>'section_index', '') ~ '^[0-9]+$'
    group by 1, 2, 3
  ),
  follows as (
    select e.course_id, e.lang,
           sum(case when e.name = 'follow' then 1 when e.name = 'unfollow' then -1 else 0 end) as followers_gained
    from public.course_events e, since
    where e.name in ('follow', 'unfollow') and e.ts >= since.day and e.course_id is not null
      and (p_course_id is null or e.course_id = p_course_id)
    group by 1, 2
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'course_id', b.course_id,
    'lang', b.lang,
    'impressions', b.impressions,
    'opens', b.opens,
    'completes', b.completes,
    'completes_per_1000_impressions', case when b.impressions > 0 then round(b.completes::numeric * 1000 / b.impressions, 1) else null end,
    'likes', b.likes,
    'saves', b.saves,
    'shares', b.shares,
    'readers', b.readers,
    'followers_gained', coalesce(f.followers_gained, 0),
    'sections', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'index', s.section_index, 'viewers', s.viewers,
        'reach', case when b.opens > 0 then round(least(s.viewers, b.opens)::numeric / b.opens, 3) else null end
      ) order by s.section_index), '[]'::jsonb)
      from sections s where s.course_id = b.course_id and s.lang = b.lang
    )
  ) order by b.course_id, b.lang), '[]'::jsonb)
  from base b
  left join follows f on f.course_id = b.course_id and f.lang = b.lang;
$$;

-- Minutes de lecture des abonnés Premium par créateur sur un mois : lectures plausibles
-- seulement (5 s à 10 min par section, 60 min par lecteur et par créateur et par jour), jamais
-- celles du créateur sur ses propres cours (creators.user_id).
create or replace function public.creator_premium_minutes(p_month date default date_trunc('month', current_date)::date)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with span as (
    select date_trunc('month', p_month)::date as start_day, (date_trunc('month', p_month) + interval '1 month')::date as stop_day
  ),
  reads as (
    select c.creator_slug, e.user_id, e.ts::date as day,
           least(greatest((e.props->>'seconds')::numeric, 5), 600) as seconds
    from public.course_events e
    join public.courses c on c.id = e.course_id
    join span on e.ts >= span.start_day and e.ts < span.stop_day
    left join public.creators cr on cr.slug = c.creator_slug
    where e.name = 'section_view'
      and e.premium_status in ('paid', 'trial')
      and c.creator_slug is not null
      and coalesce(e.props->>'seconds', '') ~ '^[0-9]+(\.[0-9]+)?$'
      and (cr.user_id is null or e.user_id is null or cr.user_id <> e.user_id)
  ),
  capped as (
    select creator_slug, user_id, day, least(sum(seconds), 3600) as seconds
    from reads group by 1, 2, 3
  ),
  per_creator as (
    select creator_slug, round(sum(seconds) / 60.0, 1) as minutes, count(distinct user_id) as readers
    from capped group by 1
  ),
  total as (select coalesce(sum(minutes), 0) as minutes from per_creator)
  select jsonb_build_object(
    'month', to_char(date_trunc('month', p_month), 'YYYY-MM'),
    'total_minutes', (select minutes from total),
    'creators', coalesce((
      select jsonb_agg(jsonb_build_object(
        'creator', pc.creator_slug, 'minutes', pc.minutes, 'readers', pc.readers,
        'share', case when t.minutes > 0 then round(pc.minutes / t.minutes, 4) else 0 end
      ) order by pc.minutes desc)
      from per_creator pc, total t
    ), '[]'::jsonb)
  );
$$;

-- Revenu net Premium d'un mois depuis les webhooks RevenueCat : prix en USD × part reversée
-- (takehome_percentage), achats et renouvellements hors sandbox.
create or replace function public.creator_premium_revenue(p_month date default date_trunc('month', current_date)::date)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with span as (
    select date_trunc('month', p_month)::date as start_day, (date_trunc('month', p_month) + interval '1 month')::date as stop_day
  ),
  ev as (
    select e.price, coalesce(e.takehome_percentage, 0.85) as takehome, e.type
    from public.subscription_events e, span
    where e.event_ts >= span.start_day and e.event_ts < span.stop_day
      and coalesce(e.environment, 'PRODUCTION') <> 'SANDBOX'
      and e.type in ('INITIAL_PURCHASE', 'RENEWAL', 'NON_RENEWING_PURCHASE', 'PRODUCT_CHANGE', 'UNCANCELLATION')
      and e.price is not null and e.price > 0
  )
  select jsonb_build_object(
    'month', to_char(date_trunc('month', p_month), 'YYYY-MM'),
    'currency', 'USD',
    'gross', coalesce(round(sum(price), 2), 0),
    'net', coalesce(round(sum(price * takehome), 2), 0),
    'transactions', count(*),
    'by_type', coalesce((select jsonb_object_agg(t.type, t.n) from (select type, count(*) n from ev group by type) t), '{}'::jsonb)
  )
  from ev;
$$;

-- Tout ce que renvoie course-stats-export, en un appel.
create or replace function public.course_stats_bundle(
  p_days integer default 90,
  p_month date default date_trunc('month', current_date)::date,
  p_course_id text default null,
  p_creator text default null
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'generated_at', now(),
    'window_days', greatest(1, least(coalesce(p_days, 90), 365)),
    'courses', (
      select coalesce(jsonb_agg(row_j), '[]'::jsonb)
      from jsonb_array_elements(public.course_stats_export(p_days, p_course_id)) row_j
      where p_creator is null
         or exists (select 1 from public.courses c where c.id = row_j->>'course_id' and c.creator_slug = p_creator)
    ),
    'premium', jsonb_build_object(
      'minutes', public.creator_premium_minutes(p_month),
      'revenue', public.creator_premium_revenue(p_month)
    )
  );
$$;

revoke all on function public.course_stats_export(integer, text) from public;
revoke all on function public.creator_premium_minutes(date) from public;
revoke all on function public.creator_premium_revenue(date) from public;
revoke all on function public.course_stats_bundle(integer, date, text, text) from public;
grant execute on function public.course_stats_export(integer, text) to service_role;
grant execute on function public.creator_premium_minutes(date) to service_role;
grant execute on function public.creator_premium_revenue(date) to service_role;
grant execute on function public.course_stats_bundle(integer, date, text, text) to service_role;
