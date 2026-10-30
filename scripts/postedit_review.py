#!/usr/bin/env python3
"""Adversarial review of a post-editing batch: draw the sample, then collect the fixes.

Works in the same folder as the post-editing (see docs/processus-traduction.md):
packs/<lang>/*.md (before), out/<lang>/*.json (the editors' output).

    python3 scripts/postedit_review.py sample  --work W --lang da [--changed 120 --unchanged 80]
        -> W/review/<lang>/changed_a.md, changed_b.md, unchanged.md
    (run the .claude/workflows/relecture-native.js workflow on them)
    python3 scripts/postedit_review.py collect --work W --lang da --journal <workflow journal.jsonl>...
        -> W/review_out/<lang>/<surface>_review.json, ready for
           python3 scripts/postedit_i18n.py apply --lang da --from W/review_out/da

Fixes come out in lens order (fidelity, then language, then missed items): a later lens
overrides an earlier one on the same id. Ids and [[links]] are remapped to glossary terms
and library sections the editors renamed.
"""

from __future__ import annotations

import argparse
import json
import random
import re
from collections import Counter, defaultdict
from pathlib import Path

WEIGHT = {"ui": 3, "store": 3, "legal": 2, "catalogue": 2, "glossaire": 2, "quiz": 3, "cours": 4}


# ------------------------------------------------------------------ sample
def _parse(md: Path) -> dict[str, dict]:
    """Items of a pack; course items carry their course header (allowed glossary terms),
    glossary items the French definitions of their course."""
    items, ctx_by_course = {}, {}
    for block in md.read_text(encoding="utf-8").split("\n### ")[1:]:
        lines = block.split("\n")
        it = {"id": lines[0]}
        for line in lines[1:]:
            if line.startswith("FR: "):
                it["fr"] = line[4:]
            elif line.startswith("ACTUEL: "):
                it["avant"] = line[8:]
            elif line.startswith("(") and "fr" not in it:
                it["ctx"] = line[1:-1] if line.endswith(")") else line[1:]
        cid = re.split(r"[/|]", it["id"])[0]
        if it.get("ctx", "").startswith(("COURS ", "Définitions françaises")):
            ctx_by_course[cid] = it["ctx"][:1500]
            if it["ctx"].startswith("COURS "):
                continue
        if cid in ctx_by_course:
            it["cours_ctx"] = ctx_by_course[cid]
        items[it["id"]] = it
    return items


def _render(items: list[dict], title: str) -> str:
    out = [title]
    for it in items:
        out.append(f"\n### {it['surface']} | {it['id']}")
        if it.get("cours_ctx"):
            out.append(f"({it['cours_ctx']})")
        out.append(f"FR: {it.get('fr', '∅')}")
        out.append(f"AVANT: {it.get('avant', '')}")
        if "apres" in it:
            out.append(f"APRÈS: {it['apres']}")
        if it.get("terme"):
            out.append(f"TERME RENOMMÉ EN: {it['terme']}")
    return "\n".join(out) + "\n"


def sample(work: Path, lang: str, n_changed: int, n_unchanged: int) -> dict:
    changed, same = defaultdict(list), defaultdict(list)
    for md in sorted((work / "packs" / lang).glob("*.md")):
        surface = "ui" if md.stem.startswith("ui") else md.stem.split("_")[0]
        out = work / "out" / lang / f"{md.stem}.json"
        if not out.exists():
            continue
        edits = {e["id"]: e for e in json.loads(out.read_text(encoding="utf-8")).get("edits", [])
                 if isinstance(e, dict) and "id" in e}
        for ident, it in _parse(md).items():
            e = edits.get(ident)
            rec = dict(it, surface=surface, lot=md.stem)
            if e and (e.get("texte") not in (None, it.get("avant")) or e.get("terme")):
                rec["apres"] = e.get("texte", it.get("avant"))
                if e.get("terme"):
                    rec["terme"] = e["terme"]
                changed[surface].append(rec)
            elif it.get("avant") not in (None, "—") and it.get("fr") not in (None, "—", "∅"):
                same[surface].append(rec)

    rng = random.Random(f"{lang}-review")

    def pick(pool, n):
        total = sum(WEIGHT[s] for s in pool if pool[s])
        chosen = []
        for s, items in pool.items():
            chosen += rng.sample(items, min(len(items), max(2, round(n * WEIGHT[s] / total))))
        rng.shuffle(chosen)
        return chosen[:n]

    d = work / "review" / lang
    d.mkdir(parents=True, exist_ok=True)
    ch = pick(changed, n_changed) if changed else []
    half = len(ch) // 2
    (d / "changed_a.md").write_text(_render(ch[:half], f"# {lang} — segments post-édités (A)"), encoding="utf-8")
    (d / "changed_b.md").write_text(_render(ch[half:], f"# {lang} — segments post-édités (B)"), encoding="utf-8")
    (d / "unchanged.md").write_text(_render(pick(same, n_unchanged) if same else [], f"# {lang} — segments laissés tels quels"), encoding="utf-8")
    return {"changes": {s: len(v) for s, v in changed.items()}, "same": {s: len(v) for s, v in same.items()},
            "sample": [half, len(ch) - half]}


