#!/usr/bin/env python3
"""Export iOS Swift course / collection / glossary data to Android locale JSON.

Parses:
  - ios/Sophia/Services/CourseData.swift     → courses.fr.json
  - ios/Sophia/Services/CollectionData.swift → collections.fr.json
  - ios/Sophia/Services/GlossaryData.swift   → glossary.fr.json (best-effort)

Also copies existing ios/Sophia/Resources/Locales/* into
android/app/src/main/assets/locales/.
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COURSE_DATA = ROOT / "ios" / "Sophia" / "Services" / "CourseData.swift"
COLLECTION_DATA = ROOT / "ios" / "Sophia" / "Services" / "CollectionData.swift"
GLOSSARY_DATA = ROOT / "ios" / "Sophia" / "Services" / "GlossaryData.swift"
IOS_LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
ANDROID_LOCALES = ROOT / "android" / "app" / "src" / "main" / "assets" / "locales"

SUBJECT_MAP = {
    "histoire": "histoire",
    "sciences": "sciences",
    "litterature": "litterature",
    "art": "art",
    "mythologie": "mythologie",
    "comprendreLeMonde": "comprendreLeMonde",
}

VALID_QUIZ_TYPES = {
    "mcq",
    "trueFalse",
    "chronological",
    "numericSlider",
    "percentageSlider",
}


# ---------------------------------------------------------------------------
# Swift literal / call parsing
# ---------------------------------------------------------------------------


def parse_swift_string(src: str, i: int) -> tuple[str, int]:
    """Parse a Swift string literal starting at src[i] == '\"'."""
    if i >= len(src) or src[i] != '"':
        raise ValueError(f"expected string at {i}: {src[i:i+40]!r}")
    i += 1
    out: list[str] = []
    while i < len(src):
        ch = src[i]
        if ch == "\\":
            if i + 1 >= len(src):
                raise ValueError("unterminated escape")
            nxt = src[i + 1]
            escapes = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}
            out.append(escapes.get(nxt, nxt))
            i += 2
            continue
        if ch == '"':
            return "".join(out), i + 1
        out.append(ch)
        i += 1
    raise ValueError("unterminated string")


def parse_swift_string_array(src: str, i: int) -> tuple[list[str], int]:
    """Parse `[\"a\", \"b\"]` starting at '['."""
    if src[i] != "[":
        raise ValueError(f"expected '[' at {i}")
    i += 1
    items: list[str] = []
    while i < len(src):
        while i < len(src) and src[i] in " \t\n\r,":
            i += 1
        if i < len(src) and src[i] == "]":
            return items, i + 1
        if src[i] != '"':
            raise ValueError(f"expected string in array at {i}: {src[i:i+40]!r}")
        value, i = parse_swift_string(src, i)
        items.append(value)
    raise ValueError("unterminated string array")


def parse_number(src: str, i: int) -> tuple[float | int, int]:
    m = re.match(r"-?\d+(?:\.\d+)?", src[i:])
    if not m:
        raise ValueError(f"expected number at {i}: {src[i:i+20]!r}")
    raw = m.group(0)
    i += len(raw)
    if "." in raw:
        return float(raw), i
    return int(raw), i


def skip_ws_comma(src: str, i: int) -> int:
    while i < len(src) and src[i] in " \t\n\r,":
        i += 1
    return i


def extract_call_body(src: str, start: int, name: str) -> tuple[str, int]:
    """Given index of 'Name(', return (body, index_after_closing_paren)."""
    token = f"{name}("
    if not src.startswith(token, start):
        raise ValueError(f"expected {token!r} at {start}")
    i = start + len(token)
    depth = 1
    in_string = False
    escape = False
    begin = i
    while i < len(src):
        ch = src[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            i += 1
            continue
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return src[begin:i], i + 1
        i += 1
    raise ValueError(f"unterminated {name}(")


def extract_bracket_body(src: str, start: int) -> tuple[str, int]:
    """Given index of '[', return (inner, index_after_closing_bracket)."""
    if src[start] != "[":
        raise ValueError(f"expected '[' at {start}")
    i = start + 1
    depth = 1
    in_string = False
    escape = False
    begin = i
    while i < len(src):
        ch = src[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            i += 1
            continue
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                return src[begin:i], i + 1
        i += 1
    raise ValueError("unterminated [")


def parse_labeled_fields(body: str, *, array_handlers: dict | None = None) -> dict:
    """Parse `key: value, key: value` Swift call args into a dict.

    array_handlers maps field name → callable(body, i) -> (value, new_i)
    for non-string arrays (e.g. lessons / quiz / nested calls).
    """
    array_handlers = array_handlers or {}
    fields: dict = {}
    i = 0
    while True:
        i = skip_ws_comma(body, i)
        if i >= len(body):
            break
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s*:", body[i:])
        if not m:
            raise ValueError(f"expected field at {i}: {body[i:i+80]!r}")
        key = m.group(1)
        i += m.end()
        i = skip_ws_comma(body, i)
        if i >= len(body):
            raise ValueError(f"missing value for {key}")

        if key in array_handlers and body[i] == "[":
            value, i = array_handlers[key](body, i)
            fields[key] = value
        elif body[i] == '"':
            value, i = parse_swift_string(body, i)
            fields[key] = value
        elif body[i] == "[":
            value, i = parse_swift_string_array(body, i)
            fields[key] = value
        elif body.startswith(".", i):
            m2 = re.match(r"\.([A-Za-z_][A-Za-z0-9_]*)", body[i:])
            if not m2:
                raise ValueError(f"bad enum at {i}")
            fields[key] = m2.group(1)
            i += m2.end()
        elif body[i].isdigit() or body[i] == "-":
            num, i = parse_number(body, i)
            fields[key] = num
        else:
            raise ValueError(f"unsupported value for {key} at {i}: {body[i:i+60]!r}")
    return fields


# ---------------------------------------------------------------------------
# Domain parsers
# ---------------------------------------------------------------------------


def parse_lesson_page(body: str) -> dict:
    fields = parse_labeled_fields(body)
    return {
        "id": fields["id"],
        "title": fields["title"],
        "content": fields["content"],
    }


def parse_quiz_question(body: str) -> dict:
    raw = parse_labeled_fields(body)
    qtype = raw.get("type") or "mcq"
    if qtype not in VALID_QUIZ_TYPES:
        raise ValueError(f"unknown quiz type {qtype!r} on {raw.get('id')}")
    out: dict = {
        "id": raw["id"],
        "type": qtype,
        "question": raw["question"],
        "explanation": raw.get("explanation") or "",
    }
    if "options" in raw:
        out["options"] = list(raw["options"])
    if "correctIndex" in raw:
        out["correctIndex"] = int(raw["correctIndex"])
    if "items" in raw:
        out["items"] = list(raw["items"])
    if "correctValue" in raw:
        out["correctValue"] = raw["correctValue"]
    if "sliderMin" in raw:
        out["sliderMin"] = raw["sliderMin"]
    if "sliderMax" in raw:
        out["sliderMax"] = raw["sliderMax"]
    if "tolerance" in raw:
        out["tolerance"] = raw["tolerance"]
    if "unit" in raw:
        out["unit"] = raw["unit"]
    return out


def parse_call_array(src: str, i: int, name: str, parser) -> tuple[list, int]:
    """Parse `[Name(...), Name(...)]` starting at '['."""
    inner, end = extract_bracket_body(src, i)
    items: list = []
    j = 0
    while True:
        j = skip_ws_comma(inner, j)
        if j >= len(inner):
            break
        token = f"{name}("
        idx = inner.find(token, j)
        if idx < 0 or idx != j:
            # allow only whitespace leftovers
            raise ValueError(f"expected {token!r} at {j}: {inner[j:j+60]!r}")
        body, after = extract_call_body(inner, idx, name)
        items.append(parser(body))
        j = after
    return items, end


def parse_course(body: str) -> dict:
    def lessons_handler(src: str, i: int):
        return parse_call_array(src, i, "LessonPage", parse_lesson_page)

    def quiz_handler(src: str, i: int):
        return parse_call_array(src, i, "QuizQuestion", parse_quiz_question)

    fields = parse_labeled_fields(
        body,
        array_handlers={"lessons": lessons_handler, "quiz": quiz_handler},
    )
    subject_raw = fields["subject"]
    if subject_raw not in SUBJECT_MAP:
        raise ValueError(f"unknown subject .{subject_raw} on course {fields.get('id')}")
    return {
        "id": fields["id"],
        "title": fields["title"],
        "description": fields["description"],
        "subject": SUBJECT_MAP[subject_raw],
        "subcategory": fields["subcategory"],
        "lessons": fields.get("lessons") or [],
        "quiz": fields.get("quiz") or [],
    }


def parse_courses(text: str) -> list[dict]:
    courses: list[dict] = []
    i = 0
    while True:
        j = text.find("Course(", i)
        if j < 0:
            break
        # Skip type references like `[Course]` / `Course)` — require following whitespace/newline
        # Actual constructors are `Course(\n` or `Course(`.
        body, end = extract_call_body(text, j, "Course")
        # Heuristic: real course bodies start with id:
        stripped = body.lstrip()
        if not stripped.startswith("id:"):
            i = end
            continue
        courses.append(parse_course(body))
        i = end
    return courses


def parse_collection(body: str) -> dict:
    fields = parse_labeled_fields(body)
    return {
        "id": fields["id"],
        "title": fields["title"],
        "description": fields["description"],
        "coverAssetName": fields.get("coverAssetName") or "",
        "courseIds": list(fields.get("courseIds") or []),
    }


def parse_collections(text: str) -> list[dict]:
    collections: list[dict] = []
    i = 0
    while True:
        j = text.find("LearningCollection(", i)
        if j < 0:
            break
        body, end = extract_call_body(text, j, "LearningCollection")
        collections.append(parse_collection(body))
        i = end
    return collections


def parse_glossary_entry(body: str) -> dict:
    fields = parse_labeled_fields(body)
    return {
        "displayTerm": fields["displayTerm"],
        "classification": fields["classification"],
        "explanation": fields["explanation"],
    }


def parse_glossary(text: str, title_to_id: dict[str, str]) -> dict[str, dict]:
    """Parse GlossaryData.entries into {courseId|term: entry}.

    Swift keys use course titles (`Title|term`). Remap to course IDs when
    possible so Android locales match en/es/… key style.
    """
    # Locate the dictionary literal: `= [` after the type annotation.
    marker = "static let entries"
    start = text.find(marker)
    if start < 0:
        raise ValueError("GlossaryData.entries not found")
    eq = text.find("=", start)
    if eq < 0:
        raise ValueError("GlossaryData.entries '=' not found")
    brace = text.find("[", eq)
    if brace < 0:
        raise ValueError("GlossaryData.entries '[' not found")
    inner, _ = extract_bracket_body(text, brace)

    entries: dict[str, dict] = {}
    unmapped = 0
    i = 0
    while True:
        i = skip_ws_comma(inner, i)
        if i >= len(inner):
            break
        if inner[i] != '"':
            raise ValueError(f"expected glossary key string at {i}: {inner[i:i+60]!r}")
        key, i = parse_swift_string(inner, i)
        i = skip_ws_comma(inner, i)
        if i >= len(inner) or inner[i] != ":":
            raise ValueError(f"expected ':' after glossary key {key!r}")
        i += 1
        i = skip_ws_comma(inner, i)
        token = "GlossaryEntry("
        if not inner.startswith(token, i):
            raise ValueError(f"expected GlossaryEntry( after key {key!r}")
        body, i = extract_call_body(inner, i, "GlossaryEntry")
        entry = parse_glossary_entry(body)

        if "|" in key:
            title, term = key.split("|", 1)
            course_id = title_to_id.get(title)
            if course_id:
                out_key = f"{course_id}|{term}"
            else:
                out_key = key
                unmapped += 1
        else:
            out_key = key
            unmapped += 1
        entries[out_key] = entry

    return entries, unmapped


# ---------------------------------------------------------------------------
# I/O
# ---------------------------------------------------------------------------


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def copy_existing_locales() -> list[str]:
    ANDROID_LOCALES.mkdir(parents=True, exist_ok=True)
    copied: list[str] = []
    if not IOS_LOCALES.is_dir():
        return copied
    for src in sorted(IOS_LOCALES.glob("*.json")):
        dest = ANDROID_LOCALES / src.name
        shutil.copy2(src, dest)
        copied.append(src.name)
    return copied


def main() -> int:
    errors: list[str] = []

    print("Parsing CourseData.swift…")
    course_text = COURSE_DATA.read_text(encoding="utf-8")
    courses = parse_courses(course_text)
    print(f"  courses: {len(courses)}")
    if len(courses) < 230:
        errors.append(f"expected ~239 courses, got {len(courses)}")

    title_to_id = {c["title"]: c["id"] for c in courses}

    print("Parsing CollectionData.swift…")
    collection_text = COLLECTION_DATA.read_text(encoding="utf-8")
    collections = parse_collections(collection_text)
    print(f"  collections: {len(collections)}")

    glossary = None
    glossary_note = None
    try:
        print("Parsing GlossaryData.swift…")
        glossary_text = GLOSSARY_DATA.read_text(encoding="utf-8")
        glossary, unmapped = parse_glossary(glossary_text, title_to_id)
        print(f"  glossary entries: {len(glossary)} (unmapped titles: {unmapped})")
        if unmapped:
            glossary_note = f"{unmapped} glossary keys kept title-prefixed (no course id match)"
    except Exception as exc:  # noqa: BLE001 — optional export
        glossary_note = f"skipped glossary.fr.json: {exc}"
        print(f"  WARNING: {glossary_note}")

    ANDROID_LOCALES.mkdir(parents=True, exist_ok=True)

    print("Copying existing iOS locale JSON…")
    copied = copy_existing_locales()
    print(f"  copied {len(copied)} files")

    courses_path = ANDROID_LOCALES / "courses.fr.json"
    collections_path = ANDROID_LOCALES / "collections.fr.json"
    write_json(courses_path, courses)
    write_json(collections_path, collections)
    print(f"Wrote {courses_path}")
    print(f"Wrote {collections_path}")

    if glossary is not None:
        glossary_path = ANDROID_LOCALES / "glossary.fr.json"
        write_json(glossary_path, glossary)
        print(f"Wrote {glossary_path}")

    # Sanity checks
    missing_lessons = sum(1 for c in courses if not c["lessons"])
    missing_quiz = sum(1 for c in courses if not c["quiz"])
    if missing_lessons:
        errors.append(f"{missing_lessons} courses have no lessons")
    if missing_quiz:
        errors.append(f"{missing_quiz} courses have no quiz")

    print()
    print("=== Summary ===")
    print(f"script: {Path(__file__).resolve()}")
    print(f"courses: {len(courses)}")
    print(f"collections: {len(collections)}")
    if glossary is not None:
        print(f"glossary: {len(glossary)}")
    if glossary_note:
        print(f"note: {glossary_note}")
    if errors:
        print("errors:")
        for err in errors:
            print(f"  - {err}")
        return 1
    print("errors: none")
    return 0


if __name__ == "__main__":
    sys.exit(main())
