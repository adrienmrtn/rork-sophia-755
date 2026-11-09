-- Sophia Studio (studio.sophia-culture.com) : l'espace des auteurs de cours, construit directement
-- sur la base de l'app. Un auteur est un utilisateur Supabase ordinaire ; son compte créateur, ses
-- brouillons, son contrat signé, ses jobs et ses chiffres sont des lignes protégées par RLS. La fiche
-- publique reste public.creators : elle n'est créée qu'à la première publication (publish-course),
-- jamais à l'inscription, pour qu'un compte en attente n'apparaisse pas dans les apps.
--
-- Rôles : authenticated = l'auteur connecté (RLS) ; is_studio_admin() = l'équipe Sophia ; le serveur
-- du Studio n'utilise la clé service_role que pour publier (publish-course) et héberger la photo.

-- ------------------------------------------------------------------ 1. l'équipe

create table if not exists public.studio_admins (
  email      text primary key,
  user_id    uuid,
  note       text,
  created_at timestamptz not null default now()
);
comment on table public.studio_admins is 'Qui relit, approuve et publie dans le Studio. Ajoutés à la main (insert), email en minuscules ; user_id est posé à la première connexion (studio_admin_touch).';
alter table public.studio_admins enable row level security;

create or replace function public.is_studio_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.studio_admins a
    where (a.user_id is not null and a.user_id = auth.uid())
       or (coalesce(auth.jwt() ->> 'email', '') <> '' and lower(a.email) = lower(auth.jwt() ->> 'email'))
  );
$$;
revoke all on function public.is_studio_admin() from public;
grant execute on function public.is_studio_admin() to authenticated, service_role;

-- Un appel PostgREST authentifié a un auth.uid() ; une session service_role ou une connexion directe
-- (migrations, MCP) n'en a pas. Les triggers de garde laissent passer ces deux derniers cas.
create or replace function public.studio_is_privileged()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is null or coalesce(auth.jwt() ->> 'role', '') = 'service_role' or public.is_studio_admin();
$$;
revoke all on function public.studio_is_privileged() from public;
grant execute on function public.studio_is_privileged() to authenticated, service_role;

drop policy if exists studio_admins_read on public.studio_admins;
create policy studio_admins_read on public.studio_admins for select to authenticated using (public.is_studio_admin());

-- Lie l'admin connecté à sa ligne (par email) : appelé par le Studio à chaque connexion.
create or replace function public.studio_admin_touch()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.studio_admins
     set user_id = auth.uid()
   where user_id is null
     and coalesce(auth.jwt() ->> 'email', '') <> ''
     and lower(email) = lower(auth.jwt() ->> 'email');
  return public.is_studio_admin();
end;
$$;
revoke all on function public.studio_admin_touch() from public;
grant execute on function public.studio_admin_touch() to authenticated;

-- ------------------------------------------------------------------ 2. le compte créateur (privé)

create table if not exists public.creator_accounts (
  user_id          uuid primary key references auth.users(id) on delete cascade,
  slug             text unique,
  status           text not null default 'pending' check (status in ('pending', 'approved', 'suspended')),
  first_name       text,
  last_name        text,
  display_name     text,
  email            text,
  writing_lang     text not null default 'fr',
  title            text,
  institution      text,
  country          text,
  links            jsonb not null default '{}'::jsonb,
  bio              text,
  long_bio         text,
  education        jsonb not null default '[]'::jsonb,
  photo_path       text,
  onboarding_step  text not null default 'identity' check (onboarding_step in ('identity', 'credentials', 'profile', 'agreement', 'guide', 'done')),
  guide_read_at    timestamptz,
  self_registered  boolean not null default true,
  approved_at      timestamptz,
  approved_by      uuid,
  suspended_reason text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint creator_accounts_slug_check check (slug is null or slug ~ '^[a-z0-9][a-z0-9-]{1,59}$'),
  constraint creator_accounts_lang_check check (writing_lang in ('fr','en','es','de','pt','pt-PT','it','tr','pl','ro','nl','el','sv','hu','bg','cs','da','nb','ru','hr','sl','sk','sr','ar','he','fi','et','lt','lv','ja'))
);
comment on table public.creator_accounts is 'Le compte Studio d''un auteur (privé : nom, email, parcours d''accueil, statut). La fiche publique est public.creators, créée à la première publication avec ce slug. title et bio sont écrits dans writing_lang.';
comment on column public.creator_accounts.slug is 'Réservé à l''inscription, devient creators.slug à la première publication ; ne change plus ensuite.';
comment on column public.creator_accounts.photo_path is 'Objet du bucket privé studio-photos (<user_id>/photo.jpg) ; copié dans course-images/author_<slug>.jpg à l''approbation.';

