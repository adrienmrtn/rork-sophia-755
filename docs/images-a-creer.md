# Images à créer pour les cours des profs

Convention : chaque image est référencée dans le JSON du cours par un nom en anglais, minuscules
et underscores, fichier JPEG de 2 Mo max (le bucket Supabase refuse au-delà). Où le déposer :

- **couverture** (image du `hero`, aussi la carte de la home) : `ios/Sophia/CourseImages/<nom>.jpg`,
  embarquée dans l'app iOS ;
- **toute autre image** (blocs `image` dans les sections) : `content/images/<nom>.jpg`, jamais
  embarquée, servie par le bucket Supabase aux deux apps.

Tant que le fichier n'existe nulle part, l'app affiche un cadre gris avec le nom : rien ne casse.
Une fois les fichiers déposés :

1. `python3 scripts/upload_course_images_to_supabase.py` (clé service_role) : indispensable, sur
   iOS comme sur Android, pour toutes les images hors couvertures ;
2. `python3 scripts/build_block_image_map.py` puis `python3 scripts/export_ios_content_for_android.py` ;
3. me donner la source de chaque image (un lien Wikimedia suffit) pour remplir
   `ios/Sophia/Resources/image_credits.json`.

Le **hero** sert aussi de couverture sur la carte de la home (`CourseImageMap`), donc un cadrage
large avec le sujet au centre.

## Pilote (3 cours) : images livrées le 27/09

Toutes en place : les trois couvertures dans `ios/Sophia/CourseImages/`, les neuf illustrations dans `content/images/` (à uploader vers le bucket). Deux fichiers ont été renommés d'après ce
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

## Lot 2 : les 72 autres cours signés (numéros 244 à 311 et 4 remplacements)

70 couvertures et 197 illustrations à fournir ; 20 images déjà présentes sont réutilisées (marquées
« existante », rien à faire). Les cours des deux auteurs non signataires (10 cours) ne sont pas dans ce
lot. Rappel : couverture → `ios/Sophia/CourseImages/<nom>.jpg`, autres → `content/images/<nom>.jpg`,
puis `scripts/upload_course_images_to_supabase.py`. Les listes brutes copiables sont en fin de
section.

### 57 · Comment Internet est-il né de la Guerre froide ? (remplace le cours existant)

Matière : sciences · Rubrique : Découvertes qui ont changé le monde · Prof : Myra Houser

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `ibm_mainframe_computer_room_1960s_operators` | hero + couverture | 16:9 | Une salle informatique des années 1960 : ordinateur central occupant toute la pièce, armoires et dérouleurs de bandes magnétiques, opérateurs en chemise blanche. Photo d'archive. | Wikimedia Commons, catégories « IBM 7090 » ou « IBM System/360 » (photos NASA, domaine public) |
| `arpanet_1969_computer_ucla` **(existante)** | partie 1 | 4:3 | Le SDS Sigma 7 de l'UCLA, premier ordinateur relié à ARPANET en 1969 : armoire à bandes magnétiques, panneau de commande. | Déjà dans content/images (Wikimedia Commons, CC BY-SA 2.0) |
| `arpanet_logical_map_1977_network_diagram` | partie 2 | 4:3 | La carte logique d'ARPANET en mars 1977 : les nœuds (universités, laboratoires, bases militaires) reliés par des lignes, document officiel. | Wikimedia Commons, « ARPANET logical map, March 1977 » (DARPA, domaine public) |
| `tim_berners_lee_next_computer_cern_first_web_server` | partie 3 | 4:3 | Le NeXT Cube de Tim Berners-Lee au CERN, premier serveur web (1990), avec son étiquette « This machine is a server. DO NOT POWER IT DOWN!! ». | Wikimedia Commons, catégorie « First web server » (CC BY-SA) |

### 149 · La Joconde comptait-elle vraiment pour Léonard ? (remplace le cours existant)

Matière : art · Rubrique : Œuvres iconiques · Prof : Dusan Nikolic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `la_joconde` **(existante)** | hero + couverture | 16:9 | Couverture actuelle du cours 149 (La Joconde, panneau de Léonard, cadrage large sur le visage et le buste) : à conserver telle quelle, elle est déjà dans ios/Sophia/CourseImages. | Déjà en place : ios/Sophia/CourseImages/la_joconde.jpg (Léonard de Vinci, domaine public) |
| `vasari_lives_of_the_artists_1568_title_page` | partie 1 | 3:4 | Page de titre (ou frontispice) des Vite de Giorgio Vasari, édition Giunti de 1568 à Florence, le texte qui identifie le modèle comme Lisa Gherardini : document vertical, gravure sur bois. | Wikimedia Commons, catégorie « Le Vite (1568) » / article « Les Vies des meilleurs peintres, sculpteurs et architectes », domaine public |
| `rubens_copy_battle_of_anghiari_louvre_drawing` | partie 2 | 4:3 | La copie par Rubens (vers 1603, Louvre) de la partie centrale de la Bataille d'Anghiari de Léonard : la mêlée de cavaliers autour de l'étendard, seule trace du grand décor inachevé du Palazzo Vecchio. | Wikimedia Commons, article « La Bataille d'Anghiari (Léonard de Vinci) », fichier « Peter Paul Ruben's copy of the lost Battle of Anghiari », domaine public |
| `mona_lisa_stolen_1911_newspaper_headline` **(existante)** | partie 3 | 4:3 | Une du journal Excelsior de janvier 1914 annonçant le retour de La Joconde après le vol de 1911 : la presse qui fabrique la sensation. | Déjà en place : content/images/mona_lisa_stolen_1911_newspaper_headline.jpg (Excelsior, 1er janvier 1914, domaine public), utilisée par l'ancienne version du cours 149 |

### 214 · L'État-providence est-il réservé aux citoyens ? (remplace le cours existant)

Matière : comprendreLeMonde · Rubrique : Économie & société · Prof : Mark N. Hoffman

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `bracero_mexican_farmworkers_california_1942_lange` | hero + couverture | 16:9 | Groupe de braceros mexicains dans un champ ou à leur arrivée par train en Californie, 1942, photographiés par Dorothea Lange : cadrage large sur les hommes au travail, chapeaux et rangs de culture. | Library of Congress, collection FSA/OWI (domaine public) ; Wikimedia Commons, catégorie « Bracero Program » |
| `renault_billancourt_immigrant_workers_assembly_line` | partie 1 | 3:2 | Ouvriers immigrés (algériens, marocains, portugais) sur une chaîne de montage automobile française d'après-guerre, usine Renault de Boulogne-Billancourt, années 1950-1960. | Wikimedia Commons, catégorie « Renault Billancourt » ; Gallica / archives Renault (vérifier la licence) ; à défaut, chaîne de montage française des Trente Glorieuses |
| `cour_de_cassation_paris_palais_de_justice` | partie 2 | 4:3 | La façade ou la grand-chambre de la Cour de cassation au Palais de justice de Paris (île de la Cité), qui casse en 1991 le refus de pension opposé à Mazari en raison de sa nationalité. | Wikimedia Commons, catégorie « Cour de cassation (France) » (CC BY-SA) |
| `georges_marchais_portrait_1981` | partie 4 | 1:1 | Portrait photographique de Georges Marchais, secrétaire général du Parti communiste français, buste, vers 1980-1981. | Wikimedia Commons, catégorie « Georges Marchais » (photos des Archives nationales néerlandaises, CC0 / CC BY-SA) |

### 234 · Comment nourrir huit milliards d'humains ? (remplace le cours existant)

Matière : comprendreLeMonde · Rubrique : Environnement & avenir · Prof : Kate Waddams

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `combine_harvester_wheat_field_aerial` | hero + couverture | 16:9 | Vue aérienne d'une moissonneuse-batteuse traçant sa ligne dans un champ de blé doré, plein été, la machine au centre du cadre. | Unsplash / Pexels (« combine harvester aerial »), ou Wikimedia Commons, catégorie « Combine harvesters » |
| `dairy_cows_grazing_green_pasture` | partie 1 | 3:2 | Vaches laitières broutant une prairie verte sous le soleil, haies ou collines à l'arrière-plan : l'herbe transformée en lait et en viande. | Unsplash / Pexels |
| `discarded_fruit_vegetables_food_waste_dumpster` | partie 2 | 4:3 | Benne ou cageots remplis de fruits et légumes encore comestibles jetés derrière un supermarché ou sur un marché : le tiers de la production mondiale perdu ou gaspillé. | Wikimedia Commons, catégorie « Food waste » (CC BY-SA), ou Unsplash |
| `agricultural_drone_precision_farming_field` | partie 3 | 3:2 | Drone agricole survolant à basse altitude des rangs de cultures et pulvérisant ou cartographiant la parcelle : l'agriculture de précision qui dose les intrants au mètre près. | Wikimedia Commons, catégorie « Agricultural drones » (CC BY-SA), ou Unsplash |

### 244 · D'où vient le loup-garou ?

Matière : mythologie · Rubrique : Légendes & créatures · Prof : Angela Bouma

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `grey_wolf_snowy_forest_dusk` | hero + couverture | 16:9 | Un loup gris seul, de face ou de trois quarts, dans une forêt enneigée au crépuscule, regard vers l'objectif, animal centré et net, cadrage large. Photo. | Unsplash / Pexels (recherche « grey wolf forest snow »), licence libre |
| `lycaon_turned_into_wolf_goltzius_1589_engraving` | partie 1 | 4:3 | La gravure d'Hendrick Goltzius (1589, série des Métamorphoses d'Ovide) montrant Lycaon fuyant le banquet et se changeant en loup sous les yeux de Jupiter. | Wikimedia Commons, catégorie « Lycaon (mythology) » / Rijksmuseum, domaine public |
| `marie_de_france_writing_medieval_illumination` | partie 3 | 3:4 | L'enluminure du XIIIe siècle représentant Marie de France assise, en train d'écrire (manuscrit BnF, Arsenal 3142, f. 256). | Wikimedia Commons, article « Marie de France » (BnF / Gallica), domaine public |
| `werewolf_woodcut_lucas_cranach_elder_1512` | partie 4 | 4:3 | La gravure sur bois « Le Loup-garou » de Lucas Cranach l'Ancien (vers 1512) : un homme à quatre pattes, ensanglanté, attaque un village. Document d'époque de la peur des loups-garous au début de l'époque moderne. | Wikimedia Commons, catégorie « Werewolf by Lucas Cranach the Elder » (Herzogliches Museum Gotha), domaine public |

### 245 · D'où vient le père Noël ?

Matière : mythologie · Rubrique : Légendes & créatures · Prof : Angela Bouma

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `santa_claus_thomas_nast_1881_harpers_weekly` | hero + couverture | 16:9 | « Merry Old Santa Claus », le dessin de Thomas Nast paru dans Harper's Weekly le 1er janvier 1881 : Santa barbu en manteau rouge, pipe à la bouche, les bras chargés de jouets. Cadrer sur le visage et le buste pour le 16:9. | Wikimedia Commons, article « Thomas Nast » / fichier « MerryOldSanta », domaine public |
| `sinterklaas_white_horse_arrival_netherlands` | partie 1 | 3:2 | Sinterklaas en mitre et chape rouges, crosse à la main, sur son cheval blanc lors de l'arrivée (intocht) dans une ville néerlandaise, photo couleur récente. | Wikimedia Commons, catégorie « Intocht van Sinterklaas » (CC BY-SA) |
| `a_visit_from_st_nicholas_troy_sentinel_1823` | partie 2 | 3:4 | La première publication anonyme du poème « A Visit from St. Nicholas » dans le journal Troy Sentinel du 23 décembre 1823, colonne de texte imprimé. | Wikimedia Commons, article « A Visit from St. Nicholas », domaine public |
| `department_store_santa_claus_children_1940s` | partie 3 | 3:2 | Un père Noël de grand magasin américain des années 1940, en costume rouge et barbe blanche, entouré d'enfants qui font la queue (photo noir et blanc d'archives). | Library of Congress, collection FSA/OWI (Marjory Collins, New York, 1942) via Wikimedia Commons, domaine public |

### 246 · Qui était le vrai roi Arthur ?

Matière : mythologie · Rubrique : Légendes & créatures · Prof : Angela Bouma

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `tintagel_castle_ruins_cornwall_coast` | hero + couverture | 16:9 | Les ruines du château de Tintagel sur les falaises de Cornouailles, mer et ciel dramatiques, vue large depuis la côte ; le lieu où Geoffroy de Monmouth situe la conception d'Arthur. Photo. | Unsplash / Wikimedia Commons, catégorie « Tintagel Castle » (CC BY-SA) |
| `badbury_rings_hillfort_dorset_aerial` | partie 1 | 3:2 | Vue aérienne des remparts circulaires de Badbury Rings (Dorset), oppidum de l'âge du fer souvent proposé comme site de la bataille de Badon. | Wikimedia Commons, catégorie « Badbury Rings » (CC BY-SA) |
| `historia_brittonum_harley_3859_manuscript_page` | partie 3 | 3:4 | Une page manuscrite de l'Historia Brittonum (British Library, Harley MS 3859, vers 1100), idéalement le chapitre 56 qui énumère les douze batailles d'Arthur, « dux bellorum ». | British Library Digitised Manuscripts / Wikimedia Commons, article « Historia Brittonum », domaine public |
| `king_arthur_enthroned_royal_ms_20_a_ii` | partie 4 | 3:4 | Arthur couronné et assis sur son trône, tenant une couronne dans chaque main, enluminure anglaise du début du XIVe siècle (British Library, Royal MS 20 A II, f. 4r). | British Library, Royal MS 20 A II f. 4r (chronique de Pierre de Langtoft), via Wikimedia Commons, domaine public |

### 247 · Pourquoi les momies font-elles peur ?

Matière : mythologie · Rubrique : Légendes & créatures · Prof : Angela Bouma

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `tutankhamun_golden_mask_egyptian_museum_cairo` | hero + couverture | 16:9 | Le masque funéraire en or de Toutânkhamon, de face, sur fond sombre, cadré sur le visage et le némès pour le 16:9. Photo de musée. | Wikimedia Commons, catégorie « Mask of Tutankhamun » (photos CC BY-SA, ex. Roland Unger) |
| `anubis_embalming_mummy_sennedjem_tomb_painting` | partie 1 | 4:3 | Peinture murale de la tombe de Sennedjem (Deir el-Médineh, Nouvel Empire) : Anubis à tête de chacal penché sur la momie allongée, en train de l'embaumer. | Wikimedia Commons, catégorie « TT1 » / « Tomb of Sennedjem », domaine public |
| `mumia_apothecary_jar_powdered_mummy_medicine` | partie 2 | 3:4 | Un pot d'apothicaire ancien étiqueté « Mumia » ou « Mumia vera aegyptiaca », qui contenait de la poudre de momie vendue comme remède (XVIIe-XVIIIe siècle). | Wikimedia Commons, article « Mummia » (pots du Deutsches Apotheken-Museum de Heidelberg ou du Museum für Hamburgische Geschichte, CC BY-SA) |
| `the_mummy_1932_film_poster_boris_karloff` | partie 4 | 3:4 | L'affiche originale du film « The Mummy » (Universal, 1932) avec Boris Karloff en Imhotep, ou à défaut une photo de plateau de Karloff maquillé en momie. | Wikimedia Commons, article « The Mummy (1932 film) » (affiche et photos promotionnelles américaines de 1932, domaine public, copyright non renouvelé) |

### 248 · Pourquoi les sorcières volent-elles sur un balai ?

Matière : mythologie · Rubrique : Légendes & créatures · Prof : Angela Bouma

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `old_besom_broom_stone_wall_rustic` | hero + couverture | 16:9 | Un vieux balai de brindilles (besom) appuyé contre un mur de pierre ou posé dans une pièce sombre, lumière chaude rasante, balai centré et net, sans personnage. Photo. | Unsplash / Pexels (recherche « besom broom », « old broom »), licence libre |
| `champion_des_dames_1440_witches_broom_miniature` | partie 1 | 3:4 | La miniature marginale du manuscrit du Champion des Dames de Martin Le Franc (vers 1440-1451, BnF ms. fr. 12476, f. 105v) : deux femmes volant, l'une sur un balai, l'autre sur un bâton, légendées « Vaudoises ». | Wikimedia Commons, article « Le Champion des Dames » / fichier « Vaudoises », BnF Gallica, domaine public |
| `hans_baldung_grien_witches_1510_woodcut` | partie 3 | 3:4 | La gravure en clair-obscur « Les Sorcières » de Hans Baldung Grien (1510) : des femmes autour d'un chaudron fumant, l'une chevauchant un bouc à l'envers avec une fourche de cuisine. | Wikimedia Commons, catégorie « Witches by Hans Baldung Grien » (Metropolitan Museum / Louvre), domaine public |
| `goya_linda_maestra_capricho_68_witches_broom` | partie 4 | 3:4 | L'eau-forte de Goya « ¡Linda maestra! » (Les Caprices, n° 68, 1799) : une vieille sorcière et une jeune femme nues volant sur le même balai, une chouette en arrière-plan. | Wikimedia Commons, catégorie « Los Caprichos », Museo del Prado, domaine public |

