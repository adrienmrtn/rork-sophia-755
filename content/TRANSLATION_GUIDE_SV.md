# Kursöversättning — från franska till svenska

Franskan (`content/courses/fr/`) är källan. Det här dokumentet är
specifikationen för `content/courses/sv/`. Det går i sin helhet till
den som skriver översättningen, och
`scripts/check_course_translation.py --lang sv` tillämpar reglerna
mekaniskt.

Samma regler gäller de andra språken; bara siffror, citattecken och
egennamn ändras.

## 1. Vad vi vill ha

Vi levererar inte en översättning. Vi levererar den **svenska utgåvan**
av kursen: texten en modersmålsredaktör skulle skriva från samma
anteckningar. Läsaren ska inte märka att originalet var franskt.

I den här ordningen:

1. **Korrekt.** Förvräng, hitta inte på och hoppa inte över fakta.
2. **Flytande.** Idiomatisk svenska. Går att läsa högt utan att snubbla.
3. **Enkelt.** Korta meningar. Vardagliga ord. En nyfiken tonåring
   ska hänga med. Hellre „visade” än „demonstrerade”, „använde” än
   „tillvaratog”.
4. **Troget formen.** Ungefär samma antal meningar, samma
   tankeordning, samma längd med tjugo procent spelrum, så att
   layouten håller.

Register: **rikssvenska**. Ingen dialekt, inget kanslispråk, inga
meningar med tre lager bisatser. Informellt **du**, inte *ni* som i
en uppsats. Modern stavning; apostrof rak `'` (aldrig `’`).

Bygg om meningarna fritt. Franskan trär långa perioder med semikolon
och berättar i presens; svensk sakprosa för unga föredrar
**preteritum** i historieberättelsen, såvida inte franskan använder
presens medvetet, kort, som effekt.

## 2. Skelettet står kvar

Bara textfält översätts. Resten kopierar verktyget från det franska
skelettet och rörs inte: `id`, `subject`, `subcategory`, `type`,
`asset`, `image`, `ratio`, `free`.

| Fält | Vad det är | Not |
| --- | --- | --- |
| `title` | Titel på kortet och i hero | Kort. Den utgivna svenska titeln, om kursen handlar om ett verk. |
| `subtitle` | Rad under titeln | Ett år eller intervall (`1945`, `1945-1975`) står kvar. |
| `description` | Blurb på två meningar | Ska stå för sig själv. |
| `hero.hook` | En mening som bete | Reklam, inte prosa. |
| `sections[].title` | Avsnittsrubrik | Nominalfras, ingen punkt i slutet. |
| `paragraph.text` | Löptext | Huvudarbetet. |
| `image.caption` | Bildtext | Kort mening; punkt bara om det är en hel mening. |
| `funFact.text` | Ram | Lätt, talspråk. |
| `takeaway.text` | Avslut | Det som ska sitta kvar. |
| `quote.text` | Citat | Se §6. |
| `quote.attribution` | Vem som sa det | Se §6. |
| `timeline.events[].date` | `1789`, `juni 1940`, `ca 450 f.Kr.` | Siffrorna står kvar. Månader översätter du. `f.Kr.` / `e.Kr.`, aldrig `av. J.-C.`. |
| `timeline.events[].title` | Etikett | Mycket kort, ingen punkt. |
| `timeline.events[].detail` | En mening | |

## 3. Markeringar i raden

Tre märken måste överleva:

- `**fet**` — datum, tal, namn och verkstitlar som stycket handlar om.
- `*kursiv*` — verkstitel i löptext.
- `[[term]]` — glossaruppslag. Tryck öppnar definitionen.

Regler:

- Märken går i par. Ett udda antal `**` är fel.
- Inget märke sväljer blanksteg eller skiljetecken: `**1945**,` är
  rätt, `**1945,**` och `** 1945 **` är fel.
- Fet betyder den svenska motsvarigheten, inte samma tecken.
  Franskt `**30 000 mots**` blir `**30.000 ord**`.
- Lägg inte till fetstil som inte finns i franskan. Fetmarkera
  inte en hel mening.

## 4. Glossartermer — den viktigaste regeln

Varje fransk `[[...]]` blir exakt en svensk `[[...]]`,
**i meningen, på samma plats i argumentet**.

Parkera aldrig termen i slutet av stycket. Lämna inget hål.
Det här är samma fel:

> Fel: `försvagad främst av : kristna korsfarare
> plundrade staden. [[Erövringen av Konstantinopel]]`

> Rätt: `försvagad främst av [[erövringen av Konstantinopel
> under det fjärde korståget (1204)]], när västerländska
> korsfarare plundrade staden.`

Texten i termen är inte fri. Det måste vara en registrerad nyckel
för den här kursen i
`ios/Sophia/Resources/Locales/glossary.sv.json`. En okänd nyckel
kommer ut som död text. Briefen från
`scripts/make_translation_briefs.py` räknar upp tillåtna nycklar;
använd en, tecken för tecken, med registretets versaler.

Ombyggnaden måste vara grammatisk **med termen inne**:

- Sätt inte `en` / `ett` / `den` / `det` framför en nyckel som
  redan börjar så (`Allegorin om den ryska revolutionen`).
- Nyckeln står i grundform. Klistra inget efter `]]`:
  `[[proletariat]]et` är fel. Bygg om meningen
  (`det utnyttjade [[proletariat]]`).
- Passar nyckeln inte, bygger du om meningen. Nyckeln ändrar
  du inte.
