# Kursu tulkošana: no franču valodas latviešu valodā

Franču teksts (`content/courses/fr/`) ir avots; šis dokuments ir `content/courses/lv/` specifikācija, un
`scripts/check_course_translation.py --lang lv` to pārbauda mašīnveidā. Tie paši noteikumi attiecas uz
saskarni, viktorīnām, glosāriju, katalogu (App Store lapu) un juridiskajiem tekstiem. Obligātā terminoloģija
pilnā apjomā ir mapē `content/terminology/` (`termes_produit.json`, `mots_pieges.json`, `oeuvres.json`,
`sentinelles.json`); kontrolvirknes no `sentinelles.json` vārtsargs `scripts/i18n_gate.py` salīdzina burtiski.

## 1. Ko mēs gribam

Mēs nenododam tulkojumu. Mēs nododam kursa **latvisko izdevumu**: tekstu, ko dzimtās valodas redaktors būtu
uzrakstījis no tām pašām piezīmēm. Lasītājs nedrīkst nojaust, ka oriģināls bija franciski. Šādā secībā:

1. **Pareizi.** Neizkropļo, neizdomā un neizlaid faktus. Datumu pārbaudi: `**18 juin 1815**` →
   `**1815. gada 18. jūnijā**`.
2. **Plūdeni.** Dabiska latviešu valoda, kas, skaļi lasot, neklūp.
3. **Vienkārši.** Īsi teikumi, ikdienas vārdi; zinātkāram pusaudzim jāspēj sekot.
4. **Formai uzticīgi.** Apmēram tikpat teikumu, tā pati domu gaita, garums divdesmit procentu robežās.

**Uzruna vienmēr ir „tu“**, vienskaitlī un sirsnīgi, kā mūsdienu mācību un patērētāju lietotnēs. Nekad
„jūs“, „jums“, „jūsu“ un nekad daudzskaitļa pavēles izteiksme (`-iet`, `-at`). Pavēle vienskaitļa 2. personā:
`Découvre` → `Atklāj`, `Choisis` → `Izvēlies`, `Commence` → `Sāc`, `Réessaie` → `Mēģini vēlreiz`. Pogā
`savs`, nevis `mans`, ja runā lietotājs par sevi trešajā personā: `Voir mon profil` → `Skatīt savu profilu`.
Mērķu izvēlē franču `mon` var palikt `savus`: `Impressionner mon entourage` → `Pārsteigt savus tuvākos`.

> Nepareizi: `Iepazīstieties ar dieviem un varoņiem` · `JŪSU PROFILS` · `Cik daudz laika jūs pavadāt telefonā?`
> Pareizi: `Iepazīsti dievus un varoņus` · `TAVS PROFILS` · `Cik daudz laika tu pavadi telefonā?`

**Franču bezpersonas „on“ nav „mēs“ un nav „viņi“.** Lieto bezpersonas teikumu, ciešamo kārtu vai
3. personu ar `-ot`: `On dit que les données sont le nouveau pétrole` → `Mēdz teikt, ka dati ir jaunā nafta`;
`On veut le tuer` → `Viņu grib nogalināt`. Īsts „nous“ (`notre façon de regarder`) var palikt `mēs`.
Izņēmums ir produkta balss: `On te préviendra` → `Mēs tev atgādināsim` (Sophia runā kā „mēs“).

**Dzimte.** Latviešu valodā ir gramatiskā dzimte, un tā skar darbības vārda divdabjus (`esi gatavs/gatava`,
`tu esi pabeidzis/pabeigusi`). Lietotāja dzimte nav zināma: veido teikumu bez dzimtes formas. `Tu es prêt ?`
→ `Sākam?`; `Tu as terminé` → `Kurss pabeigts`; `Deviens cultivé` → `Kļūsti zinošāks` nav neitrāls, tāpēc
`Uzzini vairāk 10 minūtēs dienā`. Ja neitrāli nav iespējams, lieto vīriešu dzimti tikai kā pēdējo iespēju.
Sieviešu dzimtes nosaukumi tur, kur tie ir dabiski (`karaliene Ginevra`, `dieviete Nemesīda`, `rakstniece`).

