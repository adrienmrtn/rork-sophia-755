-- La signature du contrat calculait l'empreinte avec digest() (pgcrypto), introuvable depuis une
-- fonction dont le search_path est public. On utilise sha256() de Postgres, sans extension.

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
  if v_body is null then
    raise exception 'Contrat introuvable dans cette langue';
  end if;
  insert into public.creator_agreements (user_id, document_slug, version, lang, signed_name, ip, user_agent, body_sha256)
  values (auth.uid(), 'creator-agreement', v_version, v_lang, trim(p_signed_name), p_ip, p_user_agent, encode(sha256(convert_to(v_body, 'UTF8')), 'hex'))
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
