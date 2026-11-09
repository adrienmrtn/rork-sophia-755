-- Rémunération des auteurs : 15 $ par cours validé, versés le lundi ; proposition avant rédaction ;
-- quotas hebdomadaires (10 novembre).
--
-- Décisions d'Adrien :
-- - Deux étapes. L'auteur propose un cours (titre + pitch) ; l'équipe accepte, renvoie avec un mot
--   ou un contre-titre, ou supprime. Une fois acceptée, la proposition devient un brouillon que
--   l'auteur rédige et envoie en relecture. « Accepter et lancer la production » est la validation
--   finale : elle crédite 15 $ (course_fee_cents) à la cagnotte de l'auteur et consomme son quota.
-- - Quota : trois cours validés dans les sept jours suivant l'approbation du compte, puis un par
--   semaine calendaire (lundi-dimanche, Europe/Paris), sans report. L'équipe peut fixer une limite
--   hebdomadaire par auteur (creator_accounts.weekly_quota ; 0 = bloqué). Un auteur ne peut avoir
--   en cours (proposé, en rédaction, en relecture) plus de cours que sa limite.
-- - Cagnotte : grand livre creator_credits ; versements creator_payouts posés par l'équipe le lundi
--   (« Virement fait »), à la main, en dollars, sans coordonnées collectées. Pas de rétroactif.
-- - L'ancienne part des revenus Premium disparaît des tableaux de bord ; les statistiques de
--   lecture restent.

-- ---------- 0. réglages ----------

update public.app_config
   set value = (value - 'payout_share') || jsonb_build_object('course_fee_cents', 1500, 'first_week_quota', 3, 'default_weekly_quota', 1)
 where key = 'studio';

-- ---------- 1. comptes : limite hebdomadaire ----------

alter table public.creator_accounts
  add column if not exists weekly_quota integer check (weekly_quota is null or weekly_quota between 0 and 50);
comment on column public.creator_accounts.weekly_quota is 'Limite de cours validés par semaine fixée par l''équipe. Null : la règle commune (first_week_quota la première semaine, puis default_weekly_quota). 0 : l''auteur ne peut plus proposer ni être validé.';

-- ---------- 2. brouillons : proposition, validation ----------

alter table public.studio_drafts drop constraint if exists studio_drafts_status_check;
alter table public.studio_drafts
  add constraint studio_drafts_status_check check (status in ('proposed', 'proposal_returned', 'draft', 'submitted', 'changes_requested', 'accepted', 'publishing', 'published', 'failed', 'archived'));
alter table public.studio_drafts
  add column if not exists pitch text not null default '',
  add column if not exists proposal_note text,
  add column if not exists proposed_at timestamptz,
  add column if not exists proposal_decided_at timestamptz,
  add column if not exists validated_at timestamptz;
comment on column public.studio_drafts.pitch is 'La proposition de l''auteur : quelques lignes sur le cours, avec le titre.';
comment on column public.studio_drafts.proposal_note is 'Le mot de l''équipe sur la proposition (contre-titre, précision), quand elle est renvoyée ou acceptée avec une remarque.';
comment on column public.studio_drafts.validated_at is 'La validation finale (« Accepter et lancer la production ») : 15 $ crédités, quota consommé. Jamais deux fois pour un même cours.';
create index if not exists studio_drafts_validated_idx on public.studio_drafts (user_id, validated_at) where validated_at is not null;

alter table public.studio_reviews drop constraint if exists studio_reviews_decision_check;
alter table public.studio_reviews
  add constraint studio_reviews_decision_check check (decision in ('proposed', 'proposal_accepted', 'proposal_returned', 'submitted', 'withdrawn', 'changes_requested', 'accepted', 'validated', 'rejected', 'reopened', 'published', 'publish_failed', 'note'));

