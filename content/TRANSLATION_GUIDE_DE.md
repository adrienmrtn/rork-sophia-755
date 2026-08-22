# Kursübersetzung — Französisch nach Deutsch

Französisch (`content/courses/fr/`) ist die Quelle. Dieses Dokument ist die
Spezifikation für `content/courses/de/`. Es geht unverändert an jeden, der
eine Übersetzung schreibt, und `scripts/check_course_translation.py --lang de`
prüft es mechanisch.

Dieselben Regeln gelten für die anderen Sprachen; nur Zahlen, Anführungszeichen
und Eigennamen ändern sich.

## 1. Was wir wollen

Wir liefern keine Übersetzung. Wir liefern die **deutsche Ausgabe** des
Kurses: den Text, den ein muttersprachlicher Redakteur aus denselben Notizen
geschrieben hätte. Der Leser darf nicht merken, dass der Ursprung Französisch
war.

Der Reihe nach:

1. **Richtig.** Keine Fakten verdrehen, erfinden oder weglassen.
2. **Flüssig.** Idiomatisches Deutsch. Laut vorlesen ohne Stolpern.
3. **Einfach.** Kurze Sätze. Gewöhnliche Wörter. Ein neugieriger Teenager
   muss mithalten. Lieber "zeigte" als "demonstrierte", "nutzte" als
   "verwendete".
4. **Formtreu.** Ungefähr dieselbe Satzzahl, dieselbe Reihenfolge der
   Gedanken, dieselbe Länge mit 20 Prozent Spiel, damit das Layout hält.

Register: **standarddeutsches Schriftdeutsch**, keine Dialekte, kein
Schweizer "ss"-Zwang gegen ß, keine überlangen Schachtelsätze. Orthographie
nach Duden: ß bleibt ß, "das" und "dass" unterscheiden.

Sätze frei umbauen. Französisch reiht lange Sätze mit Semikolon und erzählt
im Präsens; deutsches Sachbuch präferiert das Präteritum für Geschichte,
außer das Französische setzt das Präsens bewusst, kurz, als Effekt.

## 2. Die Struktur bleibt stehen

Nur Textfelder werden übersetzt. Alles andere kopiert das Werkzeug aus dem
französischen Gerüst und bleibt unangetastet: `id`, `subject`, `subcategory`,
`type`, `asset`, `image`, `ratio`, `free`.

| Feld | Was es ist | Hinweis |
| --- | --- | --- |
| `title` | Titel auf Karte und Hero | Kurz. Kanonischer deutscher Werktitel, wenn der Kurs von einem Werk handelt. |
| `subtitle` | Zeile unter dem Titel | Ein Jahr oder Intervall (`1945`, `1945-1975`) unverändert. |
| `description` | Zwei-Satz-Blurb | Muss allein stehen. |
| `hero.hook` | Ein Satz Köder | Werbung, keine Prosa. |
| `sections[].title` | Abschnittsüberschrift | Nominalphrase, kein Schlusspunkt. |
| `paragraph.text` | Fließtext | Die Hauptarbeit. |
| `image.caption` | Bildunterschrift | Eine Klausel, Punkt nur bei vollem Satz. |
| `funFact.text` | Kasten | Leicht, gesprächig. |
| `takeaway.text` | Schluss | Was hängen bleibt. |
| `quote.text` | Zitat | Siehe §6. |
| `quote.attribution` | Wer es sagte | Siehe §6. |
| `timeline.events[].date` | `1789`, `Juni 1940`, `um 450 v. Chr.` | Zahlen bleiben. Monate übersetzen. `v. Chr.` / `n. Chr.`, nie `av. J.-C.`. |
| `timeline.events[].title` | Etikett | Sehr kurz, kein Punkt. |
| `timeline.events[].detail` | Ein Satz | |

## 3. Inline-Markup

Drei Marken müssen überleben:

- `**fett**` — Daten, Zahlen, Namen der Personen und Werke, um die es geht.
- `*kursiv*` — Werktitel in der Prosa.
- `[[Begriff]]` — Glossareintrag. Antippen öffnet die Definition.

