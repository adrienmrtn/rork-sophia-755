#!/usr/bin/env python3
"""Builds src/screens/l10n/home.js: the `home` screen in the 23 languages other than French and
English (those two stay inline in src/screens/home.html).

    python3 appstore/screenshots/tools/l10n_home.py

Sources, per language:
  S  interface strings: the tables of ios/Sophia/Utilities/AppLocalizable.swift, then the
     per-area tables of Utilities/Localizable/*.swift, then English (the app's own fallback).
  C  content: the same two courses as the English page, from content/courses/<lang>/ (title and
     hero hook), the author's pedigree line from content/authors.json, the reading time computed
     as ReadingTime.minutes does (words / 180, between 2 and 20), the counters formatted as
     Int.compactCount does (decimal separator of the language's locale).
The author of the main card keeps the store convention of the English page: first names only and
an illustrated avatar from web/public/avatars/, never the photo or the full name.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "appstore/screenshots/src/screens/l10n/home.js"
SWIFT = ROOT / "ios/Sophia/Utilities/AppLocalizable.swift"
ADDITIONS = ROOT / "ios/Sophia/Utilities/Localizable"

# App language code -> name of its table in AppLocalizable.swift.
TABLES = {
    "ar": "arabic", "cs": "czech", "da": "danish", "de": "german", "el": "greek", "es": "spanish",
    "fi": "finnish", "he": "hebrew", "hr": "croatian", "hu": "hungarian", "it": "italian",
    "ja": "japanese", "nb": "norwegian", "nl": "dutch", "pl": "polish", "pt": "portuguese",
    "pt-PT": "portuguesePortugal", "ro": "romanian", "ru": "russian", "sk": "slovak",
    "sl": "slovenian", "sv": "swedish", "tr": "turkish",
}
# The keys of the English `S` object of home.html, in its order.
S_KEYS = [
    "tab.home", "tab.explore", "tab.duels", "tab.profile",
    "home.segment.forYou", "home.segment.following",
    "subject.histoire.short", "subject.art.short", "subject.sciences.short",
    "common.minutesShort",
]
# Same courses as the English page.
COURSE_1 = "course_269_pourquoi_personne_ne_sourit_sur_les"
COURSE_2 = "course_290_comment_les_etats_unis_ont_ils_gagne_la"
AUTHOR_1 = "guido-manuel-de-la-torre-olvera"
AUTHOR_1_SHOWN = "Guido Manuel"                       # first names only (store convention)
AVATAR_1 = "../../../../web/public/avatars/avatar_15.webp"  # illustrated avatar, not the photo
IMG = "../../../../ios/Sophia/CourseImages/"
DOT = {"art": "#d98cf2", "sciences": "#33d499", "histoire": "#f59e0a"}  # Subject.color
STREAK, READS, LIKES = 12, 2400, 187                  # user state and counters of the English page
# Decimal separator of Locale(identifier: AppLanguage.localeIdentifier), used by compactCount.
# ar_SA's default numbering system is Arabic-Indic, whose separator is U+066B, and compactCount
# pastes it between the Latin digits of String(format:): that is what the app shows.
DECIMAL_POINT = {"ja": ".", "he": ".", "ar": "\u066b"}  # every other language here: ","

# Corrections the sources cannot give, applied last: FIXES[lang]["S" | "C"][key] = value.
FIXES = {}


def unescape(s):
    s = re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda m: chr(int(m.group(1), 16)), s)
    return s.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")


STR = r'"((?:[^"\\]|\\.)*)"'


def main_tables():
    text = SWIFT.read_text(encoding="utf-8")
    starts = [(m.group(1), m.end()) for m in
              re.finditer(r"private static let (\w+): \[String: String\] = \[", text)]
    tables = {}
    for i, (name, start) in enumerate(starts):
        end = starts[i + 1][1] if i + 1 < len(starts) else len(text)
        tables[name] = {unescape(k): unescape(v) for k, v in
                        re.findall(r"^\s*" + STR + r":\s*" + STR + r",?\s*(?://.*)?$",
                                   text[start:end], re.M)}
    return tables


def addition_tables():
    out = {}
    for path in sorted(ADDITIONS.glob("Localizable+*.swift")):
        for line in path.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*" + STR + r":\s*\[(.*)\],?\s*$", line)
            if m:
                out.setdefault(unescape(m.group(1)), {
                    unescape(k): unescape(v)
                    for k, v in re.findall(STR + r":\s*" + STR, m.group(2))})
    return out


def ui_string(key, lang, tables, additions):
    """AppLocalizable.string(_:language:)."""
    if key in tables[TABLES[lang]]:
        return tables[TABLES[lang]][key]
    entry = additions.get(key)
    if entry:
        if lang in entry:
            return entry[lang]
        if "en" in entry:
            return entry["en"]
    if key in tables["english"]:
        print(f"  {lang}: {key} falls back to English", file=sys.stderr)
        return tables["english"][key]
    raise KeyError(key)


def minutes(course):
    """ReadingTime.minutes: words of the structured content / 180, rounded, within 2...20."""
    words = 0
    for section in course["sections"]:
        text = section.get("title", "")
        for b in section.get("blocks", []):
            kind = b.get("type")
            if kind in ("heading", "paragraph", "funFact", "takeaway", "quote"):
                text += " " + (b.get("text") or "")
            elif kind == "timeline":
                text += " " + " ".join(f"{e.get('date', '')} {e.get('title', '')} {e.get('detail') or ''}"
                                       for e in b.get("events", []))
            elif kind == "image":
                text += " " + (b.get("caption") or "")
        words += len(text.split())
    half_up = int(words / 180 + 0.5)                  # Double.rounded()
    return min(20, max(2, half_up))


def compact(n, lang):
    """Int.compactCount."""
    sep = DECIMAL_POINT.get(lang, ",")

    def one(value, suffix):
        if value >= 10:
            return f"{int(value)}\u00a0{suffix}"
        text = f"{value:.1f}".replace(".", sep)
        if text.endswith(sep + "0"):
            text = text[:-2]
        # The app writes a plain space; the page keeps the pair together as the English one does.
        return f"{text}\u00a0{suffix}"
    if n >= 1_000_000:
        return one(n / 1_000_000, "M")
    if n >= 1_000:
        return one(n / 1_000, "k")
    return str(n)


def course(lang, cid):
    path = ROOT / "content/courses" / lang / f"{cid}.json"
    if not path.exists():
        raise SystemExit(f"{lang}: {cid} is missing, pick another course by hand")
    return json.loads(path.read_text(encoding="utf-8"))


def plain(s):
    """String.withoutInlineMarkup: the card shows titles and hooks without [[ ]] and ** **."""
    return re.sub(r"\[\[(.*?)\]\]|\*\*(.*?)\*\*", lambda m: m.group(1) or m.group(2), s).strip()


def build():
    tables, additions = main_tables(), addition_tables()
    authors = {a["slug"]: a for a in
               json.loads((ROOT / "content/authors.json").read_text(encoding="utf-8"))["authors"]}
    author = authors[AUTHOR_1]
    out = {}
    for lang in TABLES:
        S = {k: ui_string(k, lang, tables, additions) for k in S_KEYS}
        c1, c2 = course(lang, COURSE_1), course(lang, COURSE_2)
        assert c1["author"] == AUTHOR_1, (lang, c1["author"])
        title = author["title"]
        if lang not in title:
            print(f"  {lang}: pedigree falls back", file=sys.stderr)
        C = {
            "streak": str(STREAK),
            "c1.cover": IMG + c1["hero"]["image"] + ".jpg",
            "c1.subject": S[f"subject.{c1['subject']}.short"],
            "c1.dot": DOT[c1["subject"]],
            "c1.title": plain(c1["title"]),
            "c1.hook": plain(c1["hero"]["hook"]),
            "c1.photo": AVATAR_1,
            "c1.author": AUTHOR_1_SHOWN,
            "c1.pedigree": title.get(lang) or title.get("en") or title["fr"],
            "c1.reads": compact(READS, lang),
            "c1.likes": compact(LIKES, lang),
            "c1.minutes": S["common.minutesShort"].replace("%d", str(minutes(c1))),
            "c2.cover": IMG + c2["hero"]["image"] + ".jpg",
            "c2.subject": S[f"subject.{c2['subject']}.short"],
            "c2.dot": DOT[c2["subject"]],
            "c2.title": plain(c2["title"]),
            "c2.hook": plain(c2["hero"]["hook"]),
        }
        for kind, obj in (("S", S), ("C", C)):
            for k, v in FIXES.get(lang, {}).get(kind, {}).items():
                assert k in obj, (lang, k)
                obj[k] = v
        for k in ("c1.cover", "c2.cover"):
            assert (OUT.parent.parent / C[k]).resolve().exists(), C[k]
        out[lang] = {"S": S, "C": C}
    return out


if __name__ == "__main__":
    data = build()
    body = json.dumps(data, ensure_ascii=False, indent=2)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "// Generated by appstore/screenshots/tools/l10n_home.py: do not edit by hand, fix the\n"
        "// script (its FIXES table) and rebuild. The `home` screen in the 23 languages other than\n"
        "// French and English; same keys as the English S and C objects of home.html.\n"
        f"window.L10N = {body};\n", encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}: {len(data)} languages")
