#!/usr/bin/env python3
"""Generate `ios/Sophia/Utilities/CourseAffinity.swift` from the Supabase export.

The app ships the whole catalogue, Supabase holds none of it, so the two halves of
the model are produced here and baked into a Swift file rather than fetched at
runtime: the home deck has to be built offline, on first launch, before any network
call has come back.

Inputs — both produced by running `supabase/queries/course_affinity.sql` in the
Supabase SQL editor and exporting with the CSV button:

  data/course_quality.csv     course_number, subject, readers, finishers
  data/course_neighbours.csv  course_number, "n:lift,n:lift,…" (best lift first)

Course *numbers* rather than ids, because the ids are long and the numbers are
what the SQL derives the subject from. They are mapped back to full ids using the
catalogue inlined in `supabase/queries/top_courses.sql`, which
`build_course_titles_sql.py` keeps in sync with the app. A course present in the
export but no longer in the catalogue is dropped: the deck can only ever serve
courses the app still ships.

Re-run after a meaningful change to the catalogue, or every month or so to refresh
the numbers:

    python3 scripts/build_course_affinity.py
"""

from __future__ import annotations

import csv
import datetime
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOGUE_SQL = ROOT / "supabase" / "queries" / "top_courses.sql"
QUALITY_CSV = ROOT / "scripts" / "data" / "course_quality.csv"
NEIGHBOURS_CSV = ROOT / "scripts" / "data" / "course_neighbours.csv"
OUT_SWIFT = ROOT / "ios" / "Sophia" / "Utilities" / "CourseAffinity.swift"

# A pair read together by fewer than this many people says nothing; a lift under
# this much is what popularity alone produces. Both are there to keep the model
# from recommending "Pourquoi rêve-t-on" as everyone's neighbour: it is read by so
# many people that it co-occurs with the entire catalogue.
MIN_LIFT = 2.0
MAX_NEIGHBOURS = 8

SUBJECT_KEYS = [
    "histoire",
    "sciences",
    "litterature",
    "art",
    "mythologie",
    "comprendreLeMonde",
]


def course_ids_by_number() -> dict[int, str]:
    """`{12: "course_12_la_strategie_de_napoleon_a_ulm_1805", …}` from the catalogue."""
    sql = CATALOGUE_SQL.read_text(encoding="utf-8")
    ids = re.findall(r"\('(course_(\d+)_[a-z0-9_]*)'", sql)
    return {int(number): course_id for course_id, number in ids}


def read_quality(by_number: dict[int, str]) -> dict[str, tuple[str, int]]:
    """`{course_id: (subject, finishers)}`, dropping what the app no longer ships."""
    out: dict[str, tuple[str, int]] = {}
    with QUALITY_CSV.open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            number = int(row["course_number"])
            course_id = by_number.get(number)
            if course_id is None:
                continue
            out[course_id] = (row["subject"], int(row["finishers"]))
    return out


def read_neighbours(
    by_number: dict[int, str], known: set[str]
) -> dict[str, list[tuple[str, float]]]:
    out: dict[str, list[tuple[str, float]]] = {}
    with NEIGHBOURS_CSV.open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            course_id = by_number.get(int(row["course_number"]))
            if course_id is None or course_id not in known:
                continue
            pairs: list[tuple[str, float]] = []
            for chunk in row["neighbours"].split(","):
                if not chunk:
                    continue
                neighbour_number, _, lift = chunk.partition(":")
                neighbour_id = by_number.get(int(neighbour_number))
                if neighbour_id is None or neighbour_id not in known:
                    continue
                value = float(lift)
                if value < MIN_LIFT:
                    continue
                pairs.append((neighbour_id, value))
            if pairs:
                out[course_id] = pairs[:MAX_NEIGHBOURS]
    return out


def subject_weights(quality: dict[str, tuple[str, int]]) -> dict[str, float]:
    """Share of finishers per *course* in each subject, normalised to 1.

    Per course, not per subject, because the subjects hold 39–40 courses each but
    that is a coincidence of the catalogue, not a property of demand. The home deck
    drew uniformly at random over the whole catalogue, so a course's finisher count
    is `P(opened it × finished it)` with exposure held equal — which makes the
    average finisher count of a subject exactly how often the deck should serve it.
    """
    totals: dict[str, list[int]] = {key: [] for key in SUBJECT_KEYS}
    for subject, finishers in quality.values():
        totals[subject].append(finishers)
    means = {key: (sum(values) / len(values)) if values else 0.0 for key, values in totals.items()}
    total = sum(means.values())
    return {key: value / total for key, value in means.items()}


