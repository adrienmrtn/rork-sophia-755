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
  maintenant + 15 minutes. Côté client, la lecture se limite aux colonnes `ts` et `event_id`
  de ses propres lignes : la clause `on conflict` l'exige (sans ce droit et sans règle
  `select`, Postgres refuse tout l'envoi, ce qui a bloqué la collecte jusqu'au 10 novembre,
  migration `20261110000300_course_events_upsert_grant.sql`). Ni mise à jour ni suppression.
- File d'attente sur le téléphone (fichier dans Application Support / `filesDir`),
  envoi par lots de 200 au plus, toutes les 30 secondes, quand la file atteint 50
  événements, et au passage en arrière-plan. Rejeu après une coupure réseau ; la file
  est plafonnée à 5 000 événements (les plus anciens sont perdus au-delà).
- Un événement produit avant la connexion porte `install_id` et attend dans la file ; son
  `user_id` est rempli au premier envoi après la connexion. La connexion Apple ou Google est
  obligatoire : il n'y a pas d'utilisateur anonyme durable. **Exception : l'onboarding**
  (`onboarding_step`, `onboarding_answer`) ne va pas dans `course_events` et n'attend pas la
  connexion, voir « Onboarding » plus bas.
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
| `onboarding_answer` | on quitte, en avançant, un écran d'onboarding où une réponse a été donnée | `step`, `question`, `answer` (texte) |

#### Onboarding : collecte sans compte

La connexion est le vingt-sixième écran de l'onboarding : avec la règle de `course_events`,
quelqu'un qui abandonne avant ne laisserait aucune trace. Les deux événements d'onboarding
partent donc, dès qu'ils sont en file et avec ou sans compte, par la fonction
`public.log_onboarding_events(p_events)` (migration `20261113050000_onboarding_events.sql`),
qui écrit dans `public.onboarding_events`. La ligne n'est rattachée qu'à `install_id`, un
UUID tiré au hasard par l'app ; `user_id` est rempli si l'appel est fait connecté. L'app
envoie ses lignes telles qu'elle les garde en file (les colonnes communes, la réponse dans
`props`). Une ligne mal formée est écartée sans faire échouer le lot. Garde-fous : 200
lignes par appel, horodatage entre maintenant − 30 jours et maintenant + 15 minutes, 2 000
lignes au plus par installation. Le brut est gardé 90 jours.

Questions (`question` → `answer`) :

| `question` | Écran | `answer` |
| --- | --- | --- |
| `age` | `age` | une tranche : `under18`, `18to24`, `25to34`, `35to44`, `45to54`, `55plus`. Jamais un âge exact |
| `knowledge` | `knowledge` | `0` à `3` |
| `motivation` | `motivation` | `grow`, `conversations`, `career`, `sharp`, `world` |
| `objectives` | `objective` | choix multiples : les clés triées, séparées par des virgules (`cultivate,exams`) |
| `topics` | `topics` | choix multiples, même forme (clés de matière) |
| `phone_time` | `phone_time` | minutes par jour (`180`) |
| `reading_time` | `reading_time` (iOS) | heure locale choisie (`21`) |
| `reads_monthly`, `forgets_reading`, `too_much_phone`, `likes_learning_daily` | `loading` (iOS) | `true` ou `false` |

Le prénom n'est pas envoyé. Revenir en arrière et changer de réponse envoie une nouvelle
ligne : la dernière de la journée compte.

Synthèse `public.daily_onboarding_stats` (sans limite, recalculée toutes les heures) : par
jour UTC, plateforme et langue, le nombre d'installations par écran (`kind = 'step'`), par
question (`'answered'`) et par réponse (`'answer'`, une réponse à choix multiples comptant
dans chacune de ses options). `public.admin_onboarding_dashboard(p_days, p_platform, p_lang)`
alimente la page `/admin/data/onboarding` du site ; l'ordre des écrans et les libellés sont
dans `web/src/lib/studio/onboarding.ts`, à compléter quand un écran ou une question s'ajoute.

### Fil (cartes)

