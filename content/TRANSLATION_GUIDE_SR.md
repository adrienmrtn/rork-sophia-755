# Prevod kurseva sa francuskog na srpski (latinica, ekavica)

Francuski (`content/courses/fr/`) je izvor. Ovo je specifikacija za `content/courses/sr/`, kvizove, Rečnik i
interfejs; daje se u celini onome ko prevodi, a `scripts/check_course_translation.py --lang sr` je mehanički sprovodi.
Nametnuta terminologija: `content/terminology/` (`termes_produit.json`, `mots_pieges.json`, `oeuvres.json`).

## 1. Šta želimo

Ne predajemo prevod. Predajemo **srpsko izdanje** kursa: tekst koji bi srpski urednik napisao iz istih beležaka.
Čitalac ne sme da nasluti da je original francuski. Ovim redom:
1. **Tačno.** Ne izvrći, ne izmišljaj i ne izostavljaj činjenice.
2. **Tečno.** Idiomatski srpski. Naglas se čita bez zapinjanja.
3. **Jednostavno.** Kratke rečenice, svakodnevne reči; tinejdžer mora da prati. „pokazao“, ne „demonstrirao“.
4. **Verno obliku.** Otprilike isti broj rečenica, isti tok misli, dužina uz 20% luft, da prelom ostane.

Registar: **standardni srpski, latinica, ekavica, razgovorno topao**. Bez dijalekta, bez birokratskog jezika, bez
ijekavice i kroatizama: `vek`, `pesma`, `lepota`, `vreme`, `deo`, `istorija`, `hiljada`, `tačka`, `nivo`, `kurs`,
nikad `vijek`, `pjesma`, `ljepota`, `vrijeme`, `dio`, `povijest`, `tisuća`, `točka`, `razina`, `tečaj`. Nijedno
ćirilično slovo u tekstu. `da` + prezent i infinitiv su oba ispravni (`moraš da učiš`, `moraš učiti`); u istom ekranu
biraj jedno. `Voici comment…` je `Evo kako…`, `Voici ce que…` je `Evo šta…`, nikad `Ovde je kako`.

**Vreme pripovedanja.** Francuski pripoveda u prezentu; istorijski prezent je u srpskom prirodan i zadržavaš ga, ali
ne klizi u perfekat usred pasusa: `on postaje vođa. Sastavio je [[Ustav Medine]]` → `postaje vođa. Sastavlja
[[Ustav Medine]] i osniva zajednicu vernika, [[Umma]].`

**Obraćanje je uvek „ti“, jednina, svuda**: kurs, kviz, Rečnik, interfejs. Nikad *Vi*, *vaš*, *Proverite*. **Rod
korisnika.** Muški particip isključuje korisnice već na prvom ekranu. Prvo preoblikuj bez participa (prezent,
imperativ, imenica, pasiv); tek ako ne ide, oba oblika (`došao/la`, `spreman/spremna`). `Dobro došao u Sophia` →
`Dobro došao/la u Sophiju`; `Dobro došao na brod!` → `Dobro nam došao/la!`; `Iskoristio si današnji besplatni kurs.` →
`Današnji besplatni kurs je iskorišćen.`; `Već si pročitao današnji besplatni kurs` → `Današnji besplatni kurs je već
pročitan`; `JESI LI ZNAO?` → `ZNAŠ LI?`; `Spreman sam` → `Krećem!`. Svedočanstva žena su u ženskom rodu: `Ranije sam
na telefonu provodio 7 sati dnevno.` → `…provodila 7 sati dnevno.`; `Terminale` u potpisu je `maturantkinja`
(`maturant` za muškarca).

**Bezlično „on“ nikad nije „mi“.** Revizija je našla 56 takvih rečenica: aplikacija tada govori umesto likova. Srpski
ima bezlično `se`, pasiv ili 3. lice množine:

| Francuski | Pogrešno | Ispravno |
| --- | --- | --- |
| On veut le tuer. | Želimo da ga ubijemo. | Hoće da ga ubiju. |
| On y vit en tribus. | Tamo živimo u plemenima. | Tamo se živi u plemenima. |
| On exige un dessin précis. | Zahtevamo precizan crtež. | Traže se precizan crtež i glatka površina. |
| ce qu'on appelle | ono što mi zovemo | ono što se zove / takozvani |

