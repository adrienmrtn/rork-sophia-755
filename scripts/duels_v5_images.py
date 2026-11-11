#!/usr/bin/env python3
"""Images des questions de duel ajoutées (lot v5), préparées sans rien envoyer à Supabase.

    python3 scripts/duels_v5_images.py <nom> [clé …]

Lit content/duels/v5/images_<nom>.json :
    {"<clé>": {"file": "<nom du fichier Wikimedia Commons>", "fit": "contain|cover",
               "focus": "top|center", "crop": [l, t, r, b] (facultatif), "name": "<légende>"},
     "flags/<code iso>": {"flag": true, "name": "<pays>"}}

- Wikimedia Commons : seulement domaine public ou CC0 (licence lue dans les métadonnées du
  fichier ; sinon refus). Crédits écrits dans content/duels/v5/credits_<nom>.json (même forme que
  content/duels/images.json, où ils sont ensuite réunis avant scripts/build_duels_seed.py).
- Drapeaux : flagcdn.com (domaine public), posés sur fond neutre comme les autres.
Sortie : content/duels/v5/upload/duels/images/<clé>.jpg et …/duels/flags/<code>.jpg, au format
de l'app (640 × 800, scripts/duels_images.py). Le dossier upload/duels se dépose tel quel dans
le bucket course-images de Supabase Storage (il fusionne avec le dossier duels existant).
"""
from __future__ import annotations

import io
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from duels_assets import jpeg  # noqa: E402
from duels_images import PAPER, contain, cover, flag_card  # noqa: E402

V5 = ROOT / "content" / "duels" / "v5"
RAW = V5 / "images_raw"
OUT = V5 / "upload" / "duels"
UA = {"User-Agent": "SophiaQuizContentBuilder/1.0 (educational quiz app; image preparation script)"}
FREE = re.compile(r"^(public domain|pd|cc0|cc-zero|no restrictions)", re.I)


def get(url: str, tries: int = 5) -> bytes:
    for n in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=90) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code in (429, 503) and n < tries - 1:
                time.sleep(4 * (n + 1))
                continue
            raise
    raise RuntimeError(url)


def strip_html(s: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s or "")).strip()


def commons_info(file: str) -> dict:
    q = urllib.parse.urlencode({"action": "query", "format": "json", "prop": "imageinfo",
                                "iiprop": "url|extmetadata|size", "iiurlwidth": 1280,
                                "titles": "File:" + file})
    data = json.loads(get("https://commons.wikimedia.org/w/api.php?" + q))
    page = next(iter(data["query"]["pages"].values()))
    if "imageinfo" not in page:
        raise ValueError(f"fichier introuvable sur Commons : {file}")
    info = page["imageinfo"][0]
    meta = info.get("extmetadata", {})
    lic = strip_html(meta.get("LicenseShortName", {}).get("value", ""))
    return {"thumb": info.get("thumburl") or info["url"], "license": lic,
            "artist": strip_html(meta.get("Artist", {}).get("value", ""))[:120],
            "source": info.get("descriptionurl", "")}


def main(name: str, only: list[str]) -> int:
    manifest = json.loads((V5 / f"images_{name}.json").read_text(encoding="utf-8"))
    credits_path = V5 / f"credits_{name}.json"
    credits = json.loads(credits_path.read_text(encoding="utf-8")) if credits_path.exists() else {}
    RAW.mkdir(parents=True, exist_ok=True)
    errors = []
    for key, m in manifest.items():
        if only and key not in only:
            continue
        try:
            if m.get("flag"):
                code = key.split("/", 1)[1]
                raw = RAW / f"flag_{code}.png"
                if not raw.exists():
                    raw.write_bytes(get(f"https://flagcdn.com/w1280/{code}.png"))
                flag = Image.open(raw).convert("RGBA")
                alpha = flag.getchannel("A")
                flag = flag.crop(alpha.getbbox())
                # Fond transparent (Népal…) : posé sur le fond neutre, jamais sur une couleur du drapeau.
                flat = Image.new("RGB", flag.size, PAPER)
                flat.paste(flag, mask=flag.getchannel("A"))
                card = flag_card(flat)
                dest = OUT / "flags" / f"{code}.jpg"
                quality = 88
            else:
                raw = RAW / f"{key}.jpg"
                info = commons_info(m["file"])
                if not FREE.match(info["license"]):
                    raise ValueError(f"licence refusée « {info['license']} »")
                if not raw.exists():
                    raw.write_bytes(get(info["thumb"]))
                    time.sleep(1)
                image = Image.open(raw)
                card = contain(image) if m.get("fit") == "contain" else cover(image, m.get("focus", "center"), m.get("crop"))
                dest = OUT / "images" / f"{key}.jpg"
                quality = 84
                credits[key] = {"name": m.get("name", key), "file": m["file"], "artist": info["artist"] or None,
                                "license": "Public domain" if not info["license"].lower().startswith("cc0") else "CC0",
                                "source": info["source"], "fit": m.get("fit", "cover")}
                for extra in ("focus", "crop"):
                    if m.get(extra):
                        credits[key][extra] = m[extra]
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(jpeg(card, quality))
            print("ok", key, flush=True)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{key} : {e}")
            print("ERREUR", key, e, flush=True)
    credits_path.write_text(json.dumps(credits, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if errors:
        print("\n".join(errors))
    return 1 if errors else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2:]))
