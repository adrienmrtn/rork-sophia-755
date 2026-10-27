# Prijevod tečajeva s francuskog na hrvatski

Francuski (`content/courses/fr/`) je izvor. Ovaj dokument je specifikacija za
`content/courses/hr/`, za kvizove, pojmovnik i sučelje. Daje se u cijelosti onome tko piše
prijevod, a `scripts/check_course_translation.py --lang hr` ga mehanički provodi. Nametnuta
terminologija živi u `content/terminology/` (`termes_produit.json`, `mots_pieges.json`,
`oeuvres.json`).

## 1. Što želimo

Ne predajemo prijevod. Predajemo **hrvatsko izdanje** tečaja: tekst koji bi hrvatski urednik
napisao iz istih bilježaka. Čitatelj ne smije naslutiti da je izvornik francuski.

Ovim redom:

1. **Točno.** Ne iskrivljuj, ne izmišljaj i ne ispuštaj činjenice.
2. **Tečno.** Idiomatski hrvatski. Naglas se čita bez zapinjanja.
3. **Jednostavno.** Kratke rečenice, svakodnevne riječi. Znatiželjan tinejdžer mora pratiti. Bolje
   „pokazao” nego „demonstrirao”.
4. **Vjerno obliku.** Otprilike isti broj rečenica, isti tijek misli, ista duljina uz dvadeset
   posto zazora, da prijelom ostane.

Registar: **standardni hrvatski, razgovorno topao**. Bez dijalekta, bez uredskog jezika, bez
srbizama: `točka`, `tisuća`, `stoljeće`, `povijest`, `razina`, nikad `tačka`, `hiljada`, `vek`,
`istorija`, `nivo`. Infinitiv, ne `da` + prezent: `moraš učiti`, ne `moraš da učiš`. `za ponoviti`
je germanizam: `treba ponoviti`.

**Obraćanje je uvijek „ti”, jednina, svuda**: tečaj, kviz, pojmovnik, sučelje. Nikad *Vi*, *vaš*,
*Provjerite*. Jedina iznimka je ustaljena formula `Dobro došli`.

**Rod korisnika.** Hrvatski nema srednji rod za osobu, a muški particip isključuje korisnice već
na prvom ekranu. Prvo preoblikuj bez participa (prezent, imperativ, imenica, pasiv); tek ako ne
ide, piši oba oblika (`spreman/spremna`).

| Pogrešno | Ispravno |
| --- | --- |
| Dobro došao u Sophiju | Dobro došli u Sophiju |
| Iskoristio si današnji besplatni tečaj. | Današnji besplatni tečaj je iskorišten. |
| JESI LI ZNAO? | ZNAŠ LI? |
| Već si pročitao | Već pročitano |
| Spreman sam | Krećem! |

Svjedočanstva žena pišu se u ženskom rodu, s potpisom po pravilu `Ime, 22 godine`: `Prošla sam
ispit`, `maturantica`. Lokaliziraj sadržaj, ne samo riječi: „+3 points” nema smisla u ljestvici od
1 do 5. `prosjek iz povijesti mi je ovaj polugodište porastao za 3 boda` → `prosjek iz povijesti
mi je ovo polugodište skočio za cijelu ocjenu`.

**Nazivi proizvoda**, jedan naziv svuda:

| Francuski | Hrvatski | Nikad |
| --- | --- | --- |
| cours | tečaj | lekcija, kurs |
| quiz | kviz | test, upitnik |
| parcours | staza (`Vođene staze`) | putanja, put, putovanje |
| collection | kolekcija | zbirka (osim zbirke pjesama) |
| niveau | razina (`Raz. 3`) | nivo, level |
| série | niz (`5 dana zaredom`) | serija |
| essai gratuit | besplatno probno razdoblje; gumb `Isprobaj {n} dana besplatno` | besplatna proba, `Pokreni {n} dana` |
| Premium, Sophia, XP | nepromjenjivo latinicom; `Sophiju`, `u Sophiji` | Sofija, Sophiu, Sophii, iskustveni bodovi |
| bloqueur | blokator | blocker |
| Entraînement / réviser | Vježbanje, `Vježbaj` / ponoviti, `Ponovi` | trening, revidirati |
| débloquer | otključati, `Otključaj` | odblokirati (samo za TikTok blokator) |
| glossaire | pojmovnik | rječnik |
| abonnement | pretplata (`Mjesečna`, `Godišnja`) | članarina |
| Bibliothèque | Knjižnica | biblioteka |
| matière / objectif / ami | predmet / cilj / prijatelj | materija / objektiv / pratitelj |
| téléphone / écran | mobitel / zaslon | telefon i ekran naizmjence |

