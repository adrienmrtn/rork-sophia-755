# Notifications : ce qui existe, ce qui est branché, ce qui reste

## Aujourd'hui dans les apps (local, sans serveur)

- **Rappel quotidien** (`DailyCourseReminder.swift`, `TrialReminderScheduler.kt` et l'équivalent
  iOS) : à l'heure choisie dans l'onboarding, « Ton cours du jour est prêt » avec la question du
  jour, programmé par le téléphone pour les 30 jours à venir ; rien pendant l'essai Premium.
- **Fin d'essai** (Android) : un rappel dix heures avant la fin de l'essai.
- **Bloqueur TikTok** (iOS) : la notification du bouclier.

Aucun **push** depuis le serveur : pas de clé APNs, pas de projet Firebase, pas de table de jetons
d'appareils. Mis de côté le 9 novembre ; le jour venu il faudra une clé APNs (.p8) du compte
développeur Apple et un projet Firebase pour Android.

## Abonnements côté serveur (`public.follows`)

Les apps gardent les « Suivre » dans `UserProgress.followedCreatorSlugs` et poussent tout le
JSON dans `user_progress.progress` à chaque changement (connexion obligatoire). La table
`follows (user_id, creator_slug, followed_at)` est **dérivée par trigger** de ce JSON
(`user_progress_sync_follows`) ; un remplissage initial a repris les lignes existantes. Les apps
n'écrivent jamais dans `follows`. Un lecteur ne lit que ses propres lignes (RLS).

C'est la liste de diffusion des e-mails « nouveau cours », et demain celle du push.

## E-mail « nouveau cours » (Resend, depuis la base)

Quand un cours passe `published` (première langue en ligne, trigger `courses_published_notify`),
`notify_course_published(course_id)` :

1. prend les abonnés de l'auteur (`notify_course_recipients`) : avec un e-mail, qui n'ont pas
   refusé (`notification_prefs.email_new_course`), pas encore prévenus pour ce cours
   (`notification_log`) ; la langue est celle de l'app du lecteur (dernier événement), sinon celle
   du cours ; français ou anglais pour le texte (les autres langues reçoivent l'anglais) ;
2. construit un e-mail par lecteur (sujet « Nouveau cours de X : titre », corps HTML et texte,
   bouton vers la page du cours sur le site, lien de désinscription avec jeton) ;
3. envoie par paquets de 100 à `https://api.resend.com/emails/batch` avec `pg_net`, la clé lue
   dans le Vault (`resend_api_key`) ;
4. journalise chaque destinataire dans `notification_log` (jamais deux fois le même cours).

Sans clé dans le Vault, la fonction ne fait rien et ne journalise rien. Les réglages viennent de
`app_config` → `studio` : `email_from` (défaut `Sophia <hello@sophia-culture.com>`),
`email_reply_to` (défaut `maximilien@vikstudios.com`), `site_url` (défaut
`https://sophia-culture.com`).

**Désinscription** : `https://sophia-culture.com/unsubscribe?token=<uuid>` (page du site,
`notification_unsubscribe(token)` avec la clé serveur) passe `email_new_course` à faux.

### Mettre Resend en service (Adrien)

1. https://resend.com → créer un compte, **Domains → Add domain** : `sophia-culture.com`,
   région Europe (Ireland).
2. Resend affiche deux ou trois enregistrements DNS (un TXT DKIM `resend._domainkey`, un MX et
   un TXT SPF sur un sous-domaine `send`). Les ajouter chez name.com, puis **Verify** dans Resend
   (quelques minutes).
3. **API Keys → Create API key**, permission *Sending access*, domaine `sophia-culture.com`.
   Copier la clé (`re_…`).
4. Supabase → **SQL Editor** → exécuter, en remplaçant la clé :

   ```sql
   select vault.create_secret('re_xxxxxxxxxxxxxxxx', 'resend_api_key');
   ```

   La clé ne quitte jamais la base. Pour la changer : `select vault.update_secret(id, 're_…')
   from vault.secrets where name = 'resend_api_key'`.
5. Facultatif : changer l'expéditeur ou l'adresse de réponse :

   ```sql
   update public.app_config
      set value = value || '{"email_from": "Sophia <hello@sophia-culture.com>", "email_reply_to": "maximilien@vikstudios.com"}'::jsonb
    where key = 'studio';
   ```

### Vérifier

```sql
select * from public.notify_course_recipients('course_314_carl_lewis_king_of_sprint_and_long_jump');  -- qui recevrait
select public.notify_course_published('course_314_carl_lewis_king_of_sprint_and_long_jump');         -- envoie (une fois)
select * from public.notification_log order by sent_at desc limit 20;
```

Les envois `pg_net` et leurs réponses : `select * from net._http_response order by created desc limit 10`.

## Tendances (`trending_courses`)

Chaque nuit à 02:40 UTC, `refresh_trending_courses()` garde par langue les huit cours les plus
ouverts des sept derniers jours (`course_events` · `course_open`). Le manifeste du catalogue les
porte sous `trending` ; l'onglet Explorer des apps les affiche quand la liste n'est pas vide, et
retombe sinon sur le tirage local hebdomadaire. Tant que les apps en magasin n'envoient pas
d'événements (version 2), la liste reste vide.
