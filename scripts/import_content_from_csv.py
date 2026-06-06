#!/usr/bin/env python3
"""Import uploaded CSV course, quiz, and glossary content into generated Swift data."""

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

SKIP_TITLES = {"", "B"}
SKIP_QUIZ_TITLES = SKIP_TITLES | {"Danaé et la naissance de Persée"}

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
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def swift_unescape(value: str) -> str:
    try:
        return json.loads(f'"{value}"')
    except json.JSONDecodeError:
        return value.replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")


def parse_all_courses(text: str) -> list[dict[str, object]]:
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
                "description": swift_unescape(match.group(3)),
                "subject": match.group(4),
                "subcategory": swift_unescape(match.group(5)),
                "lesson_ids": re.findall(r'LessonPage\(id: "([^"]+)"', lesson_block),
                "quiz_ids": re.findall(r'QuizQuestion\(id: "([^"]+)"', quiz_raw),
            }
        )
    return courses


def load_courses(path: Path) -> dict[str, dict[str, object]]:
    courses: dict[str, dict[str, object]] = {}
    for row in read_csv(path):
        title = (row.get("Titre") or "").strip()
        if title in SKIP_TITLES:
            continue

        parts: list[tuple[str, str]] = []
        for idx in range(1, 5):
            part_title = normalize_content(row.get(f"Partie {idx} Titre"))
            part_content = normalize_content(row.get(f"Partie {idx} Contenu"))
            if not part_content:
                continue
            parts.append((part_title or f"Partie {idx}", part_content))

        courses[title] = {
            "intro": normalize_content(row.get("Intro")),
            "parts": parts,
        }
    return courses


def load_quizzes(path: Path) -> dict[str, list[dict[str, object]]]:
    quizzes: dict[str, list[dict[str, object]]] = {}
    for row in read_csv(path):
        title = (row.get("Titre") or "").strip()
        if title in SKIP_QUIZ_TITLES:
            continue

        questions: list[dict[str, object]] = []
        for idx in range(1, 6):
            question = normalize_content(row.get(f"QCM{idx} — Question"))
            correct = normalize_content(row.get(f"QCM{idx} — ✅ Bonne réponse"))
            wrong = [
                normalize_content(row.get(f"QCM{idx} — ❌ Mauvaise {wrong_idx}"))
                for wrong_idx in range(1, 4)
            ]
            explanation = normalize_content(row.get(f"QCM{idx} — Explication"))
            if not question and not correct:
                continue

            options = [correct] + [option for option in wrong if option]
            while len(options) < 4:
                options.append("")
            questions.append(
                {
                    "question": question,
                    "options": options[:4],
                    "explanation": explanation,
                }
            )

        if questions:
            quizzes[title] = questions
    return quizzes


def load_glossary_rows(path: Path) -> dict[str, list[dict[str, str]]]:
    rows_by_course: dict[str, list[dict[str, str]]] = {}
    for row in read_csv(path):
        course = (row.get("Nom du cours") or "").strip()
        term = (row.get("Terme") or "").strip()
        classification = (row.get("Classification") or "").strip()
        if course in SKIP_TITLES or not term:
            continue
        rows_by_course.setdefault(course, []).append(
            {
                "term": term,
                "classification": classification,
                "explanation": normalize_content(row.get("Explication")),
            }
        )
    return rows_by_course


def entries_from_glossary_rows(glossary_rows: dict[str, list[dict[str, str]]]) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for course, rows in glossary_rows.items():
        for row in rows:
            classification = row["classification"]
            term = row["term"]
            swift_classification = CLASSIFICATION_MAP.get(classification)
            if not swift_classification:
                raise ValueError(f"Unknown glossary classification: {classification!r}")

            entries[f"{course}|{term}"] = {
                "displayTerm": term,
                "classification": swift_classification,
                "explanation": row["explanation"],
            }
    return entries


def entries_from_content_links(links: dict[tuple[str, str], dict[str, str]]) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for (course, display), link in links.items():
        classification = link["classification"]
        swift_classification = CLASSIFICATION_MAP.get(classification)
        if not swift_classification:
            raise ValueError(f"Unknown glossary classification: {classification!r}")

        entries[f"{course}|{display}"] = {
            "displayTerm": link["displayTerm"],
            "classification": swift_classification,
            "explanation": normalize_content(link["explanation"]),
        }
    return entries


def lesson_ids_for_course(course_id: str, existing: list[str], part_count: int) -> list[str]:
    intro = next((lesson_id for lesson_id in existing if lesson_id.endswith("_intro")), None)
    ids = [intro or f"{course_id}_intro"]
    for idx in range(1, part_count + 1):
        suffix = f"_p{idx}"
        ids.append(next((lesson_id for lesson_id in existing if lesson_id.endswith(suffix)), f"{course_id}{suffix}"))
    return ids


