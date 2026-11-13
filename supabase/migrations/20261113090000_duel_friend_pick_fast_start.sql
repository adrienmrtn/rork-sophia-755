-- Duel entre amis : dès que la matière d'une manche est choisie, la partie reprend.
--
-- Avant, la première question de la manche attendait la fin du délai de choix
-- (question_started_at), même quand le joueur avait choisi dès la première seconde.
-- Le choix avance maintenant ce départ à 2,6 secondes plus tard au plus : le temps que
-- l'autre joueur, qui interroge le serveur toutes les 0,7 s, voie la matière s'afficher.
-- Un choix fait dans les dernières secondes ne retarde rien (least).
--
-- Seule cette ligne change dans la fonction :
--   question_started_at = least(question_started_at, clock_timestamp() + interval '2600 milliseconds')
-- Les apps suivent déjà un départ avancé ; les anciennes versions, qui attendent l'heure
-- prévue au départ, rattrapent simplement la question en cours (comme après une coupure réseau).
--
-- À COLLER dans Supabase > SQL Editor, puis Run. Peut être relancé sans risque.

create or replace function public.duel_friend_pick(p_match uuid, p_round integer, p_subject text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  uid uuid := auth.uid();
  m public.duel_friend_matches;
  ids text[];
  slot int;
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;
  if not exists (
    select 1 from public.duel_friend_matches x
    where x.id = p_match and uid in (x.player_a, x.player_b)
  ) then
    raise exception 'match_not_found';
  end if;

  m := public.duel_friend_advance(p_match);
  slot := (p_round - 1) * 5;

  if m.status = 'active'
     and m.round_options is not null
     and p_round in (2, 3)
     and uid = (case when p_round = 2 then m.player_a else m.player_b end)
     and not (m.picks ? p_round::text)
     and m.current_index = slot
     and now() < m.question_started_at
     and m.round_options -> p_round::text -> 'options' ? p_subject
  then
    ids := array(select jsonb_array_elements_text(m.round_options -> p_round::text -> 'options' -> p_subject));
    update public.duel_friend_matches set
      question_ids = question_ids[1:slot] || ids || question_ids[slot + 6:20],
      picks = picks || jsonb_build_object(p_round::text, p_subject),
      -- La matière est choisie : la manche démarre sans attendre la fin du délai de choix.
      question_started_at = least(question_started_at, clock_timestamp() + interval '2600 milliseconds')
    where id = p_match
    returning * into m;
    -- La matière choisie remplace celle par défaut : ses cinq questions entrent aussi dans
    -- la mémoire des deux joueurs, sinon la partie suivante pouvait les reposer.
    update public.duel_profiles set
      recent_question_ids = (ids || recent_question_ids)[1:1500]
    where user_id in (m.player_a, m.player_b);
  end if;

  return public.duel_friend_state_json(m, uid);
end;
$function$;
