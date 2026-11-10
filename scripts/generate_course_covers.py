#!/usr/bin/env python3
"""Régénère des couvertures de cours dans la direction artistique du Studio, sans rien publier.

Même chaîne que web/src/lib/studio/covers.ts : Gemini (texte, via fal-ai/any-llm) écrit le prompt
d'image avec la consigne ART_DIRECTOR_SYSTEM_PROMPT (lue dans covers.ts, pas recopiée ici), puis
fal-ai/gemini-25-flash-image dessine trois propositions 16:9 en JPEG.

Lecture seule côté Supabase (titre, sous-titre, description, matière du cours dans sa langue
d'origine) ; les images vont dans un dossier local. L'envoi dans le bucket et le SQL restent
manuels : voir docs/cours-sans-couverture.md.

    export API_FAL_KEY=…            # ou FAL_KEY
    export SUPABASE_SECRET_KEY=…    # lecture seule
    python3 scripts/generate_course_covers.py --out /tmp/covers \
        course_255_comment_un_roman_a_t_il_sauve_notre_dame course_312_qu_est_ce_que_la_machine_d_anticythere
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://afnmcoovdvbtkgohtdij.supabase.co")
TEXT_MODEL = os.environ.get("FAL_TEXT_MODEL", "google/gemini-2.5-flash")
IMAGE_MODEL = os.environ.get("FAL_COVER_MODEL", "fal-ai/gemini-25-flash-image")


def art_director_prompt() -> str:
    source = (ROOT / "web/src/lib/studio/covers.ts").read_text(encoding="utf-8")
    match = re.search(r"ART_DIRECTOR_SYSTEM_PROMPT = `(.*?)`;", source, re.S)
    if not match:
        sys.exit("ART_DIRECTOR_SYSTEM_PROMPT introuvable dans web/src/lib/studio/covers.ts")
    return match.group(1)


def fal(path: str, body: dict) -> dict:
    key = os.environ.get("API_FAL_KEY") or os.environ.get("FAL_KEY") or os.environ.get("FAL_API_KEY")
    if not key:
        sys.exit("API_FAL_KEY (ou FAL_KEY) manquant")
    req = urllib.request.Request(
        f"https://fal.run/{path}",
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Key {key}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=300) as res:
        return json.load(res)


def course_context(course_id: str) -> str:
    key = os.environ.get("SUPABASE_SECRET_KEY") or os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not key:
        sys.exit("SUPABASE_SECRET_KEY manquant")
    query = urllib.parse.urlencode({
        "select": "title,subtitle,description,lang,courses!inner(subject,origin_lang)",
        "course_id": f"eq.{course_id}",
        "lang": "in.(fr,en)",
    })
    req = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/course_contents?{query}", headers={"apikey": key, "Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=60) as res:
        rows = json.load(res)
    if not rows:
        sys.exit(f"Cours introuvable : {course_id}")
    row = next((r for r in rows if r["lang"] == r["courses"]["origin_lang"]), rows[0])
    lines = [f"Course title: {row['title']}"]
    if row.get("subtitle"):
        lines.append(f"Subtitle: {row['subtitle']}")
    if row["courses"].get("subject"):
        lines.append(f"Subject area: {row['courses']['subject']}")
    if row.get("description"):
        lines.append(f"What the course is about: {row['description']}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("course_ids", nargs="+")
    parser.add_argument("--out", required=True, help="dossier de sortie (un sous-dossier par cours)")
    parser.add_argument("--count", type=int, default=3)
    parser.add_argument("--prompt", help="prompt d'image imposé (saute l'étape directeur artistique)")
    args = parser.parse_args()
    system = art_director_prompt()
    for course_id in args.course_ids:
        folder = Path(args.out) / course_id
        folder.mkdir(parents=True, exist_ok=True)
        prompt = args.prompt
        if not prompt:
            out = fal("fal-ai/any-llm", {"model": TEXT_MODEL, "system_prompt": system, "prompt": course_context(course_id), "temperature": 0.8})
            prompt = (out.get("output") or "").strip().strip('"“”').strip()
            if not prompt:
                sys.exit(f"{course_id} : prompt vide ({out.get('error')})")
        stamp = len(list(folder.glob("prompt_*.txt"))) + 1
        (folder / f"prompt_{stamp}.txt").write_text(prompt + "\n", encoding="utf-8")
        out = fal(IMAGE_MODEL, {"prompt": prompt, "num_images": args.count, "aspect_ratio": "16:9", "output_format": "jpeg"})
        for i, image in enumerate(out.get("images") or [], start=1):
            target = folder / f"take{stamp}_{i}.jpg"
            urllib.request.urlretrieve(image["url"], target)
            print(target)


if __name__ == "__main__":
    main()