drop trigger if exists creator_accounts_updated_at on public.creator_accounts;
create trigger creator_accounts_updated_at before update on public.creator_accounts
  for each row execute function public.set_updated_at();

alter table public.creator_accounts enable row level security;
grant select, insert, update on public.creator_accounts to authenticated;
grant all on public.creator_accounts to service_role;

drop policy if exists creator_accounts_select on public.creator_accounts;
create policy creator_accounts_select on public.creator_accounts for select to authenticated
  using (user_id = auth.uid() or public.is_studio_admin());
drop policy if exists creator_accounts_insert on public.creator_accounts;
create policy creator_accounts_insert on public.creator_accounts for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending' and self_registered and approved_at is null and approved_by is null);
drop policy if exists creator_accounts_update on public.creator_accounts;
create policy creator_accounts_update on public.creator_accounts for update to authenticated
  using (user_id = auth.uid() or public.is_studio_admin())
  with check (user_id = auth.uid() or public.is_studio_admin());

-- L'auteur édite son profil ; le statut, l'approbation et le slug publié sont à l'équipe.
create or replace function public.guard_creator_account()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if public.studio_is_privileged() then
    return new;
  end if;
  if new.user_id is distinct from old.user_id
     or new.status is distinct from old.status
     or new.approved_at is distinct from old.approved_at
     or new.approved_by is distinct from old.approved_by
     or new.suspended_reason is distinct from old.suspended_reason
     or new.self_registered is distinct from old.self_registered then
    raise exception 'Ces champs sont réservés à l''équipe Sophia' using errcode = '42501';
  end if;
  if new.slug is distinct from old.slug and exists (select 1 from public.creators c where c.slug = old.slug) then
    raise exception 'Le nom public (slug) ne change plus après la première publication' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists creator_accounts_guard on public.creator_accounts;
create trigger creator_accounts_guard before update on public.creator_accounts
  for each row execute function public.guard_creator_account();

-- Le slug public d'un utilisateur : la fiche publiée s'il y en a une, sinon celui réservé au compte.
create or replace function public.studio_creator_slug(p_user uuid default auth.uid())
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select c.slug from public.creators c where c.user_id = p_user),
    (select a.slug from public.creator_accounts a where a.user_id = p_user)
  );
$$;
revoke all on function public.studio_creator_slug(uuid) from public;
grant execute on function public.studio_creator_slug(uuid) to authenticated, service_role;

-- ------------------------------------------------------------------ 3. documents (contrat, guide) et signatures

create table if not exists public.studio_documents (
  slug         text not null,
  version      integer not null,
  lang         text not null,
  title        text not null,
  body_md      text not null,
  published_at timestamptz not null default now(),
  primary key (slug, version, lang)
);
comment on table public.studio_documents is 'Textes versionnés du Studio : creator-agreement (le contrat créateur, à signer), writing-guide (le guide de rédaction). Une nouvelle version = de nouvelles lignes ; les anciennes restent pour les signatures passées.';
alter table public.studio_documents enable row level security;
grant select on public.studio_documents to authenticated;
grant all on public.studio_documents to service_role;
drop policy if exists studio_documents_read on public.studio_documents;
create policy studio_documents_read on public.studio_documents for select to authenticated using (true);

create table if not exists public.creator_agreements (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  document_slug text not null default 'creator-agreement',
  version       integer not null,
  lang          text not null,
  signed_name   text not null,
  signed_at     timestamptz not null default now(),
  ip            text,
  user_agent    text,
  body_sha256   text,
  unique (user_id, document_slug, version)
);
comment on table public.creator_agreements is 'Une signature électronique du contrat créateur : qui, quelle version, dans quelle langue, quand, depuis où (nom tapé + case cochée, comme un contrat en ligne).';
alter table public.creator_agreements enable row level security;
grant select on public.creator_agreements to authenticated;
grant all on public.creator_agreements to service_role;
drop policy if exists creator_agreements_select on public.creator_agreements;
create policy creator_agreements_select on public.creator_agreements for select to authenticated
  using (user_id = auth.uid() or public.is_studio_admin());

-- La version en vigueur d'un document.
create or replace function public.studio_document_version(p_slug text default 'creator-agreement')
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(max(version), 0) from public.studio_documents where slug = p_slug;
$$;
revoke all on function public.studio_document_version(text) from public;
grant execute on function public.studio_document_version(text) to authenticated, service_role;

