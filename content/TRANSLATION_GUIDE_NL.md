# Cursusvertaling — van het Frans naar het Nederlands

Het Frans (`content/courses/fr/`) is de bron. Dit document is de
specificatie voor `content/courses/nl/`. Het gaat in zijn geheel naar
wie de vertaling schrijft, en `scripts/check_course_translation.py --lang nl`
past de regels mechanisch toe.

Dezelfde regels gelden voor de andere talen; alleen cijfers,
aanhalingstekens en eigennamen veranderen.

## 1. Wat we willen

We leveren geen vertaling. We leveren de **Nederlandse editie** van de
cursus: de tekst die een moedertaalredacteur uit dezelfde notities
zou schrijven. De lezer mag niet merken dat het origineel Frans was.

In deze volgorde:

1. **Correct.** Geen feiten verdraaien, verzinnen of overslaan.
2. **Vloeiend.** Idiomatisch Nederlands. Hardop lezen zonder struikelen.
3. **Eenvoudig.** Korte zinnen. Gewone woorden. Een nieuwsgierige
   tiener moet kunnen volgen. Liever „liet zien” dan „demonstreerde”,
   „gebruikte” dan „benutte”.
4. **Trouw aan de vorm.** Ongeveer hetzelfde aantal zinnen, dezelfde
   volgorde van gedachten, dezelfde lengte met twintig procent speling,
   zodat de layout blijft staan.

Register: **Standaardnederlands**. Geen dialect, geen ambtelijk jargon,
geen zinnen met drie lagen tussenzinnen. Informeel **je/jij**, niet
*u* van een essay. Hedendaagse spelling: ij en ei op hun plaats,
apostrof recht `'` (nooit `’`).

Zinnen bouw je vrij om. Het Frans rijgt lange periodes met een
puntkomma en vertelt in de tegenwoordige tijd; Nederlandse
vakproza voor jongeren prefereert de **onvoltooid verleden tijd**
voor geschiedenis, tenzij het Frans het presens bewust, kort,
als effect gebruikt.

## 2. Het skelet blijft staan

Alleen tekstvelden worden vertaald. De rest kopieert het gereedschap
uit het Franse skelet en blijft onaangeroerd: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Veld | Wat het is | Noot |
| --- | --- | --- |
| `title` | Titel op de kaart en in de hero | Kort. Canonieke in het Nederlands uitgegeven titel, als de cursus over een werk gaat. |
| `subtitle` | Regel onder de titel | Een jaar of interval (`1945`, `1945-1975`) blijft. |
| `description` | Blurb van twee zinnen | Moet zelfstandig staan. |
| `hero.hook` | Eén zin als aas | Reclame, geen proza. |
| `sections[].title` | Sectgelabel | Naamwoordgroep, geen punt aan het eind. |
| `paragraph.text` | Doorlopende tekst | Het hoofdwerk. |
| `image.caption` | Bijschrift | Korte zin; punt alleen bij een volle zin. |
| `funFact.text` | Kader | Licht, spreektaal. |
| `takeaway.text` | Slot | Wat moet blijven hangen. |
| `quote.text` | Citaat | Zie §6. |
| `quote.attribution` | Wie het zei | Zie §6. |
| `timeline.events[].date` | `1789`, `juni 1940`, `ca. 450 v.Chr.` | Cijfers blijven. Maanden vertaal je. `v.Chr.` / `n.Chr.`, nooit `av. J.-C.`. |
| `timeline.events[].title` | Label | Heel kort, geen punt. |
| `timeline.events[].detail` | Eén zin | |

## 3. Markeringen in de regel

Drie merken moeten overleven:

- `**vet**` — data, getallen, namen en titels van werken waarover
  de alinea gaat.
- `*cursief*` — de titel van een werk in proza.
- `[[term]]` — glossariumlemma. Aantikken opent de definitie.

Regels:

