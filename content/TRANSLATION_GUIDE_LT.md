# Kursų vertimas: iš prancūzų kalbos į lietuvių

Prancūziškas tekstas (`content/courses/fr/`) yra šaltinis; šis dokumentas yra `content/courses/lt/`
specifikacija, o `scripts/check_course_translation.py --lang lt` ją tikrina automatiškai. Tos pačios
taisyklės galioja sąsajai, viktorinoms, žodynėliui, katalogui, App Store puslapiui ir teisiniams tekstams.
Privaloma terminija pateikta `content/terminology/` (`termes_produit.json`, `mots_pieges.json`,
`oeuvres.json`, `sentinelles.json`). Verčiama tik iš prancūzų kalbos, niekada iš anglų.

## 1. Ko siekiame

Mes neperduodame vertimo. Perduodame **lietuvišką kurso leidimą**: tekstą, kurį gimtakalbis redaktorius
būtų parašęs iš tų pačių užrašų. Skaitytojas neturi pajusti, kad originalas buvo prancūziškas. Tokia tvarka:

1. **Teisinga.** Neiškraipyk, neišgalvok ir nepraleisk faktų. Datas patikrink: `**18 juin 1815**` →
   `**1815 m. birželio 18 d.**`.
2. **Sklandu.** Natūrali lietuvių kalba, kuri garsiai skaitant neužkliūva.
3. **Paprasta.** Trumpi sakiniai, kasdieniai žodžiai; smalsus paauglys turi lengvai sekti mintį.
4. **Ištikima formai.** Maždaug tiek pat sakinių, ta pati minties eiga, ilgis ±20 %.

**Į naudotoją kreipiamės „tu“**, vienaskaita, šiltai, kaip šiuolaikinės lietuviškos mokymosi programėlės.
Niekada `jūs`, `jūsų`, daugiskaitos liepiamosios `-kite`. Mygtukuose antrasis asmuo arba bendratis
(`Pradėk`, `Tęsti`), bet viename ekrane vienodai. Ant mygtuko `savo`, ne `mano`.

> Fr.: `Découvre les dieux et les héros` · `TON PROFIL` · `Combien de temps passes-tu sur ton téléphone ?`
> Neteisinga: `Susipažinkite su dievais ir herojais` · `JŪSŲ PROFILIS` · `Kiek laiko praleidžiate telefone?`
> Teisinga: `Susipažink su dievais ir herojais` · `TAVO PROFILIS` · `Kiek laiko praleidi telefone?`

Tikslų sąraše prancūzų bendratis lieka bendratimi: `Impressionner mon entourage` → `Nustebinti artimuosius`.

**Prancūzų beasmenis „on“ nėra nei „mes“, nei „jie“.** Lietuviškai tinka neveikiamoji rūšis, beasmenė
konstrukcija arba vienaskaitos 3 asmuo be veikėjo. Tikras „nous“ (`notre façon de regarder`) gali likti `mes`.

> Fr.: `On veut le tuer.` · `On y vit en tribus.` · `On dit que les données sont le nouveau pétrole.`
> Neteisinga: `Mes norime jį nužudyti.` · `Jie sako, kad duomenys yra naujas aliejus.`
> Teisinga: `Jį norima nužudyti.` · `Ten gyvenama gentimis.` · `Sakoma, kad duomenys yra naujoji nafta.`

**Giminė.** Lietuvių kalboje veiksmažodžio dalyviai ir būdvardžiai derinami pagal giminę, todėl apie
naudotoją venk formų, kurios priverstų rinktis (`Esi pasiruošęs?`). Rinkis neutralias konstrukcijas:
`Ar gali pradėti?`, `Puikus darbas!`, `Tau pavyko!`. Liudijimų autorės lieka
moterys per vardą (`Inès, 12 klasė`); vardų nelietuvink (`Sarah, 26`). Moteriškosios giminės daiktavardis
tik ten, kur įprasta (`karalienė Gvinevra`, `deivė Nemezidė`).

