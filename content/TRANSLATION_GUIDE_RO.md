# Traducerea cursurilor — din franceză în română

Franceza (`content/courses/fr/`) este sursa. Acest document este
specificația pentru `content/courses/ro/`. Ajunge integral la persoana
care scrie traducerea, iar `scripts/check_course_translation.py --lang ro`
aplică regulile mecanic.

Aceleași reguli țin și la celelalte limbi; se schimbă doar numerele,
ghilimelele și numele proprii.

## 1. Ce vrem

Nu predăm o traducere. Predăm **ediția românească** a cursului: textul
pe care un redactor nativ l-ar fi scris din aceleași note. Cititorul nu
trebuie să-și dea seama că originalul era francez.

În această ordine:

1. **Corect.** Fără să strâmbi, să născocești sau să sari fapte.
2. **Curgător.** Română idiomatică. Se citește cu voce tare fără poticnire.
3. **Simplu.** Fraze scurte. Cuvinte obișnuite. Un adolescent curios
   trebuie să țină pasul. Mai bine „a arătat” decât „a evidențiat”,
   „a folosit” decât „a utilizat”.
4. **Credincios formei.** Aproape același număr de fraze, aceeași ordine
   a ideilor, aceeași lungime cu o marjă de douăzeci la sută, ca
   așezarea în pagină să țină.

Registru: **română standard**. Fără regionalisme, fără limbaj de cancelarie,
fără fraze cu incize pe trei etaje. Tratament informal cu **tu**, nu
*dumneavoastră* de eseu. Ortografie contemporană: â în interiorul
cuvântului, î la capete (`român`, `în`, `a fi`); apostrof drept `'`
(niciodată `’`).

Frazele le refaci liber. Franceza leagă perioade lungi cu punct și
virgulă și povestește la prezent; proza didactică românească preferă
**perfectul compus** la narațiunea istorică, în afară de cazul în care
franceza folosește prezentul intenționat, scurt, ca efect.

## 2. Scheletul rămâne

Se traduc doar câmpurile de text. Restul îl copiază uneltele din
scheletul francez și nu se atinge: `id`, `subject`, `subcategory`,
`type`, `asset`, `image`, `ratio`, `free`.

| Câmp | Ce este | Notă |
| --- | --- | --- |
| `title` | Titlul de pe card și din hero | Scurt. Titlul canonic publicat în română, dacă cursul e despre o operă. |
| `subtitle` | Rândul de sub titlu | Un an sau un interval (`1945`, `1945-1975`) rămâne. |
| `description` | Blurb de două fraze | Trebuie să stea singur. |
| `hero.hook` | O frază-momeală | Reclamă, nu proză. |
| `sections[].title` | Titlu de secțiune | Grup nominal, fără punct la final. |
| `paragraph.text` | Text continuu | Munca principală. |
| `image.caption` | Legendă | O frază scurtă; punct doar dacă e frază întreagă. |
| `funFact.text` | Chenar | Ușor, colocvial. |
| `takeaway.text` | Încheiere | Ce trebuie să rămână. |
| `quote.text` | Citat | Vezi §6. |
| `quote.attribution` | Cine a spus | Vezi §6. |
| `timeline.events[].date` | `1789`, `iunie 1940`, `cca. 450 î.Hr.` | Cifrele rămân. Lunile se traduc. `î.Hr.` / `d.Hr.`, niciodată `av. J.-C.`. |
| `timeline.events[].title` | Etichetă | Foarte scurtă, fără punct. |
| `timeline.events[].detail` | O frază | |

## 3. Marcajele din linie

Trei mărci trebuie să supraviețuiască:

- `**aldin**` — date, numere, nume și titluri de opere despre care
  vorbește paragraful.
- `*cursiv*` — titlul unei opere în proză.
- `[[termen]]` — articol de glosar. Atingerea deschide definiția.

Reguli:

- Mărcile umblă în perechi. Un număr impar de `**` e greșeală.
- Nicio marcă nu înghite spațiu sau punctuație: `**1945**,` e bine,
  `**1945,**` și `** 1945 **` sunt greșite.
- Aldinul înseamnă echivalentul românesc, nu aceleași semne.
  Francezul `**30 000 mots**` devine `**30.000 de cuvinte**`.
- Nu adăuga aldin care nu e în franceză. Nu îngroșa o frază întreagă.

## 4. Termenii de glosar — regula cea mai importantă

Fiecare `[[...]]` francez devine exact un `[[...]]` românesc,
**în frază, în același loc al argumentului**.

Nu parca niciodată termenul la capătul paragrafului. Nu lăsa o gaură.
Aceasta e aceeași greșeală:

> Greșit: `slăbit mai ales de : cruciații creștini
> au jefuit orașul. [[Cucerirea Constantinopolului]]`

> Bine: `slăbit mai ales de [[cucerirea Constantinopolului
> în timpul Cruciadei a patra (1204)]], când cruciații occidentali
> au jefuit orașul.`

Textul termenului nu e liber. Trebuie să fie o cheie înregistrată
pentru cursul ăsta în `ios/Sophia/Resources/Locales/glossary.ro.json`.
O cheie necunoscută iese ca text mort. Brief-ul din
`scripts/make_translation_briefs.py` enumeră cheile permise; folosește
una, semn cu semn, cu majusculele din registru.

Fraza trebuie să rămână gramaticală **cu termenul băgat înăuntru**:

- Unele chei poartă deja articolul enclitic (`proletariatul`,
  `stalinismul`). Nu pune `un` / `o` / `cel` în față.
