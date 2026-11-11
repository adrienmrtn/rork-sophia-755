# Sophia duels — translating the quiz questions

Sophia is a general-knowledge app (curious teenagers and adults). Its **duels** are timed quiz
matches between two players: 20 questions, 8–15 seconds each, read on a phone. Players of
different languages play the **same match**: same question ids, same correct answer, same order
of options — only the text differs. So a translation must keep, exactly:

- the **meaning and the facts** (names, dates, numbers, places) — nothing added, nothing dropped;
- the **truth value** of a true/false statement (a "True" must stay true, a "False" stay false —
  and for the *same reason*, not because of a translation slip);
- the **correct option** (marked ✓) and the **order of options** (return them in the same order);
- the **difficulty**: the translation must neither give the answer away nor make it harder.

## The goal: a native quiz, not a word-for-word translation

Write each question as a native quiz writer of your language would have written it from scratch.
Word-for-word translation causes misunderstandings: rebuild the sentence. Concretely:

- **Established names.** People, places, works, gods, heroes, characters, events, prizes,
  scientific terms: use the form a reader of your language knows (French: Ulysse not Odysseus,
  L'Avare not "The Miser", la guerre de Cent Ans; Japanese: ホメロス, 『白鯨』; German: Odysseus,
  Der Geizige…). A title of a work is its **published title** in your language, never a literal
  rendering — if a work has no established title, keep the original title (and, if useful, a short
  gloss). Mythological names follow your language's tradition (Greek vs Latin forms, transliteration).
- **Options stay parallel**: same grammatical form, similar length, mutually distinct, all
  plausible. The correct option must not become longer, more precise or more "native-sounding"
  than the distractors. In inflected languages, put the options in the form the question needs
  (or rephrase the question so the bare form fits).
- **Watch for give-aways**: a translated title or word that now reveals the answer (e.g. a
  question "which animal…" whose translated title contains the animal), or a distractor that
  becomes obviously wrong in your language. Rephrase to keep the question fair.
- **Words in quotes** in the English: if the quote is a title, a famous line or a name, use the
  established form in your language. If the quote is an English word that the question is about
  (e.g. "like"/"as" in a definition of the simile), adapt it to the equivalent in your language
  when the question still works. If the question only makes sense in English (the answer depends
  on an English word, spelling, letter, pun, etymology of an English word), **do not translate it**:
  list it under "untranslatable" with a one-line reason.
- **Numbers and dates**: keep every value; write them the way your language does (decimal comma,
  thousands separator, date order, era words, Japanese 世紀/年 etc.).
- **Short and clear**: the player reads under time pressure. No padding, no explanations. A
  question can be shorter than the English if nothing is lost.
- **Register**: neutral quiz register of your language; follow the translation guide given below
  for typography (quotation marks, dashes, spaces before punctuation, capitalisation of titles).
  If the guide says to address the reader informally, do so in the rare questions that address them.
- **Image questions** (kind `portrait`): the player sees a picture (portrait, flag, painting,
  monument) and picks what it shows: "Who is this?", "Which country's flag is this?" etc. Translate
  naturally; options are names or titles in their established form.
- **Slider questions**: the player sets a number. If the line has `unit: …` and the unit is not
  `year`, `%`, `°C`, `m/s` or `min`, give in `"u"` the word shown right after the number on screen
  (the app prints `<number> <u>`), in the form that fits the correct value (plural if needed;
  Japanese: the counter, e.g. 日, 冊, 本). Translate the question so it matches.
- **True/False** labels: your part-1 file also gives `"true_false": ["<True>", "<False>"]`, the two
  answer buttons (short, capitalised as a button in your language).

## Output

JSON, written with the Write tool (UTF-8, valid JSON — escape `"` and `\` inside strings):

```json
{
  "items": {
    "dq_en_1_01": {"q": "<question>", "o": ["<opt 1>", "<opt 2>", "<opt 3>", "<opt 4>"]},
    "dq_en_1_05": {"q": "<true/false statement>"},
    "dq_en_1_20": {"q": "<slider question>", "u": "<unit word, only when asked>"}
  },
  "untranslatable": [{"id": "dq_en_…", "why": "<one line, in English>"}]
}
```

- `o` for `mcq` and `portrait` only, same number and order as the English, without the ✓.
- No `o` for true/false and slider questions.
- Every id of your part appears either in `items` or in `untranslatable` — none missing.
- Only part 1 also carries `"true_false"` and `"leagues"` (see your task).