**Laikas ir kalkės.** Istorinis esamasis laikas (`1874 m. jie surengia parodą`) natūralus, bet vienoje
pastraipoje laikų nekeisk. `Voici comment tout a commencé.` → `Taip viskas ir prasidėjo.` (ne `Štai kaip
viskas prasidėjo`). `fondée par Mahomet` → `Muhammado įkurta` (ne `įkurta Muhammado dėka`). `De la gravité
à l'ADN` → `Nuo gravitacijos iki DNR`. Venk `yra` perteklinio vartojimo ir `pilnai`, `pagalba` (priemonė).

**Klaidinantys žodžiai.** Versk pagal sakinį, ne pagal dažniausią angliškąją reikšmę:

| Prancūziškai (reikšmė) | Lietuviškai | Ne |
| --- | --- | --- |
| Léger / Modéré / Intense; Gratuit | Lengvas / Vidutinis / Intensyvus; Nemokamai | `Šviesa`; `Laisvas` |
| Expire dans; Mensuel / Annuel | `Baigiasi po 02:59:59`; Mėnesinė / Metinė | `Pasibaigia metais`; `žurnalas` |
| culture générale; anecdotes; Terminale; trimestre | bendrosios žinios, akiračio plėtimas; įdomūs faktai; 12 klasė; trimestras | `kultūra`; `anekdotai` |
| Pas de connexion; Glisse pour découvrir | Nėra ryšio; `Perbrauk ir atrask` | `Nėra prisijungimo`; `Braukite` |
| la personne la plus intéressante de la pièce | įdomiausias žmogus kompanijoje | `kambaryje` |
| spleen; flâneur; caravane; deux états (d'âme) | splinas; flaneris, klajūnas; karavanas; dvi sielos būsenos | `blužnis`; `vežimėlis`; `kemperis`; `dvi valstybės` |
| condamnation; beau-père (Aupick); réhabilitation | nuosprendis, pasmerkimas; patėvis; reabilitacija | `įsitikinimas`; `uošvis`; `reabilitacijos centras` |
| gravité; failles; pétrole; cellulaire; plaques | gravitacija; lūžiai, spragos; nafta; ląstelinis; fotoplokštelės | `rimtumas`; `klaidos`; `aliejus`; `mobilusis`; `lėkštės` |
| 10 000 hommes; six poèmes; à 6 ans | 10 000 vyrų; šeši eilėraščiai; būdamas 6 metų | `dolerių`; `poetai`; `6 metai` |
| berger; marine (tableau); tribut; nordique; État | piemuo; marina, jūros peizažas; duoklė; Šiaurės; valstybė | `aviganis`; `laivynas`; `pagarba`; `Norvegijos`; `štatas` |
| Grande Dépression; soupe populaire; relance | Didžioji depresija; nemokama valgykla; ekonomikos skatinimas | `pasveikimas` |
| chute; sensation; touche; réel; clé de lecture | kritimas, žlugimas; pojūtis; potėpis, klavišas; tikras; skaitymo raktas | `ruduo`; `sensacija`; `mygtukas` |

## 2. Skeletas nesikeičia

Verčiami tik teksto laukai. Visa kita įrankis nukopijuoja iš prancūziško skeleto, o tu to neliesk: `id`,
`subject`, `subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Laukas | Kas tai | Pastaba |
| --- | --- | --- |
| `title` / `subtitle` | Pavadinimas / eilutė po juo | Kūriniui – lietuviško leidimo pavadinimas. Metai (`1945-1975`) lieka. |
| `description` / `hero.hook` | Dviejų sakinių pristatymas / kabliukas | Turi būti suprantamas atskirai. Reklama, ne proza. |
| `sections[].title` | Skyriaus pavadinimas | Daiktavardinė frazė, mažosiomis, be taško. |
| `paragraph.text` | Vientisas tekstas | Pagrindinis darbas. |
| `image.caption` | Paveikslėlio parašas | Trumpas; taškas tik po pilno sakinio. |
| `funFact.text` / `takeaway.text` | Langelis / santrauka | Lengva, pokalbio tonu. |
| `quote.text` / `quote.attribution` | Citata / kas pasakė | Žr. §6. |
| `timeline.events[].date` | `1789`, `1940 m. birželis`, `apie 450 m. pr. Kr.` | Skaičiai lieka, mėnesiai mažąja raide. |

**Vietos rezervavimo ženklai** kopijuojami tiksliai, nekeičiant tvarkos tipo: `%@`, `%d`, `%lld`, `%1$@`,
`%2$d`, `{n}`, `{name}`, `\n`. Nevertink, neversk, neatskirk tarpu nuo jų skyrybos ženklų. Kadangi lietuvių
kalba linksniuoja, sakinį statyk taip, kad į ženklą patektų forma, kuriai linksnis nereikalingas:

> Fr.: `Bienvenue, %@ !` → Neteisinga: `Sveikas, %@!` (giminė) · Teisinga: `Sveiki atvykę, %@!` arba `Labas, %@!`
> Fr.: `Cours de %@` → Neteisinga: `%@ kursas` (kilmininkas nežinomas) · Teisinga: `Kursas: %@`
> Fr.: `Premium à %@ (facturé annuellement)` → `Premium už %@ (mokama kartą per metus)`

## 3. Žymės eilutėje

Trys žymės turi išlikti: `**paryškinimas**` (datos, skaičiai, vardai ir kūriniai, apie kuriuos pastraipa),
`*kursyvas*` (kūrinio pavadinimas prozoje) ir `[[terminas]]` (žodynėlio įrašas; palietus atsidaro apibrėžimas).

- Žymės eina poromis. Nelyginis `**` skaičius yra klaida.
- Žymė nepraryja tarpo ar skyrybos ženklo: `**1945**,` teisinga, `**1945,**` ir `** 1945 **` klaidingos.
  Santrumpa lieka už žymės: `**1857** m.`, ne `**1857 m.**` (nebent fr. paryškinta visa data).
- Paryškinamas lietuviškas atitikmuo: `**30 000 mots**` → `**30 000 žodžių**`.
- Nepridėk paryškinimų, kurių nėra originale. Neparyškink viso sakinio.

## 4. Žodynėlio įrašai: svarbiausia taisyklė

Kiekvienas prancūziškas `[[...]]` duoda lygiai vieną lietuvišką `[[...]]`, **sakinyje, toje pačioje minties
vietoje**. Niekada nepalik termino pastraipos gale ir nepalik skylės:

> Neteisinga: `miestą pirmiausia susilpnino: kryžiuočiai jį nusiaubė. [[Konstantinopolio užėmimas]]`
> Teisinga: `Miestą pirmiausia susilpnino [[Konstantinopolio užėmimas per Ketvirtąjį kryžiaus žygį (1204)]],
> kai Vakarų kryžiuočiai jį nusiaubė.`

Termino tekstas yra raktas faile `ios/Sophia/Resources/Locales/glossary.lt.json`; nežinomas raktas tampa
negyvu tekstu. `scripts/make_translation_briefs.py` santraukoje išvardyti leidžiami raktai; naudok vieną raidė
į raidę. Nekeisk įrašo kitu. Jei pats raktas pažeidžia §5 taisykles, taisyk `glossary.lt.json` visam kursui.

**Raktas yra vardininko forma ir jo negalima linksniuoti.** Nieko neprijunk prie `]]`: `[[džihad]]o`,
`[[kalif]]ams`, `[[laissez-faire]]'ui` klaidingos, kaip ir linksnio keitimas skliaustų viduje
(`[[džihado]]`, kai raktas `džihadas`). Kadangi lietuvių kalba turi septynis linksnius, sakinį statyk taip,
kad termino vieta reikalautų vardininko:

- veiksnys: `Tada prasideda [[indėlių bėgimas]].`
- vardinė tarinio dalis: `Pagrindinis įrankis yra [[sandorių kainodara]].`
- sąrašas po dvitaškio ar priedėlis po kablelio: `Grupę veikė vienas šaltinis: [[japoniška estampa]].`
- su vardininką valdančiu žodžiu: `vadinamasis [[naujasis kursas]]`, `tai ir yra [[džihadas]]`.

> Fr.: `Mais le groupe expérimente aussi grâce aux [[estampes japonaises]] : …`
> Neteisinga: `Tačiau grupė eksperimentuoja ir dėka [[japoniškos estampos]]: …`
> Teisinga: `Grupę įkvepia ir [[japoniškos estampos]]: asimetriška kompozicija ir lygūs spalvų plotai.`
> Fr.: `**Roosevelt** lance le [[New Deal (1933)]].`
> Neteisinga: `**Rooseveltas** pradeda [[New Deal (1933)]].` (galininkas)
> Teisinga: `**1932** m. prezidentu išrenkamas **Franklinas D. Rooseveltas**, ir prasideda [[New Deal (1933)]].`

Jei raktas netinka, perstatyk sakinį. Rakto sakinyje nekeisk.

## 5. Tikriniai vardai

