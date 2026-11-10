# Cours sans vraie couverture

État au 10/11, relevé en lecture seule sur Supabase (tables `courses`, `course_assets`,
`course_contents`, bucket `course-images`) et sur `ios/Sophia/CourseImages/`.

## Ce qu'est une vraie couverture

Une illustration maison en aplats (flat design, couleurs vives, sans texte), générée avec la
consigne de direction artistique `ART_DIRECTOR_SYSTEM_PROMPT` de `web/src/lib/studio/covers.ts` :
Gemini écrit le prompt d'image à partir du titre, Gemini image dessine. Les 310 couvertures
historiques sont des carrés 1024x1024 embarqués dans l'app iOS et copiés dans le bucket ; celles
du Studio sont en 16:9 (1344x768).

Le cours ne porte pas de champ « couverture » à part : `courses.cover_slug` est l'image du `hero`
du cours. Un cours n'a donc pas de vraie couverture quand son hero est une photo ou une image
d'archive au lieu de l'illustration.

## Le critère, et comment il a été vérifié

Dans les données, deux signes ne trompent pas :

- la ligne `course_assets` de type `cover` porte un **crédit de tiers** (Wikimedia…), alors que
  les illustrations maison n'ont pas de crédit (ou le crédit « Sophia » des cours du Studio) ;
- le fichier n'a **pas le format d'une couverture** (ni 1024x1024, ni 1344x768).

Contrôle visuel : les 310 couvertures embarquées ont été ouvertes en planches-contact (toutes sont
des illustrations, toutes en 1024x1024, et le bucket sert bien le même fichier : même taille en
octets sur les cours testés), et les couvertures des cours absents du bundle (255, 312, 314) ont
été téléchargées et regardées une à une.

## La liste : 2 cours publiés sur 311

| Cours | Titre | Ce qui sert de couverture aujourd'hui | Pourquoi ce n'est pas une vraie couverture |
| --- | --- | --- | --- |
| `course_255_comment_un_roman_a_t_il_sauve_notre_dame` | Comment un roman a-t-il sauvé Notre-Dame ? (How did a novel save Notre-Dame?) | `notre_dame_de_paris_cathedral_facade.jpg` : photo de Dietmar Rabich (Wikimedia Commons, CC BY-SA 4.0), un bandeau de 1200x203 px montrant la galerie des rois | Photo créditée, déjà utilisée comme image de bloc du cours 147 (l'architecture gothique) ; le plan d'images (docs/images-a-creer.md) la marquait « existante, à recadrer », aucune illustration n'a jamais été faite. C'est le seul des 311 cours sans fichier dans `ios/Sophia/CourseImages/`. Recadré en carte, le bandeau ne montre qu'une rangée de statues floues. |
| `course_312_qu_est_ce_que_la_machine_d_anticythere` | Qu'est-ce que la machine d'Anticythère ? (What Is the Antikythera Mechanism?) | `qu_est_ce_que_la_machine_d_anticythere.jpg` : photo du fragment A au musée d'Athènes (Marsyas, Wikimedia Commons, CC BY 2.5), 1036x924 px | Photo de musée créditée, importée comme hero par le Studio à la place d'une illustration générée. |

Hors liste, pour mémoire :

- `course_313_l_histoire_du_club_de_foot_mancheste_united` est encore `in_production` (pas publié).
  Sa couverture est annoncée comme illustration Sophia, mais l'objet
  `l_histoire_du_club_de_foot_mancheste_united.jpg` n'existe pas dans le bucket (400) : à vérifier
  avant de publier ce cours.
- `course_314_carl_lewis_king_of_sprint_and_long_jump` a une vraie couverture du Studio (16:9).
- Les cours 188 et 199 ont la même illustration (deux fichiers identiques à l'œil), et quatre
  couvertures historiques gardent une marge blanche (1, 38, 163, 205). Ce sont de vraies
  couvertures ; simple remarque de qualité.

## Les couvertures créées

Générées avec la chaîne du site, sans rien changer à la consigne : `scripts/generate_course_covers.py`
lit `ART_DIRECTOR_SYSTEM_PROMPT` dans `covers.ts`, envoie titre, sous-titre, matière et description
du cours à `fal-ai/any-llm` (`google/gemini-2.5-flash`), puis le prompt obtenu à
`fal-ai/gemini-25-flash-image` (trois propositions, 16:9, JPEG). Un seul tirage par cours a suffi.

| Cours | Fichier | Ce qu'on voit |
| --- | --- | --- |
| 255 | `design/covers-a-publier/comment_un_roman_a_t_il_sauve_notre_dame.jpg` | La façade de Notre-Dame en terracotta sur un ciel de crépuscule indigo et ambre, la silhouette de Victor Hugo en cape, plume levée, et un livre ouvert qui éclaire la cathédrale. |
| 312 | `design/covers-a-publier/la_machine_d_anticythere.jpg` | Des engrenages de bronze, le grand mangé de vert-de-gris, posés sur les planches et les amphores brisées d'une épave, dans le bleu de la mer avec des poissons en ombre. |

Les deux ont été regardées en pleine taille et comparées aux couvertures existantes : même
vocabulaire (aplats, silhouettes, fond coloré plein cadre), aucun texte, sujet lisible en vignette.
Elles sont en 16:9 comme la couverture du cours 314, pas en carré comme les 310 historiques. Les
deux autres propositions de chaque tirage sont dans `design/covers-a-publier/alternatives/`.

## Publier (rien n'a été écrit en ligne)

1. **Bucket.** Supabase → Storage → `course-images`, à la racine, envoyer les deux fichiers sans
   les renommer : `comment_un_roman_a_t_il_sauve_notre_dame.jpg` et `la_machine_d_anticythere.jpg`
   (type `image/jpeg`). Ce sont de nouveaux objets : rien n'est écrasé, et aucun cache d'image
   n'est à purger. Vérifier que
   `https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/la_machine_d_anticythere.jpg`
   s'affiche.
2. **SQL.** Lancer `supabase/migrations/20261112030000_course_covers.sql` (éditeur SQL). Il
   refuse de tourner si un fichier manque dans le bucket. Il change `courses.cover_slug`, la ligne
   `cover` de `course_assets` (crédit remis à vide, comme les autres créations maison), l'image du
   hero dans les 30 langues de chaque cours (et retire le crédit photo du hero du 312), recalcule
   le hash des paquets et marque le catalogue ; le cron `catalog-refinalize` republie les fichiers
   de langue dans la minute. La requête finale doit rendre deux lignes avec `langs_ok = 30`.
3. **Apps et site.** Rien à livrer : le site lit `cover_slug`, les apps prennent `cover` dans le
   catalogue au prochain rafraîchissement (six heures au plus) et l'image dans le bucket, puisque
   ces deux cours n'ont pas de couverture embarquée.
4. **Dépôt, pour qu'un réimport ne remette pas l'ancienne image** (non fait ici, d'autres agents
   travaillent dans l'arbre) : dans `content/courses/<langue>/course_255_…json` et
   `course_312_…json`, remplacer `hero.image` par le nouveau nom (et retirer `hero.credit` du 312) ;
   mettre les deux nouveaux noms dans `content/course_image_map.json` ; au prochain build iOS, on
   peut aussi copier les deux fichiers dans `ios/Sophia/CourseImages/`.

L'ancienne photo `notre_dame_de_paris_cathedral_facade.jpg` doit rester dans le bucket (image de
bloc du cours 147). `qu_est_ce_que_la_machine_d_anticythere.jpg` ne sert plus à rien après le
SQL ; la laisser ne gêne pas (d'anciennes versions du paquet en cache la demandent encore).
