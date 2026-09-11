#!/usr/bin/env python3
"""Strip zero-width artifacts from translated catalogs, caches and v2 content.

The bulk MT endpoint sprinkles U+200B pairs into its output (see
``mt_backend._clean``). ``mt_backend`` now scrubs on the way out, but anything
translated before that — and the handful already sitting in the English source —
still carries them. Idempotent: run it as often as you like.

Usage:
    python scripts/scrub_mt_artifacts.py [--check] [--lang da,nb,...]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from i18n_languages import ALL_CONTENT_LANGS

ROOT = Path(__file__).resolve().parents[1]
INVISIBLE = re.compile("[​‌­﻿⁠]")


def clean(text: str) -> str:
    if not INVISIBLE.search(text):
        return text
    return re.sub(r"[ \t]{2,}", " ", INVISIBLE.sub("", text)).strip()


def walk(node):
    """Returns (cleaned_node, number_of_strings_changed)."""
    if isinstance(node, str):
        out = clean(node)
        return out, int(out != node)
    if isinstance(node, list):
        total = 0
        result = []
        for item in node:
            value, n = walk(item)
            result.append(value)
            total += n
        return result, total
    if isinstance(node, dict):
        total = 0
        result = {}
        for key, item in node.items():
            new_key = clean(key) if isinstance(key, str) else key
            total += int(new_key != key)
            value, n = walk(item)
            result[new_key] = value
            total += n
        return result, total
    return node, 0


def targets(langs: list[str]) -> list[Path]:
    paths: list[Path] = []
    locales = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
    v2_bundle = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"
    for lang in langs:
        for kind in ("courses", "glossary", "collections"):
            paths.append(locales / f"{kind}.{lang}.json")
        paths.extend(sorted((ROOT / "content" / "courses" / lang).glob("*.json")))
        paths.extend(sorted(v2_bundle.glob(f"*.{lang}.json")))
        paths.append(ROOT / "content" / "locales" / lang / "quizzes_v2.json")
        paths.append(ROOT / "content" / "locales" / "_catalog_mt_cache" / f"{lang}.json")
        paths.append(ROOT / "content" / "locales" / "_v2_mt_cache" / f"{lang}.json")
        paths.append(ROOT / "content" / "locales" / "_quiz_v2_mt_cache" / f"{lang}.json")
        paths.append(
            ROOT / "android" / "app" / "src" / "main" / "assets" / "locales" / f"courses.{lang}.json"
        )
        paths.append(
            ROOT / "android" / "app" / "src" / "main" / "assets" / "locales" / f"glossary.{lang}.json"
        )
    return [p for p in paths if p.is_file()]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--lang", default=",".join(ALL_CONTENT_LANGS))
    args = parser.parse_args()

    langs = [c.strip() for c in args.lang.split(",") if c.strip()]
    dirty_files = 0
    dirty_strings = 0
    for path in targets(langs):
        raw = path.read_text(encoding="utf-8")
        if not INVISIBLE.search(raw):
            continue
        data = json.loads(raw)
        cleaned, n = walk(data)
        dirty_files += 1
        dirty_strings += n
        print(f"  {path.relative_to(ROOT)}: {n} strings")
        if args.check:
            continue
        # Keep each file's own shape: minified stays minified.
        minified = "\n" not in raw.strip()[:4000]
        text = json.dumps(
            cleaned,
            ensure_ascii=False,
            separators=(",", ":") if minified else None,
            indent=None if minified else 2,
        )
        path.write_text(text + ("" if minified else "\n"), encoding="utf-8")

    verb = "would clean" if args.check else "cleaned"
    print(f"{verb} {dirty_strings} strings in {dirty_files} files")
    return 1 if (args.check and dirty_files) else 0


if __name__ == "__main__":
    raise SystemExit(main())
