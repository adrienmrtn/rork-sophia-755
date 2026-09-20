-- The eight courses most read by the same people as each course — the "neighbours"
-- half of the home deck model.
--
-- Paste into the Supabase SQL editor, run, export with the CSV button, and save
-- the result as `scripts/data/course_neighbours.csv`. Then run
-- `python3 scripts/build_course_affinity.py` to regenerate
-- `ios/Sophia/Utilities/CourseAffinity.swift`.
--
-- `lift` is how many times more often a pair is read together than chance would
-- produce: `P(A and B) / (P(A) × P(B))`. It is the right measure here precisely
-- because the deck was random — two courses read together are read together
-- because they belong together, not because the app kept showing them side by
-- side. ×7 on Odyssée/Iliade and ×17 on two Caravage-era painting courses are the
-- model recognising the catalogue's own structure, unaided.
--
-- Raw counts would not do: "Pourquoi rêve-t-on" is read by so many people that it
-- co-occurs with the entire catalogue. It is the denominator that demotes it.
--
-- The `>= 20` floor keeps pairs that two dozen people happen to share out of the
-- model; the generator drops anything under ×2.0 lift on top of that. A course
-- left with no neighbour is fine — it is then ranked on its quality alone.
--
-- Output is one row per course: the course number, then `number:lift` for each
-- neighbour, strongest first, comma-separated. Numbers rather than ids because the
-- ids are long and the generator maps them back against the real catalogue anyway.

with course_reader as (
  select distinct
    up.user_id,
    (substring(entry.key from 'course_([0-9]+)_'))::int as course_number
  from user_progress up,
       lateral jsonb_each(
         coalesce(up.progress::jsonb -> 'courseProgress', '{}'::jsonb)
       ) entry
  where entry.key ~ '^course_[0-9]+_'
),
reader_count as (select count(distinct user_id)::numeric as readers from course_reader),
per_course as (
  select course_number, count(*)::numeric as readers
  from course_reader
  group by course_number
),
pairs as (
  select
    a.course_number as course_number,
    b.course_number as neighbour_number,
    count(*)::numeric as read_together
  from course_reader a
  join course_reader b
    on a.user_id = b.user_id
   and a.course_number <> b.course_number
  group by 1, 2
  having count(*) >= 20
),
ranked as (
  select
    pairs.course_number,
    pairs.neighbour_number,
    pairs.read_together
      / (course.readers * neighbour.readers / (select readers from reader_count))
      as lift,
    row_number() over (
      partition by pairs.course_number
      order by pairs.read_together
        / (course.readers * neighbour.readers / (select readers from reader_count)) desc
    ) as rank
  from pairs
  join per_course course on course.course_number = pairs.course_number
  join per_course neighbour on neighbour.course_number = pairs.neighbour_number
)
select
  course_number,
  string_agg(
    neighbour_number::text || ':' || round(lift, 1)::text,
    ',' order by rank
  ) as neighbours
from ranked
where rank <= 8
group by course_number
order by course_number;