-- Plus de création directe de brouillon : tout cours commence par studio_propose().
drop policy if exists studio_drafts_insert on public.studio_drafts;
drop policy if exists studio_drafts_delete on public.studio_drafts;
create policy studio_drafts_delete on public.studio_drafts for delete to authenticated
  using (public.is_studio_admin() or (user_id = auth.uid() and status in ('draft', 'proposed', 'proposal_returned') and app_course_id is null));

-- La garde : le circuit (statut, dates, notes) passe par les fonctions ci-dessous, qui posent un
-- drapeau de transaction ; un auteur qui n'est pas de l'équipe ne peut pas changer ces colonnes
-- directement. (Avant, seuls les administrateurs passaient : un auteur ordinaire ne pouvait pas
-- envoyer son cours.)
create or replace function public.guard_studio_draft()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if public.studio_is_privileged() or current_setting('studio.circuit', true) = 'on' then
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
     or new.last_job_id is distinct from old.last_job_id
     or new.pitch is distinct from old.pitch
     or new.proposal_note is distinct from old.proposal_note
     or new.proposed_at is distinct from old.proposed_at
     or new.proposal_decided_at is distinct from old.proposal_decided_at
     or new.validated_at is distinct from old.validated_at then
    raise exception 'Le circuit de relecture passe par le Studio, pas par une modification directe' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- ---------- 3. grand livre : crédits et versements ----------

create table if not exists public.creator_payouts (
  id            bigserial primary key,
  user_id       uuid not null,
  amount_cents  integer not null check (amount_cents > 0),
  currency      text not null default 'USD',
  credits_count integer not null,
  paid_at       timestamptz not null default now(),
  paid_by       uuid,
  note          text
);
comment on table public.creator_payouts is 'Un versement fait à un auteur (le lundi, à la main) : solde la cagnotte des crédits qu''il regroupe.';
create index if not exists creator_payouts_user_idx on public.creator_payouts (user_id, paid_at desc);
alter table public.creator_payouts enable row level security;
grant select on public.creator_payouts to authenticated;
grant all on public.creator_payouts to service_role;
drop policy if exists creator_payouts_select on public.creator_payouts;
create policy creator_payouts_select on public.creator_payouts for select to authenticated
  using (user_id = auth.uid() or public.is_studio_admin());

create table if not exists public.creator_credits (
  id            bigserial primary key,
  user_id       uuid not null,
  draft_id      uuid unique references public.studio_drafts(id) on delete set null,
  course_title  text not null default '',
  amount_cents  integer not null check (amount_cents > 0),
  currency      text not null default 'USD',
  created_at    timestamptz not null default now(),
  payout_id     bigint references public.creator_payouts(id) on delete set null
);
comment on table public.creator_credits is 'Un crédit par cours validé (15 $). payout_id null : dans la cagnotte, à verser le lundi.';
create index if not exists creator_credits_user_idx on public.creator_credits (user_id, payout_id, created_at);
alter table public.creator_credits enable row level security;
grant select on public.creator_credits to authenticated;
grant all on public.creator_credits to service_role;
drop policy if exists creator_credits_select on public.creator_credits;
create policy creator_credits_select on public.creator_credits for select to authenticated
  using (user_id = auth.uid() or public.is_studio_admin());

-- ---------- 4. le quota ----------

-- L'état du quota d'un auteur : sa limite, ce qu'il a validé dans la période, ce qu'il a en cours.
create or replace function public.studio_quota(p_user uuid default auth.uid(), p_at timestamptz default now())
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  a public.creator_accounts;
  v_cfg jsonb := coalesce((select value from public.app_config where key = 'studio'), '{}'::jsonb);
  v_first integer := coalesce((v_cfg ->> 'first_week_quota')::integer, 3);
  v_default integer := coalesce((v_cfg ->> 'default_weekly_quota')::integer, 1);
  v_fee integer := coalesce((v_cfg ->> 'course_fee_cents')::integer, 1500);
  v_tz text := 'Europe/Paris';
  v_first_end timestamptz;
  v_first_week boolean;
  v_period_start timestamptz;
  v_period_end timestamptz;
  v_count_from timestamptz;
  v_limit integer;
  v_used integer;
  v_open integer;
