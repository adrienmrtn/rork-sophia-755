# Task — translate 400 new Sophia duel questions into your language(s)

Work in /home/user/rork-sophia-755. For EACH language assigned to you:

1. Read `content/duels/i18n/lots/BRIEF.md` (the translation brief — follow it strictly) and your
   language's guide `content/TRANSLATION_GUIDE_<XX>.md` (pt → PT, pt-PT → PT_PT; French has no guide:
   use standard French quiz typography, « » with non-breaking spaces, etc.).
   IGNORE the brief's mentions of `true_false` and `leagues`: they are NOT needed in this batch.
2. For consistency with the 1 316 questions already translated, look at
   `content/duels/i18n/<lang>.json` (do not read it all: grep it for names, terms and typography —
   e.g. how mythological names, titles, quotation marks are rendered — and reuse the same forms).
3. Translate the 4 packs `content/duels/i18n/lots_v4/packs/part1.md` … `part4.md` (100 questions
   each; ✓ marks the correct option — keep the option ORDER exactly, drop the ✓).
   Write `content/duels/i18n/lots_v4/out/<lang>/part<N>.json` with the Write tool, format:
   `{"items": {"dq_en_…": {"q": "…", "o": [...]}, …}, "untranslatable": [{"id": "…", "why": "…"}]}`
   (`o` only for mcq/portrait; `u` for slider units other than year/%/°C/m/s/min).
   Comparison questions ("Which is larger?", 2 options) must make sense with the two options.
4. Check each part:
   `python3 scripts/duels_i18n.py check --work content/duels/i18n/lots_v4 --lang <lang> --part <N> --parts 4 --new`
   Fix every REJET line; read every AVERT line and fix it when it is a real problem (a number
   written as a word or in another format can be fine).
5. Re-read your output once as a native quiz editor: facts unchanged, correct option still the
   one marked ✓, no give-away, established names and published titles, natural phrasing.

Do not touch any other file, do not commit. Report per language: items translated, untranslatable
(with ids), and the final check line of each part.
