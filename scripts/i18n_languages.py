#!/usr/bin/env python3
"""Canonical language codes for Sophia i18n pipelines.

French content stays in Swift sources. Every other locale is produced via
JSON / CoursesV2 pipelines keyed by these codes.
"""

from __future__ import annotations

# Non-French app languages (UI + content JSON + CoursesV2).
NON_FR_LANGS: list[str] = [
    "en",
    "es",
    "de",
    "pt",
    "pt-PT",
    "it",
    "tr",
    "pl",
    "ro",
    "nl",
    "el",
    "sv",
    "hu",
    "bg",
    "cs",
    "da",
    "nb",
    "ru",
    "hr",
    "sl",
    "sk",
    "sr",
    "ar",
    "he",
    "fi",
    "et",
]

# Languages being added: seeded with the French text (scripts/seed_new_language.py)
# and post-edited surface by surface. They join NON_FR_LANGS, the apps and the gate
# once every surface is translated.
PENDING_LANGS: list[str] = ["lt", "lv", "ja"]

# Source language of every machine-translation call. French is the product
# source; translating from the English table or through an English pivot took
# French words in their most frequent English sense (essai -> trial -> court
# trial, léger -> light -> the light, flâneur -> stroller -> baby stroller).
# See content/terminology/README.md for the trap list that enforces this.
MT_SOURCE_LANG: str = "fr"

# Languages written right to left. The apps pick their language themselves
# rather than following the device locale, so neither SwiftUI nor Compose can
# infer the writing direction — see AppLanguage on both sides.
RTL_LANGS: frozenset[str] = frozenset({"ar", "he"})

# Google Translate target codes. Norwegian Bokmal is "no" upstream and Serbian
# must be requested in Cyrillic ("sr" already is); every other app code is 1:1.
# Portuguese ships twice: "pt" is Brazilian (Google's "pt" is too) and "pt-PT"
# European, which Google takes under the same code.
GT_TARGETS: dict[str, str] = {code: code for code in NON_FR_LANGS}
GT_TARGETS["nb"] = "no"

# All content language folders including French sources.
ALL_CONTENT_LANGS: list[str] = ["fr", *NON_FR_LANGS]

# Swift AppLanguage case names for AppLocalizable / merge helpers.
SWIFT_CASE_BY_CODE: dict[str, str] = {
    "fr": "french",
    "en": "english",
    "es": "spanish",
    "de": "german",
    "pt": "portuguese",
    "pt-PT": "portuguesePortugal",
    "it": "italian",
    "tr": "turkish",
    "pl": "polish",
    "ro": "romanian",
    "nl": "dutch",
    "el": "greek",
    "sv": "swedish",
    "hu": "hungarian",
    "bg": "bulgarian",
    "cs": "czech",
    "da": "danish",
    "nb": "norwegian",
    "ru": "russian",
    "hr": "croatian",
    "sl": "slovenian",
    "sk": "slovak",
    "sr": "serbian",
    "ar": "arabic",
    "he": "hebrew",
    "fi": "finnish",
    "et": "estonian",
    "lt": "lithuanian",
    "lv": "latvian",
    "ja": "japanese",
}
