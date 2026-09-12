#!/usr/bin/env python3
"""Render the Latin bold spans the non-Latin locales were left holding.

Greek lessons name **Zeus**, **Athena** and **Aristotle** in Latin letters;
Russian writes **Daedalus**, Bulgarian **Cronus**, Hebrew **New York**, Arabic
**Vienna**. The sentinel protection around a ``**bold**`` span is opaque enough
that the engine often hands the span straight back, and in a language that does
not use the Latin alphabet at all that is unmissable on the page.

Which spans are stuck is decided against the English pack: a lesson whose bold
spans line up one for one with the English lesson's, and whose span is that same
English string with not one character of the locale's own script in it.

The repair translates the **English paragraph** rather than the span, because a
name has to arrive in the case its sentence governs: Greek needs "τον
**Προμηθέα**" after "για να τιμωρήσει", "ο **Δίας**" as a subject, "των **Μήλων
των Εσπερίδων**" after "η κλοπή". The engine keeps the ``**`` markers, so the
spans of the translated paragraph pair off positionally with the English ones
and each stuck span takes the rendering belonging to its own occurrence.

What comes back in Latin is left in Latin, and that is the point rather than a
shortfall: asked in a sentence, the engine keeps "Kind of Blue", "Double Irish"
and "B-29", and renders Prometheus and the Apples of the Hesperides. A short
list of code names and foreign-language titles it would otherwise translate
literally -- "Little Boy" is a bomb, not a small boy -- is held out by name.

Spans carrying an ``<angle link>`` are left alone: the link text is matched
against the locale's glossary, and translating it here would resolve to nothing.

Usage:
    python scripts/fix_latin_spans_nonlatin.py --check
    python scripts/fix_latin_spans_nonlatin.py --lang el
    python scripts/fix_latin_spans_nonlatin.py
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
from i18n_languages import GT_TARGETS  # noqa: E402

LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
COURSES_V2 = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"
CACHE_DIR = ROOT / "content" / "locales" / "_latin_span_mt_cache"
KEEP_TABLE = ROOT / "scripts" / "latin_spans_kept.json"

BOLD = re.compile(r"\*\*(.+?)\*\*", re.S)
LATIN_WORD = re.compile(r"[A-Za-z]{2}")
#: Both link markers: ``<term>`` in a lesson body, ``[[term]]`` in a course
#: block. Either is matched against the glossary, so neither can be translated
#: on its own.
ANGLE = re.compile(r"<[^<>]+>|\[\[[^\[\]]+\]\]")

#: The languages that write none of the Latin alphabet, and the range that says
#: a string is in their own script.
SCRIPTS = {
    "el": re.compile(r"[Ͱ-Ͽἀ-῿]"),
    "ru": re.compile(r"[Ѐ-ӿ]"),
    "bg": re.compile(r"[Ѐ-ӿ]"),
    "he": re.compile(r"[֐-׿]"),
    "ar": re.compile(r"[؀-ۿ]"),
}
#: A rendering more than this much longer than what it replaces is the engine
#: explaining the term rather than naming it.
LENGTH_CEILING = 3.0


def catalogue(lang: str) -> Path:
    return LOCALE_DIR / f"courses.{lang}.json"


def load(lang: str) -> list:
    return json.loads(catalogue(lang).read_text(encoding="utf-8"))


def tables() -> tuple[set[str], set[str], dict[str, dict[str, str]]]:
    """(kept everywhere, kept in one course, per-language corrections)."""
    payload = json.loads(KEEP_TABLE.read_text(encoding="utf-8"))
    return (
        set(payload["keep"]),
        set(payload.get("keep_in_course") or []),
        payload.get("overrides") or {},
    )


class Cache:
    """English paragraph -> its translation, kept on disk between runs."""

    def __init__(self, lang: str) -> None:
        self.path = CACHE_DIR / f"{lang}.json"
        self.lang = lang
        self.data: dict[str, str] = (
            json.loads(self.path.read_text(encoding="utf-8")) if self.path.exists() else {}
        )

    def save(self) -> None:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        self.path.write_text(
            json.dumps(self.data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )

    def warm(self, paragraphs: list[str], batch: int = 12) -> None:
        missing = [p for p in dict.fromkeys(paragraphs) if p not in self.data]
        if not missing:
            return
        target = GT_TARGETS.get(self.lang, self.lang)
        for start in range(0, len(missing), batch):
            chunk = missing[start : start + batch]
            try:
                out = mt_backend.translate_batch(chunk, target, "en")
            except Exception as error:  # noqa: BLE001 - one bad batch is not fatal
                print(f"    batch failed ({error}); skipping {len(chunk)}", file=sys.stderr)
                continue
            for source, translated in zip(chunk, out):
                if translated:
                    self.data[source] = translated
            print(f"    {min(start + batch, len(missing))}/{len(missing)}", flush=True)
            self.save()


#: A definite article the engine puts in front of a name asked for on its own.
#: "Thor" comes back as "Ο Θορ", "Stendhal" as "Ο Στένταλ", and inside a
#: sentence that article is already there.
LEADING_ARTICLE = {
    "el": re.compile(r"^(?:Ο|Η|Το|Οι|Τα|Του|Της|Των|Τον|Την)\s+"),
    "ru": re.compile(r"(?!x)x"),
    "bg": re.compile(r"(?!x)x"),
    "he": re.compile(r"(?!x)x"),
    "ar": re.compile(r"^[،,]\s*و?\s*"),
}


def tidy(rendering: str, lang: str) -> str:
    """Drop what the engine adds around a name it was handed on its own."""
    out = LEADING_ARTICLE[lang].sub("", rendering.strip())
    return out.strip(" \t،,;:")


def usable(rendering: str, original: str, lang: str, keep: set[str]) -> bool:
    """Is this a name in the locale's script, and not an explanation of one?"""
    if original in keep or ANGLE.search(original):
        return False
    if not rendering or rendering == original:
        return False
    if not SCRIPTS[lang].search(rendering):
        return False  # the engine kept it in Latin: a title, a model number
    if len(rendering) > LENGTH_CEILING * len(original) + 12:
        return False
    return True


