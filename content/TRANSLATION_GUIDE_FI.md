# Kurssien kääntäminen ranskasta suomeen

Ranskankielinen teksti (`content/courses/fr/`) on lähde. Tämä dokumentti on `content/courses/fi/`:n määrittely. Se
annetaan kokonaan sille, joka käännöksen kirjoittaa, ja `scripts/check_course_translation.py --lang fi` tarkistaa sen
koneellisesti. Samat säännöt koskevat käyttöliittymää, visoja, sanastoa ja katalogia (`courses.fi.json`,
`collections.fi.json`, `glossary.fi.json`, `android/app/src/main/assets/strings/fi.json`). Kaikki ”väärin → oikein”
-esimerkit ovat nykyisen suomenkielisen tekstin auditista (`docs/audit-traductions/fi.json`).

## 1. Mitä haluamme

Emme luovuta käännöstä. Luovutamme kurssin **suomenkielisen laitoksen**: tekstin, jonka suomalainen toimittaja olisi
kirjoittanut samoista muistiinpanoista. Lukija ei saa huomata, että alkuteksti oli ranskaa.

Tässä järjestyksessä:

1. **Oikein.** Älä vääristä, keksi tai jätä pois tosiasioita. `**22 katselukertaa** (610-632)` → `**22 vuodessa**
   (610-632)`; `**10 000 kolikkoa**` → `**10 000 miehen**`.
2. **Sujuvasti.** Luontevaa yleiskieltä, joka ääneen luettuna ei kompastele.
3. **Yksinkertaisesti.** Lyhyitä lauseita, arkisia sanoja. Uteliaan teinin on pysyttävä mukana. Mieluummin ”näytti”
   kuin ”demonstroi”.
4. **Muodoltaan uskollisesti.** Suunnilleen sama määrä virkkeitä, sama ajatuskulku, pituus kahdenkymmenen prosentin
   sisällä, jotta taitto sovelluksessa pysyy.

**Lukijaa puhutellaan aina sinä-muodossa**, lämpimästi. Ei koskaan `te`, `teidän`, `teille` eikä monikon käskymuotoa
`-kaa/-kää`. Painikkeessa ei ole minä-omistusliitettä, joka tekisi puhujasta käyttäjän.

> Väärin: `Aloita oikeudenkäyntini` · `Aloita {n} päivän ilmainen kokeilujaksoni` · `Vain muutama sekunti, lupaa.` ·
> `@-tunnuksesi antaa ystävillesi löytää sinut.`
> Oikein: `Aloita kokeilujakso` · `Aloita {n} päivän kokeilu` · `Vain muutama sekunti, lupaan.` · `@-tunnuksen avulla
> kaverisi löytävät sinut.`

Latausvaiheet ovat passiivissa, tavoitteet infinitiivissä (käyttäjä valitsee ne itse, joten `-ni` sopii): `Analysoi
vastauksiasi` → `Analysoidaan vastauksiasi`, `Valitsemalla 3 aihettasi` → `Valitaan 3 aihettasi`, `Vähennä
näyttöaikaani` → `Vähentää ruutuaikaani`, `Laajenna mieltäni päivittäin` → `Sivistyä joka päivä`. Lempinimi on
substantiivi: `Mytologiasta utelias` → `Mytologian tutkija`.

**Ranskan persoonaton ”on” ei ole koskaan ”me”.** Käytä passiivia (`-taan/-tään`, `-ttiin`) tai yleistä lausetta. Sama
koskee yleistä ”vous”-muotoa. Aito ”nous” (`notre façon de regarder`) voi jäädä me-muotoon.

> Väärin: `Haluamme tappaa hänet.` · `Elämme siellä heimoissa.` · `Vaadimme tarkan piirustuksen.` · `puhumme **veron
> optimointi**`
> Oikein: `Hänet halutaan tappaa.` · `Siellä elettiin heimoissa.` · `Vaaditaan tarkka piirustus.` · `puhutaan
> **verosuunnittelusta**`

