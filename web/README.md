# Site vitrine Sophia

Site Next.js (App Router, Tailwind CSS 4) dans le même repo que les apps iOS et Android.
Ce dossier est indépendant : Xcode et Gradle ne le voient pas, il ne change rien aux apps.

## Lancer en local

```bash
cd web
npm install
npm run dev
```

Puis ouvrir http://localhost:3000.

## Contenu

Les cours, collections, profs et questions de quiz affichés viennent du repo, pas de Supabase :

```bash
python3 web/scripts/sync-content.py
```

Le script lit le catalogue français de l'app (`android/app/src/main/assets/starter_pack/fr/catalog.json`),
les quiz (`content/locales/fr/quizzes_v2.json`) et les images iOS, puis écrit
`src/data/site.json` et `public/img/`. À relancer quand le catalogue change.

## Variables d'environnement (optionnelles)

| Variable | Rôle |
|---|---|
| `NEXT_PUBLIC_APP_STORE_URL` | Lien App Store (l'identifiant de l'app n'est pas dans le repo ; par défaut, une recherche App Store) |
| `NEXT_PUBLIC_PLAY_STORE_URL` | Lien Google Play (par défaut `app.rork.sophia`) |
| `NEXT_PUBLIC_WRITE_URL` | Lien « Proposer un cours » (par défaut sophia-culture.com) |
| `NEXT_PUBLIC_SITE_URL` | URL publique du site (balises Open Graph) |

## Déploiement

Sur Vercel : importer le repo et choisir `web` comme « Root Directory ».

## Structure

- `src/app/page.tsx` : l'ordre des sections
- `src/components/` : une section par fichier (Hero, SubjectExplorer, QuizDemo…)
- `src/app/globals.css` : palette Sophia et utilitaires « néo-brutalistes » (`brutal`, `press`, `grid-paper`)
