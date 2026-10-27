# Oversættelse af kurserne — fra fransk til dansk

Fransk (`content/courses/fr/`) er kilden. Dette dokument er
specifikationen for `content/courses/da/` og for de danske strenge i
appen (quiz, ordliste, brugerflade). Det gives uændret til den, der
oversætter, og `scripts/check_course_translation.py --lang da`
håndhæver det mekanisk.

De samme regler gælder for de andre sprog; kun tal, anførselstegn og
egennavne skifter.

## 1. Hvad vi vil

Vi leverer ikke en oversættelse. Vi leverer **den danske udgave** af
kurset: den tekst, en dansk redaktør ville have skrevet ud fra de
samme noter. Læseren må aldrig kunne mærke, at originalen er fransk.

I denne rækkefølge:

1. **Rigtigt.** Ingen fakta forvrænges, opdigtes eller falder ud.
2. **Flydende.** Idiomatisk dansk. Kan læses højt uden at snuble.
3. **Enkelt.** Korte sætninger. Hverdagsord. En nysgerrig teenager
   skal kunne følge med. Hellere »viste« end »demonstrerede«, hellere
   »brugte« end »anvendte præferentielt«.
4. **Tro mod formen.** Omtrent samme antal sætninger, samme
   tankegang, samme længde med tyve procents slæk, så layoutet holder.

Tone: **varm, kort, uformel**. Brugeren er altid **du** (ental), i
kurser, quizzer, ordliste og brugerflade. Aldrig *De*, aldrig *I*
til én bruger. Bydeform i ental: `Lås op`, `Prøv igen`, `Swipe for
at opdage`. *Vi* bruges kun, når Sophia-holdet taler om sig selv
(`Vi fandt to versioner af din fremgang`).

**Franskt upersonligt »on« er aldrig »vi«.** Det var den hyppigste
fejl i den nuværende tekst (90 segmenter). Brug *man*, *folk*,
*nogen* eller passiv:

> Forkert: `Vi vil slå ham ihjel.` / `Vi bor der i stammer.` /
> `Vi kræver en præcis tegning og en glat overflade.`

> Rigtigt: `Nogen vil slå ham ihjel.` / `Folk lever i stammer.` /
> `Der kræves præcis tegning og en glat overflade.`

**Køn følger dansk, ikke fransk.** Fransk *elle/il* om en ting bliver
*den* eller *det* efter det danske ord (n-ord eller t-ord). *Han* og
*hun* er kun til personer og personificerede væsner, og så efter
personens køn:

> Forkert: `Udvidelsen er ikke kun militær. Hun er også organiseret.`
> Rigtigt: `Ekspansionen er ikke kun militær. Den er også organiseret.`

> Forkert (om Ekko): `Hans krop visner.` / (om Narcissus) `Hendes skønhed tiltrækker alle.`
> Rigtigt: `Hendes krop tørrer ind.` / `Hans skønhed tiltrækker alle.`

*Sin/sit/sine* peger kun tilbage på sætningens grundled. Den unge
mands mor er `hans mor`, ikke `sin mor`, når Teiresias er grundled:
`Seeren **Teiresias** havde advaret hans mor`. Til brugeren skriver du
kønsneutralt (dansk bøjer ikke tillægsord efter køn: `Du er nysgerrig`
gælder alle). Navngivne udtalelser fra kvinder omtales med *hun*, og
du bruger neutrale fællesord (`studerende`, `lærer`), ikke
`studine` eller `lærerinde`.

**Én tid pr. afsnit.** Fransk fortæller ofte i nutid. Behold den
franske tid (dansk tåler historisk nutid fint), men bland aldrig nutid
og datid i samme sætning eller afsnit, medmindre tiden faktisk skifter
(førdatid: `havde advaret`).

> Forkert: `I **1857** udgav **Charles Baudelaire** … Samlingen markerer et vendepunkt.`
> Rigtigt: `I **1857** udgiver **Charles Baudelaire** … Samlingen markerer et vendepunkt.`

