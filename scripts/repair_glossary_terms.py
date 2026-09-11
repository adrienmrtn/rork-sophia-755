#!/usr/bin/env python3
"""Snap ``[[term]]`` spans in translated courses onto their registered glossary key.

``translate_courses_v2`` translates a glossary term on its own and then tries to
recognise it among the course's translated glossary keys with a fuzzy match. When
the two renderings diverge the match fails and the body keeps the loose
translation, so the term no longer resolves against ``glossary.<lang>.json``:

    RU body     [[Безиксдуз]]                      ← "B-612" transliterated
    RU glossary [[Б-612]]

    RU body     [[Злокачественное новообразование]] ← a medical diagnosis
    RU glossary [[Злобность]]                       ← Melville's "Malignity"

The English course body is a reliable pivot: it is built from the same French
source, block for block, and its terms are the exact keys of ``glossary.en.json``.
So the i-th span of an English block and the i-th span of the translated block are
the same term, and ``_catalog_mt_cache/<lang>.json`` — the map the glossary
catalogue itself was built from — gives that term's registered rendering.

A span is only rewritten when the replacement is a registered key for that course,
so this can never introduce a term the app cannot resolve. A block that links a
term more often than the French does keeps the occurrence standing where the
French one stands and loses the rest — the pipeline's last-resort re-insertion
sometimes drops a term into a slot it does not belong in ("stjæler den [[tyveri
af Mona Lisa (1911)]]"). Blocks missing a term are left to
``relink_dropped_terms``.

Usage:
    python scripts/repair_glossary_terms.py --check
    python scripts/repair_glossary_terms.py --lang ru
    python scripts/repair_glossary_terms.py                 # every non-FR lang
"""

from __future__ import annotations

import argparse
import collections
import json
import re
import sys
from pathlib import Path

from i18n_languages import NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "content" / "courses"
GLOSSARY_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
CATALOG_CACHE = ROOT / "content" / "locales" / "_catalog_mt_cache"

PIVOT = "en"
GLOSS = re.compile(r"\[\[(.+?)\]\]")


def registered_terms(lang: str) -> tuple[dict[str, list[str]], dict[str, dict[str, str]]]:
    """courseId -> registered keys (catalogue order), and a spelling -> key map.

    The app resolves a body term by building ``courseId|<term>`` and looking that
    up, so the **key** half of the entry is what a span has to equal — a handful
    of entries carry a ``displayTerm`` that differs from it typographically. The
    second map lets either spelling be recognised while the key is what gets
    written back.
    """
    path = GLOSSARY_DIR / f"glossary.{lang}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    by_course: dict[str, list[str]] = collections.OrderedDict()
    spellings: dict[str, dict[str, str]] = collections.defaultdict(dict)
    for key, entry in data.items():
        if "|" not in key:
            continue
        course_id, term = key.split("|", 1)
        by_course.setdefault(course_id, []).append(term)
        spellings[course_id][term] = term
        display = entry.get("displayTerm")
        if display:
            spellings[course_id].setdefault(display, term)
    return by_course, spellings


def load_cache(lang: str) -> dict[str, str]:
    path = CATALOG_CACHE / f"{lang}.json"
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def paired_strings(pivot, target, out: list) -> None:
    """Collect (pivot_string, target_container, key) for structurally aligned nodes."""
    if isinstance(pivot, list) and isinstance(target, list) and len(pivot) == len(target):
        for index, (left, right) in enumerate(zip(pivot, target)):
            if isinstance(left, str) and isinstance(right, str):
                out.append((left, target, index))
            else:
                paired_strings(left, right, out)
    elif isinstance(pivot, dict) and isinstance(target, dict):
        for key, left in pivot.items():
            if key not in target:
                continue
            right = target[key]
            if isinstance(left, str) and isinstance(right, str):
                out.append((left, target, key))
            else:
                paired_strings(left, right, out)


