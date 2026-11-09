# Sophia web : le site public et le Studio des auteurs

`web/` est un site Next.js (App Router, Tailwind 4) déployé sur Vercel à l'adresse
sophia-culture.com, branché directement sur le Supabase de l'app (`afnmcoovdvbtkgohtdij`) : un seul
système de comptes pour les lecteurs et les auteurs, les mêmes tables de catalogue et de
statistiques que les apps. Anglais seulement pour l'instant ; les chemins (`/courses`, `/authors`)
sont prêts pour un préfixe de langue (`/fr/courses/150-…`) le jour où la traduction est lancée.
Pas de narration audio : les cours publiés depuis le Studio partent avec `skip_audio: true`.

```
visiteur ──▶ sophia-culture.com (Vercel, Next.js)
                 │  lecture anonyme : courses, course_contents, creators, glossary_entries (RLS publiques)
                 │  compte : Supabase Auth (Google, Apple, e-mail + mot de passe, lien magique)
                 ▼
            Supabase afnmcoovdvbtkgohtdij ──▶ /studio : creator_accounts, studio_drafts, studio_reviews, RPC
                 │                            /admin  : relecture, créateurs, production
                 ▼
            publish-course (clé PUBLISH_API_KEY, depuis le serveur Vercel) ──▶ usine GitHub Actions ──▶ apps
```

## Les pages

| Adresse | Quoi | Données |
| --- | --- | --- |
| `/` | Vitrine : l'app, les six matières, les cours de la semaine, les auteurs, Premium (sans prix), Écrire pour Sophia | `catalog.listCourses`, `listCreators` |
| `/courses` | Explorer : recherche, matière, sous-catégorie, pagination (24) | idem |
| `/courses/<numéro>-<slug>` | Fiche d'un cours : introduction lisible, le reste « dans l'app », plan, glossaire, sources, auteur, même matière. Le slug est corrigé par redirection permanente | `catalog.getCourse` |
| `/authors`, `/authors/<slug>` | Les auteurs et leur page, dès l'approbation du compte (la ligne `creators` est créée par `studio_set_creator_status`, la photo copiée en public par le site) ; sans cours encore, la page le dit. Sur téléphone, « Follow in the app » ouvre l'app (`sophia://author/<slug>`) | `creators` |
| `/write` | Écrire pour Sophia : promesse, étapes, FAQ, appel au compte | textes |
| `/join` | Connexion et inscription (Google, Apple, e-mail, lien magique), `?next=` | Supabase Auth |
| `/auth/callback` | Retour OAuth / lien magique, puis redirection vers `next` | |
| `/about`, `/legal/creator-agreement` | À propos, contrat créateur public (`studio_documents`, rôle anon) | |
| `/unsubscribe?token=` | Le lien « ne plus recevoir ces e-mails » des messages « nouveau cours » (docs/notifications.md) | RPC `notification_unsubscribe` |
| `/studio` | Tableau de bord auteur : lectures (jour en cours compris, en direct), terminés / 1 000 impressions, abonnés, **cagnotte** (15 $ par cours validé, versée le lundi : crédits, versements), quota de la semaine, lectures par jour, mes cours | RPC `creator_dashboard` |
| `/studio/onboarding/<étape>` | Identité, références, profil + photo, contrat (signature), guide | `creator_accounts`, `studio_sign_agreement` |
| `/studio/courses`, `/studio/courses/new` | Mes cours : propositions (envoyées, renvoyées), en rédaction, en relecture, publiés ; bandeau du quota. **Proposer un cours** : titre + pitch, dans la limite du quota | `studio_drafts`, RPC `studio_propose`, `studio_update_proposal` |
| `/studio/courses/<id>` | L'éditeur (plan, blocs, vérifications, images Commons, aperçu), enregistrement automatique, envoi en relecture | `studio_drafts`, RPC `studio_submit_draft` |
| `/studio/courses/<id>/status` | Suivi : la proposition et la note de l'équipe (reprendre, renvoyer, supprimer), les décisions, la validation (15 $), la production langue par langue | `studio_reviews`, `production_jobs`, `production_steps` |
| `/studio/courses/app/<course_id>` | Un cours publié : décrochage par section, langues, quiz | RPC `creator_course_detail` |
| `/studio/profile`, `/studio/guide` | Profil public (photo ou avatar illustré) ; un compte approuvé voit sa page publique suivre tout de suite et les apps au prochain manifeste. La photo est rendue publique **par la base** (trigger `creator_accounts_photo_sync` → Edge Function `author-photo-sync`), jamais par le site. Guide d'écriture. | triggers `creator_accounts_sync`, `creator_accounts_photo_sync`, table `author_photo_requests` |
| `/admin` | Vue d'ensemble équipe : propositions à décider, file, créateurs, production, lectures (synthèse quotidienne + journal du jour en direct, `course_stats_window`), **versements du lundi** (dû, auteurs à payer), activité | RPC `studio_admin_overview` |
| `/admin/review`, `/admin/review/<id>` | Propositions à décider (accepter, renvoyer avec un mot, supprimer) ; file de relecture ; lecture du cours, vérifications du format, quota de l'auteur, **Accepter et lancer la production** = validation : +15 $ à la cagnotte, un cran du quota | RPC `studio_decide_proposal`, `studio_review_draft`, action `publishDraft` |
| `/admin/creators` | Approuver, suspendre, remettre en attente ; contrat signé ou non ; quota de la semaine et **limite hebdomadaire** par auteur (vide = règle commune, 0 = bloqué) ; cagnotte due | RPC `studio_set_creator_status`, `studio_set_creator_quota` |
| `/admin/payouts` | **Versements du lundi** : le dû par auteur (cours crédités), « Transfer done » qui solde la cagnotte et trace le versement, historique | RPC `studio_payouts_due`, `studio_mark_paid` |
| `/admin/production`, `/admin/production/<job>` | Les jobs de l'usine, étape par étape | `production_jobs`, `production_steps` |
| `/admin/events`, `/admin/events/<slug>` | Les événements éditoriaux (Movember, 11 novembre…) : création, cours de la collection, défi, cours annoncés, textes en 30 langues (traduction), publication vers les apps sans nouvelle version (docs/evenements.md) | `campaigns`, manifeste du catalogue |
| `/api/commons/search?q=` | Recherche d'images Wikimedia Commons pour l'éditeur (connecté seulement) | API Commons |
| `/sitemap.xml`, `/robots.txt` | Référencement ; `/studio`, `/admin`, `/auth`, `/join` exclus | |

