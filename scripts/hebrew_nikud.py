#!/usr/bin/env python3
"""Strip the vowel points from the Hebrew pack.

The engine answers short strings in fully pointed Hebrew — ``בַּיִת`` for a Home
tab, ``שֶׁקֶר`` for False. Nikud belongs in scripture, poetry and children's
books; a modern interface writes plain consonantal text, and the points also
widen the glyphs enough to break the tighter chrome budgets.

Removing them is lossless for our purposes: the letters are unchanged and the
reader supplies the vowels, exactly as every Hebrew interface expects.

Usage:
    python scripts/hebrew_nikud.py --check
    python scripts/hebrew_nikud.py
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

#: Hebrew points and cantillation. U+05BE (maqaf), U+05C0 (paseq), U+05C3
#: (sof pasuq) and U+05F3-U+05F4 (geresh, gershayim) are punctuation, not
#: points, so they are deliberately outside these ranges.
NIKUD = re.compile(r"[֑-ׇֽֿׁׂׅׄ]")


def strip(text: str) -> str:
    return NIKUD.sub("", text)


def targets() -> list[Path]:
    candidates = [
        ROOT / "content" / "locales" / "he" / "ui_strings.json",
        ROOT / "android" / "app" / "src" / "main" / "assets" / "strings" / "he.json",
        ROOT / "content" / "locales" / "he" / "quizzes_v2.json",
        ROOT / "content" / "locales" / "he" / "legal.json",
        ROOT / "ios" / "Sophia" / "Resources" / "Locales" / "courses.he.json",
        ROOT / "ios" / "Sophia" / "Resources" / "Locales" / "glossary.he.json",
        ROOT / "ios" / "Sophia" / "Resources" / "Locales" / "collections.he.json",
    ]
    candidates += sorted((ROOT / "content" / "courses" / "he").glob("*.json"))
    candidates += sorted(
        (ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2").glob("*.he.json")
    )
    android = ROOT / "android" / "app" / "src" / "main" / "assets"
    candidates += sorted((android / "courses_v2" / "he").glob("*.json"))
    candidates += [android / "locales" / f"{kind}.he.json"
                   for kind in ("courses", "course_index", "collections", "glossary")]
    return [p for p in candidates if p.is_file()]


def walk(node):
    """Return (value, changed count), stripping points from every string."""
    if isinstance(node, str):
        out = strip(node)
        return out, int(out != node)
    if isinstance(node, list):
        total, result = 0, []
        for item in node:
            value, n = walk(item)
            result.append(value)
            total += n
        return result, total
    if isinstance(node, dict):
        total, result = 0, {}
        for key, item in node.items():
            value, n = walk(item)
            # Glossary keys are "courseId|term" lookups matched against the body,
            # so they take the same treatment as the text.
            result[strip(key)] = value
            total += n + int(strip(key) != key)
        return result, total
    return node, 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    args = parser.parse_args()

    total = 0
    files = 0
    for path in targets():
        data = json.loads(path.read_text(encoding="utf-8"))
        updated, changed = walk(data)
        if not changed:
            continue
        total += changed
        files += 1
        print(f"  {path.relative_to(ROOT)}: {changed} string(s)")
        if not args.check:
            indent = 2 if path.read_text(encoding="utf-8").startswith("{\n  ") else None
            path.write_text(
                json.dumps(updated, ensure_ascii=False, indent=indent) + "\n",
                encoding="utf-8",
            )
    verb = "would strip" if args.check else "stripped"
    print(f"{verb} vowel points from {total} string(s) in {files} file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