### 249 · Les Vikings ont-ils découvert l'Amérique avant Colomb ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Benjamin Campbell

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `leif_erikson_discovers_america_krohg_1893` | hero + couverture | 16:9 | Le tableau « Leiv Eiriksson oppdager Amerika » de Christian Krohg (1893) : Leif Eriksson debout à la proue de son bateau, bras tendu vers la côte, équipage et voile derrière lui. Cadrage large sur la scène entière. | Wikimedia Commons, article « Leif Erikson » ou Nasjonalmuseet (Oslo), domaine public |
| `skalholt_map_1590_vinland_helluland_markland` | partie 1 | 4:3 | La carte de Skálholt (1590, copie de 1669) dessinée d'après les sagas : l'Atlantique Nord avec le Groenland et les terres nommées Helluland, Markland et « Promontorium Winlandiæ ». | Wikimedia Commons, catégorie « Skálholt map », Bibliothèque royale de Copenhague, domaine public |
| `lanse_aux_meadows_norse_sod_houses_newfoundland` | partie 2 | 3:2 | Les maisons de tourbe reconstituées du site viking de L'Anse aux Meadows, à la pointe nord de Terre-Neuve : toits d'herbe, murs de gazon, côte et ciel en arrière-plan. Photo horizontale. | Wikimedia Commons, catégorie « L'Anse aux Meadows » (CC BY-SA), ou Parcs Canada |
| `christopher_columbus_portrait` **(existante)** | partie 4 | 1:1 | Portrait de Christophe Colomb (déjà utilisé dans le cours sur la découverte de l'Amérique), en buste, pour la partie qui compare l'impact de son voyage de 1492 à celui des Vikings. | Image déjà disponible dans content/images (réutilisation) |

### 250 · Comment Gengis Khan a-t-il conquis la moitié du monde ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Benjamin Campbell

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `genghis_khan_equestrian_statue_tsonjin_boldog_mongolia` | hero + couverture | 16:9 | La statue équestre géante de Gengis Khan (40 m, acier inoxydable) à Tsonjin Boldog, dans la steppe mongole : cavalier au centre, horizon de collines et grand ciel. Photo large, lumière du jour. | Wikimedia Commons, catégorie « Genghis Khan Equestrian Statue » (CC BY-SA), ou Unsplash « Genghis Khan statue » |
| `genghis_khan_portrait_national_palace_museum_taipei` | partie 1 | 1:1 | Le portrait officiel de Gengis Khan de l'album des empereurs Yuan (XIVe siècle, Musée national du Palais, Taipei) : visage de face, bonnet blanc, barbe grise. Cadrage serré sur le buste. | Wikimedia Commons, article « Gengis Khan », domaine public |
| `mongol_paiza_gerege_messenger_tablet_yuan_dynasty` | partie 3 | 3:4 | Une paiza (gerege), la plaque-laissez-passer en métal que portaient les messagers du yam pour obtenir chevaux et vivres aux relais : tablette verticale en fer incrustée d'argent avec inscription en écriture phags-pa, XIIIe-XIVe siècle. | Metropolitan Museum of Art (Open Access, domaine public), objet « Paiza » 1993.256, ou Wikimedia Commons catégorie « Paiza » |
| `mongol_warriors_battle_rashid_al_din_1305` | partie 4 | 4:3 | Miniature du Jami al-Tawarikh de Rashid al-Din (vers 1305-1314) montrant des cavaliers mongols en armure lançant l'assaut, arcs bandés, contre une ville ou une armée ennemie. | Wikimedia Commons, catégorie « Jami' al-tawarikh » (Bibliothèque de l'université d'Édimbourg ou BnF), domaine public |

### 251 · Pourquoi Londres a-t-elle brûlé en 1666 ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Benjamin Campbell

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `great_fire_london_1666_thames_painting` | hero + couverture | 16:9 | Le tableau anonyme « The Great Fire of London » (école hollandaise, vers 1675, Museum of London) : la ville en flammes vue depuis la Tamise, l'ancienne cathédrale Saint-Paul et le pont de Londres dans la fumée, barques de fuyards au premier plan. Panorama large. | Wikimedia Commons, catégorie « Great Fire of London in art », domaine public |
| `hollar_map_london_burnt_area_1666` | partie 1 | 4:3 | Le plan de Wenceslaus Hollar (1666) montrant la zone détruite par l'incendie : la Cité de Londres vue à vol d'oiseau, le quartier brûlé laissé en blanc, la Tamise en bas. | Wikimedia Commons, article « Great Fire of London », plan de Hollar « A map or groundplot of the citty of London », domaine public |
| `great_fire_london_ludgate_fleeing_crowd_painting` | partie 3 | 4:3 | Le tableau « The Great Fire of London, with Ludgate and Old St Paul's » (vers 1670, Yale Center for British Art) : la foule fuyant à pied et en charrette par la porte de Ludgate, la cathédrale en feu derrière. | Wikimedia Commons ou Yale Center for British Art (domaine public) |
| `monument_great_fire_london_pudding_lane` | partie 4 | 3:4 | Le Monument au grand incendie de Londres (colonne dorique de Wren et Hooke, 1677, urne dorée au sommet) près de Pudding Lane, photographié en contre-plongée, ciel dégagé. | Wikimedia Commons, catégorie « Monument to the Great Fire of London » (CC BY-SA), ou Unsplash |

### 252 · La vie au Moyen Âge était-elle vraiment si misérable ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Benjamin Campbell

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `tres_riches_heures_berry_june_haymaking` | hero + couverture | 16:9 | La miniature du mois de juin des Très Riches Heures du duc de Berry (frères de Limbourg, vers 1412-1416) : paysans fauchant et ratissant le foin devant le palais de la Cité à Paris. Recadrer sur la scène des champs, sans le calendrier du haut. | Wikimedia Commons, catégorie « Très Riches Heures du duc de Berry », musée Condé (Chantilly), domaine public |
| `luttrell_psalter_ploughing_scene_14th_century` | partie 1 | 3:2 | La scène de labour du Psautier de Luttrell (Angleterre, vers 1325-1340) : un paysan guidant une charrue tirée par des bœufs, en marge du manuscrit. Bandeau horizontal. | Wikimedia Commons, catégorie « Luttrell Psalter », British Library Add MS 42130, domaine public |
| `tacuinum_sanitatis_medieval_bread_baking_illumination` | partie 2 | 3:4 | Une enluminure du Tacuinum Sanitatis (Italie du Nord, fin XIVe siècle) montrant la cuisson du pain au four ou la vente de pain : boulanger, four voûté, miches. Folio vertical. | Wikimedia Commons, catégorie « Tacuinum Sanitatis » (BnF ou ÖNB Vienne), domaine public |
| `medieval_public_bathhouse_illumination_15th_century` | partie 3 | 4:3 | L'enluminure d'un bain public médiéval (Valère Maxime, Faits et dits mémorables, vers 1470) : baigneurs dans des cuves de bois, table dressée, serviteurs versant l'eau. | Wikimedia Commons, catégorie « Bathhouses in medieval art » (Staatsbibliothek Berlin, Dep. Breslau 2), domaine public |

### 253 · Pourquoi l'imprimerie a-t-elle tout changé ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Benjamin Campbell

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `gutenberg_bible_open_pages_library_of_congress` | hero + couverture | 16:9 | La Bible de Gutenberg (vers 1455) ouverte sur une double page : deux colonnes de caractères gothiques, lettrines et rinceaux peints à la main. Photo large sur le livre entier, exemplaire de la Library of Congress ou de la BnF. | Library of Congress (domaine public) ou Wikimedia Commons, catégorie « Gutenberg Bible » |
| `movable_metal_type_letters_composing_stick` | partie 1 | 3:2 | Gros plan sur des caractères mobiles en plomb alignés dans un composteur, lettres inversées lisibles, casse de typographe en arrière-plan. Photo horizontale. | Unsplash / Pexels « movable type » ou Wikimedia Commons, catégorie « Movable type » |
| `jost_amman_printing_shop_woodcut_1568` | partie 2 | 3:4 | La gravure sur bois « Der Buchdrucker » de Jost Amman (Ständebuch, 1568) : un atelier d'imprimerie avec la presse à bras, l'encreur aux tampons et le compositeur devant sa casse. | Wikimedia Commons, article « Jost Amman » ou catégorie « Ständebuch (1568) », domaine public |
| `luther_ninety_five_theses_1517_printed_broadsheet` | partie 3 | 3:4 | L'affiche imprimée des 95 thèses de Martin Luther (placard de Nuremberg, 1517) : texte latin en colonnes serrées, titre en grands caractères. Document vertical. | Wikimedia Commons, article « Quatre-vingt-quinze thèses », Staatsbibliothek Berlin, domaine public |

### 254 · Qui a vendu un faux Vermeer à Göring ?

Matière : art · Rubrique : Peinture & mouvements · Prof : Dusan Nikolic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `han_van_meegeren_painting_under_guard_1945` | hero + couverture | 16:9 | Photo de 1945 : Han van Meegeren, pinceau à la main devant un chevalet, peint son dernier « Vermeer » (Jésus parmi les docteurs) sous surveillance pour prouver qu'il est bien le faussaire ; cadrage large sur l'homme et la toile. | Wikimedia Commons, catégorie « Han van Meegeren », photo Nationaal Archief / Anefo (Koos Raucamp, 1945), CC0 |
| `van_meegeren_supper_at_emmaus_1937_boijmans` | partie 2 | 4:3 | Le tableau Les Pèlerins d'Emmaüs (1937) peint par Van Meegeren dans la manière du « Vermeer biblique », authentifié par Bredius et conservé au musée Boijmans Van Beuningen de Rotterdam : vue complète de la toile. | Wikimedia Commons, article « Les Pèlerins d'Emmaüs (Van Meegeren) » / catégorie « Paintings by Han van Meegeren », domaine public (auteur mort en 1947) |
| `van_meegeren_christ_and_the_adulteress_1942_goring` | partie 3 | 1:1 | Le faux Vermeer Le Christ et la femme adultère (1942), toile presque carrée vendue à Hermann Göring via Alois Miedl et retrouvée en 1945 dans les collections de Carinhall : vue complète. | Wikimedia Commons, article « Le Christ et la femme adultère (Van Meegeren) » / catégorie « Paintings by Han van Meegeren », domaine public |
| `han_van_meegeren_trial_amsterdam_courtroom_1947` | partie 4 | 3:2 | Photo du procès d'octobre-novembre 1947 à Amsterdam : Van Meegeren debout devant le tribunal, ses faux Vermeer accrochés dans la salle d'audience comme pièces à conviction. | Wikimedia Commons, catégorie « Han van Meegeren », photos Nationaal Archief / Anefo du procès (29 octobre 1947), CC0 |

### 255 · Comment un roman a-t-il sauvé Notre-Dame ?

Matière : art · Rubrique : Cinéma, photo & architecture · Prof : Dusan Nikolic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `notre_dame_de_paris_cathedral_facade` **(existante)** | hero + couverture | 16:9 | Façade occidentale de Notre-Dame vue du parvis, les deux tours et la galerie des rois bien lisibles : photo existante (Dietmar Rabich, 2014) à recadrer en 16:9 sur les tours et copier dans ios/Sophia/CourseImages. | Déjà en place : content/images/notre_dame_de_paris_cathedral_facade.jpg (Wikimedia Commons, CC BY-SA 4.0, crédit déjà renseigné) |
| `notre_dame_kings_of_judah_heads_musee_cluny` | partie 1 | 4:3 | Les têtes des rois de Juda de la galerie des rois, décapitées en 1793 et retrouvées en 1977, alignées au musée de Cluny : pierre mutilée, traces de polychromie. | Wikimedia Commons, catégorie « Heads of the Kings of Judah (Musée de Cluny) », CC BY-SA |
| `victor_hugo_notre_dame_de_paris_1831_first_edition` | partie 2 | 3:4 | Page de titre de l'édition originale de Notre-Dame de Paris (Charles Gosselin, Paris, 1831), ou le frontispice de l'édition illustrée de 1844 montrant la cathédrale : document vertical. | Wikimedia Commons, catégorie « Notre-Dame de Paris (novel) » ; Gallica / BnF, domaine public |
| `notre_dame_paris_fire_15_april_2019_spire_collapse` | partie 4 | 3:2 | Photo du 15 avril 2019 : Notre-Dame en flammes vue depuis les quais de la Seine, la flèche de Viollet-le-Duc en feu ou en train de s'effondrer, fumée jaune au-dessus des tours. | Wikimedia Commons, catégorie « Notre-Dame de Paris fire (2019) », CC BY-SA |

### 256 · Pourquoi a-t-on peint les parois de Lascaux ?

Matière : art · Rubrique : Œuvres iconiques · Prof : Dusan Nikolic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `lascaux_cave_hall_of_the_bulls_paintings` | hero + couverture | 16:9 | La salle des Taureaux : vue large de la paroi avec les grands aurochs noirs et les chevaux ocre qui se chevauchent, éclairage chaud, sans visiteur au premier plan (original ou fac-similé Lascaux II/IV). | Wikimedia Commons, catégorie « Lascaux » / « Hall of the Bulls », photos CC BY-SA (ex. Prof saxx) ; à défaut, photothèque du Centre international de l'art pariétal (Lascaux IV) |
| `lascaux_axial_gallery_chinese_horse_painting` | partie 1 | 4:3 | Le « cheval chinois » du Diverticule axial : cheval jaune et noir entouré de signes (traits, points, flèches) peints sur la paroi calcaire. | Wikimedia Commons, catégorie « Lascaux » (fichiers « Lascaux painting », « Cheval chinois »), CC BY-SA / domaine public |
| `magdalenian_bone_harpoons_upper_paleolithic_tools` | partie 2 | 4:3 | Harpons et sagaies en bois de renne ou en os de la culture magdalénienne (vers 17 000-12 000 av. J.-C.), posés à plat sur fond neutre, vitrine du musée d'Archéologie nationale ou photo de collection. | Wikimedia Commons, catégorie « Magdalenian » / « Magdalenian harpoons » (musée d'Archéologie nationale, Saint-Germain-en-Laye ; musée de Toulouse), CC BY-SA |
| `lascaux_shaft_scene_bird_headed_man_bison` | partie 3 | 4:3 | La scène du Puits : l'homme à tête d'oiseau renversé devant le bison éventré, le bâton à oiseau et le rhinocéros à gauche, peinture noire sur paroi claire. | Wikimedia Commons, catégorie « Lascaux » (fichier « Lascaux 01 » / « Scène du Puits »), domaine public ou CC BY-SA |

### 257 · Qui a fait de la Vénus de Milo un chef-d'œuvre ?

Matière : art · Rubrique : Œuvres iconiques · Prof : Dusan Nikolic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `venus_de_milo_louvre_gallery_wide_view` | hero + couverture | 16:9 | La Vénus de Milo dans sa galerie du Louvre, vue de trois quarts face, statue entière au centre du cadre avec l'espace du musée autour, lumière douce, peu ou pas de visiteurs. | Wikimedia Commons, catégorie « Venus de Milo », photos CC BY-SA / CC0 (ex. Livioandronico2013, Jastrow) ; Unsplash « Venus de Milo Louvre » |
| `olivier_voutier_drawing_venus_de_milo_1820` | partie 1 | 4:3 | Le croquis d'Olivier Voutier fait sur place en avril 1820 : la statue en deux blocs, les hermès et les fragments alignés devant la niche, dessin au crayon ou à l'encre. À défaut, le théâtre antique de Milos, à côté du lieu de la découverte. | Wikimedia Commons, article « Olivier Voutier » / « Vénus de Milo » (dessin de Voutier, domaine public) ; fallback : catégorie « Ancient theatre of Milos » |
| `venus_de_milo_arms_reconstruction_furtwangler_1893` | partie 2 | 3:4 | Dessin de reconstitution d'Adolf Furtwängler (Meisterwerke der griechischen Plastik, 1893) : la Vénus le bras gauche appuyé sur un pilier, la pomme dans la main, document vertical en noir et blanc. | Wikimedia Commons, article « Vénus de Milo » (section reconstitutions) / archive.org « Masterpieces of Greek Sculpture », 1895, domaine public |
| `venus_de_milo_louvre_19th_century_photograph` | partie 3 | 4:3 | Photographie ou gravure du XIXe siècle montrant la Vénus de Milo exposée au Louvre, seule sur son socle au fond de sa salle, avec quelques visiteurs en costume d'époque : l'icône mise en scène par la France. | Wikimedia Commons, catégorie « Venus de Milo – historical images » / « Venus de Milo in art » (photos Adolphe Braun, Neurdein, stéréoscopies vers 1860-1900), domaine public |

### 258 · Qui s'est vraiment enrichi pendant la ruée vers l'or ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Elizabeth Singer Hunt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `miners_in_the_sierras_nahl_1852_painting` | hero + couverture | 16:9 | Le tableau « Miners in the Sierras » de Charles Christian Nahl et August Wenderoth (1851-1852) : des chercheurs d'or au travail sur un sluice au bord d'un torrent de la Sierra Nevada, paysage large avec cabane et montagnes en arrière-plan. | Wikimedia Commons / Smithsonian American Art Museum (domaine public) |
| `the_way_they_go_to_california_currier_1849_lithograph` | partie 2 | 4:3 | Lithographie satirique de Nathaniel Currier « The Way They Go to California » (1849) : une foule se bousculant sur le quai pour embarquer vers la Californie, navires à quai et engins volants fantaisistes dans le ciel. | Wikimedia Commons / Library of Congress (domaine public) |
| `gold_miners_auburn_ravine_1852_daguerreotype` | partie 3 | 3:2 | Daguerréotype « Head of Auburn Ravine » (1852) : des mineurs, dont plusieurs Chinois, posant devant un long tom et une rigole d'eau dans un ravin aurifère de Californie, outils à la main. | Wikimedia Commons, catégorie « California Gold Rush » / California State Library (domaine public) |
| `sam_brannan_portrait_daguerreotype_1850s` | partie 4 | 1:1 | Portrait photographique de Samuel Brannan, marchand et éditeur de San Francisco devenu le premier millionnaire de Californie, buste de face en redingote, vers 1850-1860. | Wikimedia Commons, « Samuel Brannan » (domaine public) |

