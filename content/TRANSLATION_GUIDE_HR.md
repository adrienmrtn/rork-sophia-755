# Prijevod tečajeva s francuskog na hrvatski

Francuski (`content/courses/fr/`) je izvor. Ovaj dokument je specifikacija za `content/courses/hr/`, za kvizove,
pojmovnik i sučelje. Daje se u cijelosti onome tko piše prijevod, a
`scripts/check_course_translation.py --lang hr` ga mehanički provodi. Nametnuta terminologija je u
`content/terminology/` (`termes_produit.json`, `mots_pieges.json`, `oeuvres.json`).

## 1. Što želimo

Ne predajemo prijevod. Predajemo **hrvatsko izdanje** tečaja: tekst koji bi hrvatski urednik napisao iz istih
bilježaka. Čitatelj ne smije naslutiti da je izvornik francuski. Ovim redom:

1. **Točno.** Ne iskrivljuj, ne izmišljaj i ne ispuštaj činjenice.
2. **Tečno.** Idiomatski hrvatski. Naglas se čita bez zapinjanja.
3. **Jednostavno.** Kratke rečenice, svakodnevne riječi. Znatiželjan tinejdžer mora pratiti. Bolje „pokazao”
   nego „demonstrirao”.
4. **Vjerno obliku.** Otprilike isti broj rečenica, isti tijek misli, ista duljina uz dvadeset posto zazora, da
   prijelom ostane.

Registar: **standardni hrvatski, razgovorno topao**. Bez dijalekta, bez uredskog jezika, bez srbizama: `točka`,
`tisuća`, `stoljeće`, `povijest`, `razina`, nikad `tačka`, `hiljada`, `vek`, `istorija`, `nivo`. Infinitiv, ne
`da` + prezent: `moraš učiti`, ne `moraš da učiš`; `za ponoviti` je germanizam (`treba ponoviti`). Francuski
pripovijeda u prezentu; povijesni prezent je u hrvatskom prirodan, ali ne miješaj ga s perfektom u istom
odlomku. Svršeni prezent nije sadašnjost: `pročitaš lekciju da otključaš` → `prvo pročitaj jedan tečaj`.

**Obraćanje je uvijek „ti”, jednina, svuda**: tečaj, kviz, pojmovnik, sučelje. Nikad *Vi*, *vaš*, *Provjerite*.
Jedina iznimka je ustaljena formula `Dobro došli`.

**Rod korisnika.** Muški particip isključuje korisnice već na prvom ekranu. Prvo preoblikuj bez participa
(prezent, imperativ, imenica, pasiv); tek ako ne ide, oba oblika (`spreman/spremna`). `Dobro došao u Sophiju` →
`Dobro došli u Sophiju`; `Iskoristio si današnji besplatni tečaj.` → `Današnji besplatni tečaj je iskorišten.`;
`JESI LI ZNAO?` → `ZNAŠ LI?`; `Spreman sam` → `Krećem!`. Svjedočanstva žena su u ženskom rodu
(`Prošla sam ispit`, `maturantica`), potpis `Camille, 22 godine`. Lokaliziraj i sadržaj: „+3 points” nema smisla
u ljestvici od 1 do 5, pa `ovaj polugodište porastao za 3 boda` → `ovo polugodište skočio za cijelu ocjenu`.

**Bezlično „on” nikad nije „mi”.** Hrvatski ima bezlično `se` ili 3. lice množine:

| Francuski | Pogrešno | Ispravno |
| --- | --- | --- |
| On veut le tuer. | Želimo ga ubiti. | Žele ga ubiti. |
| On y vit en tribus. | Tamo živimo u plemenima. | Ondje se živi u plemenima. |
| On exige un dessin précis. | Zahtijevamo precizan crtež. | Traži se precizan crtež. |
| ce qu'on appelle | ono što mi zovemo | ono što se naziva |

**Nazivi proizvoda**, jedan naziv svuda:

| Francuski | Hrvatski | Nikad |
| --- | --- | --- |
| cours / quiz / collection / parcours | tečaj / kviz / kolekcija / staza (`Vođene staze`) | lekcija, kurs / test / zbirka / putanja, put |
| niveau / série | razina (`Raz. 3`) / niz (`5 dana zaredom`) | nivo, level / serija |
| essai gratuit | besplatno probno razdoblje; gumb `Isprobaj {n} dana besplatno` | besplatna proba, `Pokreni {n} dana` |
| Premium, Sophia, XP | latinicom; `Sophiju`, `u Sophiji` | Sofija, Sophiu, Sophii, iskustveni bodovi |
| bloqueur / débloquer | blokator / otključati, `Otključaj` | blocker / odblokirati |
| Entraînement / réviser | Vježbanje, `Vježbaj` / ponoviti, `Ponovi` | trening / revidirati |
| glossaire / Bibliothèque / abonnement | pojmovnik / Knjižnica / pretplata (`Mjesečna`) | rječnik / biblioteka / članarina |
| matière / objectif / ami / téléphone / écran | predmet / cilj / prijatelj / mobitel / zaslon | materija / objektiv / pratitelj / telefon / ekran |

Zamke u sučelju: `Pas de connexion` je `Nema internetske veze`, nikad `Nema veze` („nije važno”);
`sans connexion` je `bez interneta`, nikad `bez veze`. `de la pièce` je `u društvu`, ne `u prostoriji`.
`Expire dans` je `Istječe za`; `Léger` je `Lagano`, `La lumière` je `Svjetlost`. Gumb je glagol:
`PREVUCI ZA OTKRIVANJE` → `PREVUCI I OTKRIJ`. `Razina prođena` → `Razina prijeđena`, `Gori ti 🔥` → `Goriš! 🔥`.
Uz `%d` tri oblika: `%d tečaj`, `%d tečaja`, `%d tečajeva`.

## 2. Kostur ostaje

Prevode se samo tekstualna polja. Ostalo alat kopira iz francuskog kostura i ne diraš: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

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
| `timeline.events[].date` | `1789.`, `lipanj 1940.`, `oko 450. pr. Kr.` | Brojke ostaju, mjeseci se prevode. `pr. Kr.` / `po. Kr.`, nikad `av. J.-C.`. |
| `timeline.events[].title` | Oznaka | Vrlo kratko, bez točke. |
| `timeline.events[].detail` | Jedna rečenica | |

## 3. Oznake u retku

Tri oznake moraju preživjeti:

- `**podebljano**`: datumi, brojke, imena i djela o kojima odlomak govori.
- `*kurziv*`: naslov djela u prozi.
- `[[pojam]]`: natuknica pojmovnika. Dodir otvara definiciju.

Pravila:

- Oznake idu u parovima. Neparan broj `**` je greška.
- Nijedna oznaka ne guta razmak ni interpunkciju: `**1945**,` je ispravno, `**1945,**` i `** 1945 **` nisu.
- **Podebljani dio ne završava točkom** (provjera to javlja). Redna točka godine ne smije biti zadnji znak:
  `**1857. godine**`, ili na kraju rečenice `objavljuje ih **1857**.`, nikad `**1857.**`. Isto za eru:
  `**450. godine** pr. Kr.`
- Podebljava se hrvatski ekvivalent: `**30 000 mots**` postaje `**30.000 riječi**`.
- Ime u podebljanom dijelu se sklanja, cijeli oblik je unutra: `okuplja **Monet**, **Renoir**` →
  `okuplja **Moneta**, **Renoira**, **Pissarra**, **Degasa**`. Nikad nastavak s crticom: `**Claudea Moneta**`,
  ne `**Claudea Moneta**-a`; `Edgara Allana Poea`, ne `Edgar Allana Poe-a`.
- Ne dodaji podebljanje kojeg u francuskom nema. Ne podebljavaj cijelu rečenicu.

## 4. Natuknice pojmovnika: najvažnije pravilo

Svako francusko `[[...]]` postaje točno jedno hrvatsko `[[...]]`, **u rečenici, na istom mjestu u argumentu**.
Nikad ne parkiraj pojam na kraj odlomka. Nikad ne ostavljaj rupu. To je ista greška:

> Pogrešno: `oslabljen prije svega od : kršćanski križari opljačkali su grad. [[Osvajanje Carigrada]]`

> Ispravno: `oslabljen prije svega jednim događajem: [[Osvajanje Carigrada u Četvrtom križarskom ratu
> (1204.)]], kad su zapadni križari opljačkali grad.`

