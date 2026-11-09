# Événements éditoriaux (`campaigns`)

Un **événement** est une collection de cours à lire pendant une période, un **défi** (terminer
*n* cours de la collection) récompensé par un **badge**, et des **cours annoncés** en écriture.
Movember, le 11 novembre, une semaine thématique, le lancement d'une série : même objet, même
format partout. Il se crée et se publie depuis l'admin du site, et les apps le reçoivent sans
nouvelle version.

Ce document est la référence du format. Les quatre implémentations le suivent à la lettre :

| Où | Quoi |
| --- | --- |
| `supabase/migrations/20261109000700_campaigns.sql` | table `public.campaigns`, règles d'accès, `campaigns_for_manifest()`, `campaigns_refresh_participants()` |
| `web/src/lib/studio/campaigns.ts`, `web/src/app/admin/events/` | listes fermées, validation, pages **Events** de l'admin |
| `ios/Sophia/Models/Campaign.swift`, `ios/Sophia/Services/CampaignStore.swift` | décodage, lecture depuis `CatalogStore.campaigns` |
| `android/…/domain/Campaign.kt`, `android/…/data/CampaignStore.kt` | idem |

## Le circuit

1. **Admin du site** (`/admin/events`) : l'équipe crée l'événement, choisit les cours, écrit les
   textes en anglais et en français, puis clique **Translate** pour les 28 autres langues (même
   modèle de texte que les couvertures, via fal ; une langue déjà remplie n'est jamais écrasée).
   Elle peut poser une **image** (envoi d'un fichier 16:9, ou **Generate 2 images with AI** : une
   dans la direction artistique des couvertures de cours, Gemini ; une dans celle des illustrations
   du site, Recraft en papier découpé ; les deux restent en candidates, l'équipe en retient une) et
   fixer un **objectif commun** (cours lus ensemble).
   La page montre un **aperçu de la carte du fil** telle que les apps la dessinent. Une liste de
   contrôle dit ce qui manque pour publier ; un événement s'enregistre toujours en brouillon, il
   ne passe `published` que si la liste est vide.
2. **Base** : la ligne est dans `public.campaigns`. Seuls les comptes de `studio_admins` lisent et
   écrivent la table (RLS). Les apps ne la lisent jamais directement.
3. **Manifeste du catalogue** : `catalog_manifest(lang)` porte une clé `events` (fonction
   `campaigns_for_manifest()`), avec les événements `published` dont la fin remonte à moins de
   400 jours (le badge gagné reste affiché un an). Les mêmes événements sont dans chaque manifeste,
   quelle que soit la langue : les textes portent toutes les langues. L'ETag de la fonction
   `catalog-manifest` change avec eux.
4. **Apps** : `CatalogStore` relit le manifeste au lancement, au retour au premier plan après
   `refresh_hours` (1 h aujourd'hui), au « Recharger les cours » et au tirer-pour-rafraîchir ;
   il publie `campaigns` (iOS : propriété observable ; Android : `StateFlow`). `CampaignStore`
   lit cette liste et les écrans se redessinent quand elle change. Rien n'est embarqué dans les
   apps : avant le premier manifeste il n'y a pas d'événement (`content/events/movember.json`
   reste un exemple de format, c'est lui qui a servi d'amorce à la ligne `movember-2026`).
5. **Participants et objectif commun** : toutes les heures (`cron` `campaign-participants`,
   minute 25), `campaigns_refresh_participants()` compte les lecteurs distincts ayant terminé au
   moins un cours de la collection entre le premier et le dernier jour (`participants`) et le
   nombre total de ces fins de cours (`goal_count`), depuis `course_events` (`course_complete`).
   Les événements finis depuis plus d'une semaine gardent leur dernier chiffre.

Le défi, le badge et « me prévenir » restent calculés sur le téléphone à partir des cours
terminés (`course_ids`) et d'une préférence locale ; il n'y a pas encore de `campaign_progress`
côté serveur.

## Le format

Clés en `snake_case`, identiques dans la table, le manifeste et les décodeurs des apps.

| Clé | Type | Règle |
| --- | --- | --- |
| `slug` | texte | identifiant stable, `^[a-z0-9]+(-[a-z0-9]+)*$`, 3 à 60 caractères (`movember-2026`). C'est l'adresse de l'événement dans les apps. |
| `kind` | texte | le type standard, voir ci-dessous. Réservé côté apps (elles n'en font rien encore). |
| `status` | texte | `draft` (invisible des apps), `published` (servi), `archived` (retiré, gardé). Le manifeste ne porte que `published` ; la clé n'est pas envoyée aux apps. |
| `symbol` | texte | un nom de la liste standard ci-dessous (SF Symbols ; Android a l'icône Material correspondante). |
| `image_url` | texte ou null | image 16:9 hébergée (`course-images/events/…`), en tête de la carte du fil et de la page ; sans elle la carte reste bleu nuit avec le symbole. Envoyée depuis l'admin ou générée (même direction artistique que les couvertures). |
| `starts_at`, `ends_at` | `YYYY-MM-DD` | premier et dernier jour, inclus, en date civile du téléphone. `ends_at ≥ starts_at`. |
| `challenge_target` | entier | 1 à 50, au plus le nombre de cours de la collection. |
| `participants` | entier | calculé (voir ci-dessus) ; jamais saisi. |
| `goal_target` | entier ou null | l'objectif commun : cours de la collection à terminer, tous lecteurs confondus, pendant l'événement. Null : pas de barre d'objectif. |
| `goal_count` | entier | où en est l'objectif commun ; calculé toutes les heures, jamais saisi. |
| `image_candidates` | liste | côté admin seulement (pas dans le manifeste) : les images générées, `{url, style: cover \| poster, created_at}`, huit au plus. |
| `course_ids` | liste | les cours de la collection, 40 au plus, tous `published`. L'ordre est celui de l'affichage. |
| `upcoming` | liste | cours annoncés : `{"title": {langue: texte}, "creator": slug ou null, "date": "YYYY-MM-DD"}`, six au plus dans l'admin. |
| `title` | `{langue: texte}` | 60 caractères. |
| `tagline` | `{langue: texte}` | 90 caractères, la phrase sous le titre. |
| `description` | `{langue: texte}` | 300 caractères, le paragraphe de la page. |
| `badge_name` | `{langue: texte}` | 40 caractères, un ou deux mots. |

Les textes par langue : l'anglais est obligatoire pour publier ; les apps retombent sur
l'anglais, puis le français, puis la première valeur présente. Les codes sont ceux des apps
(`fr`, `en`, `pt-PT`, `nb`…, voir `LANGS` dans `web/src/lib/catalog/types.ts`).

### Les types (`kind`)

| `kind` | Pour quoi | Durée attendue |
| --- | --- | --- |
| `month` | un mois autour d'une cause ou d'un thème (Movember, Black History Month) | 20 à 62 jours |
| `week` | une semaine autour d'un thème ou d'un anniversaire | 5 à 14 jours |
| `day` | une date (11 novembre, 8 mars) avec quelques jours d'approche | 1 à 10 jours |
| `series` | le lancement d'une collection ou d'un nouvel auteur, étalé sur quelques semaines | 7 à 90 jours |

La durée hors de la fourchette n'empêche pas d'enregistrer, elle empêche de publier (liste de
contrôle de l'admin). Ajouter un type : la contrainte SQL, `CAMPAIGN_KINDS` côté web, et ce
tableau.

### Les symboles (`symbol`)

`mustache.fill` · `heart.fill` · `star.fill` · `flame.fill` · `leaf.fill` ·
`globe.europe.africa.fill` · `book.fill` · `flag.fill` · `sparkles` · `drop.fill` ·
`sun.max.fill` · `moon.fill` · `graduationcap.fill` · `brain.head.profile` · `figure.run` ·
`music.note` · `paintpalette.fill` · `building.columns.fill` · `snowflake` · `gift.fill` ·
`trophy.fill` · `atom`.

iOS affiche le symbole SF tel quel ; Android le traduit dans `CampaignSymbol`
(`NewGenComponents.kt`) : la moustache est dessinée à la main, les autres sont des icônes
Material, un nom inconnu retombe sur les étincelles. Ajouter un symbole : la contrainte SQL,
`CAMPAIGN_SYMBOLS` côté web, le `when` Android, cette liste.

## Exemple (ce que le manifeste envoie)

```json
{
  "slug": "movember-2026",
  "kind": "month",
  "symbol": "mustache.fill",
  "image_url": "https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/events/movember-2026_m3k1.jpg",
  "starts_at": "2026-11-01",
  "ends_at": "2026-11-30",
  "challenge_target": 3,
  "participants": 0,
  "goal_target": 10000,
  "goal_count": 0,
  "course_ids": ["course_228_la_sante_mentale_comme_enjeu_de_societe", "course_42_pourquoi_reve_t_on", "course_73_comment_le_cerveau_stocke_t_il_les_souve"],
  "upcoming": [{ "title": { "en": "Why do men see a doctor less often?", "fr": "Pourquoi les hommes vont-ils moins chez le médecin ?" }, "creator": "ezgi-gizem-berkay", "date": "2026-11-14" }],
  "title": { "en": "Movember", "fr": "Movember" },
  "tagline": { "en": "Men's health, let's talk about it.", "fr": "La santé des hommes, on en parle." },
  "description": { "en": "Mental health, prevention, male cancers: a month to talk about it, one course at a time.", "fr": "Santé mentale, prévention, cancers masculins : un mois pour en parler, un cours à la fois." },
  "badge_name": { "en": "Moustache", "fr": "Moustache" }
}
```

## Dans les apps

- **Fil « Pour toi »** : l'événement actif le plus proche de sa fin est une carte en troisième
  position (image en tête si elle existe, barre du défi, barre de l'objectif commun) ; les cartes
  des cours de sa collection portent son étiquette.
- **Page événement** : image, symbole, dates, titre, description, participants, objectif commun,
  la collection avec la progression du défi, les cours annoncés avec « me prévenir ».
- **Textes** : la barre de l'objectif commun lit `event.goal.progress` (« Ensemble : %@ cours lus
  sur %@ »), présent dans les 30 langues des deux apps ; l'image est téléchargée une fois et gardée
  en cache (iOS `RemoteImage`, Android Coil).
- **Profil** : le badge (nom, progression *n*/objectif) du dernier événement ; le bloc
  « événement en cours ».
- **Page créateur** : « en écriture pour … » si l'auteur a un cours annoncé dans un événement actif.
- **Mesure** : `course_open` avec `source = event` quand un cours est ouvert depuis la page
  événement (docs/events.md).

Un événement mal formé dans le manifeste (champ manquant, mauvais type) est ignoré par les deux
apps, jamais au prix du catalogue : iOS décode la liste élément par élément, Android donne une
valeur par défaut à chaque champ et écarte les lignes sans slug ni dates.

## Vérifier

```sql
select jsonb_pretty(public.catalog_manifest('fr') -> 'events');   -- ce que les apps recevront
select slug, status, participants from public.campaigns;
select public.campaigns_refresh_participants();                    -- recompte tout de suite
```

Sur le téléphone : Réglages → À propos → **Recharger les cours** (ou tirer la liste Explorer
vers le bas), puis l'onglet Accueil.