| Nom | Quand | `props` |
| --- | --- | --- |
| `card_impression` | une carte reste visible au moins 1 seconde (dans le fil paginé : la page sur laquelle on s'arrête) | — (`course_id`, `position`, `algo_version`) |
| `card_skip` | l'utilisateur passe à la carte suivante sans ouvrir | — (`course_id`, `position`) |
| `card_open` | « Commencer » sur une carte | — (`course_id`, `position`) |

### Lecture

| Nom | Quand | `props` |
| --- | --- | --- |
| `course_open` | le lecteur s'ouvre | `source` : `feed`, `library`, `subject`, `path`, `favorites`, `profile`, `my_courses`, `notification`, `widget`, `blocker`, `author`, `search`, `event`, `shared_link` (lien web d'un cours partagé), `unknown` ; `locked` (vrai si le cours est verrouillé pour un gratuit) |
| `section_view` | l'utilisateur quitte une section (page suivante, fin ou fermeture) | `section_index` (0 = intro), `section_count`, `seconds` (entier), `reached_end` (vrai si la section a été lue jusqu'au bout), `mode` (iOS : `steps` pour le lecteur pas à pas, `pages` pour le lecteur par pages ; absent sur Android, toujours par pages) |
| `course_complete` | fin du cours validée (écran de félicitations) | `first_time` (vrai si première fois), `mode` (iOS, comme `section_view`) |
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
| `like` / `unlike` | cœur sur un cours (bouton, double-tap sur la carte du fil, ou double-tap sur une leçon dans le lecteur) | `screen` : `home`, `home_following`, `course_detail`, `course_end`, `library`, `reader`… |
| `save` / `unsave` | enregistrer pour plus tard (marque-page) | `screen` |
| `share` | partage d'un cours ou de l'app | `channel`, `target` (`course` ou `app`) |
| `follow` / `unfollow` | suivre un créateur | `creator` (slug), `screen` : `creator`, `explore`, `course_detail`, `course_end`, `reader` ; depuis un cours (`course_detail`, `course_end`, `reader`) la colonne `course_id` est remplie : c'est elle qui donne les « abonnés gagnés » par cours dans `course-stats-export` |
| `not_interested` | « pas intéressé » sur une carte | — |
| `report` | signalement | `kind` (`course`, `translation`, `quiz_question`, `creator`), `target`, `reason` |

### Abonnement

| Nom | Quand | `props` |
| --- | --- | --- |
| `paywall_view` | un paywall s'affiche (une fois par présentation) | `paywall_id` (`native_quiz`, `onboarding_annual`…), `offering`, `context` quand il est connu (iOS) |
| `purchase_started` | l'achat est lancé | `product`, `offering`, `paywall_id` |
| `purchase_completed` | l'achat aboutit et le droit Premium est actif | `product`, `paywall_id` |
| `purchase_failed` | l'achat n'aboutit pas | `product`, `paywall_id`, `reason` : `cancelled`, `pending`, `error` |

`paywall_id` sur les trois événements d'achat est celui du paywall depuis lequel l'achat est
lancé, identique à celui de son `paywall_view`. Un paywall soumis à un test A/B fait dans
l'app ajoute `experiment` et `variant` à son `paywall_view` et à ses événements d'achat
(`course_paywall_ab` : `bonhomme` / `reviews` ; `discount_paywall_ab` : `percent` /
`graduate`). Le test de prix du paywall de réduction et les expériences RevenueCat se lisent
dans `offering`.

### Synthèse et tableau de bord des paywalls

- `public.daily_paywall_stats` (migration `20261113040000_daily_paywall_stats.sql`) : par
  jour UTC, plateforme, langue, paywall, offre, test et variante, les affichages, les
  personnes distinctes, les achats lancés, réussis, annulés et en échec. Conservée sans
  limite ; recalculée toutes les heures pour le jour en cours et les deux précédents.
- Un achat sans `paywall_id` (versions antérieures) est rattaché au dernier paywall affiché
  au même utilisateur dans l'heure qui précède, sinon à `unknown`.
- `public.admin_paywall_dashboard(p_days, p_platform, p_lang)` : tout ce qu'affiche la page
  `/admin/data` du site, réservé à l'équipe (`is_studio_admin`). Les revenus viennent de
  `subscription_events` (RevenueCat, production seulement, en dollars) : ils suivent la
  période et la plateforme, pas la langue, que RevenueCat ne connaît pas.

### Synthèses d'usage et tableaux de bord

Migration `20261113060000_daily_usage_stats.sql`. Quatre tables gardées sans limite,
recalculées toutes les heures pour le jour en cours et les deux précédents :

- `public.daily_usage_stats` : par jour UTC, plateforme et langue, les utilisateurs actifs,
  les sessions, les cours ouverts, les pages lues (`section_view`), les cours terminés, les
  likes, enregistrements, partages, et les réponses de quiz (dont les bonnes).
