#!/usr/bin/env python3
"""Builds src/screens/l10n/blocker.js (the 23 store languages of the `blocker` screen).

    python3 appstore/screenshots/tools/l10n_blocker.py

S: the app's localisation tables, resolved as AppLocalizable.string does (language table of
   AppLocalizable.swift, then Utilities/Localizable/*.swift by language code, then English).
C: the same three courses from content/courses/<lang>/, their author names from
   content/authors.json, the reading time as ReadingTime.minutes computes it (words / 180,
   2 to 20) and common.minutesShort; the friend's XP grouped as NumberFormatter does for the
   app's locale of that language (AppLanguage.foundationLocale, Latin digits).
"""
import glob
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "appstore/screenshots/src/screens/l10n/blocker.js")
LANGS = "ar cs da de el es fi he hr hu it ja nb nl pl pt pt-PT ro ru sk sl sv tr".split()

# AppLocalizable.swift table name per app language code (AppLocalizable.table(for:)).
TABLES = {
    "fr": "french", "en": "english", "es": "spanish", "de": "german", "pt": "portuguese",
    "pt-PT": "portuguesePortugal", "it": "italian", "tr": "turkish", "pl": "polish",
    "ro": "romanian", "nl": "dutch", "el": "greek", "sv": "swedish", "hu": "hungarian",
    "cs": "czech", "da": "danish", "nb": "norwegian", "ru": "russian", "hr": "croatian",
    "sl": "slovenian", "sk": "slovak", "ar": "arabic", "he": "hebrew", "fi": "finnish",
    "ja": "japanese",
}

# Keys of the page's English S, in the page's order.
S_KEYS = [
    "antiScroll.title", "antiScroll.cta", "friends.add.title", "profile.qr.mine",
    "profile.qr.scan", "profile.badges", "badges.seeAll", "badge.name.streak_7",
    "badge.name.courses_10", "badge.name.quiz_10", "profile.list.toRead", "profile.list.read",
    "profile.list.liked", "library.seeMore", "profile.page.antiScroll",
    "tab.home", "tab.explore", "tab.duels", "tab.profile",
]

COURSES = [  # (C key prefix, course id)
    ("course", "course_149_la_joconde"),
    ("course2", "course_303_pourquoi_certains_detestent_ils_la"),
    ("course3", "course_241_pourquoi_voulait_on_demolir_la_tour_eiffel"),
]

# 1240 as NumberFormatter(.decimal) writes it in each language's locale (CLDR grouping and
# minimum grouping digits; taken from ICU: `new Intl.NumberFormat(locale).format(1240)`).
NBSP, NNBSP = "\u00a0", "\u202f"
XP_1240 = {
    "ar": "1,240", "cs": "1" + NBSP + "240", "da": "1.240", "de": "1.240", "el": "1.240",
    "es": "1240", "fi": "1" + NBSP + "240", "he": "1,240", "hr": "1.240", "hu": "1240",
    "it": "1240", "ja": "1,240", "nb": "1" + NBSP + "240", "nl": "1.240", "pl": "1240",
    "pt": "1.240", "pt-PT": "1240", "ro": "1.240", "ru": "1" + NBSP + "240",
    "sk": "1" + NBSP + "240", "sl": "1240", "sv": "1" + NBSP + "240", "tr": "1.240",
}

STR = r'"((?:[^"\\]|\\.)*)"'


def unescape(s):
    s = re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda m: chr(int(m.group(1), 16)), s)
    return s.replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")


def load_tables():
    src = open(os.path.join(ROOT, "ios/Sophia/Utilities/AppLocalizable.swift"), encoding="utf-8").read()
    marks = [(m.start(), m.group(1)) for m in re.finditer(r"private static let (\w+): \[String: String\] = \[", src)]
    by_name = {}
    for i, (pos, name) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(src)
        by_name[name] = {unescape(k): unescape(v) for k, v in re.findall(r"^\s*" + STR + r":\s*" + STR + r",?\s*$", src[pos:end], re.M)}
    return {code: by_name[name] for code, name in TABLES.items()}