def stuck_spans(target: str, source: str, lang: str) -> list[tuple[int, str]]:
    """(position, span) for each bold span left as the English it came from."""
    target_spans = BOLD.findall(target)
    source_spans = BOLD.findall(source)
    if not source_spans or len(target_spans) != len(source_spans):
        return []
    return [
        (index, span)
        for index, (span, english) in enumerate(zip(target_spans, source_spans))
        if span == english
        and not SCRIPTS[lang].search(span)
        and LATIN_WORD.search(span)
    ]


def rebuild(target: str, renderings: dict[int, str]) -> str:
    """Swap the spans at the given positions, leaving every other one alone."""
    index = -1

    def swap(match: re.Match[str]) -> str:
        nonlocal index
        index += 1
        return f"**{renderings[index]}**" if index in renderings else match.group(0)

    return BOLD.sub(swap, target)


def paragraph_renderings(
    english: str, translated: str, wanted: set[str]
) -> dict[str, list[str]]:
    """English span -> its renderings, in the order they appear in the paragraph."""
    english_spans = BOLD.findall(english)
    out_spans = BOLD.findall(translated)
    if not english_spans or len(english_spans) != len(out_spans):
        return {}
    found: dict[str, list[str]] = {}
    for span, rendering in zip(english_spans, out_spans):
        if span in wanted:
            found.setdefault(span, []).append(rendering.strip())
    return found