**Nazivi proizvoda**, jedan naziv svuda:

| Francuski | Srpski | Nikad |
| --- | --- | --- |
| cours / quiz / collection / parcours | kurs (`Neograničeni kursevi`) / kviz / kolekcija / staza (`Tvoja staza`) | lekcija, tečaj / test, upitnik / zbirka / putanja, put |
| niveau / série | nivo (`NIVO 3`) / niz (`Niz od 5 dana`) | NIV., razina, level / serija |
| essai gratuit | besplatna proba; dugme `Isprobaj {n} dana besplatno` | probni period, besplatni period, `Započni {n} dana` |
| Premium, Sophia, XP | latinicom, nepromenljivo: `Premium`, `50 XP` | Premijum, premija, iskustveni poeni |
| bloqueur / débloquer | bloker (`TikTok bloker`) / otključaj | blocker, blokada / odblokiraj (samo za bloker) |
| glossaire / Bibliothèque / abonnement / Entraînement / réviser | Rečnik / Biblioteka / pretplata (`Mesečno`, `Godišnje`) / Vežbanje / ponovi, ponavljanje | pojmovnik, glosar / Biblio, knjižnica / članarina / trening / revidiraj |
| matière / objectif / ami / l'offre | oblast / cilj / prijatelj (`rang-lista`) / ponuda (`Pogledaj ponudu`) | materija, predmet / objektiv / pratilac / paywall |

**Sophia se menja sa „j“**: `Sophia`, `Sophije`, `Sophiji`, `Sophiju`, `Sophijom`. `Bez Sophia` → `Bez Sophije`,
`Ostani u Sophia` → `Ostani u Sophiji`, `Podeli Sophiu` → `Podeli Sophiju`. Nikad `Sophiu`, `Sophii`, nikad
nepromenjeno iza predloga; nepromenljivo samo ispred druge imenice (`Sophia Premium`).

Zamke u interfejsu: `Pas de connexion` je `Nema internet veze` ili `Nema interneta`, nikad `Nema veze` („nije važno“);
`sans connexion` je `bez interneta`, nikad `bez veze` (`Preuzete zapise možeš slušati i bez interneta.`). `la personne
la plus intéressante de la pièce` je `najzanimljivija osoba u društvu`, ne `u prostoriji`. `Expire dans` je `Ističe
za`; `Léger / Modéré / Intense` je `Lagano / Umereno / Intenzivno`; `La lumière` je `Svetlost`; `Gratuit` je
`Besplatno`. Dugme je glagol: `Prevuci da otkriješ`, `Vrati sebi vreme`. `Gori ti 🔥` → `Rasturaš 🔥`. `Otključaj mojih
-70 %` → `Otključaj popust od 70%`. Uz `%d` tri oblika: `%d kurs`, `%d kursa`, `%d kurseva`.

## 2. Kostur ostaje

Prevode se samo tekstualna polja. Ostalo alat kopira iz francuskog kostura i ne diraš: `id`, `subject`, `subcategory`,
`type`, `asset`, `image`, `ratio`, `free`.

| Polje | Šta je | Napomena |
| --- | --- | --- |
| `title` | Naslov kartice i heroja | Kratko. Ustaljeni srpski naslov dela, ako je kurs o delu. |
| `subtitle` | Red ispod naslova | Godina ili raspon (`1945`, `1945-1975`) ostaje tačno takav. |
| `description` | Blurb od dve rečenice | Stoji sam za sebe. |
| `hero.hook` | Jedna rečenica mamac | Reklama, ne proza. |
| `sections[].title` | Naslov odeljka | Imenička grupa, bez tačke na kraju. |
| `paragraph.text` | Povezan tekst | Glavni posao. |
| `image.caption` | Potpis slike | Kratko; tačka samo uz celu rečenicu. |
| `funFact.text` | Okvir | Lako, razgovorno. |
| `takeaway.text` | Zaključak | Ono što treba da ostane. |
| `quote.text` | Citat | Vidi §6. |
| `quote.attribution` | Ko je rekao | Vidi §6. |
| `timeline.events[].date` | `1789.`, `jun 1940.`, `oko 450. p. n. e.` | Cifre ostaju, meseci se prevode. `p. n. e.` / `n. e.`, nikad `av. J.-C.`. |
| `timeline.events[].title` | Oznaka | Vrlo kratko, bez tačke. |
| `timeline.events[].detail` | Jedna rečenica | Imenica, ne naredba: `Rendez-vous sans combat` → `Predaja bez borbe i opšte pomilovanje.`, ne `Predajte se bez borbe i opšteg pomilovanja` („bez“ poriče i pomilovanje). |

