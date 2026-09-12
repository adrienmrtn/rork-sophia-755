#!/usr/bin/env python3
"""Translate catalogue lessons that were never carried out of French.

``courses.en.json`` is the source every other locale is translated from, and
five of its lesson bodies — all of ``course_30_la_blitzkrieg_1940`` — are still
the French text. Each language inherited them, so the Blitzkrieg course reads in
French in eleven of them, with a handful of words swapped:

    CS  Contrairement à une idée reçue, le terme de Blitzkrieg n'est pas une
        appellation officielle de la <Wehrmacht> ; il s'agit d'une vynález de la
        presse anglo-saxonne.

This translates them from French into English, then from that English into every
other language, protecting ``<links>`` and ``**bold**`` the way
``translate_locale_catalog`` does. A lesson is replaced when it still carries the
French, when a sentinel leaked into it, or when it came back far shorter than its
source — the shape of a collapsed translation ("Tijdens zes dagen, op 22 juni
1940, op 22 juni 1940, realiseerde het leger alle militaire exploits"). Anything
already translated properly is left exactly as it stands.

The four oldest locales carry a second version of the same defect: the lesson
body reads as Spanish, German, Portuguese or Italian while the ``{…}`` sidebar
under it is still French ("{La Kaaba contenait à l'époque de Muhammad environ
360 idoles…}"). Those sidebars are translated on their own, so the prose above
them is left untouched.

Usage:
    python scripts/fix_untranslated_catalog_lessons.py --check
    python scripts/fix_untranslated_catalog_lessons.py
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import mt_backend  # noqa: E402
from check_course_translation import (  # noqa: E402
    ENGLISH_LEFTOVERS,
    FRENCH_LEFTOVERS,
    GLOSSARY_SPAN_RE,
)
from i18n_languages import GT_TARGETS, NON_FR_LANGS  # noqa: E402
from translate_courses_v2 import best_glossary_term  # noqa: E402
from translate_locale_catalog import ANGLE_RE, protect_markup, restore_markup  # noqa: E402

LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
CATALOG_CACHE = ROOT / "content" / "locales" / "_catalog_mt_cache"
FRENCH_COURSES = ROOT / "content" / "courses" / "fr"
#: Three distinct French function words in one lesson is not a borrowing.
FRENCH_THRESHOLD = 3
#: Below this share of the source's length the paragraph lost its content.
LENGTH_FLOOR = 0.6
#: Shorter than this and the lesson is a heading, not a paragraph.
HEADING_LENGTH = 120
LEAK_RE = re.compile(
    r"\bZZ[A-Z0-9]*|ZZ(?:END)?(?:BOLD|ITAL|GLOSS|NAME)[A-Z0-9]*"
    r"|(?:END)?(?:BOLD|ITAL|GLOSS|NAME)ZZ"
)
#: The "did you know" box under a lesson.
BRACE_RE = re.compile(r"\{([^{}]*)\}", re.S)


def looks_french(text: str) -> bool:
    bare = GLOSSARY_SPAN_RE.sub(" ", text)
    bare = re.sub(r"\*\*.+?\*\*|\*.+?\*|<[^<>]+>", " ", bare)
    return len({word.lower() for word in FRENCH_LEFTOVERS.findall(bare)}) >= FRENCH_THRESHOLD


def looks_english(text: str) -> bool:
    """The other half of the same defect: the source language left standing.

    Every locale is translated out of the English catalogue, so a lesson that
    still carries English sentences is one the engine answered with its input —
    "**Charlemagne** (742-814) inherited the Frankish kingdom in **768**."
    followed by perfectly good Swedish.
    """
    bare = GLOSSARY_SPAN_RE.sub(" ", text)
    bare = re.sub(r"\*\*.+?\*\*|\*.+?\*|<[^<>]+>", " ", bare)
    return len({word.lower() for word in ENGLISH_LEFTOVERS.findall(bare)}) >= FRENCH_THRESHOLD


def catalog_path(lang: str) -> Path:
    return LOCALE_DIR / f"courses.{lang}.json"


def load(lang: str) -> list:
    return json.loads(catalog_path(lang).read_text(encoding="utf-8"))


def save(lang: str, data: list) -> None:
    catalog_path(lang).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def unresolved_links(lang: str, data: list) -> set[str]:
    """Angle links that name no entry in this locale's glossary."""
    localised = json.loads((LOCALE_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8"))
    registered: dict[str, set[str]] = {}
    for key in localised:
        course_id, _, term = key.partition("|")
        if term:
            registered.setdefault(course_id, set()).add(term)
    unresolved: set[str] = set()
    for course in data:
        allowed = registered.get(course.get("id") or "", set())
        for lesson in course.get("lessons") or []:
            for term in ANGLE_RE.findall(lesson.get("content") or ""):
                if term not in allowed:
                    unresolved.add(term)
    return unresolved


def term_maps(lang: str, needed: set[str] | None = None) -> dict[str, dict[str, str]]:
    """courseId -> {English glossary term: the term registered for this locale}.

    An ``<angle link>`` is resolved against ``glossary.<lang>.json``, so carrying
    the English term through leaves the tap with nothing to match. The catalogue
    cache is the same map the glossary itself was built from; ``needed`` keeps
    the slower fallback below to the links that are actually still English.
    """
    cache_path = CATALOG_CACHE / f"{lang}.json"
    cache = json.loads(cache_path.read_text(encoding="utf-8")) if cache_path.exists() else {}
    localised = json.loads((LOCALE_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8"))
    registered: dict[str, set[str]] = {}
    for key in localised:
        course_id, _, term = key.partition("|")
        if term:
            registered.setdefault(course_id, set()).add(term)
    english = json.loads((LOCALE_DIR / "glossary.en.json").read_text(encoding="utf-8"))
    maps: dict[str, dict[str, str]] = {}
    for key in english:
        course_id, _, en_term = key.partition("|")
        if not en_term:
            continue
        allowed = registered.get(course_id, set())
        wanted = (cache.get(en_term) or "").strip()
        if wanted not in allowed:
            # The four oldest locales predate the catalogue cache, so there is
            # nothing to look the term up in: translate it and snap it onto the
            # course's own list, exactly as the course pipeline does.
            if not allowed or (needed is not None and en_term not in needed):
                continue
            bare = mt_backend.translate_one(
                en_term, GT_TARGETS.get(lang, lang), source="en"
            ).strip()
            wanted = best_glossary_term(en_term, bare, sorted(allowed))
        if wanted in allowed:
            maps.setdefault(course_id, {})[en_term] = wanted
    return maps


def translate(text: str, target: str, source: str, term_map: dict[str, str] | None = None) -> str:
    """Translate one lesson, retrying while a sentinel comes back unpaired."""
    best = ""
    for attempt in range(3):
        protected, angles = protect_markup(text)
        out = restore_markup(
            mt_backend.translate_one(protected, GT_TARGETS.get(target, target), source=source),
            angles,
            term_map,
        )
        if not LEAK_RE.search(out):
            return out
        best = out
    # The marker will not survive this sentence; the prose matters more, so drop
    # the wreckage and any bold it leaves unbalanced.
    cleaned = LEAK_RE.sub("", best)
    if cleaned.count("**") % 2:
        cleaned = cleaned.replace("**", "")
    return re.sub(r"\s+([,.;:!?])", r"\1", cleaned).strip()


def needs_translation(current: object, source: str, lang: str = "") -> bool:
    if not isinstance(current, str) or not current.strip():
        return True
    body = BRACE_RE.sub(" ", current)
    if looks_french(body) or LEAK_RE.search(current):
        return True
    if lang != "en" and looks_english(body):
        return True
    if len(source) < HEADING_LENGTH:
        # A lesson this short is a heading, and Arabic, Hebrew and Czech all
        # write one in fewer characters than English does. The floor has nothing
        # to say about it and would send it back through the engine every run.
        return False
    return len(current) < LENGTH_FLOOR * len(source)


#: A sentence boundary that does not fire inside "1948." or "St. Louis".
SENTENCE_RE = re.compile(r"(?<=[.!?])\s+(?=[A-Z\u00c0-\u024f**\[<])")


def english_words(text: str) -> set[str]:
    bare = GLOSSARY_SPAN_RE.sub(" ", BRACE_RE.sub(" ", text))
    bare = re.sub(r"\*\*.+?\*\*|\*.+?\*|<[^<>]+>", " ", bare)
    return {word.lower() for word in ENGLISH_LEFTOVERS.findall(bare)}


def translate_english_sentences(
    text: str, target: str, term_map: dict[str, str] | None = None
) -> str:
    """Translate only the sentences of ``text`` that are still English.

    When a lesson comes back half-done — "Between **1948 and 1952**, the United
    States transferred…" followed by four sound Swedish paragraphs — rewriting
    the whole body throws away the good half and gives the engine the same input
    that already defeated it. Handing it one stranded sentence at a time does
    not.
    """
    out: list[str] = []
    for block in text.split("\n"):
        pieces = SENTENCE_RE.split(block)
        for index, piece in enumerate(pieces):
            # Two function words in a single sentence is already the source
            # language; three is the threshold for a whole lesson.
            if len(english_words(piece)) >= 2:
                pieces[index] = translate(piece, target, "en", term_map)
        out.append(" ".join(part.strip() for part in pieces if part.strip()))
    return "\n".join(out)


def best_rendering(candidates: list[str], source: str) -> str:
    """The candidate that left the least English standing, then the longest."""
    scored = [c for c in candidates if c and c.strip()]
    if not scored:
        return source
    return min(scored, key=lambda c: (len(english_words(c)), -len(c)))


def remap_links(text: str, term_map: dict[str, str]) -> str:
    """Point each ``<angle link>`` at the term this locale registered.

    The link text is what the reader sees, so only a replacement of comparable
    length is taken. Snapping "Tenochtitlán" onto the entry registered as
    "Tenochtitlán y la Ciudad de México" would resolve the tap and wreck the
    sentence it sits in.
    """

    def swap(match: re.Match[str]) -> str:
        original = match.group(1)
        wanted = term_map.get(original)
        if not wanted or len(wanted) > 1.6 * len(original) + 6:
            return match.group(0)
        return f"<{wanted}>"

    return ANGLE_RE.sub(swap, text)


#: An ``<angle link>`` slot that lost the ``ZZ`` around it: ZZA0ZZ -> A0.
SLOT_RE = re.compile(r"(?<![A-Za-z0-9])A(\d)Z{0,2}(?![0-9A-Za-z])")


def restore_link_slots(current: str, source: str, term_map: dict[str, str]) -> str:
    """Put the ``<angle link>`` back where only its slot number survived.

    ``protect_markup`` hands the engine ZZA0ZZ, ZZA1ZZ… in place of each link and
    ``restore_markup`` swaps them back. When the engine eats the ZZ wrapper the
    bare number is all that is left, and the Serbian lesson reads "**27. novembra
    1095**., tokom **A0**" where English writes "**<Council of Clermont>**". The
    number is still the link's position in the English lesson, so which link it
    was is not in doubt.
    """
    angles = ANGLE_RE.findall(source)
    if not angles or not SLOT_RE.search(current):
        return current

    def swap(match: re.Match[str]) -> str:
        token = match.group(0)
        # "A4" is a paper size in the lesson on the Mona Lisa's dimensions, and
        # the English lesson says it in the same breath. A slot never survives
        # into English.
        if re.search(rf"(?<![A-Za-z0-9]){token}(?![0-9A-Za-z])", source):
            return token
        index = int(match.group(1))
        if index >= len(angles):
            return token
        term = angles[index]
        return f"<{term_map.get(term, term)}>"

    return SLOT_RE.sub(swap, current)


#: The initial of a month the engine left behind when it moved the month after
#: the day: "**August 6, 1945**" comes back as "**A6 Agustos 1945**", "**April
#: 4, 1949**" as "**A4 Nisan 1949**".
MONTH_INITIAL = re.compile(r"(?<![0-9A-Za-z])A(\d{1,2})(?![0-9A-Za-z])")
A_MONTHS = ("April", "August")


def stranded_month(text: str, source: str) -> bool:
    """Is an A in front of a day number the remains of April or August?

    Only where the English lesson has such a date to lose the letter from, and
    only for a token the English does not itself write -- "A4" is also a paper
    size, and the lesson on the Mona Lisa's dimensions says so in both.
    """
    if not any(month in source for month in A_MONTHS):
        return False
    for match in MONTH_INITIAL.finditer(text):
        token = match.group(0)
        if not re.search(rf"(?<![0-9A-Za-z]){token}(?![0-9A-Za-z])", source):
            return True
    return False


#: "April 26, 1986" in the English lesson: the date the letter fell off. The
#: separator between the day and the year is required so that "August 1096", a
#: year with no day in front of it, is not read as a day followed by a year. A
#: range ("April 27-29, 1994", "April 27 to 29, 1994") dates by its first day.
A_MONTH_DATE = re.compile(
    r"\b(?:April|August)\s+(\d{1,2})(?:\s*(?:[-\u2013]|to)\s*\d{1,2})?(?:,\s*|\s+)(\d{3,4})\b"
)


def strip_month_initial(current: str, source: str) -> str:
    """Drop the month's initial from in front of the day it was moved behind.

    Translating the sentence again does not help -- the engine answers
    "**A6 Agustos 1945**" to "**August 6, 1945**" every time -- and the day
    itself is not in doubt, so the letter is simply removed. Only where the
    English lesson dates something to that very day: "A0" and "A1" are link
    slots, "A4" in the lesson on the Mona Lisa's dimensions is a paper size, and
    a day the English does not write is a day this cannot vouch for.
    """
    if not stranded_month(current, source):
        return current
    days = {int(day) for day, _ in A_MONTH_DATE.findall(source)}
    if not days:
        return current

    def swap(match: re.Match[str]) -> str:
        token = match.group(0)
        if re.search(rf"(?<![0-9A-Za-z]){token}(?![0-9A-Za-z])", source):
            return token
        return match.group(1) if int(match.group(1)) in days else token

    return MONTH_INITIAL.sub(swap, current)


def repair_sidebars(current: str, source: str, lang: str) -> str:
    """Translate a ``{…}`` box that stayed French under a translated lesson."""
    current_boxes = BRACE_RE.findall(current)
    source_boxes = BRACE_RE.findall(source)
    if not current_boxes:
        return current
    aligned = len(current_boxes) == len(source_boxes)
    index = -1

    def replace(match: re.Match[str]) -> str:
        nonlocal index
        index += 1
        # Two French function words is enough inside one short box.
        if len({w.lower() for w in FRENCH_LEFTOVERS.findall(match.group(1))}) < 2:
            return match.group(0)
        if aligned:
            return "{" + translate(source_boxes[index], lang, "en") + "}"
        # Some boxes never made it into the English lesson at all, so the French
        # text standing here is the only source there is.
        return "{" + translate(match.group(1), lang, "fr") + "}"

    return BRACE_RE.sub(replace, current)


def french_lessons(english: list) -> dict[tuple[int, int], str]:
    """(course index, lesson index) -> the French text still sitting there."""
    stale: dict[tuple[int, int], str] = {}
    for course_index, course in enumerate(english):
        for lesson_index, lesson in enumerate(course.get("lessons") or []):
            content = lesson.get("content")
            if isinstance(content, str) and (looks_french(content) or LEAK_RE.search(content)):
                stale[(course_index, lesson_index)] = content
    return stale


def french_source(course_id: str, lesson_index: int, english: str) -> str | None:
    """The French lesson text a stale English lesson was left as."""
    return english if looks_french(english) else None


COURSES_V2 = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"


def paired_strings(target, source, out: list) -> list:
    """Walk two JSON trees of the same shape, pairing their strings."""
    if isinstance(target, str) and isinstance(source, str):
        out.append((target, source))
    elif isinstance(target, list) and isinstance(source, list):
        for a, b in zip(target, source):
            paired_strings(a, b, out)
    elif isinstance(target, dict) and isinstance(source, dict):
        for key, value in target.items():
            if key in source:
                paired_strings(value, source[key], out)
    return out


def sweep_courses_v2(lang: str, check: bool) -> int:
    """The same date repair over the course files, which is what both apps read.

    The catalogue lesson bodies are a legacy fallback that neither app reaches
    while CoursesV2 covers every lesson, so a stranded "A6. kolovoza 1945" there
    is one a reader actually sees.
    """
    changed = 0
    for target_path in sorted(COURSES_V2.glob(f"*.{lang}.json")):
        source_path = COURSES_V2 / f"{target_path.name[: -len(lang) - 6]}.en.json"
        if not source_path.is_file():
            continue
        raw = target_path.read_text(encoding="utf-8")
        target = json.loads(raw)
        source = json.loads(source_path.read_text(encoding="utf-8"))
        swaps = {}
        for got, english in paired_strings(target, source, []):
            fixed = strip_month_initial(got, english)
            if fixed != got:
                swaps[got] = fixed
        if not swaps:
            continue
        changed += len(swaps)
        if check:
            continue

        def swap(node):
            if isinstance(node, str):
                return swaps.get(node, node)
            if isinstance(node, list):
                return [swap(item) for item in node]
            if isinstance(node, dict):
                return {key: swap(value) for key, value in node.items()}
            return node

        minified = "\n" not in raw.strip()[:4000]
        target_path.write_text(
            json.dumps(
                swap(target), ensure_ascii=False,
                separators=(",", ":") if minified else None,
                indent=None if minified else 2,
            ) + ("" if minified else "\n"),
            encoding="utf-8",
        )
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    parser.add_argument(
        "--force-lang",
        default="",
        help="Comma-separated languages to retranslate regardless of how their "
        "lessons look. For the ones the bad English source left plausible but "
        "wrong: Dutch repeating the date twice, Turkish keeping Pays-Bas and "
        "Belgique, Russian moving the campaign to July. Needs --only-course.",
    )
    parser.add_argument(
        "--only-course", default="", help="Restrict a forced run to this course id."
    )
    args = parser.parse_args()

    english = load("en")
    forced = {code.strip() for code in args.force_lang.split(",") if code.strip()}
    stale = french_lessons(english)
    if args.only_course:
        for course_index, course in enumerate(english):
            if course.get("id") != args.only_course:
                continue
            for lesson_index, lesson in enumerate(course.get("lessons") or []):
                stale.setdefault((course_index, lesson_index), lesson.get("content") or "")
    if not stale and not forced:
        print("English catalogue is clean; checking the other locales.")
    for (course_index, lesson_index) in stale:
        course_id = english[course_index].get("id")
        print(f"  en {course_id} lesson {lesson_index}: still French")
    if args.check:
        print(f"Would translate {len(stale)} lesson(s) into en and {len(NON_FR_LANGS) - 1} language(s).")
        return 0

    if stale:
        for (course_index, lesson_index), text in stale.items():
            if looks_french(text):
                fixed = translate(text, "en", "fr")
            else:
                # Already English, only the markup leaked; clean it in place.
                fixed = translate(text, "en", "en")
            english[course_index]["lessons"][lesson_index]["content"] = fixed
        save("en", english)
    print(f"en: translated {len(stale)} lesson(s)")

    for lang in NON_FR_LANGS:
        if lang == "en":
            continue
        data = load(lang)
        maps = term_maps(lang, unresolved_links(lang, data))
        changed = boxes = relinked = slots = 0
        for course_index, course in enumerate(english):
            lessons = (data[course_index].get("lessons") or [])
            for lesson_index, lesson in enumerate(course.get("lessons") or []):
                if lesson_index >= len(lessons):
                    continue
                source = lesson["content"]
                current = lessons[lesson_index].get("content")
                forced_here = lang in forced and (
                    not args.only_course or course.get("id") == args.only_course
                )
                course_map = maps.get(course.get("id") or "", {})
                if forced_here or needs_translation(current, source, lang):
                    fresh = translate(source, lang, "en", course_map)
                    if looks_english(BRACE_RE.sub(" ", fresh)):
                        # The engine answered with its input. Repair the text
                        # that is already there instead, sentence by sentence.
                        fresh = best_rendering(
                            [
                                fresh,
                                translate_english_sentences(fresh, lang, course_map),
                                translate_english_sentences(
                                    current if isinstance(current, str) else "",
                                    lang,
                                    course_map,
                                ),
                            ],
                            source,
                        )
                    lessons[lesson_index]["content"] = remap_links(fresh, course_map)
                    changed += 1
                    continue
                restored = restore_link_slots(current, source, course_map)
                restored = strip_month_initial(restored, source)
                if restored != current:
                    current = restored
                    slots += 1
                repaired = repair_sidebars(current, source, lang)
                if repaired != current:
                    current = repaired
                    boxes += 1
                relinked_text = remap_links(current, course_map)
                if relinked_text != current:
                    relinked += 1
                if relinked_text != lessons[lesson_index].get("content"):
                    lessons[lesson_index]["content"] = relinked_text
        if changed or boxes or relinked or slots:
            save(lang, data)
        in_v2 = sweep_courses_v2(lang, args.check)
        print(
            f"{lang}: translated {changed} lesson(s), {boxes} sidebar(s), "
            f"{relinked} link(s) remapped, {slots} link slot(s) restored, "
            f"{in_v2} date(s) in CoursesV2"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
