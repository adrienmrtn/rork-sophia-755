#!/usr/bin/env python3
"""Apply the round-2 naturalness patch to the iOS table and every mirror.

Targets, in order:
    ios/Sophia/Utilities/AppLocalizable.swift   (source of truth)
    content/locales/<lang>/ui_strings.json      (JSON packs, where present)
    android/app/src/main/assets/strings/<lang>.json
    scripts/ui_string_overrides.json            (so a re-inject cannot revert)

Usage:
    python scripts/apply_naturalness_v2.py [--check]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from i18n_languages import SWIFT_CASE_BY_CODE
from naturalness_ui_v2 import PATCH
from translate_ui_strings import extract_dict_entries, render_dict_body

ROOT = Path(__file__).resolve().parents[1]
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
LOCALES_DIR = ROOT / "content" / "locales"
ANDROID_DIR = ROOT / "android" / "app" / "src" / "main" / "assets" / "strings"
OVERRIDES_CHROME = ROOT / "scripts" / "ui_string_overrides.json"

PLACEHOLDER = re.compile(r"%(?:\d+\$)?[@dsf]|%%")

# Ultra-tight chrome: a longer string clips or wraps badly.
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


def replace_dict_body(source: str, name: str, entries: list[tuple[str, str]]) -> str:
    match = re.search(rf"private static let {name}: \[String: String\] = \[", source)
    if not match:
        raise SystemExit(f"Dictionary {name!r} not found")
    start = match.end() - 1
    depth = 0
    for i in range(start, len(source)):
        ch = source[i]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                end = i
                break
    else:
        raise SystemExit(f"Unclosed dictionary {name!r}")
    body = "\n" + render_dict_body(entries) + "\n    "
    return source[: start + 1] + body + source[end:]


def validate(lang: str, key: str, french: str, value: str) -> list[str]:
    errors = []
    if sorted(PLACEHOLDER.findall(french)) != sorted(PLACEHOLDER.findall(value)):
        errors.append(
            f"{lang}/{key}: placeholder mismatch — FR {french!r} vs {value!r}"
        )
    positional = "$" in "".join(PLACEHOLDER.findall(value))
    plain = [p for p in PLACEHOLDER.findall(value) if "$" not in p and p != "%%"]
    if positional and plain:
        errors.append(f"{lang}/{key}: mixes positional and plain placeholders")
    for line in value.split("\n"):
        if line != line.strip():
            errors.append(f"{lang}/{key}: stray whitespace around a line break")
            break
    if "\n" in value and any(not line.strip() for line in value.split("\n")):
        errors.append(f"{lang}/{key}: empty line in a multi-line label")
    limit = HARD_MAX.get(key)
    if limit and len(value) > limit:
        errors.append(f"{lang}/{key}: {len(value)} chars > {limit} budget — {value!r}")
    return errors


def apply(check_only: bool = False) -> int:
    source = LOCALIZABLE.read_text(encoding="utf-8")
    french = dict(extract_dict_entries(source, "french"))
    # French patches land first so later locales validate against the new source.
    french.update(PATCH.get("fr", {}))

    errors: list[str] = []
    total = 0

    for lang, patch in PATCH.items():
        name = SWIFT_CASE_BY_CODE[lang]
        entries = extract_dict_entries(source, name)
        current = dict(entries)
        for key, value in patch.items():
            if key not in current:
                errors.append(f"{lang}: unknown key {key!r}")
                continue
            errors.extend(validate(lang, key, french.get(key, ""), value))

        changed = sum(1 for k, v in patch.items() if current.get(k) != v)
        total += changed
        print(f"[{lang}] {changed} keys change")
        if not check_only:
            new_entries = [(k, patch.get(k, v)) for k, v in entries]
            source = replace_dict_body(source, name, new_entries)

    # Highlight fragments must still occur inside their headline.
    src_now = LOCALIZABLE.read_text(encoding="utf-8")
    for lang, patch in PATCH.items():
        merged = dict(extract_dict_entries(src_now, SWIFT_CASE_BY_CODE[lang]))
        merged.update(patch)
        for head_key, hi_key in (
            ("paywall.header", "paywall.header.highlight"),
            ("paywall.weaponHeadline", "paywall.weaponHeadline.highlight"),
            ("paywall.premiumHeadline", "paywall.premiumHeadline.highlight"),
        ):
            if merged[hi_key] not in merged[head_key]:
                errors.append(
                    f"{lang}: {hi_key} {merged[hi_key]!r} not inside {head_key} {merged[head_key]!r}"
                )

    if errors:
        print("ERRORS:", file=sys.stderr)
        for err in errors:
            print(f"  {err}", file=sys.stderr)
        return 1

    if check_only:
        print(f"check OK — {total} value changes pending")
        return 0

    LOCALIZABLE.write_text(source, encoding="utf-8")

    for lang, patch in PATCH.items():
        pack = LOCALES_DIR / lang / "ui_strings.json"
        if pack.exists():
            data = json.loads(pack.read_text(encoding="utf-8"))
            data.update(patch)
            pack.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
        droid = ANDROID_DIR / f"{lang}.json"
        if droid.exists():
            data = json.loads(droid.read_text(encoding="utf-8"))
            data.update(patch)
            droid.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )

    chrome = (
        json.loads(OVERRIDES_CHROME.read_text(encoding="utf-8"))
        if OVERRIDES_CHROME.exists()
        else {}
    )
    for lang, patch in PATCH.items():
        if lang == "fr":
            continue
        chrome.setdefault(lang, {}).update(patch)
    OVERRIDES_CHROME.write_text(
        json.dumps(chrome, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    print(f"Wrote {LOCALIZABLE} ({total} value changes)")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    raise SystemExit(apply(check_only=args.check))


if __name__ == "__main__":
    main()
