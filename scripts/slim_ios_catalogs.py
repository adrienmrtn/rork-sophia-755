#!/usr/bin/env python3
"""Drop the legacy lesson bodies from the iOS catalogs.

The reader renders `Resources/CoursesV2/<id>.<lang>.json`; the legacy text of each
lesson (`lessons[].content` in `Resources/Locales/courses.<lang>.json`, and the
`content:` of every `LessonPage` in `Services/CourseData.swift`) is only a fallback
for a course with no structured edition, and every course has one in every language.
That text weighed 46 MB uncompressed for nothing. The lesson ids and titles stay:
`CourseView` pages over them and looks each section up by id.

`LessonPage` decodes a missing `content` as an empty string, so the key is simply
dropped from the JSON. Idempotent; re-run after anything regenerates a catalog.

Usage:
    python scripts/slim_ios_catalogs.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from i18n_languages import NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
COURSE_DATA = ROOT / "ios" / "Sophia" / "Services" / "CourseData.swift"

LESSON_CONTENT_RE = re.compile(r'(LessonPage\(id: "[^"]+", title: "(?:[^"\\]|\\.)*", content: )"(?:[^"\\]|\\.)*"\)')


def slim_catalog(path: Path) -> tuple[int, int]:
    before = path.stat().st_size
    courses = json.loads(path.read_text(encoding="utf-8"))
    for course in courses:
        for lesson in course.get("lessons") or []:
            lesson.pop("content", None)
    path.write_text(json.dumps(courses, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return before, path.stat().st_size


def slim_swift() -> tuple[int, int, int]:
    source = COURSE_DATA.read_text(encoding="utf-8")
    before = len(source.encode("utf-8"))
    slimmed, count = LESSON_CONTENT_RE.subn(r'\1"")', source)
    COURSE_DATA.write_text(slimmed, encoding="utf-8")
    return before, len(slimmed.encode("utf-8")), count


def main() -> int:
    total_before = total_after = 0
    for lang in NON_FR_LANGS:
        path = LOCALES / f"courses.{lang}.json"
        if not path.is_file():
            continue
        before, after = slim_catalog(path)
        total_before += before
        total_after += after
    print(f"courses.<lang>.json: {total_before / 1e6:.1f} MB -> {total_after / 1e6:.1f} MB")
    before, after, count = slim_swift()
    print(f"CourseData.swift: {before / 1e6:.1f} MB -> {after / 1e6:.1f} MB ({count} lesson bodies emptied)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
