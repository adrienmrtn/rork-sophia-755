# Oversættelse af kurserne — fra fransk til dansk

Fransk (`content/courses/fr/`) er kilden. Dette dokument er specifikationen for
`content/courses/da/` og for appens danske strenge (quiz, ordliste,
brugerflade); `scripts/check_course_translation.py --lang da` håndhæver det
mekanisk. De andre sprog følger samme regler.

## 1. Hvad vi vil

Vi leverer ikke en oversættelse. Vi leverer **den danske udgave** af kurset: den
tekst, en dansk redaktør ville have skrevet ud fra de samme noter. Læseren må
aldrig kunne mærke, at originalen er fransk. I denne rækkefølge:

1. **Rigtigt.** Ingen fakta forvrænges, opdigtes eller falder ud.
2. **Flydende.** Idiomatisk dansk. Kan læses højt uden at snuble.
3. **Enkelt.** Korte sætninger, hverdagsord. En nysgerrig teenager skal kunne
   følge med. Hellere »viste« end »demonstrerede«.
4. **Tro mod formen.** Omtrent samme antal sætninger, samme tankegang, samme
   længde med tyve procents slæk, så layoutet holder.

Tone: **varm, kort, uformel**. Brugeren er altid **du** (ental), overalt. Aldrig
*De*, aldrig *I* til én bruger; bydeform i ental (`Lås op`, `Prøv igen`). *Vi*
er kun Sophia-holdet (`Vi fandt to versioner af din fremgang`).

**Fransk upersonligt »on« er aldrig »vi«** (90 segmenter i den nuværende tekst).
Brug *man*, *folk*, *nogen* eller passiv:

> Forkert: `Vi vil slå ham ihjel.` / `Vi bor der i stammer.` / `Vi kræver en præcis tegning.`
> Rigtigt: `Nogen vil slå ham ihjel.` / `Folk lever i stammer.` / `Der kræves præcis tegning.`

**Køn følger dansk, ikke fransk.** *Elle/il* om en ting bliver *den* eller *det*
efter det danske ord; *han* og *hun* kun om personer og væsner, efter deres køn;
*sin* kun om grundleddet.

> Forkert: `Udvidelsen … Hun er også organiseret.` / (Ekko) `Hans krop visner.` / `Teiresias havde advaret sin mor`
> Rigtigt: `Ekspansionen … Den er også organiseret.` / `Hendes krop tørrer ind.` / `… advaret hans mor`

Til brugeren skriver du kønsneutralt (`Du er nysgerrig` gælder alle). Udtalelser
fra kvinder omtales med *hun* og neutrale fællesord (`studerende`, `lærer`),
aldrig `studine` eller `lærerinde`.

**Én tid pr. afsnit.** Behold den franske tid (dansk tåler historisk nutid), men
bland aldrig nutid og datid. Forkert: `I **1857** udgav **Baudelaire** …
Samlingen markerer et vendepunkt.` Rigtigt: `I **1857** udgiver **Baudelaire**
…`

**Ingen kalker.** `Chez Hugo` → `Hos Hugo` (ikke `I Hugo`); `Voici comment…` →
`Sådan …`, `Voici ce que…` → `Her er, hvad …` (aldrig `Her er hvordan`); `compte
sur toi pour` → `regner med dig, så vi kan …`; `partenaire pour maîtriser` →
`hjælper dig med at mestre`; `briller` → `brillere` (ikke `skinne`); `de la
pièce` → `i selskabet` (ikke `i rummet`); `en rafale` → `i byger`; `idoles` →
`afguder` (aldrig `idolisere`).

**Faste produktord.** Ét ord pr. begreb i hele appen:

| Fransk | Dansk | Aldrig |
| --- | --- | --- |
| cours / quiz | kursus, pl. kurser (`Ubegrænsede kurser`) / quiz, quizzer | lektion, lektie / spørgeskema, test |
| parcours / collection / niveau | Forløb (`Dit forløb`) / samling / Niveau (`Niv. 3`) | Rute, rejse / kollektion / trin, level |
| série (streak) | stime (`Din stime: 5 dage`, `Din stime er i gang!`) | serie; `dage i træk` som navneord |
| essai gratuit / abonnement | Gratis prøveperiode / `Månedligt` og `Årligt abonnement` | gratis prøve, prøvetid / medlemskab |
| Premium / Sophia | uændret (`Premium-abonnement`, `Sophias kurser`) | præmie / Sofia, `Sophia's` |
| bloqueur / entraînement | blokering (`TikTok-blokering`) / Træning | blokker, blockeren / praksis |
| réviser / objectif / matière / ami | repetér / mål / fag / ven, pl. venner | genopfrisk / objektiv / materiale / følger |
| débloquer / annuler | lås op (`Lås op for Premium`) / opsig | oplåse, frigør / afmeld |
| valider / conditions / progression / terminer | Bekræft / Vilkår / fremgang / gennemfør | Tjek / Betingelser / fremskridt / afslut |
| glossaire / Biblio / XP / l'offre | Ordliste / Bibliotek / XP / tilbuddet (`Se tilbuddet`) | ordbog / katalog / oplevelsespoint / betalingsmur |
| Expire dans / Pas de connexion | `Udløber om 3 dage` / `Ingen forbindelse` | |
| Léger, Modéré, Intense / Terminale / trimestre | `Let`, `Moderat`, `Intens` / `3.g` / `dette semester` | lys |
| Reprends du temps / Glisse pour découvrir | `Få din tid tilbage` / `Swipe for at opdage` | |
| culture générale / devenir cultivé | almen viden / `blive klogere` | `dannet` alene (= velopdragen) |

**Ord med to betydninger.** Konteksten bestemmer, aldrig den hyppigste engelske
betydning. Fundet i den nuværende tekst (rigtigt, *aldrig*): spleen → `spleen`
(*milt*); flâneur → `flanør` (*barnevogn*); condamnation → `domfældelse`
(*overbevisning*); beau-père → `stedfar` (*svigerfar*); lumière → `lyset`
(*let*); touche → `penselstrøg` (*berøring*); sensation → `sansning`; pouvoir →
`magt` (*strøm*); puis → `derefter` (*dengang*); appeler → `råbe` (*ringe*);
marchand d'art → `kunsthandler` (*købmand*); manquer l'autre → `gå glip af`
(*savne*); sanctuaire → `helligdom` (*fristed*); deux états → `to tilstande`
(*to stater*); chute → `fald` (*efterår*); amnistie générale → `almindelig
amnesti` (*general benådning*); bank run → `stormløb på bankerne`.

## 2. Skelettet bliver

Kun tekstfelterne oversættes. Resten kopierer værktøjet fra det franske skelet,
og du rører det ikke: `id`, `subject`, `subcategory`, `type`, `asset`, `image`,
`ratio`, `free`.

| Felt | Hvad det er | Note |
| --- | --- | --- |
| `title` | Titel på kortet og i heroen | Kort. Den danske udgivelsestitel, hvis kurset handler om et værk. |
| `subtitle` | Linjen under titlen | Årstal eller interval (`1945`, `1945-1975`) bliver stående. |
| `description` | To sætninger på kortet | Står alene. Læses af alle, før kurset åbnes. |
| `hero.hook` | Én lokkende sætning | Reklame, ikke prosa. Det første, brugeren ser. |
| `sections[].title` | Afsnitsoverskrift | Intet punktum. Står alene i indholdsfortegnelsen: `Det, impressionismen ændrede`, ikke `Hvilken impressionisme ændrede sig`. |
| `paragraph.text` / `image.caption` | Brødtekst / billedtekst | Hovedarbejdet / kort, punktum kun ved hel sætning. |
| `funFact.text` / `takeaway.text` | Boks / konklusion | Let, mundtlig / det, der skal blive hængende. |
| `quote.text` / `quote.attribution` | Citat / hvem sagde det | Se §6. |
| `timeline.events[].date` | `1789`, `juni 1940`, `ca. 450 f.Kr.` | Tal forbliver tal. Måneder med lille. `f.Kr.` / `e.Kr.`, aldrig `av. J.-C.`. |
| `timeline.events[].title` / `.detail` | Etiket / én sætning | Etiketten meget kort, intet punktum. |

