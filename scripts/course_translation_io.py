#!/usr/bin/env python3
"""Shared plumbing for the course translation workflow.

The workflow keeps structure and prose strictly separate:

* ``make_translation_briefs.py`` walks a French course and emits a flat list of
  translatable *segments*, each addressed by a stable key such as
  ``s2.b1.text``, together with the glossary keys the target language allows.
* A translator (human or model) fills in one English string per segment key.
* ``apply_translation_briefs.py`` rebuilds the localised course by cloning the
  French skeleton and substituting prose at those keys.

Because the skeleton is cloned rather than edited, ids, block types, asset
names, ratios and paywall flags cannot drift, and a translation is always
structurally identical to its source.
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT_ROOT = ROOT / "content" / "courses"
LOCALES_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
FR_GLOSSARY_SWIFT = ROOT / "ios" / "Sophia" / "Services" / "GlossaryData.swift"

GLOSSARY_RE = re.compile(r"\[\[(.+?)\]\]")

#: Fields copied verbatim from the French skeleton, never translated.
STRUCTURAL_KEYS = {"id", "subject", "subcategory", "type", "asset", "image", "ratio", "free"}


def segments(course: dict) -> list[tuple[str, str]]:
    """Every translatable ``(key, french_text)`` pair of a course, in reading order."""
    out: list[tuple[str, str]] = []

    def take(key: str, value: object) -> None:
        if isinstance(value, str) and value.strip():
            out.append((key, value))

    take("title", course.get("title"))
    take("subtitle", course.get("subtitle"))
    take("description", course.get("description"))
    take("hero.hook", (course.get("hero") or {}).get("hook"))

    for s_index, section in enumerate(course.get("sections") or []):
        take(f"s{s_index}.title", section.get("title"))
        for b_index, block in enumerate(section.get("blocks") or []):
            prefix = f"s{s_index}.b{b_index}"
            take(f"{prefix}.text", block.get("text"))
            take(f"{prefix}.caption", block.get("caption"))
            take(f"{prefix}.attribution", block.get("attribution"))
            for e_index, event in enumerate(block.get("events") or []):
                take(f"{prefix}.e{e_index}.date", event.get("date"))
                take(f"{prefix}.e{e_index}.title", event.get("title"))
                take(f"{prefix}.e{e_index}.detail", event.get("detail"))
    return out


def apply_segments(course: dict, translations: dict[str, str]) -> tuple[dict, list[str]]:
    """Clone ``course`` with prose replaced by ``translations``.

    Returns the rebuilt course and the list of segment keys left untranslated.
    """
    rebuilt = json.loads(json.dumps(course))
    missing: list[str] = []

    def put(key: str, container: dict, field: str) -> None:
        if field not in container or not isinstance(container[field], str):
            return
        if not container[field].strip():
            return
        value = translations.get(key)
        if isinstance(value, str) and value.strip():
            container[field] = value
        else:
            missing.append(key)

    put("title", rebuilt, "title")
    put("subtitle", rebuilt, "subtitle")
    put("description", rebuilt, "description")
    if isinstance(rebuilt.get("hero"), dict):
        put("hero.hook", rebuilt["hero"], "hook")

    for s_index, section in enumerate(rebuilt.get("sections") or []):
        put(f"s{s_index}.title", section, "title")
        for b_index, block in enumerate(section.get("blocks") or []):
            prefix = f"s{s_index}.b{b_index}"
            put(f"{prefix}.text", block, "text")
            put(f"{prefix}.caption", block, "caption")
            put(f"{prefix}.attribution", block, "attribution")
            for e_index, event in enumerate(block.get("events") or []):
                put(f"{prefix}.e{e_index}.date", event, "date")
                put(f"{prefix}.e{e_index}.title", event, "title")
                put(f"{prefix}.e{e_index}.detail", event, "detail")
    return rebuilt, missing


def load_course(lang: str, course_id: str) -> dict:
    return json.loads((CONTENT_ROOT / lang / f"{course_id}.json").read_text(encoding="utf-8"))


def french_courses() -> list[Path]:
    return sorted((CONTENT_ROOT / "fr").glob("*.json"))


def write_course(lang: str, course: dict) -> bool:
    """Write a course source file with stable formatting. True when it changed."""
    path = CONTENT_ROOT / lang / f"{course['id']}.json"
    payload = json.dumps(course, ensure_ascii=False, indent=2) + "\n"
    if path.exists() and path.read_text(encoding="utf-8") == payload:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(payload, encoding="utf-8")
    return True


def glossary_keys_by_course(lang: str) -> dict[str, list[str]]:
    """Registered glossary display terms per course id, for a localised glossary."""
    path = LOCALES_DIR / f"glossary.{lang}.json"
    entries = json.loads(path.read_text(encoding="utf-8"))
    grouped: dict[str, list[str]] = defaultdict(list)
    for key in entries:
        course_id, _, term = key.partition("|")
        if term:
            grouped[course_id].append(term)
    return grouped


def glossary_entries(lang: str) -> dict[str, dict]:
    path = LOCALES_DIR / f"glossary.{lang}.json"
    return json.loads(path.read_text(encoding="utf-8"))


def french_glossary_by_title() -> dict[str, dict[str, str]]:
    """French glossary explanations, ``{course title: {term: explanation}}``.

    Parsed out of the generated Swift table, which is the French source of truth.
    """
    source = FR_GLOSSARY_SWIFT.read_text(encoding="utf-8")
    pattern = re.compile(
        r'"((?:[^"\\]|\\.)*)":\s*GlossaryEntry\('
        r'displayTerm:\s*"(?:[^"\\]|\\.)*",\s*'
        r"classification:\s*\.\w+,\s*"
        r'explanation:\s*"((?:[^"\\]|\\.)*)"\)'
    )
    grouped: dict[str, dict[str, str]] = defaultdict(dict)
    for key, explanation in pattern.findall(source):
        title, _, term = key.partition("|")
        if term:
            grouped[unescape_swift(title)][unescape_swift(term)] = unescape_swift(explanation)
    return grouped


def unescape_swift(value: str) -> str:
    return value.replace('\\"', '"').replace("\\\\", "\\").replace("\\n", "\n")


def glossary_terms_in(text: str) -> list[str]:
    return [match.strip() for match in GLOSSARY_RE.findall(text)]


def normalise_term(value: str) -> str:
    return "".join(char for char in value.lower() if char.isalnum())
