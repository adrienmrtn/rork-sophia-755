# Kurzuskfordítás — franciából magyarra

A francia (`content/courses/fr/`) a forrás. Ez a dokumentum a
`content/courses/hu/` specifikációja. Teljes egészében eljut ahhoz,
aki a fordítást írja, és a
`scripts/check_course_translation.py --lang hu` mechanikusan
alkalmazza a szabályokat.

Ugyanezek a szabályok érvényesek a többi nyelvre; csak a számok,
az idézőjelek és a tulajdonnevek változnak.

## 1. Mit akarunk

Nem fordítást adunk le. A kurzus **magyar kiadását** adjuk le:
azt a szöveget, amit egy anyanyelvi szerkesztő ugyanabból a
jegyzetből írna. Az olvasó ne vegye észre, hogy az eredeti francia.

Ebben a sorrendben:

1. **Helyes.** Ne csavard, ne találj ki és ne hagyj ki tényeket.
2. **Folyékony.** Idiomatikus magyar. Hangosan is botlás nélkül
   olvasható.
3. **Egyszerű.** Rövid mondatok. Hétköznapi szavak. Egy kíváncsi
   tizenéves kövesse. Inkább „megmutatta”, mint „demonstrálta”,
   „használta”, mint „kiemelten hasznosította”.
4. **Hű a formához.** Nagyjából ugyanannyi mondat, ugyanaz a
   gondolatmenet, ugyanaz a hossz húsz százalék játékkal, hogy
   a tördelés megmaradjon.

Regiszter: **köznyelvi magyar**. Nincs tájszólás, nincs hivatali
zsargon, nincs háromszintes mellékmondat. Tegező **te**, nem
*ön* mint egy esszében. Mai helyesírás; az aposztróf egyenes `'`
(soha `’`).

A mondatokat szabadon építed újra. A francia hosszú periódusokat
fűz pontosvesszővel, és jelen időben mesél; a magyar ifjúsági
szakszöveg a **múlt időt** szereti a történeti elbeszélésben,
hacsak a francia szándékosan, röviden, hatásként nem használ
jelent.

## 2. A váz megmarad

Csak a szövegmezők fordulnak. A többit az eszköz másolja a
francia vázból, és nem nyúlsz hozzá: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Mező | Mi az | Megjegyzés |
| --- | --- | --- |
| `title` | Cím a kártyán és a heróban | Rövid. A Magyarországon kiadott cím, ha a kurzus műről szól. |
| `subtitle` | Sor a cím alatt | Év vagy intervallum (`1945`, `1945-1975`) marad. |
| `description` | Kétmondatos blurb | Magában is áll. |
| `hero.hook` | Egy mondat csali | Reklám, nem próza. |
| `sections[].title` | Szakaszcím | Névszói szerkezet, a végén nincs pont. |
| `paragraph.text` | Folyószöveg | A fő munka. |
| `image.caption` | Képaláírás | Rövid mondat; pont csak teljes mondatnál. |
| `funFact.text` | Keret | Könnyű, beszélt. |
| `takeaway.text` | Zárás | Ami megmaradjon. |
| `quote.text` | Idézet | L. §6. |
| `quote.attribution` | Ki mondta | L. §6. |
| `timeline.events[].date` | `1789`, `1940. június`, `kb. i. e. 450` | A számok maradnak. A hónapokat fordítod. `i. e.` / `i. sz.`, soha `av. J.-C.`. |
| `timeline.events[].title` | Címke | Nagyon rövid, nincs pont. |
| `timeline.events[].detail` | Egy mondat | |

## 3. Jelölések a sorban

Három jelnek túl kell élnie:

- `**félkövér**` — dátumok, számok, nevek és azok a műcímek,
  amelyekről a bekezdés szól.
- `*dőlt*` — műcím a prózában.
- `[[szó]]` — szójegyzék-tétel. Koppintásra kinyílik a definíció.

