#!/usr/bin/env python3
"""Build the narration text ElevenLabs reads, one file per course.

    python3 scripts/tts/build_tts.py --lang fr --out ~/Desktop/tts_fr
    python3 scripts/tts/build_tts.py --lang de --out ~/Desktop/tts_de

Writes next to the per-course files:
  chapitres/            one file per chapter, for mixing a jingle between them
  manifest.csv          what each course file holds
  transformations.csv   every rule that fired, so a bad reading is traceable
  problemes.csv         anything left that a voice would read aloud by mistake
"""

from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import lang_de  # noqa: E402
import lang_en  # noqa: E402
import lang_es  # noqa: E402
import lang_fr  # noqa: E402
import lang_tr  # noqa: E402
import tts_common  # noqa: E402

LANGS = {'fr': lang_fr, 'en': lang_en, 'es': lang_es, 'tr': lang_tr, 'de': lang_de}
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', choices=sorted(LANGS), required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--root', default=ROOT)
    args = ap.parse_args()

    lang = LANGS[args.lang]
    summary = tts_common.build(lang, args.root, os.path.expanduser(args.out))

    hours = summary['characters'] / 13.5 / 3600
    print(f"{args.lang}: {summary['courses']} cours, {summary['chapters']} chapitres, "
          f"{summary['characters']:,} caractères (~{hours:.1f} h)")
    print(f"{summary['transformations']:,} transformations")

    problems = summary['problems']
    if problems:
        print(f"\n{len(problems)} problème(s) résiduel(s) — voir problemes.csv :")
        seen = {}
        for cid, kind, what in problems:
            seen.setdefault((kind, what), []).append(cid)
        for (kind, what), courses in sorted(seen.items(), key=lambda x: -len(x[1]))[:25]:
            print(f"   [{kind}] {what!r} × {len(courses)}  ({courses[0]})")
        return 1
    print('aucun résidu : ni chiffre, ni balisage, ni symbole')
    return 0


if __name__ == '__main__':
    sys.exit(main())