-- L'utilisateur a-t-il signé la version en vigueur du contrat ?
create or replace function public.creator_agreement_current(p_user uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.creator_agreements s
    where s.user_id = p_user and s.document_slug = 'creator-agreement'
      and s.version = public.studio_document_version('creator-agreement')
  );
$$;
revoke all on function public.creator_agreement_current(uuid) from public;
grant execute on function public.creator_agreement_current(uuid) to authenticated, service_role;

-- Signer la version en vigueur, dans la langue demandée (repli : fr).
create or replace function public.studio_sign_agreement(p_lang text, p_signed_name text, p_ip text default null, p_user_agent text default null)
returns public.creator_agreements
language plpgsql
security definer
set search_path = public
as $$
declare
  v_version integer := public.studio_document_version('creator-agreement');
  v_lang text;
  v_body text;
  v_row public.creator_agreements;
begin
  if auth.uid() is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  if v_version = 0 then
    raise exception 'Aucun contrat publié';
  end if;
  if length(trim(coalesce(p_signed_name, ''))) < 3 then
    raise exception 'Le nom signé est requis';
  end if;
  select d.lang, d.body_md into v_lang, v_body
  from public.studio_documents d
  where d.slug = 'creator-agreement' and d.version = v_version and d.lang in (p_lang, 'fr')
  order by case when d.lang = p_lang then 0 else 1 end
  limit 1;
  insert into public.creator_agreements (user_id, document_slug, version, lang, signed_name, ip, user_agent, body_sha256)
  values (auth.uid(), 'creator-agreement', v_version, v_lang, trim(p_signed_name), p_ip, p_user_agent, encode(digest(v_body, 'sha256'), 'hex'))
  on conflict (user_id, document_slug, version) do update set signed_at = now(), signed_name = excluded.signed_name
  returning * into v_row;
  update public.creator_accounts
     set onboarding_step = case when onboarding_step = 'agreement' then 'guide' else onboarding_step end
   where user_id = auth.uid();
  return v_row;
end;
$$;
revoke all on function public.studio_sign_agreement(text, text, text, text) from public;
grant execute on function public.studio_sign_agreement(text, text, text, text) to authenticated;

-- ------------------------------------------------------------------ 4. les brouillons

create table if not exists public.studio_drafts (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  app_course_id  text references public.courses(id) on delete set null,
  origin_lang    text not null default 'fr',
  title          text not null default '',
  subtitle       text,
  subject        text,
  subcategory    text,
  description    text not null default '',
  hero           jsonb not null default '{}'::jsonb,
  sections       jsonb not null default '[]'::jsonb,
  sources        jsonb not null default '[]'::jsonb,
  glossary       jsonb not null default '[]'::jsonb,
  quiz           jsonb,
  status         text not null default 'draft' check (status in ('draft', 'submitted', 'changes_requested', 'accepted', 'publishing', 'published', 'failed', 'archived')),
  review_comment text,
  precheck       jsonb,
  submitted_at   timestamptz,
  accepted_at    timestamptz,
  published_at   timestamptz,
  version        integer not null default 1,
  last_job_id    uuid references public.production_jobs(id) on delete set null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint studio_drafts_lang_check check (origin_lang in ('fr','en','es','de','pt','pt-PT','it','tr','pl','ro','nl','el','sv','hu','bg','cs','da','nb','ru','hr','sl','sk','sr','ar','he','fi','et','lt','lv','ja')),
  constraint studio_drafts_subject_check check (subject is null or subject in ('histoire', 'sciences', 'litterature', 'art', 'mythologie', 'comprendreLeMonde'))
);
comment on table public.studio_drafts is 'Un cours écrit dans le Studio, au format V2 (docs/publish-contract.md), dans sa langue d''origine. app_course_id et last_job_id sont posés à la publication ; les traductions et le quiz sont faits par l''usine.';
create index if not exists studio_drafts_user_idx on public.studio_drafts (user_id, updated_at desc);
create index if not exists studio_drafts_status_idx on public.studio_drafts (status, submitted_at desc);

drop trigger if exists studio_drafts_updated_at on public.studio_drafts;
create trigger studio_drafts_updated_at before update on public.studio_drafts
  for each row execute function public.set_updated_at();

alter table public.studio_drafts enable row level security;
grant select, insert, update, delete on public.studio_drafts to authenticated;
grant all on public.studio_drafts to service_role;

drop policy if exists studio_drafts_select on public.studio_drafts;
create policy studio_drafts_select on public.studio_drafts for select to authenticated
  using (user_id = auth.uid() or public.is_studio_admin());