def drop_surplus_spans(pivot_text: str, target_text: str) -> str:
    """Unwrap the glossary links a block carries beyond what the French has.

    The course pipeline re-inserts a term whose slot did not survive by looking
    for an empty article slot, and that occasionally lands a second copy where
    the sentence does not want one. The genuine occurrence is the one sitting
    where the pivot's is, measured as a share of the paragraph, so surplus
    copies are unwrapped farthest-first.
    """
    pivot_spans = list(GLOSS.finditer(pivot_text))
    target_spans = list(GLOSS.finditer(target_text))
    surplus = len(target_spans) - len(pivot_spans)
    if surplus <= 0:
        return target_text

    pivot_at = [m.start() / max(len(pivot_text), 1) for m in pivot_spans]
    scored = []
    for index, match in enumerate(target_spans):
        here = match.start() / max(len(target_text), 1)
        distance = min((abs(here - at) for at in pivot_at), default=1.0)
        scored.append((distance, index))
    drop = {index for _, index in sorted(scored, reverse=True)[:surplus]}

    out = []
    cursor = 0
    for index, match in enumerate(target_spans):
        out.append(target_text[cursor : match.start()])
        out.append(match.group(1) if index in drop else match.group(0))
        cursor = match.end()
    out.append(target_text[cursor:])
    return "".join(out)


def repair_course(
    pivot_doc,
    target_doc,
    allowed: list[str],
    spellings: dict[str, str],
    pivot_terms: list[str],
    cache: dict[str, str],
) -> list[tuple[str, str]]:
    """Rewrite unregistered spans in place; return the (before, after) pairs."""
    allowed_set = set(allowed)
    changes: list[tuple[str, str]] = []
    slots: list[tuple[str, dict | list, object]] = []
    paired_strings(pivot_doc, target_doc, slots)

    for pivot_text, container, key in slots:
        target_text = container[key]
        trimmed = drop_surplus_spans(pivot_text, target_text)
        if trimmed != target_text:
            for extra in set(GLOSS.findall(target_text)):
                changes.append((f"[[{extra}]]", "(surplus link dropped)"))
            container[key] = target_text = trimmed

        pivot_spans = GLOSS.findall(pivot_text)
        target_spans = GLOSS.findall(target_text)
        if not target_spans or len(pivot_spans) != len(target_spans):
            continue

        replacements: dict[int, str] = {}
        for index, (pivot_term, target_term) in enumerate(zip(pivot_spans, target_spans)):
            if target_term.strip() in spellings:
                continue
            wanted = spellings.get((cache.get(pivot_term.strip()) or "").strip(), "")
            if not wanted:
                # Same catalogue, same order: fall back to the term's position.
                if len(pivot_terms) == len(allowed) and pivot_term.strip() in pivot_terms:
                    wanted = allowed[pivot_terms.index(pivot_term.strip())]
                else:
                    continue
            if wanted and wanted != target_term:
                replacements[index] = wanted

        if not replacements:
            continue

        counter = -1

        def substitute(match: re.Match[str]) -> str:
            nonlocal counter
            counter += 1
            return f"[[{replacements[counter]}]]" if counter in replacements else match.group(0)

        updated = GLOSS.sub(substitute, target_text)
        for index, wanted in replacements.items():
            changes.append((target_spans[index], wanted))
        container[key] = updated

    return changes


def run(lang: str, dry_run: bool) -> tuple[int, int]:
    target_dir = COURSES / lang
    if not target_dir.is_dir():
        return 0, 0
    allowed_by_course, spellings_by_course = registered_terms(lang)
    pivot_by_course, _ = registered_terms(PIVOT)
    cache = load_cache(lang)

    repaired_terms = 0
    repaired_files = 0
    for path in sorted(target_dir.glob("*.json")):
        course_id = path.stem
        pivot_path = COURSES / PIVOT / f"{course_id}.json"
        if not pivot_path.is_file():
            continue
        target_doc = json.loads(path.read_text(encoding="utf-8"))
        changes = repair_course(
            json.loads(pivot_path.read_text(encoding="utf-8")),
            target_doc,
            allowed_by_course.get(course_id, []),
            spellings_by_course.get(course_id, {}),
            pivot_by_course.get(course_id, []),
            cache,
        )
        if not changes:
            continue
        repaired_terms += len(changes)
        repaired_files += 1
        if dry_run:
            for before, after in changes[:3]:
                print(f"    {course_id}: {before!r} → {after!r}")
        else:
            path.write_text(
                json.dumps(target_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
    return repaired_terms, repaired_files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", help="Language code, comma separated, or all")
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    args = parser.parse_args()

    if not args.lang or args.lang == "all":
        langs = [code for code in NON_FR_LANGS if code != PIVOT]
    else:
        langs = [code.strip() for code in args.lang.split(",") if code.strip()]

    total = 0
    for lang in langs:
        terms, files = run(lang, args.check)
        total += terms
        state = "would repair" if args.check else "repaired"
        print(f"{lang}: {state} {terms} term(s) in {files} file(s)")
    print(f"{'Would repair' if args.check else 'Repaired'} {total} glossary term(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
