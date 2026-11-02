# Oversettelse av kursene — fra fransk til norsk bokmål

Fransk (`content/courses/fr/`) er kilden; oversett aldri fra den engelske utgaven. Dette
dokumentet er spesifikasjonen for `content/courses/nb/`, quizene, ordlisten og appteksten,
og `scripts/check_course_translation.py --lang nb` håndhever reglene mekanisk.

## 1. Hva vi vil ha

Vi leverer ikke en oversettelse. Vi leverer den **norske utgaven** av kurset: teksten en
norsk redaktør ville skrevet ut fra de samme notatene. Leseren skal ikke merke at originalen
var fransk.

I denne rekkefølgen:
1. **Riktig.** Ikke forvreng, ikke finn på, ikke hopp over fakta.
2. **Flytende.** Idiomatisk bokmål. Kan leses høyt uten å snuble.
3. **Enkelt.** Korte setninger. Hverdagsord. En nysgjerrig tenåring skal henge med. Heller
   «viste» enn «demonstrerte», «brukte» enn «benyttet seg av».
4. **Tro mot formen.** Omtrent like mange setninger, samme tankegang, samme lengde med tjue
   prosent slingringsmonn, så oppsettet holder.

Register: **moderat bokmål**, som i en god lærebok for videregående. Ingen dialekt, intet
kansellispråk, ingen bisetninger i tre etasjer. Leseren er **du** overalt (kurs, quiz,
ordliste, knapper), aldri *De* og aldri *dere* til én bruker. Imperativ i entall: «Sveip»,
«Start». Én norm i hele appen: `fremgang`, `frem` (ikke `framgang`, `fram`); preteritum på
`-et` (`jobbet`, ikke `jobba`); hunkjønnsord i felleskjønn (`boken`, ikke `boka`, `ei bok`).

**Upersonlig «on» er aldri «vi».** Bruk `man`, `folk`, `noen`, passiv eller en omskriving.
`vi` er Sophia som snakker i appen, ingenting annet.
- `On veut le tuer.` Feil: `Vi vil drepe ham.` Riktig: `Noen vil ta livet av ham.`
- `On y vit en tribus.` Feil: `Vi bor der i stammer.` Riktig: `Folk lever i stammer.`

**Pronomen følger norsk kjønn, ikke fransk.** Ting og abstrakter er `den` (en-ord) eller
`det` (et-ord); `han` og `hun` bare om personer og figurer. En figur har samme kjønn hele
kurset: Ekko er `hun`/`hennes`, Narkissos `han`/`hans`, uansett fransk `son`/`sa`.
`sin`/`sitt`/`sine` viser bare til subjektet.
- Feil: `Utvidelsen er ikke bare militær. Hun er også organisert.`
- Riktig: `Ekspansjonen er ikke bare militær. Den er også organisert.`
- Feil: `Kroppen hans visner` (om Ekko). Riktig: `Kroppen hennes tørker inn.`
- Feil: `Teiresias hadde advart sin mor` (= sin egen). Riktig: `Teiresias hadde advart moren hans.`

**Brukeren og vitnesbyrdene.** Norske adjektiv bøyes ikke etter kjønn, så «Du er klar»
passer alle. Velg kjønnsnøytrale personord (`elev`, `leser`, `venn`), aldri `-inne`-former.
Et vitnesbyrd fra en kvinne bruker `hun`/`hennes` hele veien. Signaturen er `Inès, 19, VG3`
(Terminale → VG3).

**Tid og ordstilling.** Historisk fortelling står i **preteritum**; historisk presens bare
hvis hele avsnittet holder seg der, aldri vekslende fra setning til setning. Verbet står på
plass to, eiendomsordet etter substantivet.
- Feil: `I **1857** publiserte **Charles Baudelaire** ... Samlingen markerer et vendepunkt.` Riktig: `... markerte ...`
- Feil: `Likevel i undertall, hans trofaste vant på **Badr**.` Riktig: `Selv i undertall seiret tilhengerne hans ved **Badr**.`