Le `proxy.ts` (middleware Next 16) rafraîchit la session et renvoie vers `/join?next=…` les visiteurs
non connectés de `/studio` et `/admin` ; les pages revérifient. `/admin` exige en plus une ligne
dans `studio_admins` (fonction `studio_admin_touch`, qui pose `user_id` à la première connexion).

## Rémunération et quotas (10 novembre)

Un auteur touche **15 dollars par cours validé** (`app_config.studio.course_fee_cents`), quel que
soit le nombre de lectures ; la part des revenus Premium n'existe plus (les statistiques de lecture
restent). La validation est le clic **Accepter et lancer la production** (ou « Validate only ») :
`studio_review_draft('accepted')` pose `validated_at`, crée un crédit dans `creator_credits`
(jamais deux pour un même cours) et journalise `validated`. La cagnotte d'un auteur est la somme de
ses crédits sans `payout_id`. Le lundi, Adrien fait les virements à la main, en dollars, puis clique
« Transfer done » sur `/admin/payouts` : `studio_mark_paid` crée une ligne `creator_payouts` et y
rattache les crédits. Rien n'est collecté comme coordonnées bancaires ; pas de rétroactif.

**Deux étapes.** Un cours commence par une **proposition** (`studio_propose` : titre + pitch, statut
`proposed`). L'équipe accepte (statut `draft`, l'éditeur s'ouvre), renvoie avec un mot ou un
contre-titre (`proposal_returned`, l'auteur reprend et renvoie), ou supprime. Ensuite rédaction,
envoi en relecture, validation.

**Quota.** `studio_quota(user)` : trois cours validés dans les sept jours suivant l'approbation du
compte (`first_week_quota`), puis un par semaine calendaire lundi-dimanche, Europe/Paris
(`default_weekly_quota`), sans report. `creator_accounts.weekly_quota` (réglé sur `/admin/creators`)
remplace la règle commune pour un auteur ; 0 bloque. Un auteur ne peut proposer que si ses cours en
cours (proposés, en rédaction, en relecture) sont sous la limite ; l'équipe ne peut valider que si
les validations de la période sont sous la limite (le message dit à partir de quand). Un compte non
approuvé peut proposer et écrire, pas être validé.

Le contrat créateur **version 2** (`studio_documents`) dit tout cela ; la version en vigueur étant
la 2, un auteur ayant signé la 1 devra re-signer avant son prochain envoi.

## Le circuit d'un cours

1. L'auteur crée un compte sur `/join`, passe les cinq étapes de `/studio/onboarding` (le contrat
   est signé en ligne, version et empreinte gardées dans `creator_agreements`).
