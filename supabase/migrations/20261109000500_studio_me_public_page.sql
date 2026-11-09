-- studio_me() dit aussi si la page publique de l'auteur existe déjà (une ligne creators sous son
-- slug, créée à la première publication) : le Studio n'y renvoie qu'à ce moment-là.

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
    'public_page', v_slug is not null and exists (select 1 from public.creators c where c.slug = v_slug)
  );
end;
$$;
revoke all on function public.studio_me() from public;
grant execute on function public.studio_me() to authenticated;
