# Journal d'événements produit (`course_events`)

Spécification unique des événements envoyés par l'app iOS et l'app Android. Les deux
plateformes utilisent **exactement les mêmes noms et les mêmes propriétés** ; un
événement qui n'est pas dans cette liste est refusé par la base (contrainte `name`).

Le journal sert à mesurer ce qui est montré, ouvert, lu et terminé, à noter les cours,
à nourrir l'algorithme du fil et le tableau de bord des créateurs, et à calculer la
rémunération. Il remplace l'absence totale de mesure dans le temps (`user_progress`
n'est qu'une photo sans dates).

## Transport

- Table `public.course_events`, partitionnée par jour UTC dans le schéma `analytics`,
  conservée 90 jours. Synthèse quotidienne dans `public.daily_course_stats` (pour
  toujours). Migration : `supabase/migrations/20261108120000_course_events_and_subscriptions.sql`.
- L'app insère directement par PostgREST (`upsert` sur `(ts, event_id)`, doublons
  ignorés). Règle RLS : `user_id = auth.uid()`, horodatage entre maintenant − 30 jours et
  maintenant + 15 minutes. Aucune lecture, mise à jour ni suppression côté client.
- File d'attente sur le téléphone (fichier dans Application Support / `filesDir`),
  envoi par lots de 200 au plus, toutes les 30 secondes, quand la file atteint 50
  événements, et au passage en arrière-plan. Rejeu après une coupure réseau ; la file
  est plafonnée à 5 000 événements (les plus anciens sont perdus au-delà).