drop policy if exists studio_drafts_insert on public.studio_drafts;
create policy studio_drafts_insert on public.studio_drafts for insert to authenticated
  with check (
    user_id = auth.uid() and status = 'draft' and app_course_id is null and last_job_id is null
    and exists (select 1 from public.creator_accounts a where a.user_id = auth.uid() and a.status <> 'suspended')
  );
drop policy if exists studio_drafts_update on public.studio_drafts;
create policy studio_drafts_update on public.studio_drafts for update to authenticated
  using (public.is_studio_admin() or (user_id = auth.uid() and status in ('draft', 'changes_requested')))
  with check (public.is_studio_admin() or (user_id = auth.uid() and status in ('draft', 'changes_requested')));
drop policy if exists studio_drafts_delete on public.studio_drafts;
create policy studio_drafts_delete on public.studio_drafts for delete to authenticated
  using (public.is_studio_admin() or (user_id = auth.uid() and status = 'draft' and app_course_id is null));

-- L'auteur édite le contenu ; le circuit (statut, relecture, publication) passe par les fonctions.
create or replace function public.guard_studio_draft()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if public.studio_is_privileged() then
    return new;
  end if;
  if new.user_id is distinct from old.user_id
     or new.app_course_id is distinct from old.app_course_id
     or new.status is distinct from old.status
     or new.review_comment is distinct from old.review_comment
     or new.precheck is distinct from old.precheck
     or new.submitted_at is distinct from old.submitted_at
     or new.accepted_at is distinct from old.accepted_at
     or new.published_at is distinct from old.published_at
     or new.version is distinct from old.version
     or new.last_job_id is distinct from old.last_job_id then
    raise exception 'Le circuit de relecture passe par le Studio, pas par une modification directe' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists studio_drafts_guard on public.studio_drafts;
create trigger studio_drafts_guard before update on public.studio_drafts
  for each row execute function public.guard_studio_draft();

-- Le journal du circuit : envois, décisions, publications.
create table if not exists public.studio_reviews (
  id          bigserial primary key,
  draft_id    uuid not null references public.studio_drafts(id) on delete cascade,
  reviewer_id uuid,
  decision    text not null check (decision in ('submitted', 'withdrawn', 'changes_requested', 'accepted', 'rejected', 'reopened', 'published', 'publish_failed', 'note')),
  comment     text,
  created_at  timestamptz not null default now()
);
create index if not exists studio_reviews_draft_idx on public.studio_reviews (draft_id, created_at desc);
alter table public.studio_reviews enable row level security;
grant select on public.studio_reviews to authenticated;
grant all on public.studio_reviews to service_role;
drop policy if exists studio_reviews_select on public.studio_reviews;
create policy studio_reviews_select on public.studio_reviews for select to authenticated
  using (public.is_studio_admin() or exists (select 1 from public.studio_drafts d where d.id = studio_reviews.draft_id and d.user_id = auth.uid()));

-- Envoyer en relecture : le compte est complet et actif, le contrat signé, le cours a un titre et des sections.
create or replace function public.studio_submit_draft(p_id uuid)
returns public.studio_drafts
language plpgsql
security definer
set search_path = public
as $$
declare
  d public.studio_drafts;
  a public.creator_accounts;
begin
  select * into d from public.studio_drafts where id = p_id;
  if d.id is null or d.user_id <> auth.uid() then
    raise exception 'Brouillon introuvable' using errcode = '42501';
  end if;
  if d.status not in ('draft', 'changes_requested') then
    raise exception 'Ce cours n''est pas modifiable (statut %)', d.status;
  end if;
  select * into a from public.creator_accounts where user_id = auth.uid();
  if a.user_id is null or a.slug is null or coalesce(a.display_name, '') = '' then
    raise exception 'Complétez votre profil créateur avant d''envoyer un cours';
  end if;
  if a.status = 'suspended' then
    raise exception 'Compte suspendu : contactez l''équipe Sophia';
  end if;
  if not public.creator_agreement_current(auth.uid()) then
    raise exception 'Le contrat créateur doit être signé avant l''envoi';
  end if;
  if length(trim(d.title)) < 3 or jsonb_typeof(d.sections) <> 'array' or jsonb_array_length(d.sections) < 2 then
    raise exception 'Le cours est incomplet (titre et au moins deux parties)';
  end if;
  update public.studio_drafts
     set status = 'submitted', submitted_at = now(), review_comment = null
   where id = p_id
  returning * into d;
  insert into public.studio_reviews (draft_id, reviewer_id, decision) values (p_id, auth.uid(), 'submitted');
  return d;
end;
$$;
revoke all on function public.studio_submit_draft(uuid) from public;
grant execute on function public.studio_submit_draft(uuid) to authenticated;

