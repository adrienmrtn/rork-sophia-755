# Le pont Studio ↔ app : publier un cours, suivre sa production, lire ses statistiques

Le Studio (sophia-culture.com) envoie un cours dans sa langue d'origine ; l'app le produit dans
ses 30 langues (traductions, quiz, glossaire, couverture, audio), le publie langue par langue et
renvoie des statistiques. Trois Edge Functions Supabase (projet `afnmcoovdvbtkgohtdij`), une usine
GitHub Actions, un webhook.

```
Studio ──POST /publish-course──▶ validation, écriture du cours d'origine, job « queued »
                                       │  pg_cron (5 min) ou POST /jobs-dispatch
                                       ▼
                        GitHub Actions « Produce course » (scripts/produce_course.py)
                        glossary → quiz → cover → translate+gate ×29 → publish → audio → commit content/
                                       │  à chaque étape : webhook job-step ; à la fin : job-done
                                       ▼
Studio ◀──GET /publish-course?job_id──  état du job      Studio ◀──GET /course-stats-export── chiffres
```

Base des fonctions : `https://afnmcoovdvbtkgohtdij.supabase.co/functions/v1/`. Toutes les
requêtes portent l'en-tête `x-api-key: <PUBLISH_API_KEY>` (secret de la fonction, voir
[Configuration](#configuration)). Sans en-tête : `401 {"error":"unauthorized"}`.

## POST /publish-course

Corps JSON :

```jsonc
{
  "kind": "course",                 // "video" → 501 jusqu'au prompt 10
  "origin_lang": "fr",              // une des 30 langues de l'app
  "requested_by": "studio",         // libre (compte du Studio, par exemple)
  "course": {                       // le cours V2 dans sa langue d'origine (CHARTE_REFONTE §4)
    "id": "course_310_…",           // omis pour un nouveau cours : l'app attribue course_<n>_<slug>
    "title": "…", "subtitle": "1503",
    "subject": "art",               // histoire | sciences | litterature | art | mythologie | comprendreLeMonde
    "subcategory": "Œuvres iconiques",
    "description": "…",             // 20 à 600 caractères, l'accroche de la carte
    "hero": { "image": "slug_du_bucket", "image_url": "https://…", "ratio": "16:9", "hook": "…",
              "credit": { "title": "…", "author": "…", "license": "CC BY-SA 4.0", "source": "Wikimedia Commons" } },
    "sections": [ { "id": "…", "title": "Introduction", "free": true, "blocks": [ … ] }, … ],  // 2 à 12
    "sources": [ { "text": "…", "url": "https://…" } ],
    "glossary": [ { "term": "Sfumato", "classification": "concept", "explanation": "…" } ]
  },
  "creator": { "slug": "dusan-nikolic", "name": "Dušan Nikolić", "title": "…", "bio": "…",
               "photo_url": "https://…", "institution": "…", "country": "RS", "links": {}, "verified": true },
  "quiz": [ … ],                    // facultatif : 6 à 10 questions (CHARTE_QUIZ §3) ; sinon l'usine les écrit
  "options": { "languages": ["en", "es"], "skip_audio": false }   // facultatif : par défaut les 29 autres langues
}
```

Quand `languages` est un sous-ensemble, l'usine inscrit les langues non demandées dans
`content/catalog_withheld.json` (cours non distribué dans ces langues) : la porte de traduction
ne réclame pas ces copies, l'import ne les attend pas. Un job ultérieur qui produit une de ces
langues (« Translate into more languages » dans l'admin) l'en retire.

Blocs admis : `heading`, `paragraph`, `image`, `timeline`, `funFact`, `takeaway`, `quote`, avec
les champs de la charte. Un bloc `image` porte `asset` (slug d'un objet du bucket `course-images`)
ou `image_url` (https ; l'usine importe l'image et fixe le slug). Dans les textes : `**gras**`,
`[[Terme]]` équilibrés, pas de tiret cadratin, un seul `takeaway`. Un `[[Terme]]` sans entrée dans
`course.glossary` est accepté : l'usine écrit l'entrée manquante.

Réponses :

| Code | Corps | Sens |
| --- | --- | --- |
| 202 | `{course_id, job_id, status: "queued", origin_lang, languages, content: {hash, bytes…}, steps}` | reçu, cours d'origine écrit, job en file |
| 400 | `{error: "invalid", errors: ["sections[2].blocks[0].text : …", …]}` | la charte n'est pas respectée ; chaque ligne nomme le champ |
| 400 | `{error: "bad_json"}` | corps illisible |
| 401 | `{error: "unauthorized"}` | clé absente ou fausse |
| 500 | `{error: "upsert_failed" \| "job_failed" \| …, detail}` | erreur serveur, à remonter |
| 501 | `{error: "not_implemented"}` | `kind: "video"` |

Identifiants : `course_<n>_<slug>` (slug du titre, sans accents, 48 caractères au plus), sections
`<courseId>_intro`, `<courseId>_p1`…, questions `<courseId>_q1`… Ils ne changent jamais : la
progression, le Parcours et l'Entraînement des lecteurs s'y accrochent.

Nouveau cours : il a le statut `in_production` et n'est visible dans aucune langue tant que l'usine
n'a pas livré son quiz et son glossaire ; il passe `published` dans sa langue d'origine dès ces deux
étapes, puis dans chaque langue qui passe la porte. Cours existant (même `id`) : le texte d'origine
est remplacé tout de suite dans sa langue, les autres langues gardent leur édition courante jusqu'à
la nouvelle, et seuls les segments dont le texte d'origine a changé sont retraduits ; un quiz non
fourni est conservé (ids inchangés) et revérifié contre le nouveau texte.

## GET /publish-course?job_id=…

```jsonc
{
  "job": { "id", "course_id", "origin_lang", "kind", "status", "summary", "error", "options",
           "created_at", "dispatched_at", "started_at", "finished_at" },
  "steps": [ { "step": "translate", "lang": "en", "status": "done", "detail": {…}, "started_at", "finished_at" }, … ]
}
```

Statuts du job : `queued` (en file), `dispatched` (envoyé à GitHub), `running`, puis `done`
(tout a passé), `partial` (au moins une étape a échoué, le reste est publié) ou `failed`. Statuts
d'une étape : `pending`, `running`, `done`, `failed`, `skipped`. Étapes : `glossary`, `quiz`,
`cover` (sans langue), `translate` et `gate` (par langue cible), `publish`, `audio` (`fr`, `en`).
`detail` porte ce qui s'est passé : nombre de questions et questions rejetées pour `quiz`, segments
retraduits ou réutilisés pour `translate`, constats de la porte pour `gate` (`findings`), langues
publiées et retenues pour `publish`. `summary` du job, à la fin : `published`, `failed` (constats par
langue), `quiz`, `glossary_entries`, `cover`, `audio`, `commit`, `llm` (appels et jetons).

404 si le job n'existe pas.

## POST /jobs-dispatch

Envoie tout de suite les jobs en file à GitHub Actions au lieu d'attendre le passage de pg_cron
(toutes les cinq minutes). Rend `{"dispatched": n, "queued": m}` ; `{"dispatched": 0, "error":
"github_dispatch_token absent du Vault"}` tant que le jeton n'est pas posé.

## Webhooks vers le Studio

Si `app_config.studio.webhook_url` est renseignée, Supabase (pg_net) envoie un POST JSON à chaque
changement d'étape et à la fin du job, avec l'en-tête `x-api-key` = secret Vault
`studio_webhook_secret` (vide s'il n'est pas posé). Le Studio répond 2xx ; une réponse lente ou
absente n'arrête rien (délai 8 s, pas de relance).

```jsonc
{ "event": "job-step", "job_id": "…", "course_id": "…", "step": "gate", "lang": "de",
  "status": "done", "detail": { "findings": [], "count": 0, "repairs": 1 }, "at": "2026-11-08T20:01:02Z" }

{ "event": "job-done", "job_id": "…", "course_id": "…", "status": "partial",
  "summary": { "published": ["fr", "en", …], "failed": { "he": ["…"] }, … }, "error": null,
  "steps": [ { "step": "quiz", "lang": null, "status": "done" }, … ], "at": "…" }
```

## GET /course-stats-export

Paramètres : `days` (fenêtre glissante, 1 à 365, défaut 90), `month` (`AAAA-MM`, défaut le mois
courant), `course_id`, `creator` (slug : ne garde que ses cours). Réponse mise en cache cinq minutes.

```jsonc
{
  "generated_at": "…", "window_days": 90,
  "courses": [ {
    "course_id": "course_149_la_joconde", "lang": "fr",
    "impressions": 12840, "opens": 1930, "completes": 1210, "completes_per_1000_impressions": 94.2,
    "likes": 310, "saves": 88, "shares": 12, "readers": 1702, "followers_gained": 41,
    "sections": [ { "index": 0, "viewers": 1930, "reach": 1.0 }, { "index": 1, "viewers": 1702, "reach": 0.882 }, … ]
  } ],
  "premium": {
    "minutes": { "month": "2026-11", "total_minutes": 48210.5,
                 "creators": [ { "creator": "dusan-nikolic", "minutes": 9120.0, "readers": 412, "share": 0.1892 } ] },
    "revenue": { "month": "2026-11", "currency": "USD", "gross": 1196.85, "net": 906.36, "transactions": 44,
                 "by_type": { "INITIAL_PURCHASE": 15, "RENEWAL": 29 } }
  }
}
```

Définitions. Par cours et par langue, sur la fenêtre (agrégats `daily_course_stats`) :
`impressions` (cartes vues dans le fil), `opens` (lecteur ouvert), `completes` (cours terminé),
`completes_per_1000_impressions`, `likes`, `saves`, `shares`, `readers` (lecteurs distincts) ;
`followers_gained` = abonnements moins désabonnements déclenchés depuis le cours (événements
`follow`/`unfollow` portant `course_id` : lecteur, fiche, écran de fin) ; `sections[].reach` = part
des ouvertures qui a affiché la section (événements `section_view`), le décrochage se lit dans la
décroissance. Par créateur et par mois : `minutes` de lecture des abonnés Premium (`premium_status`
`paid` ou `trial`), lectures plausibles seulement : 5 s à 10 min retenues par section, 60 min au plus
par lecteur, par créateur et par jour, et jamais les lectures du créateur sur ses propres cours
(`creators.user_id`) ; `share` est la part du créateur dans le total du mois. `revenue` : prix en
USD des achats et renouvellements du mois (webhooks RevenueCat hors sandbox) × part reversée
(`takehome_percentage`, 85 % par défaut) ; `net` est la base de la répartition.

Fonctions SQL sous-jacentes (service_role) : `course_stats_export(days, course_id)`,
`creator_premium_minutes(month)`, `creator_premium_revenue(month)`, `course_stats_bundle(…)`.

## L'usine

`.github/workflows/produce-course.yml` → `scripts/produce_course.py --job <id>`, un job à la
fois. Deux fournisseurs de modèle, choisis d'après les secrets présents (ou `PRODUCTION_PROVIDER`) :
l'API Anthropic (`ANTHROPIC_API_KEY`, défaut `claude-opus-5-5`, sorties JSON contraintes par schéma,
repli serveur sur refus activé, `PRODUCTION_FALLBACKS=off` pour le couper) ou fal-ai/any-llm
(`FAL_API_KEY`, défaut `anthropic/claude-sonnet-4.5`, JSON demandé dans le prompt et vérifié à la
lecture ; autres valeurs possibles : `openai/gpt-5-chat`, `google/gemini-2.5-pro`,
`anthropic/claude-haiku-5.5`…). `PRODUCTION_MODEL` change le modèle dans les deux cas.

1. **glossary** : les entrées du Studio, complétées pour chaque `[[terme]]` sans entrée.
2. **quiz** : celui du Studio, ou l'existant pour une mise à jour, ou écrit par le modèle (6 à 10
   questions, chacune citant la section qui la justifie) ; un second appel « à livre ouvert »
   vérifie chaque réponse contre le texte et retire les questions non justifiées ; moins de six
   questions vérifiées, le job échoue.
3. **cover** : import des `image_url` dans `course-images` (JPEG, 1600 px au plus).
4. **translate** par langue, quatre en parallèle, le français d'abord quand il n'est pas l'origine :
   traduction avec `content/TRANSLATION_GUIDE_<LANG>.md`, la terminologie imposée
   (`content/terminology/`) et le glossaire du cours dans le prompt ; relecture native adverse ;
   puis **gate** : `check_course_translation.check_course`, terminologie (`check_terminology`),
   structure (marqueurs, quiz, glossaire). Un constat déclenche une réparation à partir des constats
   (deux au plus). Zéro constat : la langue passe.
5. **publish** : `catalog_upsert_course(…, 'published')` puis `catalog_finalize_language` pour
   chaque langue qui passe ; une langue retenue est écrite `failed` (invisible dans les apps) et
   inscrite dans `content/catalog_withheld.json`. `courses.status` passe `published`.
6. **audio** (`fr`, `en`) : narration ElevenLabs quand `ELEVENLABS_API_KEY` et
   `ELEVENLABS_VOICE_<LANG>` sont posés, téléversée dans `course-audio/<lang>/<courseId>.mp3` avec
   le manifeste ; sinon `skipped`.
7. **commit** : `content/courses/<lang>/`, `content/locales/<lang>/quizzes_v2.json`,
   `content/glossary/<lang>.json`, `content/courses/index.json`, `content/authors.json`,
   `content/course_image_map.json`, `content/image_credits.json`, `content/catalog_withheld.json`
   poussés sur `main` (branche `usine/<courseId>` et pull request si `main` refuse).

Relancer un job : Actions → « Produce course » → Run workflow → `job_id`. Ordre de grandeur : une
heure et 60 à 90 appels au modèle pour un cours de six sections en 29 langues.

## Configuration

| Où | Quoi | Comment |
| --- | --- | --- |
| Supabase → Edge Functions → Secrets | `PUBLISH_API_KEY` | une chaîne aléatoire longue (`openssl rand -hex 32`), la même dans le Studio |
| Supabase → SQL | Vault `github_dispatch_token` | `select vault.create_secret('<jeton>', 'github_dispatch_token');` ; jeton GitHub fine-grained sur `adrienmrtn/rork-sophia-755` avec *Contents: Read and write* (c'est ce qu'exige `repository_dispatch`) |
| Supabase → SQL | Vault `studio_webhook_secret` (facultatif) | `select vault.create_secret('<secret>', 'studio_webhook_secret');` |
| Supabase → SQL | `app_config.studio.webhook_url` (facultatif) | `update app_config set value = '{"webhook_url": "https://…"}' where key = 'studio';` |
| GitHub → Settings → Secrets → Actions | `SUPABASE_SERVICE_ROLE_KEY` ; `ANTHROPIC_API_KEY` ou `FAL_API_KEY` (l'un des deux suffit) ; `ELEVENLABS_API_KEY` (facultatif) | |
| GitHub → Settings → Variables → Actions | `PRODUCTION_MODEL`, `ELEVENLABS_VOICE_FR`, `ELEVENLABS_VOICE_EN` (facultatifs) | |

Migration : `supabase/migrations/20261108200000_production_pipeline.sql` (tables
`production_jobs`, `production_steps`, fonctions `catalog_upsert_course`, `jobs_dispatch`,
déclencheurs d'état et de webhook, fonctions de statistiques, cron `catalog-jobs-dispatch`).

## Essai de bout en bout

Un corps de requête complet et valide : `docs/examples/publish-course-anticythere.json` (le cours
de l'essai du 8 novembre 2026, cinq sections, glossaire, couverture importée par URL).

```bash
curl -sS -X POST "https://afnmcoovdvbtkgohtdij.supabase.co/functions/v1/publish-course" \
  -H "x-api-key: $PUBLISH_API_KEY" -H "Content-Type: application/json" \
  --data @cours.json
```

Réponse 202 avec `job_id`. Puis, jusqu'à `done` ou `partial` :

```bash
curl -sS "https://afnmcoovdvbtkgohtdij.supabase.co/functions/v1/publish-course?job_id=$JOB" -H "x-api-key: $PUBLISH_API_KEY"
```

Le cours apparaît dans les apps au prochain rafraîchissement du manifeste (six heures au plus,
tout de suite via Réglages → Cours en ligne → Recharger), avec son quiz et son glossaire dans
chaque langue publiée. Les chiffres :

```bash
curl -sS "https://afnmcoovdvbtkgohtdij.supabase.co/functions/v1/course-stats-export?days=90&course_id=$COURSE" -H "x-api-key: $PUBLISH_API_KEY"
```

## Limites connues

- `kind: "video"` arrive au prompt 10.
- La photo d'un créateur du Studio (`creators.photo_url`) arrive dans les apps avec le prochain
  rafraîchissement du catalogue (au plus six heures), sous la clé `photoUrl` ; d'ici là, et sans
  réseau la première fois, elles montrent les initiales.
- La narration n'existe qu'en fr, en, es, de, tr (règles de lecture `scripts/tts/`) et seules fr et
  en ont une étape dans le job.
- Les packs de départ embarqués dans les apps ne contiennent pas un cours produit après le build :
  il arrive par le manifeste, comme toute correction.