**Asmenvardžiai neverčiami.** Mašina skaito juos kaip bendrinius žodžius: Munch lieka Munchas (ne „kramtyti“),
Degas lieka Degas.

**Lietuviška galūnė.** Vardai, kurių rašyba atitinka tarimą, gauna galūnę tiesiai: `Aupickas`, `Aupicko`,
`Dzeusas`, `Nadaro ateljė`, `Muncho`. Kai rašyba ir tarimas skiriasi, originalas išlaikomas, galūnė po
apostrofo `'` (U+0027): `Baudelaire'as`, `Baudelaire'o`, `Shakespeare'o`, `Monet` (nekaitomas) arba
`Monet'o`, `Degas'o`, `Seurat'o`, `Poe'as`. Vienoje kalboje rinkis vieną būdą ir laikykis jo. Santrumpos
nekaitomos arba su brūkšneliu tik šnekamojoje kalboje: rašyk `NATO`, `JTO`, `DNR`, be galūnių.

**Įsitvirtinę lietuviški pavadinimai**, vienodai visame kurse: `Christophe Colomb` → `Kristupas Kolumbas`,
`Londres` → `Londonas`, `Pékin` → `Pekinas`, `Aix-la-Chapelle` → `Achenas`, `Charlemagne` → `Karolis
Didysis`, `Michel-Ange` → `Mikelandželas`, `Saint-Pétersbourg` → `Sankt Peterburgas`, `Ulysse` →
`Odisėjas`, `ONU` → `JTO`, `OTAN` → `NATO`, `Byzance` → `Bizantija`, `Sassanides` → `Sasanidai`, `roi
Arthur, reine Guenièvre` → `karalius Artūras, karalienė Gvinevra`. Graikų mitai lietuviška tradicija:
Narcizas (gėlė `narcizas`), Echo, Dedalas, Ikaras, Sizifas, Tantalas, Jasonas, Medėja, Polifemas, Kronas,
Hesiodas, Olimpas, Teiresijas, Panas, Nemezidė. Rusų vardai pagal lietuvišką transkripciją: Fiodoras
Dostojevskis, Sonia Marmeladova, Porfirijus Petrovičius.

**Islamas ir arabiški žodžiai**: `Muhammadas` (`Muhammado`), `Meka`, `Medina`, `hidžra` mažąja raide, `uma`,
`kalifas`, `džizja`, `zimis`, `džihadas`, `beduinai`, `muedzinas`; razzia → `antpuolis`. Ne: `Hegira`,
`Ummah`, `Muhammad`, `razzias`.

