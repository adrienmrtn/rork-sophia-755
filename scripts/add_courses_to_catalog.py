#!/usr/bin/env python3
"""Register structured (V2) courses in the legacy catalogs the apps list courses from.

A course only exists for the reader once it appears in the catalogs: `content/courses`
holds the body, but the list of courses, their lesson ids and their quiz still live in

  * ``ios/Sophia/Services/CourseData.swift``            (French, generated Swift)
  * ``ios/Sophia/Resources/Locales/courses.<lang>.json`` (every other language)
  * ``ios/Sophia/Utilities/CourseImageMap.swift``       (home-card cover, iOS)
  * ``android/app/src/main/assets/course_image_map.json`` (home-card cover, Android)
  * ``android/app/src/main/assets/locales/courses.fr.json`` and ``glossary.fr.json``
    (French on Android: iOS keeps French in Swift, so the export script has nothing to
    copy and the French entries are written here, keyed by course id like every other
    language; ``export_ios_content_for_android.py`` then derives ``course_index.fr.json``)

This script derives all of that from the V2 source of the course: the lesson ids and
titles are the section ids and titles, the legacy lesson body is the section's prose
(never rendered while the V2 resource exists, kept as a fallback), the cover is the hero
image, and the quiz comes from ``content/locales/<lang>/quizzes_v2.json``.

It is idempotent: an entry that already exists (a course being replaced) is rewritten
in place; a new one is appended. Languages without a V2 file for the course are left
alone, so the course stays absent from those catalogs until its edition exists.

Usage:
    python scripts/add_courses_to_catalog.py course_241_* course_242_*
    python scripts/add_courses_to_catalog.py --lang en course_241_*   # one catalog only
    python scripts/add_courses_to_catalog.py --dry-run course_241_*
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

from i18n_languages import ALL_CONTENT_LANGS

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content" / "courses"
QUIZZES = ROOT / "content" / "locales"
COURSE_DATA = ROOT / "ios" / "Sophia" / "Services" / "CourseData.swift"
LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
IMAGE_MAP_SWIFT = ROOT / "ios" / "Sophia" / "Utilities" / "CourseImageMap.swift"
IMAGE_MAP_ANDROID = ROOT / "android" / "app" / "src" / "main" / "assets" / "course_image_map.json"
ANDROID_LOCALES = ROOT / "android" / "app" / "src" / "main" / "assets" / "locales"
GLOSSARY_SWIFT = ROOT / "ios" / "Sophia" / "Services" / "GlossaryData.swift"

GLOSSARY_ENTRY_RE = re.compile(
    r'"((?:[^"\\]|\\.)*)\|((?:[^"\\]|\\.)*)":\s*GlossaryEntry\('
    r'displayTerm:\s*"((?:[^"\\]|\\.)*)",\s*'
    r"classification:\s*\.(\w+),\s*"
    r'explanation:\s*"((?:[^"\\]|\\.)*)"\)'
)

QUIZ_KEYS = (
    "id", "type", "question", "explanation", "options", "correctIndex",
    "items", "correctValue", "sliderMin", "sliderMax", "tolerance", "unit",
)


# --- helpers ----------------------------------------------------------------------

def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def dump_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def swift_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def swift_number(value) -> str:
    number = float(value)
    return str(int(number)) if number.is_integer() else repr(number)


def legacy_lesson_content(section: dict) -> str:
    """The section's prose as one legacy string: paragraphs separated by blank lines,
    glossary marks in the legacy ``<Term>`` form."""
    parts: list[str] = []
    for block in section.get("blocks", []):
        if block.get("type") in {"heading", "paragraph"} and block.get("text"):
            parts.append(block["text"])
    text = "\n\n".join(parts)
    return re.sub(r"\[\[(.+?)\]\]", r"<\1>", text)


def quiz_for(lang: str, course_id: str) -> list[dict]:
    path = QUIZZES / lang / "quizzes_v2.json"
    if not path.is_file():
        return []
    for block in load_json(path):
        if block.get("courseId") == course_id:
            return [{key: q[key] for key in QUIZ_KEYS if key in q} for q in block["quiz"]]
    return []


def matching_courses(patterns: list[str]) -> list[Path]:
    sources = sorted((CONTENT / "fr").glob("*.json"))
    if patterns:
        sources = [s for s in sources if any(fnmatch.fnmatch(s.stem, p) for p in patterns)]
    return sources


# --- French: CourseData.swift --------------------------------------------------------

def swift_quiz_question(question: dict) -> str:
    qtype = question.get("type", "mcq")
    fields = [f"id: {swift_string(question['id'])}"]
    if qtype != "mcq":
        fields.append(f"type: .{qtype}")
    fields.append(f"question: {swift_string(question['question'])}")
    if "options" in question:
        options = ", ".join(swift_string(option) for option in question["options"])
        fields.append(f"options: [{options}]")
    if "correctIndex" in question:
        fields.append(f"correctIndex: {int(question['correctIndex'])}")
    fields.append(f"explanation: {swift_string(question.get('explanation', ''))}")
    if "items" in question:
        items = ", ".join(swift_string(item) for item in question["items"])
        fields.append(f"items: [{items}]")
    for key in ("correctValue", "sliderMin", "sliderMax", "tolerance"):
        if key in question and question[key] is not None:
            fields.append(f"{key}: {swift_number(question[key])}")
    if "unit" in question and question["unit"] is not None:
        fields.append(f"unit: {swift_string(question['unit'])}")
    return "        QuizQuestion(" + ", ".join(fields) + ")"


def swift_course_block(course: dict, quiz: list[dict]) -> str:
    lessons = "\n".join(
        "                LessonPage(id: {id}, title: {title}, content: {content}),".format(
            id=swift_string(section["id"]),
            title=swift_string(section["title"]),
            content=swift_string(legacy_lesson_content(section)),
        )
        for section in course["sections"]
    )
    quiz_lines = ",\n".join(swift_quiz_question(q) for q in quiz)
    return (
        "        Course(\n"
        f"            id: {swift_string(course['id'])},\n"
        f"            title: {swift_string(course['title'])},\n"
        f"            description: {swift_string(course.get('description', ''))},\n"
        f"            subject: .{course['subject']},\n"
        f"            subcategory: {swift_string(course.get('subcategory', ''))},\n"
        "            lessons: [\n"
        f"{lessons}\n"
        "            ],\n"
        "            quiz: [\n"
        f"{quiz_lines}\n"
        "    ]\n"
        "        )"
    )


def upsert_swift_course(source: str, course_id: str, block: str) -> tuple[str, str]:
    """Replace the existing `Course(` entry for `course_id`, or append one. Returns (text, action)."""
    start_marker = f'        Course(\n            id: "{course_id}",'
    start = source.find(start_marker)
    if start != -1:
        end = source.find("\n        )", start)
        if end == -1:
            raise ValueError(f"unterminated Course block for {course_id}")
        end += len("\n        )")
        return source[:start] + block + source[end:], "updated"
    closing = "\n    ]\n}\n"
    if not source.endswith(closing):
        raise ValueError("CourseData.swift does not end with the expected array/enum closing")
    body = source[: -len(closing)].rstrip()
    return body + ",\n" + block + closing, "added"


# --- other languages: courses.<lang>.json -------------------------------------------

def catalog_entry(course: dict, quiz: list[dict]) -> dict:
    return {
        "id": course["id"],
        "title": course["title"],
        "description": course.get("description", ""),
        "subject": course["subject"],
        "subcategory": course.get("subcategory", ""),
        "lessons": [
            {"id": s["id"], "title": s["title"], "content": legacy_lesson_content(s)}
            for s in course["sections"]
        ],
        "quiz": quiz,
    }


def upsert_catalog(catalog: list[dict], entry: dict) -> str:
    for index, existing in enumerate(catalog):
        if existing.get("id") == entry["id"]:
            catalog[index] = entry
            return "updated"
    catalog.append(entry)
    return "added"


# --- French on Android ---------------------------------------------------------------

def swift_unescape(value: str) -> str:
    return value.replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")


def french_glossary_for(title: str) -> dict[str, dict]:
    """The French glossary entries of one course, from the generated Swift table."""
    entries: dict[str, dict] = {}
    for raw_title, raw_term, display, classification, explanation in GLOSSARY_ENTRY_RE.findall(
        GLOSSARY_SWIFT.read_text(encoding="utf-8")
    ):
        if swift_unescape(raw_title) != title:
            continue
        entries[swift_unescape(raw_term)] = {
            "displayTerm": swift_unescape(display),
            "classification": classification,
            "explanation": swift_unescape(explanation),
        }
    return entries


def upsert_android_french(course: dict, quiz: list[dict]) -> str:
    """Android's French catalog is slim (no lessons) and its glossary is keyed by course id."""
    catalog_path = ANDROID_LOCALES / "courses.fr.json"
    glossary_path = ANDROID_LOCALES / "glossary.fr.json"
    catalog = load_json(catalog_path)
    entry = {
        "id": course["id"],
        "title": course["title"],
        "description": course.get("description", ""),
        "subject": course["subject"],
        "subcategory": course.get("subcategory", ""),
        "quiz": quiz,
    }
    action = upsert_catalog(catalog, entry)
    catalog_path.write_text(
        json.dumps(catalog, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8"
    )
    glossary = load_json(glossary_path)
    for term, value in french_glossary_for(course["title"]).items():
        glossary[f"{course['id']}|{term}"] = value
    dump_json(glossary_path, glossary)
    return action


# --- covers -------------------------------------------------------------------------

def upsert_swift_image_map(source: str, course_id: str, slug: str) -> tuple[str, str]:
    line = f'        "{course_id}": "{slug}",'
    pattern = re.compile(rf'^        "{re.escape(course_id)}": "[^"]*",\n', re.M)
    if pattern.search(source):
        return pattern.sub(line + "\n", source), "updated"
    closing = "    ]\n}\n"
    if not source.endswith(closing):
        raise ValueError("CourseImageMap.swift does not end with the expected closing")
    return source[: -len(closing)] + line + "\n" + closing, "added"


# --- main -----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("patterns", nargs="+", help="Course id glob(s), e.g. 'course_241_*'")
    parser.add_argument("--lang", action="append", help="Only this catalog language (repeatable)")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    languages = args.lang or list(ALL_CONTENT_LANGS)
    sources = matching_courses(args.patterns)
    if not sources:
        print("No matching course sources.", file=sys.stderr)
        return 1

    swift_source = COURSE_DATA.read_text(encoding="utf-8")
    image_map_swift = IMAGE_MAP_SWIFT.read_text(encoding="utf-8")
    image_map_android = load_json(IMAGE_MAP_ANDROID)
    catalogs: dict[str, list[dict]] = {}
    changed_catalogs: set[str] = set()

    for source in sources:
        french = load_json(source)
        course_id = french["id"]
        hero = (french.get("hero") or {}).get("image")

        if "fr" in languages:
            french_quiz = quiz_for("fr", course_id)
            block = swift_course_block(french, french_quiz)
            swift_source, action = upsert_swift_course(swift_source, course_id, block)
            print(f"  fr  {action:8} {course_id}")
            if not args.dry_run:
                action = upsert_android_french(french, french_quiz)
                print(f"  fr  {action:8} {course_id} (android)")

        for lang in languages:
            if lang == "fr":
                continue
            translated = CONTENT / lang / f"{course_id}.json"
            if not translated.is_file():
                continue
            if lang not in catalogs:
                catalogs[lang] = load_json(LOCALES / f"courses.{lang}.json")
            entry = catalog_entry(load_json(translated), quiz_for(lang, course_id))
            action = upsert_catalog(catalogs[lang], entry)
            changed_catalogs.add(lang)
            print(f"  {lang}  {action:8} {course_id}")

        if hero:
            image_map_swift, action = upsert_swift_image_map(image_map_swift, course_id, hero)
            image_map_android[course_id] = hero
            print(f"  cover {action:6} {course_id} -> {hero}")

    if args.dry_run:
        print("dry run: nothing written")
        return 0

    if "fr" in languages:
        COURSE_DATA.write_text(swift_source, encoding="utf-8")
    for lang in changed_catalogs:
        dump_json(LOCALES / f"courses.{lang}.json", catalogs[lang])
    IMAGE_MAP_SWIFT.write_text(image_map_swift, encoding="utf-8")
    dump_json(IMAGE_MAP_ANDROID, dict(sorted(image_map_android.items(), key=lambda kv: course_sort_key(kv[0]))))
    print(f"Registered {len(sources)} course(s).")
    return 0


def course_sort_key(course_id: str) -> tuple[int, str]:
    match = re.match(r"course_(\d+)_", course_id)
    return (int(match.group(1)) if match else 10**9, course_id)


if __name__ == "__main__":
    raise SystemExit(main())
