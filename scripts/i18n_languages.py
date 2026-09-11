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
]

# Locales whose UI is translated but whose course catalog has not shipped yet.
# They read the English catalog at runtime (see LocalizedContentLoader).
UI_ONLY_LANGS: list[str] = [
    "da",
    "nb",
    "ru",
    "hr",
    "sl",
    "sk",
    "sr",
]

# Google Translate target codes. Norwegian Bokmal is "no" upstream and Serbian
# must be requested in Cyrillic ("sr" already is); every other app code is 1:1.
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
}