## 3. Oznake u redu

Tri oznake moraju da prežive:
- `**podebljano**`: datumi, brojevi, imena i dela o kojima pasus govori.
- `*kurziv*`: naslov dela u prozi.
- `[[pojam]]`: odrednica Rečnika. Dodir otvara definiciju.

Pravila:
- Oznake idu u parovima. Neparan broj `**` je greška.
- Nijedna oznaka ne guta razmak ni interpunkciju: `**1945**,` je ispravno, `**1945,**` i `** 1945 **` nisu.
- **Podebljani deo ne završava tačkom** (provera to javlja). Redna tačka godine ne sme da bude poslednji znak:
  `**1857. godine**`, nikad `**1857.** godine` ni `**1857.**`. Isto za eru: `**450. godine** p. n. e.`
- Podebljava se srpski ekvivalent: `**30 000 mots**` postaje `**30.000 reči**`.
- Ime u podebljanom delu se menja, ceo oblik je unutra: `okuplja **Monet**, **Renoir**` → `okuplja **Monea**,
  **Renoara**, **Pisaroa**, **Degaa** i **Bertu Morizo**`. Nikad nastavak sa crticom van oznake (`**Mone**-a`).
- Ne dodaj podebljanje kojeg u francuskom nema. Ne podebljavaj celu rečenicu.

## 4. Odrednice Rečnika: najvažnije pravilo

Svako francusko `[[...]]` postaje tačno jedno srpsko `[[...]]`, **u rečenici, na istom mestu u argumentu**. Nikad ne
parkiraj pojam na kraj pasusa. Nikad ne ostavljaj rupu. To je ista greška:

> Pogrešno: `oslabljen pre svega od : hrišćanski krstaši opljačkali su grad. [[Osvajanje Carigrada]]`

> Ispravno: `oslabljen pre svega jednim događajem: [[Osvajanje Carigrada u Četvrtom krstaškom ratu (1204)]], kada su zapadni krstaši opljačkali grad.`

Tekst pojma nije slobodan. Mora da bude ključ registrovan za taj kurs u
`ios/Sophia/Resources/Locales/glossary.sr.json`; neregistrovan ključ ostaje mrtav tekst. Sažetak iz
`scripts/make_translation_briefs.py` navodi dozvoljene ključeve; upotrebi jedan znak po znak, sa velikim slovima. Neki
ključ postoji u dva oblika (`Zvanični pariski salon` / `zvanični pariski salon`); biraj između njih.

Rečenica mora da ostane gramatična **sa umetnutim ključem**, a tu srpski sa padežima zapinje. Revizija je našla
odrednice ubačene u nominativu bez obzira na funkciju u rečenici:

- Ključ je u registrovanom obliku, gotovo uvek nominativu. **Ne menjaj ga i ne izmišljaj promenjen ključ**
  (`[[Varšavskog pakta]]`, `[[Umu]]` nisu registrovani). Ne lepi nastavak iza `]]`: `[[kalif]]a` je greška.
- Stavi ključ na mesto nominativa: kao subjekat ili kao apoziciju uz imenicu koja se menja (`delo`, `savez`, `pokret`,
  `titula`, `zajednica`). Ako ne seda, preoblikuj rečenicu; ključ ne diraj.

| Pogrešno | Ispravno |
| --- | --- |
| bivše zemlje **[[Varšavski pakt]]** | bivše članice saveza **[[Varšavski pakt]]** |
| i osnovao [[Umma]], zajednicu vernika | i osniva zajednicu vernika, [[Umma]] |
| umornih od [[Zvanični pariski salon]] | umornih od pravila koja nameće [[Zvanični pariski salon]] |
| Vlast tada prelazi na [[kalif]], njegove naslednike. | Vlast preuzimaju njegovi naslednici, koji nose titulu [[kalif]]. |

