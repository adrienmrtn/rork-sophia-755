#!/usr/bin/env python3
"""Wire the seven new UI locales into AppLocalizable.swift and its mirrors.

New locales: Danish, Norwegian Bokmal, Russian, Croatian (``new_locales_ui_data``)
plus Slovenian, Slovak and Serbian (``new_locales_ui_data2``).

What it writes:
    ios/Sophia/Utilities/AppLocalizable.swift   (source of truth: 7 new tables
                                                 + the 7 new language.* autonyms
                                                 in every existing table)
    content/locales/<lang>/ui_strings.json      (JSON pack per new locale)
    android/app/src/main/assets/strings/<lang>.json

Usage:
    python scripts/apply_new_locales.py [--check]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from i18n_languages import SWIFT_CASE_BY_CODE, UI_ONLY_LANGS
from new_locales_ui_data import STRINGS as STRINGS4
from new_locales_ui_data2 import STRINGS3
from translate_ui_strings import extract_dict_entries, render_dict_body

ROOT = Path(__file__).resolve().parents[1]
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
LOCALES_DIR = ROOT / "content" / "locales"
ANDROID_DIR = ROOT / "android" / "app" / "src" / "main" / "assets" / "strings"

PLACEHOLDER = re.compile(r"%(?:\d+\$)?[@dsf]|%%")

# Autonyms for the language picker: the same string in every table, like the
# fifteen that already ship.
NEW_AUTONYMS = {
    "language.danish": "Dansk",
    "language.norwegian": "Norsk",
    "language.russian": "Русский",
    "language.croatian": "Hrvatski",
    "language.slovenian": "Slovenščina",
    "language.slovak": "Slovenčina",
    "language.serbian": "Српски",
}

# Keys the Android string packs carry but the Swift table does not: the
# notification channel is an Android platform concept with no iOS counterpart.
ANDROID_ONLY = {
    "notification.channel.name": {
        "da": "Kursusforslag",
        "nb": "Kursforslag",
        "ru": "Рекомендации курсов",
        "hr": "Prijedlozi tečajeva",
        "sl": "Predlogi tečajev",
        "sk": "Návrhy kurzov",
        "sr": "Предлози курсева",
    },
    "notification.channel.description": {
        "da": "Et lille skub i ny og næ til at tage fat på et kursus igen.",
        "nb": "Av og til en liten dytt for å ta fatt på et kurs igjen.",
        "ru": "Изредка напоминаем вернуться к курсу.",
        "hr": "Povremeni podsjetnik da se vratiš tečaju.",
        "sl": "Občasen opomnik, da se vrneš k tečaju.",
        "sk": "Občasné pripomenutie, aby si sa vrátil ku kurzu.",
        "sr": "Повремени подсетник да се вратиш курсу.",
    },
}

# Same ultra-tight chrome budgets the round-2 patch enforces.
HARD_MAX = {
    "tab.home": 12,
    "tab.library": 12,
    "tab.training": 14,
    "tab.collections": 14,
    "tab.profile": 12,
    "discount.sideTab.label": 10,
    "quiz.trueFalse.true": 12,
    "quiz.trueFalse.false": 12,
    "onboardingV2.pw.pro": 8,
    "onboardingV2.pw.free": 12,
    "paywall.quiz.demo.badge.mcq": 16,
    "paywall.quiz.demo.badge.trueFalse": 20,
    "paywall.quiz.demo.badge.slider": 16,
    "paywall.quiz.demo.badge.chrono": 20,
    "common.streak.day": 8,
    "common.streak.days": 8,
    "library.filter.all": 14,
    "library.filter.todo": 16,
    "library.filter.inProgress": 18,
    "library.filter.done": 14,
    "library.filter.favorites": 16,
    "collections.badge.complete": 16,
    "collections.badge.path": 14,
}

HIGHLIGHTS = (
    ("paywall.header", "paywall.header.highlight"),
    ("paywall.weaponHeadline", "paywall.weaponHeadline.highlight"),
    ("paywall.premiumHeadline", "paywall.premiumHeadline.highlight"),
)

# Scripts each locale is written in, so a Latin slip inside a Cyrillic string
# (or the reverse) is caught before it ships. Format specifiers are stripped
# first; brand names and the handful of Latin tokens below are exempt, and the
# language.* autonyms are exempt wholesale (they are spelled in their own
# language's script by design).
CYRILLIC_LANGS = {"ru", "sr"}
LATIN_WORD = re.compile(r"[A-Za-zÀ-ÖØ-öø-ÿ]+")
CYRILLIC_CHAR = re.compile(r"[\u0400-\u04FF]")
ALLOWED_LATIN = {
    "sophia", "premium", "pro", "app", "store", "storeu", "storeom", "xp",
    "apple", "google", "tiktok", "ugc", "debug", "kombo", "min", "h", "t",
    "com", "email", "ti", "ty", "e", "g", "x",
}


def _script_errors(lang: str, key: str, value: str) -> list[str]:
    if key.startswith("language."):
        return []
    bare = PLACEHOLDER.sub(" ", value)
    if lang in CYRILLIC_LANGS:
        stray = sorted(
            {w for w in LATIN_WORD.findall(bare) if w.lower() not in ALLOWED_LATIN}
        )
        if stray:
            return [f"{lang}/{key}: Latin script in a Cyrillic table — {stray}"]
    elif CYRILLIC_CHAR.search(bare):
        return [f"{lang}/{key}: Cyrillic in a Latin-script table — {value!r}"]
    return []


def build_tables() -> dict[str, dict[str, str]]:
    """One full {key: value} table per new locale, autonyms included."""
    tables: dict[str, dict[str, str]] = {}
    for source in (STRINGS4, STRINGS3):
        for key, row in source.items():
            for lang, value in row.items():
                tables.setdefault(lang, {})[key] = value
    for table in tables.values():
        table.update(NEW_AUTONYMS)
    return tables


def validate(lang: str, key: str, french: str, value: str) -> list[str]:
    errors: list[str] = []
    if sorted(PLACEHOLDER.findall(french)) != sorted(PLACEHOLDER.findall(value)):
        errors.append(f"{lang}/{key}: placeholder mismatch — FR {french!r} vs {value!r}")
    found = PLACEHOLDER.findall(value)
    if any("$" in p for p in found) and any("$" not in p and p != "%%" for p in found):
        errors.append(f"{lang}/{key}: mixes positional and plain placeholders")
    if value != value.strip():
        errors.append(f"{lang}/{key}: leading or trailing whitespace")
    for line in value.split("\n"):
        if line != line.strip():
            errors.append(f"{lang}/{key}: stray whitespace around a line break")
            break
    if "\n" in value and any(not line.strip() for line in value.split("\n")):
        errors.append(f"{lang}/{key}: empty line in a multi-line label")
    if french.count("\n") != value.count("\n"):
        errors.append(
            f"{lang}/{key}: {value.count(chr(10))} line breaks vs FR {french.count(chr(10))}"
        )
    limit = HARD_MAX.get(key)
    if limit and len(value) > limit:
        errors.append(f"{lang}/{key}: {len(value)} chars > {limit} budget — {value!r}")
    errors.extend(_script_errors(lang, key, value))
    return errors


def insert_dicts(source: str, tables: dict[str, dict[str, str]], order: list[str]) -> str:
    """Adds (or refreshes) the new tables and their switch arms.

    Re-running must not duplicate a dictionary or a switch case: a Swift literal
    with the same key twice crashes at runtime, and a duplicate `case` will not
    compile. So an existing table is replaced in place and only a genuinely new
    one is appended.
    """
    blocks = []
    for code in order:
        name = SWIFT_CASE_BY_CODE[code]
        entries = [(k, tables[code][k]) for k in KEY_ORDER]
        if re.search(rf"private static let {name}: \[String: String\] = \[", source):
            source = replace_dict_body(source, name, entries)
            continue
        blocks.append(
            f"\n    // MARK: - {name.capitalize()}\n\n"
            f"    private static let {name}: [String: String] = [\n"
            f"{render_dict_body(entries)}\n    ]\n"
        )
    if blocks:
        anchor = "    private static let czech: [String: String] = ["
        end = source.index("]\n", source.index(anchor))
        insert_at = end + len("]\n")
        source = source[:insert_at] + "".join(blocks) + source[insert_at:]

    switch_anchor = "        case .czech: czech\n"
    if switch_anchor not in source:
        raise SystemExit("table(for:) switch anchor not found")
    cases = "".join(
        f"        case .{SWIFT_CASE_BY_CODE[c]}: {SWIFT_CASE_BY_CODE[c]}\n"
        for c in order
        if f"        case .{SWIFT_CASE_BY_CODE[c]}: {SWIFT_CASE_BY_CODE[c]}\n" not in source
    )
    return source.replace(switch_anchor, switch_anchor + cases, 1)


def replace_dict_body(source: str, name: str, entries: list[tuple[str, str]]) -> str:
    match = re.search(rf"private static let {name}: \[String: String\] = \[", source)
    if not match:
        raise SystemExit(f"Dictionary {name!r} not found")
    start = match.end() - 1
    depth = 0
    for i in range(start, len(source)):
        if source[i] == "[":
            depth += 1
        elif source[i] == "]":
            depth -= 1
            if depth == 0:
                end = i
                break
    else:
        raise SystemExit(f"Unclosed dictionary {name!r}")
    body = "\n" + render_dict_body(entries) + "\n    "
    return source[: start + 1] + body + source[end:]


KEY_ORDER: list[str] = []


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    source = LOCALIZABLE.read_text(encoding="utf-8")
    french_entries = extract_dict_entries(source, "french")
    french = dict(french_entries)
    tables = build_tables()

    order = [c for c in UI_ONLY_LANGS]
    missing_langs = [c for c in order if c not in tables]
    if missing_langs:
        raise SystemExit(f"No strings for {missing_langs}")

    global KEY_ORDER
    # dict.fromkeys keeps order and drops the autonyms if a previous run already
    # wrote them into the French table — duplicate keys in a Swift literal crash.
    KEY_ORDER = list(dict.fromkeys([k for k, _ in french_entries] + list(NEW_AUTONYMS)))

    errors: list[str] = []
    for code in order:
        table = tables[code]
        unknown = sorted(set(table) - set(KEY_ORDER))
        absent = [k for k in KEY_ORDER if k not in table]
        if unknown:
            errors.append(f"{code}: unknown keys {unknown[:5]}")
        if absent:
            errors.append(f"{code}: missing {len(absent)} keys (e.g. {absent[:5]})")
        for key, value in table.items():
            if key in french:
                errors.extend(validate(code, key, french[key], value))
        for head_key, hi_key in HIGHLIGHTS:
            if table.get(hi_key) and table[hi_key] not in table.get(head_key, ""):
                errors.append(
                    f"{code}: {hi_key} {table[hi_key]!r} not inside {head_key} {table.get(head_key)!r}"
                )

    if errors:
        print("ERRORS:", file=sys.stderr)
        for err in errors:
            print(f"  {err}", file=sys.stderr)
        return 1

    if args.check:
        print(f"check OK — {len(order)} locales × {len(KEY_ORDER)} keys")
        return 0

    # The autonyms are new keys, so every table already in the file needs them
    # too or key parity breaks in qa_i18n_layout_strings.py.
    for code, name in SWIFT_CASE_BY_CODE.items():
        if code in order:
            continue
        entries = extract_dict_entries(source, name)
        have = {k for k, _ in entries}
        entries += [(k, v) for k, v in NEW_AUTONYMS.items() if k not in have]
        source = replace_dict_body(source, name, entries)

    source = insert_dicts(source, tables, order)
    LOCALIZABLE.write_text(source, encoding="utf-8")

    for code in order:
        payload = {k: tables[code][k] for k in KEY_ORDER}
        pack = LOCALES_DIR / code / "ui_strings.json"
        pack.parent.mkdir(parents=True, exist_ok=True)
        pack.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        droid_payload = dict(payload)
        droid_payload.update({k: v[code] for k, v in ANDROID_ONLY.items()})
        droid = ANDROID_DIR / f"{code}.json"
        droid.parent.mkdir(parents=True, exist_ok=True)
        droid.write_text(
            json.dumps(droid_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )

    # The autonyms are new keys, so the packs that already shipped need them too.
    for path in sorted(LOCALES_DIR.glob("*/ui_strings.json")) + sorted(ANDROID_DIR.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        if all(k in data for k in NEW_AUTONYMS):
            continue
        data.update({k: v for k, v in NEW_AUTONYMS.items() if k not in data})
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )

    print(f"Wrote {len(order)} tables × {len(KEY_ORDER)} keys into {LOCALIZABLE.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
