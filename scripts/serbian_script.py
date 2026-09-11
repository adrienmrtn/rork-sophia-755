#!/usr/bin/env python3
"""Serbian Cyrillic → Latin, and the reason Sophia ships Serbian in Latin.

Serbian is written in both scripts officially and they map 1:1, so this
conversion is lossless. We convert rather than ship Cyrillic because Google's
Serbian engine transliterates unfamiliar Latin proper nouns **letter by
letter** — "Paul Verlaine" comes back as "Паул Верлаине", "Les Fleurs du Mal"
as "Лес Флеурс ду Мал". Those are wrong in Cyrillic and very visible in a
course about French poetry.

That same letter-by-letter mapping is exactly what this function reverses, so
converting the output restores the names to their original spelling:

    Лес Флеурс ду Мал  →  Les Fleurs du Mal
    Паул Верлаине      →  Paul Verlaine

while the names the engine *did* transcribe properly land on their correct
Serbian Latin form (Шарл Бодлер → Šarl Bodler) and ordinary prose reads as
normal Serbian Latin (Bodler izvlači lepotu iz zla).

Usage:
    python scripts/serbian_script.py --check          # report what would change
    python scripts/serbian_script.py                  # convert sr content in place
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CYRILLIC_TO_LATIN = {
    "А": "A", "Б": "B", "В": "V", "Г": "G", "Д": "D", "Ђ": "Đ", "Е": "E",
    "Ж": "Ž", "З": "Z", "И": "I", "Ј": "J", "К": "K", "Л": "L", "Љ": "Lj",
    "М": "M", "Н": "N", "Њ": "Nj", "О": "O", "П": "P", "Р": "R", "С": "S",
    "Т": "T", "Ћ": "Ć", "У": "U", "Ф": "F", "Х": "H", "Ц": "C", "Ч": "Č",
    "Џ": "Dž", "Ш": "Š",
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "ђ": "đ", "е": "e",
    "ж": "ž", "з": "z", "и": "i", "ј": "j", "к": "k", "л": "l", "љ": "lj",
    "м": "m", "н": "n", "њ": "nj", "о": "o", "п": "p", "р": "r", "с": "s",
    "т": "t", "ћ": "ć", "у": "u", "ф": "f", "х": "h", "ц": "c", "ч": "č",
    "џ": "dž", "ш": "š",
}

HAS_CYRILLIC = re.compile("[Ѐ-ӿ]")


def to_latin(text: str) -> str:
    """Converts Serbian Cyrillic to Latin. Any other character passes through."""
    if not text or not HAS_CYRILLIC.search(text):
        return text
    out: list[str] = []
    for index, char in enumerate(text):
        mapped = CYRILLIC_TO_LATIN.get(char)
        if mapped is None:
            out.append(char)
            continue
        # Lj / Nj / Dž run fully uppercase inside an all-caps word (ПОНАВЉАЊЕ →
        # PONAVLJANJE), but title-case on their own (Његош → Njegoš).
        if len(mapped) == 2 and char.isupper():
            following = text[index + 1] if index + 1 < len(text) else ""
            if following and following.isupper() and following in CYRILLIC_TO_LATIN:
                mapped = mapped.upper()
        out.append(mapped)
    return "".join(out)


def walk(node):
    if isinstance(node, str):
        converted = to_latin(node)
        return converted, int(converted != node)
    if isinstance(node, list):
        total = 0
        result = []
        for item in node:
            value, n = walk(item)
            result.append(value)
            total += n
        return result, total
    if isinstance(node, dict):
        total = 0
        result = {}
        for key, item in node.items():
            new_key = to_latin(key) if isinstance(key, str) else key
            total += int(new_key != key)
            value, n = walk(item)
            result[new_key] = value
            total += n
        return result, total
    return node, 0


def targets() -> list[Path]:
    locales = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
    android = ROOT / "android" / "app" / "src" / "main" / "assets"
    paths = [locales / f"{kind}.sr.json" for kind in ("courses", "glossary", "collections")]
    paths += sorted((ROOT / "content" / "courses" / "sr").glob("*.json"))
    paths += sorted((ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2").glob("*.sr.json"))
    paths += sorted((android / "courses_v2" / "sr").glob("*.json"))
    paths += [
        ROOT / "content" / "locales" / "sr" / "quizzes_v2.json",
        ROOT / "content" / "locales" / "sr" / "legal.json",
        ROOT / "content" / "locales" / "_catalog_mt_cache" / "sr.json",
        ROOT / "content" / "locales" / "_v2_mt_cache" / "sr.json",
        ROOT / "content" / "locales" / "_quiz_v2_mt_cache" / "sr.json",
        android / "legal" / "sr.json",
    ]
    paths += [android / "locales" / f"{kind}.sr.json"
              for kind in ("courses", "course_index", "collections", "glossary")]
    return [p for p in paths if p.is_file()]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    files = 0
    strings = 0
    for path in targets():
        raw = path.read_text(encoding="utf-8")
        if not HAS_CYRILLIC.search(raw):
            continue
        converted, n = walk(json.loads(raw))
        files += 1
        strings += n
        print(f"  {path.relative_to(ROOT)}: {n} strings")
        if args.check:
            continue
        minified = "\n" not in raw.strip()[:4000]
        text = json.dumps(
            converted,
            ensure_ascii=False,
            separators=(",", ":") if minified else None,
            indent=None if minified else 2,
        )
        path.write_text(text + ("" if minified else "\n"), encoding="utf-8")

    verb = "would convert" if args.check else "converted"
    print(f"{verb} {strings} strings in {files} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
