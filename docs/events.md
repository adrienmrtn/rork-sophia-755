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
  conservée 60 jours. Synthèse quotidienne dans `public.daily_course_stats` (pour
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
| `algo_version` | version de l'algorithme qui a produit le fil (`local-v1`, puis `local-v2` depuis que la tête de fil des nouveaux lecteurs est tirée parmi les meilleurs cours de chaque matière ; le fil est calculé sur le téléphone, réglé par `app_config.home_deck`) |
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
lignes au plus par installation. Le brut est gardé 60 jours.

Questions (`question` → `answer`) :

| `question` | Écran | `answer` |
| --- | --- | --- |
| `age` | `age` | une tranche : `under18`, `18to24`, `25to34`, `35to44`, `45to54`, `55plus`. Jamais un âge exact |
| `gender` | `gender` | `man`, `woman` ou `undisclosed` (« je préfère ne pas répondre ») |
| `knowledge` | `knowledge` | `0` à `3`. Aucun niveau n'est présélectionné : la réponse est toujours un choix |
| `motivation` | `motivation` | `grow`, `conversations`, `career`, `sharp`, `world` |
| `objectives` | `objective` | choix multiples : les clés triées, séparées par des virgules (`cultivate,exams`) |
| `topics` | `topics` | choix multiples, même forme (clés de matière) |
| `phone_time` | `phone_time` | minutes par jour (`180`) |
| `swipe_liked`, `swipe_passed` | `swipe_courses` | les cours gardés et ceux écartés dans le swipe, par leur numéro (`course_42_…` → `42`), triés, séparés par des virgules (`42,150`). Une liste vide n'est pas envoyée |
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

Test `checkout_cancel_ab` (Android) : que se passe-t-il quand la feuille de paiement Google
est refermée sans achat. Variante `control` : retour au paywall ; variante `offer` : le
paywall de l'offre flash s'ouvre aussitôt. Réglage dans `public.app_config`, clé
`checkout_cancel_ab` : `{"enabled": true, "share_offer": 0.5, "default_variant": "control"}`
(sans ligne : test actif, moitié-moitié). Le premier abandon d'une présentation, pour une
personne à qui l'offre flash pouvait être montrée (pas Premium, offre moins chère que son prix
normal, offre du jour pas encore consommée), est l'exposition : son `purchase_failed`
(`reason` : `cancelled`) porte `cancel_test` (`checkout_cancel_ab`) et `cancel_variant`,
dans les deux variantes. Les événements du paywall de réduction ouvert de cette façon portent
`trigger` : `checkout_cancel`. Cette offre ne consomme pas le cadeau du jour : il arrive
toujours au troisième swipe, avec le compte à rebours en cours s'il tourne encore, avec un
nouveau sinon ; un abandon n'ouvre l'offre qu'une fois par jour. Ces clés sont distinctes de `experiment` / `variant` pour ne
pas découper `daily_paywall_stats` ; le test se lit dans `course_events`.

Offre flash et expériences de prix : l'offre RevenueCat servie (la « courante ») peut nommer
l'offre flash qui va avec elle, par la métadonnée `promo_offering` (identifiant d'une offre,
ou `none` pour aucune offre flash). Sans métadonnée, c'est le tirage `discount_bucket` qui
choisit, comme avant. L'app ne montre jamais une offre flash dont l'annuel coûte autant ou
plus que l'annuel normal du client.

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
  `impressions` et `card_opens` (migration `20261116020000`) comptent les cartes affichées
  dans le fil et celles ouvertes depuis le fil : leur rapport, le taux d'ouverture, dit si un
  cours attire, là où le nombre d'ouvertures dit surtout s'il a été montré.