def build_lessons(course_id: str, lesson_ids: list[str], course: dict[str, object]) -> str:
    lines = [
        f'                LessonPage(id: "{lesson_ids[0]}", title: "Introduction", content: {swift_string(course["intro"])}),'
    ]
    for lesson_id, (title, content) in zip(lesson_ids[1:], course["parts"]):
        lines.append(
            f'                LessonPage(id: "{lesson_id}", title: {swift_string(title)}, content: {swift_string(content)}),'
        )
    return "\n".join(lines)


def swift_options(options: list[str]) -> str:
    return "[" + ", ".join(swift_string(option) for option in options) + "]"


def build_quiz(quiz_ids: list[str], questions: list[dict[str, object]], course_title: str) -> str:
    if len(quiz_ids) != len(questions):
        raise ValueError(
            f"{course_title}: CSV has {len(questions)} quiz questions, app has {len(quiz_ids)} IDs"
        )

    lines = []
    for quiz_id, question in zip(quiz_ids, questions):
        lines.append(
            f'        QuizQuestion(id: "{quiz_id}", '
            f"question: {swift_string(question['question'])}, "
            f"options: {swift_options(question['options'])}, "
            "correctIndex: 0, "
            f"explanation: {swift_string(question['explanation'])})"
        )
    return "            quiz: [\n" + ",\n".join(lines) + "\n    ]"


def build_course_block(app_course: dict[str, object], csv_course: dict[str, object], quiz: list[dict[str, object]]) -> str:
    course_id = app_course["id"]
    lesson_ids = lesson_ids_for_course(
        course_id,
        app_course["lesson_ids"],
        len(csv_course["parts"]),
    )
    lessons = build_lessons(course_id, lesson_ids, csv_course)
    quiz_body = build_quiz(app_course["quiz_ids"], quiz, app_course["title"])
    return f"""        Course(
            id: "{course_id}",
            title: {swift_string(app_course["title"])},
            description: {swift_string(app_course["description"])},
            subject: {app_course["subject"]},
            subcategory: {swift_string(app_course["subcategory"])},
            lessons: [
{lessons}
            ],
{quiz_body}
        )"""


def write_course_data(app_courses: list[dict[str, object]], csv_courses: dict[str, dict[str, object]], csv_quizzes: dict[str, list[dict[str, object]]]) -> None:
    blocks = []
    missing_courses = []
    missing_quizzes = []
    for app_course in app_courses:
        title = app_course["title"]
        csv_course = csv_courses.get(title)
        quiz = csv_quizzes.get(title)
        if csv_course is None:
            missing_courses.append(title)
            continue
        if quiz is None:
            missing_quizzes.append(title)
            continue
        blocks.append(build_course_block(app_course, csv_course, quiz))

    if missing_courses:
        raise ValueError(f"No CSV course content for {len(missing_courses)} courses: {missing_courses[:8]}")
    if missing_quizzes:
        raise ValueError(f"No CSV quiz content for {len(missing_quizzes)} courses: {missing_quizzes[:8]}")

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
    lesson_line_breaks = [
        line
        for line in course_text.splitlines()
        if "LessonPage" in line and 'content: "' in line and not line.rstrip().endswith('"),')
    ]
    if lesson_line_breaks:
        raise ValueError(f"CourseData has {len(lesson_line_breaks)} malformed LessonPage lines")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--courses-csv", type=Path, required=True)
    parser.add_argument("--quiz-csv", type=Path, required=True)
    parser.add_argument("--glossary-csv", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    csv_courses = load_courses(args.courses_csv)
    csv_quizzes = load_quizzes(args.quiz_csv)
    glossary_rows = load_glossary_rows(args.glossary_csv)
    glossary_entries = entries_from_glossary_rows(glossary_rows)
    content_link_entries = entries_from_content_links(collect_glossary_links(csv_courses, glossary_rows))
    glossary_entries = {**glossary_entries, **content_link_entries}

    app_courses = parse_all_courses(COURSE_DATA.read_text(encoding="utf-8"))
    write_course_data(app_courses, csv_courses, csv_quizzes)
    write_glossary_data(glossary_entries)
    validate_outputs()

    print(f"App courses updated: {len(app_courses)}")
    print(f"CSV courses loaded: {len(csv_courses)}")
    print(f"CSV quizzes loaded: {len(csv_quizzes)}")
    print(f"Glossary CSV entries loaded: {sum(len(rows) for rows in glossary_rows.values())}")
    print(f"Glossary link aliases added: {len(content_link_entries)}")
    print(f"Glossary entries written: {len(glossary_entries)}")


if __name__ == "__main__":
    main()
