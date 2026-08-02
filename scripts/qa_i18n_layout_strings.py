#!/usr/bin/env python3
"""Soft QA: flag UI strings much longer than FR in layout-sensitive keys.

Step 6 gate for the 9-language rollout (and existing non-FR packs).
Hard fail = missing keys vs FR. Soft = long chrome labels (informational,
guide copy overrides / Swift flex).
"""

from __future__ import annotations

import argparse
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

# Tight chrome — tabs, CTAs, badges, legal, streak, TF.
SENSITIVE = [
    "discount.sideTab.label",
    "onboardingV2.pw.free",
    "onboardingV2.pw.pro",
    "onboardingV2.pw.trialBadge",
    "onboardingV2.pw.startTrial",
    "paywall.restore",
    "paywall.cta.unlockFree",
    "paywall.trialBadge",
    "paywall.quiz.demo.badge.mcq",
    "paywall.quiz.demo.badge.trueFalse",
    "paywall.quiz.demo.badge.slider",
    "paywall.quiz.demo.badge.chrono",
    "paywall.error.retry",
    "settings.terms.title",
    "settings.privacy.title",
    "common.streak.day",
    "common.streak.days",
    "common.processing",
    "common.continue",
    "common.next",
    "common.backHome",
    "quiz.trueFalse.true",
    "quiz.trueFalse.false",
    "tab.home",
    "tab.library",
    "tab.training",
    "tab.collections",
    "tab.profile",
    "home.start",
    "home.skip",
    "training.title",
]

# Prefer ≤ this many characters for ultra-tight chrome (tabs / side tab / TF).
HARD_MAX = {
    "tab.home": 10,
    "tab.library": 10,
    "tab.training": 12,
    "tab.collections": 12,
    "tab.profile": 10,
    "discount.sideTab.label": 10,
    "quiz.trueFalse.true": 10,
    "quiz.trueFalse.false": 10,
    "onboardingV2.pw.pro": 4,
    "onboardingV2.pw.free": 10,
    "paywall.quiz.demo.badge.mcq": 14,
    "common.streak.day": 6,
    "common.streak.days": 6,
}


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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--langs",
        default="",
        help="Comma-separated lang codes (default: all non-FR with a UI pack)",
    )
    args = parser.parse_args()

    text = LOCALIZABLE.read_text(encoding="utf-8")
    maps = {code: parse_block(text, name) for code, name in LANG_BLOCKS.items()}
    fr = maps["fr"]
    print(f"Parsed FR keys: {len(fr)}")

    wanted = [c.strip() for c in args.langs.split(",") if c.strip()] or list(LANGS)
    qa_langs = [lang for lang in wanted if maps.get(lang)]
    pending = [lang for lang in wanted if not maps.get(lang)]
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
        hard_max = HARD_MAX.get(key)
        for lang in qa_langs:
            val = maps[lang].get(key)
            if val is None:
                print(f"  HARD missing {lang}: {key}")
                hard += 1
                continue
            # Decode swift escapes for length checks
            decoded = val.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")
            fr_decoded = fr_val.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")
            too_long_vs_fr = len(decoded) > max(len(fr_decoded) + 6, int(len(fr_decoded) * 1.6))
            too_long_abs = hard_max is not None and len(decoded) > hard_max
            if too_long_vs_fr or too_long_abs:
                why = []
                if too_long_vs_fr:
                    why.append("vsFR")
                if too_long_abs:
                    why.append(f">max{hard_max}")
                print(
                    f"  LONG {lang} {key} [{'+'.join(why)}]: "
                    f"FR({len(fr_decoded)})={fr_decoded!r} → ({len(decoded)})={decoded!r}"
                )
                soft += 1

    print(f"\nHard: {hard}  Soft long-string: {soft}")
    if hard:
        print("GATE6 FAIL — key parity")
        return 1
    print("GATE6 PASS — key parity OK; long-string warnings are informational")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
