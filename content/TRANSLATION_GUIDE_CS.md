# Překlad kurzů — z francouzštiny do češtiny

Francouzština (`content/courses/fr/`) je zdroj. Tento dokument je
specifikace `content/courses/cs/`. Dostane ho celý ten, kdo píše
překlad, a `scripts/check_course_translation.py --lang cs` ho
uplatňuje mechanicky.

Stejná pravidla platí i pro ostatní jazyky; mění se jen čísla,
uvozovky a vlastní jména.

## 1. Co chceme

Neodevzdáváme překlad. Odevzdáváme **české vydání** kurzu: text,
který by z týchž poznámek napsal rodilý redaktor. Čtenář nemá
poznat, že originál byl francouzský.

V tomto pořadí:

1. **Správně.** Nekruť, nevymýšlej a nevynechávej fakta.
2. **Plynule.** Idiomatická čeština. Nahlas se čte bez zakopnutí.
3. **Jednoduše.** Krátké věty. Obecná slova. Zvědavý teenager
   stačí. Spíš „ukázal“ než „demonstroval“, „použil“ než
   „preferenčně využil“.
4. **Věrně formě.** Zhruba stejný počet vět, stejný sled myšlenek,
   stejná délka s dvacetiprocentní vůlí, aby zůstal zlom.

Registr: **spisovná hovorová čeština**. Bez nářečí, bez úředního
žargonu, bez třípatrových vedlejších vět. Tykání **ty**, ne *Vy*
jako v eseji. Současný pravopis; apostrof rovný `'` (nikdy `’`).

Věty stavíš znovu. Francouzština dlouhé periody spojuje středníkem
a vypráví přítomným časem; český naučný text má rád **minulý čas**
u historického vyprávění, ledaže francouzština přítomný čas použije
záměrně, krátce, jako efekt.

## 2. Kostra zůstává

Překládají se jen textová pole. Zbytek nástroj zkopíruje z
francouzské kostry a nesaháš na to: `id`, `subject`, `subcategory`,
`type`, `asset`, `image`, `ratio`, `free`.

| Pole | Co to je | Poznámka |
| --- | --- | --- |
| `title` | Titulek na kartě a v heru | Krátký. V Česku vydaný název, pokud je kurz o díle. |
| `subtitle` | Řádek pod titulem | Rok nebo interval (`1945`, `1945-1975`) zůstává. |
| `description` | Dvouvětý blurb | Stojí sám. |
| `hero.hook` | Jedna věta-návnada | Reklama, ne próza. |
| `sections[].title` | Název oddílu | Jmenná fráze, na konci tečka není. |
| `paragraph.text` | Souvislý text | Hlavní práce. |
| `image.caption` | Popisek | Krátká věta; tečka jen u úplné věty. |
| `funFact.text` | Rámeček | Lehký, mluvený. |
| `takeaway.text` | Závěr | To, co má zůstat. |
| `quote.text` | Citát | Viz §6. |
| `quote.attribution` | Kdo to řekl | Viz §6. |
| `timeline.events[].date` | `1789`, `červen 1940`, `asi 450 př. n. l.` | Číslice zůstávají. Měsíce překládáš. `př. n. l.` / `n. l.`, nikdy `av. J.-C.`. |
| `timeline.events[].title` | Štítek | Velmi krátký, bez tečky. |
| `timeline.events[].detail` | Jedna věta | |

## 3. Značky v řádku

Tři značky musí přežít:

- `**tučné**` — data, čísla, jména a ty názvy děl, o nichž
  odstavec mluví.
- `*kurziva*` — název díla v próze.
- `[[termín]]` — heslo slovníčku. Klepnutí otevře definici.

Pravidla:

- Značky chodí v páru. Lichý počet `**` je chyba.
- Žádná značka nespolkne mezeru ani interpunkci: `**1945**,`
  je správně, `**1945,**` a `** 1945 **` jsou špatně.
- Tučné značí český ekvivalent, ne tytéž znaky. Francouzské
  `**30 000 mots**` bude `**30.000 slov**`.
- Nepřidávej tučné, které ve francouzštině není. Netučni celou větu.

## 4. Slovníčková hesla — nejdůležitější pravidlo

Každé francouzské `[[...]]` se stane právě jedním českým `[[...]]`,
**ve větě, na stejném místě argumentu**.

Nikdy nenechávej heslo na konci odstavce. Nikdy nenechávej díru.
Je to táž chyba:

> Špatně: `oslabené především : křesťanští křižáci
> vydrancovali město. [[Dobytí Konstantinopole]]`

> Dobře: `oslabené především [[dobytím Konstantinopole
> během čtvrté křížové výpravy (1204)]], když západní křižáci
> vydrancovali město.`

Text hesla není volný. Musí to být klíč registrovaný pro tento
kurz v `ios/Sophia/Resources/Locales/glossary.cs.json`. Neznámý
klíč vypadne jako mrtvý text. Brief z
`scripts/make_translation_briefs.py` vypíše povolené klíče; použij
jeden znak po znaku, včetně velkých písmen.

Věta musí zůstat gramatická **se vsazeným heslem**:

- Čeština nemá členy. Nestav `ten` / `ta` / `to` před klíč,
  který tak už začíná.
- Klíč je v nominativu. Neohýbej za `]]`: `[[proletariát]]u`
  je špatně. Přestav větu (`vykořisťovaný [[proletariát]]`).
- Když klíč nesedí, přestav větu. Klíč neměň.
- `během [[Druhá světová válka]]` je špatně (chybí pád). Lepší:
  `když probíhala **[[Druhá světová válka]]**` nebo `v době
  **[[Druhá světová válka]]**`.