- Ne počinji rečenicu ključem sa malim slovom: `[[razzias]], brzi napadi` → `Pokreće [[razzias]], brze napade.`
- Odrednica ne sme da nestane: `pokreće napade, brze napade` izgubio je `[[razzias]]`.
- Neprilagođen registrovan ključ (`razzias`, `Dhimma`, `jizia`, `Nemesis`, `Naiads`, `Oread`, `Echo`, `Musee d'Orsai`,
  `Salon des Refuses`, `Madame Bovari`, `Le Spleen de Paris`, `Bodlerova "slezina"`) piši u `[[...]]` tačno takav i
  prijavi ga; ispravlja se u `glossary.sr.json` (`razija`, `zimma`, `džizja`, `Nemeza`, `Najade`, `Oreada`, `Eho`,
  `Muzej Orse`, `Salon odbijenih`, `Gospođa Bovari`, `Pariski splin`, `Bodlerov splin`). U prozi van zagrada uvek
  prilagođeni oblik.

## 5. Vlastita imena

**Nikad ne prevodi lično ime.** Mašinski prevod je od Zevsa napravio `imao`, od Pana `Bang`. Ali srpski
**transkribuje** strana imena fonetski, po Pravopisu, i menja ih po padežima: `Monet` → `Mone` (`Moneu`, `Monea`),
`Manet` → `Mane` (`Eduara Manea`), `Renoir` → `Renoar`, `Pissarro` → `Pisaro`, `Degas` → `Dega`, `Berthe Morisot` →
`Berta Morizo`, `Baudelaire` → `Šarl Bodler`, `Aupick` → `Opik` (`generalom Opikom`), `Hugo` → `Viktor Igo`, `Leroy` →
`Leroa`, `Freud` → `Frojd`, `Munch` → `Edvard Munk`, `Musée d'Orsay` → `Muzej Orse`. Jedno ime, jedan oblik u celom
kursu (ne `Leroa`, `Leroi` i `Leroj`). Original u zagradi najviše jednom, pri prvom pominjanju. `chez Hugo` je `kod
Igoa`, ne `U Hugu`. `scripts/proper_nouns.json` nema srpsku tabelu: upiši oblik tamo, ne ispravljaj isto ime dvaput.

**Ustaljeni srpski oblik**, dosledno: `Muhamed`, `Meka`, `Medina`, `Jasrib`, `Kaba`, `Narcis`, `Eho` (ne `Odjek`, ne
`Echo`), `Tiresija`, `Nemeza`, `Ovidije`, `kralj Artur`, `kraljica Ginevra`, `Christophe Colomb` → `Kristofor
Kolumbo`, `Charlemagne` → `Karlo Veliki`, `Londres` → `London`, `Pékin` → `Peking`, `Aix-la-Chapelle` → `Ahen`,
`Michel-Ange` → `Mikelanđelo`. `ONU` → `UN`, `OTAN` → `NATO`; `OTAN` ostaje samo kad tekst navodi francuski naziv:
`NATO na engleskom i OTAN na francuskom` (ne `NATO … i NATO na francuskom`). `Hladni rat` uvek velikim slovom.

**Arapski i islamski pojmovi** u prilagođenom obliku: `Hidžra` (622; ne `Hegira`, ne `emigracija`), `razija` (mn.
`razije`), `džizja`, `halifa` (prihvatljivo `kalif`, jedno po kursu), `zimma` (`zimije`), `uma` (`umet`), `džihad`,
`beduini`, `Kurejšije`. Množina po srpskim pravilima; nikad `jizya`, `calife` ni francuska množina. `nosi ime:
**Hegira**` → `nosi ime: **Hidžra**`.

**Rod prati srpsku reč i lik, ne francuski**: Eho je ona (`Eho, osuđena da bude samo glas koji ponavlja`, `njeno
telo`), Narcis je on (`Njegova lepota privlači sve`). Medina je ženskog roda (`Preimenovana je u „grad Proroka“ i to
ime je zadržala`). Knjiga je ženskog roda (`Knjiga je izazvala skandal. Osuđena je za…`), *Cveće zla* je srednjeg roda
jednine (`Cveće zla je prvo skandalizovalo, a zatim postalo…`). NATO je savez, muškog roda (`nestanak njegovog
protivnika`, `njegovu korisnost`).

