# Parrainage : « Invite un ami et gagne 3 cours gratuits »

iOS seulement pour l'instant (Android à porter). Base : `supabase/migrations/20261113000000_referrals.sql`.

## Les règles

- **Qui voit l'offre** : un lecteur qui a terminé au moins un cours **sur ce téléphone** et qui
  n'est pas Premium. Rien du parrainage ne se montre avant (ni carte, ni ligne, ni page).
  - Dans le fil d'accueil : la carte, en sixième position, tant que la récompense n'est pas gagnée.
  - Dans les réglages, section Compte : la ligne « Inviter un ami », tant que la récompense
    n'est pas gagnée, puis tant qu'il reste des cours gratuits à utiliser. Elle n'est plus dans
    le profil.
- **« Terminé sur ce téléphone »** (`ProgressManager.hasFinishedACourseHere`) : un cours fini ici
  (dernière page lue, audio écouté jusqu'au bout ou quiz terminé), pas seulement une
  progression revenue du compte. À la réinstallation, la session restaurée ramène les cours
  lus ailleurs avant toute lecture : sans ce repère, l'offre s'affichait dès l'arrivée. Les
  installations existantes le reçoivent au premier lancement d'après leur progression locale ;
  « Réinitialiser la progression » le remet à zéro.
- **Le code** d'un lecteur est son @ (`profiles.handle`). Il faut donc un compte pour inviter :
  sans compte, la page propose d'en créer un.
- **Le lien partagé** : `https://sophia-culture.com/invite/<handle>` (page du site, et lien
  universel : app installée, iOS l'ouvre dans l'app). `sophia://invite/<handle>` fait la même chose.
- **L'ami invité** crée son compte. Si l'app a été ouverte par le lien, elle retient le code et
  le déclare toute seule à la connexion (`claim_referral`). Sinon l'ami le saisit dans
  Réglages → Compte, proposé aux comptes de moins de 14 jours : la page « Inviter un ami »
  porte le champ « Tu as le code d'un ami ? » ; et tant que l'offre n'est pas ouverte (premier
  cours pas encore terminé, ou abonné Premium), la ligne des réglages s'appelle elle-même
  « Tu as le code d'un ami ? » et n'ouvre que ce champ, sans rien de l'offre. Sans compte, pas
  de ligne : il faut d'abord en créer un.
- **Garde-fous** (serveur) : un compte n'est parrainé qu'une fois, pas par lui-même ni par son
  propre filleul, et seulement dans les 14 jours qui suivent sa création.
- **La récompense** va à celui qui invite, **une seule fois**, dès le premier ami inscrit :
  3 crédits de cours. L'ami invité ne reçoit rien.
- **Un crédit** débloque en entier, pour toujours, un cours réservé au choix : dans le lecteur,
  là où le paywall `debloquer_cours` s'ouvrirait, l'app propose d'abord « Utiliser un cours
  gratuit ? ». Le quiz reste Premium.

## Où ça vit

| Quoi | Où |
| --- | --- |
| Table `referrals`, RPC `claim_referral(code)` et `referral_status()` | la migration ci-dessus |
| État serveur, code en attente, message de partage | `ios/Sophia/Services/ReferralService.swift` |
| Crédits dépensés (`referralUnlockedCourseIds`, synchronisés avec la progression) | `UserProgress`, `ProgressManager` |
| Carte du fil, page d'invitation, règles d'affichage (`InviteFriend`) | `ios/Sophia/Views/NewGen/InviteFriendViews.swift` |
| Ligne des réglages | `SettingsView.inviteRow` |
| Repère « un cours terminé sur ce téléphone » | `ProgressManager.hasFinishedACourseHere` (`sophia_first_course_finished_here`) |
| Choix « cours gratuit ou Premium » dans le lecteur | `CourseView.presentDebloquerPaywall` |
| Liens | `SophiaDeepLink.inviteCode`, `DeepLinkRouter.open` |
| Page du site et association Apple | `web/src/app/(site)/invite/[handle]`, `.well-known/apple-app-site-association` |
| Illustration | `invite_poster` (`design/site-art/manifest-app-invite.json`, fond ramené au crème) |

La récompense acquise est gardée sur le téléphone (`sophia_referral_rewarded`) pour que les
crédits restent utilisables hors ligne ; les cours débloqués suivent le compte. Elle est
effacée à la déconnexion (`AuthService.signOut`) : elle appartient au compte qui part.
