#!/usr/bin/env python3
"""Traduction des questions de duel dans les 29 autres langues de l'app.

    python3 scripts/duels_i18n.py packs  --work DIR [--parts 3]
    python3 scripts/duels_i18n.py check  --work DIR --lang ja --part 1 [--parts 3]
    python3 scripts/duels_i18n.py merge  --work DIR [--parts 3]
    python3 scripts/duels_i18n.py status

L'anglais (content/duels/questions_en.json) reste la référence : une question garde son
identifiant, son type, sa bonne réponse (même rang d'option), ses bornes et sa valeur dans
toutes les langues. Seuls changent le texte de la question, celui des options et l'unité du
curseur. C'est ce qui permet à deux joueurs de langues différentes de jouer la même partie.

  packs  écrit DIR/packs/partN.md : les questions à traduire, en lots, communs à toutes les langues
  check  contrôle les fichiers d'un traducteur (DIR/out/<lang>/part<N>*.json, réunis) (ids, nombre d'options, options distinctes,
         nombres conservés, écriture attendue) ; une ligne « REJET » par défaut bloquant
  merge  réunit DIR/out/<lang>/part*.json dans content/duels/i18n/<lang>.json
  status ce qui manque, langue par langue

Les questions intraduisibles (étymologie d'un mot anglais, jeu sur l'orthographe anglaise…)
sont dans content/duels/i18n/_excluded.json : elles ne sont ni traduites ni tirées, pour
personne, afin que tous les joueurs piochent dans le même vivier.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QUESTIONS = ROOT / "content" / "duels" / "questions_en.json"
I18N = ROOT / "content" / "duels" / "i18n"
EXCLUDED = I18N / "_excluded.json"

LANGS = ["fr", "es", "de", "pt", "pt-PT", "it", "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs",
         "da", "nb", "ru", "hr", "sl", "sk", "sr", "ar", "he", "fi", "et", "lt", "lv", "ja"]

# Unités que l'app affiche telles quelles ou pas du tout (« year » : l'app n'écrit que le nombre).
FIXED_UNITS = {None, "", "year", "%", "°C", "m/s", "min"}

# Écriture attendue : une option ou une question entièrement en alphabet latin est suspecte
# dans ces langues (un nom propre doit y être transcrit).
SCRIPT = {
    "ru": "CYRILLIC", "bg": "CYRILLIC", "el": "GREEK", "ar": "ARABIC", "he": "HEBREW",
    "ja": ("CJK", "HIRAGANA", "KATAKANA"),
}


LEAGUE_SLUGS = ["aesop", "homer", "sappho", "confucius", "socrates", "cleopatra", "hypatia", "avicenna", "murasaki",
                "mansa_musa", "dante", "joan_of_arc", "gutenberg", "leonardo", "michelangelo", "copernicus",
                "shakespeare", "galileo", "vermeer", "newton", "mozart", "napoleon", "austen", "darwin", "lovelace",
                "van_gogh", "curie", "einstein", "kahlo", "sophia"]


def load_questions() -> list[dict]:
    return json.loads(QUESTIONS.read_text(encoding="utf-8"))


def excluded_ids() -> set[str]:
    if not EXCLUDED.exists():
        return set()
    return {x["id"] for x in json.loads(EXCLUDED.read_text(encoding="utf-8"))["questions"]}


def to_translate() -> list[dict]:
    skip = excluded_ids()
    return [q for q in load_questions() if q["id"] not in skip]


def split(items: list, parts: int) -> list[list]:
    size = -(-len(items) // parts)
    return [items[i * size:(i + 1) * size] for i in range(parts)]


def unit_needs_translation(q: dict) -> bool:
    return q["kind"] == "slider" and q.get("unit") not in FIXED_UNITS


# ------------------------------------------------------------------ packs
def render(q: dict) -> str:
    lines = [f"### {q['id']} · {q['kind']} · {q['subject']}"]
    if q["kind"] == "portrait":
        lines.append("(image question: the player sees a picture — portrait, flag, painting, monument — "
                     "and picks what it shows)")
    lines.append(f"Q: {q['question']}")
    if q["kind"] in ("mcq", "portrait"):
        opts = [o + (" ✓" if i == q["correct_index"] else "") for i, o in enumerate(q["options"])]
        lines.append("O: " + " | ".join(opts))
    elif q["kind"] == "true_false":
        lines.append(f"A: {'True' if q['correct_index'] == 0 else 'False'}")
    elif q["kind"] == "slider":
        lines.append(f"A: {q['correct_value']:g} (slider {q['slider_min']:g}–{q['slider_max']:g})"
                     + (f" · unit: {q['unit']}" if q.get("unit") else ""))
    return "\n".join(lines)


def cmd_packs(work: Path, parts: int) -> None:
    out = work / "packs"
    out.mkdir(parents=True, exist_ok=True)
    for n, chunk in enumerate(split(to_translate(), parts), start=1):
        (out / f"part{n}.md").write_text("\n\n".join(render(q) for q in chunk) + "\n", encoding="utf-8")
        print(f"part{n}: {len(chunk)} questions ({chunk[0]['id']} … {chunk[-1]['id']})")


# ------------------------------------------------------------------ check
def load_part(work: Path, lang: str, part: int) -> dict:
    """Réunit les fichiers d'un lot : part1.json, ou part1-a.json, part1-b.json…"""
    out = {"items": {}, "untranslatable": [], "true_false": None, "leagues": None}
    files = sorted((work / "out" / lang).glob(f"part{part}.json")) + sorted((work / "out" / lang).glob(f"part{part}-*.json"))
    if not files:
        raise FileNotFoundError(f"aucun fichier part{part}*.json pour {lang}")
    for f in files:
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception as e:  # noqa: BLE001
            raise ValueError(f"{f.name} : JSON illisible ({e})") from e
        out["items"].update(d.get("items") or {})
        out["untranslatable"] += d.get("untranslatable") or []
        out["true_false"] = out["true_false"] or d.get("true_false")
        out["leagues"] = out["leagues"] or d.get("leagues")
    return out


