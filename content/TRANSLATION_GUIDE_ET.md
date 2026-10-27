# Kursuste tõlkimine: prantsuse keelest eesti keelde

Prantsuse tekst (`content/courses/fr/`) on allikas. See dokument on
`content/courses/et/` spetsifikatsioon. See antakse tervikuna sellele,
kes tõlke kirjutab, ja `scripts/check_course_translation.py --lang et`
kontrollib seda masinlikult. Samad reeglid kehtivad rakenduse liidese,
viktoriinide, sõnastiku ja kataloogi (`courses.et.json`,
`collections.et.json`) kohta. Kõik „vale → õige“ näited on pärit
praeguse eesti teksti auditist (`docs/audit-traductions/et.json`).

## 1. Mida me tahame

Me ei anna üle tõlget. Anname üle kursuse **eestikeelse väljaande**:
teksti, mille emakeelne toimetaja oleks samadest märkmetest kirjutanud.
Lugeja ei tohi aru saada, et algtekst oli prantsuse keeles.

Selles järjekorras:

1. **Õige.** Ära moonuta, ära mõtle välja ega jäta fakte välja.
   Kuupäev kontrolli üle: `**18. juuli 1815. a**` → `**18. juunil 1815**`.
2. **Ladus.** Loomulik eesti keel, mis valjusti loetuna ei komista.
3. **Lihtne.** Lühikesed laused, igapäevased sõnad. Uudishimulik
   teismeline peab järge pidama. Pigem „näitas“ kui „demonstreeris“.
4. **Vormitruu.** Umbes sama arv lauseid, sama mõttekäik, pikkus
   kahekümne protsendi piires, et paigutus rakenduses püsiks.

**Pöördumine on alati sina**, ainsuses ja soojalt. Ei kunagi `teie`,
`te`, `teil` ega mitmuse käsku `-ge`/`-ke`. Nupul on `oma`, mitte
`minu` (`minu` tähendaks rääkijat):

> Vale: `Tutvuge jumalate ja kangelastega` · `TEIE PROFIIL` ·
> `Kui palju aega veedate telefonis?` · `Vaata minu profiili`
>
> Õige: `Tutvu jumalate ja kangelastega` · `SINU PROFIIL` ·
> `Kui palju aega veedad telefonis?` · `Vaata oma profiili`

Eesmärkide valikus jääb prantsuse infinitiiv da-infinitiiviks:
`Impressionner mon entourage` → `Jätta lähedastele muljet`, mitte
`Jäta muljet ümbritsevatele inimestele`.

**Prantsuse umbisikuline „on“ ei ole kunagi „me“ ega „nad“.** Kasuta
umbisikulist tegumoodi (`-takse`, `-ti`). Sama kehtib üldise „vous“
kohta. Päris „nous“ (`notre façon de regarder`) võib jääda `me`.

> Vale: `Me tahame teda tappa.` · `Me elame seal hõimudena.` ·
> `Nad ütlevad, et andmed on uus õli.` · `kui te seda paksendate`
>
> Õige: `Teda tahetakse tappa.` · `Seal elatakse hõimudena.` ·
> `Öeldakse, et andmed on uus nafta.` · `kui seda paksemaks tehakse`

**Sugu.** Eesti keeles grammatilist sugu ei ole: `ta` on nii mees kui
naine ja omadussõna ei ühildu. Kasutaja kohta pole seega kahte vormi
vaja; vali sõnad, mis sobivad igaühele (`õpilane`, `sõber`, mitte
`sõbranna`). Kui prantsuse „il/elle“ eristab tegelasi, korda nime:
`Ta vastab: „Keegi!“` → `Echo vastab: „Keegi!“`. Naissoost tunnistuste
autorid jäävad naiseks oma nime kaudu (`Inès, 12. klass`, `Léa, 17`);
nimesid ära eestista (`Saara, 26` → `Sarah, 26`). Naissoost nimisõna
ainult siis, kui see on tavaline: `kuninganna Guinevere`,
`kättemaksujumalanna Nemesis`, `nümf Echo`; ametinimetus jääb
neutraalseks (`teadlane`, `kirjanik`).

