# Oversettelse av kursene — fra fransk til norsk bokmål

Fransk (`content/courses/fr/`) er kilden. Dette dokumentet er
spesifikasjonen for `content/courses/nb/`, for quizene, ordlisten og
appteksten. Det går i sin helhet til den som skriver oversettelsen, og
`scripts/check_course_translation.py --lang nb` håndhever reglene
mekanisk. Oversett alltid fra fransk, aldri fra den engelske utgaven.

## 1. Hva vi vil ha

Vi leverer ikke en oversettelse. Vi leverer den **norske utgaven** av
kurset: teksten en norsk redaktør ville skrevet ut fra de samme
notatene. Leseren skal ikke merke at originalen var fransk.

I denne rekkefølgen:

1. **Riktig.** Ikke forvreng, ikke finn på, ikke hopp over fakta.
2. **Flytende.** Idiomatisk bokmål. Kan leses høyt uten å snuble.
3. **Enkelt.** Korte setninger. Hverdagsord. En nysgjerrig tenåring
   skal henge med. Heller «viste» enn «demonstrerte», «brukte» enn
   «benyttet seg av».
4. **Tro mot formen.** Omtrent like mange setninger, samme tankegang,
   samme lengde med tjue prosent slingringsmonn, så oppsettet holder.

Register: **moderat bokmål**, som i en god lærebok for videregående.
Ingen dialekt, intet kansellispråk, ingen bisetninger i tre etasjer.
Leseren er **du** overalt (kurs, quiz, ordliste, knapper), aldri *De*
og aldri *dere* til én bruker. Imperativ i entall: «Sveip», «Start».
Én norm i hele appen: `fremgang`, `frem` (ikke `framgang`, `fram`);
preteritum på `-et` (`jobbet`, ikke `jobba`); hunkjønnsord i
felleskjønn (`boken`, `en bok`, ikke `boka`, `ei bok`).

**Upersonlig «on» er aldri «vi».** Bruk `man`, `folk`, `noen`, passiv
eller en omskriving. `vi` er Sophia som snakker i appen, ingenting annet.

> `On veut le tuer.` Feil: `Vi vil drepe ham.` Riktig: `Noen vil ta livet av ham.`
> `On y vit en tribus.` Feil: `Vi bor der i stammer.` Riktig: `Folk lever i stammer.`

**Pronomen følger norsk kjønn, ikke fransk.** Ting og abstrakter er
`den` (en-ord) eller `det` (et-ord). `han` og `hun` brukes bare om
personer og figurer.

> Feil: `Utvidelsen er ikke bare militær. Hun er også organisert.`
> Riktig: `Ekspansjonen er ikke bare militær. Den er også organisert.`
> Feil: `Boken forårsaket en skandale. Han ble dømt ...`
> Riktig: `Boken vakte skandale. Den ble dømt ...`

En figur har samme kjønn gjennom hele kurset. Fransk `son`/`sa` sier
ingenting om eierens kjønn: Ekko er `hun`/`hennes`, Narkissos
`han`/`hans`. `sin`/`sitt`/`sine` viser bare til subjektet.

> Feil: `Kroppen hans visner` (om Ekko). Riktig: `Kroppen hennes tørker inn.`
> Feil: `Teiresias hadde advart sin mor` (= sin egen). Riktig: `Teiresias hadde advart moren hans.`

**Brukeren og vitnesbyrdene.** Norske adjektiv bøyes ikke etter kjønn,
så «Du er klar» og «Velkommen tilbake» passer alle. Velg kjønnsnøytrale
personord (`elev`, `leser`, `venn`), aldri `-inne`-former. Et
vitnesbyrd fra en kvinne bruker `hun`/`hennes` hele veien. Signaturen
er `Inès, 19, VG3` (Terminale → VG3), uten tankestrek.

**Tid.** Historisk fortelling står i **preteritum**. Historisk presens
bare hvis hele avsnittet holder seg der. Aldri skifte fra setning til
setning:

