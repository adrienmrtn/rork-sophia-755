#!/usr/bin/env python3
"""Translate the quiz options the engine handed back in English.

Two defects, both of which leave a reader picking between answers in a language
that is not theirs.

**The English string left standing.** The engine returned its input for a
handful of short options, so the Serbian reader of the Romeo and Juliet quiz
chooses between "Vestsajdska priča", "Mast", "The Godfather" and "Bes života".
French has the translated title everywhere these are wrong, which is how they
are found: an option that matches the English pack while French carries
something else was never translated. Options French keeps in the original --
the ship Ever Given, the group Furious Five -- match French too, and are left
alone. ``scripts/quiz_option_translations.json`` holds one rendering per
language, taken from the wording the question's own explanation already uses.

**The Serbian name pushed through a Latin/Cyrillic round trip.** The Serbian
pack is written in Latin script by transliterating the Cyrillic the engine
answers with. Names it had transliterated into Cyrillic letter by letter come
back mangled -- w to v, y to i, x to k, qu to ku -- and Karl Marx becomes "Karl
Mark", New York "Nev Iork", Whaam! "Vhaam!". These are found the same way, by
folding those substitutions away and comparing with the English pack, and
repaired from ``scripts/serbian_name_repairs.json`` across every Serbian
surface, since the same names stand in the questions, explanations, course
bodies and glossary too.

Usage:
    python scripts/fix_untranslated_quiz_options.py --check
    python scripts/fix_untranslated_quiz_options.py
    python scripts/fix_untranslated_quiz_options.py --lang sr
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

CONTENT_LOCALES = ROOT / "content" / "locales"
LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
COURSES_V2 = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"
OPTION_TABLE = ROOT / "scripts" / "quiz_option_translations.json"
NAME_TABLE = ROOT / "scripts" / "serbian_name_repairs.json"


def quizzes_path(lang: str) -> Path:
    return CONTENT_LOCALES / lang / "quizzes_v2.json"


def load_quizzes(lang: str) -> list | None:
    path = quizzes_path(lang)
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


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


def name_pattern(repairs: dict[str, str]) -> re.Pattern[str]:
    """One alternation over every mangled name, longest first.

    A single pass matters: "Karl Mark" becomes "Karl Marks", which contains the
    string it replaced, so running the replacements one after another would keep
    finding the repair it had just made.
    """
    keys = sorted(repairs, key=len, reverse=True)
    body = "|".join(re.escape(key) for key in keys)
    # A name ends where a letter stops, so "Essek" does not fire inside a word.
    return re.compile(rf"(?<![0-9A-Za-zÀ-ÿČčĆćĐđŠšŽž])(?:{body})(?![0-9A-Za-zÀ-ÿČčĆćĐđŠšŽž])")


def repair_names(text: str, pattern: re.Pattern[str], repairs: dict[str, str]) -> str:
    return pattern.sub(lambda m: repairs[m.group(0)], text)


def walk_strings(node, fix):
    """Apply ``fix`` to every string in a JSON tree, counting the changes."""
    if isinstance(node, str):
        out = fix(node)
        return out, int(out != node)
    if isinstance(node, list):
        total, result = 0, []
        for item in node:
            value, n = walk_strings(item, fix)
            result.append(value)
            total += n
        return result, total
    if isinstance(node, dict):
        total, result = 0, {}
        for key, item in node.items():
            value, n = walk_strings(item, fix)
            # A glossary key is "courseId|term" and the term half is matched
            # against the body, so repairing "Kvikveg" in the text and leaving
            # "Kueekueg" in the key only moves the broken link.
            course_id, separator, term = key.partition("|")
            if separator and term:
                fixed = fix(term)
                if fixed != term and f"{course_id}|{fixed}" not in node:
                    key = f"{course_id}|{fixed}"
                    total += 1
            result[key] = value
            total += n
        return result, total
    return node, 0


def serbian_targets() -> list[Path]:
    """Every Serbian file a mangled name can be standing in."""
    android = ROOT / "android" / "app" / "src" / "main" / "assets"
    paths = [quizzes_path("sr")]
    paths += [LOCALE_DIR / f"{kind}.sr.json" for kind in ("courses", "glossary", "collections")]
    paths += sorted((ROOT / "content" / "courses" / "sr").glob("*.json"))
    paths += sorted(COURSES_V2.glob("*.sr.json"))
    paths += sorted((android / "courses_v2" / "sr").glob("*.json"))
    paths += [
        android / "locales" / f"{kind}.sr.json"
        for kind in ("courses", "course_index", "collections", "glossary")
    ]
    return [path for path in paths if path.is_file()]


def apply_options(lang: str, table: dict[str, str], check: bool) -> int:
    """Swap each listed option for its rendering. Whole options only."""
    data = load_quizzes(lang)
    if data is None:
        return 0
    changed = 0
    for entry in data:
        for question in entry.get("quiz", []) or []:
            options = question.get("options")
            if not isinstance(options, list):
                continue
            for index, option in enumerate(options):
                wanted = table.get(option) if isinstance(option, str) else None
                if wanted is None or wanted == option:
                    continue
                options[index] = wanted
                changed += 1
    if changed and not check:
        save_json(quizzes_path(lang), data)
    return changed


def apply_serbian_names(repairs: dict[str, str], check: bool) -> tuple[int, int]:
    pattern = name_pattern(repairs)
    fix = lambda text: repair_names(text, pattern, repairs)  # noqa: E731
    strings = files = 0
    for path in serbian_targets():
        data, count = walk_strings(json.loads(path.read_text(encoding="utf-8")), fix)
        if not count:
            continue
        files += 1
        strings += count
        if not check:
            save_json(path, data)
    return strings, files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    parser.add_argument("--lang", default=",".join(ALL_CONTENT_LANGS))
    args = parser.parse_args()

    wanted = {code.strip() for code in args.lang.split(",") if code.strip()}
    options = json.loads(OPTION_TABLE.read_text(encoding="utf-8"))
    repairs = json.loads(NAME_TABLE.read_text(encoding="utf-8"))["names"]
    shared = options.get("_shared", {})

    languages = sorted(wanted - {"fr", "en"})

    total = 0
    for lang in languages:
        if lang.startswith("_") or lang not in wanted:
            continue
        table = {**shared, **options.get(lang, {})}
        if lang == "sr":
            # Serbian transcribes the names the others merely re-accent, and
            # does it below, for every Serbian surface rather than the quiz
            # alone. Re-accenting them here would hide them from that pass.
            table = {k: v for k, v in table.items() if k not in repairs}
        count = apply_options(lang, table, args.check)
        total += count
        if count:
            print(f"  {lang}: {count} option(s)")

    if "sr" in wanted:
        strings, files = apply_serbian_names(repairs, args.check)
        print(f"  sr: {strings} mangled name(s) in {files} file(s)")
        total += strings

    verb = "would repair" if args.check else "repaired"
    print(f"{verb} {total} string(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
