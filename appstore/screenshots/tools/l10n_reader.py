#!/usr/bin/env python3
"""Rebuilds appstore/screenshots/src/screens/l10n/reader.js (the `reader` screen in the 23
languages other than French and English, which stay inline in reader.html).

    python3 appstore/screenshots/tools/l10n_reader.py

Sources, per language:
  S  ios/Sophia/Utilities/AppLocalizable.swift, the language's table (English when a key is
     missing, as AppLocalizable.string does).
  C  content/courses/<lang>/course_269_pourquoi_personne_ne_sourit_sur_les.json, section 4 of 5,
     the same passage as the English page (paragraph, image, paragraph); the image credit is
     content/image_credits.json formatted like ImageCredit.formatted (not localised in the app).
What the script cannot know is in HAND below.
"""
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "appstore/screenshots/src/screens/l10n/reader.js"
SWIFT = ROOT / "ios/Sophia/Utilities/AppLocalizable.swift"
COURSE = "course_269_pourquoi_personne_ne_sourit_sur_les"
SECTION = 3        # index of the section shown (4th of 5)
REVEALED = 4       # steps revealed in that section: title, paragraph, image, paragraph

LANGS = "ar cs da de el es fi he hr hu it ja nb nl pl pt pt-PT ro ru sk sl sv tr".split()
# AppLanguage raw value -> name of its table in AppLocalizable.swift
TABLES = {
    "en": "english", "ar": "arabic", "cs": "czech", "da": "danish", "de": "german", "el": "greek",
    "es": "spanish", "fi": "finnish", "he": "hebrew", "hr": "croatian", "hu": "hungarian",
    "it": "italian", "ja": "japanese", "nb": "norwegian", "nl": "dutch", "pl": "polish",
    "pt": "portuguese", "pt-PT": "portuguesePortugal", "ro": "romanian", "ru": "russian",
    "sk": "slovak", "sl": "slovenian", "sv": "swedish", "tr": "turkish",
}
S_KEYS = ["common.continue"]

# ---- Fixed by hand ----------------------------------------------------------------------------
# scrollY / scrollYPad: scroll offset of the thread on the phone / the iPad, tuned on the renders
# so that neither the header nor the bottom bar cuts through a line of text (0 when all fits).
SCROLL = {
    # lang: (phone, iPad)
    "cs": (10, 0), "da": (20, 0), "de": (13, 20), "el": (10, 0), "es": (20, 0), "fi": (10, 0),
    "hr": (20, 0), "hu": (10, 0), "it": (10, 0), "ja": (20, 20), "nb": (10, 0), "nl": (13, 20),
    "pl": (10, 0), "pt": (20, 0), "pt-PT": (13, 0), "ro": (10, 0), "ru": (13, 0), "sk": (10, 0),
    "sl": (10, 0), "sv": (20, 0), "tr": (13, 0),
}
HAND = {
    # The Greek caption carries Markdown italics (*Μάλε Μπάμπε*) that the app's caption view
    # (a plain Text) does not interpret: the asterisks are dropped here rather than shown.
    "el": {"caption": lambda s: s.replace("*", "")},
}
# -----------------------------------------------------------------------------------------------


def swift_table(src: str, name: str) -> dict:
    start = src.index(f"private static let {name}: [String: String] = [")
    end = src.index("\n    ]", start)
    out = {}
    for m in re.finditer(r'^\s*"((?:[^"\\]|\\.)+)":\s*"((?:[^"\\]|\\.)*)",?\s*$', src[start:end], re.M):
        out[m.group(1)] = json.loads('"' + re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda u: chr(int(u.group(1), 16)), m.group(2)) + '"')
    return out


def rich(text: str) -> str:
    """Course markup as BlockContentView renders it: **bold**, *italic*, [[glossary term]]."""
    t = html.escape(text, quote=False)
    t = re.sub(r"\[\[\s*(.+?)\s*\]\]", r'<span class="term">\1</span>', t)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"\*(.+?)\*", r"<i>\1</i>", t)
    return t


def credit(slug: str) -> str:
    c = json.loads((ROOT / "content/image_credits.json").read_text(encoding="utf-8"))[slug]
    parts = []
    if c["title"]:
        parts.append(c["title"])
    if c["author"]:
        parts.append("— " + c["author"])
    base = " ".join(parts)
    if c["license"]:
        base += f" ({c['license']})" if base else c["license"]
    return base


def main():
    src = SWIFT.read_text(encoding="utf-8")
    english = swift_table(src, "english")
    data = {}
    for lang in LANGS:
        table = swift_table(src, TABLES[lang])
        S = {}
        for k in S_KEYS:
            if k not in table:
                print(f"{lang}: {k} missing, English fallback")
            S[k] = table.get(k, english[k])

        course = json.loads((ROOT / f"content/courses/{lang}/{COURSE}.json").read_text(encoding="utf-8"))
        sections = course["sections"]
        blocks = sections[SECTION]["blocks"]
        p1, img, p2 = blocks[0], blocks[1], blocks[2]
        assert (p1["type"], img["type"], p2["type"]) == ("paragraph", "image", "paragraph"), lang
        steps = 1 + len(blocks)
        phone, pad = SCROLL.get(lang, (0, 0))
        C = {
            "counter": f"{SECTION + 1} / {len(sections)}",
            "segments": [1 if i < SECTION else (round(REVEALED / steps, 4) if i == SECTION else 0)
                         for i in range(len(sections))],
            "image": img["asset"],
            "ratio": img["ratio"].replace(":", " / "),
            "scrollYPad": pad,
            "scrollY": phone,
            "sectionTitle": html.escape(sections[SECTION]["title"], quote=False),
            "p1": rich(p1["text"]),
            "caption": html.escape(img.get("caption") or "", quote=False),
            "credit": html.escape(img.get("credit") or credit(img["asset"]), quote=False),
            "p2": rich(p2["text"]),
        }
        for key, fix in HAND.get(lang, {}).items():
            C[key] = fix(C[key])
        data[lang] = {"S": S, "C": C}

    body = json.dumps(data, ensure_ascii=False, indent=2)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "// Generated by appstore/screenshots/tools/l10n_reader.py: do not edit, rebuild.\n"
        "// The `reader` screen in the 23 languages other than French and English.\n"
        f"window.L10N = {body};\n",
        encoding="utf-8",
    )
    print(f"wrote {OUT.relative_to(ROOT)} ({len(data)} languages)")


if __name__ == "__main__":
    main()