> Feil: `I **1857** publiserte **Charles Baudelaire** ... Samlingen markerer et vendepunkt.`
> Riktig: `I **1857** publiserte **Charles Baudelaire** ... Samlingen markerte et vendepunkt.`

**Ordstilling.** Verbet står på plass to. Eiendomsord etter substantivet.

> Feil: `Likevel i undertall, hans trofaste vant på **Badr**.`
> Riktig: `Selv i undertall seiret tilhengerne hans ved **Badr**.`

Kalker som avslører maskinoversettelse:

| Feil | Riktig |
| --- | --- |
| `Her er hvordan det hele startet.` | `Slik begynte det hele.` |
| `bringe ned store imperier og føde en stat` | `felle store riker og skape en stat` |
| `Denne mannens navn er **Muhammed**.` | `Mannen heter **Muhammed**.` |
| `Foreldreløs av sin far på 6 år` | `Han mister faren som 6-åring` |
| `spiller den forbannede poeten`, `arbeidet hans` | `er selve bildet på den fordømte dikteren`, `verket hans` |
| `Overgi deg uten kamp` (Reddition, substantiv) | `Overgivelse uten kamp` |
| `Hvilken impresjonisme forandret` (Ce que) | `Det impresjonismen forandret` |
| `Ekko kan bare gjentas.` | `Ekko kan bare gjenta.` |
| `er vertskap for`, `i tjeneste for`, `regner med deg for å` | `huser`, `for`, `er avhengig av at du` |

## 2. Skjelettet står

Bare tekstfeltene oversettes. Resten kopierer verktøyet fra det
franske skjelettet, og det rører du ikke: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Felt | Hva det er | Merknad |
| --- | --- | --- |
| `title` | Tittel på kortet og i toppen | Kort. Den norske utgivelsestittelen hvis kurset handler om et verk. |
| `subtitle` | Linje under tittelen | Årstall eller intervall (`1945`, `1945-1975`) står uendret. |
| `description` | Omtale på to setninger | Skal stå alene. |
| `hero.hook` | Én lokkesetning | Reklame, ikke prosa. |
| `sections[].title` | Avsnittstittel | Substantivfrase, stor bokstav bare først, ingen punktum. |
| `paragraph.text` | Løpende tekst | Hovedarbeidet. |
| `image.caption` | Bildetekst | Kort; punktum bare ved hel setning. |
| `funFact.text` | Faktaboks | Lett, muntlig. |
| `takeaway.text` | Oppsummering | Det som skal sitte. |
| `quote.text` | Sitat | Se §6. |
| `quote.attribution` | Hvem som sa det | Se §6. |
| `timeline.events[].date` | `1789`, `juni 1940`, `ca. 450 f.Kr.` | Sifrene står. Månedene oversettes, liten forbokstav. `f.Kr.` / `e.Kr.`, aldri `av. J.-C.`. |
| `timeline.events[].title` | Etikett | Svært kort, ingen punktum. Substantiv, ikke imperativ. |
| `timeline.events[].detail` | Én setning | |

I appteksten står plassholdere (`%@`, `%d`) og emoji uendret.

## 3. Markører i linjen

Tre markører må overleve:

- `**fet**` — datoer, tall, navn og titler avsnittet handler om.
- `*kursiv*` — verkstittel i løpende tekst.
- `[[term]]` — ordlisteoppslag. Et trykk åpner definisjonen.

Regler:

- Markørene går i par. Et oddetall `**` er en feil.
- Ingen markør sluker mellomrom, tegn eller bindestrek: `**1945**,`
  er riktig; `**1945,**`, `** 1945 **` og `de **-beleiringen av
  Medina**` er feil (`**beleiringen av Medina**`).
- Fet markerer den norske motsvarigheten, ikke de samme tegnene.
  Fransk `**30 000 mots**` blir `**30 000 ord**`.
- Ikke legg til fet som ikke står i fransk. Ikke fet hele setninger.

## 4. Ordlisteoppslag — den viktigste regelen

Hvert franske `[[...]]` blir nøyaktig ett norsk `[[...]]`, **i
setningen, på samme sted i resonnementet**.