-- Retirer un envoi tant qu'il n'est pas relu.
create or replace function public.studio_withdraw_draft(p_id uuid)
returns public.studio_drafts
language plpgsql
security definer
set search_path = public
as $$
declare
  d public.studio_drafts;
begin
  select * into d from public.studio_drafts where id = p_id;
  if d.id is null or d.user_id <> auth.uid() then
    raise exception 'Brouillon introuvable' using errcode = '42501';
  end if;
  if d.status <> 'submitted' then
    raise exception 'Seul un cours envoyé et pas encore relu peut être retiré';
  end if;
  update public.studio_drafts set status = 'draft', submitted_at = null where id = p_id returning * into d;
  insert into public.studio_reviews (draft_id, reviewer_id, decision) values (p_id, auth.uid(), 'withdrawn');
  return d;
end;
$$;
revoke all on function public.studio_withdraw_draft(uuid) from public;
grant execute on function public.studio_withdraw_draft(uuid) to authenticated;

-- La décision de l'équipe : demander des modifications (commentaire requis), accepter, refuser, rouvrir.
create or replace function public.studio_review_draft(p_id uuid, p_decision text, p_comment text default null)
returns public.studio_drafts
language plpgsql
security definer
set search_path = public
as $$
declare
  d public.studio_drafts;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  select * into d from public.studio_drafts where id = p_id;
  if d.id is null then
    raise exception 'Brouillon introuvable';
  end if;
  if p_decision = 'changes_requested' then
    if length(trim(coalesce(p_comment, ''))) < 3 then
      raise exception 'Dites à l''auteur quoi changer (commentaire requis)';
    end if;
    update public.studio_drafts set status = 'changes_requested', review_comment = trim(p_comment) where id = p_id returning * into d;
  elsif p_decision = 'accepted' then
    update public.studio_drafts set status = 'accepted', accepted_at = now(), review_comment = nullif(trim(coalesce(p_comment, '')), '') where id = p_id returning * into d;
  elsif p_decision = 'rejected' then
    update public.studio_drafts set status = 'archived', review_comment = nullif(trim(coalesce(p_comment, '')), '') where id = p_id returning * into d;
  elsif p_decision = 'reopened' then
    update public.studio_drafts set status = 'draft', review_comment = nullif(trim(coalesce(p_comment, '')), '') where id = p_id returning * into d;
  elsif p_decision = 'note' then
    null;
  else
    raise exception 'Décision inconnue : %', p_decision;
  end if;
  insert into public.studio_reviews (draft_id, reviewer_id, decision, comment) values (p_id, auth.uid(), p_decision, nullif(trim(coalesce(p_comment, '')), ''));
  return d;
end;
$$;
revoke all on function public.studio_review_draft(uuid, text, text) from public;
grant execute on function public.studio_review_draft(uuid, text, text) to authenticated;

-- Approuver ou suspendre une personne.
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
  return a;
end;
$$;
revoke all on function public.studio_set_creator_status(uuid, text, text) from public;
grant execute on function public.studio_set_creator_status(uuid, text, text) to authenticated;

-- Quand le job de l'usine se termine, le brouillon suit : publié (done ou partial, la langue
-- d'origine est toujours publiée en premier) ou en échec.
create or replace function public.studio_sync_draft_from_job()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    if new.status in ('done', 'partial') then
      update public.studio_drafts
         set status = 'published', published_at = coalesce(published_at, now())
       where last_job_id = new.id and status in ('publishing', 'accepted', 'failed');
      insert into public.studio_reviews (draft_id, decision, comment)
      select d.id, 'published', 'Job ' || new.id::text || ' : ' || new.status
      from public.studio_drafts d where d.last_job_id = new.id;
    elsif new.status = 'failed' then
      update public.studio_drafts set status = 'failed' where last_job_id = new.id and status = 'publishing';
      insert into public.studio_reviews (draft_id, decision, comment)
      select d.id, 'publish_failed', left(coalesce(new.error, 'échec de l''usine'), 600)
      from public.studio_drafts d where d.last_job_id = new.id;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists production_jobs_studio_sync on public.production_jobs;
create trigger production_jobs_studio_sync after update of status on public.production_jobs
  for each row execute function public.studio_sync_draft_from_job();

-- ------------------------------------------------------------------ 5. ce qu'un auteur voit de la production

grant select on public.production_jobs, public.production_steps to authenticated;

