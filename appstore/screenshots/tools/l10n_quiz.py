#!/usr/bin/env python3
"""Rebuild src/screens/l10n/quiz.js (the 23 store languages of the `quiz` screen).

    python3 appstore/screenshots/tools/l10n_quiz.py

S (interface strings) comes from the app's tables, looked up as AppLocalizable.string does:
the language's table in AppLocalizable.swift, then Utilities/Localizable/*.swift (language,
then "en"), then the English table. C (content) is question 3 of the Cubism course in
content/locales/<lang>/quizzes_v2.json, options in the order the page shows them.
The keys are read from the English S and C of src/screens/quiz.html.
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHOTS = HERE.parent
ROOT = SHOTS.parent.parent
PAGE = SHOTS / "src/screens/quiz.html"
OUT = SHOTS / "src/screens/l10n/quiz.js"
UTIL = ROOT / "ios/Sophia/Utilities"

LANGS = "ar cs da de el es fi he hr hu it ja nb nl pl pt pt-PT ro ru sk sl sv tr".split()
# App language code -> name of its table in AppLocalizable.swift.
TABLE = {
    "en": "english", "ar": "arabic", "cs": "czech", "da": "danish", "de": "german", "el": "greek",
    "es": "spanish", "fi": "finnish", "he": "hebrew", "hr": "croatian", "hu": "hungarian",
    "it": "italian", "ja": "japanese", "nb": "norwegian", "nl": "dutch", "pl": "polish",
    "pt": "portuguese", "pt-PT": "portuguesePortugal", "ro": "romanian", "ru": "russian",
    "sk": "slovak", "sl": "slovenian", "sv": "swedish", "tr": "turkish",
}
COURSE = "course_126_le_cubisme_picasso_et_braque"
QUESTION = COURSE + "_q3"
# Page slot -> index in the source `options` (the app shuffles; the page shows the right
# answer second, as the French and English pages do).
OPTION_ORDER = {"option1": 1, "option2": 0, "option3": 3, "option4": 2}

STR = r'"((?:[^"\\]|\\.)*)"'


def unescape(s):
    s = re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda m: chr(int(m.group(1), 16)), s)
    return s.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")


def main_tables():
    """{table name: {key: text}} from AppLocalizable.swift."""
    tables, cur = {}, None
    for line in (UTIL / "AppLocalizable.swift").read_text(encoding="utf-8").splitlines():
        m = re.match(r"\s*private static let (\w+): \[String: String\] = \[", line)
        if m:
            cur = tables.setdefault(m.group(1), {})
            continue
        if cur is not None:
            if re.match(r"\s*\]\s*$", line):
                cur = None
                continue
            m = re.match(r"\s*" + STR + r":\s*" + STR + r",?\s*(//.*)?$", line)
            if m:
                cur[unescape(m.group(1))] = unescape(m.group(2))
    return tables


def additions():
    """{key: {lang: text}} from Utilities/Localizable/*.swift."""
    out, key = {}, None
    for f in sorted((UTIL / "Localizable").glob("*.swift")):
        for line in f.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*" + STR + r":\s*\[\s*$", line)
            if m:
                key = unescape(m.group(1))
                out.setdefault(key, {})
                continue
            if key is not None:
                if re.match(r"\s*\],?\s*$", line):
                    key = None
                    continue
                m = re.match(r"\s*" + STR + r":\s*" + STR + r",?\s*(//.*)?$", line)
                if m:
                    out[key][unescape(m.group(1))] = unescape(m.group(2))
    return out


def page_keys(name):
    """Keys of the English block of `const <name>` in the page."""
    src = PAGE.read_text(encoding="utf-8")
    block = src[src.index("const %s = {" % name):]
    block = block[block.index("en: {"):]
    block = block[:block.index("}")]
    return re.findall(r'^\s*(?:"([^"]+)"|(\w+)):', block, re.M)


def typo(text):
    """Hand fixes the sources cannot know, same as the French and English pages:
    a typewriter apostrophe inside a word becomes a curly one."""
    return re.sub(r"(?<=\w)'(?=\w)", "\u2019", text)


def build():
    tables, extra = main_tables(), additions()
    s_keys = [a or b for a, b in page_keys("S")][1:]   # [0] is the `en` label itself
    c_keys = [a or b for a, b in page_keys("C")][1:]
    notes, data = [], {}

    def ui(key, lang):
        table = tables[TABLE[lang]]
        if key in table:
            return table[key]
        if key in extra:
            if lang in extra[key]:
                return extra[key][lang]
            if "en" in extra[key]:
                notes.append("%s: %s falls back to English (as the app does)" % (lang, key))
                return extra[key]["en"]
        if key in tables["english"]:
            notes.append("%s: %s falls back to English (as the app does)" % (lang, key))
            return tables["english"][key]
        raise KeyError(key)

    for lang in LANGS:
        quizzes = json.loads((ROOT / "content/locales" / lang / "quizzes_v2.json").read_text(encoding="utf-8"))
        course = next(c for c in quizzes if c["courseId"] == COURSE)
        q = next(x for x in course["quiz"] if x["id"] == QUESTION)
        assert q["correctIndex"] == 0 and len(q["options"]) == 4 and len(course["quiz"]) == 9, lang
        C = {}
        for k in c_keys:
            if k in OPTION_ORDER:
                C[k] = typo(q["options"][OPTION_ORDER[k]])
            else:
                C[k] = typo(q[k])
        # By hand: the Spanish source has a stray full stop after one painting title.
        if lang == "es":
            C["option4"] = C["option4"].rstrip(".")
        data[lang] = {"S": {k: ui(k, lang) for k in s_keys}, "C": C}

    body = json.dumps(data, ensure_ascii=False, indent=2)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "// Generated by appstore/screenshots/tools/l10n_quiz.py: do not edit, rebuild.\n"
        "// S: the app's localisation tables. C: question 3 of %s\n"
        "// (content/locales/<lang>/quizzes_v2.json).\n"
        "window.L10N = %s;\n" % (COURSE, body), encoding="utf-8")
    for n in notes:
        print(n, file=sys.stderr)
    print("wrote %s (%d languages)" % (OUT.relative_to(ROOT), len(data)))


if __name__ == "__main__":
    build()
