#!/usr/bin/env python3
"""Verify non-FR catalog quizzes keep FR structure (id, type, keys, answers)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FR = json.loads((ROOT / "content" / "locales" / "fr" / "quizzes_v2.json").read_text())
IOS = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
LANGS = [
    "en", "es", "de", "pt", "it", "tr", "pl", "ro", "nl",
    "el", "sv", "hu", "bg", "cs",
]

STRUCT = ("id", "type", "correctIndex", "correctValue", "sliderMin", "sliderMax", "tolerance")


def by_id(blocks) -> dict:
    if blocks and "courseId" in blocks[0]:
        return {b["courseId"]: b["quiz"] for b in blocks}
    return {c["id"]: c.get("quiz") or [] for c in blocks}


def main() -> int:
    fr = by_id(FR)
    errors = 0
    for lang in LANGS:
        cat = json.loads((IOS / f"courses.{lang}.json").read_text())
        v2 = json.loads((ROOT / "content" / "locales" / lang / "quizzes_v2.json").read_text())
        cat_q = by_id(cat)
        v2_q = by_id(v2)
        for cid, fr_quiz in fr.items():
            for source, label in ((cat_q, "catalog"), (v2_q, "v2")):
                got = source.get(cid)
                if got is None:
                    print(f"{lang} {label} missing {cid}")
                    errors += 1
                    continue
                if len(got) != len(fr_quiz):
                    print(f"{lang} {label} {cid}: {len(got)} questions, FR has {len(fr_quiz)}")
                    errors += 1
                    continue
                for a, b in zip(fr_quiz, got):
                    for key in STRUCT:
                        if a.get(key) != b.get(key):
                            print(f"{lang} {label} {a['id']}: {key} {b.get(key)!r} != FR {a.get(key)!r}")
                            errors += 1
                    for key in ("options", "items"):
                        if key in a:
                            if not isinstance(b.get(key), list) or len(b[key]) != len(a[key]):
                                print(f"{lang} {label} {a['id']}: {key} length mismatch")
                                errors += 1
                    if not b.get("question"):
                        print(f"{lang} {label} {a['id']}: empty question")
                        errors += 1
        # catalog vs v2 identity
        for cid, quiz in cat_q.items():
            if cid in v2_q and json.dumps(quiz, ensure_ascii=False) != json.dumps(v2_q[cid], ensure_ascii=False):
                print(f"{lang} catalog/v2 quiz mismatch on {cid}")
                errors += 1
    if errors:
        print(f"FAILED {errors} errors")
        return 1
    print("quiz structure OK vs FR + catalog/v2 sync")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
