-- Collecte des événements : volume par jour, plateforme et version (30 derniers jours).
-- À coller dans l'éditeur SQL. Une version qui n'apparaît plus, ou dont les
-- événements par utilisateur s'effondrent, a cassé l'enregistrement.
select
  day,
  platform,
  app_version,
  users,
  events,
  round(events::numeric / greatest(users, 1), 1) as events_per_user,
  impressions,
  opens,
  completes,
  quiz_answers,
  paywall_views
from public.events_health
order by day desc, platform, app_version;

-- Un parcours précis : les événements d'un utilisateur sur une journée, dans l'ordre.
-- select ts, name, course_id, screen, position, premium_status, props
-- from public.course_events
-- where user_id = '00000000-0000-0000-0000-000000000000'
--   and ts > now() - interval '1 day'
-- order by ts;
