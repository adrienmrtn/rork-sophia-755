# Prevajanje tečajev: iz francoščine v slovenščino

Francosko besedilo (`content/courses/fr/`) je vir; ta dokument je specifikacija za `content/courses/sl/`, ki jo
`scripts/check_course_translation.py --lang sl` preverja strojno. Ista pravila veljajo za vmesnik, kvize, slovarček
in katalog (`content/locales/sl/`). Obvezna terminologija je v celoti v `content/terminology/` (`termes_produit.json`,
`mots_pieges.json`, `oeuvres.json`); vsi primeri »narobe → prav« so iz revizije `docs/audit-traductions/sl.json`.

## 1. Kaj hočemo

Ne oddajamo prevoda. Oddajamo **slovensko izdajo** tečaja: besedilo, ki bi ga iz istih zapiskov napisal slovenski
urednik. Bralec ne sme opaziti, da je izvirnik francoski. Po vrsti:

1. **Pravilno.** Ne potvarjaj, ne izmišljuj in ne izpuščaj dejstev. Večpomensko besedo beri iz sobesedila, ne po
   najpogostejšem angleškem pomenu: `V samo **22 črk**` → `V samo **22 letih**`; `z **10.000 dolarjev**` → `s
   **10.000 možmi**`; `Šest pesnikov je bilo obsojenih` → `Šest pesmi je bilo obsojenih`; `Kljub številčni premoči`
   (en infériorité numérique) → `Čeprav so v manjšini`; `se približuje antika` → `se antika končuje`.
2. **Tekoče.** Naravna slovenščina, ki se na glas prebere brez spotikanja.
3. **Preprosto.** Kratki stavki, vsakdanje besede; radoveden najstnik mora slediti. Raje `pokazal` kot
   `demonstriral`, `uporabil` kot `preferenčno izkoriščal`.
4. **Zvesto obliki.** Približno enako število stavkov, isti potek misli, dolžina v okviru dvajsetih odstotkov.

**Ogovor je vedno ti**, v ednini in toplo: v tečajih, kvizih, slovarčku in vmesniku. Nikoli `vi`, `Dobrodošli` ali
velelnik na `-te`/`-ite`. Na gumbu `svoj`, ne `moj` (`moj` je govorec).

> Narobe: `Odklenite vse tečaje` · `Odkleni mojih -70 %` · `Poskusiti lahko kolikorkrat želiš.`
> Prav: `Odkleni vse tečaje` · `Odkleni popust -70 %` · `Poskusiš lahko, kolikorkrat želiš.`

**Francoski brezosebni »on« ni nikoli »mi«.** Uporabi 3. osebo množine brez osebka, `ljudje`, trpnik z deležnikom
ali `se` (`Pravijo, da …`, `Zahteva se …`). Tudi splošni »vous« ni `vi`. Pravi »nous« (`notre regard`) ostane `naš
pogled`; aplikacija sme govoriti v 1. osebi (`tako ti bolje prilagodimo stopnjo`).

> Narobe: `Želimo ga ubiti.` · `Tam živimo v plemenih.` · `Zahtevamo natančno risbo in gladko površino.` · `To
> zmago doživljamo kot čudež.` · `Kot otrok sva brala zgodbo o živalih; kot odrasli beremo razpravo.`
> Prav: `Hočejo ga ubiti.` · `Ljudje tam živijo v plemenih.` · `Zahtevana je natančna risba in gladka površina.` ·
> `Zmago doživijo kot čudež.` · `Otrok v njej bere zgodbo o živalih, odrasel pa razpravo.`

**Spol uporabnika.** Slovenščina spol zaznamuje v pretekliku (`končal`/`končala`), v prihodnjiku (`boš prebral`) in
na pridevniku (`pripravljen`, `star`). Uporabnik je fant ali dekle; moška oblika ni privzeta. Najprej se spolu
izogni: sedanjik (`Prebereš`), brezosebno ali samostalnik (`Končano!`), vprašanje brez pridevnika, vzklik. Šele če
ne gre drugače in je prostora dovolj (nikoli na gumbu), obe obliki s poševnico: `odkril/-a`, `pripravljen/-a`.