Szabályok:

- A jelek párban járnak. Páratlan számú `**` hiba.
- Semmilyen jel nem nyel szóközt vagy írásjelet: `**1945**,`
  helyes, `**1945,**` és `** 1945 **` hibás.
- A félkövér a magyar megfelelőt jelöli, nem ugyanazokat a
  karaktereket. A francia `**30 000 mots**` `**30.000 szó**`
  lesz.
- Ne tegyél félkövért oda, ahol a franciában nincs. Ne tedd
  félkövérré az egész mondatot.

## 4. Szójegyzék-tételek — a legfontosabb szabály

Minden francia `[[...]]` pontosan egy magyar `[[...]]` lesz,
**a mondatban, az érvelés ugyanazon pontján**.

Soha ne parkoltasd a tételt a bekezdés végére. Ne hagyj lyukat.
Ez ugyanaz a hiba:

> Rossz: `főként ez gyengítette : keresztény keresztesek
> fosztották ki a várost. [[Konstantinápoly elfoglalása]]`

> Jó: `főként [[Konstantinápoly 1204-es, a negyedik
> keresztes hadjárat alatti elfoglalása]] gyengítette, amikor
> nyugati keresztesek fosztották ki a várost.`

A tétel szövege nem szabad. Ennek a kurzusnak a
`ios/Sophia/Resources/Locales/glossary.hu.json` fájlban
regisztrált kulcsának kell lennie. Ismeretlen kulcs holt
szövegként jön ki. A `scripts/make_translation_briefs.py`
briefje felsorolja a megengedett kulcsokat; használj egyet,
karakterre pontosan, a regiszter nagybetűivel.

Az átépítésnek **a tétellel bent** grammatikusnak kell maradnia:

- Ne tegyél `a` / `az` / `egy` szót olyan kulcs elé, amely már
  így kezdődik (`Az orosz forradalom allegóriája`).
- A kulcs alanyesetű. Semmit se ragassz a `]]` után:
  `[[proletariátus]]t` hibás. Építsd újra
  (`a kizsákmányolt [[proletariátus]]`).
- Ha a kulcs nem ül, a mondatot építed újra. A kulcsot nem
  változtatod.
- `a [[Második világháború]] alatt` ülhet, de
  `a [[Második világháború]]nak` ferde. Jobb:
  `amikor a **[[Második világháború]]** dúlt`.
- `Alarik I,` csonka névelőnek tűnik. Írd: `I. Alarik`.

## 5. Tulajdonnevek

A gépi fordítás a családneveket köznévnek olvassa. Kemény
szabályok:

**Soha ne fordíts kereszt- és családnevet.** A Degas Degas
marad, nem „Gáztalanítás”. A Corneille Corneille. A Le
Corbusier Le Corbusier.

**Bevett magyar alak**, ha van:
`Christophe Colomb` → `Kolumbusz Kristóf`, `Guillaume le Conquérant`
→ `Hódító Vilmos`, `Londres` → `London`, `Pékin` → `Peking`,
`Aix-la-Chapelle` → `Aachen`, `Charlemagne` → `Nagy Károly`,
`Tchernobyl` → `Csernobil`, `Michel-Ange` → `Michelangelo`.

**A műcímek a Magyarországon kiadott címet viselik**, nem
tükörfordítást:

| Francia | Magyar |
| --- | --- |
| *Impression, soleil levant* | *Impresszió, felkelő nap* |
| *La Ferme des animaux* | *Állatfarm* |
| *Le Rouge et le Noir* | *Vörös és fekete* |
| *À la recherche du temps perdu* | *Az eltűnt idő nyomában* |
| *Le Déjeuner sur l'herbe* | *Reggeli a szabadban* |
| *Les Demoiselles d'Avignon* | *Avignoni kisasszonyok* |
| *Les Fleurs du Mal* | *A romlás virágai* |
| *Les Misérables* | *A nyomorultak* |
| *Le Petit Prince* | *A kis herceg* |
| *L'Étranger* | *Közöny* |
| *Le Mythe de Sisyphe* | *Sziszüphosz mítosza* |
| *Le Père Goriot* | *Goriot apó* |

