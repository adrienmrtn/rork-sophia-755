#!/usr/bin/env python3
"""Mechanical, French-guarded corrections of machine-translation artefacts, in every language and every copy.

Only patterns whose fix does not depend on reading the sentence are handled here:

* ``annee``   — "En 1857," rendered with a place preposition and no word for "year"
                (ru "В 1857" → "В 1857 году", cs "V 1857" → "V roce 1857", sk → "V roku",
                sl "V 1857" → "Leta 1857", hr/sr "U 1857" → "Godine 1857.", bg "През 1857" →
                "През 1857 г.", fi "1857:ssä" / "Julkaisussa 1857" → "Vuonna 1857",
                et "Filmis 1984" / "624-s" → "Aastal 1984" / "aastal 624", da/nb "på 1893" → "i 1893").
                Applied only to a year the French text of the same segment introduces with
                "En" or "Vers": "Dans *1984*" (the novel) is left alone.
* ``siecle``  — centuries written the way the language does not (bg "20. век" → "XX век",
                ru "20 века" → "XX века"), and the century shifted by one (fi "700-luvulla"
                for "VIIe siècle" → "600-luvulla", da/nb "700-tallet", sv "700-talet").
                Russian and the shifted forms are guarded by the French century.
* ``pourcent``— Turkish puts the percent sign first: "25%" → "%25".
* ``ponctuation`` — what ``check_course_translation.py`` forbids and the guides spell out:
                Greek titles in French guillemets « » → „ ” (TRANSLATION_GUIDE_EL), and an en
                dash standing for the French " : " of a title → ": ". Course content only, not UI.

Every change is applied to every copy of the string (see ``i18n_copies``).

Usage:
    python scripts/fix_mechanical_i18n.py --dry-run            # counts and samples, writes nothing
    python scripts/fix_mechanical_i18n.py --lang ru --dry-run -v
    python scripts/fix_mechanical_i18n.py --plan plan.json     # write the old → new list
    python scripts/fix_mechanical_i18n.py                      # apply everywhere
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from course_translation_io import segments
from i18n_copies import ROOT, apply_mapping
from i18n_languages import NON_FR_LANGS, SWIFT_CASE_BY_CODE

FR_COURSES = ROOT / "content" / "courses" / "fr"
IOS_LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
FR_CATALOG = ROOT / "android" / "app" / "src" / "main" / "assets" / "locales"
QUIZZES = ROOT / "content" / "locales"

ROMAN = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV",
         "XVI", "XVII", "XVIII", "XIX", "XX", "XXI"]
ROMAN_VALUE = {r: i for i, r in enumerate(ROMAN) if r}

#: A number followed by one of these is a quantity ("En 100 jours", "En 123 pages"), not a year.
UNITS = (r"jours?|pages?|ans|années|heures?|minutes?|secondes?|mois|semaines?|siècles?|km|kilomètres?|mètres?|m|kg|"
         r"tonnes?|millions?|milliards?|personnes?|morts?|hommes?|soldats?|habitants?|victimes?|exemplaires?|"
         r"copies|euros?|dollars?|francs?|livres?|%|°|fois|ouvriers|navires|bateaux|kilos?|litres?")
FR_YEAR_RE = re.compile(r"(?:^|[\s(«\"“'’])(En|en|Vers|vers|En l'an|en l'an)\s+\**\s*(\d{3,4})\b\**(?!\s*(?:" + UNITS + r")\b)")
FR_CENTURY_RE = re.compile(r"\b([IVX]{1,5})\s*(?:e|ᵉ|ème|er)\s+(?:siècle|s\.)")
FR_ANY_ROMAN_RE = re.compile(r"\b([IVX]{1,5})\s*(?:e|ᵉ|ème|er)\b")


def fr_years(fr: str | None) -> tuple[set[str], set[str]]:
    """Years the French introduces with "En" (in) and with "Vers" (around)."""
    en, vers = set(), set()
    for word, year in FR_YEAR_RE.findall(fr or ""):
        (vers if word.lower() == "vers" else en).add(year)
    return en, vers


def fr_centuries(fr: str | None) -> set[int]:
    return {ROMAN_VALUE[r] for r in FR_CENTURY_RE.findall(fr or "") if r in ROMAN_VALUE}


def _cap(word: str, like: str) -> str:
    return word[:1].upper() + word[1:] if like[:1].isupper() else word


def _sentence_start(text: str, pos: int) -> bool:
    before = text[:pos].rstrip(" *")
    return not before or before[-1] in ".!?:\n«\"“"


def _hr_sr_year(m: re.Match[str], lang: str) -> str:
    """Croatian and Serbian: "U 1857, …" → "Godine 1857., …" (hr) / "Godine 1857." or "1857. godine, …" (sr).

    The ordinal dot never absorbs a comma (Hrvatski pravopis); only a full stop
    after the year serves as both. Serbian keeps the natural mid-sentence order
    "<year>. godine" and drops the comma only after a sentence-opening date.
    The ordinal dot goes after the bold markers: "**1857**." (a dot inside the
    bold span reads as a sentence break to the course validator).
    """
    b1, year, b2, comma = m.group(2), m.group(3), m.group(4), m.group(5) or ""
    nxt = m.string[m.end():m.end() + 1]
    start = _sentence_start(m.string, m.start())
    y = f"{b1}{year}{b2}"
    if nxt == "." and not comma:
        return f"{_cap('godine', m.group(1))} {y}"
    if nxt and nxt in ":;!?)" and not comma:
        return f"{y}. godine"
    if lang == "hr":
        return f"{_cap('godine', m.group(1))} {y}.{',' if comma else ''}"
    if start:
        return f"Godine {y}."
    return f"{y}. godine{',' if comma else ''}"


Y = r"(?<!\*)(\*{0,2})({year})(\*{0,2})(?!\*)"
NOT_AFTER = r"(?!\d|\s*[-–]\s*\d)"


def year_rules(lang: str):
    """[(kind, pattern template, replacement function)] ; kind = 'en' or 'vers'."""
    rules = []
    if lang == "ru":
        rules.append(("en", r"(?<![\w-])([Вв])\s+" + Y + NOT_AFTER + r"(?!\s*(?:год|г\.|-))",
                      lambda m: f"{m.group(1)} {m.group(2)}{m.group(3)}{m.group(4)} году"))
        rules.append(("vers", r"(?<![\w-])([Оо]коло|[Пп]римерно)\s+" + Y + NOT_AFTER + r"(?!\s*(?:год|г\.|-))",
                      lambda m: f"{m.group(1)} {m.group(2)}{m.group(3)}{m.group(4)} года"))
    elif lang in ("cs", "sk"):
        word = "roce" if lang == "cs" else "roku"
        rules.append(("en", r"(?<![\w-])([Vv])\s+" + Y + NOT_AFTER + r"(?!\.\s*(?:let|rok|stol)|\s+a\s+\**\d)",
                      lambda m, w=word: f"{m.group(1)} {w} {m.group(2)}{m.group(3)}{m.group(4)}"))
        rules.append(("vers", r"(?<![\w-])([Kk]olem|[Oo]kolo)\s+" + Y + NOT_AFTER,
                      lambda m: f"{m.group(1)} roku {m.group(2)}{m.group(3)}{m.group(4)}"))
    elif lang == "sl":
        rules.append(("en", r"(?<![\w-])([Vv]|[Pp]ri|[Oo]b)\s+" + Y + NOT_AFTER + r"(?!-?ih\b|\.\s*let|\s+in\s+\**\d)",
                      lambda m: f"{_cap('leta', m.group(1))} {m.group(2)}{m.group(3)}{m.group(4)}"))
        rules.append(("vers", r"(?<![\w-])([Oo]koli|[Oo]krog)\s+" + Y + NOT_AFTER,
                      lambda m: f"{m.group(1)} leta {m.group(2)}{m.group(3)}{m.group(4)}"))
    elif lang in ("hr", "sr"):
        rules.append(("en", r"(?<![\w-])([Uu])\s+" + Y + r"(?!\d|\s*[-–]\s*\d|\.?\s*godin|\s+i\s+\**\d)(\s*,)?",
                      lambda m, lang=lang: _hr_sr_year(m, lang)))
        rules.append(("vers", r"(?<![\w-])([Oo]ko)\s+" + Y + r"(?![.\d]|\s*[-–]\s*\d)",
                      lambda m: f"{m.group(1)} {m.group(2)}{m.group(3)}{m.group(4)}. godine"))
    elif lang == "bg":
        # "г." ending a sentence keeps a single full stop.
        def bg_g(m):
            return " г" if m.string[m.end():m.end() + 1] == "." else " г."
        rules.append(("en", r"(?<![\w-])([Пп]рез|[Вв]ъв|[Вв])\s+" + Y + NOT_AFTER + r"(?!\s*г\b|\s+и\s+\**\d)",
                      lambda m: f"{_cap('през', m.group(1))} {m.group(2)}{m.group(3)}{m.group(4)}{bg_g(m)}"))
        rules.append(("vers", r"(?<![\w-])([Оо]коло)\s+" + Y + NOT_AFTER + r"(?!\s*г\b)",
                      lambda m: f"{m.group(1)} {m.group(2)}{m.group(3)}{m.group(4)}{bg_g(m)}"))
    elif lang == "fi":
        rules.append(("en", r"(?<![\w-])(Julkaisussa|Asiassa|Alueella|Mallissa|Teoksessa|Kirjassa|Elokuvassa|Kaupungissa|"
                            r"Tapauksessa|Numerossa|Sarjassa|Paikassa|paikassa|julkaisussa|asiassa|alueella|mallissa|teoksessa|kirjassa|"
                            r"elokuvassa|kaupungissa|tapauksessa|numerossa|sarjassa)\s+" + Y + NOT_AFTER,
                      lambda m: f"{_cap('vuonna', m.group(1))} {m.group(2)}{m.group(3)}{m.group(4)}"))
        rules.append(("en", r"(?<![\w-])" + Y + r":(?:ssa|ssä)\b",
                      "FI_SUFFIX"))
    elif lang == "et":
        rules.append(("en", r"(?<![\w-])(Linnas|Filmis|Raamatus|Mängus|Väljaandes|Kohtuasjas|Ajakirjas|Saates|Numbris|Asjas|"
                            r"linnas|filmis|raamatus|mängus|väljaandes|kohtuasjas|ajakirjas|saates|numbris|asjas)\s+" + Y + NOT_AFTER,
                      lambda m: f"{_cap('aastal', m.group(1))} {m.group(2)}{m.group(3)}{m.group(4)}"))
        rules.append(("en", r"(?<![\w-])" + Y + r"-s\b", "ET_SUFFIX"))
    elif lang in ("da", "nb"):
        rules.append(("en", r"(?<![\w-])([Pp]å)\s+" + Y + r"(?!\d|\s*[-–]\s*\d|-?tal|'?erne)",
                      lambda m: f"{_cap('i', m.group(1))} {m.group(2)}{m.group(3)}{m.group(4)}"))
    return rules


def fix_years(lang: str, text: str, fr: str | None) -> tuple[str, int]:
    en, vers = fr_years(fr)
    if not (en or vers):
        return text, 0
    n = 0
    for kind, template, repl in year_rules(lang):
        for year in sorted(en if kind == "en" else vers):
            pattern = re.compile(template.replace("{year}", re.escape(year)))
            if repl in ("FI_SUFFIX", "ET_SUFFIX"):
                word = "vuonna" if repl == "FI_SUFFIX" else "aastal"

                def sub(m, word=word):
                    w = word.capitalize() if _sentence_start(m.string, m.start()) else word
                    return f"{w} {m.group(1)}{m.group(2)}{m.group(3)}"
                text, k = pattern.subn(sub, text)
            else:
                text, k = pattern.subn(repl, text)
            n += k
    return text, n


def fix_centuries(lang: str, text: str, fr: str | None) -> tuple[str, int]:
    n = 0
    if lang == "bg":
        def roman(m):
            v = int(m.group(1))
            return f"{ROMAN[v]} {m.group(2)}" if 1 <= v <= 21 else m.group(0)
        # First bound of a range: "от 5. до 12. век" → "от V до XII век".
        text, k = re.subn(r"(?<![\w.-])(\d{1,2})\s*\.(?=\s*(?:до|–|-|—|и)\s*\d{1,2}\s*\.\s*век)",
                          lambda m: ROMAN[int(m.group(1))] if 1 <= int(m.group(1)) <= 21 else m.group(0), text); n += k
        text, k = re.subn(r"(?<![\w.-])(\d{1,2})\s*\.\s*(век\w*)", roman, text); n += k
        text, k = re.subn(r"(?<![\w.-])(\d{1,2})\s*-?\s*(?:ти|ви|ри|ми|и)\s+(век\w*)", roman, text); n += k
    fr_c = fr_centuries(fr)
    # "Du XIIe au XVIe siècle": only the last numeral sits next to "siècle".
    fr_any = {ROMAN_VALUE[r] for r in FR_ANY_ROMAN_RE.findall(fr or "") if r in ROMAN_VALUE}
    if lang == "ru" and fr_c:
        def roman_ru(m):
            v = int(m.group(1))
            return f"{ROMAN[v]} {m.group(2)}" if v in fr_c and 1 <= v <= 21 else m.group(0)
        # First bound of a range: "С 12 по 16 век" → "С XII по XVI век".
        text, k = re.subn(r"(?<![\w.-])(\d{1,2})(?:-?(?:го|й))?(?=\s*(?:по|–|-|—|и|или)\s*\d{1,2}(?:-?(?:й|го|м|ом|ого))?\s+век)",
                          lambda m: ROMAN[int(m.group(1))] if int(m.group(1)) in fr_any else m.group(0), text); n += k
        text, k = re.subn(r"(?<![\w.-])(\d{1,2})(?:-?(?:й|го|м|ом|ого|ый))?\s+(век(?:а|е|у|ом)?)\b(?!\w)", roman_ru, text); n += k
    shifted = {"fi": r"luvu\w*|luku\w*", "da": r"tallet\w*", "nb": r"tallet\w*", "sv": r"talet\w*"}
    if lang in shifted and fr:
        # Only the unambiguous case: the French names exactly one century and the
        # translation writes exactly one "X00-tallet"; the VIIe siècle is 600-tallet.
        romans = {ROMAN_VALUE[r] for r in FR_ANY_ROMAN_RE.findall(fr) if r in ROMAN_VALUE}
        forms = re.findall(rf"(?<![\d])(\d{{3,4}})-(?:{shifted[lang]})", text)
        if len(romans) == 1 and len(set(forms)) == 1 and len(fr_c) == 1:
            c = romans.pop()
            wrong, right = c * 100, (c - 1) * 100
            if right > 0 and forms[0] == str(wrong) and str(wrong) not in fr:
                text, k = re.subn(rf"(?<![\d])({wrong})(-(?:{shifted[lang]}))", lambda m, r=right: f"{r}{m.group(2)}", text); n += k
    return text, n


def fix_percent(lang: str, text: str) -> tuple[str, int]:
    if lang != "tr":
        return text, 0
    # Ranges carry the sign on both bounds: "30 ile 99%" → "%30 ile %99", "30-99%" → "%30-99".
    text, k1 = re.subn(r"(?<![%\w.,])(\d+(?:[.,]\d+)?)(\s+(?:ile|ve|veya)\s+)(\d+(?:[.,]\d+)?)\s?%(?![\w%])", r"%\1\2%\3", text)
    text, k2 = re.subn(r"(?<![%\w.,])(\d+(?:[.,]\d+)?)(\s*[-–]\s*)(\d+(?:[.,]\d+)?)\s?%(?![\w%])", r"%\1\2\3", text)
    text, k3 = re.subn(r"(?<![%\w.,])(\d+(?:[.,]\d+)?)\s?%(?![\w%])", r"%\1", text)
    return text, k1 + k2 + k3


def fix_punctuation(lang: str, text: str, fr: str | None, location: str) -> tuple[str, int]:
    if location.startswith("ui:"):
        return text, 0
    n = 0
    if lang == "el" and "«" in text:
        # Never inside [[...]]: the glossary key would no longer match.
        parts = re.split(r"(\[\[.*?\]\])", text)
        for i, part in enumerate(parts):
            if not part.startswith("[["):
                parts[i], k = re.subn(r"«([^«»\[\]]*)»", r"„\1”", part); n += k
        text = "".join(parts)
    is_title = location.endswith("/title")
    if is_title and fr and " – " in text and " – " not in fr:
        if " : " in fr and ":" not in text:
            text = text.replace(" – ", ": ", 1); n += 1
        elif ", " in fr:
            text = text.replace(" – ", ", ", 1); n += 1
    return text, n


def _outside_glossary(func, text: str, *args) -> tuple[str, int]:
    """Apply ``func`` to the text outside [[...]] spans: a glossary term must keep matching its key."""
    parts = re.split(r"(\[\[.*?\]\])", text)
    total = 0
    for i, part in enumerate(parts):
        if part.startswith("[[") or not part:
            continue
        parts[i], k = func(part, *args)
        total += k
    return "".join(parts), total


def fix(lang: str, text: str, fr: str | None, location: str = "") -> tuple[str, Counter]:
    rules = Counter()
    new, k = _outside_glossary(lambda t: fix_years(lang, t, fr), text)
    rules["annee"] += k
    new, k = _outside_glossary(lambda t: fix_centuries(lang, t, fr), new)
    rules["siecle"] += k
    new, k = _outside_glossary(lambda t: fix_percent(lang, t), new)
    rules["pourcent"] += k
    new, k = fix_punctuation(lang, new, fr, location)
    rules["ponctuation"] += k
    return new, +rules


# ---------------------------------------------------------------- inputs with their French
def _load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def pairs(lang: str):
    """Yield (location, text, french or None) for every primary string of ``lang``."""
    for path in sorted((ROOT / "content" / "courses" / lang).glob("*.json")):
        fr_path = FR_COURSES / path.name
        fr = dict(segments(_load(fr_path))) if fr_path.exists() else {}
        for key, text in segments(_load(path)):
            yield f"cours:{path.stem}/{key}", text, fr.get(key)
    fr_courses = {c["id"]: c for c in _load(FR_CATALOG / "courses.fr.json")}
    fr_quiz = {q["courseId"]: {x["id"]: x for x in q["quiz"]} for q in _load(QUIZZES / "fr" / "quizzes_v2.json")}
    for course in _load(IOS_LOCALES / f"courses.{lang}.json"):
        fr = fr_courses.get(course["id"], {})
        for field in ("title", "description"):
            if course.get(field):
                yield f"catalogue:{course['id']}/{field}", course[field], fr.get(field)
        for lesson in course.get("lessons") or []:
            yield f"catalogue:{lesson['id']}", lesson.get("title") or "", None
    for entry in _load(QUIZZES / lang / "quizzes_v2.json"):
        frq = fr_quiz.get(entry["courseId"], {})
        for q in entry["quiz"]:
            f = frq.get(q["id"], {})
            for field in ("question", "explanation", "statement"):
                if q.get(field):
                    yield f"quiz:{q['id']}/{field}", q[field], f.get(field)
            for i, option in enumerate(q.get("options") or []):
                fo = (f.get("options") or [None] * 99)
                yield f"quiz:{q['id']}/option{i}", option, fo[i] if i < len(fo) else None
            for i, item in enumerate(q.get("items") or []):
                fi_ = (f.get("items") or [None] * 99)
                yield f"quiz:{q['id']}/item{i}", item, fi_[i] if i < len(fi_) else None
    for key, entry in _load(IOS_LOCALES / f"glossary.{lang}.json").items():
        yield f"glossaire:{key}", entry.get("explanation") or "", None
    fr_cols = {c["id"]: c for c in _load(FR_CATALOG / "collections.fr.json")}
    for col in _load(IOS_LOCALES / f"collections.{lang}.json"):
        for field in ("title", "description"):
            yield f"collections:{col['id']}/{field}", col.get(field) or "", fr_cols.get(col["id"], {}).get(field)
    android = _load(ROOT / "android" / "app" / "src" / "main" / "assets" / "strings" / f"{lang}.json")
    android_fr = _load(ROOT / "android" / "app" / "src" / "main" / "assets" / "strings" / "fr.json")
    for key, value in android.items():
        if isinstance(value, str):
            yield f"ui:{key}", value, android_fr.get(key)


def plan(lang: str) -> tuple[dict[str, str], list[dict]]:
    mapping: dict[str, str] = {}
    log: list[dict] = []
    for location, text, fr in pairs(lang):
        if not text or text in mapping:
            continue
        new, rules = fix(lang, text, fr, location)
        if new != text:
            mapping[text] = new
            log.append({"langue": lang, "emplacement": location, "regles": dict(rules), "avant": text, "apres": new})
    return mapping, log


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--lang", default="all")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--plan", type=Path, help="écrire la liste avant → après (JSON)")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()
    langs = NON_FR_LANGS if args.lang == "all" else args.lang.split(",")
    full_log: list[dict] = []
    for lang in langs:
        mapping, log = plan(lang)
        full_log += log
        per_rule = Counter()
        for item in log:
            per_rule.update(item["regles"])
        files = apply_mapping(lang, mapping, dry_run=args.dry_run)
        print(f"{lang:6s} chaînes={len(mapping):4d} " + " ".join(f"{r}={n}" for r, n in sorted(per_rule.items()))
              + f"  fichiers={len(files)}")
        if args.verbose:
            for item in log[:40]:
                print(f"    {item['emplacement']}\n      - {item['avant'][:160]}\n      + {item['apres'][:160]}")
    if args.plan:
        args.plan.write_text(json.dumps(full_log, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(f"plan écrit dans {args.plan}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
