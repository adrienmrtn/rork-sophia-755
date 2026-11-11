# Brief — writing new Sophia duel questions (batch v4)

Sophia is a general-knowledge app for curious teenagers and adults. Its **duels** are timed quiz
matches (8–15 s per question, read on a phone). Questions are written in English, then translated
into 29 languages (French, Spanish, German, Japanese, Arabic, Hebrew, Greek, Russian, Turkish,
Polish, Hungarian, Finnish, …). Players of different languages play the same question.

## Format (JSON array, one object per line)

```json
{"level": 3, "kind": "mcq", "subject": "history", "question": "…?", "options": ["CORRECT", "wrong", "wrong", "wrong"]},
{"level": 3, "kind": "mcq", "subject": "world", "question": "Which country is larger in area?", "options": ["CORRECT", "wrong"]},
{"level": 2, "kind": "tf", "subject": "science", "question": "<statement>.", "answer": true},
{"level": 5, "kind": "slider", "subject": "history", "question": "In what year …?", "min": 1700, "max": 1900, "value": 1789, "unit": "year", "step": 1}
```

- **The FIRST option is always the correct one** (the build script shuffles them).
- `mcq`: 4 options (or exactly 2 for a comparison: "Which is taller?", "Which came first?").
- `tf`: a statement; `answer` true or false. Make roughly half true, half false. A false
  statement must be clearly false (a swapped name/date/place), never a quibble.
- `slider`: the player sets a number; the closest wins. `unit` is `"year"` for years, otherwise a
  short plural noun shown after the number ("days", "metres", "books", "bones", "%", "°C", "km"…).
  Integer `min`/`max`/`value`/`step`. Range wide enough to be a real guess but not absurd
  (years: 100–300-year window; the value must NOT sit exactly in the middle of the range).
- `level`: 1 (everyone knows it) … 8 (expert / quiz-buff). Level 1–2: famous facts; 3–4:
  good general culture; 5–6: well-read person; 7–8: specialist but still fair and gettable.

## Quality rules (strict — an independent verifier will reject violations)

1. **Correct and unambiguous.** One answer only, true beyond doubt, checkable in a mainstream
   reference (encyclopedia). Distractors must be **certainly wrong** yet plausible (same type, same
   era/region, similar length and form). No "All of the above", no "None".
2. **Timeless.** Nothing that can change: no "current", "largest today", records, living people's
   positions, population/GDP figures (except comparisons with a huge, stable gap), recent events
   after 2020.
3. **Translatable.** The answer must NOT depend on an English word, spelling, letter, pun,
   rhyme or English etymology. Avoid English-only titles with no established translation
   unless the author is famous.
4. **Short.** A question fits in ~2 lines of a phone (max ~110 characters). Options short (max
   ~30 characters).
5. **Varied.** Mix eras, continents (Asia, Africa, Americas, Oceania, Middle East — not only
   Europe/US), women and men, famous and lesser-known topics. No two questions on the same fact.
   **No duplicate or near-duplicate of the existing questions** listed in the file you are given.
6. No give-away: the question must not contain the answer or a word that reveals it.
7. Neutral and respectful (religion, politics, wars): facts only.
