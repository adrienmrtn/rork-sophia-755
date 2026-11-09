-- Une seule lecture par page du Studio : le compte créateur, le rôle équipe et l'état du contrat.
-- (Le site faisait trois appels ; chacun traversait l'Atlantique.)

create or replace function public.studio_me()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_account jsonb;
begin
  if v_uid is null then
    return null;
  end if;
  select to_jsonb(a) into v_account from public.creator_accounts a where a.user_id = v_uid;
  return jsonb_build_object(
    'account', v_account,
    'is_admin', coalesce(public.studio_admin_touch(), false),
    'agreement_signed', coalesce(public.creator_agreement_current(v_uid), false)
  );
end;
$$;
revoke all on function public.studio_me() from public;
grant execute on function public.studio_me() to authenticated;
