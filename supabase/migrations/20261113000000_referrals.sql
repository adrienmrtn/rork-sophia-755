-- Parrainage : « Invite un ami et gagne 3 cours gratuits ».
-- À coller tel quel dans l'éditeur SQL de Supabase ; rejouable.
--
-- Règles (docs/parrainage.md) :
--   - le code d'invitation d'un lecteur est son @ (profiles.handle) ;
--   - l'ami invité crée son compte, puis l'app appelle claim_referral(code) : le lien de
--     partage le fait tout seul, sinon l'ami saisit le code dans la page « Invite un ami » ;
--   - un compte ne peut être parrainé qu'une fois, pas par lui-même, et seulement dans les
--     14 jours qui suivent sa création (un vieux compte ne peut pas « s'inviter » après coup) ;
--   - la récompense revient à celui qui invite, une seule fois, dès le premier ami inscrit :
--     3 crédits de cours. Le serveur dit si elle est acquise (referral_status) ; les crédits
--     dépensés vivent dans la progression du lecteur (referralUnlockedCourseIds).

create table if not exists public.referrals (
  invitee_id uuid primary key references auth.users (id) on delete cascade,
  inviter_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint referrals_not_self check (invitee_id <> inviter_id)
);
create index if not exists referrals_inviter_idx on public.referrals (inviter_id);
comment on table public.referrals is 'Parrainage : qui a invité qui. Une ligne par compte invité, écrite par claim_referral. Le premier filleul vaut 3 crédits de cours au parrain (une seule fois).';

alter table public.referrals enable row level security;
revoke all on public.referrals from anon, authenticated;

-- L'ami invité déclare le code (@) de celui qui l'a invité. Renvoie :
--   ok | unknown_code | self | already_claimed | account_too_old
create or replace function public.claim_referral(p_code text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_code text := lower(btrim(replace(coalesce(p_code, ''), '@', '')));
  v_inviter uuid;
  v_created timestamptz;
begin
  if v_me is null then
    raise exception 'not_signed_in' using errcode = '28000';
  end if;
  if exists (select 1 from public.referrals r where r.invitee_id = v_me) then
    return 'already_claimed';
  end if;
  select p.id into v_inviter from public.profiles p where p.handle = v_code;
  if v_inviter is null then
    return 'unknown_code';
  end if;
  if v_inviter = v_me then
    return 'self';
  end if;
  select u.created_at into v_created from auth.users u where u.id = v_me;
  if v_created is null or v_created < now() - interval '14 days' then
    return 'account_too_old';
  end if;
  -- Pas de parrainage croisé : celui qui m'a invité ne peut pas devenir mon filleul.
  if exists (select 1 from public.referrals r where r.invitee_id = v_inviter and r.inviter_id = v_me) then
    return 'self';
  end if;
  insert into public.referrals (invitee_id, inviter_id) values (v_me, v_inviter)
  on conflict (invitee_id) do nothing;
  return 'ok';
end;
$$;

-- Où j'en suis : amis inscrits grâce à moi, récompense acquise ou non, et si je peux encore
-- saisir le code de quelqu'un.
create or replace function public.referral_status()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'invited', (select count(*) from public.referrals r where r.inviter_id = auth.uid()),
    'rewarded', exists (select 1 from public.referrals r where r.inviter_id = auth.uid()),
    'credits', case when exists (select 1 from public.referrals r where r.inviter_id = auth.uid()) then 3 else 0 end,
    'claimed', exists (select 1 from public.referrals r where r.invitee_id = auth.uid()),
    'can_claim', auth.uid() is not null
      and not exists (select 1 from public.referrals r where r.invitee_id = auth.uid())
      and exists (select 1 from auth.users u where u.id = auth.uid() and u.created_at >= now() - interval '14 days')
  );
$$;

revoke all on function public.claim_referral(text) from public, anon;
revoke all on function public.referral_status() from public, anon;
grant execute on function public.claim_referral(text) to authenticated;
grant execute on function public.referral_status() to authenticated;
