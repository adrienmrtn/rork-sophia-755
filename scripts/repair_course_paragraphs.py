#!/usr/bin/env python3
"""Repair course paragraphs the translation pipeline left damaged.

Two defects are handled, both of which need the same remedy — translating the
paragraph again with its glossary terms as ordinary words, then linking them
where they actually landed.

``translate_courses_v2`` hides each ``[[term]]`` behind an opaque slot so the
engine cannot delete it, and drops the term when the slot does not survive —
deliberately, because parking it at the end of the paragraph would read worse
than losing it (see that script's own note). What the drop leaves behind is
sometimes more than a missing link: with the slot gone, the sentence can lose
the idea altogether.

    FR  L'épilogue en Sibérie montre une **[[La rédemption par la souffrance]]**
        lente et difficile.
    RU  Эпилог в Сибири показывает медленный и трудный процесс.
        ("shows a slow and difficult process" — the redemption is gone)

Translating the same sentence with the term as ordinary words instead of a slot
gives the engine something to work with, and it renders the idea in the case the
sentence needs:

    RU  Эпилог в Сибири показывает медленное и трудное искупление через страдания.

The term is then linked where it actually stands, inflected, and that spelling is
registered as an alias of the glossary entry — the same FR-parity mechanism
``enrich_glossary_aliases`` uses — so the tap resolves. A paragraph is only
rewritten when every term the French carries comes back placed; anything less
and the existing translation is kept and the term stays reported.

The second defect is French coming through untranslated. The engine sometimes
returns part of a paragraph verbatim, and with the glossary terms hidden behind
slots the result is neither language:

    SK  Mier zostáva krehký. **Gaïa**, mère des Titans, enfante encore des
        menaces: le monstre [[Typhon]], puis la [[Gigantomachy…]], guerre contre
        les Géants. Tentoraz bohovia potrebujú na porážku smrteľníka.

Usage:
    python scripts/repair_course_paragraphs.py --lang ru --check
    python scripts/repair_course_paragraphs.py --lang da,nb,ru,hr,sl,sk,sr
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import translate_courses_v2 as pipeline  # noqa: E402
from i18n_languages import NON_FR_LANGS  # noqa: E402
from check_course_translation import (  # noqa: E402
    check_segment,
    normalise_term,
    residual_french,
    rules_for,
)
from repair_markup_tokens import repair as repair_markup  # noqa: E402

COURSES = ROOT / "content" / "courses"
GLOSSARY_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
CATALOG_CACHE = ROOT / "content" / "locales" / "_catalog_mt_cache"

GLOSS = re.compile(r"\[\[(.+?)\]\]")
BOLD = re.compile(r"\*\*(.+?)\*\*", re.S)
#: How much each finding costs, so a rewrite can be compared with what it
#: replaces. A paragraph that comes back in the wrong language, or with the
#: markers broken, is worse than one that lost a glossary link — so trading the
#: first for the second is an improvement, and the reverse never is.
SEVERITY = {
    "empty": 100,
    "english-leftover": 100,
    "french-leftover": 100,
    "structure-drift": 80,
    "leaked-token": 60,
    "bold-unbalanced": 50,
    "glossary-unbalanced": 50,
    "glossary-count": 10,
    "glossary-total": 10,
}
DEFAULT_SEVERITY = 20
#: Sentinel wreckage the engine occasionally returns instead of the markers.
DEBRIS = re.compile(
    r"Z{2,}|(?:END)?(?:BOLD|ITAL|GLOSS|NAME)[Z0-9]|\bZ-?\d", re.IGNORECASE
)
WORD = re.compile(r"\w+", re.UNICODE)
#: A genitive or plural ending stuck on the outside of a link.
INFLECTED_TAIL = re.compile(r"\]\](?='?s(?![\w])|s'(?![\w]))")
#: Function words never carry a term on their own.
STOP = frozenset(
    """de la le les du des et un une the a an of and or in on at to for
    i u na do od za po iz sa te og er en et som med den det av
    и в на с по для от к из а""".split()
)


def stem(word: str) -> str:
    lowered = word.lower()
    return lowered[: max(4, int(len(lowered) * 0.65))]


def same_word(term_word: str, text_word: str) -> bool:
    """True when an inflected form of the same word (Slavic cases, definite forms)."""
    left, right = term_word.lower(), text_word.lower()
    if left == right:
        return True
    left_stem, right_stem = stem(term_word), stem(text_word)
    if min(len(left_stem), len(right_stem)) < 4:
        return False
    return left_stem == right_stem or left.startswith(right_stem) or right.startswith(left_stem)


def locate(text: str, term: str) -> tuple[int, int] | None:
    """Span of ``term`` in ``text``, allowing inflection, or None.

    Inflection is the whole point: Slavic and Nordic prose declines a term where
    it stands, so "studená vojna" appears as "studenej vojny" and never matches
    literally. What a shortened run must not do is underline half the phrase —
    "Трафальгарском" for "Трафальгарская битва" would mark the adjective and
    leave "сражении" outside the link — so a run has to reach the term's head
    word, which in these languages is the last one.
    """
    term_words = WORD.findall(term)
    text_words = [(m.start(), m.end(), m.group(0)) for m in WORD.finditer(text)]
    if not term_words:
        return None
    for width in range(len(term_words), 0, -1):
        partial = width < len(term_words)
        for offset in range(0, len(term_words) - width + 1):
            run = term_words[offset : offset + width]
            if partial:
                # At most one word short, reaching the head, and carrying a word
                # substantial enough to name the concept — never just its date.
                if width < len(term_words) - 1:
                    continue
                if offset + width != len(term_words):
                    continue
                if not any(len(w) >= 6 and w.lower() not in STOP for w in run):
                    continue
            for index in range(len(text_words) - width + 1):
                window = text_words[index : index + width]
                if not all(same_word(w, hw) for w, (_, _, hw) in zip(run, window)):
                    continue
                start, end = window[0][0], window[-1][1]
                span = text[start:end]
                if partial and len(span) < 0.45 * len(term):
                    continue
                if span.count("(") != span.count(")") or len(span) < 4:
                    continue
                # A link may not straddle a bold marker or an existing span.
                if any(char in span for char in "*[]"):
                    continue
                return start, end
    return None


class Relinker:
    def __init__(self, lang: str) -> None:
        self.lang = lang
        self.translator = pipeline.Translator(lang)
        self.entries = json.loads(
            (GLOSSARY_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8")
        )
        self.by_course: dict[str, set[str]] = {}
        for key in self.entries:
            course_id, _, term = key.partition("|")
            if term:
                self.by_course.setdefault(course_id, set()).add(term)
        catalog_path = CATALOG_CACHE / f"{lang}.json"
        self.catalog = (
            json.loads(catalog_path.read_text(encoding="utf-8"))
            if catalog_path.exists()
            else {}
        )
        self.new_aliases: list[tuple[str, str, str]] = []
        self.rules = rules_for(lang)

    def target_term(self, course_id: str, french_term: str, english_term: str | None) -> str:
        """The registered rendering of a French term for this course."""
        wanted = (self.catalog.get((english_term or "").strip()) or "").strip()
        if wanted and wanted in self.by_course.get(course_id, set()):
            return wanted
        candidates = self.translator.glossary.get(course_id, [])
        bare = self.translator._apply_mt(french_term).strip().strip("[]")
        return pipeline.best_glossary_term(french_term, bare, candidates)

    def retranslate(self, french: str, refresh: bool = False) -> str:
        """Translate a paragraph with its glossary terms as ordinary words."""
        source = GLOSS.sub(r"\1", french)
        if refresh:
            self.translator.cache.pop(source, None)
        return repair_markup(self.translator._apply_mt(source))

    def retranslate_plain(self, french: str, drop_italics: bool) -> str:
        """Translate with the emphasis markers taken out, not hidden.

        Russian is where hiding them fails hardest: the engine transliterates
        ``ZZBOLDZZéther`` as one unknown token, and what survives the cleanup is
        "Зетер" — a letter of the sentinel fused to a letter-by-letter
        transliteration of the word. Without the markers the same sentence comes
        back as ordinary Russian ("вдохнуть эфир"), so they are re-applied
        afterwards from the French.
        """
        plain = GLOSS.sub(r"\1", french).replace("**", "")
        if drop_italics:
            plain = plain.replace("*", "")
        return repair_markup(self.translator._apply_mt(plain))

    def reapply_bold(self, text: str, french: str) -> str:
        """Put the French paragraph's emphasis back onto the translation."""
        for inner in BOLD.findall(french):
            wanted = self.translator._apply_mt(GLOSS.sub(r"\1", inner).replace("*", "")).strip()
            if not wanted:
                continue
            # Offsets are preserved: [[ and ]] are two characters each.
            blanked = text.replace("[[", "  ").replace("]]", "  ")
            found = locate(blanked, wanted)
            if found is None:
                continue
            start, end = found
            # A term that is bold in the French keeps its link inside the span.
            if text[start - 2 : start] == "[[" and text[end : end + 2] == "]]":
                start, end = start - 2, end + 2
            if "*" in text[start:end]:
                continue
            text = f"{text[:start]}**{text[start:end]}**{text[end:]}"
        return text

    def leaks_french(self, text: str) -> bool:
        return residual_french(text, self.rules.leftover_extra_skip) is not None

    def flags(self, course_id: str, french: str, text: str) -> list[str]:
        """What ``check_course_translation`` would report about this paragraph.

        Asking the validator directly is what keeps the two in step: a paragraph
        is worth translating again exactly when it is flagged, and a
        retranslation is worth keeping exactly when it clears findings without
        raising new ones.
        """
        allowed = set(self.by_course.get(course_id, set()))
        allowed_norm = {normalise_term(term): term for term in allowed}
        found: list = []
        check_segment(
            course_id, "-", french, text, allowed, allowed_norm, found, self.rules, self.lang
        )
        return [finding.rule for finding in found]

    @staticmethod
    def cost(flags: list[str]) -> int:
        return sum(SEVERITY.get(rule, DEFAULT_SEVERITY) for rule in flags)

    def absorb_inflection(self, course_id: str, text: str) -> tuple[str, list]:
        """Pull a genitive or plural ending inside the link it hangs off.

        ``[[Nick Ut]]s billede`` underlines the name but not the ending that
        makes it a genitive, and the reader sees the break. Danish and Norwegian
        write the genitive without an apostrophe, so the ending simply joins the
        term, and that spelling is registered as an alias of the entry.
        """
        aliases: list[tuple[str, str, str]] = []
        out: list[str] = []
        cursor = 0
        for match in GLOSS.finditer(text):
            tail = text[match.end() : match.end() + 2]
            ending = re.match(r"'?s(?![\w])|s'(?![\w])", tail)
            if not ending:
                continue
            inner = match.group(1)
            spelling = f"{inner}s"
            keep = "'" if ending.group(0).startswith("s'") else ""
            out.append(text[cursor : match.start()])
            out.append(f"[[{spelling}]]{keep}")
            cursor = match.end() + len(ending.group(0))
            if spelling not in self.by_course.get(course_id, set()):
                aliases.append((course_id, spelling, inner))
        if not out:
            return text, []
        out.append(text[cursor:])
        return "".join(out), aliases

    def damaged(self, text: str) -> bool:
        """Markup the engine broke rather than translated.

        An odd number of bold markers, an unclosed glossary span or sentinel
        wreckage all mean the paragraph reads wrong on screen — the markers
        slipped a word along, so the emphasis lands on the wrong half of the
        sentence ("вдохнуть **Зетер. Хирург**Джон Уоррен**").
        """
        return (
            text.count("**") % 2 == 1
            or text.count("[[") != text.count("]]")
            or bool(DEBRIS.search(text))
        )

    def wanted_terms(self, course_id: str, french: str, english: str | None) -> list[str]:
        french_terms = [t.strip() for t in GLOSS.findall(french)]
        english_terms = [t.strip() for t in GLOSS.findall(english or "")]
        if len(english_terms) != len(french_terms):
            english_terms = [None] * len(french_terms)
        return [
            self.target_term(course_id, french_term, english_term)
            for french_term, english_term in zip(french_terms, english_terms)
        ]

    def place(self, course_id: str, text: str, wanted: list[str]) -> tuple[str, list]:
        """Wrap each term that stands unlinked in ``text``; return it and new aliases."""
        linked = set(GLOSS.findall(text))
        blanked = GLOSS.sub(lambda m: " " * len(m.group(0)), text)
        placements: list[tuple[int, int]] = []
        aliases: list[tuple[str, str, str]] = []
        for term in wanted:
            if not term or term in linked:
                continue
            found = locate(blanked, term)
            if found is None:
                continue
            if any(not (found[1] <= start or found[0] >= end) for start, end in placements):
                continue
            placements.append(found)
            spelling = text[found[0] : found[1]]
            if spelling not in self.by_course.get(course_id, set()):
                aliases.append((course_id, spelling, term))
        for start, end in sorted(placements, reverse=True):
            text = f"{text[:start]}[[{text[start:end]}]]{text[end:]}"
        return text, aliases

    def rebuild(self, course_id: str, french: str, english: str | None, current: str):
        """Best version of a paragraph whose links do not match the French.

        Linking a term that already stands in the translation costs nothing and
        changes nothing else, so that is tried first. Translating the sentence
        again is what is left, and it is also the only thing that helps when the
        paragraph carries *too many* links: the surplus one was injected into a
        slot that did not want it, and it took the sentence with it —

            dem [[Carte-de-visite]], der kunne betale en maler
            dem, der kunne betale en maler. Med studier og [[carte-de-visite]]…
        """
        wanted = self.wanted_terms(course_id, french, english)
        expected = len(GLOSS.findall(french))
        before = self.flags(course_id, french, current)
        #: (linked count, paragraph, new aliases), in-place attempt first so a
        #: tie on count keeps the paragraph that changes the least.
        candidates: list[tuple[int, str, list]] = []

        if len(GLOSS.findall(current)) < expected:
            text, aliases = self.place(course_id, current, wanted)
            if not self.flags(course_id, french, text):
                return text, aliases
            if len(GLOSS.findall(text)) > len(GLOSS.findall(current)):
                candidates.append((len(GLOSS.findall(text)), text, aliases))

        attempts = [
            lambda: self.retranslate(french, False),
            lambda: self.retranslate(french, True),
            lambda: self.retranslate_plain(french, False),
            lambda: self.retranslate_plain(french, True),
        ]
        for index, attempt in enumerate(attempts):
            fresh = attempt()
            if index >= 2:
                fresh = self.reapply_bold(fresh, french)
            retried, retried_aliases = self.place(course_id, fresh, wanted)
            after = self.flags(course_id, french, retried)
            if not after:
                return retried, retried_aliases
            # Keep a retranslation only when it costs less than what it
            # replaces, so a dropped link may be traded for readable prose but
            # never the other way round.
            if self.cost(after) < self.cost(before):
                candidates.append((len(GLOSS.findall(retried)), retried, retried_aliases))
                break

        if not candidates:
            return None
        _, text, aliases = min(candidates, key=lambda item: abs(item[0] - expected))
        return text, aliases

    def register(self, aliases: list[tuple[str, str, str]]) -> None:
        for course_id, spelling, wanted in aliases:
            source = self.entries.get(f"{course_id}|{wanted}")
            if source is None or f"{course_id}|{spelling}" in self.entries:
                continue
            self.entries[f"{course_id}|{spelling}"] = dict(source, displayTerm=spelling)
            self.by_course.setdefault(course_id, set()).add(spelling)
            self.new_aliases.append((course_id, spelling, wanted))

    def save_glossary(self) -> None:
        (GLOSSARY_DIR / f"glossary.{self.lang}.json").write_text(
            json.dumps(self.entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )


def paired(french, english, target, out: list) -> None:
    """Collect (french, english, container, key) for every translatable field.

    Only the fields ``course_translation_io.segments`` calls translatable are
    walked. A course id reads like French prose — ``course_139_la_naissance_du
    _jazz_americain`` — and anything that treats it as prose will happily
    translate it.
    """

    def take(french_node, english_node, target_node, key) -> None:
        if not isinstance(target_node, dict) or key not in target_node:
            return
        value = target_node[key]
        source = (french_node or {}).get(key)
        if not isinstance(value, str) or not isinstance(source, str) or not source.strip():
            return
        mirror = (english_node or {}).get(key)
        out.append((source, mirror if isinstance(mirror, str) else None, target_node, key))

    if not isinstance(french, dict) or not isinstance(target, dict):
        return
    english = english if isinstance(english, dict) else {}
    for key in ("title", "subtitle", "description"):
        take(french, english, target, key)
    take(french.get("hero"), english.get("hero"), target.get("hero"), "hook")

    fr_sections = french.get("sections") or []
    en_sections = english.get("sections") or []
    tg_sections = target.get("sections") or []
    for index, fr_section in enumerate(fr_sections):
        if index >= len(tg_sections):
            break
        tg_section = tg_sections[index]
        en_section = en_sections[index] if index < len(en_sections) else {}
        take(fr_section, en_section, tg_section, "title")
        fr_blocks = fr_section.get("blocks") or []
        en_blocks = (en_section or {}).get("blocks") or []
        tg_blocks = (tg_section or {}).get("blocks") or []
        for b_index, fr_block in enumerate(fr_blocks):
            if b_index >= len(tg_blocks):
                break
            tg_block = tg_blocks[b_index]
            en_block = en_blocks[b_index] if b_index < len(en_blocks) else {}
            for key in ("text", "caption", "attribution"):
                take(fr_block, en_block, tg_block, key)
            fr_events = fr_block.get("events") or []
            en_events = (en_block or {}).get("events") or []
            tg_events = (tg_block or {}).get("events") or []
            for e_index, fr_event in enumerate(fr_events):
                if e_index >= len(tg_events):
                    break
                en_event = en_events[e_index] if e_index < len(en_events) else {}
                for key in ("date", "title", "detail"):
                    take(fr_event, en_event, tg_events[e_index], key)


def run(lang: str, dry_run: bool) -> tuple[int, int]:
    relinker = Relinker(lang)
    fixed = 0
    touched = 0
    for path in sorted((COURSES / lang).glob("*.json")):
        course_id = path.stem
        french_path = COURSES / "fr" / f"{course_id}.json"
        if not french_path.is_file():
            continue
        english_path = COURSES / "en" / f"{course_id}.json"
        target_doc = json.loads(path.read_text(encoding="utf-8"))
        slots: list = []
        paired(
            json.loads(french_path.read_text(encoding="utf-8")),
            json.loads(english_path.read_text(encoding="utf-8")) if english_path.is_file() else None,
            target_doc,
            slots,
        )
        changed = False
        for french, english, container, slot in slots:
            target = container[slot]
            absorbed, absorbed_aliases = relinker.absorb_inflection(course_id, target)
            if absorbed != target:
                relinker.register(absorbed_aliases)
                container[slot] = target = absorbed
                fixed += 1
                changed = True

            if not relinker.flags(course_id, french, target):
                continue
            relinker.translator.course_id = course_id
            relinker.translator.segment_key = "relink"
            rebuilt = relinker.rebuild(course_id, french, english, target)
            if rebuilt is None:
                continue
            text, aliases = rebuilt
            if text == target:
                continue
            relinker.register(aliases)
            container[slot] = text
            fixed += 1
            changed = True
        if changed:
            touched += 1
            if not dry_run:
                path.write_text(
                    json.dumps(target_doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
                )
    if not dry_run:
        relinker.save_glossary()
        relinker.translator.save()
    print(
        f"{lang}: {'would relink' if dry_run else 'relinked'} {fixed} paragraph(s) "
        f"in {touched} course(s), {len(relinker.new_aliases)} alias(es)"
    )
    return fixed, touched


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--lang", default=",".join(code for code in NON_FR_LANGS if code != "en")
    )
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    args = parser.parse_args()
    total = 0
    for lang in [code.strip() for code in args.lang.split(",") if code.strip()]:
        total += run(lang, args.check)[0]
    print(f"{'Would relink' if args.check else 'Relinked'} {total} paragraph(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