- Cheia e în nominativ și nu se declină. Nu lipi nimic după `]]`:
  `[[proletariatul]]ui` e greșit. Refă fraza
  (`exploatat, [[proletariatul]] rezistă`).
- Dacă cheia nu se așază, refaci fraza. Cheia nu se schimbă.
- `în timpul [[Al Doilea Război Mondial]]` e greșit (lipsește cazul).
  Mai bine: `când era în toi **[[Al Doilea Război Mondial]]**`.
- `Alaric I,` arată ca un articol sau o conjuncție abandonată. Scrie
  `Alaric primul` sau `Alaric I`.

## 5. Numele proprii

Traducerea automată citește numele ca pe substantive comune. Reguli
tari:

**Nu traduce niciodată prenumele și numele.** Degas rămâne Degas, nu
„Degazează”. Corneille rămâne Corneille. Le Corbusier rămâne
Le Corbusier.

**Forma românească stabilită**, când există:
`Christophe Colomb` → `Cristofor Columb`, `Guillaume le Conquérant` →
`Wilhelm Cuceritorul`, `Londres` → `Londra`, `Pékin` → `Pekin`,
`Aix-la-Chapelle` → `Aachen`, `Charlemagne` → `Carol cel Mare`,
`Tchernobyl` → `Cernobîl`, `Michel-Ange` → `Michelangelo`.

**Titlurile de opere poartă titlul publicat în română**, nu o calcă:

| Franceză | Română |
| --- | --- |
| *Impression, soleil levant* | *Impresie, răsărit de soare* |
| *La Ferme des animaux* | *Ferma animalelor* |
| *Le Rouge et le Noir* | *Roșu și Negru* |
| *À la recherche du temps perdu* | *În căutarea timpului pierdut* |
| *Le Déjeuner sur l'herbe* | *Dejunul pe iarbă* |
| *Les Demoiselles d'Avignon* | *Domnișoarele din Avignon* |
| *Les Fleurs du Mal* | *Florile răului* |
| *Les Misérables* | *Mizerabilii* |
| *Le Petit Prince* | *Micul Prinț* |
| *L'Étranger* | *Străinul* |
| *Le Mythe de Sisyphe* | *Mitul lui Sisif* |
| *Le Père Goriot* | *Moș Goriot* |

Dacă nu există un titlu românesc stabilit, lași originalul și lămurești
la prima apariție.

**Personajele literaturii traduse poartă numele din ediția românească
standard:**

| Operă | Franceză | Română |
| --- | --- | --- |
| *Ferma animalelor* | Malabar | Boxer |
| *Ferma animalelor* | Brille-Babil | Pârâciosul |
| *Ferma animalelor* | Boule de neige | Bile de zăpadă |
| *Ferma animalelor* | Vieux Major | Bătrânul Maior |
| *Micul Prinț* | Bésixdouze | asteroidul B-612 |
| *1984* | novlangue | Noua vorbire |
| *1984* | doublepensée | gândire dublă |

Registrul e în `scripts/proper_nouns.json`. Adaugă acolo, nu repara
același nume de două ori.

## 6. Citatele

Citatul nu e un exercițiu de traducere. Dacă există o formulare
românească canonică, o folosești. Altfel traduci scurt și limpede.

- Ghilimele românești `„ ”`. Fără francezele `« »`.
- Punctul frazei citate stă înăuntrul ghilimelei de închidere:
  `„Toate animalele sunt egale.”`
- `quote.attribution` e `Autor, Operă`. Dacă franceza dă vorbitorul
  după liniuță, virgulă sau în paranteză:
  `Victor Hugo, Mizerabilii (episcopul Bienvenu)`.

## 7. Punctuație și tipografie

Control mecanic, fără excepții.

- **Nicio pauză `—`, nicio semipauză `–`.** Rescrii cu virgulă,
  două puncte, paranteză sau punct. Intervalele de numere cu cratimă:
  `1945-1975`.
- Fără `« »`, fără semne de lățime zero, fără spațiu neseparabil.
- Apostroful e drept `'` (U+0027), ca în fișierele franceze.
  Nu `’`.
- Niciodată spațiu înainte de `, . ; : ! ?`. Niciodată două spații
  la rând.
- Spațiu după două puncte și după punct și virgulă; pe amândouă le
  folosești rar: proza didactică românească preferă punctul.
- Fără resturi de franceză. `siècle`, `dans`, `l'`, `d'un` într-un
  paragraf românesc e greșeală, la fel un toponim francez netradus.

## 8. Numere, date, unități

- Mii: punct. `30 000` → `30.000`. Nici spațiu, nici virgulă.
  (Convenție de casă, ca validatorul să prindă spațiul francez.)
- Zecimale: virgulă. `3,5 %` → `3,5%`. Fără spațiu înainte de `%`.
- Secolele romane după cuvânt: `XVe siècle` → `secolul XV` /
  `în secolul XV`. Niciodată `XVe` singur, niciodată `secolul 15`.
- Ere: `î.Hr.` și `d.Hr.`: `450 î.Hr.`, `622 d.Hr.`.
- Date: `24 februarie 2022`. Un singur schelet pe curs.
- Fără conversii. Metricele rămân metrice.
- `Mds`/`Md` → `miliarde`. `M` → `milioane`, în cuvinte.

## 9. Control

```bash
python scripts/check_course_translation.py --lang ro
python scripts/check_course_translation.py --lang ro course_102_*
```

Validatorul semnalează pe curs: derivă de structură, mărci decalate,
numărul de termeni, chei neînregistrate, termeni parcați la capătul
paragrafului, articol dublu, semne interzise, spații, resturi franceze
și numere nelocalizate. Trecerea curată e o obligație, nu o sugestie.
