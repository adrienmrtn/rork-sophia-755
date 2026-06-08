#!/usr/bin/env python3
"""Generate English locale JSON bundles from CSV exports + French CourseData IDs."""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from import_content_from_csv import (  # noqa: E402
    lesson_ids_for_course,
    normalize_content,
    parse_all_courses,
)

COURSE_DATA = ROOT / "ios/Sophia/Services/CourseData.swift"
LOCALE_BUNDLE_DIR = ROOT / "ios/Sophia/Resources/Locales"
DEFAULT_LANG = "en"

SUBJECT_EN_MAP = {
    "History": "histoire",
    "Sciences": "sciences",
    "Literature": "litterature",
    "Art": "art",
    "Mythology": "mythologie",
    "Understanding the modern world": "comprendreLeMonde",
}

CLASSIFICATION_EN_MAP = {
    "Historical reference": "referenceHistorique",
    "Concept": "concept",
    "Related event": "evenementConnexe",
    "Event": "evenementConnexe",
    "Figure": "personnage",
    "Location": "lieuInstitution",
    "Place / institution": "lieuInstitution",
    "Institution": "lieuInstitution",
    "Movement": "concept",
    "Work": "referenceHistorique",
    "Other": "concept",
    "Date": "referenceHistorique",
    "Law": "referenceHistorique",
    "Theory": "concept",
    "Technique": "concept",
    "Object": "referenceHistorique",
    "Period": "referenceHistorique",
    "Acronym": "concept",
}

RARITY_EN_MAP = {
    "Common": "commune",
    "Rare": "rare",
    "Epic": "epique",
    "Legendary": "legendaire",
}

SKIP_TITLES = {"", "B"}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def make_description(intro: str, max_len: int = 150) -> str:
    text = re.sub(r"\s+", " ", intro or "").strip()
    if len(text) <= max_len:
        return text
    cut = text[: max_len - 3].rsplit(" ", 1)[0]
    return f"{cut}..."


def load_en_courses_rows(path: Path) -> list[dict[str, str]]:
    rows = []
    for row in read_csv(path):
        title = (row.get("Titre") or "").strip()
        if title in SKIP_TITLES:
            continue
        rows.append(row)
    return rows


def load_en_quizzes(path: Path) -> dict[str, list[dict[str, object]]]:
    text = path.read_text(encoding="utf-8-sig")
    quizzes: dict[str, list[dict[str, object]]] = {}

    section_lines: list[str] = []
    for line in text.splitlines():
        if line.startswith("#"):
            if section_lines:
                _parse_quiz_section(section_lines, quizzes)
                section_lines = []
            continue
        section_lines.append(line)
    if section_lines:
        _parse_quiz_section(section_lines, quizzes)
    return quizzes


def _parse_quiz_section(lines: list[str], quizzes: dict[str, list[dict[str, object]]]) -> None:
    if not lines:
        return
    reader = csv.DictReader(lines)
    for row in reader:
        title = (row.get("Titre") or "").strip()
        if title in SKIP_TITLES:
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


def load_en_glossary(path: Path) -> dict[str, list[dict[str, str]]]:
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


def build_title_maps(
    app_courses: list[dict[str, object]], en_rows: list[dict[str, str]]
) -> tuple[dict[str, str], dict[str, str]]:
    if len(en_rows) != len(app_courses):
        raise ValueError(f"Course count mismatch: EN CSV {len(en_rows)} vs app {len(app_courses)}")

    en_title_to_id: dict[str, str] = {}
    fr_title_to_id: dict[str, str] = {}
    for app_course, en_row in zip(app_courses, en_rows):
        course_id = str(app_course["id"])
        en_title = (en_row.get("Titre") or "").strip()
        fr_title = str(app_course["title"])
        en_title_to_id[en_title] = course_id
        fr_title_to_id[fr_title] = course_id
    return en_title_to_id, fr_title_to_id


def build_courses_json(
    app_courses: list[dict[str, object]],
    en_rows: list[dict[str, str]],
    en_quizzes: dict[str, list[dict[str, object]]],
) -> list[dict[str, object]]:
    courses: list[dict[str, object]] = []
    for app_course, en_row in zip(app_courses, en_rows):
        en_title = (en_row.get("Titre") or "").strip()
        subject_label = (en_row.get("Matière") or "").strip()
        subject_key = SUBJECT_EN_MAP.get(subject_label)
        if not subject_key:
            raise ValueError(f"Unknown EN subject: {subject_label!r} for {en_title}")

        parts: list[tuple[str, str]] = []
        for idx in range(1, 5):
            part_title = normalize_content(en_row.get(f"Partie {idx} Titre"))
            part_content = normalize_content(en_row.get(f"Partie {idx} Contenu"))
            if not part_content:
                continue
            parts.append((part_title or f"Part {idx}", part_content))

        intro = normalize_content(en_row.get("Intro"))
        quiz_questions = en_quizzes.get(en_title)
        if not intro or not parts or not quiz_questions:
            continue

        course_id = str(app_course["id"])
        lesson_ids = lesson_ids_for_course(
            course_id,
            list(app_course["lesson_ids"]),
            len(parts),
        )
        lessons = [
            {"id": lesson_ids[0], "title": "Introduction", "content": intro},
        ]
        for lesson_id, (title, content) in zip(lesson_ids[1:], parts):
            lessons.append({"id": lesson_id, "title": title, "content": content})

        quiz_ids = list(app_course["quiz_ids"])
        if len(quiz_ids) != len(quiz_questions):
            continue

        quiz = []
        for quiz_id, question in zip(quiz_ids, quiz_questions):
            quiz.append(
                {
                    "id": quiz_id,
                    "question": question["question"],
                    "options": question["options"],
                    "correctIndex": 0,
                    "explanation": question["explanation"],
                }
            )

        courses.append(
            {
                "id": course_id,
                "title": en_title,
                "description": make_description(intro),
                "subject": subject_key,
                "subcategory": normalize_content(en_row.get("Sous-catégorie")),
                "lessons": lessons,
                "quiz": quiz,
            }
        )
    return courses


