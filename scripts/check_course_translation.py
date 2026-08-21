#!/usr/bin/env python3
"""Validate localised course content against the French source and the style guide.

Every rule here maps to a rule in ``content/TRANSLATION_GUIDE_EN.md``. The
checks are deliberately mechanical: they catch the failure modes the machine
translation pipeline used to produce (glossary terms parked at the end of a
paragraph, empty article slots, unbalanced markers, leaked protection tokens,
untranslated number formats) plus the typography rules we impose on the English
edition.

Usage:
    python scripts/check_course_translation.py --lang en
    python scripts/check_course_translation.py --lang en --verbose course_10*
    python scripts/check_course_translation.py --lang en --json report.json
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from collections import Counter
from pathlib import Path

from course_translation_io import (
    CONTENT_ROOT,
    glossary_keys_by_course,
    glossary_terms_in,
    load_course,
    normalise_term,
    segments,
)

BOLD_RE = re.compile(r"\*\*")
GLOSSARY_SPAN_RE = re.compile(r"\[\[(.+?)\]\]")

FORBIDDEN_CHARS = {
    "\u2014": "em dash",
    "\u2013": "en dash",
    "\u00ab": "French opening guillemet",
    "\u00bb": "French closing guillemet",
    "\u200b": "zero-width space",
    "\u00a0": "non-breaking space",
    "\u2019": "curly apostrophe",
    "\u2018": "curly opening single quote",
    "\ufeff": "byte-order mark",
}

#: Function words that must never be left stranded before punctuation. This is
#: the fingerprint of a glossary term that was deleted from mid-sentence.
STRANDED_EN = (
    "the|a|an|of|by|in|to|for|with|from|and|or|as|on|at|that|this|its|his|her|their|"
    "into|about|through|during|between|against|than|but|is|was|were|are"
)
STRANDED_RE = re.compile(rf"\b({STRANDED_EN})\s*([,;:.!?])", re.IGNORECASE)

FRENCH_LEFTOVERS = re.compile(
    r"\b(les|des|une|dans|avec|pour|sont|qui|que|quoi|aussi|si\u00e8cle|si\u00e8cles|"
    r"ainsi|alors|entre|leur|leurs|cette|cet|ces|plus|tout|tous|toute|toutes|"
    r"apr\u00e8s|avant|depuis|jusqu|chez|sous|vers|autour|contre|pendant|selon|"
    r"est\-\u00e0\-dire|c'est|n'est|d'un|d'une|l'un|au|aux|du)\b"
)
# Words that are legitimate English or fixed proper-noun parts and must not trip
# the French-leftover heuristic.
FRENCH_ALLOWLIST = re.compile(
    r"\b(a|an|the|Les|Le|La|L'|Du|De|Des|Sans|Salon|Jardin|Champ|Champs|Mont|Sacr\u00e9|"
    r"Coeur|C\u0153ur|Arc|Palais|Louvre|Orsay|Comm|Prix|Grand|Petit|Notre|Dame|Rue|Place|"
    r"Cit\u00e9|\u00cele|Ile|Saint|Sainte|Bois|Beaux|Arts|Nouvelle|Vague|Guernica)\b"
)

VOWEL_SOUND_EXCEPTIONS_CONSONANT = ("one", "once", "uni", "use", "user", "usu", "euro", "eul")
VOWEL_SOUND_EXCEPTIONS_VOWEL = ("hour", "honest", "honor", "honour", "heir")

# Articles that must not precede a glossary key that already carries one.
LEADING_ARTICLES = ("the ", "a ", "an ")

FRENCH_THOUSANDS_RE = re.compile(r"\b\d{1,3}(?: \d{3})+\b")
FRENCH_DECIMAL_RE = re.compile(r"\b\d+,\d+\s*(%|km|kg|m|cm|mm|\u00b0)")
ROMAN_CENTURY_RE = re.compile(r"\b[IVXL]+(?:e|\u00e8me|er)\b")
BC_FRENCH_RE = re.compile(r"av\.?\s*J\.?-?C|apr\.?\s*J\.?-?C")
LEAKED_TOKEN_RE = re.compile(r"ZZ[A-Z0-9]*|__[A-Z]+__|\{\{\s*\w+\s*\}\}")


class Finding:
    __slots__ = ("course_id", "key", "rule", "detail")

    def __init__(self, course_id: str, key: str, rule: str, detail: str) -> None:
        self.course_id = course_id
        self.key = key
        self.rule = rule
        self.detail = detail

    def as_dict(self) -> dict:
        return {"course": self.course_id, "segment": self.key, "rule": self.rule, "detail": self.detail}


def snippet(text: str, around: int, width: int = 90) -> str:
    start = max(0, around - width // 2)
    return ("..." if start else "") + text[start : start + width].replace("\n", " ") + "..."


def bold_spans(text: str) -> list[str]:
    """The contents of each ``**...**`` pair, ignoring an unpaired trailing marker."""
    parts = text.split("**")
    return parts[1:-1:2] if len(parts) % 2 else []


def article_before(text: str, span_start: int) -> str | None:
    before = text[:span_start].rstrip()
    before = re.sub(r"(\*\*|\*|==)$", "", before).rstrip()
    match = re.search(r"\b(the|a|an)$", before, re.IGNORECASE)
    return match.group(1).lower() if match else None


def starts_with_vowel_sound(term: str) -> bool:
    word = re.sub(r"^[^A-Za-z]+", "", term).lower()
    if not word:
        return False
    if word.startswith(VOWEL_SOUND_EXCEPTIONS_VOWEL):
        return True
    if word.startswith(VOWEL_SOUND_EXCEPTIONS_CONSONANT):
        return False
    return word[0] in "aeiou"


def check_segment(
    course_id: str,
    key: str,
    french: str,
    english: str,
    allowed: set[str],
    allowed_norm: dict[str, str],
    findings: list[Finding],
) -> None:
    def report(rule: str, detail: str) -> None:
        findings.append(Finding(course_id, key, rule, detail))

    if not english.strip():
        report("empty", "translated segment is empty")
        return

    # --- markup integrity -------------------------------------------------
    if len(BOLD_RE.findall(english)) % 2:
        report("bold-unbalanced", snippet(english, 0, 120))
    if english.count("[[") != english.count("]]"):
        report("glossary-unbalanced", snippet(english, 0, 120))
    for span in bold_spans(english):
        if span != span.strip():
            report("bold-whitespace", f"bold span wraps whitespace: {span!r}")
        elif span.endswith((",", ";", ":", "!", "?")) or (span.endswith(".") and " " in span.rstrip(".")):
            report("bold-punctuation", f"bold span swallows punctuation: {span!r}")
        elif not span:
            report("bold-empty", "empty bold span")

    # --- glossary ---------------------------------------------------------
    french_terms = glossary_terms_in(french)
    english_terms = glossary_terms_in(english)
    if len(french_terms) != len(english_terms):
        report(
            "glossary-count",
            f"French has {len(french_terms)} term(s), translation has {len(english_terms)}",
        )

    for match in GLOSSARY_SPAN_RE.finditer(english):
        term = match.group(1)
        if term.strip() != term:
            report("glossary-padding", f"term has surrounding whitespace: {term!r}")
        stripped = term.strip()
        if stripped not in allowed:
            alternative = allowed_norm.get(normalise_term(stripped))
            hint = f" (did you mean {alternative!r}?)" if alternative else ""
            report("glossary-unregistered", f"{stripped!r} is not a glossary key for this course{hint}")

        tail = english[match.end() : match.end() + 3]
        if re.match(r"(s\b|'s|s')", tail):
            report("glossary-inflected", f"suffix attached after ]]: {snippet(english, match.end())}")

        article = article_before(english, match.start())
        if article:
            lowered = stripped.lower()
            if lowered.startswith(LEADING_ARTICLES):
                report(
                    "glossary-double-article",
                    f"{article!r} precedes a key that already starts with an article: {stripped!r}",
                )
            elif article in {"a", "an"}:
                vowel = starts_with_vowel_sound(stripped)
                if article == "a" and vowel:
                    report("glossary-article-a-an", f"'a' before vowel sound: a {stripped!r}")
                if article == "an" and not vowel:
                    report("glossary-article-a-an", f"'an' before consonant sound: an {stripped!r}")

    # A term that sat mid-sentence in French but ends the paragraph in English
    # was dropped from its slot and appended -- the defining bug of the old
    # machine translation pipeline.
    if len(french_terms) == len(english_terms):
        for index, (fr_span, en_span) in enumerate(
            zip(GLOSSARY_SPAN_RE.finditer(french), GLOSSARY_SPAN_RE.finditer(english))
        ):
            fr_ratio = fr_span.start() / max(1, len(french))
            en_ratio = en_span.start() / max(1, len(english))
            if en_ratio > 0.85 and fr_ratio < 0.6 and len(english.split()) > 20:
                report(
                    "glossary-displaced",
                    f"term {index + 1} sits at {fr_ratio:.0%} in French but {en_ratio:.0%} here: "
                    f"{snippet(english, en_span.start())}",
                )

    # --- stranded function words (the empty slot left behind) --------------
    for match in STRANDED_RE.finditer(english):
        word = match.group(1).lower()
        # "as," / "is," / "that," are legitimate mid-sentence; only flag the
        # determiner and preposition classes, which cannot precede punctuation.
        if word in {"the", "a", "an", "of", "by", "with", "from", "into", "during", "between", "against"}:
            report("stranded-function-word", snippet(english, match.start()))

    # --- typography -------------------------------------------------------
    for char, label in FORBIDDEN_CHARS.items():
        index = english.find(char)
        if index >= 0:
            report("forbidden-char", f"{label}: {snippet(english, index)}")
    if re.search(r"\s[,;:!?](?!\))", english):
        report("space-before-punctuation", snippet(english, re.search(r"\s[,;:!?]", english).start()))
    if "  " in english:
        report("double-space", snippet(english, english.find("  ")))
    if re.search(r"[,;:](?=[^\s\d\"'\u201c\)\]])", english):
        report("missing-space-after-punctuation", snippet(english, re.search(r"[,;:](?=[^\s\d\"'\u201c\)\]])", english).start()))
    if english != english.strip():
        report("edge-whitespace", "leading or trailing whitespace")

    leaked = LEAKED_TOKEN_RE.search(english)
    if leaked:
        report("leaked-token", f"{leaked.group(0)!r}: {snippet(english, leaked.start())}")

    # --- localisation of numbers and eras ---------------------------------
    match = FRENCH_THOUSANDS_RE.search(english)
    if match:
        report("french-thousands-separator", f"{match.group(0)!r} should use a comma")
    match = FRENCH_DECIMAL_RE.search(english)
    if match:
        report("french-decimal-comma", f"{match.group(0)!r} should use a period")
    match = ROMAN_CENTURY_RE.search(english)
    if match:
        report("roman-ordinal", f"{match.group(0)!r} should be an English ordinal")
    match = BC_FRENCH_RE.search(english)
    if match:
        report("french-era", f"{match.group(0)!r} should be BC/AD")

    # --- residual French --------------------------------------------------
    candidate = GLOSSARY_SPAN_RE.sub(" ", english)
    candidate = re.sub(r"\*+", "", candidate)
    for match in FRENCH_LEFTOVERS.finditer(candidate):
        word = match.group(0)
        # Italicised or capitalised runs are original-language titles and names.
        if FRENCH_ALLOWLIST.fullmatch(word):
            continue
        context = candidate[max(0, match.start() - 40) : match.end() + 40]
        if re.search(rf"\*[^*]*\b{re.escape(word)}\b[^*]*\*", english):
            continue
        report("french-leftover", f"{word!r}: {context.strip()}")
        break


def check_course(course_id: str, lang: str, allowed_by_course: dict[str, list[str]]) -> list[Finding]:
    findings: list[Finding] = []
    french = load_course("fr", course_id)
    try:
        translated = load_course(lang, course_id)
    except FileNotFoundError:
        return [Finding(course_id, "-", "missing-translation", f"no {lang} file")]

    fr_segments = dict(segments(french))
    tr_segments = dict(segments(translated))

    if list(fr_segments) != list(tr_segments):
        only_fr = [k for k in fr_segments if k not in tr_segments]
        only_tr = [k for k in tr_segments if k not in fr_segments]
        findings.append(
            Finding(course_id, "-", "structure-drift", f"missing {only_fr}, unexpected {only_tr}")
        )

    for field in ("subject", "id"):
        if french.get(field) != translated.get(field):
            findings.append(
                Finding(course_id, field, "structure-drift", f"{french.get(field)!r} != {translated.get(field)!r}")
            )

    allowed = set(allowed_by_course.get(course_id, []))
    allowed_norm = {normalise_term(term): term for term in allowed}

    for key, english in tr_segments.items():
        check_segment(course_id, key, fr_segments.get(key, ""), english, allowed, allowed_norm, findings)

    # Whole-course glossary budget: every French term must survive somewhere.
    fr_total = sum(len(glossary_terms_in(text)) for text in fr_segments.values())
    tr_total = sum(len(glossary_terms_in(text)) for text in tr_segments.values())
    if fr_total != tr_total:
        findings.append(
            Finding(course_id, "-", "glossary-total", f"French uses {fr_total} term(s), translation {tr_total}")
        )

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("patterns", nargs="*", help="Course id glob(s)")
    parser.add_argument("--lang", required=True)
    parser.add_argument("--verbose", action="store_true", help="List every finding")
    parser.add_argument("--json", type=Path, help="Write the full report as JSON")
    parser.add_argument("--rule", action="append", help="Only report these rules")
    args = parser.parse_args()

    allowed_by_course = glossary_keys_by_course(args.lang)
    course_ids = [p.stem for p in sorted((CONTENT_ROOT / "fr").glob("*.json"))]
    if args.patterns:
        course_ids = [c for c in course_ids if any(fnmatch.fnmatch(c, p) for p in args.patterns)]

    all_findings: list[Finding] = []
    for course_id in course_ids:
        all_findings.extend(check_course(course_id, args.lang, allowed_by_course))

    if args.rule:
        wanted = set(args.rule)
        all_findings = [f for f in all_findings if f.rule in wanted]

    by_rule = Counter(f.rule for f in all_findings)
    affected = len({f.course_id for f in all_findings})

    print(f"Checked {len(course_ids)} course(s) in '{args.lang}'.")
    if not all_findings:
        print("Clean.")
    else:
        print(f"{len(all_findings)} finding(s) across {affected} course(s):\n")
        for rule, count in by_rule.most_common():
            print(f"  {count:5d}  {rule}")
        if args.verbose:
            print()
            for finding in all_findings:
                print(f"{finding.course_id} [{finding.key}] {finding.rule}: {finding.detail}")

    if args.json:
        args.json.write_text(
            json.dumps([f.as_dict() for f in all_findings], ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"\nReport written to {args.json}")

    return 1 if all_findings else 0


if __name__ == "__main__":
    sys.exit(main())
