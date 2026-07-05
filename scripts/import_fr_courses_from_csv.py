#!/usr/bin/env python3
"""Regenerate French CourseData.swift and GlossaryData.swift from CSV sources.

Preserves existing quiz questions from CourseData.swift.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from import_courses_and_glossary import (  # noqa: E402
    COURSE_DATA,
    GLOSSARY_DATA,
    collect_glossary_links,
    find_quiz_blocks,
    normalize_content,
    swift_escape,
    swift_string,
)

DEFAULT_COURSES_CSV = ROOT / "scripts/data/Excel_cours_modifies_FR.csv"
DEFAULT_GLOSSARY_CSV = ROOT / "scripts/data/Glossaire_culture_generale_modifie.csv"

SKIP_CSV_TITLES = {"", "B"}
CONTENT_OVERRIDE_BY_APP_NUM = {170: 190}
GLOSSARY_COURSE_REMAP = {"B": "Méduse et Persée"}

SUBJECT_MAP = {
    "Histoire": ".histoire",
    "Sciences": ".sciences",
    "Littérature": ".litterature",
    "Art": ".art",
    "Mythologie": ".mythologie",
    "Comprendre le monde actuel": ".comprendreLeMonde",
}

CLASSIFICATION_MAP = {
    "Référence historique": "referenceHistorique",
    "Concept": "concept",
    "Événement connexe": "evenementConnexe",
    "Événement": "evenementConnexe",
    "Évènement": "evenementConnexe",
    "Personnage": "personnage",
    "Lieu / institution": "lieuInstitution",
    "Institution": "lieuInstitution",
    "Lieu": "lieuInstitution",
    "Mouvement": "concept",
    "Œuvre": "referenceHistorique",
    "Autre": "concept",
    "Date": "referenceHistorique",
    "Loi": "referenceHistorique",
    "Théorie": "concept",
    "Technique": "concept",
    "Objet": "referenceHistorique",
    "Période": "referenceHistorique",
    "Acronyme": "concept",
    "Espèce": "concept",
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def swift_unescape(value: str) -> str:
    try:
        return json.loads(f'"{value}"')
    except json.JSONDecodeError:
        return value.replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")


def course_number(course_id: str) -> int:
    match = re.match(r"course_(\d+)_", course_id)
    if not match:
        raise ValueError(f"Unexpected course id: {course_id}")
    return int(match.group(1))


def make_description(intro: str, max_len: int = 150) -> str:
    text = intro.replace("\n", " ")
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"<([^>]+)>", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]", "", text)
    text = re.sub(r"\{([^}]+)\}", "", text)
    text = re.sub(r"\|\|([^|]+)\|\|", r"\1", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= max_len:
        return text
    cut = text[:max_len].rsplit(" ", 1)[0]
    return f"{cut}..."


def load_courses_by_id(path: Path) -> dict[int, dict[str, object]]:
    courses: dict[int, dict[str, object]] = {}
    for row in read_csv(path):
        csv_id = int((row.get("ID") or "0").strip())
        title = (row.get("Titre") or "").strip()

        parts: list[tuple[str, str]] = []
        for idx in range(1, 5):
            part_title = normalize_content(row.get(f"Partie {idx} Titre"))
            part_content = normalize_content(row.get(f"Partie {idx} Contenu"))
            if not part_content:
                continue
            parts.append((part_title or f"Partie {idx}", part_content))

        matiere = (row.get("Matière") or "").strip()
        subject = SUBJECT_MAP.get(matiere)
        if subject is None:
            raise ValueError(f"Unknown subject for CSV id {csv_id}: {matiere!r}")

        courses[csv_id] = {
            "csv_id": csv_id,
            "title": title,
            "intro": normalize_content(row.get("Intro")),
            "parts": parts,
            "subcategory": normalize_content(row.get("Sous-catégorie")),
            "subject": subject,
        }
    return courses


def load_glossary_rows(path: Path) -> dict[str, list[dict[str, str]]]:
    rows_by_course: dict[str, list[dict[str, str]]] = {}
    for row in read_csv(path):
        course = (row.get("Nom du cours") or "").strip()
        course = GLOSSARY_COURSE_REMAP.get(course, course)
        if course in SKIP_CSV_TITLES or not course:
            continue
        term = (row.get("Terme") or "").strip()
        if not term:
            continue
        rows_by_course.setdefault(course, []).append(
            {
                "term": term,
                "classification": (row.get("Classification") or "").strip(),
                "explanation": normalize_content(row.get("Explication")),
            }
        )
    return rows_by_course


def entries_from_glossary_rows(glossary_rows: dict[str, list[dict[str, str]]]) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for course, rows in glossary_rows.items():
        for row in rows:
            swift_classification = CLASSIFICATION_MAP.get(row["classification"])
            if not swift_classification:
                raise ValueError(f"Unknown glossary classification: {row['classification']!r}")
            entries[f"{course}|{row['term']}"] = {
                "displayTerm": row["term"],
                "classification": swift_classification,
                "explanation": row["explanation"],
            }
    return entries


def entries_from_content_links(links: dict[tuple[str, str], dict[str, str]]) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for (course, display), link in links.items():
        swift_classification = CLASSIFICATION_MAP.get(link["classification"])
        if not swift_classification:
            raise ValueError(f"Unknown glossary classification: {link['classification']!r}")
        entries[f"{course}|{display}"] = {
            "displayTerm": link["displayTerm"],
            "classification": swift_classification,
            "explanation": normalize_content(link["explanation"]),
        }
    return entries


def parse_app_courses(text: str) -> list[dict[str, object]]:
    pattern = re.compile(
        r"Course\(\s*\n"
        r'\s*id: "(course_\d+[^"]+)",\s*\n'
        r'\s*title: "((?:[^"\\]|\\.)*)",\s*\n'
        r'\s*description: "((?:[^"\\]|\\.)*)",\s*\n'
        r"\s*subject: (\.\w+),\s*\n"
        r'\s*subcategory: "((?:[^"\\]|\\.)*)",\s*\n'
        r"\s*lessons: \[",
        re.MULTILINE,
    )
    quiz_blocks = find_quiz_blocks(text)
    matches = list(pattern.finditer(text))
    if len(quiz_blocks) != len(matches):
        raise ValueError(f"Quiz blocks ({len(quiz_blocks)}) != courses ({len(matches)})")

    courses: list[dict[str, object]] = []
    for idx, match in enumerate(matches):
        lessons_start = match.end()
        lessons_end = text.find("\n            ],", lessons_start)
        if lessons_end == -1:
            raise ValueError(f"No lessons end for {match.group(1)}")
        lesson_block = text[lessons_start:lessons_end]
        quiz_raw = quiz_blocks[idx][2]
        courses.append(
            {
                "id": match.group(1),
                "title": swift_unescape(match.group(2)),
                "lesson_ids": re.findall(r'LessonPage\(id: "([^"]+)"', lesson_block),
                "quiz_raw": quiz_raw,
            }
        )
    return courses


def csv_course_for_app(app_course: dict[str, object], courses_by_id: dict[int, dict[str, object]]) -> dict[str, object]:
    app_num = course_number(app_course["id"])
    csv_id = CONTENT_OVERRIDE_BY_APP_NUM.get(app_num, app_num)
    csv_course = courses_by_id.get(csv_id)
    if csv_course is None:
        raise ValueError(f"No CSV row for app course {app_course['id']} (csv id {csv_id})")
    return csv_course


def display_title_for_app(app_course: dict[str, object], courses_by_id: dict[int, dict[str, object]]) -> str:
    app_num = course_number(app_course["id"])
    if app_num in CONTENT_OVERRIDE_BY_APP_NUM:
        reference = courses_by_id.get(app_num)
        if reference and reference["title"] not in SKIP_CSV_TITLES:
            return str(reference["title"])
    return str(app_course["title"])


def lesson_ids_for_course(course_id: str, existing: list[str], part_count: int) -> list[str]:
    intro = next((lesson_id for lesson_id in existing if lesson_id.endswith("_intro")), None)
    ids = [intro or f"{course_id}_intro"]
    for idx in range(1, part_count + 1):
        suffix = f"_p{idx}"
        ids.append(next((lesson_id for lesson_id in existing if lesson_id.endswith(suffix)), f"{course_id}{suffix}"))
    return ids


def build_lessons(course_id: str, lesson_ids: list[str], csv_course: dict[str, object]) -> str:
    lines = [
        f'                LessonPage(id: "{lesson_ids[0]}", title: "Introduction", content: {swift_string(csv_course["intro"])}),'
    ]
    for lesson_id, (title, content) in zip(lesson_ids[1:], csv_course["parts"]):
        lines.append(
            f'                LessonPage(id: "{lesson_id}", title: {swift_string(title)}, content: {swift_string(content)}),'
        )
    return "\n".join(lines)


def build_quiz_block(quiz_raw: str) -> str:
    if quiz_raw.strip():
        return "            quiz: [\n" + quiz_raw + "\n    ]"
    return "            quiz: []"


def build_course_block(
    app_course: dict[str, object],
    csv_course: dict[str, object],
    courses_by_id: dict[int, dict[str, object]],
) -> str:
    course_id = app_course["id"]
    title = display_title_for_app(app_course, courses_by_id)
    lesson_ids = lesson_ids_for_course(course_id, app_course["lesson_ids"], len(csv_course["parts"]))
    lessons = build_lessons(course_id, lesson_ids, csv_course)
    description = make_description(csv_course["intro"])
    quiz_body = build_quiz_block(app_course["quiz_raw"])

    return f"""        Course(
            id: "{course_id}",
            title: {swift_string(title)},
            description: {swift_string(description)},
            subject: {csv_course["subject"]},
            subcategory: {swift_string(csv_course["subcategory"])},
            lessons: [
{lessons}
            ],
{quiz_body}
        )"""


def courses_for_glossary_links(courses_by_id: dict[int, dict[str, object]]) -> dict[str, dict[str, object]]:
    linked: dict[str, dict[str, object]] = {}
    for app_num in range(1, 241):
        if app_num == 190:
            continue
        csv_id = CONTENT_OVERRIDE_BY_APP_NUM.get(app_num, app_num)
        course = courses_by_id.get(csv_id)
        if not course:
            continue
        title = str(course["title"])
        if app_num == 170:
            title = str(courses_by_id[170]["title"])
        linked[title] = {
            "intro": course["intro"],
            "parts": course["parts"],
        }
    return linked


def write_course_data(app_courses: list[dict[str, object]], courses_by_id: dict[int, dict[str, object]]) -> None:
    blocks = [build_course_block(app_course, csv_course_for_app(app_course, courses_by_id), courses_by_id) for app_course in app_courses]
    header = "import Foundation\n\nnonisolated enum CourseData {\n    static let allCourses: [Course] = [\n"
    footer = "\n    ]\n}\n"
    COURSE_DATA.write_text(header + ",\n".join(blocks) + footer, encoding="utf-8")


def write_glossary_data(entries: dict[str, dict[str, str]]) -> None:
    lines = []
    for key in sorted(entries):
        course, display = key.split("|", 1)
        entry = entries[key]
        lines.append(
            "        "
            f'"{swift_escape(course)}|{swift_escape(display)}": GlossaryEntry('
            f"displayTerm: {swift_string(entry['displayTerm'])}, "
            f"classification: .{entry['classification']}, "
            f"explanation: {swift_string(entry['explanation'])})"
        )
    body = ",\n".join(lines)
    GLOSSARY_DATA.write_text(
        f"""import Foundation