## 3. Markører i linjen

Tre markører skal overleve: `**fed**` (årstal, tal, navne og de værker,
afsnittet handler om), `*kursiv*` (værktitel i prosaen) og `[[term]]`
(ordlisteopslag; et tryk åbner definitionen).

- Markører går i par. Et ulige antal `**` er en fejl.
- Ingen markør sluger mellemrum, tegnsætning eller løse tegn: `**1945**,` er
  rigtigt; `**1945,**`, `** 1945 **` og `**-belejringen af Medina**` er forkert.
- Fed markerer den danske ækvivalent: fransk `**30 000 mots**` bliver `**30.000
  ord**`.
- Tilføj ikke fed, som det franske ikke har. Gør ikke en hel sætning fed.

## 4. Ordlisteord — den vigtigste regel

Hvert fransk `[[...]]` bliver præcis ét dansk `[[...]]`, **inde i sætningen,
samme sted i argumentet**. Parkér aldrig termen sidst i afsnittet, efterlad
aldrig et hul, og mist aldrig markeringen:

> Forkert: `svækket først og fremmest af: korsfarere plyndrede byen. [[Erobringen af Konstantinopel]]`
> Rigtigt: `svækket først og fremmest af [[erobringen af Konstantinopel under det fjerde korstog (1204)]], da vestlige korsfarere plyndrede byen.`
> Forkert: `Muhammed lancerer raids, hurtige raids` (fransk `[[razzias]]`, linket væk)
> Rigtigt: `Muhammed iværksætter [[razziaer]], hurtige overfald, for at afskære fjendens karavaner.`

Termens tekst er ikke fri. Den skal være en nøgle, der er registreret for kurset
i `ios/Sophia/Resources/Locales/glossary.da.json`; en ukendt nøgle vises som død
tekst. Briefen fra `scripts/make_translation_briefs.py` lister de tilladte
nøgler; brug én tegn for tegn. Står der en engelsk eller forvansket nøgle
(`Naiads`, `Kalif`, `Baudelairesk "milt"`, `De byzantinske og sassaniderige
imperier`), retter du nøgle og `displayTerm` i samme ændring (`najaderne`,
`kaliffer`, `Parisisk spleen`, `Det byzantinske og det sassanidiske rige`) og
bruger så den. En artikeloverskrift er ikke en term: fransk `[[symbolisme]]` er
`[[symbolismen]]`, ikke `[[Symbolik og Baudelaires arv]]`.

Sætningen skal være grammatisk **med termen sat ind**. På dansk sidder bestemt
artikel og ejefald som endelse, og dér går det galt:

- Intet efter `]]`: ingen endelse, intet ejefalds-s, ingen apostrof, ingen
  bindestreg. `[[Kalif]]'erne`, `[[kaliffer]]ne`, `[[Quraysh]]s`,
  `[[Quraysh]]-stamme` er forkert.
- Nøglen bestemmer formen (bestemt/ubestemt, ental/flertal); byg sætningen om:
  `Den kraftfulde [[Quraysh]] stamme` → `Den mægtige stamme [[Quraysh]]`; `til
  [[Kalif]]'erne` → `til hans efterfølgere, de første [[kaliffer]]`.
- Ingen dobbelt artikel: `det [[Det byzantinske og det sassanidiske rige]]` er
  forkert.
- Efter et tal står flertal: `to [[najader]]`, ikke `to [[najaden]]`.
- Passer nøglen slet ikke, bygger du sætningen om. Nøglen ændrer du kun i
  `glossary.da.json`, aldrig kun i teksten.

