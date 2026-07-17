#!/usr/bin/env python3
"""Merge per-locale AppLocalizable dictionaries into a single 6-language file."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "ios/Sophia/Utilities/AppLocalizable.swift"

DICT_RE = re.compile(
    r"private static let (?P<name>\w+): \[String: String\] = \[(?P<body>.*?)^\s*\]",
    re.S | re.M,
)

EXTRA_LANGUAGE_KEYS: dict[str, dict[str, str]] = {
    "french": {
        "language.spanish": "Español",
        "language.german": "Deutsch",
        "language.portuguese": "Português",
        "language.italian": "Italiano",
    },
    "english": {
        "language.spanish": "Español",
        "language.german": "Deutsch",
        "language.portuguese": "Português",
        "language.italian": "Italiano",
    },
    "spanish": {
        "language.german": "Alemán",
        "language.portuguese": "Portugués",
        "language.italian": "Italiano",
    },
    "german": {
        "language.spanish": "Spanisch",
        "language.portuguese": "Portugiesisch",
        "language.italian": "Italienisch",
    },
    "portuguese": {
        "language.spanish": "Espanhol",
        "language.german": "Alemão",
        "language.italian": "Italiano",
    },
    "italian": {
        "language.spanish": "Spagnolo",
        "language.german": "Tedesco",
        "language.portuguese": "Portoghese",
    },
}


def extract_dict(source: str, name: str) -> str:
    for match in DICT_RE.finditer(source):
        if match.group("name") == name:
            return match.group("body").strip("\n")
    raise SystemExit(f"Dictionary {name!r} not found")


def inject_language_keys(body: str, lang: str) -> str:
    extras = EXTRA_LANGUAGE_KEYS.get(lang, {})
    if not extras:
        return body
    # Only inject keys that are not already present, so the script is
    # idempotent and safe to re-run against an already-merged file.
    missing = {k: v for k, v in extras.items() if f'"{k}"' not in body}
    if not missing:
        return body
    lines = body.splitlines()
    out: list[str] = []
    inserted = False
    for line in lines:
        out.append(line)
        if not inserted and '"language.english"' in line:
            for key, value in missing.items():
                indent = re.match(r"^(\s*)", line).group(1)
                out.append(f'{indent}"{key}": "{value}",')
            inserted = True
    if not inserted:
        raise SystemExit(f"Could not inject language keys for {lang}")
    return "\n".join(out)


def render() -> str:
    # AppLocalizable.swift in the working tree is the single source of truth for
    # every language. Reading from it (instead of divergent remote branches)
    # keeps this script idempotent and prevents regressing hand-edited strings.
    local_src = TARGET.read_text(encoding="utf-8")

    french = inject_language_keys(extract_dict(local_src, "french"), "french")
    english = inject_language_keys(extract_dict(local_src, "english"), "english")
    spanish = inject_language_keys(extract_dict(local_src, "spanish"), "spanish")
    german = inject_language_keys(extract_dict(local_src, "german"), "german")
    portuguese = inject_language_keys(extract_dict(local_src, "portuguese"), "portuguese")

    italian_body = (ROOT / "content/locales/it/ui_strings_swift.txt").read_text(encoding="utf-8").strip("\n")
    italian = inject_language_keys(italian_body, "italian")

    return f"""import Foundation

enum AppLocalizable {{
    static func string(_ key: String, language: AppLanguage) -> String {{
        switch language {{
        case .french:
            return french[key] ?? english[key] ?? key
        case .english:
            return english[key] ?? key
        case .spanish:
            return spanish[key] ?? english[key] ?? key
        case .german:
            return german[key] ?? english[key] ?? key
        case .portuguese:
            return portuguese[key] ?? english[key] ?? key
        case .italian:
            return italian[key] ?? english[key] ?? key
        }}
    }}

    // MARK: - French

    private static let french: [String: String] = [
{french}
    ]

    // MARK: - English

    private static let english: [String: String] = [
{english}
    ]

    // MARK: - Spanish

    private static let spanish: [String: String] = [
{spanish}
    ]

    // MARK: - German

    private static let german: [String: String] = [
{german}
    ]

    // MARK: - Portuguese

    private static let portuguese: [String: String] = [
{portuguese}
    ]

    // MARK: - Italian

    private static let italian: [String: String] = [
{italian}
    ]
}}
"""


def main() -> None:
    TARGET.write_text(render(), encoding="utf-8")
    print(f"Wrote {TARGET}")


if __name__ == "__main__":
    main()