NUM = re.compile(r"\d[\d,.   ]*\d|\d")


def numbers(text: str) -> set[str]:
    return {re.sub(r"[,.   ]", "", m) for m in NUM.findall(text)}


def script_ok(text: str, lang: str) -> bool:
    want = SCRIPT.get(lang)
    if not want:
        return True
    wants = want if isinstance(want, tuple) else (want,)
    letters = [c for c in text if c.isalpha()]
    if not letters:
        return True
    return any(any(w in unicodedata.name(c, "") for w in wants) for c in letters)


def check(lang: str, data: dict, expected: list[dict]) -> tuple[list[str], list[str]]:
    """(rejets, avertissements). Un rejet bloque la fusion ; un avertissement est à relire."""
    rejects, warns = [], []
    items = data.get("items")
    if not isinstance(items, dict):
        return ["fichier : il faut {\"items\": {id: {...}}}"], []
    by_id = {q["id"]: q for q in expected}
    retired = excluded_ids()
    for qid in items:
        if qid not in by_id and qid not in retired:
            rejects.append(f"REJET {qid} : identifiant inconnu dans ce lot")
    flagged = {f.get("id") for f in data.get("untranslatable", []) if isinstance(f, dict)}
    for qid, q in by_id.items():
        t = items.get(qid)
        if t is None:
            if qid not in flagged:
                rejects.append(f"REJET {qid} : manquante (ni traduite ni signalée intraduisible)")
            continue
        text = (t.get("q") or "").strip()
        if not text:
            rejects.append(f"REJET {qid} : question vide")
            continue
        if q["kind"] in ("mcq", "portrait"):
            opts = t.get("o")
            if not isinstance(opts, list) or len(opts) != len(q["options"]):
                rejects.append(f"REJET {qid} : il faut {len(q['options'])} options, dans l'ordre de l'anglais")
                continue
            if any(not isinstance(o, str) or not o.strip() for o in opts):
                rejects.append(f"REJET {qid} : option vide")
                continue
            if len({o.strip().casefold() for o in opts}) != len(opts):
                rejects.append(f"REJET {qid} : deux options identiques")
            for o, src in zip(opts, q["options"]):
                if not script_ok(o, lang) and o.strip() != src.strip() and not re.fullmatch(r"[\dA-Z .,%–-]+", o):
                    warns.append(f"AVERT {qid} : option en alphabet latin « {o} »")
        elif "o" in t:
            rejects.append(f"REJET {qid} : pas d'options pour un {q['kind']}")
        if unit_needs_translation(q) and not (t.get("u") or "").strip():
            rejects.append(f"REJET {qid} : unité « {q['unit']} » à traduire (champ u)")
        if not script_ok(text, lang):
            rejects.append(f"REJET {qid} : question pas dans l'écriture de la langue")
        src_nums = {n for n in numbers(q["question"]) if len(n) >= 2}
        missing = src_nums - numbers(text)
        if missing and lang != "ja":
            warns.append(f"AVERT {qid} : nombre(s) {sorted(missing)} absent(s) de la traduction")
    return rejects, warns