- `under [[Andra världskriget]]` kan sitta, men
  `under den [[Andra världskriget]]` är snett. Bättre:
  `när **[[Andra världskriget]]** rasade`.
- `Alarik I,` ser ut som ett strandat led. Skriv
  `Alarik den förste` eller `Alarik I`.

## 5. Egennamn

Maskinöversättning läser efternamn som appellativer. Hårda regler:

**Översätt aldrig för- och efternamn.** Degas förblir Degas, inte
„Avgasning”. Corneille förblir Corneille. Le Corbusier förblir
Le Corbusier.

**Etablerad svensk form**, när den finns:
`Christophe Colomb` → `Kristoffer Columbus`, `Guillaume le Conquérant`
→ `Vilhelm Erövraren`, `Londres` → `London`, `Pékin` → `Peking`,
`Aix-la-Chapelle` → `Aachen`, `Charlemagne` → `Karl den store`,
`Tchernobyl` → `Tjernobyl`, `Michel-Ange` → `Michelangelo`.

**Verkstitlar bär den utgivna svenska titeln**, ingen kalk:

| Franska | Svenska |
| --- | --- |
| *Impression, soleil levant* | *Impression, soluppgång* |
| *La Ferme des animaux* | *Djurfarmen* |
| *Le Rouge et le Noir* | *Rött och svart* |
| *À la recherche du temps perdu* | *På spaning efter den tid som flytt* |
| *Le Déjeuner sur l'herbe* | *Frukost i det gröna* |
| *Les Demoiselles d'Avignon* | *Flickorna från Avignon* |
| *Les Fleurs du Mal* | *Ondskans blommor* |
| *Les Misérables* | *Samhällets olycksbarn* |
| *Le Petit Prince* | *Lille prinsen* |
| *L'Étranger* | *Främlingen* |
| *Le Mythe de Sisyphe* | *Myten om Sisyfos* |
| *Le Père Goriot* | *Pappa Goriot* |

Finns ingen fast svensk titel lämnar du originalet och förklarar
vid första förekomsten.

**Personer i översatt litteratur bär namnet från den etablerade
svenska utgåvan:**

| Verk | Franska | Svenska |
| --- | --- | --- |
| *Djurfarmen* | Malabar | Boxer |
| *Djurfarmen* | Brille-Babil | Skrikhals |
| *Djurfarmen* | Boule de neige | Snöboll |
| *Djurfarmen* | Vieux Major | Gamle Major |
| *Lille prinsen* | Bésixdouze | asteroid B-612 |
| *1984* | novlangue | Newspeak |
| *1984* | doublepensée | dubbeltänk |

Registret står i `scripts/proper_nouns.json`. Lägg till där,
laga inte samma namn två gånger.

## 6. Citat

Ett citat är ingen översättningsövning. Finns en kanonisk svensk
formulering, använd den. Annars översätter du kort och klart.

- Citattecken `„ ”`. Inga franska `« »`.
- Punkten i den citerade meningen står innanför det avslutande
  tecknet: `„Alla djur är jämlika.”`
- `quote.attribution` är `Författare, Verk`. Om franskan ger
  talaren efter streck, komma eller inom parentes:
  `Victor Hugo, Samhällets olycksbarn (biskop Bienvenu)`.

## 7. Interpunktion och typografi

Mekanisk kontroll, utan undantag.

- **Inget tankstreck `—`, inget halvgevir `–`.** Skriv om med
  komma, kolon, parentes eller punkt. Talserier med bindestreck:
  `1945-1975`.
- Inga `« »`, inga nollbreddstecken, inget hårt blanksteg.
- Apostrofen är rak `'` (U+0027), som i de franska filerna.
  Inte `’`.
- Aldrig blanksteg före `, . ; : ! ?`. Aldrig två blanksteg i rad.
- Blanksteg efter kolon och semikolon; använd båda sparsamt:
  svensk sakprosa föredrar punkten.
- Inga franska rester. `siècle`, `dans` som preposition, `l'`,
  `d'un` i ett svenskt stycke är fel, liksom ett oöversatt
  franskt ortnamn. Observera: `dans` är svenskt („dans”),
  `du` är svenskt („du”) — de får stå.

## 8. Tal, datum, enheter

- Tusental: punkt. `30 000` → `30.000`. Inget blanksteg, inget
  komma. (Huskonvention, så att kontrollen fångar det franska
  blanksteget.)
- Decimaler: komma. `3,5 %` → `3,5%`. Inget blanksteg före `%`.
- Århundraden: `XVe siècle` → `1400-talet` / `på 1400-talet`.
  Aldrig `XVe` ensamt.
- Tideräkning: `f.Kr.` och `e.Kr.`: `450 f.Kr.`, `622 e.Kr.`.
- Datum: `24 februari 2022`. Ett schema per kurs.
- Inga omräkningar. Metriskt förblir metriskt.
- `Mds`/`Md` → `miljarder`. `M` → `miljoner`, i ord.

## 9. Kontroll

```bash
python scripts/check_course_translation.py --lang sv
python scripts/check_course_translation.py --lang sv course_102_*
```

Kontrollen rapporterar per kurs: strukturavvikelse, sneda märken,
antal uppslag, oregistrerade nycklar, termer parkerade i slutet
av stycket, dubbel artikel, förbjudna tecken, blanksteg, franska
rester och olokaliserade tal. En ren körning är ett krav, inte
ett förslag.
