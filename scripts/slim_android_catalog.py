#!/usr/bin/env python3
"""Slim Android course catalogs: index + quiz only (no lesson bodies).

iOS still ships full `courses.{lang}.json`. Android reads lesson text from
`courses_v2/{lang}/{id}.json` and only needs metadata + quiz in the catalog.

Writes (all 15 languages):
  locales/course_index.{lang}.json  — id/title/description/subject/subcategory
  locales/courses.{lang}.json       — same + quiz, lessons stripped

Idempotent. Safe to re-run after `export_ios_content_for_android.py`.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALES = ROOT / "android" / "app" / "src" / "main" / "assets" / "locales"

LANGS = [
    "fr", "en", "es", "de", "pt", "it",
    "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs",
]

INDEX_KEYS = ("id", "title", "description", "subject", "subcategory")


def _dump(path: Path, data) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )


def slim_one(lang: str) -> tuple[int, int, int]:
    src = LOCALES / f"courses.{lang}.json"
    if not src.is_file():
        raise FileNotFoundError(src)
    courses = json.loads(src.read_text(encoding="utf-8"))
    if not isinstance(courses, list):
        raise ValueError(f"{src.name} is not a list")

    index = []
    slim = []
    quiz_total = 0
    for course in courses:
        if not isinstance(course, dict) or not course.get("id"):
            continue
        entry = {key: course.get(key, "") for key in INDEX_KEYS}
        index.append(entry)
        quiz = course.get("quiz") or []
        quiz_total += len(quiz)
        slim.append({**entry, "quiz": quiz})

    _dump(LOCALES / f"course_index.{lang}.json", index)
    _dump(src, slim)
    return len(slim), quiz_total, src.stat().st_size


def slim_locale_catalogs() -> list[str]:
    LOCALES.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    for lang in LANGS:
        count, quiz_total, size = slim_one(lang)
        msg = f"  {lang}: {count} courses, {quiz_total} quiz items, {size / 1024:.0f} KB"
        print(msg)
        lines.append(msg)
    return lines


def main() -> int:
    print("=== Slim Android course catalogs ===")
    slim_locale_catalogs()
    print("errors: none")
    return 0


if __name__ == "__main__":
    sys.exit(main())