## 5. Egennavne

**Oversæt aldrig et personnavn.** Degas er Degas. Guden Pan er `Pan`, ikke
`Bang`; `Munch` er Edvard Munch; gudinden er `Nemesis`, ikke »fjenden«.

**Brug den etablerede danske form**, og den samme i hele kurset: `Pékin` →
`Beijing`, `Michel-Ange` → `Michelangelo`, `Mahomet` → `Muhammed`, `La Mecque` →
`Mekka`, `Byzance` → `Byzans`, `roi Arthur, reine Guenièvre` → `kong Arthur,
dronning Guinevere`, `ONU, OTAN` → `FN, NATO` (men `NATO på engelsk og OTAN på
fransk`, når teksten handler om forkortelsen). Regentnumre: `Ludvig 14.`.

Myter i dansk form, konsekvent: `Écho` → `Ekko`, `Narcisse` → `Narcissus`,
`Tirésias` → `Teiresias`, `Céphise` → `Kefisos`, `Naïades / Dryades` → `najader
/ dryader`. Forkert: `Echo` og `Ekko` i samme kursus. Blomsten er `narcissen`,
ikke `påskelilje`: ordet skal pege på narcissisme.

**Islam.** `Hégire` → `hijra`, aldrig `Hegira` eller `afgang`: `Denne
udvandring, hijra, markerer islams år 1.` Termer: `razzia` (pl. `razziaer`),
`jizya`, `kalif` (pl. `kaliffer`), `dhimma`, `umma`, `Kaaba`, `Koranen`; intet
fransk flertals-s, ingen engelsk stavning (`Ummah`).

**Værktitler bærer den danske udgivelsestitel**, ikke en kalke:

| Fransk | Dansk |
| --- | --- |
| *Les Fleurs du Mal* / *Le Spleen de Paris* | *Syndens blomster* (ikke *Ondskabens blomster*) / *Parisisk spleen* |
| *Impression, soleil levant* | *Impression, solopgang* (ikke *Print, stigende sol*) |
| *Le Déjeuner sur l'herbe* / *Nymphéas* | *Frokost i det grønne* (ikke *på græsset*) / *Åkanderne* |
| *La Ferme des animaux* / *Le Meilleur des mondes* | *Kammerat Napoleon* / *Fagre nye verden* |
| *Le Procès* / *La Métamorphose* / *L'Étranger* | *Processen* / *Forvandlingen* / *Den fremmede* |
| *À la recherche du temps perdu* / *Le Mythe de Sisyphe* | *På sporet af den tabte tid* / *Sisyfos-myten* |
| *Les Misérables* / *Le Rouge et le Noir* / *Le Père Goriot* | *De elendige* / *Rødt og sort* / *Far Goriot* |
| *Le Petit Prince* / *Le Cri* / *La Joconde* | *Den lille prins* / *Skriget* / *Mona Lisa* |
| *Les Demoiselles d'Avignon* / *Guernica* | uændret |

Digte og afsnit på dansk, i anførselstegn: `»Spleen og Ideal«`,
`»Korrespondancer«` (ikke `»Korrespondere«`), `»Andagt«`, `»Vinen«`,
`»Oprøret«`, aldrig `"Wine"` eller `"The Revolt"`. Freuds essay er `»Om
indførelse af begrebet narcissisme«`. Uden dansk titel: original, forklaret
første gang.

**Figurer bærer navnet fra den danske udgave:** `novlangue` → `nysprog`,
`doublepensée` → `dobbelttænkning`, `Bésixdouze` → `asteroide B-612`. Registret
ligger i `scripts/proper_nouns.json`; skriv det dér, så du ikke retter det samme
navn to gange.

## 6. Citater

Findes der en kanonisk dansk ordlyd, bruger du den; ellers kort og rent.

- Anførselstegn `»…«`, spidserne ind mod citatet. Aldrig `«…»`, `"…"` eller
  `“…”`, og aldrig et løst `»` midt i et afsnit. Citat i citat: `›…‹`.