begin
  if p_user is null then
    return null;
  end if;
  if p_user <> auth.uid() and not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  select * into a from public.creator_accounts where user_id = p_user;
  if a.user_id is null then
    return null;
  end if;
  if a.approved_at is null then
    -- Compte pas encore approuvé : il peut préparer jusqu'à la limite de première semaine, rien n'est validé.
    v_first_week := true;
    v_period_start := a.created_at;
    v_period_end := null;
    v_count_from := a.created_at;
    v_limit := coalesce(a.weekly_quota, v_first);
  else
    v_first_end := a.approved_at + interval '7 days';
    v_first_week := p_at < v_first_end;
    if v_first_week then
      v_period_start := a.approved_at;
      v_period_end := v_first_end;
      v_count_from := a.approved_at;
      v_limit := coalesce(a.weekly_quota, v_first);
    else
      v_period_start := (date_trunc('week', p_at at time zone v_tz)) at time zone v_tz;
      v_period_end := v_period_start + interval '7 days';
      v_count_from := greatest(v_period_start, v_first_end);
      v_limit := coalesce(a.weekly_quota, v_default);
    end if;
  end if;
  select count(*) into v_used from public.studio_drafts d
   where d.user_id = p_user and d.validated_at is not null and d.validated_at >= v_count_from
     and (v_period_end is null or d.validated_at < v_period_end);
  select count(*) into v_open from public.studio_drafts d
   where d.user_id = p_user and d.status in ('proposed', 'proposal_returned', 'draft', 'submitted', 'changes_requested');
  return jsonb_build_object(
    'limit', v_limit,
    'used', v_used,
    'open', v_open,
    'can_propose', v_limit > 0 and a.status <> 'suspended' and v_open < v_limit,
    'can_validate', v_limit > 0 and a.status = 'approved' and v_used < v_limit,
    'first_week', v_first_week,
    'period_start', v_period_start,
    'period_end', v_period_end,
    'next_slot_at', case when v_limit > 0 and v_used < v_limit then p_at else v_period_end end,
    'blocked', v_limit = 0,
    'custom', a.weekly_quota is not null,
    'fee_cents', v_fee,
    'currency', 'USD'
  );
end;
$$;
revoke all on function public.studio_quota(uuid, timestamptz) from public;
grant execute on function public.studio_quota(uuid, timestamptz) to authenticated, service_role;

-- L'équipe fixe la limite hebdomadaire d'un auteur (null : la règle commune ; 0 : bloqué).
create or replace function public.studio_set_creator_quota(p_user uuid, p_quota integer)
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
  if p_quota is not null and (p_quota < 0 or p_quota > 50) then
    raise exception 'La limite va de 0 à 50 cours par semaine';
  end if;
  perform set_config('studio.circuit', 'on', true);
  update public.creator_accounts set weekly_quota = p_quota where user_id = p_user returning * into a;
  if a.user_id is null then
    raise exception 'Compte introuvable';
  end if;
  return a;
end;
$$;
revoke all on function public.studio_set_creator_quota(uuid, integer) from public;
grant execute on function public.studio_set_creator_quota(uuid, integer) to authenticated;

-- ---------- 5. la proposition ----------

-- L'auteur propose un cours : un titre et un pitch. Dans la limite de ce qu'il peut avoir en cours.
create or replace function public.studio_propose(p_title text, p_pitch text)
returns public.studio_drafts
language plpgsql
security definer
set search_path = public
as $$
declare
  a public.creator_accounts;
  q jsonb;
  d public.studio_drafts;