- Merken lopen in paren. Een oneven aantal `**` is fout.
- Geen merk slokt spatie of leesteken op: `**1945**,` is goed,
  `**1945,**` en `** 1945 **` zijn fout.
- Vet betekent het Nederlandse equivalent, niet dezelfde tekens.
  Frans `**30 000 mots**` wordt `**30.000 woorden**`.
- Voeg geen vet toe dat er in het Frans niet staat. Vet geen
  hele zin.

## 4. Glossariumtermen — de belangrijkste regel

Elke Franse `[[...]]` wordt precies één Nederlandse `[[...]]`,
**in de zin, op dezelfde plek in het argument**.

Parkeer de term nooit aan het eind van de alinea. Laat geen gat
achter. Dit is dezelfde fout:

> Fout: `verzwakt vooral door : christelijke kruisvaarders
> plunderden de stad. [[De verovering van Constantinopel]]`

> Goed: `verzwakt vooral door [[de verovering van Constantinopel
> tijdens de Vierde Kruistocht (1204)]], toen westerse kruisvaarders
> de stad plunderden.`

De tekst van de term is niet vrij. Het moet een geregistreerde
sleutel zijn voor deze cursus in
`ios/Sophia/Resources/Locales/glossary.nl.json`. Een onbekende
sleutel komt eruit als dode tekst. De brief van
`scripts/make_translation_briefs.py` somt de toegestane sleutels
op; gebruik er één, teken voor teken, met de hoofdletters uit
het register.

De verbouwing moet grammaticaal blijven **met de term erin**:

- Zet geen `de` / `het` / `een` voor een sleutel die al zo begint
  (`De allegorie van de Russische Revolutie`).
- De sleutel staat in de nominatief. Plak niets achter `]]`:
  `[[proletariaat]]s` is fout. Bouw de zin om
  (`het uitgebuite [[proletariaat]]`).
- Past de sleutel niet, dan bouw je de zin om. De sleutel wijzig
  je niet.
- `tijdens [[Tweede Wereldoorlog]]` is krom. Beter:
  `toen de **[[Tweede Wereldoorlog]]** in volle gang was`.
- `Alarik I,` lijkt op een gestrand lidwoord. Schrijf
  `Alarik de eerste` of `Alarik I`.

## 5. Eigennamen

Machinevertaling leest achternamen als soortnamen. Harde regels:

**Vertaal nooit voor- en achternaam.** Degas blijft Degas, niet
„Ontgassen”. Corneille blijft Corneille. Le Corbusier blijft
Le Corbusier.

**Gevestigde Nederlandse vorm**, als die bestaat:
`Christophe Colomb` → `Christoffel Columbus`, `Guillaume le Conquérant`
→ `Willem de Veroveraar`, `Londres` → `Londen`, `Pékin` → `Peking`,
`Aix-la-Chapelle` → `Aken`, `Charlemagne` → `Karel de Grote`,
`Tchernobyl` → `Tsjernobyl`, `Michel-Ange` → `Michelangelo`.

**Werktitels dragen de in het Nederlands uitgegeven titel**, geen
calque:

| Frans | Nederlands |
| --- | --- |
| *Impression, soleil levant* | *Impressie, zonsopgang* |
| *La Ferme des animaux* | *Dierenboerderij* |
| *Le Rouge et le Noir* | *Rood en zwart* |
| *À la recherche du temps perdu* | *Op zoek naar de verloren tijd* |
| *Le Déjeuner sur l'herbe* | *Het ontbijt op het gras* |
| *Les Demoiselles d'Avignon* | *De jonge dames van Avignon* |
| *Les Fleurs du Mal* | *De bloemen van het kwaad* |
| *Les Misérables* | *De ellendigen* |
| *Le Petit Prince* | *De kleine prins* |
| *L'Étranger* | *De vreemdeling* |
| *Le Mythe de Sisyphe* | *De mythe van Sisyphus* |
| *Le Père Goriot* | *Vader Goriot* |