Tekst pojma nije slobodan. Mora biti ključ registriran za taj tečaj u
`ios/Sophia/Resources/Locales/glossary.hr.json`; neregistriran ključ ostaje mrtav tekst. Sažetak iz
`scripts/make_translation_briefs.py` navodi dopuštene ključeve; upotrijebi jedan znak po znak, s velikim
slovima. Neki ključ postoji u dva oblika (`Službeni pariški salon` / `službeni pariški salon`); biraj među
njima.

Rečenica mora ostati gramatična **s umetnutim ključem**, a tu hrvatski s padežima zapinje:

- Ključ je u registriranom obliku, gotovo uvijek nominativu. **Ne sklanjaj ga i ne izmišljaj sklonjeni ključ**
  (`[[Službenog pariškog salona]]` nije registriran). Ne lijepi nastavak iza `]]`: `[[Kalif]]a` je greška.
- Stavi ključ na mjesto nominativa: kao subjekt ili kao apoziciju uz imenicu koja se sklanja (`djelo`, `pokret`,
  `naslov`, `pojam`). Ako ne sjeda, preoblikuj rečenicu; ključ ne diraj.

| Pogrešno | Ispravno |
| --- | --- |
| umornih od [[Službeni pariški salon]] | umornih od pravila koja nameće [[Službeni pariški salon]] |
| pripovijeda u svom [[Metamorfoze]] | pripovijeda u djelu [[Metamorfoze]] |
| Vlast tada prelazi na [[Kalif]], njegove nasljednike. | Vlast preuzimaju njegovi nasljednici, koji nose naslov [[Kalif]]. |

- Pazi na doseg prijedloga: `Predaja bez borbe i općeg pomilovanja` kaže da pomilovanja nije bilo. Francuski
  kaže suprotno: `Predaja bez borbe i opći oprost.`
- Ne počinji rečenicu ključem s malim slovom (`[[beduini]], pustinjski nomadi`):
  `Arapi su tada uglavnom [[beduini]], pustinjski nomadi.`
- Natuknica ne smije nestati: `pokreće napade, brze napade` izgubio je `[[razzias]]`.
- Ako je registrirani ključ neprilagođen (`razzias`, `Dhimma`, `Nemesis`), u `[[...]]` ga piši točno takvog i
  prijavi ga; ključ se ispravlja u `glossary.hr.json` (`razija`, `zimma`, `Nemeza`). U prozi izvan zagrada
  uvijek prilagođeni oblik.

## 5. Vlastita imena

Strojni prijevod čita prezimena i imena bogova kao opće imenice. Tvrda pravila:

**Nikad ne prevodi osobno ime.** Pan ostaje Pan, ne „Prasak”. Munch ostaje Munch. Strano ime piše se izvorno i
sklanja po hrvatskim pravilima: `Moneta`, `generalom Aupickom`, `kod Badra`, `u Kabu`.

**Ustaljeni hrvatski oblik**, dosljedno u cijelom tečaju: `Muhamed` (ne naizmjence `Muhammed`), `Abu Bakr`,
`Omar`, `Meka`, `Medina`, `Narcis`, `Eho` (ne `Odjek`, ne `Echo`), `Tirezija`, `Nemeza`, `Ovidije`,
`kralj Artur`, `kraljica Guinevere`, `Christophe Colomb` → `Kristofor Kolumbo`, `Charlemagne` → `Karlo Veliki`,
`Pékin` → `Peking`, `Aix-la-Chapelle` → `Aachen`. `ONU` → `UN`, `OTAN` → `NATO`; `OTAN` ostaje samo kad tekst
navodi francuski naziv (`NATO na engleskom i OTAN na francuskom`).

**Arapski i islamski pojmovi** u prilagođenom obliku: `hidžra` (malim slovom; `hidžretska godina`), `razija`,
`džizja`, `kalif`, `zimma`, `umma`, množina po hrvatskim pravilima (`kalifi`, `razije`). Nikad `Hegira`,
`jizya`, `calife` ni francuska množina.

