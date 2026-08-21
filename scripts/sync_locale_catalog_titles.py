#!/usr/bin/env python3
"""Align the legacy locale catalog with the structured (v2) course content.

Two catalogs describe the same courses. The structured one under
``content/courses/<lang>/`` supplies the body the app renders. The legacy one,
``ios/Sophia/Resources/Locales/courses.<lang>.json``, still supplies the course
list: the title and blurb on every card, and the lesson ids the reader pages
through.

When the structured content is rewritten, the two drift, and a reader sees the
old title on the card and the new one inside the course. This copies the
title, the description and the per-lesson headings across, matching lessons to
sections by id. Nothing else in the legacy catalog is touched, so ids, quizzes
and the legacy body text stay exactly as they were.

The structured title wins outright. Some legacy card titles carry a
disambiguating parenthesis the structured title drops, `The discovery of
penicillin (Fleming, 1928)` against `The discovery of penicillin`, but that
parenthesis only exists in the French card catalog and carrying it across would
put French inside an English title. A card and a course header that agree matter
more than the extra date.

Usage:
    python scripts/sync_locale_catalog_titles.py --lang en
    python scripts/sync_locale_catalog_titles.py --lang en --dry-run
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from course_translation_io import CONTENT_ROOT, LOCALES_DIR


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    catalog_path = LOCALES_DIR / f"courses.{args.lang}.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))

    structured = {}
    for path in sorted((CONTENT_ROOT / args.lang).glob("*.json")):
        course = json.loads(path.read_text(encoding="utf-8"))
        structured[course["id"]] = course

    changes: list[str] = []
    missing: list[str] = []

    for entry in catalog:
        course = structured.get(entry.get("id"))
        if course is None:
            missing.append(entry.get("id", "?"))
            continue

        for field in ("title", "description"):
            new = course.get(field)
            if isinstance(new, str) and new and entry.get(field) != new:
                changes.append(f"{entry['id']}.{field}")
                entry[field] = new

        sections = {section["id"]: section for section in course.get("sections", [])}
        for lesson in entry.get("lessons", []):
            section = sections.get(lesson.get("id"))
            if section is None:
                continue
            new = section.get("title")
            if isinstance(new, str) and new and lesson.get("title") != new:
                changes.append(f"{entry['id']}.{lesson['id']}.title")
                lesson["title"] = new

    print(f"{len(changes)} field(s) to update in {catalog_path.name}")
    if missing:
        print(f"  no structured content for {len(missing)} course(s): {missing[:5]}")

    if args.dry_run:
        for change in changes[:40]:
            print(f"  {change}")
        return 0

    payload = json.dumps(catalog, ensure_ascii=False, indent=2) + "\n"
    if catalog_path.read_text(encoding="utf-8") == payload:
        print("Already in sync.")
        return 0
    catalog_path.write_text(payload, encoding="utf-8")
    print(f"Wrote {catalog_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