Ha nincs bevett magyar cím, az eredetit hagyod, és az első
előfordulásnál megmagyarázod.

**A fordított irodalom szereplői a bevett magyar kiadás nevét
viselik:**

| Mű | Francia | Magyar |
| --- | --- | --- |
| *Állatfarm* | Malabar | Bandi |
| *Állatfarm* | Brille-Babil | Süvi |
| *Állatfarm* | Boule de neige | Hógolyó |
| *Állatfarm* | Vieux Major | öreg Őrnagy |
| *A kis herceg* | Bésixdouze | B-612-es aszteroida |
| *1984* | novlangue | Újbeszéd |
| *1984* | doublepensée | kettősgondol |

A regiszter a `scripts/proper_nouns.json` fájlban van. Oda
teszed, ne javítsd kétszer ugyanazt a nevet.

## 6. Idézetek

Az idézet nem fordítási gyakorlat. Ha van kanonikus magyar
megfogalmazás, azt használod. Különben röviden és tisztán
fordítasz.

- Idézőjelek `„ ”`. Nincs francia `« »`.
- Az idézett mondat pontja a zárójelen belül van:
  `„Minden állat egyenlő.”`
- A `quote.attribution` `Szerző, Mű`. Ha a francia a beszélőt
  gondolatjel, vessző vagy zárójel után adja:
  `Victor Hugo, A nyomorultak (Bienvenu püspök)`.

## 7. Központozás és tipográfia

Mechanikus ellenőrzés, kivétel nélkül.

- **Nincs gondolatjel `—`, nincs félkvirt `–`.** Írd át
  vesszővel, kettősponttal, zárójellel vagy ponttal. Számsorok
  kötőjellel: `1945-1975`.
- Nincs `« »`, nincs nulla szélességű jel, nincs nemtörő szóköz.
- Az aposztróf egyenes `'` (U+0027), mint a francia fájlokban.
  Nem `’`.
- Soha szóköz a `, . ; : ! ?` előtt. Soha két szóköz egymás után.
- Szóköz a kettőspont és a pontosvessző után; mindkettőt ritkán
  használd: a magyar szakszöveg a pontot szereti.
- Nincs francia maradék. A `siècle`, a `dans` elöljáróként, az
  `l'`, a `d'un` magyar bekezdésben hiba, mint a lefordítatlan
  francia helynév.

## 8. Számok, dátumok, mértékegységek

- Ezresek: pont. `30 000` → `30.000`. Nincs szóköz, nincs
  vessző. (Házi konvenció, hogy az ellenőrző elkapja a francia
  szóközt.)
- Tizedesek: vessző. `3,5 %` → `3,5%`. Nincs szóköz a `%` előtt.
- Századok: `XVe siècle` → `15. század` / `a 15. században`.
  Soha `XVe` magában.
- Időszámítás: `i. e.` és `i. sz.`: `i. e. 450`, `i. sz. 622`.
- Dátum: `2022. február 24.`. Egy séma kurzusonként.
- Nincs átváltás. A metrikus metrikus marad.
- `Mds`/`Md` → `milliárd`. `M` → `millió`, szavakkal.

## 9. Ellenőrzés

```bash
python scripts/check_course_translation.py --lang hu
python scripts/check_course_translation.py --lang hu course_102_*
```

Az ellenőrző kurzusonként jelenti: struktúraelcsúszás, ferde
jelek, tételszám, nem regisztrált kulcsok, a bekezdés végére
parkoltatott tételek, kettős névelő, tiltott karakterek,
szóközök, francia maradékok és lokalizálatlan számok.
A tiszta futás kötelezettség, nem javaslat.
