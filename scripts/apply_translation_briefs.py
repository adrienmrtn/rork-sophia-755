#!/usr/bin/env python3
"""Rebuild localised course files from translated segment maps.

Input is one JSON file per course, ``<course_id>.json``, mapping segment keys
(as produced by ``make_translation_briefs.py``) to translated strings. The
French course is cloned and only those segments are substituted, so structure,
ids, asset names and paywall flags are carried over untouched.

Non-translatable metadata that is nevertheless language-specific -- ``subtitle``
when it is a bare year, and ``subcategory`` -- is resolved as follows:
``subcategory`` is taken from the existing localised file when present (it must
keep matching the collection labels the app groups by), otherwise from French.

Usage:
    python scripts/apply_translation_briefs.py --lang en --from /tmp/sophia-translation/en/out
    python scripts/apply_translation_briefs.py --lang en --from DIR --dry-run
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from course_translation_io import (
    CONTENT_ROOT,
    apply_segments,
    load_course,
    write_course,
)


def resolve_subcategory(course_id: str, lang: str, french: dict) -> str:
    existing = CONTENT_ROOT / lang / f"{course_id}.json"
    if existing.is_file():
        try:
            previous = json.loads(existing.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            previous = {}
        if isinstance(previous.get("subcategory"), str) and previous["subcategory"]:
            return previous["subcategory"]
    return french.get("subcategory", "")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", required=True)
    parser.add_argument("--from", dest="source", type=Path, required=True)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--allow-partial", action="store_true", help="Write even when segments are missing")
    args = parser.parse_args()

    files = sorted(args.source.glob("*.json"))
    if not files:
        print(f"No translation files in {args.source}")
        return 1

    written = 0
    skipped = 0
    for path in files:
        course_id = path.stem
        try:
            translations = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            print(f"  BAD JSON {path.name}: {error}")
            skipped += 1
            continue
        if not isinstance(translations, dict):
            print(f"  BAD SHAPE {path.name}: expected an object of segment keys")
            skipped += 1
            continue

        try:
            french = load_course("fr", course_id)
        except FileNotFoundError:
            print(f"  NO SOURCE {course_id}")
            skipped += 1
            continue

        rebuilt, missing = apply_segments(french, translations)
        if missing and not args.allow_partial:
            print(f"  INCOMPLETE {course_id}: {len(missing)} segment(s) missing: {missing[:6]}")
            skipped += 1
            continue

        rebuilt["subcategory"] = resolve_subcategory(course_id, args.lang, french)

        unknown = [key for key in translations if key not in dict(_keys(french))]
        if unknown:
            print(f"  UNKNOWN KEYS {course_id}: {unknown[:6]}")

        if args.dry_run:
            written += 1
            continue
        if write_course(args.lang, rebuilt):
            written += 1

    print(f"\n{'Would write' if args.dry_run else 'Wrote'} {written} course(s); skipped {skipped}.")
    return 1 if skipped else 0


def _keys(french: dict):
    from course_translation_io import segments

    return segments(french)


if __name__ == "__main__":
    raise SystemExit(main())
