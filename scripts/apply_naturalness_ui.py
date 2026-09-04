#!/usr/bin/env python3
"""Apply naturalness UI overrides to iOS AppLocalizable.swift and JSON packs.

Usage:
    python scripts/apply_naturalness_ui.py
    python scripts/apply_naturalness_ui.py --check
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from i18n_languages import SWIFT_CASE_BY_CODE
from naturalness_ui_data import LANGS, build_overrides
from translate_ui_strings import (
    encode_swift_string,
    extract_dict_entries,
    render_dict_body,
)

ROOT = Path(__file__).resolve().parents[1]
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
LOCALES_DIR = ROOT / "content" / "locales"
OVERRIDES_CHROME = ROOT / "scripts" / "ui_string_overrides.json"

JSON_PACK_LANGS = {"tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs"}

# App name must stay Latin "Sophia" — MT often turns it into the city Sofia.
BRAND_REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "bg": [("София", "Sophia")],
    "el": [("τη Σοφία", "τη Sophia"), ("στη Σοφία", "στη Sophia"), ("Η Σοφία", "Η Sophia"), ("Σοφία", "Sophia")],
    "sv": [("Utan Sofia", "Utan Sophia"), ("Sofia", "Sophia")],
}


def replace_dict_body(source: str, name: str, entries: list[tuple[str, str]]) -> str:
    match = re.search(
        rf"private static let {name}: \[String: String\] = \[",
        source,
    )
    if not match:
        raise SystemExit(f"Dictionary {name!r} not found")
    start = match.end() - 1
    depth = 0
    i = start
    while i < len(source):
        ch = source[i]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                end = i
                break
        i += 1
    else:
        raise SystemExit(f"Unclosed dictionary {name!r}")

    body = "\n" + render_dict_body(entries) + "\n    "
    return source[: start + 1] + body + source[end:]


def highlight_ok(overrides: dict[str, dict[str, str]], lang: str) -> list[str]:
    pairs = [
        ("paywall.header", "paywall.header.highlight"),
        ("paywall.weaponHeadline", "paywall.weaponHeadline.highlight"),
        ("paywall.premiumHeadline", "paywall.premiumHeadline.highlight"),
    ]
    errors = []
    table = overrides[lang]
    # Fall back to checking only when both keys are in this override set;
    # after apply we re-check against the merged table.
    for head_key, hi_key in pairs:
        if head_key not in table or hi_key not in table:
            continue
        head = table[head_key]
        hi = table[hi_key]
        if hi not in head:
            errors.append(f"{lang}: {hi_key} {hi!r} not in {head_key} {head!r}")
    return errors


def apply(check_only: bool = False) -> int:
    overrides = build_overrides()
    source = LOCALIZABLE.read_text(encoding="utf-8")

    errors: list[str] = []
    changed_keys_total = 0

    for lang in LANGS:
        name = SWIFT_CASE_BY_CODE[lang]
        entries = extract_dict_entries(source, name)
        current = dict(entries)
        patch = overrides[lang]
        unknown = [k for k in patch if k not in current]
        if unknown:
            errors.append(f"{lang}: unknown keys {unknown[:8]}")
        changed = 0
        new_entries = []
        brand_fixes = BRAND_REPLACEMENTS.get(lang, [])
        for key, value in entries:
            next_value = patch[key] if key in patch else value
            for old, new in brand_fixes:
                if old in next_value:
                    next_value = next_value.replace(old, new)
            if next_value != value:
                changed += 1
            new_entries.append((key, next_value))
        changed_keys_total += changed
        print(f"[{lang}] {changed} keys change")
        if not check_only:
            source = replace_dict_body(source, name, new_entries)

        # Highlight check on the merged result.
        merged = dict(new_entries)
        for head_key, hi_key in (
            ("paywall.header", "paywall.header.highlight"),
            ("paywall.weaponHeadline", "paywall.weaponHeadline.highlight"),
            ("paywall.premiumHeadline", "paywall.premiumHeadline.highlight"),
        ):
            if hi_key in merged and merged[hi_key] not in merged[head_key]:
                errors.append(
                    f"{lang}: highlight {hi_key}={merged[hi_key]!r} "
                    f"not in headline {merged[head_key]!r}"
                )

        if not check_only and lang in JSON_PACK_LANGS:
            pack_path = LOCALES_DIR / lang / "ui_strings.json"
            if pack_path.exists():
                pack = json.loads(pack_path.read_text(encoding="utf-8"))
                pack.update({k: v for k, v in patch.items() if k in pack or k in current})
                pack_path.write_text(
                    json.dumps(pack, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )

    if not check_only:
        LOCALIZABLE.write_text(source, encoding="utf-8")
        # Keep chrome overrides in sync so a later inject does not revert us.
        chrome = json.loads(OVERRIDES_CHROME.read_text(encoding="utf-8")) if OVERRIDES_CHROME.exists() else {}
        for lang, patch in overrides.items():
            if lang == "fr":
                continue
            bucket = chrome.setdefault(lang, {})
            bucket.update(patch)
        OVERRIDES_CHROME.write_text(
            json.dumps(chrome, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {LOCALIZABLE} ({changed_keys_total} value changes)")

    if errors:
        print("ERRORS:", file=sys.stderr)
        for err in errors:
            print(f"  {err}", file=sys.stderr)
        return 1
    print("highlight + key checks OK")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    raise SystemExit(apply(check_only=args.check))


if __name__ == "__main__":
    main()
