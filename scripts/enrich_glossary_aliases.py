#!/usr/bin/env python3
"""Enrich non-FR glossary JSON with tap aliases (FR-parity).

French ``GlossaryData`` is denser mainly because ``import_content_from_csv.py``
adds exact keys for every ``<term>`` content link that fuzzy-matches a glossary
row, plus case/article variants. Locale glossaries were built from CSV only, so
many in-lesson ``<>`` taps rely on runtime fuzzy matching — or miss entirely
when the linked text is a short form of ``displayTerm``.

This script:
  1. Keeps every existing ``courseId|term`` entry untouched
  2. Adds exact alias keys for ``<>`` links that fuzzy-match a course entry
  3. Adds parenthetical / article-stripped short-form aliases from displayTerms
  4. Skips classification-label junk leaked into ``<>`` wrappers

Does **not** invent new concepts or machine-translate. Hard misses (``<>`` with
no glossary concept) stay unresolved — they are also absent from FR.

Usage:
    python scripts/enrich_glossary_aliases.py --lang en --only course_1_*
    python scripts/enrich_glossary_aliases.py --lang all
    python scripts/enrich_glossary_aliases.py qa --lang all
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

from i18n_languages import NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
CONTENT_LOCALES = ROOT / "content" / "locales"

LANGS = NON_FR_LANGS

LINK_RE = re.compile(r"<([^<>]+)>")
PAREN_RE = re.compile(r"\(([^)]+)\)")

# Classification labels / noise sometimes wrapped in <> in lesson CSVs.
JUNK_NORM = {
    "location",
    "event",
    "concept",
    "figure",
    "institution",
    "period",
    "work",
    "movement",
    "technique",
    "date",
    "politics",
    "evento",
    "concepto",
    "figura",
    "institucion",
    "periodo",
    "obra",
    "movimiento",
    "tecnica",
    "ort",
    "ereignis",
    "konzept",
    "figur",
    "zeitraum",
    "werk",
    "bewegung",
    "technik",
    "localizacao",
    "conceito",
    "instituicao",
    "movimento",
    "tecnica",
    "luogo",
    "concetto",
    "istituzione",
    "opera",
    "movimento",
    "tecnica",
    "allinterno",
    "inside",
    "dentro",
}

ARTICLES = {
    "en": ("the ", "a ", "an "),
    "es": ("el ", "la ", "los ", "las ", "un ", "una "),
    "de": ("der ", "die ", "das ", "dem ", "den ", "ein ", "eine "),
    "pt": ("o ", "a ", "os ", "as ", "um ", "uma "),
    "it": ("il ", "lo ", "la ", "i ", "gli ", "le ", "un ", "uno ", "una ", "l'"),
    "tr": ("bir ",),
    "pl": (),
    "ro": ("un ", "o ", "niște "),
    "nl": ("de ", "het ", "een "),
    "el": ("ο ", "η ", "το ", "οι ", "τα ", "ένας ", "μία ", "ένα "),
    "sv": ("en ", "ett ", "den ", "det ", "de "),
    "hu": ("a ", "az ", "egy "),
    "bg": ("един ", "една ", "едно "),
    "cs": (),
}


def norm_key(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value or "")
    return "".join(ch for ch in decomposed.lower() if ch.isalnum())


def is_junk(term: str) -> bool:
    n = norm_key(term)
    if not n or len(n) < 3:
        return True
    return n in JUNK_NORM


def fuzzy_match(term: str, entries: list[dict]) -> dict | None:
    from difflib import SequenceMatcher

    needle = norm_key(term)
    if len(needle) < 3:
        return None
    best = None
    best_score = 0.0
    for entry in entries:
        hay = norm_key(entry.get("displayTerm") or "")
        if not hay:
            continue
        if needle == hay:
            return entry
        score = 0.0
        if len(needle) >= 4 and (needle in hay or hay in needle):
            score = min(len(needle), len(hay)) / max(len(needle), len(hay))
        # Near-typos / locale spelling drift with small length delta
        # (e.g. Soviet vs Soviete). Same-length substitutions like
        # T-lymphocytes vs B-lymphocytes must NOT match.
        if (
            len(needle) >= 8
            and len(hay) >= 8
            and 1 <= abs(len(needle) - len(hay)) <= 2
        ):
            sm = SequenceMatcher(None, needle, hay).ratio()
            if sm >= 0.9:
                score = max(score, sm)
        if score > best_score:
            best_score = score
            best = entry
    if best and best_score >= 0.45:
        return best
    return None


def short_forms(display: str, lang: str) -> list[str]:
    out: list[str] = []
    stripped = display.strip()
    if not stripped:
        return out
    # Parenthetical: "Newspeak (novlangue)" → both sides useful as aliases.
    for inner in PAREN_RE.findall(stripped):
        inner = inner.strip()
        if inner and not is_junk(inner):
            out.append(inner)
    outer = PAREN_RE.sub("", stripped).strip(" -–—")
    if outer and outer != stripped and not is_junk(outer):
        out.append(outer)
    lower = stripped
    for art in ARTICLES.get(lang, ()):
        if lower.casefold().startswith(art):
            candidate = stripped[len(art) :].lstrip()
            if candidate and not is_junk(candidate):
                out.append(candidate)
            break
    # Dedup preserve order
    seen: set[str] = set()
    unique: list[str] = []
    for item in out:
        if item not in seen and item != stripped:
            seen.add(item)
            unique.append(item)
    return unique


GLOSSARY_CSV = {
    "en": CONTENT_LOCALES / "en" / "source" / "Glossaire_culture_generale_modifie_EN_96bc.csv",
    "es": CONTENT_LOCALES / "es" / "source" / "Glossaire_culture_generale_modifie_ES_5952.csv",
    "de": CONTENT_LOCALES / "de" / "source" / "Glossaire_culture_generale_modifie_DE_507c.csv",
    "pt": CONTENT_LOCALES / "pt" / "source" / "Glossaire_culture_generale_modifie_PT_ee5e.csv",
    "it": CONTENT_LOCALES / "it" / "source" / "Glossaire_culture_generale_modifie_IT_8e63.csv",
}

COURSES_CSV = {
    "en": CONTENT_LOCALES / "en" / "source" / "Excel_cours_systeme_modifie_EN_0b72.csv",
    "es": CONTENT_LOCALES / "es" / "source" / "Excel_cours_systeme_modifie_ES_1e16.csv",
    "de": CONTENT_LOCALES / "de" / "source" / "Excel_cours_systeme_modifie_DE_ea79.csv",
    "pt": CONTENT_LOCALES / "pt" / "source" / "Excel_cours_systeme_modifie_PT_4407.csv",
    "it": CONTENT_LOCALES / "it" / "source" / "Excel_cours_systeme_modifie_IT_626c.csv",
}


def load_bundle(lang: str) -> tuple[list[dict], dict[str, dict]]:
    courses = json.loads((LOCALE_DIR / f"courses.{lang}.json").read_text(encoding="utf-8"))
    glossary = json.loads((LOCALE_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8"))
    return courses, glossary


def load_canonical_glossary(lang: str, *, from_json: bool = False) -> dict[str, dict]:
    """Rebuild the CSV-only glossary (no tap aliases) — source of truth for enrich.

    For locales without CSV exports (new MT languages), ``from_json=True`` uses the
    current bundled glossary as the canonical base (idempotent alias layering).
    """
    if from_json or lang not in GLOSSARY_CSV:
        gloss = json.loads((LOCALE_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8"))
        # Drop previously generated short/link aliases? We cannot distinguish
        # perfectly; treat current file as canonical when from_json.
        return gloss

    sys.path.insert(0, str(ROOT / "scripts"))
    from generate_en_locale_json import load_en_courses_rows, load_en_glossary  # noqa: WPS433
    from import_content_from_csv import parse_all_courses  # noqa: WPS433

    course_data = (ROOT / "ios/Sophia/Services/CourseData.swift").read_text(encoding="utf-8")
    app_courses = parse_all_courses(course_data)
    rows = load_en_courses_rows(COURSES_CSV[lang])
    glossary_rows = load_en_glossary(GLOSSARY_CSV[lang])

    if lang == "en":
        from generate_en_locale_json import build_glossary_json  # noqa: WPS433
    elif lang == "es":
        from generate_es_locale_json import build_glossary_json  # noqa: WPS433
    elif lang == "de":
        from generate_de_locale_json import build_glossary_json  # noqa: WPS433
    elif lang == "pt":
        from generate_pt_locale_json import build_glossary_json  # noqa: WPS433
    elif lang == "it":
        from generate_it_locale_json import build_glossary_json  # noqa: WPS433
    else:
        raise ValueError(lang)

    return build_glossary_json(app_courses, rows, glossary_rows)


def write_glossary(lang: str, glossary: dict[str, dict]) -> None:
    path = LOCALE_DIR / f"glossary.{lang}.json"
    path.write_text(json.dumps(glossary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_alias_csv(lang: str, aliases: list[dict]) -> None:
    path = CONTENT_LOCALES / lang / "source" / "glossary_aliases_v2.csv"
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = ["courseId", "aliasTerm", "canonicalDisplayTerm", "classification", "explanation", "source"]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(aliases)


def enrich_lang(
    lang: str,
    *,
    only: str = "",
    limit: int = 0,
    from_json: bool = False,
) -> tuple[dict[str, dict], list[dict], dict]:
    import fnmatch

    courses, current = load_bundle(lang)
    canonical = load_canonical_glossary(lang, from_json=from_json or lang not in GLOSSARY_CSV)
    if only:
        patterns = [p.strip() for p in only.split(",") if p.strip()]
        courses = [
            c
            for c in courses
            if any(fnmatch.fnmatch(c["id"], pat) or c["id"] == pat for pat in patterns)
        ]
    if limit:
        courses = courses[:limit]

    by_course: dict[str, list[dict]] = defaultdict(list)
    for key, entry in canonical.items():
        if "|" not in key:
            continue
        cid, _ = key.split("|", 1)
        by_course[cid].append(entry)

    added_aliases: list[dict] = []
    stats = {
        "courses": len(courses),
        "before": len(current),
        "canonical": len(canonical),
        "link_aliases": 0,
        "short_aliases": 0,
        "skipped_existing": 0,
        "skipped_junk": 0,
        "unresolved_links": 0,
    }

    # Always rebuild from CSV canonical + aliases (idempotent).
    out = dict(canonical)

    for course in courses:
        cid = course["id"]
        canonical_entries = list(by_course.get(cid, []))
        if not canonical_entries:
            continue

        matchable = list(canonical_entries)

        # 1) Short-form aliases first — parentheticals/articles become matchable
        #    targets for <> link resolution below (FR-style densification).
        for entry in canonical_entries:
            display = entry.get("displayTerm") or ""
            for alias in short_forms(display, lang):
                key = f"{cid}|{alias}"
                if key in out:
                    continue
                alias_entry = {
                    "displayTerm": alias,
                    "classification": entry["classification"],
                    "explanation": entry["explanation"],
                }
                out[key] = alias_entry
                matchable.append(alias_entry)
                added_aliases.append(
                    {
                        "courseId": cid,
                        "aliasTerm": alias,
                        "canonicalDisplayTerm": display,
                        "classification": entry["classification"],
                        "explanation": entry["explanation"],
                        "source": "short_form",
                    }
                )
                stats["short_aliases"] += 1

        # 2) Exact aliases for <> lesson links that fuzzy-match a course entry.
        seen_links: set[str] = set()
        for lesson in course.get("lessons") or []:
            content = lesson.get("content") or ""
            for term in LINK_RE.findall(content):
                term = term.strip()
                if not term or term in seen_links:
                    continue
                seen_links.add(term)
                key = f"{cid}|{term}"
                if key in out:
                    stats["skipped_existing"] += 1
                    continue
                if is_junk(term):
                    stats["skipped_junk"] += 1
                    continue
                match = fuzzy_match(term, matchable)
                if not match:
                    stats["unresolved_links"] += 1
                    continue
                out[key] = {
                    "displayTerm": term,
                    "classification": match["classification"],
                    "explanation": match["explanation"],
                }
                added_aliases.append(
                    {
                        "courseId": cid,
                        "aliasTerm": term,
                        "canonicalDisplayTerm": match["displayTerm"],
                        "classification": match["classification"],
                        "explanation": match["explanation"],
                        "source": "content_link",
                    }
                )
                stats["link_aliases"] += 1

    stats["after"] = len(out)
    stats["added"] = stats["link_aliases"] + stats["short_aliases"]
    return out, added_aliases, stats


def measure_coverage(lang: str, glossary: dict[str, dict] | None = None) -> dict:
    courses, base = load_bundle(lang)
    gloss = glossary if glossary is not None else base
    by_course: dict[str, list[dict]] = defaultdict(list)
    for key, entry in gloss.items():
        if "|" not in key:
            continue
        cid, _ = key.split("|", 1)
        by_course[cid].append(entry)

    total = exact = fuzzy = junk = miss = 0
    for course in courses:
        cid = course["id"]
        entries = by_course.get(cid, [])
        for lesson in course.get("lessons") or []:
            for term in LINK_RE.findall(lesson.get("content") or ""):
                term = term.strip()
                total += 1
                if f"{cid}|{term}" in gloss:
                    exact += 1
                elif is_junk(term):
                    junk += 1
                elif fuzzy_match(term, entries):
                    fuzzy += 1
                else:
                    miss += 1
    return {
        "keys": len(gloss),
        "links": total,
        "exact": exact,
        "fuzzy": fuzzy,
        "junk": junk,
        "miss": miss,
        "exact_pct": round(100 * exact / total, 1) if total else 0.0,
    }


def validate_enrichment(before: dict, after: dict) -> list[str]:
    errs: list[str] = []
    for key, entry in before.items():
        if key not in after:
            errs.append(f"missing original key {key}")
            continue
        if after[key].get("explanation") != entry.get("explanation"):
            errs.append(f"explanation changed for {key}")
        if after[key].get("classification") != entry.get("classification"):
            errs.append(f"classification changed for {key}")
    if len(after) < len(before):
        errs.append(f"key count shrank {len(before)} → {len(after)}")
    return errs


def cmd_enrich(args: argparse.Namespace) -> int:
    langs = LANGS if args.lang == "all" else [args.lang]
    failed = 0
    for lang in langs:
        if lang not in LANGS:
            print(f"Unknown lang {lang}", file=sys.stderr)
            return 1
        before = json.loads((LOCALE_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8"))
        from_json = bool(getattr(args, "from_json", False) or lang not in GLOSSARY_CSV)
        canonical = load_canonical_glossary(lang, from_json=from_json)
        cov_before = measure_coverage(lang, before)
        after, aliases, stats = enrich_lang(
            lang, only=args.only, limit=args.limit, from_json=from_json
        )
        # enrich_lang starts from CSV canonical (or JSON for new locales), then
        # adds aliases. Idempotent for CSV langs; JSON mode layers on current file.

        errs = validate_enrichment(canonical, after)
        cov_after = measure_coverage(lang, after)
        print(f"\n=== {lang} ===")
        print(
            f"  keys {stats['before']} → {len(after)} "
            f"(canonical {stats['canonical']}, +{len(after) - stats['canonical']} aliases)"
        )
        print(
            f"  aliases: link={stats['link_aliases']} short={stats['short_aliases']} "
            f"junk_skipped={stats['skipped_junk']} unresolved={stats['unresolved_links']}"
        )
        print(
            f"  <> coverage exact: {cov_before['exact']}/{cov_before['links']} "
            f"({cov_before['exact_pct']}%) → {cov_after['exact']}/{cov_after['links']} "
            f"({cov_after['exact_pct']}%)"
        )
        print(f"  remaining miss (non-junk): {cov_after['miss']}")
        if errs:
            print(f"  QA FAIL ({len(errs)})")
            for e in errs[:20]:
                print("   -", e)
            failed += 1
            continue
        if not args.dry_run:
            write_glossary(lang, after)
            write_alias_csv(lang, aliases)
            print(f"  wrote glossary.{lang}.json + glossary_aliases_v2.csv ({len(aliases)} rows)")
        else:
            print("  dry-run: not written")
    return 1 if failed else 0


def cmd_qa(args: argparse.Namespace) -> int:
    langs = LANGS if args.lang == "all" else [args.lang]
    failed = 0
    for lang in langs:
        gloss = json.loads((LOCALE_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8"))
        cov = measure_coverage(lang, gloss)
        print(
            f"{lang}: keys={cov['keys']} exact={cov['exact']}/{cov['links']} "
            f"({cov['exact_pct']}%) fuzzy={cov['fuzzy']} junk={cov['junk']} miss={cov['miss']}"
        )
        # Hard gate: every non-junk <> that fuzzy-matches must have an exact alias key.
        courses, _ = load_bundle(lang)
        by_course: dict[str, list[dict]] = defaultdict(list)
        for key, entry in gloss.items():
            if "|" not in key:
                continue
            by_course[key.split("|", 1)[0]].append(entry)
        recoverable_miss = 0
        for course in courses:
            cid = course["id"]
            entries = by_course.get(cid, [])
            for lesson in course.get("lessons") or []:
                for term in LINK_RE.findall(lesson.get("content") or ""):
                    term = term.strip()
                    if f"{cid}|{term}" in gloss or is_junk(term):
                        continue
                    if fuzzy_match(term, entries):
                        recoverable_miss += 1
        if recoverable_miss:
            print(f"  FAIL: {recoverable_miss} recoverable <> links still lack exact keys")
            failed += 1
        else:
            print("  PASS: all recoverable <> links have exact keys")
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd")

    p = sub.add_parser("enrich", help="Add glossary tap aliases")
    p.add_argument("--lang", required=True)
    p.add_argument("--only", default="")
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument(
        "--from-json",
        action="store_true",
        help="Use bundled glossary JSON as canonical (for langs without CSV)",
    )
    p.set_defaults(func=cmd_enrich)

    q = sub.add_parser("qa", help="Hard QA on recoverable <> coverage")
    q.add_argument("--lang", required=True)
    q.set_defaults(func=cmd_qa)

    # Default to enrich when no subcommand (back-compat).
    args, unknown = parser.parse_known_args()
    if args.cmd is None:
        # treat top-level flags as enrich
        p = argparse.ArgumentParser()
        p.add_argument("--lang", required=True)
        p.add_argument("--only", default="")
        p.add_argument("--limit", type=int, default=0)
        p.add_argument("--dry-run", action="store_true")
        args = p.parse_args()
        args.func = cmd_enrich
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
