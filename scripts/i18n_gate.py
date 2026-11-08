#!/usr/bin/env python3
"""Porte de sortie des traductions : refuse tout ce qui ferait régresser une langue.

Lancée par la CI (.github/workflows/i18n-gate.yml) sur chaque push et chaque pull
request qui touche un texte affiché, et à lancer à la main avant de pousser :

    python3 scripts/i18n_gate.py                    # toutes les vérifications, 26 langues
    python3 scripts/i18n_gate.py --only cles,temoins
    python3 scripts/i18n_gate.py --update-baseline  # après avoir corrigé des constats
    python3 scripts/i18n_gate.py --update-baseline --accept-new  # cours restructuré seulement

Vérifications :

  cles          chaque clé d'interface française existe dans chaque langue (tables
                iOS d'AppLocalizable.swift, chaînes Android), avec les mêmes
                placeholders (%@, %d, {n}…) que le français, dans un ordre que
                String(format:) accepte ; pas de clé en double ; ui_strings.json
                identique à la table publiée.
  copies        chaque cours existe dans chaque langue, et la source (content/courses),
                le bundle iOS et la copie Android sont identiques ; glossaire,
                catalogue, collections et index Android présents et identiques des
                deux côtés ; aucun lien [[terme]] mort ; fichiers JSON lisibles.
  validateur    scripts/check_course_translation.py sur les 309 cours.
  terminologie  scripts/check_terminology.py (mots pièges, termes produit, titres).
  quiz          scripts/check_quiz_structure.py (structure et bonnes réponses).
  fiche         scripts/appstore_metadata.py check (longueurs de la fiche App Store).
  temoins       les chaînes témoins de content/terminology/sentinelles.json ont
                exactement la traduction attendue, sur iOS et sur Android.

Les constats de validateur, terminologie, quiz et copies qui existaient au moment où
la porte a été posée sont listés dans content/terminology/i18n_gate_baseline.json :
ils ne bloquent pas, seuls les nouveaux bloquent. Une correction fait baisser le
compte ; --update-baseline l'enregistre pour que la porte se resserre, et refuse
d'écrire tant qu'il reste des constats NOUVEAU. N'ajoutez pas un constat au baseline
pour faire passer un commit : corrigez-le, ou, si c'est un faux positif, corrigez la
règle. --accept-new ne sert qu'à un cours restructuré, dont les constats connus
changent d'emplacement.

Les faux positifs vérifiés un par un sont listés, avec leur raison, dans
content/terminology/exceptions.json : ils ne comptent plus du tout. Le baseline ne doit
garder que des défauts réels pas encore corrigés.

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
EXCEPTIONS = TERM_DIR / "exceptions.json"

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


def swift_entries(case: str, source: str) -> list[tuple[str, str]]:
    m = re.search(r"private static let %s: \[String: String\] = \[(.*?)\n    \]" % case, source, re.S)
    if not m:
        return []
    return [(_unescape(k), _unescape(v)) for k, v in
            re.findall(r'^\s*"((?:\\.|[^"\\])*)":\s*"((?:\\.|[^"\\])*)",?\s*$', m.group(1), re.M)]


def swift_table(case: str, source: str) -> dict[str, str]:
    return dict(swift_entries(case, source))


def android_table(lang: str) -> dict[str, str]:
    p = AND / "strings" / f"{lang}.json"
    data = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}
    return {k: v for k, v in data.items() if isinstance(v, str)}


def placeholders(s: str) -> list[str]:
    """For display: every placeholder, positions dropped, sorted."""
    return sorted(re.sub(r"^%\d+\$", "%", p) for p in PLACEHOLDER.findall(s))


def _arguments(s: str) -> dict[int, str]:
    """The format arguments of a string: argument number -> type. %2$@ names its argument;
    a bare %@ takes the next one in order, as String(format:) and String.format do."""
    args, nxt = {}, 0
    for p in re.findall(r"%(?:\d+\$)?(?:lld|ld|lu|lf|f|d|@|s)", s):
        m = re.match(r"%(\d+)\$(.*)", p)
        if m:
            n, kind = int(m.group(1)) - 1, m.group(2)
        else:
            n, kind = nxt, p[1:]
            nxt += 1
        args.setdefault(n, kind)
    return args


def same_placeholders(key: str, value: str, fr_value: str) -> bool:
    """Same named placeholders ({n}, {name}) and the same argument of the same type at each
    position: a language may reorder arguments only by numbering them (%2$@ %1$d), or
    String(format:) reads a number where it expects a string and the app crashes."""
    named = lambda s: sorted(p for p in PLACEHOLDER.findall(s) if p.startswith("{") and p not in OPTIONAL_PLACEHOLDERS)
    got, want = _arguments(value), _arguments(fr_value)
    if key.endswith((".one", ".two", ".zero")):
        # These forms may spell the number out ("one day", Arabic "يومان") instead of printing %d.
        return set(named(value)) <= set(named(fr_value)) and all(want.get(n) == t for n, t in got.items())
    return named(value) == named(fr_value) and got == want


PLURAL_FORMS = (".zero", ".two", ".few", ".many", ".other")
# Languages whose only plural category is "other" (CLDR): the French ".one" has no counterpart,
# and PluralStringsTest on Android rejects a ".one" variant that ICU would never select.
NO_ONE_FORM = {"ja"}


def _plural_reference(key: str, fr: dict[str, str]) -> str | None:
    """French has no ".few" or ".two": such a key is checked against French ".many"."""
    if key.endswith(PLURAL_FORMS):
        base = key.rsplit(".", 1)[0]
        for form in (".many", ".other"):
            if base + form in fr:
                return base + form
    return None


def check_cles(langs: list[str]) -> list[str]:
    source = LOCALIZABLE.read_text(encoding="utf-8")
    fr_ios, fr_and = swift_table("french", source), android_table("fr")
    out = []
    for lang in ["fr", *langs]:
        # A dictionary literal with a key twice stops the app at launch.
        for key, n in Counter(k for k, _ in swift_entries(SWIFT_CASE_BY_CODE[lang], source)).items():
            if n > 1:
                out.append(f"cles|{lang}|ios|{key}|clé en double ({n} fois)")
    for lang in langs:
        ios = swift_table(SWIFT_CASE_BY_CODE[lang], source)
        for platform, fr, cur in (("ios", fr_ios, ios), ("android", fr_and, android_table(lang))):
            for key, fr_value in fr.items():
                if key.startswith(UNTRANSLATED_PREFIXES):
                    continue
                if key not in cur and lang in NO_ONE_FORM and key.endswith(".one") and key[:-4] + ".other" in cur:
                    continue  # Japanese has a single plural category: ".one" would be unreachable
                if key not in cur:
                    out.append(f"cles|{lang}|{platform}|{key}|clé absente")
                elif not same_placeholders(key, cur[key], fr_value):
                    out.append(f"cles|{lang}|{platform}|{key}|placeholders {placeholders(cur[key])} ≠ français {placeholders(fr_value)}")
            for key in cur.keys() - fr.keys():
                ref = _plural_reference(key, fr)
                if ref and not same_placeholders(key, cur[key], fr[ref]):
                    out.append(f"cles|{lang}|{platform}|{key}|placeholders {placeholders(cur[key])} ≠ français {placeholders(fr[ref])} ({ref})")
        # content/locales/<lang>/ui_strings.json feeds translate_ui_strings.py: a stale copy
        # would put old machine text back over the shipped table.
        pack = ROOT / "content" / "locales" / lang / "ui_strings.json"
        if pack.exists():
            data = _json(pack)
            for key, value in ios.items():
                if data.get(key) != value:
                    out.append(f"cles|{lang}|ui_strings.json|{key}|≠ AppLocalizable.swift")
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


def _norm(term: str) -> str:
    return "".join(c for c in term.lower() if c.isalnum())


def _json(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def _duplicate_keys(p: Path) -> list[str]:
    dups = []

    def hook(pairs):
        seen = set()
        for k, _ in pairs:
            if k in seen:
                dups.append(k)
            seen.add(k)
        return dict(pairs)
    json.loads(p.read_text(encoding="utf-8"), object_pairs_hook=hook)
    return dups


def check_copies(langs: list[str]) -> list[str]:
    """La source (content/) est cohérente, et les packs de départ embarqués en sont des copies.

    Les catalogues ne vivent plus dans les bundles : les apps lisent le catalogue en ligne
    (docs/catalogue-en-ligne.md) et n'embarquent qu'un pack de départ par langue
    (catalogue complet + les 40 premiers cours du Parcours), généré par
    scripts/import_catalog_to_supabase.py. C'est ce pack qu'on compare à content/.
    """
    out = []
    # check_terminology reads these with a loader that turns a broken file into "nothing
    # to report": a broken file must fail here instead.
    for lang in ["fr", *langs]:
        for p in (ROOT / "content" / "locales" / lang / "quizzes_v2.json", ROOT / "content" / "locales" / lang / "legal.json",
                  ROOT / "content" / "locales" / lang / "ui_strings.json", AND / "strings" / f"{lang}.json", AND / "legal" / f"{lang}.json",
                  ROOT / "content" / "glossary" / f"{lang}.json", ROOT / "content" / "collections" / f"{lang}.json"):
            if p.exists():
                try:
                    _json(p)
                except ValueError as e:
                    out.append(f"copies|{lang}|{p.relative_to(ROOT)}|JSON illisible : {e}")
    fr_ids = sorted(p.stem for p in (COURSES / "fr").glob("*.json"))
    withheld_file = ROOT / "content" / "catalog_withheld.json"
    withheld_by_lang = {k: set(v) for k, v in (_json(withheld_file).get("by_language", {}) if withheld_file.exists() else {}).items()}
    structure_path = ROOT / "content" / "collections" / "collections.json"
    structure = {c["id"]: c for c in _json(structure_path)} if structure_path.exists() else {}
    if not structure:
        out.append("copies|fr|collections|content/collections/collections.json absent ou vide")
    for lang in ["fr", *langs]:
        # Glossaire et collections : une seule source, dans content/.
        gp = ROOT / "content" / "glossary" / f"{lang}.json"
        if not gp.exists():
            out.append(f"copies|{lang}|glossaire|content/glossary/{lang}.json absent")
        glossary = _json(gp) if gp.exists() else {}
        # Both apps fall back to a match that ignores case, spaces and punctuation
        # (GlossaryStore.normKey on iOS, GlossaryStore.normalize on Android).
        normalized = {f"{k.split('|', 1)[0]}|{_norm(k.split('|', 1)[1])}" for k in glossary if "|" in k}
        if gp.exists():
            # A duplicate key loads silently (the last one wins) and breaks every rewrite tool.
            out += [f"copies|{lang}|{gp.relative_to(ROOT)}|{k}|clé en double" for k in _duplicate_keys(gp)]
            for k in glossary:
                if "|" not in k or k.split("|", 1)[0] not in fr_ids:
                    out.append(f"copies|{lang}|glossaire|{k}|clé sans id de cours connu")
        cp = ROOT / "content" / "collections" / f"{lang}.json"
        if not cp.exists():
            out.append(f"copies|{lang}|collections|content/collections/{lang}.json absent")
        else:
            translated = {c["id"]: c for c in _json(cp)}
            for cid in sorted(set(structure) - set(translated)):
                out.append(f"copies|{lang}|collections|{cid}|collection sans traduction")
            for cid in sorted(set(translated) - set(structure)):
                out.append(f"copies|{lang}|collections|{cid}|traduction d'une collection inconnue")
        # Cours : chaque fichier source existe et ses liens de glossaire sont résolubles.
        for cid in fr_ids:
            src = COURSES / lang / f"{cid}.json"
            if not src.exists():
                # Un cours retenu dans cette langue (catalog_withheld.json) n'est pas distribué :
                # l'usine peut n'avoir rien écrit pour lui.
                if cid not in withheld_by_lang.get(lang, set()):
                    out.append(f"copies|{lang}|{cid}|cours absent")
                continue
            if gp.exists() and cid not in withheld_by_lang.get(lang, set()):
                for s_ in _strings(_json(src)):
                    for term in re.findall(r"\[\[(.+?)\]\]", s_):
                        if f"{cid}|{term}" not in glossary and f"{cid}|{_norm(term)}" not in normalized:
                            out.append(f"copies|{lang}|{cid}|lien mort [[{term}]]")
        # Packs de départ : identiques entre iOS et Android, et copies fidèles de content/.
        packs = {"ios": IOS / "StarterPack" / lang, "android": AND / "starter_pack" / lang}
        catalogs = {}
        for platform, folder in packs.items():
            cat = folder / "catalog.json"
            if not cat.is_file():
                out.append(f"copies|{lang}|pack|catalogue {platform} absent ({cat.relative_to(ROOT)})")
                continue
            catalogs[platform] = cat.read_bytes()
        if len(catalogs) == 2 and catalogs["ios"] != catalogs["android"]:
            out.append(f"copies|{lang}|pack|catalogue iOS ≠ Android")
        if "ios" in catalogs:
            catalog = json.loads(catalogs["ios"])
            expected = [cid for cid in fr_ids if (COURSES / lang / f"{cid}.json").exists() and cid not in withheld_by_lang.get(lang, set())]
            listed = {c["id"]: c for c in catalog.get("courses", [])}
            for cid in sorted(set(expected) ^ set(listed)):
                out.append(f"copies|{lang}|pack|{cid}|cours présent d'un seul côté du catalogue")
            for cid, entry in listed.items():
                src = COURSES / lang / f"{cid}.json"
                if not src.exists():
                    continue
                course = _json(src)
                if [(x.get("id"), x.get("title")) for x in entry.get("sections", [])] != \
                        [(x["id"], x["title"]) for x in course.get("sections", [])]:
                    out.append(f"copies|{lang}|pack|{cid}|sections du catalogue ≠ sections du cours")
                if entry.get("title") != course.get("title") or entry.get("subcategory", "") != course.get("subcategory", ""):
                    out.append(f"copies|{lang}|pack|{cid}|titre ou sous-catégorie ≠ source")
            if len(catalog.get("collections", [])) != len(structure) and structure:
                out.append(f"copies|{lang}|pack|collections : {len(catalog.get('collections', []))} dans le pack, {len(structure)} dans content/")
            for platform, folder in packs.items():
                courses_dir = folder / "courses"
                bundles = sorted(courses_dir.glob("*.json")) if courses_dir.is_dir() else []
                if not bundles:
                    out.append(f"copies|{lang}|pack|aucun cours de départ {platform}")
                for bundle_path in bundles:
                    bundle = _json(bundle_path)
                    src = COURSES / lang / f"{bundle_path.stem}.json"
                    if not src.exists():
                        out.append(f"copies|{lang}|pack|{bundle_path.stem}|cours de départ {platform} sans source")
                    elif bundle.get("content") != _json(src):
                        out.append(f"copies|{lang}|pack|{bundle_path.stem}|contenu du pack {platform} ≠ source")
    return out


# ------------------------------------------------------------------ outils existants
def _withheld(lang: str) -> set[str]:
    """Les cours que catalog_withheld.json retient dans cette langue : non distribués, donc hors
    des vérifications de traduction (l'usine les laisse en l'état jusqu'à une relance)."""
    path = ROOT / "content" / "catalog_withheld.json"
    data = _json(path) if path.exists() else {}
    return set((data.get("by_language") or {}).get(lang, []))


def _validate_lang(lang: str) -> list[str]:
    from check_course_translation import check_course
    from course_translation_io import glossary_keys_by_course
    allowed = glossary_keys_by_course(lang)
    withheld = _withheld(lang)
    out = []
    for p in sorted((COURSES / "fr").glob("*.json")):
        if p.stem in withheld:
            continue
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
    if "Traceback" in r.stderr or r.returncode not in (0, 1):
        # A crash must not read as "no finding".
        return [f"quiz|check_quiz_structure.py a planté (code {r.returncode}) : {r.stderr.strip().splitlines()[-1:] or ''}"]
    lines = [l.strip() for l in r.stdout.splitlines() if l.strip()]
    for l in lines:
        if l.startswith("skipped"):
            print(f"    (quiz : {l})")
    wanted = set(langs)
    return [f"quiz|{l}" for l in lines
            if not l.startswith(("FAILED", "OK", "All ", "Checked", "skipped", "quiz structure OK"))
            and l.split(" ", 1)[0] in wanted]


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
    fr = {**android_table("fr"), **swift_table("french", source)}
    for key, by_lang in sentinels.items():
        if fr.get(key) != by_lang.get("fr"):
            out.append(f"temoins|fr|{key}|le français a changé ({fr.get(key)!r} au lieu de {by_lang.get('fr')!r}) : "
                       "revoir la chaîne témoin dans les 26 langues")
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
    parser.add_argument("--accept-new", action="store_true",
                        help="avec --update-baseline : accepter aussi les constats NOUVEAU (à justifier dans le commit)")
    parser.add_argument("--max-lines", type=int, default=60, help="nouveaux constats affichés par vérification")
    args = parser.parse_args()

    checks = [c.strip() for c in args.only.split(",") if c.strip()] or CHECKS
    unknown = [c for c in checks if c not in CHECKS]
    if unknown:
        parser.error(f"vérification inconnue : {', '.join(unknown)}")
    langs = NON_FR_LANGS if args.lang == "all" else [c.strip() for c in args.lang.split(",")]
    bad = [l for l in langs if l not in NON_FR_LANGS]
    if bad:
        parser.error(f"langue inconnue : {', '.join(bad)} (langues : {', '.join(NON_FR_LANGS)})")
    if args.update_baseline and (args.lang != "all" or set(checks) != set(CHECKS)):
        parser.error("--update-baseline réécrit tout le baseline : lancez-le sans --only ni --lang")

    baseline = _json(BASELINE) if BASELINE.exists() else {}
    exceptions = _json(EXCEPTIONS)["constats"] if EXCEPTIONS.exists() else {}
    failed, new_baseline, grown = False, {}, 0
    for check in checks:
        found = Counter(RUN[check](langs))
        excused = sum(n for k, n in found.items() if k in exceptions)
        if args.lang == "all":
            stale = [k for k in exceptions if k.startswith(check + "|") and k not in found]
            if stale:
                print(f"    ({len(stale)} exceptions ne correspondent plus à aucun constat : à retirer de exceptions.json)")
        found = Counter({k: n for k, n in found.items() if k not in exceptions})
        if check in BASELINED:
            new_baseline[check] = dict(sorted(found.items()))
            known = Counter(baseline.get(check, {}))
            new = found - known
            grown += sum(new.values())
            fixed = sum((known - found).values()) if args.lang == "all" else 0
        else:
            new, fixed = found, 0
        status = "ÉCHEC" if new else "ok"
        extra = f", dont {sum(found.values()) - sum(new.values())} connus (baseline)" if check in BASELINED else ""
        print(f"{check:13s} {status:5s} {sum(found.values()):5d} constats{extra}"
              + (f", {fixed} corrigés depuis le baseline" if fixed else "")
              + (f", {excused} faux positifs justifiés (exceptions.json)" if excused else ""))
        for line in sorted(new.elements())[: args.max_lines]:
            print(f"    NOUVEAU {line.split('|', 1)[1]}")
        if sum(new.values()) > args.max_lines:
            print(f"    … et {sum(new.values()) - args.max_lines} autres")
        failed |= bool(new)

    if args.update_baseline:
        if grown and not args.accept_new:
            print(f"\nBaseline inchangé : {grown} constats NOUVEAU y entreraient. Corrigez-les, ou, si ce sont "
                  "des déplacements (cours restructuré) ou des faux positifs que la règle ne peut pas éviter, "
                  "relancez avec --accept-new et dites pourquoi dans le commit.")
            return 1
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
