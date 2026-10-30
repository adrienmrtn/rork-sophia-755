#!/usr/bin/env python3
"""Native post-editing of a language, surface by surface: packs for the editors, checks, write-back.

Surfaces (French always beside the current text):
  ui         every UI key (iOS table + Android-only keys), by key prefix in four lots
  cours      lesson bodies, four courses per lot (title, description, hook, sections…)
  quiz       questions, options, explanations, ten courses per lot
  glossaire  glossary definitions (the term itself is a key the lessons link to: unchanged)
  catalogue  collection titles and descriptions, library section labels
  legal      terms and privacy (iOS text with its Swift arrays, Android text)
  store      App Store product page

A pack lists, for each item: its id, the French, the current text, the audit
findings and terminology occurrences recorded for that spot (hints), and for
lessons the glossary keys the course may link to. Editors return only what they
change. ``apply`` checks every edit (placeholders, line breaks, bold and
[[glossary]] markers, numbers, length) and writes the accepted ones to every
copy: course source, iOS bundle and Android copy (identical files), catalogs
(title, description and lesson titles follow the lesson body, as in the edited
languages), quiz source and both catalogs, both glossaries, UI tables (iOS,
Android, content/locales/<lang>/ui_strings.json), store files.

Usage:
    python scripts/postedit_i18n.py packs --lang fi --out DIR
    python scripts/postedit_i18n.py apply --lang fi --from DIR [--dry-run]
    python scripts/postedit_i18n.py check --lang fi --file DIR/cours_000.json
    python scripts/postedit_i18n.py dump --lang fi course_100_les_fleurs_du_mal_baudelaire
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from course_translation_io import glossary_keys_by_course, segments
from i18n_copies import _DUMPERS, _style, _swift_escape, apply_mapping
from i18n_languages import SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "content" / "courses"
IOS = ROOT / "ios" / "Sophia" / "Resources"
AND = ROOT / "android" / "app" / "src" / "main" / "assets"
LOCALES = ROOT / "content" / "locales"
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
STORE = ROOT / "appstore" / "metadata"
STORE_LOCALE = {"en": "en-US", "es": "es-ES", "de": "de-DE", "pt": "pt-BR", "pt-PT": "pt-PT", "it": "it", "tr": "tr",
                "pl": "pl", "ro": "ro", "nl": "nl-NL", "el": "el", "sv": "sv", "hu": "hu", "cs": "cs", "da": "da",
                "nb": "no", "ru": "ru", "hr": "hr", "sl": "sl-SI", "sk": "sk", "ar": "ar-SA", "he": "he", "fi": "fi"}
STORE_FIELDS = {"name": 30, "subtitle": 30, "promotional_text": 170, "keywords": 100, "description": 4000, "whats_new": 4000}
UI_LOTS = [("ui1", ("onboardingV2.",)), ("ui2", ("onboarding.", "prepaywall.", "offer.", "discount.", "trial.", "purchase.")),
           ("ui3", ("paywall.",)), ("ui4", ())]
COURSES_PER_LOT, QUIZ_COURSES_PER_LOT, GLOSSARY_PER_LOT = 4, 10, 150

PLACEHOLDER = re.compile(r"%(?:\d+\$)?(?:lld|ld|lu|lf|f|d|@|s)|\{[a-zA-Z]+\}")
GLOSS = re.compile(r"\[\[(.+?)\]\]")
NUM = re.compile(r"\d+")
GROUP_SEP = re.compile(r"(?<=\d)[,.\u00a0\u202f ](?=\d{3}(?!\d))")


def _nums(s: str) -> set[str]:
    """Numbers in a text, thousands separators removed (1 000, 1,000, 1.000 → 1000)."""
    return set(NUM.findall(GROUP_SEP.sub("", s)))


def _load(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def _dump(p: Path, data, raw: str | None = None) -> None:
    raw = raw if raw is not None else p.read_text(encoding="utf-8")
    p.write_text(_DUMPERS[_style(raw, json.loads(raw))](data), encoding="utf-8")


# ------------------------------------------------------------------ UI tables
def swift_table(case: str, source: str | None = None) -> dict[str, str]:
    source = source if source is not None else LOCALIZABLE.read_text(encoding="utf-8")
    m = re.search(r"private static let %s: \[String: String\] = \[(.*?)\n    \]" % case, source, re.S)
    if not m:
        return {}
    out = {}
    for k, v in re.findall(r'^\s*"((?:\\.|[^"\\])*)":\s*"((?:\\.|[^"\\])*)",?\s*$', m.group(1), re.M):
        out[_unescape(k)] = _unescape(v)
    return out


def _unescape(s: str) -> str:
    def r(m):
        e = m.group(1)
        if e.startswith("u{"):
            return chr(int(e[2:-1], 16))
        return {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(e, e)
    return re.sub(r"\\(u\{[0-9A-Fa-f]+\}|.)", r, s)


def ui_items(lang: str) -> dict[str, dict]:
    fr = {**_load(AND / "strings" / "fr.json"), **swift_table("french")}
    cur = {**_load(AND / "strings" / f"{lang}.json"), **swift_table(SWIFT_CASE_BY_CODE[lang])}
    return {k: {"fr": fr.get(k), "texte": v} for k, v in cur.items() if isinstance(v, str) and k in fr}


# ------------------------------------------------------------------ hints
def hints(lang: str) -> dict[str, list[str]]:
    """Audit findings and terminology occurrences, keyed like the pack ids."""
    out: dict[str, list[str]] = defaultdict(list)
    audit = ROOT / "docs" / "audit-traductions" / f"{lang}.json"
    if audit.exists():
        for c in _load(audit).get("constats", []):
            loc = re.sub(r"^(ui|courses|cours):", "", c.get("location") or "")
            loc = loc.split(" ")[0].strip()
            out[loc].append(f"audit [{c.get('severity')}] {c.get('problem','')} — proposé : {c.get('fix','')}")
    occ = ROOT / "docs" / "audit-traductions" / "_terminologie_occurrences.json"
    if occ.exists():
        for h in _load(occ):
            if h["langue"] != lang:
                continue
            loc = h["emplacement"].split(":", 1)[-1] if h["emplacement"].startswith(("ios:", "android:")) else h["emplacement"]
            out[loc].append(f"terminologie : « {h['trouve']} » → attendu {h['attendu'][:120]}")
    return out


def _hint_for(h: dict, *keys: str) -> list[str]:
    seen, res = set(), []
    for k in keys:
        for x in h.get(k, []):
            if x not in seen:
                seen.add(x); res.append(x)
    return res[:6]


# ------------------------------------------------------------------ packs
def packs(lang: str, out: Path, courses: set[str] | None = None, keys: list[str] | None = None) -> dict[str, int]:
    """Every surface by default. With courses and/or keys, only those: the lessons, quizzes
    and glossary of these course ids, and the UI keys equal to one of keys (or starting with
    it when it ends in '*') -- the path for new content (docs/processus-traduction.md)."""
    out.mkdir(parents=True, exist_ok=True)
    scoped = courses is not None or keys is not None
    courses, keys = courses or set(), keys or []

    def wanted_key(k: str) -> bool:
        return any(k.startswith(x[:-1]) if x.endswith("*") else k == x for x in keys)
    h = hints(lang)
    counts: dict[str, int] = {}

    def write(name: str, header: str, items: list[dict]):
        lines = [header]
        for it in items:
            lines.append(f"\n### {it['id']}")
            if it.get("ctx"):
                lines.append(f"({it['ctx']})")
            lines.append(f"FR: {it['fr']}")
            lines.append(f"ACTUEL: {it['texte']}")
            for x in it.get("hints", []):
                lines.append(f"  ! {x}")
        (out / f"{name}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        counts[name] = len(items)

    # UI
    ui = ui_items(lang)
    taken = set()
    for name, prefixes in UI_LOTS:
        lot = sorted(k for k in ui if k not in taken and (not prefixes or k.startswith(prefixes)))
        taken.update(lot)
        if scoped:
            lot = [k for k in lot if wanted_key(k)]
            if not lot:
                continue
        items = [{"id": k, "fr": ui[k]["fr"].replace("\n", "⏎"), "texte": ui[k]["texte"].replace("\n", "⏎"),
                  "hints": _hint_for(h, k)} for k in lot]
        write(name, f"# Interface {lang} — lot {name} ({len(items)} clés). ⏎ = retour à la ligne.\n", items)

    # courses
    fr_dir = COURSES / "fr"
    all_ids = sorted(p.stem for p in fr_dir.glob("*.json"))
    ids = [c for c in all_ids if c in courses] if scoped else all_ids
    gloss = glossary_keys_by_course(lang)
    for i in range(0, len(ids), COURSES_PER_LOT):
        items = []
        for cid in ids[i:i + COURSES_PER_LOT]:
            fr = dict(segments(_load(fr_dir / f"{cid}.json")))
            cur = _load(COURSES / lang / f"{cid}.json")
            keys = ", ".join(f"[[{k}]]" for k in sorted(gloss.get(cid, [])))
            items.append({"id": f"{cid}", "fr": "—", "texte": "—", "ctx": f"COURS {cid} — termes de glossaire autorisés : {keys or 'aucun'}"})
            for key, text in segments(cur):
                items.append({"id": f"{cid}/{key}", "fr": fr.get(key, "∅"), "texte": text,
                              "hints": _hint_for(h, f"{cid}/{key}")})
        write(f"cours_{i // COURSES_PER_LOT:03d}", f"# Cours {lang} — lot {i // COURSES_PER_LOT:03d}\n", items)

    # quizzes
    frq = {q["courseId"]: {x["id"]: x for x in q["quiz"]} for q in _load(LOCALES / "fr" / "quizzes_v2.json")}
    cq = [e for e in _load(LOCALES / lang / "quizzes_v2.json") if not scoped or e["courseId"] in courses]
    for i in range(0, len(cq), QUIZ_COURSES_PER_LOT):
        items = []
        for entry in cq[i:i + QUIZ_COURSES_PER_LOT]:
            for q in entry["quiz"]:
                f = frq.get(entry["courseId"], {}).get(q["id"], {})
                for field in ("question", "explanation", "statement"):
                    if q.get(field):
                        items.append({"id": f"{q['id']}/{field}", "fr": f.get(field, "∅"), "texte": q[field], "hints": _hint_for(h, q["id"])})
                for j, o in enumerate(q.get("options") or []):
                    fo = (f.get("options") or [])
                    mark = " (bonne réponse)" if j == q.get("correctIndex") else ""
                    items.append({"id": f"{q['id']}/options/{j}", "fr": (fo[j] if j < len(fo) else "∅") + mark, "texte": o})
                for j, o in enumerate(q.get("items") or []):
                    fo = (f.get("items") or [])
                    items.append({"id": f"{q['id']}/items/{j}", "fr": fo[j] if j < len(fo) else "∅", "texte": o})
        write(f"quiz_{i // QUIZ_COURSES_PER_LOT:03d}", f"# Quiz {lang} — lot {i // QUIZ_COURSES_PER_LOT:03d}\n", items)

    # glossary definitions (FR found by course + classification order is unreliable: give the FR entries of the course)
    g = _load(IOS / "Locales" / f"glossary.{lang}.json")
    gfr = _load(AND / "locales" / "glossary.fr.json")
    fr_by_course = defaultdict(list)
    for k, v in gfr.items():
        fr_by_course[k.split("|", 1)[0]].append(f"{v['displayTerm']} : {v.get('explanation','')}")
    gkeys = sorted(k for k in g if not scoped or k.split("|", 1)[0] in courses)
    for i in range(0, len(gkeys), GLOSSARY_PER_LOT):
        items, last = [], None
        for k in gkeys[i:i + GLOSSARY_PER_LOT]:
            cid, term = k.split("|", 1)
            ctx = None
            if cid != last:
                ctx = "Définitions françaises du cours : " + " | ".join(fr_by_course.get(cid, []))[:3000]
                last = cid
            items.append({"id": k, "ctx": ctx, "fr": "(voir les définitions françaises du cours ci-dessus)",
                          "texte": f"[{term}] {g[k].get('explanation','')}", "hints": _hint_for(h, k)})
        write(f"glossaire_{i // GLOSSARY_PER_LOT:03d}", f"# Glossaire {lang} — lot {i // GLOSSARY_PER_LOT:03d}. Le terme entre crochets ne change pas : réécrire seulement la définition qui suit.\n", items)

    if scoped:
        return counts

    # catalogue: collections + library section labels
    cfr = {c["id"]: c for c in _load(AND / "locales" / "collections.fr.json")}
    items = []
    for c in _load(IOS / "Locales" / f"collections.{lang}.json"):
        for field in ("title", "description"):
            items.append({"id": f"collection:{c['id']}/{field}", "fr": cfr.get(c["id"], {}).get(field, "∅"), "texte": c.get(field, "")})
    seen = {}
    for cid in all_ids:
        f = _load(fr_dir / f"{cid}.json").get("subcategory")
        t = _load(COURSES / lang / f"{cid}.json").get("subcategory")
        if f and t and f not in seen:
            seen[f] = t
            items.append({"id": f"rubrique:{t}", "fr": f, "texte": t, "ctx": "libellé de rubrique de la bibliothèque (court)"})
    write("catalogue", f"# Collections et rubriques {lang}\n", items)

    # legal: terms and privacy, iOS text (Apple) and Android text (Google)
    items = []
    for plat, (fr_doc, cur_doc) in _legal_docs(lang).items():
        for doc in ("terms", "privacy"):
            for i, sec in enumerate(cur_doc.get(doc, [])):
                frs = (fr_doc.get(doc) or [])
                for field in ("title", "body"):
                    items.append({"id": f"{plat}:{doc}/{i}/{field}", "fr": frs[i][field] if i < len(frs) else "∅",
                                  "texte": sec[field].replace("\n", "⏎")})
    write("legal", f"# Conditions et confidentialité {lang} (ios = App Store, android = Google Play). ⏎ = retour à la ligne.\n", items)

    # store
    loc = STORE_LOCALE.get(lang)
    if loc and (STORE / loc).is_dir():
        items = []
        for field, limit in STORE_FIELDS.items():
            p, pf = STORE / loc / f"{field}.txt", STORE / "fr-FR" / f"{field}.txt"
            if p.exists():
                items.append({"id": f"store:{field}", "ctx": f"limite {limit} caractères", "fr": pf.read_text(encoding="utf-8") if pf.exists() else "∅",
                              "texte": p.read_text(encoding="utf-8")})
        write("store", f"# Fiche App Store {lang} ({loc})\n", items)
    return counts


def _legal_paths(lang: str) -> dict[str, Path]:
    return {"ios": LOCALES / lang / "legal.json", "android": AND / "legal" / f"{lang}.json"}


def _legal_swift(lang: str) -> dict:
    """iOS legal text as shipped: the Swift arrays (legal.json can lag behind them)."""
    from translate_legal_docs import LEGAL_SWIFT, SECTION_RE, SWIFT_PROP, _swift_unescape, extract_existing_swift_array
    swift = LEGAL_SWIFT.read_text(encoding="utf-8")
    prop = "French" if lang == "fr" else SWIFT_PROP[lang]
    return {doc: [{"id": _swift_unescape(a), "title": _swift_unescape(b), "body": _swift_unescape(c)}
                  for a, b, c in SECTION_RE.findall(extract_existing_swift_array(swift, f"{doc}{prop}") or "")]
            for doc in ("terms", "privacy")}


def _legal_docs(lang: str) -> dict[str, tuple[dict, dict]]:
    out = {"ios": (_legal_swift("fr"), _legal_swift(lang))}
    a_fr, a_cur = _legal_paths("fr")["android"], _legal_paths(lang)["android"]
    if a_cur.exists():
        out["android"] = (_load(a_fr), _load(a_cur))
    return out


def _legal_swift_block(prop: str, doc: str, sections: list[dict]) -> str:
    from translate_legal_docs import render_sections
    return f"private static let {doc}{prop}: [LegalSection] = [\n{render_sections(sections)}\n    ]\n"


def dump(lang: str, course_ids: list[str]) -> str:
    """One course at a time: its lesson segments, quiz items and glossary definitions, ids as apply expects."""
    quizzes = {q["courseId"]: q["quiz"] for q in _load(LOCALES / lang / "quizzes_v2.json")}
    gloss = _load(IOS / "Locales" / f"glossary.{lang}.json")
    out = []
    for cid in course_ids:
        p = COURSES / lang / f"{cid}.json"
        if not p.exists():
            continue
        out.append(f"## COURS {cid}")
        out.append("# fichier cours_*")
        for key, text in segments(_load(p)):
            out.append(f"### {cid}/{key}\n{text}")
        out.append("# fichier quiz_*")
        for q in quizzes.get(cid, []):
            for field in ("question", "explanation", "statement"):
                if q.get(field):
                    out.append(f"### {q['id']}/{field}\n{q[field]}")
            for field in ("options", "items"):
                for j, o in enumerate(q.get(field) or []):
                    out.append(f"### {q['id']}/{field}/{j}\n{o}")
        out.append("# fichier glossaire_* (texte = définition seule ; \"terme\" pour renommer)")
        for k, v in gloss.items():
            if k.startswith(cid + "|"):
                out.append(f"### {k}\n{v.get('explanation', '')}")
    return "\n".join(out)


# ------------------------------------------------------------------ checks
def _sig(s: str) -> list[str]:
    return sorted(PLACEHOLDER.findall(s))


def check_edit(kind: str, old: str, new: str, fr: str | None, allowed: set[str] | None = None) -> str | None:
    if not new or not new.strip():
        return "vide"
    if kind in ("ui", "quiz", "cours", "catalogue", "glossaire") and _sig(old) != _sig(new):
        return "placeholders"
    if kind == "ui" and old.count("\n") != new.count("\n") and (fr or "").count("\n") != new.count("\n"):
        return "retours à la ligne"
    if new.count("**") % 2:
        return "gras déséquilibré"
    if kind == "cours":
        terms = GLOSS.findall(new)
        if allowed is not None and any(t not in allowed for t in terms):
            return "terme de glossaire inconnu : " + ", ".join(t for t in terms if t not in allowed)[:80]
        if len(terms) < min(len(GLOSS.findall(old)), len(GLOSS.findall(fr or ""))):
            return "terme de glossaire perdu"
    nums_new = _nums(new)
    allowed_nums = _nums(old) | _nums(fr or "")
    # "100 ألف", "100 тыс." → 100000 is the same number written out
    allowed_nums |= {n + "000" for n in allowed_nums} | {n + "000000" for n in allowed_nums}
    extra = {n for n in nums_new - allowed_nums if len(n) >= 2}
    if extra:
        return "nombre nouveau : " + ", ".join(sorted(extra))[:40]
    ref = fr if fr and fr not in ("∅", "—") else old
    if len(ref) > 25 and not (0.4 <= len(new) / max(1, len(ref)) <= 2.6):
        return "longueur"
    return None


# ------------------------------------------------------------------ apply
def apply(lang: str, src: Path, dry_run: bool, only: Path | None = None) -> dict:
    report: dict = {"acceptes": Counter(), "rejetes": Counter(), "rejets": []}
    edits: dict[str, dict[str, str]] = defaultdict(dict)
    renames: dict[str, str] = {}
    for f in [only] if only else sorted(src.glob("*.json")):
        surface = f.stem.split("_")[0]
        surface = "ui" if surface.startswith("ui") else surface
        try:
            data = _load(f)
        except json.JSONDecodeError:
            report["rejetes"]["fichier illisible"] += 1
            continue
        for e in data.get("edits", []):
            if not (isinstance(e, dict) and isinstance(e.get("id"), str)):
                continue
            if surface == "glossaire" and isinstance(e.get("terme"), str):
                renames[e["id"]] = e["terme"].strip()
            if isinstance(e.get("texte"), str):
                edits[surface][e["id"]] = e["texte"].replace("⏎", "\n") if surface == "ui" else e["texte"]

    def reject(surface, ident, why):
        report["rejetes"][surface] += 1
        report["rejets"].append({"surface": surface, "id": ident, "raison": why})

    # --- UI
    if edits.get("ui"):
        ui = ui_items(lang)
        accepted = {}
        for k, v in edits["ui"].items():
            if k not in ui:
                reject("ui", k, "id inconnu"); continue
            if v == ui[k]["texte"]:
                continue
            why = check_edit("ui", ui[k]["texte"], v, ui[k]["fr"])
            if why:
                reject("ui", k, why); continue
            accepted[k] = v
        report["acceptes"]["ui"] = len(accepted)
        if accepted and not dry_run:
            _write_ui(lang, accepted)

    # --- courses
    if edits.get("cours"):
        gloss = glossary_keys_by_course(lang)
        by_course = defaultdict(dict)
        for ident, v in edits["cours"].items():
            if "/" in ident:
                cid, key = ident.split("/", 1)
                by_course[cid][key] = v
        n = 0
        for cid, changes in by_course.items():
            p = COURSES / lang / f"{cid}.json"
            if not p.exists():
                continue
            raw = p.read_text(encoding="utf-8")
            course = json.loads(raw)
            fr = dict(segments(_load(COURSES / "fr" / f"{cid}.json")))
            cur = dict(segments(course))
            ok = {}
            for key, v in changes.items():
                if key not in cur:
                    reject("cours", f"{cid}/{key}", "id inconnu"); continue
                if v == cur[key]:
                    continue
                why = check_edit("cours", cur[key], v, fr.get(key), set(gloss.get(cid, [])))
                if why:
                    reject("cours", f"{cid}/{key}", why); continue
                ok[key] = v
            if not ok:
                continue
            n += len(ok)
            _set_segments(course, ok)
            if not dry_run:
                p.write_text(_DUMPERS["indent2"](course), encoding="utf-8")
                for copy in (IOS / "CoursesV2" / f"{cid}.{lang}.json", AND / "courses_v2" / lang / f"{cid}.json"):
                    if copy.exists():
                        copy.write_text(_DUMPERS["min_sorted"](course), encoding="utf-8")
        report["acceptes"]["cours"] = n

    # --- quizzes
    if edits.get("quiz"):
        frq = {x["id"]: x for q in _load(LOCALES / "fr" / "quizzes_v2.json") for x in q["quiz"]}
        files = [LOCALES / lang / "quizzes_v2.json", IOS / "Locales" / f"courses.{lang}.json", AND / "locales" / f"courses.{lang}.json"]
        raws = {f: f.read_text(encoding="utf-8") for f in files}
        datas = {f: json.loads(r) for f, r in raws.items()}
        index = {}
        for q in (x for e in datas[files[0]] for x in e["quiz"]):
            index[q["id"]] = q
        accepted = {}
        for ident, v in edits["quiz"].items():
            parts = ident.split("/")
            q = index.get(parts[0])
            if not q or len(parts) not in (2, 3):
                reject("quiz", ident, "id inconnu"); continue
            if len(parts) == 2:
                old, frv = q.get(parts[1]), frq.get(parts[0], {}).get(parts[1])
            else:
                lst, j = q.get(parts[1]) or [], int(parts[2])
                if j >= len(lst):
                    continue
                old = lst[j]
                frl = frq.get(parts[0], {}).get(parts[1]) or []
                frv = frl[j] if j < len(frl) else None
            if not isinstance(old, str) or v == old:
                continue
            why = check_edit("quiz", old, v, frv)
            if why:
                reject("quiz", ident, why); continue
            accepted[ident] = v
        for f, data in datas.items():
            quizzes = (x for e in data for x in e["quiz"]) if f == files[0] else (x for c in data for x in c.get("quiz") or [])
            for q in quizzes:
                for ident, v in accepted.items():
                    parts = ident.split("/")
                    if parts[0] != q["id"]:
                        continue
                    if len(parts) == 2:
                        q[parts[1]] = v
                    else:
                        q[parts[1]][int(parts[2])] = v
            if accepted and not dry_run:
                _dump(f, data, raws[f])
        report["acceptes"]["quiz"] = len(accepted)

    # --- glossary definitions
    if edits.get("glossaire"):
        files = [IOS / "Locales" / f"glossary.{lang}.json", AND / "locales" / f"glossary.{lang}.json"]
        raws = {f: f.read_text(encoding="utf-8") for f in files}
        datas = {f: json.loads(r) for f, r in raws.items()}
        g = datas[files[0]]
        accepted = {}
        for k, v in edits["glossaire"].items():
            if k not in g:
                reject("glossaire", k, "id inconnu"); continue
            v = re.sub(r"^\[[^\]]*\]\s*", "", v)
            old = g[k].get("explanation", "")
            if v == old:
                continue
            why = check_edit("glossaire", old, v, None)
            if why:
                reject("glossaire", k, why); continue
            accepted[k] = v
        for f, data in datas.items():
            for k, v in accepted.items():
                if k in data:
                    data[k]["explanation"] = v
            if accepted and not dry_run:
                _dump(f, data, raws[f])
        report["acceptes"]["glossaire"] = len(accepted)

    # --- glossary terms renamed: key, displayTerm and every [[term]] of the course (all copies)
    if renames:
        files = [IOS / "Locales" / f"glossary.{lang}.json", AND / "locales" / f"glossary.{lang}.json"]
        raws = {f: f.read_text(encoding="utf-8") for f in files}
        datas = {f: json.loads(r) for f, r in raws.items()}
        g = datas[files[0]]
        taken = set(g)
        by_course: dict[str, dict[str, str]] = defaultdict(dict)
        for k, new in renames.items():
            if k not in g or "|" not in k:
                continue
            cid, old = k.split("|", 1)
            if not new or new == old:
                continue
            if any(x in new for x in ("[[", "]]", "|", "\n", "**")) or len(new) > 120:
                reject("glossaire", k, "terme invalide"); continue
            if f"{cid}|{new}" in taken:
                reject("glossaire", k, "terme déjà pris dans ce cours"); continue
            if not (COURSES / lang / f"{cid}.json").exists():
                continue
            taken.discard(k); taken.add(f"{cid}|{new}")
            by_course[cid][old] = new
        for f, data in datas.items():
            out = {}
            for k, v in data.items():
                cid, _, term = k.partition("|")
                new = by_course.get(cid, {}).get(term)
                if new:
                    v = dict(v, displayTerm=new)
                    k = f"{cid}|{new}"
                out[k] = v
            if by_course and not dry_run:
                _dump(f, out, raws[f])
        for cid, ren in by_course.items():
            p = COURSES / lang / f"{cid}.json"
            course = _load(p)
            pat = re.compile(r"\[\[(" + "|".join(re.escape(t) for t in sorted(ren, key=len, reverse=True)) + r")\]\]")
            course = _map_strings(course, lambda s: pat.sub(lambda m: f"[[{ren[m.group(1)]}]]", s))
            if not dry_run:
                p.write_text(_DUMPERS["indent2"](course), encoding="utf-8")
                for copy in (IOS / "CoursesV2" / f"{cid}.{lang}.json", AND / "courses_v2" / lang / f"{cid}.json"):
                    if copy.exists():
                        copy.write_text(_DUMPERS["min_sorted"](course), encoding="utf-8")
        report["acceptes"]["termes"] = sum(len(r) for r in by_course.values())

    # --- collections + section labels
    if edits.get("catalogue"):
        files = [IOS / "Locales" / f"collections.{lang}.json", AND / "locales" / f"collections.{lang}.json"]
        raws = {f: f.read_text(encoding="utf-8") for f in files}
        datas = {f: json.loads(r) for f, r in raws.items()}
        labels = {}
        n = 0
        for ident, v in edits["catalogue"].items():
            if ident.startswith("collection:"):
                cid, field = ident[len("collection:"):].split("/")
                cur = next((c for c in datas[files[0]] if c["id"] == cid), None)
                if cur is None or cur.get(field) == v:
                    continue
                why = check_edit("catalogue", cur.get(field, ""), v, None)
                if why:
                    reject("catalogue", ident, why); continue
                n += 1
                for data in datas.values():
                    for c in data:
                        if c["id"] == cid:
                            c[field] = v
            elif ident.startswith("rubrique:"):
                old = ident[len("rubrique:"):]
                if v and v != old and len(v) <= 60:
                    labels[old] = v
        if not dry_run:
            for f, data in datas.items():
                _dump(f, data, raws[f])
            if labels:
                apply_mapping(lang, labels)
        report["acceptes"]["catalogue"] = n + len(labels)

    # --- legal: content/locales/<lang>/legal.json + Swift arrays (iOS), assets/legal/<lang>.json (Android)
    if edits.get("legal"):
        docs = _legal_docs(lang)
        changed = set()
        n = 0
        for ident, v in edits["legal"].items():
            m = re.fullmatch(r"(ios|android):(terms|privacy)/(\d+)/(title|body)", ident)
            if not m or m.group(1) not in docs:
                reject("legal", ident, "id inconnu"); continue
            plat, doc, i, field = m.group(1), m.group(2), int(m.group(3)), m.group(4)
            fr_doc, cur_doc = docs[plat]
            secs = cur_doc.get(doc) or []
            if i >= len(secs):
                reject("legal", ident, "id inconnu"); continue
            v = v.replace("⏎", "\n")
            old = secs[i][field]
            if v == old:
                continue
            frs = fr_doc.get(doc) or []
            why = check_edit("legal", old, v, frs[i][field] if i < len(frs) else None)
            if why:
                reject("legal", ident, why); continue
            secs[i][field] = v
            changed.add(plat)
            n += 1
        if not dry_run:
            paths = _legal_paths(lang)
            for plat in changed:
                raw = paths[plat].read_text(encoding="utf-8") if paths[plat].exists() else None
                _dump(paths[plat], docs[plat][1], raw)
            if "ios" in changed:
                from translate_legal_docs import LEGAL_SWIFT, SWIFT_PROP, extract_existing_swift_array
                swift = LEGAL_SWIFT.read_text(encoding="utf-8")
                prop = SWIFT_PROP[lang]
                for doc in ("terms", "privacy"):
                    old_block = extract_existing_swift_array(swift, f"{doc}{prop}")
                    swift = swift.replace(old_block, _legal_swift_block(prop, doc, docs["ios"][1][doc]), 1)
                LEGAL_SWIFT.write_text(swift, encoding="utf-8")
        report["acceptes"]["legal"] = n

    # --- store
    if edits.get("store"):
        loc = STORE_LOCALE.get(lang)
        n = 0
        for ident, v in edits["store"].items():
            field = ident.split(":", 1)[-1]
            p = STORE / (loc or "") / f"{field}.txt"
            if field not in STORE_FIELDS or not p.exists():
                continue
            if len(v) > STORE_FIELDS[field]:
                reject("store", ident, f"trop long ({len(v)} > {STORE_FIELDS[field]})"); continue
            if v != p.read_text(encoding="utf-8"):
                n += 1
                if not dry_run:
                    p.write_text(v, encoding="utf-8")
        report["acceptes"]["store"] = n

    # --- catalog cards follow the lesson body (title, description, lesson titles)
    if not dry_run:
        report["catalogue_aligne"] = sync_catalog(lang)
    return report


def _map_strings(node, fn):
    if isinstance(node, str):
        return fn(node)
    if isinstance(node, list):
        return [_map_strings(x, fn) for x in node]
    if isinstance(node, dict):
        return {k: _map_strings(v, fn) for k, v in node.items()}
    return node


def _set_segments(course: dict, changes: dict[str, str]) -> None:
    def put(key, container, field):
        if key in changes and isinstance(container.get(field), str):
            container[field] = changes[key]
    put("title", course, "title"); put("subtitle", course, "subtitle"); put("description", course, "description")
    if isinstance(course.get("hero"), dict):
        put("hero.hook", course["hero"], "hook")
    for si, s in enumerate(course.get("sections") or []):
        put(f"s{si}.title", s, "title")
        for bi, b in enumerate(s.get("blocks") or []):
            pre = f"s{si}.b{bi}"
            for fld in ("text", "caption", "attribution"):
                put(f"{pre}.{fld}", b, fld)
            for ei, ev in enumerate(b.get("events") or []):
                for fld in ("date", "title", "detail"):
                    put(f"{pre}.e{ei}.{fld}", ev, fld)


def sync_catalog(lang: str) -> int:
    """Course cards and lesson lists take the title, description and section titles of the lesson body."""
    changed = 0
    for f in (IOS / "Locales" / f"courses.{lang}.json", AND / "locales" / f"courses.{lang}.json", AND / "locales" / f"course_index.{lang}.json"):
        if not f.exists():
            continue
        raw = f.read_text(encoding="utf-8")
        data = json.loads(raw)
        for c in data:
            p = COURSES / lang / f"{c['id']}.json"
            if not p.exists():
                continue
            body = _load(p)
            for field in ("title", "description"):
                if field in c and body.get(field) and c[field] != body[field]:
                    c[field] = body[field]; changed += 1
            if c.get("lessons") and len(c["lessons"]) == len(body.get("sections") or []):
                for lesson, section in zip(c["lessons"], body["sections"]):
                    if section.get("title") and lesson.get("title") != section["title"]:
                        lesson["title"] = section["title"]; changed += 1
        _dump(f, data, raw)
    return changed


def _write_ui(lang: str, accepted: dict[str, str]) -> None:
    for f in (AND / "strings" / f"{lang}.json", LOCALES / lang / "ui_strings.json"):
        if not f.exists():
            continue
        raw = f.read_text(encoding="utf-8")
        data = json.loads(raw)
        for k, v in accepted.items():
            if k in data:
                data[k] = v
        _dump(f, data, raw)
    source = LOCALIZABLE.read_text(encoding="utf-8")
    case = SWIFT_CASE_BY_CODE[lang]
    m = re.search(r"private static let %s: \[String: String\] = \[(.*?)\n    \]" % case, source, re.S)
    body = m.group(1)
    for k, v in accepted.items():
        body = re.sub(r'^(\s*"%s":\s*)"(?:\\.|[^"\\])*"' % re.escape(_swift_escape(k)),
                      lambda mm: mm.group(1) + '"' + _swift_escape(v) + '"', body, count=1, flags=re.M)
    LOCALIZABLE.write_text(source[: m.start(1)] + body + source[m.end(1):], encoding="utf-8")


def termsheet(lang: str) -> str:
    """The imposed terminology of one language, from content/terminology, as the editors read it."""
    tdir = ROOT / "content" / "terminology"
    out = [f"# Terminologie imposée pour {lang} (content/terminology)", "",
           "## Termes produit (un seul terme partout dans l'interface)"]
    for t in _load(tdir / "termes_produit.json")["termes"]:
        x = t["par_langue"].get(lang)
        if x:
            out.append(f"- {t['fr']} → **{x['canon']}**" + (f" — {x['note']}" if x.get("note") else ""))
    out += ["", "## Mots pièges (sens voulu → forme imposée ; jamais le faux sens)"]
    for t in _load(tdir / "mots_pieges.json")["entrees"]:
        x = t["par_langue"].get(lang)
        if x and x.get("forme_imposee"):
            wrong = f" (faux sens observés : {t['faux_sens_observes']})" if t.get("faux_sens_observes") else ""
            out.append(f"- {t['fr']}{wrong} → **{x['forme_imposee']}**")
    out += ["", "## Titres d'œuvres (titre sous lequel l'œuvre est connue)"]
    for t in _load(tdir / "oeuvres.json")["oeuvres"]:
        x = t["par_langue"].get(lang)
        if x and x.get("titre"):
            out.append(f"- {t['titre_fr']} ({t.get('auteur', '')}) → *{x['titre']}* [{x.get('statut', '')}]")
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("packs"); a.add_argument("--lang", required=True); a.add_argument("--out", type=Path, required=True)
    a.add_argument("--courses", nargs="+", help="only these course ids (lessons, quizzes, glossary)")
    a.add_argument("--keys", nargs="+", help="only these UI keys; a trailing * matches a prefix")
    b = sub.add_parser("apply"); b.add_argument("--lang", required=True); b.add_argument("--from", dest="src", type=Path, required=True)
    b.add_argument("--dry-run", action="store_true"); b.add_argument("--report", type=Path)
    d = sub.add_parser("dump", help="every editable item of some courses (body, quiz, glossary), with ids")
    d.add_argument("--lang", required=True); d.add_argument("courses", nargs="+")
    t = sub.add_parser("termsheet", help="the imposed terminology of one language, as markdown")
    t.add_argument("--lang", required=True); t.add_argument("--out", type=Path, required=True)
    c = sub.add_parser("check", help="dry run of one output file, one line per rejected edit")
    c.add_argument("--lang", required=True); c.add_argument("--file", type=Path, required=True)
    args = ap.parse_args()
    if args.cmd == "dump":
        print(dump(args.lang, args.courses))
        return 0
    if args.cmd == "termsheet":
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(termsheet(args.lang), encoding="utf-8")
        return 0
    if args.cmd == "check":
        rep = apply(args.lang, args.file.parent, True, only=args.file)
        for r in rep["rejets"]:
            print(f"REJET {r['id']} : {r['raison']}")
        print("acceptés", dict(rep["acceptes"]), "rejetés", sum(rep["rejetes"].values()))
        return 0
    if args.cmd == "packs":
        scope = (set(args.courses) if args.courses else None, args.keys)
        print(json.dumps(packs(args.lang, args.out, *scope), ensure_ascii=False))
        return 0
    rep = apply(args.lang, args.src, args.dry_run)
    print(args.lang, "acceptés", dict(rep["acceptes"]), "rejetés", dict(rep["rejetes"]), "catalogue aligné", rep.get("catalogue_aligne"))
    if args.report:
        args.report.write_text(json.dumps({**rep, "acceptes": dict(rep["acceptes"]), "rejetes": dict(rep["rejetes"])}, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
