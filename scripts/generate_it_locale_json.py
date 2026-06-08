#!/usr/bin/env python3
"""Generate Italian locale JSON bundles from CSV exports + French CourseData IDs."""

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
    build_title_maps,
    load_en_courses_rows,
    load_en_glossary,
    load_en_quizzes,
    make_description,
    read_csv,
    write_locale_bundle,
)
from import_content_from_csv import lesson_ids_for_course, normalize_content, parse_all_courses  # noqa: E402

COURSE_DATA = ROOT / "ios/Sophia/Services/CourseData.swift"
DEFAULT_LANG = "it"

SUBJECT_IT_MAP = {
    "Storia": "histoire",
    "Scienze": "sciences",
    "Letteratura": "litterature",
    "Arte": "art",
    "Mitologia": "mythologie",
    "Comprendere il mondo attuale": "comprendreLeMonde",
}

CLASSIFICATION_IT_MAP = {
    "Riferimento storico": "referenceHistorique",
    "Concetto": "concept",
    "Evento correlato": "evenementConnexe",
    "Evento": "evenementConnexe",
    "Personaggio": "personnage",
    "Luogo": "lieuInstitution",
    "Luogo / istituzione": "lieuInstitution",
    "Istituzione": "lieuInstitution",
    "Movimento": "concept",
    "Opera": "referenceHistorique",
    "Altro": "concept",
    "Data": "referenceHistorique",
    "Legge": "referenceHistorique",
    "Teoria": "concept",
    "Tecnica": "concept",
    "Oggetto": "referenceHistorique",
    "Periodo": "referenceHistorique",
    "Acronimo": "concept",
}

RARITY_IT_MAP = {
    "Comune": "commune",
    "Rara": "rare",
    "Epica": "epique",
    "Leggendaria": "legendaire",
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


def resolve_course_titles_it(titles: str, title_map: dict[str, str]) -> list[str] | None:
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
    it_rows: list[dict[str, str]],
    it_quizzes: dict[str, list[dict[str, object]]],
) -> list[dict[str, object]]:
    courses: list[dict[str, object]] = []
    for app_course, it_row in zip(app_courses, it_rows):
        it_title = (it_row.get("Titre") or "").strip()
        subject_label = (it_row.get("Matière") or "").strip()
        subject_key = SUBJECT_IT_MAP.get(subject_label)
        if not subject_key:
            raise ValueError(f"Unknown IT subject: {subject_label!r} for {it_title}")

        parts: list[tuple[str, str]] = []
        for idx in range(1, 5):
            part_title = normalize_content(it_row.get(f"Partie {idx} Titre"))
            part_content = normalize_content(it_row.get(f"Partie {idx} Contenu"))
            if not part_content:
                continue
            parts.append((part_title or f"Parte {idx}", part_content))

        intro = normalize_content(it_row.get("Intro"))
        quiz_questions = it_quizzes.get(it_title)
        if not intro or not parts or not quiz_questions:
            continue

        course_id = str(app_course["id"])
        lesson_ids = lesson_ids_for_course(
            course_id,
            list(app_course["lesson_ids"]),
            len(parts),
        )
        lessons = [
            {"id": lesson_ids[0], "title": "Introduzione", "content": intro},
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
                "title": it_title,
                "description": make_description(intro),
                "subject": subject_key,
                "subcategory": normalize_content(it_row.get("Sous-catégorie")),
                "lessons": lessons,
                "quiz": quiz,
            }
        )
    return courses


def build_glossary_json(
    app_courses: list[dict[str, object]],
    it_rows: list[dict[str, str]],
    glossary_rows: dict[str, list[dict[str, str]]],
) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for app_course, it_row in zip(app_courses, it_rows):
        it_title = (it_row.get("Titre") or "").strip()
        course_id = str(app_course["id"])
        for row in glossary_rows.get(it_title, []):
            classification = CLASSIFICATION_IT_MAP.get(row["classification"])
            if not classification:
                raise ValueError(
                    f"Unknown IT classification: {row['classification']!r} ({it_title})"
                )
            term = row["term"]
            entries[f"{course_id}|{term}"] = {
                "displayTerm": term,
                "classification": classification,
                "explanation": row["explanation"],
            }
    return entries


def build_cards_json_it(path: Path, title_map: dict[str, str]) -> list[dict[str, object]]:
    cards: list[dict[str, object]] = []
    for row in read_csv(path):
        card_id = (row.get("id") or "").strip()
        name = (row.get("Nom") or "").strip()
        rarity_label = (row.get("Rareté") or row.get("Rarete") or "").strip()
        rarity = RARITY_IT_MAP.get(rarity_label)
        course_titles = row.get("Cours") or ""
        course_ids = resolve_course_titles_it(course_titles, title_map)
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


def build_collections_json_it(path: Path, title_map: dict[str, str]) -> list[dict[str, object]]:
    collections: list[dict[str, object]] = []
    for row in read_csv(path):
        collection_id = (row.get("id") or "").strip()
        title = (row.get("Titre") or "").strip()
        description = normalize_content(row.get("Description"))
        course_titles = row.get("Cours") or ""
        course_ids = resolve_course_titles_it(course_titles, title_map)
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
    source = ROOT / "content/locales/it/source"
    parser = argparse.ArgumentParser()
    parser.add_argument("--courses-csv", type=Path, default=source / "Excel_cours_systeme_modifie_IT_626c.csv")
    parser.add_argument("--quiz-csv", type=Path, default=source / "Excel_QCM_IT_38dc.csv")
    parser.add_argument("--glossary-csv", type=Path, default=source / "Glossaire_culture_generale_modifie_IT_8e63.csv")
    parser.add_argument("--collections-csv", type=Path, default=source / "Collections_IT_441a.csv")
    parser.add_argument("--cards-csv", type=Path, default=source / "Cartes_IT_a872.csv")
    parser.add_argument("--lang", default=DEFAULT_LANG)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    app_courses = parse_all_courses(COURSE_DATA.read_text(encoding="utf-8"))
    it_rows = load_en_courses_rows(args.courses_csv)
    it_quizzes = load_en_quizzes(args.quiz_csv)
    glossary_rows = load_en_glossary(args.glossary_csv)
    it_title_to_id, _ = build_title_maps(app_courses, it_rows)

    courses = build_courses_json(app_courses, it_rows, it_quizzes)
    glossary = build_glossary_json(app_courses, it_rows, glossary_rows)
    collections = build_collections_json_it(args.collections_csv, it_title_to_id)
    cards = build_cards_json_it(args.cards_csv, it_title_to_id)

    lang = args.lang
    for name, payload in {
        "courses": courses,
        "glossary": glossary,
        "collections": collections,
        "cards": cards,
    }.items():
        write_locale_bundle(lang, name, payload)

    print(f"Courses written: {len(courses)} / {len(app_courses)}")
    print(f"Glossary entries: {len(glossary)}")
    print(f"Collections written: {len(collections)}")
    print(f"Cards written: {len(cards)}")
    print(f"Output: courses.{lang}.json, glossary.{lang}.json, ...")


if __name__ == "__main__":
    main()
