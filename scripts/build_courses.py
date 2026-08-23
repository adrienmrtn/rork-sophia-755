#!/usr/bin/env python3
"""Compile structured ("v2") course content into bundled iOS resources.

This replaces the legacy Excel pipeline. Source of truth is one JSON file per
course under ``content/courses/fr/`` (block format, see ``content/CHARTE_REFONTE.md``).

For each source file it:
  1. Validates the block schema.
  2. Emits the bundled French resource ``ios/Sophia/Resources/CoursesV2/<id>.fr.json``.
  3. (Optional) copies committed translations from ``content/courses/<lang>/`` into
     ``ios/Sophia/Resources/CoursesV2/<id>.<lang>.json`` when they exist.

Translations themselves are produced only after the French content of a course is
validated; this script does not machine-translate — it only wires validated files
into the app bundle.

Usage:
    python scripts/build_courses.py            # build every course
    python scripts/build_courses.py course_1_* # build matching course ids
    python scripts/build_courses.py --check     # validate only, write nothing
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import sys
from pathlib import Path

from i18n_languages import ALL_CONTENT_LANGS

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "content" / "courses"
BUNDLE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"

LANGUAGES = ALL_CONTENT_LANGS
BLOCK_TYPES = {"heading", "paragraph", "image", "timeline", "funFact", "takeaway", "quote"}


class ValidationError(Exception):
    pass


def validate_course(data: dict, origin: Path) -> None:
    def require(condition: bool, message: str) -> None:
        if not condition:
            raise ValidationError(f"{origin.name}: {message}")

    require(isinstance(data.get("id"), str) and data["id"], "missing 'id'")
    require(isinstance(data.get("title"), str) and data["title"], "missing 'title'")
    require(isinstance(data.get("sections"), list) and data["sections"], "missing 'sections'")

    for index, section in enumerate(data["sections"]):
        loc = f"section[{index}]"
        require(isinstance(section.get("id"), str) and section["id"], f"{loc} missing 'id'")
        require(isinstance(section.get("title"), str), f"{loc} missing 'title'")
        blocks = section.get("blocks")
        require(isinstance(blocks, list), f"{loc} missing 'blocks'")
        for block_index, block in enumerate(blocks):
            bloc = f"{loc}.blocks[{block_index}]"
            btype = block.get("type")
            require(btype in BLOCK_TYPES, f"{bloc} unknown type '{btype}'")
            if btype in {"heading", "paragraph", "funFact", "takeaway", "quote"}:
                require(isinstance(block.get("text"), str), f"{bloc} missing 'text'")
            if btype == "image":
                require(isinstance(block.get("asset"), str) and block["asset"], f"{bloc} missing 'asset'")
            if btype == "timeline":
                events = block.get("events")
                require(isinstance(events, list) and events, f"{bloc} missing 'events'")
                for event_index, event in enumerate(events):
                    ev = f"{bloc}.events[{event_index}]"
                    require(isinstance(event.get("date"), str), f"{ev} missing 'date'")
                    require(isinstance(event.get("title"), str), f"{ev} missing 'title'")


def write_json(path: Path, data: dict) -> bool:
    """Writes minified JSON. Returns True if the file content changed."""
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    if path.exists() and path.read_text(encoding="utf-8") == payload:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(payload, encoding="utf-8")
    return True


def build(patterns: list[str], check_only: bool) -> int:
    fr_dir = SOURCE_ROOT / "fr"
    if not fr_dir.is_dir():
        print(f"No source directory: {fr_dir}", file=sys.stderr)
        return 1

    sources = sorted(fr_dir.glob("*.json"))
    if patterns:
        sources = [
            s for s in sources
            if any(fnmatch.fnmatch(s.stem, pattern) for pattern in patterns)
        ]

    if not sources:
        print("No matching course sources found.")
        return 0

    built = 0
    errors = 0
    for source in sources:
        try:
            data = json.loads(source.read_text(encoding="utf-8"))
            validate_course(data, source)
        except (json.JSONDecodeError, ValidationError) as error:
            print(f"  INVALID {source.name}: {error}", file=sys.stderr)
            errors += 1
            continue

        course_id = data["id"]
        print(f"  OK  {course_id} ({len(data['sections'])} sections)")

        if check_only:
            continue

        changed = write_json(BUNDLE_DIR / f"{course_id}.fr.json", data)
        if changed:
            built += 1

        # Wire committed translations into the bundle when present.
        for lang in LANGUAGES:
            if lang == "fr":
                continue
            translated = SOURCE_ROOT / lang / f"{course_id}.json"
            if translated.is_file():
                try:
                    tdata = json.loads(translated.read_text(encoding="utf-8"))
                    validate_course(tdata, translated)
                except (json.JSONDecodeError, ValidationError) as error:
                    print(f"    skip {lang}: {error}", file=sys.stderr)
                    continue
                if write_json(BUNDLE_DIR / f"{course_id}.{lang}.json", tdata):
                    print(f"    + {lang}")

    if errors:
        print(f"\n{errors} course(s) failed validation.", file=sys.stderr)
        return 1

    stale = check_bundle_sync(sources)
    if stale:
        print(
            f"\n{stale} CoursesV2 bundle file(s) are stale. "
            "The iOS app loads CoursesV2, not content/courses — run this script.",
            file=sys.stderr,
        )
        return 1

    if check_only:
        print(f"\nValidated {len(sources)} course(s). Bundles are in sync.")
    else:
        print(f"\nBuilt/updated {built} bundle file(s) from {len(sources)} source(s).")
    return 0


def check_bundle_sync(fr_sources: list[Path]) -> int:
    """Count translation (and French) bundles that do not match content/courses.

    iOS renders ``Resources/CoursesV2/<id>.<lang>.json``. Rewriting
    ``content/courses/<lang>`` alone leaves the old glossary-at-end text on device.
    """
    stale = 0
    for source in fr_sources:
        course_id = source.stem
        for lang in LANGUAGES:
            src = SOURCE_ROOT / lang / f"{course_id}.json"
            if not src.is_file():
                continue
            bundle = BUNDLE_DIR / f"{course_id}.{lang}.json"
            if not bundle.is_file():
                print(f"  MISSING {bundle.name}", file=sys.stderr)
                stale += 1
                continue
            if json.loads(src.read_text(encoding="utf-8")) != json.loads(
                bundle.read_text(encoding="utf-8")
            ):
                print(f"  STALE {bundle.name}", file=sys.stderr)
                stale += 1
    return stale


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("patterns", nargs="*", help="Course id glob(s), e.g. 'course_1_*'")
    parser.add_argument("--check", action="store_true", help="Validate only, write nothing")
    args = parser.parse_args()
    return build(args.patterns, args.check)


if __name__ == "__main__":
    raise SystemExit(main())
