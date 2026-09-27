# Images à créer pour les cours des profs

Convention : chaque image est référencée dans le JSON du cours par un nom en anglais, minuscules
et underscores. Le fichier attendu est `ios/Sophia/CourseImages/<nom>.jpg` (JPEG, 2 Mo max, le
bucket Supabase refuse au-delà). Tant que le fichier n'existe pas, l'app affiche un cadre gris
avec le nom : rien ne casse. Une fois les fichiers déposés :

1. `python3 scripts/upload_course_images_to_supabase.py` (clé service_role) pour Android ;
2. `python3 scripts/build_block_image_map.py` puis `python3 scripts/export_ios_content_for_android.py` ;
3. me donner la source de chaque image (un lien Wikimedia suffit) pour remplir
   `ios/Sophia/Resources/image_credits.json`.

Le **hero** sert aussi de couverture sur la carte de la home (`CourseImageMap`), donc un cadrage
large 16:9 avec le sujet au centre.

## Pilote (3 cours) : images livrées le 27/09

Toutes en place dans `ios/Sophia/CourseImages/`. Deux fichiers ont été renommés d'après ce
qu'ils montrent réellement : `wienerisches_diarium_1725_vampire_report` est devenu
`edvard_munch_vampire_painting_1895` (tableau de Munch) et
`diaphragm_lungs_glottis_anatomy_diagram` est devenu `mouse_diaphragm_muscle_fibres_microscopy`
(microscopie). L'image « Tokyo Tower » fournie pour `eiffel_tower_radio_antenna_1914_military` a
été remplacée par la gravure « Antenne tour Eiffel 1914 » (Wikimedia Commons, domaine public).
Les trois couvertures n'ont pas de crédit renseigné : à compléter dans `image_credits.json`
si elles ne sont pas des créations maison. Reste l'upload Supabase pour Android.


### course_241 · Pourquoi voulait-on démolir la tour Eiffel ?

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `eiffel_tower_1889_universal_exhibition` | hero + couverture | 16:9 | La tour achevée en 1889, vue du Champ-de-Mars ou du Trocadéro pendant l'Exposition universelle, avec les pavillons au pied. Photo ou gravure d'époque. | Wikimedia Commons, catégorie « Eiffel Tower in 1889 » (domaine public) |
| `eiffel_tower_construction_1888_champ_de_mars` | section 1 | 4:3 | Le chantier : les quatre piliers montés jusqu'au premier étage, échafaudages, 1887-1888. | Photos de Louis-Émile Durandelle ou Théophile Féau, domaine public |
| `gustave_eiffel_portrait_nadar` | section 2 | 1:1 | Portrait photographique de Gustave Eiffel, buste, fin XIXe. | Portrait par Nadar, domaine public |
| `eiffel_tower_radio_antenna_1914_military` | section 3 | 4:3 | Les câbles d'antenne de télégraphie sans fil tendus du sommet vers le Champ-de-Mars, ou le poste radio militaire de la tour, années 1900-1914. | Cartes postales et photos d'époque, domaine public |

### course_242 · Pourquoi a-t-on le hoquet ?

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `child_hiccups_surprised_hand_over_mouth` | hero + couverture | 16:9 | Un enfant ou un jeune adulte surpris par un hoquet, main devant la bouche, lumière chaude, cadrage serré. Photo. | Unsplash / Pexels (licence libre) |
| `diaphragm_lungs_glottis_anatomy_diagram` | section 1 | 4:3 | Schéma anatomique simple : poumons, diaphragme en dôme dessous, trachée et glotte. Fond clair, style manuel scolaire. | Wikimedia Commons (illustrations anatomiques CC BY / domaine public), ou illustration maison |
| `fetal_ultrasound_scan_pregnancy` | section 2 | 4:3 | Image d'échographie d'un fœtus, profil reconnaissable. | Wikimedia Commons, catégorie « Obstetric ultrasonography » |
| `glass_of_cold_water_home_remedy_hiccups` | section 4 | 1:1 | Un verre d'eau froide posé sur une table, gouttes de condensation, fond neutre. | Unsplash / Pexels |

### course_243 · Pourquoi a-t-on inventé les vampires ?

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `foggy_village_graveyard_night_balkans` | hero + couverture | 16:9 | Cimetière de village dans la brume, au crépuscule ou de nuit, croix de bois ou de pierre, ambiance Europe de l'Est. Photo, sans personnage. | Unsplash / Pexels |
| `wienerisches_diarium_1725_vampire_report` | section 1 | 4:3 | La page du *Wienerisches Diarium* de juillet 1725 relatant l'affaire Blagojević (texte gothique allemand), ou un rapport manuscrit autrichien de l'époque. | Wikimedia Commons, article « Petar Blagojević » (domaine public) |
| `mercy_brown_grave_exeter_rhode_island` | section 2 | 4:3 | La pierre tombale de Mercy L. Brown au cimetière de Chestnut Hill, Exeter, Rhode Island. | Wikimedia Commons, article « Mercy Brown vampire incident » (CC BY-SA) |
| `bram_stoker_dracula_1897_first_edition_cover` | section 3 | 4:3 | La couverture jaune de la première édition de *Dracula* (Archibald Constable, 1897), titre rouge. | Wikimedia Commons, domaine public |

## Photos des profs

Déjà en place dans `ios/Sophia/Resources/AuthorPhotos/` (512 × 512, JPEG) et
`android/app/src/main/assets/author_photos/` : `author_dusan_nikolic.jpg`, `author_stacy_jankowski.jpg`.
Angela Bouma n'a pas de photo sur la plateforme : l'app affiche ses initiales. Si elle en fournit
une, la déposer sous `author_angela_bouma.jpg` et renseigner `"photo": "author_angela_bouma"`
dans `content/authors.json`.