**Kūrinio pavadinimas yra lietuviško leidimo pavadinimas**, ne pažodinis (visas sąrašas `oeuvres.json`):

| Prancūziškai → lietuviškai | Prancūziškai → lietuviškai |
| --- | --- |
| *Les Fleurs du Mal* → *Blogio gėlės* | *Le Spleen de Paris* → *Paryžiaus splinas* |
| *Impression, soleil levant* → *Impresija. Tekanti saulė* | *Le Déjeuner sur l'herbe* → *Pusryčiai ant žolės* |
| *La Nuit étoilée* → *Žvaigždėta naktis*; *La Ronde de nuit* → *Naktinė sargyba* | *Les Demoiselles d'Avignon* → *Avinjono merginos*; *Le Cri* → *Šauksmas* |
| *La Ferme des animaux* → *Gyvulių ūkis* | *Le Petit Prince* → *Mažasis princas* |
| *Les Raisins de la colère* → *Rūstybės kekės* | *Ne tirez pas sur l'oiseau moqueur* → *Nežudyk strazdo giesmininko* |
| *Crime et Châtiment* → *Nusikaltimas ir bausmė*; *Le Procès* → *Procesas* | *Madame Bovary* → *Ponia Bovari*; *Les Misérables* → *Vargdieniai* |
| *Le Rouge et le Noir* → *Raudona ir juoda*; *L'Étranger* → *Svetimas* | *Gatsby le Magnifique* → *Didysis Getsbis*; *Le Meilleur des mondes* → *Puikus naujas pasaulis* |
| *L'Origine des espèces* → *Rūšių atsiradimas*; *La République* → *Valstybė* | *Psychose*, *Sueurs froides*, *Fenêtre sur cour* → *Psichopatas*, *Svaigulys*, *Galinis langas* |

Kita: `Roaring Twenties` → `Audringasis XX a. 3-iasis dešimtmetis` arba `Šėlstantys dvidešimtieji`; `New Deal`
lieka; `Salon des Refusés` → `Atmestųjų salonas`; *1984*: `Big Brother` → `Didysis Brolis`, `novlangue` →
`naujakalbė`, `doublepensée` → `dvejamintis`. Kurso tekste pavadinimas `*kursyvu*`; sąsajoje, viktorinoje ir
žodynėlyje (be žymių) kabutėse: `Kas parašė rinkinį „Blogio gėlės“?`. Niekada laužtiniuose skliaustuose. Jei
lietuviško pavadinimo nėra, palik originalą ir pirmą kartą paaiškink skliaustuose. Registras:
`scripts/proper_nouns.json`.

## 6. Citatos

Citata nėra vertimo pratimas. Jei yra kanoninis lietuviškas tekstas, naudok jį; kitaip versk trumpai ir aiškiai.

- Kabutės `„ “` (U+201E ir U+201C). Ne `« »`, ne `" "`, ne `“ ”`: `**"Splinas ir idealas"**` →
  `**„Splinas ir idealas“**`. Citatos citatoje venk; perstatyk.
- Taškas po citatos rašomas už kabučių, jei citata yra sakinio dalis; savarankiškas cituojamas sakinys:
  `„Visi gyvuliai lygūs.“`
- `quote.attribution` yra `Autorius, kūrinys`: `Charles'is Baudelaire'as, „Atitikmenys“`;
  `Fiodoras Dostojevskis, Nusikaltimas ir bausmė (Raskolnikovas)`.
- *Gyvulių ūkis*: `„Visi gyvuliai lygūs, bet kai kurie gyvuliai lygesni už kitus.“`

## 7. Skyryba ir tipografija

- **Jokio ilgojo brūkšnio `—`.** Lietuvių norma yra brūkšnys `–` su tarpais (`Meka – dabartinėje Saudo
  Arabijoje – buvo prekybos miestas`), bet programėlėje geriau perstatyti kableliu, dvitaškiu, skliaustais
  ar tašku. Intervalai su brūkšneliu be tarpų: `1945-1975`, `XIV-XVI a.`