**Suku.** Suomessa ei ole kieliopillista sukua: `hän` on mies tai nainen, adjektiivi ei taivu suvun mukaan.
Käyttäjälle ei tarvita kahta muotoa; valitse sanat, jotka sopivat kaikille (`opiskelija`, `kaveri`, ei `ystävätär`).
Kun ranskan il/elle erottaa kaksi henkilöä, toista nimi: `Hänellä ei ole enää omaa ääntä. Hänellä on silmät vain
itselleen.` → `Ekholla ei ole enää omaa ääntä. Narkissoksella on silmät vain itselleen.` Asiasta `se`/`ne`, ei koskaan
`hän`: `Hän liitti uusiksi toiminta-alueiksi …` (Nato) → `Se on ottanut uusiksi toiminta-alueikseen …`. Naispuolisen
kokemuskertojan sukupuoli näkyy nimestä (`Inès, abiturientti`, `Léa, 24`); nimiä ei suomennata: `Tuomas, 29` →
`Thomas, 29`, `Saara, 26` → `Sarah, 26`. Naissukuinen sana vain vakiintuneena: `kuningatar Guinevere`, `koston
jumalatar Nemesis`, `nymfi Ekho`; ammatit neutraaleina (`tutkija`, `kirjailija`).

**Aikamuoto.** Seuraa ranskaa. Historiallinen preesens (`Vuonna **1874** he järjestävät oman näyttelynsä`) on suomessa
luonteva. Kappaleen sisällä ei vaihdeta: `hänestä tulee johtaja … Hän laati … ja perusti` on virhe.

**Käännöslainat.** `Siinä on %@ täydet päivät.` → `Eli kokonaiset %@.`; `Se on %d viikkoa vuodessa` → `Eli %d viikkoa
vuodessa`; `Voici comment ça marche` → `Näin se toimii`; `Voici ce que tu vas apprendre` → `Tämän opit`. Pour +
infinitiivi ei ole translatiiviketju: `Luo tilisi aloittaaksesi` → `Luo tili ja aloita`. `Mikä impressionismi muuttui`
→ `Mitä impressionismi muutti`. `Takaisin kotiin` → `Takaisin etusivulle`.

**Petolliset sanat.** Monimerkityksinen sana käännetään lauseen, ei englannin yleisimmän merkityksen mukaan
(tuotesanat ovat §2:n taulukossa):