Bestaat er geen vaste Nederlandse titel, dan laat je het origineel
staan en licht je het bij de eerste verschijning toe.

**Personages uit vertaalde literatuur dragen de naam uit de
standaard Nederlandse editie:**

| Werk | Frans | Nederlands |
| --- | --- | --- |
| *Dierenboerderij* | Malabar | Bokser |
| *Dierenboerderij* | Brille-Babil | Pieper |
| *Dierenboerderij* | Boule de neige | Sneeuwbal |
| *Dierenboerderij* | Vieux Major | Oude Majoor |
| *De kleine prins* | Bésixdouze | planetoïde B-612 |
| *1984* | novlangue | Nieuwsspraak |
| *1984* | doublepensée | dubbeldenk |

Het register staat in `scripts/proper_nouns.json`. Voeg daar toe,
repareer dezelfde naam niet twee keer.

## 6. Citaten

Een citaat is geen vertaaloefening. Bestaat er een canonieke
Nederlandse formulering, gebruik die. Anders vertaal je kort
en helder.

- Nederlandse aanhalingstekens `„ ”`. Geen Franse `« »`.
- De punt van de geciteerde zin staat binnen het sluitende teken:
  `„Alle dieren zijn gelijk.”`
- `quote.attribution` is `Auteur, Werk`. Als het Frans de spreker
  na een streepje, komma of tussen haakjes geeft:
  `Victor Hugo, De ellendigen (bisschop Bienvenu)`.

## 7. Interpunctie en typografie

Mechanische controle, zonder uitzonderingen.

- **Geen kastlijn `—`, geen gedachtestreepje `–`.** Herschrijf
  met komma, dubbele punt, haakjes of punt. Getallenreeksen met
  koppelteken: `1945-1975`.
- Geen `« »`, geen tekens van nulbreedte, geen harde spatie.
- De apostrof is recht `'` (U+0027), zoals in de Franse bestanden.
  Niet `’`.
- Nooit een spatie voor `, . ; : ! ?`. Nooit twee spaties op rij.
- Spatie na dubbele punt en puntkomma; gebruik beide spaarzaam:
  Nederlands vakproza prefereert de punt.
- Geen Franse resten. `siècle`, `dans` als voorzetsel, `l'`,
  `d'un` in een Nederlandse alinea is fout, evenals een
  onvertaalde Franse plaatsnaam. Let op: `les` is Nederlands
  („les”), `dans` is Nederlands („dans”) — die laat je staan.

## 8. Getallen, data, eenheden

- Duizendtallen: punt. `30 000` → `30.000`. Geen spatie, geen komma.
  (Huisconventie, zodat de checker de Franse spatie vangt.)
- Decimalen: komma. `3,5 %` → `3,5%`. Geen spatie voor `%`.
- Eeuwen: `XVe siècle` → `15e eeuw` / `in de 15e eeuw`. Nooit
  `XVe` alleen, nooit `vijftiende` als het Frans een Romeins
  cijfer geeft dat je als `15e` kunt zetten.
- Tijdrekening: `v.Chr.` en `n.Chr.`: `450 v.Chr.`, `622 n.Chr.`.
- Data: `24 februari 2022`. Eén schema per cursus.
- Geen omrekeningen. Metrisch blijft metrisch.
- `Mds`/`Md` → `miljarden`. `M` → `miljoenen`, in woorden.

## 9. Controle

```bash
python scripts/check_course_translation.py --lang nl
python scripts/check_course_translation.py --lang nl course_102_*
```

De validator meldt per cursus: structuurdrift, scheve merken,
aantal lemma's, ongeregistreerde sleutels, termen geparkeerd
aan het eind van de alinea, dubbel lidwoord, verboden tekens,
spaties, Franse resten en niet-gelokaliseerde getallen.
Een schone run is een plicht, geen suggestie.
