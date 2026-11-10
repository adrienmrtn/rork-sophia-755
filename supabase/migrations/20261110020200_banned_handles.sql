-- Pseudos (@) interdits : insultes, propos haineux, figures et organisations liées à la haine ou
-- au terrorisme, contenu sexuel, et noms qui feraient passer un compte pour l'équipe Sophia.
--
-- La liste vit dans une table, pour qu'on puisse l'allonger sans publier une version de l'app :
--   insert into public.banned_handle_terms (term, kind) values ('motàbannir', 'contains');
-- `contains` : le @ est refusé dès qu'il contient le terme (réservé aux termes sans ambiguïté).
-- `exact`    : le @ est refusé s'il est exactement ce terme, chiffres mis à part. Pour les mots
--              courts ou présents dans des prénoms et des mots innocents (« nazi » dans Nazir,
--              « sex » dans Essex, « viol » dans Violette, « sophia » dans SophiaMartin).
-- La comparaison se fait sur le @ « déguisé » remis à plat (0→o, 1→i, 3→e, 4→a, 5→s, 7→t) et
-- sur le @ sans ses chiffres. L'app iOS porte la même liste (`HandleModeration.swift`) pour
-- répondre sans attendre le serveur ; c'est le serveur qui fait foi.

create table if not exists public.banned_handle_terms (
  term text primary key check (term ~ '^[a-z]+$'),
  kind text not null check (kind in ('contains', 'exact'))
);

-- Aucune politique : la table n'est lue que par les fonctions ci-dessous (security definer).
alter table public.banned_handle_terms enable row level security;
revoke all on table public.banned_handle_terms from anon, authenticated;

insert into public.banned_handle_terms (term, kind) values
  ('hitler', 'contains'), ('heilhitler', 'contains'), ('siegheil', 'contains'), ('neonazi', 'contains'),
  ('nazism', 'contains'), ('nazisme', 'contains'), ('thirdreich', 'contains'), ('mussolini', 'contains'),
  ('goebbels', 'contains'), ('himmler', 'contains'), ('binladen', 'contains'), ('benladen', 'contains'),
  ('alqaeda', 'contains'), ('alqaida', 'contains'), ('daesh', 'contains'), ('taliban', 'contains'),
  ('terrorist', 'contains'), ('whitepower', 'contains'), ('whitepride', 'contains'), ('supremacist', 'contains'),
  ('antisemit', 'contains'), ('kkk', 'contains'), ('nigger', 'contains'), ('nigga', 'contains'),
  ('faggot', 'contains'), ('tarlouze', 'contains'), ('bougnoule', 'contains'), ('youpin', 'contains'),
  ('tranny', 'contains'), ('retarded', 'contains'), ('fuck', 'contains'), ('motherfucker', 'contains'),
  ('bitch', 'contains'), ('pussy', 'contains'), ('penis', 'contains'), ('vagina', 'contains'),
  ('porn', 'contains'), ('hentai', 'contains'), ('blowjob', 'contains'), ('handjob', 'contains'),
  ('pedophil', 'contains'), ('killyourself', 'contains'), ('salope', 'contains'), ('connard', 'contains'),
  ('connasse', 'contains'), ('encule', 'contains'), ('niquetamere', 'contains'), ('niquetarace', 'contains'),
  ('filsdepute', 'contains'), ('suceuse', 'contains'), ('hurensohn', 'contains'), ('fotze', 'contains'),
  ('schwuchtel', 'contains'), ('wichser', 'contains'), ('arschloch', 'contains'), ('hijodeputa', 'contains'),
  ('putamadre', 'contains'), ('maricon', 'contains'), ('pendejo', 'contains'), ('mierda', 'contains'),
  ('vaffanculo', 'contains'), ('stronzo', 'contains'), ('frocio', 'contains'), ('cazzo', 'contains'),
  ('caralho', 'contains'), ('buceta', 'contains'), ('kurwa', 'contains'), ('blyat', 'contains'),
  ('pidor', 'contains'), ('pidar', 'contains'), ('siktir', 'contains'), ('orospu', 'contains'),
  ('sophia', 'exact'), ('sophiaapp', 'exact'), ('sophiaofficial', 'exact'), ('sophiaofficiel', 'exact'),
  ('sophiateam', 'exact'), ('sophiasupport', 'exact'), ('admin', 'exact'), ('administrator', 'exact'),
  ('administrateur', 'exact'), ('support', 'exact'), ('moderator', 'exact'), ('moderateur', 'exact'),
  ('staff', 'exact'), ('official', 'exact'), ('officiel', 'exact'), ('system', 'exact'),
  ('root', 'exact'), ('null', 'exact'), ('nazi', 'exact'), ('nazis', 'exact'),
  ('isis', 'exact'), ('stalin', 'exact'), ('staline', 'exact'), ('petain', 'exact'),
  ('polpot', 'exact'), ('pedo', 'exact'), ('pede', 'exact'), ('negro', 'exact'),
  ('negre', 'exact'), ('kike', 'exact'), ('chink', 'exact'), ('spic', 'exact'),
  ('fag', 'exact'), ('cunt', 'exact'), ('slut', 'exact'), ('whore', 'exact'),
  ('rape', 'exact'), ('rapist', 'exact'), ('viol', 'exact'), ('violeur', 'exact'),
  ('sex', 'exact'), ('sexe', 'exact'), ('sexy', 'exact'), ('xxx', 'exact'),
  ('nude', 'exact'), ('nudes', 'exact'), ('shit', 'exact'), ('pute', 'exact'),
  ('putes', 'exact'), ('puta', 'exact'), ('puto', 'exact'), ('bite', 'exact'),
  ('chatte', 'exact'), ('couille', 'exact'), ('couilles', 'exact'), ('ntm', 'exact'),
  ('fdp', 'exact'), ('tapette', 'exact'), ('bicot', 'exact'), ('cabron', 'exact'),
  ('joder', 'exact'), ('foda', 'exact'), ('viado', 'exact'), ('suka', 'exact'),
  ('amk', 'exact'), ('kys', 'exact'), ('suicide', 'exact')
