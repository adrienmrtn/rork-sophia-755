# Couvertures à créer pour les 9 nouvelles collections

Les neuf collections ajoutées le 28/09 sont en ligne sans illustration : l'app affiche le fond
dégradé de secours (avec une icône sur iOS) tant que l'image n'existe pas. Rien ne casse ; il
suffit de déposer les fichiers pour qu'ils apparaissent.

## Format et dépôt

- JPEG **1200 × 670 px** (ratio ≈ 16:9), 150 Ko maximum comme les couvertures existantes.
- Nom de fichier = le nom indiqué pour chaque collection ci-dessous, suivi de `.jpg`.
- **iOS** : `ios/Sophia/Assets.xcassets/CollectionCovers/<nom>.imageset/` avec le JPEG et un
  `Contents.json` identique à celui des autres couvertures (le fichier en `1x`).
- **Android** : `android/app/src/main/assets/collection_covers/<nom>.jpg`.

Envoie-moi les images, je les installe des deux côtés.

## Style commun (à reprendre pour toutes)

Même famille que les 31 couvertures existantes :

- illustration vectorielle à aplats, formes nettes, léger grain ou dégradés doux ;
- palette saturée : fonds bleu nuit, indigo ou violet, accents orange, or, rouge ou turquoise ;
- scène qui réunit **deux à quatre symboles** des cours de la collection, souvent avec une ou
  plusieurs silhouettes humaines stylisées ;
- sujet principal au centre, lisible en petit sur la carte de la collection ;
- **aucun texte**, aucun logo, aucune lettre.

Base de prompt (en anglais, à compléter par la scène de chaque collection) :

> Flat vector illustration, bold saturated colors, deep navy and purple background with warm
> orange and gold accents, clean geometric shapes, subtle gradients, stylized silhouettes,
> centered composition, 16:9, no text, no letters, no logo. Scene: …

## Les neuf couvertures

### Aux origines de nos monstres
Nom : `collection_aux_origines_de_nos_monstres`
Cours : momies, sorcières, vampires, loup-garou, Frankenstein, zombies.
Scène : une colline sous une pleine lune énorme ; en ombres chinoises, une sorcière sur son
balai qui traverse la lune, un loup-garou qui hurle sur un rocher, la silhouette d'un château
de vampire, une momie qui sort d'un sarcophage au premier plan. Violet profond et vert pâle
de brume, lune jaune or.
> Scene: a huge full moon over a hill, a witch on a broomstick crossing the moon, a werewolf
> howling on a rock, a gothic vampire castle silhouette, a mummy rising from a sarcophagus in
> the foreground, purple night and pale green mist.

### De Gilgamesh à Superman : l'art de raconter
Nom : `collection_de_gilgamesh_a_superman_l_art_de_raconter`
Cours : le plus vieux livre du monde (Gilgamesh), Ésope, le roi Arthur, le père Noël, la
science-fiction, les super-héros.
Scène : un livre ouvert d'où s'échappe un ruban de récits qui s'envole de gauche à droite :
une tablette d'argile cunéiforme, un renard et un corbeau de fable, une épée plantée dans une
pierre, un traîneau dans le ciel, une fusée rétro, et au bout un super-héros cape au vent.
Fond indigo, ruban doré.
> Scene: an open book releasing a golden ribbon of stories flowing left to right: a cuneiform
> clay tablet, a fox and a crow, a sword in a stone, a sleigh in the sky, a retro rocket, and a
> caped superhero flying at the end; indigo background.

### La Guerre froide, un monde coupé en deux
Nom : `collection_la_guerre_froide_un_monde_coupe_en_deux`
Cours : pont aérien de Berlin, Corée, crise de Cuba, course à la Lune, Internet, chute du
Mur, fin de l'URSS.
Scène : l'image coupée en deux par un mur de béton vertical ; à gauche, fond rouge avec une
fusée soviétique ; à droite, fond bleu avec une fusée américaine ; au-dessus du mur, un avion
cargo qui largue des colis, et la Lune en haut au centre. Rouge et bleu, gris béton.
> Scene: the image split in two by a vertical concrete wall, left side red with a Soviet
> rocket, right side blue with an American rocket, a cargo plane dropping parcels above the
> wall, the Moon at the top center.

