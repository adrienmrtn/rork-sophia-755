# Przekład kursów — z francuskiego na polski

Francuski (`content/courses/fr/`) jest źródłem. Ten dokument to
specyfikacja `content/courses/pl/`. Trafia w całości do osoby, która
pisze przekład, a `scripts/check_course_translation.py --lang pl`
stosuje reguły mechanicznie.

Te same reguły obowiązują w innych językach; zmieniają się tylko liczby,
cudzysłowy i nazwy własne.

## 1. Czego chcemy

Nie oddajemy tłumaczenia. Oddajemy **polską edycję** kursu: tekst, który
napisałby z tych samych notatek native editor. Czytelnik nie ma poznać,
że oryginał był francuski.

W tej kolejności:

1. **Poprawnie.** Bez przekręcania, zmyślania i pomijania faktów.
2. **Płynnie.** Idiomatyczna polszczyzna. Czyta się na głos bez potknięcia.
3. **Prosto.** Krótkie zdania. Potoczne słowa. Ciekawy nastolatek ma
   nadążyć. Lepiej „pokazał” niż „unaocznił”, „użył” niż „zastosował”.
4. **Wiernie formie.** Prawie ta sama liczba zdań, ta sama kolejność
   myśli, ta sama długość z dwudziestoprocentowym luzem, żeby układ
   się utrzymał.

Rejestr: **polszczyzna ogólna**. Bez gwary, bez urzędniczego żargonu,
bez zdań z wielopiętrowym wtrąceniem. Zwrot **ty**, nie *Pan/Pani*
z eseju. Współczesna pisownia: ą, ę, ó, ś, ź, ć, ń, ł na miejscu;
apostrof prosty `'` (nigdy `’`).

Zdania przebudowujesz swobodnie. Francuski spina długie okresy
średnikiem i opowiada historię czasem teraźniejszym; polski tekst
dydaktyczny woli **czas przeszły** do narracji historycznej, chyba że
francuski używa teraźniejszości celowo, krótko, jako efekt.

## 2. Szkielet zostaje

Tłumaczy się tylko pola tekstowe. Resztę narzędzie kopiuje z francuskiego
szkieletu i nie rusza: `id`, `subject`, `subcategory`, `type`, `asset`,
`image`, `ratio`, `free`.

| Pole | Co to jest | Uwaga |
| --- | --- | --- |
| `title` | Tytuł na karcie i w hero | Krótki. Kanoniczny tytuł wydany w Polsce, jeśli kurs jest o dziele. |
| `subtitle` | Wiersz pod tytułem | Rok lub zakres (`1945`, `1945-1975`) zostaje. |
| `description` | Dwuzdaniowy blurb | Ma stać sam. |
| `hero.hook` | Jedno zdanie-zanęta | Reklama, nie proza. |
| `sections[].title` | Tytuł sekcji | Fraza rzeczownikowa, bez kropki na końcu. |
| `paragraph.text` | Ciągły tekst | Główna robota. |
| `image.caption` | Podpis | Jedno zdanie skrótowe; kropka tylko gdy to pełne zdanie. |
| `funFact.text` | Boksyk | Lekki, potoczny. |
| `takeaway.text` | Zakończenie | To, co ma zostać. |
| `quote.text` | Cytat | Zob. §6. |
| `quote.attribution` | Kto powiedział | Zob. §6. |
| `timeline.events[].date` | `1789`, `czerwiec 1940`, `ok. 450 p.n.e.` | Cyfry zostają. Miesiące się tłumaczy. `p.n.e.` / `n.e.`, nigdy `av. J.-C.`. |
| `timeline.events[].title` | Etykieta | Bardzo krótka, bez kropki. |
| `timeline.events[].detail` | Jedno zdanie | |

## 3. Znaczniki w linii

Trzy marki muszą przeżyć:

- `**pogrubienie**` — daty, liczby, nazwiska i tytuła dzieł, o których
  mówi akapit.