drop policy if exists production_jobs_studio_read on public.production_jobs;
create policy production_jobs_studio_read on public.production_jobs for select to authenticated
  using (
    public.is_studio_admin()
    or exists (select 1 from public.studio_drafts d where d.last_job_id = production_jobs.id and d.user_id = auth.uid())
    or exists (select 1 from public.courses c join public.creators cr on cr.slug = c.creator_slug
               where c.id = production_jobs.course_id and cr.user_id = auth.uid())
  );
-- Les étapes suivent la visibilité du job (la sous-requête est elle-même soumise à la politique ci-dessus).
drop policy if exists production_steps_studio_read on public.production_steps;
create policy production_steps_studio_read on public.production_steps for select to authenticated
  using (exists (select 1 from public.production_jobs j where j.id = production_steps.job_id));

-- Un auteur voit ses cours même en production ; l'équipe voit tout, y compris les contenus retenus.
drop policy if exists courses_studio_read on public.courses;
create policy courses_studio_read on public.courses for select to authenticated
  using (public.is_studio_admin() or exists (select 1 from public.creators cr where cr.slug = courses.creator_slug and cr.user_id = auth.uid()));
drop policy if exists course_contents_studio_read on public.course_contents;
create policy course_contents_studio_read on public.course_contents for select to authenticated
  using (public.is_studio_admin() or exists (select 1 from public.courses c join public.creators cr on cr.slug = c.creator_slug
                                             where c.id = course_contents.course_id and cr.user_id = auth.uid()));
drop policy if exists quizzes_studio_read on public.quizzes;
create policy quizzes_studio_read on public.quizzes for select to authenticated using (public.is_studio_admin());
drop policy if exists glossary_entries_studio_read on public.glossary_entries;
create policy glossary_entries_studio_read on public.glossary_entries for select to authenticated using (public.is_studio_admin());

-- ------------------------------------------------------------------ 6. les chiffres

-- La part de la cagnotte créateurs : payout_share du revenu net Premium du mois, répartie au temps de
-- lecture des abonnés (creator_premium_minutes).
update public.app_config
   set value = coalesce(value, '{}'::jsonb) || jsonb_build_object('payout_share', coalesce((value ->> 'payout_share')::numeric, 0.30))
 where key = 'studio';
insert into public.app_config (key, value)
select 'studio', '{"webhook_url": "", "payout_share": 0.30}'::jsonb
where not exists (select 1 from public.app_config where key = 'studio');

