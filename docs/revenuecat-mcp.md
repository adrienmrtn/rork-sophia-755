# MCP RevenueCat

Le fichier `.mcp.json` à la racine déclare le serveur MCP hébergé par RevenueCat
(`https://mcp.revenuecat.ai/mcp`). Il donne à Claude Code un accès au projet RevenueCat
« Sophia » (`proj3f496a80`) : apps, entitlement, offerings, packages, produits, paywalls,
expériences, clients, métriques.

## Authentification

Le serveur accepte deux modes :

| Mode | Quand | Comment |
| --- | --- | --- |
| Clé API v2 (Bearer) | Sessions cloud (Claude Code sur le web ou depuis Claude Desktop), non interactives | Variable d'environnement `REVENUECAT_API_KEY`, lue par le header du `.mcp.json` |
| OAuth avec le compte RevenueCat | Sessions locales interactives (`/mcp`) | Retirer le bloc `headers` du `.mcp.json` ou laisser `REVENUECAT_API_KEY` vide n'y suffit pas : le repli OAuth est désactivé dès qu'un header `Authorization` est configuré |

En pratique, pour le cloud :

1. Dashboard RevenueCat, projet Sophia, **API keys**, créer une clé secrète **v2** avec des permissions
   en lecture seule (suffisant pour l'audit et les métriques ; `read_write` seulement pour modifier le catalogue).
2. Réglages de l'environnement cloud (menu de l'environnement dans la barre de titre de la session,
   puis Edit) : ajouter `REVENUECAT_API_KEY` dans les API credentials, sinon en variable d'environnement.
3. Démarrer une nouvelle session : les outils `mcp__revenuecat__*` apparaissent.

Ne jamais coller la clé dans le chat ni dans le repo. Une clé qui a fuité se régénère dans le dashboard.

## Instantané du catalogue (26/09/2026)

Offerings référencées par les apps (`SophiaPaywallContext` côté iOS, `PaywallContext` côté Android) :

| Offering | Courante | Package | iOS (App Store) | Android (Play) | Test Store |
| --- | --- | --- | --- | --- | --- |
| `fin_onboarding` | oui | `$rc_annual` | `Sophia_yearly` 39,99 €, essai 3 j | `sophia_pro:p1y` 47,99 € | `sophia_annual` |
| `fin_onboarding` | oui | `$rc_monthly` | `Sophia_monthly` 9,99 €, essai 3 j | `sophia_pro:monthly` 9,99 € | `sophia_monthly` |
| `quizz` (+ `entrainement`) | non | `$rc_annual` / `$rc_monthly` | idem | idem | idem |
| `debloquer_cours` | non | `$rc_annual` / `$rc_monthly` | idem | idem | idem |
| `offre_discount` | non | `$rc_annual` | `discount_yearly` 19,99 € | `sophia_pro:annual-promo` 23,99 € | `discount_yearly` |

Entitlement unique : `premium` (`entl5b0c63b9a1`). Les 20 autres offerings et la plupart des 42 paywalls
sont des restes d'expériences terminées ; voir `PLAN.md` pour le nettoyage proposé.

Liens dashboard : [offerings](https://app.revenuecat.com/projects/3f496a80/product-catalog/offerings),
[entitlements](https://app.revenuecat.com/projects/3f496a80/product-catalog/entitlements),
[paywalls](https://app.revenuecat.com/projects/3f496a80/paywalls),
[overview](https://app.revenuecat.com/projects/3f496a80/overview).