- `*kursywa*` — tytuł dzieła w prozie.
- `[[termin]]` — hasło słownika. Dotknięcie otwiera definicję.

Reguły:

- Marki chodzą parami. Nieparzysta liczba `**` to błąd.
- Żadna marka nie łyka spacji ani interpunkcji: `**1945**,` jest dobre,
  `**1945,**` i `** 1945 **` są złe.
- Pogrubienie znaczy polski odpowiednik, nie te same znaki.
  Francuskie `**30 000 mots**` staje się `**30.000 słów**`.
- Nie dodawaj pogrubienia, którego nie ma w francuskim. Nie pogrubiaj
  całego zdania.

## 4. Terminy słownikowe — najważniejsza reguła

Każde francuskie `[[...]]` staje się dokładnie jednym polskim `[[...]]`,
**w zdaniu, w tym samym miejscu argumentu**.

Nigdy nie parkuj terminu na końcu akapitu. Nigdy nie zostawiaj dziury.
To ten sam błąd:

> Źle: `osłabione przede wszystkim przez : chrześcijańscy krzyżowcy
> złupili miasto. [[Zdobycie Konstantynopola]]`
>
> Dobrze: `osłabione przede wszystkim przez [[zdobycie Konstantynopola
> podczas IV krucjaty (1204)]], gdy zachodni krzyżowcy złupili miasto.`

Tekst terminu nie jest dowolny. Musi być kluczem zarejestrowanym dla
tego kursu w `ios/Sophia/Resources/Locales/glossary.pl.json`.
Nieznany klucz wychodzi jako martwy tekst. Brief z
`scripts/make_translation_briefs.py` wylicza dozwolone klucze; użyj
jednego znak w znak, z wielkimi literami.

Zdanie ma zostać gramatyczne **z wstawionym terminem**:

- W polskim nie ma rodzajników. Nie stawiaj `ten` / `ta` / `to` przed
  kluczem, który już tak zaczyna.
- Klucz jest w mianowniku. Nie odmieniaj za `]]`: `[[proletariat]]u`
  jest złe. Przebuduj zdanie (`wyzyskiwany [[proletariat]]`).
- Jeśli klucz nie siada, przebuduj zdanie. Klucza nie zmieniaj.
- `podczas [[Druga wojna światowa]]` jest złe (brak przypadka). Lepiej:
  `gdy trwała **[[Druga wojna światowa]]**` albo `w czasie
  **[[Druga wojna światowa]]**`.

## 5. Nazwy własne

Tłumaczenie maszynowe czyta nazwiska jak rzeczowniki pospolite. Twarde
reguły:

**Nigdy nie tłumacz imienia i nazwiska.** Degas zostaje Degas, nie
„Odgazowywać”. Corneille zostaje Corneille. Le Corbusier zostaje
Le Corbusier.

**Ustabilizowana polska forma**, gdy istnieje:
`Christophe Colomb` → `Krzysztof Kolumb`, `Guillaume le Conquérant` →
`Wilhelm Zdobywca`, `Londres` → `Londyn`, `Pékin` → `Pekin`,
`Aix-la-Chapelle` → `Akwizgran`, `Charlemagne` → `Karol Wielki`,
`Tchernobyl` → `Czarnobyl`, `Michel-Ange` → `Michał Anioł`.

**Tytuły dzieł noszą tytuł wydany w Polsce**, nie kalkę:

| Francuski | Polski |
| --- | --- |
| *Impression, soleil levant* | *Impresja, wschód słońca* |
| *La Ferme des animaux* | *Folwark zwierzęcy* |
| *Le Rouge et le Noir* | *Czerwone i czarne* |
| *À la recherche du temps perdu* | *W poszukiwaniu straconego czasu* |
| *Le Déjeuner sur l'herbe* | *Śniadanie na trawie* |
| *Les Demoiselles d'Avignon* | *Panny z Awinionu* |
| *Les Fleurs du Mal* | *Kwiaty zła* |
| *Les Misérables* | *Nędznicy* |
| *Le Petit Prince* | *Mały Książę* |
| *L'Étranger* | *Obcy* |
| *Le Mythe de Sisyphe* | *Mit Syzyfa* |
| *Le Père Goriot* | *Ojciec Goriot* |

