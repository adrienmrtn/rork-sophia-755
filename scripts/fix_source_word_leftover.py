#!/usr/bin/env python3
"""Repair a word the English pack never carried out of French.

``courses.en.json`` is the pack every locale but French is translated from, and
it kept the French past participle "Dicté" where it means dictated: "the rhythm
of the seasons seems immutable, Dicté by a precise inclination of our axis".
Twenty-one locales inherited it untouched, so Russian reads "которое само по
себе Dicté его содержанием кремнезёма" and Greek "το οποίο είναι το ίδιο Dicté
λόγω της περιεκτικότητάς του σε πυρίτιο".

A past participle agrees with what it describes in most of these languages, so
one replacement word would be wrong in half the sentences it landed in. The
sentence is translated again from the repaired English instead, and taken only
when its ``**bold**`` and ``<angle link>`` markers come back in the same numbers
-- the sentence is defective either way, but its markup is not.

The two occurrences that are not the verb are left alone: Mount Dicté in Crete
is a place, and the French spelling of a Cretan mountain is not a defect.

Usage:
    python scripts/fix_source_word_leftover.py --check
    python scripts/fix_source_word_leftover.py
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
from i18n_languages import ALL_CONTENT_LANGS, GT_TARGETS  # noqa: E402

LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
WORD = re.compile(r"\bDicté\b")
#: "Mount Dicté" and "the cave of <Dicté>" name a mountain in Crete, whatever
#: word each language puts in front of it.
PLACE = re.compile(
    r"<Dicté>|Dicté\s*(?:Da[ğg]|[Óo]ros)"
    r"|(?:Mount|Mont|Monte|Muntele|monte|mount|berg|Berg|bjerg|fjell|hora|hory|hoře|hore|"
    r"g[oó]r|gori|gorje|planin|hegy|vuor|mäe|[όο]ρος|βουν|гор|جبل|הר)"
    r"[^.]{0,40}?Dicté"
    # Hungarian, Norwegian, Finnish and Estonian put the mountain after the name:
    # "Dicté-hegy", "Dicté-fjellet", "Dicté-vuorella", "Dicté mäe".
    r"|Dicté[- ]?(?:hegy|fjell|vuor|mäe|berg|hore|gora|Da[ğg])"
)
SENTENCE = re.compile(r"(?<=[.!?])\s+")
BOLD = re.compile(r"\*\*")
ANGLE = re.compile(r"<[^<>]+>")


def path(lang: str) -> Path:
    return LOCALE_DIR / f"courses.{lang}.json"


def load(lang: str) -> list:
    return json.loads(path(lang).read_text(encoding="utf-8"))


def save(lang: str, data: list) -> None:
    path(lang).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def repair_english(check: bool) -> int:
    """Swap the participle for the English word, leaving the mountain alone."""
    data = load("en")
    changed = 0
    for course in data:
        for lesson in course.get("lessons") or []:
            body = lesson.get("content") or ""
            if not WORD.search(body):
                continue
            out: list[str] = []
            for piece in SENTENCE.split(body):
                if WORD.search(piece) and not PLACE.search(piece):
                    # "technology does not **Dicté** our future" is the bare verb.
                    replacement = "dictate" if re.search(r"\bnot\b[^.]*Dicté", piece) else "dictated"
                    piece = WORD.sub(replacement, piece)
                out.append(piece)
            fixed = " ".join(out)
            if fixed != body:
                lesson["content"] = fixed
                changed += 1
    if changed and not check:
        save("en", data)
    return changed


ANCHOR = re.compile(r"\*\*([^*]+)\*\*|<([^<>]+)>|\b(\d{2,4})\b")


def anchors(text: str) -> set[str]:
    """The pieces of a sentence that survive translation unchanged."""
    return {part for match in ANCHOR.finditer(text) for part in match.groups() if part}


def pick_source(
    piece: str, position: int, pieces: list[str], source_pieces: list[str]
) -> str | None:
    """The English sentence this one was translated from.

    Sentence counts line up most of the time and the position is enough. Where
    they do not -- a translation that split one sentence in two, or joined two --
    the English sentence sharing the most bold spans, links and years with it is
    the one, and never a sentence that does not carry the word at all.
    """
    candidates = [s for s in source_pieces if WORD.search(s) or re.search(r"\bdictate[ds]?\b", s)]
    if not candidates:
        return None
    if len(pieces) == len(source_pieces) and position < len(source_pieces):
        aligned = source_pieces[position]
        if aligned in candidates:
            return aligned
    mine = anchors(piece)
    best = max(candidates, key=lambda s: (len(mine & anchors(s)), -abs(len(s) - len(piece))))
    return best


def markers(text: str) -> tuple[int, int]:
    return len(BOLD.findall(text)), len(ANGLE.findall(text))


def repair_locale(lang: str, english: dict, check: bool) -> int:
    data = load(lang)
    jobs: list[tuple[int, int, int, str]] = []
    for course_index, course in enumerate(data):
        source_course = english.get(course.get("id") or "")
        if not source_course:
            continue
        lessons = source_course.get("lessons") or []
        for lesson_index, lesson in enumerate(course.get("lessons") or []):
            body = lesson.get("content") or ""
            if not WORD.search(body) or lesson_index >= len(lessons):
                continue
            source_pieces = SENTENCE.split(lessons[lesson_index].get("content") or "")
            pieces = SENTENCE.split(body)
            for position, piece in enumerate(pieces):
                if not WORD.search(piece) or PLACE.search(piece):
                    continue
                source = pick_source(piece, position, pieces, source_pieces)
                if source:
                    jobs.append((course_index, lesson_index, position, source))
    if not jobs or check:
        return len(jobs)

    target = GT_TARGETS.get(lang, lang)
    sources = list(dict.fromkeys(job[3] for job in jobs))
    try:
        out = dict(zip(sources, mt_backend.translate_batch(sources, target, "en")))
    except Exception as error:  # noqa: BLE001
        print(f"    {lang}: translation failed ({error})", file=sys.stderr)
        return 0

    changed = 0
    for course_index, lesson_index, position, source in jobs:
        translated = (out.get(source) or "").strip()
        lesson = data[course_index]["lessons"][lesson_index]
        pieces = SENTENCE.split(lesson["content"])
        if position >= len(pieces) or not translated:
            continue
        if markers(translated) != markers(source):
            continue  # the markup did not survive; leave the sentence as it is
        pieces[position] = translated
        lesson["content"] = " ".join(pieces)
        changed += 1
    if changed:
        save(lang, data)
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    args = parser.parse_args()

    print(f"  en: {repair_english(args.check)} lesson(s)")
    english = {course["id"]: course for course in load("en")}
    total = 0
    for lang in ALL_CONTENT_LANGS:
        if lang in ("en", "fr"):
            continue
        count = repair_locale(lang, english, args.check)
        if count:
            print(f"  {lang}: {count} sentence(s)")
        total += count
    verb = "would repair" if args.check else "repaired"
    print(f"{verb} {total} sentence(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