def load_additions():
    out = {}
    for path in sorted(glob.glob(os.path.join(ROOT, "ios/Sophia/Utilities/Localizable/*.swift"))):
        src = open(path, encoding="utf-8").read()
        for m in re.finditer(r"^\s*" + STR + r":\s*\[\s*\n(.*?)^\s*\],?\s*$", src, re.M | re.S):
            out[unescape(m.group(1))] = {unescape(k): unescape(v) for k, v in re.findall(r"^\s*" + STR + r":\s*" + STR + r",?\s*$", m.group(2), re.M)}
    return out


TABLE = load_tables()
ADD = load_additions()
FALLBACKS = []  # (lang, what) reported at the end


def string(key, lang):
    """AppLocalizable.string(_:language:)."""
    if key in TABLE[lang]:
        return TABLE[lang][key]
    entry = ADD.get(key)
    if entry:
        if lang in entry:
            return entry[lang]
        if "en" in entry:
            FALLBACKS.append((lang, key + " -> en"))
            return entry["en"]
    if key in TABLE["en"]:
        FALLBACKS.append((lang, key + " -> en"))
        return TABLE["en"][key]
    raise KeyError(key)


def word_count(section):
    """ReadingTime.wordCount(of:)."""
    text = section.get("title", "")
    for b in section.get("blocks", []):
        t = b.get("type")
        if t in ("heading", "paragraph", "funFact", "takeaway", "quote"):
            text += " " + b.get("text", "")
        elif t == "timeline":
            text += " " + " ".join("%s %s %s" % (e.get("date", ""), e.get("title", ""), e.get("detail") or "") for e in b.get("events", []))
        elif t == "image":
            text += " " + (b.get("caption") or "")
    return len(text.split())


def swift_round(x):  # .rounded(): to nearest, ties away from zero
    return int(x + 0.5)


def course(lang, cid):
    path = os.path.join(ROOT, "content/courses", lang, cid + ".json")
    if not os.path.exists(path):
        FALLBACKS.append((lang, cid + " missing -> en"))
        path = os.path.join(ROOT, "content/courses/en", cid + ".json")
    d = json.load(open(path, encoding="utf-8"))
    words = sum(word_count(s) for s in d["sections"])
    minutes = min(20, max(2, swift_round(words / 180)))
    return d["title"], d["author"], minutes


AUTHORS = {a["slug"]: a["name"] for a in json.load(open(os.path.join(ROOT, "content/authors.json"), encoding="utf-8"))["authors"]}


def html(s):
    return s.replace("&", "&amp;").replace("<", "&lt;")


def build(lang):
    S = {k: html(string(k, lang)) for k in S_KEYS}
    C = {
        "friendRank": "4",
        "friendHandle": "@theo.lambert",
        "friendXp": XP_1240[lang] + " XP",
        "countToRead": "5",
        "countRead": "23",
        "countLiked": "9",
    }
    for prefix, cid in COURSES:
        title, author, minutes = course(lang, cid)
        C[prefix + "Title"] = html(title)
        C[prefix + "Meta"] = html("%s · %s" % (AUTHORS[author], string("common.minutesShort", lang) % minutes))
    return {"S": S, "C": C}


def main():
    # Self-check against the page's inline English.
    assert string("antiScroll.cta", "en") == "Turn on anti-scroll"
    assert [course("en", c)[2] for _, c in COURSES] == [5, 3, 4], [course("en", c)[2] for _, c in COURSES]
    data = {lang: build(lang) for lang in LANGS}
    body = json.dumps(data, ensure_ascii=False, indent=2)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("// Generated by appstore/screenshots/tools/l10n_blocker.py. Do not edit by hand:\n"
                "// fix the generator and rebuild.\n"
                "window.L10N = " + body + ";\n")
    print("wrote", OUT)
    for lang, what in FALLBACKS:
        print("fallback:", lang, what)


if __name__ == "__main__":
    main()
