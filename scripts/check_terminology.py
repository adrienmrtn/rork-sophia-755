#!/usr/bin/env python3
"""Balaye toutes les surfaces de l'app, dans chaque langue, à la recherche des
formes fautives connues (mots pièges), des variantes de termes produit et des
titres d'œuvres rendus littéralement.

Les listes vivent dans ``content/terminology/`` (voir le README). Elles sont
le pendant de ``scripts/proper_nouns.json`` : là où celui-ci protège des noms
avant la traduction automatique, celles-ci vérifient le résultat après.

Surfaces balayées par langue : chaînes iOS (AppLocalizable.swift) et Android
(assets/strings), corps de cours (content/courses), quiz (quizzes_v2.json),
glossaire et collections (Resources/Locales), catalogue (courses.<lang>.json :
titres, descriptions, titres de leçons), fiche App Store (appstore/metadata),
textes légaux (iOS et Android).

Usage:
    python scripts/check_terminology.py                 # résumé par langue
    python scripts/check_terminology.py --lang he -v    # chaque occurrence
    python scripts/check_terminology.py --json /tmp/term.json
    python scripts/check_terminology.py --gate          # code retour 1 s'il reste une occurrence
"""

from __future__ import annotations

import argparse
import json
import os
from concurrent.futures import ProcessPoolExecutor
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from i18n_languages import NON_FR_LANGS, SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
TERM_DIR = ROOT / "content" / "terminology"
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
ANDROID_STRINGS = ROOT / "android" / "app" / "src" / "main" / "assets" / "strings"
ANDROID_LEGAL = ROOT / "android" / "app" / "src" / "main" / "assets" / "legal"
IOS_LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
COURSES = ROOT / "content" / "courses"
LOCALES = ROOT / "content" / "locales"
STORE = ROOT / "appstore" / "metadata"
STORE_LOCALE = {
    "en": "en-US", "es": "es-ES", "de": "de-DE", "pt": "pt-BR", "pt-PT": "pt-PT", "it": "it", "tr": "tr",
    "pl": "pl", "ro": "ro", "nl": "nl-NL", "el": "el", "sv": "sv", "hu": "hu", "cs": "cs", "da": "da",
    "nb": "no", "ru": "ru", "hr": "hr", "sl": "sl-SI", "sk": "sk", "ar": "ar-SA", "he": "he", "fi": "fi",
}

ENTRY_RE = re.compile(r'^\s*"((?:\\.|[^"\\])*)":\s*"((?:\\.|[^"\\])*)",?\s*$', re.M)


def _swift_unescape(value: str) -> str:
    def repl(match: re.Match[str]) -> str:
        esc = match.group(1)
        if esc.startswith("u{"):
            return chr(int(esc[2:-1], 16))
        return {"n": "\n", "t": "\t", '"': '"', "\\": "\\", "r": "\r"}.get(esc, esc)
    return re.sub(r"\\(u\{[0-9A-Fa-f]+\}|.)", repl, value)


def ios_table(code: str) -> dict[str, str]:
    source = LOCALIZABLE.read_text(encoding="utf-8")
    name = SWIFT_CASE_BY_CODE[code]
    match = re.search(r"private static let %s: \[String: String\] = \[(.*?)\n    \]" % name, source, re.S)
    if not match:
        return {}
    return {_swift_unescape(k): _swift_unescape(v) for k, v in ENTRY_RE.findall(match.group(1))}