**Kalker** avslører maskinoversettelse: `Her er hvordan det hele startet` → `Slik begynte
det hele`; `bringe ned store imperier og føde en stat` → `felle store riker og skape en
stat`; `Denne mannens navn er` → `Mannen heter`; `Overgi deg uten kamp` (Reddition) →
`Overgivelse uten kamp`; `Hvilken impresjonisme forandret` (Ce que) → `Det impresjonismen
forandret`; `Ekko kan bare gjentas` → `Ekko kan bare gjenta`; `er vertskap for` → `huser`.

## 2. Skjelettet står

Bare tekstfeltene oversettes. Resten kopierer verktøyet fra det franske skjelettet, og det
rører du ikke: `id`, `subject`, `subcategory`, `type`, `asset`, `image`, `ratio`, `free`.
I appteksten står plassholdere (`%@`, `%d`) og emoji uendret.

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
| `quote.text` / `quote.attribution` | Sitat / hvem som sa det | Se §6. |
| `timeline.events[].date` | `1789`, `juni 1940`, `ca. 450 f.Kr.` | Sifrene står. Månedene oversettes, liten forbokstav. `f.Kr.` / `e.Kr.`, aldri `av. J.-C.`. |
| `timeline.events[].title` / `.detail` | Etikett / én setning | Etiketten svært kort, uten punktum. Substantiv, ikke imperativ. |

## 3. Markører i linjen

Tre markører må overleve: `**fet**` (datoer, tall, navn og titler avsnittet handler om),
`*kursiv*` (verkstittel i løpende tekst) og `[[term]]` (ordlisteoppslag; et trykk åpner
definisjonen). Regler:
- Markørene går i par. Et oddetall `**` er en feil.
- Ingen markør sluker mellomrom, tegn eller bindestrek: `**1945**,` er riktig; `**1945,**`,
  `** 1945 **` og `de **-beleiringen av Medina**` er feil.
- Fet markerer den norske motsvarigheten, ikke de samme tegnene. Fransk `**30 000 mots**`
  blir `**30 000 ord**`.
- Ikke legg til fet som ikke står i fransk. Ikke fet hele setninger.

## 4. Ordlisteoppslag — den viktigste regelen

Hvert franske `[[...]]` blir nøyaktig ett norsk `[[...]]`, **i setningen, på samme sted i
resonnementet**.

Parker aldri termen sist i avsnittet. La aldri et hull stå igjen, og la ikke oppslaget
forsvinne i en omskriving (`[[razzias]]` som blir «raid, raske raid» uten klammer). Det er
samme feil:

> Feil: `svekket fremfor alt av : kristne korsfarere plyndret byen. [[Erobringen av Konstantinopel]]`
>
> Riktig: `svekket fremfor alt av [[erobringen av Konstantinopel under det fjerde korstoget (1204)]], da vestlige korsfarere plyndret byen.`

Teksten i termen er ikke fri. Den må være en nøkkel registrert for kurset i
`ios/Sophia/Resources/Locales/glossary.nb.json`. En ukjent nøkkel vises som død tekst.
Briefen fra `scripts/make_translation_briefs.py` lister de tillatte nøklene; bruk én tegn
for tegn, med de store bokstavene slik de står.

Setningen må være grammatisk **med nøkkelen satt inn**. Norsk bøyer bestemthet og genitiv
med endelser, og det er der det går galt:

- Ingenting limes på etter `]]`: `[[Kalif]]ene`, `[[Ekko]]s` og `[[Quraysh]]-stammen` er
  feil. Skriv om: `stemmen til [[Ekko]]`, `den mektige stammen [[Quraysh]]`.
- Ikke `en` / `et` / `ei` / `den` / `det` / `de` foran en nøkkel som allerede begynner slik:
  `lei av den [[Den offisielle Paris-salongen]]` er feil, `lei av [[Den offisielle
  Paris-salongen]]` er riktig.
- Etter tall og flertallsord står flertall, men nøkkelen bøyes ikke. Feil: `Makten går over
  til [[Kalifs]]`. Riktig: `Makten går over til etterfølgerne hans, som får tittelen
  [[Kalif]].`
