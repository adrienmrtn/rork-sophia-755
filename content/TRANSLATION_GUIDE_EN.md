# Course translation guide — French to English

French (`content/courses/fr/`) is the source of truth. This document is the
specification for producing `content/courses/en/`. It is written to be handed
verbatim to whoever (human or model) writes a translation, and it is what
`scripts/check_course_translation.py` enforces mechanically.

The same rules generalise to the other 13 languages; only the language-specific
sections (numbers, quotation marks, proper-noun tables) change.

## 1. What we are aiming for

We are not producing a translation. We are producing the English edition of the
course: the text a native English editor would have written from the same
research notes. A reader must never be able to tell the course was written in
French first.

Concretely, in order of priority:

1. **Correct.** No factual drift, no invented facts, no dropped facts.
2. **Fluent.** Idiomatic English. Reads out loud without stumbling.
3. **Simple.** Short sentences. Common words. A curious teenager should follow
   it. Prefer "showed" over "demonstrated", "used" over "utilised".
4. **Faithful in shape.** Same number of sentences give or take one, same order
   of ideas, same length within roughly 20%, so the app layout stays stable.

Spelling and usage are **American English** throughout: `labor`, `criticize`,
`modeled`, `theater`, `toward`, `analyze`, `defense`. Never mix in British
forms.

Rewrite freely at the sentence level to get there. French loves long sentences
chained with semicolons and present-tense narration; English does not. Split
them. Use the past tense for historical narration unless the French is
deliberately using the present for dramatic effect in a short passage.

## 2. Structure is frozen

Only the text fields are translated. Everything else is copied from the French
source by the build tooling and must not be touched: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

Translatable fields, and what each one is:

| Field | What it is | Notes |
| --- | --- | --- |
| `title` | course title on the card and hero | Keep it short. Use the canonical English title of a work when the course is about one. |
| `subtitle` | one-line kicker under the title | A bare year or year range (`1945`, `1945-1975`) is left exactly as is. |
| `description` | two-sentence card blurb | Must stand alone out of context. |
| `hero.hook` | single punchy sentence | Keep the punch. This is marketing copy, not prose. |
| `sections[].title` | section heading | Noun phrase, no final period. |
| `paragraph.text` | body prose | The bulk of the work. |
| `image.caption` | caption under an image | One clause, no final period unless it is a full sentence. |
| `funFact.text` | boxed aside | Light, conversational. |
| `takeaway.text` | closing summary card | The one thing to remember. |
| `quote.text` | quoted line | See §6. |
| `quote.attribution` | who said it | See §6. |
| `timeline.events[].date` | `1789`, `June 1940`, `c. 450 BC` | Numerals stay numerals. Translate month names. Use `BC`/`AD`, never `av. J.-C.`. |
| `timeline.events[].title` | event label | Very short, no final period. |
| `timeline.events[].detail` | one sentence about the event | |

## 3. Inline markup

Three markers exist in the body text and all three must survive translation:

- `**bold**` — key facts: dates, figures, names of the people and works the
  paragraph is actually about.
- `*italic*` — titles of works quoted inside prose.
- `[[Term]]` — a glossary term. Tapping it opens a definition panel.

Rules:

- Markers must be balanced. An odd number of `**` in a field is a bug.
- No marker may wrap leading or trailing whitespace or punctuation:
  `**1945**,` is right, `**1945,**` and `** 1945 **` are wrong.
- Bold the English equivalent of what the French bolded, not the same character
  offsets. If French bolds `**30 000 mots**`, English bolds `**30,000 words**`.
- Do not add bold that is not in the French. Do not bold whole sentences.

## 4. Glossary terms — the most important rule

Each `[[...]]` in the French text produces exactly one `[[...]]` in the English
text, and it stays **inside the sentence, in the same place in the argument**.

Never park a glossary term at the end of the paragraph. Never leave the slot it
came from empty. These two failures are the same bug and they are what this
whole guide exists to prevent:

> Wrong: `weakened above all by : Christian crusaders had sacked the city. [[The sack of Constantinople]]`
>
> Right: `weakened above all by [[the sack of Constantinople during the Fourth Crusade (1204)]], when Western Christian crusaders sacked the city.`

The term text is not free-form. It must be one of the glossary keys registered
for that course in `ios/Sophia/Resources/Locales/glossary.en.json`, because that
is what the app looks up to find the definition. A term that is not a
registered key renders as dead plain text. The per-course brief produced by
`scripts/make_translation_briefs.py` lists the allowed keys; use one of them
exactly, character for character, including capitalisation.

The sentence must be grammatical **with the term spliced in**, which is where
articles go wrong:

- The key often already carries its article: `[[The Ummah]]`, `[[The allegory
  of the Russian Revolution]]`. Then write `He founded [[The Ummah]]`, never
  `He founded the [[The Ummah]]`.
- Where the key has no article, supply the right one outside the brackets, and
  get `a` versus `an` right against the **first sound of the key**: `an
  [[abolitionist]] gesture`, `a [[Oread]]` is wrong and must be `an [[Oread]]`.