begin
  select * into a from public.creator_accounts where user_id = auth.uid();
  if a.user_id is null then
    raise exception 'Create your author account first' using errcode = '42501';
  end if;
  if a.status = 'suspended' then
    raise exception 'Your account is suspended. Contact the team.';
  end if;
  if length(trim(coalesce(p_title, ''))) < 8 then
    raise exception 'Give the course a title (8 characters at least).';
  end if;
  if length(trim(coalesce(p_pitch, ''))) < 40 then
    raise exception 'Describe the course in a few lines (40 characters at least).';
  end if;
  q := public.studio_quota(auth.uid());
  if not coalesce((q ->> 'can_propose')::boolean, false) then
    if (q ->> 'limit')::integer = 0 then
      raise exception 'Your account cannot propose courses at the moment. Contact the team.';
    end if;
    raise exception 'You already have % in progress, which is your current limit. Finish % first.',
      case when (q ->> 'open')::integer = 1 then 'one course' else (q ->> 'open') || ' courses' end,
      case when (q ->> 'open')::integer = 1 then 'it' else 'them' end;
  end if;
  perform set_config('studio.circuit', 'on', true);
  insert into public.studio_drafts (user_id, origin_lang, title, pitch, status, proposed_at, description, hero, sections, sources, glossary)
  values (
    auth.uid(), a.writing_lang, left(trim(p_title), 160), left(trim(p_pitch), 600), 'proposed', now(), '',
    '{"ratio": "16:9"}'::jsonb,
    '[{"title": "Introduction", "free": true, "blocks": [{"type": "paragraph", "text": ""}]}, {"title": "", "free": false, "blocks": [{"type": "paragraph", "text": ""}]}]'::jsonb,
    '[]'::jsonb, '[]'::jsonb)
  returning * into d;
  insert into public.studio_reviews (draft_id, reviewer_id, decision, comment) values (d.id, auth.uid(), 'proposed', d.pitch);
  return d;
end;
$$;
revoke all on function public.studio_propose(text, text) from public;
grant execute on function public.studio_propose(text, text) to authenticated;

-- L'auteur reprend sa proposition (renvoyée ou pas encore lue) et la renvoie.
create or replace function public.studio_update_proposal(p_id uuid, p_title text, p_pitch text)
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
    raise exception 'Proposal not found' using errcode = '42501';
  end if;
  if d.status not in ('proposed', 'proposal_returned') then
    raise exception 'This course is no longer a proposal (status %)', d.status;
  end if;
  if length(trim(coalesce(p_title, ''))) < 8 then
    raise exception 'Give the course a title (8 characters at least).';
  end if;
  if length(trim(coalesce(p_pitch, ''))) < 40 then
    raise exception 'Describe the course in a few lines (40 characters at least).';
  end if;
  perform set_config('studio.circuit', 'on', true);
  update public.studio_drafts
     set title = left(trim(p_title), 160), pitch = left(trim(p_pitch), 600), status = 'proposed', proposed_at = now()
   where id = p_id
  returning * into d;
  insert into public.studio_reviews (draft_id, reviewer_id, decision, comment) values (p_id, auth.uid(), 'proposed', d.pitch);
  return d;
end;
$$;
revoke all on function public.studio_update_proposal(uuid, text, text) from public;
grant execute on function public.studio_update_proposal(uuid, text, text) to authenticated;

