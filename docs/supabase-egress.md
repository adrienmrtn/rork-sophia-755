# Trafic Supabase (egress) : ce que l'app télécharge, et une seule fois

Octobre 2026 : le quota « Cached Egress » du plan Pro (250 Go/mois) a été dépassé
(311 Go le 20 octobre) juste après deux sorties du 27-29 septembre : les images de
cours servies par le bucket `course-images` au lieu d'être embarquées, et le mode
audio dont les narrations étaient streamées depuis `course-audio`.

Règle : **un fichier du bucket se télécharge au plus une fois par installation.**

## iOS

- `CourseImageLoader` garde les images dans Application Support (exclu des sauvegardes),
  plus dans Caches, que le système vide quand le téléphone manque de place. Le dossier
  Caches d'une version précédente est déplacé au premier lancement.
- `CourseAudioPlayer` ne streame plus : une narration absente du téléphone est d'abord
  téléchargée via `CourseAudioDownloads.ensureDownloaded`, puis lue depuis le disque.
  Pendant le téléchargement le lecteur affiche l'état « chargement » (`isBuffering`).
  Le fichier apparaît ensuite dans Réglages → Téléchargements, où il peut être supprimé.

## Android

- ExoPlayer lit à travers un `CacheDataSource` (`filesDir/course_audio_stream_cache`,
  256 Mo, LRU) : une narration streamée est conservée et rejouée depuis le disque.
  Les fichiers téléchargés (`file://`) passent par `DefaultDataSource` sans copie.
- Le cache disque Coil des images passe de 48 à 192 Mo.

## Côté Supabase

- Désactiver le spend cap (Organisation → Billing) pour que le dépassement soit facturé
  au lieu de restreindre le projet (erreurs 402). L'egress cached coûte quelques
  dollars par centaine de Go.
- Vérifier la répartition par bucket : projet → Reports → Storage.