> Narobe: `Dobrodošel` · `Koliko si star?` · `Končal si` · `Pripravljen sem` · `Današnji brezplačni tečaj si že
> prebral` · `Bodi iskren, služi le prilagoditvi ravni.`
> Prav: `Lepo, da si tu` · `Koliko let imaš?` · `Končano!` · `Gremo!` · `Današnji brezplačni tečaj je že prebran` ·
> `Odgovori iskreno: tako ti bolje prilagodimo stopnjo.`

**Pričevanja** imajo spol podpisnika. Léa, Inès in Camille so ženske: `Prej sem na telefonu preživel 7 ur na dan …
se počutim pametnejšega` → `Prej sem na telefonu preživela 7 ur na dan … se počutim pametnejšo`. Terminale je `4.
letnik` (`maturantka`/`maturant`), ne `starejši letnik`. Imen ne posloveni (`Inès, 25` ostane).

**Spol likov in samostalnikov** sledi slovenski besedi, ne francoski. `Knjiga je povzročila škandal. Obsojen je bil
…` → `Knjiga povzroči škandal. Obsojena je …`; *Rože zla* so ženskega spola v množini (`so povzročile`, ne `je
povzročil`); `Medina` je `preimenovana`. Eho je nimfa (`ni mogla izraziti svoje želje`, ne `ni mogel`), Narcis je
mladenič (`Njegova lepota`, ne `Njena`). `svoj` kaže na osebek: `Videc je posvaril svojo mamo` (videčevo) → `Videc
je posvaril njegovo mater` (Narcisovo). Brez osebka stavek izgubi pomen: `Je nimfa …` → `Ona je nimfa …`.
**Čas**: zgodovinski sedanjik (`Leta 622 mora pobegniti`) ali preteklik, a en čas na odstavek: `… konča dobo
dvomov. Čez nekaj dni se je Nato vrnil` → `… Čez nekaj dni se Nato vrne`.

**Kalki in tujke.** Glagol namesto samostalnika, slovenski frazem namesto dobesednega:

| Narobe | Prav |
| --- | --- |
| `Tukaj je, kako …` · `PODRSAJ ZA ODKRIVANJE` · `Prijavi se za nadaljevanje.` | `Takole …` · `Podrsaj in odkrij` · `Prijavi se in nadaljuj.` |
| `Vzemi si čas nazaj` · `Goriš 🔥` · `Lepa rednost 👏` · `Ne čisto...` | `Vzemi si spet čas zase` · `Kar žariš 🔥` · `Lepo ti gre, kar tako naprej 👏` · `Ni čisto tako…` |
| `letna naplata` (hrvaško) · `Zaženi {n} dni brezplačno` (program) | `zaračunano letno` · `Začni {n}-dnevni brezplačni preizkus` |
| `Rasti po ravneh in se povzpni na lestvici` · `Poslušaj vsako lekcijo kot zvok` | `Osvajaj stopnje in se povzpni po lestvici` · `Vsak tečaj lahko tudi poslušaš` |
| `Vse življenje znanja s Premium` · `10 minut kulture` | `Dostop Premium do znanja za vse življenje` · `10 minut znanja` |
| `Kako se je impresionizem rodil proti Salonu?` · `pomembnejši od subjekta` | `Kako je impresionizem nastal iz upora proti Salonu?` · `pomembnejši od motiva` |

**Lažni prijatelji.** Prevajaj po francoskem sobesedilu:

| Francosko (pomen) | Slovensko | Ne |
| --- | --- | --- |
| Léger / Modéré / Intense; la lumière; Gratuit; Expire dans; Mensuel / Annuel | Nizka / Zmerna / Visoka; Svetloba; Brezplačno; `Poteče čez`; Mesečno / Letno | `Svetloba` za léger; `lahkotnost`; prosto; revija, letopis |
| culture générale, cultivé; anecdotes; trimestre; Pas de connexion; la personne la plus intéressante de la pièce | splošna razgledanost, razgledan/-a; anekdote; trimester; `Ni povezave`; najbolj zanimiva oseba v družbi | kultura, kulturen; vici; mandat; `ni važno`; `v sobi` |
| spleen; flâneur; caravane; deux états (d'âme); condamnation; beau-père (Aupick); postérité; modernité | spleen; flâneur (sprehajalec-opazovalec); karavana; dve stanji; obsodba; očim; zapuščina; modernost | `vranica`; `otroški voziček`; prikolica; dve državi; prepričanje; `tast`; `Potomci`; `sodobnost` |
| ans; hommes (soldats); poèmes; plaques (photo); pétrole; gravité; failles; cellulaire; Pan; Némésis | let; mož; pesmi; fotografske plošče; nafta; gravitacija; prelomi, pomanjkljivosti; celični; Pan; Nemezis | `črk`; `dolarjev`; `pesnikov`; krožniki; olje; resnost; okvare; mobilni; `Pok`; sovražnik |
| Grande Dépression; soupe populaire; bank runs; relance; offshore | velika gospodarska kriza; ljudska kuhinja; naval na banke; oživitev gospodarstva; davčna oaza | depresija; `banka teče`; ozdravitev; odprto morje |
| touche; sensation; chute; puissant; réel; clé (de lecture) | poteza (čopiča); občutenje; padec; mogočen; resničen; ključ za razumevanje | `dotik`, tipka; senzacija; jesen |

## 2. Skelet ostane

Prevajajo se samo besedilna polja. Ostalo orodje prepiše iz francoskega skeleta in se ga ne dotikaš: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Polje | Kaj je | Opomba |
| --- | --- | --- |
| `title` / `subtitle` / `description` / `hero.hook` | Naslov / vrstica pod njim / uvod v dveh stavkih / vaba | Pri delu slovenski naslov izdaje. Letnica ali razpon (`1945-1975`) ostane. Uvod stoji sam; vaba je oglas, ne proza. |
| `sections[].title` | Naslov razdelka | Samostalniška zveza, velika začetnica le na prvi besedi, brez pike. |
| `paragraph.text` / `image.caption` | Povezano besedilo / podnapis | Glavno delo. Podnapis kratek; pika le za celim stavkom. |
| `funFact.text` / `takeaway.text` | Okvirček / sklep | Lahkotno. Tisto, kar mora ostati v spominu. |
| `quote.text` / `quote.attribution` | Navedek / kdo ga je rekel | Glej §6. |
| `timeline.events[].date` | `1789`, `junij 1940`, `okoli 450 pr. n. št.` | Številke ostanejo, mesec z malo, nikoli `av. J.-C.`. |
| `timeline.events[].title` / `.detail` | Oznaka / en stavek | Oznaka zelo kratka, brez pike. |

**Izrazi izdelka** so v vsej aplikaciji enotni:

| Francosko | Slovensko | Ne |
| --- | --- | --- |
| quiz; cours; Parcours; collection | kviz (`mini kviz`); tečaj (`Neomejeni tečaji`); Pot (učna pot); zbirka | vprašalnik, test; `lekcija`; parkur; kolekcija |
| niveau, NIV. 3; série (streak); essai gratuit | stopnja, `ST. 3`; niz; brezplačni preizkus | raven, `RAV.`; `dni zapored` kot oznaka; preskus, poskus |
| Premium; Sophia | Premium (`naročnina Premium`, nesklonjeno); Sophia (`aplikacija Sophia`; `Sophie` le, če drugače ne gre) | premija; `s Premiumom` |
| bloqueur TikTok | blokator (`Blokator TikToka`, `z blokatorjem`) | blocker, blokada, anti-scroll |
| Entraînement; réviser; abonnement; débloquer | Vadba; ponoviti (gumb `Ponovi`, samostalnik `ponavljanje`); naročnina; odkleni | trening, praksa; revidirati; abonma, članarina; odblokiraj |
| objectif; matière / sujet; ami | cilj; predmet / tema; prijatelj | objektiv; subjekt, materija; frend |
| glossaire; XP; Bibliothèque; l'offre (paywall) | slovarček; XP (`100 XP`, nesklonjeno); Knjižnica; Ponudba | glosar, slovar; `XP-ja`; biblioteka |

## 3. Oznake v vrstici

Tri oznake morajo ostati: `**krepko**` (letnice, števila, imena in dela, o katerih govori odstavek), `*ležeče*`
(naslov dela v prozi) in `[[izraz]]` (geslo v slovarčku; dotik odpre razlago).

- Oznake gredo v parih. Liho število `**` je napaka.
- Nobena oznaka ne pogoltne presledka ali ločila: `**1945**,` je prav, `**1945,**` in `** 1945 **` sta narobe.
  Vrstilna pika sodi k številu znotraj zveze (`**7. stoletje**`, `**24. februarja 2022**`); krepko pa se ne konča s
  piko: `**1857.**` validator prebere kot konec stavka.
- Krepko označi slovenski ustreznik, ne istih znakov: `**30 000 mots**` → `**30.000 besed**`. Ob letnici odebeli
  število: `Leta **1857**`.
- Ne dodajaj krepkega, ki ga v francoščini ni. Ne odebeli celega stavka.

## 4. Gesla v slovarčku: najpomembnejše pravilo

Vsak francoski `[[...]]` da natanko en slovenski `[[...]]`, **v stavku, na istem mestu v miselnem toku**. Izraza
nikoli ne parkiraj na koncu odstavka. Ne puščaj luknje. To je ena in ista napaka:

> Narobe: `oslabljeno predvsem zaradi : krščanski križarji so izropali mesto. [[Zavzetje Konstantinopla]]`
> Prav: `Mesto je oslabilo predvsem [[zavzetje Konstantinopla med četrto križarsko vojno (1204)]], ko so zahodni
> križarji izropali mesto.`

Besedilo izraza je ključ, registriran za ta tečaj v `ios/Sophia/Resources/Locales/glossary.sl.json`; neznan ključ
ostane mrtvo besedilo. Povzetek iz `scripts/make_translation_briefs.py` našteje dovoljene ključe; uporabi enega znak
za znakom, z velikimi začetnicami kot v registru. Ne vstavljaj celotnega naslova gesla, če obstaja kratek ključ, in
ne zamenjaj gesla z drugim. Če registrirani ključ sam krši §5 (`Ummah`, `Ummet`, `razzias`, `Jihad`, `jizya`, `Ovid`,
`Echo`, `Le Spleen de Paris`, `Doublethink`, `Akademija za likovno umetnost`, `Baudelairjeva "vranica"`), ga popravi
v `glossary.sl.json` za ves tečaj hkrati, ne le v enem odstavku.

Stavek mora biti slovničen **z vstavljenim izrazom**. Slovenščina ima šest sklonov, ključ pa je v imenovalniku:

- Ničesar ne lepi za `]]`: `[[Ovid]]a`, `[[kalif]]i`, `[[džihad]]om` so narobe. Validator tega v slovenščini ne
  vidi; preveri ročno (§9).
- Postavi izraz tja, kjer stavek zahteva imenovalnik: osebek (`Pariz preoblikuje **[[Baron Haussmann]]**`),
  povedkovo določilo, za dvopičjem ali za `ki se imenuje`, `z imenom`.
- Naslov dela ali ustanove ostane v imenovalniku za vrstnim samostalnikom, ki nosi sklon: `v pesnitvi
  [[Metamorfoze]]`, `v zbirki [[Pariški spleen]]`, `z romanom [[Gospa Bovary]]`.
- Sklonjena oblika v oklepajih (`[[baronom Haussmannom]]`, `[[Metamorfozah]]`, `[[razzije]]` iz popravkov revizije)
  je dovoljena le, ko je registrirana kot ključ istega gesla za ta tečaj. Najprej ključ, potem besedilo.

> Narobe: `Pripravil je [[Medinska ustava]], pakt med klani, in ustanovil [[Ummah]].`
> Prav: `Sestavi pakt med klani, ki se imenuje [[Medinska ustava]], in tako nastane [[umma]].`
> Narobe: `Rimski pesnik [[Ovid]] v svojem [[Metamorfoze]] pripoveduje o prekrižani usodi …`
> Prav: `Rimski pesnik [[Ovidij]] v pesnitvi [[Metamorfoze]] pripoveduje o prepleteni usodi …`
> Narobe: `Pod **[[Baron Haussmann]]** se Pariz spreminja.` · `odpira pot do **[[Simbolizem in Baudelairova
> dediščina]]**` · `med [[Druga svetovna vojna]]`
> Prav: `Pariz preoblikuje **[[Baron Haussmann]]**: široki bulvarji, nove stavbe.` · `Iz te poetike zraste
> **[[simbolizem]]**, ki sta ga nadaljevala Verlaine in Mallarmé.` · `ko divja **[[Druga svetovna vojna]]**`

Predlog pred ločilom (`na ,`, `pod .`, `med :`) je prazno mesto izraza; validator ga javi. Če ključ ne sede,
preoblikuj stavek. Ključa v stavku ne spreminjaj.

## 5. Lastna imena

**Osebnega imena in priimka ne prevajaj.** Strojni prevod jih bere kot občna imena: Degas ostane Degas, Munch ostane
Munch (ne `žvečiti`), bog Pan ostane Pan (ne `Pok`).

**Tuje ime se sklanja**, kot v vsakem slovenskem besedilu. Narobe: `se norčuje iz Monet`, `z generalom Aupick`,
`zmagal na Badr`, `Vstopi v Kaaba`, `podrejena Akademija`, `združuje Monet, Renoir, Pissarro, Degas`, `Pomaga Zeus,
kralju bogov`. Prav: `se ponorčuje iz Moneta`, `z generalom Aupickom`, `zmagajo pri Badru`, `Vstopi v Kaabo`,
`podrejena Akademiji lepih umetnosti`, `združuje Moneta, Renoirja, Pissarra in Degasa`, `Pomaga mu Zevs, kralj
bogov`. Neizgovorjeni končni `-e` odpade: `Baudelaire`, `Baudelaira`, `Baudelairov`.

**Ustaljena slovenska oblika**, enako v vsem tečaju: `Christophe Colomb` → `Krištof Kolumb`, `Guillaume le
Conquérant` → `Viljem Osvajalec`, `Londres` → `London`, `Pékin` → `Peking`, `Aix-la-Chapelle` → `Aachen`,
`Charlemagne` → `Karel Veliki`, `Tchernobyl` → `Černobil`, `Michel-Ange` → `Michelangelo`, `Léonard de Vinci` →
`Leonardo da Vinci`, `Byzance` → `Bizanc`, `Ulysse` → `Odisej`, `roi Arthur, reine Guenièvre` → `kralj Artur,
kraljica Guinevere`, `Siège périlleux` → `Nevarni sedež`, `ONU`, `OTAN` → `OZN`, `NATO`. Izjema je anekdota o
kraticah: `NATO v angleščini in OTAN v francoščini`, ne `NATO … in NATO v francoščini`. Grški miti v slovenski
obliki, ne latinski ali angleški: Narcis (`Narcisa`), Eho (nimfa, ženskega spola; ne `Echo`, ne `Odmev`, ki je le
zvočni pojav), Ovidij, Tejrezias (ne `Tirezija`), Zevs, Hera, Nemezis, Kefis, Dedal, Ikar, Sizif.

**Islam in arabske besede**: `Mohamed` (`Mohameda`), `Meka` (`proti Meki`), `Medina` (`v Medini`), `Jatrib`, `Kaaba`,
`hidžra` z malo v prozi (`po hidžri`; naslov gesla `Hidžra`), `umma`, `kalif`, `džizja`, `dhimma`, `džihad`,
`razzija` (`razzije`), `beduini`. Narobe: `Hegira`, `Hijra`, `Ummah`, `Ummet`, `Yathrib`, `Muhammad`, `razzias`,
`Jihad`, `jizya`.

**Naslov dela je naslov slovenske izdaje**, ne dobeseden prevod (popoln seznam: `oeuvres.json`):

| Francosko → slovensko | Francosko → slovensko |
| --- | --- |
| *Les Fleurs du Mal* → *Rože zla*; *Le Spleen de Paris* → *Pariški spleen* | »Spleen et Idéal«, »Tableaux parisiens«, »Correspondances«, »Recueillement« → »Spleen in ideal«, »Pariške slike«, »Korespondence«, »Zbranost« |
| *Impression, soleil levant* → *Impresija, vzhajajoče sonce*; *Les Nymphéas* → *Lokvanji* | *Le Déjeuner sur l'herbe* → *Zajtrk v travi*; *Les Demoiselles d'Avignon* → *Avignonske gospodične* |
| *La Nuit étoilée* → *Zvezdna noč*; *Le Cri* → *Krik*; *La Joconde* → *Mona Liza* | *La Ferme des animaux* → *Živalska farma*; *Le Petit Prince* → *Mali princ* |
| *Crime et Châtiment* → *Zločin in kazen*; *Le Procès* → *Proces* | *Les Misérables* → *Nesrečniki*; *Notre-Dame de Paris* → *Notredamski zvonar* |
| *Le Rouge et le Noir* → *Rdeče in črno*; *L'Étranger* → *Tujec* | *À la recherche du temps perdu* → *Iskanje izgubljenega časa*; *Madame Bovary* → *Gospa Bovary* |
| *Les Raisins de la colère* → *Grozdi jeze*; *Gatsby le Magnifique* → *Veliki Gatsby* | *Ne tirez pas sur l'oiseau moqueur* → *Ne ubijaj slavca*; *Le Meilleur des mondes* → *Krasni novi svet* |
| *Psychose*, *Sueurs froides*, *Fenêtre sur cour* → *Psiho*, *Vrtoglavica*, *Dvoriščno okno* | *La République* → *Država*; *Le Prince* → *Vladar*; *Nighthawks* ostane |

Drugo: `Académie des beaux-arts` → `Akademija lepih umetnosti`; `Salon des Refusés` → `Salon zavrnjenih`; `New Deal`
ostane (`New Deala`); *1984*: `Big Brother` → `Veliki brat`, za novlangue je registriran ključ `novogovor` (v
`[[...]]` ne izmišljuj `Newspeak`). V besedilu tečaja je naslov `*ležeče*`; v vmesniku, kvizu in slovarčku (brez
oznak) v narekovajih: `Kdo je napisal zbirko »Rože zla«?`. Nikoli oglatih oklepajev: `[Le Déjeuner sur l'herbe]` →
`*Zajtrk v travi*`. Če slovenskega naslova ni, pusti izvirnik in ga ob prvi omembi pojasni v oklepaju. Like prevedene
književnosti imenuj kot v slovenski izdaji. Register je `scripts/proper_nouns.json` (preglednica `sl` pod
`per_language`): tja vpiši ime, ne popravljaj istega dvakrat.

## 6. Navedki

Navedek ni prevajalska vaja. Če obstaja kanonična slovenska ubeseditev, uporabi njo. Sicer prevedi kratko in jasno.

- Narekovaji `»…«` (začetni U+00BB, končni U+00AB). Ne `"…"`, ne `„…“`, ne francoski `« »` z obrnjeno smerjo:
  `Ima ga za "dušnega brata"` → `Ima ga za »dušnega brata«`; `Ona odgovori: "Nekdo!" »` → `Ona odgovori:
  »Nekdo!«`. Navedka v navedku ne gradi (`‘` je prepovedan); preoblikuj.
- Pika samostojnega navedenega stavka je znotraj končnega narekovaja: `»Vse živali so enake.«`. Navedek sredi
  stavka: `Obsojena je zaradi »žalitve javne morale«.`
- `quote.attribution` je `Avtor, Delo`; pesem v narekovajih: `Charles Baudelaire, »Korespondence«`. Če francoščina da
  govorca za pomišljajem, uporabi vejico ali oklepaj: `Victor Hugo, Nesrečniki (škof Myriel)`.
- Kanonični navedek iz *Živalske farme*: `»Vse živali so enake, vendar so nekatere živali bolj enake od drugih.«`

## 7. Ločila in tipografija

Strojno preverjeno, brez izjem.

- **Ni dolgega `—` ne srednjega pomišljaja `–`.** Preoblikuj z vejico, dvopičjem, oklepajem ali piko: `Bodi iskren –
  tako …` → `Odgovori iskreno: tako …`. Razpon s stičnim vezajem: `610-632` (tudi kjer popravek v reviziji piše
  `610–632`), `1945-1975`.
- Ni `« »` v francoski rabi, ni presledka ničelne širine, ni nedeljivega presledka (U+00A0), ni BOM. Opuščaj je raven
  `'` (U+0027): `Muzej d'Orsay`, ne `d’Orsay`.
- Pred ločilom ni presledka, dveh presledkov zapored ni. Za vejico, dvopičjem in podpičjem je presledek (razen v uri
  `02:59` in v številu `3,5`). Podpičje redko: slovensko učno besedilo ima rado piko.
- Vejica pred `ki`, `da`, `ker`, `ko`, `če`, `kjer`, `kolikor(krat)`; nikoli pred `in` pri preprostem priredju:
  `narediti učenje lahko, in dostopno vsem` → `učenje narediti preprosto in dostopno vsem`. Tri pike so en znak `…`.
- Občna imena sredi stavka z malo: `renesansa`, `impresionizem`, `velika gospodarska kriza`, `hidžra`.
- Brez francoskih ostankov (`siècle`, `dans`, `l'`, `Salon des Refusés`, `Le Spleen de Paris`) in angleških
  (`blocker`, `Echo`, `Ovid`, `Doublethink`). To so smeti strojnega prevoda; stavek napiši na novo.

## 8. Števila, datumi, mere

- Tisočice: pika od petmestnih števil naprej (`30 000` → `30.000`, `10 000 hommes` → `10.000 mož`); štirimestna
  skupaj (`4000 let`, `4500 km`). Nikoli presledek (validator ga javi), nikoli vejica. Letnice brez ločila.
- Decimalke z vejico (`3,5`). Odstotek z navadnim presledkom, kot določa pravopis: `3,5 %`, `-70 %`; pridevnik
  `5-odstoten`. `Mds`/`Md` → `milijard`, `M` → `milijonov`, z besedo. Cena: `9,99 €`.
- **Sklon za številom.** 1 (in 101) → ednina, 2 → dvojina, 3 in 4 → množina, od 5 naprej rodilnik množine: `1 kviz`,
  `2 kviza`, `3 kvizi`, `5 kvizov`; `2 leti`, `4 leta`, `22 let`; `šest pesmi`. Ključi vmesnika `one` / `two` /
  `few` / `other` imajo vsak svojo obliko (`%d kviz`, `%d kviza`, `%d kvizi`, `%d kvizov`). Predlog spremeni sklon:
  `s 10.000 možmi`, `pri 6 letih`, `v 22 letih`, `92 let po obsodbi`.
- **Starost in trajanje**: `à 6 ans` → `pri **6 letih**` (ne `pri 6 črk`, ne `kot šestletnik`, ki nosi spol); `en 22
  ans` → `v **22 letih**`; `il a 20 ans` → `star je 20 let` / `stara je 20 let` po spolu osebe.
- **Letnica**: `En 1857` → `Leta **1857**`; `Vers 630` → `Okoli leta **630**`; `dès 610` → `že leta 610`; `jusqu'en
  632` → `do leta 632`; `entre 1945 et 1975` → `med letoma 1945 in 1975` (dvojina) ali `v letih 1945-1975`. Narobe:
  `V **622** mora trgovec …`, `Pri **630** je situacija obratna`, `Okoli 630`, `v **624**`, `V **1857** je
  Baudelaire objavil`. Prav: `Leta **622** mora trgovec …`, `Leta **630** se položaj obrne`.
- **Datum**: v besedilu mesec v rodilniku z malo (`**24. februarja 2022**`); na časovnici mesec in leto v
  imenovalniku (`junij 1940`). Razpon: `od 13. marca do 7. maja 1954`. Ena shema na tečaj.
- **Stoletje**: arabska številka s piko, brez zamika (601-700 je 7. stoletje): `VIIe siècle` → `7. stoletje`, `v 7.
  stoletju`; `XIVe-XVIe siècle` → `od 14. do 16. stoletja`. Narobe: `VII. stoletje`, `XVe`, `700-ta leta` (to je 8.
  stoletje). `années 1920` → `dvajseta leta 20. stoletja`, ne `1920-ta`.
- Štetje let: `pr. n. št.` in `n. št.` z navadnimi presledki (`450 pr. n. št.`, ne `pr.n.št.`), nikoli `av. J.-C.`.
  Hidžra: `Kaj pomeni Hegira v 622?` → `Kaj pomeni hidžra leta 622?`; `l'an 1 de l'Hégire` → `1. leto po hidžri`.
- Brez pretvarjanja: metrično ostane metrično, presledek med številom in enoto (`4500 km`). XP in stopnje: `100 XP`,
  `ST. 3`, `120 XP do 5. stopnje`.

## 9. Preverjanje

```bash
python scripts/check_course_translation.py --lang sl
python scripts/check_course_translation.py --lang sl course_102_*
```

Preverjanje po tečajih javi: premaknjen skelet, pokvarjene oznake, število gesel, neregistrirane ključe, izraze,
parkirane na koncu odstavka, osamljene predloge pred ločilom, prepovedane znake (dovoljena sta le `»` in `«`),
presledke, francoske in angleške ostanke, uhajajoče žetone in nelokalizirana števila (presledek v tisočicah, rimsko
stoletje, `av. J.-C.`). Čist zagon je obveznost, ne predlog. Ponavljajočih se napak iz revizije validator ne vidi;
poišči jih ročno in popravi vse zadetke:

```bash
grep -rnE '\b([Vv]|[Pp]ri|[Oo]koli)\s+\**[0-9]{3,4}\**\b|\b(Želimo|živimo|Zahtevamo|doživljamo|beremo)\b|\]\][a-zčšž]|\b(Dobrodošel|Dobrodošli|Končal si|Pripravljen sem|si prebral|boš prebral|preživel|pametnejšega)\b|\blekcij|\bblocker|anti-scroll|\bRAV\.|\b(Hegira|Yathrib|Ummah|Ummet|Ovid|Echo|Jihad|razzias|naplata|Zaženi)\b|\b(črk|dolarjev|vranic\w*|lahkotnost|Pok|tastom|Potomci)\b|\bza (nadaljevanje|odkrivanje|razkritje|prikaz)\b|\\"|\.\.\.' content/courses/sl/ content/locales/sl/
```

Na koncu preberi na glas: ti v ednini, spol uporabnika nevtralen ali v obeh oblikah, »on« brezosebno, `Leta 622`,
sklon za številom in okoli `[[...]]`, imena sklonjena in v slovenski obliki, `»…«`.
