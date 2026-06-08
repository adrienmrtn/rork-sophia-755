#!/usr/bin/env python3
"""Generate German locale JSON bundles from CSV exports + French CourseData IDs."""

from __future__ import annotations

import argparse
import difflib
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from generate_en_locale_json import (  # noqa: E402
    SKIP_TITLES,
    build_title_maps,
    load_en_courses_rows,
    load_en_glossary,
    load_en_quizzes,
    make_description,
    read_csv,
    write_json,
)
from import_content_from_csv import lesson_ids_for_course, normalize_content, parse_all_courses  # noqa: E402

COURSE_DATA = ROOT / "ios/Sophia/Services/CourseData.swift"
DEFAULT_OUT = ROOT / "ios/Sophia/Locales/de"

SUBJECT_DE_MAP = {
    "Geschichte": "histoire",
    "Wissenschaften": "sciences",
    "Literatur": "litterature",
    "Kunst": "art",
    "Mythologie": "mythologie",
    "Die heutige Welt verstehen": "comprendreLeMonde",
}

CLASSIFICATION_DE_MAP = {
    "Historischer Bezug": "referenceHistorique",
    "Konzept": "concept",
    "Zugehöriges Ereignis": "evenementConnexe",
    "Ereignis": "evenementConnexe",
    "Personage": "personnage",
    "Ort": "lieuInstitution",
    "Ort / Institution": "lieuInstitution",
    "Institution": "lieuInstitution",
    "Bewegung": "concept",
    "Werk": "referenceHistorique",
    "Andere": "concept",
    "Datum": "referenceHistorique",
    "Gesetz": "referenceHistorique",
    "Theorie": "concept",
    "Technik": "concept",
    "Objekt": "referenceHistorique",
    "Zeitraum": "referenceHistorique",
    "Periode": "referenceHistorique",
    "Akronym": "concept",
}

RARITY_DE_MAP = {
    "Gewöhnlich": "commune",
    "Selten": "rare",
    "Episch": "epique",
    "Legendär": "legendaire",
}


def normalize_title(value: str) -> str:
    folded = unicodedata.normalize("NFD", value or "")
    stripped = "".join(char for char in folded if unicodedata.category(char) != "Mn")
    return re.sub(r"\s+", " ", stripped).strip().casefold()


def lookup_course_id(title: str, title_map: dict[str, str], normalized_map: dict[str, str]) -> str | None:
    if course_id := title_map.get(title):
        return course_id
    normalized = normalize_title(title)
    if course_id := normalized_map.get(normalized):
        return course_id
    matches = difflib.get_close_matches(normalized, normalized_map.keys(), n=1, cutoff=0.78)
    if matches:
        return normalized_map[matches[0]]
    return None


def resolve_course_titles_de(titles: str, title_map: dict[str, str]) -> list[str] | None:
    normalized_map = {normalize_title(title): course_id for title, course_id in title_map.items()}
    course_ids: list[str] = []
    for part in titles.split("|"):
        title = part.strip()
        if not title:
            continue
        course_id = lookup_course_id(title, title_map, normalized_map)
        if course_id is None:
            return None
        course_ids.append(course_id)
    return course_ids or None


def build_courses_json(
    app_courses: list[dict[str, object]],
    de_rows: list[dict[str, str]],
    de_quizzes: dict[str, list[dict[str, object]]],
) -> list[dict[str, object]]:
    courses: list[dict[str, object]] = []
    for app_course, de_row in zip(app_courses, de_rows):
        de_title = (de_row.get("Titre") or "").strip()
        subject_label = (de_row.get("Matière") or "").strip()
        subject_key = SUBJECT_DE_MAP.get(subject_label)
        if not subject_key:
            raise ValueError(f"Unknown DE subject: {subject_label!r} for {de_title}")

        parts: list[tuple[str, str]] = []
        for idx in range(1, 5):
            part_title = normalize_content(de_row.get(f"Partie {idx} Titre"))
            part_content = normalize_content(de_row.get(f"Partie {idx} Contenu"))
            if not part_content:
                continue
            parts.append((part_title or f"Teil {idx}", part_content))

        intro = normalize_content(de_row.get("Intro"))
        quiz_questions = de_quizzes.get(de_title)
        if not intro or not parts or not quiz_questions:
            continue

        course_id = str(app_course["id"])
        lesson_ids = lesson_ids_for_course(
            course_id,
            list(app_course["lesson_ids"]),
            len(parts),
        )
        lessons = [
            {"id": lesson_ids[0], "title": "Einführung", "content": intro},
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
                "title": de_title,
                "description": make_description(intro),
                "subject": subject_key,
                "subcategory": normalize_content(de_row.get("Sous-catégorie")),
                "lessons": lessons,
                "quiz": quiz,
            }
        )
    return courses