**Aeg.** Järgi prantsuse teksti. Ajalooline olevik (`Aastal 1874
korraldavad nad näituse`) on eesti keeles loomulik. Ühe lõigu sees
ära vaheta: `võtab vastu … Ta koostas … ja asutas` on viga.

**Kalgid.** `Siin on, kuidas see kõik algas.` → `Nii see kõik algas.`
`Muhamedi poolt asutatud umma` → `Muhamedi asutatud umma`.
`Alates gravitatsioonist kuni DNA-ni` → `Gravitatsioonist DNA-ni`.
`Mõistmine, kuidas nafta …` → `Kuidas nafta …`. Asja kohta `see`/`need`,
mitte `ta`/`nad`: `Laienemine ei ole ainult sõjaline. Ta on ka …` →
`See on ka …`. `moderne` on `moodne`/`tänapäevane`, mitte `kaasaegne`.

**Petlikud sõnad.** Mitmetähenduslik sõna tõlgi lause järgi, mitte
inglise keele sagedasema tähenduse järgi:

| Prantsuse (tähendus) | Eesti | Mitte |
| --- | --- | --- |
| Léger / Modéré / Intense; la lumière | Kerge / Mõõdukas / Intensiivne; valgus | `Valgus` (kerge kohta) |
| Expire dans; Gratuit | `Lõpeb 02:59:59`; Tasuta | `Aegub aastal`; vaba |
| Mensuel / Annuel | Igakuine / Iga-aastane, `arveldatakse kord aastas` | ajakiri, `Lisatasu` |
| culture générale, cultivé | üldteadmised, laia silmaringiga, haritud | kultuur, kultuurne |
| anecdotes; Terminale; trimestre | põnevad faktid; 12. klass; veerand | anekdoodid; vanem kursus; ametiaeg |
| Pas de connexion | Ühendus puudub | |
| la personne la plus intéressante de la pièce | seltskonna kõige huvitavam inimene | ruumi |
| Reprends du temps pour toi; Glisse pour découvrir | Võta oma aeg tagasi; Libista, et avastada | |
| spleen; flâneur | spliin; flanöör | põrn; jalutuskäru, vanker |
| caravane | karavan, kaubakaravan | haagissuvila |
| condamnation; beau-père (Aupick) | süüdimõistmine, kohtuotsus; kasuisa | veendumus; äi |
| deux états (d'âme) | kaks hingeseisundit | kaks riiki |
| gravité; failles; pétrole | gravitatsioon; murrangud, lõhed; nafta | tõsidus; vead, luumurrud; õli |
| cellulaire; plaques (photo) | raku-, rakuline; fotoplaadid | mobiil-; taldrikud |
| hommes (10 000); poèmes; ans | meest; luuletust; aastat, `-aastaselt` | dollarit; luuletajat |
| berger; marine (maal) | karjus; merevaade | lambakoer; merevägi |
| Grande Dépression; soupe populaire | suur depressioon; supiköök | närvivapustus |
| bank runs; relance | pangajooksud; majanduse elavdamine | pank jookseb; tervenemine |
| offshore, paradis fiscal | offshore-majandus, maksuparadiis | avamerel |
| chute; sensation; touche | kukkumine, langus; aisting; klahv, pintslitöö | sügis; sensatsioon; nupp |
| réhabilitation; juger (Socrate) | rehabiliteerimine; kohut mõistma | taastusravi; üle proovima |
| tribut; nordique; État; peuples | andam; Põhjala; riik; rahvad | austusavaldus; Norra; osariik; inimesed |
| puissant; réel; clé de lecture | võimas, tõhus; tõeline; tõlgendusvõti | |

## 2. Skelett jääb

Tõlgitakse ainult tekstivälju. Ülejäänu kopeerib tööriist prantsuse
skeletist ja sa ei puutu seda: `id`, `subject`, `subcategory`, `type`,
`asset`, `image`, `ratio`, `free`.

| Väli | Mis see on | Märkus |
| --- | --- | --- |
| `title` | Kaardi ja päise pealkiri | Lühike. Teose kohta eesti väljaande pealkiri. |
| `subtitle` | Rida pealkirja all | Aasta või vahemik (`1945`, `1945-1975`) jääb. |
| `description` | Kahelauseline tutvustus | Peab üksi seisma. |
| `hero.hook` | Üks meelitav lause | Reklaam, mitte proosa. |
| `sections[].title` | Osa pealkiri | Nimisõnafraas, lõpus punkti pole. |
| `paragraph.text` | Sidus tekst | Põhitöö. |
| `image.caption` | Pildiallkiri | Lühike; punkt ainult täislause järel. |
| `funFact.text` | Kast | Kerge, jutukas. |
| `takeaway.text` | Kokkuvõte | See, mis peab meelde jääma. |
| `quote.text` | Tsitaat | Vt §6. |
| `quote.attribution` | Kes ütles | Vt §6. |
| `timeline.events[].date` | `1789`, `juuni 1940`, `umbes 450 eKr` | Numbrid jäävad. Kuud tõlgi väikese tähega. `eKr`, mitte `av. J.-C.`. |
| `timeline.events[].title` | Silt | Väga lühike, punktita. |
| `timeline.events[].detail` | Üks lause | |

Pealkirjad on lausekirjas: suur on ainult esimene täht ja pärisnimed
(`genotsiidid ja mälu` → `Genotsiidid ja mälu: mitte kunagi enam`).

**Tootesõnavara** on kogu rakenduses üks ja sama:

| Prantsuse | Eesti | Mitte |
| --- | --- | --- |
| quiz | viktoriin (`5 viktoriini`) | kviis, küsimustik, mälumäng |
| cours | kursus (`3 kursust läbitud`) | tund, õppetund, loeng |
| parcours | teekond (`TEEKOND`) | reis, rada, õppetee |
| collection | kogumik | kollektsioon |
| niveau, NIV. 3 | tase, `TASE 3` | aste, nivoo |
| série (streak) | seeria, päevade seeria | sari, triip |
| essai gratuit | tasuta prooviperiood (`Alusta prooviperioodi`, `Prooviperiood lõpeb`) | kohtuprotsess, katseaeg, prooviversioon |
| Premium | Premium (`Premiumi`, `Premiumiga`, `Premium-funktsioonid`) | preemia, lisatasu, `Premium funktsioonid` |
| Sophia | Sophia (`Sophiat`, `Sophiaga`) | `Sophia'ga` |
| bloqueur TikTok | TikToki blokeerija | blocker, `blockerit` |
| Entraînement | Harjutamine (`lisanduvad sinu Harjutamisse`) | praktika, treening |
| réviser, révision | kordama, kordamine (`Korda`, `kui seda ei korrata`) | üle vaatama, revideerima |
| objectif; ami | eesmärk; sõber | objektiiv, sihtmärk; semu, kaaslane |
| matière / sujet | aine (`3 ainet, mida avada`) / teema | objekt |
| abonnement | tellimus, kuutellimus, aastatellimus | abonement, liikmesus |
| débloquer | Ava (`Ava Premiumiga`) | lukust lahti, vabastama |
| glossaire; XP | sõnastik; XP | sõnaraamat, glossaar; kogemuspunktid |
| Bibliothèque; Accueil | Raamatukogu; Avaleht | Teek, Biblio; Kodu |
| l'offre (paywall) | pakkumine (`Pakkumist ei saa laadida`) | paywall |
| terminé | läbitud | valmis, tehtud, lõpetatud, täielik |
| notification; audio | märguanne; audiokursus | teavitus, teade; heli, helid |
| progression; ambassadeur | edenemine; saadik | edusammud kõrvuti; suursaadik |
| Vrai / Faux | Tõsi / Vale (küsimus: `Õige või vale?`) | Tõene / Väär |

## 3. Märgised reas

Kolm märgist peavad säilima:

- `**paks kiri**`: kuupäevad, arvud, nimed ja teosed, millest lõik räägib.
- `*kaldkiri*`: teose pealkiri proosas.
- `[[termin]]`: sõnastiku kirje. Puudutus avab definitsiooni.

Reeglid:

- Märgised käivad paarikaupa. Paaritu arv `**` on viga.
- Ükski märgis ei neela tühikut ega kirjavahemärki: `**1945**,` on õige,
  `**1945,**` ja `** 1945 **` on valed. Järgarvu punkt jääb välja:
  `**1857**. aastal`, mitte `**1857.** aastal`.
- Paks kiri märgib eesti vastet, mitte samu märke. Prantsuse
  `**30 000 mots**` on `**30 000 sõna**`.
- Ära lisa paksu kirja, mida prantsuse tekstis pole. Ära tee paksuks
  tervet lauset.

## 4. Sõnastiku kirjed: kõige tähtsam reegel

Iga prantsuse `[[...]]` annab täpselt ühe eesti `[[...]]`,
**lauses, mõttekäigu samas kohas**.

Ära kunagi pargi terminit lõigu lõppu. Ära jäta auku. See on üks ja
sama viga:

> Vale: `nõrgestas eelkõige : kristlikud ristisõdijad rüüstasid linna.
> [[Konstantinoopoli vallutamine]]`
>
> Õige: `Linna nõrgestas eelkõige [[Konstantinoopoli vallutamine
> neljanda ristiretke ajal (1204)]], kui lääne ristisõdijad linna
> rüüstasid.`

Termini tekst ei ole vaba. See peab olema selle kursuse võti failis
`ios/Sophia/Resources/Locales/glossary.et.json`. Tundmatu võti jääb
surnud tekstiks. `scripts/make_translation_briefs.py` lühikirjeldus
loetleb lubatud võtmed; kasuta ühte täht-tähelt, suurtähtedega
nagu registris. Ära vaheta kirjet teise vastu: `[[Suured andmed]]`
prantsuse „prix de transfert“ asemel on viga, õige on `[[siirdehind]]`.
Kui registreeritud võti ise rikub §5 reegleid (`Ummah`, `razzias`,
`Džihaad`, `Beduiinid`), paranda see `glossary.et.json`-is kogu
kursuse jaoks korraga, mitte ainult ühes lõigus.

Lause peab olema grammatiline **koos sisestatud terminiga**:

- Võti on nimetavas. Ära liida midagi `]]` taha: `[[džihaad]]i`,
  `[[kaliif]]-dele`, `[[laissez-faire]]'ile` on valed.
- Ehita lause nii, et termini koht nõuab nimetavat: alus
  (`Siis tulevad [[pangajooksud]]: …`), öeldistäide
  (`Peamine tööriist on [[siirdehind]]`) või loetelu kooloni järel.
- Kaassõna või täiendina vajaks termin omastavat; seal ehita ümber:

> Vale: `Kuid rühm katsetab ka tänu [[Jaapani trükised]]: …`
>
> Õige: `Rühma mõjutavad ka [[Jaapani puulõiked]]: asümmeetriline
> kadreering ja ühtlased värvipinnad.`
>
> Vale: `Islami tsivilisatsioonist sai ka [[Džihaad]] ideaal, …`
>
> Õige: `Islami tsivilisatsiooni kannab ka [[džihaad]]: ühtaegu
> pingutus iseenda kallal ja kogukonna kaitse.`
>
> Vale: `**Franklin D. Roosevelt** toob turule [[Roosevelti uus tehing (1933)]].`
>
> Õige: `**1932**. aastal valitakse presidendiks **Franklin D.
> Roosevelt** ja algab [[Roosevelti New Deal (1933)]].`

- `[[Varssavi pakt]] riigid` ei sobi. Parem: `Idabloki riike ühendab
  [[Varssavi pakt]].` Samuti `Teise maailmasõja ajal` asemel:
  `kui käis **[[Teine maailmasõda]]**`.
- Kui võti ei sobi, ehita lause ümber. Võtit lauses ei muuda.

## 5. Pärisnimed

Masintõlge loeb perekonnanimesid tavasõnadena. Kindlad reeglid:

**Isiku- ja perekonnanime ei tõlgita.** Degas jääb Degas'ks, Munch
jääb Munchiks (mitte „närima“), Corneille jääb Corneille'iks.

**Käändelõpp liitub nimele otse**, kui nimi hääldub nagu kirjutatakse:
`Aupickiga`, `Zeusil`, `Badri lahing`, `Nadari ateljees`. Kui kirjapilt
ja hääldus erinevad, tuleb sirge ülakoma: `Baudelaire'i`,
`Shakespeare'i`, `Monet'd`, `Degas'd`, `Seurat'ga`, `Poe'd`,
`Globe'i teatrile`. Sidekriips ainult lühendi järel: `NATO-l`, `ÜRO-s`,
`DNA-ni`. Vale: `Aupick-ga`, `Zeus-l`, `Badr-l`. Ka lisand käändub:
`**Bauhaus** kool` → `Bauhausi kool`; `Edgar Poe, keda` → `Edgar Poe'd,
keda` (sihitis).

**Kinnistunud eesti kuju**, kui see on olemas, ja ühtmoodi kogu kursuses:
`Christophe Colomb` → `Kolumbus`, `Londres` → `London`, `Pékin` →
`Peking`, `Aix-la-Chapelle` → `Aachen`, `Charlemagne` → `Karl Suur`,
`Michel-Ange` → `Michelangelo`, `Saint-Pétersbourg` → `Peterburi`
(mitte `Saint-Peterburi`), `Ulysse` → `Odysseus`, `ONU`, `OTAN` →
`ÜRO`, `NATO`, `Byzance` → `Bütsants`, `Sassanides` → `Sassaniidid`,
`roi Arthur` → `kuningas Arthur`, `Siège périlleux` → `Ohtlik Iste`.

**Kreeka müüdid kreekapärases kujus**, mitte ladina või inglise:
Narkissos (`Narkissose`), Echo (lill on `nartsiss`, nähtus `kaja`),
Daidalos, Ikaros, Sisyphos, Tantalos, Iason, Medeia, Polyphemos,
Kronos, Patroklos, Hektor, Hesiodos, Olümpos, Teiresias, jumal Paan.
Vene nimed eesti translitereeringus: Fjodor Dostojevski, Pulheria,
Dunja, Sonja Marmeladova, Porfiri Petrovitš, Semjonovski väljak.

**Islam ja araabia sõnad** (kursus 1): `Muhamed` (`Muhamedi`), `Meka`,
`Mediina` (`Mediinasse`, `Mediina põhiseadus`), `hidžra` väikese tähega
(`hidžrat`, `pärast hidžrat`), `umma`, `kaliif`, `džizja`, `dhimma`,
`džihaad`, `beduiinid`, `muezzin`, razzia on `rüüsteretk`. Vale:
`Hegira`, `Hijra`, `Ummah`, `Medina`, `Muhammad`, `razzias`.

**Teose pealkiri on eesti väljaande pealkiri**, mitte sõnasõnaline:

| Prantsuse → eesti | Prantsuse → eesti |
| --- | --- |
| *Les Fleurs du Mal* → *Kurja lilled* | *Le Spleen de Paris* → *Pariisi spliin* |
| *Tableaux parisiens* → *Pariisi pildid* | *Spleen et Idéal* → „Spliin ja ideaal“ |
| *Correspondances* → „Vastavused“ | *Recueillement* → „Mõtisklus“ |
| *Impression, soleil levant* → *Impressioon. Tõusev päike* | *Le Déjeuner sur l'herbe* → *Lõunasöök murul* |
| *La Nuit étoilée* → *Tähine öö* | *La Ronde de nuit* → *Öine vahtkond* |
| *Les Demoiselles d'Avignon* → *Avignoni neiud* | *Le Cri* → *Karje* |
| *La Ferme des animaux* → *Loomade farm* | *Le Petit Prince* → *Väike prints* |
| *Les Raisins de la colère* → *Vihakobarad* | *Ne tirez pas sur l'oiseau moqueur* → *Tappa laulurästast* |
| *Crime et Châtiment* → *Kuritöö ja karistus* | *Le Procès* → *Protsess* |
| *Les Misérables* → *Hüljatud* | *Madame Bovary* → *Madame Bovary* |
| *Le Rouge et le Noir* → *Punane ja must* | *L'Étranger* → *Võõras* |
| *Gatsby le Magnifique* → *Suur Gatsby* | *Le Meilleur des mondes* → *Hea uus ilm* |
| *La Comédie humaine* → *Inimlik komöödia* | *L'Origine des espèces* → *Liikide tekkimine* |
| *La République* → *Riik* | *Les Confessions* → *Pihtimused* |
| *Psychose* → *Psühho* | *Sueurs froides* → *Vertigo* |
| *Fenêtre sur cour* → *Tagaaken* | *Citizen Kane* → *Kodanik Kane* |
| *Le Seigneur des anneaux* → *Sõrmuste isand* | *Fahrenheit 451* → *451° Fahrenheiti* |

Muud: `Roaring Twenties` → `Hullud kahekümnendad`, `New Deal` jääb
(`New Deali`), `Salon des Refusés` → `Tagasilükatute salong`, *1984*-s
`Big Brother` → `Suur Vend`, `novlangue` → `uuskeel`, `doublepensée` →
`kaksismõtlemine`, Chaplini `Charlot` → `Hulkur`. Kursuse tekstis on
pealkiri `*kaldkirjas*`; liideses, viktoriinis ja sõnastikus (märgisteta)
jutumärkides: `Kes on luulekogu „Kurja lilled“ autor?`. Ei kunagi
nurksulge: `[Le Déjeuner sur l'herbe]` → `*Lõunasöök murul*`. Kui eesti
pealkirja pole, jäta originaal ja selgita esimesel korral sulgudes.

Register on `scripts/proper_nouns.json`. Kirjuta sinna, ära paranda
sama nime kaks korda.

## 6. Tsitaadid

Tsitaat ei ole tõlkeharjutus. Kui on kanooniline eesti sõnastus,
kasuta seda. Muidu tõlgi lühidalt ja selgelt.

- Jutumärgid `„ “` (U+201E ja U+201C). Ei `« »`, ei `" "`, ei `“ ”`, ei `„ ”`.
  `**"Põrn ja ideaalne"**` → `**„Spliin ja ideaal“**`.
- Tsitaadi sees tsitaati ära pane (ülakoma `‘` on keelatud); ehita ümber.
- Iseseisva tsiteeritud lause punkt on lõpujutumärgi sees:
  `„Kõik loomad on võrdsed.“`
- `quote.attribution` on `Autor, teos`. Luuletus jutumärkides:
  `Charles Baudelaire, „Vastavused“`. Kui prantsuse tekst annab
  kõneleja kriipsu järel, kasuta koma või sulge:
  `Fjodor Dostojevski, Kuritöö ja karistus (Raskolnikov)`.

Kanooniline tsitaat *Loomade farmist*:
`„Kõik loomad on võrdsed, kuid mõned loomad on võrdsemad kui teised.“`

## 7. Kirjavahemärgid ja tüpograafia

Masinlik kontroll, eranditeta.

- **Ei pikka kriipsu `—` ega mõttekriipsu `–`.** Ehita ümber koma,
  kooloni, sulgude või punktiga: `peab Mekast – tänapäeva Saudi
  Araabias – pärit kaupmees` → `peab Mekast pärit kaupmees oma linnast
  põgenema. Meka asub tänapäeva Saudi Araabias.` Vahemikud sidekriipsuga:
  `1945-1975`, `14.-16. sajand`.
- Ei `« »`, ei nullilaiusega tühikut, ei sisetühikut (U+00A0), ei BOM-i.
- Ülakoma on sirge `'` (U+0027): `Baudelaire'i`, mitte `Baudelaire’i`.
- Kirjavahemärgi ees tühikut pole. Kaht tühikut järjest pole. Koma,
  kooloni ja semikooloni järel on tühik (välja arvatud kellaaeg `02:59`).
- Koma iga kõrvallause ees (`et`, `kes`, `mis`, `kui`, `sest`) ja selle
  lõpus, kui lause jätkub.
- Lause keskel on üldnimi väikese tähega: `**Muezzin**` → `**muezzin**`,
  `Suur Depressioon` → `suur depressioon`, `renessanss`, `impressionism`.
- Ei prantsuse jääke (`siècle`, `dans`, `l'`, `Salong des Refusés`) ega
  rikutud märke: `**Z69**%`, `ZPea`, `Tsooni`, `7. nüüd` (mai),
  `10.tagumik`. Need on masintõlke prügi; kirjuta lause uuesti.

## 8. Arvud, kuupäevad, mõõdud

- Tuhanded: tavaline tühik alates viiekohalisest arvust, `30 000`,
  `10 000 meest`; neljakohaline kokku, `3000`. Ei punkti, ei koma, ei U+00A0.
- Kümnendmurd komaga, `%` ilma tühikuta: `3,5 %` → `3,5%`, `25%`.
- **Arvu järel on nimisõna ainsuse osastavas** (arv 1 välja arvatud):
  `51 riigid` → `51 riiki`; `9000 USA pangad` → `9000 USA panka`;
  `%d viktoriinid` → `%d viktoriini`; `kursused läbitud` → `kursust
  läbitud`; `kaotatud tunde aastas` → `kaotatud tundi aastas`;
  `õiged vastused` → `õiget vastust`; `neli nooruki` → `neli noorukit`.
- **Aasta**: `En 1857` → `Aastal **1857**` või `**1857**. aastal`;
  `Vers 570` → `umbes **570**. aastal`; `à partir de 610` → `alates
  **610**. aastast`. Vale: `Linnas 622`, `Filmis 1947`, `Raamatus`,
  `Ajakirjas 1866`, `Kohtuasjas 1857`, `630 puhul`, `624-s`, `610-lt`,
  `1874-i`, palja aastaga `**1932** valiti`.
- **Kuupäev** lauses alaleütlevas, kuu väikese tähega, ilma `a`-ta:
  `**24. oktoober 1929**, Wall Street variseb` → `**24. oktoobril 1929**
  variseb Wall Street kokku`; `Saates 29` → `**29.** oktoobril`. Ajajoone
  sildis nimetav: `18. juuni 1815`, `juuni 1940`.
- Vahemik: `du 13 mars au 7 mai 1954` → `13. märtsist 7. maini 1954`;
  `entre 1945 et 1975` → `aastatel 1945-1975`, mitte `1945 ja 1975 vahel`;
  `dans les années 1850` → `1850. aastatel`.
- **Sajand**: araabia number ja punkt, ilma nihketa. `VIIe siècle` →
  `7. sajand`, `7. sajandil`; `XIVe-XVIe siècle` → `14.-16. sajandil`.
  Vale: `700ndad` (see on 8. sajand), `7ndal sajandil`, `XVe`.
- Ajaarvamine: `eKr`, `pKr` ilma punktideta: `399 eKr`. Ei kunagi
  `av. J.-C.`. Hidžra: `Mida kujutab Hegira numbris 622?` → `Mida
  tähendab hidžra aastal 622?`; sellest saab moslemi kalendri 1. aasta.
- Vanus ja kestus: `à 6 ans` → `6-aastaselt`, `à 25 ans` → `25-aastaselt`
  (mitte `**25 aastat** juhib`), `en 22 ans` → `22 aastaga`.
- Ümberarvutusi pole. Meetermõõdustik jääb.
- `Mds`/`Md` → `miljardit`, `M` → `miljonit`, sõnadega: `2,5 miljonit inimest`.
- Tase ja XP: `NIV. 3` → `TASE 3`; `120 XP 5. tasemeni`.

## 9. Kontroll

```bash
python scripts/check_course_translation.py --lang et
python scripts/check_course_translation.py --lang et course_102_*
```

Kontroll annab iga kursuse kohta: nihkunud skelett, katkised märgised,
kirjete arv, registreerimata võtmed, lõigu lõppu pargitud terminid,
`]]` taha liidetud lõpud, keelatud märgid, tühikud, prantsuse jäägid,
lekkinud märgid ja lokaliseerimata arvud. Puhas läbijooks on kohustus,
mitte soovitus.

Kontroll ei näe auditi korduvaid vigu. Need otsi käsitsi ja paranda
kõik leiud:

```bash
grep -rnE '\b(teie|teid|teil|Linnas|Filmis|Ajakirjas|Kohtuasjas|Saates)\b|\b[Mm]e (tahame|elame|saame)\b|\w+ poolt\b|\*{0,2}[0-9]{3,4}\*{0,2}-(s|l|lt|i)\b|\b(Avasta|Tutvu|Sukeldu|Jälgi|Uuri|Vaata|Proovi|Leia|Vali|Alusta|Luge|Pan|Kuula)(ge|ke)\b|["“”]' content/courses/et/
```

Seejärel loe lõik valjusti: sina-vorm, `see` asja kohta, iga `[[...]]`
grammatiline, iga aasta `aastal`-iga, iga arvu järel osastav.
