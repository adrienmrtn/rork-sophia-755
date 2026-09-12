#!/usr/bin/env python3
"""Translate the ``**bold**`` spans the engine handed back as its own input.

``protect_markup`` wraps the inside of every bold span in sentinels before the
text goes to the engine, and for a short span that is often all the engine does
with it: the Swedish lesson on Stendhal opens on "**The Red and the Black** är
mycket mer än ett enkelt skönlitterärt verk", the Danish one on the Arabian
Nights on "**One Thousand and One Nights** udgør et af de mest fascinerende
monumenter".

They are found by comparing with the English pack -- a span that matches it
exactly and carries an English function word was never translated -- and each
one is written out in ``scripts/bold_span_translations.json`` in the title that
language actually uses ("Rött och svart", "Tusind og en nat"). Spans that stay
in the original everywhere are listed there under "keep", with the reason: a Bob
Dylan song, a group's name, a genre whose glossary entry is registered under it.

Some entries carry the words around the span because the sentence needs fixing
with it. "The execution of the **Mona Lisa** begins in Florence" means the
making of the painting, and thirteen languages read it as a death sentence:
Swedish "Avrättningen av", Czech and Slovak "Poprava", Danish and Norwegian
"Henrettelsen", Russian "Казнь", Hebrew "ההוצאה להורג". Elsewhere the engine
moved a title's first word and left its first letter behind, so Czech reads
"**OTisíc a jedné noci**".

English is repaired too: it is the pack every other language is translated from,
and the doubled article in "the **the Mona Lisa**" and the two links that name
no glossary entry anywhere -- "<The energy transition>", "<The future of work>"
-- are its own.

``--audit`` is the regression guard: it re-runs the comparison rather than the
table, so a span the pipeline leaves in English tomorrow fails even though it is
in nobody's list. It exits non-zero on anything it finds.

Usage:
    python scripts/fix_untranslated_bold_spans.py --check
    python scripts/fix_untranslated_bold_spans.py
    python scripts/fix_untranslated_bold_spans.py --lang sv,da,nb
    python scripts/fix_untranslated_bold_spans.py --audit
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from i18n_languages import ALL_CONTENT_LANGS  # noqa: E402

TABLE = ROOT / "scripts" / "bold_span_translations.json"
LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
COURSES_V2 = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"


def targets(lang: str) -> list[Path]:
    """Every file a lesson body for this language can be sitting in."""
    android = ROOT / "android" / "app" / "src" / "main" / "assets"
    paths = [LOCALE_DIR / f"courses.{lang}.json"]
    paths += sorted((ROOT / "content" / "courses" / lang).glob("*.json"))
    paths += sorted(COURSES_V2.glob(f"*.{lang}.json"))
    paths += sorted((android / "courses_v2" / lang).glob("*.json"))
    paths += [android / "locales" / f"courses.{lang}.json"]
    return [path for path in paths if path.is_file()]


def save_json(path: Path, data) -> None:
    raw = path.read_text(encoding="utf-8")
    minified = "\n" not in raw.strip()[:4000]
    text = json.dumps(
        data,
        ensure_ascii=False,
        separators=(",", ":") if minified else None,
        indent=None if minified else 2,
    )
    path.write_text(text + ("" if minified else "\n"), encoding="utf-8")


def walk(node, fix):
    if isinstance(node, str):
        out = fix(node)
        return out, int(out != node)
    if isinstance(node, list):
        total, result = 0, []
        for item in node:
            value, n = walk(item, fix)
            result.append(value)
            total += n
        return result, total
    if isinstance(node, dict):
        total, result = 0, {}
        for key, item in node.items():
            value, n = walk(item, fix)
            result[key] = value
            total += n
        return result, total
    return node, 0


def replacer(pairs: list[list[str]]):
    """Apply the pairs in order, longest first within each position.

    Order matters twice over: a phrase entry has to reach the sentence before
    the bare span inside it is swapped out from under it, and a longer span has
    to match before a shorter one it contains ("Seven Voyages of Sinbad the
    Sailor" before "Sinbad the Sailor").
    """
    ordered = sorted(pairs, key=lambda pair: len(pair[0]), reverse=True)
    phrases = [pair for pair in pairs if not pair[0].startswith("**")]
    spans = [pair for pair in ordered if pair[0].startswith("**")]

    def fix(text: str) -> str:
        for old, new in phrases + spans:
            if old in text:
                text = text.replace(old, new)
        return text

    return fix


BOLD = re.compile(r"\*\*(.+?)\*\*", re.S)


def all_spans(node, out: list[str]) -> list[str]:
    if isinstance(node, str):
        out.extend(BOLD.findall(node))
    elif isinstance(node, list):
        for item in node:
            all_spans(item, out)
    elif isinstance(node, dict):
        for item in node.values():
            all_spans(item, out)
    return out


def audit(languages: set[str], keep: dict[str, str]) -> int:
    """Report every bold span still identical to its English counterpart.

    Both content sets: the catalogue lesson bodies iOS reads, and the CoursesV2
    course files, which are where Android takes its lesson text from.
    """
    from check_course_translation import ENGLISH_LEFTOVERS  # noqa: PLC0415

    def untranslated(span: str, source: set[str]) -> bool:
        if span not in source or span in keep:
            return False
        # A bare name carries no English to leave standing -- "New Orleans" is
        # spelled that way in Danish too. An article or a preposition is another
        # matter.
        if not re.search(r"\b[a-z]{3,}\b", span):
            return False
        return bool(ENGLISH_LEFTOVERS.search(f" {span} "))

    english = {
        course["id"]: course
        for course in json.loads((LOCALE_DIR / "courses.en.json").read_text(encoding="utf-8"))
    }
    found = 0
    for lang in sorted(languages - {"en", "fr"}):
        path = LOCALE_DIR / f"courses.{lang}.json"
        if path.is_file():
            for course in json.loads(path.read_text(encoding="utf-8")):
                source_course = english.get(course["id"])
                if not source_course:
                    continue
                lessons = source_course.get("lessons") or []
                for index, lesson in enumerate(course.get("lessons") or []):
                    if index >= len(lessons):
                        continue
                    source = set(BOLD.findall(lessons[index].get("content") or ""))
                    for span in BOLD.findall(lesson.get("content") or ""):
                        if untranslated(span, source):
                            print(
                                f"{lang} {course['id']} lesson {index}: "
                                f"**{span}** is still English"
                            )
                            found += 1
        for translated in sorted(COURSES_V2.glob(f"*.{lang}.json")):
            source_path = COURSES_V2 / f"{translated.name[: -len(lang) - 6]}.en.json"
            if not source_path.is_file():
                continue
            source = set(all_spans(json.loads(source_path.read_text(encoding="utf-8")), []))
            for span in all_spans(json.loads(translated.read_text(encoding="utf-8")), []):
                if untranslated(span, source):
                    print(f"{lang} {translated.name}: **{span}** is still English")
                    found += 1
    if found:
        print(f"FAILED {found} untranslated bold span(s)")
        return 1
    print("bold spans OK: none left reading as the English pack")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    parser.add_argument(
        "--audit",
        action="store_true",
        help="Fail on any span still identical to the English, table or no table",
    )
    parser.add_argument("--lang", default=",".join(ALL_CONTENT_LANGS))
    args = parser.parse_args()

    payload = json.loads(TABLE.read_text(encoding="utf-8"))
    table = payload["replacements"]
    if args.audit:
        wanted = {code.strip() for code in args.lang.split(",") if code.strip()}
        return audit(wanted, payload["keep"])
    wanted = {code.strip() for code in args.lang.split(",") if code.strip()}

    strings = files = 0
    for lang in sorted(wanted):
        pairs = table.get(lang)
        if not pairs:
            continue
        fix = replacer(pairs)
        changed = touched = 0
        for path in targets(lang):
            data, count = walk(json.loads(path.read_text(encoding="utf-8")), fix)
            if not count:
                continue
            touched += 1
            changed += count
            if not args.check:
                save_json(path, data)
        if changed:
            print(f"  {lang}: {changed} string(s) in {touched} file(s)")
        strings += changed
        files += touched

    verb = "would translate" if args.check else "translated"
    print(f"{verb} {strings} span(s) in {files} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
