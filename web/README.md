# Sophia web

Le site public de Sophia et l'espace auteur (Studio), en Next.js, déployé sur Vercel, branché sur
le Supabase de l'app. Documentation complète : [`docs/site-web.md`](../docs/site-web.md).

```bash
cp .env.example .env.local   # puis compléter
npm install
npm run dev                  # http://localhost:3000
npm test                     # règles du format de cours (Vitest)
npm run lint
npm run build
```

Sans accès à Supabase (hors ligne), `SOPHIA_DATA=starter npm run dev` sert le catalogue depuis les
packs de départ de l'app (`ios/Sophia/Resources/StarterPack`) ; les pages publiques s'affichent,
le Studio demande une connexion.

Dossiers : `src/app/(site)` pages publiques · `src/app/studio` espace auteur · `src/app/admin`
espace équipe · `src/lib/catalog` lecture du catalogue · `src/lib/studio` règles du format,
session, données · `src/lib/copy` textes (anglais).
