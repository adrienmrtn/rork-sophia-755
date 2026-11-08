# Le catalogue de cours en ligne

Depuis le prompt 3, les cours ne sont plus compilés dans les apps : ils vivent dans Supabase et les
apps les téléchargent. Un cours ajouté ou corrigé en base apparaît sur iOS et Android sans build.
Le format des blocs V2, les identifiants de cours (`course_NN_…`), de sections (`<courseId>_intro`,
`_p1`…) et de questions (`<courseId>_qN`) ne changent pas : la progression, le Parcours et
l'Entraînement des lecteurs continuent sans migration.

## Source de vérité : `content/`

| Dossier ou fichier | Contenu |
| --- | --- |
| `content/courses/<lang>/<courseId>.json` | le contenu V2 d'un cours dans une langue (30 langues × 309 cours) |
| `content/locales/<lang>/quizzes_v2.json` | les questions par cours |
| `content/glossary/<lang>.json` | `"<courseId>\|<terme>"` → `{displayTerm, classification, explanation}` |
| `content/collections/collections.json` | l'ordre des collections du Parcours, leur couverture et leurs cours |
| `content/collections/<lang>.json` | titre et description traduits de chaque collection |
| `content/authors.json` | les créateurs (`title` et `bio` par langue) |
| `content/image_credits.json`, `content/course_image_map.json` | crédits des images, couverture de chaque cours |
| `content/catalog_withheld.json` | cours non distribués dans une langue (`by_language`) ou une région (`by_region`) |

La gate de traduction (`scripts/i18n_gate.py`) lit `content/` et vérifie que les packs de départ
embarqués en sont des copies fidèles.

## Serveur (Supabase, projet `afnmcoovdvbtkgohtdij`)

Migration `supabase/migrations/20261108180000_online_catalog.sql`.

- `creators` : slug, nom, photo, institution, pays, liens, `title` et `bio` par langue (jsonb), `verified`,
  `photo_url` : le portrait hébergé d'un créateur du Studio (copie faite par l'usine dans
  `course-images/author_<slug>.jpg`), servi aux apps sous la clé `photoUrl` du catalogue et affiché
  quand le créateur n'a pas de photo embarquée.
- `courses` : identité d'un cours indépendante de la langue : `subject`, `creator_slug`, `status`
  (draft, published, archived), `tier`, `origin_lang`, `cover_slug`, `published_at`.
- `course_contents` (`course_id`, `lang`) : le contenu V2 complet (`content` jsonb), titre,
  description, sous-catégorie, accroche, `section_ids`, `status` (published ou withheld pour la
  langue), et `hash` : les 16 premiers hexas du sha256 du **paquet** servi aux apps.
- `quizzes` (`course_id`, `lang`) : les questions ; `glossary_entries` (`course_id`, `lang`, `term`).
- `collections`, `collection_courses`, `collection_translations` : le Parcours. `sort_index` est
  l'ordre des niveaux : il verrouille la progression des lecteurs, ne pas le changer à la légère.
- `course_assets` : couverture, images des blocs et audio d'un cours, avec leur crédit.
- `catalog_files` (`lang`, `kind`) : le hash des trois fichiers par langue.
- `app_config` : `catalog` → `{"enabled": true, "refresh_hours": 6, "share": 1.0}`.

RLS : lecture publique (anon et authentifié) de ce qui est publié ; écriture réservée à la clé
service (import, puis la fonction `publish-course` du prompt 4).

### Ce que les apps téléchargent

Bucket public `course-content` (cache immuable, le hash est dans le nom) :

- `<lang>/catalog.<hash>.json` : tous les cours publiés de la langue (métadonnées, sections sans le
  texte, accroche, couverture, créateur, nombre de questions), les collections, les créateurs ;
- `<lang>/quizzes.<hash>.json` : `{"<courseId>": [questions]}` ;
- `<lang>/glossary.<hash>.json` : même format que `content/glossary/<lang>.json` ;
- `<lang>/courses/<courseId>.<hash>.json` : le **paquet** d'un cours, tout ce qu'il faut pour le
  lire hors ligne : `{id, lang, hash, content, quiz, glossary, credits}`.

Le manifeste d'une langue : `GET /functions/v1/catalog-manifest?lang=fr` (Edge Function
`supabase/functions/catalog-manifest`, appuyée sur la fonction SQL `catalog_manifest(lang)`), avec
`Cache-Control: max-age=300` et un ETag (`If-None-Match` → 304). Il liste les trois fichiers et le
paquet de chaque cours publié, avec leur hash et leur chemin dans le bucket.

### Importer le catalogue

```bash
export SUPABASE_URL=https://afnmcoovdvbtkgohtdij.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=…      # Project Settings → API Keys → service_role
python3 scripts/import_catalog_to_supabase.py            # tables + Storage + packs de départ
python3 scripts/import_catalog_to_supabase.py --verify   # compte ce qui est en base
```

