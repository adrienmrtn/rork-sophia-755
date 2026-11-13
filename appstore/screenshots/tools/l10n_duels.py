#!/usr/bin/env python3
"""Rebuilds appstore/screenshots/src/screens/l10n/duels.js (the 23 store languages of the
`duels` screen) from the app's own sources.

    python3 appstore/screenshots/tools/l10n_duels.py [--android-fallback]

S (interface strings), resolved as AppLocalizable.string does on iOS:
  1. the language's table in ios/Sophia/Utilities/AppLocalizable.swift,
  2. the key's entry in ios/Sophia/Utilities/Localizable/*.swift (that language, else "en"),
  3. the English table.
  With --android-fallback, a key that iOS only has in French and English (step 2 or 3 fell back
  to English) takes the project's own translation from
  android/app/src/main/assets/strings/<lang>.json instead, when there is one.
C (content): duel question dq_en_2_152 in content/duels/i18n/<lang>.json, plus the invented
  opponent handle (HANDLE, the same neutral Latin-letter handle in every language).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "appstore/screenshots/src/screens/l10n/duels.js"
IOS = ROOT / "ios/Sophia/Utilities"

LANGS = "ar cs da de el es fi he hr hu it ja nb nl pl pt pt-PT ro ru sk sl sv tr".split()
# Name of each language's table in AppLocalizable.swift (AppLocalizable.table(for:)).
TABLE = {
    "en": "english", "ar": "arabic", "cs": "czech", "da": "danish", "de": "german", "el": "greek",
    "es": "spanish", "fi": "finnish", "he": "hebrew", "hr": "croatian", "hu": "hungarian",
    "it": "italian", "ja": "japanese", "nb": "norwegian", "nl": "dutch", "pl": "polish",
    "pt": "portuguese", "pt-PT": "portuguesePortugal", "ro": "romanian", "ru": "russian",
    "sk": "slovak", "sl": "slovenian", "sv": "swedish", "tr": "turkish",
}
# Exactly the keys of the page's English S, in the page's order.
S_KEYS = [
    "duel.round.of", "duel.game.counter", "duel.you", "duel.round.short", "subject.art",
    "duel.game.correct", "duel.verdict.point", "duel.verdict.leading",
]
QUESTION = "dq_en_2_152"
HANDLE = "mila24"  # invented, neutral, Latin letters; not a handle of content/duels/bots.json

# Hand fixes the sources cannot give: { lang: { "S"|"C": { key: text } } }.
HAND = {}

PAIR = re.compile(r'"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"')


def unescape(s):
    s = re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda m: chr(int(m.group(1), 16)), s)
    return s.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")


def main_tables():
    """{ table name: { key: text } } for the big per-language dictionaries."""
    src = (IOS / "AppLocalizable.swift").read_text(encoding="utf-8")
    heads = list(re.finditer(r"private static let (\w+): \[String: String\] = \[", src))
    tables = {}
    for i, h in enumerate(heads):
        body = src[h.end(): heads[i + 1].start() if i + 1 < len(heads) else len(src)]
        wanted = {}
        for k, v in PAIR.findall(body):
            if k in S_KEYS and k not in wanted:
                wanted[k] = unescape(v)
        tables[h.group(1)] = wanted
    return tables


def additions():
    """{ key: { lang: text } } from the per-area tables (first table that has the key wins)."""
    found = {}
    for path in sorted((IOS / "Localizable").glob("Localizable+*.swift")):
        src = path.read_text(encoding="utf-8")
        for key in S_KEYS:
            if key in found:
                continue
            m = re.search(r'"%s"\s*:\s*\[(.*?)\n\s*\]' % re.escape(key), src, re.S)
            if m:
                found[key] = {k: unescape(v) for k, v in PAIR.findall(m.group(1))}
    return found


def main():
    android = "--android-fallback" in sys.argv
    tables, extra = main_tables(), additions()
    bots = json.loads((ROOT / "content/duels/bots.json").read_text(encoding="utf-8"))
    assert HANDLE not in json.dumps(bots), "HANDLE collides with a bot handle"
    out, notes = {}, []
    for lang in LANGS:
        own, s = tables[TABLE[lang]], {}
        droid = {}
        if android:
            p = ROOT / "android/app/src/main/assets/strings" / (lang + ".json")
            droid = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
        for key in S_KEYS:
            if key in own:
                s[key] = own[key]
            elif lang in extra.get(key, {}):
                s[key] = extra[key][lang]
            elif key in droid:
                s[key] = droid[key]
                notes.append("%s: %s from the Android table" % (lang, key))
            elif "en" in extra.get(key, {}):
                s[key] = extra[key]["en"]
                notes.append("%s: %s falls back to English" % (lang, key))
            else:
                s[key] = tables["english"][key]
                notes.append("%s: %s falls back to English" % (lang, key))
        item = json.loads((ROOT / "content/duels/i18n" / (lang + ".json")).read_text(encoding="utf-8"))["items"][QUESTION]
        assert len(item["o"]) == 4, lang
        c = {"opponent": HANDLE, "opponentAt": "@" + HANDLE, "question": item["q"]}
        for i, o in enumerate(item["o"]):
            c["o%d" % i] = o
        s.update(HAND.get(lang, {}).get("S", {}))
        c.update(HAND.get(lang, {}).get("C", {}))
        out[lang] = {"S": s, "C": c}
    head = (
        "// Generated by appstore/screenshots/tools/l10n_duels.py%s: do not edit by hand.\n"
        "// S: iOS localisation tables (AppLocalizable.swift, Localizable/*.swift, English fallback as the app does).\n"
        "// C: duel question %s from content/duels/i18n/<lang>.json, invented opponent handle.\n"
        % (" --android-fallback" if android else "", QUESTION)
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(head + "window.L10N = " + json.dumps(out, ensure_ascii=False, indent=2) + ";\n", encoding="utf-8")
    print("wrote %s (%d languages)" % (OUT.relative_to(ROOT), len(out)))
    for n in notes:
        print("  " + n)


if __name__ == "__main__":
    main()