| Ranska (merkitys) | Suomi | Ei |
| --- | --- | --- |
| essai gratuit; Expire dans | ilmainen kokeilu, kokeilujakso (`Kokeilu päättyy`); `Aikaa jäljellä`, `Päättyy`, `2 päivän päästä` | oikeudenkäynti, koeaika; `Vanhenee v`, `2 päivässä` |
| Léger / Modéré / Intense; la lumière; Gratuit; Mensuel / Annuel | Kevyt / Kohtalainen / Runsas; Valo; Ilmainen (`3 ilmaista aihettasi`); Kuukausittain / Vuosittain | `Kevyt` valosta; `vapaata`; aikakauslehti, vuosikirja |
| culture générale, cultivé; anecdotes; Terminale; trimestre | yleissivistys, sivistynyt (`kasvattaa sivistystäsi`, `Sivistyksesi kehitys`); yllättävät faktat; abiturientti; lukukausi | kulttuuri, `Kulttuurinen edistymisesi`, `TIEDOT`; vitsit; `vanhempi vuosi`; virkakausi |
| scroller; Glisse pour découvrir; Pas de connexion; Reprends du temps pour toi; la personne la plus intéressante de la pièce | skrollata, skrollailu; `Pyyhkäise ja tutustu`; Ei verkkoyhteyttä; Ota aikasi takaisin; porukan kiinnostavin tyyppi | vieritys, rullata; `PYYHÄVÄ LÖYDÄKSI`; huoneen kiinnostavin |
| spleen; flâneur; caravane; deux états (d'âme) | spleen (`Spleen ja ihanne`); flanööri; karavaani; kaksi mielentilaa | perna; lastenrattaat; asuntovaunu; kaksi valtiota |
| condamnation; beau-père (Aupick); réhabilitation; surhomme | tuomio (`tuomittiin`); isäpuoli; maineenpalautus; yli-ihminen | vakaumus; anoppi, appi; kuntoutus; supermies |
| ans; hommes; poèmes | `22 vuodessa`, `6-vuotiaana`; `10 000 miestä`; `kuusi runoa` | katselukertaa; kolikkoa, dollaria; runoilijaa |
| gravité; failles; pétrole; cellulaire; plaques | painovoima; siirros, heikko kohta; öljy; solu-; valokuvauslevy | vakavuus; vika; matkapuhelin; lautanen |
| Grande Dépression; soupe populaire; krach; bank runs; relance | suuri lama; soppakeittiö; romahdus (`Romahduspäivänä`); talletuspako; elvytys | `Suuri laama`; `Kolaripäivänä`; `pankki juoksee`; toipuminen |
| paradis fiscal; optimisation fiscale; escalade nucléaire; prise (de La Mecque) | veroparatiisi, offshore-yhtiö; verosuunnittelu; ydinsodan eskalaatio; valtaus | avomeri; `veron optimointi`; `Ydinvoiman kiihtyminen`; vangitseminen |
| puissant; touche; sensation; chute; Renaissance | mahtava, voimakas; kosketin, siveltimenjälki; aistimus; putoaminen, romahdus; renessanssi | tehokas; kosketus; sensaatio; syksy |

## 2. Runko pysyy

Vain tekstikentät käännetään. Muun työkalu kopioi ranskankielisestä rungosta, etkä koske siihen: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Kenttä | Mikä se on | Huomio |
| --- | --- | --- |
| `title` | Kortin ja yläosan otsikko | Lyhyt. Teoksesta kertovassa kurssissa suomennoksen nimi. |
| `subtitle` | Rivi otsikon alla | Vuosi tai väli (`1945`, `1945-1975`) pysyy. |
| `description` | Kahden virkkeen esittely | Toimii yksinään. |
| `hero.hook` | Yksi houkutteleva virke | Mainos, ei proosaa. |
| `sections[].title` | Osan otsikko | Substantiivilauseke, ei pistettä lopussa. |
| `paragraph.text` | Yhtenäinen teksti | Päätyö. |
| `image.caption` | Kuvateksti | Lyhyt; piste vain kokonaisen virkkeen jälkeen. |
| `funFact.text` | Laatikko | Kevyt, puheenomainen. |
| `takeaway.text` | Yhteenveto | Se, minkä pitää jäädä mieleen. |
| `quote.text` / `quote.attribution` | Lainaus / kuka sanoi | Ks. §6. |
| `timeline.events[].date` | `1789`, `kesäkuu 1940`, `noin 450 eKr.` | Numerot pysyvät, kuukaudet pienellä, `eKr.`, ei `av. J.-C.`. |
| `timeline.events[].title` | Tunniste | Hyvin lyhyt, ei pistettä. |
| `timeline.events[].detail` | Yksi virke | Kokonainen lause: `Antaudu ilman taistelua…` → `Antautuminen ilman taistelua ja yleinen armahdus.` |

Otsikot ovat virkekirjoituksella: iso alkukirjain vain ensimmäisessä sanassa ja erisnimissä.

**Tuotesanasto** on koko sovelluksessa yksi ja sama:

| Ranska | Suomi | Ei |
| --- | --- | --- |
| quiz; cours | visa (`%d visaa`, `Avaa visa`, `Visat auttoivat minua…`); kurssi (`3 kurssia suoritettu`) | tietokilpailu, tietovisa, kysely, `Tietustelut`; oppitunti, luento |
| parcours; collection; niveau, NIV. 3; série (streak); combo | polku; kokoelma; taso, `TASO 3`; putki, `5 päivän putki`; ketju | matka, reitti, tietomatka; kollektio; aste, luokka; sarja |
| essai gratuit; abonnement; débloquer; offre de bienvenue | ilmainen kokeilu, kokeilujakso; tilaus, kuukausitilaus, vuositilaus; avata (`Avaa Premium`, `3 aihetta avattavissa Premiumilla`); Tervetuliaistarjous | oikeudenkäynti; jäsenyys, liittymä; poista lukitus, `lukituksen avaamiseen`; `Tervetuloa tarjous` |
| Premium; Sophia | Premium (`Premiumin`, `Premiumia`, `Premium-tilaus`); Sophia (`Sophian`, `Sophiaa`) | preemio, `Premium:in`; `Sofia`, `Sofian` |
| bloqueur TikTok; l'offre (paywall) | TikTok-esto, esto, sovellusesto; tarjous (`Premium-tarjous`, `Katso tarjous`) | blocker, `blockerilla`, anti-scroll; paywall, maksumuuri |
| Entraînement; réviser; révision espacée | Harjoittelu (`siirtyvät Harjoitteluusi`); kerrata, kertaus (`Kertaan 10 minuuttia päivässä`); hajautettu kertaus | käytäntö, harjoitus; tarkistaa, tarkastella; ajoitettu kertaus |
| objectif; ami; matière / sujet; glossaire | tavoite; kaveri; aihe / teema; sanasto | objektiivi, maali; ystävä; oppiaine, materia; sanakirja |
| XP; Bibliothèque; Accueil; terminé (badge); audio; Tout | XP (`100 XP:tä`, `%d XP arvonimeen %@`); Kirjasto; Etusivu; VALMIS; äänikurssi; Kaikki | katalogi, arkisto; Koti; TÄYDELLINEN; äänet; `Koko ajan` |

## 3. Merkinnät rivissä

Kolmen merkinnän on säilyttävä:

- `**lihavointi**`: päivämäärät, luvut, nimet ja teokset, joista kappale kertoo.
- `*kursiivi*`: teoksen nimi proosassa.
- `[[termi]]`: sanastokirjaus. Napautus avaa määritelmän.

Säännöt:

- Merkinnät ovat pareittain. Pariton määrä `**` on virhe.
- Mikään merkintä ei niele välilyöntiä eikä välimerkkiä: `**1945**,` on oikein, `**1945,**` ja `** 1945 **` väärin.
  Lihavointi ei lopu pisteeseen: `**24. lokakuuta**`, `**450** eKr.`, ei `**29.**`.
- **Sijapääte kuuluu lihavoinnin sisään.** Ei koskaan kaksoispistettä merkinnän jälkeen: `**Badr**:ssä` →
  `**Badrissa**`, `**Aupick** kanssa` → `**Aupickin** kanssa`, `**Zeusta**:tä` → `**Zeusta**`, `**Dostojevskin**:n` →
  `**Dostojevskin**`. Vuosi lihavoidaan ilman päätettä: `vuonna **624**`.
- Lihavointi merkitsee suomenkielistä vastinetta, ei samoja merkkejä: `**30 000 mots**` → `**30 000 sanaa**`.
- Älä lisää lihavointia, jota ranskassa ei ole. Älä lihavoi koko virkettä.

## 4. Sanastokirjaukset: tärkein sääntö

Jokaisesta ranskan `[[...]]`:sta tulee täsmälleen yksi suomen `[[...]]`, **virkkeen sisään, samaan kohtaan
ajatuskulkua**. Älä koskaan pysäköi termiä kappaleen loppuun. Älä jätä aukkoa. Ne ovat sama virhe:

> Väärin: `heikensi ennen kaikkea : ristiretkeläiset ryöstivät kaupungin. [[Konstantinopolin valtaus]]`
> Oikein: `Kaupunkia heikensi ennen kaikkea [[Konstantinopolin valtaus neljännellä ristiretkellä (1204)]], kun
> läntiset ristiretkeläiset ryöstivät sen.`

Termin teksti ei ole vapaa. Sen on oltava tälle kurssille rekisteröity avain tiedostossa
`ios/Sophia/Resources/Locales/glossary.fi.json`. Tuntematon avain jää kuolleeksi tekstiksi.
`scripts/make_translation_briefs.py`:n brief luettelee sallitut avaimet; käytä yhtä merkki merkiltä, isot kirjaimet
mukaan lukien. Älä vaihda kirjausta toiseen.

Virkkeen on oltava kieliopillinen **termi paikallaan**. Suomi taivuttaa, joten tämä on suomessa vaikein kohta:

- Mitään ei liimata `]]`:n perään: `[[Kalifi]]:ille`, `[[Ummah]]in`, `[[Le Spleen de Paris]]:ssä` ovat vääriä.
  Kaksoispiste-pääte kuuluu vain lyhenteisiin ja numeroihin (`YK:ssa`, `XP:tä`), ei termeihin.
- Rakenna virke niin, että termin paikka vaatii nominatiivin: subjekti (`Sitten tulee [[talletuspako]]: …`),
  predikatiivi (`Tärkein työkalu on [[siirtohinnoittelu]]`), luettelo kaksoispisteen jälkeen tai `nimellä` / `eli`:
  `Hän laatii sopimuksen, joka tunnetaan nimellä [[Medinan perustuslaki]].`
- Monisanainen termi ja pääsana eivät muodosta yhdyssanaa: `entiset **[[Varsovan sopimus]]** maat` → `entiset
  itäblokin maat, joita yhdisti **[[Varsovan sopimus]]**`. Yksisanaisen nimen perään yhdysmerkki käy: `Mahtava
  [[Quraysh]]-heimo hallitsee Mekkaa.`
- Jos virkettä ei voi rakentaa nominatiiville luontevasti, rekisteröi taivutettu muoto omaksi avaimekseen
  `glossary.fi.json`:iin samalla selityksellä (kuten `kyberavaruudessa`): `noin kolmekymmentä [[Virallinen Pariisin
  salonki]] avasi` → `noin kolmekymmentä [[Pariisin viralliseen Salonkiin]] kyllästynyttä taiteilijaa avaa`. Avainta
  ei koskaan muuteta vain virkkeessä.
- Jos rekisteröity avain itse rikkoo §1:n tai §5:n sääntöjä, korjaa se `glossary.fi.json`:iin koko kurssille kerralla:
  `Ummah` → `umma`, `razzias` → `ryöstöretki`, `Kalifi` → `kalifi`, `Ovid` → `Ovidius`, `Proosa runo` → `proosaruno`,
  `Le Spleen de Paris` → `Pariisin ikävä`, `pankki juoksee` → `talletuspako`, `Rooseveltin uusi sopimus` → `New Deal`,
  `Baudelairelainen "perna"` → `baudelairelainen spleen`, `Salon des Refusés` → `Hylättyjen salonki`.

## 5. Erisnimet

Konekäännös lukee sukunimet yleissanoina. Ehdottomat säännöt:

**Henkilön etu- ja sukunimeä ei käännetä.** Munch on Munch (ei ”pureskella”), Pan on Pan (ei `Bang`), Degas on Degas,
Corneille on Corneille.

**Taivutus.** Pääte liitetään suoraan, kun nimi äännetään kuten kirjoitetaan: `Aupickin`, `Badrissa`, `Zeusta`,
`Nadarin`. Kun nimen loppu äännetään toisin kuin kirjoitetaan, pääte erotetaan suoralla heittomerkillä: `Monet'ta`,
`Monet'n`, `Degas'n`, `Seurat'n`. Äänetön loppu-e ei vaadi heittomerkkiä: `Baudelairen`, `Shakespearen`. Lyhenteeseen
kaksoispiste: `YK:ssa`, `EU:n`; Nato kirjoitetaan sanana: `Natossa`, `Naton`.

**Vakiintunut suomenkielinen muoto**, sama koko kurssissa: `Christophe Colomb` → `Kristoffer Kolumbus`, `Londres` →
`Lontoo`, `Pékin` → `Peking`, `Aix-la-Chapelle` → `Aachen`, `Charlemagne` → `Kaarle Suuri`, `Michel-Ange` →
`Michelangelo`, `Saint-Pétersbourg` → `Pietari`, `Ulysse` → `Odysseus`, `Byzance` → `Bysantti`, `ONU`, `OTAN` → `YK`,
`Nato` (`OTAN` vain kun puhutaan ranskan lyhenteestä: `NATO englanniksi ja OTAN ranskaksi`), `roi Arthur, reine
Guenièvre` → `kuningas Arthur, kuningatar Guinevere`, `Siège périlleux` → `Vaarallinen istuin`.

**Kreikkalaiset myytit kreikkalaisessa asussa**, ei latinan eikä englannin: Narkissos (`Narkissoksen`), Ekho (`Ekhon`;
ilmiö on `kaiku`, kukka `narsissi`), Teiresias, Pan (`Panin`), Nemesis (`Nemesiksen`), oreadi, naiadit, dryadit,
Medeia, Sisyfos, Daidalos, Ikaros. Kirjoittaja on Ovidius, teos *Muodonmuutoksia*. Väärin: `**Narsissi**:n ja
**Kaiku**:n`, `Narcisse soittaa`, `Echo`, `Tirésias`. **Venäläiset nimet** suomalaisessa translitteraatiossa: Fjodor
Dostojevski, Rodion Raskolnikov, Porfiri Petrovitš, Pulherija, Dunja, Sonja Marmeladova (ei `Poulcheria`, `Dounia`,
`Sonya`).

**Islam ja arabian sanat**: `Muhammad` (`Muhammadin`), `Mekka` (`Mekasta`), `Medina` (`Medinaan`), `Jathrib`, `hidžra`
pienellä (`hidžran jälkeen`), `umma`, `kalifi` (`kalifeille`), `jizya`, `dhimma`, `jihad`, `beduiinit`, `muezzin`;
razzia on `ryöstöretki`. Väärin: `Hegira`, `Hijra`, `Ummah`, `Muhammed`, `razzias`. `Tämä lähtö, Hegira, merkitsee
islamin ensimmäistä vuotta` → `Tämä lähtö, hidžra, on islamilaisen ajanlaskun vuosi 1`.

**Teoksen nimi on suomennoksen nimi**, ei sanatarkka käännös:

| Ranska → suomi | Ranska → suomi | Ranska → suomi |
| --- | --- | --- |
| *Les Fleurs du Mal* → *Pahan kukat* | *Le Spleen de Paris* → *Pariisin ikävä* | *Spleen et Idéal* → ”Spleen ja ihanne” |
| *Correspondances* → ”Vastaavuuksia” (ei `Kirjeenvaihto`) | *Recueillement* → ”Hiljentyminen” | *Impression, soleil levant* → *Impressio, auringonnousu* (ei `Printti`) |
| *Le Déjeuner sur l'herbe* → *Aamiainen ruohikolla* | *Les Demoiselles d'Avignon* → *Avignonin naiset* | *La Nuit étoilée* → *Tähtikirkas yö* |
| *La Ronde de nuit* → *Yövartio* | *Le Cri* → *Huuto* | *La Joconde* → *Mona Lisa* |
| *1984* → *Vuonna 1984* | *La Ferme des animaux* → *Eläinten vallankumous* | *Crime et Châtiment* → *Rikos ja rangaistus* |
| *Le Procès* → *Oikeusjuttu* | *Les Misérables* → *Kurjat* | *Madame Bovary* → *Rouva Bovary* |
| *Le Rouge et le Noir* → *Punaista ja mustaa* | *L'Étranger* → *Sivullinen* | *Gatsby le Magnifique* → *Kultahattu* |
| *Le Meilleur des mondes* → *Uljas uusi maailma* | *Le Petit Prince* → *Pikku Prinssi* | *Le Maître et Marguerite* → *Saatana saapuu Moskovaan* |
| *Les Raisins de la colère* → *Vihan hedelmät* | *Ne tirez pas sur l'oiseau moqueur* → *Kuin surmaisi satakielen* | *La République* → *Valtio* |
| *Psychose* → *Psyko* | *Fenêtre sur cour* → *Takaikkuna* | *Sueurs froides* → *Vertigo* (ajatusviiva on kielletty) |

Muut: `Roaring Twenties` → `Hullu 20-luku`; `Black Tuesday` → `musta tiistai`; `New Deal` pysyy (`New Dealin`, ei
`uusi sopimus`); `Salon des Refusés` → `Hylättyjen salonki`; `Genesis` (otsikko) → `Synty`; *Vuonna 1984*: `Big
Brother` → `Isoveli`, `novlangue` → `uuskieli`, `doublepensée` → `kaksoisajattelu`; Chaplinin `Charlot` → `Kulkuri`.
Kurssitekstissä nimi on `*kursiivilla*`; käyttöliittymässä, visassa ja sanastossa (ilman merkintöjä) lainausmerkeissä:
`Kuka kirjoitti kokoelman ”Pahan kukat”?`. Jos suomennosta ei ole, jätä alkuperäinen nimi ja selitä se ensimmäisellä
kerralla suluissa.

Rekisteri on `scripts/proper_nouns.json`. Kirjoita sinne, älä korjaa samaa nimeä kahdesti.

## 6. Lainaukset

Lainaus ei ole käännösharjoitus. Jos vakiintunut suomenkielinen sanamuoto on olemassa, käytä sitä. Muuten käännä
lyhyesti ja selkeästi.

- Lainausmerkit `” ”` (U+201D molemmin puolin). Ei `« »`, ei `" "`, ei `“ ”`, ei `„ ”`: `**"Perna ja ihanne"**` →
  `**”Spleen ja ihanne”**`; `"Profeetan kaupungiksi"` → `”Profeetan kaupungiksi”`.
- Lainausta lainauksen sisään ei tehdä (puolilainausmerkki `’` on kielletty); rakenna virke uudelleen.
- Itsenäisen lainatun virkkeen piste on lainausmerkin sisällä: `”Kaikki eläimet ovat tasa-arvoisia.”`
- `quote.attribution` on `Tekijä, teos`; runo lainausmerkeissä: `Charles Baudelaire, ”Vastaavuuksia”`. Jos ranska
  antaa puhujan ajatusviivan jälkeen, käytä pilkkua tai sulkeita: `Fjodor Dostojevski, Rikos ja rangaistus
  (Raskolnikov)`.

Vakiintunut lainaus *Eläinten vallankumouksesta*: `”Kaikki eläimet ovat tasa-arvoisia, mutta jotkut eläimet ovat
tasa-arvoisempia kuin toiset.”`

## 7. Välimerkit ja typografia

Koneellinen tarkistus, ei poikkeuksia.

- **Ei pitkää viivaa `—` eikä ajatusviivaa `–`**, vaikka suomen oikeinkirjoitus muuten käyttäisi niitä. Rakenna
  uudelleen pilkulla, kaksoispisteellä, sulkeilla tai pisteellä. Välit yhdysmerkillä: `1945-1975`, `610-632`, `1-2 h`,
  `30-100 €/kk`. Väärin: `1h - 2h`, `610–632`.
- Ei `« »`, ei nollalevyistä välilyöntiä, ei sitovaa välilyöntiä (U+00A0), ei BOM:ia. Myös `10 000` ja `25 %`
  kirjoitetaan tavallisella välilyönnillä.
- Heittomerkki on suora `'` (U+0027): `Monet'ta`, ei `Monet’ta`.
- Välimerkin edessä ei ole välilyöntiä, kahta välilyöntiä peräkkäin ei ole. Pilkun, kaksoispisteen ja puolipisteen
  jälkeen tulee välilyönti, paitsi kaksoispiste-päätteessä (`YK:ssa`) ja kellonajassa (`02:59`).
- Pilkku jokaisen sivulauseen eteen (`että`, `joka`, `kun`, `koska`, `jotta`) ja sen jälkeen, jos päälause jatkuu.
- Yleisnimi pienellä virkkeen keskellä: `**Suuri laama**` → `**suuri lama**`, `**Muezzin**` → `**muezzin**`,
  `Romantiikka` → `romantiikka`, `renessanssi`, `impressionismi`; kuukaudet ja kansallisuudet pienellä.
- Yhdyssana kirjoitetaan yhteen: `Proosa runo` → `proosaruno`, `deflaatio politiikka` → `deflaatiopolitiikka`,
  `Tervetuloa tarjous` → `Tervetuliaistarjous`. Nimen tai lyhenteen kanssa yhdysmerkki: `Quraysh-heimo`,
  `Premium-tilaus`, `TikTok-esto`; monisanaisen nimen kanssa välilyönti ja yhdysmerkki: `New Deal -ohjelma`.
- Ei ranskan jäänteitä (`siècle`, `dans`, `l'`, `concierge`, `Le Déjeuner sur l'herbe`) eikä englannin (`Roaring
  Twenties`, `Black Tuesday`, `Genesis`), eikä rikkinäisiä merkkejä (`**10.24**.`, `ZZ…`). Se on konekäännöksen
  roskaa; kirjoita virke uudelleen.

## 8. Luvut, päivämäärät, mitat

- Tuhannet: tavallinen välilyönti (`3 000 maalausta`, `10 000 miestä`, `yli 1 000 arvostelua`, ei `1000+`). Vuosiluvut
  ilman välilyöntiä. Ei pistettä, ei pilkkua.
- Desimaalipilkku ja välilyönti ennen prosenttia ja yksikköä: `3,5 %`, `**25 %**`, `-70 % IKUISESTI`, `1-2 h`. Väärin:
  `-70% IKUISESTI`, `1h`.
- **Luvun jälkeen substantiivi on yksikön partitiivissa** (paitsi luku 1): `%d tietokilpailut` → `%d visaa`;
  `menetettyjä tunteja vuodessa` → `menetettyä tuntia vuodessa`; `oikeat vastaukset` → `oikeaa vastausta`; `enemmän
  kuin **3 000**-maalaukset` → `yli **3 000** maalausta`; `1 päivää ennen` → `päivää ennen`.
- **Vuosi**: `En 1857` → `Vuonna **1857**`; `Vers 630` → `noin vuonna **630**`; `dès 610` → `vuodesta **610**
  lähtien`; `jusqu'en 632` → `vuoteen **632** asti`. Väärin: `Julkaisussa 1857`, `Asiassa 1863`, `Alueella 1874`,
  `Mallissa 630`, `Teoksessa`, `Kirjassa`, `Elokuvassa 1947`, `**622**:ssa`, `624:ssä`, `610:lta`. Pääte ei koskaan
  tartu vuosilukuun; sana `vuonna` kantaa sijan.
- **Päivämäärä** proosassa: päivä järjestyslukuna ja kuukausi partitiivissa, ilman pilkkua: `**24.10.1929**, Wall
  Street romahtaa` → `**24. lokakuuta 1929** Wall Street romahtaa`; `**29**, "Black Tuesday"` → `**29. lokakuuta**,
  ”mustana tiistaina”`. Aikajanan tunnisteessa nominatiivi: `kesäkuu 1940`.
- Välit: `entre 1945 et 1975` → `vuosina 1945-1975`; `années 1850` → `1850-luvulla`; `du 13 mars au 7 mai 1954` → `13.
  maaliskuuta ja 7. toukokuuta 1954 välillä` (aikajanalla `13.3.-7.5.1954`).
- **Vuosisata** on aina `-luku` ilman siirtymää: `VIIe siècle` → `600-luku`, `600-luvulla` (vuodet 601-700); `XIXe
  siècle` → `1800-luvulla`; `XIVe-XVIe siècle` → `1300-1500-luvuilla`. Väärin: `700-luvulla` VII:stä (se on 700-luku
  eli VIIIe), `7. vuosisadalla`, `XVe`.
- Ajanlasku: `eKr.` ja `jKr.`: `noin 450 eKr.`, `622 jKr.`. Ei koskaan `av. J.-C.`. Hidžran vuosi: `Mitä Hegira
  tarkoittaa numerossa 622?` → `Mitä hidžra tarkoittaa vuonna 622?`
- Ikä ja kesto: `à 6 ans` → `6-vuotiaana` (`Isänsä orvoksi **6 katselukertaa**` → `Isänsä hän menetti
  **6-vuotiaana**`); `en 22 ans` → `22 vuodessa`; `dans 2 jours` → `2 päivän päästä`.
- Ei muunnoksia, metrijärjestelmä pysyy. `Mds`/`Md` → `miljardia`, `M` → `miljoonaa`, sanoin: `2,5 miljoonaa ihmistä`.
  Taso: `NIV. 3` → `TASO 3`; `120 XP:tä tasolle 5`.

## 9. Tarkistus

```bash
python scripts/check_course_translation.py --lang fi
python scripts/check_course_translation.py --lang fi course_102_*
```

Tarkistus raportoi kurssikohtaisesti: siirtynyt runko, rikkinäiset merkinnät, kirjausten määrä, rekisteröimättömät
avaimet, kappaleen loppuun pysäköidyt termit, kielletyt merkit (`— – « » ’ ‘`, U+00A0, U+200B, BOM), välilyönnit,
ranskan ja englannin jäänteet, vuotaneet merkit, roomalaiset vuosisadat ja lokalisoimattomat ajanlaskut. Puhdas ajo on
velvollisuus, ei ehdotus.

Tarkistus ei näe auditin toistuvia virheitä. Etsi ne käsin ja korjaa jokainen osuma:

```bash
grep -rnE '\b(Julkaisussa|Asiassa|Alueella|Mallissa|Teoksessa|Kirjassa|Elokuvassa) \**[0-9]{3,4}|[0-9]{3,4}\**:(ssa|ssä|lta|ltä|n)\b|(\]\]|\*\*):[a-zäö]+|\b(Haluamme|Elämme|Vaadimme|[Kk]utsumme|[Pp]uhumme|[Vv]oimme)\b|katselukert|\bSofia|tietokilpailu|tietovisa|oikeudenkäynti|\bsarja|\b(te|teidän|teille)\b|\\"' content/courses/fi/ ios/Sophia/Resources/Locales/*.fi.json android/app/src/main/assets/strings/fi.json
```

Lue sitten kappale ääneen: sinä-muoto, `se` asiasta, jokainen `[[...]]` kieliopillisesti paikallaan, jokainen vuosi
`vuonna`-sanan kanssa, jokaisen luvun jälkeen partitiivi, vuosisata ilman siirtymää.
