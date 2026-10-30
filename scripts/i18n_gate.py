#!/usr/bin/env python3
"""Porte de sortie des traductions : refuse tout ce qui ferait régresser une langue.

Lancée par la CI (.github/workflows/i18n-gate.yml) sur chaque push et chaque pull
request qui touche un texte affiché, et à lancer à la main avant de pousser :

    python3 scripts/i18n_gate.py                    # toutes les vérifications, 26 langues
    python3 scripts/i18n_gate.py --only cles,temoins
    python3 scripts/i18n_gate.py --update-baseline  # après avoir corrigé des constats

Vérifications :

  cles          chaque clé d'interface française existe dans chaque langue (tables
                iOS d'AppLocalizable.swift, chaînes Android), avec les mêmes
                placeholders (%@, %d, {n}…) que le français.
  copies        chaque cours existe dans chaque langue, et la source (content/courses),
                le bundle iOS et la copie Android sont identiques ; glossaire et
                catalogue identiques entre iOS et Android ; aucun lien [[terme]] mort.
  validateur    scripts/check_course_translation.py sur les 309 cours.
  terminologie  scripts/check_terminology.py (mots pièges, termes produit, titres).
  quiz          scripts/check_quiz_structure.py (structure et bonnes réponses).
  fiche         scripts/appstore_metadata.py check (longueurs de la fiche App Store).
  temoins       les chaînes témoins de content/terminology/sentinelles.json ont
                exactement la traduction attendue, sur iOS et sur Android.

Les constats de validateur, terminologie, quiz et copies qui existaient au moment où
la porte a été posée sont listés dans content/terminology/i18n_gate_baseline.json :
ils ne bloquent pas, seuls les nouveaux bloquent. Une correction fait baisser le
compte ; --update-baseline l'enregistre pour que la porte se resserre. N'ajoutez pas
un constat au baseline pour faire passer un commit : corrigez-le, ou, si c'est un
faux positif, corrigez la règle.

Les clés manquantes, les placeholders, la fiche et les chaînes témoins n'ont pas de
baseline : ils doivent être justes. Pour changer volontairement une chaîne témoin,
modifiez sa valeur dans sentinelles.json dans le même commit, avec la raison.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from i18n_languages import NON_FR_LANGS, SWIFT_CASE_BY_CODE  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
IOS = ROOT / "ios" / "Sophia" / "Resources"
AND = ROOT / "android" / "app" / "src" / "main" / "assets"
COURSES = ROOT / "content" / "courses"
TERM_DIR = ROOT / "content" / "terminology"
BASELINE = TERM_DIR / "i18n_gate_baseline.json"
SENTINELS = TERM_DIR / "sentinelles.json"

CHECKS = ["cles", "copies", "validateur", "terminologie", "quiz", "fiche", "temoins"]
BASELINED = {"copies", "validateur", "terminologie", "quiz"}
PLACEHOLDER = re.compile(r"%(?:\d+\$)?(?:lld|ld|lu|lf|f|d|@|s)|\{[a-zA-Z]+\}")
# Filled in by both apps when present, so a language may add it: the word for "days"
# agreed with {n} (StringStore.trialText on Android, AppLocalizable on iOS).
OPTIONAL_PLACEHOLDERS = {"{dayWord}"}
# Developer-only screens, not translated on purpose.
UNTRANSLATED_PREFIXES = ("settings.debug.",)


# ------------------------------------------------------------------ tables d'interface
def _unescape(s: str) -> str:
    def r(m):
        e = m.group(1)
        if e.startswith("u{"):
            return chr(int(e[2:-1], 16))
        return {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(e, e)
    return re.sub(r"\\(u\{[0-9A-Fa-f]+\}|.)", r, s)


def swift_table(case: str, source: str) -> dict[str, str]:
    m = re.search(r"private static let %s: \[String: String\] = \[(.*?)\n    \]" % case, source, re.S)
    if not m:
        return {}
    return {_unescape(k): _unescape(v) for k, v in
            re.findall(r'^\s*"((?:\\.|[^"\\])*)":\s*"((?:\\.|[^"\\])*)",?\s*$', m.group(1), re.M)}


def android_table(lang: str) -> dict[str, str]:
    p = AND / "strings" / f"{lang}.json"
    data = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
    return {k: v for k, v in data.items() if isinstance(v, str)}


def placeholders(s: str) -> list[str]:
    # %1$d and %d are the same argument type; the position only lets a language reorder them.
    return sorted(re.sub(r"^%\d+\$", "%", p) for p in PLACEHOLDER.findall(s))


def same_placeholders(key: str, value: str, fr_value: str) -> bool:
    got = [p for p in placeholders(value) if p not in OPTIONAL_PLACEHOLDERS]
    want = placeholders(fr_value)
    if key.endswith(".one"):
        # A singular form may spell the number out ("one day") instead of printing %d.
        return not (Counter(got) - Counter(want))
    return got == want


def check_cles(langs: list[str]) -> list[str]:
    source = LOCALIZABLE.read_text(encoding="utf-8")
    fr_ios, fr_and = swift_table("french", source), android_table("fr")
    out = []
    for lang in langs:
        for platform, fr, cur in (("ios", fr_ios, swift_table(SWIFT_CASE_BY_CODE[lang], source)),
                                  ("android", fr_and, android_table(lang))):
            for key, fr_value in fr.items():
                if key.startswith(UNTRANSLATED_PREFIXES):
                    continue
                if key not in cur:
                    out.append(f"cles|{lang}|{platform}|{key}|clé absente")
                elif not same_placeholders(key, cur[key], fr_value):
                    out.append(f"cles|{lang}|{platform}|{key}|placeholders {placeholders(cur[key])} ≠ français {placeholders(fr_value)}")
    return out


# ------------------------------------------------------------------ copies
def _strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, list):
        for x in node:
            yield from _strings(x)
    elif isinstance(node, dict):
        for x in node.values():
            yield from _strings(x)


def _json(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def check_copies(langs: list[str]) -> list[str]:
    out = []
    fr_ids = sorted(p.stem for p in (COURSES / "fr").glob("*.json"))
    for lang in ["fr", *langs]:
        gi, ga = IOS / "Locales" / f"glossary.{lang}.json", AND / "locales" / f"glossary.{lang}.json"
        glossary = _json(gi) if gi.exists() else {}
        if gi.exists() and ga.exists() and _json(ga) != glossary:
            g2 = _json(ga)
            for k in sorted(set(glossary) | set(g2)):
                if glossary.get(k) != g2.get(k):
                    out.append(f"copies|{lang}|glossaire|{k}|iOS ≠ Android")
        for cid in fr_ids:
            src = COURSES / lang / f"{cid}.json"
            if not src.exists():
                out.append(f"copies|{lang}|{cid}|cours absent")
                continue
            course = _json(src)
            for name, p in (("ios", IOS / "CoursesV2" / f"{cid}.{lang}.json"), ("android", AND / "courses_v2" / lang / f"{cid}.json")):
                if not p.exists():
                    out.append(f"copies|{lang}|{cid}|copie {name} absente")
                elif _json(p) != course:
                    out.append(f"copies|{lang}|{cid}|copie {name} ≠ source")
            if gi.exists():
                for s in _strings(course):
                    for term in re.findall(r"\[\[(.+?)\]\]", s):
                        if f"{cid}|{term}" not in glossary:
                            out.append(f"copies|{lang}|{cid}|lien mort [[{term}]]")
        ci, ca = IOS / "Locales" / f"courses.{lang}.json", AND / "locales" / f"courses.{lang}.json"
        if ci.exists() and ca.exists():
            android = {x["id"]: x for x in _json(ca)}
            for x in _json(ci):
                y = android.get(x["id"], {})
                for field, value in x.items():
                    if field in y and y[field] != value:
                        out.append(f"copies|{lang}|catalogue|{x['id']}|{field} iOS ≠ Android")
    return out


# ------------------------------------------------------------------ outils existants
def _validate_lang(lang: str) -> list[str]:
    from check_course_translation import check_course
    from course_translation_io import glossary_keys_by_course
    allowed = glossary_keys_by_course(lang)
    out = []
    for p in sorted((COURSES / "fr").glob("*.json")):
        for f in check_course(p.stem, lang, allowed):
            out.append(f"validateur|{lang}|{f.course_id}|{f.key}|{f.rule}")
    return out


def _terms_lang(lang: str) -> list[str]:
    from check_terminology import _scan_language
    _, _, hits = _scan_language(lang)
    return [f"terminologie|{lang}|{h['surface']}|{h['emplacement']}|{h['type']}:{h['id']}" for h in hits]


def _pool(fn, langs: list[str]) -> list[str]:
    with ProcessPoolExecutor(max_workers=max(1, min(len(langs), os.cpu_count() or 1))) as pool:
        return [x for chunk in pool.map(fn, langs) for x in chunk]


def check_quiz(langs: list[str]) -> list[str]:
    r = subprocess.run([sys.executable, str(SCRIPTS / "check_quiz_structure.py")], cwd=SCRIPTS,
                       capture_output=True, text=True)
    lines = [l.strip() for l in r.stdout.splitlines() if l.strip()]
    wanted = set(langs)
    return [f"quiz|{l}" for l in lines
            if not l.startswith(("FAILED", "OK", "All ", "Checked")) and l.split(" ", 1)[0] in wanted]


def check_fiche(_langs: list[str]) -> list[str]:
    r = subprocess.run([sys.executable, str(SCRIPTS / "appstore_metadata.py"), "check"], cwd=ROOT,
                       capture_output=True, text=True)
    if r.returncode == 0:
        return []
    return [f"fiche|{l.strip()}" for l in r.stdout.splitlines() if l.strip()] or [f"fiche|code retour {r.returncode}"]


def check_temoins(langs: list[str]) -> list[str]:
    if not SENTINELS.exists():
        return ["temoins|sentinelles.json absent"]
    sentinels = _json(SENTINELS)["cles"]
    source = LOCALIZABLE.read_text(encoding="utf-8")
    out = []
    for lang in langs:
        ios, android = swift_table(SWIFT_CASE_BY_CODE[lang], source), android_table(lang)
        for key, by_lang in sentinels.items():
            expected = by_lang.get(lang)
            if expected is None:
                out.append(f"temoins|{lang}|{key}|pas de valeur attendue")
                continue
            for platform, table in (("ios", ios), ("android", android)):
                if key in table and table[key] != expected:
                    out.append(f"temoins|{lang}|{key}|{platform} : {table[key]!r} au lieu de {expected!r}")
    return out


RUN = {
    "cles": check_cles,
    "copies": check_copies,
    "validateur": lambda langs: _pool(_validate_lang, langs),
    "terminologie": lambda langs: _pool(_terms_lang, langs),
    "quiz": check_quiz,
    "fiche": check_fiche,
    "temoins": check_temoins,
}


# ------------------------------------------------------------------ main
def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--only", default="", help="vérifications à lancer, séparées par des virgules : " + ",".join(CHECKS))
    parser.add_argument("--lang", default="all", help="langues, séparées par des virgules (défaut : les 26)")
    parser.add_argument("--update-baseline", action="store_true",
                        help="enregistrer les constats actuels comme baseline (toutes langues, toutes vérifications)")
    parser.add_argument("--max-lines", type=int, default=60, help="nouveaux constats affichés par vérification")
    args = parser.parse_args()

    checks = [c.strip() for c in args.only.split(",") if c.strip()] or CHECKS
    unknown = [c for c in checks if c not in CHECKS]
    if unknown:
        parser.error(f"vérification inconnue : {', '.join(unknown)}")
    langs = NON_FR_LANGS if args.lang == "all" else [c.strip() for c in args.lang.split(",")]
    if args.update_baseline and (args.lang != "all" or set(checks) != set(CHECKS)):
        parser.error("--update-baseline réécrit tout le baseline : lancez-le sans --only ni --lang")

    baseline = _json(BASELINE) if BASELINE.exists() else {}
    failed, new_baseline = False, {}
    for check in checks:
        found = Counter(RUN[check](langs))
        if check in BASELINED:
            new_baseline[check] = dict(sorted(found.items()))
            known = Counter(baseline.get(check, {}))
            new = found - known
            fixed = sum((known - found).values()) if args.lang == "all" else 0
        else:
            new, fixed = found, 0
        status = "ÉCHEC" if new else "ok"
        extra = f", dont {sum(found.values()) - sum(new.values())} connus (baseline)" if check in BASELINED else ""
        print(f"{check:13s} {status:5s} {sum(found.values()):5d} constats{extra}"
              + (f", {fixed} corrigés depuis le baseline" if fixed else ""))
        for line in sorted(new.elements())[: args.max_lines]:
            print(f"    NOUVEAU {line.split('|', 1)[1]}")
        if sum(new.values()) > args.max_lines:
            print(f"    … et {sum(new.values()) - args.max_lines} autres")
        failed |= bool(new)

    if args.update_baseline:
        BASELINE.write_text(json.dumps(new_baseline, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")
        print(f"\nBaseline réécrit : {BASELINE.relative_to(ROOT)} "
              f"({sum(sum(v.values()) for v in new_baseline.values())} constats connus).")
        return 0
    if failed:
        print("\nLa porte refuse ce changement. Corrigez les constats NOUVEAU ci-dessus "
              "(voir docs/processus-traduction.md).")
        return 1
    print("\nPorte ouverte : aucune régression.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