# ------------------------------------------------------------------ collect
def collect(work: Path, lang: str, journals: list[Path]) -> dict:
    labels, results = {}, {}
    for j in journals:
        for line in j.read_text(encoding="utf-8").splitlines():
            e = json.loads(line)
            if e.get("type") == "started":
                labels[e["agentId"]] = e.get("label", "")
            elif e.get("type") == "result" and isinstance(e.get("result"), dict):
                results[e["agentId"]] = e["result"].get("verdicts", [])

    renames = defaultdict(dict)  # glossary renames by the editors: course -> old term -> new term
    for f in (work / "out" / lang).glob("glossaire_*.json"):
        for e in json.loads(f.read_text(encoding="utf-8")).get("edits", []):
            if isinstance(e, dict) and e.get("terme") and "|" in e.get("id", ""):
                cid, old = e["id"].split("|", 1)
                renames[cid][old] = e["terme"].strip()
    sections = {}  # library section labels renamed by the editors: the sample shows the old one
    cat = work / "out" / lang / "catalogue.json"
    if cat.exists():
        for e in json.loads(cat.read_text(encoding="utf-8")).get("edits", []):
            if isinstance(e, dict) and str(e.get("id", "")).startswith("rubrique:") and e.get("texte"):
                sections[e["id"]] = "rubrique:" + e["texte"]

    def remap(surface, ident, text):
        ident = sections.get(ident, ident)
        if surface == "glossaire" and "|" in ident:
            cid, term = ident.split("|", 1)
            ident = f"{cid}|{renames.get(cid, {}).get(term, term)}"
        cid = re.split(r"[/|]", ident)[0]
        if surface == "quiz":
            cid = cid.rsplit("_q", 1)[0]
        ren = renames.get(cid, {})
        if ren and text:
            text = re.sub(r"\[\[(.+?)\]\]", lambda m: f"[[{ren.get(m.group(1), m.group(1))}]]", text)
        return ident, text

    stats, final = Counter(), {}
    lens_rank = lambda a: 0 if ":fidélité:" in labels.get(a, "") else 1 if ":langue:" in labels.get(a, "") else 2
    for agent in sorted(results, key=lens_rank):
        label = labels.get(agent, "")
        if not label.startswith(f"{lang}:"):
            continue
        lens = label.split(":")[1]
        for v in results[agent]:
            stats[f"{lens}:{v.get('verdict')}"] += 1
            if v.get("verdict") == "fix":
                stats[f"{lens}:fix:{v.get('gravite')}"] += 1
                if v.get("texte") or v.get("terme"):
                    final[(v["surface"], v["id"])] = (v.get("texte"), lens, v.get("raison", ""), v.get("gravite"), v.get("terme"))

    out = work / "review_out" / lang
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob("*.json"):
        f.unlink()
    by_surface, log = defaultdict(list), []
    for (surface, ident), (text, lens, why, grav, terme) in final.items():
        ident2, text2 = remap(surface, ident, text)
        e = {"id": ident2}
        if text2:
            e["texte"] = re.sub(r"^\[[^\]]*\]\s*", "", text2) if surface == "glossaire" else text2
        if terme and surface == "glossaire":
            e["terme"] = terme
        by_surface[surface].append(e)
        log.append({"surface": surface, "id": ident2, "lens": lens, "gravite": grav, "raison": why, "texte": text2})
    for surface, edits in by_surface.items():
        (out / f"{surface}_review.json").write_text(json.dumps({"edits": edits}, ensure_ascii=False, indent=1), encoding="utf-8")
    d = work / "review" / lang
    d.mkdir(parents=True, exist_ok=True)
    (d / "fixes.json").write_text(json.dumps(log, ensure_ascii=False, indent=1), encoding="utf-8")
    (d / "stats.json").write_text(json.dumps(stats, ensure_ascii=False, indent=1), encoding="utf-8")
    return {"stats": stats, "fixes": {s: len(v) for s, v in by_surface.items()}}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("sample")
    a.add_argument("--work", type=Path, required=True); a.add_argument("--lang", required=True)
    a.add_argument("--changed", type=int, default=120); a.add_argument("--unchanged", type=int, default=80)
    b = sub.add_parser("collect")
    b.add_argument("--work", type=Path, required=True); b.add_argument("--lang", required=True)
    b.add_argument("--journal", type=Path, nargs="+", required=True)
    args = ap.parse_args()
    if args.cmd == "sample":
        print(json.dumps(sample(args.work, args.lang, args.changed, args.unchanged), ensure_ascii=False))
    else:
        print(json.dumps(collect(args.work, args.lang, args.journal), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
