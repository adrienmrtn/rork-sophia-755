#!/usr/bin/env python3
"""Écrit l'aperçu embarqué des éditions natives (content/native_editions.json).

Tant qu'une édition native n'est pas publiée dans Supabase, les apps reçoivent encore
l'ancienne version du cours. Ce script en fait un paquet local, au format des paquets du
catalogue (`{id, lang, hash, content, quiz, glossary, credits}`), qu'un build DEBUG d'iOS
lit à la place du paquet en ligne (`InteractivePreview` dans CatalogStore.swift).

Ne touche pas à Supabase et ne change rien pour les utilisateurs.

  python3 scripts/build_interactive_preview.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from import_catalog_to_supabase import Sources, build_language, canonical  # noqa: E402

OUT = ROOT / "ios" / "Sophia" / "Resources" / "InteractivePreview"


def main() -> int:
    editions = json.loads((ROOT / "content" / "native_editions.json").read_text(encoding="utf-8"))
    OUT.mkdir(parents=True, exist_ok=True)
    wanted = {f"preview_{lang}_{cid}.json" for lang, ids in editions.items() for cid in ids}
    for stale in OUT.glob("preview_*.json"):
        if stale.name not in wanted:
            stale.unlink()
    written = 0
    for lang, ids in sorted(editions.items()):
        built = build_language(Sources([lang]), lang)
        for cid in ids:
            bundle = built["bundles"].get(cid)
            if bundle is None:
                print(f"attention : {cid} absent en {lang}")
                continue
            (OUT / f"preview_{lang}_{cid}.json").write_bytes(canonical(bundle))
            written += 1
    print(f"aperçu : {written} paquet(s) dans {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
