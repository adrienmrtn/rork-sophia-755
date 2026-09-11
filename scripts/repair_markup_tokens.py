#!/usr/bin/env python3
"""Repair MT protection tokens that leaked into translated content.

The translation pipelines hide ``**bold**`` and ``<glossary>`` spans behind
sentinel tokens (``ZZBOLDZ…ZZENDBOLDZZ``, ``ZZA0ZZ``) so the engine cannot
translate the markers themselves. Occasionally the engine mangles a sentinel —
splits it, drops a letter, or (in Cyrillic targets) transliterates it — and the
restore step no longer recognises it. What ships is then literal garbage in the
middle of a sentence: "op 27 november 1095ZZENDBOLDZZ, tijdens de…".

Every shipped locale carries a few dozen of these. This script puts the pair
back together where both halves survive, and deletes the debris where they did
not. ``ZZ`` and ``ЗЗ`` appear nowhere in the French or English sources, so
matching them is unambiguous.

Usage:
    python scripts/repair_markup_tokens.py --check
    python scripts/repair_markup_tokens.py --lang cs,ru
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from i18n_languages import ALL_CONTENT_LANGS

ROOT = Path(__file__).resolve().parents[1]

# Both halves survived, in either script → restore the pair.
PAIRED = [
    re.compile(r"ZZ\s*BOLD\s*Z{1,2}\s*(?P<inner>[^*]+?)\s*ZZ\s*END\s*BOLD\s*Z{1,3}", re.I),
    re.compile(r"ЗЗ\s*БОЛД\s*З{1,2}\s*(?P<inner>[^*]+?)\s*ЗЗ\s*ЕНД\s*БОЛД\s*З{1,3}", re.I),
]
# One half survived as a real marker → mirror it onto the mangled side.
HALVES = [
    (re.compile(r"ZZ\s*BOLD\s*Z{1,2}\s*(?P<inner>[^*]{1,120}?)\*\*", re.I), "**{inner}**"),
    (re.compile(r"\*\*(?P<inner>[^*]{1,120}?)\s*ZZ\s*END\s*BOLD\s*Z{1,3}", re.I), "**{inner}**"),
    (re.compile(r"ЗЗ\s*БОЛД\s*З{1,2}\s*(?P<inner>[^*]{1,120}?)\*\*", re.I), "**{inner}**"),
    (re.compile(r"\*\*(?P<inner>[^*]{1,120}?)\s*ЗЗ\s*ЕНД\s*БОЛД\s*З{1,3}", re.I), "**{inner}**"),
]
# Nothing recoverable: a lone sentinel, or a shredded one.
DEBRIS = [
    # "BOLD" in capitals never occurs in the source text, so Zs and digits stuck
    # to it are sentinel wreckage: ZZZZENDBOLD46ZZZZ1BOLD46ZZZZ. The leading run
    # must start with Zs, or a real year in front of the token ("1095ZZENDBOLDZZ")
    # would be swallowed with it.
    re.compile(r"Z{2,}[0-9]*(?:END)?BOLD[Z0-9]*"),
    re.compile(r"(?:END)?BOLD[Z0-9]+"),
    re.compile(r"З{2,}[0-9]*(?:ЕНД)?БОЛД[З0-9]*"),
    re.compile(r"(?:ЕНД)?БОЛД[З0-9]+"),
    # A sentinel shredded into a single blob: ZZZZA0BOLD, ZZG1XG, ЗЗА0ЗЗ…
    re.compile(r"Z{2,}\s*[A-Z]{0,2}\s*\d*\s*(?:END)?\s*BOLD\s*Z*", re.I),
    re.compile(r"З{2,}\s*[А-Я]{0,2}\s*\d*\s*(?:ЕНД)?\s*БОЛД\s*З*", re.I),
    re.compile(r"ZZ\s*(?:END)?\s*BOLD\s*Z*", re.I),
    re.compile(r"ЗЗ\s*(?:ЕНД)?\s*БОЛД\s*З*", re.I),
    re.compile(r"ZZ\s*[A-Z]{0,2}\s*\d+\s*(?:X?[A-Z])?\s*ZZ", re.I),
    re.compile(r"ЗЗ\s*[А-Я]{0,2}\s*\d+\s*(?:Х?[А-Я])?\s*ЗЗ", re.I),
    re.compile(r"Z{2,}"),
    re.compile(r"З{2,}"),
]
TIDY = [
    (re.compile(r"\*\*\s*\*\*"), ""),
    (re.compile(r"[ \t]{2,}"), " "),
    (re.compile(r"\s+([,;:.!?])"), r"\1"),
    (re.compile(r"\(\s*\)"), ""),
]
SUSPECT = re.compile(r"ZZ|ЗЗ")


def repair(text: str) -> str:
    if not SUSPECT.search(text):
        return text
    for pattern in PAIRED:
        text = pattern.sub(lambda m: f"**{m.group('inner').strip()}**", text)
    for pattern, template in HALVES:
        text = pattern.sub(lambda m: template.format(inner=m.group("inner").strip()), text)
    for pattern in DEBRIS:
        text = pattern.sub("", text)
    for pattern, replacement in TIDY:
        text = pattern.sub(replacement, text)
    return text.strip()


def walk(node):
    if isinstance(node, str):
        out = repair(node)
        return out, int(out != node)
    if isinstance(node, list):
        total, result = 0, []
        for item in node:
            value, n = walk(item)
            result.append(value)
            total += n
        return result, total
    if isinstance(node, dict):
        total, result = 0, {}
        for key, item in node.items():
            new_key = repair(key) if isinstance(key, str) else key
            total += int(new_key != key)
            value, n = walk(item)
            result[new_key] = value
            total += n
        return result, total
    return node, 0


def targets(langs: list[str]) -> list[Path]:
    locales = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
    v2 = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"
    android = ROOT / "android" / "app" / "src" / "main" / "assets"
    paths: list[Path] = []
    for lang in langs:
        paths += [locales / f"{kind}.{lang}.json" for kind in ("courses", "glossary", "collections")]
        paths += sorted((ROOT / "content" / "courses" / lang).glob("*.json"))
        paths += sorted(v2.glob(f"*.{lang}.json"))
        paths += sorted((android / "courses_v2" / lang).glob("*.json"))
        paths += [android / "locales" / f"{kind}.{lang}.json"
                  for kind in ("courses", "course_index", "collections", "glossary")]
        paths.append(ROOT / "content" / "locales" / lang / "quizzes_v2.json")
    return [p for p in paths if p.is_file()]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--lang", default=",".join(ALL_CONTENT_LANGS))
    args = parser.parse_args()

    langs = [c.strip() for c in args.lang.split(",") if c.strip()]
    files = strings = 0
    for path in targets(langs):
        raw = path.read_text(encoding="utf-8")
        if not SUSPECT.search(raw):
            continue
        repaired, n = walk(json.loads(raw))
        if not n:
            continue
        files += 1
        strings += n
        print(f"  {path.relative_to(ROOT)}: {n} strings")
        if args.check:
            continue
        minified = "\n" not in raw.strip()[:4000]
        text = json.dumps(
            repaired,
            ensure_ascii=False,
            separators=(",", ":") if minified else None,
            indent=None if minified else 2,
        )
        path.write_text(text + ("" if minified else "\n"), encoding="utf-8")

    verb = "would repair" if args.check else "repaired"
    print(f"{verb} {strings} strings in {files} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