2. Il écrit dans l'éditeur. Les règles du format V2 (`web/src/lib/studio/course-format.ts`, les
   mêmes que `publish-course`) s'affichent pendant la frappe ; les images viennent de Commons avec
   leur crédit ; l'enregistrement est automatique (1,5 s après la dernière frappe).
3. **Envoyer en relecture** → RPC `studio_submit_draft` (compte complet, contrat signé, titre et
   deux parties). Statut `submitted`. L'auteur peut retirer tant que l'équipe n'a pas lu.
4. L'équipe lit sur `/admin/review/<id>` : demander des changements (commentaire), accepter,
   refuser, ou **Accepter et lancer la production**. Cette dernière action, côté serveur avec la
   clé `service_role` :
   copie la photo de l'auteur de `studio-photos/<uid>/…` vers `course-images/author_<slug>.<ext>`
   (publique) ; construit le corps de `publish-course` (`toPublishBody`, `options.skip_audio: true`,
   `creator.verified` = compte approuvé) ; appelle la fonction avec `PUBLISH_API_KEY` ; écrit
   `status = publishing`, `last_job_id`, `app_course_id` sur le brouillon ; pose
   `creators.user_id` ; appelle `jobs_dispatch(5)` pour démarrer tout de suite.
5. Le déclencheur `production_jobs_studio_sync` fait passer le brouillon à `published` (job `done`
   ou `partial`) ou `failed`. L'auteur suit sur `/studio/courses/<id>/status`, puis lit ses
   chiffres sur `/studio` dès que les apps envoient des événements de lecture.

Correction d'un cours publié : l'équipe rouvre le brouillon (`reopened`), l'auteur modifie et
renvoie ; la publication repart avec le même `app_course_id` (mise à jour, retraduction des seuls
segments changés).

## Déploiement