- Ne `« »`, ne nulinio pločio tarpai, ne U+00A0, ne BOM. Apostrofas tiesus `'` (U+0027).
- Prieš skyrybos ženklą tarpo nėra; po kablelio, dvitaškio ir kabliataškio yra (išskyrus laiką `02:59`).
  Kablelis prieš kiekvieną šalutinį sakinį (`kad`, `kuris`, `kai`, `nes`, `jei`). Prancūziškas tarpas prieš
  `?`, `!`, `:` šalinamas: `Prêt ?` → `Pradedam?`
- Sakinio viduryje bendriniai daiktavardžiai mažąja raide: `renesansas`, `impresionizmas`, `muedzinas`. Mėnesiai
  ir savaitės dienos mažąja raide.
- Jokių prancūziškų liekanų (`siècle`, `dans`, `l'`) ir sugadintų ženklų (`**Z69**%`, `ZPa`). Tai mašininio
  vertimo šiukšlės; parašyk sakinį iš naujo.

## 8. Skaičiai, datos, matai

- Tūkstančiai: paprastas tarpas nuo penkiaženklių (`30 000`, `10 000 vyrų`), keturženkliai kartu (`3000`).
  Dešimtainės trupmenos su kableliu; procentas su tarpu pagal VLKK: `3,5 %`.
- **Daiktavardis po skaičiaus** pagal skaitvardį: 1, 21, 31 (ne 11) → vardininkas vns. (`1 viktorina`,
  `21 kursas`); 2–9, 22–29 (ne 12–19) → vardininkas dgs. (`3 viktorinos`, `5 kursai`); 0, 10–20, 30, 100…
  → kilmininkas dgs. (`10 viktorinų`, `15 kursų`, `0 XP`). Trupmenos → kilmininkas vns. (`1,5 valandos`).
- **Daugiskaitos formos** `.stringsdict` / Android `plurals`: `one`, `few`, `many`, `other` (CLDR).
  `many` lietuviams yra trupmenos. Pavyzdžiui `%d day streak`: one `%d diena iš eilės`, few `%d dienos iš
  eilės`, many `%d dienos iš eilės`, other `%d dienų iš eilės`. Niekada neužpildyk visų vienodai.
- **Metai**: `En 1857` → `**1857** m.` arba `**1857**-aisiais`; `Vers 570` → `apie **570** m.`; `dès 610`
  → `nuo **610** m.`. Ne `1857-ais metais` su klaidomis, ne pliki `**1932** išrinktas`.
- **Data** lietuviška tvarka: `**24 octobre 1929**` → `**1929 m. spalio 24 d.**`; laiko juostoje
  `1815 m. birželio 18 d.`; intervalas `nuo 1954 m. kovo 13 d. iki gegužės 7 d.`; `entre 1945 et 1975` →
  `1945-1975 m.`; `années 1850` → `XIX a. 6-ajame dešimtmetyje`.
- **Amžius**: romėniški skaitmenys su `a.`: `VIIe siècle` → `VII a.`, `VII amžiuje`; `XIVe-XVIe` → `XIV-XVI a.`
  Ne `700-ieji` (tai metai), ne `7-ame amžiuje`.
- Era: `pr. Kr.`, `po Kr.` (`399 m. pr. Kr.`), ne `av. J.-C.`
- Amžius ir trukmė: `à 25 ans` → `būdamas 25 metų` / `25-erių`; `en 22 ans` → `per 22 metus`. Mato vienetai
  metriniai, neperskaičiuojami. `Mds` → `mlrd.`, `M` → `mln.`. `NIV. 3` → `3 LYGIS`.

## 9. Produkto terminai

Visoje programėlėje viena forma:

| Prancūziškai | Lietuviškai | Ne |
| --- | --- | --- |
| quiz; cours; leçon | viktorina (`5 viktorinos`); kursas (`3 kursai baigti`); pamoka | kvizas, testas; paskaita |
| parcours; collection | kelias (`KELIAS`); rinkinys | kelionė, maršrutas; kolekcija |
| niveau, NIV. 3; série (streak) | lygis, `3 LYGIS`; serija, `dienų serija` | pakopa; serialas, ruožas |
| essai gratuit; Fin de l'essai | nemokamas bandomasis laikotarpis (`Pradėti bandomąjį laikotarpį`); `Bandomasis laikotarpis baigiasi` | teismo procesas, bandymas, bandomoji versija |
| Premium | Premium (nekaitomas: `su Premium`, `Premium funkcijos`, `Premium planas`) | premija, priedas, `Premiumo` |
| abonnement mensuel / annuel | mėnesinė prenumerata / metinė prenumerata; trumpai `Mėnesinė` / `Metinė` | abonementas; žurnalas |
| Sophia; bloqueur TikTok | Sophia (`Sophios`, `su Sophia`); TikTok blokatorius | `Sofija` |
| Entraînement; réviser | Treniruotė; kartoti, `Kartoti` | praktika; peržiūrėti |
| objectif; ami; matière / sujet | tikslas; draugas; dalykas / tema | objektyvas |
| débloquer; glossaire; XP | atrakinti (`Atrakink su Premium`); žodynėlis; XP (`120 XP`) | atblokuoti; glosarijus; taškai |
| Bibliothèque; Accueil; l'offre; terminé | Biblioteka; Pradžia; pasiūlymas (`Nepavyko įkelti pasiūlymo`); baigta | Namai; paywall; padaryta |
| notification; Vrai / Faux | pranešimas; Tiesa / Netiesa (`Tiesa ar netiesa?`) | notifikacija; Teisinga / Klaidinga |

App Store puslapyje ir teisiniuose tekstuose tie patys terminai; teisiniuose tekstuose kreipinys `jūs` leidžiamas
tik jei taip reikalauja teisinė forma, kitur visur `tu`.

## 10. Patikra

```bash
python scripts/check_course_translation.py --lang lt
python scripts/i18n_gate.py
```

Švarus patikros rezultatas yra privalomas. Pasikartojančias klaidas ieškok rankiniu būdu:

```bash
grep -rnE '\b(jūs|jūsų|jums)\b|\b(Atrask|Susipažink|Pasinerk|Žiūrėk|Rinkis)ite\b|\]\][a-ząčęėįšųūž]|”|«|—|\bdėka\b' content/courses/lt/
```

Galutinis sąrašas:

- [ ] Visur `tu`, jokių `jūs`; giminės formos apie naudotoją išvengtos.
- [ ] `%@`, `%d`, `%1$@`, `{n}` nepakitę; aplink juos linksnis nereikalingas.
- [ ] `**` ir `*` poromis, be tarpų viduje; `[[...]]` vardininku, raktas iš `glossary.lt.json`, savo vietoje.
- [ ] Vardai su teisingomis galūnėmis ir apostrofais; įsitvirtinę lietuviški pavadinimai; kūriniai iš `oeuvres.json`.
- [ ] Kabutės `„ “`, jokio `—`, jokių prancūziškų tarpų prieš `?` `!` `:`.
- [ ] Datos `1929 m. spalio 24 d.`, amžiai `XIX a.`, `pr. Kr.`; daiktavardis po skaičiaus teisingu linksniu.
- [ ] `one` / `few` / `many` / `other` užpildyti skirtingai.
- [ ] Produkto terminai pagal §9 ir `sentinelles.json`: Premium, nemokamas bandomasis laikotarpis, mėnesinė prenumerata, Lengvas.
- [ ] Garsiai perskaityta: skamba kaip lietuviškas tekstas, ne vertimas.
