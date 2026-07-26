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
]

# Google Translate target codes (1:1 with app codes for current set).
GT_TARGETS: dict[str, str] = {code: code for code in NON_FR_LANGS}

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
}
