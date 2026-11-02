# Kurssien kääntäminen: ranskasta suomeen

Ranskankielinen teksti (`content/courses/fr/`) on lähde; tämä dokumentti on `content/courses/fi/`:n määrittely, ja
`scripts/check_course_translation.py --lang fi` valvoo sitä koneellisesti. Samat säännöt koskevat käyttöliittymää,
visoja, sanastoa ja katalogia. Pakollinen terminologia: `content/terminology/` (`termes_produit.json`,
`mots_pieges.json`, `oeuvres.json`); kaikki ”väärin → oikein” -esimerkit ovat auditista `docs/audit-traductions/fi.json`.

## 1. Mitä haluamme

Emme luovuta käännöstä. Luovutamme kurssin **suomenkielisen laitoksen**: tekstin, jonka suomalainen toimittaja olisi
kirjoittanut samoista muistiinpanoista. Lukija ei saa huomata, että alkuteksti oli ranskaa. Tässä järjestyksessä:

1. **Oikein.** Älä vääristä, keksi tai jätä pois faktoja: `**22 katselukertaa**` → `**22 vuodessa**`,
   `**10 000 kolikkoa**` → `**10 000 miehen**`.
2. **Sujuvasti.** Luontevaa yleiskieltä, joka ei kompastele ääneen luettuna.
3. **Yksinkertaisesti.** Lyhyitä lauseita, arkisia sanoja; uteliaan teinin pitää pysyä mukana. Ei translatiiviketjuja:
   `Luo tilisi aloittaaksesi` → `Luo tili ja aloita`.
4. **Muodoltaan uskollisesti.** Suunnilleen sama määrä lauseita, sama ajatuskulku, pituus 20 prosentin sisällä.

**Puhuttelu on aina sinä**, yksikössä ja lämpimästi: `Avaa`, `Kertaa`, `polkusi`. Ei koskaan `te`, `Te`, `teidän`
eikä monikon käskymuotoa (`Tutustukaa`). Painikkeessa ei minä-muotoa: `Aloita {n} päivän ilmainen kokeilujaksoni` →
`Aloita {n} päivän kokeilu`. Tavoitelistan infinitiivi pysyy A-infinitiivinä: `Vähennä näyttöaikaani` → `Vähentää
ruutuaikaa`, `Laajenna mieltäni päivittäin` → `Sivistyä joka päivä`. Latausvaiheet passiivissa: `Analysoi
vastauksiasi` → `Analysoidaan vastauksiasi`, `Valitsemalla 3 aihettasi` → `Valitaan 3 aihettasi`.

**Ranskan persoonaton ”on” ei ole koskaan ”me”.** Käytä passiivia (`-taan`, `-tiin`) tai nollapersoonaa; sama koskee
yleistä ”vous”:ta. Aito ”nous” (Sophia puhuu itsestään: `Ilmoitamme sinulle`) saa jäädä.

> Väärin: `Haluamme tappaa hänet.` · `Elämme siellä heimoissa.` · `puhumme **veron optimointi**`
> Oikein: `Häntä halutaan tappaa.` · `Siellä elettiin heimoissa.` · `puhutaan **verosuunnittelusta**`

**Sukupuoli.** Suomessa ei ole kieliopillista sukua: `hän` on sekä mies että nainen. Käyttäjästä ei tarvita kahta
muotoa; valitse sanoja, jotka sopivat kaikille (`opiskelija`, `kaveri`, `oppinut`), ei `-mies`-sanoja (`yli-ihminen`,
ei `supermies`). Kun ranskan il/elle erottaa kaksi henkilöä, toista nimi tai käytä `tämä`:

> Väärin: `Hänellä ei ole enää omaa ääntä. Hänellä on silmät vain itselleen.`
> Oikein: `Ekholla ei ole enää omaa ääntä. Narkissoksella on silmät vain itselleen.`
> Väärin: `Kun hän lähestyy halatakseen häntä, hän hylkää hänet halveksuen.` → Oikein: `Kun Ekho lähestyy halatakseen Narkissosta, tämä torjuu hänet halveksien.`