**Rod likova** prati lik, ne francusku riječ: Eho je ona (`Eho, osuđena da bude samo glas`, `njezino tijelo`,
`vjerna`), Narcis je on (`Njegova ljepota privlači sve`). NATO je savez, muški rod
(`nestanak njegova protivnika`). *Cvjetovi zla* su množina (`Cvjetovi zla najprije sablažnjavaju`), knjiga je
ženskog roda (`Osuđena je`). Pazi na povratnu zamjenicu: `Tirezija upozorio je svoju majku` govori o Tirezijinoj
majci; ispravno je `njegovu majku`.

**Naslovi djela nose ustaljeni hrvatski naslov**, ne kalk (puni popis u `oeuvres.json`): *Impression, soleil
levant* → *Impresija, izlazak sunca*, *Le Déjeuner sur l'herbe* → *Doručak na travi*, *Les Fleurs du Mal* →
*Cvjetovi zla*, *Le Spleen de Paris* → *Pariški spleen*, *Correspondances* → *Suglasja*, *Recueillement* →
*Sabranost*, *La Ferme des animaux* → *Životinjska farma*, *1984* → *1984.*, *Les Misérables* → *Jadnici*, *Le
Petit Prince* → *Mali princ*, *Les Demoiselles d'Avignon* → *Gospođice iz Avignona*, *Le Procès* → *Proces*.
Jedno djelo, jedan naslov: *Correspondances* ne smije biti `Dopisivanje`, `Korespondencije` i `Prepisivanja` u
istom tečaju. Naslov se sklanja (`objavljuje *Cvjetove zla*`) ili stoji uz imenicu u nominativu
(`u romanu *Jadnici*`). Bez ustaljenog naslova ostavi izvornik i objasni ga.

**Riječi s dva značenja.** Nikad ne uzimaj najčešći engleski smisao. `spleen` je spleen, ne `slezena`; `l'idéal`
je `ideal`, ne `idealno`; `flâneur` je flâneur, ne `dječja kolica`; `touche` je `potez (kista)`, ne `dodir`;
`lumière` je `svjetlost`, ne `lagan`; `costume` je `odijelo`, ne `kostim`; `beau-père` (Aupick) je `očuh`, ne
`tast`; `incarne` je `utjelovljuje`, ne `glumi`; `postérité` je `naslijeđe`, ne `potomstvo`; `peindre dehors` je
`slikanje na otvorenom`, ne `izvana`; `l'Antiquité se referme` je `antika se zatvara`, ne `približava`; `motif`
je `motiv`, ne `uzorak`; `condamnation` je `osuda`; `soupe populaire` je `pučka kuhinja`; `pétrole` je `nafta`.
Registar je u `scripts/proper_nouns.json`: tamo ga upiši, ne ispravljaj isto ime dvaput.

## 6. Citati

Citat nije prevoditeljska vježba. Ako postoji kanonska hrvatska formulacija, koristi nju. Inače prevedi kratko i
čisto.

- Navodnici su `„ ”` (U+201E i U+201D). Nikad engleski `“ ”`, ravni `" "` ni francuski `« »`:
  `zbog “vrijeđanja javnog morala”` → `zbog „vrijeđanja javnog morala”`.
- Točka citirane rečenice ide unutar zatvarajućeg navodnika: `„Sve su životinje jednake.”` Citat u citatu
  izbjegni preoblikovanjem; `‘ ’` su zabranjeni.
- Jeka mora biti jeka: `„Ima li koga?” Ona odgovara: „Koga!”`, ne `„Netko!”`.
- `quote.attribution` je `Autor, Djelo`. Ako francuski daje govornika iza crte, zareza ili u zagradi:
  `Victor Hugo, Jadnici (biskup Bienvenu)`.
- Kanonski citat iz *Životinjske farme*:
  `„Sve su životinje jednake, ali neke su životinje jednakije od drugih.”`

## 7. Interpunkcija i tipografija

Mehanička provjera, bez iznimaka.

- **Nema duge crte `—` ni srednje `–`.** Preoblikuj zarezom, dvotočkom, zagradom ili točkom. Rasponi spojnicom:
  `1945-1975`, `601.-700.`. `Uvreda jednog kritičara — i pokret dobiva ime` →
  `Kritičar se naruga, a prvi veliki pokret moderne umjetnosti dobiva ime.`