-- La décision de l'équipe sur une proposition : accepter (le cours passe en rédaction), renvoyer
-- avec un mot ou un contre-titre (requis), supprimer.
create or replace function public.studio_decide_proposal(p_id uuid, p_decision text, p_note text default null)
returns public.studio_drafts
language plpgsql
security definer
set search_path = public
as $$
declare
  d public.studio_drafts;
  v_note text := nullif(trim(coalesce(p_note, '')), '');
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  select * into d from public.studio_drafts where id = p_id;
  if d.id is null then
    raise exception 'Proposal not found';
  end if;
  if d.status not in ('proposed', 'proposal_returned') then
    raise exception 'This course is no longer a proposal (status %)', d.status;
  end if;
  perform set_config('studio.circuit', 'on', true);
  if p_decision = 'accepted' then
    update public.studio_drafts set status = 'draft', proposal_decided_at = now(), proposal_note = v_note where id = p_id returning * into d;
    insert into public.studio_reviews (draft_id, reviewer_id, decision, comment) values (p_id, auth.uid(), 'proposal_accepted', v_note);
  elsif p_decision = 'returned' then
    if v_note is null or length(v_note) < 3 then
      raise exception 'Tell the author what to change, or suggest another title (note required).';
    end if;
    update public.studio_drafts set status = 'proposal_returned', proposal_decided_at = now(), proposal_note = v_note where id = p_id returning * into d;
    insert into public.studio_reviews (draft_id, reviewer_id, decision, comment) values (p_id, auth.uid(), 'proposal_returned', v_note);
  elsif p_decision = 'deleted' then
    delete from public.studio_drafts where id = p_id returning * into d;
  else
    raise exception 'Unknown decision: %', p_decision;
  end if;
  return d;
end;
$$;
revoke all on function public.studio_decide_proposal(uuid, text, text) from public;
grant execute on function public.studio_decide_proposal(uuid, text, text) to authenticated;

-- ---------- 6. le circuit existant, avec le drapeau et la validation payée ----------

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
  perform set_config('studio.circuit', 'on', true);
  update public.studio_drafts
     set status = 'submitted', submitted_at = now(), review_comment = null
   where id = p_id
  returning * into d;
  insert into public.studio_reviews (draft_id, reviewer_id, decision) values (p_id, auth.uid(), 'submitted');
  return d;
end;
$$;

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
  perform set_config('studio.circuit', 'on', true);
  update public.studio_drafts set status = 'draft', submitted_at = null where id = p_id returning * into d;
  insert into public.studio_reviews (draft_id, reviewer_id, decision) values (p_id, auth.uid(), 'withdrawn');
  return d;
end;
$$;

-- La décision de l'équipe sur un cours envoyé. « accepted » est la validation finale : le compte
-- doit être approuvé, le quota de la période le permettre ; 15 $ sont crédités une seule fois.
create or replace function public.studio_review_draft(p_id uuid, p_decision text, p_comment text default null)
returns public.studio_drafts
language plpgsql
security definer
set search_path = public
as $$
declare
  d public.studio_drafts;
  a public.creator_accounts;
  q jsonb;
  v_fee integer := coalesce((select (value ->> 'course_fee_cents')::integer from public.app_config where key = 'studio'), 1500);
  v_comment text := nullif(trim(coalesce(p_comment, '')), '');
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  select * into d from public.studio_drafts where id = p_id;
  if d.id is null then
    raise exception 'Brouillon introuvable';
  end if;
  perform set_config('studio.circuit', 'on', true);
  if p_decision = 'changes_requested' then
    if v_comment is null or length(v_comment) < 3 then
      raise exception 'Dites à l''auteur quoi changer (commentaire requis)';
    end if;
    update public.studio_drafts set status = 'changes_requested', review_comment = v_comment where id = p_id returning * into d;
  elsif p_decision = 'accepted' then
    select * into a from public.creator_accounts where user_id = d.user_id;
    if a.status is distinct from 'approved' then
      raise exception 'Approve the author''s account before validating a course.';
    end if;
    if d.validated_at is null then
      q := public.studio_quota(d.user_id);
      if not coalesce((q ->> 'can_validate')::boolean, false) then
        if (q ->> 'limit')::integer = 0 then
          raise exception 'This author''s weekly limit is 0: raise it on the Creators page before validating.';
        end if;
        raise exception 'Weekly limit reached for this author (%/% validated). Next validation possible from %.',
          q ->> 'used', q ->> 'limit', to_char(((q ->> 'period_end')::timestamptz) at time zone 'Europe/Paris', 'FMDay DD Mon');
      end if;
    end if;
    update public.studio_drafts
       set status = 'accepted', accepted_at = now(), validated_at = coalesce(validated_at, now()), review_comment = v_comment
     where id = p_id
    returning * into d;
    if not exists (select 1 from public.creator_credits c where c.draft_id = p_id) then
      insert into public.creator_credits (user_id, draft_id, course_title, amount_cents, currency) values (d.user_id, p_id, d.title, v_fee, 'USD');
      insert into public.studio_reviews (draft_id, reviewer_id, decision, comment)
      values (p_id, auth.uid(), 'validated', format('$%s credited to the author''s pot, paid on Monday.', to_char(v_fee / 100.0, 'FM999990.00')));
    end if;
  elsif p_decision = 'rejected' then
    update public.studio_drafts set status = 'archived', review_comment = v_comment where id = p_id returning * into d;
  elsif p_decision = 'reopened' then
    update public.studio_drafts set status = 'draft', review_comment = v_comment where id = p_id returning * into d;
  elsif p_decision = 'note' then
    null;
  else
    raise exception 'Décision inconnue : %', p_decision;
  end if;
  insert into public.studio_reviews (draft_id, reviewer_id, decision, comment) values (p_id, auth.uid(), p_decision, v_comment);
  return d;