**Ingen kalker.** Byg sætningen om på dansk:
`Chez Hugo` → `Hos Hugo` (ikke `I Hugo`); `Voici comment…` →
`Sådan …` (aldrig `Her er hvordan`); `compte sur toi pour` →
`regner med dig, så vi kan …`; `partenaire pour maîtriser` →
`hjælper dig med at mestre`; `briller en société` → `brillere`
(ikke `skinne`); `la personne la plus intéressante de la pièce` →
`den mest interessante person i selskabet` (ikke `i rummet`);
`jamais en rafale` → `aldrig i byger`; `idoles` → `afguder` (aldrig
verbet `idolisere`).

**Faste produktord.** Ét ord pr. begreb i hele appen:

| Fransk | Dansk | Ikke |
| --- | --- | --- |
| cours | kursus, pl. kurser (`Ubegrænsede kurser`) | lektion, lektie |
| quiz | quiz (quizzen, quizzer) | spørgeskema, test, prøve |
| parcours (fane) | Forløb (`Dit forløb`, `Forløbet er gennemført`) | Rute, rejse |
| collection | samling | kollektion |
| niveau | Niveau, forkortet `Niv. 3` | trin, level |
| série (streak) | stime (`Din stime: 5 dage`, `Din stime er i gang!`) | serie, `dage i træk` som navneord |
| essai gratuit | Gratis prøveperiode | gratis prøve, prøvetid |
| Premium | Premium, uændret (`Premium-abonnement`) | præmie |
| Sophia | Sophia, ejefald `Sophias` | Sofia, `Sophia's` |
| bloqueur TikTok | blokering (`TikTok-blokering`) | blokker, blockeren |
| entraînement (fane) | Træning | praksis |
| réviser | repetér, repetition | genopfrisk |
| objectif | mål | objektiv, formål |
| matière | fag (og *emne* for sujet) | materiale |
| ami | ven, pl. venner | følger, kammerat |
| abonnement / mensuel / annuel | abonnement / `Månedligt abonnement` / `Årligt abonnement` | medlemskab |
| débloquer | lås op (`Lås op for Premium`, `Lås kurset op`) | oplåse, frigør |
| annuler l'abonnement | opsig | afmeld |
| valider / conditions | Bekræft / Vilkår | Tjek / Betingelser |
| progression / terminer un cours | fremgang / gennemfør | fremskridt / afslut |
| glossaire | Ordliste | ordbog |
| XP | XP | oplevelsespoint |
| Biblio | Bibliotek | katalog |
| l'offre (paywall) | tilbuddet (`Se tilbuddet`) | betalingsmur |

Andre faste: `Expire dans` → `Udløber om 3 dage`; `Pas de connexion`
→ `Ingen forbindelse`; `Léger / Modéré / Intense` → `Let / Moderat /
Intens`; `Reprends du temps pour toi` → `Få din tid tilbage`;
`Glisse pour découvrir` → `Swipe for at opdage`; `Terminale` → `3.g`;
`trimestre` → `dette semester`; `culture générale` → `almen viden`;
`devenir cultivé` → `blive klogere` (ikke `blive rigtig dannet`, der
lyder som »velopdragen«).

**Ord med to betydninger.** Vælg betydningen fra konteksten, aldrig
den hyppigste engelske. Fundet i den nuværende tekst:

| Fransk | Rigtigt | Aldrig |
| --- | --- | --- |
| spleen (Baudelaire) | spleen | milt (organet) |
| flâneur | flanør | barnevogn |
| condamnation (retslig) | domfældelse, dømt | overbevisning |
| beau-père (mors mand) | stedfar | svigerfar |
| lumière | lyset | let |
| touche (maleri) | penselstrøg | berøring, tast |
| sensation (sanselig) | sansning | sensation |
| pouvoir (politisk) | magt | strøm |
| puis | derefter, siden | dengang |
| appeler (råbe) | råbe | ringe |
| marchand (d'art) | kunsthandler | købmand |
| manquer l'autre | gå glip af den anden | savne |
| sanctuaire | helligdom | fristed |
| chute / clé de lecture | fald / nøgle | efterår / tast |
| deux états (d'âme) | to tilstande | to stater |
| caravane | karavane | campingvogn |
| gravité / pétrole / cellulaire | tyngdekraft / olie / celle- | alvor / mobil |
| Grande Dépression | den store depression | depression (sygdom) |
| soupe populaire / bank run | suppekøkken / stormløb på bankerne | |
| relance (économique) | genopretning, hjælpepakke | helbredelse |
| amnistie générale | almindelig amnesti | general benådning |

## 2. Skelettet bliver

Kun tekstfelterne oversættes. Resten kopierer værktøjet fra det
franske skelet, og du rører det ikke: `id`, `subject`, `subcategory`,
`type`, `asset`, `image`, `ratio`, `free`.

| Felt | Hvad det er | Note |
| --- | --- | --- |
| `title` | Titel på kortet og i heroen | Kort. Den danske udgivelsestitel, hvis kurset handler om et værk. |
| `subtitle` | Linjen under titlen | Årstal eller interval (`1945`, `1945-1975`) bliver stående. |
| `description` | To sætninger på kortet | Skal kunne stå alene. Læses af alle, før kurset åbnes. |
| `hero.hook` | Én lokkende sætning | Reklame, ikke prosa. Første sætning brugeren ser. |
| `sections[].title` | Afsnitsoverskrift | Navneordsforbindelse, intet punktum. |
| `paragraph.text` | Brødtekst | Hovedarbejdet. |
| `image.caption` | Billedtekst | Kort; punktum kun ved hel sætning. |
| `funFact.text` | Boks | Let, mundtlig. |
| `takeaway.text` | Konklusion | Det, der skal blive hængende. |
| `quote.text` | Citat | Se §6. |
| `quote.attribution` | Hvem sagde det | Se §6. |
| `timeline.events[].date` | `1789`, `juni 1940`, `ca. 450 f.Kr.` | Tal forbliver tal. Måneder oversættes, med lille. `f.Kr.` / `e.Kr.`, aldrig `av. J.-C.`. |
| `timeline.events[].title` | Etiket | Meget kort, intet punktum. |
| `timeline.events[].detail` | Én sætning | |

Overskrifter læses for sig i indholdsfortegnelsen. Tjek, at de giver
mening: `Ce que l'impressionnisme a changé` er `Det, impressionismen
ændrede`, ikke `Hvilken impressionisme ændrede sig`.

## 3. Markører i linjen

Tre markører skal overleve:

- `**fed**` — årstal, tal, navne og de værkers titler, afsnittet
  handler om.
- `*kursiv*` — værktitel i prosaen.
- `[[term]]` — ordlisteopslag. Et tryk åbner definitionen.

Regler:

- Markører går i par. Et ulige antal `**` er en fejl.
- Ingen markør sluger mellemrum eller tegnsætning: `**1945**,` er
  rigtigt, `**1945,**` og `** 1945 **` er forkert. Heller ingen
  løse tegn inde i markøren: `**-belejringen af Medina**` er forkert,
  `**belejringen af Medina**` rigtigt.
- Fed markerer den danske ækvivalent, ikke de samme tegn. Fransk
  `**30 000 mots**` bliver `**30.000 ord**`.
- Tilføj ikke fed, som det franske ikke har. Gør ikke en hel sætning
  fed.

## 4. Ordlisteord — den vigtigste regel

Hvert fransk `[[...]]` bliver præcis ét dansk `[[...]]`, **inde i
sætningen, samme sted i argumentet**.

Parkér aldrig termen sidst i afsnittet. Efterlad aldrig et hul. Det er
samme fejl:

> Forkert: `svækket først og fremmest af: korsfarere plyndrede byen.
> [[Erobringen af Konstantinopel]]`

> Rigtigt: `svækket først og fremmest af [[erobringen af
> Konstantinopel under det fjerde korstog (1204)]], da vestlige
> korsfarere plyndrede byen.`

Mist heller ikke markeringen. Fransk `[[razzias]]` blev til
`lancerer raids, hurtige raids` uden link; rigtigt er
`Muhammed iværksætter [[razziaer]], hurtige overfald, for at afskære
fjendens karavaner.`

Termens tekst er ikke fri. Den skal være en nøgle, der er registreret
for kurset i `ios/Sophia/Resources/Locales/glossary.da.json`. En ukendt
nøgle vises som død tekst. Briefen fra `scripts/make_translation_briefs.py`
lister de tilladte nøgler; brug én tegn for tegn, med store og små
bogstaver. Står der i `glossary.da.json` en engelsk, fransk eller
forvansket nøgle (`Naiads`, `Dryads`, `Oread`, `Kalif`,
`Baudelairesk "milt"`, `De byzantinske og sassaniderige imperier`,
`Le Spleen de Paris`, `Symbolik og Baudelaires arv`), retter du
nøglen og `displayTerm` i samme ændring til den danske form
(`najaderne`, `dryaderne`, `kaliffer`, `Parisisk spleen`,
`Det byzantinske og det sassanidiske rige`, `symbolismen`) og bruger
så den. En nøgle, der kun findes i teksten, opfinder du aldrig. En
artikeloverskrift er ikke en term: fransk `[[symbolisme]]` er ikke
`[[Symbolik og Baudelaires arv]]`.

Sætningen skal være grammatisk **med termen sat ind**. På dansk
sidder bestemt artikel og ejefald som endelse, og det er dér, det går
galt:

- Intet efter `]]`. Ingen bestemt endelse, intet ejefalds-s, ingen
  apostrof, ingen bindestreg: `[[Kalif]]'erne`, `[[kaliffer]]ne`,
  `[[Quraysh]]s` og `[[Quraysh]]-stamme` er forkert. Valideringen
  melder `s` efter `]]`.
- Nøglen bestemmer formen (ubestemt/bestemt, ental/flertal). Byg
  sætningen om, så nøglen passer: `Den kraftfulde [[Quraysh]] stamme`
  → `Den mægtige stamme [[Quraysh]] kontrollerer handelen.`;
  `Magten går derefter over til [[Kalif]]'erne` → `Magten går
  derefter til hans efterfølgere, de første [[kaliffer]].`
- Ingen dobbelt artikel. Starter nøglen med `en`, `et`, `den`, `det`
  eller `de`, sætter du ikke en til foran: `det [[Det byzantinske og
  det sassanidiske rige]]` er forkert (valideringen melder det).
- Efter et tal står navneordet i flertal, og nøglen skal passe til
  det: `to [[najader]]`, ikke `to [[najaden]]`.
- Passer nøglen slet ikke, bygger du sætningen om. Nøglen rører du
  ikke uden at rette den i `glossary.da.json`.

## 5. Egennavne

Maskinoversættelse læser efternavne som almindelige ord. Faste regler:

**Oversæt aldrig et person- eller familienavn.** Degas er Degas,
Corneille er Corneille, Le Corbusier er Le Corbusier. Guden Pan er
`Pan`, ikke `Bang`; Munch er `Edvard Munch`; gudinden er `Nemesis`.

**Brug den etablerede danske form**, hvis den findes, og den samme
form i hele kurset: `Christophe Colomb` → `Christoffer Columbus`,
`Guillaume le Conquérant` → `Vilhelm Erobreren`, `Charlemagne` →
`Karl den Store`, `Londres` → `London`, `Pékin` → `Beijing`,
`Aix-la-Chapelle` → `Aachen`, `Tchernobyl` → `Tjernobyl`,
`Michel-Ange` → `Michelangelo`, `Mahomet` → `Muhammed`, `La Mecque`
→ `Mekka`, `Byzance` → `Byzans`, `roi Arthur, reine Guenièvre` →
`kong Arthur, dronning Guinevere`, `ONU, OTAN` → `FN, NATO`
(men skriv `OTAN`, når teksten netop handler om den franske
forkortelse: `NATO på engelsk og OTAN på fransk`).

Græske myter i dansk form, konsekvent: `Écho` → `Ekko`, `Narcisse` →
`Narcissus`, `Tirésias` → `Teiresias`, `Céphise` → `Kefisos`,
`Naïades / Dryades / Oréade` → `najader / dryader / oreade`. Forkert:
`læner Narcisse sig` i ét afsnit og `Narcissus er fortæret` i det
næste. Blomsten *narcisse* er `narcissen`, ikke `påskelilje`: ordet
skal pege på narcissisme.

**Islam.** `Hégire` → `hijra` (`Hijra` som egennavn), aldrig
`Hegira` og aldrig `afgang`: `Denne udvandring, hijra, markerer islams
år 1.` Arabiske termer: `razzia` (pl. `razziaer`), `jizya`, `kalif`
(pl. `kaliffer`), `dhimma`, `umma`, `Kaaba`, `Koranen`. Ingen fransk
flertals-s (`razzias`), ingen engelsk stavning (`Ummah`).

**Regentnumre** skrives med arabertal og punktum: `Ludvig 14.`,
`Henrik 4.`. Står navnet sidst i sætningen, er der kun ét punktum.

**Værktitler bærer den danske udgivelsestitel**, ikke en kalke:

| Fransk | Dansk |
| --- | --- |
| *Les Fleurs du Mal* | *Syndens blomster* (ikke *Ondskabens blomster*) |
| *Le Spleen de Paris* | *Parisisk spleen* |
| *Impression, soleil levant* | *Impression, solopgang* (ikke *Print, stigende sol*) |
| *Le Déjeuner sur l'herbe* | *Frokost i det grønne* (ikke *Frokost på græsset*) |
| *Nymphéas* | *Åkanderne* |
| *La Ferme des animaux* | *Kammerat Napoleon* |
| *Le Meilleur des mondes* | *Fagre nye verden* |
| *Le Procès* / *La Métamorphose* | *Processen* / *Forvandlingen* |
| *L'Étranger* / *Le Mythe de Sisyphe* | *Den fremmede* / *Sisyfos-myten* |
| *À la recherche du temps perdu* | *På sporet af den tabte tid* |
| *Les Misérables* / *Notre-Dame de Paris* | *De elendige* / *Klokkeren fra Notre-Dame* |
| *Le Rouge et le Noir* / *Le Père Goriot* | *Rødt og sort* / *Far Goriot* |
| *Le Petit Prince* | *Den lille prins* |
| *La République* / *Le Banquet* | *Staten* / *Symposion* |
| *Le Cri* / *La Joconde* / *La Nuit étoilée* | *Skriget* / *Mona Lisa* / *Stjernenat* |
| *Les Demoiselles d'Avignon* / *Guernica* | uændret |

Digte og afsnit i et værk står i anførselstegn, på dansk:
`»Spleen og Ideal«`, `»Korrespondancer«` (ikke verbet
`»Korrespondere«`), `»Andagt«`, `»Parisiske billeder«`, `»Vinen«`,
`»Oprøret«`, `»Døden«`. Aldrig engelsk (`"Wine"`, `"The Revolt"`,
`"To introduce narcissism"`): Freuds essay hedder `»Om indførelse af
begrebet narcissisme«`. Har et værk ingen dansk titel, beholder du
originalen og forklarer den ved første omtale.

**Figurer i oversat litteratur bærer navnet fra den danske udgave:**
`novlangue` → `nysprog`, `doublepensée` → `dobbelttænkning` (*1984*),
`Bésixdouze` → `asteroide B-612` (*Den lille prins*).

Registret ligger i `scripts/proper_nouns.json`. Skriv det dér, så du
ikke retter det samme navn to gange.

## 6. Citater

Et citat er ikke en oversættelsesøvelse. Findes der en kanonisk dansk
ordlyd, bruger du den. Ellers oversætter du kort og rent.

- Anførselstegn `»…«`, spidserne peger ind mod citatet. Aldrig
  `«…»`, aldrig lige `"…"`, aldrig engelske `“…”`, og aldrig et løst
  `»` midt i et afsnit (`»Da hun nærmer sig` uden lukning).
- Citat i citat: `›…‹`.
- Et helt citeret udsagn har punktum inden for: `»Han bliver gammel,
  hvis han ikke lærer sig selv at kende.«` Komma efter replik står
  uden for: `»Nogen!«, svarer hun.`
- `quote.attribution` er `Forfatter, Værk`. Giver det franske taleren
  efter tankestreg, komma eller i parentes:
  `Victor Hugo, De elendige (biskop Myriel)`.

Kanonisk citat fra *Kammerat Napoleon*:
`»Alle dyr er lige, men nogle dyr er mere lige end andre.«`

## 7. Tegnsætning og typografi

Mekanisk tjek, uden undtagelser.

- **Ingen lang tankestreg `—`, ingen kort `–`.** Heller ikke den
  danske tankestreg mellem mellemrum. Skriv om med komma, kolon,
  parentes eller punktum. Talintervaller med bindestreg: `1945-1975`.
  Forkert: `omkring **360 afguder** – altså cirka én for hver dag`.
  Rigtigt: `omkring **360 afguder**, altså cirka én for hver dag`.
- Ingen hårdt mellemrum, intet nulbreddetegn, intet BOM.
- Apostroffen er lige `'` (U+0027), som i de franske filer, aldrig
  `’`: `1850'erne`, `Sokrates' forsvarstale`. Ejefald af ord, der
  ikke ender på s, tager ingen apostrof: `Sophias`, `Baudelaires`.
- Aldrig mellemrum før `, ; : ! ?`. Aldrig to mellemrum i træk.
  Altid mellemrum efter komma, kolon og semikolon (undtagen i tal:
  `3,5`).
- Semikolon sjældent: dansk kursustekst foretrækker punktum.
- Ingen franske eller engelske rester. `siècle`, `dans` som
  forholdsord, `l'`, `d'un`, `overhead view` i et dansk afsnit er en
  fejl (`fugleperspektiv`), og det samme er et uoversat fransk
  stednavn.

## 8. Tal, datoer, mål

- Tusinder: punktum. `30 000` → `30.000`. Aldrig mellemrum, aldrig
  komma. Valideringen fanger det franske mellemrum.
- Decimaler: komma. `3,5 %` → `3,5 %`, med almindeligt mellemrum før
  `%` (dansk norm), aldrig hårdt mellemrum.
- Årstal: `En 1857` → `I 1857`. `Vers 630` → `omkring 630` eller
  `ca. 630`. Aldrig `I år 1857` som fast skabelon, aldrig `i byen 622`,
  `ind i 622` eller engelsk `in 622`.
- Århundreder: `XVe siècle` → `1400-tallet` eller `det 15.
  århundrede`. Pas på forskydningen: `VIIe siècle` er `600-tallet` /
  `det 7. århundrede`, aldrig `700-tallet`. Aldrig `XVe` alene,
  aldrig romertal for århundreder.
- Årtier: `les années 1850` → `1850'erne`.
- Tidsregning: `f.Kr.` og `e.Kr.` efter årstallet: `450 f.Kr.`,
  `622 e.Kr.`. Aldrig `av. J.-C.`.
- Dato: `24. februar 2022`. Måned med lille. Én skabelon pr. kursus.
- Alder og varighed: `à 6 ans` → `som 6-årig` eller `6 år gammel`;
  `en vingt ans` → `på tyve år`. Forkert: `Forældreløs af sin far på
  **6 år**`. Rigtigt: `Han mister sin far som **6-årig**.` Sæt
  varigheden, hvor den ikke kan læses som alder: `en købmand på tyve
  år` er forkert, `skabte en verdenscivilisation på bare tyve år`
  rigtigt.
- Efter tal står navneordet i flertal (`seks digte`, `360 afguder`,
  `3 dage`); `hommes` om soldater er `mand`, ubøjet: `**10.000 mand**`.
  Tallet én får accent, når det betyder antal: `én Gud`, aldrig
  `en Én Gud`.
- Intet omregnes. Metrisk forbliver metrisk: `5 km`, `20 kg`.
- `Mds`/`Md` → `milliarder`. `M` → `millioner`, med bogstaver.

## 9. Tjek

```bash
python scripts/check_course_translation.py --lang da
python scripts/check_course_translation.py --lang da course_102_*
```

Valideringen rapporterer pr. kursus: forskudt skelet, skæve markører,
antal ordlisteopslag, uregistrerede nøgler, termer parkeret sidst i
afsnittet, endelse efter `]]`, dobbelt artikel foran en nøgle,
efterladte småord foran et hul (`af ,`, `at.`), forbudte tegn (`—`,
`–`, `’`, hårdt mellemrum), mellemrum, franske og engelske rester,
romertal for århundreder, `av. J.-C.` og ulokaliserede tusinder.
`»` og `«` er tilladt for dansk; retningen tjekker du selv.

Valideringen ser ikke *vi* for *on*, *hun* om en ting, falske venner,
skiftende navneformer eller blandede tider. Læs derfor hvert kursus
højt én gang, efter en ren kørsel. En ren kørsel er et krav, ikke et
forslag.
