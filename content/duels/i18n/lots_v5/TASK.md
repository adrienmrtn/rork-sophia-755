# Task — translate new Sophia duel questions (batch v5) into ONE language

Work in /home/user/rork-sophia-755. Your language and your parts are given in your task
(e.g. `ja`, parts 6–10). Each part is a pack of 100 questions.

## Read first
1. `content/duels/i18n/lots/BRIEF.md` — the translation brief. Follow it strictly.
   IGNORE its mentions of `true_false` and `leagues`: not needed in this batch.
2. Your language's guide `content/TRANSLATION_GUIDE_<XX>.md` (pt → PT, pt-PT → PT_PT; French has no
   guide: standard French quiz typography, « » with non-breaking spaces, narrow no-break space before ? ! ;).
3. For consistency with the ~1 700 questions already translated, grep `content/duels/i18n/<lang>.json`
   for names, titles, terms and typography (mythological names, transliterations, quotation marks,
   how comparison questions and slider units are phrased) and reuse the same forms.

## The owner's rule: meaning, not words
- **Never translate word for word.** Rewrite each question as a native quiz writer of your
  language would have written it: natural word order, idiomatic phrasing, established names and
  published titles. Read your sentence aloud in your head: if a native player would find it odd,
  rewrite it.
- **If a question cannot make real sense in your language** (the answer hinges on an English word,
  spelling, letter, pun, etymology; a title with no equivalent that the question depends on; the
  translated wording unavoidably gives the answer away — e.g. the name of the thing literally
  contains the answer in your language — and no fair rewording exists), DO NOT force it: list it in
  `untranslatable` with a one-line reason in English. Such a question will be deleted in ALL
  languages, so use it only for real cases, not for mere difficulty.
- Image questions (kind `portrait`): the player sees a picture; translate naturally.

## Packs and output
- Packs: `content/duels/i18n/lots_v5/packs/part<N>.md` (✓ marks the correct option — keep the
  option ORDER exactly, drop the ✓).
- Write `content/duels/i18n/lots_v5/out/<lang>/part<N>.json` with the Write tool:
  `{"items": {"dq_en_…": {"q": "…", "o": [...]}, …}, "untranslatable": [{"id": "…", "why": "…"}]}`
  (`o` only for mcq/portrait; `u` for slider units other than year/%/°C/m/s/min, in the form that
  fits the correct value). Escape `"` inside strings (or use your language's quotation marks).
- Check each part:
  `python3 scripts/duels_i18n.py check --work content/duels/i18n/lots_v5 --lang <lang> --part <N> --parts 15 --new`
  Fix every REJET line; read every AVERT and fix real problems.
- Re-read each part once as a native editor: facts unchanged, correct option still the ✓ one,
  no give-away, parallel options, natural phrasing.

Do not touch any other file, do not commit. Report: items translated per part, untranslatable
(ids + reasons), and the final check line of each part.