Regeln:

- Marken sind paarig. Eine ungerade Zahl `**` ist ein Fehler.
- Keine Marke umschließt Leerraum oder Satzzeichen: `**1945**,` ist richtig,
  `**1945,**` und `** 1945 **` sind falsch.
- Fett markiert das deutsche Äquivalent, nicht dieselben Zeichen.
  Französisch `**30 000 mots**` wird `**30.000 Wörter**`.
- Kein Fett, das im Französischen fehlt. Keinen ganzen Satz fett setzen.

## 4. Glossarbegriffe — die wichtigste Regel

Jedes französische `[[...]]` wird genau ein deutsches `[[...]]`, **im Satz,
an derselben Stelle des Arguments**.

Nie einen Begriff ans Ende des Absatzes stellen. Nie die Lücke offen
lassen. Das ist derselbe Fehler:

> Falsch: `geschwächt vor allem durch : christliche Kreuzfahrer plünderten die Stadt. [[Die Plünderung Konstantinopels]]`
>
> Richtig: `geschwächt vor allem durch [[die Plünderung Konstantinopels während des Vierten Kreuzzugs (1204)]], als westliche Kreuzfahrer die Stadt plünderten.`

Der Termtext ist nicht frei. Er muss ein für diesen Kurs in
`ios/Sophia/Resources/Locales/glossary.de.json` hinterlegter Schlüssel sein.
Ein unbekannter Schlüssel erscheint als toter Fließtext. Das Brief von
`scripts/make_translation_briefs.py` listet die erlaubten Schlüssel;
einen davon Zeichen für Zeichen verwenden, inklusive Großschreibung.

Der Satz muss **mit eingesetztem Term** grammatisch sein:

- Der Schlüssel trägt oft schon den Artikel: `[[Die Umma]]`, `[[Die
  Allegorie der Russischen Revolution]]`. Dann `Er gründete [[Die Umma]]`,
  nie `Er gründete die [[Die Umma]]`.
- Fehlt der Artikel, steht er außerhalb: `ein [[abolitionistisches]]
  Zeichen`, `eine [[Oread]]`. Kasus und Genus müssen zum Schlüssel passen.
- Nie `der` vor einem Eigennamen, der keinen Artikel nimmt, wenn der
  Schlüssel ihn nicht trägt. `im [[Zweiten Weltkrieg]]` oder `während
  [[des Zweiten Weltkriegs]]`, je nach Schlüssel.
- Nicht über die Klammer flektieren: `[[Proletariat]]s` ist falsch.
  Umschreiben.
- Passt der Schlüssel nicht, den Satz umbauen. Den Schlüssel nicht ändern.

## 5. Eigennamen

Maschinelle Übersetzung liest Namen als Gattungswörter. Harte Regeln:

**Nie einen Personennamen übersetzen.** Degas bleibt Degas, nicht
"Entgasen". Corneille bleibt Corneille, nicht "Krähe". Le Corbusier bleibt
Le Corbusier.

**Die etablierte deutsche Form**, wo es eine gibt:
`Christophe Colomb` → `Christoph Kolumbus`, `Guillaume le Conquérant` →
`Wilhelm der Eroberer`, `Londres` → `London`, `Pékin` → `Peking`,
`Aix-la-Chapelle` → `Aachen`.

**Werktitel tragen den veröffentlichten deutschen Titel**, keinen wörtlichen
Kalk:

| Französisch | Deutsch |
| --- | --- |
| *Impression, soleil levant* | *Impression, Sonnenaufgang* |
| *La Ferme des animaux* | *Farm der Tiere* |
| *Le Rouge et le Noir* | *Rot und Schwarz* |
| *À la recherche du temps perdu* | *Auf der Suche nach der verlorenen Zeit* |
| *Le Déjeuner sur l'herbe* | *Das Frühstück im Grünen* |
| *Les Demoiselles d'Avignon* | *Les Demoiselles d'Avignon* (bleibt) |
| *Les Fleurs du Mal* | *Die Blumen des Bösen* |
| *Les Misérables* | *Die Elenden* |
| *Le Petit Prince* | *Der kleine Prinz* |