### Des pyramides à Gengis Khan : énigmes du passé
Nom : `collection_des_pyramides_a_gengis_khan_enigmes_du_passe`
Cours : pyramides, Spartiates, Alexandrie, route de la soie, Pompéi, christianisme, Gengis Khan.
Scène : un paysage continu qui défile de gauche à droite : pyramides sous le soleil, un
hoplite spartiate au bouclier rond, une caravane de chameaux sur une piste, le Vésuve qui
fume au loin, et un cavalier mongol au galop à droite. Ciel orange à violet, sable doré.
> Scene: a continuous panorama from left to right: pyramids under the sun, a Spartan hoplite
> with a round shield, a camel caravan on a trail, Vesuvius smoking in the distance, a Mongol
> horseman galloping on the right; orange to purple sky, golden sand.

### Les petits mystères du corps
Nom : `collection_les_petits_mysteres_du_corps`
Cours : hoquet, bâillement, frissons, rougir, chatouilles, coriandre, entendre sa voix.
Scène : un visage de profil stylisé, joues roses, avec autour de petites icônes qui gravitent :
bulle de hoquet, plume, onde sonore, feuille de coriandre, chair de poule, point
d'interrogation lumineux. Fond bleu nuit, accents rose et turquoise, ton léger et amusé.
> Scene: a stylized face in profile with pink cheeks, small icons orbiting around it: a hiccup
> bubble, a feather, a sound wave, a coriander leaf, goosebumps, a glowing question mark;
> navy background, pink and turquoise accents, playful mood.

### Le XIXe siècle invente le monde moderne
Nom : `collection_le_xixe_siecle_invente_le_monde_moderne`
Cours : guerre de l'opium, famine irlandaise, ruée vers l'or, vieilles photos, fuseaux
horaires, frontières de l'Afrique, Amundsen.
Scène : une locomotive à vapeur qui traverse la scène ; au-dessus, une grande horloge de gare ;
un chercheur d'or avec sa batée au bord d'une rivière ; un appareil photo à soufflet sur
trépied ; au loin, un voilier chargé de caisses. Tons sépia et laiton, ciel bleu profond.
> Scene: a steam locomotive crossing the frame, a large railway station clock above it, a gold
> prospector panning in a river, a bellows camera on a tripod, a sailing ship loaded with
> crates in the distance; sepia and brass tones, deep blue sky.

### Le prix caché de notre quotidien
Nom : `collection_le_prix_cache_de_notre_quotidien`
Cours : électricité, smartphone, cobalt, IA et énergie, nourrir l'humanité, famine évitée,
Bhopal.
Scène : un smartphone géant posé debout, vu en coupe : à l'intérieur, des couches de mine, de
minerai bleu de cobalt et de câbles électriques qui descendent vers une centrale et des champs
de blé. Un petit personnage regarde l'écran, sans voir ce qu'il y a dessous. Bleu nuit, cobalt,
or des champs.
> Scene: a giant upright smartphone shown in cross-section, revealing layers of a mine, blue
> cobalt ore and power cables running down to a power plant and wheat fields; a small person
> looks at the screen unaware; navy, cobalt blue and golden wheat.

### Guerre, paix et diplomatie
Nom : `collection_guerre_paix_et_diplomatie`
Cours : guerre la plus meurtrière, Suisse neutre, OTAN, bases étrangères, Yougoslavie,
sanctions, accords climatiques.
Scène : une longue table de négociation vue de face, drapeaux stylisés sans emblème lisible ;
d'un côté des chars et des casques, de l'autre une colombe qui s'envole et une montagne
enneigée (la neutralité suisse). Fond bleu marine, accents or et rouge.
> Scene: a long negotiation table seen from the front with stylized flags (no readable
> emblems), tanks and helmets on one side, a dove taking off and a snowy mountain on the other;
> navy background, gold and red accents.

### Les secrets des chefs-d'œuvre
Nom : `collection_les_secrets_des_chefs_d_oeuvre`
Cours : Vénus de Milo, violet des rois, Joconde, faux Vermeer, La Nuit étoilée, Le Cri.
Scène : une salle de musée la nuit, éclairée par une lampe torche : la Vénus de Milo sur son
socle, un tableau de Mona Lisa, un ciel en tourbillons façon Nuit étoilée, et au premier plan
une silhouette de faussaire avec pinceau et palette. Violet royal, faisceau de lumière dorée.
> Scene: a museum gallery at night lit by a flashlight beam: the Venus de Milo on a pedestal, a
> Mona Lisa painting, a swirling starry-night sky painting, a forger's silhouette with brush and
> palette in the foreground; royal purple, golden light beam.