on conflict (term) do update set kind = excluded.kind;

create or replace function public.handle_is_allowed(candidate text)
returns boolean
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  cleaned text := lower(coalesce(candidate, ''));
  unleeted text;
  letters text;
begin
  unleeted := regexp_replace(translate(cleaned, '013457', 'oieast'), '[0-9]', '', 'g');
  letters := regexp_replace(cleaned, '[0-9]', '', 'g');
  return not exists (
    select 1 from public.banned_handle_terms b
    where (b.kind = 'contains' and (position(b.term in unleeted) > 0 or position(b.term in letters) > 0))
       or (b.kind = 'exact' and (b.term = unleeted or b.term = letters))
  );
end;
$$;

revoke all on function public.handle_is_allowed(text) from public;
revoke all on function public.handle_is_allowed(text) from anon;
revoke all on function public.handle_is_allowed(text) from authenticated;

-- Changement de @ : mêmes règles qu'avant, plus le refus des @ interdits (`handle_not_allowed`).
create or replace function public.update_my_handle(new_handle text)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  cleaned text;
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;

  cleaned := lower(btrim(coalesce(new_handle, '')));
  cleaned := regexp_replace(cleaned, '^@+', '');
  cleaned := regexp_replace(cleaned, '[^a-z0-9]', '', 'g');

  if cleaned !~ '^[a-z][a-z0-9]{2,19}$' then
    raise exception 'invalid_handle';
  end if;

  if not public.handle_is_allowed(cleaned) then
    raise exception 'handle_not_allowed';
  end if;

  if exists (
    select 1 from public.profiles p
    where p.handle = cleaned and p.id <> uid
  ) then
    raise exception 'handle_taken';
  end if;

  update public.profiles
  set handle = cleaned
  where id = uid;

  return cleaned;
end;
$$;

revoke all on function public.update_my_handle(text) from public;
revoke all on function public.update_my_handle(text) from anon;
grant execute on function public.update_my_handle(text) to authenticated;

-- @ généré à l'inscription (à partir de l'email) : une base interdite est remplacée par une base
-- aléatoire, comme quand l'email ne donne rien d'utilisable.
create or replace function public.allocate_unique_handle(preferred_base text)
returns text
language plpgsql
volatile
set search_path to 'public'
as $$
declare
  base text;
  candidate text;
  suffix int := 1;
begin
  base := public.normalize_handle_base(preferred_base);
  if base is null or not public.handle_is_allowed(base) then
    base := public.random_handle_base();
  end if;

  candidate := base;
  while exists (select 1 from public.profiles p where p.handle = candidate) loop
    candidate := base || suffix::text;
    suffix := suffix + 1;
    if suffix > 10000 then
      base := public.random_handle_base();
      candidate := base;
      suffix := 1;
    end if;
  end loop;

  return candidate;
end;
$$;

revoke all on function public.allocate_unique_handle(text) from public;
revoke all on function public.allocate_unique_handle(text) from anon;
revoke all on function public.allocate_unique_handle(text) from authenticated;