- Passer ikke nøkkelen, bygger du om setningen. Nøkkelen endrer du ikke.
- En nøkkel på engelsk, latin eller fransk (`Kalifs`, `Naiads`, `Oread`, `Ummah`, `Male rør
  og friluft`, `Baudelairesk "milt"`) er en feil i ordlisten. Meld den: den rettes i
  `glossary.nb.json` og i kursteksten i samme endring (`kalifer`, `najader`, `oreade`,
  `umma`, `malingstuber og friluftsmaleri`, `spleen`). Skriv aldri en uregistrert nøkkel.
- Forklaringene i ordlisten følger §1, §5, §7 og §8 som kursteksten.

## 5. Egennavn, titler og faste ord

**Oversett aldri for- og etternavn.** Degas er Degas, Munch er Munch (ikke «tygge»), Pan
er guden Pan (ikke «Bang»), Nemesis er hevnens gudinne.

**Etablert norsk form** når den finnes: `Christophe Colomb` → `Christoffer Columbus`,
`Charlemagne` → `Karl den store`, `Londres` → `London`, `Aix-la-Chapelle` → `Aachen`,
`Byzance` → `Bysants` (ikke `Byzantium`), `URSS` → `Sovjetunionen` (ikke `USSR`), `ONU` →
`FN`, `OTAN` → `NATO` (men `NATO på engelsk og OTAN på fransk` når teksten forklarer
forkortelsen), `Zeus` → `Zevs`. Myten om Narkissos: `Narkissos`, `Ekko`, `Teiresias`,
`Kefisos`, `Ovid`, `oreade`, `najader`, `dryader`; blomsten er `narsiss`, ikke `påskelilje`.
Én skrivemåte per kurs: `Kaba`/`Kabaen`, ikke også `Kaaba`.

**Islam.** `Hégire` → `hijra` (aldri `Hegira`, `Hegiraen`, `avgang`). `Mahomet` →
`Muhammed`, `La Mecque` → `Mekka`, `calife` → `kalif` (`kalifer`, `kalifene`), `razzia`
(`razziaer`), `jizya`, `dhimma`, `Oumma` → `umma`, `idoles` → `avgudsbilder`. Feil: `Denne
avgangen, Hegira, markerer år 1 av islam.` Riktig: `Denne utvandringen, hijra, markerer år 1
i den islamske tidsregningen.`

**Verkstitler har den norske utgivelsestittelen**, ikke en kalk (hele listen i
`content/terminology/oeuvres.json`): *Impresjon, soloppgang* (ikke *Print, stigende sol*),
*Frokost i det grønne* (ikke *Lunsj på gresset*), *Det ondes blomster*, *Kamerat Napoleon*,
*Vidunderlige nye verden*, *Prosessen*, *De elendige*, *Rødt og svart*, *På sporet av den
tapte tid*, *Den fremmede*, *Den lille prinsen*, *Skrik*, *Mona Lisa*, *Stjernenatt*.
*Le Spleen de Paris*, *Correspondances*, *Recueillement* og *Les Demoiselles d'Avignon*
står uendret; de tre diktene forklares én gang («samsvar mellom sansene», «andakt»).
Finnes ingen norsk tittel, beholder du originalen og forklarer ved første forekomst. I
*1984* heter novlangue `nytale` og doublepensée `dobbelttenkning`; i `[[...]]` gjelder den
registrerte nøkkelen (`Newspeak` på kurs 101 og 102) til ordlisten er rettet. Nye navn føres
i `scripts/proper_nouns.json` under `nb`; rett aldri samme navn to ganger.

**Produktord**, ett ord overalt (`content/terminology/termes_produit.json`):

