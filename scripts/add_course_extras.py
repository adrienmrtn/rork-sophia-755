#!/usr/bin/env python3
"""Merge the glossary and the quiz written alongside a course into the shared tables.

When a course is written (or rewritten) by hand, its glossary entries and its quiz are
produced next to it, in one "extras" file per course, so that several courses can be
written in parallel without racing on the big shared files. This script folds those
files into the places the apps read:

  * French glossary  -> ``ios/Sophia/Services/GlossaryData.swift`` (key ``"<FR title>|<term>"``)
  * other glossaries -> ``ios/Sophia/Resources/Locales/glossary.<lang>.json`` (key ``"<id>|<term>"``)
  * quizzes          -> ``content/locales/<lang>/quizzes_v2.json`` (one block per course)

Run ``add_courses_to_catalog.py`` afterwards: it copies the quiz into the catalogs and
the French glossary onto Android, and ``export_ios_content_for_android.py`` copies the
other glossaries.

Extras file (``<anything>.json``)::

    {
      "courseId": "course_244_...",
      "glossary": {
        "fr": [{"term": "sabbat", "displayTerm": "sabbat", "classification": "concept", "explanation": "..."}],
        "en": [{"term": "sabbath", "classification": "concept", "explanation": "..."}]
      },
      "quiz": {"fr": [ ...questions... ], "en": [ ...questions... ]}
    }

``term`` is the text inside ``[[...]]`` in the course; ``displayTerm`` defaults to it.
Question ids are renumbered ``<courseId>_q<n>``. Existing entries with the same key are
replaced, so the script is idempotent.

Usage:
    python scripts/add_course_extras.py path/to/extras/*.json
    python scripts/add_course_extras.py --check path/to/extras/*.json   # validate only
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from add_courses_to_catalog import (  # noqa: E402
    GLOSSARY_ENTRY_RE,
    GLOSSARY_SWIFT,
    LOCALES,
    QUIZ_KEYS,
    QUIZZES,
    dump_json,
    load_json,
    swift_string,
    swift_unescape,
)

ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "content" / "courses"
CLASSIFICATIONS = {"referenceHistorique", "concept", "evenementConnexe", "personnage", "lieuInstitution"}
QUIZ_TYPES = {"mcq", "trueFalse", "chronological", "numericSlider", "percentageSlider"}
GLOSSARY_REF_RE = re.compile(r"\[\[([^\]]+)\]\]")


class ExtrasError(Exception):
    pass


# --- validation ----------------------------------------------------------------------

def glossary_refs(course: dict) -> set[str]:
    refs: set[str] = set()
    for section in course.get("sections", []):
        for block in section.get("blocks", []):
            for key in ("text", "caption", "hook"):
                value = block.get(key)
                if isinstance(value, str):
                    refs.update(m.strip() for m in GLOSSARY_REF_RE.findall(value))
    hook = (course.get("hero") or {}).get("hook")
    if isinstance(hook, str):
        refs.update(m.strip() for m in GLOSSARY_REF_RE.findall(hook))
    return refs


def validate_question(question: dict, where: str) -> None:
    qtype = question.get("type", "mcq")
    if qtype not in QUIZ_TYPES:
        raise ExtrasError(f"{where}: unknown type {qtype!r}")
    for key in ("question", "explanation"):
        if not isinstance(question.get(key), str) or not question[key].strip():
            raise ExtrasError(f"{where}: missing '{key}'")
    if qtype in {"mcq", "trueFalse"}:
        options = question.get("options")
        if not isinstance(options, list) or not all(isinstance(o, str) and o.strip() for o in options):
            raise ExtrasError(f"{where}: 'options' must be a list of strings")
        if qtype == "mcq" and not 3 <= len(options) <= 5:
            raise ExtrasError(f"{where}: mcq needs 3 to 5 options, got {len(options)}")
        if qtype == "trueFalse" and len(options) != 2:
            raise ExtrasError(f"{where}: trueFalse needs exactly 2 options")
        index = question.get("correctIndex")
        if not isinstance(index, int) or not 0 <= index < len(options):
            raise ExtrasError(f"{where}: 'correctIndex' out of range")
        if qtype == "mcq" and index != 0:
            raise ExtrasError(f"{where}: mcq keeps the right answer at index 0 (shuffled on display)")
    elif qtype == "chronological":
        items = question.get("items")
        if not isinstance(items, list) or not 3 <= len(items) <= 5:
            raise ExtrasError(f"{where}: chronological needs 3 to 5 'items'")
        if any(re.search(r"\(\s*\d{3,4}\s*\)", item) for item in items):
            raise ExtrasError(f"{where}: a chronological item must not carry its date")
    else:
        for key in ("correctValue", "sliderMin", "sliderMax", "tolerance"):
            if not isinstance(question.get(key), (int, float)):
                raise ExtrasError(f"{where}: missing numeric '{key}'")
        if not question["sliderMin"] <= question["correctValue"] <= question["sliderMax"]:
            raise ExtrasError(f"{where}: 'correctValue' outside the slider range")
        if qtype == "percentageSlider" and (question["sliderMin"], question["sliderMax"]) != (0, 100):
            raise ExtrasError(f"{where}: percentageSlider range is fixed to 0-100")
        question.setdefault("unit", "%" if qtype == "percentageSlider" else "")


def validate_extras(extras: dict, path: Path) -> dict:
    course_id = extras.get("courseId")
    if not isinstance(course_id, str) or not course_id:
        raise ExtrasError(f"{path.name}: missing 'courseId'")
    glossary = extras.get("glossary") or {}
    quiz = extras.get("quiz") or {}
    courses = {}
    for lang in set(glossary) | set(quiz):
        source = COURSES / lang / f"{course_id}.json"
        if not source.is_file():
            raise ExtrasError(f"{path.name}: no {lang} edition at {source.relative_to(ROOT)}")
        courses[lang] = load_json(source)
    for lang, entries in glossary.items():
        if not isinstance(entries, list):
            raise ExtrasError(f"{path.name}: glossary.{lang} must be a list")
        terms = set()
        for entry in entries:
            term = (entry.get("term") or "").strip()
            if not term:
                raise ExtrasError(f"{path.name}: glossary.{lang} entry without 'term'")
            if entry.get("classification") not in CLASSIFICATIONS:
                raise ExtrasError(
                    f"{path.name}: glossary.{lang} {term!r} has classification "
                    f"{entry.get('classification')!r}, expected one of {sorted(CLASSIFICATIONS)}"
                )
            if not isinstance(entry.get("explanation"), str) or not entry["explanation"].strip():
                raise ExtrasError(f"{path.name}: glossary.{lang} {term!r} has no explanation")
            entry["term"] = term
            entry["displayTerm"] = (entry.get("displayTerm") or term).strip()
            terms.add(term)
        missing = glossary_refs(courses[lang]) - terms
        if missing:
            raise ExtrasError(f"{path.name}: [[...]] in the {lang} course without a glossary entry: {sorted(missing)}")
    for lang, questions in quiz.items():
        if not isinstance(questions, list) or not 6 <= len(questions) <= 10:
            raise ExtrasError(f"{path.name}: quiz.{lang} needs 6 to 10 questions")
        for number, question in enumerate(questions, start=1):
            question["id"] = f"{course_id}_q{number}"
            question.setdefault("type", "mcq")
            validate_question(question, f"{path.name} quiz.{lang} q{number}")
        # Same key order as the catalogs, so the two copies compare equal byte for byte.
        quiz[lang] = [
            {key: question[key] for key in QUIZ_KEYS if key in question} for question in questions
        ]
    extras["_courses"] = courses
    return extras


# --- French glossary (Swift) ---------------------------------------------------------

def swift_entry_line(title: str, entry: dict) -> str:
    return (
        f"        {swift_string(title + '|' + entry['term'])}: GlossaryEntry("
        f"displayTerm: {swift_string(entry['displayTerm'])}, "
        f"classification: .{entry['classification']}, "
        f"explanation: {swift_string(entry['explanation'])})"
    )


def upsert_swift_glossary(new_entries: dict[str, str]) -> tuple[int, int]:
    """new_entries maps ``"<title>|<term>"`` to the full Swift line (without trailing comma)."""
    source = GLOSSARY_SWIFT.read_text(encoding="utf-8")
    start = source.index("static let entries: [String: GlossaryEntry] = [")
    start = source.index("\n", start) + 1
    end = source.index("\n    ]", start)
    head, body, tail = source[:start], source[start:end], source[end:]
    lines = [line.rstrip().rstrip(",") for line in body.split("\n") if line.strip()]
    positions: dict[str, int] = {}
    for index, line in enumerate(lines):
        match = GLOSSARY_ENTRY_RE.search(line)
        if match:
            positions[swift_unescape(match.group(1)) + "|" + swift_unescape(match.group(2))] = index
    replaced = added = 0
    for key, line in new_entries.items():
        if key in positions:
            lines[positions[key]] = line
            replaced += 1
        else:
            positions[key] = len(lines)
            lines.append(line)
            added += 1
    GLOSSARY_SWIFT.write_text(head + ",\n".join(lines) + tail, encoding="utf-8")
    return added, replaced


# --- main ----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="+", type=Path, help="Extras JSON files")
    parser.add_argument("--check", action="store_true", help="Validate only, write nothing")
    args = parser.parse_args()

    bundles = []
    failures = 0
    for path in args.files:
        try:
            bundles.append(validate_extras(load_json(path), path))
        except (ExtrasError, json.JSONDecodeError, KeyError) as error:
            print(f"  INVALID {error}", file=sys.stderr)
            failures += 1
    if failures:
        print(f"{failures} invalid extras file(s), nothing written.", file=sys.stderr)
        return 1
    if args.check:
        print(f"{len(bundles)} extras file(s) valid.")
        return 0

    swift_entries: dict[str, str] = {}
    json_glossaries: dict[str, dict[str, dict]] = {}
    quizzes: dict[str, dict[str, list]] = {}
    for extras in bundles:
        course_id = extras["courseId"]
        for lang, entries in (extras.get("glossary") or {}).items():
            if lang == "fr":
                title = extras["_courses"]["fr"]["title"]
                for entry in entries:
                    swift_entries[f"{title}|{entry['term']}"] = swift_entry_line(title, entry)
            else:
                for entry in entries:
                    json_glossaries.setdefault(lang, {})[f"{course_id}|{entry['term']}"] = {
                        "displayTerm": entry["displayTerm"],
                        "classification": entry["classification"],
                        "explanation": entry["explanation"],
                    }
        for lang, questions in (extras.get("quiz") or {}).items():
            quizzes.setdefault(lang, {})[course_id] = questions

    if swift_entries:
        added, replaced = upsert_swift_glossary(swift_entries)
        print(f"GlossaryData.swift: {added} added, {replaced} replaced")
    for lang, entries in json_glossaries.items():
        path = LOCALES / f"glossary.{lang}.json"
        glossary = load_json(path) if path.is_file() else {}
        before = len(glossary)
        glossary.update(entries)
        dump_json(path, glossary)
        print(f"glossary.{lang}.json: {len(glossary) - before} added, {len(entries) - (len(glossary) - before)} replaced")
    for lang, by_course in quizzes.items():
        path = QUIZZES / lang / "quizzes_v2.json"
        blocks = load_json(path) if path.is_file() else []
        index = {block["courseId"]: position for position, block in enumerate(blocks)}
        added = replaced = 0
        for course_id, questions in by_course.items():
            block = {"courseId": course_id, "quiz": questions}
            if course_id in index:
                blocks[index[course_id]] = block
                replaced += 1
            else:
                index[course_id] = len(blocks)
                blocks.append(block)
                added += 1
        dump_json(path, blocks)
        print(f"quizzes_v2.json ({lang}): {added} added, {replaced} replaced")
    return 0


if __name__ == "__main__":
    sys.exit(main())
