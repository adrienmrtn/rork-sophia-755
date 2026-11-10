#!/usr/bin/env python3
"""Images des duels : met en forme les illustrations générées (scripts/site_art.py avec
design/site-art/manifest-duel-leagues.json et manifest-avatars-duels.json) et les portraits
Wikimedia Commons, puis les range là où les apps et le serveur les attendent.

    SUPABASE_SECRET_KEY=… python3 scripts/duels_assets.py <dossier_illustrations> [<dossier_portraits>]

- league_XX_<slug>.* : fond 720×1280 et vignette 360×640 (JPEG), envoyés sur Supabase Storage
  (bucket public course-images, dossier duels/leagues) ; la couleur d'accent de chaque ligue
  est écrite dans content/duels/league_colors.json.
- avatar_XX.*        : 256×256, dans le catalogue d'images iOS (JPEG) et les drawables Android (WebP).
- duel_trophy.*      : l'illustration du trophée, dans le catalogue d'images iOS.
- portraits/*.jpg    : 640 px de large au plus, envoyés dans duels/portraits.

Sans SUPABASE_SECRET_KEY, rien n'est envoyé : seuls les fichiers locaux sont écrits.
"""
from __future__ import annotations

import io
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://afnmcoovdvbtkgohtdij.supabase.co")
BUCKET = "course-images"
IOS_ASSETS = ROOT / "ios" / "Sophia" / "Assets.xcassets"
ANDROID_DRAWABLES = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi"

# Portraits en pied ou larges : la part de l'image à garder (gauche, haut, droite, bas, en fractions)
# pour que le visage reste lisible dans la carte de question.
PORTRAIT_CROPS: dict[str, tuple[float, float, float, float]] = {
    "napoleon": (0.20, 0.03, 0.80, 0.50),
    "ada_lovelace": (0.12, 0.02, 0.88, 0.70),
}


def jpeg(image: Image.Image, quality: int) -> bytes:
    buf = io.BytesIO()
    image.convert("RGB").save(buf, format="JPEG", quality=quality, optimize=True, progressive=True)
    return buf.getvalue()


def upload(path: str, data: bytes) -> None:
    key = os.environ.get("SUPABASE_SECRET_KEY", "").strip()
    if not key:
        return
    req = urllib.request.Request(
        f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{path}", data=data, method="POST",
        headers={"Authorization": f"Bearer {key}", "apikey": key, "Content-Type": "image/jpeg",
                 "x-upsert": "true", "Cache-Control": "public, max-age=31536000"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            resp.read()
    except urllib.error.HTTPError as e:
        sys.exit(f"envoi refusé pour {path} : {e.code} {e.read().decode('utf-8', 'replace')[:300]}")


def cover(image: Image.Image, width: int, height: int) -> Image.Image:
    ratio = max(width / image.width, height / image.height)
    resized = image.resize((round(image.width * ratio), round(image.height * ratio)), Image.LANCZOS)
    left, top = (resized.width - width) // 2, (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def accent(image: Image.Image) -> str:
    """La couleur la plus présente de l'image, assombrie : le fond d'attente et le voile du texte."""
    small = image.convert("RGB").resize((64, 64)).quantize(6)
    palette = small.getpalette()
    index = max(small.getcolors(), key=lambda c: c[0])[1]
    r, g, b = palette[index * 3: index * 3 + 3]
    r, g, b = (round(c * 0.72) for c in (r, g, b))
    return f"#{r:02X}{g:02X}{b:02X}"


def imageset(name: str, data: bytes) -> None:
    folder = IOS_ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / f"{name}.jpg").write_bytes(data)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{name}.jpg", "idiom": "universal", "scale": "1x"},
                   {"idiom": "universal", "scale": "2x"}, {"idiom": "universal", "scale": "3x"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    art = Path(sys.argv[1])
    colors: dict[str, str] = {}
    for path in sorted(art.glob("league_*.*")):
        image = Image.open(path).convert("RGB")
        name = path.stem
        upload(f"duels/leagues/{name}.jpg", jpeg(cover(image, 720, 1280), 82))
        upload(f"duels/leagues/{name}_thumb.jpg", jpeg(cover(image, 360, 640), 78))
        colors[name.split("_", 2)[2]] = accent(image)
        print("ligue", name, colors[name.split("_", 2)[2]], flush=True)
    if colors:
        out = ROOT / "content" / "duels" / "league_colors.json"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(colors, indent=2) + "\n", encoding="utf-8")
    for path in sorted(art.glob("avatar_*.*")):
        image = cover(Image.open(path).convert("RGB"), 256, 256)
        imageset(path.stem, jpeg(image, 86))
        if ANDROID_DRAWABLES.exists():
            image.save(ANDROID_DRAWABLES / f"{path.stem}.webp", format="WEBP", quality=86, method=6)
        print("avatar", path.stem, flush=True)
    for path in art.glob("duel_trophy.*"):
        imageset("duel_trophy", jpeg(cover(Image.open(path).convert("RGB"), 600, 600), 88))
        print("trophée", flush=True)
    if len(sys.argv) > 2:
        for path in sorted(Path(sys.argv[2]).glob("*.jpg")):
            image = Image.open(path).convert("RGB")
            if path.stem in PORTRAIT_CROPS:
                l, t, r, b = PORTRAIT_CROPS[path.stem]
                image = image.crop((round(l * image.width), round(t * image.height), round(r * image.width), round(b * image.height)))
            if image.width > 640:
                image = image.resize((640, round(image.height * 640 / image.width)), Image.LANCZOS)
            upload(f"duels/portraits/{path.stem}.jpg", jpeg(image, 84))
            print("portrait", path.stem, image.size, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
