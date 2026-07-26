#!/usr/bin/env python3
"""Merge per-locale AppLocalizable dictionaries into the multi-language file."""

from __future__ import annotations

import re
from pathlib import Path

from i18n_languages import NON_FR_LANGS, SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "ios/Sophia/Utilities/AppLocalizable.swift"

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

# Keys for every language name shown in UI copy (native endonyms).
ALL_LANGUAGE_KEYS: dict[str, str] = {
    f"language.{name}": label for name, label in NATIVE_LANGUAGE_NAMES.items()
}

# Languages that currently ship a dedicated dictionary block in AppLocalizable.
SHIPPED_DICT_NAMES = [
    "french",
    "english",
    "spanish",
    "german",
    "portuguese",
    "italian",
]

PENDING_CASES = [
    SWIFT_CASE_BY_CODE[code]
    for code in NON_FR_LANGS
    if SWIFT_CASE_BY_CODE[code] not in SHIPPED_DICT_NAMES
]


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


def render() -> str:
    # AppLocalizable.swift in the working tree is the single source of truth for
    # every shipped language. Reading from it keeps this script idempotent.
    local_src = TARGET.read_text(encoding="utf-8")

    dicts = {
        name: inject_language_keys(extract_dict(local_src, name))
        for name in SHIPPED_DICT_NAMES
    }

    pending_cases = ", ".join(f".{name}" for name in PENDING_CASES)
    # Wrap long case list for readability in generated Swift.
    pending_case_lines = []
    chunk: list[str] = []
    for name in PENDING_CASES:
        chunk.append(f".{name}")
        if len(chunk) >= 5:
            pending_case_lines.append(", ".join(chunk) + ",")
            chunk = []
    if chunk:
        pending_case_lines.append(", ".join(chunk))
    pending_block = "\n             ".join(pending_case_lines)

    sections = []
    for name in SHIPPED_DICT_NAMES:
        title = name.capitalize()
        sections.append(
            f"""    // MARK: - {title}

    private static let {name}: [String: String] = [
{dicts[name]}
    ]"""
        )
    sections_text = "\n\n".join(sections)

    return f"""import Foundation

enum AppLocalizable {{
    static func string(_ key: String, language: AppLanguage) -> String {{
        if let value = table(for: language)[key] {{
            return value
        }}
        if language != .english, let value = english[key] {{
            return value
        }}
        return key
    }}

    /// Per-language UI tables. Languages without a dedicated dictionary yet
    /// (new locales before their UI pack lands) resolve via English fallback.
    private static func table(for language: AppLanguage) -> [String: String] {{
        switch language {{
        case .french: french
        case .english: english
        case .spanish: spanish
        case .german: german
        case .portuguese: portuguese
        case .italian: italian
        case {pending_block}:
            [:]
        }}
    }}

{sections_text}
}}
"""


def main() -> None:
    TARGET.write_text(render(), encoding="utf-8")
    print(f"Wrote {TARGET}")
    print(f"Shipped dicts: {', '.join(SHIPPED_DICT_NAMES)}")
    print(f"Pending EN-fallback cases: {', '.join(PENDING_CASES)}")


if __name__ == "__main__":
    main()