Parker aldri termen sist i avsnittet. La aldri et hull stå igjen. Det
er samme feil:

> Feil: `svekket fremfor alt av : kristne korsfarere plyndret byen.
> [[Erobringen av Konstantinopel]]`

> Riktig: `svekket fremfor alt av [[erobringen av Konstantinopel
> under det fjerde korstoget (1204)]], da vestlige korsfarere
> plyndret byen.`

Et oppslag forsvinner heller ikke i en omskriving: `[[razzias]]` som
blir «raid, raske raid» uten klammer, er et tapt oppslag.

Teksten i termen er ikke fri. Den må være en nøkkel registrert for
kurset i `ios/Sophia/Resources/Locales/glossary.nb.json`. En ukjent
nøkkel vises som død tekst. Briefen fra
`scripts/make_translation_briefs.py` lister de tillatte nøklene; bruk
én tegn for tegn, med de store bokstavene slik de står.

Setningen må være grammatisk **med nøkkelen satt inn**. Norsk bøyer
bestemthet og genitiv med endelser, og det er der det går galt:

- Ingenting limes på etter `]]`. `[[Kalif]]ene`, `[[Ekko]]s` og
  `[[Quraysh]]-stammen` er feil (kontrollen melder `s` etter `]]`).
  Skriv om: `stemmen til [[Ekko]]`, `den mektige stammen [[Quraysh]]`.
- Ikke `en` / `et` / `ei` / `den` / `det` / `de` foran en nøkkel som
  allerede begynner slik: `lei av den [[Den offisielle
  Paris-salongen]]` er feil, `lei av [[Den offisielle
  Paris-salongen]]` er riktig.
- Etter tall og flertallsord står flertall, men nøkkelen bøyes ikke.
  Feil: `Makten går over til [[Kalifs]]`. Riktig: `Makten går over
  til etterfølgerne hans, som får tittelen [[Kalif]].`
- Passer ikke nøkkelen, bygger du om setningen. Nøkkelen endrer du
  ikke i teksten.
- Står en nøkkel på engelsk, latin eller fransk (`Kalifs`, `Naiads`,
  `Oread`, `Ummah`, `Male rør og friluft`, `Baudelairesk "milt"`), er
  det en feil i ordlisten. Meld den: nøkkelen rettes i
  `glossary.nb.json` og i kursteksten i samme endring (`kalifer`,
  `najader`, `oreade`, `umma`, `malingstuber og friluftsmaleri`,
  `spleen`). Skriv aldri en uregistrert nøkkel; kontrollen avviser den.

Forklaringene i ordlisten følger reglene i §1, §5, §7 og §8 som
kursteksten (`Byzantium`, `700-tallet` om 600-tallet er feil der også).

## 5. Egennavn, titler og faste ord

Maskinoversettelse leser navn som vanlige ord. Faste regler:

**Oversett aldri for- og etternavn.** Degas er Degas, Munch er Munch
(ikke «tygge»), Pan er guden Pan (ikke «Bang»), Nemesis er hevnens
gudinne (ikke «erkefienden»).

**Etablert norsk form** når den finnes: `Christophe Colomb` →
`Christoffer Columbus`, `Guillaume le Conquérant` → `Vilhelm
Erobreren`, `Charlemagne` → `Karl den store`, `Londres` → `London`,
`Aix-la-Chapelle` → `Aachen`, `Byzance` → `Bysants` (ikke
`Byzantium`), `URSS` → `Sovjetunionen` (ikke `USSR`), `ONU` → `FN`,
`OTAN` → `NATO` (men `NATO på engelsk og OTAN på fransk` når teksten
forklarer forkortelsen), `Tchernobyl` → `Tsjernobyl`, `Michel-Ange` →
`Michelangelo`, `Zeus` → `Zevs`. Myten om Narkissos: `Narkissos`,
`Ekko`, `Teiresias`, `Kefisos`, `Ovid`, `oreade`, `najader`,
`dryader`; blomsten `narcisse` er `narsiss` (ikke `påskelilje`). Én
skrivemåte per kurs: `Kaba`/`Kabaen`, ikke også `Kaaba`.