#: "ο **Ο Χριστόφορος Κολόμβος**": the engine answers a Greek name with its
#: article, and the sentence the name is going back into already has one.
#: Only the same article twice over is dropped -- "το **Η Δημοκρατία**" is two
#: different ones, and picking either would be guessing at the gender.
GREEK_ARTICLES = (
    "ο", "η", "το", "οι", "τα", "του", "της", "των", "τον", "την", "τους", "τις",
)
#: "στο" is "σε" plus "το", so it doubles the article inside the span just the same.
FUSED = {
    "στο": "το", "στη": "τη", "στην": "την", "στον": "τον",
    "στους": "τους", "στις": "τις", "στα": "τα", "στους": "τους",
}
_ARTICLE_ALT = "|".join(sorted(set(GREEK_ARTICLES) | set(FUSED), key=len, reverse=True))
DOUBLED_ARTICLE = re.compile(
    rf"\b({_ARTICLE_ALT})(\s+\*\*)({_ARTICLE_ALT})\s+", re.IGNORECASE
)


def drop_doubled_article(text: str) -> str:
    """Drop the article inside a span when the sentence supplies the same one."""

    def swap(match: re.Match[str]) -> str:
        outer = match.group(1).lower()
        inner = match.group(3).lower()
        if FUSED.get(outer, outer) != inner:
            return match.group(0)
        return match.group(1) + match.group(2)

    previous = None
    while previous != text:
        previous = text
        text = DOUBLED_ARTICLE.sub(swap, text)
    return text


def second_pass(
    lang: str, data: list, english: dict, keep: set[str], cache: Cache,
    corrections: dict[str, str], keep_in_course: set[str],
) -> int:
    """Ask for the span on its own, for the ones the paragraph would not render.

    A paragraph gives the engine the case but also the licence to leave a name
    it does not recognise exactly as it found it. Handed "Cronus" or "Nelson
    Mandela" alone it transliterates them, so this asks again for whatever the
    first pass could not place -- and takes the answer only when it is no longer
    than the name it replaces, since a name asked for out of context is also
    where "Templo Mayor" comes back as "the Mayor of the Temple".
    """
    stuck: dict[str, list[tuple[int, int, int]]] = {}
    for course_index, course in enumerate(data):
        source_course = english.get(course.get("id") or "")
        if not source_course:
            continue
        lessons = source_course.get("lessons") or []
        for lesson_index, lesson in enumerate(course.get("lessons") or []):
            if lesson_index >= len(lessons):
                continue
            source = lessons[lesson_index].get("content") or ""
            for position, span in stuck_spans(lesson.get("content") or "", source, lang):
                if span in keep or ANGLE.search(span):
                    continue
                if f"{course.get('id') or ''}|{span}" in keep_in_course:
                    continue
                stuck.setdefault(span, []).append((course_index, lesson_index, position))
    if not stuck:
        return 0
    print(f"    second pass: {len(stuck)} name(s) on their own")
    cache.warm(sorted(stuck))

    changed = 0
    for span, places in stuck.items():
        rendering = corrections.get(span) or tidy(cache.data.get(span) or "", lang)
        if not usable(rendering, span, lang, keep):
            continue
        # A name asked for alone must not come back longer than it went in,
        # unless it is a correction written out by hand.
        if span not in corrections and len(rendering.split()) > len(span.split()):
            continue
        for course_index, lesson_index, position in places:
            lesson = data[course_index]["lessons"][lesson_index]
            lesson["content"] = rebuild(lesson["content"], {position: rendering})
            changed += 1
    return changed


def glossary_path(lang: str) -> Path:
    return LOCALE_DIR / f"glossary.{lang}.json"


