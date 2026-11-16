-- Traduction française des retours de l'app (page /admin/data/feedback).
--
-- Écrite par le site à la première lecture d'un retour, puis relue ici : un retour n'est
-- traduit qu'une fois. Vide : le message était déjà en français. Null : pas encore traduit.
alter table public.app_feedback add column if not exists message_fr text;
comment on column public.app_feedback.message_fr is 'Traduction française du message, écrite par le site (web/src/lib/studio/feedback-translation.ts). Vide : déjà en français. Null : pas encore traduit.';
