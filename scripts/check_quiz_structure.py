#!/usr/bin/env python3
"""Verify non-FR catalog quizzes keep FR structure (id, type, keys, answers).

Also catches an option the engine handed back untranslated: the reader of the
Serbian Romeo and Juliet quiz picking between "Vestsajdska priča", "Briljantin",
"The Godfather" and "Buntovnik bez razloga". An option that matches the English
pack while French carries something else was never translated -- the ones French
keeps in the original (the ship Ever Given, the group Furious Five) match French
too, so they do not trip this.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from check_course_translation import ENGLISH_LEFTOVERS
from i18n_languages import NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
FR = json.loads((ROOT / "content" / "locales" / "fr" / "quizzes_v2.json").read_text())
EN = json.loads((ROOT / "content" / "locales" / "en" / "quizzes_v2.json").read_text())
IOS = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
LANGS = list(NON_FR_LANGS)
NAME_REPAIRS = json.loads(
    (ROOT / "scripts" / "serbian_name_repairs.json").read_text(encoding="utf-8")
)["names"]

STRUCT = ("id", "type", "correctIndex", "correctValue", "sliderMin", "sliderMax", "tolerance")
#: Languages that write no Latin at all, where any all-ASCII option is untouched.
NON_LATIN = {"el", "ru", "bg", "he", "ar"}
ASCII_ONLY = re.compile(r"[\x20-\x7e]+")


def by_id(blocks) -> dict:
    if blocks and "courseId" in blocks[0]:
        return {b["courseId"]: b["quiz"] for b in blocks}
    return {c["id"]: c.get("quiz") or [] for c in blocks}


def untranslated(option: str, fr_option: str, en_option: str | None, lang: str) -> bool:
    """Is this option still the English the pack was translated from?"""
    if lang == "en":
        return False  # the pack everything else is translated from
    if not isinstance(option, str) or not option.strip() or option == fr_option:
        return False
    if option != en_option:
        return False
    if lang in NON_LATIN and ASCII_ONLY.fullmatch(option):
        # These write no Latin, so a Latin word is untranslated even without an
        # article to give it away -- but an acronym (GDPR, WTI) and a number are
        # spelled the same way in every script.
        return bool(re.search(r"[a-z]{3}", option))
    # A bare name carries no English to leave standing: "New Orleans" is spelled
    # that way in Danish too. An article or a preposition is another matter.
    return bool(ENGLISH_LEFTOVERS.search(option))


def main() -> int:
    fr = by_id(FR)
    en = by_id(EN)
    mangled = re.compile(
        "(?<![0-9A-Za-zÀ-ÿČčĆćĐđŠšŽž])(?:"
        + "|".join(re.escape(k) for k in sorted(NAME_REPAIRS, key=len, reverse=True))
        + ")(?![0-9A-Za-zÀ-ÿČčĆćĐđŠšŽž])"
    )
    errors = 0
    for lang in LANGS:
        cat = json.loads((IOS / f"courses.{lang}.json").read_text())
        v2 = json.loads((ROOT / "content" / "locales" / lang / "quizzes_v2.json").read_text())
        cat_q = by_id(cat)
        v2_q = by_id(v2)
        for cid, fr_quiz in fr.items():
            for source, label in ((cat_q, "catalog"), (v2_q, "v2")):
                got = source.get(cid)
                if got is None:
                    print(f"{lang} {label} missing {cid}")
                    errors += 1
                    continue
                if len(got) != len(fr_quiz):
                    print(f"{lang} {label} {cid}: {len(got)} questions, FR has {len(fr_quiz)}")
                    errors += 1
                    continue
                for a, b in zip(fr_quiz, got):
                    for key in STRUCT:
                        if a.get(key) != b.get(key):
                            print(f"{lang} {label} {a['id']}: {key} {b.get(key)!r} != FR {a.get(key)!r}")
                            errors += 1
                    for key in ("options", "items"):
                        if key in a:
                            if not isinstance(b.get(key), list) or len(b[key]) != len(a[key]):
                                print(f"{lang} {label} {a['id']}: {key} length mismatch")
                                errors += 1
                    if not b.get("question"):
                        print(f"{lang} {label} {a['id']}: empty question")
                        errors += 1
                    if label != "v2":
                        continue
                    en_q = next(
                        (q for q in en.get(cid) or [] if q.get("id") == a["id"]), {}
                    )
                    en_opts = en_q.get("options") or []
                    options = [o for o in (b.get("options") or []) if isinstance(o, str)]
                    if len(set(options)) != len(options):
                        # Two renderings that collapsed onto one word leave the
                        # reader two identical answers to choose between.
                        print(f"{lang} {a['id']}: duplicate options {options}")
                        errors += 1
                    for index, option in enumerate(b.get("options") or []):
                        fr_opt = (a.get("options") or [None] * 9)[index] if index < len(
                            a.get("options") or []
                        ) else None
                        en_opt = en_opts[index] if index < len(en_opts) else None
                        if fr_opt is None:
                            continue
                        if untranslated(option, fr_opt, en_opt, lang):
                            print(
                                f"{lang} {a['id']}: option {index} still English "
                                f"{option!r} (FR {fr_opt!r})"
                            )
                            errors += 1
                        if lang == "sr" and mangled.search(option or ""):
                            print(
                                f"{lang} {a['id']}: option {index} mangled by the "
                                f"Latin transliteration {option!r}"
                            )
                            errors += 1
        # catalog vs v2 identity
        for cid, quiz in cat_q.items():
            if cid in v2_q and json.dumps(quiz, ensure_ascii=False) != json.dumps(v2_q[cid], ensure_ascii=False):
                print(f"{lang} catalog/v2 quiz mismatch on {cid}")
                errors += 1
    if errors:
        print(f"FAILED {errors} errors")
        return 1
    print("quiz structure OK vs FR + catalog/v2 sync")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
