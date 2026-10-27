# Audit du naturel des traductions (26 langues)

Audit fait le 26/10/2026 à la demande « certains pays se plaignent des traductions de l'appli qui ne sont pas naturelles ; analyse surtout pour les langues les moins connues ». Il porte sur tout ce qui est affiché : chaînes d'interface (iOS et Android, 1 066 clés), corps de cours, quiz, glossaire, collections, libellés de rubriques, catalogue (309 titres et descriptions) et fiche App Store. Les constats détaillés, avec une proposition de correction pour chacun, sont dans `docs/audit-traductions/<langue>.json`.

## 1. Résumé

**La plainte est fondée, et elle a une cause précise.** Sophia est traduite en 26 langues à partir du français par Google Translate (`scripts/mt_backend.py`). Quinze langues ont ensuite reçu un guide de traduction (`content/TRANSLATION_GUIDE_*.md`) et une passe d'édition ; **onze n'en ont jamais eu** : danois, norvégien, finnois, russe, estonien, hébreu, slovaque, croate, serbe, slovène, arabe. Pour ces onze langues, les cours, les quiz, le glossaire et les descriptions du catalogue sont encore la sortie brute de la machine. C'est exactement là que les utilisateurs disent que « ça ne sonne pas naturel ».

Deux profils ressortent parmi ces onze langues :

- **Hébreu, arabe, estonien, finnois** (score global 2 à 2,5 sur 5) : tout est touché, y compris l'interface. Les contresens apparaissent dès l'onboarding, dans les écrans que chaque utilisateur traverse : « Débloquer mon essai » est devenu « Commence mon procès » en estonien et en finnois, « Fin de l'essai » « le procès se termine » en hébreu, arabe, estonien et finnois ; « Léger » est devenu « lumière » dans ces quatre langues ; « Premium » est « prime d'assurance » en hébreu et « cher » en arabe ; « Mensuel » est un « magazine mensuel » en hébreu ; « Gratuit » est « libre » en arabe. Le catalogue hébreu dit « mâcher » pour Munch, « huile » pour pétrole, « Estampe, soleil qui se lève » pour *Impression, soleil levant*. Action : relecture native complète.
- **Russe, slovaque, croate, serbe, slovène, danois, norvégien** (interface 4, cours 2) : l'interface a été relue et se lit bien, mais les cours sont de la traduction brute. Le narrateur y parle à la première personne (« Nous voulons le tuer » pour « On veut le tuer », dans 49 à 90 segments par langue), « En 622 » est calqué sans le mot « année », les termes de glossaire restent au nominatif, « spleen » devient « la rate » et « flâneur » « poussette », « six poèmes condamnés » deviennent « six poètes condamnés » (slovène, russe), « 22 ans » devient « 22 lettres » (slovène). Action : relecture native complète des contenus, corrections ciblées de l'interface.

Les langues avec guide (turc, polonais, roumain, néerlandais, grec, suédois, hongrois, bulgare, tchèque) sont à 3 : compréhensibles, parfois fluides, mais trahies par des faux amis et une terminologie produit qui change d'un écran à l'autre. Le bulgare et le turc ont été échantillonnés : corrections ciblées. Le roumain porte le même « procès » que l'hébreu sur « Fin de l'essai » (`Procesul se termină`). Les éditions principales (anglais, espagnol) sont à 4 : quelques calques et, pour l'espagnol, des formes latino-américaines dans une édition destinée à l'Espagne.

**Ce qui explique les erreurs communes.** L'interface des vingt langues ajoutées après les six premières a été traduite à partir du dictionnaire **anglais** (`scripts/translate_ui_strings.py`), et Google Translate passe par l'anglais pour la plupart des paires. Les mêmes contresens reviennent donc d'une langue à l'autre : *trial* → procès, *light* → lumière, *monthly* → magazine, *stroller* (flâneur) → poussette, *caravans* → camping-cars, *spleen* → la rate, *premium* → prime, *free* → libre. Ce sont des erreurs de machine, pas de traducteur, et elles se corrigent par liste.

## 2. Causes racines

