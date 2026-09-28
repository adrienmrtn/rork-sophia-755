#!/usr/bin/env python3
"""Compile structured ("v2") course content into bundled iOS resources.

This replaces the legacy Excel pipeline. Source of truth is one JSON file per
course under ``content/courses/fr/`` (block format, see ``content/CHARTE_REFONTE.md``).

For each source file it:
  1. Validates the block schema.
  2. Emits the bundled French resource ``ios/Sophia/Resources/CoursesV2/<id>.fr.json``.
  3. (Optional) copies committed translations from ``content/courses/<lang>/`` into
     ``ios/Sophia/Resources/CoursesV2/<id>.<lang>.json`` when they exist.
  4. Emits ``ios/Sophia/Resources/authors.json`` from ``content/authors.json``, each
     author carrying the ids of the courses that name it in ``author`` (so the app can
     list "other courses by this professor" without decoding every course).

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
AUTHORS_SOURCE = ROOT / "content" / "authors.json"
IMAGE_DIRS = (ROOT / "ios" / "Sophia" / "CourseImages", ROOT / "content" / "images")
ALIASES_SWIFT = ROOT / "ios" / "Sophia" / "Utilities" / "CourseImageAliases.swift"
AUTHORS_BUNDLE = ROOT / "ios" / "Sophia" / "Resources" / "authors.json"

LANGUAGES = ALL_CONTENT_LANGS
BLOCK_TYPES = {"heading", "paragraph", "image", "timeline", "funFact", "takeaway", "quote"}


class ValidationError(Exception):
    pass


def load_authors() -> dict[str, dict]:
    """Authors keyed by slug, or an empty dict when the file does not exist yet."""
    if not AUTHORS_SOURCE.is_file():
        return {}
    data = json.loads(AUTHORS_SOURCE.read_text(encoding="utf-8"))
    authors = data.get("authors", data) if isinstance(data, dict) else data
    return {author["slug"]: author for author in authors}


def validate_course(data: dict, origin: Path, authors: dict[str, dict] | None = None) -> None:
    def require(condition: bool, message: str) -> None:
        if not condition:
            raise ValidationError(f"{origin.name}: {message}")

    require(isinstance(data.get("id"), str) and data["id"], "missing 'id'")
    require(isinstance(data.get("title"), str) and data["title"], "missing 'title'")
    require(isinstance(data.get("sections"), list) and data["sections"], "missing 'sections'")

    # Professor-authored courses: `author` names a slug of content/authors.json and
    # `sources` lists the references shown under the course (reference text, optional URL).
    author = data.get("author")
    if author is not None:
        require(isinstance(author, str) and author, "'author' must be a non-empty slug")
        if authors is not None:
            require(author in authors, f"unknown author '{author}' (not in content/authors.json)")
    sources = data.get("sources")
    if sources is not None:
        require(isinstance(sources, list), "'sources' must be a list")
        for index, source in enumerate(sources):
            loc = f"sources[{index}]"
            require(isinstance(source, dict), f"{loc} must be an object")
            require(isinstance(source.get("text"), str) and source["text"].strip(), f"{loc} missing 'text'")
            url = source.get("url")
            require(url is None or (isinstance(url, str) and url.startswith("http")), f"{loc} 'url' must be http(s)")

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


def known_images() -> set[str]:
    """File stems of every course image, plus the slugs the iOS alias table maps to them."""
    stems = {p.stem for folder in IMAGE_DIRS for p in folder.glob("*.jpg")}
    stems |= {p.stem for folder in IMAGE_DIRS for p in folder.glob("*.png")}
    if ALIASES_SWIFT.is_file():
        import re
        for slug, target in re.findall(r'"([^"]+)":\s*"([^"]+)"', ALIASES_SWIFT.read_text(encoding="utf-8")):
            if target in stems:
                stems.add(slug)
    return stems


def missing_images(data: dict, known: set[str]) -> list[str]:
    """Slugs a course references that no folder holds (they render as a placeholder)."""
    refs = []
    hero = (data.get("hero") or {}).get("image")
    if hero:
        refs.append(hero)
    for section in data.get("sections", []):
        for block in section.get("blocks", []):
            if block.get("type") == "image" and block.get("asset"):
                refs.append(block["asset"])
    return [r for r in refs if r not in known and r.lower() not in known]


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

    authors = load_authors()
    known = known_images()
    built = 0
    errors = 0
    for source in sources:
        try:
            data = json.loads(source.read_text(encoding="utf-8"))
            validate_course(data, source, authors)
        except (json.JSONDecodeError, ValidationError) as error:
            print(f"  INVALID {source.name}: {error}", file=sys.stderr)
            errors += 1
            continue

        course_id = data["id"]
        print(f"  OK  {course_id} ({len(data['sections'])} sections)")
        for slug in missing_images(data, known):
            print(f"    image to provide: {slug}")

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
                    validate_course(tdata, translated, authors)
                except (json.JSONDecodeError, ValidationError) as error:
                    print(f"    skip {lang}: {error}", file=sys.stderr)
                    continue
                if write_json(BUNDLE_DIR / f"{course_id}.{lang}.json", tdata):
                    print(f"    + {lang}")

    if errors:
        print(f"\n{errors} course(s) failed validation.", file=sys.stderr)
        return 1

    if authors and not check_only:
        if write_authors_bundle(authors, sorted(fr_dir.glob("*.json"))):
            print("  + authors.json")

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


def write_authors_bundle(authors: dict[str, dict], fr_sources: list[Path]) -> bool:
    """Write the bundled authors file: content/authors.json plus each author's course ids.

    Course ids come from every French source (not only the ones being built), so the
    list is complete whatever pattern the script was run with.
    """
    course_ids: dict[str, list[str]] = {slug: [] for slug in authors}
    for source in fr_sources:
        try:
            data = json.loads(source.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        slug = data.get("author")
        if isinstance(slug, str) and slug in course_ids:
            course_ids[slug].append(data["id"])
    bundle = []
    for slug, author in authors.items():
        entry = {key: value for key, value in author.items() if not key.startswith("_")}
        entry["courseIds"] = sorted(course_ids[slug])
        bundle.append(entry)
    payload = json.dumps({"authors": bundle}, ensure_ascii=False, indent=2) + "\n"
    if AUTHORS_BUNDLE.exists() and AUTHORS_BUNDLE.read_text(encoding="utf-8") == payload:
        return False
    AUTHORS_BUNDLE.write_text(payload, encoding="utf-8")
    return True


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
