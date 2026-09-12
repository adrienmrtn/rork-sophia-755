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
  round(avg((value ->> 'lastLessonIndex')::int)::numeric, 2)       as avg_last_lesson
from user_progress up
cross join lateral jsonb_each(up.progress -> 'courseProgress')
group by key
order by readers desc, finishers desc
limit 10;

-- 2. The ten most-saved courses -----------------------------------------------
select
  course_id,
  count(*) as saves
from user_progress up
cross join lateral jsonb_array_elements_text(
  coalesce(up.progress -> 'favoriteCourseIds', '[]'::jsonb)
) as course_id
group by course_id
order by saves desc
limit 10;

-- 3. Both at once, with titles ------------------------------------------------
-- Needs course_titles.sql to have been run in the same session.
with read as (
  select key as course_id,
         count(*) as readers,
         count(*) filter (where (value ->> 'isCompleted')::boolean) as finishers
  from user_progress up
  cross join lateral jsonb_each(up.progress -> 'courseProgress')
  group by key
),
saved as (
  select course_id, count(*) as saves
  from user_progress up
  cross join lateral jsonb_array_elements_text(
    coalesce(up.progress -> 'favoriteCourseIds', '[]'::jsonb)
  ) as course_id
  group by course_id
)
select
  coalesce(t.title, r.course_id) as course,
  r.readers,
  r.finishers,
  coalesce(s.saves, 0)           as saves
from read r
left join saved s using (course_id)
left join course_titles t on t.course_id = r.course_id
order by r.readers desc
limit 10;

-- 4. How much of the audience this actually covers ----------------------------
-- Signed-in users only; compare with your total installs before reading
-- anything into the ranking.
select
  count(*)                                                              as synced_users,
  count(*) filter (where up.progress -> 'courseProgress' <> '{}'::jsonb) as users_with_a_read,
  sum(jsonb_array_length(
    coalesce(up.progress -> 'favoriteCourseIds', '[]'::jsonb)
  ))                                                                    as total_saves
from user_progress up;
