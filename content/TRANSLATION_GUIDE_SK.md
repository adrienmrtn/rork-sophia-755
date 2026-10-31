# Preklad kurzov: z francúzštiny do slovenčiny

Francúzsky text (`content/courses/fr/`) je zdroj; tento dokument je špecifikácia pre `content/courses/sk/`, ktorú
`scripts/check_course_translation.py --lang sk` kontroluje strojovo. Tie isté pravidlá platia pre rozhranie, kvízy,
slovník pojmov a katalóg (`content/locales/sk/`). Záväzná terminológia je celá v `content/terminology/`
(`termes_produit.json`, `mots_pieges.json`, `oeuvres.json`); všetky príklady „zle → správne“ sú z auditu
`docs/audit-traductions/sk.json`.

## 1. Čo chceme

Neodovzdávame preklad. Odovzdávame **slovenské vydanie** kurzu: text, ktorý by z tých istých poznámok napísal
slovenský redaktor. Čitateľ nesmie spoznať, že originál je francúzsky. V tomto poradí:

1. **Správne.** Nič neskresľuj, nevymýšľaj ani nevynechávaj. Viacvýznamové slovo čítaj z kontextu, nie podľa
   najčastejšieho anglického významu: `Napriek presile jeho verných` (en infériorité numérique) → `Hoci sú v
   menšine`; `uľahčuje inštaláciu novej energie` → `uľahčuje nástup novej moci`; `Zachytenie Mekky` → `Dobytie Mekky`.
2. **Plynulo.** Prirodzená slovenčina, ktorá sa nahlas prečíta bez zakopnutia. Žiadne bohemizmy: `Rádi ťa znova
   vidíme` → `Radi ťa znova vidíme`, `kurs` → `kurz`, `odemknout` → `odomknúť`.
3. **Jednoducho.** Krátke vety, bežné slová; zvedavý tínedžer to musí pochopiť bez námahy. Radšej `ukázal` ako
   `demonštroval`, `stelesňuje prekliateho básnika` ako `hrá základne prekliateho`.
4. **Verne tvaru.** Približne rovnaký počet viet, ten istý postup myšlienok, dĺžka v rámci dvadsiatich percent.

**Oslovenie je vždy ty**, v jednotnom čísle a vrúcne: v kurzoch, kvízoch, slovníku pojmov aj v rozhraní. Nikdy `Vy`,
`Vitajte`, `Vyskúšajte` ani rozkazovací spôsob na `-te`. Tlačidlo je neurčitok, jeden tvar v celej aplikácii
(`Vyskúšať zadarmo`, `Odomknúť Premium`, `Pokračovať`); „C'est parti“ je všade `Poďme na to`. Vo vete rozkazovací
spôsob 2. osoby jednotného čísla (`odomkni`, `zopakuj si`, `precvič si`). Na tlačidle ani `môj`, ani 1. osoba.

**Francúzske neosobné „on“ nie je nikdy „my“**, inak Sophia hovorí za postavy. Použi 3. osobu množného čísla bez
podmetu, `ľudia`, zvratné pasívum alebo `dá sa` / `možno` (`On dit que` → `Hovorí sa, že`). Skutočné „nous“ ostáva
(`notre regard` → `náš pohľad`) a aplikácia smie hovoriť v 1. osobe (`Radi ťa znova vidíme`).

**Rod používateľa.** Minulý čas (`dokončil` / `dokončila`) a prídavné meno (`pripravený`) nesú rod; používateľ je
chlapec aj dievča a mužský tvar nie je predvolený. Najprv sa rodu vyhni: prítomný čas, neosobná veta, podstatné meno,
výkrik. Až keď to nejde a miesta je dosť (nikdy na tlačidle), oba tvary: `objavil(a) si`, `pripravený(-á)`.
**Svedectvá** majú rod podpisu: Léa, Inès a Camille sú ženy; Terminale je `maturantka` / `maturant` (`Lea, maturantka`).

**Rod postáv a vecí** sa riadi slovenským slovom: `kniha` je ženského rodu, *Kvety zla* sú množné číslo (`Kvety zla
vyvolali`), NATO je v celom kurze stredného rodu, Echo je nymfa (ona), Narcis mladík (on). Keď sloveso rod neukazuje,
podmet nevypúšťaj; `svoj` sa vzťahuje na podmet. **Čas**: minulý, alebo historický prézent, ak ho drží francúzština;
jeden na odsek, nikdy kondicionál ani budúci čas pre minulý fakt. „Voici comment…“ je `Takto…`, `Pozri sa, ako…`.

