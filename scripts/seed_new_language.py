#!/usr/bin/env python3
"""Seed a new app language with the French text, ready for full post-edition.

There is no machine-translation service reachable from the build machines, so a new
language starts as a copy of French on every surface, and the post-edition workflow
(docs/processus-traduction.md, section 3) rewrites every segment: its packs show the
French as both source and current text. The language stays out of NON_FR_LANGS (and
so out of the apps and the gate) until every surface is translated.

What it writes, for each code (only files that do not exist yet):
    content/courses/<lang>/*.json, ios CoursesV2/*.<lang>.json, android courses_v2/<lang>/
    content/locales/<lang>/quizzes_v2.json, legal.json, ui_strings.json
    ios + android locales: courses, glossary, collections (+ android course_index)
    android strings/<lang>.json, legal/<lang>.json
    AppLocalizable.swift: a `<case>` table copied from `french`

usage: seed_new_language.py lt lv ja
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

from i18n_languages import PENDING_LANGS, SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
AND = ROOT / "android" / "app" / "src" / "main" / "assets"
IOS = ROOT / "ios" / "Sophia" / "Resources"
SWIFT = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"


def copy(src: Path, dst: Path) -> int:
    if dst.exists():
        return 0
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)
    return 1


def seed(lang: str) -> dict[str, int]:
    n = {"cours": 0, "fichiers": 0}
    for src in sorted((ROOT / "content" / "courses" / "fr").glob("*.json")):
        n["cours"] += copy(src, ROOT / "content" / "courses" / lang / src.name)
        copy(src, IOS / "CoursesV2" / f"{src.stem}.{lang}.json")
        copy(src, AND / "courses_v2" / lang / src.name)
    for name in ("quizzes_v2.json", "legal.json"):
        n["fichiers"] += copy(ROOT / "content" / "locales" / "fr" / name, ROOT / "content" / "locales" / lang / name)
    # French catalogs live in Swift on iOS; the Android copies are the same data.
    for name in ("courses", "glossary", "collections"):
        src = AND / "locales" / f"{name}.fr.json"
        n["fichiers"] += copy(src, IOS / "Locales" / f"{name}.{lang}.json") + copy(src, AND / "locales" / f"{name}.{lang}.json")
    n["fichiers"] += copy(AND / "locales" / "course_index.fr.json", AND / "locales" / f"course_index.{lang}.json")
    n["fichiers"] += copy(AND / "strings" / "fr.json", AND / "strings" / f"{lang}.json")
    n["fichiers"] += copy(AND / "legal" / "fr.json", AND / "legal" / f"{lang}.json")

    case = SWIFT_CASE_BY_CODE[lang]
    source = SWIFT.read_text(encoding="utf-8")
    if not re.search(r"private static let %s: \[String: String\] = \[" % case, source):
        m = re.search(r"    private static let french: \[String: String\] = \[(.*?)\n    \]\n", source, re.S)
        table = f"\n    // MARK: - {case} (copie du français, à post-éditer)\n\n" \
                f"    private static let {case}: [String: String] = [{m.group(1)}\n    ]\n"
        end = source.rstrip().rfind("}")
        SWIFT.write_text(source[:end].rstrip("\n") + "\n" + table + "}\n", encoding="utf-8")
        n["fichiers"] += 1
    from postedit_i18n import swift_table
    p = ROOT / "content" / "locales" / lang / "ui_strings.json"
    if not p.exists():
        p.write_text(json.dumps(swift_table(case), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return n


if __name__ == "__main__":
    for code in sys.argv[1:]:
        if code not in PENDING_LANGS:
            sys.exit(f"{code} n'est pas dans PENDING_LANGS (scripts/i18n_languages.py)")
        print(code, seed(code))
