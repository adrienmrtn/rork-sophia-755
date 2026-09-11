#!/usr/bin/env python3
"""Align catalog-quiz capitalisation and de-duplicate answer options.

Two content problems showed up across the 14 non-FR catalogs:

  * Answer chips, chronological items, questions and explanations sometimes
    started lowercase where the French source starts uppercase — inside a
    single question one chip would read "Sovjetisk totalitarism" and the next
    "italiensk fascism". French has zero such sets, so the source is the rule.
  * Two multiple-choice questions had lost a distinction in translation and
    ended up with the same answer twice (Romanian eagle/vulture, Greek
    chorus/choregia), which makes them unanswerable.

Usage:
    python scripts/fix_quiz_capitalisation.py [--check]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALES = ROOT / "content" / "locales"
IOS_LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
ANDROID_LOCALES = ROOT / "android" / "app" / "src" / "main" / "assets" / "locales"

LANGS = ["en", "es", "de", "pt", "it", "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs"]

# Answers that are genuinely lowercase-initial brands or notations.
KEEP_LOWER = {"iPhone", "iPad", "iMac", "eBay", "iOS", "mRNA", "e=mc²", "pH"}

# Questions where the translation collapsed two distinct answers into one.
DEDUPE = {
    ("ro", "course_162_promethee_le_voleur_de_feu_q4"): {1: "Un hoitar"},
    ("el", "course_158_la_tragedie_grecque_et_le_theatre_antiqu_q6"): {2: "Η χορηγία"},
}


def upper_first(text: str, lang: str) -> str:
    if not text or not text[0].isalpha() or not text[0].islower():
        return text
    if text.split(" ")[0] in KEEP_LOWER:
        return text
    # camelCase-styled tokens ("iPhone") must keep their first letter.
    if len(text) > 1 and text[1].isupper():
        return text
    first = text[0]
    if lang == "tr" and first == "i":
        first = "İ"
    elif lang == "tr" and first == "ı":
        first = "I"
    else:
        first = first.upper()
    return first + text[1:]


def starts_lower(text: str) -> bool:
    return bool(text) and text[0].isalpha() and text[0].islower()


def fix_lang(lang: str, fr_index: dict, check_only: bool) -> int:
    path = LOCALES / lang / "quizzes_v2.json"
    blocks = json.loads(path.read_text(encoding="utf-8"))
    changed = 0

    for block in blocks:
        source = fr_index.get(block["courseId"]) or []
        for i, question in enumerate(block["quiz"]):
            french = source[i] if i < len(source) else {}

            for field in ("question", "explanation"):
                value = question.get(field) or ""
                if starts_lower(value) and not starts_lower(french.get(field) or ""):
                    fixed = upper_first(value, lang)
                    if fixed != value:
                        question[field] = fixed
                        changed += 1

            for field in ("options", "items"):
                values = question.get(field)
                if not values:
                    continue
                fr_values = french.get(field) or []
                for j, value in enumerate(values):
                    fr_value = fr_values[j] if j < len(fr_values) else ""
                    if starts_lower(value) and not starts_lower(fr_value):
                        fixed = upper_first(value, lang)
                        if fixed != value:
                            values[j] = fixed
                            changed += 1

            replacements = DEDUPE.get((lang, question["id"]))
            if replacements:
                for index, value in replacements.items():
                    if question["options"][index] != value:
                        question["options"][index] = value
                        changed += 1

    if changed and not check_only:
        path.write_text(
            json.dumps(blocks, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        # The iOS catalog and its Android copy carry the same quiz arrays.
        quiz_by_course = {b["courseId"]: b["quiz"] for b in blocks}
        ios_catalog = IOS_LOCALES / f"courses.{lang}.json"
        android_catalog = ANDROID_LOCALES / f"courses.{lang}.json"
        for catalog, minified in ((ios_catalog, False), (android_catalog, True)):
            courses = json.loads(catalog.read_text(encoding="utf-8"))
            for course in courses:
                if course["id"] in quiz_by_course:
                    course["quiz"] = quiz_by_course[course["id"]]
            # The Android assets ship minified; keep each file's own shape.
            if minified:
                text = json.dumps(courses, ensure_ascii=False, separators=(",", ":"))
            else:
                text = json.dumps(courses, ensure_ascii=False, indent=2) + "\n"
            catalog.write_text(text, encoding="utf-8")
    return changed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    fr_blocks = json.loads((LOCALES / "fr" / "quizzes_v2.json").read_text(encoding="utf-8"))
    fr_index = {b["courseId"]: b["quiz"] for b in fr_blocks}

    total = 0
    for lang in LANGS:
        n = fix_lang(lang, fr_index, args.check)
        total += n
        print(f"[{lang}] {n} fixes")
    print(f"total {total}")
    sys.exit(0)


if __name__ == "__main__":
    main()
