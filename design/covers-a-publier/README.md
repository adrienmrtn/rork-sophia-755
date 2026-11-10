# Couvertures à publier

Deux couvertures générées le 10/11 pour les cours publiés qui n'en avaient pas de vraie
(liste, critère et marche à suivre : `docs/cours-sans-couverture.md`).

| Fichier (= nom de l'objet à créer dans le bucket `course-images`, à la racine) | Cours |
| --- | --- |
| `comment_un_roman_a_t_il_sauve_notre_dame.jpg` | 255 · Comment un roman a-t-il sauvé Notre-Dame ? |
| `la_machine_d_anticythere.jpg` | 312 · Qu'est-ce que la machine d'Anticythère ? |

JPEG 1344x768 (16:9), moins de 250 Ko, sans texte. `alternatives/` garde les deux autres
propositions de chaque tirage (pour en préférer une : la renommer comme le fichier principal).
`manifest.json` porte les prompts d'image. Rien n'est en ligne : envoi dans le bucket puis
`supabase/migrations/20261112030000_course_covers.sql`.