**Islam.** `Hégire` → `hijra` (aldri `Hegira`, `Hegiraen`, `avgang`).
`Mahomet` → `Muhammed`, `La Mecque` → `Mekka`, `Médine` → `Medina`.
`calife` → `kalif` (`kalifer`, `kalifene`), `razzia` → `razzia`
(`razziaer`), `jizya`, `dhimma`, `Oumma` → `umma`, `idoles` →
`avgudsbilder`, `bédouins` → `beduiner`.

> Feil: `Denne avgangen, Hegira, markerer år 1 av islam.`
> Riktig: `Denne utvandringen, hijra, markerer år 1 i den islamske tidsregningen.`

**Verkstitler har den norske utgivelsestittelen**, ikke en kalk.
Hele listen står i `content/terminology/oeuvres.json`:

| Fransk | Norsk |
| --- | --- |
| *Impression, soleil levant* | *Impresjon, soloppgang* (ikke *Print, stigende sol*) |
| *Le Déjeuner sur l'herbe* | *Frokost i det grønne* (ikke *Lunsj på gresset*) |
| *Les Fleurs du Mal* | *Det ondes blomster* |
| *Le Spleen de Paris*, *Correspondances*, *Recueillement* | uendret; forklar én gang («samsvar mellom sansene», «andakt») |
| *La Ferme des animaux* | *Kamerat Napoleon* |
| *Le Meilleur des mondes* | *Vidunderlige nye verden* |
| *Le Procès* / *La Métamorphose* | *Prosessen* / *Forvandlingen* |
| *Les Misérables* | *De elendige* |
| *Le Rouge et le Noir* | *Rødt og svart* |
| *À la recherche du temps perdu* | *På sporet av den tapte tid* |
| *L'Étranger* / *Le Mythe de Sisyphe* | *Den fremmede* / *Myten om Sisyfos* |
| *Le Petit Prince* | *Den lille prinsen* |
| *Notre-Dame de Paris* | *Ringeren i Notre-Dame* |
| *Le Cri* / *La Joconde* / *La Nuit étoilée* | *Skrik* / *Mona Lisa* / *Stjernenatt* |
| *Les Demoiselles d'Avignon*, *Nighthawks* | uendret |

Finnes ingen norsk tittel, beholder du originalen og forklarer ved
første forekomst. I *1984* heter novlangue `nytale` og doublepensée
`dobbelttenkning`. I `[[...]]` gjelder likevel den registrerte
nøkkelen (`Newspeak` på kurs 101 og 102) til ordlisten er rettet.
Nye navn føres i `scripts/proper_nouns.json` under `nb`; rett aldri
samme navn to ganger.

**Produktord** (ett ord overalt, se `content/terminology/termes_produit.json`):

| Fransk | Norsk | Aldri |
| --- | --- | --- |
| cours / quiz | `kurs` (et kurs, kurset) / `quiz` (en quiz, quizen) | `leksjon`, `prøve`, `test` |
| Parcours / Collection | `Løype` / `samling` | `rute`, `reise`, `kolleksjon` |
| Niveau / Série | `nivå` (NIVÅ 3) / `rekke` (`5 dager på rad`) | `serie` |
| essai gratuit | `gratis prøveperiode` (`Start prøveperioden`) | `prøven`, `gratis prøve` |
| Premium / Sophia / XP | uendret (`Sophias`) | oversatt eller bøyd |
| bloqueur TikTok | `TikTok-blokkering`, `blokkeringen` | `blockeren`, `sperre` |
| Entraînement / Biblio | `Trening` / `Bibliotek` | `praksis`, `Biblio` |
| réviser / objectif / matière | `repetere` / `mål` / `fag` | `revidere`, `objektiv` |
| débloquer / glossaire / ami | `lås opp` / `ordliste` / `venn` | `glossar`, `kamerat` |
| résilier l'abonnement | `si opp abonnementet` | `avbryt`, `avslutt` |
| rang / l'offre | `rang` / `tilbudet`, `abonnementssiden` | `rangering`, `betalingsmur` |
| Mensuel / Annuel / Gratuit | `Månedlig` / `Årlig` / `Gratis` | |
| Voici comment... | `Slik fungerer det`, `Slik gjør du det` | `Her er hvordan` |