- `Alarich I,` vypadá jako utržený člen. Piš: `I. Alarich`.

## 5. Vlastní jména

Strojový překlad čte příjmení jako obecná podstatná jména. Tvrdá
pravidla:

**Nikdy nepřekládej křestní jméno a příjmení.** Degas zůstane
Degas, ne „Odgazovat“. Corneille zůstane Corneille. Le Corbusier
zůstane Le Corbusier.

**Zažitý český tvar**, pokud existuje:
`Christophe Colomb` → `Kryštof Kolumbus`, `Guillaume le Conquérant`
→ `Vilém Dobyvatel`, `Londres` → `Londýn`, `Pékin` → `Peking`,
`Aix-la-Chapelle` → `Cáchy`, `Charlemagne` → `Karel Veliký`,
`Tchernobyl` → `Černobyl`, `Michel-Ange` → `Michelangelo`.

**Názvy děl nesou název vydaný v Česku**, ne kalku:

| Francouzsky | Česky |
| --- | --- |
| *Impression, soleil levant* | *Dojem, východ slunce* |
| *La Ferme des animaux* | *Farma zvířat* |
| *Le Rouge et le Noir* | *Červený a černý* |
| *À la recherche du temps perdu* | *Hledání ztraceného času* |
| *Le Déjeuner sur l'herbe* | *Snídaně v trávě* |
| *Les Demoiselles d'Avignon* | *Avignonské slečny* |
| *Les Fleurs du Mal* | *Květy zla* |
| *Les Misérables* | *Bídníci* |
| *Le Petit Prince* | *Malý princ* |
| *L'Étranger* | *Cizinec* |
| *Le Mythe de Sisyphe* | *Mýtus o Sisyfovi* |
| *Le Père Goriot* | *Goriotův strejček* |

Když zažitý český název není, nech originál a při prvním výskytu
vysvětli.

**Postavy přeložené literatury nesou jméno ze školního vydání
Gabriela Gössela (1991) a maturitačních rozborů:**

| Dílo | Francouzsky | Česky |
| --- | --- | --- |
| *Farma zvířat* | Malabar | Boxer |
| *Farma zvířat* | Brille-Babil | Pištík |
| *Farma zvířat* | Boule de neige | Kuliš |
| *Farma zvířat* | Vieux Major | starý Major |
| *Malý princ* | Bésixdouze | planetka B-612 |
| *1984* | novlangue | Newspeak |
| *1984* | doublepensée | doublethink |

Registr je v `scripts/proper_nouns.json`. Tam to dopiš, neopravuj
totéž jméno dvakrát.

Na kurzu 102 je registrovaný klíč novlangue **Newspeak**. Nevymýšlej
jiný tvar uvnitř `[[...]]` na tomto kurzu, pokud takový klíč není.

## 6. Citáty

Citát není překladatelské cvičení. Když existuje kanonická česká
formulace, použij ji. Jinak překládej krátce a čistě.

- Uvozovky `„ ”`. Žádné francouzské `« »`.
- Tečka citované věty je uvnitř uzavírací uvozovky:
  `„Všechna zvířata jsou si rovna.”`
- `quote.attribution` je `Autor, Dílo`. Když francouzština mluvčího
  dává za pomlčku, čárku nebo do závorky:
  `Victor Hugo, Bídníci (biskup Bienvenu)`.

Kanonický citát z *Farmy zvířat*:
`„Všechna zvířata jsou si rovna, ale některá zvířata jsou si rovnější.”`

## 7. Interpunkce a typografie

Mechanická kontrola, bez výjimek.

- **Žádná pomlčka `—`, žádná půlčtverčíková `–`.** Přepiš čárkou,
  dvojtečkou, závorkou nebo tečkou. Číselné řady se spojovníkem:
  `1945-1975`.
- Žádné `« »`, žádný znak nulové šířky, žádná pevná mezera.
- Apostrof je rovný `'` (U+0027), jako ve francouzských souborech.
  Ne `’`.
- Nikdy mezera před `, . ; : ! ?`. Nikdy dvě mezery za sebou.
- Mezera po dvojtečce a středníku; obojí používej zřídka: český
  naučný text má rád tečku.
- Žádné francouzské zbytky. `siècle`, `dans` jako předložka, `l'`,
  `d'un` v českém odstavci je chyba, stejně jako nepřeložený
  francouzský toponym.

## 8. Čísla, data, jednotky

- Tisíce: tečka. `30 000` → `30.000`. Ani mezera, ani čárka.
  (Domácí konvence, aby kontrola chytila francouzskou mezeru.)
- Desetinná: čárka. `3,5 %` → `3,5%`. Bez mezery před `%`.
- Století: `XVe siècle` → `15. století` / `v 15. století`.
  Nikdy `XVe` samo.
- Letopočet: `př. n. l.` a `n. l.`: `450 př. n. l.`, `622 n. l.`.
- Datum: `24. února 2022`. Jedno schéma na kurz.
- Bez přepočtů. Metrické zůstává metrické.
- `Mds`/`Md` → `miliardy`. `M` → `miliony`, slovy.

## 9. Kontrola

```bash
python scripts/check_course_translation.py --lang cs
python scripts/check_course_translation.py --lang cs course_102_*
```

Kontrola hlásí na kurz: posun kostry, rozjeté značky, počet hesel,
neregistrované klíče, hesla zaparkovaná na konci odstavce, dvojí
ukazovací zájmeno, zakázané znaky, mezery, francouzské zbytky
a nelokalizovaná čísla. Čistý běh je povinnost, ne návrh.
