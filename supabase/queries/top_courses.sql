-- Most-read and most-saved courses, from the data already in Supabase.
--
-- There is no event log yet: `user_progress` holds one row per signed-in user
-- with a JSON snapshot of their progress. That snapshot is enough for a
-- ranking, because `courseProgress` gains an entry the moment a lesson is
-- viewed (ProgressManager.updateLessonProgress) and `favoriteCourseIds` holds
-- every course the user saved.
--
-- What it can answer:   how many distinct users opened / finished / saved each
--                       course, and how far into it they got.
-- What it cannot:       how many times, when, or in what order -- a snapshot
--                       keeps no history, and a course saved then unsaved
--                       leaves no trace. Anonymous users never sync, so this
--                       covers signed-in users only.
--
-- Run it in the Supabase SQL editor. Paste course_titles.sql first if you want
-- titles instead of ids.

-- 1. The ten most-read courses ------------------------------------------------
select
  key                                                              as course_id,
  count(*)                                                         as readers,
  count(*) filter (where (value ->> 'isCompleted')::boolean)       as finishers,
  round(
    100.0 * count(*) filter (where (value ->> 'isCompleted')::boolean)
    / nullif(count(*), 0)
  , 1)                                                             as completion_pct,
  -- lastLessonIndex is a 0-based high-water mark, so +1 reads as "lessons
  -- reached": 5 on a five-lesson course means the average reader got to the end.
  round(avg((value ->> 'lastLessonIndex')::int)::numeric + 1, 2)   as avg_lessons_read
from user_progress up
cross join lateral jsonb_each(up.progress::jsonb -> 'courseProgress')
group by key
order by readers desc, finishers desc
limit 10;

-- 2. The ten most-saved courses -----------------------------------------------
select
  course_id,
  count(*) as saves
from user_progress up
cross join lateral jsonb_array_elements_text(
  coalesce(up.progress::jsonb -> 'favoriteCourseIds', '[]'::jsonb)
) as course_id
group by course_id
order by saves desc
limit 10;

-- 3. With titles ---------------------------------------------------------------
-- Lives in its own file, carrying the 238 titles and lesson counts inline:
--   top_courses_with_titles.sql   the ten most-read
--   all_courses_with_titles.sql   every course, the untouched ones included
-- It cannot be done from here: Supabase has neither titles nor lesson counts,
-- and the SQL editor opens a new connection per run, so a temporary lookup
-- table is gone before the query that needs it.

-- 4. How much of the audience this actually covers ----------------------------
-- Signed-in users only; compare with your total installs before reading
-- anything into the ranking.
select
  count(*)                                                              as synced_users,
  count(*) filter (where up.progress::jsonb -> 'courseProgress' <> '{}'::jsonb) as users_with_a_read,
  sum(jsonb_array_length(
    coalesce(up.progress::jsonb -> 'favoriteCourseIds', '[]'::jsonb)
  ))                                                                    as total_saves
from user_progress up;