- Helt udsagn: punktum indenfor (`»Han bliver gammel, hvis han ikke lærer sig
  selv at kende.«`). Komma efter replik udenfor: `»Nogen!«, svarer hun.`
- `quote.attribution` er `Forfatter, Værk`, en taler i parentes: `Victor Hugo,
  De elendige (biskop Myriel)`. Kanonisk: `»Alle dyr er lige, men nogle dyr er
  mere lige end andre.«`

## 7. Tegnsætning og typografi

- **Ingen tankestreg `—` eller `–`**, heller ikke den danske mellem mellemrum.
  Skriv om med komma, kolon, parentes eller punktum; intervaller med bindestreg
  (`1945-1975`). Forkert: `**360 afguder** – altså én for hver dag`. Rigtigt:
  `**360 afguder**, altså én for hver dag`.
- Intet hårdt mellemrum, intet nulbreddetegn, intet BOM.
- Apostroffen er lige `'` (U+0027), aldrig `’`: `1850'erne`, `Sokrates'
  forsvarstale`. Ejefald uden apostrof: `Sophias`, `Baudelaires`.
- Aldrig mellemrum før `, ; : ! ?`, aldrig to mellemrum. Altid mellemrum efter
  komma, kolon og semikolon (undtagen i tal: `3,5`). Semikolon sjældent.
- Ingen franske eller engelske rester: `siècle`, `dans`, `l'`, `d'un` eller
  `overhead view` (→ `fugleperspektiv`) i et dansk afsnit er en fejl, ligesom et
  uoversat fransk stednavn.

## 8. Tal, datoer, mål

- Tusinder: punktum. `30 000` → `30.000`. Aldrig mellemrum, aldrig komma.
- Decimaler: komma. `3,5 %`, almindeligt mellemrum før `%`.
- Årstal: `En 1857` → `I 1857`; `Vers 630` → `omkring 630` / `ca. 630`. Aldrig
  `i byen 622`, `ind i 622` eller `in 622`.
- Århundreder: `XVe siècle` → `1400-tallet` / `det 15. århundrede`. Pas på
  forskydningen: `VIIe siècle` er `600-tallet`, aldrig `700-tallet`, og aldrig
  romertal.
- Årtier: `1850'erne`. Tidsregning: `450 f.Kr.`, `622 e.Kr.`. Dato: `24. februar
  2022`, måned med lille.
- Alder og varighed: `à 6 ans` → `som 6-årig`; `en vingt ans` → `på tyve år`.
  Forkert: `Forældreløs af sin far på **6 år**`, `en købmand på tyve år` (læses
  som alder). Rigtigt: `Han mister sin far som **6-årig**`, `skabte en
  verdenscivilisation på bare tyve år`.
- Efter tal står flertal (`seks digte`, `360 afguder`); soldater tælles i ubøjet
  `mand`: `**10.000 mand**`. Talordet `én` får accent: `én Gud`, aldrig `en Én
  Gud`.
- Intet omregnes (`5 km`, `20 kg`). `Mds`/`Md` → `milliarder`, `M` →
  `millioner`, med bogstaver.

## 9. Tjek

```bash
python scripts/check_course_translation.py --lang da
python scripts/check_course_translation.py --lang da course_102_*
```

Valideringen melder skelet, markører, ordlisteopslag (antal, registrering,
placering, `s` efter `]]`, dobbelt artikel), småord foran et hul (`af ,`,
`at.`), forbudte tegn, mellemrum, franske og engelske rester, romertal, `av.
J.-C.` og tusindtalsmellemrum. `»` og `«` er tilladt; retningen tjekker du selv.
Den ser ikke *vi* for *on*, *hun* om en ting, falske venner, skiftende
navneformer eller blandede tider: læs hvert kursus højt efter en ren kørsel. En
ren kørsel er et krav, ikke et forslag.
