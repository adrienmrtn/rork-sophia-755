# Verification task (batch v5)

Read content/duels/v4/v4_BRIEF_VERIFIER.md and content/duels/v5/BRIEF_V5.md, and follow them.
You did NOT write the draft. Be adversarial on facts, ambiguity, translatability (a question that
cannot make sense in Japanese, Arabic or Finnish must be dropped), repetition (max 2 questions on the
same person/work/event/place, counting existing ones) and duplicates with the existing questions
file of the subject (content/duels/v5/existing_<subject>.txt).
Keep exactly **117** questions (drop the weakest; if short, write replacements to the same standard),
levels as even as possible across 1–8 (14 or 15 each). Output:
- content/duels/v5/final_<subject>_<lane>.json (JSON array, one object per line, first option correct,
  ordered by level), validated with python3 (field checks per kind: mcq 2 or 4 distinct options;
  tf answer bool; slider integers min<value<max, step, unit, value not exactly mid-range);
- content/duels/v5/review_<subject>_<lane>.md (each change/drop and why).
Do not touch other files, do not commit. Reply: kept, fixed, dropped/replaced, per-level counts.
