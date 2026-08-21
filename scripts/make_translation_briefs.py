#!/usr/bin/env python3
"""Emit per-course translation briefs for a target language.

A brief is everything a translator needs for one course and nothing else: the
French segments keyed for round-tripping, the glossary terms the French text
uses, and the exact glossary keys the target language registers for that course
(the only strings allowed inside ``[[...]]``).

Briefs are working files, not content. They are written outside the repo by
default so they never end up committed.

Usage:
    python scripts/make_translation_briefs.py --lang en
    python scripts/make_translation_briefs.py --lang en --out /tmp/briefs course_10*
"""

from __future__ import annotations

import argparse
import fnmatch
import json
from pathlib import Path

from course_translation_io import (
    french_courses,
    french_glossary_by_title,
    glossary_entries,
    glossary_keys_by_course,
    glossary_terms_in,
    load_course,
    normalise_term,
    segments,
)

DEFAULT_OUT = Path("/tmp/sophia-translation")


def rank_candidates(french_term: str, keys: list[str]) -> list[str]:
    """Order the registered keys by how plausibly they render ``french_term``.

    Only a hint: shared digits and shared capitalised tokens (proper nouns and
    numbers survive translation) push a key up. The translator makes the call.
    """
    french_digits = {token for token in french_term.split() if any(c.isdigit() for c in token)}
    french_caps = {
        normalise_term(token)
        for token in french_term.replace("(", " ").replace(")", " ").split()
        if token[:1].isupper() and len(token) > 3
    }

    def score(key: str) -> tuple[int, int, int]:
        key_digits = {token for token in key.split() if any(c.isdigit() for c in token)}
        key_caps = {
            normalise_term(token)
            for token in key.replace("(", " ").replace(")", " ").split()
            if token[:1].isupper() and len(token) > 3
        }
        return (
            -len(french_digits & key_digits),
            -len(french_caps & key_caps),
            abs(len(key) - len(french_term)),
        )

    return sorted(keys, key=score)


def build_brief(course_id: str, lang: str, allowed: list[str], fr_glossary: dict, entries: dict) -> dict:
    french = load_course("fr", course_id)
    used = []
    seen = set()
    for _, text in segments(french):
        for term in glossary_terms_in(text):
            if term not in seen:
                seen.add(term)
                used.append(term)

    course_glossary = fr_glossary.get(french.get("title", ""), {})
    glossary_brief = []
    for term in used:
        glossary_brief.append(
            {
                "french_term": term,
                "french_definition": course_glossary.get(term, ""),
                "suggested_keys": rank_candidates(term, allowed)[:6],
            }
        )

    allowed_with_definitions = [
        {
            "key": key,
            "definition": (entries.get(f"{course_id}|{key}") or {}).get("explanation", ""),
        }
        for key in allowed
    ]

    return {
        "course_id": course_id,
        "language": lang,
        "subject": french.get("subject"),
        "glossary_terms_used_in_french": glossary_brief,
        "allowed_glossary_keys": allowed_with_definitions,
        "segments": [
            {"key": key, "french": text} for key, text in segments(french)
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("patterns", nargs="*", help="Course id glob(s)")
    parser.add_argument("--lang", required=True)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    allowed_by_course = glossary_keys_by_course(args.lang)
    fr_glossary = french_glossary_by_title()
    entries = glossary_entries(args.lang)

    out_dir = args.out / args.lang / "briefs"
    out_dir.mkdir(parents=True, exist_ok=True)

    written = 0
    for source in french_courses():
        course_id = source.stem
        if args.patterns and not any(fnmatch.fnmatch(course_id, p) for p in args.patterns):
            continue
        brief = build_brief(
            course_id, args.lang, sorted(allowed_by_course.get(course_id, [])), fr_glossary, entries
        )
        (out_dir / f"{course_id}.json").write_text(
            json.dumps(brief, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        written += 1

    print(f"Wrote {written} brief(s) to {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