**Naslovi dela nose ustaljeni srpski naslov**, ne kalk (pun spisak u `oeuvres.json`): *Impression, soleil levant* →
*Impresija, rađanje sunca* (ne *Štampa, izlazeće sunce*), *Les Nymphéas* → *Lokvanji* (ne *Vodeni ljiljani*), *Le
Déjeuner sur l'herbe* → *Doručak na travi*, *Les Demoiselles d'Avignon* → *Gospođice iz Avinjona*, *Les Fleurs du Mal*
→ *Cveće zla*, *Le Spleen de Paris* → *Pariski splin*, *Spleen et Idéal* → „Splin i ideal“, *Correspondances* →
*Saglasja*, *Recueillement* → *Sabranost*, *Madame Bovary* → *Gospođa Bovari*, *Les Misérables* → *Jadnici*, *La Ferme
des animaux* → *Životinjska farma*, *Le Procès* → *Proces*, *Les Métamorphoses* → *Metamorfoze*. Jedno delo, jedan
naslov: *Correspondances* ne sme biti `Prepiska` u naslovu odeljka i `Saglasja` u pasusu. Naslov se menja (`objavljuje
*Cveće zla*`, `u *Lokvanjima*`) ili stoji uz imenicu u nominativu (`u romanu *Jadnici*`). Bez ustaljenog naslova
ostavi original i objasni ga. `novlangue` je `novogovor` (na kursu 102 ključ `[[Novogovor]]`), `doublepensée` je
`dvomisao`.

**Reči sa dva značenja.** Nikad ne uzimaj najčešći engleski smisao. `beau-père` (Aupick) je `očuh`, ne `tast`: `svađa
sa svojim tastom` → `svađa se sa očuhom, generalom **Opikom**`. `Spleen` je `splin`, ne `slezina`; `l'idéal` je
`ideal`, ne `idealan`; `deux états` (duše) su `dva stanja`, ne `dve države`. `condamnation` je `sudska osuda`, ne
`uverenje`. `touche` je `potez`, ne `dodir` (`potezi čiste boje`); `tubes de peinture` su `boje u tubama`, ne `cevi za
farbanje`; `motif` je `motiv`, ne `šara`. `10 000 hommes` su `10.000 ljudi`, ne `muškaraca`. `postérité` je `nasleđe`,
ne `potomstvo` ni `Posteriti`; `dehors` je `napolju`, ne `spolja`; `l'espace` uz sajber prostor je `svemir`.
`l'Antiquité s'achève` je `antika se završava`, ne `se približava`. `les poèmes sont levés` je `zabrana pesama je
ukinuta`, ne `pesme su uklonjene`. `pousser la logique` je `dovesti do krajnosti`, ne `gurnuti`; `incarne` je
`oličava`, ne `igra`. `une civilisation mondiale` je `jedna svetska civilizacija`; ostalo u `mots_pieges.json`.

## 6. Citati

Citat nije prevodilačka vežba. Ako postoji kanonska srpska formulacija, koristi nju. Inače prevedi kratko i čisto.
- Navodnici su `„ “` (U+201E i U+201C). Nikad `„ ”`, ravni `" "` ni `« »`. Eho mora da bude eho: `"Ima li nekoga?"` →
  `„Ima li nekoga?“ Ona odgovara: „Nekoga!“`
- Tačka citirane rečenice ide unutar zatvarajućeg navodnika: `„Sve životinje su jednake.“` Citat u citatu izbegni
  preoblikovanjem; `‚ ‘` i `’` su zabranjeni.
- `quote.attribution` je `Autor, Delo`. Ako francuski daje govornika iza crte, zareza ili u zagradi: `Viktor Igo,
  Jadnici (biskup Mirijel)`.
- Kanonski citat iz *Životinjske farme*: `„Sve životinje su jednake, ali neke životinje su jednakije od drugih.“`

## 7. Interpunkcija i tipografija

Mehanička provera, bez izuzetaka.
- **Nema duge crte `—` ni srednje `–`**, iako ih Pravopis poznaje. Preoblikuj zarezom, dvotačkom, zagradom ili tačkom.
  Rasponi spojnicom: `1945-1975`, `XIV-XVI vek`, a u prozi radije `od 610. do 632. godine`.
- Nema `« »`, znaka nulte širine, neprelomnog razmaka, `‘` ni `’`. Apostrof je pravi `'` (U+0027), kao u francuskim
  datotekama: `d'Orsay` ako se original navodi.