| Fransk | Norsk | Aldri |
| --- | --- | --- |
| cours / quiz | `kurs` (et kurs, kurset) / `quiz` (quizen) | `leksjon`, `prøve`, `test` |
| Parcours / Collection | `Løype` / `samling` | `rute`, `reise`, `kolleksjon` |
| Niveau / Série | `nivå` (NIVÅ 3) / `rekke` (`5 dager på rad`) | `serie` |
| essai gratuit | `gratis prøveperiode` (`Start prøveperioden`) | `prøven`, `gratis prøve` |
| Premium / Sophia / XP | uendret (`Sophias`) | oversatt |
| bloqueur TikTok | `TikTok-blokkering`, `blokkeringen` | `blockeren`, `sperre` |
| Entraînement / Biblio | `Trening` / `Bibliotek` | `praksis`, `Biblio` |
| réviser / objectif / matière | `repetere` / `mål` / `fag` | `revidere`, `objektiv` |
| débloquer / glossaire / ami | `lås opp` / `ordliste` / `venn` | `glossar`, `kamerat` |
| résilier / rang / l'offre | `si opp abonnementet` / `rang` / `tilbudet` | `avbryt`, `rangering`, `betalingsmur` |
| Mensuel / Annuel / Gratuit | `Månedlig` / `Årlig` / `Gratis` | |

**Feller.** Oversett etter sammenhengen i fransk, aldri via engelsk:

| Fransk (betydning her) | Norsk | Aldri |
| --- | --- | --- |
| condamnation / beau-père (mors mann) | `domfellelse` / `stefar` | `overbevisning` / `svigerfar` |
| spleen / deux états (d'âme) | `spleen` / `to sinnstilstander` | `milt` / `to stater` |
| lumière / touche / sensation | `lyset` / `penselstrøk` / `sanseinntrykk` | `lett` / `berøring` / `sensasjon` |
| motif (maleri) / tubes de peinture | `motivet` / `malingstuber` | `mønsteret` / `rør` |
| pouvoir / puissant / l'espace | `makt` / `mektig` / `verdensrommet` | `kraft` / `kraftig` / `plass` |
| ruse / appelle / carrefour / se referme | `knep` / `roper` / `møtested` / `går mot slutten` | `rus` / `ringer` / `veiskille` / `nærmer seg` |
| marchand (d'art) / œuvre | `kunsthandler` / `verk` | `kjøpmann` / `arbeid` |
| flâneur / caravane / pétrole / gravité | `flanør` / `karavane` / `olje` / `tyngdekraft` | `barnevogn` / `campingvogn` / `matolje` / `alvor` |
| Terminale / trimestre / docteurs | `VG3` / `termin` / `forskere med doktorgrad` | `doktorer` (= leger) |

## 6. Sitater

Et sitat er ingen oversettelsesøvelse. Finnes en kjent norsk ordlyd, bruker du den. Ellers
oversetter du kort og klart.

- Anførselstegn `« »`, uten mellomrom innenfor. Aldri rette `" "`, aldri `“ ”`, aldri en
  blanding, aldri et foreldreløst tegn. Feil: `Omdøpt til "profetens by"`, `Hun svarer:
  «Noen!» »`. Riktig: `Omdøpt til «profetens by».`, `Hun svarer: «Noen her!»`
- Sitat i sitat: rette enkle `'...'` (`‘ ’` er forbudt).
- Punktum innenfor når hele setningen er sitert: `«Alle dyr er like.»` Utenfor når sitatet
  er en del av setningen: `Den ble dømt for «krenkelse av offentlig moral».`
- `quote.attribution` er `Forfatter, Verk`. Gir fransk taleren etter tankestrek, komma eller
  i parentes: `Victor Hugo, De elendige (biskop Myriel)`.

Kjent sitat fra *Kamerat Napoleon*: `«Alle dyr er like, men noen dyr er likere enn andre.»`

## 7. Tegnsetting og typografi

Mekanisk kontroll, uten unntak.

- **Ingen lang tankestrek `—`, ingen kort `–`**, heller ikke den norske tankestreken. Skriv
  om med komma, kolon, parentes eller punktum. Tallrekker med bindestrek: `1945-1975`.
- Ingen nullbreddetegn, ingen hardt mellomrom (U+00A0), heller ikke i tall. Apostrofen er
  rett `'` (U+0027), ikke `’`; genitiv etter s: `Sokrates' forsvarstale`. `« »` skal brukes.
- Aldri mellomrom foran `, . ; : ! ?` (fransk har det foran `: ; ! ?` og innenfor `« »`;
  fjern det). Aldri to mellomrom etter hverandre.
- Komma etter innledende leddsetning, ikke foran `at`: `Da Hera oppdaget knepet, straffet
  hun Ekko.`
- Liten forbokstav: måneder, ukedager, `første verdenskrig`, `renessansen`, `den store
  depresjonen`, `kong Arthur`, `profeten`, nasjonalitetsord (`fransk`, `persisk`).
- Ingen franske eller engelske rester. `siècle`, `dans` som preposisjon, `l'`, `d'un`,
  `Baudelairian` er feil. `du` og `dans` som norske ord er i orden.

## 8. Tall, datoer, mål

- Tusen: vanlig mellomrom. `30 000`, `10 000 mann`. Aldri punktum, aldri komma, aldri hardt
  mellomrom. Firesifret i ett: `4000`. Årstall deles aldri.
- Desimaler: komma. `3,5 %` (vanlig mellomrom foran `%`), `2,5 millioner`. På knapper: `Lås
  opp med -70 %`, ikke `Lås opp mine -70 %`.
- Årstall: `En 1857` → `i 1857`, `vers 630` → `rundt 630`, `en l'an 622` → `i år 622`. Aldri
  `på 1857`, `om 1857`. Ved setningsstart kommer verbet rett etter: `I 1857 publiserte
  Baudelaire ...`. Tiår: `les années 1930` → `1930-årene` / `på 1930-tallet`, aldri `1930s`.
- Århundrer: `-tallet`, **ett hundre lavere** enn romertallet: `VIIe siècle` → `600-tallet`
  (ikke `700-tallet`), `XVe` → `1400-tallet`, `fin du XIXe` → `slutten av 1800-tallet`. `Ier
  siècle` → `det første århundre e.Kr.`; før vår tidsregning, med ordenstall: `IIIe siècle
  av. J.-C.` → `det 3. århundre f.Kr.`. Aldri romertall, aldri `XVe` alene.
  Feil: `På 700-tallet interesserte Arabia nesten ingen.` Riktig: `På 600-tallet brydde
  nesten ingen seg om Arabia.`
- Tidsregning: `ca. 450 f.Kr.`, `622 e.Kr.` (`e.Kr.` bare der det trengs). Dato: `24.
  februar 2022` (punktum etter dagen). Ett mønster per kurs.
- Alder og varighet: `à 6 ans` → `som 6-åring` / `6 år gammel`; `en 22 ans` → `på 22 år`.
  Aldri `på 6 år` om alder.
- Etter tall står flertall: `360 avgudsbilder` (ikke `360 idolisere`), `seks dikt`, `tre
  kurs`. `én` med aksent bare for trykk: `én domfellelse`. Regentnavn beholder romertallet:
  `Napoleon III`, `Ludvig XIV`.
- Ingen omregning. `Mds`/`Md` → `milliarder`, `M` → `millioner`, med ord.

## 9. Kontroll

```bash
python scripts/check_course_translation.py --lang nb
python scripts/check_course_translation.py --lang nb course_102_*
```

Kontrollen melder per kurs: avvik i skjelettet, skjeve markører, antall oppslag,
uregistrerte nøkler, termer parkert sist i avsnittet, dobbel artikkel, `s` limt etter `]]`,
forbudte tegn, mellomrom, franske og engelske rester, og romertall og `av. J.-C.` som ikke
er lokalisert. En ren kjøring er et krav, ikke et forslag.

Kontrollen ser ikke alt. Søk selv etter `Vi` først i setningen, `Hun`/`Han` om ting, `"`,
`700-tallet` for `VIIe`, `Echo`, `Hegira`, `Byzantium`, `leksjon`, `prøven`, `Her er
hvordan`. Les til slutt høyt: det som høres oversatt ut, er oversatt for dårlig.
