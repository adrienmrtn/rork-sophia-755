#!/usr/bin/env python3
"""Translate the Android Terms / Privacy pack into the other app languages.

The Android documents are not a brand-swap of the iOS ones: whole passages
differ (the analytics section names Play Console and the Android settings path,
not App Analytics and the iPhone one). So they are translated from the Android
English pack directly, which is already correct for Play, rather than derived
from ``content/locales/<lang>/legal.json``.

Section ids, ordering and counts are copied unchanged; only titles and bodies
are translated. ``scripts/qa_android_phase_e.py`` then lints the result for
leftover iOS wording.

Usage:
    python scripts/translate_android_legal.py --lang da,nb,ru,hr,sl,sk,sr
    python scripts/translate_android_legal.py --lang all --force
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import mt_backend
from i18n_languages import GT_TARGETS, NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
LEGAL_DIR = ROOT / "android" / "app" / "src" / "main" / "assets" / "legal"
SOURCE = LEGAL_DIR / "en.json"

#: Words the engine must not touch. Hidden behind opaque tokens, restored after.
KEEP = [
    "Google Play Store", "Google Play", "Play Console", "Play Store",
    "Google Account", "Google", "Android", "Sophia", "RevenueCat",
    "Firebase", "Supabase", "Mixpanel", "TikTok",
]
BANNED = re.compile(r"\biOS\b|\biPhone\b|\biPad\b|\bApp Store\b|\bApple\b|UserDefaults", re.I)


def protect(text: str) -> tuple[str, list[str]]:
    kept: list[str] = []
    for term in KEEP:
        pattern = re.compile(rf"\b{re.escape(term)}\b")
        while True:
            match = pattern.search(text)
            if not match:
                break
            kept.append(match.group(0))
            text = text[: match.start()] + f"ZZK{len(kept) - 1}ZZ" + text[match.end():]
    return text, kept


def restore(text: str, kept: list[str]) -> str:
    for index, value in enumerate(kept):
        text = re.sub(rf"ZZ\s*K\s*{index}\s*ZZ", value.replace("\\", "\\\\"), text, flags=re.I)
    return re.sub(r"ZZ\s*K?\s*\d*\s*ZZ", "", text, flags=re.I)


def translate_lang(lang: str, source: dict, force: bool) -> Path | None:
    out_path = LEGAL_DIR / f"{lang}.json"
    if out_path.exists() and not force:
        print(f"  {lang}: exists, skipping (use --force)")
        return None

    flat: list[str] = []
    slots: list[tuple[str, int, str]] = []
    kept_per_string: list[list[str]] = []
    for kind in ("terms", "privacy"):
        for index, section in enumerate(source[kind]):
            for field in ("title", "body"):
                protected, kept = protect(section[field])
                flat.append(protected)
                kept_per_string.append(kept)
                slots.append((kind, index, field))

    target = GT_TARGETS.get(lang, lang)
    translated = mt_backend.translate_batch(flat, target, source="en")

    out = {kind: [dict(section) for section in source[kind]] for kind in ("terms", "privacy")}
    for (kind, index, field), value, kept in zip(slots, translated, kept_per_string):
        out[kind][index][field] = restore(value, kept)

    leftovers = [
        f"{kind}[{i}].{field}"
        for kind in ("terms", "privacy")
        for i, section in enumerate(out[kind])
        for field in ("title", "body")
        if BANNED.search(section[field])
    ]
    if leftovers:
        print(f"  {lang}: iOS wording survived in {leftovers}", file=sys.stderr)
        return None

    out_path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"  {lang}: wrote terms={len(out['terms'])} privacy={len(out['privacy'])}")
    return out_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lang", required=True)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    langs = NON_FR_LANGS if args.lang == "all" else [c.strip() for c in args.lang.split(",")]
    unknown = [c for c in langs if c not in NON_FR_LANGS]
    if unknown:
        raise SystemExit(f"unknown langs {unknown}")

    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    for lang in langs:
        if lang == "en":
            continue
        translate_lang(lang, source, args.force)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