def third_pass(
    lang: str, data: list, english: dict, keep: set[str], cache: Cache,
    corrections: dict[str, str], keep_in_course: set[str],
) -> int:
    """The links, which need the glossary renamed in the same breath.

    An ``<angle link>`` is resolved by matching its text against the locale's
    glossary, so the text cannot be translated on its own. Two thirds of these
    name no entry at all and are dead links already; the rest are registered
    under the English term, and for those the key and its displayTerm move with
    the body.
    """
    glossary = json.loads(glossary_path(lang).read_text(encoding="utf-8"))
    registered: dict[str, set[str]] = {}
    for key in glossary:
        course_id, _, term = key.partition("|")
        if term:
            registered.setdefault(course_id, set()).add(term)

    wanted: dict[str, list[tuple[int, int, int, str, str]]] = {}
    for course_index, course in enumerate(data):
        source_course = english.get(course.get("id") or "")
        if not source_course:
            continue
        lessons = source_course.get("lessons") or []
        for lesson_index, lesson in enumerate(course.get("lessons") or []):
            if lesson_index >= len(lessons):
                continue
            source = lessons[lesson_index].get("content") or ""
            for position, span in stuck_spans(lesson.get("content") or "", source, lang):
                match = ANGLE.search(span)
                if not match or span in keep:
                    continue
                term = match.group(0)[1:-1]
                if f"{course.get('id') or ''}|{term}" in keep_in_course:
                    continue
                wanted.setdefault(term, []).append(
                    (course_index, lesson_index, position, span, course.get("id") or "")
                )
    if not wanted:
        return 0
    print(f"    third pass: {len(wanted)} link(s)")
    cache.warm(sorted(wanted))

    changed = 0
    for term, places in wanted.items():
        rendering = corrections.get(term) or tidy(cache.data.get(term) or "", lang)
        if not usable(rendering, term, lang, keep):
            continue
        if len(rendering.split()) > len(term.split()) + 1:
            continue
        for course_index, lesson_index, position, span, course_id in places:
            if rendering in registered.get(course_id, set()):
                continue  # that name is already taken by another entry
            key = f"{course_id}|{term}"
            if key in glossary:
                entry = glossary.pop(key)
                if entry.get("displayTerm") == term:
                    entry["displayTerm"] = rendering
                glossary[f"{course_id}|{rendering}"] = entry
                registered.setdefault(course_id, set()).add(rendering)
            lesson = data[course_index]["lessons"][lesson_index]
            lesson["content"] = rebuild(
                lesson["content"], {position: span.replace(f"<{term}>", f"<{rendering}>")}
            )
            changed += 1
    if changed:
        glossary_path(lang).write_text(
            json.dumps(glossary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
    return changed


def run(lang: str, check: bool) -> tuple[int, int]:
    english = {course["id"]: course for course in load("en")}
    data = load(lang)
    keep, keep_in_course, overrides = tables()
    corrections = overrides.get(lang, {})

    work: list[tuple[int, int, str, list[tuple[int, str]]]] = []
    for course_index, course in enumerate(data):
        source_course = english.get(course.get("id") or "")
        if not source_course:
            continue
        lessons = source_course.get("lessons") or []
        for lesson_index, lesson in enumerate(course.get("lessons") or []):
            if lesson_index >= len(lessons):
                continue
            source = lessons[lesson_index].get("content") or ""
            target = lesson.get("content") or ""
            found = stuck_spans(target, source, lang)
            if found:
                work.append((course_index, lesson_index, source, found))

    wanted_paragraphs: list[str] = []
    for _, _, source, found in work:
        names = {span for _, span in found}
        for paragraph in source.split("\n"):
            if any(f"**{name}**" in paragraph for name in names):
                wanted_paragraphs.append(paragraph)

    instances = sum(len(found) for _, _, _, found in work)
    if check:
        print(f"  {lang}: {instances} span(s) in {len(work)} lesson(s), "
              f"{len(set(wanted_paragraphs))} paragraph(s) to translate")
        return instances, 0

    cache = Cache(lang)
    print(f"  {lang}: {instances} span(s), {len(set(wanted_paragraphs))} paragraph(s)")
    cache.warm(wanted_paragraphs)

    changed = 0
    for course_index, lesson_index, source, found in work:
        names = {span for _, span in found}
        # Every rendering the paragraphs gave us, in reading order.
        pool: dict[str, list[str]] = {}
        for paragraph in source.split("\n"):
            translated = cache.data.get(paragraph)
            if not translated:
                continue
            for span, renderings in paragraph_renderings(paragraph, translated, names).items():
                pool.setdefault(span, []).extend(renderings)
        taken: dict[str, int] = {}
        renderings: dict[int, str] = {}
        for position, span in found:
            options = pool.get(span) or []
            index = taken.get(span, 0)
            # Past the last rendering the paragraphs offered, reuse the last one:
            # a span repeated more often in the lesson than in its own paragraph.
            rendering = options[min(index, len(options) - 1)] if options else ""
            taken[span] = index + 1
            rendering = corrections.get(span, rendering)
            course_id = data[course_index].get("id") or ""
            if f"{course_id}|{span}" in keep_in_course:
                continue
            if usable(rendering, span, lang, keep):
                renderings[position] = rendering
        if not renderings:
            continue
        lesson = data[course_index]["lessons"][lesson_index]
        lesson["content"] = rebuild(lesson["content"], renderings)
        changed += len(renderings)

    changed += second_pass(lang, data, english, keep, cache, corrections, keep_in_course)
    changed += third_pass(lang, data, english, keep, cache, corrections, keep_in_course)
    cache.save()

    # A correction also applies to the span as the locale spells it today, not
    # only as the English pack does: "**Dicté**" was a French word standing in
    # the English source, and repairing the source leaves the locales holding it.
    if corrections:
        literal = re.compile(
            "|".join(re.escape(f"**{key}**") for key in sorted(corrections, key=len, reverse=True))
        )
        for course in data:
            for lesson in course.get("lessons") or []:
                body = lesson.get("content") or ""
                fixed = literal.sub(
                    lambda m: f"**{corrections[m.group(0)[2:-2]]}**", body
                )
                if fixed != body:
                    lesson["content"] = fixed
                    changed += 1

    if lang == "el":
        for course in data:
            for lesson in course.get("lessons") or []:
                body = lesson.get("content") or ""
                tidied = drop_doubled_article(body)
                if tidied != body:
                    lesson["content"] = tidied
                    changed += 0  # a cleanup, not another rendering

    if changed:
        catalogue(lang).write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
    print(f"  {lang}: rendered {changed} of {instances}")
    return instances, changed


def audit(languages: list[str]) -> int:
    """Fail on a Latin span that is not one of the ones we meant to keep.

    Around eight hundred survive a full run on purpose -- a title, a brand, an
    acronym, a glossary link -- so a bare count says nothing. The baseline in
    latin_spans_kept.json records exactly which, and anything outside it is new.
    """
    payload = json.loads(KEEP_TABLE.read_text(encoding="utf-8"))
    baseline = {lang: set(spans) for lang, spans in (payload.get("baseline") or {}).items()}
    keep = set(payload["keep"])
    english = {course["id"]: course for course in load("en")}
    found = 0
    for lang in languages:
        allowed = baseline.get(lang, set()) | keep
        for course in load(lang):
            source_course = english.get(course.get("id") or "")
            if not source_course:
                continue
            lessons = source_course.get("lessons") or []
            for lesson_index, lesson in enumerate(course.get("lessons") or []):
                if lesson_index >= len(lessons):
                    continue
                source = lessons[lesson_index].get("content") or ""
                for _, span in stuck_spans(lesson.get("content") or "", source, lang):
                    if span in allowed or ANGLE.search(span):
                        continue
                    print(
                        f"{lang} {course['id']} lesson {lesson_index}: "
                        f"**{span}** is still in the Latin alphabet"
                    )
                    found += 1
        for target_path in sorted(COURSES_V2.glob(f"*.{lang}.json")):
            source_path = COURSES_V2 / f"{target_path.name[: -len(lang) - 6]}.en.json"
            if not source_path.is_file():
                continue
            pairs = paired_strings(
                json.loads(target_path.read_text(encoding="utf-8")),
                json.loads(source_path.read_text(encoding="utf-8")),
                [],
            )
            for got, source in pairs:
                for _, span in stuck_spans(got, source, lang):
                    if span in allowed or ANGLE.search(span):
                        continue
                    print(f"{lang} {target_path.name}: **{span}** is still in the Latin alphabet")
                    found += 1
    if found:
        print(f"FAILED {found} Latin span(s) outside the baseline")
        return 1
    print("non-Latin locales OK: every Latin span left is one we meant to keep")
    return 0


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


def courses_v2_pass(lang: str, cache: Cache, check: bool) -> tuple[int, int]:
    """The same repair over the CoursesV2 files, which is what Android reads.

    The catalogue holds a condensed lesson; the course files hold the long form,
    and Android takes its lesson text from those. They were translated by the
    same pipeline and carry the same defect, in far smaller numbers.
    """
    keep, keep_in_course, corrections = tables()
    found = changed = 0
    for target_path in sorted(COURSES_V2.glob(f"*.{lang}.json")):
        source_path = COURSES_V2 / f"{target_path.name[: -len(lang) - 6]}.en.json"
        if not source_path.is_file():
            continue
        target = json.loads(target_path.read_text(encoding="utf-8"))
        source = json.loads(source_path.read_text(encoding="utf-8"))
        pairs = paired_strings(target, source, [])
        wanted = [
            english
            for got, english in pairs
            if stuck_spans(got, english, lang)
        ]
        stuck_here = sum(len(stuck_spans(got, english, lang)) for got, english in pairs)
        found += stuck_here
        if not stuck_here or check:
            continue
        cache.warm(wanted)

        replacements: dict[str, str] = {}
        for got, english in pairs:
            found_spans = stuck_spans(got, english, lang)
            if not found_spans:
                continue
            translated = cache.data.get(english)
            if not translated:
                continue
            names = {span for _, span in found_spans}
            pool = paragraph_renderings(english, translated, names)
            for _, span in found_spans:
                options = pool.get(span) or []
                rendering = corrections.get(span) or (options[0] if options else "")
                if not usable(rendering, span, lang, keep):
                    # The paragraph would not render it; ask for the name alone,
                    # which the catalogue pass has usually already cached.
                    alone = tidy(cache.data.get(span) or "", lang)
                    if not usable(alone, span, lang, keep):
                        continue
                    if len(alone.split()) > len(span.split()):
                        continue
                    rendering = alone
                replacements.setdefault(f"**{span}**", f"**{rendering}**")
        if not replacements:
            continue

        def swap(node):
            if isinstance(node, str):
                for was, becomes in replacements.items():
                    node = node.replace(was, becomes)
                return node
            if isinstance(node, list):
                return [swap(item) for item in node]
            if isinstance(node, dict):
                return {key: swap(value) for key, value in node.items()}
            return node

        raw = target_path.read_text(encoding="utf-8")
        minified = "\n" not in raw.strip()[:4000]
        target_path.write_text(
            json.dumps(
                swap(target), ensure_ascii=False,
                separators=(",", ":") if minified else None,
                indent=None if minified else 2,
            ) + ("" if minified else "\n"),
            encoding="utf-8",
        )
        changed += len(replacements)
    return found, changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    parser.add_argument(
        "--audit",
        action="store_true",
        help="Fail on a Latin span that is not in the baseline",
    )
    parser.add_argument("--lang", default=",".join(SCRIPTS))
    args = parser.parse_args()

    languages = [c.strip() for c in args.lang.split(",") if c.strip() in SCRIPTS]
    if args.audit:
        return audit(languages)

    found = fixed = 0
    for lang in [code.strip() for code in args.lang.split(",") if code.strip()]:
        if lang not in SCRIPTS:
            continue
        a, b = run(lang, args.check)
        found += a
        fixed += b
        cache = Cache(lang)
        c, d = courses_v2_pass(lang, cache, args.check)
        cache.save()
        if c:
            print(f"  {lang}: CoursesV2 {d or c} of {c} span(s)")
        found += c
        fixed += d
    verb = "would render" if args.check else "rendered"
    print(f"{verb} {fixed or found} span(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