def expected_part(part: int | None, parts: int, work: Path | None = None) -> list[dict]:
    """Les questions d'un lot. Si DIR/packs/partN.md existe, le lot est celui qu'il contient
    (moins les questions retirées depuis) : retirer une question ne décale pas les lots."""
    qs = to_translate()
    if not part:
        return qs
    pack = work / "packs" / f"part{part}.md" if work else None
    if pack and pack.exists():
        ids = set(re.findall(r"^### (dq_en_\d+_\d+) ", pack.read_text(encoding="utf-8"), re.M))
        return [q for q in qs if q["id"] in ids]
    return split(qs, parts)[part - 1]


def cmd_check(work: Path, lang: str, part: int, parts: int) -> int:
    try:
        data = load_part(work, lang, part)
    except (FileNotFoundError, ValueError) as e:
        print(f"REJET {e}")
        return 1
    rejects, warns = check(lang, data, expected_part(part, parts, work))
    if part == 1:
        tf = data.get("true_false")
        if not (isinstance(tf, list) and len(tf) == 2 and all(isinstance(x, str) and x.strip() for x in tf)):
            rejects.append("REJET true_false : il faut [\"<True>\", \"<False>\"] dans la langue")
        lg = data.get("leagues")
        missing = [slug for slug in LEAGUE_SLUGS if not (isinstance(lg, dict) and str(lg.get(slug, "")).strip())]
        if missing:
            rejects.append(f"REJET leagues : noms manquants {missing}")
    for line in rejects + warns:
        print(line)
    print(f"{lang} part{part} : {len(data['items'])} traduites, {len(data['untranslatable'])} signalées, "
          f"{len(rejects)} rejet(s), {len(warns)} avertissement(s)")
    return 1 if rejects else 0


# ------------------------------------------------------------------ merge / status
def cmd_merge(work: Path, parts: int) -> None:
    I18N.mkdir(parents=True, exist_ok=True)
    for lang in LANGS:
        try:
            loaded = [load_part(work, lang, n) for n in range(1, parts + 1)]
        except (FileNotFoundError, ValueError) as e:
            print(f"{lang} : incomplet ({e}), ignoré")
            continue
        items, flags = {}, []
        for d in loaded:
            items.update(d["items"])
            flags += d["untranslatable"]
        payload = {"lang": lang, "true_false": loaded[0]["true_false"], "leagues": loaded[0]["leagues"],
                   "items": dict(sorted(items.items(), key=lambda kv: order_key(kv[0]))),
                   "untranslatable": flags}
        (I18N / f"{lang}.json").write_text(json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(f"{lang} : {len(items)} questions, {len(flags)} signalées")


def order_key(qid: str) -> tuple[int, int]:
    _, _, level, n = qid.split("_")
    return int(level), int(n)


def cmd_status() -> int:
    qs = to_translate()
    bad = 0
    for lang in LANGS:
        f = I18N / f"{lang}.json"
        if not f.exists():
            print(f"{lang} : absent")
            bad += 1
            continue
        d = json.loads(f.read_text(encoding="utf-8"))
        rejects, warns = check(lang, d, qs)
        missing = [q["id"] for q in qs if q["id"] not in d["items"]]
        extra = []
        if not d.get("true_false") or len(d["true_false"]) != 2:
            extra.append("libellés vrai/faux manquants")
        if not d.get("leagues") or any(not d["leagues"].get(x) for x in LEAGUE_SLUGS):
            extra.append("noms des ligues manquants")
        print(f"{lang} : {len(d['items'])}/{len(qs)}, {len(missing)} manquantes, {len(rejects)} rejets, "
              f"{len(warns)} avertissements" + (" — " + ", ".join(extra) if extra else ""))
        bad += bool(rejects or missing or extra)
    return 1 if bad else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("packs"); p.add_argument("--work", type=Path, required=True); p.add_argument("--parts", type=int, default=3)
    c = sub.add_parser("check"); c.add_argument("--work", type=Path, required=True); c.add_argument("--lang", required=True)
    c.add_argument("--part", type=int, required=True); c.add_argument("--parts", type=int, default=3)
    m = sub.add_parser("merge"); m.add_argument("--work", type=Path, required=True); m.add_argument("--parts", type=int, default=3)
    sub.add_parser("status")
    a = ap.parse_args()
    if a.cmd == "packs":
        cmd_packs(a.work, a.parts)
    elif a.cmd == "check":
        return cmd_check(a.work, a.lang, a.part, a.parts)
    elif a.cmd == "merge":
        cmd_merge(a.work, a.parts)
    else:
        return cmd_status()
    return 0


if __name__ == "__main__":
    sys.exit(main())