def _load(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def iter_texts(code: str):
    """Yield (surface, location, text) for every displayed string of one language."""
    for key, value in ios_table(code).items():
        yield "ui", f"ios:{key}", value
    android = _load(ANDROID_STRINGS / f"{code}.json") or {}
    for key, value in android.items():
        if isinstance(value, str):
            yield "ui", f"android:{key}", value
    for path in sorted((COURSES / code).glob("*.json")):
        course = _load(path) or {}
        cid = course.get("id", path.stem)
        for field in ("title", "subtitle", "description"):
            if course.get(field):
                yield "cours", f"{cid}/{field}", course[field]
        if (course.get("hero") or {}).get("hook"):
            yield "cours", f"{cid}/hero.hook", course["hero"]["hook"]
        for s_index, section in enumerate(course.get("sections") or []):
            if section.get("title"):
                yield "cours", f"{cid}/s{s_index}.title", section["title"]
            for b_index, block in enumerate(section.get("blocks") or []):
                prefix = f"{cid}/s{s_index}.b{b_index}"
                for field in ("text", "caption", "attribution"):
                    if block.get(field):
                        yield "cours", f"{prefix}.{field}", block[field]
                for e_index, event in enumerate(block.get("events") or []):
                    for field in ("title", "detail"):
                        if event.get(field):
                            yield "cours", f"{prefix}.e{e_index}.{field}", event[field]
    for entry in _load(LOCALES / code / "quizzes_v2.json") or []:
        for q in entry.get("quiz") or []:
            qid = q.get("id", "?")
            for field in ("question", "explanation", "statement"):
                if q.get(field):
                    yield "quiz", f"{qid}/{field}", q[field]
            for i, option in enumerate(q.get("options") or []):
                if isinstance(option, str):
                    yield "quiz", f"{qid}/option{i}", option
            for i, item in enumerate(q.get("items") or []):
                if isinstance(item, str):
                    yield "quiz", f"{qid}/item{i}", item
    for key, entry in (_load(IOS_LOCALES / f"glossary.{code}.json") or {}).items():
        for field in ("displayTerm", "explanation"):
            if entry.get(field):
                yield "glossaire", f"{key}/{field}", entry[field]
    for coll in _load(IOS_LOCALES / f"collections.{code}.json") or []:
        for field in ("title", "description"):
            if coll.get(field):
                yield "collections", f"{coll.get('id')}/{field}", coll[field]
    for course in _load(IOS_LOCALES / f"courses.{code}.json") or []:
        cid = course.get("id")
        for field in ("title", "subtitle", "description", "subcategory"):
            if course.get(field):
                yield "catalogue", f"{cid}/{field}", course[field]
        for lesson in course.get("lessons") or []:
            if lesson.get("title"):
                yield "catalogue", f"{lesson.get('id')}/title", lesson["title"]
    locale = STORE_LOCALE.get(code)
    if locale and (STORE / locale).is_dir():
        for path in sorted((STORE / locale).glob("*.txt")):
            if path.stem.endswith("_url"):
                continue
            yield "store", f"{locale}/{path.stem}", path.read_text(encoding="utf-8")
    for label, path in (("ios", LOCALES / code / "legal.json"), ("android", ANDROID_LEGAL / f"{code}.json")):
        pack = _load(path) or {}
        for kind in ("terms", "privacy"):
            for section in pack.get(kind) or []:
                for field in ("title", "body"):
                    if section.get(field):
                        yield "legal", f"{label}:{kind}/{section.get('id')}/{field}", section[field]


def load_lists() -> tuple[list[dict], list[dict], list[dict]]:
    traps = (_load(TERM_DIR / "mots_pieges.json") or {}).get("entrees", [])
    terms = (_load(TERM_DIR / "termes_produit.json") or {}).get("termes", [])
    works = (_load(TERM_DIR / "oeuvres.json") or {}).get("oeuvres", [])
    return traps, terms, works


def compile_rules(code: str, traps: list[dict], terms: list[dict], works: list[dict]) -> list[tuple[str, str, str, re.Pattern[str], set[str] | None]]:
    """(kind, id, label, pattern, surfaces or None for all)."""
    rules = []
    for entry in traps:
        per = (entry.get("par_langue") or {}).get(code) or {}
        surfaces = None
        if entry.get("ou"):
            wanted = {s.strip() for s in entry["ou"].split(",")}
            # 'ui' rules also apply to the store page; course rules to quiz, glossary, catalogue.
            expand = {"ui": {"ui", "store", "legal"}, "cours": {"cours", "quiz", "glossaire", "catalogue", "collections"},
                      "quiz": {"quiz"}, "glossaire": {"glossaire"}, "catalogue": {"catalogue", "collections"}, "store": {"store"}}
            surfaces = set()
            for w in wanted:
                surfaces |= expand.get(w, {w})
        for raw in per.get("fautif") or []:
            try:
                rules.append(("piege", entry["id"], per.get("forme_imposee", ""), re.compile(raw, re.I | re.U), surfaces))
            except re.error as error:
                print(f"  warn {code} piege {entry['id']}: bad regex {raw!r}: {error}", file=sys.stderr)
    for term in terms:
        per = (term.get("par_langue") or {}).get(code) or {}
        for raw in per.get("variantes_a_signaler") or []:
            try:
                rules.append(("produit", term["id"], per.get("canon", ""), re.compile(raw, re.I | re.U), {"ui", "store", "catalogue", "collections"}))
            except re.error as error:
                print(f"  warn {code} produit {term['id']}: bad regex {raw!r}: {error}", file=sys.stderr)
    for work in works:
        per = (work.get("par_langue") or {}).get(code) or {}
        for raw in per.get("fautif") or []:
            try:
                rules.append(("oeuvre", work["id"], per.get("titre", ""), re.compile(raw, re.I | re.U), None))
            except re.error as error:
                print(f"  warn {code} oeuvre {work['id']}: bad regex {raw!r}: {error}", file=sys.stderr)
    return rules


def scan(code: str, rules) -> list[dict]:
    """Every rule on every string; a rule reports at most one occurrence per string."""
    hits = []
    for surface, location, text in iter_texts(code):
        for kind, ident, expected, pattern, surfaces in rules:
            if surfaces is not None and surface not in surfaces:
                continue
            match = pattern.search(text)
            if match:
                start = max(0, match.start() - 30)
                hits.append({
                    "langue": code, "surface": surface, "emplacement": location, "type": kind, "id": ident,
                    "trouve": match.group(0), "contexte": text[start:match.end() + 30].replace("\n", " "),
                    "attendu": expected,
                })
    return hits


def _scan_language(code: str) -> tuple[str, int, list[dict]]:
    traps, terms, works = load_lists()
    rules = compile_rules(code, traps, terms, works)
    return code, len(rules), scan(code, rules)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--lang", default="all")
    parser.add_argument("-v", "--verbose", action="store_true", help="une ligne par occurrence")
    parser.add_argument("--json", type=Path, help="écrire toutes les occurrences dans ce fichier")
    parser.add_argument("--gate", action="store_true", help="code retour 1 s'il reste une occurrence")
    args = parser.parse_args()
    langs = NON_FR_LANGS if args.lang == "all" else [c.strip() for c in args.lang.split(",")]
    traps, terms, works = load_lists()
    if not (traps or terms or works):
        print(f"Aucune liste dans {TERM_DIR} ; rien à vérifier.")
        return 0
    all_hits: list[dict] = []
    # The regex engine dominates (about 25 s per language): one process per language.
    with ProcessPoolExecutor(max_workers=max(1, min(len(langs), os.cpu_count() or 1))) as pool:
        results = list(pool.map(_scan_language, langs))
    for code, rules_count, hits in results:
        rules = range(rules_count)
        all_hits.extend(hits)
        by_surface = Counter(h["surface"] for h in hits)
        by_id = Counter(f"{h['type']}:{h['id']}" for h in hits)
        top = ", ".join(f"{k} ×{n}" for k, n in by_id.most_common(5))
        print(f"{code:6s} règles={len(rules):4d} occurrences={len(hits):5d}  "
              + " ".join(f"{s}={n}" for s, n in sorted(by_surface.items()))
              + (f"\n       principaux : {top}" if top else ""))
        if args.verbose:
            for h in hits:
                print(f"    [{h['surface']}] {h['emplacement']}  «{h['trouve']}»  → attendu : {h['attendu']}\n        …{h['contexte']}…")
    print(f"\nTotal : {len(all_hits)} occurrences dans {len(langs)} langues.")
    if args.json:
        args.json.write_text(json.dumps(all_hits, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(f"Détail écrit dans {args.json}")
    return 1 if (args.gate and all_hits) else 0


if __name__ == "__main__":
    raise SystemExit(main())
