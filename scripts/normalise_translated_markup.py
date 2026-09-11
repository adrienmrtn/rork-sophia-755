#!/usr/bin/env python3
"""Normalise the mechanical markup and typography defects MT leaves behind.

Every rule here clears a specific finding from
``scripts/check_course_translation.py``, and only the mechanical ones — nothing
that needs judgement about meaning:

  bold-empty            ``****`` and ``** **`` are dropped.
  bold-whitespace       whitespace inside a bold span is moved outside it.
  bold-punctuation      a trailing , ; : ! ? (or a sentence-final period that is
                        not an abbreviation) is moved outside the span.
  forbidden-char        stray em/en dashes become hyphens and curly apostrophes
                        become straight ones, matching the shipped locales.
                        Russian keeps both dashes — they are its punctuation.
                        An orphan French guillemet is closed or dropped in the
                        languages that do not use guillemets at all.
  thousands separator   the French "30 000" takes the locale's separator.
  space-before-punctuation / double-space / edge-whitespace.
  doubled punctuation  ",," / ",:" / ",." collapse to the mark that belongs,
                       and a mark glued to the next word or to **bold** gains
                       the space it is missing.
  glossary-unregistered
                       a glossary entry's key half gets the same treatment as
                       its displayTerm, so a body term that lost an en dash
                       still resolves to it exactly.

Usage:
    python scripts/normalise_translated_markup.py --check
    python scripts/normalise_translated_markup.py --lang da,nb,ru
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from check_course_translation import ABBREVIATION_TAIL_RE, rules_for  # noqa: E402
from i18n_languages import ALL_CONTENT_LANGS  # noqa: E402

BOLD = re.compile(r"\*\*(.*?)\*\*", re.S)
THOUSANDS = re.compile(r"\b(\d{1,3})((?: \d{3})+)\b")
TRAILING_PUNCT = ",;:!?"


def thousands_separator(lang: str) -> str | None:
    """The character this language groups thousands with, or None to leave it."""
    rules = rules_for(lang)
    if not rules.flag_space_thousands:
        return None
    return "," if "comma" in rules.thousands_hint else "."


def fix_bold(text: str) -> str:
    # An odd number of markers means the source pairing is already broken
    # (check_course_translation reports it as bold-unbalanced). Rewriting spans
    # there pairs them differently from how they read and shifts the boundary,
    # so leave those strings entirely alone.
    if text.count("**") % 2:
        return text

    def repl(match: re.Match[str]) -> str:
        span = match.group(1)
        if not span.strip():
            return ""
        lead = span[: len(span) - len(span.lstrip())]
        trail = span[len(span.rstrip()):]
        span = span.strip()
        moved = ""
        while span and (
            span[-1] in TRAILING_PUNCT
            or (span[-1] == "." and not ABBREVIATION_TAIL_RE.search(span))
        ):
            moved = span[-1] + moved
            span = span[:-1].rstrip()
        if not span:
            return f"{lead}{moved}{trail}"
        return f"{lead}**{span}**{moved}{trail}"

    return BOLD.sub(repl, text)


#: Closing quote for the languages whose rules forbid guillemets, keyed by the
#: opening mark the engine actually produced. Croatian closes „…" with a right
#: double quote; Slovak and Serbian close „…" with a left one.
CLOSING_QUOTE = {
    "hr": {'"': '"', "\u201e": "\u201d", "\u201c": "\u201d", "\u201d": "\u201d"},
    "sk": {'"': '"', "\u201e": "\u201c", "\u201c": "\u201d", "\u201d": "\u201d"},
    "sr": {'"': '"', "\u201e": "\u201c", "\u201c": "\u201d", "\u201d": "\u201d"},
}
QUOTE_MARKS = '"\u201e\u201c\u201d'
ORPHAN_CLOSE = re.compile(r"\s*\u00bb")


def fix_guillemets(text: str, lang: str) -> str:
    """Resolve a French closing guillemet MT left behind.

    The engine converts the opening « of a French quotation to the target's own
    mark and translates the quoted sentence, then strands the closing » after
    it: ``"Ima nešto pokvareno u Kraljevini Danskoj. » Predstava…``. Whether the
    » is the real end of the quotation or a duplicate of a close the engine
    already emitted is decided by what the string itself contains.
    """
    closers = CLOSING_QUOTE.get(lang)
    if not closers or "\u00bb" not in text:
        return text

    marks = [index for index, char in enumerate(text) if char in QUOTE_MARKS]
    orphan = ORPHAN_CLOSE.search(text)
    if orphan is None or not marks:
        # Nothing to pair it with: the guillemet is noise either way.
        return ORPHAN_CLOSE.sub("", text)

    opening = text[marks[0]]
    closing = closers.get(opening, opening)
    before = marks[-1]

    if len(marks) % 2:
        # A quotation is still open — the » is where it ends.
        return text[: orphan.start()] + closing + text[orphan.end() :]
    if text[before + 1 : orphan.start()].strip():
        # Already closed, but early: the engine ended the quote mid-way and the
        # » marks the real end, so move that closing mark onto it.
        return (
            text[:before]
            + text[before + 1 : orphan.start()]
            + closing
            + text[orphan.end() :]
        )
    # Closed immediately before the »: a plain duplicate.
    return text[: orphan.start()] + text[before + 1 : orphan.start()] + text[orphan.end() :]


def normalise(text: str, lang: str, separator: str | None, allowed: set[str]) -> str:
    out = fix_guillemets(fix_bold(text), lang)
    if "—" not in allowed:
        out = out.replace("—", "-")
    if "–" not in allowed:
        out = out.replace("–", "-")
    out = out.replace("’", "'").replace("‘", "'").replace(" ", " ")
    if separator:
        out = THOUSANDS.sub(
            lambda m: m.group(1) + m.group(2).replace(" ", separator), out
        )
    out = re.sub(r"[ \t]{2,}", " ", out)
    out = re.sub(r"\s+([,;:!?])(?!\))", r"\1", out)
    # A comma the engine left in front of the real mark ("kirkefar,:", "let**,.")
    out = re.sub(r",\s*([,;:.!?])", r"\1", out)
    # A mark glued to what follows it ("ekstremno:**430 °C**").
    out = re.sub(r"([,;:])(?=\*\*|\[\[)", r"\1 ", out)
    return out.strip()


def walk(node, lang: str, separator: str | None, allowed: set[str]):
    if isinstance(node, str):
        value = normalise(node, lang, separator, allowed)
        return value, int(value != node)
    if isinstance(node, list):
        total, result = 0, []
        for item in node:
            value, n = walk(item, lang, separator, allowed)
            result.append(value)
            total += n
        return result, total
    if isinstance(node, dict):
        total, result = 0, {}
        for key, item in node.items():
            value, n = walk(item, lang, separator, allowed)
            # A glossary key is "courseId|term" and the term half is matched
            # against the body, so it has to be spelled the same way the body is
            # — the displayTerm beside it is already normalised.
            course_id, sep, term = key.partition("|")
            if sep and term:
                fixed = normalise(term, lang, separator, allowed)
                if fixed != term and f"{course_id}|{fixed}" not in node:
                    key = f"{course_id}|{fixed}"
                    total += 1
            result[key] = value
            total += n
        return result, total
    return node, 0


def targets(lang: str) -> list[Path]:
    locales = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
    v2 = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"
    android = ROOT / "android" / "app" / "src" / "main" / "assets"
    paths = [locales / f"{kind}.{lang}.json" for kind in ("courses", "glossary", "collections")]
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

    files = strings = 0
    for lang in [c.strip() for c in args.lang.split(",") if c.strip()]:
        if lang == "fr":
            continue  # French is authored, never normalised
        separator = thousands_separator(lang)
        allowed = set(getattr(rules_for(lang), "forbidden_chars", {}))
        allowed = {"—", "–"} - allowed
        for path in targets(lang):
            raw = path.read_text(encoding="utf-8")
            data, n = walk(json.loads(raw), lang, separator, allowed)
            if not n:
                continue
            files += 1
            strings += n
            if args.check:
                continue
            minified = "\n" not in raw.strip()[:4000]
            text = json.dumps(
                data,
                ensure_ascii=False,
                separators=(",", ":") if minified else None,
                indent=None if minified else 2,
            )
            path.write_text(text + ("" if minified else "\n"), encoding="utf-8")
        print(f"  {lang}: {strings} strings so far")

    verb = "would normalise" if args.check else "normalised"
    print(f"{verb} {strings} strings in {files} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