Idempotent : un cours dont le paquet a le même hash n'est ni réécrit ni retéléversé. Le script
régénère aussi les packs de départ des deux apps (`--starter-pack-only` pour ne faire que ça).
Pour publier une correction : modifier `content/`, relancer l'import ; le manifeste change, les
apps téléchargent le nouveau paquet au prochain rafraîchissement (au plus six heures) ou à la
prochaine ouverture du cours.

## Dans les apps

Même architecture des deux côtés (`ios/Sophia/Services/Catalog/CatalogStore.swift`,
`android/…/data/catalog/CatalogStore.kt`), trois couches consultées dans l'ordre :

1. **la mémoire** : un snapshot par langue (cours avec leurs sections et leur quiz, collections,
   créateurs, glossaire) et les paquets déjà décodés ;
2. **le cache disque** (Application Support/Catalog sur iOS, `filesDir/catalog` sur Android,
   exclus des sauvegardes) : le dernier manifeste, les trois fichiers de la langue, un paquet par
   cours téléchargé ;
3. **le pack de départ embarqué** (`Resources/StarterPack/<lang>/`, `assets/starter_pack/<lang>/`) :
   le catalogue complet de la langue et les 40 premiers cours du Parcours avec leur quiz et leur
   glossaire, pour que l'app ait toujours quelque chose à montrer, même sans réseau et avant le
   premier rafraîchissement. Environ 30 Mo pour les 30 langues, contre 164 Mo de bundles avant.

Les API des anciens chargeurs (`ContentCatalog`, `CourseContentStore`, `LocalizedContentLoader`,
`AuthorStore`, `CollectionData`, `GlossaryStore`) sont restées : elles lisent le snapshot et
n'attendent jamais le réseau. Le manifeste est relu au lancement et au retour au premier plan si
le dernier date de plus de `refresh_hours` ; seuls les fichiers dont le hash a changé sont
téléchargés, et un fichier n'est écrit que s'il se décode. Le paquet d'un cours se télécharge à
l'ouverture du lecteur (état « Téléchargement du cours… », ou « pas encore sur ton téléphone »
hors ligne) et en avance pour les premières cartes du fil. Un cours déjà ouvert se relit en mode
avion.

`app_config.catalog.enabled = false` est le coupe-circuit : plus aucun appel réseau, les apps
vivent sur le disque et le pack. (`share` est lu mais n'est plus un pourcentage de déploiement :
le catalogue complet n'étant plus embarqué, un lecteur « hors part » n'aurait que 40 cours.)

Réglages → section développeur → « Catalogue en ligne » montre la source du snapshot, le nombre
de cours sur le téléphone et la date du dernier rafraîchissement ; un tap force le
rafraîchissement.

## Scripts

- `scripts/import_catalog_to_supabase.py` : l'import et les packs de départ (ci-dessus).
- `scripts/build_courses.py` : valide `content/courses` et régénère les packs de départ ; il
  n'écrit plus `Resources/CoursesV2`.
- `scripts/export_ios_content_for_android.py` : n'exporte plus que les textes d'interface, les
  photos des auteurs et la carte des images de blocs.
- Les anciens générateurs de bundles (`add_courses_to_catalog.py`, `slim_*_catalogs.py`,
  `sync_locale_catalog_titles.py`, `translate_locale_catalog.py`) ne sont plus dans la chaîne :
  leurs sorties n'existent plus dans les apps.

## Le pont avec le Studio et l'usine

Depuis le prompt 4, un cours peut aussi arriver par le Studio (sophia-culture.com) : l'Edge
Function `publish-course` valide le cours dans sa langue d'origine, l'écrit en base
(`catalog_upsert_course`) et crée un job de production (`production_jobs`, `production_steps`).
`jobs_dispatch` (pg_cron toutes les cinq minutes, ou `POST /jobs-dispatch`) l'envoie à GitHub
Actions (`.github/workflows/produce-course.yml`, `scripts/produce_course.py`), qui traduit, relit
et vérifie chaque langue avec les mêmes portes que ce dépôt, écrit le quiz et le glossaire, publie
langue par langue et pousse les fichiers produits dans `content/`. Le Studio suit l'avancement par
`GET /publish-course?job_id` ou par webhook, et lit les chiffres dans `course-stats-export`.
Contrat complet, secrets et essai de bout en bout : `docs/publish-contract.md` ; migration
`supabase/migrations/20261108200000_production_pipeline.sql`.

## Points de vigilance

- La progression d'un cours est indexée par position de section (`lastLessonIndex`) : réordonner
  ou supprimer une section décale la reprise. Le lecteur borne l'index, mais une telle
  modification reste à éviter sur un cours déjà lu.
- Les ids de questions alimentent l'Entraînement : renommer une question la fait disparaître des
  révisions ; corriger son texte, oui, changer son id, non.
- Les couvertures d'un cours arrivé après le build ne sont pas dans le bundle iOS : la carte du
  fil les prend dans le bucket `course-images` d'après `cover` du catalogue ; les autres écrans
  montrent l'icône de la matière en attendant que la carte embarquée soit régénérée.
