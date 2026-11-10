-- Les apps envoient leurs événements par « upsert » (insert … on conflict (ts, event_id) do
-- nothing) pour rejouer un lot sans doublon après une coupure. Or une clause on conflict qui
-- nomme des colonnes exige le droit de lecture sur ces colonnes, et dès que la lecture est
-- requise, Postgres applique aussi les règles select à la ligne insérée. Sans droit de lecture
-- ni règle select, chaque envoi était refusé (403 « permission denied for table course_events »)
-- et aucun événement n'est jamais entré dans la table (constaté le 10 novembre, build iOS 439).
-- Correctif : lecture limitée aux deux colonnes de la clé, sur ses propres lignes seulement.
grant select (ts, event_id) on public.course_events to authenticated;

create policy course_events_select_own on public.course_events
  for select to authenticated
  using (user_id = auth.uid());
