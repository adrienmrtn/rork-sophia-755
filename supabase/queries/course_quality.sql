-- Readers and finishers per course — the "quality" half of the home deck model.
--
-- Paste into the Supabase SQL editor, run, export with the CSV button, and save
-- the result as `scripts/data/course_quality.csv`. Then run
-- `python3 scripts/build_course_affinity.py` to regenerate
-- `ios/Sophia/Utilities/CourseAffinity.swift`.
--
-- Why `finishers` is the metric the deck ranks on, rather than `readers`:
-- the deck used to be `courses.shuffled()`, so every course got the same
-- exposure. Under equal exposure a course's finisher count *is*
-- `P(the reader opens it × the reader finishes it)`, which is exactly what a
-- first card should maximise. No model needed to justify it, and no popularity
-- bias to unwind — which is also why `HomeDeckBuilder` keeps dealing a quarter of
-- the deck at random.
--
-- The subject is derived from the course number because Supabase holds none of the
-- catalogue: the ranges below are a property of how the courses are numbered, and
-- `scripts/build_course_affinity.py` re-checks them against the real catalogue when
-- it maps numbers back to ids.
--
--   1–40    histoire         81–120  litterature     161–200  mythologie
--   41–80   sciences        121–160  art             201–240  comprendreLeMonde
--
-- Caveats that also apply to `top_courses.sql`: signed-in users only (sync never
-- runs for anonymous ones), nothing per language, and distinct users rather than
-- volume. One more, specific to this file: the five courses of the onboarding swipe
-- deck are over-represented, because being liked there put them in the user's
-- favourites, which is a second way into them. Their finisher counts are inflated;
-- everything else was only ever reachable through the random deck.

with course_progress as (
  select
    up.user_id,
    entry.key as course_id,
    (substring(entry.key from 'course_([0-9]+)_'))::int as course_number,
    (entry.value ->> 'isCompleted')::boolean as is_completed
  from user_progress up,
       lateral jsonb_each(
         coalesce(up.progress::jsonb -> 'courseProgress', '{}'::jsonb)
       ) entry
  where entry.key ~ '^course_[0-9]+_'
)
select
  course_number,
  case
    when course_number between   1 and  40 then 'histoire'
    when course_number between  41 and  80 then 'sciences'
    when course_number between  81 and 120 then 'litterature'
    when course_number between 121 and 160 then 'art'
    when course_number between 161 and 200 then 'mythologie'
    else 'comprendreLeMonde'
  end as subject,
  count(*) as readers,
  count(*) filter (where is_completed) as finishers
from course_progress
group by course_number
order by course_number;