### 259 · Pourquoi Amundsen a-t-il battu Scott au pôle Sud ?

Matière : histoire · Rubrique : Révolutions & conflits modernes · Prof : Elizabeth Singer Hunt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `amundsen_party_south_pole_polheim_december_1911` | hero + couverture | 16:9 | Photographie d'Olav Bjaaland au pôle Sud, mi-décembre 1911 : Amundsen et ses compagnons debout devant la tente « Polheim » surmontée du drapeau norvégien, sur la plaine de neige à perte de vue. | Wikimedia Commons, catégorie « Amundsen's South Pole expedition » / Nasjonalbiblioteket (domaine public) |
| `roald_amundsen_portrait_fur_parka_photograph` | partie 1 | 1:1 | Portrait photographique de Roald Amundsen en parka de fourrure, capuche relevée, visage buriné, années 1900-1910. | Wikimedia Commons, catégorie « Roald Amundsen » (domaine public) |
| `scott_shackleton_wilson_discovery_expedition_1902` | partie 2 | 3:2 | Photo du 2 novembre 1902 : Shackleton, Scott et Wilson posant en tenue polaire devant le navire Discovery avant leur marche vers le sud, fanions de traîneau visibles. | Wikimedia Commons, catégorie « Discovery Expedition » (domaine public) |
| `scott_party_at_south_pole_january_1912_bowers` | partie 4 | 4:3 | La photo déclenchée par Henry Bowers au pôle Sud le 18 janvier 1912 : Scott, Wilson, Oates, Evans et Bowers, visages épuisés, posant devant l'Union Jack après avoir trouvé la tente d'Amundsen. | Wikimedia Commons, catégorie « Terra Nova Expedition » / Scott Polar Research Institute (domaine public) |

### 260 · D'où viennent les super-héros ?

Matière : litterature · Rubrique : Anglo-saxons & littérature mondiale · Prof : Elizabeth Singer Hunt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `superman_fleischer_cartoon_1941_flying_metropolis` | hero + couverture | 16:9 | Photogramme du premier dessin animé Superman des studios Fleischer (1941) : Superman en vol au-dessus des gratte-ciel de Metropolis, style Art déco, couleurs saturées, plan large. | Wikimedia Commons, catégorie « Superman (1941 film) » (domaine public, droits non renouvelés) |
| `heracles_fighting_amazons_attic_black_figure_amphora` | partie 2 | 4:3 | Amphore attique à figures noires (VIe siècle av. J.-C.) montrant Héraclès combattant les Amazones pour s'emparer de la ceinture d'Hippolyte, détail du décor bien lisible. | Wikimedia Commons, catégorie « Heracles and the Amazons » (British Museum / Louvre, domaine public) |
| `samson_slaying_the_lion_cranach_1525_painting` | partie 3 | 4:3 | Tableau de Lucas Cranach l'Ancien « Samson terrassant le lion » (vers 1525) : Samson à cheval sur le lion lui ouvrant la gueule à mains nues, paysage à l'arrière-plan. | Wikimedia Commons, catégorie « Samson and the lion » (Schlossmuseum Weimar, domaine public) |
| `thor_hammer_mjolnir_norse_god_painting` **(existante)** | partie 4 | 3:4 | Image déjà disponible : peinture du XIXe siècle représentant Thor brandissant son marteau Mjöllnir, le dieu nordique que Stan Lee et Jack Kirby réinventent chez Marvel en 1962. | Déjà dans content/images (réutilisation) |

### 261 · A-t-on vraiment tout perdu dans l'incendie d'Alexandrie ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Ezgi Gizem Berkay

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `alexandria_library_fire_goll_1876_wood_engraving` | hero + couverture | 16:9 | La gravure sur bois d'Hermann Göll (1876) montrant la bibliothèque d'Alexandrie en flammes : colonnades antiques, fumée, foule en fuite. C'est l'image même qui a fixé le mythe ; cadrage large sur l'incendie. | Wikimedia Commons, « The Burning of the Library at Alexandria » (Hermann Göll, Die Weisen und Gelehrten des Alterthums, 1876), domaine public |
| `oxyrhynchus_greek_papyrus_fragment_ancient_text` | partie 1 | 4:3 | Un fragment de papyrus grec antique aux bords effrités, texte à l'encre noire sur fibres brunes (papyrus d'Oxyrhynque, Égypte, Ier-IIIe siècle), pour montrer la fragilité des rouleaux. | Wikimedia Commons, catégorie « Oxyrhynchus Papyri » (domaine public) |
| `abbasid_library_scholars_al_wasiti_1237_maqamat` | partie 2 | 4:3 | La miniature de Yahya al-Wasiti (1237) dans les Maqamat d'al-Hariri : des savants discutent dans une bibliothèque, étagères pleines de manuscrits derrière eux. | Wikimedia Commons, « Maqamat al-Hariri », BnF Arabe 5847, folio 5v (domaine public) |
| `pompeys_pillar_serapeum_ruins_alexandria_photo` | partie 3 | 3:2 | La colonne de Pompée dressée au milieu des ruines du Sérapéum à Alexandrie, seuls vestiges du sanctuaire détruit en 391, photo couleur, ciel dégagé. | Wikimedia Commons, catégorie « Pompey's Pillar (Alexandria) » (CC BY-SA) ou Unsplash |

