-- Retours envoyés depuis le formulaire des réglages (iOS et Android). L'app continue de
-- les envoyer à Formspree, qui nous prévient par e-mail et porte l'adresse de réponse ;
-- cette table en garde une copie sans l'adresse, pour les lire à côté des données d'usage
-- (tableau de bord /admin/data). Voir docs/events.md.

create table if not exists public.app_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null,
  message text not null,
  has_email boolean not null default false,
  lang text,
  platform text not null,
  app_version text,
  os_version text,
  device text,
  is_premium boolean,
  created_at timestamptz not null default now(),
  constraint app_feedback_category_check check (category in ('bug', 'idea', 'feature', 'content', 'translation', 'other')),
  constraint app_feedback_platform_check check (platform in ('ios', 'android')),
  constraint app_feedback_message_check check (char_length(message) between 1 and 5000),
  constraint app_feedback_lang_check check (lang is null or char_length(lang) between 2 and 5),
  constraint app_feedback_text_sizes check (
    coalesce(char_length(app_version), 0) <= 32
    and coalesce(char_length(os_version), 0) <= 32
    and coalesce(char_length(device), 0) <= 64
  )
);

comment on table public.app_feedback is 'Copie des retours du formulaire de l''app (sans adresse e-mail, qui reste chez Formspree).';

create index if not exists app_feedback_created_at on public.app_feedback (created_at desc);
create index if not exists app_feedback_user on public.app_feedback (user_id);

alter table public.app_feedback enable row level security;

-- L'app dépose ses propres retours et rien d'autre : ni lecture, ni mise à jour.
drop policy if exists app_feedback_insert_own on public.app_feedback;
create policy app_feedback_insert_own on public.app_feedback
  for insert to authenticated
  with check (user_id = (select auth.uid()));

revoke all on public.app_feedback from anon, authenticated;
grant insert on public.app_feedback to authenticated;