| Pravidlo | Zle | Správne |
| --- | --- | --- |
| tlačidlo | `Spustiť skúšku` · `Spustiť bezplatnú skúšku` · `Idem do toho` / `Ideme na to` · `Odomknúť mojich -70 %` | `Vyskúšať zadarmo` · `Vyskúšať zadarmo` · `Poďme na to` · `Získať zľavu -70 %` |
| „on“ | `Chceme ho zabiť.` · `Žijeme tam v kmeňoch.` · `Požadujeme presnú kresbu a hladký povrch.` | `Chcú ho zabiť.` · `Ľudia tam žijú v kmeňoch.` · `Vyžaduje sa presná kresba a hladký povrch bez stôp po štetci.` |
| `dá sa` + nominatív | `Túto ponuku sa teraz nedá načítať.` | `Táto ponuka sa teraz nedá načítať.` |
| rod používateľa | `Dokončil si kurz` · `Si pripravený?` · `staň sa vzdelaným` | `Kurz máš za sebou!` · `Môžeme začať?` · `rozšír si obzory` |
| svedectvá (Léa, Inès) | `Predtým som na telefóne trávil 7 hodín denne… cítim sa múdrejší` · `cítim sa rozhľadenejší` | `Predtým som na telefóne trávila 7 hodín denne. Teraz len 40 minút so Sophiou a každý týždeň sa cítim múdrejšia.` · `cítim sa rozhľadenejšia` (na každej obrazovke rovnako) |
| rod vecí | `Kniha vyvolala škandál. Bol odsúdený…` (čitateľ rozumie: Baudelaire) · `NATO, ktorá bola založená` · `Freud publikovali` | `Kniha vyvolá škandál. Je odsúdená…` · `NATO, založené v roku 1949` · `Freud publikoval` |
| rod postáv | `Jej krása priťahuje každého` (o Narcisovi) · `Už nemá vlastný hlas. Oči má len pre seba.` | `Jeho krása priťahuje každého` · `Ona už nemá vlastný hlas. On má oči len pre seba.` |
| `svoj` a `sa` | `Veštec varoval svoju matku` (veštcovu) · `Echo sa môže len opakovať` | `Veštec varoval jeho matku` (Narcisovu) · `Echo môže len opakovať slová druhých` |
| čas | `by posolstvo… zničilo veľké impériá` · `povedal, že dostane zjavenia` · `Fínsko sa pripojí k aliancii v roku 2023` | `posolstvo… zvrhne veľké ríše` · `tvrdí, že od roku 610 dostáva zjavenia` · `Fínsko sa k aliancii pripojilo v roku 2023` |
| Voici comment | `Tu je návod, ako to všetko začalo.` | `Takto sa to všetko začalo.` |

**Kalky.** Sloveso namiesto podstatného mena, slovenské spojenie namiesto doslovného:

| Zle | Správne |
| --- | --- |
| `Takto rastie tvoje vedomie` · `10 minút kultúry` · `Horíš 🔥` | `Takto rastie tvoj rozhľad` · `10 minút vedomostí` · `Ide ti to skvele 🔥` |
| `Rasti v úrovniach` · `cestu, ktorú sleduješ každý deň` · `Sleduj tematické cesty` | `Postupuj na vyššie úrovne` · `cestu, ktorou pôjdeš každý deň` · `Choď tematickými cestami` |
| `Séria je na spadnutie!` · `nikdy v sérii` · `PRIJATÉ ŽIADOSTI` · `Na urobenie` | `Séria je na dosah!` · `nikdy hromadne` · `ŽIADOSTI O PRIATEĽSTVO` · `Nezačaté` |
| `Odomkni… pre interaktívne kvízy` · `tím profesorov… v službách jedinej misie` | `Odomkni…, získaj interaktívne kvízy` · `tím učiteľov… s jediným poslaním` |
| `Žiadny audio kurz nezodpovedá.` · `Stovky kurzov čaká` · `%d správne z %d` | `Žiadna nahrávka nezodpovedá hľadaniu.` · `Stovky kurzov čakajú` · `Správne: %d z %d` |

**Slová-pasce.** Prekladaj podľa francúzskeho kontextu (úplný zoznam: `mots_pieges.json`):

