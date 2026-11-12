# Brief — independent verification of new duel questions (batch v4)

You did NOT write these questions. Your job is to be an adversarial fact-checker and quiz editor.
Read content/duels/v4/v4_BRIEF_WRITER.md first (format and rules). In the draft, the FIRST
option of an mcq is the intended correct answer.

For EVERY question, check:
1. **Fact**: the correct answer is right beyond reasonable doubt (mainstream encyclopedic
   consensus). For tf: the stated truth value is right. For slider: the value is right and the
   range is sensible (value not exactly mid-range).
2. **Distractors**: each is certainly wrong (no "also arguably correct" option), plausible, parallel.
3. **Unambiguous** wording; no give-away; short (≤ ~110 chars question, ≤ ~30 chars options).
4. **Timeless** (nothing that can change), **translatable** (answer does not hinge on English
   words/spelling/etymology), neutral.
5. **Not a duplicate** of the existing questions (file content/duels/v4/existing_<subject>.txt)
   or of another draft question.
6. Level plausible (1 = everyone knows, 8 = expert). Re-level if clearly off.

Fix what can be fixed (reword, replace a distractor, correct a value, change level). DROP a
question you cannot make certainly correct. Then keep exactly the requested number of questions,
with levels as evenly spread across 1–8 as possible (drop surplus from over-represented levels;
if you are short, write replacement questions yourself, held to the same standard).

Output:
- content/duels/v4/final_<subject>.json — JSON array, one object per line, same format, first
  option correct, exactly the requested count, ordered by level.
- content/duels/v4/review_<subject>.md — short log: each question changed or dropped and why.
