#!/usr/bin/env python3
"""Soft QA: flag UI strings much longer than FR in layout-sensitive keys."""

from __future__ import annotations

import re
import sys
from pathlib import Path

from i18n_languages import NON_FR_LANGS, SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
LOCALIZABLE = ROOT / "ios/Sophia/Utilities/AppLocalizable.swift"

LANGS = NON_FR_LANGS
LANG_BLOCKS = {
    code: SWIFT_CASE_BY_CODE[code]
    for code in ["fr", *NON_FR_LANGS]
    if code in SWIFT_CASE_BY_CODE
}

SENSITIVE = [
    "discount.sideTab.label",
    "onboardingV2.pw.free",
    "onboardingV2.pw.pro",
    "onboardingV2.pw.trialBadge",
    "onboardingV2.pw.startTrial",
    "paywall.restore",
    "settings.terms.title",
    "settings.privacy.title",
    "paywall.cta.unlockFree",
    "common.streak.day",
    "common.streak.days",
    "quiz.trueFalse.true",
    "quiz.trueFalse.false",
    "tab.library",
    "tab.training",
    "common.processing",
]


def parse_block(text: str, name: str) -> dict[str, str]:
    m = re.search(
        rf"private static let {name}:\s*\[String:\s*String\]\s*=\s*\[",
        text,
    )
    if not m:
        return {}
    start = m.end() - 1
    depth = 0
    i = start
    while i < len(text):
        if text[i] == "[":
            depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0:
                block = text[start : i + 1]
                out: dict[str, str] = {}
                for km in re.finditer(r'"([^"\\]+)"\s*:\s*"((?:\\.|[^"\\])*)"', block):
                    out[km.group(1)] = km.group(2)
                return out
        i += 1
    return {}


def main() -> int:
    text = LOCALIZABLE.read_text(encoding="utf-8")
    maps = {code: parse_block(text, name) for code, name in LANG_BLOCKS.items()}
    fr = maps["fr"]
    print(f"Parsed FR keys: {len(fr)}")
    # Skip locales that are wired in AppLanguage but do not have a UI pack yet
    # (empty dictionary → English runtime fallback). Those are filled in later steps.
    qa_langs = [lang for lang in LANGS if maps.get(lang)]
    pending = [lang for lang in LANGS if not maps.get(lang)]
    if pending:
        print(f"  skip (no UI pack yet): {', '.join(pending)}")
    hard = 0
    soft = 0
    for lang in qa_langs:
        missing = sorted(set(fr) - set(maps[lang]))
        if missing:
            print(f"  HARD {lang}: missing {len(missing)} keys vs FR (e.g. {missing[:3]})")
            hard += len(missing)
        extra = sorted(set(maps[lang]) - set(fr))
        if extra:
            print(f"  note {lang}: {len(extra)} extra keys vs FR")
    for key in SENSITIVE:
        fr_val = fr.get(key)
        if fr_val is None:
            print(f"  soft missing FR: {key}")
            soft += 1
            continue
        for lang in qa_langs:
            val = maps[lang].get(key)
            if val is None:
                print(f"  HARD missing {lang}: {key}")
                hard += 1
                continue
            if len(val) > max(len(fr_val) + 6, int(len(fr_val) * 1.6)):
                print(
                    f"  LONG {lang} {key}: FR({len(fr_val)})={fr_val!r} "
                    f"→ ({len(val)})={val!r}"
                )
                soft += 1
    print(f"\nHard: {hard}  Soft long-string: {soft}")
    if hard:
        print("GATE5 FAIL — key parity")
        return 1
    print("GATE5 PASS — key parity OK; long-string warnings are informational")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