**Feller.** Oversett etter sammenhengen i fransk, aldri via engelsk:

| Fransk (betydning her) | Norsk | Aldri |
| --- | --- | --- |
| condamnation (dom) | `domfellelse`, `dom` | `overbevisning` |
| beau-père (mors nye mann) | `stefar` | `svigerfar` |
| spleen / deux états (d'âme) | `spleen` / `to sinnstilstander` | `milt` / `to stater` |
| flâneur | `flanør` | `barnevogn` |
| lumière / touche / sensation | `lyset` / `penselstrøk` / `sanseinntrykk` | `lett` / `berøring` / `sensasjon` |
| motif (malerkunst) / tubes de peinture | `motivet` / `malingstuber` | `mønsteret` / `rør` |
| ruse / appelle (roper) | `knep` / `roper` | `rus` / `ringer` |
| pouvoir / puissant | `makt` / `mektig` | `kraft` / `kraftig` |
| l'espace (verdensrommet) | `verdensrommet` | `plass` |
| carrefour / se referme | `møtested` / `går mot slutten` | `veiskille` / `nærmer seg` |
| marchand (d'art) / œuvre | `kunsthandler` / `verk` | `kjøpmann` / `arbeid` |
| caravane / pétrole / gravité | `karavane` / `olje` / `tyngdekraft` | `campingvogn` / `matolje` / `alvor` |
| Renaissance / Grande Dépression | `renessansen` / `den store depresjonen` | stor forbokstav |
| soupe populaire / panique bancaire | `suppekjøkken` / `bankpanikk` | `bankoperasjoner` |
| Terminale / trimestre | `VG3` / `termin` | `eldre år` |
| Léger (skala) / La lumière (quiz) | `Lett` / `Lyset` | |
| docteurs (forskere) | `forskere med doktorgrad` | `doktorer` (= leger) |

## 6. Sitater

Et sitat er ingen oversettelsesøvelse. Finnes en kjent norsk ordlyd,
bruker du den. Ellers oversetter du kort og klart.

- Anførselstegn `« »`, uten mellomrom innenfor: `«Er det noen her?»`.
  Aldri rette `" "`, aldri `“ ”`, aldri en blanding.
  > Feil: `Omdøpt til "profetens by"`. Riktig: `Omdøpt til «profetens by».`
  > Feil: `Hun svarer: «Noen!» »`. Riktig: `Hun svarer: «Noen her!»`
- Sitat i sitat: rette enkle `'...'` (`‘ ’` er forbudt).
- Punktum innenfor når hele setningen er sitert: `«Alle dyr er like.»`
  Utenfor når sitatet er en del av setningen: `Den ble dømt for
  «krenkelse av offentlig moral».`
- `quote.attribution` er `Forfatter, Verk`. Gir fransk taleren etter
  tankestrek, komma eller i parentes: `Victor Hugo, De elendige
  (biskop Myriel)`.

Kjent sitat fra *Kamerat Napoleon*:
`«Alle dyr er like, men noen dyr er likere enn andre.»`

## 7. Tegnsetting og typografi

Mekanisk kontroll, uten unntak.

- **Ingen lang tankestrek `—`, ingen kort `–`**, heller ikke den
  norske tankestreken. Skriv om med komma, kolon, parentes eller
  punktum. Tallrekker med bindestrek: `1945-1975`.
- Ingen nullbreddetegn, ingen hardt mellomrom (U+00A0), heller ikke i
  tall. `« »` er tillatt i norsk og skal brukes.
- Apostrofen er rett `'` (U+0027), som i de franske filene. Ikke `’`.
  Genitiv etter s: `Sokrates' forsvarstale`.
- Aldri mellomrom foran `, . ; : ! ?` (fransk har det foran `: ; ! ?`
  og innenfor `« »`; fjern det). Aldri to mellomrom etter hverandre.
- Komma etter innledende leddsetning: `Da Hera oppdaget knepet,
  straffet hun Ekko.` Ikke komma foran `at`.
- Liten forbokstav: måneder, ukedager, `første verdenskrig`,
  `renessansen`, `kong Arthur`, `dronning Guinevere`, `profeten`,
  nasjonalitetsord (`fransk`, `persisk`).
- Ingen franske eller engelske rester. `siècle`, `dans` som
  preposisjon, `l'`, `d'un`, `Baudelairian`, `alexandrine` er feil.
  `du` og `dans` som norske ord (`du`, `en dans`) er i orden.

## 8. Tall, datoer, mål

- Tusen: vanlig mellomrom. `30 000` blir stående, `10 000 mann`.
  Aldri punktum, aldri komma, aldri hardt mellomrom. Firesifrede tall
  i ett: `4000`. Årstall deles aldri: `1857`.
- Desimaler: komma. `3,5 %` (vanlig mellomrom foran `%`),
  `2,5 millioner`. På knapper: `Lås opp med -70 %`, ikke `Lås opp
  mine -70 %`.
- Årstall: `En 1857` → `i 1857`, `vers 630` → `rundt 630`, `en l'an
  622` → `i år 622`. Aldri `på 1857`, `om 1857`. Ved setningsstart
  kommer verbet rett etter: `I 1857 publiserte Baudelaire ...`.
- Tiår: `les années 1930` → `1930-årene` / `på 1930-tallet`. Aldri
  `1930s`.
- Århundrer: `-tallet`, ett hundre **lavere** enn romertallet. Aldri
  romertall, aldri `XVe` alene.

  | Fransk | Norsk |
  | --- | --- |
  | `Ier siècle` | `det første århundre e.Kr.` |
  | `VIIe siècle` | `600-tallet` (ikke `700-tallet`) |
  | `XVe siècle` | `1400-tallet` |
  | `fin du XIXe siècle` | `slutten av 1800-tallet` |
  | `IIIe siècle av. J.-C.` | `det 3. århundre f.Kr.` |

  > Feil: `På 700-tallet interesserte Arabia nesten ingen.`
  > Riktig: `På 600-tallet brydde nesten ingen seg om Arabia.`
- Tidsregning: `f.Kr.` og `e.Kr.`: `ca. 450 f.Kr.`, `622 e.Kr.`
  (`e.Kr.` bare der det trengs).
- Dato: `24. februar 2022` (punktum etter dagen). Ett mønster per kurs.
- Alder og varighet: `à 6 ans` → `som 6-åring` / `6 år gammel`;
  `en 22 ans` → `på 22 år`. Aldri `på 6 år` om alder.
- Etter tall står flertall: `360 avgudsbilder` (ikke `360
  idolisere`), `seks dikt`, `tre kurs`. `én` med aksent bare for
  trykk: `én domfellelse`. Regentnavn beholder romertallet:
  `Napoleon III`, `Ludvig XIV`.
- Ingen omregning. Metrisk forblir metrisk.
- `Mds`/`Md` → `milliarder`, `M` → `millioner`, med ord.

## 9. Kontroll

```bash
python scripts/check_course_translation.py --lang nb
python scripts/check_course_translation.py --lang nb course_102_*
```

Kontrollen melder per kurs: avvik i skjelettet, skjeve markører, antall
oppslag, uregistrerte nøkler, termer parkert sist i avsnittet, dobbel
artikkel, `s` limt etter `]]`, forbudte tegn, mellomrom, franske og
engelske rester, og romertall og `av. J.-C.` som ikke er lokalisert.
En ren kjøring er et krav, ikke et forslag.

Kontrollen ser ikke alt. Les selv etter: setninger som begynner med
`Vi` (fransk «on»), `Hun`/`Han` om ting, rette `"`, `700-tallet` der
fransk sier `VIIe`, engelske navn (`Echo`, `Hegira`, `Byzantium`),
`leksjon`, `prøven` og `Her er hvordan`. Les til slutt teksten høyt:
det som høres oversatt ut, er oversatt for dårlig.