- Un événement produit avant la connexion (premiers écrans de l'onboarding) porte
  `install_id` et attend dans la file ; son `user_id` est rempli au premier envoi après la
  connexion. La connexion Apple ou Google est obligatoire : il n'y a pas d'utilisateur
  anonyme durable.
- Contrôle de la collecte : vue `public.events_health` (événements par jour,
  plateforme et version, 30 jours), requête `supabase/queries/events_health.sql`.

## Colonnes communes

| Colonne | Contenu |
| --- | --- |
| `event_id` | UUID généré par l'app (idempotence) |
| `user_id` | utilisateur Supabase |
| `install_id` | UUID de l'installation, stable tant que l'app n'est pas réinstallée |
| `session_id` | UUID renouvelé à chaque passage au premier plan après 30 min d'absence |
| `name` | nom de l'événement (liste ci-dessous) |
| `course_id` | identifiant de cours (`course_16_…`), si l'événement concerne un cours |
| `lang` | langue de l'app (`fr`, `pt-PT`…) |
| `country` | région du téléphone, ISO 3166-1 alpha-2 |
| `platform` | `ios` ou `android` |
| `app_version` | version marketing (`1.11`) |
| `premium_status` | `free`, `trial`, `paid` ou `unknown` au moment de l'événement |
| `screen` | écran d'origine quand il compte (`home`, `library`, `profile`…) |
| `position` | rang de la carte dans le fil (0 = première), pour les événements de carte |
| `algo_version` | version de l'algorithme qui a produit le fil (`local-v1` tant que le fil est calculé sur le téléphone) |
| `props` | propriétés spécifiques, JSON de 2 Ko au plus |
| `ts` | horodatage de l'événement sur l'appareil |

## Événements

### Application et onboarding

| Nom | Quand | `props` |
| --- | --- | --- |
| `app_open` | passage au premier plan (une fois par session) | `source` : `direct`, `notification`, `widget`, `link` ; `nav` : `classic` ou `newgen`, la variante de navigation tirée au sort (A/B du prompt 2) |
| `onboarding_step` | un écran d'onboarding s'affiche | `step` (nom analytique de l'écran, identique sur les deux plateformes ; Android émet `paywall` là où iOS distingue `paywall_annual` et `paywall_comparison`), `index` |

### Fil (cartes)

| Nom | Quand | `props` |
| --- | --- | --- |
| `card_impression` | une carte reste visible au moins 1 seconde (dans le fil paginé : la page sur laquelle on s'arrête) | — (`course_id`, `position`, `algo_version`) |
| `card_skip` | l'utilisateur passe à la carte suivante sans ouvrir | — (`course_id`, `position`) |
| `card_open` | « Commencer » sur une carte | — (`course_id`, `position`) |

### Lecture

| Nom | Quand | `props` |
| --- | --- | --- |
| `course_open` | le lecteur s'ouvre | `source` : `feed`, `library`, `subject`, `path`, `favorites`, `profile`, `my_courses`, `notification`, `widget`, `blocker`, `author`, `search`, `event`, `unknown` ; `locked` (vrai si le cours est verrouillé pour un gratuit) |
| `section_view` | l'utilisateur quitte une section (page suivante, fin ou fermeture) | `section_index` (0 = intro), `section_count`, `seconds` (entier), `reached_end` (vrai si la section a été lue jusqu'au bout) |
| `course_complete` | fin du cours validée (écran de félicitations) | `first_time` (vrai si première fois) |
| `glossary_open` | une fiche de glossaire s'ouvre | `term`, `section_index` (iOS seulement : Android ne connaît pas la section depuis le texte) |
| `funfact_open` | un « Le savais-tu ? » est révélé | `section_index`. iOS seulement : sur Android l'encart est toujours déplié, rien à révéler |
| `audio_play` | la narration démarre | `source` : `reader`, `card`, `queue`, `library` |

### Quiz

| Nom | Quand | `props` |
| --- | --- | --- |
| `quiz_start` | un quiz commence | `context` : `course`, `path`, `training` |
| `quiz_answer` | une réponse est validée | `question_id`, `context`, `correct`, `points`, `max_points`, `option_index` (choix unique, index affiché après mélange), `seconds` |
| `quiz_complete` | un quiz se termine | `context`, `score`, `max_score`, `correct`, `total`, `passed` (parcours) |

### Gestes sociaux

Tant que les likes et les abonnements n'existent pas côté serveur (prompt 6), les gestes
sont locaux : le cœur est un « j'aime » (`likedCourseIds`), le marque-page un
« enregistrer » (`favoriteCourseIds`, la liste « À lire »), « Suivre » un abonnement
(`followedCreatorSlugs`). Dans la navigation classique, le marque-page de la carte reste
enregistré comme `like` / `unlike`.

| Nom | Quand | `props` |
| --- | --- | --- |
| `like` / `unlike` | cœur sur un cours (bouton, ou double-tap sur la carte du fil) | `screen` : `home`, `home_following`, `course_detail`, `course_end`, `library`… |
| `save` / `unsave` | enregistrer pour plus tard (marque-page) | `screen` |
| `share` | partage d'un cours ou de l'app | `channel`, `target` (`course` ou `app`) |
| `follow` / `unfollow` | suivre un créateur | `creator` (slug), `screen` : `creator`, `explore`, `course_detail`, `course_end`, `reader` |
| `not_interested` | « pas intéressé » sur une carte | — |
| `report` | signalement | `kind` (`course`, `translation`, `quiz_question`, `creator`), `target`, `reason` |

### Abonnement

| Nom | Quand | `props` |
| --- | --- | --- |
| `paywall_view` | un paywall s'affiche (une fois par présentation) | `paywall_id` (`native_quiz`, `onboarding_annual`…), `offering`, `context` quand il est connu (iOS) |
| `purchase_started` | l'achat est lancé | `product`, `offering` |
| `purchase_completed` | l'achat aboutit et le droit Premium est actif | `product` |
| `purchase_failed` | l'achat n'aboutit pas | `product`, `reason` : `cancelled`, `pending`, `error` |

## Abonnements côté serveur

- `public.subscription_events` : les webhooks RevenueCat (fonction `revenuecat-webhook`,
  en-tête `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>`).
- `public.subscriber_snapshots` : le statut tel que l'app le connaît, envoyé à chaque
  lancement et à chaque changement (`is_active`, `period_type`, `product_id`, `store`,
  `expires_at`, `will_renew`). Il couvre les abonnés déjà actifs avant la mise en place
  du webhook.
- `public.premium_status` : vue qui combine les deux, la source la plus récente l'emporte.

## Ajouter un événement

1. L'ajouter ici, avec ses propriétés.
2. L'ajouter à la contrainte `course_events_name_check` par une migration.
3. L'ajouter à la liste des deux apps (`AnalyticsEventName` sur iOS, `Analytics.KNOWN_NAMES`
   sur Android) et l'émettre au même endroit fonctionnel sur les deux plateformes.
4. Si une synthèse doit le compter, l'ajouter à `refresh_daily_course_stats`.