**Laiki un kalki.** Vēsturiskā tagadne (`1874. gadā viņi rīko izstādi`) ir dabiska, bet vienā rindkopā laiku
nemaini. `Voici comment tout a commencé` → `Tā viss sākās`, nevis `Šeit ir, kā viss sākās`. `fondée par
Mahomet` → `Muhameda dibinātā`, nevis `dibināta no Muhameda puses`. `De la gravité à l'ADN` → `No gravitācijas
līdz DNS`. Lietai `tā`/`tas` atbilstoši dzimtei, nevis `viņa`/`viņš`: `L'expansion ... Elle est aussi` →
`Paplašināšanās ... Tā ir arī`.

**Viltus draugi.** Tulko pēc teikuma, nevis pēc biežākās angļu nozīmes:

| Franciski (nozīme) | Latviski | Nevis |
| --- | --- | --- |
| Léger / Modéré / Intense; Gratuit | Viegli / Mēreni / Intensīvi; Bez maksas | `Gaisma`; `Brīvs` |
| Expire dans; Mensuel / Annuel | `Beidzas pēc 02:59:59`; Mēneša / Gada | `Derīgs līdz gadam`; `Ikmēneša žurnāls` |
| culture générale; anecdotes; Terminale | vispārējās zināšanas, plašs redzesloks; interesanti fakti; 12. klase | kultūra; anekdotes |
| Pas de connexion; Glisse pour découvrir | Nav savienojuma; Pavelc, lai atklātu | |
| la personne la plus intéressante de la pièce | interesantākais cilvēks sabiedrībā | istabas ... |
| spleen; flâneur; caravane; deux états (d'âme) | splīns; flanērs; karavāna; divi dvēseles stāvokļi | liesa; ratiņi; treilers; divas valstis |
| condamnation; beau-père (Aupick); réhabilitation | notiesāšana; patēvs; reabilitācija | pārliecība; sievastēvs; rehabilitācija |
| gravité; failles; pétrole; cellulaire; plaques | gravitācija; lūzumi, plaisas; nafta; šūnu; fotoplates | nopietnība; kļūdas; eļļa; mobilais; šķīvji |
| 10 000 hommes; six poèmes; à 6 ans | 10 000 vīru; seši dzejoļi; sešu gadu vecumā | dolāru; dzejnieki; `6 gadus` |
| berger; marine (glezna); tribut; nordique; État | gans; jūras ainava; meslu nodeva; Ziemeļvalstu; valsts | aitu suns; flote; cieņas apliecinājums; Norvēģija; štats |
| Grande Dépression; soupe populaire; relance | Lielā depresija; zupas virtuve; ekonomikas stimulēšana | atveseļošanās |
| chute; sensation; touche; puissant; juger | krišana; sajūta; triepiens, taustiņš; spēcīgs; tiesāt | rudens; sensācija; poga |

## 2. Skelets paliek

Tulko tikai teksta laukus. Pārējo rīks kopē no franču skeleta, un tu tam nepieskaries: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Lauks | Kas tas ir | Piezīme |
| --- | --- | --- |
| `title` / `subtitle` | Virsraksts / rinda zem tā | Darbam latviskā izdevuma nosaukums. Gads vai posms (`1945-1975`) paliek. |
| `description` / `hero.hook` | Divu teikumu ievads / vilinošs teikums | Jāstāv patstāvīgi. Reklāma, nevis proza. |
| `sections[].title` | Daļas virsraksts | Lietvārda frāze, tikai pirmais vārds ar lielo burtu, bez punkta. |
| `paragraph.text` | Saistīts teksts | Galvenais darbs. |
| `image.caption` | Attēla paraksts | Īss; punkts tikai pēc pilna teikuma. |
| `funFact.text` / `takeaway.text` | Kastīte / kopsavilkums | Viegls, sarunvalodas tonis. |
| `quote.text` / `quote.attribution` | Citāts / autors | Sk. §6. |
| `timeline.events[].date` | `1789`, `1940. gada jūnijs`, `ap 450. g. p.m.ē.` | Mēneši ar mazo burtu. |

**Vietturi** tiek kopēti burtiski: `%@`, `%d`, `%1$@`, `%2$d`, `{n}`, `\n`. Tos nedrīkst tulkot, pārvietot uz
citu nozīmi, dzēst vai locīt; secību var mainīt tikai numurētiem (`%1$@`, `%2$@`). Rindiņu pārnesumu skaits
saskarnē paliek tāds pats kā franciski.

> `Démarrer mon essai de {n} jours` → `Sākt {n} dienu bezmaksas izmēģinājumu` (nevis `{n} dienas`, nevis `{n}-dienu`)
> `Quiz du niveau %d` → `%d. līmeņa viktorīna` · `Soit %@ complets.` → `Tas ir %@ bez pārtraukuma.`

Vietturis ar locījumu: ja `%@` ir vārds vai skaitlis, kas latviski būtu jāloka, veido teikumu tā, lai
vietturis stāvētu nominatīvā vai aiz kola: `Bienvenue, %@ !` → `Sveiks, %@!` nav neitrāli; lieto `Laipni
lūdzam, %@!`.

## 3. Iezīmes rindā

Trīs iezīmes jāsaglabā: `**trekns**` (datumi, skaitļi, vārdi un darbi, par kuriem ir rindkopa), `*slīpraksts*`
(darba nosaukums prozā) un `[[termins]]` (glosārija ieraksts; pieskāriens atver definīciju).

- Iezīmes nāk pa pāriem. Nepāra `**` skaits ir kļūda.
- Neviena iezīme neapņem atstarpi vai pieturzīmi: `**1945**,` ir pareizi; `**1945,**` un `** 1945 **` nē.
  Kārtas skaitļa punkts paliek ārpusē: `**1857**. gadā`, nevis `**1857.** gadā`.
- Treknraksts iezīmē latvisko atbilsmi: `**30 000 mots**` → `**30 000 vārdu**`. Nepievieno treknrakstu, kura
  franciski nav, un netaisi treknu visu teikumu.

## 4. Glosārija ieraksti: svarīgākais noteikums

Katrs franču `[[...]]` dod tieši vienu latvisko `[[...]]` **teikumā, tajā pašā domu gaitas vietā**. Nekad
nenoliec terminu rindkopas beigās, neatstāj tukšumu un nemaini pret citu ierakstu.

Termina teksts ir kursa atslēga failā `ios/Sophia/Resources/Locales/glossary.lv.json`; nezināma atslēga
paliek miris teksts. `scripts/make_translation_briefs.py` kopsavilkums uzskaita atļautās atslēgas; lieto vienu
burtu pa burtam, ar lielajiem burtiem kā reģistrā. Ja reģistrētā atslēga pati pārkāpj §5, labo to
`glossary.lv.json` visam kursam uzreiz.

**Atslēga ir nominatīvā un netiek locīta.** Latviešu valodā ir septiņi locījumi, tāpēc lielākā daļa vietu
teikumā prasītu ģenitīvu, datīvu vai lokatīvu. Neko nepievieno aiz `]]` un nemaini galotni iekavās:
`[[džihāda]]`, `[[kalifs]]am`, `[[Varšavas līgums]]ā` ir nepareizi. Veido teikumu ap pamatformu:

- teikuma priekšmets: `Tad sākas [[banku panika]]: ...`;
- izteicēja daļa pēc `ir`: `Galvenais rīks ir [[transfertcena]].`;
- uzskaitījums aiz kola vai pielikums: `Viens jēdziens: [[laissez-faire]].`;
- konstrukcija `tā sauktais` / `jēdziens` + nominatīvs neder, jo tā prasa saskaņojumu; pārbaudi locījumu.

> Nepareizi: `Grupu ietekmē arī [[Japāņu kokgriezumi]]em.`
> Pareizi: `Grupu ietekmē arī [[japāņu kokgriezumi]]: asimetriska kompozīcija un vienlaidu krāsu laukumi.`
> Nepareizi: `**Franklins D. Rūzvelts** ievieš [[Jaunais kurss (1933)]].`
> Pareizi: `**1932**. gadā prezidentu ievēl **Franklinu D. Rūzveltu**, un sākas [[Jaunais kurss (1933)]].`
> Nepareizi: `Otrā pasaules kara laikā` ar `[[Otrais pasaules karš]]` iekšā. Pareizi: `kad notiek **[[Otrais
> pasaules karš]]**`.

Ja atslēga neiederas, pārbūvē teikumu. Atslēgu teikumā nemaina.

## 5. Īpašvārdi

**Personvārdus netulko, bet latviešu valodā tos atveido un loka** pēc fonētiskā principa (Valsts valodas
centra ieteikumi): `Degas` → `Dega`, `Monet` → `Monē`, `Baudelaire` → `Bodlērs`, `Shakespeare` → `Šekspīrs`,
`Victor Hugo` → `Viktors Igo`, `Voltaire` → `Voltērs`, `Corneille` → `Korneijs`, `Munch` → `Munks`,
`Napoléon` → `Napoleons`. Vīriešu vārdiem pievieno galotni `-s`/`-š` un loka (`Bodlēra`, `Monē` nelokāms,
jo beidzas ar `-ē`); sieviešu vārdiem `-a`/`-e` (`Simona de Bovuāra`). Oriģinālu var dot iekavās pirmajā
reizē, ja lasītājs to meklētu: `Bodlērs (Baudelaire)`. Viens vārds visā kursā vienā formā; reģistrs ir
`scripts/proper_nouns.json`, ieraksti tur, nevis labo divreiz.

**Iegājušās latviskās formas:** `Christophe Colomb` → `Kolumbs`, `Londres` → `Londona`, `Pékin` → `Pekina`,
`Aix-la-Chapelle` → `Āhene`, `Charlemagne` → `Kārlis Lielais`, `Michel-Ange` → `Mikelandželo`,
`Saint-Pétersbourg` → `Sanktpēterburga`, `Ulysse` → `Odisejs`, `ONU` → `ANO`, `OTAN` → `NATO`, `UE` → `ES`,
`Byzance` → `Bizantija`, `roi Arthur` → `karalis Artūrs`. Grieķu mīti grieķiski: Narciss, Ehō, Daidals,
Ikars, Sīzifs, Tantals, Jāsons, Mēdeja, Polifēms, Krons, Hēsiods, Olimps, Tīresijs, Pāns. Krievu vārdi pēc
krievu izrunas: Fjodors Dostojevskis, Soņa Marmeladova, Porfirijs Petrovičs. Japāņu vārdi Hepbērna sistēmā,
latviski pielāgoti: `Hokusai` → `Hokusai`, `Tokyo` → `Tokija`.

**Islāms:** `Muhameds` (`Muhameda`), `Meka`, `Medīna`, `hidžra` ar mazo burtu, `umma`, `kalifs`, `džizja`,
`džihāds`, `beduīni`, `muedzins`; razzia ir `sirojums`. Nepareizi: `Hegira`, `Ummah`, `Mahomets`.

**Darba nosaukums ir latviskā izdevuma nosaukums**, nevis burtisks (pilns saraksts: `oeuvres.json`):

| Franciski → latviski | Franciski → latviski |
| --- | --- |
| *Les Fleurs du Mal* → *Ļaunuma puķes* | *Le Petit Prince* → *Mazais princis* |
| *La Ferme des animaux* → *Dzīvnieku ferma* | *Crime et Châtiment* → *Noziegums un sods* |
| *Les Misérables* → *Nožēlojamie* | *Le Rouge et le Noir* → *Sarkanais un melnais* |
| *L'Étranger* → *Svešinieks* | *Gatsby le Magnifique* → *Lielais Getsbijs* |
| *Le Cri* → *Kliedziens*; *La Nuit étoilée* → *Zvaigžņotā nakts* | *Le Meilleur des mondes* → *Brīnišķīgā jaunā pasaule* |
| *Madame Bovary* paliek | *Le Procès* → *Process* |

*1984*: `Big Brother` → `Lielais Brālis`, `novlangue` → `jaunruna`. Kursa tekstā nosaukums `*slīprakstā*`;
saskarnē, viktorīnā un glosārijā pēdiņās: `Kurš uzrakstīja „Ļaunuma puķes“?`. Ja latviska nosaukuma nav, atstāj
oriģinālu un pirmajā reizē paskaidro iekavās.

## 6. Citāti

Ja ir kanonisks latviskais tulkojums, lieto to. Citādi tulko īsi un skaidri.

- Pēdiņas `„ “` (U+201E un U+201C). Ne `« »`, ne `" "`, ne `“ ”`. Citātu citātā neliek; pārbūvē.
- Patstāvīga teikuma punkts ir pirms noslēguma pēdiņām: `„Visi dzīvnieki ir vienlīdzīgi.“`
- `quote.attribution` ir `Autors, darbs`: `Šarls Bodlērs, „Saskaņas“`.
- Kanonisks citāts: `„Visi dzīvnieki ir vienlīdzīgi, bet daži dzīvnieki ir vienlīdzīgāki par citiem.“`

## 7. Pieturzīmes un tipogrāfija

- Latviešu normā domuzīme ` – ` ir parasta, bet Sophia tekstos **domuzīmes `—` un `–` neliek**: pārbūvē ar
  komatu, kolu, iekavām vai punktu. Posmi ar defisi: `1945-1975`, `14.-16. gadsimts`.
- Ne `« »`, ne nulles platuma atstarpe, ne U+00A0, ne BOM. Apostrofs taisns `'` (U+0027), latviski gandrīz
  nevajadzīgs.
- Pirms pieturzīmes atstarpes nav (franču `?`, `!`, `:` ar atstarpi pirms ir kļūda). Pēc komata, kola,
  semikola ir atstarpe (izņemot laiku `02:59`). Komats pirms katra palīgteikuma (`ka`, `kas`, `kurš`, `ja`,
  `jo`, `lai`) un pirms divdabja teicieniem (`Pavelc, lai atklātu`).
- Sugasvārdi teikuma vidū ar mazo burtu: `impresionisms`, `renesanse`; vēstures notikumi pēc normas
  (`Lielā depresija`, `Otrais pasaules karš`).
- Neviena franču atlieka (`siècle`, `dans`, `l'`) un bojātas zīmes. Garumzīmes un mīkstinājuma zīmes
  (`ā ē ī ū č ģ ķ ļ ņ š ž`) ir obligātas: `Atklaj` ir kļūda.

## 8. Skaitļi, datumi, mērvienības

- Tūkstoši: parasta atstarpe no pieciem cipariem (`30 000`), četrciparu kopā (`3000`). Decimāldaļa ar komatu,
  `%` bez atstarpes: `3,5%`. `Mds` → `miljardi`, `M` → `miljoni`.
- **Gads:** `En 1857` → `**1857**. gadā`; `Vers 570` → `ap **570**. gadu`; `dès 610` → `jau **610**. gadā`.
  Nepareizi: `1857 gadā`, `gadā 1857`.
- **Datums:** `**24 octobre 1929**` → `**1929. gada 24. oktobrī**` (lokatīvs teikumā); laika joslas etiķetē
  nominatīvs `1815. gada 18. jūnijs`. Mēneši ar mazo burtu. Saskarnē `31.10.2026.` vai `2026. gada 31. oktobris`.
- **Gadsimts:** arābu cipars ar punktu: `VIIe siècle` → `7. gadsimts`, `7. gadsimtā`; `XIVe-XVIe` →
  `14.-16. gadsimtā`. `années 1850` → `19. gs. 50. gadi`.
- Ēras: `p.m.ē.` un `m.ē.` (`399. g. p.m.ē.`), nekad `av. J.-C.`.
- Vecums: `à 25 ans` → `25 gadu vecumā`; ilgums `en 22 ans` → `22 gados`. Pārrēķinu nav.

**Daudzskaitļa formas (zero / one / other).** Latviešu CLDR kategorijas: `zero` (0, 10-20, 30, 40 ... un
skaitļi, kas beidzas ar 0 vai 11-19), `one` (1, 21, 31, 101 ..., izņemot 11), `other` (pārējie). Katrai
`.stringsdict`/`plurals` atslēgai jādod visas trīs:

| Kategorija | Piemērs | `%d quiz` | `%d cours terminés` |
| --- | --- | --- | --- |
| zero | 0, 10, 11, 20 | `%d viktorīnu` | `%d kursu pabeigts` |
| one | 1, 21, 31 | `%d viktorīna` | `%d kurss pabeigts` |
| other | 2, 3, 22 | `%d viktorīnas` | `%d kursi pabeigti` |

`zero` latviski ir ģenitīvs daudzskaitlī (`10 dienu`, `0 punktu`), nevis „nekas“. Ja virkne nav daudzskaitļa
atslēga, izvēlies formu, kas der visiem: `Viktorīnas: %d`.

## 9. Produkta termini

Visā lietotnē viena forma:

| Franciski | Latviski | Nevis |
| --- | --- | --- |
| quiz; cours; leçon | viktorīna (`Visas viktorīnas`); kurss; nodarbība | kvizs, tests; lekcija, stunda |
| parcours; collection | ceļš (`Tavs ceļš`); kolekcija | maršruts, trase |
| niveau, NIV. 3; série (streak) | līmenis, `3. LĪMENIS`; sērija (`7 dienu sērija`) | pakāpe; svītra, strīks |
| essai gratuit | bezmaksas izmēģinājums (`Sākt izmēģinājumu`, `Izmēģinājums beidzas`) | tiesas process, prove, demo |
| Premium | Premium (`Sophia Premium`, `ar Premium`, `Premium funkcijas`) | prēmija, `Premiumā` |
| abonnement mensuel / annuel | mēneša abonements / gada abonements; plānos `Mēneša` / `Gada` | ikmēneša žurnāls |
| débloquer; Offre de bienvenue | atbloķēt (`Atbloķēt ar Premium`); Sveiciena piedāvājums | atslēgt |
| XP; glossaire; Bibliothèque; Accueil | XP; glosārijs; Bibliotēka; Sākums | pieredzes punkti; vārdnīca; Mājas |
| l'offre (paywall); terminé(e) | piedāvājums (`Neizdevās ielādēt piedāvājumu`); PABEIGTS | paywall; gatavs |
| notification; progression; matière | paziņojums; progress; priekšmets (`Tavi 3 bezmaksas priekšmeti`) | ziņa; objekts |
| Vrai / Faux; bonnes réponses | Patiesi / Aplami; pareizās atbildes | Taisnība / Nepatiesība |
| Sophia | Sophia, nelokāms nosaukums vai `Sophia` + lietvārds (`lietotnē Sophia`) | `Sofija`, `Sophiā` |

Kontrolvirknes (`sentinelles.json`, vārdiski): `Fin de l'essai` → `Izmēģinājums beidzas`; `Léger` →
`Viegli`; `Mensuel` → `Mēneša`; `Expire dans` → `Beidzas pēc`; `Annule à tout moment, sans frais.` →
`Atcel jebkurā laikā bez maksas.`; `Pas de connexion. Vérifie ton réseau et réessaie.` → `Nav savienojuma.
Pārbaudi tīklu un mēģini vēlreiz.`; `On te préviendra par notification. Annulable en 15 secondes.` → `Mēs
tev atgādināsim ar paziņojumu. Atcelt var 15 sekundēs.`

App Store lapa un juridiskie teksti: tā pati terminoloģija, oficiāls, bet „tu“ uzrunā tikai mārketinga
tekstā; noteikumos un privātuma politikā lieto bezpersonas formu (`Lietotājs var atcelt abonementu`).

## 10. Pārbaude

```bash
python scripts/check_course_translation.py --lang lv
python scripts/i18n_gate.py
grep -rnE '\b(jūs|jums|jūsu|Jūs)\b|\]\][a-zāčēģīķļņšūž]|«|»|—|–|“[^“„]*”| [?!:;]' content/courses/lv/
```

Tīrs palaidiens ir pienākums. Visbeidzot nolasi skaļi un pārbaudi:

- [ ] uzruna „tu“, vienskaitļa pavēle, nav dzimtes formu par lietotāju;
- [ ] vietturi `%@ %d %1$@ {n}` un `\n` neskarti, iezīmes `**`, `*`, `[[...]]` pa pāriem;
- [ ] katrs `[[...]]` ir reģistra atslēga nominatīvā, teikums ap to gramatiski pareizs;
- [ ] īpašvārdi atveidoti latviski un vienādi visā kursā; darbiem latviskie nosaukumi;
- [ ] pēdiņas `„ “`, nav domuzīmju, nav atstarpju pirms pieturzīmēm, garumzīmes vietā;
- [ ] `1857. gadā`, `7. gadsimtā`, `p.m.ē.`, `3,5%`, `30 000`;
- [ ] daudzskaitļa atslēgām zero / one / other;
- [ ] produkta termini no §9, kontrolvirknes burtiski.