- Nikad razmak ispred `, . ; : ! ?`, nikad dva razmaka zaredom, razmak iza zareza i kraja rečenice. Predlog ili `te`
  ispred interpunkcije (`od ,`, `sa .`, `te,`) je rupa iza obrisanog pojma. Dvotačku i tačku sa zarezom koristi retko.
- Nema francuskih ostataka: `siècle`, `dans`, `l'`, `d'un`, nepreveden francuski toponim ili ime bez akcenata
  (`Musee`, `Refuses`) u srpskom pasusu je greška. Isto za engleske ostatke (`blocker`, `Posteriti`).

## 8. Brojevi, datumi, mere

- Hiljade: tačka. `30 000` → `30.000`. Nikad razmak, nikad zarez.
- Decimale: zarez. `3,5 %` → `3,5%`. Bez razmaka ispred `%`.
- **Godina** ima rednu tačku i reč `godine`; `En 1857` nikad nije `U 1857` (revizija: 148 rečenica). Bez podebljanja
  dobro je i `Godine 622.` na početku rečenice; sa podebljanjem važi §3.

| Francuski | Pogrešno | Ispravno |
| --- | --- | --- |
| En **622**, un marchand… | U **622**, trgovac iz Meke… | **622. godine** trgovac iz Meke… |
| En **1857**, Baudelaire publie… | U **1857**, **Šarl Bodler** je objavio… | **1857. godine** **Šarl Bodler** objavljuje… |
| le scandale de 1863, vers 630 | skandal iz 1863, u 630 | skandal iz 1863. godine, oko 630. godine |

- Pun datum: `24. februara 2022.`, mesec malim slovom, u genitivu, srpskim imenom (`jul`, `avgust`, `novembar`, nikad
  `srpanj`, `kolovoz`, `studeni`). Jedna šema po kursu.
- **Vekovi** arapskim rednim brojem sa tačkom: `VIIe siècle` → `7. vek`, `u 7. veku`. Rimski broj bez francuskog
  nastavka je dozvoljen (`VII vek`), jedna šema po kursu. Nikad `VIIe`, nikad `700-te`: `7. vek` je `601-700.`
- Era: `p. n. e.` i `n. e.` sa običnim razmakom: `450. p. n. e.`, `622. n. e.`
- **Padež iza broja**: 1 (21, 31…) jednina, 2-4 (22, 23, 24…) genitiv jednine, 5-20 genitiv množine: `1 kurs`, `3
  kviza`, `5 kurseva`, `22 godine`, `sa 6 godina`, `za 22 godine`, `šest cenzurisanih pesama`, `10 000 hommes` →
  `10.000 ljudi` (vojnika). `ans` je `godina`, nikad `pisma` ni `pregleda`.
- Bez preračunavanja. `Mds`/`Md` → `milijarde`/`milijardi`, `M` → `miliona`, rečima (`3 miliona`, ne `3 milijuna`).

## 9. Provera

```bash
python scripts/check_course_translation.py --lang sr
```

Provera javlja kostur, oznake, broj i registraciju odrednica, parkirane pojmove, zabranjene znakove, razmake, predloge
ispred interpunkcije, tačku u podebljanom, ostatke, hiljade (`30.000`), vekove (`15. vek`) i eru (`p. n. e.`). Čist
prolaz je obaveza, ne predlog.

Provera ne vidi gramatiku. Pročitaj tekst naglas i pretraži ono što je revizija našla:

```bash
grep -nE '\b[Uu] \*{0,2}[0-9]{3,4}\*{0,2}([^.0-9]|$)' content/courses/sr/*.json       # U 1857
grep -niE '\b(mi )?(želimo|živimo|zahtevamo|zovemo)\b' content/courses/sr/*.json    # on = mi
grep -nP '”|\\"|\]\][a-zčćšđž]|\p{Cyrillic}' content/courses/sr/*.json   # navodnici, nastavak, ćirilica
grep -niE '\b(uz|bez|u|na) Sophia\b|Sophi[ui]\b|lekcij|putanj|blocker|nema veze|bez veze' ios/Sophia/Resources/Locales/*sr*
grep -nE '\b(vijek|pjesm|ljepot|vrijeme|tisuć|stoljeć|povijest|točk|razin|tečaj)' content/courses/sr/*.json
```

Svaki pogodak je ispravljen ili opravdan. Rod, padež oko `**…**` i `[[…]]` i vreme pripovedanja proveravaš čitanjem.