Projet Vercel **sophia-web** (équipe « Adrien's projects », `prj_aUDnPO47GYIntox6MDVuE7eTr2ik`),
lié au dépôt `adrienmrtn/rork-sophia-755`, racine `web`, branche de production `main`. Chaque
poussée sur `main` qui touche `web/` déploie ; chaque pull request a son aperçu. Le domaine
`sophia-culture.com` est rattaché au projet, mais le DNS (registrar name.com) pointe encore vers
Lovable (`185.158.133.1`) : rien ne change pour les visiteurs tant que les enregistrements ne sont
pas modifiés.

Variables d'environnement (Vercel → Settings → Environment Variables) :

| Variable | Valeur | Posée |
| --- | --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | `https://afnmcoovdvbtkgohtdij.supabase.co` | oui |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | la clé publiable du projet | oui |
| `NEXT_PUBLIC_SITE_URL` | `https://sophia-culture.com` (production) | oui |
| `SUPABASE_SECRET_KEY` | Supabase → Settings → API Keys → Secret keys (`sb_secret_…`, pleins droits ; l'ancienne `SUPABASE_SERVICE_ROLE_KEY` est acceptée) | **à poser** |
| `PUBLISH_API_KEY` | la même chaîne que le secret de l'Edge Function `publish-course` | **à poser** |
| `FAL_KEY` | la clé fal.ai (la même que le secret GitHub de l'usine d'images) : couvertures générées dans l'éditeur | **à poser** |
| `NEXT_PUBLIC_APP_STORE_URL`, `NEXT_PUBLIC_PLAY_STORE_URL` | facultatif, les liens des fiches | |

Sans `SUPABASE_SECRET_KEY` et `PUBLISH_API_KEY`, tout fonctionne sauf « Accepter et lancer
la production » (message explicite dans l'admin).

### Mise en ligne du domaine (quand le site est validé)

Chez name.com, pour `sophia-culture.com` :

| Type | Nom | Valeur |
| --- | --- | --- |
| A | `@` | `216.150.1.1` et `216.150.16.1` (ou l'ancienne adresse unique `76.76.21.21`) |
| CNAME | `www` | `f51d4520f6c33d8b.vercel-dns-016.com` (ou `cname.vercel-dns.com`) |

Supprimer l'A record Lovable `185.158.133.1`. Propagation de quelques minutes à quelques heures ;
Vercel émet le certificat tout seul. Le site Lovable reste joignable sur son adresse `*.lovable.app`
pour le Hub vidéo (lien « Video creators hub » du pied de page, à ajuster si l'adresse change).

### Supabase Auth

Authentication → URL Configuration :

- Site URL : `https://sophia-culture.com`
- Redirect URLs : `https://sophia-culture.com/auth/callback`, `https://*.vercel.app/auth/callback`
  (aperçus), `http://localhost:3000/auth/callback` (développement).

Providers :

- **Google** : déjà utilisé par les apps ; vérifier que l'URI de redirection
  `https://afnmcoovdvbtkgohtdij.supabase.co/auth/v1/callback` est bien dans la console Google Cloud
  du client OAuth web.
- **Apple** : la connexion Apple sur le web exige un *Services ID* (différent du Bundle ID de
  l'app), avec le domaine `afnmcoovdvbtkgohtdij.supabase.co` et l'URL de retour ci-dessus, plus la
  clé `.p8` → secret client généré pour Supabase. Tant que ce n'est pas fait, le bouton Apple
  renvoie une erreur ; Google et l'e-mail fonctionnent.
- **E-mail** : les messages de confirmation et les liens magiques partent du SMTP de Supabase
  (quota 2 par heure par défaut). Pour un vrai lancement, brancher un SMTP (Resend, Postmark…) dans
  Authentication → SMTP Settings et personnaliser les modèles (Authentication → Email Templates ;
  le lien doit mener à `{{ .SiteURL }}/auth/callback?token_hash={{ .TokenHash }}&type=email`).

### Migrations Supabase

Toutes appliquées sauf la dernière :

- `20261109000000_studio.sql` : tables et fonctions du Studio (appliquée).
- `20261109000100_studio_documents.sql` : contrat créateur et guide (appliquée).
- `20261109000200_studio_documents_public.sql` : lecture anonyme de `studio_documents` pour la
  page publique `/legal/creator-agreement` — **à appliquer** (SQL Editor, ou `supabase db push`).

L'équipe : `insert into public.studio_admins (email) values ('<adresse>');` (jamais dans le dépôt).

## Développement et vérifications

```bash
cd web && cp .env.example .env.local && npm install
npm run dev                         # Supabase réel
SOPHIA_DATA=starter npm run dev     # hors ligne : packs de départ de l'app (pages publiques)
npm test && npm run lint && npm run build
```

`.github/workflows/web-ci.yml` rejoue tests, lint et build sur chaque pull request touchant `web/`.
Les tests (`src/lib/studio/course-format.test.ts`) couvrent les règles du format et le corps envoyé
à `publish-course`.

## Ce qui n'est pas dans cette version

- Une seule langue d'interface (anglais). Les textes sont dans `web/src/lib/copy/` ; les cours et
  les auteurs sont lus dans la langue `en` du catalogue.
- Pas de narration audio (ni dans les cartes « ce que contient le cours », ni à la publication).
- Pas de paiement web, pas de prix affiché : Premium se souscrit dans l'app.
- Les statistiques du tableau de bord sont vides tant que les apps n'envoient pas les événements
  (`course_events` → `daily_course_stats`, voir `docs/events.md`) ; la cagnotte Premium se calcule
  dès que les webhooks RevenueCat arrivent (`creator_premium_revenue`).
- Le webhook `app_config.studio.webhook_url` n'est pas utilisé : le site lit directement
  `production_jobs` et `production_steps` (RLS : l'auteur voit ses jobs, l'équipe tout).
- Le guide d'écriture publié en base (v1) mentionne encore l'enregistrement audio ; à corriger dans
  `studio_documents` quand la narration sera décidée.