end;
$$;

-- ---------- 7. les versements du lundi ----------

-- Ce qui est dû, auteur par auteur, et l'historique des versements.
create or replace function public.studio_payouts_due()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'due_cents', coalesce((select sum(amount_cents) from public.creator_credits where payout_id is null), 0),
    'creators', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', t.user_id,
        'name', coalesce(a.display_name, nullif(trim(concat_ws(' ', a.first_name, a.last_name)), ''), a.email, t.user_id::text),
        'slug', a.slug,
        'email', a.email,
        'amount_cents', t.amount_cents,
        'oldest_at', t.oldest_at,
        'credits', t.credits
      ) order by t.oldest_at)
      from (
        select c.user_id, sum(c.amount_cents) amount_cents, min(c.created_at) oldest_at,
               jsonb_agg(jsonb_build_object('id', c.id, 'draft_id', c.draft_id, 'title', c.course_title, 'amount_cents', c.amount_cents, 'created_at', c.created_at) order by c.created_at) credits
        from public.creator_credits c where c.payout_id is null group by c.user_id
      ) t left join public.creator_accounts a on a.user_id = t.user_id
    ), '[]'::jsonb),
    'history', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id, 'user_id', p.user_id,
        'name', coalesce(a.display_name, nullif(trim(concat_ws(' ', a.first_name, a.last_name)), ''), a.email, p.user_id::text),
        'amount_cents', p.amount_cents, 'credits_count', p.credits_count, 'paid_at', p.paid_at, 'note', p.note
      ) order by p.paid_at desc)
      from (select * from public.creator_payouts order by paid_at desc limit 100) p
      left join public.creator_accounts a on a.user_id = p.user_id
    ), '[]'::jsonb),
    'paid_total_cents', coalesce((select sum(amount_cents) from public.creator_payouts), 0)
  );
end;
$$;
revoke all on function public.studio_payouts_due() from public;
grant execute on function public.studio_payouts_due() to authenticated;

-- « Virement fait » : regroupe les crédits non versés de l'auteur dans un versement.
create or replace function public.studio_mark_paid(p_user uuid, p_note text default null)
returns public.creator_payouts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_amount integer;
  v_count integer;
  p public.creator_payouts;
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  perform 1 from public.creator_credits where user_id = p_user and payout_id is null for update;
  select coalesce(sum(amount_cents), 0), count(*) into v_amount, v_count from public.creator_credits where user_id = p_user and payout_id is null;
  if v_count = 0 then
    raise exception 'Nothing due for this author.';
  end if;
  insert into public.creator_payouts (user_id, amount_cents, currency, credits_count, paid_by, note)
  values (p_user, v_amount, 'USD', v_count, auth.uid(), nullif(trim(coalesce(p_note, '')), ''))
  returning * into p;
  update public.creator_credits set payout_id = p.id where user_id = p_user and payout_id is null;
  return p;