- `public.daily_course_usage` : la même chose par cours (`daily_course_stats`, qui nourrit le
  tableau de bord des créateurs, ne connaît pas la plateforme).
- `public.daily_quiz_question_stats` : réponses et bonnes réponses par question
  (`quiz_answer`, tous contextes).
- `public.daily_duel_stats` : duels lancés, terminés et abandonnés, par type (`match` :
  adversaire tiré par le jeu ; `friend` : entre amis, compté pour celui qui lance). Les duels
  ne viennent pas d'événements de l'app mais des tables du jeu (`duel_matches`,
  `duel_friend_matches`) : le serveur connaît chaque partie. La plateforme est celle des
  événements de l'utilisateur ce jour-là, `unknown` quand son app n'en envoie pas.

Pages de l'espace équipe du site, chacune servie par une fonction réservée à l'équipe :

| Page | Fonction | Contenu |
| --- | --- | --- |
| `/admin/data` | `admin_paywall_dashboard` | paywalls, tests A/B, revenus |
| `/admin/data/onboarding` | `admin_onboarding_dashboard` | entonnoir, réponses |
| `/admin/data/usage` | `admin_usage_dashboard` | lecture, cours les plus ouverts, questions les plus ratées (à partir de 20 réponses), duels |
| `/admin/data/social` | `admin_social_dashboard` | demandes d'amis, amitiés, invitations en duel, parrainage, créateurs suivis |
| `/admin/data/feedback` | `admin_feedback_dashboard` | les retours de `app_feedback` |

`admin_social_dashboard` (migration `20261113070000_admin_social_dashboard.sql`) lit
directement `friend_requests`, `friendships`, `duel_invites`, `referrals` et `follows` : ces
tables sont gardées sans limite mais ne portent ni plateforme ni langue, la page ne suit donc
que la période. Les titres de cours et les énoncés de quiz sont lus dans `course_contents` et
`quizzes`, dans la langue filtrée, à défaut en français.

## Abonnements côté serveur

- `public.subscription_events` : les webhooks RevenueCat (fonction `revenuecat-webhook`,
  en-tête `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>`).
- `public.subscriber_snapshots` : le statut tel que l'app le connaît, envoyé à chaque
  lancement et à chaque changement (`is_active`, `period_type`, `product_id`, `store`,
  `expires_at`, `will_renew`). Il couvre les abonnés déjà actifs avant la mise en place
  du webhook.
- `public.premium_status` : vue qui combine les deux, la source la plus récente l'emporte.

## Retours envoyés depuis l'app

Le formulaire des réglages (« Envoyer un retour », « Demander une fonctionnalité ») envoie
chaque message à Formspree, qui nous prévient par e-mail et porte l'adresse de réponse. Une
fois cet envoi réussi, l'app en dépose une copie dans `public.app_feedback` (migration
`20261113030000_app_feedback.sql`) : `user_id`, `category` (`bug`, `idea`, `feature`,
`content`, `translation`, `other`), `message`, `has_email` (une adresse a été laissée ; elle
n'est pas copiée), `lang`, `platform`, `app_version`, `os_version`, `device`, `is_premium`,
`created_at`. L'app ne peut qu'insérer ses propres lignes ; la lecture se fait côté serveur.
Un échec de la copie est silencieux : le message est déjà parti.

## Piège Android : valeurs par défaut

Le client Supabase d'Android sérialise sans les valeurs par défaut (`encodeDefaults = false`).
Un champ obligatoire en base qui n'existe dans l'app que comme valeur par défaut (`platform =
"android"`) disparaît donc de la requête et fait refuser tout le lot : c'est ce qui a empêché
tout événement Android d'arriver jusqu'au 13 novembre. Un tel champ porte `@EncodeDefault`
ou n'a pas de valeur par défaut ; `AnalyticsPayloadTest` le vérifie.

## Ajouter un événement

1. L'ajouter ici, avec ses propriétés.
2. L'ajouter à la contrainte `course_events_name_check` par une migration.
3. L'ajouter à la liste des deux apps (`AnalyticsEventName` sur iOS, `Analytics.KNOWN_NAMES`
   sur Android) et l'émettre au même endroit fonctionnel sur les deux plateformes.
4. Si une synthèse doit le compter, l'ajouter à `refresh_daily_course_stats`.