Gibt es keinen festen deutschen Titel, Original behalten und beim ersten
Mal in Klammern glosieren.

**Figuren der übersetzten Literatur tragen den Namen der deutschen
Standardausgabe**:

| Werk | Französisch | Deutsch |
| --- | --- | --- |
| *Farm der Tiere* | Malabar | Boxer |
| *Farm der Tiere* | Brille-Babil | Schwatzwutz |
| *Farm der Tiere* | Boule de neige | Schneeball |
| *Farm der Tiere* | Vieux Major | der alte Major |
| *Der kleine Prinz* | Bésixdouze | Asteroid B-612 |
| *1984* | novlangue | Neusprech |
| *1984* | doublepensée | Doppeldenk |

Das Register liegt in `scripts/proper_nouns.json`. Dort ergänzen, nicht
denselben Namen zweimal flicken.

## 6. Zitate

Ein Zitat ist keine Übersetzungsübung. Gibt es einen kanonischen deutschen
Wortlaut, den nehmen. Sonst knapp und klar übersetzen.

- Geschwungene Anführungszeichen `“ ”`. Keine französischen Guillemets `« »`.
- Satzschlusszeichen stehen in der schließenden Anführung:
  `“Alle Tiere sind gleich.”`
- `quote.attribution` ist `Autor, Werk`. Steht im Französischen ein Sprecher
  hinter einem Gedankenstrich, Komma oder Klammer:
  `Victor Hugo, Die Elenden (Monseigneur Bienvenu)`.

## 7. Zeichensetzung und Typografie

Mechanisch geprüft, keine Ausnahme.

- **Kein Geviertstrich `—`, kein Halbgeviert `–`.** Umschreiben mit Komma,
  Doppelpunkt, Klammer oder Punkt. Zahlenintervalle mit Bindestrich:
  `1945-1975`.
- Keine Guillemets `« »`, keine Nullbreitenzeichen, keine geschützten
  Leerzeichen.
- Apostroph ist das gerade `'` (U+0027), wie in den französischen Dateien.
  Nicht `’`.
- Nie ein Leerzeichen vor `, . ; : ! ?`. Nie zwei Leerzeichen hintereinander.
- Ein Leerzeichen nach Doppelpunkt oder Semikolon, und beides sparsam: das
  Deutsche der Sachprosa bevorzugt den Punkt.
- Kein französisches Restwort. `siècle`, `dans`, `qui`, `l'`, `d'un` in
  einem deutschen Absatz sind ein Fehler, ebenso ein unübersetzter
  französischer Ortsname in einem sonst deutschen Satz.

## 8. Zahlen, Daten, Einheiten

- Tausender: Punkt. `30 000` → `30.000`. Nie Leerzeichen, nie Komma.
- Dezimal: Komma. `3,5 %` → `3,5%`. Kein Leerzeichen vor `%`.
- Jahrhunderte arabisch mit Punkt: `XVe siècle` → `15. Jahrhundert`.
- Epochen: `v. Chr.` und `n. Chr.`: `450 v. Chr.`, `622 n. Chr.`.
- Daten: `24. Februar 2022`. Ein Schema pro Kurs.
- Nichts umrechnen. Metrisch bleibt metrisch.
- `Mds`/`Md` → `Milliarden`. `M` → `Millionen`, ausgeschrieben.

## 9. Prüfung

```bash
python scripts/check_course_translation.py --lang de
python scripts/check_course_translation.py --lang de course_102_*
```

Meldet pro Kurs: Strukturdrift, unpaarige Marken, Glossarzählung,
unregistrierte Schlüssel, ans Ende geschobene Begriffe, doppelte Artikel,
verbotene Zeichen, Abstände, französische Reste und unlokalisierte Zahlen.
Ein sauberer Lauf ist Pflicht, kein Vorschlag.