- Never write `the` in front of a bare proper name that does not take one:
  `during [[World War II]]`, not `during the [[World War II]]`.
- Do not pluralise or possessive-ise across the bracket: `[[proletariat]]s` and
  `[[Oread]]'s` are wrong. Reword instead.
- If the registered key simply cannot be made to read naturally in the
  sentence, restructure the sentence around it. Do not change the key.

## 5. Proper nouns

Machine translation mangles names. The following are hard rules.

**Never translate a personal name.** Degas is Degas, not "Entgasen". Corneille
is Corneille, not "Crow". Le Corbusier is Le Corbusier. If a name looks like a
common noun in the source language, it is still a name.

**Use the established English form when one exists**, for people
(`Christophe Colomb` → `Christopher Columbus`, `Guillaume le Conquérant` →
`William the Conqueror`), places (`Aix-la-Chapelle` → `Aachen`, `Londres` →
`London`, `Pékin` → `Beijing`), institutions (`Assemblée nationale` →
`National Assembly`), and events (`la Bataille des Ardennes` → `the Battle of
the Bulge`).

**Titles of works take their published English title**, not a literal gloss:

| French | English |
| --- | --- |
| *Impression, soleil levant* | *Impression, Sunrise* |
| *La Ferme des animaux* | *Animal Farm* |
| *Le Rouge et le Noir* | *The Red and the Black* |
| *À la recherche du temps perdu* | *In Search of Lost Time* |
| *Le Déjeuner sur l'herbe* | *The Luncheon on the Grass* |
| *Les Demoiselles d'Avignon* | *Les Demoiselles d'Avignon* (kept) |

When a work has no standard English title, keep the original and gloss it once
in parentheses on first mention.

**Characters in translated literature take the name used in the standard
English translation**, which is often not the French one:

| Work | French | English |
| --- | --- | --- |
| *Animal Farm* | Malabar | Boxer |
| *Animal Farm* | Brille-Babil | Squealer |
| *Animal Farm* | Boule de neige | Snowball |
| *Animal Farm* | Sage l'Ancien / Vieux Major | Old Major |
| *The Little Prince* | Bésixdouze | Asteroid B-612 |
| *Nineteen Eighty-Four* | la novlangue | Newspeak |
| *Nineteen Eighty-Four* | la doublepensée | doublethink |

The registry that encodes all of this for the automated pipeline lives in
`scripts/proper_nouns.json`; add to it rather than fixing the same name twice.

## 6. Quotations

A quotation is not a translation exercise. If the quoted text has a canonical
published English wording, use it. Otherwise translate it plainly and keep it
short.

- Use curly double quotes `“ ”`. Never French guillemets `« »`.
- Punctuation goes inside the closing quote for full sentences:
  `“All animals are equal.”`
- `quote.attribution` is `Author, Work` — and where the French adds a speaker
  after a dash, use a comma or parentheses instead: `Victor Hugo, Les
  Misérables (Monseigneur Bienvenu)`.

## 7. Punctuation and typography

These are checked mechanically and there is no exception to any of them.

- **No em dash `—` and no en dash `–`, anywhere.** Recast with a comma, a
  colon, parentheses, or a full stop. For a numeric range use a plain hyphen:
  `1945-1975`.
- No French guillemets `« »`, no zero-width spaces, no non-breaking spaces.
- Apostrophe is the straight `'` (U+0027), matching the French files. Not `’`.
- Never a space before `, . ; : ! ?`. Never two spaces in a row.
- One space after a colon or semicolon, and use them sparingly: English
  prefers a full stop where French uses a semicolon.
- No stray French words. `siècle`, `dans`, `qui`, `l'`, `d'un` in an English
  paragraph is a defect, and so is a French place name left untranslated inside
  an otherwise English phrase.

## 8. Numbers, dates and units

- Thousands separator is a comma: `30 000` → `30,000`. Never a space, never a
  period.
- Decimal separator is a period: `3,5 %` → `3.5%`. No space before `%`.
- Centuries are ordinal and Arabic: `XVe siècle` → `15th century`.
- Eras are `BC` and `AD`, placed after and before the year respectively:
  `450 BC`, `AD 622`.
- Dates read `24 February 2022` or `February 24, 2022`; pick one per course and
  stay with it.
- Convert nothing. Metric stays metric; add an imperial gloss only where the
  French itself does.
- `Mds`/`Md` → `billion`. `M` → `million`, spelled out.

## 9. Checking your work

Run the validator before considering a course done:

```bash
python scripts/check_course_translation.py --lang en                 # every course
python scripts/check_course_translation.py --lang en course_102_*    # one course
```

It reports, per course: structural drift against the French source, unbalanced
markers, glossary count mismatches, glossary keys that are not registered,
glossary terms parked at the end of a paragraph, article/`a`-`an` errors around
glossary terms, forbidden characters, spacing defects, French leftovers, and
number formatting that was not localised. A clean run is a hard requirement,
not a suggestion.
