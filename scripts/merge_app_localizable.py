#!/usr/bin/env python3
"""Rebuild AppLocalizable.swift from shipped dictionaries + UI JSON packs.

Prefer ``scripts/translate_ui_strings.py inject`` for the nine new locales.
This helper keeps the same table(for:) shape when reshuffling existing packs.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from i18n_languages import NON_FR_LANGS, SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "ios/Sophia/Utilities/AppLocalizable.swift"
LOCALES_DIR = ROOT / "content" / "locales"

DICT_RE = re.compile(
    r"private static let (?P<name>\w+): \[String: String\] = \[(?P<body>.*?)^\s*\]",
    re.S | re.M,
)

NATIVE_LANGUAGE_NAMES: dict[str, str] = {
    "french": "Français",
    "english": "English",
    "spanish": "Español",
    "german": "Deutsch",
    "portuguese": "Português",
    "italian": "Italiano",
    "turkish": "Türkçe",
    "polish": "Polski",
    "romanian": "Română",
    "dutch": "Nederlands",
    "greek": "Ελληνικά",
    "swedish": "Svenska",
    "hungarian": "Magyar",
    "bulgarian": "Български",
    "czech": "Čeština",
}

ALL_LANGUAGE_KEYS: dict[str, str] = {
    f"language.{name}": label for name, label in NATIVE_LANGUAGE_NAMES.items()
}

SHIPPED_CODES = ["fr", "en", *NON_FR_LANGS]
# Unique while preserving order (en appears in NON_FR_LANGS).
_seen: set[str] = set()
SHIPPED_CODES = [c for c in SHIPPED_CODES if not (c in _seen or _seen.add(c))]
SHIPPED_DICT_NAMES = [SWIFT_CASE_BY_CODE[c] for c in SHIPPED_CODES]


def extract_dict(source: str, name: str) -> str:
    for match in DICT_RE.finditer(source):
        if match.group("name") == name:
            return match.group("body").strip("\n")
    raise SystemExit(f"Dictionary {name!r} not found")


def inject_language_keys(body: str) -> str:
    missing = {k: v for k, v in ALL_LANGUAGE_KEYS.items() if f'"{k}"' not in body}
    if not missing:
        return body
    lines = body.splitlines()
    out: list[str] = []
    inserted = False
    for line in lines:
        out.append(line)
        if not inserted and '"language.english"' in line:
            indent = re.match(r"^(\s*)", line).group(1)
            for key, value in missing.items():
                out.append(f'{indent}"{key}": "{value}",')
            inserted = True
    if not inserted:
        raise SystemExit("Could not inject language keys")
    return "\n".join(out)


def main() -> None:
    # Delegate to the UI inject path so both tools stay aligned.
    from translate_ui_strings import inject

    inject()
    print(f"Shipped dicts: {', '.join(SHIPPED_DICT_NAMES)}")
    packs = sorted(p.parent.name for p in LOCALES_DIR.glob("*/ui_strings.json"))
    print(f"JSON UI packs present: {', '.join(packs)}")


if __name__ == "__main__":
    main()