| Francúzsky (význam) | Slovensky | Nie |
| --- | --- | --- |
| essai gratuit; Léger / Modéré / Intense; la lumière; Gratuit; Mensuel / Annuel; Expire dans | skúšobné obdobie zadarmo; Ľahké / Mierne / Intenzívne; Svetlo; Zadarmo; Mesačne / Ročne (`mesačné predplatné`); `Vyprší o 2 dni 4 h` | `skúška` (= examen); `Svetlo` pre léger; ľahkosť; voľný; časopis, ročenka |
| culture générale, cultivé; anecdotes; trimestre; Pas de connexion; la personne la plus intéressante de la pièce | všeobecný rozhľad, rozhľadený; zaujímavosti; trimester (radšej `polrok`); `Žiadne pripojenie`; najzaujímavejší človek v spoločnosti | `kultúra`, `vedomie`; vtipy; mandát; `nevadí`; `v priestore` |
| Reprends du temps pour toi; Glisse pour découvrir; l'offre (paywall) | `Získaj späť svoj čas`; `Potiahni a objav`; `Ponuka Premium` | doslovné „vezmi si čas dozadu“; vymyslené slovesá; platobná stena |
| spleen; flâneur; caravane; deux états (d'âme); condamnation; beau-père (Aupick); postérité; source (eau) | splín; flâneur (pozorovateľ-tulák po meste); karavána; dva stavy (duše); odsúdenie, súdny rozsudok; nevlastný otec; budúce generácie, odkaz; prameň | `slezina`; `kočík`; obytný príves; dva štáty; `presvedčenie`; `svokor`; `potomstvo`; `zdroj` |
| ans; hommes (vojaci); poèmes; plaques (photo); pétrole; gravité; failles; cellulaire; pouvoir | rokov; mužov, vojakov; básne; fotografické platne; ropa; gravitácia; zlomy (pri chybách trhliny, slabiny); bunkový; moc | listov; dolárov; básnikov; taniere; olej; vážnosť; poruchy; mobilný; `energia` |
| Grande Dépression; soupe populaire; bank runs; relance; offshore; Renaissance; naturalisme | veľká hospodárska kríza; vývarovňa; hromadné vyberanie vkladov; oživenie ekonomiky; offshore, daňový raj; renesancia; naturalizmus | depresia; polievková kuchyňa; „banka beží“; uzdravenie; šíre more; národné obrodenie; naturizmus |
| touche; sensation; chute (d'un empire); puissant; réel; clé (de lecture); estampes; costume | ťah štetcom (klavír: klávesa); vnem; pád; mocný; skutočný; kľúč k pochopeniu; drevorezy; oblek | `dotyk`; senzácia; jeseň; výkonný; reálny; zámok; `výtlačky`; `kostým` |

## 2. Kostra ostáva

Prekladajú sa iba textové polia. Zvyšok nástroj skopíruje z francúzskej kostry a nesiahaš naň: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Pole | Čo to je | Poznámka |
| --- | --- | --- |
| `title` / `subtitle` / `description` / `hero.hook` | Názov / riadok pod ním / dvojvetný úvod / návnada | Pri diele slovenský vydaný názov. Rok alebo rozsah (`1945-1975`) ostáva. Úvod stojí sám; návnada je reklama, nie próza. |
| `sections[].title` | Názov časti | Menná fráza, veľké písmeno len na začiatku, bez bodky. |
| `paragraph.text` / `image.caption` | Súvislý text / popis obrázka | Hlavná práca. Popis krátky; bodka len za celou vetou. |
| `funFact.text` / `takeaway.text` | Rámček / záver | Ľahko, hovorovo. To, čo má ostať v pamäti. |
| `quote.text` / `quote.attribution` | Citát / kto ho povedal | Pozri §6. |
| `timeline.events[].date` | `1789`, `jún 1940`, `okolo 450 pred n. l.` | Číslice ostávajú, mesiac malým písmenom, nikdy `av. J.-C.`. |
| `timeline.events[].title` / `.detail` | Štítok / jedna veta | Štítok veľmi krátky, bez bodky. |

**Termíny produktu** sú v celej aplikácii jednotné (`termes_produit.json`):

| Francúzsky | Slovensky | Nie |
| --- | --- | --- |
| quiz; cours; Parcours; collection | kvíz (`mini kvíz`, `kvízu`); kurz (`Neobmedzené kurzy`); cesta (záložka `Cesty`); kolekcia | quiz, písomka, skúška; `lekcia`, kurs; trasa, priebeh; zbierka (tá je pre básne) |
| niveau, NIV. 3; série (streak); essai gratuit | úroveň, `Úr. 3`; séria (`Tvoja séria: 5 dní`); skúšobné obdobie zadarmo | level, stupeň; seriál, pruh; `skúška` |
| Premium; Sophia | Premium (nesklonné: `s Premium`, `odomkni Premium`); Sophia (`so Sophiou`, `v Sophii`) | prémia, prémiový; `Sofia` |
| bloqueur TikTok | blokátor (`TikTok blokátor`, `s blokátorom`; `odblokovať` len pri ňom) | blocker, `s blockerom` |
| Entraînement; réviser; abonnement; débloquer | Tréning (sloveso `precvič si`); opakovať (`Zopakuj si kurz`, `opakovanie`); predplatné; odomknúť | prax; revidovať, preskúmať; odber, členstvo; odblokovať, odemknout |
| objectif; matière / sujet; ami | cieľ; predmet / téma; priateľ (`žiadosť o priateľstvo`) | objektív; matéria; kamarát vo funkcii priateľov |
| glossaire; XP; Bibliothèque | slovník pojmov; XP (`50 XP`, nesklonné); Knižnica | glosár; `body skúseností`; bibliotéka, katalóg |
| progression; appuyer; notification; mode audio; terminés | pokrok; ťukni; oznámenie; Audio režim; Dokončené | postup; klepni; notifikácia; Zvukový režim; Hotové |

## 3. Značky v riadku

Tri značky musia prežiť: `**tučné**` (roky, čísla, mená a diela, o ktorých odsek hovorí), `*kurzíva*` (názov diela v
próze) a `[[pojem]]` (heslo slovníka pojmov; ťuknutie otvorí vysvetlenie).

- Značky idú v pároch; nepárny počet `**` je chyba. Nepridávaj tučné, ktoré vo francúzštine nie je, ani celú vetu.
- Žiadna značka nepohltí medzeru ani interpunkciu: `**1945**,` je správne, `**1945,**` a `** 1945 **` sú zle.
- Radová bodka patrí do tučného spojenia (`**7. storočie**`, `**24. februára 2022**`); tučné sa však nekončí bodkou:
  `**7.** storočí` aj `**1857.**` validátor prečíta ako koniec vety.
- Tučne označ slovenský ekvivalent, nie tie isté znaky: `**30 000 mots**` → `**30.000 slov**`. Pri roku zvýrazni
  číslo, nie slovo `roku`: `V roku **1857**`.

## 4. Heslá slovníka pojmov: najdôležitejšie pravidlo

Každé francúzske `[[...]]` dá presne jedno slovenské `[[...]]`, **vo vete, na tom istom mieste v toku myšlienky**.
Pojem nikdy neparkuj na konci odseku. Nenechávaj dieru. Je to jedna a tá istá chyba:

> Zle: `oslabená predovšetkým : kresťanskí križiaci vyplienili mesto. [[Dobytie Konštantínopolu]]`
>
> Správne: `Mesto oslabilo predovšetkým [[dobytie Konštantínopolu počas štvrtej krížovej výpravy (1204)]], keď západní
> križiaci mesto vyplienili.`

Text pojmu je kľúč registrovaný pre tento kurz v `ios/Sophia/Resources/Locales/glossary.sk.json`; neznámy kľúč ostane
mŕtvym textom. Brief zo `scripts/make_translation_briefs.py` vymenuje povolené kľúče; použi jeden znak po znaku, s
veľkými písmenami ako v registri. Nedávaj namiesto krátkeho hesla celý nadpis (`**[[Symbolizmus a Baudelairov
odkaz]]**` za `[[symbolisme]]`) a nezamieňaj heslá. Kľúč, ktorý sám porušuje §5 (`Ummah`, `razzias`, `jizya`, `Oread`,
`Le Spleen de Paris`, `Baudelairovská "slezina"`, `Prozaická báseň`, `Japonské výtlačky`, `Salón des Refusés`,
odseknuté `Medinskú`), oprav v `glossary.sk.json` pre celý kurz naraz (`umma`, `razzie`, `džizja`, `oreáda`, `Parížsky
splín`, `splín`, `báseň v próze`, `japonské drevorezy`, `Salón odmietnutých`, `Ústava Mediny`), nie iba v jednom
odseku. Najprv kľúč, potom text.

Veta musí byť gramatická **s vloženým pojmom**. Slovenčina má šesť pádov a kľúč má pevný tvar:

- Nič nelep za `]]`: `[[kalif]]a`, `[[kalif]]om`, `[[Echo]]u` sú zle. Validátor to v slovenčine nevidí; skontroluj
  ručne (§9). Slovenčina nemá členy: nedávaj pred kľúč `ten`, `tá`, `to` ako náhradu francúzskeho `le` / `la`.
- Postav pojem tam, kde veta žiada jeho pád: podmet (`Paríž prestavuje **[[Barón Haussmann]]**`), menný prísudok
  (`Abú Bakr je prvý [[kalif]]`), za dvojbodkou, za `známy ako`, `vošiel do dejín ako`, `nazýva sa`.
- Názov diela, inštitúcie či hnutia ostáva v nominatíve za druhovým podstatným menom, ktoré nesie pád: `v zbierke
  [[Parížsky splín]]`, `v diele [[Metamorfózy]]`, `s románom [[Pani Bovaryová]]`.
- Kľúč v inom páde (`beduínov`, `kyberpriestoru`, `Severoatlantickej zmluvy`) žiada vetu, ktorá ten pád potrebuje:
  `kmene [[beduínov]]`, `útoky z [[kyberpriestoru]]`, `článok 5 [[Severoatlantickej zmluvy]]`.

| Zle | Správne |
| --- | --- |
| `Žijeme tam v kmeňoch. [[beduínov]], púštni nomádi, žijú vedľa niekoľkých obchodných miest.` | `Ľudia tam žijú v kmeňoch. Väčšinu tvoria kmene [[beduínov]], púštnych kočovníkov, a popri nich stojí niekoľko obchodných miest ako Mekka.` |
| `Pod **[[Barón Haussmann]]** sa Paríž mení.` | `Paríž prestavuje **[[Barón Haussmann]]**: široké bulváry, nové domy.` |
| `Napísal [[Medinskú]] ústavu… a založil La Oumma.` | `Spisuje dohodu medzi klanmi, ktorá vošla do dejín ako [[Ústava Mediny]], a tak vzniká [[umma]], spoločenstvo veriacich.` |
| `podniká nájazdy, rýchle nájazdy` (pojem stratil značku) | `podniká [[razzie]], rýchle nájazdy, aby odrezal nepriateľské karavány` |
| `Túto pozornosť mestu pripravuje **[[Prozaická báseň]]**` (podmet a predmet prehodené) | `Táto pozornosť venovaná mestu pripravuje pôdu pre **[[báseň v próze]]**.` |

Predložka pred interpunkciou (`na ,`, `pod .`, `že .`) je prázdne miesto po pojme. Ak kľúč nesedí, prestav vetu, nie
kľúč.

## 5. Vlastné mená

**Osobné meno ani priezvisko neprekladaj.** Strojový preklad ich číta ako obyčajné slová: Degas ostáva Degas, Munch
ostáva Munch (`Muncha`, `Munchovi`, nie „žuť“), boh Pan ostáva Pan (`Pana`, `Panovi`), nie `Bang`.

**Cudzie meno sa skloňuje**, ako v každom slovenskom texte. Ženské priezviská v próze dostávajú `-ová` (`Jeanne
Duvalová`, *Denník Anny Frankovej*).

| Zle | Správne |
| --- | --- |
| `Kritik sa vysmieva Monet` · `Skupina združuje **Monet**, **Renoir**` · `s generálom **Aupick**` · `Miluje **Jeanne Duvalová**` | `Kritik sa vysmieva Monetovi` · `združuje **Moneta**, **Renoira**` · `s generálom **Aupickom**` · `Miluje **Jeanne Duvalovú**` |
| `vyhrali na **Badr**` · `umenie riadilo **Akadémia výtvarných umení**` · `Pomáha **Zeus**` · `zdržiava **Hera**` | `zvíťazia pri **Badre**` · `umenie sa riadilo **Akadémiou výtvarných umení**` · `Pomáha **Diovi**` · `zdržiava **Héru**` |
| `Muhammad` / `Mohamed` striedavo · `Tento odchod je **Hegire**` · `založil La Oumma` · `Jeho myšlienka **O jedného Boha**` | `Mohamed` v celom kurze · `Tento odchod je **hidžra**` · `a tak vzniká [[umma]]` · `Jeho myšlienka **jediného Boha**` |
| `NATO v angličtine a NATO vo francúzštine` · `Veštec **Tirésias**` · `je [[Oread]]` | `NATO v angličtine a OTAN vo francúzštine` · `Veštec **Teiresias**` · `je [[oreáda]]` |

**Zaužívaná slovenská podoba**, rovnaká v celom kurze: `Christophe Colomb` → `Krištof Kolumbus`, `Guillaume le
Conquérant` → `Viliam Dobyvateľ`, `Londres` → `Londýn`, `Pékin` → `Peking`, `Aix-la-Chapelle` → `Cáchy`, `Charlemagne`
→ `Karol Veľký`, `Tchernobyl` → `Černobyľ`, `Michel-Ange` → `Michelangelo`, `Byzance` → `Byzancia`, `roi Arthur, reine
Guenièvre` → `kráľ Artuš, kráľovná Ginevra` (nie cár), `Siège périlleux` → `Nebezpečné sedadlo`, `ONU` → `OSN`, `URSS`
→ `ZSSR`, `OTAN` → `NATO`. Mýty: Narcis (`narcis` je kvet, malým), Echo (nymfa), Teiresias, Zeus (`Dia`, `Diovi`),
Héra, Nemesis (bohyňa pomsty, nie „nepriateľ“), Ovídius, oreáda. Islam: `Mohamed`, `Mekka` (`do Mekky`), `Medina`,
`Jasrib`, `Kaaba` (`do Kaaby`), `hidžra` malým (`letopočet podľa hidžry`), `umma`, `kalif`, `džizja`, `dhimma`,
`džihád`, `razzia` (`razzie`), `beduíni`, `kmeň Kurajšovcov`; nikdy `Hegira`, `Ummah`, `razzias`, `jizya`.

**Názov diela je názov slovenského vydania**, nie doslovný preklad (úplný zoznam: `oeuvres.json`):

| Oblasť | Francúzsky → slovensky |
| --- | --- |
| Baudelaire | *Les Fleurs du Mal* → *Kvety zla*; *Le Spleen de Paris* → *Parížsky splín*; oddiely a básne v úvodzovkách: „Spleen et Idéal“ → „Splín a ideál“, „Tableaux parisiens“ → „Parížske obrazy“, „Correspondances“ → „Súzvuky“, „Recueillement“ → „Rozjímanie“ |
| Romány 20. storočia | *La Ferme des animaux* → *Zvieracia farma*; *1984*; *Le Meilleur des mondes* → *Prekrásny nový svet*; *Fahrenheit 451* → *451 stupňov Fahrenheita*; *Le Procès* → *Proces*; *La Métamorphose* → *Premena*; *Le Maître et Marguerite* → *Majster a Margaréta*; *Les Raisins de la colère* → *Hrozno hnevu*; *Ne tirez pas sur l'oiseau moqueur* → *Zabiť vtáčika*; *Gatsby le Magnifique* → *Veľký Gatsby*; *Le Seigneur des anneaux* → *Pán prsteňov*; *Cent ans de solitude* → *Sto rokov samoty*; *Le Petit Prince* → *Malý princ*; *L'Alchimiste* → *Alchymista* |
| Klasika | *Hamlet*; *Roméo et Juliette* → *Rómeo a Júlia*; *Don Quichotte* → *Don Quijote*; *Frankenstein*; *Moby Dick*; *Crime et Châtiment* → *Zločin a trest*; *Les Misérables* → *Bedári*; *Madame Bovary* → *Pani Bovaryová*; *Le Rouge et le Noir* → *Červený a čierny*; *Candide* → *Candide alebo Optimizmus*; *Les Confessions* → *Vyznania*; *Le Père Goriot* → *Otec Goriot*; *Notre-Dame de Paris* → *Chrám Matky Božej v Paríži*; *À la recherche du temps perdu* → *Hľadanie strateného času*; *L'Étranger* → *Cudzinec*; *Le Mythe de Sisyphe* → *Mýtus o Sizyfovi*; *Le Prince* → *Vladár*; *Le Journal d'Anne Frank* → *Denník Anny Frankovej* |
| Staroveko | *L'Odyssée* → *Odysea*; *L'Iliade* → *Iliada*; *Œdipe roi* → *Kráľ Oidipus*; *Antigone* → *Antigona*; *Médée* → *Médeia*; *Le Banquet* → *Hostina*; *La République* → *Ústava*; *Apologie de Socrate* → *Obrana Sokrata*; *La Poétique* → *Poetika*; *Les Travaux et les Jours* → *Práce a dni*; *L'Épopée de Gilgamesh* → *Epos o Gilgamešovi* |
| Výtvarné umenie | *Impression, soleil levant* → *Impresia, východ slnka* (nie `Tlač, vychádzajúce slnko`); *Le Déjeuner sur l'herbe* → *Raňajky v tráve* (nie `Obed v tráve`); *Les Demoiselles d'Avignon* → *Avignonské slečny*; *Le Cri* → *Výkrik*; *La Joconde* → *Mona Lisa*; *La Nuit étoilée* → *Hviezdna noc*; *Guernica*; *La Liberté guidant le peuple* → *Sloboda vedie ľud*; *La Création d'Adam* → *Stvorenie Adama*; *La Persistance de la mémoire* → *Perzistencia pamäti*; *La Ronde de nuit* → *Nočná hliadka*; *La Vénus de Milo* → *Venuša z Milu*; *Nighthawks* ostáva |
| Film a hudba | *Citizen Kane* → *Občan Kane*; *2001, l'Odyssée de l'espace* → *2001: Vesmírna odysea*; *Psychose* → *Psycho*; *Sueurs froides* → *Vertigo*; *Fenêtre sur cour* → *Okno do dvora*; *La Corde* → *Povraz*; *Le Sacre du printemps* → *Svätenie jari*; *Aïda* → *Aida*; *The Freewheelin' Bob Dylan* a *Rapper's Delight* ostávajú |

Ďalej: `Académie des beaux-arts` → `Akadémia výtvarných umení`, `Salon des Refusés` → `Salón odmietnutých`, `Musée
d'Orsay` → `múzeum Orsay`, `New Deal` ostáva. *1984*: `Big Brother` → `Veľký Brat`, kľúče `Newspeak` a `doublethink`.
*Zvieracia farma*: Napoleon, Boxer (Malabar), starý Major; ostatné postavy podľa slovenského vydania, inak anglický
originál (Snowball, Squealer), nikdy kalk z francúzštiny; zapíš ich do `scripts/proper_nouns.json` (`per_language` →
`sk`). Bez slovenského názvu ostáva originál, pri prvej zmienke vysvetlený. V kurze je názov `*kurzívou*` a smie sa
skloňovať (`v Kafkovom *Procese*`); v rozhraní a kvíze v úvodzovkách (`Kto napísal zbierku „Kvety zla“?`).

## 6. Citáty

Citát nie je prekladateľské cvičenie. Ak existuje kanonické slovenské znenie, použi ho. Inak prelož krátko a čisto.

- Úvodzovky `„…“` (dolná U+201E, horná U+201C). Nikdy rovné `"…"` ani francúzske `« »`: `Narcisse volá: "Je tu
  niekto?"` → `Narcis volá: „Je tu niekto?“`; `**"Korespondencia"**` → `**„Súzvuky“**`. Citát v citáte nestavaj (`‘`
  je zakázané); prestav vetu alebo použi kurzívu.
- Bodka samostatnej citovanej vety je vnútri úvodzoviek (`„Všetky zvieratá sú si rovné.“`); citát vo vnútri vety ju
  má vonku: `Je odsúdená za „urážku verejnej morálky“.`
- `quote.attribution` je `Autor, Dielo`; báseň v úvodzovkách: `Charles Baudelaire, „Súzvuky“`. Ak francúzština dáva
  hovoriaceho za pomlčku, použi čiarku alebo zátvorku: `Victor Hugo, Bedári (biskup Myriel)`.
- Kanonický citát zo *Zvieracej farmy*: `„Všetky zvieratá sú si rovné, ale niektoré sú si rovnejšie.“`

## 7. Interpunkcia a typografia

- **Žiadna dlhá `—` ani krátka pomlčka `–`**, hoci ich slovenčina inak rada používa. Prestav vetu čiarkou, dvojbodkou,
  zátvorkou alebo bodkou: `Táto tolerancia – usmernená – uľahčuje` → `Táto usmernená tolerancia uľahčuje`. Rozsah v
  poli `subtitle` a na časovej osi so spojovníkom bez medzier: `610-632`, `1945-1975`; v próze slovami: `v rokoch 610
  až 632`, `14. až 16. storočie`, `30-100 € / mesiac` → `30 až 100 € mesačne`.
- Žiadne `« »`, nulová medzera, nezlomiteľná medzera (U+00A0) ani BOM. Apostrof je rovný `'` (U+0027): `Musée
  d'Orsay`, nie `d’Orsay`.
- Pred interpunkciou nikdy medzera, nikdy dve medzery za sebou; za `, : ;` medzera (okrem `02:59` a `3,5`).
  Bodkočiarku zriedka: náučný text má rád bodku. Čiarka pred `že`, `ktorý`, `keď`, `aby`, `ak`, `hoci`; nie pred `a`
  v jednoduchom priraďovaní. Tri bodky sú jeden znak `…`.
- Všeobecné mená malým: `kresťania`, `moslimovia`, `renesancia`, `impresionizmus`, `veľká hospodárska kríza`,
  `hidžra`. Pravopis: `cenzurovaných`, nie `cenzúrovaných`. Žiadne francúzske (`siècle`, `dans`, `l'`, `Salón des
  Refusés`) ani anglické zvyšky (`blocker`, `Oread`): vetu napíš nanovo.

## 8. Čísla, dátumy, miery

| Čo | Pravidlo | Zle → správne |
| --- | --- | --- |
| Tisícky | Slovenská norma píše medzeru, ale bežnú medzeru validátor hlási a nezlomiteľná je zakázaná. Domáca konvencia: štvorciferné spolu, od piatich číslic bodka. Nikdy čiarka. | `30 000` → `30.000`; `so **10 000 mužmi**` → `so **10.000 mužmi**`; oprava auditu `3 000 obrazov` → `3000 obrazov`; `4500 km` |
| Desatinné, percentá, peniaze | Desatinná čiarka; percentá s bežnou medzerou podľa pravopisu, prídavné meno so spojovníkom; `Mds` / `Md` / `M` slovom. | `3,5%` → `3,5 %`; `-70 %`; `70-percentný`; `9,99 €`; `2 Mds` → `2 miliardy`, `5 M` → `5 miliónov` |
| Pád po čísle | 1 → nominatív j. č., 2 až 4 → nominatív mn. č., od 5 genitív mn. č.; sloveso po 5+ v strednom rode j. č., po `stovky` v mn. č. Kľúče `one` / `few` / `many` / `other` majú každý svoj tvar. | `1 kvíz`, `3 kvízy`, `5 kvízov`; `šesť básní`; `Päť básní bolo odsúdených`; `Stovky kurzov čaká` → `čakajú`; `%d kurz` / `%d kurzy` / `%d kurzu` / `%d kurzov`; `s 10.000 mužmi`, `pred 92 rokmi` |
| Vek a trvanie | `ans` sú roky; pri veku bez rodu, alebo podľa rodu osoby. | `à 6 ans` → `vo veku 6 rokov` / `ako 6-ročná`; `en 22 ans` → `za **22 rokov**`; `il a 20 ans` → `má 20 rokov` |
| Rok | Vždy so slovom `rok` v správnom páde; zvýrazni len číslo. 138 viet v kurzoch má `V` bez `roku`. | `V **622**` → `V roku **622**`; `V **1857**` → `V roku **1857**`; `Vers 630` → `Okolo roku **630**`; `dès 610` → `od roku **610**`; `jusqu'en 632` → `do roku 632`; `na **Badr** v 624` → `pri **Badre** v roku **624**`; `dans 1984` → `v románe *1984*` |
| Dátum | V texte mesiac v genitíve malým, bodka za dňom; na časovej osi nominatív. Jedna schéma na kurz. | `**24. februára 2022**`; `v júni 1940`; os: `jún 1940`; `od 13. marca do 7. mája 1954` |
| Storočie | Arabská číslica s bodkou, bez posunu (601 až 700 je 7. storočie); pozor na lokál. | `VIIe siècle` → `7. storočie`, `v 7. storočí`; `XIVe-XVIe siècle` → `14. až 16. storočie`; nie `XVe`, `VII. storočie`, `7 storočie`, `600-te roky`; `années 1920` → `20. roky 20. storočia` |
| Letopočet a hidžra | `pred n. l.` a `n. l.` s bežnými medzerami, nikdy `av. J.-C.`. Hidžra je slovenské slovo, skloňuje sa. | `450 av. J.-C.` → `450 pred n. l.`; `Hegire v 622` → `hidžra v roku 622`; `l'an 1 de l'Hégire` → `1. rok hidžry` |
| Miery a hra | Nič neprepočítavaj; metrické ostáva metrické. XP a úrovne podľa §2. | `50 XP`; `Úr. 3`; `120 XP do 5. úrovne` |

## 9. Kontrola

```bash
python scripts/check_course_translation.py --lang sk
python scripts/check_course_translation.py --lang sk course_102_*
python scripts/check_terminology.py --lang sk -v
```

Validátor hlási kostru, značky, heslá (počet, registrácia, parkovanie), osamotené predložky (`na ,`, `že .`), zakázané
znaky (`—`, `–`, `« »`, `’`, `‘`, U+00A0), medzery, francúzske a anglické zvyšky, žetóny a čísla (`30 000`, `XVe`,
`av. J.-C.`); `check_terminology.py` termíny produktu, názvy diel a slová-pasce. Čistý beh je povinnosť. Chyby z
auditu nevidí; hľadaj ich ručne:

```bash
grep -rnE '\b[Vv] \**[0-9]{3,4}\**\b|\b(Chceme|Žijeme|Požadujeme|Modlíme sa)\b|\]\][a-záäčďéíĺľňóôŕšťúýž]|\b(trávil|múdrejší|rozhľadenejší|Rádi|kurs)\b|\b[Ss]kúšk(a|u|y|ou|e)\b|\blekci|\bblocker|\bklepni\b|notifikáci|Zvukový režim|\b(Hegire|Hegira|Narcisse|Tirésias|Oread|Oumma|Ummah|razzias|jizya|Bang)\b|\b(slezin\w*|kočík\w*|presvedčeni\w*|výtlačk\w*|svokr\w*)\b|Tu je návod|NATO\**, ktorá|\\"|\.\.\.' content/courses/sk/ content/locales/sk/
```

Nakoniec čítaj nahlas: ty v jednotnom čísle, rod používateľa neutrálny alebo v oboch tvaroch, svedectvá žien v ženskom
rode, „on“ neosobne, `v roku 622`, pád po čísle a okolo `[[...]]`, mená skloňované a v slovenskej podobe, `„…“`.