-- Le tableau de bord d'un auteur : ses lectures, ses cours, ses langues, sa part Premium.
create or replace function public.creator_dashboard(p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_slug text := public.studio_creator_slug(auth.uid());
  v_days integer := greatest(1, least(coalesce(p_days, 28), 365));
  v_since date := current_date - v_days;
  v_prev date := current_date - 2 * v_days;
  v_pool numeric := coalesce((select (value ->> 'payout_share')::numeric from public.app_config where key = 'studio'), 0.30);
  v_month date := date_trunc('month', current_date)::date;
  v_payouts jsonb := '[]'::jsonb;
  v_minutes jsonb;
  v_revenue jsonb;
  v_mine jsonb;
  v_net numeric;
  v_m date;
  result jsonb;
begin
  if v_slug is null then
    return jsonb_build_object('slug', null, 'days', v_days, 'courses', '[]'::jsonb, 'series', '[]'::jsonb, 'payouts', '[]'::jsonb);
  end if;

  -- Trois mois de cagnotte : le mois en cours (estimation) et les deux précédents.
  for i in 0..2 loop
    v_m := (v_month - (i || ' months')::interval)::date;
    v_minutes := public.creator_premium_minutes(v_m);
    v_revenue := public.creator_premium_revenue(v_m);
    v_net := coalesce((v_revenue ->> 'net')::numeric, 0);
    select c into v_mine from jsonb_array_elements(v_minutes -> 'creators') c where c ->> 'creator' = v_slug;
    v_payouts := v_payouts || jsonb_build_object(
      'month', to_char(v_m, 'YYYY-MM'),
      'current', i = 0,
      'minutes', coalesce((v_mine ->> 'minutes')::numeric, 0),
      'readers', coalesce((v_mine ->> 'readers')::integer, 0),
      'share', coalesce((v_mine ->> 'share')::numeric, 0),
      'pool_net', v_net,
      'pool_share', v_pool,
      'currency', coalesce(v_revenue ->> 'currency', 'USD'),
      'amount', round(v_net * v_pool * coalesce((v_mine ->> 'share')::numeric, 0), 2)
    );
  end loop;

  with mine as (
    select c.id, c.subject, c.status, c.published_at, c.origin_lang
    from public.courses c where c.creator_slug = v_slug
  ),
  cur as (
    select d.course_id, sum(d.impressions) impressions, sum(d.opens) opens, sum(d.completes) completes,
           sum(d.likes) likes, sum(d.readers) readers, sum(d.quiz_answers) quiz_answers, sum(d.quiz_correct) quiz_correct
    from public.daily_course_stats d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1
  ),
  prev as (
    select sum(d.opens) opens from public.daily_course_stats d join mine m on m.id = d.course_id
    where d.day >= v_prev and d.day < v_since
  ),
  langs as (
    select d.course_id, d.lang, sum(d.opens) opens
    from public.daily_course_stats d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1, 2
  ),
  series as (
    select d.day, sum(d.opens) opens from public.daily_course_stats d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1
  ),
  follows as (
    select coalesce(sum(case when e.name = 'follow' then 1 when e.name = 'unfollow' then -1 else 0 end), 0) n
    from public.course_events e
    where e.name in ('follow', 'unfollow') and e.ts >= v_since and e.props ->> 'creator' = v_slug
  ),
  subj as (
    select c.subject, case when sum(d.impressions) > 0 then round(sum(d.completes)::numeric * 1000 / sum(d.impressions), 1) end as per1000
    from public.daily_course_stats d join public.courses c on c.id = d.course_id
    where d.day >= v_since group by 1
  )
  select jsonb_build_object(
    'slug', v_slug,
    'days', v_days,
    'reads', coalesce((select sum(opens) from cur), 0),
    'reads_prev', coalesce((select opens from prev), 0),
    'impressions', coalesce((select sum(impressions) from cur), 0),
    'completes', coalesce((select sum(completes) from cur), 0),
    'likes', coalesce((select sum(likes) from cur), 0),
    'per_1000', (select case when sum(impressions) > 0 then round(sum(completes)::numeric * 1000 / sum(impressions), 1) end from cur),
    'subject_per_1000', coalesce((select jsonb_object_agg(subject, per1000) from subj where per1000 is not null), '{}'::jsonb),
    'followers_gained', (select n from follows),
    'languages_read', (select count(distinct lang) from langs where opens > 0),
    'series', (select coalesce(jsonb_agg(jsonb_build_object('day', day, 'reads', opens) order by day), '[]'::jsonb) from series),
    'courses', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', m.id,
        'subject', m.subject,
        'status', m.status,
        'published_at', m.published_at,
        'title', (select cc.title from public.course_contents cc where cc.course_id = m.id and cc.lang = m.origin_lang),
        'impressions', coalesce(cur.impressions, 0),
        'reads', coalesce(cur.opens, 0),
        'completes', coalesce(cur.completes, 0),
        'likes', coalesce(cur.likes, 0),
        'readers', coalesce(cur.readers, 0),
        'per_1000', case when coalesce(cur.impressions, 0) > 0 then round(cur.completes::numeric * 1000 / cur.impressions, 1) end,
        'completion', case when coalesce(cur.opens, 0) > 0 then round(cur.completes::numeric / cur.opens, 3) end,
        'quiz_score', case when coalesce(cur.quiz_answers, 0) > 0 then round(cur.quiz_correct::numeric / cur.quiz_answers, 3) end,
        'languages', (select coalesce(jsonb_agg(jsonb_build_object('lang', l.lang, 'reads', l.opens) order by l.opens desc), '[]'::jsonb) from langs l where l.course_id = m.id),
        'published_langs', (select count(*) from public.course_contents cc where cc.course_id = m.id and cc.status = 'published')
      ) order by m.published_at desc nulls last, m.id), '[]'::jsonb)
      from mine m left join cur on cur.course_id = m.id
    ),
    'payouts', v_payouts
  ) into result;
  return result;
end;
$$;
revoke all on function public.creator_dashboard(integer) from public;
grant execute on function public.creator_dashboard(integer) to authenticated;

-- Le détail d'un cours pour son auteur (ou l'équipe) : où les lecteurs décrochent, les langues, le quiz.
create or replace function public.creator_course_detail(p_course_id text, p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_slug text := public.studio_creator_slug(auth.uid());
  v_days integer := greatest(1, least(coalesce(p_days, 28), 365));
  v_since date := current_date - v_days;
begin
  if not public.is_studio_admin()
     and not exists (select 1 from public.courses c where c.id = p_course_id and c.creator_slug = v_slug) then
    raise exception 'Cours introuvable' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'course_id', p_course_id,
    'days', v_days,
    'stats', public.course_stats_export(v_days, p_course_id),
    'languages', (
      select coalesce(jsonb_agg(jsonb_build_object('lang', t.lang, 'reads', t.opens, 'completes', t.completes) order by t.opens desc), '[]'::jsonb)
      from (select d.lang, sum(d.opens) opens, sum(d.completes) completes from public.daily_course_stats d
            where d.course_id = p_course_id and d.day >= v_since group by 1) t
    ),
    'quiz', (
      select jsonb_build_object('answers', coalesce(sum(d.quiz_answers), 0), 'correct', coalesce(sum(d.quiz_correct), 0))
      from public.daily_course_stats d where d.course_id = p_course_id and d.day >= v_since
    ),
    'sections', (
      select cc.section_ids from public.course_contents cc join public.courses c on c.id = cc.course_id
      where cc.course_id = p_course_id and cc.lang = c.origin_lang
    )
  );