Zamke iz sučelja: `Pas de connexion` je `Nema internetske veze`, nikad `Nema veze` („nije važno”).
`sans connexion` je `bez interneta`, nikad `bez veze` („bezveze”). `la personne la plus
intéressante de la pièce` je `najzanimljivija osoba u društvu`, ne `u prostoriji`. `Expire dans`
je `Istječe za`. `Léger` (ljestvica) je `Lagano`, `La lumière` (kviz) je `Svjetlost`. Gumb je
glagol, ne „za + imenica”: `PREVUCI ZA OTKRIVANJE` → `PREVUCI I OTKRIJ`. `Razina prođena` →
`Razina prijeđena`. `Gori ti 🔥` → `Goriš! 🔥`. Množina uz broj ima tri oblika (one/few/other): `%d
tečaj`, `%d tečaja`, `%d tečajeva`; `%d kviz`, `%d kviza`, `%d kvizova`.

Rečenice gradi iznova. Francuski veže duga razdoblja točkom sa zarezom i pripovijeda u prezentu.
Hrvatski podnosi povijesni prezent; zadrži ga ili prijeđi u perfekt, ali ne miješaj vremena u
istom odlomku. Svršeni prezent nije sadašnjost: `pročitaš lekciju da otključaš` → `prvo pročitaj
jedan tečaj`.

**Bezlično „on” nikad nije „mi”.** Hrvatski ima bezlično `se` ili
3. lice množine:

| Francuski | Pogrešno | Ispravno |
| --- | --- | --- |
| On veut le tuer. | Želimo ga ubiti. | Žele ga ubiti. |
| On y vit en tribus. | Tamo živimo u plemenima. | Ondje se živi u plemenima. |
| On exige un dessin précis. | Zahtijevamo precizan crtež. | Traži se precizan crtež. |
| ce qu'on appelle | ono što mi zovemo | ono što se naziva |

## 2. Kostur ostaje