- Nema `« »`, znaka nulte širine, neprelomivog razmaka, `‘` ni `’`. Apostrof je ravni `'` (U+0027), kao u
  francuskim datotekama: `Musée d'Orsay`.
- Nikad razmak ispred `, . ; : ! ?`, nikad dva razmaka zaredom, uvijek razmak iza točke. Prijedlog ili `te`
  ispred interpunkcije (`od ,`, `te,`) je rupa iza obrisanog pojma.
- Dvotočku i točku sa zarezom rabi rijetko; hrvatski udžbenički tekst voli točku.
- Nema francuskih ostataka: `siècle`, `dans`, `l'`, `d'un` ili nepreveden francuski toponim u hrvatskom odlomku
  su greška.

## 8. Brojevi, datumi, mjere

- Tisuće: točka. `30 000` → `30.000`. Nikad razmak, nikad zarez.
- Decimale: zarez. `3,5 %` → `3,5%`. Bez razmaka ispred `%`.
- **Godina** ima rednu točku i riječ `godine`; `En 1857` nikad nije `U 1857`. Bez podebljanja dobro je i
  `Godine 622.` na početku rečenice; s podebljanjem vrijedi §3.

| Francuski | Pogrešno | Ispravno |
| --- | --- | --- |
| En **622**, un marchand… | U **622**, trgovac… | **622. godine** trgovac iz Meke… |
| En **1857**, Baudelaire publie… | U **1857**, Baudelaire je objavio… | **1857. godine** Baudelaire objavljuje… |
| En avril **1874**… | U travnju je **1874**… | U travnju **1874. godine**… |
| vers 630 | u 630 | oko 630. godine |

- Puni datum: `24. veljače 2022.`, mjesec malim slovom, u genitivu, hrvatskim imenom (`ožujka`, `studenoga`,
  nikad `marta`, `novembra`). Jedna shema po tečaju.
- **Stoljeća** arapskim brojem s točkom: `VIIe siècle` → `7. stoljeće`, `u 7. stoljeću`, `7. st.` Nikad `VIIe`,
  nikad `700-te`: `7. stoljeće` je `601.-700.`.
- Era: `pr. Kr.` i `po. Kr.` s običnim razmakom: `450. pr. Kr.`, `622. po. Kr.`
- **Padež iza broja**: 1 (21, 31…) jednina, 2-4 genitiv jednine, 5-20 genitiv množine: `1 tečaj`, `3 kviza`,
  `5 tečajeva`, `Camille, 22 godine`, `sa šest godina`, `šest osuđenih pjesama`, `10 000 hommes` →
  `10.000 vojnika`. Nebrojivo se ne broji: `Pronađena su dva napretka` → `Pronađene su dvije verzije napretka`.
- Bez preračunavanja. `Mds`/`Md` → `milijarde`/`milijardi`, `M` → `milijuna`, riječima (`3 milijuna`, ne
  `3 miliona`).

## 9. Provjera

```bash
python scripts/check_course_translation.py --lang hr
python scripts/check_course_translation.py --lang hr course_100_*
```

Provjera javlja po tečaju: pomaknut kostur, rasparene oznake, broj natuknica, neregistrirane ključeve, pojmove
parkirane na kraju odlomka, zabranjene znakove (`—`, `–`, `« »`, `’`, `‘`, neprelomivi razmak), razmake,
prijedloge ispred interpunkcije, točku na kraju podebljanog dijela, francuske ostatke, tisuće s razmakom
(`30.000`), francuska stoljeća (`15. stoljeće`) i eru (`pr. Kr.`). Čist prolaz je obveza, ne prijedlog.

Provjera ne vidi gramatiku: rod korisnika, rod likova i padež oko `**…**` i `[[…]]` provjeravaš čitanjem, naglas.
Pretraži i ono što je revizija našla; svaki pogodak je ispravljen ili opravdan:

```bash
grep -nE '\b[Uu] \*{0,2}[0-9]{3,4}' content/courses/hr/*.json      # U 1857
grep -nE '\b(Želimo|živimo|Zahtijevamo|mi zovemo)\b' content/courses/hr/*.json
grep -nE '“|\\"|\]\][a-zčćšž]' content/courses/hr/*.json        # navodnici, nastavak iza ]]
```
