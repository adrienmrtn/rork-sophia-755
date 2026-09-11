#!/usr/bin/env python3
"""Wire a batch of UI locales into AppLocalizable.swift and its mirrors.

``apply_new_locales.py`` does this for the seven locales whose tables are
hand-written Python modules. This one takes the same gates to a batch whose
tables arrive as ``content/locales/<lang>/ui_strings.json`` — Arabic, Hebrew,
Finnish and Estonian — and adds the check those four need most: a table written
in Arabic or Hebrew must not be carrying English prose that the engine declined
to translate, and a Latin-script table must not be carrying any of their script
back the other way.

What it writes:
    ios/Sophia/Utilities/AppLocalizable.swift   (one table per locale, the
                                                 table(for:) arms, and the new
                                                 language.* autonyms in every
                                                 table that already shipped)
    content/locales/<lang>/ui_strings.json      (re-ordered to the English keys)
    android/app/src/main/assets/strings/<lang>.json

Usage:
    python scripts/apply_locale_batch.py --lang ar,he,fi,et --check
    python scripts/apply_locale_batch.py --lang ar,he,fi,et
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from apply_new_locales import HIGHLIGHTS, replace_dict_body, validate  # noqa: E402
from i18n_languages import SWIFT_CASE_BY_CODE  # noqa: E402
from translate_ui_strings import extract_dict_entries, render_dict_body  # noqa: E402

LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
LOCALES_DIR = ROOT / "content" / "locales"
ANDROID_DIR = ROOT / "android" / "app" / "src" / "main" / "assets" / "strings"

PLACEHOLDER = re.compile(r"%(?:\d+\$)?[@dsf]|%%")

#: Autonyms for the language picker: the same string in every table, like the
#: twenty-two that already ship.
NEW_AUTONYMS = {
    "language.arabic": "العربية",
    "language.hebrew": "עברית",
    "language.finnish": "Suomi",
    "language.estonian": "Eesti",
}

#: Keys the Android string packs carry but the Swift table does not: the
#: notification channel is an Android platform concept with no iOS counterpart.
ANDROID_ONLY = {
    "notification.channel.name": {
        "ar": "اقتراحات الدورات",
        "he": "הצעות לקורסים",
        "fi": "Kurssiehdotuksia",
        "et": "Kursusesoovitused",
    },
    "notification.channel.description": {
        "ar": "تذكير بين الحين والآخر للعودة إلى دورة.",
        "he": "תזכורת מדי פעם לחזור לקורס.",
        "fi": "Satunnainen muistutus palata kurssin pariin.",
        "et": "Aeg-ajalt meeldetuletus kursuse juurde naasta.",
    },
}

#: The script each locale is written in. A slip either way is a defect: English
#: left untranslated in the Arabic table, or Arabic leaking into the Finnish one.
ARABIC_CHAR = re.compile(r"[؀-ۿݐ-ݿ]")
HEBREW_CHAR = re.compile(r"[֐-׿יִ-ﭏ]")
CYRILLIC_CHAR = re.compile(r"[Ѐ-ӿ]")
LATIN_WORD = re.compile(r"[A-Za-zÀ-ÖØ-öø-ÿ]+")
NON_LATIN = {"ar": ARABIC_CHAR, "he": HEBREW_CHAR}

#: Latin that belongs in any table: brand names, units and the tokens the app
#: shows verbatim.
ALLOWED_LATIN = {
    "sophia", "premium", "pro", "app", "store", "xp", "apple", "google",
    "tiktok", "ugc", "debug", "ios", "android", "ok", "email", "id", "vs",
    "min", "h", "s", "e", "g", "x", "com",
}
#: An address or link is Latin in every language.
EMAIL_OR_URL = re.compile(r"\S+@\S+\.\S+|https?://|\bwww\.")


def script_errors(lang: str, key: str, value: str) -> list[str]:
    """Prose in the wrong script, which is how an untranslated string shows up."""
    if key.startswith("language."):
        return []  # Autonyms are spelled in their own script by design.
    bare = PLACEHOLDER.sub(" ", value)
    if lang in NON_LATIN:
        # An address is Latin in every language; so is a brand or a unit. Any
        # other Latin word in an Arabic or Hebrew table is a string the engine
        # handed back untranslated, whole or in part.
        if EMAIL_OR_URL.search(bare):
            return []
        stray = sorted(
            {w for w in LATIN_WORD.findall(bare) if w.lower() not in ALLOWED_LATIN}
        )
        if stray:
            return [f"{lang}/{key}: Latin prose left in — {stray}"]
        return []
    for script, pattern in (("Arabic", ARABIC_CHAR), ("Hebrew", HEBREW_CHAR), ("Cyrillic", CYRILLIC_CHAR)):
        if pattern.search(bare):
            return [f"{lang}/{key}: {script} in a Latin-script table — {value!r}"]
    return []


def load_pack(lang: str) -> dict[str, str]:
    path = LOCALES_DIR / lang / "ui_strings.json"
    if not path.exists():
        raise SystemExit(f"Missing UI pack: {path} — run translate_ui_strings.py first")
    return json.loads(path.read_text(encoding="utf-8"))


def insert_dicts(source: str, tables: dict[str, dict[str, str]], order: list[str], keys: list[str]) -> str:
    """Add (or refresh) each table and its ``table(for:)`` arm.

    Re-running must not duplicate a dictionary or a case: a Swift literal with
    the same key twice crashes at runtime and a duplicate case will not compile.
    """
    blocks = []
    for code in order:
        name = SWIFT_CASE_BY_CODE[code]
        entries = [(k, tables[code][k]) for k in keys]
        if re.search(rf"private static let {name}: \[String: String\] = \[", source):
            source = replace_dict_body(source, name, entries)
            continue
        blocks.append(
            f"\n    // MARK: - {name.capitalize()}\n\n"
            f"    private static let {name}: [String: String] = [\n"
            f"{render_dict_body(entries)}\n    ]\n"
        )
    if blocks:
        anchor = "    private static let serbian: [String: String] = ["
        end = source.index("]\n", source.index(anchor))
        source = source[: end + 2] + "".join(blocks) + source[end + 2 :]

    switch_anchor = "        case .serbian: serbian\n"
    if switch_anchor not in source:
        raise SystemExit("table(for:) switch anchor not found")
    cases = "".join(
        f"        case .{SWIFT_CASE_BY_CODE[c]}: {SWIFT_CASE_BY_CODE[c]}\n"
        for c in order
        if f"        case .{SWIFT_CASE_BY_CODE[c]}: {SWIFT_CASE_BY_CODE[c]}\n" not in source
    )
    return source.replace(switch_anchor, switch_anchor + cases, 1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", default="ar,he,fi,et")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    order = [code.strip() for code in args.lang.split(",") if code.strip()]

    source = LOCALIZABLE.read_text(encoding="utf-8")
    french_entries = extract_dict_entries(source, "french")
    french = dict(french_entries)
    keys = list(dict.fromkeys([k for k, _ in french_entries] + list(NEW_AUTONYMS)))

    tables: dict[str, dict[str, str]] = {}
    for code in order:
        table = load_pack(code)
        table.update(NEW_AUTONYMS)
        tables[code] = table

    errors: list[str] = []
    for code in order:
        table = tables[code]
        absent = [k for k in keys if k not in table]
        if absent:
            errors.append(f"{code}: missing {len(absent)} keys (e.g. {absent[:5]})")
        for key, value in table.items():
            if key in french:
                errors.extend(validate(code, key, french[key], value))
            errors.extend(script_errors(code, key, value))
        for head_key, hi_key in HIGHLIGHTS:
            if table.get(hi_key) and table[hi_key] not in table.get(head_key, ""):
                errors.append(
                    f"{code}: {hi_key} {table[hi_key]!r} not inside {head_key} {table.get(head_key)!r}"
                )

    if errors:
        print(f"{len(errors)} ERROR(S):", file=sys.stderr)
        for err in errors[:80]:
            print(f"  {err}", file=sys.stderr)
        if len(errors) > 80:
            print(f"  … and {len(errors) - 80} more", file=sys.stderr)
        return 1

    if args.check:
        print(f"check OK — {len(order)} locales × {len(keys)} keys")
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

    source = insert_dicts(source, tables, order, keys)
    LOCALIZABLE.write_text(source, encoding="utf-8")

    for code in order:
        payload = {k: tables[code][k] for k in keys}
        pack = LOCALES_DIR / code / "ui_strings.json"
        pack.parent.mkdir(parents=True, exist_ok=True)
        pack.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        droid = dict(payload)
        droid.update({k: v[code] for k, v in ANDROID_ONLY.items()})
        droid_path = ANDROID_DIR / f"{code}.json"
        droid_path.parent.mkdir(parents=True, exist_ok=True)
        droid_path.write_text(
            json.dumps(droid, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
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

    print(f"Wrote {len(order)} tables × {len(keys)} keys into {LOCALIZABLE.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