def build_glossary_json(
    app_courses: list[dict[str, object]],
    en_rows: list[dict[str, str]],
    glossary_rows: dict[str, list[dict[str, str]]],
) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for app_course, en_row in zip(app_courses, en_rows):
        en_title = (en_row.get("Titre") or "").strip()
        course_id = str(app_course["id"])
        for row in glossary_rows.get(en_title, []):
            classification = CLASSIFICATION_EN_MAP.get(row["classification"])
            if not classification:
                raise ValueError(
                    f"Unknown EN classification: {row['classification']!r} ({en_title})"
                )
            term = row["term"]
            entries[f"{course_id}|{term}"] = {
                "displayTerm": term,
                "classification": classification,
                "explanation": row["explanation"],
            }
    return entries


def resolve_course_titles(titles: str, title_map: dict[str, str]) -> list[str] | None:
    parts = [part.strip() for part in titles.split("|")]
    course_ids: list[str] = []
    for title in parts:
        if not title:
            continue
        course_id = title_map.get(title)
        if not course_id:
            return None
        course_ids.append(course_id)
    return course_ids or None


def build_collections_json(path: Path, title_map: dict[str, str]) -> list[dict[str, object]]:
    collections: list[dict[str, object]] = []
    for row in read_csv(path):
        collection_id = (row.get("id") or "").strip()
        title = (row.get("Titre") or "").strip()
        description = normalize_content(row.get("Description"))
        course_titles = row.get("Cours") or ""
        course_ids = resolve_course_titles(course_titles, title_map)
        if not collection_id or not title or not course_ids:
            continue
        collections.append(
            {
                "id": collection_id,
                "title": title,
                "description": description,
                "courseIds": course_ids,
            }
        )
    return collections


def build_cards_json(path: Path, title_map: dict[str, str]) -> list[dict[str, object]]:
    cards: list[dict[str, object]] = []
    for row in read_csv(path):
        card_id = (row.get("id") or "").strip()
        name = (row.get("Nom") or "").strip()
        rarity_label = (row.get("Rareté") or row.get("Rarete") or "").strip()
        rarity = RARITY_EN_MAP.get(rarity_label)
        course_titles = row.get("Cours") or ""
        course_ids = resolve_course_titles(course_titles, title_map)
        if not card_id or not name or not rarity or not course_ids:
            continue
        cards.append(
            {
                "id": card_id,
                "name": name,
                "rarity": rarity,
                "courseIds": course_ids,
            }
        )
    return cards


def write_json(path: Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def write_locale_bundle(lang: str, name: str, payload: object) -> Path:
    path = LOCALE_BUNDLE_DIR / f"{name}.{lang}.json"
    write_json(path, payload)
    return path


def parse_args() -> argparse.Namespace:
    source = ROOT / "content/locales/en/source"
    parser = argparse.ArgumentParser()
    parser.add_argument("--courses-csv", type=Path, default=source / "Excel_cours_systeme_modifie_EN_0b72.csv")
    parser.add_argument("--quiz-csv", type=Path, default=source / "Excel_QCM_EN_0fad.csv")
    parser.add_argument("--glossary-csv", type=Path, default=source / "Glossaire_culture_generale_modifie_EN_96bc.csv")
    parser.add_argument("--collections-csv", type=Path, default=source / "Collections_EN_23b7.csv")
    parser.add_argument("--cards-csv", type=Path, default=source / "Cartes_EN_c174.csv")
    parser.add_argument("--lang", default=DEFAULT_LANG)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    app_courses = parse_all_courses(COURSE_DATA.read_text(encoding="utf-8"))
    en_rows = load_en_courses_rows(args.courses_csv)
    en_quizzes = load_en_quizzes(args.quiz_csv)
    glossary_rows = load_en_glossary(args.glossary_csv)
    en_title_to_id, _ = build_title_maps(app_courses, en_rows)

    courses = build_courses_json(app_courses, en_rows, en_quizzes)
    glossary = build_glossary_json(app_courses, en_rows, glossary_rows)
    collections = build_collections_json(args.collections_csv, en_title_to_id)
    cards = build_cards_json(args.cards_csv, en_title_to_id)

    lang = args.lang
    bundles = {
        "courses": courses,
        "glossary": glossary,
        "collections": collections,
        "cards": cards,
    }
    for name, payload in bundles.items():
        write_locale_bundle(lang, name, payload)

    print(f"Courses written: {len(courses)} / {len(app_courses)}")
    print(f"Glossary entries: {len(glossary)}")
    print(f"Collections written: {len(collections)}")
    print(f"Cards written: {len(cards)}")
    print(f"Output: {LOCALE_BUNDLE_DIR} (*.{lang}.json)")


if __name__ == "__main__":
    main()
