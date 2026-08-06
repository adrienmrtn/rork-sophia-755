#!/usr/bin/env python3
"""Targeted Portuguese (pt_PT / AO90) copy fixes in CoursesV2 content.

Handles issues called out by a native reviewer:
  - mixed pre-AO90 spelling (actua/reflecte → atua/reflete)
  - missing articles before proper nouns (como Índia → como a Índia)
  - através de OTAN/NATO → através da …
  - dates missing "de" (a 8 agosto → a 8 de agosto)

Usage:
    python scripts/fix_portuguese_copy.py
    python scripts/fix_portuguese_copy.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parents[1]
COURSES_PT = ROOT / "content" / "courses" / "pt"

MONTHS = (
    "janeiro|fevereiro|março|abril|maio|junho|julho|"
    "agosto|setembro|outubro|novembro|dezembro"
)


def _preserve_case(src: str, replacement: str) -> str:
    if src and src[0].isupper():
        return replacement[0].upper() + replacement[1:]
    return replacement


def _sub_actua(match: re.Match[str]) -> str:
    suffix = match.group(1) or ""
    return _preserve_case(match.group(0), "atua" + suffix)


def _sub_reflecte(match: re.Match[str]) -> str:
    suffix = match.group(1) or ""
    return _preserve_case(match.group(0), "reflete" + suffix)


def _sub_reflectem(match: re.Match[str]) -> str:
    suffix = match.group(1) or ""
    return _preserve_case(match.group(0), "refletem" + suffix)


Rule = tuple[re.Pattern[str], str | Callable[[re.Match[str]], str]]

def _sub_atual(match: re.Match[str]) -> str:
    suffix = match.group(1) or ""
    return _preserve_case(match.group(0), "atual" + suffix)


RULES: list[Rule] = [
    # Pre-AO90 verb forms → post-1990 (reviewer: atua/actua, reflete/reflecte).
    (re.compile(r"\b[Aa]ctua(m|r|ção|ções|nte|ntes)?\b"), _sub_actua),
    (re.compile(r"\b[Rr]eflecte(-se)?\b"), _sub_reflecte),
    (re.compile(r"\b[Rr]eflectem(-se)?\b"), _sub_reflectem),
    # Adjective/adverb AO90: actual → atual (avoid touching already-fixed "atual").
    (re.compile(r"\b[Aa]ctual(mente|is|idade|idades)?\b"), _sub_atual),
    # Missing article before Índia after "como".
    (re.compile(r"\bcomo\s+Índia\b"), "como a Índia"),
    (re.compile(r"\bcomo\s+\*\*Índia\*\*"), "como a **Índia**"),
    # através de + OTAN/NATO (feminine acronym in PT).
    (re.compile(r"\batravés de\s+(OTAN|NATO)\b"), r"através da \1"),
    (re.compile(r"\batravés de\s+\*\*(OTAN|NATO)\*\*"), r"através da **\1**"),
    # Dates: "a 8 agosto" → "a 8 de agosto" (skip if "de" already present).
    (
        re.compile(
            rf"\b([aà]|em)\s+(\d{{1,2}})\s+(?!de\b)({MONTHS})\b",
            re.IGNORECASE,
        ),
        r"\1 \2 de \3",
    ),
]


def apply_rules(text: str) -> str:
    out = text
    for pattern, repl in RULES:
        out = pattern.sub(repl, out)
    return out


def walk_strings(obj):
    if isinstance(obj, dict):
        for key, value in obj.items():
            if isinstance(value, str):
                yield obj, key, value
            else:
                yield from walk_strings(value)
    elif isinstance(obj, list):
        for index, value in enumerate(obj):
            if isinstance(value, str):
                yield obj, index, value
            else:
                yield from walk_strings(value)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not COURSES_PT.is_dir():
        print("missing content/courses/pt", file=sys.stderr)
        return 1

    files = fixes = 0
    examples: list[str] = []
    for path in sorted(COURSES_PT.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        changed = 0
        for container, key, value in walk_strings(data):
            new = apply_rules(value)
            if new == value:
                continue
            container[key] = new
            changed += 1
            if len(examples) < 12:
                examples.append(f"{path.name}: {value[:70]!r} → {new[:70]!r}")
        if changed:
            files += 1
            fixes += changed
            if not args.dry_run:
                path.write_text(
                    json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )

    print(f"Portuguese copy fixes: files={files} strings={fixes}")
    for ex in examples:
        print(" ", ex)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