Prevode se samo tekstualna polja. Ostalo alat kopira iz francuskog kostura i ne diraš: `id`,
`subject`, `subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Polje | Što je | Napomena |
| --- | --- | --- |
| `title` | Naslov kartice i heroja | Kratko. Ustaljeni hrvatski naslov djela, ako je tečaj o djelu. |
| `subtitle` | Redak ispod naslova | Godina ili raspon (`1945`, `1945-1975`) ostaje točno takav. |
| `description` | Blurb od dvije rečenice | Stoji sam za sebe. |
| `hero.hook` | Jedna rečenica mamac | Reklama, ne proza. |
| `sections[].title` | Naslov odjeljka | Imenska skupina, bez točke na kraju. |
| `paragraph.text` | Vezani tekst | Glavni posao. |
| `image.caption` | Potpis slike | Kratko; točka samo uz cijelu rečenicu. |
| `funFact.text` | Okvir | Lagano, razgovorno. |
| `takeaway.text` | Zaključak | Ono što treba ostati. |
| `quote.text` | Citat | Vidi §6. |
| `quote.attribution` | Tko je rekao | Vidi §6. |
| `timeline.events[].date` | `1789.`, `lipanj 1940.`, `oko 450. pr. Kr.` | Brojke ostaju, mjeseci se prevode, `pr. Kr.` / `po. Kr.`, nikad `av. J.-C.`. |
| `timeline.events[].title` | Oznaka | Vrlo kratko, bez točke. |
| `timeline.events[].detail` | Jedna rečenica | |

## 3. Oznake u retku

Tri oznake moraju preživjeti:

- `**podebljano**`: datumi, brojke, imena i ona djela o kojima odlomak govori.
- `*kurziv*`: naslov djela u prozi.
- `[[pojam]]`: natuknica pojmovnika. Dodir otvara definiciju.

Pravila:

- Oznake idu u parovima. Neparan broj `**` je greška.
- Nijedna oznaka ne guta razmak ni interpunkciju: `**1945**,` je ispravno, `**1945,**` i `** 1945
  **` nisu.
- **Podebljani dio ne završava točkom** (provjera to javlja). Redna točka godine zato ne smije
  biti zadnji znak: `**1857. godine**` ili, na kraju rečenice, `objavljuje ih **1857**.`, nikad
  `**1857.**`. Isto vrijedi za eru: `**450. godine** pr. Kr.`
- Podebljava se hrvatski ekvivalent, ne isti znakovi: francusko `**30 000 mots**` postaje
  `**30.000 riječi**`.
- Ime u podebljanom dijelu se sklanja, cijeli oblik ide unutra: `okuplja **Moneta**, **Renoira**,
  **Pissarra**, **Degasa**`, ne `okuplja **Monet**, **Renoir**`. Nikad nastavak s crticom:
  `**Claudea Moneta**`, ne `**Claudea Moneta**-a`; `Edgara Allana Poea`, ne `Edgar Allana Poe-a`.
- Ne dodaji podebljanje kojeg u francuskom nema. Ne podebljavaj cijelu rečenicu.

## 4. Natuknice pojmovnika: najvažnije pravilo

Svako francusko `[[...]]` postaje točno jedno hrvatsko `[[...]]`, **u rečenici, na istom mjestu u
argumentu**.

Nikad ne parkiraj pojam na kraj odlomka. Nikad ne ostavljaj rupu. To je ista greška, i ovaj vodič
postoji da je spriječi:

> Pogrešno: `oslabljen prije svega od : kršćanski križari opljačkali su grad. [[Osvajanje
> Carigrada]]`

> Ispravno: `oslabljen prije svega jednim događajem: [[Osvajanje Carigrada u Četvrtom križarskom
> ratu (1204.)]], kad su zapadni križari opljačkali grad.`

Tekst pojma nije slobodan. Mora biti ključ registriran za taj tečaj u
`ios/Sophia/Resources/Locales/glossary.hr.json`. Neregistriran ključ ostaje mrtav tekst. Sažetak
iz `scripts/make_translation_briefs.py` navodi dopuštene ključeve; upotrijebi jedan znak po znak,
s velikim slovima. Neki ključ postoji u dva oblika (`Službeni pariški salon` / `službeni pariški
salon`, `Džihad` / `džihad`); biraj među njima.

Rečenica mora ostati gramatična **s umetnutim ključem**, a tu hrvatski s padežima zapinje:

- Ključ je u registriranom obliku, gotovo uvijek nominativu. **Ne sklanjaj ga i ne izmišljaj
  sklonjeni ključ** (`[[Službenog pariškog salona]]` nije registriran). Ne lijepi nastavak iza
  `]]`: `[[Kalif]]a` je greška.
- Stavi ključ na mjesto nominativa: kao subjekt, ili kao apoziciju uz imenicu koja se sklanja
  (`djelo`, `pokret`, `naslov`, `pojam`).

| Pogrešno | Ispravno |
| --- | --- |
| umornih od [[Službeni pariški salon]] | umornih od pravila koja nameće [[Službeni pariški salon]] |
| pripovijeda u svom [[Metamorfoze]] | pripovijeda u djelu [[Metamorfoze]] |
| Vlast tada prelazi na [[Kalif]], njegove nasljednike. | Vlast tada preuzimaju njegovi nasljednici, koji nose naslov [[Kalif]]. |

- Pazi na doseg prijedloga. `bez borbe i općeg pomilovanja` znači da pomilovanja nije bilo;
  francuski kaže suprotno: `Predaja bez borbe i opći oprost.`
- Ne počinji rečenicu ključem s malim slovom (`[[beduini]], pustinjski nomadi`). Uzmi registrirani
  oblik s velikim slovom ili preoblikuj: `Arapi su tada uglavnom [[beduini]], pustinjski nomadi.`
- Natuknica ne smije nestati u prijevodu: `pokreće napade, brze napade` izgubio je `[[razzias]]` i
  stvorio tautologiju.
- Ako je registrirani ključ u neprilagođenom obliku (`razzias`, `Dhimma`, `Nemesis`), u `[[...]]`
  ga piši točno takvog, a prijavi ga: ključ se ispravlja u `glossary.hr.json` (`razija`, `zimma`,
  `Nemeza`), pa tek onda tekst. U prozi izvan zagrada uvijek prilagođeni oblik.

## 5. Vlastita imena

Strojni prijevod čita prezimena i imena bogova kao opće imenice. Tvrda pravila:

**Nikad ne prevodi osobno ime.** Pan ostaje Pan, ne „Prasak”. Munch ostaje Munch. Degas ostaje
Degas. Strano ime piše se izvorno i sklanja po hrvatskim pravilima: `Moneta`, `generalom
Aupickom`, `kod Badra`, `u Kabu`.

**Ustaljeni hrvatski oblik**, ako postoji, i to dosljedno u cijelom tečaju: `Muhamed` (nikad
naizmjence `Muhammed`), `Abu Bakr`, `Omar`, `Meka`, `Medina`, `Kaba`, `Narcis`, `Eho` (ne `Odjek`,
ne `Echo`), `Tirezija`, `Nemeza`, `Ovidije`, `kralj Artur`, `kraljica Guinevere`, `Christophe
Colomb` → `Kristofor Kolumbo`, `Charlemagne` → `Karlo Veliki`, `Guillaume le Conquérant` → `Vilim
Osvajač`, `Londres` → `London`, `Pékin` → `Peking`, `Aix-la-Chapelle` → `Aachen`, `Tchernobyl` →
`Černobil`, `Michel-Ange` → `Michelangelo`. Kratice: `ONU` → `UN`, `OTAN` → `NATO`; `OTAN` ostaje
samo kad tekst izrijekom navodi francuski naziv (`NATO na engleskom i OTAN na francuskom`).

**Arapski i islamski pojmovi** u prilagođenom hrvatskom obliku: `hidžra` (malim slovom;
`hidžretska godina`), `razija`, `džizja`, `kalif`, `zimma`, `umma`. Množina po hrvatskim
pravilima: `kalifi`, `razije`; nikad francuska množina ni engleska transliteracija (`Hegira`,
`jizya`, `calife`).

**Rod likova** prati lik, ne francusku riječ: Eho je ona (`Eho, osuđena da bude samo glas`,
`njezino tijelo`, `vjerna`), Narcis je on (`Njegova ljepota privlači sve`). NATO je savez, muški
rod (`nestanak njegova protivnika`). *Cvjetovi zla* su množina (`Cvjetovi zla najprije
sablažnjavaju`), knjiga je ženskog roda (`Osuđena je`). Pazi na povratnu zamjenicu: `Tirezija
upozorio je svoju majku` govori o Tirezijinoj majci; ispravno je `njegovu majku`.

**Naslovi djela nose ustaljeni hrvatski naslov**, ne kalk. Puni popis je u
`content/terminology/oeuvres.json`:

| Francuski | Hrvatski |
| --- | --- |
| *Impression, soleil levant* | *Impresija, izlazak sunca* |
| *Le Déjeuner sur l'herbe* | *Doručak na travi* |
| *Les Demoiselles d'Avignon* | *Gospođice iz Avignona* |
| *Les Fleurs du Mal* | *Cvjetovi zla* |
| *Le Spleen de Paris* | *Pariški spleen* |
| *Correspondances* / *Recueillement* | *Suglasja* / *Sabranost* |
| *La Ferme des animaux* | *Životinjska farma* |
| *1984* | *1984.* |
| *Le Rouge et le Noir* | *Crveno i crno* |
| *À la recherche du temps perdu* | *U potrazi za izgubljenim vremenom* |
| *Les Misérables* | *Jadnici* |
| *Le Petit Prince* | *Mali princ* |
| *L'Étranger* / *Le Procès* | *Stranac* / *Proces* |
| *Le Cri* / *La Joconde* | *Krik* / *Mona Lisa* |

Jedno djelo, jedan naslov: pjesma *Correspondances* ne smije biti `Dopisivanje`, `Korespondencije`
i `Prepisivanja` u istom tečaju. Naslov se u rečenici sklanja (`objavljuje *Cvjetove zla*`) ili
stoji uz imenicu u nominativu (`u romanu *Jadnici*`). Ako ustaljenog hrvatskog naslova nema,
ostavi izvornik i pri prvom spomenu objasni.

**Riječi s dva značenja.** Nikad ne uzimaj najčešći engleski smisao:

| Francuski | Pogrešno | Ispravno |
| --- | --- | --- |
| spleen | slezena | spleen (`Spleen i ideal`) |
| l'idéal | idealno | ideal |
| flâneur | dječja kolica | flâneur, šetač koji promatra grad |
| touche (de pinceau) | dodir | potez (kista) |
| lumière | lagan | svjetlost |
| costume | kostim | odijelo |
| beau-père (Aupick) | tast | očuh |
| incarne | glumi | utjelovljuje |
| postérité | potomstvo | naslijeđe |
| peindre dehors | slikanje izvana | slikanje na otvorenom |
| l'Antiquité se referme | antika se približava | antika se zatvara |
| motif / sujet | uzorak / subjekt | motiv / tema |
| condamnation | uvjerenje | osuda |
| Grande Dépression | velika depresija (bolest) | Velika depresija |
| soupe populaire / pétrole | juha / ulje | pučka kuhinja / nafta |

Registar je u `scripts/proper_nouns.json` i u `content/terminology/`. Tamo ga upiši; ne ispravljaj
isto ime dvaput.

## 6. Citati

Citat nije prevoditeljska vježba. Ako postoji kanonska hrvatska formulacija, koristi nju. Inače
prevedi kratko i čisto.

- Navodnici su `„ ”` (U+201E i U+201D). Nikad engleski `“ ”`, nikad ravni `" "`, nikad francuski
  `« »`. Sučelje ih već piše ispravno, tečajevi ne: `zbog “vrijeđanja javnog morala”` → `zbog
  „vrijeđanja javnog morala”`.
- Točka citirane rečenice ide unutar zatvarajućeg navodnika: `„Sve su životinje jednake.”`
- Citat u citatu izbjegni preoblikovanjem; `‘ ’` su zabranjeni.
- Jeka mora biti jeka: `„Ima li koga?” Ona odgovara: „Koga!”`, ne `„Netko!”`.
- `quote.attribution` je `Autor, Djelo`. Ako francuski daje govornika iza crte, zareza ili u
  zagradi: `Victor Hugo, Jadnici (biskup Bienvenu)`.

Kanonski citat iz *Životinjske farme*: `„Sve su životinje jednake, ali neke su životinje jednakije
od drugih.”`

## 7. Interpunkcija i tipografija

Mehanička provjera, bez iznimaka.

- **Nema duge crte `—` ni srednje `–`.** Preoblikuj zarezom, dvotočkom, zagradom ili točkom.
  Rasponi spojnicom: `1945-1975`, `601.-700.`. `Uvreda jednog kritičara — i pokret dobiva ime` →
  `Kritičar se naruga, a prvi veliki pokret moderne umjetnosti dobiva ime.`
- Nema `« »`, nema znaka nulte širine, nema neprelomivog razmaka, nema `‘` ni `’`.
- Apostrof je ravni `'` (U+0027), kao u francuskim datotekama: `Musée d'Orsay`.
- Nikad razmak ispred `, . ; : ! ?`. Nikad dva razmaka zaredom. Uvijek razmak iza točke.
- Prijedlog ili `te` ne stoje ispred interpunkcije (`od ,`, `za .`, `te,`): to je rupa iza
  obrisanog pojma.
- Razmak iza dvotočke i točke sa zarezom; oboje rijetko, hrvatski udžbenički tekst voli točku.
- Nema francuskih ostataka. `siècle`, `dans`, `l'`, `d'un` u hrvatskom odlomku su greška, kao i
  nepreveden francuski toponim.

## 8. Brojevi, datumi, mjere

- Tisuće: točka. `30 000` → `30.000`. Nikad razmak, nikad zarez.
- Decimale: zarez. `3,5 %` → `3,5%`. Bez razmaka ispred `%`.
- **Godina** ima rednu točku i riječ `godine`; francusko `En 1857` nikad nije `U 1857`:

| Francuski | Pogrešno | Ispravno |
| --- | --- | --- |
| En **622**, un marchand… | U **622**, trgovac… | **622. godine** trgovac iz Meke… |
| En **1857**, Baudelaire publie… | U **1857**, Baudelaire je objavio… | **1857. godine** Baudelaire objavljuje… |
| En avril **1874**… | U travnju je **1874**… | U travnju **1874. godine**… |
| vers 630 | u 630 | oko 630. godine |

Bez podebljanja u izvorniku dobro je i `Godine 622.` na početku rečenice; s podebljanjem vrijedi
§3, nikad `**622.**`.
- Puni datum: `24. veljače 2022.`, mjesec malim slovom u genitivu (`siječnja`, `veljače`,
  `ožujka`, `travnja`, `svibnja`, `lipnja`, `srpnja`, `kolovoza`, `rujna`, `listopada`,
  `studenoga`, `prosinca`). Jedna shema po tečaju.
- **Stoljeća** arapskim brojem s točkom: `VIIe siècle` → `7. stoljeće`, `u 7. stoljeću`, kratica
  `7. st.`. Nikad `VIIe`, nikad `700-te`. `7. stoljeće` je `601.-700.`.
- Era: `pr. Kr.` i `po. Kr.`: `450. pr. Kr.`, `622. po. Kr.` (s običnim razmakom).
- **Padež iza broja**: 1 (21, 31…) traži jedninu, 2-4 (22, 23, 24…) genitiv jednine, 5-20 i
  okrugli brojevi genitiv množine: `1 tečaj`, `3 kviza`, `5 tečajeva`, `Camille, 22 godine`, `u 22
  godine`, `sa šest godina`, `šest osuđenih pjesama`, `10.000 hommes` → `10.000 vojnika`.
  Nebrojive imenice se ne broje: `Pronađena su dva napretka` → `Pronađene su dvije verzije
  napretka`.
- Bez preračunavanja. Metričko ostaje metričko.
- `Mds`/`Md` → `milijarde` / `milijardi`, `M` → `milijuna`, riječima (`3 milijuna`, ne `3
  miliona`).

## 9. Provjera

```bash
python scripts/check_course_translation.py --lang hr
python scripts/check_course_translation.py --lang hr course_100_*
```

Provjera javlja po tečaju: pomaknut kostur, rasparene oznake, broj natuknica, neregistrirane
ključeve, pojmove parkirane na kraju odlomka, zabranjene znakove (`—`, `–`, `« »`, `’`, `‘`,
neprelomivi razmak), razmake, prijedloge ispred interpunkcije, točku na kraju podebljanog dijela,
francuske ostatke, tisuće s razmakom (`30.000`), francuska stoljeća (`15. stoljeće`) i eru (`pr.
Kr.` / `po. Kr.`). Čist prolaz je obveza, ne prijedlog.

Provjera ne vidi gramatiku. Prije predaje pročitaj tekst naglas i pretraži ono što je revizija
našla u stotinama rečenica:

```bash
grep -nE '\b[Uu] \*{0,2}[0-9]{3,4}' content/courses/hr/*.json      # U 1857
grep -nE '\b(Želimo|živimo|Zahtijevamo|mi zovemo)\b' content/courses/hr/*.json
grep -nE '“|\\"|\]\][a-zčćšž]' content/courses/hr/*.json        # navodnici, nastavak iza ]]
grep -nE '\b(slezen|dječja kolica|tast|kostim|potomstv|Prasak)' content/courses/hr/*.json
```

Svaki pogodak je ili ispravljen ili opravdan. Rod korisnika, rod likova i padež oko `**…**` i
`[[…]]` provjeravaš čitanjem.