def normalised_quality(quality: dict[str, tuple[str, int]]) -> dict[str, float]:
    """Finishers rescaled to 0–1 *within* each subject.

    Within, not across: the subject weights above already carry how much more
    sciences is wanted than mythologie. Scoring courses on a global scale too would
    count that preference twice and leave the humanities unable to win a slot the
    weights had already granted them.
    """
    best: dict[str, int] = {}
    for subject, finishers in quality.values():
        best[subject] = max(best.get(subject, 0), finishers)
    return {
        course_id: (finishers / best[subject] if best[subject] else 0.0)
        for course_id, (subject, finishers) in quality.items()
    }


def swift_dictionary(name: str, kind: str, rows: list[str]) -> str:
    body = "\n".join(f"        {row}" for row in rows)
    return f"    static let {name}: {kind} = [\n{body}\n    ]\n"


def main() -> int:
    by_number = course_ids_by_number()
    if not by_number:
        print(f"No catalogue found in {CATALOGUE_SQL}", file=sys.stderr)
        return 1

    quality = read_quality(by_number)
    if not quality:
        print(f"No rows in {QUALITY_CSV}", file=sys.stderr)
        return 1

    neighbours = read_neighbours(by_number, set(quality))
    weights = subject_weights(quality)
    scores = normalised_quality(quality)

    quality_rows = [
        f'"{course_id}": {scores[course_id]:.3f},' for course_id in sorted(scores)
    ]
    neighbour_rows = [
        '"{}": [{}],'.format(
            course_id,
            ", ".join(f'"{neighbour}"' for neighbour, _ in neighbours[course_id]),
        )
        for course_id in sorted(neighbours)
    ]
    lift_rows = [
        '"{}": [{}],'.format(
            course_id,
            ", ".join(f"{lift:.1f}" for _, lift in neighbours[course_id]),
        )
        for course_id in sorted(neighbours)
    ]
    weight_rows = [f'"{key}": {weights[key]:.3f},' for key in SUBJECT_KEYS]

    covered = len(neighbours)
    generated_on = datetime.date.today().isoformat()

    header = f'''// Generated by scripts/build_course_affinity.py on {generated_on} — do not edit by hand.
//
// The observed half of the home deck: how often each course is finished, and which
// courses are read by the same people. Both come from what users actually did, not
// from an editorial guess.
//
// Why the numbers can be trusted: until this shipped, the deck was
// `courses.shuffled()`. Every course got the same exposure, so a finisher count is
// a clean `P(opened × finished)` and a co-read pair carries no popularity bias to
// unwind. That property is worth keeping — `HomeDeckBuilder` still deals a quarter
// of the deck at random, which is what lets these numbers be refreshed later
// without the model having trained on its own recommendations.
//
// {len(quality)} courses scored, {covered} with at least one neighbour above ×{MIN_LIFT:.1f} lift.

import Foundation

nonisolated enum CourseAffinity {{
'''

    parts = [
        header,
        """    /// How often the deck should serve each subject, before the reader's own history
    /// bends it. Shares of the average finisher count per course — see the generator.
""",
        swift_dictionary("subjectBaseWeight", "[String: Double]", weight_rows),
        """
    /// Observed quality, 0–1 within the course's own subject. 1 is the most-finished
    /// course of that subject.
""",
        swift_dictionary("quality", "[String: Double]", quality_rows),
        """
    /// Courses read by the same people, best lift first. A course absent here simply
    /// has no co-read partner strong enough to be worth acting on.
""",
        swift_dictionary("neighbourIds", "[String: [String]]", neighbour_rows),
        """
    /// Lift of each pair in `neighbourIds`, same order. ×3 means three times as many
    /// people read both as chance alone would produce.
""",
        swift_dictionary("neighbourLifts", "[String: [Double]]", lift_rows),
        """
    /// Neighbours of `courseId` as `(id, lift)`, strongest first.
    ///
    /// The two dictionaries are generated together and always agree; `zip` keeps a
    /// hand-edit that breaks that from crashing, and simply drops the excess.
    static func neighbours(of courseId: String) -> [(id: String, lift: Double)] {
        guard let ids = neighbourIds[courseId], let lifts = neighbourLifts[courseId] else {
            return []
        }
        return zip(ids, lifts).map { (id: $0, lift: $1) }
    }
}
""",
    ]

    OUT_SWIFT.write_text("".join(parts), encoding="utf-8")
    print(f"{OUT_SWIFT.relative_to(ROOT)}: {len(quality)} courses, {covered} with neighbours")
    for key in SUBJECT_KEYS:
        print(f"  {key:<18} {weights[key] * 100:5.1f}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
