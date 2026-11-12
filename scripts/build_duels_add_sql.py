#!/usr/bin/env python3
"""SQL des questions de duel ajoutées depuis une liste de référence, avec leurs traductions.

    python3 scripts/build_duels_add_sql.py --baseline content/duels/v4/baseline_ids.txt \
        --migration supabase/migrations/20261114010100_duels_v4_add.sql \
        --paste-dir supabase/duels_v4_a_coller

Les questions nouvelles sont celles de content/duels/questions_en.json absentes de la liste de
référence (les identifiants déjà en base). Écrit :
  - la migration : les questions (duel_questions) puis leurs traductions (duel_question_translations) ;
  - le même contenu découpé en fichiers de moins de 900 000 octets pour l'éditeur SQL de Supabase,
    à exécuter dans l'ordre (le premier contient les questions anglaises).
Tout se rejoue sans risque (ON CONFLICT DO UPDATE). Refuse d'écrire si une langue est incomplète.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from build_duels_seed import insert  # noqa: E402
from duels_i18n import I18N, LANGS, check, excluded_ids, load_questions  # noqa: E402

LIMIT = 900_000
COLUMNS = ["id", "lang", "level", "kind", "subject", "question", "options", "correct_index", "image_url",
           "image_credit", "slider_min", "slider_max", "slider_step", "correct_value", "unit"]


def sql_str(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def translation_rows(lang: str, new: list[dict]) -> list[str]:
    data = json.loads((I18N / f"{lang}.json").read_text(encoding="utf-8"))
    ids = {q["id"] for q in new}
    rejects, _ = check(lang, {**data, "items": {k: v for k, v in data["items"].items() if k in ids}}, new)
    missing = [q["id"] for q in new if q["id"] not in data["items"]]
    if rejects or missing:
        sys.exit(f"{lang} : {len(rejects)} rejet(s), {len(missing)} manquante(s) — SQL non écrit\n  "
                 + "\n  ".join((rejects + missing)[:20]))
    tf = data["true_false"]
    rows = []
    for q in new:
        t = data["items"][q["id"]]
        opts = None
        if q["kind"] in ("mcq", "portrait"):
            opts = [o.strip() for o in t["o"]]
        elif q["kind"] == "true_false":
            opts = tf
        unit = (t.get("u") or "").strip() if q["kind"] == "slider" else ""
        rows.append("  (" + ", ".join([
            sql_str(q["id"]), sql_str(lang), sql_str(t["q"].strip()),
            (sql_str(json.dumps(opts, ensure_ascii=False)) + "::jsonb") if opts else "NULL",
            sql_str(unit) if unit else "NULL"]) + ")")
    return rows


def translations_sql(rows: list[str]) -> str:
    return ("INSERT INTO public.duel_question_translations (question_id, lang, question, options, unit) VALUES\n"
            + ",\n".join(rows)
            + "\nON CONFLICT (question_id, lang) DO UPDATE SET question = EXCLUDED.question, options = EXCLUDED.options,\n"
            "  unit = EXCLUDED.unit, updated_at = now();\n")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline", type=Path, required=True)
    ap.add_argument("--migration", type=Path, required=True)
    ap.add_argument("--paste-dir", type=Path, required=True)
    a = ap.parse_args()
    base = set(a.baseline.read_text(encoding="utf-8").split())
    skip = excluded_ids()
    added = [q for q in load_questions() if q["id"] not in base]
    if not added:
        sys.exit("aucune question nouvelle")
    # Une question nouvelle retirée (intraduisible dans au moins une langue) n'est pas insérée du
    # tout : elle reste dans questions_en.json pour que les identifiants ne bougent pas.
    new = [q for q in added if q["id"] not in skip]
    live = new

    head = (f"-- Duels : {len(new)} questions ajoutées et leurs traductions ({len(LANGS)} langues).\n"
            "-- Généré par scripts/build_duels_add_sql.py — ne pas modifier à la main. Rejouable.\n")
    blocks = [insert("duel_questions", COLUMNS, new, "id")]
    for lang in LANGS:
        rows = translation_rows(lang, live)
        blocks.append(f"-- {lang} : {len(rows)} questions\n" + translations_sql(rows))

    a.migration.write_text(head + "\nBEGIN;\n\n" + "\n".join(blocks) + "\nCOMMIT;\n", encoding="utf-8")

    # Fichiers à coller : des blocs entiers, chaque fichier sous la limite de l'éditeur.
    files: list[list[str]] = [[]]
    for b in blocks:
        if files[-1] and len("".join(files[-1]).encode()) + len(b.encode()) > LIMIT - 2000:
            files.append([])
        files[-1].append(b)
    a.paste_dir.mkdir(parents=True, exist_ok=True)
    for old in a.paste_dir.glob("*.sql"):
        old.unlink()
    for n, chunk in enumerate(files, start=1):
        text = (f"-- Duels, questions ajoutées — fichier {n} sur {len(files)}, à exécuter dans l'ordre.\n"
                "BEGIN;\n\n" + "\n".join(chunk) + "\nCOMMIT;\n")
        (a.paste_dir / f"{n:02d}_duels_ajout.sql").write_text(text, encoding="utf-8")
        print(f"{a.paste_dir / f'{n}_duels_ajout.sql'} : {len(text.encode()) / 1e3:.0f} ko")
    print(f"{a.migration} : {len(new)} questions, {len(LANGS)} langues")
    return 0


if __name__ == "__main__":
    sys.exit(main())