Naispuolinen kokemuksen kirjoittaja näkyy nimestään (`Inès, abiturientti`, `Sarah, 26`); nimiä ei suomenneta
(`Tuomas, 29` → `Thomas, 29`, `Saara` → `Sarah`, `Lea` → `Léa`). Naisnimitys vain vakiintuneena (`kuningatar
Guinevere`, `koston jumalatar Nemesis`); ammattinimike neutraali (`opettaja`, `kirjailija`).

**`hän` vain ihmisestä**, asiasta ja järjestöstä `se`: `Hän liitti uusiksi toiminta-alueiksi…` (Nato) → `Se on ottanut
uusiksi toiminta-alueikseen…`. Omistusliite viittaa subjektiin: `Porfiri tietää olevansa syyllinen` tekee tuomarista
syyllisen; oikein `tietää Raskolnikovin olevan syyllinen`.

**Aikamuoto ja kalkit.** Historiallinen preesens (`Vuonna 1874 he järjestävät oman näyttelynsä`) on luonteva, mutta
kappaleen sisällä aikamuoto ei vaihdu (`hänestä tulee johtaja … Hän laati … ja perusti`). `Voici comment ça marche` →
`Näin se toimii`; `Voici ce que tu vas apprendre` → `Tämän opit`; `Soit %@ jours complets` → `Eli kokonaiset %@`, ei
`Siinä on %@ täydet päivät`; `Takaisin kotiin` → `Takaisin etusivulle`; `ympärilläni olevat ihmiset` → `läheiseni`.

**Petolliset sanat.** Käännä lauseen mukaan, ei englannin yleisimmän merkityksen mukaan:

| Ranska (merkitys) | Suomi | Ei |
| --- | --- | --- |
| Léger / Modéré / Intense; la lumière; Gratuit | Kevyt / Kohtalainen / Runsas; Valo; Ilmainen | `Kevyt` valosta; `3 vapaata aihetta` |
| essai gratuit; Expire dans; dans 2 jours; Mensuel / Annuel | `ilmainen kokeilu`, `Aloita kokeilujakso`, `Kokeilu päättyy`; `Aikaa jäljellä`; `2 päivän päästä`; Kuukausittain / Vuosittain (`kuukausitilaus`, `vuositilaus`) | `Aloita oikeudenkäyntini`, koeaika; `Vanhenee`; `2 päivässä`; aikakauslehti, vuosikirja |
| réviser; Entraînement; répétition espacée; scroller; temps d'écran | kerrata (`Kertaan 10 minuuttia päivässä`); Harjoittelu; hajautettu kertaus; skrollata, skrollailu; ruutuaika | tarkistaa, tarkastella; käytäntö; ajoitettu; rullata, vieritys; näyttöaika |
| culture générale, cultivé; anecdotes; Terminale; trimestre | yleissivistys, sivistynyt (`kasvattaa sivistystäsi`); anekdootit, yllättävät faktat; abiturientti; lukukausi | `Kulttuurinen edistymisesi`, `TIEDOT`; vitsit; `vanhempi vuosi`; toimikausi |
| Pas de connexion; Glisse pour découvrir; Reprends du temps pour toi; la personne la plus intéressante de la pièce | Ei verkkoyhteyttä; Pyyhkäise ja tutustu; Ota aikasi takaisin; porukan kiinnostavin tyyppi | `PYYHÄVÄ LÖYDÄKSI`; huoneen kiinnostavin |
| spleen; flâneur; caravane; deux états (d'âme) | spleen (`baudelairelainen spleen`); flanööri; karavaani; kaksi mielentilaa | perna; lastenrattaat; asuntovaunu; kaksi valtiota |
| condamnation; beau-père (Aupick); réhabilitation | tuomio, tuomittiin; isäpuoli; maineenpalautus | vakaumus; appi, anoppi; kuntoutus |
| gravité; failles; pétrole; cellulaire; plaques | painovoima; siirros, heikko kohta; öljy; solu- (`soluhengitys`); valokuvauslevy | vakavuus; viat; matkapuhelin-; lautaset |
| 10 000 hommes; six poèmes; à 6 ans; en 22 ans | 10 000 miestä (sotilasta); kuusi runoa; 6-vuotiaana; 22 vuodessa | kolikkoa, dollaria; runoilijaa; `katselukertaa` |
| Grande Dépression; krach; soupe populaire; bank runs; relance; paradis fiscal | suuri lama; romahdus; soppakeittiö, soppajono; talletuspako; elvytys; veroparatiisi (`offshore-yhtiö`) | `Suuri laama`; kolari; `pankki juoksee`; toipuminen; avomeri |
| chute; sensation; touche; puissant; réel; clé | putoaminen, romahdus; aistimus; kosketin, kosketus; mahtava, voimakas; todellinen; avain | syksy; sensaatio; tehokas |
| surhomme; prise (d'une ville); escalade nucléaire; naturalisme | yli-ihminen; valtaus (`Mekan valtaus`); ydinsodan eskalaatio; naturalismi | supermies; vangitseminen; ydinvoima; naturismi |

## 2. Runko pysyy

Vain tekstikentät käännetään. Muun työkalu kopioi ranskalaisesta rungosta, eikä niihin kosketa: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Kenttä | Mikä se on | Huomio |
| --- | --- | --- |
| `title` / `subtitle` | Otsikko / rivi sen alla | Teoksesta suomennoksen nimi. Vuosi tai väli (`1945-1975`) pysyy. |
| `description` / `hero.hook` | Kahden lauseen esittely / houkutteleva lause | Seisoo yksin. Mainos, ei proosaa. |
| `sections[].title` | Osion otsikko | Nimilauseke, iso kirjain vain alussa, ei pistettä: `Mitä impressionismi muutti` (ei `Mikä impressionismi muuttui`). |
| `paragraph.text` / `image.caption` | Leipäteksti / kuvateksti | Päätyö. Kuvateksti lyhyt; piste vain kokonaisen lauseen perään. |
| `funFact.text` / `takeaway.text` | Laatikko / yhteenveto | Kevyt, puheenomainen. Se, minkä pitää jäädä mieleen. |
| `quote.text` / `quote.attribution` | Lainaus / kuka sanoi | Ks. §6. |
| `timeline.events[].date` | `1789`, `kesäkuu 1940`, `n. 450 eKr.` | Numerot pysyvät, kuukaudet pienellä, `eKr.`, ei `av. J.-C.`. |
| `timeline.events[].title` / `.detail` | Tunniste / yksi lause | Tunniste lyhyt, ilman pistettä, ei käskymuotoa: `Antaudu ilman taistelua` → `Antautuminen ilman taistelua`. |

**Tuotesanasto** on koko sovelluksessa yksi ja sama:

| Ranska | Suomi | Ei |
| --- | --- | --- |
| quiz, mini quiz; cours | visa (`%d visaa`, `Avaa visa`, `Visat auttoivat minua…`); kurssi (`3 kurssia suoritettu`) | tietokilpailu, tietovisa, `Tietustelut`, kysely; oppitunti, luento |
| parcours; collection | polku (`Valmistellaan polkuasi`); kokoelma (`Kokoelma valmis`) | matka, reitti, tietomatka; kollektio, keräys |
| niveau, NIV. 3; série (streak); combo | taso, `TASO 3`; putki (`5 päivän putki`); ketju | aste, luokka; sarja |
| Premium; Sophia | Premium (`Premiumin`, `Premium-tilaus`, `avattavissa Premiumilla`); Sophia (`Sophian`, `Sophiaa`) | `Premium:in`, preemio; `Sofia`, `Sofian kanssa` |
| bloqueur TikTok; l'offre (paywall) | TikTok-esto, esto, sovellusesto; tarjous (`Premium-tarjous`, `Katso tarjous`) | `blockerilla`, `anti-scroll`; paywall, maksumuuri |
| Entraînement; réviser | Harjoittelu (`siirtyvät Harjoitteluusi`); kerrata (`Aika kerrata`, `Kertaa ne`) | käytäntö, harjoitus; tarkistaa |
| objectif; ami; matière / sujet | tavoite; kaveri; aihe (`3 ilmaista aihettasi`) / teema | objektiivi, maali; ystävä; oppiaine, materia |
| abonnement; débloquer | tilaus (`kuukausitilaus`, `vuositilaus`); avata (`Avaa Premium`, `Avaa kurssi`) | jäsenyys, liittymä, sopimus; `poista lukitus`, vapauta |
| glossaire; XP; Bibliothèque; Accueil | sanasto; XP (`100 XP:tä`); Kirjasto; etusivu | sanakirja; kokemuspisteet (vain selityksenä); katalogi, arkisto; koti |
| terminé; Tout (filtre); audio; offre de bienvenue | `VALMIS`; Kaikki; äänikurssi (`Kaikki äänikurssit`); `Tervetuliaistarjous` | `TÄYDELLINEN`; `Koko ajan`; äänet; `Tervetuloa tarjous` |

## 3. Merkinnät rivillä

Kolme merkintää säilyy: `**lihavointi**` (päivämäärät, luvut, nimet ja teokset, joista kappale kertoo), `*kursiivi*`
(teoksen nimi proosassa) ja `[[termi]]` (sanastoartikkeli; napautus avaa määritelmän).

- Merkinnät kulkevat pareittain (pariton määrä `**` on virhe) eivätkä niele välilyöntiä tai välimerkkiä: `**1945**,`
  on oikein, `**1945,**` ja `** 1945 **` väärin.
- Taivutettu muoto on kokonaan lihavoinnin sisällä: `**Badrissa**`, `**Aupickin**`, ei `**Badr**:ssä`.
- Lihavointi merkitsee suomenkielistä vastinetta: `**30 000 mots**` → `**30 000 sanaa**`; `**3 000**-maalaukset` →
  `**3 000** maalausta`. Älä lisää lihavointia, jota ranskassa ei ole. Älä lihavoi kokonaista lausetta.

## 4. Sanastoartikkelit: tärkein sääntö

Jokaisesta ranskan `[[...]]`:sta tulee täsmälleen yksi suomen `[[...]]`, **lauseen sisään, samaan kohtaan
ajatuskulkua**. Älä koskaan pysäköi termiä kappaleen loppuun. Älä jätä aukkoa. Ne ovat sama virhe:

> Väärin: `heikensi ennen kaikkea : kristityt ristiretkeläiset ryöstivät kaupungin. [[Konstantinopolin valtaus]]`
> Oikein: `Kaupunkia heikensi ennen kaikkea [[Konstantinopolin valtaus neljännellä ristiretkellä (1204)]], kun
> läntiset ristiretkeläiset ryöstivät kaupungin.`

Älä myöskään pudota termiä: `Sopimuksen ydin on sen **Artikla 5**` (ranskassa `[[Article 5]]`) on laskuvirhe. Termin
teksti on tämän kurssin avain tiedostossa `ios/Sophia/Resources/Locales/glossary.fi.json`; tuntematon avain jää
kuolleeksi tekstiksi. `scripts/make_translation_briefs.py`:n tiivistelmä luettelee sallitut avaimet; käytä yhtä merkki
merkiltä, isot kirjaimet kuten rekisterissä. Jos avain itse rikkoo §5:tä, korjaa se `glossary.fi.json`:ssa koko
kurssille: `Ummah` → `umma`, `razzias` → `ryöstöretki`, `Kalifi` → `kalifi`, `Ovid` → `Ovidius`, `Metamorfoosit` →
`Muodonmuutoksia`, `pankki juoksee` → `talletuspako`, `Proosa runo` → `proosaruno`, `Le Spleen de Paris` → `Pariisin
ikävä`, `Baudelairelainen "perna"` → `baudelairelainen spleen`, `Rooseveltin uusi sopimus` → `New Deal`, `Newspeak` →
`uuskieli`, `Varsovan sopimus` → `Varsovan liitto`, `Ydinvoiman eskalaatio` → `ydinsodan eskalaatio`.

Lauseen on oltava kieliopillinen **termi paikallaan**. Suomi taivuttaa, avain ei:

- Avain on perusmuodossa. `]]`:n perään ei liitetä päätettä, ei kaksoispisteellä eikä ilman: `[[Kalifi]]:ille`,
  `[[kalifi]]lle`, `[[Le Spleen de Paris]]:ssä` ovat vääriä. Tarkistin päästää kaksoispisteen läpi (`EU:ssa` on
  laillinen), joten vastuu on sinulla.
- Rakenna lause niin, että termin paikka vaatii nominatiivia: subjekti, predikatiivi tai luettelo kaksoispisteen
  jälkeen. Muualla termi saa pääsanan, ja pääsana taipuu: `[[Quraysh]]-heimon`, `[[Medinan perustuslaki]]
  -sopimuksessa` (monisanaisen jälkeen välilyönti ja yhdysmerkki). Pelkkä välilyönti (`[[Quraysh]] heimo`) on virhe.

> Väärin: `Valta siirtyy sitten [[Kalifi]]:ille.` → Oikein: `Vallan perii sitten [[kalifi]], profeetan seuraaja.`
> Väärin: `Tehokas [[Quraysh]] heimo hallitsee tätä kauppaa.` → Oikein: `Mahtava [[Quraysh]]-heimo hallitsee tätä kauppaa.`
> Väärin: `Hän liitti uusiksi virallisiksi toiminta-alueiksi **[[Kyberavaruus]]** ja tilan.` → Oikein: `**[[Kyberavaruus]]** ja avaruus ovat nyt sen virallisia toiminta-alueita.`

- Taivutettu avain (`kyberavaruudessa`) käy vain, jos juuri se on rekisterissä. Jos avain ei istu, rakenna lause
  uudelleen; avainta et muuta lauseessa.

## 5. Erisnimet

**Henkilönimeä ei käännetä.** Degas pysyy Degas'na, Munch Munchina (ei ”pureskella”), jumala Pan Panina (ei `Bang`).

**Pääte liittyy nimeen suoraan**, kun nimi lausutaan kuten kirjoitetaan: `Aupickin`, `Badrissa`, `Panin`,
`Nemesiksen`, `Dostojevskin`, `Baudelairen`. Kun kirjoitettu loppu ei äänny, suora heittomerkki: `Monet'ta`,
`Degas'n`. Kaksoispiste vain lyhenteen, numeron tai symbolin jälkeen: `EU:ssa`, `YK:n`, `100 XP:tä`, `Huone 101:ssä`.
Väärin: `**Badr**:ssä`, `Narsissi:n`, `**Zeusta**:tä`. Määrite taipuu: `hyväksyy kutsun Yathrib-keidas` → `hyväksyy
Jathribin keitaan kutsun`; `Kriitikot pilkkaavat Monet` → `Kriitikko pilkkaa Monet'ta`.

**Vakiintunut suomalainen muoto**, sama koko kurssissa: `Christophe Colomb` → `Kristoffer Kolumbus`, `Londres` →
`Lontoo`, `Charlemagne` → `Kaarle Suuri`, `Michel-Ange` → `Michelangelo`, `roi Arthur, reine Guenièvre` → `kuningas
Arthur, kuningatar Guinevere`, `ONU` → `YK`, `OTAN` → `Nato` (`Naton`; sanaleikissä `NATO englanniksi ja OTAN
ranskaksi`). Kreikan myytit kreikkalaisittain: Narkissos (`Narkissoksen`), Ekho (`Ekhon`; ilmiö on kaiku), Teiresias,
Ovidius, oreadi; ei `Narcissus`, `Narsissi`, `Echo`, `Kaiku` henkilönä, `Ovid`. Venäläiset: Dostojevski, Porfiri
Petrovitš, Dunja, Pulherija, Sonja (ei `Dounia`, `Poulcheria`, `Sonya`).

**Islam ja arabian sanat**: `Muhammad` (`Muhammadin`; ei vuorottelua `Muhammed`-muodon kanssa), `Mekka` (`Mekkaan`),
`Medina`, `Jathrib`, `hidžra` pienellä (`hidžran jälkeen`, `islamilainen ajanlasku alkaa hidžrasta`), `umma`, `kalifi`
(`kalifille`), `dhimma`, `jizya`, `jihad`; razzia on `ryöstöretki`.

> Väärin: `Tämä lähtö, Hegira, merkitsee islamin ensimmäistä vuotta ja maailman sivilisaation alkua.`
> Oikein: `Tämä lähtö, hidžra, on islamilaisen ajanlaskun vuosi 1 ja maailmanlaajuisen sivilisaation alku.`

**Teoksen nimi on suomennoksen nimi**, ei sanasta sanaan (koko luettelo: `oeuvres.json`):

| Ranska → suomi | Ranska → suomi |
| --- | --- |
| *Les Fleurs du Mal* → *Pahan kukat*; *Le Spleen de Paris* → *Pariisin ikävä* | ”Spleen et Idéal”, ”Correspondances”, ”Recueillement” → ”Spleen ja ihanne”, ”Vastaavuuksia”, ”Hiljentyminen” |
| *Impression, soleil levant* → *Impressio, auringonnousu* | *Le Déjeuner sur l'herbe* → *Aamiainen ruohikolla*; *Le Cri* → *Huuto* |
| *Les Métamorphoses* (Ovide) → *Muodonmuutoksia* | *La Métamorphose* (Kafka) → *Muodonmuutos*; *Le Procès* → *Oikeusjuttu* |
| *1984* → *Vuonna 1984*; *La Ferme des animaux* → *Eläinten vallankumous* | *Le Petit Prince* → *Pikku Prinssi*; *Crime et Châtiment* → *Rikos ja rangaistus* |
| *Le Rouge et le Noir* → *Punaista ja mustaa*; *L'Étranger* → *Sivullinen* | *Gatsby le Magnifique* → *Kultahattu*; *Le Meilleur des mondes* → *Uljas uusi maailma* |
| *Madame Bovary* → *Rouva Bovary*; *Les Misérables* → *Kurjat* | *Ne tirez pas sur l'oiseau moqueur* → *Kuin surmaisi satakielen* |
| *Le Maître et Marguerite* → *Saatana saapuu Moskovaan* | *Sueurs froides* → *Vertigo - punainen kyynel* (ajatusviiva tavuviivaksi, ks. §7) |

*Vuonna 1984* on ansa: `romaanissa *Vuonna 1984*`, ei `Elokuvassa 1984`. Nimi pysyy perusmuodossa, pääsana taipuu:
`kokoelmassa *Pahan kukat*`, `*Rikos ja rangaistus* -romaanissa`. Muut: `Roaring Twenties` → `hullu 20-luku`, `Black
Tuesday` → `musta tiistai`, `Genesis` → `synty`, `New Deal` pysyy (`New Dealin`); `novlangue` → `uuskieli`,
`doublepensée` → `kaksoisajattelu`, Isoveli; *Eläinten vallankumous*: Lumipallo, Kirkuja, Ottelija, Vanha Majuri.
Kurssin tekstissä nimi `*kursiivilla*`, käyttöliittymässä ja visassa lainausmerkeissä (`Kuka kirjoitti
runokokoelman ”Pahan kukat”?`). Ilman suomennosta jätä alkuperäinen ja selitä se kerran suluissa. Rekisteri on
`scripts/proper_nouns.json`: kirjoita sinne, älä korjaa samaa nimeä kahdesti.

## 6. Lainaukset

Lainaus ei ole käännösharjoitus: vakiintunut suomenkielinen sanamuoto, jos sellainen on; muuten lyhyesti ja selkeästi.

- Lainausmerkit `” ”` (U+201D molemmin puolin). Ei `« »`, ei `" "`, ei `“ ”`, ei `„ “`: `**"Perna ja ihanne"**` →
  `**”Spleen ja ihanne”**`; `"Sophian ansiosta…"` → `”Sophian ansiosta historian keskiarvoni nousi…”`. Lainausta
  lainauksen sisään ei tehdä (`’` on kielletty); rakenna uudelleen.
- Itsenäisen lainatun virkkeen piste on loppumerkin sisällä: `”Kaikki eläimet ovat tasa-arvoisia.”` Johdannon jälkeen
  kaksoispiste: `Narkissos huutaa: ”Onko siellä ketään?”` (ei `soittaa`).
- `quote.attribution` on `Tekijä, teos`; runo lainausmerkeissä: `Charles Baudelaire, ”Vastaavuuksia”`. Puhuja
  ajatusviivan sijaan suluissa: `Fjodor Dostojevski, Rikos ja rangaistus (Raskolnikov)`.
- Vakiintunut lainaus *Eläinten vallankumouksesta*: `”Kaikki eläimet ovat tasa-arvoisia, mutta jotkut eläimet ovat
  tasa-arvoisempia kuin toiset.”`

## 7. Välimerkit ja typografia

- **Ei pitkää ajatusviivaa `—` eikä lyhyttä `–`.** Suomen painokäytäntö käyttäisi `–`:ta, mutta tarkistin kieltää sen.
  Rakenna uudelleen pilkulla, kaksoispisteellä, sulkeilla tai pisteellä. Välit tavuviivalla: `1945-1975`, `610-632`,
  `1-2 h`, `30-100 €/kk`, `1300-1500-luvuilla`.
- Ei `« »`, ei nollaleveää välilyöntiä, ei sitovaa välilyöntiä (U+00A0), ei BOM:ia. Heittomerkki on suora `'`
  (U+0027): `Monet'n`, ei `Monet’n`.
- Ei välilyöntiä ennen välimerkkiä, ei kahta välilyöntiä peräkkäin. Pilkun, kaksoispisteen ja puolipisteen jälkeen
  välilyönti (paitsi `02:59` ja `EU:ssa`). Pilkku sivulauseen eteen (`että`, `joka`, `kun`, `koska`, `jotta`).
- Yhdyssana yhteen: `Proosa runo` → `proosaruno`, `deflaatio politiikka` → `deflaatiopolitiikka`, `Tervetuloa
  tarjous` → `tervetuliaistarjous`. Nimen tai lyhenteen jälkeen yhdysmerkki: `Premium-tilaus`, `TikTok-esto`,
  `YK-joukot`; monisanaisen nimen jälkeen välilyönti ja yhdysmerkki: `New Deal -ohjelma`.
- Yleisnimi lauseen sisällä pienellä: `**Suuri laama**` → `suuri lama`, `**Ydinvoiman kiihtymisen**` → `ydinsodan
  eskalaation`, `renessanssi`, `hidžra`, `musta tiistai`; kuukaudet pienellä. Otsikossa iso kirjain vain alussa:
  `Tietovisat ja Harjoittelu` → `Visat ja harjoittelu`.
- Ei ranskan jäänteitä (`siècle`, `dans`, `l'`) eikä englannin (`Roaring Twenties`, `blocker`, `paywall`).
  Keksityt sanat (`PYYHÄVÄ`, `Tietustelut`) ovat konekäännöksen roskaa; kirjoita lause uudelleen.

## 8. Luvut, päivämäärät, mitat

- Tuhannet: tavallinen välilyönti nelinumeroisesta alkaen (`1 000+ arvostelua`, `10 000 miestä`), ei koskaan
  vuosiluvussa (`1857`). Ei pistettä, ei pilkkua, ei U+00A0. Desimaalit pilkulla (`3,5`). Prosentti ja yksikkö
  välilyönnin kanssa: `-70% IKUISESTI` → `-70 % IKUISESTI`, `**25 %**`, `1h - 2h` → `1-2 h`, `10 min`.
- **Luvun jälkeen nimisana on yksikön partitiivissa** (paitsi 1): `%d tietokilpailut` → `%d visaa`, `7 oikeat
  vastaukset` → `7 oikeaa vastausta`, `730 menetettyjä tunteja` → `730 menetettyä tuntia`, `500 asioita` → `500 uutta
  asiaa`. Muissa sijoissa luku ja sana kongruoivat: `10 000 miehen kanssa`, `kolmessa vuodessa`. Paikkamerkit `%d`,
  `%@`, `{n}` pysyvät, ja lauseen pitää toimia millä tahansa luvulla.
- **Vuosi**: `En 1857` → `Vuonna **1857**`; `Vers 630` → `noin vuonna **630**` (aikajanalla `n. 630`); `dès 610` →
  `vuodesta **610** alkaen`; `après 622` → `vuoden **622** jälkeen`. Väärin: `Julkaisussa 1857`, `Asiassa 1857`,
  `Alueella 1874`, `Mallissa 630`, `Teoksessa`/`Kirjassa`/`Elokuvassa` + vuosi, `**622**:ssa`, `624:ssä`, `610:lta`.
- **Päivämäärä**: `24. lokakuuta 1929`, kuukausi pienellä; pelkkä kuukausi `kesäkuu 1940`. Väärin: `**10.24.**`,
  `**24.10.1929**, Wall Street romahtaa` → `**24. lokakuuta 1929** Wall Street romahtaa`; `**29**, "Black Tuesday"`
  → `**29. päivänä**, ”mustana tiistaina”`. `entre 1945 et 1975` → `vuosina 1945-1975`; `années 1850` → `1850-luvulla`.
- **Vuosisata** aina `-luku`-muodossa, ilman siirtymää ja ilman roomalaisia numeroita: `VIIe siècle` → `600-luku`,
  `600-luvulla` (vuodet 601-700); `XIXe` → `1800-luku`; `XIVe-XVIe` → `1300-1500-luvuilla`; `Ve siècle av. J.-C.` →
  `400-luvulla eKr.`. Väärin: `700-luvulla Arabia ei kiinnostanut…` (se on VIIIe) → `600-luvulla Arabia ei
  kiinnostanut juuri ketään.`
- Ajanlasku `eKr.` / `jKr.` (`399 eKr.`), ei `av. J.-C.`; `An 1 de l'Hégire` → `islamilaisen ajanlaskun vuosi 1`.
- Ikä ja kesto: `à 6 ans` → `6-vuotiaana`, `en 22 ans` → `22 vuodessa`, `dans 2 jours` → `2 päivän päästä`, ei
  `katselukertaa`. Ei muunnoksia. `Mds` → `miljardia`, `M` → `miljoonaa`. `NIV. 3` → `TASO 3`.

## 9. Tarkistus

```bash
python scripts/check_course_translation.py --lang fi
python scripts/check_course_translation.py --lang fi course_102_*
```

Tarkistin raportoi: siirtynyt runko, rikkinäiset merkinnät, artikkelien määrä, rekisteröimättömät ja pysäköidyt
termit, kielletyt merkit, välilyönnit, ranskan jäänteet, lokalisoimattomat luvut. Puhdas ajo on velvollisuus. Auditin
toistuvia virheitä (me-muoto, `<vuosi>:ssa`, pääte `]]`:n perässä, `katselukertaa`) se ei näe; etsi ne käsin:

```bash
grep -rnE '\b(Haluamme|Elämme|Vaadimme|Puhumme|Kutsumme|Lainaamme)\b|\b(Julkaisussa|Asiassa|Alueella|Mallissa|Teoksessa|Kirjassa|Elokuvassa) \**[0-9]{3,4}|[0-9]{3,4}\**:(ssa|ssä|lta|ltä|n)\b|(\]\]|\*\*):[a-zäö]|\]\][a-zäö]|katselukert|\bSofia|tietokilpailu|[Tt]ietovisa|Tietustelu|oikeudenkäynti|\b[Pp]erna|Hegira|\b(Te|Teidän|Teille)\b|\\"|“|„' content/courses/fi/
```

Lopuksi lue ääneen: sinä, passiivi ”on”:n paikalla, `se` asiasta, `[[...]]` perusmuodossa, `vuonna`, partitiivi.