/// Glossary entries — generated from Glossaire_culture_generale CSV.
nonisolated enum GlossaryData {{
    static let entries: [String: GlossaryEntry] = [
{body}
    ]
}}
""",
        encoding="utf-8",
    )


def validate_outputs() -> None:
    course_text = COURSE_DATA.read_text(encoding="utf-8")
    malformed = [
        line
        for line in course_text.splitlines()
        if "LessonPage" in line and 'content: "' in line and not line.rstrip().endswith('"),')
    ]
    if malformed:
        raise ValueError(f"CourseData has {len(malformed)} malformed LessonPage lines")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--courses-csv", type=Path, default=DEFAULT_COURSES_CSV)
    parser.add_argument("--glossary-csv", type=Path, default=DEFAULT_GLOSSARY_CSV)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    courses_by_id = load_courses_by_id(args.courses_csv)
    glossary_rows = load_glossary_rows(args.glossary_csv)

    glossary_entries = entries_from_glossary_rows(glossary_rows)
    content_links = collect_glossary_links(courses_for_glossary_links(courses_by_id), glossary_rows)
    glossary_entries = {**glossary_entries, **entries_from_content_links(content_links)}

    app_courses = parse_app_courses(COURSE_DATA.read_text(encoding="utf-8"))
    write_course_data(app_courses, courses_by_id)
    write_glossary_data(glossary_entries)
    validate_outputs()

    print(f"Updated courses: {len(app_courses)}")
    print(f"CSV course rows loaded: {len(courses_by_id)}")
    print(f"Glossary entries written: {len(glossary_entries)}")
    print(f"Content link aliases: {len(content_links)}")


if __name__ == "__main__":
    main()