Jeśli nie ma ustalonego polskiego tytułu, zostaw oryginał i objaśnij
przy pierwszym pojawieniu.

**Bohaterowie przekładanej literatury noszą imię ze standardowego
wydania polskiego:**

| Dzieło | Francuski | Polski |
| --- | --- | --- |
| *Folwark zwierzęcy* | Malabar | Bokser |
| *Folwark zwierzęcy* | Brille-Babil | Pisalski |
| *Folwark zwierzęcy* | Boule de neige | Snowball |
| *Folwark zwierzęcy* | Vieux Major | Stary Major |
| *Mały Książę* | Bésixdouze | asteroida B-612 |
| *1984* | novlangue | nowomowa |
| *1984* | doublepensée | dwójmyślenie |

Rejestr jest w `scripts/proper_nouns.json`. Dopisz tam, nie naprawiaj
tego samego imienia dwa razy.

## 6. Cytaty

Cytat to nie ćwiczenie translatorskie. Jeśli istnieje kanoniczne
polskie sformułowanie, użyj go. W przeciwnym razie tłumacz krótko
i jasno.

- Cudzysłowy polskie `„ ”`. Bez francuskich `« »`.
- Kropka cytowanego zdania stoi wewnątrz zamykającego cudzysłowu:
  `„Wszystkie zwierzęta są równe.”`
- `quote.attribution` to `Autor, Dzieło`. Jeśli francuski podaje
  mówcę po myślniku, przecinku lub w nawiasie:
  `Victor Hugo, Nędznicy (biskup Bienvenu)`.

## 7. Interpunkcja i typografia

Kontrola mechaniczna, bez wyjątków.

- **Żadnej pauzy `—`, żadnej półpauzy `–`.** Przepisz przecinkiem,
  dwukropkiem, nawiasem albo kropką. Zakresy liczb z dywizem:
  `1945-1975`.
- Żadnych `« »`, żadnych znaków zerowej szerokości, żadnej twardej
  spacji.
- Apostrof jest prosty `'` (U+0027), jak we francuskich plikach.
  Nie `’`.
- Nigdy spacji przed `, . ; : ! ?`. Nigdy dwóch spacji pod rząd.
- Spacja po dwukropku i średniku; obu używaj oszczędnie: polska proza
  dydaktyczna woli kropkę.
- Żadnych resztek francuskiego. `siècle`, `dans`, `l'`, `d'un` w polskim
  akapicie to błąd, podobnie nieprzetłumaczony francuski toponim.

## 8. Liczby, daty, jednostki

- Tysiące: kropka. `30 000` → `30.000`. Ani spacja, ani przecinek.
  (To konwencja domu, żeby checker łapał francuską spację.)
- Dziesiętne: przecinek. `3,5 %` → `3,5%`. Bez spacji przed `%`.
- Wieki rzymskie po słowie albo z przyimkiem: `XVe siècle` →
  `XV wiek` / `w XV wieku`. Nigdy `XVe` samo, nigdy `15. wiek`.
- Ery: `p.n.e.` i `n.e.`: `450 p.n.e.`, `622 n.e.`.
- Daty: `24 lutego 2022`. Jeden schemat na kurs.
- Bez przeliczeń. Metryczne zostaje metryczne.
- `Mds`/`Md` → `miliardy`. `M` → `miliony`, słownie.

## 9. Kontrola

```bash
python scripts/check_course_translation.py --lang pl
python scripts/check_course_translation.py --lang pl course_102_*
```

Walidator zgłasza na kurs: dryf struktury, rozjechane marki, liczbę
haseł, niezarejestrowane klucze, terminy zaparkowane na końcu akapitu,
podwójny zaimek wskazujący, zakazane znaki, odstępy, resztki francuskie
i nielokalne liczby. Czyste przejście jest obowiązkiem, nie sugestią.