end;
$$;
revoke all on function public.studio_mark_paid(uuid, text) from public;
grant execute on function public.studio_mark_paid(uuid, text) to authenticated;

-- ---------- 8. tableaux de bord ----------

-- Le tableau de bord d'un auteur : lectures, cours, et sa cagnotte (crédits, versements, quota).
create or replace function public.creator_dashboard(p_days integer default 28)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_slug text := public.studio_creator_slug(v_uid);
  v_days integer := greatest(1, least(coalesce(p_days, 28), 365));
  v_since date := current_date - v_days;
  v_prev date := current_date - 2 * v_days;
  v_fee integer := coalesce((select (value ->> 'course_fee_cents')::integer from public.app_config where key = 'studio'), 1500);
  v_money jsonb;
  result jsonb;
begin
  if v_uid is null then
    return null;
  end if;
  v_money := jsonb_build_object(
    'fee_cents', v_fee,
    'currency', 'USD',
    'pot_cents', coalesce((select sum(amount_cents) from public.creator_credits where user_id = v_uid and payout_id is null), 0),
    'paid_cents', coalesce((select sum(amount_cents) from public.creator_payouts where user_id = v_uid), 0),
    'credits', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'draft_id', c.draft_id, 'title', c.course_title, 'amount_cents', c.amount_cents, 'created_at', c.created_at, 'paid_at', p.paid_at) order by c.created_at desc)
      from public.creator_credits c left join public.creator_payouts p on p.id = c.payout_id where c.user_id = v_uid
    ), '[]'::jsonb),
    'payouts', coalesce((
      select jsonb_agg(jsonb_build_object('id', p.id, 'amount_cents', p.amount_cents, 'credits_count', p.credits_count, 'paid_at', p.paid_at) order by p.paid_at desc)
      from public.creator_payouts p where p.user_id = v_uid
    ), '[]'::jsonb),
    'quota', public.studio_quota(v_uid)
  );
  if v_slug is null then
    return jsonb_build_object('slug', null, 'days', v_days, 'courses', '[]'::jsonb, 'series', '[]'::jsonb) || v_money;
  end if;

  with mine as (
    select c.id, c.subject, c.status, c.published_at, c.origin_lang
    from public.courses c where c.creator_slug = v_slug
  ),
  cur as (
    select d.course_id, sum(d.impressions) impressions, sum(d.opens) opens, sum(d.completes) completes,
           sum(d.likes) likes, sum(d.readers) readers, sum(d.quiz_answers) quiz_answers, sum(d.quiz_correct) quiz_correct
    from public.course_stats_window(v_since) d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1
  ),
  prev as (
    select sum(d.opens) opens from public.course_stats_window(v_prev) d join mine m on m.id = d.course_id
    where d.day >= v_prev and d.day < v_since
  ),
  langs as (
    select d.course_id, d.lang, sum(d.opens) opens
    from public.course_stats_window(v_since) d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1, 2
  ),
  series as (
    select d.day, sum(d.opens) opens from public.course_stats_window(v_since) d join mine m on m.id = d.course_id
    where d.day >= v_since group by 1
  ),
  follows as (
    select coalesce(sum(case when e.name = 'follow' then 1 when e.name = 'unfollow' then -1 else 0 end), 0) n
    from public.course_events e
    where e.name in ('follow', 'unfollow') and e.ts >= v_since and e.props ->> 'creator' = v_slug
  ),
  subj as (
    select c.subject, case when sum(d.impressions) > 0 then round(sum(d.completes)::numeric * 1000 / sum(d.impressions), 1) end as per1000
    from public.course_stats_window(v_since) d join public.courses c on c.id = d.course_id
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
    )
  ) || v_money into result;
  return result;
end;
$$;

-- La vue d'ensemble de l'équipe : la cagnotte à verser remplace la part Premium.
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
  v_tz text := 'Europe/Paris';
  v_next_monday timestamptz := ((date_trunc('week', now() at time zone v_tz) + interval '7 days') at time zone v_tz);