### 262 · Comment Pompéi a-t-elle disparu en dix-huit heures ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Ezgi Gizem Berkay

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `pompeii_forum_ruins_mount_vesuvius_background` | hero + couverture | 16:9 | Le forum de Pompéi au grand angle : colonnes et dallage au premier plan, le Vésuve en arrière-plan, lumière du jour, peu de visiteurs. | Wikimedia Commons, catégorie « Forum (Pompeii) » (CC BY-SA) ou Unsplash |
| `pompeii_via_dell_abbondanza_street_stepping_stones` | partie 1 | 3:2 | Une rue pavée de Pompéi (via dell'Abbondanza) avec ses pierres de passage surélevées, les ornières de chars et les façades de boutiques. | Wikimedia Commons, catégorie « Via dell'Abbondanza (Pompeii) » (CC BY-SA) ou Unsplash |
| `last_day_of_pompeii_bryullov_1833_painting` | partie 2 | 4:3 | « Le Dernier Jour de Pompéi » de Karl Brioullov (1833, Musée russe, Saint-Pétersbourg) : la foule fuyant sous la pluie de pierres, statues qui basculent, ciel embrasé. | Wikimedia Commons, « The Last Day of Pompeii » (domaine public) |
| `pompeii_plaster_casts_victims_garden_of_fugitives` | partie 4 | 3:2 | Les moulages en plâtre des victimes dans le Jardin des Fugitifs à Pompéi, corps recroquevillés alignés sous leur vitrine. | Wikimedia Commons, catégorie « Garden of the Fugitives (Pompeii) » (CC BY-SA) |

### 263 · À quoi servait vraiment la route de la soie ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Ezgi Gizem Berkay

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `silk_road_camel_caravan_dunhuang_sand_dunes` | hero + couverture | 16:9 | Une caravane de chameaux de Bactriane en file dans les dunes près de Dunhuang (Gansu, Chine), lumière rasante, cadrage large. | Unsplash / Pexels (« camel caravan Dunhuang ») ou Wikimedia Commons, catégorie « Mingsha Shan » |
| `mogao_caves_dunhuang_buddhist_mural_silk_road` | partie 1 | 4:3 | Une peinture murale bouddhique des grottes de Mogao à Dunhuang (époque Tang, VIIe-IXe siècle) : bodhisattvas ou scène de paradis, pour l'arrivée du bouddhisme en Chine par la route. | Wikimedia Commons, catégorie « Mogao Caves » (domaine public) |
| `plague_in_rome_delaunay_1869_painting_orsay` | partie 2 | 4:3 | « Peste à Rome » de Jules-Élie Delaunay (1869, musée d'Orsay) : l'ange exterminateur frappant une porte, cadavres au pied d'une statue antique. | Wikimedia Commons, « La Peste à Rome » (domaine public) |
| `yersinia_pestis_bacteria_electron_micrograph` | partie 3 | 4:3 | Micrographie électronique à balayage de la bactérie Yersinia pestis (bacilles colorisés sur fond sombre), pour le passage sur l'ADN ancien de la peste de Justinien. | NIAID (Flickr, CC BY) ou CDC Public Health Image Library (domaine public) |

### 264 · Qui a vraiment construit les pyramides ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Ezgi Gizem Berkay

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `giza_pyramids_khufu_khafre_menkaure_wide_view` | hero + couverture | 16:9 | Les trois pyramides de Gizeh alignées, vue large depuis le plateau désertique au sud-ouest, ciel dégagé, sans foule. Attention : l'image existante « egyptian_pyramids_sahara_desert » montre en réalité le temple d'Hatchepsout, pas les pyramides. | Unsplash / Pexels ou Wikimedia Commons, catégorie « Giza pyramid complex » (CC BY-SA) |
| `great_pyramid_khufu_limestone_blocks_close_up` | partie 1 | 3:2 | Gros plan sur les assises de blocs de calcaire de la Grande Pyramide, avec une personne pour donner l'échelle des blocs. | Unsplash / Pexels ou Wikimedia Commons, catégorie « Great Pyramid of Giza » (CC BY-SA) |
| `diary_of_merer_papyrus_wadi_al_jarf` | partie 2 | 4:3 | Un fragment du papyrus de Merer (Wadi al-Jarf, règne de Khéops), écriture hiératique en colonnes rouges et noires, exposé au Musée égyptien du Caire. | Wikimedia Commons, catégorie « Diary of Merer » (CC BY-SA) |
| `giza_plateau_nile_valley_satellite_view_nasa` | partie 4 | 4:3 | Vue satellite ou photo depuis l'ISS du plateau de Gizeh : les pyramides à la lisière du désert, la vallée verte du Nil et Le Caire juste à côté. | NASA Earth Observatory / photos ISS (domaine public) |

### 265 · Pourquoi les Spartiates étaient-ils si redoutables ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Ezgi Gizem Berkay

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `young_spartans_exercising_degas_painting_1860` | hero + couverture | 16:9 | « Petites filles spartiates provoquant des garçons » d'Edgar Degas (vers 1860, National Gallery, Londres) : jeunes filles et garçons face à face dans un paysage nu, toile en format large. | Wikimedia Commons, « Young Spartans Exercising » (domaine public) |
| `delphi_temple_of_apollo_ruins_oracle_greece` | partie 1 | 3:2 | Les colonnes du temple d'Apollon à Delphes avec les pentes du Parnasse derrière, là où l'oracle aurait ratifié les lois de Lycurgue. | Unsplash / Pexels ou Wikimedia Commons, catégorie « Temple of Apollo (Delphi) » (CC BY-SA) |
| `spartan_running_girl_bronze_statuette_british_museum` | partie 2 | 1:1 | La statuette en bronze d'une jeune fille spartiate courant, tunique courte relevée (atelier laconien, vers 520-500 av. J.-C., British Museum), fond neutre. | Wikimedia Commons, « Bronze figure of a running girl », British Museum (CC BY-SA) |
| `hoplite_phalanx_chigi_vase_corinthian_650_bc` | partie 3 | 4:3 | Détail de la frise du vase Chigi (vers 650-640 av. J.-C., Villa Giulia, Rome) : deux phalanges d'hoplites casqués, boucliers ronds levés, avançant au son de l'aulos. | Wikimedia Commons, catégorie « Chigi vase » (domaine public) |

### 266 · Pourquoi y a-t-il du cobalt dans nos batteries ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Guido Manuel De La Torre Olvera

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `cobalt_copper_open_pit_mine_kolwezi_drc` | hero + couverture | 16:9 | Vue large d'une mine à ciel ouvert de cuivre-cobalt de la région de Kolwezi (Katanga, RDC) : gradins en terrasses, roche verte et bleue, engins minuscules au fond ; photo aérienne ou en plongée, sans personnage au premier plan. | Wikimedia Commons, catégories « Mining in Lualaba Province » et « Cobalt mining in the Democratic Republic of the Congo » (photos Fairphone, CC BY) ; à défaut Unsplash « open pit copper mine ». |
| `john_goodenough_portrait_lithium_battery_inventor` | partie 1 | 1:1 | Portrait de John B. Goodenough, co-inventeur de la cathode lithium-cobalt en 1980, en buste, de préférence la photo de 2019 lors du prix Nobel de chimie ou un portrait officiel de l'université du Texas. | Wikimedia Commons, catégorie « John B. Goodenough » (photos Nobel Media / Royal Society, CC BY-SA). |
| `lithium_ion_battery_fire_thermal_runaway_test` | partie 2 | 4:3 | Une batterie lithium-ion en emballement thermique : flammes et jet de gaz sortant d'une cellule ou d'un téléphone lors d'un test en laboratoire ; à défaut, une batterie de téléphone gonflée et noircie. | Wikimedia Commons, catégories « Lithium-ion battery fires » et « Swollen lithium polymer batteries » ; photos de tests FAA / NTSB (domaine public, gouvernement américain). |
| `artisanal_cobalt_miners_kolwezi_congo` | partie 4 | 3:2 | Mineurs artisanaux adultes creusant ou triant le minerai de cobalt à la main, sans machine, près de Kolwezi (RDC) ; sacs de minerai, outils rudimentaires ; aucun enfant identifiable. | Wikimedia Commons, catégorie « Artisanal mining in the Democratic Republic of the Congo » (photos Fairphone et Julien Harneis, CC BY-SA). |

### 267 · Qui a tué le premier câble transatlantique ?

Matière : sciences · Rubrique : Découvertes qui ont changé le monde · Prof : Guido Manuel De La Torre Olvera

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `hms_agamemnon_laying_atlantic_telegraph_cable_1858` | hero + couverture | 16:9 | Le HMS Agamemnon déroulant le câble télégraphique en plein Atlantique en 1858, une baleine croisant la ligne : peinture ou gravure d'époque, navire au centre, ciel et mer larges. | Wikimedia Commons, catégorie « Transatlantic telegraph cable (1858) » : peinture de Robert Charles Dudley (Metropolitan Museum, domaine public) ou gravures de l'Illustrated London News. |
| `new_york_atlantic_cable_celebration_september_1858` | partie 1 | 4:3 | La fête new-yorkaise du 1er septembre 1858 en l'honneur du câble : défilé aux flambeaux ou feu d'artifice devant l'hôtel de ville, foule et drapeaux ; gravure de presse d'époque. | Wikimedia Commons et Library of Congress : gravures de Frank Leslie's Illustrated Newspaper et Harper's Weekly, septembre 1858 (domaine public). |
| `thomson_mirror_galvanometer_1858_instrument` | partie 3 | 4:3 | Le galvanomètre à miroir de William Thomson (futur lord Kelvin) : petit instrument en laiton avec bobine, miroir suspendu et échelle graduée, du type utilisé pour lire les signaux du câble de 1858 ; photo de musée sur fond neutre. | Wikimedia Commons, catégories « Mirror galvanometers » et « Kelvin galvanometers » ; Science Museum Group Collection (CC BY), Hunterian Museum de Glasgow. |
| `atlantic_telegraph_cable_1858_cross_section_sample` | partie 4 | 4:3 | Un tronçon du câble atlantique de 1858 vu en coupe : sept fils de cuivre torsadés au centre, gaine de gutta-percha, armure de fils de fer ; échantillon-souvenir vendu par Tiffany ou pièce de musée. | Wikimedia Commons, catégorie « Transatlantic telegraph cable (1858) » ; Smithsonian National Museum of American History (CC0) ; Science Museum Group. |

### 268 · Pourquoi le violet est-il la couleur des rois ?

Matière : sciences · Rubrique : Découvertes qui ont changé le monde · Prof : Guido Manuel De La Torre Olvera

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `justinian_mosaic_san_vitale_ravenna_purple_robe` | hero + couverture | 16:9 | La mosaïque de Justinien à Saint-Vital de Ravenne (vers 547) : l'empereur en chlamyde pourpre au centre, entouré de sa cour et du clergé, cadrage horizontal sur le panneau entier. | Wikimedia Commons, catégorie « Mosaic of Justinianus I (Basilica of San Vitale) » (œuvre du domaine public, photos CC BY-SA). |
| `bolinus_brandaris_murex_shells_tyrian_purple` | partie 2 | 4:3 | Coquilles de murex épineux (Bolinus brandaris ou Hexaplex trunculus), plusieurs exemplaires en gros plan sur fond neutre, épines et canal siphonal bien visibles. | Wikimedia Commons, catégories « Bolinus brandaris » et « Hexaplex trunculus » (photos H. Zell et musées d'histoire naturelle, CC BY-SA). |
| `murex_dyed_wool_shades_purple_to_tekhelet_blue` | partie 3 | 4:3 | Écheveaux ou échantillons de laine teints au murex, alignés pour montrer la gamme du rouge-pourpre au bleu tekhelet obtenue à partir du même escargot. | Wikimedia Commons, catégories « Tyrian purple » et « Tekhelet » (photos CC BY-SA d'expériences de teinture au Hexaplex trunculus, association Ptil Tekhelet). |

### 269 · Pourquoi personne ne sourit sur les vieilles photos ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Guido Manuel De La Torre Olvera

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `victorian_family_daguerreotype_unsmiling_portrait` | hero + couverture | 16:9 | Portrait de studio du XIXe siècle (daguerréotype ou ambrotype, 1845-1870) : un couple ou une famille assis côte à côte, regard fixe vers l'objectif, bouches fermées, cadrage horizontal serré sur les visages. | Wikimedia Commons, catégories « Daguerreotypes of groups » et « Daguerreotype portraits of families » ; Library of Congress (domaine public). |
| `daguerre_boulevard_du_temple_1838_first_person` | partie 1 | 4:3 | Le daguerréotype « Boulevard du Temple » de Daguerre (1838) : la rue parisienne vide de passants et de voitures, avec en bas à gauche l'homme immobile qui se fait cirer les bottes, premier humain photographié. | Wikimedia Commons, article « Boulevard du Temple (daguerréotype) » (domaine public). |
| `robert_cornelius_self_portrait_1839_daguerreotype` | partie 2 | 1:1 | L'autoportrait de Robert Cornelius (Philadelphie, octobre 1839), plus ancien autoportrait photographique : jeune homme aux cheveux en désordre, bras croisés, regard de côté, sans sourire. | Wikimedia Commons / Library of Congress, « Robert Cornelius, self-portrait, 1839 » (domaine public). |
| `frans_hals_malle_babbe_laughing_woman_painting` | partie 3 | 4:3 | « Malle Babbe » de Frans Hals (vers 1633-1635, Gemäldegalerie de Berlin) : femme riant à pleines dents, chope à la main, chouette sur l'épaule, l'exemple du grand rire peint comme signe de folie ou d'ivresse. | Wikimedia Commons, article « Malle Babbe » (domaine public). |

### 270 · Pourquoi la Yougoslavie a-t-elle éclaté ?

Matière : comprendreLeMonde · Rubrique : Conflits & géopolitique · Prof : Ivana Toskovic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `sarajevo_siege_building_burning_1992` | hero + couverture | 16:9 | Sarajevo assiégée en 1992 : le bâtiment du Conseil exécutif (ou le Parlement) en flammes, vu de la rue, avec les tours modernes de la ville en fond. Photo de presse d'époque, cadrage large. | Wikimedia Commons, photo de Mikhail Evstafiev « Evstafiev-sarajevo-building-burns » (CC BY-SA 3.0), catégorie « Siege of Sarajevo » |
| `josip_broz_tito_portrait_marshal_uniform` | partie 1 | 1:1 | Portrait officiel de Josip Broz Tito en uniforme de maréchal, buste, années 1960-1970. | Wikimedia Commons, catégorie « Josip Broz Tito » : portraits officiels ou photos de la visite à la Maison-Blanche en 1971 (US National Archives, domaine public) |
| `yugoslav_500_billion_dinar_banknote_1993` | partie 2 | 3:2 | Le billet de 500 milliards de dinars yougoslaves émis en 1993, à plat, recto lisible : symbole de l'hyperinflation qui accompagne l'éclatement du pays. | Wikimedia Commons, catégorie « Banknotes of Yugoslavia » ou article « Yugoslav dinar » (billet 500 000 000 000 dinara, 1993) |
| `srebrenica_potocari_memorial_gravestones` | partie 3 | 3:2 | Les rangées de stèles blanches du mémorial de Potočari, près de Srebrenica, sous un ciel clair, sans personnage au premier plan. | Wikimedia Commons, catégorie « Srebrenica–Potočari Memorial and Cemetery » (CC BY-SA) |

### 271 · Pourquoi les États-Unis sont-ils si puissants ?

Matière : comprendreLeMonde · Rubrique : Conflits & géopolitique · Prof : Ivana Toskovic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `us_navy_aircraft_carrier_at_sea` | hero + couverture | 16:9 | Un porte-avions américain de classe Nimitz en haute mer, vu de trois quarts depuis les airs, avions de chasse alignés sur le pont, escorteurs à l'horizon. Photo couleur nette, sujet au centre. | US Navy / DVIDS, reprise sur Wikimedia Commons, catégorie « Nimitz-class aircraft carriers » (domaine public, gouvernement fédéral américain) |
| `bretton_woods_conference_1944_delegates` | partie 1 | 3:2 | Les délégués de la conférence de Bretton Woods réunis à l'hôtel Mount Washington en juillet 1944 (séance plénière ou photo de groupe), à l'origine du FMI et du rôle central du dollar. | Wikimedia Commons, catégorie « Bretton Woods Conference » (photos du gouvernement américain / ONU, domaine public) |
| `immigrants_ellis_island_new_york_1900s` | partie 2 | 3:2 | Immigrants européens débarquant à Ellis Island vers 1900-1910, bagages à la main, dans la grande salle d'enregistrement ou sur le quai face à Manhattan. Photo noir et blanc d'archives. | Library of Congress (photos de Lewis Hine ou Bain News Service), Wikimedia Commons catégorie « Ellis Island immigrants » (domaine public) |
| `hollywood_sign_los_angeles_film_industry` **(existante)** | partie 4 | 3:2 | Le panneau Hollywood sur les collines de Los Angeles, symbole de la culture américaine exportée dans le monde entier (image déjà utilisée dans l'app). | Déjà disponible : content/images/hollywood_sign_los_angeles_film_industry.jpg |

### 272 · Pourquoi la Corée est-elle coupée en deux ?

Matière : comprendreLeMonde · Rubrique : Conflits & géopolitique · Prof : Ivana Toskovic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `panmunjom_joint_security_area_blue_huts` | hero + couverture | 16:9 | Les baraques bleues de la Joint Security Area à Panmunjom, soldats sud-coréens au garde-à-vous face au bâtiment nord-coréen, ligne de démarcation visible au sol. Cadrage large, sujet centré. | Wikimedia Commons, catégorie « Joint Security Area » (photos de l'US Army / Department of Defense, domaine public) |
| `korea_38th_parallel_division_map_1945` | partie 1 | 4:3 | Carte de la péninsule coréenne en 1945 partagée au 38e parallèle : zone d'occupation soviétique au nord, américaine au sud, Séoul et Pyongyang indiqués. Carte existante, lisible sur téléphone. | Wikimedia Commons, catégorie « Division of Korea » (cartes CIA / gouvernement américain, domaine public, ou cartes CC BY-SA) |
| `republic_of_korea_founding_ceremony_seoul_1948` | partie 2 | 3:2 | La cérémonie de proclamation de la République de Corée à Séoul le 15 août 1948, foule et tribune officielle devant l'ancien bâtiment du gouvernement général, avec Syngman Rhee et le général MacArthur. | Wikimedia Commons, article « First Republic of Korea » / catégorie « Syngman Rhee » (photos du gouvernement coréen ou de l'US Army, domaine public) |
| `korean_war_refugees_fleeing_south_1951` | partie 3 | 3:2 | Colonne de réfugiés coréens fuyant vers le sud pendant l'hiver 1950-1951, baluchons sur la tête, route enneigée ou pont détruit. Photo noir et blanc d'archives militaires américaines. | Wikimedia Commons, catégorie « Refugees of the Korean War » (US Army / National Archives, domaine public) |

### 273 · Pourquoi la Suisse n'est-elle jamais en guerre ?

Matière : comprendreLeMonde · Rubrique : Conflits & géopolitique · Prof : Ivana Toskovic

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `swiss_army_soldiers_alps_exercise` | hero + couverture | 16:9 | Soldats de l'armée suisse en exercice dans un paysage de haute montagne, tenue camouflée, sommets enneigés en arrière-plan. Photo couleur, cadrage large. | Wikimedia Commons, catégorie « Swiss Armed Forces » (photos du DDPS/VBS diffusées librement) ; à défaut, Unsplash « Swiss army » |
| `palais_des_nations_geneva_flags_alley` | partie 1 | 3:2 | L'allée des drapeaux des États membres devant le Palais des Nations à Genève, siège européen de l'ONU, par temps clair. | Wikimedia Commons, catégorie « Palais des Nations » (CC BY-SA) ou UN Photo |
| `swiss_alps_camouflaged_military_bunker` | partie 2 | 4:3 | L'entrée d'un fort militaire suisse creusé dans la montagne et camouflé en chalet ou en rocher (par exemple Fort de Pré-Giroud, Fürigen ou Sasso San Gottardo). | Wikimedia Commons, catégories « Fortifications in Switzerland » / « Festung Fürigen » / « Fort de Pré-Giroud » (CC BY-SA) |
| `paradeplatz_zurich_ubs_credit_suisse_banks` | partie 3 | 3:2 | La Paradeplatz de Zurich avec les sièges historiques d'UBS et du Credit Suisse, tramways bleus au premier plan : le cœur de la place financière suisse. | Wikimedia Commons, catégorie « Paradeplatz (Zürich) » (CC BY-SA) |

### 274 · Peut-on modifier l'ADN d'un être humain ?

Matière : sciences · Rubrique : Découvertes qui ont changé le monde · Prof : Kate Waddams

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `genetics_lab_pipette_dna_samples_gloved_hands` | hero + couverture | 16:9 | Mains gantées d'un chercheur pipetant dans une barrette de microtubes, laboratoire de génétique moderne, lumière froide, cadrage large et net, sans visage. | Unsplash / Pexels (recherche « pipette DNA lab »), ou NCI Visuals Online (domaine public) |
| `emmanuelle_charpentier_jennifer_doudna_crispr_pioneers` | partie 1 | 3:2 | Emmanuelle Charpentier et Jennifer Doudna côte à côte, en buste, lors d'une remise de prix (Princesse des Asturies 2015, Kavli 2018 ou Nobel de chimie 2020). | Wikimedia Commons, catégories « Emmanuelle Charpentier » et « Jennifer Doudna » (CC BY-SA) ; à défaut deux portraits séparés |
| `sickle_cell_red_blood_cells_micrograph` | partie 2 | 4:3 | Micrographie électronique de globules rouges où l'on distingue nettement des cellules falciformes (en croissant) parmi des cellules normales : la drépanocytose, première maladie traitée par CRISPR en 2023. | Wikimedia Commons, article « Sickle cell disease » (micrographies NIH/NHLBI, domaine public) |
| `ivf_embryo_icsi_microinjection_micrograph` | partie 4 | 4:3 | Vue au microscope d'un ovocyte humain maintenu par une pipette pendant une micro-injection (ICSI) : l'image de la fécondation in vitro, porte d'entrée de l'édition germinale. | Wikimedia Commons, catégorie « Intracytoplasmic sperm injection » (domaine public / CC BY-SA) |

### 275 · Que peut-on vraiment lire dans son ADN ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Kate Waddams

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `dna_double_helix_3d_render_blue` | hero + couverture | 16:9 | Double hélice d'ADN vue de près, en rendu 3D ou modèle physique, teintes bleues sur fond sombre, l'hélice traversant le cadre en diagonale, lisible en vignette. | NHGRI (genome.gov, domaine public) ou Unsplash |
| `identical_twins_sisters_portrait_nature_nurture` | partie 1 | 3:2 | Deux vraies jumelles adultes côte à côte, mêmes traits mais vêtements ou coiffures différents : le même ADN, deux personnalités. | Unsplash / Pexels |
| `dna_sequencing_chromatogram_sanger_readout` | partie 2 | 4:3 | Chromatogramme de séquençage Sanger : la succession de pics colorés (A, T, C, G) sur laquelle un test génétique repère une variante comme BRCA1. | Wikimedia Commons, catégorie « DNA sequencing » (domaine public / CC BY-SA) |
| `early_human_migrations_out_of_africa_map` | partie 3 | 4:3 | Carte du monde des grandes migrations d'Homo sapiens depuis l'Afrique, flèches datées en milliers d'années, reconstituées grâce à l'ADN des populations actuelles. | Wikimedia Commons, « Map of early human migrations » (domaine public / CC BY-SA) |

### 276 · Pourquoi les antibiotiques cessent-ils d'agir ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Kate Waddams

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `antibiogram_petri_dish_inhibition_zones` | hero + couverture | 16:9 | Boîte de Petri d'antibiogramme vue de dessus : tapis bactérien avec des pastilles blanches d'antibiotiques entourées de halos d'inhibition de tailles différentes (certaines sans halo : la résistance). | Wikimedia Commons, catégorie « Antibiotic sensitivity testing », ou CDC Public Health Image Library (domaine public) |
| `alexander_fleming_penicillin_petri_dish` **(existante)** | partie 1 | 4:3 | Alexander Fleming examinant une boîte de Petri dans son laboratoire (photo noir et blanc, années 1940) : l'inventeur de la pénicilline, qui avertissait déjà du risque de résistance. | Image déjà dans content/images (Imperial War Museum, domaine public) |
| `mrsa_staphylococcus_aureus_electron_micrograph_cdc` | partie 2 | 4:3 | Micrographie électronique à balayage, colorisée, d'amas de Staphylococcus aureus résistant à la méticilline (SARM) : le « superbug ». | CDC Public Health Image Library (domaine public), aussi sur Wikimedia Commons, article « MRSA » |
| `hospital_operating_room_surgery_team` | partie 4 | 3:2 | Équipe chirurgicale en pleine intervention dans un bloc opératoire moderne, lampes scialytiques allumées : les opérations de routine qui deviendraient risquées sans antibiotiques. | Unsplash / Pexels, ou Wikimedia Commons, catégorie « Surgery » |

### 277 · Les sanctions évitent-elles vraiment la guerre ?

Matière : comprendreLeMonde · Rubrique : Conflits & géopolitique · Prof : Mark N. Hoffman

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `un_security_council_vote_iraq_sanctions_1990` | hero + couverture | 16:9 | Le Conseil de sécurité de l'ONU votant à main levée une résolution sur l'Irak (résolution 661 du 6 août 1990 ou l'une des résolutions de 1990-1995), vue large de la salle en fer à cheval avec la fresque de Per Krohg au fond. | UN Photo (photothèque ONU, usage éditorial) ou Wikimedia Commons, catégorie « United Nations Security Council meetings » ; à défaut, photo gouvernementale américaine d'une séance du Conseil (domaine public) |
| `gulf_war_1991_oil_fires_kuwait` **(existante)** | partie 1 | 3:2 | Les puits de pétrole koweïtiens en feu en 1991 : la guerre du Golfe qui chasse l'Irak du Koweït, mais laisse l'embargo pétrolier en place. | Image déjà disponible dans content/images (réutilisation) |
| `iraq_water_treatment_plant_baghdad_tigris` | partie 2 | 4:3 | Une station de pompage ou de traitement d'eau délabrée en Irak (canalisations rouillées, bassins), ou le Tigre à Bagdad avec un rejet d'eaux usées, années 1990-2000. | Wikimedia Commons, photos de l'US Army Corps of Engineers ou de l'USAID sur les stations d'eau irakiennes (domaine public) ; catégorie « Water supply in Iraq » |
| `oil_for_food_programme_iraq_ration_distribution` | partie 3 | 4:3 | Distribution de rations alimentaires en Irak sous le programme Pétrole contre nourriture : sacs de farine ou cartons marqués ONU/WFP, file d'habitants, fin des années 1990. | UN Photo / WFP (usage éditorial) ou Wikimedia Commons, article « Oil-for-Food Programme » ; à défaut, photo d'un marché de Bagdad dans les années 1990 (domaine public si agence gouvernementale américaine) |

### 278 · Pourquoi les accords climatiques sont-ils si peu respectés ?

Matière : comprendreLeMonde · Rubrique : Environnement & avenir · Prof : Mark N. Hoffman

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `cop21_paris_agreement_adoption_2015_fabius_gavel` | hero + couverture | 16:9 | La séance finale de la COP21 au Bourget, 12 décembre 2015 : Laurent Fabius abat le marteau, Ban Ki-moon, François Hollande et Christiana Figueres bras levés, tribune et salle en plan large. | Wikimedia Commons, catégorie « 2015 United Nations Climate Change Conference » (photos UNclimatechange / Présidence du Mexique, CC BY) ; UNFCCC Flickr |
| `factory_chimneys_greenhouse_gas_emissions` **(existante)** | partie 1 | 4:3 | Cheminées d'usine crachant leurs fumées : les industries fortement émettrices que les objectifs contraignants de Kyoto renchérissent face à leurs concurrentes étrangères. | Image déjà disponible dans content/images (réutilisation) |
| `montreal_protocol_1987_signing_ceremony` **(existante)** | partie 3 | 4:3 | La cérémonie de signature du protocole de Montréal en septembre 1987 : le traité dont l'aide financière aux industries a permis la mise en œuvre effective. | Image déjà disponible dans content/images (réutilisation) |
| `garzweiler_lignite_open_pit_mine_germany` | partie 4 | 3:2 | La mine de lignite à ciel ouvert de Garzweiler (Rhénanie, Allemagne) : excavatrice à roue-pelle géante dans la fosse, éoliennes ou village à l'horizon, vue large. | Wikimedia Commons, catégorie « Tagebau Garzweiler » (CC BY-SA) |

### 279 · Pourquoi accepter une armée étrangère sur son sol ?

Matière : comprendreLeMonde · Rubrique : Conflits & géopolitique · Prof : Mark N. Hoffman

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `subic_bay_naval_base_philippines_aerial_us_navy` | hero + couverture | 16:9 | Vue aérienne de la base navale américaine de Subic Bay (Philippines) : navires de guerre à quai dans la baie tropicale, quais et hangars, années 1980-1991. | Wikimedia Commons, catégorie « Naval Base Subic Bay », photos de l'US Navy (domaine public) |
| `mers_el_kebir_naval_base_algeria_harbour` | partie 1 | 3:2 | Le port militaire de Mers el-Kébir près d'Oran : la jetée, la rade abritée et la montagne du Murdjadjo, vue d'époque (années 1930-1960) ou photo actuelle du site. | Wikimedia Commons, catégorie « Mers El Kébir » (cartes postales anciennes du domaine public, photos CC BY-SA) |
| `destroyers_for_bases_1940_us_destroyers_halifax` | partie 2 | 3:2 | Les vieux destroyers américains à quatre cheminées remis à la Royal Navy à Halifax en septembre 1940, alignés à quai, dans le cadre de l'accord « destroyers contre bases ». | Wikimedia Commons, catégorie « Destroyers for Bases Agreement » ; US Naval History and Heritage Command (domaine public) |
| `camp_x_ray_guantanamo_detainees_january_2002` | partie 4 | 3:2 | Les premiers détenus de Camp X-Ray à Guantánamo, 11 janvier 2002, agenouillés en combinaison orange derrière les grillages, gardés par des marines. | Wikimedia Commons, photo de Shane T. McCoy (US Navy, 2002, domaine public) |

### 280 · Pourquoi le dollar domine-t-il le monde ?

Matière : comprendreLeMonde · Rubrique : Économie & société · Prof : Mark N. Hoffman

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `us_hundred_dollar_bills_stack_close_up` | hero + couverture | 16:9 | Liasses de billets de 100 dollars américains en gros plan, portrait de Benjamin Franklin lisible, éclairage net, fond neutre : cadrage horizontal serré. | Unsplash / Pexels (licence libre) |
| `gold_bars_federal_reserve_new_york_vault` | partie 1 | 4:3 | Lingots d'or empilés dans la chambre forte de la Federal Reserve Bank de New York ou de Fort Knox : l'or que les États-Unis détiennent en majorité au sortir de la guerre. | Wikimedia Commons, catégorie « Federal Reserve Bank of New York gold vault » (photos de la Fed / du Trésor américain, domaine public) |
| `keynes_harry_dexter_white_bretton_woods_1944` | partie 2 | 4:3 | John Maynard Keynes et Harry Dexter White côte à côte à la conférence de Bretton Woods, juillet 1944 (photo de l'ouverture ou des couloirs du Mount Washington Hotel). | Wikimedia Commons, article « Bretton Woods Conference » (photo du FMI, domaine public) |
| `richard_nixon_televised_address_august_1971` | partie 3 | 4:3 | Richard Nixon lors de son allocution télévisée du 15 août 1971 au Bureau ovale, annonçant la fin de la convertibilité du dollar en or. | Wikimedia Commons / Richard Nixon Presidential Library (photo de la Maison-Blanche, domaine public) |

### 281 · Comment meurt une étoile ?

Matière : sciences · Rubrique : La Terre et l'Univers · Prof : Muhammad Zaheer

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `crab_nebula_supernova_remnant_hubble` | hero + couverture | 16:9 | La nébuleuse du Crabe (M1), reste de la supernova observée en 1054 : mosaïque Hubble aux filaments orange et bleu, la nébuleuse entière centrée sur fond noir. | NASA/ESA Hubble, Wikimedia Commons, catégorie « Crab Nebula » (domaine public) |
| `helix_nebula_planetary_nebula_white_dwarf_hubble` | partie 2 | 4:3 | La nébuleuse de l'Hélice (NGC 7293), nébuleuse planétaire : anneau de gaz bleu et rouge avec la naine blanche visible au centre, image Hubble/CTIO. | NASA/ESA Hubble, Wikimedia Commons, catégorie « Helix Nebula » (domaine public) |
| `m87_black_hole_event_horizon_telescope_2019` | partie 3 | 1:1 | La première image d'un trou noir (M87*, avril 2019) : l'anneau orange flou de l'Event Horizon Telescope autour de l'ombre noire centrale. | EHT Collaboration, Wikimedia Commons, article « Messier 87 » (CC BY 4.0) |
| `pillars_of_creation_eagle_nebula_jwst_2022` | partie 4 | 3:4 | Les Piliers de la création (nébuleuse de l'Aigle) vus par le télescope James Webb en 2022 : colonnes de gaz et de poussière ocre où naissent de nouvelles étoiles, image verticale. | NASA/ESA/CSA/STScI, Wikimedia Commons, catégorie « Pillars of Creation » (domaine public) |

### 282 · Que se passerait-il si un supervolcan se réveillait ?

Matière : sciences · Rubrique : La Terre et l'Univers · Prof : Muhammad Zaheer

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `yellowstone_grand_prismatic_spring_aerial` | hero + couverture | 16:9 | Vue aérienne du Grand Prismatic Spring, au cœur de la caldeira de Yellowstone : bassin turquoise cerclé d'orange, panaches de vapeur, cadrage large. | Wikimedia Commons, catégorie « Grand Prismatic Spring » (photos NPS/USGS, domaine public) |
| `volcano_eruption_lava` **(existante)** | partie 2 | 3:2 | Image existante (cours 62) : coulée pyroclastique dévalant le flanc du volcan Mayon (Philippines), nuage gris de gaz et de cendres chauds sous un ciel bleu. | Déjà dans content/images/volcano_eruption_lava.jpg |
| `yellowstone_supereruption_ashfall_map_usgs_2014` | partie 3 | 4:3 | Carte USGS (Mastin et al., 2014) des épaisseurs de cendres modélisées sur l'Amérique du Nord après une supra-éruption de Yellowstone : cercles concentriques autour du Wyoming, légende en centimètres. | USGS / Yellowstone Volcano Observatory, figure de « Modeling ash fall distribution from a Yellowstone supereruption » (domaine public) |
| `mount_pinatubo_eruption_column_1991_clark_air_base` | partie 4 | 4:3 | La colonne éruptive du Pinatubo le 12 juin 1991, vue depuis la base aérienne de Clark : gigantesque champignon de cendres gris au-dessus des palmiers. | USGS (photo Dave Harlow ou Richard Hoblitt), Wikimedia Commons, catégorie « 1991 eruption of Mount Pinatubo » (domaine public) |

### 283 · Qu'y a-t-il vraiment dans un smartphone ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Muhammad Zaheer

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `disassembled_smartphone_components_flat_lay` | hero + couverture | 16:9 | Un smartphone entièrement démonté, pièces alignées à plat (écran, carte mère, batterie, coque, caméras, vis) sur fond neutre, vue de dessus. | Unsplash / Pexels (licence libre) ; à défaut Wikimedia Commons, catégorie « Disassembled mobile phones » |
| `smartphone_logic_board_chips_gold_contacts_macro` | partie 2 | 4:3 | Gros plan sur la carte mère d'un smartphone : puces noires, pistes de cuivre et contacts dorés bien visibles. | Unsplash / Pexels ; Wikimedia Commons, catégorie « Mobile phone printed circuit boards » (CC BY-SA) |
| `salar_de_atacama_lithium_evaporation_ponds_aerial` | partie 3 | 3:2 | Vue aérienne ou satellite des bassins d'évaporation de lithium du salar d'Atacama (Chili) : rectangles turquoise et jaunes au milieu du désert de sel. | NASA Earth Observatory ou Copernicus Sentinel-2 (domaine public / CC BY), Wikimedia Commons, catégorie « Salar de Atacama » |
| `e_waste_pile_discarded_mobile_phones` | partie 4 | 4:3 | Un tas de vieux téléphones portables et de déchets électroniques destinés au recyclage, cadrage serré sur les appareils. | Wikimedia Commons, catégorie « Electronic waste » (CC BY-SA), ou Unsplash / Pexels |

### 284 · Pourquoi Mars est-elle devenue un désert ?

Matière : sciences · Rubrique : La Terre et l'Univers · Prof : Muhammad Zaheer

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `mars_valles_marineris_hemisphere_viking_mosaic` | hero + couverture | 16:9 | Le globe de Mars centré sur le canyon Valles Marineris, mosaïque Viking : la planète rouge entière sur fond noir, bien lisible en petit. | NASA/JPL-Caltech/USGS, Wikimedia Commons, catégorie « Mars (planet) » (domaine public) |
| `jezero_crater_river_delta_mars_reconnaissance_orbiter` | partie 1 | 4:3 | Le delta fossile du cratère Jezero vu depuis l'orbite (Mars Reconnaissance Orbiter) : éventail de sédiments en fausses couleurs, preuve d'un ancien lac. | NASA/JPL-Caltech/MSSS/JHU-APL, Wikimedia Commons, catégorie « Jezero (crater) » (domaine public) |
| `maven_solar_wind_stripping_mars_atmosphere_nasa` | partie 2 | 4:3 | Visualisation NASA de la mission MAVEN : le vent solaire arrache les ions de la haute atmosphère de Mars, traînées de gaz emportées derrière la planète. | NASA Goddard Space Flight Center, page « NASA Mission Reveals Speed of Solar Wind Stripping Martian Atmosphere » (domaine public) |
| `mars_north_polar_ice_cap_mars_global_surveyor` | partie 4 | 4:3 | La calotte polaire nord de Mars en été : spirale de glace blanche sur le sol ocre, vue orbitale (Mars Global Surveyor ou Mars Express). | NASA/JPL/MSSS ou ESA/DLR/FU Berlin, Wikimedia Commons, catégorie « Planum Boreum » (domaine public / CC BY-SA) |

### 285 · Pourquoi la Lune s'éloigne-t-elle de la Terre ?

Matière : sciences · Rubrique : La Terre et l'Univers · Prof : Muhammad Zaheer

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `full_moon_rising_over_ocean_horizon` | hero + couverture | 16:9 | Pleine lune se levant au-dessus de la mer : cadrage large, mer au premier plan, Lune grosse et bien lisible, sans personnage. | Unsplash / Pexels (licence libre) |
| `mont_saint_michel_bay_high_tide_aerial` | partie 1 | 3:2 | La baie du Mont-Saint-Michel à marée haute, le Mont entièrement entouré d'eau, photo aérienne ou depuis la côte. | Wikimedia Commons, catégorie « Mont-Saint-Michel » (CC BY-SA), ou Unsplash |
| `apollo_11_lunar_laser_retroreflector_nasa_1969` | partie 2 | 4:3 | Le rétroréflecteur laser (LRRR) déposé par Apollo 11 sur le sol lunaire en juillet 1969 : panneau de prismes sur son support, module lunaire en arrière-plan (photo AS11-40-5952). | NASA, Wikimedia Commons, catégorie « Lunar Laser Ranging Experiment » (domaine public) |
| `total_solar_eclipse_corona_2017_nasa` | partie 4 | 4:3 | Éclipse totale de Soleil du 21 août 2017 : disque noir de la Lune entouré de la couronne solaire blanche sur ciel sombre. | NASA (photo Aubrey Gemignani), Wikimedia Commons, catégorie « Solar eclipse of 2017 August 21 » (domaine public) |

### 286 · Comment a-t-on évité la famine annoncée des années 1960 ?

Matière : histoire · Rubrique : Guerre froide & monde contemporain · Prof : Myra Houser

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `norman_borlaug_wheat_field_mexico_1960s` | hero + couverture | 16:9 | Norman Borlaug debout dans un champ de blé au Mexique dans les années 1960, épis au premier plan, cadrage large ; à défaut, un champ de blé doré à la moisson. | Wikimedia Commons, catégorie « Norman Borlaug » (photos CIMMYT / USDA, domaine public ou CC BY) ; sinon Unsplash « wheat field harvest » |
| `dust_bowl_okies_migrant_family_dorothea_lange` **(existante)** | partie 1 | 1:1 | « Migrant Mother » de Dorothea Lange (1936) : une mère de famille d'ouvriers agricoles pendant la Grande Dépression, deux enfants blottis contre elle. | Déjà dans content/images (Dorothea Lange, domaine public) |
| `india_wheat_revolution_postage_stamp_1968` | partie 2 | 3:4 | Le timbre indien « Wheat Revolution » de 1968, émis pour célébrer les récoltes record des nouvelles variétés de blé ; à défaut, une moisson de blé au Pendjab. | Wikimedia Commons, « Stamp of India 1968 Wheat Revolution » (licence GODL-India) ; sinon catégorie « Wheat fields in Punjab, India » |
| `great_leap_forward_backyard_furnaces_china_1958` | partie 3 | 4:3 | Hauts-fourneaux de fortune dans une campagne chinoise pendant le Grand Bond en avant (1958), paysans au travail devant les fours fumants. | Wikimedia Commons, catégorie « Great Leap Forward » (photo « Backyard furnace », domaine public en Chine) |

### 287 · Pourquoi a-t-on ravitaillé Berlin par avion en 1948 ?

Matière : histoire · Rubrique : Guerre froide & monde contemporain · Prof : Myra Houser

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `berlin_airlift_1948_c54_landing_tempelhof_children` | hero + couverture | 16:9 | Des Berlinois, surtout des enfants, perchés sur les décombres regardent un C-54 américain atterrir à Tempelhof (1948). Photo d'époque en noir et blanc. | Wikimedia Commons, « C-54 landing at Tempelhof » (photo US Air Force, domaine public) |
| `germany_allied_occupation_zones_map_1945` | partie 1 | 4:3 | Carte de l'Allemagne occupée (1945-1949) : les quatre zones américaine, britannique, française et soviétique, et Berlin lui-même divisé au cœur de la zone soviétique. | Wikimedia Commons, catégorie « Maps of Allied-occupied Germany » (domaine public ou CC BY-SA) |
| `gail_halvorsen_candy_bomber_parachutes_1948` | partie 3 | 4:3 | Le pilote Gail Halvorsen, le « Candy Bomber », attachant des friandises à de petits parachutes en mouchoir devant son avion (1948). | Wikimedia Commons, catégorie « Gail Halvorsen » (photos US Air Force, domaine public) |
| `crowd_west_berlin_november_9_1989` **(existante)** | partie 4 | 3:2 | Le mur de Berlin vu de l'Ouest en 1989 : mur, bande de la mort et mirador est-allemand devant les immeubles de Berlin-Est. | Déjà dans content/images (Raphaël Thiémard, CC BY-SA 2.0) |

### 288 · Que s'est-il passé à Bhopal la nuit du 3 décembre 1984 ?

Matière : histoire · Rubrique : Guerre froide & monde contemporain · Prof : Myra Houser

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `union_carbide_bhopal_abandoned_plant_ruins` | hero + couverture | 16:9 | L'usine désaffectée d'Union Carbide à Bhopal : tours, tuyauteries rouillées et structures métalliques envahies par la végétation, vue large. | Wikimedia Commons, catégorie « Union Carbide India Limited plant, Bhopal » (photos CC BY-SA) |
| `taj_mahal_palace_bhopal_shah_jahan_begum` | partie 1 | 3:2 | Le Taj Mahal Palace de Bhopal, palais du XIXe siècle construit par la begum Shah Jahan : façade, arcades et coupoles, vue extérieure. | Wikimedia Commons, catégorie « Taj Mahal Palace (Bhopal) » (CC BY-SA) |
| `bhopal_gas_tragedy_memorial_statue_mother_child` | partie 3 | 3:4 | La statue commémorative devant l'ancienne usine : une mère portant un enfant et se couvrant le visage (sculpture de Ruth Waterman, 1985). | Wikimedia Commons, catégorie « Bhopal disaster » (CC BY-SA) |
| `bhopal_survivors_protest_justice_union_carbide` | partie 4 | 4:3 | Manifestation de survivants de Bhopal, pancartes réclamant justice contre Union Carbide et Dow Chemical, années 2000-2010. | Wikimedia Commons, catégorie « Bhopal disaster » (photos Bhopal Medical Appeal, CC BY-SA) |

### 289 · Pourquoi l'URSS s'est-elle effondrée en 1991 ?

Matière : histoire · Rubrique : Guerre froide & monde contemporain · Prof : Myra Houser

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `soviet_tanks_red_square_moscow_august_1991_coup` | hero + couverture | 16:9 | Chars soviétiques sur la place Rouge devant le Kremlin pendant le putsch d'août 1991, badauds autour des blindés, vue large. | Wikimedia Commons, catégorie « 1991 Soviet coup d'état attempt » (photos CC BY / CC BY-SA) |
| `soviet_union_fifteen_republics_map` | partie 1 | 4:3 | Carte de l'URSS avec ses quinze républiques fédérées en couleurs distinctes, de la Baltique au Pacifique. | Wikimedia Commons, catégorie « Maps of the Soviet Union » (cartes CIA, domaine public, ou CC BY-SA) |
| `mikhail_gorbachev_portrait_1987` | partie 3 | 1:1 | Portrait officiel de Mikhaïl Gorbatchev vers 1985-1987, buste, costume sombre, tache de naissance visible. | Wikimedia Commons, catégorie « Mikhail Gorbachev in 1987 » (RIA Novosti CC BY-SA 3.0, ou photos de la Maison-Blanche, domaine public) |
| `alma_ata_protocol_signing_december_21_1991` | partie 4 | 3:2 | La signature du protocole d'Alma-Ata le 21 décembre 1991 : les dirigeants des républiques autour d'une longue table, drapeaux derrière eux. | Wikimedia Commons, archives RIA Novosti « Signing the Alma-Ata Protocol » (CC BY-SA 3.0) |

### 290 · Comment les États-Unis ont-ils gagné la course à la Lune ?

Matière : histoire · Rubrique : Guerre froide & monde contemporain · Prof : Myra Houser

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `apollo_11_aldrin_us_flag_lunar_module_1969` | hero + couverture | 16:9 | Buzz Aldrin debout à côté du drapeau américain planté sur la mer de la Tranquillité, module lunaire Eagle à gauche (NASA AS11-40-5875), cadrage large. | NASA / Wikimedia Commons, catégorie « Apollo 11 » (domaine public) |
| `laika_soviet_space_dog_sputnik_2_1957` | partie 1 | 1:1 | La chienne Laïka dans son harnais de vol avant le lancement de Spoutnik 2 (novembre 1957), photo soviétique d'époque. | Wikimedia Commons, catégorie « Laika » (photos d'archives, domaine public) |
| `moon_earth_orbit_space` **(existante)** | partie 3 | 4:3 | Le module lunaire Eagle remontant vers le module de commande de Collins, la Terre se levant au-dessus de l'horizon lunaire (NASA AS11-44-6643). | Déjà dans content/images (NASA, domaine public) |
| `apollo_soyuz_handshake_stafford_leonov_1975` | partie 4 | 4:3 | La poignée de main en orbite entre Thomas Stafford et Alexeï Leonov dans le sas d'Apollo-Soyouz, juillet 1975. | NASA / Wikimedia Commons, catégorie « Apollo–Soyuz Test Project » (domaine public) |

### 291 · L'esclavage américain a-t-il vraiment pris fin en 1865 ?

Matière : histoire · Rubrique : Révolutions & conflits modernes · Prof : Nathan Hewitt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `southern_chain_gang_convicts_1900s_photograph` | hero + couverture | 16:9 | Une chaîne de forçats noirs (chain gang) au travail sous la garde d'hommes armés dans le Sud des États-Unis, vers 1900-1910 : photo d'archives horizontale, le groupe au centre du cadre. | Wikimedia Commons / Library of Congress, « A Southern chain gang » (Detroit Publishing Co., vers 1903), domaine public |
| `lincoln_emancipation_proclamation_carpenter_painting_1864` | partie 1 | 4:3 | Le tableau de Francis Bicknell Carpenter « First Reading of the Emancipation Proclamation » (1864) : Lincoln assis lisant la Proclamation à son cabinet réuni. | Wikimedia Commons, article « First Reading of the Emancipation Proclamation of President Lincoln », domaine public |
| `thirteenth_amendment_joint_resolution_1865_national_archives` | partie 2 | 3:4 | La résolution conjointe du Congrès proposant le 13e amendement (1865), document manuscrit signé par Lincoln, où figure la clause « except as a punishment for crime ». | Wikimedia Commons / National Archives (NARA), « 13th Amendment to the U.S. Constitution », domaine public |
| `convict_leasing_prisoners_florida_1910s` | partie 3 | 4:3 | Des détenus en tenue rayée loués à une entreprise privée (convict leasing) au travail dans un champ ou un camp forestier du Sud, années 1900-1910. | Wikimedia Commons, catégorie « Convict lease system » ; State Archives of Florida (Florida Memory) ou Library of Congress, domaine public |

### 292 · Pourquoi le Titanic manquait-il de canots de sauvetage ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Nathan Hewitt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `rms_titanic_departing_southampton_april_1912` | hero + couverture | 16:9 | Le Titanic quittant Southampton le 10 avril 1912, vu de profil, coque et quatre cheminées entières dans le cadre : photo d'époque. | Wikimedia Commons, catégorie « RMS Titanic », photos de 1912, domaine public |
| `titanic_boat_deck_lifeboats_welin_davits_1912` | partie 1 | 4:3 | Le pont des embarcations du Titanic (ou de son jumeau l'Olympic) avec les canots suspendus à leurs bossoirs Welin, 1911-1912. | Wikimedia Commons, catégories « RMS Titanic » et « RMS Olympic », photos Harland & Wolff (Robert Welch) ou Bain News Service, domaine public |
| `titanic_lifeboat_survivors_approaching_carpathia_1912` | partie 3 | 3:2 | Un canot du Titanic à moitié vide s'approchant du Carpathia au matin du 15 avril 1912 : photo prise depuis le pont du Carpathia. | Wikimedia Commons, catégorie « Lifeboats of the RMS Titanic », domaine public |
| `new_york_times_front_page_titanic_1912` | partie 4 | 3:4 | La une du New York Times du 16 avril 1912 : « Titanic Sinks Four Hours After Hitting Iceberg », document vertical. | Wikimedia Commons, article « Sinking of the Titanic », domaine public |

### 293 · Pourquoi l'Angleterre s'est-elle battue pour l'opium ?

Matière : histoire · Rubrique : Révolutions & conflits modernes · Prof : Nathan Hewitt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `nemesis_destroying_chinese_war_junks_1841` | hero + couverture | 16:9 | Le vapeur britannique Nemesis détruisant les jonques de guerre chinoises dans la baie d'Anson, 7 janvier 1841 : peinture d'Edward Duncan (1843), cadrage large sur la bataille navale. | Wikimedia Commons, article « Nemesis (1839) » / « First Opium War », domaine public |
| `patna_opium_factory_stacking_room_1850_lithograph` | partie 1 | 4:3 | La salle d'empilage de la fabrique d'opium de Patna (Bengale), lithographie d'après W. S. Sherwill, vers 1850 : des milliers de boules d'opium alignées sur des étagères. | Wikimedia Commons / Wellcome Collection, « The stacking room, opium factory at Patna, India », domaine public |
| `treaty_of_nanking_signing_hms_cornwallis_1842` | partie 2 | 4:3 | La signature du traité de Nankin à bord du HMS Cornwallis, 29 août 1842 : gravure d'après John Platt, plénipotentiaires britanniques et mandarins autour de la table. | Wikimedia Commons, article « Treaty of Nanking », domaine public |
| `chinese_opium_smokers_den_photograph_1880s` | partie 4 | 4:3 | Des fumeurs d'opium allongés avec leurs pipes dans une fumerie chinoise, photo de la fin du XIXe siècle (vers 1880-1900). | Wikimedia Commons, catégorie « Opium dens in China », photos de Lai Afong ou anonymes, domaine public |

### 294 · Pourquoi l'Irlande affamée exportait-elle sa nourriture ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Nathan Hewitt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `famine_memorial_custom_house_quay_dublin` | hero + couverture | 16:9 | Les statues de bronze du Famine Memorial de Rowan Gillespie sur Custom House Quay à Dublin, silhouettes décharnées marchant vers le port, la Liffey en arrière-plan : photo horizontale. | Wikimedia Commons, catégorie « Famine Memorial (Dublin) » (CC BY-SA, liberté de panorama irlandaise) |
| `daniel_macdonald_irish_family_discovering_blight_1847` | partie 1 | 4:3 | Le tableau de Daniel MacDonald « An Irish Peasant Family Discovering the Blight of their Store » (vers 1847) : une famille découvrant ses pommes de terre pourries. | Wikimedia Commons, article « Great Famine (Ireland) » / « Daniel MacDonald (painter) », domaine public |
| `skibbereen_famine_engraving_mahony_1847` | partie 2 | 4:3 | Une gravure de James Mahony pour l'Illustrated London News (février 1847) : scène de famine à Skibbereen, comté de Cork (funérailles ou village abandonné). | Wikimedia Commons, catégorie « Great Famine (Ireland) in art », gravures de l'Illustrated London News, domaine public |
| `jeanie_johnston_famine_ship_replica_dublin` | partie 4 | 3:2 | La réplique du Jeanie Johnston, trois-mâts d'émigrants de la Grande Famine, amarrée sur la Liffey à Dublin : photo horizontale du navire. | Wikimedia Commons, catégorie « Jeanie Johnston (ship, 2002) » (CC BY-SA) |

### 295 · Pourquoi avons-nous des fuseaux horaires ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Nathan Hewitt

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `shepherd_gate_clock_royal_observatory_greenwich` | hero + couverture | 16:9 | L'horloge Shepherd à cadran de 24 heures (1852) scellée dans le mur de l'observatoire royal de Greenwich, cadran centré et lisible : photo. | Wikimedia Commons, catégorie « Shepherd Gate Clock » (CC BY-SA) |
| `bristol_corn_exchange_clock_two_minute_hands` | partie 1 | 4:3 | L'horloge du Corn Exchange de Bristol avec ses deux aiguilles des minutes : l'heure locale de Bristol et l'heure de Greenwich (railway time), dix minutes d'écart. | Wikimedia Commons, article « Railway time » / « The Exchange, Bristol » (CC BY-SA) |
| `william_allen_railroad_time_zones_map_1883` | partie 2 | 4:3 | La carte des fuseaux horaires ferroviaires nord-américains adoptés le 18 novembre 1883 d'après la proposition de William F. Allen, bandes colorées d'est en ouest. | Wikimedia Commons, article « Standard time » / « William F. Allen », carte de 1883 (Travelers' Official Railway Guide), domaine public |
| `sandford_fleming_portrait_photograph_1890s` | partie 3 | 1:1 | Portrait photographique de Sandford Fleming, ingénieur écossais-canadien, buste, barbe blanche, années 1890. | Wikimedia Commons, catégorie « Sandford Fleming », Bibliothèque et Archives Canada, domaine public |

### 296 · L'IA consomme-t-elle beaucoup d'énergie ?

Matière : comprendreLeMonde · Rubrique : Environnement & avenir · Prof : Rana Abdalla

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `data_center_server_racks_aisle_blue_lights` | hero + couverture | 16:9 | Allée centrale d'un data centre moderne : rangées symétriques de baies de serveurs éclairées (LED bleues ou blanches), perspective fuyante, sans personnage, photo contemporaine. | Unsplash / Pexels (« data center », « server room ») ou Wikimedia Commons, catégorie « Server rooms » (CC BY) |
| `data_center_cooling_pipes_chillers` | partie 1 | 4:3 | Le refroidissement d'un data centre : gros tuyaux colorés d'eau de refroidissement ou groupes froids et tours aéroréfrigérantes en toiture, photo industrielle contemporaine. | Wikimedia Commons, catégorie « Data center cooling » (CC BY / CC BY-SA) |
| `frontier_supercomputer_oak_ridge_cabinets` | partie 2 | 3:2 | Rangées d'armoires du supercalculateur Frontier (ou Summit) au Oak Ridge National Laboratory, salle machine vue en enfilade : le type de machines qui tournent pendant des semaines pour entraîner un modèle d'IA. | Wikimedia Commons, catégorie « Frontier (supercomputer) » / Flickr ORNL (US DOE, domaine public) |
| `high_voltage_power_lines_data_center_virginia` | partie 4 | 3:2 | Pylônes et lignes à haute tension au premier plan, bâtiments de data centres en arrière-plan (Loudoun County / Ashburn, Virginie, la « Data Center Alley ») ; à défaut, lignes à haute tension seules au crépuscule, cadrage horizontal. | Wikimedia Commons, catégorie « Data centers in Loudoun County, Virginia » (CC BY-SA) ; sinon Unsplash (« power lines ») |

### 297 · D'où vient vraiment l'électricité de votre prise ?

Matière : comprendreLeMonde · Rubrique : Environnement & avenir · Prof : Rana Abdalla

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `wind_turbines_coal_power_plant_landscape` | hero + couverture | 16:9 | Éoliennes au premier plan et centrale thermique (tours de refroidissement, cheminées) au second plan dans le même paysage, image du mix électrique ; ex. centrale de Scholven (Gelsenkirchen) ou de Niederaußem (Allemagne), lumière de fin de journée. | Wikimedia Commons, catégories « Scholven Power Station » et « Niederaußem Power Station » (CC BY-SA) |
| `steam_turbine_generator_hall_power_plant` | partie 1 | 3:2 | Salle des machines d'une centrale électrique : turbine à vapeur couplée à son alternateur, grande machine cylindrique avec passerelles, photo industrielle en couleur. | Wikimedia Commons, catégories « Steam turbines » et « Turbine halls » (CC BY / domaine public, photos TVA ou Siemens) |
| `electricity_grid_control_room_operators_screens` | partie 2 | 3:2 | Salle de contrôle d'un gestionnaire de réseau électrique : opérateurs de dos devant un mur d'écrans affichant le schéma du réseau (ex. Bonneville Power Administration, RTE ou ERCOT). | Wikimedia Commons, catégorie « Electric power control rooms » (photos BPA / US DOE, domaine public) |
| `belchatow_coal_power_plant_cooling_towers_poland` | partie 4 | 3:2 | Centrale à charbon de Bełchatów (Pologne), la plus grande d'Europe : tours de refroidissement et panaches de vapeur au-dessus de la plaine, vue large, illustre le CO2 lié à l'électricité fossile qui circule au-delà des frontières. | Wikimedia Commons, catégorie « Bełchatów Power Station » (CC BY-SA) |

### 298 · Ésope a-t-il vraiment existé ?

Matière : litterature · Rubrique : Grecs & Philosophes antiques · Prof : Simon Lea

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `aesop_fox_kylix_vatican_470_bc` | hero + couverture | 16:9 | Le médaillon du kylix attique à figures rouges (vers 470 av. J.-C., musées du Vatican) : Ésope, assis et enveloppé dans son manteau, écoute un renard qui lui parle ; recadrer large sur les deux figures. | Wikimedia Commons, « Aesop and the fox, Attic red-figure kylix » (Museo Gregoriano Etrusco, Vatican), domaine public |
| `aesop_velazquez_portrait_1638_prado` | partie 1 | 3:4 | Le portrait d'Ésope par Diego Vélasquez (vers 1638, musée du Prado) : un homme en haillons, visage marqué, un livre à la main, en pied ; l'esclave laid et pauvre de la légende. | Wikimedia Commons, « Aesop by Velázquez » (Prado), domaine public |
| `hare_and_tortoise_fable_arthur_rackham_1912` | partie 2 | 4:3 | « Le Lièvre et la Tortue » : illustration d'Arthur Rackham pour « Aesop's Fables » (Londres, 1912), la tortue avançant pendant que le lièvre dort. | Wikimedia Commons ou Project Gutenberg (Aesop's Fables, trad. V. S. Vernon Jones, ill. Arthur Rackham, 1912), domaine public |
| `animal_farm_pigs_barnyard_orwell` **(existante)** | partie 4 | 3:2 | Fresque murale « Animal Farm » : un cochon en costume et cravate, l'animal personnifié de la fable d'Orwell (image déjà utilisée pour le cours sur « La Ferme des animaux »). | Image existante : content/images/animal_farm_pigs_barnyard_orwell.jpg |

### 299 · Pourquoi Aurore Dupin s'est-elle appelée George Sand ?

Matière : litterature · Rubrique : Classiques français & européens · Prof : Simon Lea

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `george_sand_portrait_auguste_charpentier_1838` | hero + couverture | 16:9 | Portrait de George Sand par Auguste Charpentier (1838, musée de la Vie romantique, Paris) : cheveux noirs, regard de face, robe sombre ; recadrer large sur le visage et les épaules. | Wikimedia Commons, « George Sand par Auguste Charpentier », domaine public |
| `indiana_george_sand_1832_title_page` | partie 1 | 3:4 | Page de titre de l'édition originale d'« Indiana » (Paris, J.-P. Roret et H. Dupuy, 1832), signée « G. Sand ». | Gallica (BnF) ou Wikimedia Commons, domaine public |
| `george_sand_mens_clothes_caricature_lorentz_1842` | partie 2 | 3:4 | Caricature d'Alcide Lorentz (« Miroir drolatique », 1842) : George Sand debout en redingote et pantalon, cigare à la main. | Wikimedia Commons, « George Sand par Alcide Lorentz », domaine public |
| `chopin_george_sand_double_portrait_delacroix_1838` | partie 3 | 4:3 | Le double portrait inachevé de Frédéric Chopin au piano et de George Sand l'écoutant, par Eugène Delacroix (1838) : reconstitution des deux fragments (Louvre et Ordrupgaard). | Wikimedia Commons, « Portrait de Frédéric Chopin et George Sand » (reconstitution), domaine public |

### 300 · Comment le journal d'Anne Frank a-t-il survécu ?

Matière : litterature · Rubrique : Anglo-saxons & littérature mondiale · Prof : Simon Lea

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `anne_frank_red_checkered_diary_1942` | hero + couverture | 16:9 | Le journal d'Anne Frank : le carnet d'autographes à couverture rouge à carreaux reçu pour ses 13 ans, le 12 juin 1942, posé fermé ou entrouvert, cadrage large sur fond neutre. | Wikimedia Commons, catégorie « Diary of Anne Frank » (fac-similé exposé à la Maison Anne Frank, Amsterdam, ou au Anne Frank Zentrum, Berlin ; photos CC BY / CC BY-SA) |
| `anne_frank_diary_handwritten_pages_photos_glued` | partie 1 | 4:3 | Le journal ouvert : deux pages manuscrites à l'encre avec des photographies collées par Anne Frank, 1942. | Wikimedia Commons, catégorie « Diary of Anne Frank » (photos du fac-similé en vitrine, CC BY-SA) |
| `anne_frank_house_bookcase_secret_annex_entrance` | partie 3 | 3:4 | La bibliothèque pivotante qui dissimulait l'entrée de l'Annexe, Prinsengracht 263, Amsterdam, photographiée dans le musée, porte entrouverte. | Wikimedia Commons, catégorie « Anne Frank Huis » (CC BY-SA) |
| `anne_frank_statue_westermarkt_amsterdam_andriessen` | partie 4 | 3:4 | La statue en bronze d'Anne Frank par Mari Andriessen (1977) sur le Westermarkt, près de la Westerkerk, Amsterdam. | Wikimedia Commons, catégorie « Statue of Anne Frank (Westermarkt, Amsterdam) » (CC BY-SA, liberté de panorama aux Pays-Bas) |

### 301 · Pourquoi Machiavel a-t-il écrit « Le Prince » ?

Matière : litterature · Rubrique : Classiques français & européens · Prof : Simon Lea

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `machiavelli_portrait_santi_di_tito_florence` | hero + couverture | 16:9 | Le portrait posthume de Nicolas Machiavel par Santi di Tito (seconde moitié du XVIe siècle, Palazzo Vecchio, Florence) : buste en habit noir et rouge, léger sourire ; recadrer large sur le visage et le buste. | Wikimedia Commons, « Portrait of Niccolò Machiavelli by Santi di Tito », domaine public |
| `il_principe_1532_blado_title_page` | partie 1 | 3:4 | Page de titre de la première édition imprimée du « Prince » (« Il Principe di Niccolò Machiavelli », Rome, Antonio Blado, 1532). | Wikimedia Commons, « Il Principe 1532 » (Blado), domaine public |
| `lorenzo_de_medici_duke_urbino_raphael_1518` | partie 2 | 1:1 | Portrait de Laurent II de Médicis, duc d'Urbino, dédicataire du « Prince », par Raphaël (vers 1518) : buste en manteau de fourrure, recadré carré sur le visage. | Wikimedia Commons, « Portrait of Lorenzo di Medici, Duke of Urbino (Raphael) », domaine public. Ne pas confondre avec Laurent le Magnifique (image existante lorenzo_de_medici_portrait_florence). |
| `machiavelli_tomb_santa_croce_florence_epitaph` | partie 4 | 3:4 | Le cénotaphe de Machiavel dans la basilique Santa Croce à Florence (Innocenzo Spinazzi, 1787), avec l'épitaphe « Tanto nomini nullum par elogium ». | Wikimedia Commons, catégorie « Tomb of Niccolò Machiavelli (Santa Croce) » (CC BY-SA) |

### 302 · Quel est le plus vieux livre du monde ?

Matière : litterature · Rubrique : Anglo-saxons & littérature mondiale · Prof : Simon Lea

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `gilgamesh_hero_lion_relief_khorsabad_louvre` | hero + couverture | 16:9 | Le grand relief assyrien du « héros maîtrisant un lion » (palais de Sargon II à Khorsabad, VIIIe siècle av. J.-C., musée du Louvre), souvent identifié à Gilgamesh : recadrer large sur le visage barbu et le lion serré contre la poitrine. | Wikimedia Commons, « Hero overpowering a lion, Khorsabad, Louvre AO 19862 » (photos CC BY-SA ou domaine public) |
| `gilgamesh_tablet_cuneiform_nineveh_british_museum` **(existante)** | partie 1 | 3:2 | Tablette d'argile de l'Épopée de Gilgamesh en écriture cunéiforme (bibliothèque d'Assurbanipal, Ninive, British Museum), déjà en place. | Image existante : content/images/gilgamesh_tablet_cuneiform_nineveh_british_museum.jpg |
| `humbaba_clay_mask_face_british_museum` | partie 3 | 4:3 | Masque en argile du démon Humbaba, gardien de la Forêt des Cèdres : visage aux traits sinueux, période paléo-babylonienne (vers 1800-1600 av. J.-C., British Museum ou Louvre). | Wikimedia Commons, catégorie « Humbaba » (CC BY-SA) |
| `gilgamesh_flood_tablet_utnapishtim_myth` **(existante)** | partie 4 | 3:2 | La « tablette du Déluge » (tablette XI de l'épopée, Ninive, British Museum), qui raconte l'histoire d'Utnapishtim, déjà en place. | Image existante : content/images/gilgamesh_flood_tablet_utnapishtim_myth.jpg |

### 303 · Pourquoi certains détestent-ils la coriandre ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Stacy Jankowski, PhD

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `fresh_coriander_cilantro_bunch_leaves` | hero + couverture | 16:9 | Une botte de coriandre fraîche vue de près, feuilles vertes bien nettes sur fond neutre ou planche de bois, lumière naturelle, sujet centré et lisible en petit. | Unsplash / Pexels (« cilantro », « coriander leaves »), licence libre |
| `olfactory_nerve_nasal_cavity_gray_anatomy_plate` | partie 1 | 4:3 | Planche anatomique ancienne de la cavité nasale montrant le nerf et le bulbe olfactifs (coupe sagittale de la tête), style manuel d'anatomie du début du XXe siècle. | Wikimedia Commons, Gray's Anatomy 1918, planches 771-772 « Distribution of the olfactory nerve » (domaine public) |
| `dna_double_helix_nhgri_illustration` | partie 2 | 4:3 | Illustration réaliste d'une double hélice d'ADN avec ses paires de bases colorées, fond sombre ou clair uni, pour évoquer la variation d'une seule lettre (SNP) du gène OR6A2. | Wikimedia Commons, images du NHGRI / NIH (domaine public), catégorie « DNA double helix » |
| `cilantro_lime_mexican_tacos_street_food` | partie 3 | 3:2 | Des tacos mexicains garnis de coriandre fraîche hachée et de quartiers de citron vert, photo culinaire vue de dessus, couleurs vives : la coriandre au cœur des cuisines du monde. | Unsplash / Pexels (« tacos cilantro lime »), licence libre |

### 304 · Pourquoi rougit-on ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Stacy Jankowski, PhD

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `blushing_red_cheeks_woman_portrait_close_up` | hero + couverture | 16:9 | Portrait serré d'une jeune femme ou d'un jeune homme aux joues visiblement rouges, regard gêné ou sourire timide, fond uni et lumière douce ; les joues doivent rester lisibles en vignette. | Unsplash / Pexels (« blushing », « red cheeks portrait »), licence libre |
| `thermal_infrared_image_human_face_heat` | partie 1 | 4:3 | Image thermique (caméra infrarouge) d'un visage humain de face, zones chaudes en rouge-jaune sur les joues et le nez, fond froid en bleu : la chaleur évacuée par les vaisseaux du visage. | Wikimedia Commons, catégorie « Thermographic images of human faces » (CC BY-SA ou NASA/JPL domaine public) |
| `embarrassed_person_hiding_face_in_hands` | partie 2 | 3:2 | Une personne gênée se cachant le visage dans les mains ou derrière un pull, dans une situation sociale (bureau, table entre amis), cadrage buste, lumière naturelle. | Unsplash / Pexels (« embarrassed », « hiding face »), licence libre |
| `shy_speaker_receiving_applause_audience` | partie 3 | 3:2 | Une personne applaudie devant un public ou des collègues (remise de prix, félicitations en réunion), visiblement intimidée par l'attention, vue depuis la salle. | Unsplash / Pexels (« applause award shy »), licence libre |

### 305 · Pourquoi déteste-t-on entendre sa voix enregistrée ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Stacy Jankowski, PhD

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `studio_microphone_headphones_voice_recording` | hero + couverture | 16:9 | Un micro de studio en gros plan avec un casque posé à côté ou une personne au casque qui s'écoute, ambiance studio ou podcast, lumière chaude, micro centré et reconnaissable en petit. | Unsplash / Pexels (« podcast microphone headphones »), licence libre |
| `cochlea_stereocilia_hair_cells_electron_micrograph` | partie 1 | 4:3 | Micrographie électronique à balayage des cellules ciliées de la cochlée : rangées de stéréocils en V, colorisée ou en niveaux de gris, très fort grossissement. | Wikimedia Commons, catégorie « Hair cells » / « Stereocilia » (images NIH-NIDCD ou Wellcome, domaine public ou CC BY) |
| `tuning_fork_weber_test_bone_conduction_skull` | partie 2 | 4:3 | Un diapason appliqué sur le crâne ou l'os derrière l'oreille (test de Weber ou de Rinne) lors d'un examen ORL : le son qui passe par l'os et non par l'air. | Wikimedia Commons, catégorie « Weber test » / « Rinne test » (CC BY-SA), ou photo médicale d'archive domaine public |
| `humanoid_android_robot_face_geminoid` | partie 3 | 4:3 | Visage d'un androïde très réaliste mais pas tout à fait humain (type Geminoid, Repliee ou Sophia), cadrage portrait de face, éclairage neutre : l'effet « vallée de l'étrange ». | Wikimedia Commons, catégories « Geminoid », « Repliee Q2 », « Sophia (robot) » (CC BY-SA) |

### 306 · Pourquoi rit-on quand on nous chatouille ?

Matière : sciences · Rubrique : Notre quotidien expliqué · Prof : Stacy Jankowski, PhD

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `parent_tickling_laughing_child_bed` | hero + couverture | 16:9 | Un parent chatouillant un enfant qui éclate de rire, sur un lit ou un canapé, lumière chaude du matin, les deux visages visibles, cadrage large avec l'enfant au centre. | Unsplash / Pexels (« tickling child laughing »), licence libre |
| `feather_light_touch_skin_knismesis` | partie 1 | 4:3 | Une plume effleurant la peau d'un bras ou d'un pied nu, gros plan, fond uni, pour illustrer la chatouille légère (knismesis) opposée à la chatouille qui fait rire. | Unsplash / Pexels (« feather skin touch »), licence libre |
| `human_brain_anatomy` **(existante)** | partie 2 | 4:3 | Coupe sagittale d'un cerveau humain réel (image déjà en catalogue) : elle montre les régions sous-corticales et le cortex frontal évoqués dans le circuit du rire. | Image existante dans content/images/, à réutiliser telle quelle |
| `young_chimpanzees_play_fighting_laughing` | partie 4 | 3:2 | Deux jeunes chimpanzés (ou bonobos) qui jouent à se bagarrer et se chatouiller, bouche ouverte en « visage de jeu », en semi-liberté ou dans un sanctuaire : le jeu et le lien social chez nos cousins. | Wikimedia Commons, catégories « Juvenile chimpanzees » / « Play behavior in primates » (CC BY-SA) |

### 307 · Comment le christianisme est-il devenu religion d'État ?

Matière : histoire · Rubrique : Antiquité & Moyen Âge · Prof : Vedran Obucina

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `arch_of_constantine_rome_colosseum_view` | hero + couverture | 16:9 | L'arc de Constantin à Rome, élevé en 315 pour célébrer la victoire du pont Milvius, vu de face en plan large, avec le Colisée visible sur le côté, lumière chaude du matin, sans foule au premier plan. | Wikimedia Commons, catégorie « Arch of Constantine (Rome) » (CC BY-SA), ou Unsplash |
| `first_council_of_nicaea_325_byzantine_icon` | partie 1 | 4:3 | Icône ou fresque byzantine du premier concile de Nicée (325) : l'empereur Constantin trônant au centre, entouré des évêques, avec le texte du Credo déployé devant eux. | Wikimedia Commons, catégorie « First Council of Nicaea » (fresques des monastères des Météores ou de Sümela, domaine public) |
| `emperor_julian_apostate_statue_louvre` | partie 2 | 1:1 | La statue en marbre de l'empereur Julien dit l'Apostat conservée au Louvre, cadrée sur le buste et le visage barbu de philosophe, fond sombre. | Wikimedia Commons, article « Julien (empereur romain) », photo de la statue du Louvre (CC BY-SA) |
| `missorium_of_theodosius_388_silver_dish` | partie 3 | 1:1 | Le missorium de Théodose (plat d'argent de 388, Real Academia de la Historia, Madrid) : Théodose Ier trônant au centre, nimbé, entre Valentinien II et Arcadius, plat vu de face en entier. | Wikimedia Commons, article « Missorium de Théodose » (domaine public / CC BY-SA) |

### 308 · Quelle a été la guerre la plus meurtrière de l'histoire ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Vedran Obucina

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `taiping_rebellion_battle_qing_court_painting_1860s` | hero + couverture | 16:9 | Peinture de cour Qing des années 1860 montrant une bataille de la guerre des Taiping : armées en mouvement devant les murailles d'une ville, bannières, fumée des canons, cadrage panoramique. | Wikimedia Commons, catégorie « Taiping Rebellion », album « Suppression of the Taiping Rebellion » du Musée du Palais (domaine public) |
| `hong_xiuquan_portrait_taiping_heavenly_king` | partie 1 | 1:1 | Portrait de Hong Xiuquan, le « Roi céleste », dessin ou gravure du XIXe siècle, buste de face avec coiffe et robe de cérémonie. | Wikimedia Commons, article « Hong Xiuquan » (domaine public) |
| `nanjing_ming_city_wall_zhonghua_gate` | partie 3 | 3:2 | Les murailles Ming de Nankin, porte Zhonghua ou tronçon de rempart en brique, photo actuelle en plan large montrant la masse de la fortification que les Taiping ont tenue onze ans. | Wikimedia Commons, catégorie « City Wall of Nanjing » (CC BY-SA), ou Unsplash |
| `recapture_of_nanjing_1864_qing_court_painting` | partie 4 | 4:3 | Peinture de cour Qing « Reprise de Jinling (Nankin) » de juillet 1864 : les troupes impériales franchissent la brèche des remparts, la ville en flammes derrière. | Wikimedia Commons, catégorie « Taiping Rebellion » (album de la suppression des Taiping, Musée du Palais, domaine public) |

### 309 · D'où vient la science-fiction ?

Matière : litterature · Rubrique : Anglo-saxons & littérature mondiale · Prof : Vedran Obucina

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `melies_trip_to_the_moon_1902` | hero + couverture | 16:9 | Le photogramme célèbre du « Voyage dans la Lune » de Georges Méliès (1902) : le visage de la Lune avec l'obus fiché dans l'œil, recadré en large avec la Lune au centre. | Wikimedia Commons, article « Le Voyage dans la Lune » (domaine public) |
| `galileo_moon_drawings_sidereus_nuncius_1610` | partie 1 | 4:3 | Les lavis de la Lune dessinés par Galilée pour le Sidereus Nuncius (1610) : cratères et reliefs le long du terminateur, première preuve que le ciel n'est pas une voûte parfaite. | Wikimedia Commons, article « Sidereus Nuncius » (domaine public) |
| `frankenstein_monster_illustration_1831` **(existante)** | partie 2 | 3:4 | Le frontispice de l'édition de 1831 de Frankenstein par Theodor von Holst : la créature s'éveillant sur la table du laboratoire, Victor s'enfuyant. | Image déjà disponible dans content/images/ (cours 106), domaine public |
| `amazing_stories_april_1926_cover_frank_paul` | partie 3 | 3:4 | La couverture du premier numéro d'Amazing Stories (avril 1926), illustrée par Frank R. Paul : patineurs sous les anneaux de Saturne et titre en grosses lettres, magazine de Hugo Gernsback. | Wikimedia Commons, article « Amazing Stories » (domaine public aux États-Unis) |

### 310 · Qui a tracé les frontières de l'Afrique ?

Matière : histoire · Rubrique : Époque moderne & XIXe siècle · Prof : Vedran Obucina

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `berlin_conference_1884_engraving_congo_map` | hero + couverture | 16:9 | La gravure de l'Illustrirte Zeitung (1884) montrant la conférence de Berlin : les diplomates européens en redingote autour de la table, la grande carte de l'Afrique accrochée au mur derrière Bismarck, cadrage large. | Wikimedia Commons, article « Conférence de Berlin » (gravure de 1884, domaine public) |
| `africa_colonial_map_1913_european_powers` | partie 1 | 3:4 | Carte d'atlas d'époque (vers 1913) du continent africain colorié par puissance coloniale : Afrique française, britannique, allemande, portugaise, belge, italienne et espagnole, continent entier lisible. | Wikimedia Commons, catégorie « Maps of colonial Africa » (atlas de 1913, domaine public) |
| `anglo_ashanti_war_kumasi_1874_engraving` | partie 2 | 4:3 | Gravure de presse de la guerre anglo-ashanti de 1874 : troupes britanniques entrant à Kumasi ou combat en forêt contre les guerriers ashanti, Illustrated London News ou The Graphic. | Wikimedia Commons, catégorie « Anglo-Ashanti wars » (gravures de 1874 et 1896, domaine public) |
| `oau_founding_summit_addis_ababa_1963` | partie 3 | 3:2 | Photo de la conférence fondatrice de l'Organisation de l'unité africaine à Addis-Abeba en mai 1963 : les chefs d'État africains réunis autour de Haïlé Sélassié dans l'Africa Hall, plan large. | Wikimedia Commons, article « Organisation de l'unité africaine » ; à défaut, photo actuelle de l'Africa Hall d'Addis-Abeba (CC BY-SA) |

### 311 · Qui a inventé les zombies ?

Matière : mythologie · Rubrique : Légendes & créatures · Prof : Vedran Obucina

| Nom du fichier | Rôle | Ratio | Ce que l'image doit montrer | Piste |
| --- | --- | --- | --- | --- |
| `night_of_the_living_dead_1968_still` | hero + couverture | 16:9 | Photogramme de « La Nuit des morts-vivants » de George A. Romero (1968) : la foule des morts-vivants avançant de nuit vers la ferme, noir et blanc, plan large. | Wikimedia Commons, catégorie « Night of the Living Dead » (film tombé dans le domaine public) |
| `haitian_vodou_ceremony_drums_ritual` | partie 1 | 3:2 | Cérémonie vaudou en Haïti : tambours, participants vêtus de blanc, drapeaux brodés et autel, photo documentaire respectueuse, sans mise en scène horrifique. | Wikimedia Commons, catégorie « Vodou in Haiti » (CC BY-SA) |
| `william_seabrook_magic_island_1929_book_cover` | partie 2 | 3:4 | La couverture ou la jaquette de la première édition de « The Magic Island » de William Seabrook (Harcourt, Brace, 1929), avec ses illustrations d'Alexander King. | Wikimedia Commons ou Internet Archive (ouvrage américain de 1929, domaine public depuis 2025) |
| `white_zombie_1932_bela_lugosi_film_poster` | partie 3 | 3:4 | L'affiche originale de « White Zombie » (1932) : Bela Lugosi aux yeux hypnotiques dominant une jeune femme en blanc, lettrage d'époque. | Wikimedia Commons, article « White Zombie (film) » (affiche et film dans le domaine public) |

### Listes copiables

Couvertures :

```
ibm_mainframe_computer_room_1960s_operators
bracero_mexican_farmworkers_california_1942_lange
combine_harvester_wheat_field_aerial
grey_wolf_snowy_forest_dusk
santa_claus_thomas_nast_1881_harpers_weekly
tintagel_castle_ruins_cornwall_coast
tutankhamun_golden_mask_egyptian_museum_cairo
old_besom_broom_stone_wall_rustic
leif_erikson_discovers_america_krohg_1893
genghis_khan_equestrian_statue_tsonjin_boldog_mongolia
great_fire_london_1666_thames_painting
tres_riches_heures_berry_june_haymaking
gutenberg_bible_open_pages_library_of_congress
han_van_meegeren_painting_under_guard_1945
lascaux_cave_hall_of_the_bulls_paintings
venus_de_milo_louvre_gallery_wide_view
miners_in_the_sierras_nahl_1852_painting
amundsen_party_south_pole_polheim_december_1911
superman_fleischer_cartoon_1941_flying_metropolis
alexandria_library_fire_goll_1876_wood_engraving
pompeii_forum_ruins_mount_vesuvius_background
silk_road_camel_caravan_dunhuang_sand_dunes
giza_pyramids_khufu_khafre_menkaure_wide_view
young_spartans_exercising_degas_painting_1860
cobalt_copper_open_pit_mine_kolwezi_drc
hms_agamemnon_laying_atlantic_telegraph_cable_1858
justinian_mosaic_san_vitale_ravenna_purple_robe
victorian_family_daguerreotype_unsmiling_portrait
sarajevo_siege_building_burning_1992
us_navy_aircraft_carrier_at_sea
panmunjom_joint_security_area_blue_huts
swiss_army_soldiers_alps_exercise
genetics_lab_pipette_dna_samples_gloved_hands
dna_double_helix_3d_render_blue
antibiogram_petri_dish_inhibition_zones
un_security_council_vote_iraq_sanctions_1990
cop21_paris_agreement_adoption_2015_fabius_gavel
subic_bay_naval_base_philippines_aerial_us_navy
us_hundred_dollar_bills_stack_close_up
crab_nebula_supernova_remnant_hubble
yellowstone_grand_prismatic_spring_aerial
disassembled_smartphone_components_flat_lay
mars_valles_marineris_hemisphere_viking_mosaic
full_moon_rising_over_ocean_horizon
norman_borlaug_wheat_field_mexico_1960s
berlin_airlift_1948_c54_landing_tempelhof_children
union_carbide_bhopal_abandoned_plant_ruins
soviet_tanks_red_square_moscow_august_1991_coup
apollo_11_aldrin_us_flag_lunar_module_1969
southern_chain_gang_convicts_1900s_photograph
rms_titanic_departing_southampton_april_1912
nemesis_destroying_chinese_war_junks_1841
famine_memorial_custom_house_quay_dublin
shepherd_gate_clock_royal_observatory_greenwich
data_center_server_racks_aisle_blue_lights
wind_turbines_coal_power_plant_landscape
aesop_fox_kylix_vatican_470_bc
george_sand_portrait_auguste_charpentier_1838
anne_frank_red_checkered_diary_1942
machiavelli_portrait_santi_di_tito_florence
gilgamesh_hero_lion_relief_khorsabad_louvre
fresh_coriander_cilantro_bunch_leaves
blushing_red_cheeks_woman_portrait_close_up
studio_microphone_headphones_voice_recording
parent_tickling_laughing_child_bed
arch_of_constantine_rome_colosseum_view
taiping_rebellion_battle_qing_court_painting_1860s
melies_trip_to_the_moon_1902
berlin_conference_1884_engraving_congo_map
night_of_the_living_dead_1968_still
```

Illustrations dans les cours :

```
arpanet_logical_map_1977_network_diagram
tim_berners_lee_next_computer_cern_first_web_server
vasari_lives_of_the_artists_1568_title_page
rubens_copy_battle_of_anghiari_louvre_drawing
renault_billancourt_immigrant_workers_assembly_line
cour_de_cassation_paris_palais_de_justice
georges_marchais_portrait_1981
dairy_cows_grazing_green_pasture
discarded_fruit_vegetables_food_waste_dumpster
agricultural_drone_precision_farming_field
lycaon_turned_into_wolf_goltzius_1589_engraving
marie_de_france_writing_medieval_illumination
werewolf_woodcut_lucas_cranach_elder_1512
sinterklaas_white_horse_arrival_netherlands
a_visit_from_st_nicholas_troy_sentinel_1823
department_store_santa_claus_children_1940s
badbury_rings_hillfort_dorset_aerial
historia_brittonum_harley_3859_manuscript_page
king_arthur_enthroned_royal_ms_20_a_ii
anubis_embalming_mummy_sennedjem_tomb_painting
mumia_apothecary_jar_powdered_mummy_medicine
the_mummy_1932_film_poster_boris_karloff
champion_des_dames_1440_witches_broom_miniature
hans_baldung_grien_witches_1510_woodcut
goya_linda_maestra_capricho_68_witches_broom
skalholt_map_1590_vinland_helluland_markland
lanse_aux_meadows_norse_sod_houses_newfoundland
genghis_khan_portrait_national_palace_museum_taipei
mongol_paiza_gerege_messenger_tablet_yuan_dynasty
mongol_warriors_battle_rashid_al_din_1305
hollar_map_london_burnt_area_1666
great_fire_london_ludgate_fleeing_crowd_painting
monument_great_fire_london_pudding_lane
luttrell_psalter_ploughing_scene_14th_century
tacuinum_sanitatis_medieval_bread_baking_illumination
medieval_public_bathhouse_illumination_15th_century
movable_metal_type_letters_composing_stick
jost_amman_printing_shop_woodcut_1568
luther_ninety_five_theses_1517_printed_broadsheet
van_meegeren_supper_at_emmaus_1937_boijmans
van_meegeren_christ_and_the_adulteress_1942_goring
han_van_meegeren_trial_amsterdam_courtroom_1947
notre_dame_kings_of_judah_heads_musee_cluny
victor_hugo_notre_dame_de_paris_1831_first_edition
notre_dame_paris_fire_15_april_2019_spire_collapse
lascaux_axial_gallery_chinese_horse_painting
magdalenian_bone_harpoons_upper_paleolithic_tools
lascaux_shaft_scene_bird_headed_man_bison
olivier_voutier_drawing_venus_de_milo_1820
venus_de_milo_arms_reconstruction_furtwangler_1893
venus_de_milo_louvre_19th_century_photograph
the_way_they_go_to_california_currier_1849_lithograph
gold_miners_auburn_ravine_1852_daguerreotype
sam_brannan_portrait_daguerreotype_1850s
roald_amundsen_portrait_fur_parka_photograph
scott_shackleton_wilson_discovery_expedition_1902
scott_party_at_south_pole_january_1912_bowers
heracles_fighting_amazons_attic_black_figure_amphora
samson_slaying_the_lion_cranach_1525_painting
oxyrhynchus_greek_papyrus_fragment_ancient_text
abbasid_library_scholars_al_wasiti_1237_maqamat
pompeys_pillar_serapeum_ruins_alexandria_photo
pompeii_via_dell_abbondanza_street_stepping_stones
last_day_of_pompeii_bryullov_1833_painting
pompeii_plaster_casts_victims_garden_of_fugitives
mogao_caves_dunhuang_buddhist_mural_silk_road
plague_in_rome_delaunay_1869_painting_orsay
yersinia_pestis_bacteria_electron_micrograph
great_pyramid_khufu_limestone_blocks_close_up
diary_of_merer_papyrus_wadi_al_jarf
giza_plateau_nile_valley_satellite_view_nasa
delphi_temple_of_apollo_ruins_oracle_greece
spartan_running_girl_bronze_statuette_british_museum
hoplite_phalanx_chigi_vase_corinthian_650_bc
john_goodenough_portrait_lithium_battery_inventor
lithium_ion_battery_fire_thermal_runaway_test
artisanal_cobalt_miners_kolwezi_congo
new_york_atlantic_cable_celebration_september_1858
thomson_mirror_galvanometer_1858_instrument
atlantic_telegraph_cable_1858_cross_section_sample
bolinus_brandaris_murex_shells_tyrian_purple
murex_dyed_wool_shades_purple_to_tekhelet_blue
daguerre_boulevard_du_temple_1838_first_person
robert_cornelius_self_portrait_1839_daguerreotype
frans_hals_malle_babbe_laughing_woman_painting
josip_broz_tito_portrait_marshal_uniform
yugoslav_500_billion_dinar_banknote_1993
srebrenica_potocari_memorial_gravestones
bretton_woods_conference_1944_delegates
immigrants_ellis_island_new_york_1900s
korea_38th_parallel_division_map_1945
republic_of_korea_founding_ceremony_seoul_1948
korean_war_refugees_fleeing_south_1951
palais_des_nations_geneva_flags_alley
swiss_alps_camouflaged_military_bunker
paradeplatz_zurich_ubs_credit_suisse_banks
emmanuelle_charpentier_jennifer_doudna_crispr_pioneers
sickle_cell_red_blood_cells_micrograph
ivf_embryo_icsi_microinjection_micrograph
identical_twins_sisters_portrait_nature_nurture
dna_sequencing_chromatogram_sanger_readout
early_human_migrations_out_of_africa_map
mrsa_staphylococcus_aureus_electron_micrograph_cdc
hospital_operating_room_surgery_team
iraq_water_treatment_plant_baghdad_tigris
oil_for_food_programme_iraq_ration_distribution
garzweiler_lignite_open_pit_mine_germany
mers_el_kebir_naval_base_algeria_harbour
destroyers_for_bases_1940_us_destroyers_halifax
camp_x_ray_guantanamo_detainees_january_2002
gold_bars_federal_reserve_new_york_vault
keynes_harry_dexter_white_bretton_woods_1944
richard_nixon_televised_address_august_1971
helix_nebula_planetary_nebula_white_dwarf_hubble
m87_black_hole_event_horizon_telescope_2019
pillars_of_creation_eagle_nebula_jwst_2022
yellowstone_supereruption_ashfall_map_usgs_2014
mount_pinatubo_eruption_column_1991_clark_air_base
smartphone_logic_board_chips_gold_contacts_macro
salar_de_atacama_lithium_evaporation_ponds_aerial
e_waste_pile_discarded_mobile_phones
jezero_crater_river_delta_mars_reconnaissance_orbiter
maven_solar_wind_stripping_mars_atmosphere_nasa
mars_north_polar_ice_cap_mars_global_surveyor
mont_saint_michel_bay_high_tide_aerial
apollo_11_lunar_laser_retroreflector_nasa_1969
total_solar_eclipse_corona_2017_nasa
india_wheat_revolution_postage_stamp_1968
great_leap_forward_backyard_furnaces_china_1958
germany_allied_occupation_zones_map_1945
gail_halvorsen_candy_bomber_parachutes_1948
taj_mahal_palace_bhopal_shah_jahan_begum
bhopal_gas_tragedy_memorial_statue_mother_child
bhopal_survivors_protest_justice_union_carbide
soviet_union_fifteen_republics_map
mikhail_gorbachev_portrait_1987
alma_ata_protocol_signing_december_21_1991
laika_soviet_space_dog_sputnik_2_1957
apollo_soyuz_handshake_stafford_leonov_1975
lincoln_emancipation_proclamation_carpenter_painting_1864
thirteenth_amendment_joint_resolution_1865_national_archives
convict_leasing_prisoners_florida_1910s
titanic_boat_deck_lifeboats_welin_davits_1912
titanic_lifeboat_survivors_approaching_carpathia_1912
new_york_times_front_page_titanic_1912
patna_opium_factory_stacking_room_1850_lithograph
treaty_of_nanking_signing_hms_cornwallis_1842
chinese_opium_smokers_den_photograph_1880s
daniel_macdonald_irish_family_discovering_blight_1847
skibbereen_famine_engraving_mahony_1847
jeanie_johnston_famine_ship_replica_dublin
bristol_corn_exchange_clock_two_minute_hands
william_allen_railroad_time_zones_map_1883
sandford_fleming_portrait_photograph_1890s
data_center_cooling_pipes_chillers
frontier_supercomputer_oak_ridge_cabinets
high_voltage_power_lines_data_center_virginia
steam_turbine_generator_hall_power_plant
electricity_grid_control_room_operators_screens
belchatow_coal_power_plant_cooling_towers_poland
aesop_velazquez_portrait_1638_prado
hare_and_tortoise_fable_arthur_rackham_1912
indiana_george_sand_1832_title_page
george_sand_mens_clothes_caricature_lorentz_1842
chopin_george_sand_double_portrait_delacroix_1838
anne_frank_diary_handwritten_pages_photos_glued
anne_frank_house_bookcase_secret_annex_entrance
anne_frank_statue_westermarkt_amsterdam_andriessen
il_principe_1532_blado_title_page
lorenzo_de_medici_duke_urbino_raphael_1518
machiavelli_tomb_santa_croce_florence_epitaph
humbaba_clay_mask_face_british_museum
olfactory_nerve_nasal_cavity_gray_anatomy_plate
dna_double_helix_nhgri_illustration
cilantro_lime_mexican_tacos_street_food
thermal_infrared_image_human_face_heat
embarrassed_person_hiding_face_in_hands
shy_speaker_receiving_applause_audience
cochlea_stereocilia_hair_cells_electron_micrograph
tuning_fork_weber_test_bone_conduction_skull
humanoid_android_robot_face_geminoid
feather_light_touch_skin_knismesis
young_chimpanzees_play_fighting_laughing
first_council_of_nicaea_325_byzantine_icon
emperor_julian_apostate_statue_louvre
missorium_of_theodosius_388_silver_dish
hong_xiuquan_portrait_taiping_heavenly_king
nanjing_ming_city_wall_zhonghua_gate
recapture_of_nanjing_1864_qing_court_painting
galileo_moon_drawings_sidereus_nuncius_1610
amazing_stories_april_1926_cover_frank_paul
africa_colonial_map_1913_european_powers
anglo_ashanti_war_kumasi_1874_engraving
oau_founding_summit_addis_ababa_1963
haitian_vodou_ceremony_drums_ritual
william_seabrook_magic_island_1929_book_cover
white_zombie_1932_bela_lugosi_film_poster
```

## Photos des profs

Déjà en place dans `ios/Sophia/Resources/AuthorPhotos/` (512 × 512, JPEG) et
`android/app/src/main/assets/author_photos/` : `author_dusan_nikolic.jpg`, `author_stacy_jankowski.jpg`.
Angela Bouma n'a pas de photo sur la plateforme : l'app affiche ses initiales. Si elle en fournit
une, la déposer sous `author_angela_bouma.jpg` et renseigner `"photo": "author_angela_bouma"`
dans `content/authors.json`.

Lot 2 : six portraits ajoutés (`author_elizabeth_singer_hunt`, `author_guido_manuel_de_la_torre_olvera`,
`author_ivana_toskovic`, `author_mark_n_hoffman`, `author_rana_abdalla`, `author_simon_lea`), recadrés
en carré 512 px depuis les photos de la plateforme. Les huit autres profs du lot n'ont pas de photo
sur la plateforme : initiales.