def build_glossary_json(
    app_courses: list[dict[str, object]],
    de_rows: list[dict[str, str]],
    glossary_rows: dict[str, list[dict[str, str]]],
) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for app_course, de_row in zip(app_courses, de_rows):
        de_title = (de_row.get("Titre") or "").strip()
        course_id = str(app_course["id"])
        for row in glossary_rows.get(de_title, []):
            classification = CLASSIFICATION_DE_MAP.get(row["classification"])
            if not classification:
                raise ValueError(
                    f"Unknown DE classification: {row['classification']!r} ({de_title})"
                )
            term = row["term"]
            entries[f"{course_id}|{term}"] = {
                "displayTerm": term,
                "classification": classification,
                "explanation": row["explanation"],
            }
    return entries


def build_cards_json_de(path: Path, title_map: dict[str, str]) -> list[dict[str, object]]:
    cards: list[dict[str, object]] = []
    for row in read_csv(path):
        card_id = (row.get("id") or "").strip()
        name = (row.get("Nom") or "").strip()
        rarity_label = (row.get("Rareté") or row.get("Rarete") or "").strip()
        rarity = RARITY_DE_MAP.get(rarity_label)
        course_titles = row.get("Cours") or ""
        course_ids = resolve_course_titles_de(course_titles, title_map)
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


def build_collections_json_de(path: Path, title_map: dict[str, str]) -> list[dict[str, object]]:
    collections: list[dict[str, object]] = []
    for row in read_csv(path):
        collection_id = (row.get("id") or "").strip()
        title = (row.get("Titre") or "").strip()
        description = normalize_content(row.get("Description"))
        course_titles = row.get("Cours") or ""
        course_ids = resolve_course_titles_de(course_titles, title_map)
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


def parse_args() -> argparse.Namespace:
    source = ROOT / "content/locales/de/source"
    parser = argparse.ArgumentParser()
    parser.add_argument("--courses-csv", type=Path, default=source / "Excel_cours_systeme_modifie_DE_ea79.csv")
    parser.add_argument("--quiz-csv", type=Path, default=source / "Excel_QCM_DE_5e64.csv")
    parser.add_argument("--glossary-csv", type=Path, default=source / "Glossaire_culture_generale_modifie_DE_507c.csv")
    parser.add_argument("--collections-csv", type=Path, default=source / "Collections_DE_443e.csv")
    parser.add_argument("--cards-csv", type=Path, default=source / "Cartes_DE_ba02.csv")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUT)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    app_courses = parse_all_courses(COURSE_DATA.read_text(encoding="utf-8"))
    de_rows = load_en_courses_rows(args.courses_csv)
    de_quizzes = load_en_quizzes(args.quiz_csv)
    glossary_rows = load_en_glossary(args.glossary_csv)
    de_title_to_id, _ = build_title_maps(app_courses, de_rows)

    courses = build_courses_json(app_courses, de_rows, de_quizzes)
    glossary = build_glossary_json(app_courses, de_rows, glossary_rows)
    collections = build_collections_json_de(args.collections_csv, de_title_to_id)
    cards = build_cards_json_de(args.cards_csv, de_title_to_id)

    out = args.output_dir
    write_json(out / "courses.json", courses)
    write_json(out / "glossary.json", glossary)
    write_json(out / "collections.json", collections)
    write_json(out / "cards.json", cards)

    print(f"Courses written: {len(courses)} / {len(app_courses)}")
    print(f"Glossary entries: {len(glossary)}")
    print(f"Collections written: {len(collections)}")
    print(f"Cards written: {len(cards)}")
    print(f"Output: {out}")


if __name__ == "__main__":
    main()