end;
$$;
revoke all on function public.creator_course_detail(text, integer) from public;
grant execute on function public.creator_course_detail(text, integer) to authenticated;

-- La vue d'ensemble de l'équipe : relecture, créateurs, production, lectures, cagnotte.
create or replace function public.studio_admin_overview(p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer := greatest(1, least(coalesce(p_days, 28), 365));
  v_since date := current_date - v_days;
  v_month date := date_trunc('month', current_date)::date;
  v_pool numeric := coalesce((select (value ->> 'payout_share')::numeric from public.app_config where key = 'studio'), 0.30);
  v_minutes jsonb;
  v_revenue jsonb;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  v_minutes := public.creator_premium_minutes(v_month);
  v_revenue := public.creator_premium_revenue(v_month);
  return jsonb_build_object(
    'days', v_days,
    'review_queue', (select count(*) from public.studio_drafts where status = 'submitted'),
    'drafts_by_status', coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from public.studio_drafts group by 1) t), '{}'::jsonb),
    'creators_pending', (select count(*) from public.creator_accounts where status = 'pending'),
    'creators_approved', (select count(*) from public.creator_accounts where status = 'approved'),
    'creators_published', (select count(*) from public.creators),
    'agreements_missing', (select count(*) from public.creator_accounts a where a.status <> 'suspended' and not public.creator_agreement_current(a.user_id)),
    'jobs', coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from public.production_jobs group by 1) t), '{}'::jsonb),
    'courses_published', (select count(*) from public.courses where status = 'published'),
    'courses_in_production', (select count(*) from public.courses where status = 'in_production'),
    'reads', coalesce((select sum(opens) from public.daily_course_stats where day >= v_since), 0),
    'completes', coalesce((select sum(completes) from public.daily_course_stats where day >= v_since), 0),
    'readers', coalesce((select sum(readers) from public.daily_course_stats where day >= v_since), 0),
    'series', (select coalesce(jsonb_agg(jsonb_build_object('day', day, 'completes', c, 'reads', o) order by day), '[]'::jsonb)
               from (select day, sum(completes) c, sum(opens) o from public.daily_course_stats where day >= v_since group by 1) t),
    'by_language', (select coalesce(jsonb_agg(jsonb_build_object('lang', lang, 'reads', o) order by o desc), '[]'::jsonb)
                    from (select lang, sum(opens) o from public.daily_course_stats where day >= v_since group by 1) t),
    'by_subject', (select coalesce(jsonb_agg(jsonb_build_object('subject', subject, 'reads', o, 'completes', c, 'courses', n) order by o desc), '[]'::jsonb)
                   from (select c.subject, sum(d.opens) o, sum(d.completes) c, count(distinct d.course_id) n
                         from public.daily_course_stats d join public.courses c on c.id = d.course_id where d.day >= v_since group by 1) t),
    'premium', jsonb_build_object('month', v_revenue ->> 'month', 'currency', v_revenue ->> 'currency', 'gross', v_revenue ->> 'gross', 'net', v_revenue ->> 'net',
                                  'transactions', v_revenue ->> 'transactions', 'pool_share', v_pool,
                                  'pool', round(coalesce((v_revenue ->> 'net')::numeric, 0) * v_pool, 2),
                                  'total_minutes', v_minutes ->> 'total_minutes', 'creators', v_minutes -> 'creators')
  );
end;
$$;
revoke all on function public.studio_admin_overview(integer) from public;
grant execute on function public.studio_admin_overview(integer) to authenticated;

-- ------------------------------------------------------------------ 7. les photos des auteurs (bucket privé)

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('studio-photos', 'studio-photos', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists studio_photos_own on storage.objects;
create policy studio_photos_own on storage.objects for all to authenticated
  using (bucket_id = 'studio-photos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'studio-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists studio_photos_admin_read on storage.objects;
create policy studio_photos_admin_read on storage.objects for select to authenticated
  using (bucket_id = 'studio-photos' and public.is_studio_admin());