- `public.daily_version_usage` : l'usage par plateforme, version de l'app et langue
  (tableau « By app version » de la page d'usage).
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
| `/admin/data/retention` | `admin_cohort_retention` | rétention par cohorte d'inscription, « a appris » et « a rouvert l'app » : J0, J+1, J+3, J+7, J+14, J+30 |
| `/admin/data/social` | `admin_social_dashboard` | demandes d'amis, amitiés, invitations en duel, parrainage, créateurs suivis |
| `/admin/data/feedback` | `admin_feedback_dashboard` | les retours de `app_feedback` |
| `/admin/data/health` | `admin_data_health` | santé de la collecte : volume reçu, taille du journal, tâches planifiées |

`admin_social_dashboard` (migration `20261113070000_admin_social_dashboard.sql`) lit
directement `friend_requests`, `friendships`, `duel_invites`, `referrals` et `follows` : ces
tables sont gardées sans limite mais ne portent ni plateforme ni langue, la page ne suit donc
que la période. Les titres de cours et les énoncés de quiz sont lus dans `course_contents` et
`quizzes`, dans la langue filtrée, à défaut en français.

### Rétention par cohorte

Migrations `20261116010000_cohort_retention.sql` et `20261116050000_cohort_retention_split.sql`.
`public.daily_cohort_retention`, gardée sans limite : une ligne par jour UTC de création de
compte (`auth.users.created_at`). Deux mesures qui ne se mélangent pas :

- **a appris** (`learned_0`, `learned_1`… `learned_30`) : le compte a gagné de l'XP
  (`xp_events`) le jour de l'inscription, puis exactement 1, 3, 7, 14 et 30 jours plus tard.
  Toutes versions de l'app, depuis juillet 2026 : c'est la mesure comparable dans le temps.
- **a rouvert l'app** (`reopened_1`… `reopened_30`) : l'app a envoyé un événement
  (`course_events`) ce jour-là. Seules les versions récentes en envoient : la part se calcule
  parmi les comptes suivis (`tracked`, ceux dont l'app a envoyé un événement le jour de
  l'inscription), pas parmi tous les inscrits.

`refresh_recent_cohort_retention()` recalcule toutes les heures (tâche
`daily_cohort_retention`) les cohortes des 31 derniers jours. `admin_cohort_retention(p_days)`
sert la page `/admin/data/retention` : un jalon n'est rendu que lorsque son jour est terminé,
et chaque total porte sa propre base. Les colonnes `d0`…`d30` et `admin_retention_dashboard`
sont celles de la première version (XP ou événement confondus) ; plus rien ne les lit.

### Filtre par version de l'app

Migration `20261116030000_data_version_filter.sql`. `daily_paywall_stats`,
`daily_onboarding_stats`, `daily_usage_stats`, `daily_course_usage` et
`daily_quiz_question_stats` portent `app_version` dans leur clé ; les fonctions
`admin_paywall_dashboard`, `admin_onboarding_dashboard`, `admin_usage_dashboard` et
`admin_feedback_dashboard` prennent `p_version` et renvoient `versions` (plateforme et
version connues). Sur le site, choisir une version choisit aussi sa plateforme. Ne suivent
pas la version : les revenus (RevenueCat), les duels, les amis et la rétention, dont la
source ne la connaît pas.

### Réglage du fil d'accueil

`app_config`, clé `home_deck` : `{"head_pool": 5, "exploration_every": 4}`, lu au lancement
par les apps (`HomeDeckConfig`, iOS et Android, algorithme `local-v2`) ; la dernière valeur
connue sert hors ligne. `head_pool` : pour un lecteur qui n'a encore terminé aucun cours,
chaque carte est tirée parmi ce nombre de meilleurs cours de sa matière (à 1, toujours le
meilleur, donc la même tête de fil pour tous les nouveaux comptes). `exploration_every` : une
carte sur N est tirée au hasard hors de la matière dominante. Bornes : 1 à 20 et 2 à 20.

### Conservation et santé de la collecte

Migration `20261113080000_retention_60_days_and_health.sql`.

- Les deux journaux bruts (`course_events`, `onboarding_events`) sont gardés **60 jours** ;
  toutes les tables `daily_*` sont gardées sans limite. À plein régime, ce sont les journaux
  qui remplissent le disque : la durée se change dans `ensure_course_events_partitions` et
  `refresh_recent_onboarding_stats`.
- `public.daily_event_volume` : événements reçus par jour UTC, plateforme, version de l'app
  et nom, recalculé toutes les heures avec l'usage.
- `public.admin_data_health()` : taille de la base et du journal (lues dans le catalogue de
  Postgres, sans comptage), volume des trente derniers jours, répartition par événement et
  par version, dernier passage de chaque tâche planifiée. La page en tire ses alertes
  (`web/src/lib/studio/health.ts`) : tâche en échec ou arrêtée, plateforme qui n'envoie plus
  rien, base qui approche la taille recommandée pour sa machine.

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

La page `/admin/data/feedback` montre sous chaque message sa traduction française
(migration `20261116040000`, colonne `app_feedback.message_fr`) : le site la fait écrire par
le modèle de texte de fal à la première lecture, puis la garde. Vide : le message était déjà
en français.

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