begin
  if not public.is_studio_admin() then
    raise exception 'Réservé à l''équipe Sophia' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'days', v_days,
    'review_queue', (select count(*) from public.studio_drafts where status = 'submitted'),
    'proposals_waiting', (select count(*) from public.studio_drafts where status = 'proposed'),
    'drafts_by_status', coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from public.studio_drafts group by 1) t), '{}'::jsonb),
    'creators_pending', (select count(*) from public.creator_accounts where status = 'pending'),
    'creators_approved', (select count(*) from public.creator_accounts where status = 'approved'),
    'creators_published', (select count(*) from public.creators),
    'agreements_missing', (select count(*) from public.creator_accounts a where a.status <> 'suspended' and not public.creator_agreement_current(a.user_id)),
    'jobs', coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from public.production_jobs group by 1) t), '{}'::jsonb),
    'courses_published', (select count(*) from public.courses where status = 'published'),
    'courses_in_production', (select count(*) from public.courses where status = 'in_production'),
    'reads', coalesce((select sum(opens) from public.course_stats_window(v_since) where day >= v_since), 0),
    'completes', coalesce((select sum(completes) from public.course_stats_window(v_since) where day >= v_since), 0),
    'readers', coalesce((select sum(readers) from public.course_stats_window(v_since) where day >= v_since), 0),
    'series', (select coalesce(jsonb_agg(jsonb_build_object('day', day, 'completes', c, 'reads', o) order by day), '[]'::jsonb)
               from (select day, sum(completes) c, sum(opens) o from public.course_stats_window(v_since) where day >= v_since group by 1) t),
    'by_language', (select coalesce(jsonb_agg(jsonb_build_object('lang', lang, 'reads', o) order by o desc), '[]'::jsonb)
                    from (select lang, sum(opens) o from public.course_stats_window(v_since) where day >= v_since group by 1) t),
    'by_subject', (select coalesce(jsonb_agg(jsonb_build_object('subject', subject, 'reads', o, 'completes', c, 'courses', n) order by o desc), '[]'::jsonb)
                   from (select c.subject, sum(d.opens) o, sum(d.completes) c, count(distinct d.course_id) n
                         from public.course_stats_window(v_since) d join public.courses c on c.id = d.course_id where d.day >= v_since group by 1) t),
    'payouts', jsonb_build_object(
      'fee_cents', coalesce((select (value ->> 'course_fee_cents')::integer from public.app_config where key = 'studio'), 1500),
      'currency', 'USD',
      'due_cents', coalesce((select sum(amount_cents) from public.creator_credits where payout_id is null), 0),
      'creators_due', (select count(distinct user_id) from public.creator_credits where payout_id is null),
      'validated_period', (select count(*) from public.studio_drafts where validated_at >= v_since),
      'paid_total_cents', coalesce((select sum(amount_cents) from public.creator_payouts), 0),
      'next_monday', v_next_monday)
  );
end;
$$;

-- studio_me() porte aussi le quota et la cagnotte, pour les pages du Studio.
create or replace function public.studio_me()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_account jsonb;
  v_slug text;
begin
  if v_uid is null then
    return null;
  end if;
  select to_jsonb(a), a.slug into v_account, v_slug from public.creator_accounts a where a.user_id = v_uid;
  return jsonb_build_object(
    'account', v_account,
    'is_admin', coalesce(public.studio_admin_touch(), false),
    'agreement_signed', coalesce(public.creator_agreement_current(v_uid), false),
    'public_page', v_slug is not null and exists (select 1 from public.creators c where c.slug = v_slug),
    'quota', case when v_account is null then null else public.studio_quota(v_uid) end,
    'pot_cents', coalesce((select sum(amount_cents) from public.creator_credits where user_id = v_uid and payout_id is null), 0)
  );
end;
$$;
