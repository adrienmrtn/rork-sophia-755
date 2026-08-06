#!/usr/bin/env python3
"""Repair CoursesV2 translations where glossary terms were dropped mid-sentence.

The MT pipeline sometimes loses ``ZZG`` wrappers and appends ``**[[Term]]**`` at the
end, leaving empty slots like ``de :`` / ``do ,`` / ``the ,``. This script peels
trailing glossary markers and re-inserts them at the empty-slot positions.

Usage:
    python scripts/repair_glossary_slots.py              # all non-FR langs
    python scripts/repair_glossary_slots.py --lang pt en
    python scripts/repair_glossary_slots.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "content" / "courses"

ALL_LANGS = [
    "en", "es", "de", "pt", "it",
    "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs",
]

# Article/preposition left behind when the glossary token was yanked out.
ARTICLES = (
    "de|do|da|del|the|di|du|des|um|uma|un|une|el|il|lo|la|le|les|"
    "der|die|das|dem|den|ein|eine|o|a|par|pelo|pela|au|aux|al"
)

EMPTY_PUNCT = re.compile(
    rf"\b({ARTICLES})\s*([,:])\s+(?!\[)",
    flags=re.IGNORECASE,
)
# "Através do  troca" — article followed by 2+ spaces, no glossary.
EMPTY_SPACE = re.compile(
    rf"\b({ARTICLES})\s{{2,}}(?!\[)",
    flags=re.IGNORECASE,
)
TRAILING_GLOSS = re.compile(
    r"(?:\s+)((?:\*\*)?\[\[[^\]]+\]\](?:\*\*)?)\s*$",
)


def walk_strings(obj):
    """Yield (parent_container, key_or_index, string) for in-place edits."""
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


def has_empty_slot(text: str) -> bool:
    return bool(EMPTY_PUNCT.search(text) or EMPTY_SPACE.search(text))


GLOSS_TOKEN = re.compile(r"((?:\*\*)?\[\[[^\]]+\]\](?:\*\*)?)")


def _normalize_spaces(work: str) -> str:
    work = re.sub(r"[^\S\n]{2,}", " ", work)
    work = re.sub(r"\s+([,:;])", r"\1", work)
    work = re.sub(r"([,:;])(\S)", r"\1 \2", work)
    return work


def _insert_at_empty_slot(work: str, term: str) -> str | None:
    punct_m = EMPTY_PUNCT.search(work)
    if punct_m:
        article = punct_m.group(1)
        punct = punct_m.group(2)
        insertion = f"{article} {term}{punct} "
        return work[: punct_m.start()] + insertion + work[punct_m.end() :]
    space_m = EMPTY_SPACE.search(work)
    if space_m:
        article = space_m.group(1)
        insertion = f"{article} {term} "
        return work[: space_m.start()] + insertion + work[space_m.end() :]
    return None


def repair_misplaced(text: str) -> str:
    """Move a later [[term]] back into an earlier empty article/prep slot."""
    work = text
    for _ in range(8):
        slot = EMPTY_PUNCT.search(work)
        if not slot:
            break
        rest = work[slot.end() :]
        gloss = GLOSS_TOKEN.search(rest)
        if not gloss:
            break
        term = gloss.group(1)
        abs_start = slot.end() + gloss.start()
        abs_end = slot.end() + gloss.end()
        # Keep a bare display term if the later occurrence was a sentence subject.
        inner = re.sub(r"^\*\*?\[\[|\]\]\*\*?$", "", term)
        bare = inner
        without = work[:abs_start] + bare + work[abs_end:]
        without = re.sub(r"[^\S\n]{2,}", " ", without)
        inserted = _insert_at_empty_slot(without, term)
        if inserted is None or inserted == work:
            break
        work = inserted
    return work


def repair_text(text: str) -> str | None:
    """Return repaired text, or None if unchanged / not applicable."""
    if "[[" not in text or not has_empty_slot(text):
        return None

    original = text
    work = text
    peeled: list[str] = []

    # Peel trailing glossary tokens while empty slots remain.
    while has_empty_slot(work):
        match = TRAILING_GLOSS.search(work)
        if not match:
            break
        peeled.append(match.group(1))
        work = work[: match.start()].rstrip()

    if peeled:
        # Peeled last-to-first; restore left-to-right (original FR order).
        peeled.reverse()
        for term in peeled:
            inserted = _insert_at_empty_slot(work, term)
            if inserted is not None:
                work = inserted
            else:
                work = f"{work.rstrip()} {term}"

    # Second pass: glossary parked mid-paragraph after the hole.
    work = repair_misplaced(work)
    work = _normalize_spaces(work)
    return work if work != original else None


def repair_file(path: Path, dry_run: bool) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    fixes = 0
    for container, key, value in walk_strings(data):
        repaired = repair_text(value)
        if repaired is None:
            continue
        container[key] = repaired
        fixes += 1
    if fixes and not dry_run:
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return fixes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", nargs="*", default=ALL_LANGS)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    total_files = 0
    total_fixes = 0
    for lang in args.lang:
        if lang == "fr":
            continue
        folder = COURSES / lang
        if not folder.is_dir():
            print(f"[{lang}] missing", file=sys.stderr)
            continue
        lang_files = 0
        lang_fixes = 0
        for path in sorted(folder.glob("*.json")):
            n = repair_file(path, dry_run=args.dry_run)
            if n:
                lang_files += 1
                lang_fixes += n
        print(f"[{lang}] files={lang_files} strings={lang_fixes}")
        total_files += lang_files
        total_fixes += lang_fixes

    mode = "dry-run" if args.dry_run else "wrote"
    print(f"Done ({mode}): {total_files} files, {total_fixes} strings")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