1. **Traduction automatique sans post-édition pour onze langues.** `scripts/translate_courses_v2.py` prévient lui-même : « This produces a draft, not a shippable edition ». La passe d'édition prévue (`make_translation_briefs.py` puis `apply_translation_briefs.py`, cadrée par un guide) n'a été faite que pour les quinze langues avec guide. Le validateur mécanique `check_course_translation.py` n'a jamais servi de porte de sortie pour les onze autres : son mode d'emploi ne les liste pas, et il remonte aujourd'hui 11 à 113 constats par langue chez elles contre 0 à 2 chez les langues éditées.
2. **Passage par l'anglais.** Chaînes d'interface traduites depuis l'anglais, contenus traduits par un moteur qui pivote par l'anglais : les mots polysémiques anglais (*trial*, *light*, *free*, *monthly*, *stroller*, *plate*, *fault*, *gravity*, *oil*) sont pris dans le mauvais sens à l'arrivée.
3. **Passes de naturel limitées à l'ossature de l'interface.** La relecture des 24 langues du 30/09 (#242) et `naturalness_ui_v2.py` ont nettoyé onglets, réglages, bibliothèque, parcours ; l'onboarding v1 et les paywalls ont gardé leurs contresens en hébreu, arabe, estonien et finnois ; aucune passe n'a touché les corps de cours, les quiz, le glossaire ni le catalogue.
4. **Pas de table de terminologie par langue.** « Quiz », « cours », « parcours », « essai gratuit », « Premium », « Sophia » ont deux à quatre formes selon l'écran dans presque toutes les langues (hébreu : quatre mots pour quiz ; arabe : trois pour cours ; russe : тест / квиз).
5. **Grammaire assemblée.** Les langues à cas (finnois, estonien, slovaque, slovène, croate, serbe, russe) reçoivent des termes de glossaire et des noms propres au nominatif à l'intérieur de phrases qui exigent un autre cas, et des nombres suivis d'un nom non décliné ; l'adresse à l'utilisateur est au masculin par défaut, y compris dans les témoignages signés Léa, Inès ou Camille.
6. **Corrections appliquées à un seul volet.** `naturalness_quiz.py` a remplacé « Hégire » par la forme locale dans les quiz, pas dans les leçons : la leçon dit « Hegira » et le quiz « Hijra » en danois, norvégien, slovaque, serbe, slovène, finnois et estonien.


## 3. Vue d'ensemble par langue

Scores sur 5 (voir la section 7 pour l'échelle). « Constats relevés » = ce que le relecteur natif a listé sur l'échantillon, plafonné ; « on » → « nous » et « validateur » sont comptés sur les 309 cours. Les langues sont classées par groupe puis par score.

| Langue | Groupe | Guide | Global /5 | UI | Cours | Quiz, gloss. | Catalogue | Store | Constats relevés (bloquants / majeurs / mineurs) | « on » → « nous » (/168) | Validateur | Action |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Estonien (`et`) | C | non | **2.0** | 2.5 | 2.0 | 2.5 | 2.0 | – | 240 (102 / 137 / 1) | 74 | 11 | Relecture complète |
| Hébreu (`he`) | C | non | **2.0** | 2.5 | 2.0 | 2.0 | 2.0 | 2.0 | 386 (112 / 222 / 52) | 68 | 86 | Relecture complète |
| Arabe (`ar`) | C | non | **2.5** | 3.0 | 2.0 | – | – | – | 170 (74 / 93 / 3) | 37 | 113 | Relecture complète |
| Finnois (`fi`) | C | non | **2.5** | 2.5 | 2.0 | – | – | – | 110 (37 / 63 / 10) | 76 | 25 | Relecture complète |
| Russe (`ru`) | C | non | **2.5** | 4.0 | 1.5 | – | – | – | 50 (24 / 26 / 0) | 74 | 68 | Relecture complète |
| Slovène (`sl`) | C | non | **2.5** | 4.0 | 2.0 | – | – | – | 50 (17 / 33 / 0) | 49 | 16 | Relecture complète |
| Danois (`da`) | C | non | **3.0** | 4.0 | 2.0 | – | – | – | 50 (26 / 24 / 0) | 90 | 33 | Relecture complète |
| Croate (`hr`) | C | non | **3.0** | 4.0 | 2.0 | – | – | – | 50 (17 / 33 / 0) | 57 | 7 | Relecture complète |
| Norvégien (`nb`) | C | non | **3.0** | 4.0 | 2.0 | – | – | – | 72 (44 / 28 / 0) | 90 | 15 | Relecture complète |
| Slovaque (`sk`) | C | non | **3.0** | 4.0 | 2.0 | – | – | – | 50 (18 / 32 / 0) | 60 | 53 | Relecture complète |
| Serbe (`sr`) | C | non | **3.0** | 4.0 | 2.0 | – | – | – | 50 (19 / 31 / 0) | 56 | 31 | Relecture complète |
| Bulgare (`bg`) | B | oui | **3.0** | 3.0 | 3.0 | – | – | – | 236 (2 / 84 / 150) | 0 | 1 | Corrections ciblées |
| Turc (`tr`) | B | oui | **3.0** | 3.0 | 3.0 | – | – | – | 173 (9 / 66 / 98) | 0 | 0 | Corrections ciblées |
| Tchèque (`cs`) | B | oui | – | – | – | – | – | – | non échantillonné | 13 | 1 | à échantillonner |
| Grec (`el`) | B | oui | – | – | – | – | – | – | non échantillonné | 0 | 44 | à échantillonner |
| Hongrois (`hu`) | B | oui | – | – | – | – | – | – | non échantillonné | 0 | 1 | à échantillonner |
| Néerlandais (`nl`) | B | oui | – | – | – | – | – | – | non échantillonné | 13 | 0 | à échantillonner |
| Polonais (`pl`) | B | oui | – | – | – | – | – | – | non échantillonné | 0 | 1 | à échantillonner |
| Roumain (`ro`) | B | oui | – | – | – | – | – | – | non échantillonné | 0 | 0 | à échantillonner |
| Suédois (`sv`) | B | oui | – | – | – | – | – | – | non échantillonné | 26 | 1 | à échantillonner |
| Anglais (`en`) | A | oui | **3.5** | 4.0 | 4.0 | 3.0 | – | – | 205 (1 / 70 / 134) | 28 | 0 | Corrections ciblées |
| Espagnol (`es`) | A | oui | **4.0** | 4.0 | 4.0 | – | – | – | 167 (0 / 46 / 121) | 0 | 0 | Corrections ciblées |
| Allemand (`de`) | A | oui | – | – | – | – | – | – | non échantillonné | 5 | 2 | à échantillonner |
| Italien (`it`) | A | oui | – | – | – | – | – | – | non échantillonné | 0 | 0 | à échantillonner |
| Portugais (Brésil) (`pt`) | A | oui | – | – | – | – | – | – | non échantillonné | 0 | 0 | à échantillonner |
| Portugais (Portugal) (`pt-PT`) | A | oui | – | – | – | – | – | – | non échantillonné | 0 | 0 | à échantillonner |



## 4. Motifs systématiques mesurés sur tout le corpus

Les relecteurs natifs décrivent des motifs récurrents ; ceux qui se laissent compter mécaniquement ont été mesurés sur les 309 cours de chaque langue. Ils donnent une image fidèle de ce qui sépare les deux groupes de langues.

### 4.1 Le « on » impersonnel français rendu par « nous »

Le français narratif emploie « on » (« On veut le tuer », « On y vit en tribus »). Le moteur de traduction automatique le rend par « nous », ce qui change le sujet de la phrase : le lecteur estonien lit « Nous voulons le tuer ». Sur les 168 segments où une phrase française commence par « On », voici le nombre de segments où la traduction commence par un « nous » :

| Langue | Guide | Segments « on » → « nous » (sur 168) | Exemple |
|---|---|---|---|
| Danois (`da`) | non | **90** | Vi kan "lugte" en farve eller "se" en parfume. |
| Norvégien (`nb`) | non | **90** | Vi kan "lukte" en farge eller "se" en parfyme. |
| Finnois (`fi`) | non | **76** | Voimme "haistaa" värin tai "nähdä" hajuveden. |
| Russe (`ru`) | non | **74** | Мы можем «понюхать» цвет или «увидеть» аромат. |
| Estonien (`et`) | non | **74** | Me tahame teda tappa. |
| Hébreu (`he`) | non | **68** | אנחנו רוצים להרוג אותו. |
| Slovaque (`sk`) | non | **60** | Chceme ho zabiť. |
| Croate (`hr`) | non | **57** | Želimo ga ubiti. |
| Serbe (`sr`) | non | **56** | Želimo da ga ubijemo. |
| Slovène (`sl`) | non | **49** | Želimo ga ubiti. |
| Arabe (`ar`) | non | **37** | نريد قتله |
| Anglais (`en`) | oui | 28 | We know it as the greatest love story of the stage. (souvent légitime) |
| Suédois (`sv`) | oui | 26 | Vi ser den nästan bara som ett rött öga. |
| Néerlandais (`nl`) | oui | 13 | |
| Tchèque (`cs`) | oui | 13 | |
| Allemand (`de`) | oui | 5 | |
| Espagnol, portugais (2), italien, turc, polonais, roumain, grec, hongrois, bulgare | oui | **0** | |

La coupure est nette : les onze langues sans guide de traduction (`da nb fi ru et he sk hr sr sl ar`) sont restées au stade de la traduction automatique brute ; les langues qui ont eu un guide et une passe de relecture ont été corrigées. Le compte estonien inclut les verbes sans pronom (« Tahame », « Näeme ») ; pour les autres langues seul le pronom explicite est compté, le vrai nombre est donc un peu plus élevé.

### 4.2 « En 1874, … » pris pour un lieu, un film ou un livre

Le français ouvre 244 phrases par « En <année> ». Le moteur a parfois lu « en » comme « dans » :

- **Estonien** : 32 phrases commencent par « Filmis 1984 » (« Dans le film 1984 »), 11 par « Raamatus » (« Dans le livre »), 6 par « Linnas 622 » (« Dans la ville 622 »), 5 par « Mängus » (« Dans le jeu »), 5 par « Väljaandes ». Seules 32 phrases ont la forme naturelle « Aastal 1874 » ou « 1874. aastal ».
- **Finnois** : 93 phrases portent un suffixe de cas sur l'année (« 622:ssa », « 1874:ssä »), forme qu'un Finlandais lit comme un numéro de chambre, et 50 commencent par « Teoksessa / Kirjassa / Elokuvassa / Alueella / Asiassa <année> » (« Dans l'œuvre / le livre / le film / la région / l'affaire 1874 »). La forme naturelle « Vuonna 1874 » n'apparaît que 105 fois.
- **Slovaque, tchèque, croate, serbe, slovène** : le mot « année » manque dans environ la moitié des cas (« V 1492 » au lieu de « V roku 1492 », « U 1492 » au lieu de « 1492. godine », « V 1492 » au lieu de « Leta 1492 »), avec les deux formes qui alternent d'une phrase à l'autre dans le même cours.

### 4.3 Terminologie : le mot de la leçon n'est pas celui du quiz

La passe de naturel sur les quiz (`scripts/naturalness_quiz.py`) a remplacé « Hégire » par la forme locale dans les quiz, mais pas dans les leçons. Résultat, dans le cours sur l'islam, la leçon dit « Hegira » (forme française) et le quiz dit « Hijra » / « Hidžra » en danois, norvégien, slovaque, serbe, slovène, finnois et estonien. Le même décalage leçon/quiz existe pour tout terme corrigé par cette passe.

### 4.4 Résidus techniques dans l'arabe

Le pipeline protège les passages en gras par un jeton avant de les envoyer au moteur ; en arabe, le jeton revient parfois sous la forme d'une lettre isolée en gras (« **ز** ») à la place du texte. On en compte 72 dans 58 cours sur 309. Les relecteurs signalent aussi des chaînes parasites (« ززكسج0زز ») et des termes de glossaire doublés par leur propre traduction.

### 4.5 Ce que dit le validateur mécanique

`scripts/check_course_translation.py` (termes de glossaire perdus, caractères interdits, formats de nombres) donne le même classement :

| Langue | Constats | Cours touchés |
|---|---|---|
| Arabe (`ar`) | 113 | 53 |
| Hébreu (`he`) | 86 | 41 |
| Russe (`ru`) | 68 | 33 |
| Slovaque (`sk`) | 53 | 25 |
| Grec (`el`) | 44 | 22 |
| Danois (`da`) | 33 | 17 |
| Serbe (`sr`) | 31 | 16 |
| Finnois (`fi`) | 25 | 13 |
| Slovène (`sl`) | 16 | 9 |
| Norvégien (`nb`) | 15 | 8 |
| Estonien (`et`) | 11 | 6 |
| Croate (`hr`) | 7 | 4 |
| Allemand, polonais, suédois, hongrois, bulgare, tchèque | 1 à 2 | 1 à 2 |
| Anglais, espagnol, portugais (2), italien, turc, roumain, néerlandais | 0 | 0 |

Ce validateur n'a jamais été exécuté comme porte de sortie pour les onze langues sans guide (son en-tête ne liste que les langues avec guide).


## 5. Détail par langue

Pour chaque langue : verdict, scores, motifs récurrents, et les constats prioritaires avec le texte actuel, ce qu'il dit réellement en français, et la correction proposée. Le reste des constats est dans `docs/audit-traductions/<langue>.json`.


### Groupe C — langues sans guide de traduction (le cœur des plaintes)

### Estonien (`et`) — groupe C, sans guide de traduction

**Score global : 2.0/5** (UI 2.5, cours 2.0, quiz/glossaire 2.5, catalogue 2.0, App Store –). Action : **Relecture complète**. Effort estimé : UI : 1,5 jour (onboarding, paywall, tutoiement, cas) ; catalogue : 2 jours ; cours 1 à 240, quiz et glossaire : relecture native complète, 3 semaines ; les cours 241 à 311 peuvent rester.

La plainte est justifiée : l'estonien est une traduction automatique brute partout sauf dans l'ossature de l'app (onglets, réglages, bloqueur TikTok) et dans les cours les plus récents. Les contresens dominent et ils sont visibles dès l'onboarding : « Débloquer mon essai » est devenu « Commence mon procès (au tribunal) », « Expire dans » « Expire en l'an… », « Léger » « Lumière », Premium « supplément ». Dans les cours, « En 622 » est rendu « Dans la ville 622 », « En 1984 » « Dans le film 1984 » (32 phrases), le « on » impersonnel devient « nous », « New Deal » « nouvelle transaction », « bank runs » « la banque court ». Le catalogue contient des dates fausses (Waterloo le 18 juillet), des titres d'œuvres traduits littéralement alors qu'ils ont une forme estonienne établie, et des jetons corrompus (« Z69 », « ZPea »). S'y ajoutent un vouvoiement résiduel dans l'onboarding et les quiz alors que l'app tutoie, et des cas grammaticaux faux après les nombres et autour des termes de glossaire. Les cours 241 à 311 sont en revanche d'un estonien natif.

Surfaces relues (score du relecteur) : UI (2.5), Cours (2.0), Quiz, glossaire, collections (2.5), Catalogue (2.0). Constats relevés : 240 (102 bloquants, 137 majeurs, 1 mineurs), plus 320 vus mais non listés.

Motifs récurrents :

- « En <année> » lu comme un contenant : « Filmis » (dans le film) 32 fois, « Raamatus » (dans le livre) 11, « Linnas » (dans la ville) 6, « Mängus » 5 ; seules 32 phrases sur 244 ont la forme naturelle « Aastal ».
- « on » impersonnel rendu par « nous » (me / verbes en -me) : 74 segments sur 168 ; l'estonien veut l'impersonnel en -takse.
- Mots polysémiques pris dans le mauvais sens via l'anglais : spleen → organe, flâneur → poussette, correspondances → courrier, caravanes → camping-cars, gravité → sérieux, rater → avoir la nostalgie.
- Vouvoiement ou impératif pluriel (teie, -ge) dans l'onboarding, le profil, les consignes de quiz et les collections, alors que l'app tutoie.
- Cas grammaticaux faux : nominatif après un nombre (partitif attendu), « minu » au lieu du réfléchi « oma », termes de glossaire laissés au nominatif, désinences collées par trait d'union (« 624-s »).
- Noms propres et titres instables (trois graphies de Muhammad, cinq de Narcisse) et titres d'œuvres littéraux à la place de la forme estonienne établie (Kurja lilled, Vihakobarad, Öine vahtkond).
- Terminologie produit flottante : parcours = teekond / reis / rada ; matière = aine / teema / objekt ; réviser = üle vaatama (inspecter) au lieu de kordama.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| onboarding.premiumTrial.cta | Alusta minu kohtuprotsessi | Commence mon procès (au tribunal) | Alusta prooviperioodi | bloquant |
| onboarding.trial.trialEnds | Kohtuprotsess lõppeb | Le procès se termine | Prooviperiood lõppeb | bloquant |
| offer.expiresIn | Aegub aastal | Expire en l'an… | Lõpeb | bloquant |
| onboarding.phone.intensity.light | Valgus | Lumière | Kerge | bloquant |
| onboardingV2.pw.priceNoTrial | Lisatasu %@ (iga-aastane arve). | Supplément %@ (facture annuelle) | Premium hinnaga %@ (arveldatakse kord aastas). | bloquant |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (6 « Linnas… | Linnas **622** peab … kaupmees oma linnast põgenema. | Dans la ville 622, un marchand doit fuir sa ville | Aastal **622** peab … kaupmees oma linnast põgenema. | bloquant |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (74 segment… | Me tahame teda tappa. | Nous voulons le tuer. | Teda tahetakse tappa. | bloquant |
| course_13_la_bataille_de_waterloo_1815/description | **18. juuli 1815. a** varises Belgias | Le 18 juillet 1815, en Belgique… | **18. juunil 1815** varises Belgias | bloquant |
| course_120_l_alchimiste_paulo_coelho/description | Andaluusia lambakoer Santiago | Santiago, chien de berger andalou | Andaluusia lambakarjus Santiago | bloquant |
| course_1_la_naissance_de_l_islam_622_q6 | Kaupmehe haagissuvilate maks | Une taxe sur les camping-cars du marchand | Kaubakaravanide maks | bloquant |

### Hébreu (`he`) — groupe C, sans guide de traduction

**Score global : 2.0/5** (UI 2.5, cours 2.0, quiz/glossaire 2.0, catalogue 2.0, App Store 2.0). Action : **Relecture complète**. Effort estimé : UI : 2 jours (onboarding, paywall, table de terminologie) ; catalogue : 2 jours ; cours, quiz, glossaire : retraduction ou relecture native complète, 3 à 4 semaines ; fiche App Store : 0,5 jour.

La plainte est pleinement justifiée : l'édition hébraïque est, pour l'essentiel, une traduction automatique non relue. Les contresens dominent, et ils touchent ce que tout utilisateur voit dès la première minute : « Fin de l'essai » est devenu « le procès se termine », « Premium » « prime d'assurance », « Mensuel » « magazine mensuel », « Léger » « lumière ». Le catalogue est le pire des cinq volets : « Munch » rendu par « mâcher », « Impression, soleil levant » par « Estampe, soleil qui se lève », « pétrole » par « huile », « ONU » par le préfixe « non- », la Shoah décrite comme « l'attentat contre six millions de Juifs ». Les cours cumulent le « on » rendu par « nous », des accords de genre faux (Écho au masculin), des termes laissés en caractères latins et des titres d'œuvres hors de leur forme hébraïque établie. La terminologie produit n'est pas stabilisée (quatre mots pour « quiz », trois pour « parcours », Sophia translittérée ou non). Seuls les cours récents (hoquet, mort d'une étoile, Yougoslavie) et quelques collections sont d'un hébreu natif, ce qui rend l'écart encore plus visible.

Surfaces relues (score du relecteur) : UI (2.5), Cours (2.0), Quiz, glossaire, collections (2.0), Catalogue (2.0), App Store (2.0). Constats relevés : 386 (112 bloquants, 222 majeurs, 52 mineurs), plus 277 vus mais non listés.

Motifs récurrents :

- Mots polysémiques pris dans le mauvais sens (artefact TA) : plaques → assiettes, failles → pannes, gravité → sévérité, procès → processus, flâneur → poussette, soupes populaires → cosmétiques, Pentagone → figure géométrique.
- « on » impersonnel rendu par « nous » (אנחנו) : 68 des 168 segments concernés dans les cours ; à corriger sur tout le corpus.
- Terminologie produit instable : quiz = חידון / מבחן / בחינה / שאלון ; cours = קורס / שיעור ; parcours = מסלול / מסע / שביל ; Premium = Premium / פרימיום / פרמיה ; Sophia tantôt translittérée (סופיה), tantôt en latin.
- Accords de genre faux sur les personnages féminins (Écho, Scout, Shéhérazade, Rosa Parks) et témoignages signés d'un prénom féminin rédigés au masculin.
- Titres d'œuvres et noms propres hors de leur forme hébraïque établie, translittérés à l'anglaise ou de plusieurs façons dans le même cours (ההגירה / ההיג'רה, קוריש / קורייש).
- Termes de glossaire laissés en caractères latins ou garblés ([[כליףs]], [[razzias]], [[jizya]]), balisage gras coupé au milieu d'un mot.
- Fiche App Store : nom et sous-titre en anglais, description calquée (« sans charpie », « maximiser la garde »), trois registres d'adresse.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| onboarding.trial.trialEnds | המשפט מסתיים | Le procès (judiciaire) se termine | סיום תקופת הניסיון | bloquant |
| paywall.premiumColumn | פרמיה | Prime (d'assurance, bonus) | Premium | bloquant |
| paywall.plan.monthly | ירחון | Un mensuel (périodique) | חודשי | bloquant |
| onboarding.phone.intensity.light | אור | La lumière (clarté) | קל | bloquant |
| course_128_l_expressionnisme_munch_et_le_cri/description | עם **ללעוס** ו-*הצעקה* | avec **mâcher** et *Le Cri* | עם **מונק** ו*הצעקה* | bloquant |
| course_154_impression_soleil_levant_monet/title | הדפס, שמש עולה, מונה | Estampe (gravure), soleil qui se lève, Monet | אימפרסיה, זריחה, מונה | bloquant |
| course_205_le_petrole_comme_source_de_conflits/description | הנה הסיבה ש-**שמן** הוא אף פעם לא רק אנרגיה | voici pourquoi l'**huile** n'est jamais seulement de l'énergie | הנה למה **נפט** הוא אף פעם לא רק אנרגיה. | bloquant |
| course_37_la_shoah_mecanismes_d_un_genocide/description | ארגן את ההתנקשות בשישה מיליון יהודים | a organisé l'attentat (tentative d'assassinat) contre six millions de Juifs | המשטר הנאצי ארגן את רציחתם של שישה מיליון יהודים | bloquant |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (68 segment… | אנחנו רוצים להרוג אותו. | Nous voulons le tuer. | רוצים להרוג אותו. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire_q4 ; s2.b0.text | "טחול ואידיאלי" | « Rate et Idéal » | "ספלין ואידיאל" | bloquant |

### Arabe (`ar`) — groupe C, sans guide de traduction

**Score global : 2.5/5** (UI 3.0, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 1 jour (onboarding v1, paywall, terminologie) ; cours, quiz et glossaire : relecture native complète, 3 semaines ; résidus « **ز** » : script.

La plainte est justifiée. L'interface arabe (3/5) est hétérogène : les écrans récents (onboarding v2, bloqueur TikTok, parcours, audio) sont naturels, mais l'onboarding v1 et le paywall gardent des contresens que tout utilisateur voit : « Gratuit » rendu « libre » (حر), « Premium » « cher » (غالي), « Fin de l'essai » « le procès se termine », « Léger » « lumière », « Reprends du temps pour toi » « prends ton temps vers l'arrière ». La marque est tantôt « صوفيا » tantôt « Sophia », « cours » a trois mots (دورة / درس / دورة تدريبية), « quiz » deux, et les tics de traduction automatique (قم بـ, الخاص بك, يرجى) raidissent le texte. Les cours (2/5) sont, hors deux cours scientifiques, de la traduction brute passée par l'anglais : « on » rendu par « nous » (37 segments), « spleen » rendu « la rate », « flâneur » « poussette », « s'oppose à deux états (d'âme) » devenu « s'oppose à la solution à deux États », « Hégire » rendu par un adjectif, résidus techniques (« **ز** » en gras à la place d'un segment perdu), noms propres en latin ou translittérés à l'anglaise, genres inversés.

Surfaces relues (score du relecteur) : UI (3.0), Cours (2.0), UI + cours (relecture combinée) (2.5). Constats relevés : 170 (74 bloquants, 93 majeurs, 3 mineurs), plus 232 vus mais non listés.

Motifs récurrents :

- « on » impersonnel rendu par « nous » : 37 segments sur 168.
- Faux sens de polysémie via l'anglais : spleen → la rate, loan shark → requin, conviction → croyance, flâneur → poussette, Némésis → l'ennemi, deux états → deux États.
- Résidu technique « **ز** » à la place d'un segment en gras perdu : 72 occurrences dans 58 cours ; termes [[glossaire]] doublés par leur traduction ou balisage perdu.
- Noms propres et titres d'œuvres en latin ou translittérés d'après l'anglais, graphie instable d'un même nom.
- Genres inversés (Écho au masculin, Narcisse au féminin).
- UI : marque صوفيا / Sophia, Premium / بريميوم / المميز, cours = دورة / درس / دورة تدريبية, essai gratuit = تجربة / نسخة تجريبية / محاكمة ; périphrases قم بـ au lieu de l'impératif.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| paywall.freeColumn | حر | libre (au sens de liberté) | مجاني | bloquant |
| paywall.premiumColumn | غالي | cher, coûteux | Premium | bloquant |
| onboarding.trial.trialEnds | تنتهي المحاكمة | le procès (judiciaire) se termine | نهاية التجربة | bloquant |
| onboarding.phone.intensity.light | ضوء | lumière | خفيف | bloquant |
| onboardingV2.screenTime.title | خذ وقتك إلى الوراء | prends ton temps vers l'arrière | استعد وقتك لنفسك | bloquant |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (37 segment… | نريد قتله. | Nous voulons le tuer. | كان هناك من يريد قتله. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s2.b0.text | يعارض حل الدولتين | s'oppose à la solution à deux États (Israël-Palestine) | يقابل بين حالتين نفسيتين | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s2.b0.text | **"الطحال والمثالية"** | « La Rate et l'Idéalisme » | **«سأم ومثال»** | bloquant |
| course_1_la_naissance_de_l_islam_622/s1.b2.text (et autres … | فكرته عن إله واحد **ز** تهدد | son idée d'un dieu unique **z** menace | فكرته عن **الإله الواحد** تهدد | bloquant |
| onboardingV2.welcome.title, témoignages, ambassadeur | مرحبًا بك في صوفيا | Bienvenue dans « Sofia » | مرحبًا بك في Sophia | majeur |

### Finnois (`fi`) — groupe C, sans guide de traduction

**Score global : 2.5/5** (UI 2.5, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 1,5 jour (onboarding, paywall, terminologie, déclinaisons) ; cours, quiz et glossaire : relecture native complète, 3 semaines ; « <année>:ssa » → « vuonna » : script.

La plainte est justifiée pour le finnois, et sur les deux surfaces. L'ossature de l'interface (réglages, parcours, entraînement, bloqueur TikTok, audio) est en finnois correct, mais l'onboarding et le paywall accumulent des erreurs qu'un Finlandais voit tout de suite : « Débloquer mon essai » est devenu « Commence mon procès » (Aloita oikeudenkäyntini), « Fin de l'essai » « le procès se termine », « GLISSE POUR DÉCOUVRIR » deux mots qui n'existent pas (« PYYHÄVÄ LÖYDÄKSI »), la marque réécrite « Sofia », « quiz » rendu par quatre mots dont un inventé (« Tietustelut »). Les cours sont bimodaux : deux cours natifs (hoquet, étoile), deux relus (OTAN, paradis fiscaux), six en traduction brute (islam, Baudelaire, impressionnisme, Narcisse, 1929, Dostoïevski) avec des contresens dès les premières phrases : « 22 ans » devenu « 22 visionnages », « En 1857 » « Dans la publication 1857 », « Vers 630 » « Dans le modèle 630 », « 622 » avec un suffixe de cas collé (« 622:ssa », 93 fois dans le corpus), le VIIe siècle devenu le VIIIe, « on » rendu par « nous » (76 segments), « spleen » par « la rate », « flâneur » par « poussette », mots composés coupés en deux, noms propres sous quatre graphies.

Surfaces relues (score du relecteur) : UI (2.5), UI + cours (relecture combinée) (2.0). Constats relevés : 110 (37 bloquants, 63 majeurs, 10 mineurs), plus 172 vus mais non listés.

Motifs récurrents :

- « En <année> » rendu par un contenant absurde (Julkaisussa, Asiassa, Alueella, Mallissa, Teoksessa, Kirjassa, Elokuvassa : 50 phrases) ou par l'année avec suffixe casuel collé (« 622:ssa » : 93 phrases) ; « Vuonna » n'apparaît que 105 fois sur 244.
- « on » impersonnel rendu par « nous » (me / -mme) : 76 segments sur 168 ; le finnois veut le passif impersonnel.
- Terme de glossaire ou gras laissé au nominatif avec le suffixe collé après le balisage par un deux-points (**Badr**:ssä, [[Kalifi]]:ille).
- « ans » traduit « katselukertaa » (visionnages) : 18 occurrences dans 14 cours, artefact de mémoire de traduction.
- Noms propres et titres instables (Narcissus / Narsissi / Narcisse / Narkissos, Echo / Kaiku, Ovid) ; mots composés coupés (Proosa runo, deflaatio politiikka).
- Faux amis : puissant → tehokas (efficace), touche → kosketus (contact), sensation → sensaatio (scandale), chute → syksy (automne).
- UI : « culture » rendu tieto / kulttuuri au lieu de sivistys ; nombre + nom mal décliné ; anglicismes blocker / anti-scroll / paywall.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| onboarding.premiumTrial.cta | Aloita oikeudenkäyntini | Commence mon procès (au tribunal) | Aloita kokeilujakso | bloquant |
| onboarding.trial.trialEnds | Oikeudenkäynti päättyy | Le procès (judiciaire) se termine | Kokeilu päättyy | bloquant |
| onboarding.showcase.courses.swipe | PYYHÄVÄ LÖYDÄKSI | deux mots qui n'existent pas en finnois | PYYHKÄISE JA TUTUSTU | bloquant |
| course_1_la_naissance_de_l_islam_622/s4.b3.text | Vain **22 katselukertaa** (610-632) | En seulement 22 visionnages (610-632) | Vain **22 vuodessa** (610–632) | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s0.b0.text ; course… | Julkaisussa **1857** … / **622**:ssa … | Dans la publication 1857 / en « 622-dans » | Vuonna **1857** … / Vuonna **622** … | bloquant |
| course_1_la_naissance_de_l_islam_622/s1.b0.text | 700-luvulla Arabia ei kiinnostanut melkein ketään. | Au VIIIe siècle (700-799), l'Arabie n'intéressait presque personne | 600-luvulla Arabia ei kiinnostanut juuri ketään. | bloquant |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (76 segment… | Haluamme tappaa hänet. | Nous voulons le tuer. | Hänet halutaan tappaa. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/hero.hook | Kuusi sensuroitua runoa, yksi vakaumus… | Six poèmes censurés, une conviction (croyance)… | Kuusi sensuroitua runoa, yksi tuomio… | bloquant |
| onboarding.graph.subtitle, paywall.quiz.reviews.title | Sofian kanssa ja ilman | Avec et sans Sofia | Sophian kanssa ja ilman | majeur |
| UI : tietokilpailu / tietovisa / visa / Tietustelut | Tietustelut auttoivat minua… | mot inexistant | Visat auttoivat minua… | majeur |

### Russe (`ru`) — groupe C, sans guide de traduction

**Score global : 2.5/5** (UI 4.0, cours 1.5, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 0,5 jour (terminologie, féminin, « общая культура ») ; cours, quiz et glossaire : relecture native complète, 3 semaines.

La plainte est pleinement justifiée et vise les cours. L'interface russe (4/5) a été relue : tutoiement cohérent, boutons courts, pluriels prévus ; il reste des calques (« в комнате », « общая культура » pour culture générale, « уроков » pour cours), un masculin par défaut qui jure avec les témoignages signés de prénoms féminins, et une terminologie instable (тест / квиз, курс / урок, путь / маршрут, блокер / блокировщик). Les cours (1,5 à 2/5) sont de la traduction automatique brute : « on » rendu par « мы » (74 segments), « Spleen » rendu « селезёнка » (la rate) dans tout le cours Baudelaire, « flâneur » rendu « коляска » (poussette), « six poèmes condamnés » devenus « six versificateurs condamnés », « l'Antiquité approche » pour « s'achève », « razzias » translittéré tel quel, « В 622 » sans « году » (207 phrases), termes de glossaire au nominatif, genres perdus (Écho, НАТО), temps verbaux qui sautent du présent au futur. Un lecteur russe reconnaît la machine dès les premières lignes.

Surfaces relues (score du relecteur) : UI + cours (relecture combinée) (2.5). Constats relevés : 50 (24 bloquants, 26 majeurs, 0 mineurs), plus 75 vus mais non listés.

Motifs récurrents :

- « on » impersonnel rendu par « мы / нам » : 74 segments sur 168.
- Mots polysémiques pris dans le mauvais sens : Pan → Хлопнуть, spleen → селезёнка, flâneur → коляска, motif → выкройка, Impression → Впечатление.
- « En <année> » rendu « В <année> » sans « году » : 207 phrases sur 244.
- Termes [[glossaire]] au nominatif dans une phrase qui exige un autre cas (« основал [[Умма]] »).
- Titres d'œuvres et noms propres sans leur forme russe établie ou laissés en latin (Monet, Manet, Le Déjeuner sur l'herbe).
- Genres perdus (Écho, НАТО он/она/оно) ; temps verbaux incohérents (présent de narration rendu au passé ou au futur).
- UI : terminologie тест / квиз, курс / урок, путь / маршрут, блокер / блокировщик ; masculin par défaut.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| course_1_la_naissance_de_l_islam_622/s0.b0.text (74 segment… | Мы хотим его убить. | Nous voulons le tuer. | Его хотят убить. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s2.b0.text | **«Селезенка и идеал»** … **селезенка**, слово, заимствованное… | « Rate et Idéal » … la rate (organe), mot emprunté… | **«Сплин и идеал»** … **сплин**, слово, заимствованное… | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s2.b2.text | Бодлер бродит как **коляска** | Baudelaire erre comme une poussette | Бодлер бродит по городу как **фланёр** | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s2.b2.text | Шесть стихотворцев были осуждены в 1857 году | Six poètes furent condamnés en 1857 | Шесть стихотворений были запрещены в 1857 году | bloquant |
| course_1_la_naissance_de_l_islam_622/s4.b2.text | Постепенно приближается античность. | Peu à peu, l'Antiquité approche. | Античность постепенно уходит в прошлое. | bloquant |
| cours : 207 phrases sur 244 | В **622** … | la date se lit comme un nombre nu | В **622 году** … | majeur |
| offer.feature1 | 240 курсов по общей культуре | 240 cours de culture commune / collective | 240 курсов для эрудиции | majeur |
| onboardingV2.review.quote | «Раньше я сидел в телефоне по 7 часов в день…» | Léa parle au masculin | «Раньше я сидела в телефоне по 7 часов в день…» | majeur |

### Slovène (`sl`) — groupe C, sans guide de traduction

**Score global : 2.5/5** (UI 4.0, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 0,5 jour de corrections ciblées ; cours, quiz et glossaire : relecture native complète, 2 à 3 semaines.

La plainte est justifiée, mais elle vise les cours, pas l'interface. L'UI slovène (4/5) a été relue : tutoiement constant, boutons courts, pluriels slovènes corrects ; il reste un croatisme sur le paywall (« naplata »), un bouton d'essai qui « lance » un programme, un possessif incohérent (« Odkleni mojih -70 % ») et un masculin exclusif jusque dans les témoignages signés Léa ou Inès. Les cours (2/5) sont de la traduction automatique brute : « 22 ans » devenu « 22 lettres », « 10 000 hommes » « 10 000 dollars », « six poèmes condamnés » « six poètes condamnés », « En 622 » rendu « V 622 » au lieu de « Leta 622 » dans presque chaque date, le « on » rendu par « nous », les termes de glossaire laissés au nominatif, des noms propres non déclinés ou sous forme non slovène. Un lecteur slovène repère la machine dès le premier paragraphe du cours sur l'islam.

Surfaces relues (score du relecteur) : UI + cours (relecture combinée) (2.5). Constats relevés : 50 (17 bloquants, 33 majeurs, 0 mineurs), plus 110 vus mais non listés.

Motifs récurrents :

- « En <année> » rendu « V <année> » / « Pri <année> » (86 cas) au lieu de « Leta <année> ».
- « on » impersonnel ou passif rendu par « nous » : 49 segments sur 168.
- Termes de glossaire [[…]] laissés au nominatif ou remplacés par le titre complet de la fiche : phrases agrammaticales.
- Mots polysémiques pris dans le mauvais sens : ans → črk, hommes → dolarjev, poèmes → pesnikov, Spleen → vranica, flâneur → otroški voziček, lumière → lahkotnost.
- Noms propres non déclinés ou sous forme non slovène (Ovid, Echo, Hegira, Yathrib, Narcisse) ; genre calqué du français (Écho au masculin, Narcisse au féminin).
- Masculin par défaut dans toute l'UI (Dobrodošel, Končal si, Pripravljen sem) et dans les témoignages signés d'un prénom féminin.
- Terminologie produit flottante : tečaj / lekcija, raven / stopnja, blocker / blokator / anti-scroll.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| course_1_la_naissance_de_l_islam_622/s4.b3.text | V samo **22 črk** (610-632) je Mohamed spremenil… | En seulement 22 lettres (de l'alphabet)… | V samo **22 letih** (610–632) je Mohamed… | bloquant |
| course_1_la_naissance_de_l_islam_622/s3.b0.text | Mohamed koraka proti Meki z **10.000 dolarjev**. | Muhammad marche sur La Mecque avec 10 000 dollars. | Mohamed s **10.000 možmi** koraka proti Meki. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s2.b2.text | Šest pesnikov je bilo obsojenih leta 1857 | Six poètes furent condamnés en 1857 | Šest pesmi je bilo leta 1857 obsojenih | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s1.b0.text | Osirotel … pri **6 črk** | orphelin à 6 lettres | Pri **6 letih** ostane brez očeta | bloquant |
| cours : 86 phrases sur 244 | V **622** mora trgovec … pobegniti | calque de la préposition française | Leta **622** mora trgovec … pobegniti | majeur |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (49 segment… | Želimo ga ubiti. | Nous voulons le tuer. | Hočejo ga ubiti. | bloquant |
| onboardingV2.pw.yearlyBilling | letna naplata | « naplata » est le mot croate/serbe pour facturation | zaračunano letno | majeur |
| onboardingV2.pw.startTrial | Zaženi {n} dni brezplačno | Démarre (un moteur) {n} jours gratuitement | Začni {n}-dnevni brezplačni preizkus | majeur |
| onboardingV2.review.quote, paywall.reviews.r3.quote, onboar… | Prej sem na telefonu preživel 7 ur … / Pripravljen sem | formes masculines pour Léa, Inès | preživela … / Gremo! | majeur |

### Danois (`da`) — groupe C, sans guide de traduction

**Score global : 3.0/5** (UI 4.0, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 0,5 jour (terminologie, onglet Parcours) ; cours, quiz et glossaire : relecture native complète, 2 à 3 semaines.

La plainte est justifiée pour le danois, et elle vise presque uniquement les cours. L'interface (4/5) est du danois naturel, tutoyé et relu ; ses défauts sont des flottements de terminologie (kurser / lektioner, rute / forløb / rejse, afmeld / opsig, gratis prøve / prøveperiode), quelques calques (« person i rummet », « skinne i samtaler ») et l'onglet Parcours nommé « Rute » (itinéraire de bus). Les cours (2/5) sont de la traduction automatique brute : « on » rendu par « vi » (90 segments, le maximum du corpus avec le norvégien), « 360 idoles » devenues le verbe « idolâtrer », l'expansion reprise par « hun » (elle, une femme), « une condamnation » devenue « une conviction intime », « spleen » « la rate », « flâneur » « poussette », titres d'œuvres inventés ou laissés en français, termes de glossaire déformés, temps verbaux qui changent dans la même phrase. Les deux cours scientifiques de l'échantillon sont, eux, d'un danois natif.

Surfaces relues (score du relecteur) : UI + cours (relecture combinée) (2.5). Constats relevés : 50 (26 bloquants, 24 majeurs, 0 mineurs), plus 85 vus mais non listés.

Motifs récurrents :

- « on » impersonnel rendu par « vi » : 90 segments sur 168.
- Pronoms et possessifs calqués sur le genre français : « hun » pour l'expansion, « hans krop » pour Écho.
- Mots polysémiques pris dans le mauvais sens : spleen → milt, flâneur → barnevogn, condamnation → overbevisning.
- Titres d'œuvres et noms de sections laissés en anglais ou en français, ou inventés (Syndens blomster) au lieu du titre danois établi.
- Termes [[glossaire]] déformés, anglicisés ou remplacés par un libellé d'article.
- Noms propres en forme française ou latine, incohérents d'un paragraphe à l'autre (Echo / Ekko, Narcisse / Narkissos).
- Temps verbaux instables : présent narratif et passé dans la même phrase.
- UI : terminologie kurser / lektioner, rute / forløb / rejse, afmeld / opsig, gratis prøve / prøveperiode.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| course_1_la_naissance_de_l_islam_622/s0.b0.text (90 segment… | Vi vil slå ham ihjel. | Nous voulons le tuer. | Nogen vil slå ham ihjel. | bloquant |
| course_1_la_naissance_de_l_islam_622/s1.b0.text | ca. **360 idolisere**, eller omtrent en for hver dag | environ 360 idolâtrer (verbe), soit à peu près une par jour | omkring **360 afguder** – altså cirka én for hver dag | bloquant |
| course_1_la_naissance_de_l_islam_622/s4.b0.text (motif syst… | Udvidelsen er ikke kun militær. Hun er også organiseret. | L'expansion n'est pas que militaire. Elle (pronom de personne) est aussi organisée. | Ekspansionen er ikke kun militær. Den er også organiseret. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/hero.hook | Seks censurerede digte, en overbevisning og fødslen af… | Six poèmes censurés, une conviction (croyance) et la naissance de… | Seks censurerede digte, en domfældelse og den moderne poesis fødsel. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s1.b0.text | Forældreløs af sin far på **6 år** skændes han med sin… | calque mot à mot, agrammatical en danois | Han mister sin far som **6-årig** og ligger i strid med… | bloquant |
| tab.path | Rute | itinéraire (de bus, de randonnée) | Forløb | majeur |
| paywall.header | Bliv den mest⏎interessante⏎person i rummet. | dans l'espace / dans la pièce (sens spatial) | Bliv den mest⏎interessante⏎person i selskabet. | majeur |
| onboardingV2.motivation.conversations | For at skinne i samtaler | Pour luire (comme le soleil) dans les conversations | For at brillere i samtaler | majeur |

### Croate (`hr`) — groupe C, sans guide de traduction

**Score global : 3.0/5** (UI 4.0, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 0,5 jour (deux contresens, féminin, terminologie) ; cours, quiz et glossaire : relecture native complète, 2 à 3 semaines.

La plainte est justifiée et recouvre deux surfaces différentes. L'interface croate (4/5) est éditée et idiomatique (tečaj, tjedan, povijest, guillemets corrects, « ti » constant), mais deux chaînes sont franchement embarrassantes : « Pas de connexion » est devenu « Nema veze » (« pas grave, peu importe ») et « s'écoutent sans connexion » « slušaš bez veze » (« tu écoutes pour rien »). S'y ajoutent le masculin par défaut dès l'accueil, « la personne la plus intéressante de la salle », l'anglicisme « blocker » et une terminologie flottante (tečaj / lekcija, staza / putanja, proba / probno razdoblje). Les cours (2/5) sont, pour quatre leçons sur cinq, de la traduction automatique brute : « on » rendu par « nous » (57 segments), « U 622 » sans « godine » (133 phrases), Baudelaire qui « joue » le poète maudit, « l'Antiquité s'approche », beau-père rendu par « père de l'épouse », spleen par « la rate », termes de glossaire au nominatif, guillemets anglais. La leçon sur l'OTAN, relue, montre ce que donne le croate quand il est édité.

Surfaces relues (score du relecteur) : UI + cours (relecture combinée) (2.5). Constats relevés : 50 (17 bloquants, 33 majeurs, 0 mineurs), plus 75 vus mais non listés.

Motifs récurrents :

- « on » impersonnel rendu par « nous » : 57 segments sur 168.
- « En <année> » calqué « U <année> » : 133 phrases sur 244.
- Noms propres, titres et termes [[glossaire]] au nominatif dans le balisage alors que la syntaxe exige un cas.
- Mots polysémiques pris dans le mauvais sens : spleen → slezena, flâneur → dječja kolica, touche → dodir.
- Guillemets anglais ou droits dans les cours (l'UI utilise les bons).
- Masculin par défaut ; terminologie tečaj / lekcija, staza / putanja, proba / probno razdoblje, blocker.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| paywall.error.network | Nema veze. Provjeri mrežu i pokušaj ponovno. | Peu importe. Vérifie le réseau et réessaie. | Nema internetske veze. Provjeri mrežu i pokušaj ponovno. | bloquant |
| audio.downloads.footer | Preuzete zapise slušaš bez veze. | Tu écoutes les fichiers téléchargés pour rien. | Preuzete zapise možeš slušati i bez interneta. | bloquant |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (57 segment… | Želimo ga ubiti. | Nous voulons le tuer. | Žele ga ubiti. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s1.b0.text | **Charles Baudelaire** glumi **prokletog pjesnika** | Charles Baudelaire joue (comme un acteur) le poète maudit | **Charles Baudelaire** utjelovljuje **prokletog pjesnika** | bloquant |
| course_1_la_naissance_de_l_islam_622/s4.b2.text | Malo po malo, antika se približava. | Peu à peu, l'Antiquité s'approche. | Malo-pomalo antika se zatvara. | bloquant |
| cours : 133 phrases sur 244 | U **622**, … | sans « godine » ni point ordinal | **622.** godine … | majeur |
| onboardingV2.welcome.title, onboarding.final.subtitle | Dobro došao u Sophiju | Bienvenue (participe masculin) | Dobro došli u Sophiju | majeur |
| paywall.header | Postani⏎najzanimljivija⏎osoba u prostoriji. | de la salle, du local | Postani⏎najzanimljivija⏎osoba u društvu. | majeur |

### Norvégien (`nb`) — groupe C, sans guide de traduction

**Score global : 3.0/5** (UI 4.0, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 0,5 jour ; cours, quiz et glossaire : relecture native complète, 2 à 3 semaines ; guillemets et « on » → tournure impersonnelle : relecteur.

La plainte est justifiée pour le norvégien, et elle vise presque uniquement les cours. L'interface (4/5) a été relue : tutoiement naturel, boutons courts, guillemets « » corrects, bonnes idiomatisations (« Da kjører vi », « på T-banen ») ; il reste quelques fautes visibles sur le paywall et l'onboarding (« Et smugkikk », « Lås opp mine -70 % », « doktorer », « Du brenner ») et des flottements de terminologie (kurs / leksjon, prøve / prøveperiode, løype / rute / reise, blocker / blokkering). Les cours (2/5) sont, pour quatre leçons sur cinq, de la traduction automatique brute : « on » rendu par « vi » (90 segments, le plus haut de toutes les langues avec le danois), « 360 idoles » devenues le verbe « 360 idolâtrer », « reddition » devenue l'impératif « rends-toi », « une condamnation » « une conviction intime », le VIIe siècle devenu le VIIIe (« 700-tallet »), objets et abstractions repris par « hun/han » selon le genre français, guillemets anglais, temps verbaux qui alternent d'une phrase à l'autre, noms propres en forme anglaise (« Echo » pour Ekko).

Surfaces relues (score du relecteur) : UI + cours (relecture combinée) (2.5), UI. Constats relevés : 72 (44 bloquants, 28 majeurs, 0 mineurs), plus 80 vus mais non listés.

Motifs récurrents :

- « on » impersonnel rendu par « vi » : 90 segments sur 168, le maximum du corpus avec le danois.
- Pronoms calqués sur le genre grammatical français : objets et abstractions deviennent « hun / han », genre des personnages inversé.
- Faux sens de polysémie par pivot anglais : flâneur → stroller → barnevogn (poussette), condamnation → conviction → overbevisning, spleen → milt (la rate).
- Guillemets droits anglais dans les cours (l'UI a les bons « »), parfois mélangés dans la même citation.
- Noms propres, termes de glossaire et titres d'œuvres en forme anglaise, latine ou française (Echo, Hegira, Les Fleurs du Mal).
- Temps verbaux instables : présent de narration et prétérit alternent d'une phrase à l'autre.
- UI : terminologie kurs / leksjon, prøve / prøveperiode, løype / rute / reise, blocker / blokkering, rang / rangering.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| course_1_la_naissance_de_l_islam_622/s0.b0.text (90 segment… | Vi vil drepe ham. | Nous voulons le tuer. | Noen vil ta livet av ham. | bloquant |
| course_1_la_naissance_de_l_islam_622/s1.b0.text | På 700-tallet interesserte Arabia nesten ingen. | Au VIIIe siècle (700-tallet), l'Arabie n'intéressait presque personne | På 600-tallet er det nesten ingen som bryr seg om Arabia. | bloquant |
| course_1_la_naissance_de_l_islam_622/s1.b0.text | Kabaen huset omtrent **360 idolisere** | La Kaaba abritait environ 360 idolâtrer (verbe) | Kabaen huset rundt **360 avgudsbilder** | bloquant |
| course_1_la_naissance_de_l_islam_622/s3.b3 (timeline) | Overgi deg uten kamp og generell benådning. | Rends-toi sans combat et grâce générale. | Overgivelse uten kamp og allmenn amnesti. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/hero.hook | Seks sensurerte dikt, en overbevisning og fødselen til… | Six poèmes censurés, une conviction (certitude) et la naissance de… | Seks sensurerte dikt, én domfellelse og den moderne poesiens fødsel. | bloquant |
| course_1_la_naissance_de_l_islam_622/s4.b0.text (motif syst… | Utvidelsen er ikke bare militær. Hun er også organisert. | L'expansion n'est pas seulement militaire. Elle (une femme) est aussi organisée. | Ekspansjonen er ikke bare militær. Den er også organisert. | bloquant |
| course_1_la_naissance_de_l_islam_622/description | Denne avgangen, Hegira, markerer år 1 av islam | Ce départ (de train), Hegira, marque l'an 1 de l'islam | Denne utvandringen, hijra, markerer år 1 i den islamske tidsregningen | majeur |
| offer.unlock | Lås opp mine -70 % | Déverrouille mes -70 % | Hent rabatten på 70 % | majeur |

### Slovaque (`sk`) — groupe C, sans guide de traduction

**Score global : 3.0/5** (UI 4.0, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 0,5 jour (essai, conscience, bohémisme, féminin) ; cours, quiz et glossaire : relecture native complète, 2 à 3 semaines.

La plainte est justifiée, surtout pour les cours. L'interface slovaque (4/5) est dans l'ensemble naturelle et visiblement relue : tutoiement, boutons courts, pluriels gérés. Restent quelques vrais accrocs visibles dès l'onboarding : « Ta progression culturelle » rendue « Voici comment grandit ta conscience » (vedomie = conscience), le bouton d'essai « Spustiť skúšku » (« Lancer l'examen »), un bohémisme (« Rádi »), des témoignages féminins conjugués au masculin et une terminologie flottante (kurz / lekcia, pokrok / postup, blocker / blokátor). Les cours (2/5) sont de la traduction automatique brute : « on » rendu par « nous » (« Chceme ho zabiť », 60 segments dans le corpus), « En 622 » rendu « V 622 » sans « roku » (138 phrases), termes de glossaire et noms propres laissés au nominatif, mots polysémiques pris dans le mauvais sens (spleen → rate, flâneur → poussette, condamnation → conviction), accords de genre perdus (Écho au masculin), et des phrases qui ne veulent plus rien dire (« facilite l'installation d'une nouvelle énergie dans des régions fatiguées »).

Surfaces relues (score du relecteur) : UI + cours (relecture combinée) (3.0). Constats relevés : 50 (18 bloquants, 32 majeurs, 0 mineurs), plus 110 vus mais non listés.

Motifs récurrents :

- « on » impersonnel rendu par « nous » : 60 segments sur 168.
- « En <année> » rendu « V <année> » sans « roku » : 138 phrases sur 244, en alternance avec la forme correcte.
- Noms propres, titres et termes [[glossaire]] laissés au nominatif après préposition ou verbe (le slovaque décline).
- Mots polysémiques pris dans le mauvais sens : spleen → rate, flâneur → poussette, source → ressource, pouvoir → énergie, condamnation → conviction.
- Accords de genre perdus (Écho, le recueil) ; masculin par défaut dans l'UI et les témoignages féminins.
- « Essai gratuit » rendu par « skúška » (examen) en concurrence avec « skúšobné obdobie » ; terminologie kurz / lekcia, blocker / blokátor.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| onboarding.premiumTrial.cta | Spustiť skúšku | Lancer l'examen (skúška = examen) | Vyskúšať zadarmo | bloquant |
| onboarding.graph.title | Takto rastie⏎tvoje vedomie | Voici comment grandit ta conscience | Takto rastie⏎tvoj rozhľad | bloquant |
| course_1_la_naissance_de_l_islam_622/s0.b0.text (60 segment… | Chceme ho zabiť. | Nous voulons le tuer. | Chcú ho zabiť. | bloquant |
| cours : 138 phrases sur 244 | V **622** … | calque ; le slovaque dit « V roku 622 » | V roku **622** … | majeur |
| course_1_la_naissance_de_l_islam_622/s4.b0.text | uľahčuje inštaláciu novej energie v unavených oblastiach | facilite l'installation d'une nouvelle énergie dans des régions fatiguées | uľahčuje nástup novej moci v oblastiach vyčerpaných vojnou | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/description | jedno presvedčenie | une conviction, une croyance | jeden súdny rozsudok | bloquant |
| onboardingV2.existingAccount.title | Rádi ťa znova vidíme | « Rádi » est la forme tchèque | Radi ťa znova vidíme | majeur |
| onboardingV2.review.quote | Predtým som na telefóne trávil 7 hodín denne… | Léa parle au masculin | Predtým som na telefóne trávila 7 hodín denne… | majeur |

### Serbe (`sr`) — groupe C, sans guide de traduction

**Score global : 3.0/5** (UI 4.0, cours 2.0, quiz/glossaire –, catalogue –, App Store –). Action : **Relecture complète**. Effort estimé : UI : 0,5 jour ; cours, quiz et glossaire : relecture native complète, 2 à 3 semaines.

La plainte est justifiée et vise d'abord les cours. L'interface serbe (4/5) est fluide et tutoyée ; ses accrocs sont la marque tantôt déclinée (uz Sophiju), tantôt non (Bez Sophia, Ostani u Sophia), tantôt mal déclinée (Podeli Sophiu), un masculin par défaut (Dobro došao, Spreman sam), quelques calques (« Bienvenue sur le bateau », « la personne la plus intéressante du local ») et des termes produit instables (kurs / lekcija, staza / putanja, proba / probni period). Les cours (2/5) sont, pour quatre leçons sur cinq, de la traduction automatique brute : « on » rendu par « nous » (56 segments), « Rendez-vous sans combat » à l'impératif, « l'Antiquité s'approche » pour « l'Antiquité s'achève », « beau-père » rendu par « père de l'épouse », « Spleen » par « la rate », « U 622 » au lieu de « 622. godine » (148 phrases), termes de glossaire au nominatif, noms propres en graphie française mutilée.

Surfaces relues (score du relecteur) : UI + cours (relecture combinée) (3.0). Constats relevés : 50 (19 bloquants, 31 majeurs, 0 mineurs), plus 95 vus mais non listés.

Motifs récurrents :

- « on » impersonnel rendu par « nous » : 56 segments sur 168.
- « En <année> » calqué « U <année> » (148 cas) au lieu de « 622. godine » / « Godine 622. ».
- Termes de glossaire [[…]] insérés au nominatif quelle que soit la fonction dans la phrase.
- Noms propres et titres d'œuvres en graphie française ou anglaise, accents supprimés, transcription incohérente (le serbe transcrit : Opik, Bodler).
- Mots polysémiques pris dans le mauvais sens : beau-père → tast, condamnation → uverenje, états → države, Spleen → slezina.
- Genre calqué du français (Écho, Médine, le recueil) ; masculin par défaut pour l'utilisateur.
- Marque Sophia déclinée de trois façons ; termes produit instables (kurs / lekcija, staza / putanja, proba / probni period, blocker / bloker).

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| course_1_la_naissance_de_l_islam_622/s0.b0.text (56 segment… | Želimo da ga ubijemo. | Nous voulons le tuer. | Hoće da ga ubiju. | bloquant |
| course_1_la_naissance_de_l_islam_622/s3.b3 (timeline) | Predajte se bez borbe i opšteg pomilovanja. | Rendez-vous sans combat ni pardon général. | Predaja bez borbe i opšte pomilovanje. | bloquant |
| course_1_la_naissance_de_l_islam_622/s4.b2.text | Malo po malo, Antika se približava. | Peu à peu, l'Antiquité s'approche. | Malo-pomalo, antika se završava. | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s1.b0.text | svađa sa svojim tastom, generalom **Aupick** | se dispute avec le père de son épouse | svađa se sa očuhom, generalom **Opikom** | bloquant |
| course_100_les_fleurs_du_mal_baudelaire/s2.b0.text | **„Slezina i ideal“** | « La Rate (l'organe) et l'idéal » | **„Splin i ideal“** | bloquant |
| cours : 148 phrases sur 244 | U **622**, trgovac iz Meke… | préposition de lieu sans « godine » | Godine **622.** trgovac iz Meke… | majeur |
| onboarding.graph.withoutSophia, share.card.title | Bez Sophia / Podeli Sophiu | Sophia au nominatif après préposition ; accusatif mal formé | Bez Sophije / Podeli Sophiju | majeur |
| onboardingV2.aboard.title | Dobro došao na brod! | Bienvenue sur le bateau | Dobro nam došao/la! | majeur |
| paywall.header | najzanimljivija⏎osoba u prostoriji | du local, de la salle | Postani⏎najzanimljivija⏎osoba u društvu. | majeur |


### Groupe B — langues avec guide

### Bulgare (`bg`) — groupe B, avec guide de traduction

**Score global : 3.0/5** (UI 3.0, cours 3.0, quiz/glossaire –, catalogue –, App Store –). Action : **Corrections ciblées**. Effort estimé : UI : 1 jour (table de terminologie, faux amis, féminin) ; cours d'histoire et de littérature : 1 semaine de relecture native ; typographie : script.

La plainte est partiellement justifiée. Le bulgare est compréhensible et souvent fluide (onboarding, réglages, bloqueur TikTok, cours scientifiques), mais il trahit la traduction par des faux amis récurrents : « cultivé » rendu par « културен » (poli, bien élevé), « anecdotes » par « анекдоти » (blagues), « Renaissance » par « Възраждане » (le Réveil national bulgare). La terminologie produit n'est pas stabilisée (курс / урок, тест / куиз, маршрут / пътека / път, Premium / Премиум) et l'adresse est au masculin par défaut, jusque dans les témoignages signés Léa ou Inès. Les cours d'histoire (islam, OTAN, 1929, Suez, Lancelot) et de littérature mélangent aoriste et présent dans le même paragraphe, calquent les verbes français (lancer → пусна, transformer → обърна), insèrent les termes de glossaire sans accord et gardent des noms propres en latin ; le « tsar Arthur » et le « siège militaire périlleux » sont des contresens. Les conventions typographiques bulgares ne sont pas respectées (« 7. век » au lieu de « VII век », point comme séparateur de milliers, année sans « г. »). Le « on » → « nous » n'apparaît pas : la passe guidée a bien eu lieu.

Surfaces relues (score du relecteur) : UI (3.0), Cours (3.0). Constats relevés : 236 (2 bloquants, 84 majeurs, 150 mineurs), plus 27 vus mais non listés.

Motifs récurrents :

- Faux ami « culture / cultivé » → « култура / културен » (systématique).
- Terminologie produit instable : курс / урок, тест / куиз, маршрут / пътека / път / пътешествие, Premium / Премиум.
- Masculin par défaut pour l'utilisateur et dans les témoignages féminins.
- Présent historique rendu tantôt à l'aoriste, tantôt au présent dans le même paragraphe (cours d'histoire).
- Typographie : siècles en ordinal (7. век), point comme séparateur de milliers, année sans « г. ».
- Calques verbaux : lancer → пусна, transformer → обърна, compter → брои ; termes de glossaire insérés sans accord.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| paywall.quiz.demo.chrono.i3 | Възраждане | le Réveil national bulgare (XVIIIe–XIXe siècle) | Ренесанс | bloquant |
| paywall.quiz.subtitle, share.message (motif systématique) | …и стани истински културен. | …et deviens vraiment bien élevé. | …и стани истински начетен. | majeur |
| paywall.review4.quote | откъде намирам всички тези анекдоти | d'où je trouve toutes ces blagues | откъде знам всички тези интересни факти | majeur |
| course_195_lancelot_guenievre_et_la_table_ronde/s2.b3.text | На масата [[Опасна обсада]] чака… | À la table, le Siège (militaire) dangereux attend… | На масата [[Опасното място]] чака… | bloquant |
| course_195_lancelot_guenievre_et_la_table_ronde | цар **Артур** … царица **Гуиневира** | le tsar Arthur, la tsarine Guenièvre | крал **Артур** … кралица **Гуиневир** | majeur |
| cours : motif systématique | 7. век, 19. век | convention non bulgare | VII век, XIX век | majeur |
| onboarding (durées, pourcentages) | Това са 23 дни пълни дни / 87% на потребителите | « Ce sont 23 jours pleins jours » / « 87 % des utilisateurs » (mauvaise préposition) | Това са 23 цели дни / 87% от потребителите | majeur |

### Turc (`tr`) — groupe B, avec guide de traduction

**Score global : 3.0/5** (UI 3.0, cours 3.0, quiz/glossaire –, catalogue –, App Store –). Action : **Corrections ciblées**. Effort estimé : UI : 0,5 jour ; cours anciens (islam, littérature, art, économie) : 1 semaine de relecture native ; % : script.

La plainte est partiellement justifiée. Le turc est tutoyé, le balisage est préservé et les cours récents (Lascaux, frontières de l'Afrique, mort d'une étoile, hoquet) se lisent comme du turc natif. Mais les cours plus anciens (islam, Baudelaire, impressionnisme, Narcisse, 1929, paradis fiscaux) restent truffés de calques (« İşte … nasıl … », « dayatmak » pour imposer, « kocaman » enfantin) et de contresens embarrassants : Némésis traduite par « l'Ennemi », « bank runs » par « opérations bancaires », « offshore » par « haute mer », la relance par « guérir », Héra qualifiée de « bonne femme jalouse ». L'UI (relue en partie) garde des étiquettes bancales (« Süresi doluyor » pour « Expire dans », « Ödeme duvarı » paywall traduit mot à mot) et le signe % placé à la française après le nombre dans la moitié des cours.

Surfaces relues (score du relecteur) : Cours (3.0), UI. Constats relevés : 173 (9 bloquants, 66 majeurs, 98 mineurs), plus 12 vus mais non listés.

Motifs récurrents :

- « Voici comment… » rendu par une nominalisation « İşte … nasıl …-dığı » au lieu d'une phrase finie.
- « imposer » systématiquement « dayatmak » (forcer, connoté) ; « énorme / minuscule » rendus par « kocaman / minicik » (registre enfantin).
- Signe % après le nombre dans la moitié des cours (convention française).
- Libellés de glossaire trop longs ou fléchis à l'intérieur des crochets.
- Mots polysémiques pris dans le mauvais sens : Némésis, bank runs, offshore, relance.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| course_166_narcisse_et_echo/s3.b0.text | haklı öcün tanrıçası [[Düşman]] adına yakarır | prie au nom de « l'Ennemi », déesse de la juste vengeance | haklı öcün tanrıçası [[Nemesis]]'e yakarır | bloquant |
| course_18_la_grande_depression_1929/s2.b0.text | Sonra [[banka işlemleri]] gelir | Puis viennent les opérations bancaires | Sonra [[banka hücumları]] gelir | bloquant |
| course_212_les_paradis_fiscaux_expliques/s1.b0.text | buna [[açık deniz]] ekonomisi denir | on appelle cela l'économie de haute mer | buna [[offshore]] ekonomi denir | bloquant |
| course_166_narcisse_et_echo/s1.b0.text | kıskanç karı **Hera**'yı | la « bonne femme » jalouse Héra (registre vulgaire) | kıskanç eşi **Hera**'yı | bloquant |
| offer.expiresIn | Süresi doluyor | « Est en train d'expirer » | Kalan süre | majeur |
| paywall.error.unavailable | Ödeme duvarı yüklenemiyor | Le mur de paiement ne peut pas être chargé | Teklif yüklenemedi | majeur |
| cours : motif systématique | 25% | convention française ; le turc écrit %25 | %25 | majeur |


### Groupe A — éditions principales

### Anglais (`en`) — groupe A, avec guide de traduction

**Score global : 3.5/5** (UI 4.0, cours 4.0, quiz/glossaire 3.0, catalogue –, App Store –). Action : **Corrections ciblées**. Effort estimé : UI : 1 jour (34 correctifs listés + passes regex culture / parcours / UK-US / -70% / 1h / @ / LVL.) ; cours : 1–2 jours de passes ciblées (libellés de glossaire à corriger à la source, calques et faux amis listés, capitalisation, présent historique) sans relecture intégrale ; quiz, glossaires et descriptions de collections de 1re génération : 2 jours de relecture native complète ; catalogue (titres/descriptions de cours) et page App Store : non échantillonnés, prévoir 0,5 jour de contrôle natif.

Le reproche « les traductions ne sont pas naturelles » n'est que partiellement fondé pour l'anglais : les trois échantillons (93 relevés UI, 44 cours, 68 quiz/glossaire/collections, soit 1 bloquant et 70 majeurs) montrent un texte édité, souvent de niveau natif, et non une traduction automatique brute — les onglets, les boutons, le tutoiement chaleureux et la plupart des paragraphes de cours passent sans retouche. Ce qui domine, de loin, ce sont les calques (38 à 55 % des relevés selon l'échantillon) : expressions figurées traduites mot à mot (« Come discover », « effort on oneself », « had no tongue left », « X, on the contrary, grants »), le faux ami « culture/cultured » martelé sur le paywall et le partage, puis l'instabilité terminologique (« Parcours » rendu path/journey/route, Pro/PRO/Premium, Umma/Ummah, Hijra/Hegira) et un mélange UK/US dans une édition annoncée US (revise, tick, personalised, lecturers). Les vrais contresens sont rares mais embarrassants et placés sur des écrans fréquentés : la rubrique « Anglo-Saxons & world literature » (seul bloquant), « Cancel anytime in 15 seconds » dans l'essai gratuit, les deux phrases du bloqueur TikTok, « soul brother » dans un quiz, et un fait inventé (Baudelaire aurait importé « spleen » en français). La surface la plus faible est celle des quiz/glossaire/collections (3/5) : les descriptions de collections de première génération cumulent majuscules françaises et calques (« the seventh art », « the living », « the World War »), et le glossaire du cours sur l'impressionnisme est du mot à mot avec des crochets résiduels, alors que les collections récentes sont natives, ce qui rend l'inégalité très visible. L'UI (4/5) et les cours (4/5) tiennent bien, avec des problèmes concentrés sur l'onboarding et le paywall pour l'UI (41 des 93 relevés), et sur des artefacts de pipeline pour les cours (libellés de glossaire étendus insérés tels quels dans la prose). Le catalogue (titres/descriptions de cours) et la page App Store n'ont pas été échantillonnés ; le seul titre de cours relevé (« How was Impressionism born against the Salon? ») laisse penser qu'un contrôle rapide des titres s'impose. Au total : un texte édité de bon niveau, à corriger de façon ciblée, avec une relecture native complète limitée aux glossaires et aux descriptions de collections anciennes.

Surfaces relues (score du relecteur) : UI (4.0), Cours (4.0), Quiz, glossaire, collections (3.0). Constats relevés : 205 (1 bloquants, 70 majeurs, 134 mineurs).

Motifs récurrents :

- Calques d'expressions et de tournures françaises traduites mot à mot — catégorie n° 1 dans les trois échantillons (38 à 55 % des relevés) : « Come discover » (Viens découvrir), « learn with method », « effort on oneself », « had no tongue left », « pushed X to » (pousser à), « in the service of ». Artefacts MT à traiter en corpus : « au contraire » → « X, on the contrary, verb » inséré entre sujet et verbe (quiz), « entre X et Y » → « between X and Y » (collections), « pour + infinitif » → « for: » + impératifs (paywall).
- Faux ami « culture / cultivé » → « culture / cultured » (paywall, partage, onboarding) : à remplacer en corpus par knowledge / learning / smarter (regex \b(cultured|of culture|into culture)\b).
- Terminologie produit instable : « Parcours » = path / journey / route / learning paths ; abonnement = Sophia Pro / Sophia PRO / Premium / premium ; goal / objective ; en contenu Umma/Ummah, Hijra/Hegira, Sassanid/Sasanian, expansion/enlargement/extension. Fixer un glossaire produit et l'appliquer en corpus.
- Mélange anglais britannique / américain dans une édition déclarée US : personalised, revise/revising, tick, lecturers, term, well played (UI), fire brigade, won through (cours), Theatre, Shakespearian (collections). Passe regex corpus-wide.
- Majuscules françaises héritées sur des noms communs en milieu de phrase (Music, Art, History, World, Memory, Politics) dans les descriptions de collections, capitalisation incohérente des périodes et titres dans les cours (antiquity, central Europe, Persian empire, secretary general), title case vs sentence case pour boutons et libellés de section. Artefact MT (majuscules des titres FR recopiées) à corriger en corpus.
- Artefacts de pipeline glossaire : libellés d'entrées étendus ou avec article majuscule insérés tels quels dans la prose (« [[Symbolism and Baudelaire's legacy]] », « founded [[The Ummah]] », « [[paint tubes and plein air]] work »), crochets [ ] résiduels autour des titres d'œuvres ([Les Nymphéas]), titres français non remplacés par le titre anglais établi (Water Lilies, Rouen Cathedral). À corriger à la source (génération des libellés), pas texte par texte.
- Conventions numériques et typographiques françaises conservées : « 1h », « %d h », « -70% », « LVL. », « D3 », fourchettes « €30-100 / month », trois points « ... », tiret « - » entouré d'espaces, guillemets droits et typographiques mélangés. Passe regex corpus-wide.
- Présent historique français conservé dans les explications de quiz et mélangé au prétérit dans le même cours (grants / links / summarizes vs died / published) ; l'anglais narratif attend le passé.
- « @ » employé comme nom commun (« your @ », « this @ », « get an @ ») dans toute la section amis ; l'anglais dit « username » ou « @handle ».
- Jargon produit interne exposé à l'utilisateur (« paywall », « onboarding », « Open source » pour ouvrir la source) et formulations de rapport d'entreprise (« boosts goal achievement by 89% », « Your profile has been created successfully ») qui cassent la voix chaleureuse et tutoyante.
- Faux amis et sens inadaptés de mots polysémiques dans cours et glossaire : cult (culte), rehabilitation (réhabilitation), blunt (franc), chromatic circle (color wheel), clear touch (touche limpide), anecdotes (faits amusants), the living (le vivant), seventh art (cinéma), manifestations (phénomènes).
- Témoignages avec prénoms français et âges (Léa, 24 ; Inès ; Yanis ; Malik) combinés à « on the App Store » : crédibilité affaiblie pour un public américain — décision produit plutôt que problème de traduction.
- Légendes d'images sans point final en anglais alors que le français en a un : à confirmer comme choix de style délibéré et à appliquer partout.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| Libellés de sous-catégories (content) — rubrique « Anglo-sa… | Anglo-Saxons & world literature | « Les Anglo-Saxons (peuples germaniques de l'Angleterre médiévale) & littérature mondiale » — un anglophone n… | English-language & world literature | bloquant |
| paywall.quiz.review3.quote, paywall.reviews.r3.quote, paywa… | I feel more cultured every week. The quizzes anchor everything. / Finally an app that turns scrolling into cu… | « Je me sens plus raffiné / mondain chaque semaine » ; « transforme le scroll en culture (arts, coutumes) » ;… | I feel smarter every week. The quizzes make everything stick. / Finally an app that turns scrolling into lear… | majeur |
| tab.path, explain.path.title, path.title (« path ») vs coll… | Your journey / JOURNEY / Struggling to know what to learn? Sophia builds you a **personalized route** that yo… | « Ton voyage / périple », « itinéraire routier personnalisé », « ton chemin » : l'utilisateur ne sait pas que… | Your path / PATH / Path complete / Not sure what to learn? Sophia builds you a **personalized path** to follo… | majeur |
| onboardingV2.trial.step2.detail (étape de l'essai gratuit, … | We'll remind you via notification. Cancel anytime in 15 seconds. | « On te le rappellera par notification. Annule à tout moment dans les 15 secondes » — comme si on n'avait que… | We'll send you a notification. Cancelling takes 15 seconds. | majeur |
| paywall.weaponHeadline + puces du paywall (Build your confi… | Sophia, your secret weapon for: — Build your confidence / Feed your curiosity | « Sophia, ton arme secrète pour : — Construis ta confiance » : le « pour + infinitif » français ne se calque … | Sophia, your secret weapon to: — Build your confidence / Feed your curiosity (keep the bullets as verbs) | majeur |
| onboardingV2.exams.quote2 et quote4, tiktokBlocker.app.none… | "I revise 10 minutes a day and my grades really took off." / No app chosen yet. Tick TikTok in Apple's list. … | Pour un Américain, « I revise 10 minutes a day » = « je corrige mon texte 10 minutes par jour » (pas « je rév… | "I study 10 minutes a day and my grades really took off." / No app selected yet. Check TikTok in Apple's list… | majeur |
| offer.discount, offer.unlock | -70% FOREVER / Unlock my -70% offer | « -70 % POUR TOUJOURS » : en anglais le signe moins devant un pourcentage n'est pas une convention commercial… | 70% OFF FOREVER / Claim my 70% off | majeur |
| tiktokBlocker.how.step3, tiktokBlocker.notifications.subtit… | TikTok is unlocked until tomorrow. Then again, every day. / The “Open Sophia” button on the lock screen goes … | « TikTok est débloqué jusqu'à demain. Cela dit / d'un autre côté, chaque jour. » (phrase sans sens) ; « lock … | TikTok is unlocked until tomorrow. And it starts over every day. / The “Open Sophia” button on the blocking s… | majeur |
| collections c_vblwguvnamcf, c_7etcora6amcf, c_nuv73pnuamcf,… | Why does Music move us? An exploration between Art and biology. / History of the seventh art / …our understan… | Majuscules sur Music, Art, Memory, World héritées des titres français ; « septième art » inconnu des anglopho… | Why does music move us? Where art meets biology. / A History of Cinema / …our understanding of life. / Turnin… | majeur |
| course_100_les_fleurs_du_mal_baudelaire_q9 / question (quiz) | Which American writer, described as a “soul brother”, did Baudelaire translate? | « Soul brother » = « frère de couleur / pote noir » dans l'argot afro-américain des années 60-70, pas « âme s… | Which American writer, whom he called a “kindred spirit,” did Baudelaire translate? | majeur |

### Espagnol (`es`) — groupe A, avec guide de traduction

**Score global : 4.0/5** (UI 4.0, cours 4.0, quiz/glossaire –, catalogue –, App Store –). Action : **Corrections ciblées**. Effort estimé : UI : 0,5 jour (variantes, terminologie) ; cours : corrections ponctuelles, 1 jour.

La plainte n'est pas vraiment justifiée pour l'espagnol : l'UI et les cours sont fluides, souvent bien localisés (« sobremesa », « enhorabuena »), tutoiement et placeholders respectés. Ce qu'un utilisateur espagnol remarque, c'est un mélange de variantes régionales incompatible avec la cible es-ES : prétérit simple à la latino-américaine (« Subiste de nivel », « Ya usaste »), lexique d'Amérique (costo, postularse, en promedio, teléfono au lieu de móvil), et une terminologie produit instable (parcours = recorrido / ruta / viaje / camino / itinerario ; quizzes / quiz). Dans les cours, quelques fautes réelles (« desde medio del Sena »), des contresens isolés (« terror » pour angoisse, « llave » pour clé, « alejandrino de 12 sílabas ») et des calques récurrents (« se vuelve » + nom, « cuenta como », ponctuation américaine dans les guillemets).

Surfaces relues (score du relecteur) : UI (4.0), Cours (4.0). Constats relevés : 167 (0 bloquants, 46 majeurs, 121 mineurs), plus 6 vus mais non listés.

Motifs récurrents :

- Variantes latino-américaines (prétérit, lexique) dans une édition es-ES.
- Terminologie « parcours » instable (cinq mots) ; pluriel de quiz instable.
- Ponctuation anglo-américaine à l'intérieur des guillemets ; guillemets français avec espaces dans certains témoignages.
- Calques : « se vuelve » + nom, « contar como », « Voici comment… » rendu au passé.

| Où | Texte actuel | Ce que ça dit | Proposition | Gravité |
|---|---|---|---|---|
| UI : Subiste de nivel, Ya usaste, sin costo, postularse, en… | Subiste de nivel | prétérit simple ; l'Espagne dit « Has subido de nivel » | Has subido de nivel | majeur |
| onboarding.dailyGoal.perDay | %@ al día! | « %@ par jour ! » sans ¡ | ¡%@ al día! | majeur |
| onboarding.premiumTrial.cta | Empieza mi prueba | « Commence (toi) mon essai » | Empezar mi prueba | majeur |
| paywall.quiz.review3.quote | Me siento más culto cada semana. | cultivé (masculin) pour Inès | Me siento más culta cada semana. | majeur |
| course_100_les_fleurs_du_mal_baudelaire/s3.b2.text | el **alejandrino**, un verso de 12 sílabas | l'alexandrin espagnol a 14 syllabes | el **alejandrino**, un verso de 14 sílabas (12 en francés) | majeur |


### Langues non échantillonnées dans cette passe

Pas de relecteur natif faute de quota ; seuls les indicateurs mécaniques sont disponibles. À échantillonner selon la même méthode (P2 et P3 du plan).

| Langue | Groupe | « on » → « nous » (/168) | Validateur | Chaînes UI identiques à l'anglais | Observation |
|---|---|---|---|---|---|
| Tchèque (`cs`) | B | 13 | 1 | 4 | 13 segments « on » → « nous » restent dans les cours ; « V 1492 » sans « roce » dans 117 phrases sur 244. |
| Grec (`el`) | B | 0 | 44 | 0 | 44 constats au validateur mécanique (termes de glossaire perdus), le plus haut des langues avec guide. |
| Hongrois (`hu`) | B | 0 | 1 | 0 |  |
| Néerlandais (`nl`) | B | 13 | 0 | 10 | 13 segments « on » → « we » restent dans les cours. |
| Polonais (`pl`) | B | 0 | 1 | 3 |  |
| Roumain (`ro`) | B | 0 | 0 | 3 | Clé sentinelle : « Fin de l'essai » est rendu `Procesul se termină` (« le procès se termine »), même contresens que l'hébreu ; la fiche App Store mélange « vă » et « ești » dans le même paragraphe. |
| Suédois (`sv`) | B | 26 | 1 | 6 | 26 segments « on » → « vi » restent dans les cours. |
| Allemand (`de`) | A | 5 | 2 | 3 | 2 constats au validateur ; 5 segments « on » → « wir ». |
| Italien (`it`) | A | 0 | 0 | 8 |  |
| Portugais (Brésil) (`pt`) | A | 0 | 0 | 3 |  |
| Portugais (Portugal) (`pt-PT`) | A | 0 | 0 | 4 |  |


## 6. Plan d'action recommandé

**P0, cette semaine, par liste (une journée par langue au plus).**

- Corriger les contresens d'interface bloquants listés dans la section 5 et dans `docs/audit-traductions/<langue>.json` : hébreu, arabe, estonien, finnois (essai / procès, léger / lumière, Premium, mensuel, gratuit), slovaque (« Lancer l'examen », « ta conscience »), croate (« Nema veze »), roumain (« Procesul se termină »), turc (« Ödeme duvarı », « Süresi doluyor »), bulgare (« Възраждане », « културен »).
- Fixer une table de terminologie produit par langue (quiz, cours, parcours, collection, niveau, série, essai gratuit, Premium, Sophia non translittérée) et l'appliquer par script sur les 1 066 clés, comme l'a fait `naturalness_ui_v2.py` pour quinze langues.
- Remettre le nom et le sous-titre de la fiche App Store hébraïque en hébreu.
- Corriger par script, sur tout le corpus, les motifs purement mécaniques : « V / U <année> » sans « roku / godine / году / Leta » (slovaque, tchèque, croate, serbe, slovène, russe), « <année>:ssa » et « Teoksessa <année> » en finnois, « Filmis / Linnas / Raamatus <année> » en estonien, « Hegira » des leçons aligné sur les quiz, % avant le nombre en turc, siècles en chiffres romains en bulgare, guillemets de chaque langue.

**P1, deux à quatre semaines : relecture native complète des contenus des onze langues sans guide.** Ordre proposé, par gravité et par ce que l'utilisateur rencontre en premier : hébreu, estonien, arabe, finnois, russe, slovène, slovaque, croate, serbe, danois, norvégien. Pour chacune : écrire le `TRANSLATION_GUIDE_<LANGUE>.md` sur le modèle bulgare, relire catalogue puis onboarding et paywall puis cours 1 à 240 (les cours 241 à 311, plus récents, sont déjà d'un niveau natif dans toutes les langues échantillonnées), quiz et glossaire, et passer `check_course_translation.py --lang <code>` comme porte de sortie. Le « on » rendu par « nous » (168 segments par langue) demande un relecteur : la tournure impersonnelle correcte dépend de la phrase.

**P2 : langues avec guide.** Appliquer les corrections ciblées du bulgare et du turc, puis échantillonner de la même manière polonais, roumain, néerlandais, tchèque, hongrois, grec et suédois, qui n'ont pas été relus dans cette passe (le grec remonte 44 constats au validateur, le tchèque, le néerlandais et le suédois gardent 13 à 26 « nous »).

**P3 : éditions principales.** Espagnol : variantes d'Espagne (passé composé, móvil, coste, solicitar), terminologie « parcours ». Anglais : « cultured » / « culture », formes britanniques dans une table américaine, « @ » pour pseudo.

**Processus.** Ne plus livrer de traduction automatique brute dans une langue : au minimum une post-édition cadrée par un guide, le validateur, et une relecture native de l'onboarding, du paywall et du catalogue avant mise en ligne.

## 7. Méthode et limites

- **Échantillons par langue** (fichiers construits à partir du dépôt) : toutes les chaînes d'interface avec le français et l'anglais en regard ; 5 à 15 cours alignés segment par segment sur le français (les mêmes cours dans toutes les langues, plus cinq cours tirés au sort par langue pour l'hébreu et l'estonien) ; les quiz de 3 cours ; le glossaire de 3 cours ; les 40 collections ; les 22 libellés de rubriques ; le catalogue complet ; la fiche App Store.
- **Relecture** : un relecteur natif (modèle de langue) par langue et par surface, chargé de ne relever que ce qu'un utilisateur natif remarquerait, avec une glose française de ce que dit réellement le texte et une proposition de correction ; listes plafonnées à 50 ou 60 constats par échantillon, le relecteur indiquant combien d'autres il a vus. Une contre-vérification par un second relecteur était prévue ; elle n'a pas pu être exécutée (limite d'usage de la session atteinte à trois reprises). En remplacement, chaque constat bloquant cité dans ce rapport a été vérifié un par un dans les fichiers sources, et les motifs systématiques ont été comptés sur les 309 cours de chaque langue.
- **Couverture** : complète (interface, cours, quiz et glossaire, catalogue, store) pour l'hébreu et l'estonien ; interface et cours pour l'arabe, le finnois, le russe, le slovaque, le croate, le serbe, le slovène, le danois et le norvégien ; interface et cours pour le bulgare, le turc, l'espagnol ; interface, cours et quiz pour l'anglais. Non échantillonnés dans cette passe : allemand, portugais (deux éditions), italien, polonais, roumain, néerlandais, tchèque, hongrois, grec, suédois ; pour eux, seuls les indicateurs mécaniques de la section 4 sont disponibles.
- **Scores** : 5 = indiscernable d'un texte écrit dans la langue ; 4 = bon, quelques aspérités ; 3 = compréhensible mais visiblement traduit ; 2 = erreurs fréquentes ; 1 = inutilisable. Le score global pondère ce que l'utilisateur rencontre en premier (interface, catalogue) puis les cours.
- **Fichiers** : `docs/audit-traductions/<langue>.json` (constats, gravité, texte actuel, glose française, correction proposée, motifs récurrents, scores des relecteurs) ; les échantillons et scripts de construction sont dans l'espace de travail de la session, pas dans le dépôt.
