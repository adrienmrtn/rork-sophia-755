-- Inscription impossible pour un email dont la partie locale commence par un chiffre
-- (constaté le 10 novembre : 192 tentatives échouées en 24 h pour une même personne). Le pseudo
-- dérivé de l'email (« 8114xxx ») ne respectait pas profiles_handle_format_check
-- (^[a-z][a-z0-9]{2,19}$) ; le trigger handle_new_user échouait, et avec lui la création du
-- compte (« Database error saving new user »). Par ailleurs une base de 20 caractères plus un
-- suffixe numérique dépassait les 20 caractères autorisés.
create or replace function public.normalize_handle_base(raw text)
returns text
language plpgsql
immutable
set search_path to 'public'
as $$
declare
  cleaned text;
begin
  cleaned := lower(coalesce(raw, ''));
  cleaned := regexp_replace(cleaned, '[^a-z0-9]', '', 'g');
  -- Un pseudo commence par une lettre : on en ajoute une devant un début en chiffre.
  if cleaned ~ '^[0-9]' then
    cleaned := 'u' || cleaned;
  end if;
  if length(cleaned) < 3 then
    return null;
  end if;
  -- 15 au plus, pour que le suffixe d'unicité (jusqu'à 5 chiffres) tienne dans les 20.
  return left(cleaned, 15);
end;
$$;
