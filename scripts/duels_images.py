#!/usr/bin/env python3
"""Images des questions de duel : drapeaux, tableaux, monuments, portraits, œuvres mythologiques.

    SUPABASE_SECRET_KEY=… python3 scripts/duels_images.py flags <dossier_de_travail>
    SUPABASE_SECRET_KEY=… python3 scripts/duels_images.py images <dossier_de_travail>

L'app affiche l'image d'une question dans un cadre en hauteur (4:5) qu'elle remplit. Chaque
image est donc mise à ce format ici, en 640 × 800, pour s'afficher entière sur toutes les
versions de l'app :
- un drapeau est posé entier sur un fond neutre (jamais rogné : un drapeau rogné n'est plus
  reconnaissable) ; source flagcdn.com, domaine public ;
- « contain » (tableaux) : l'œuvre entière, sur un fond fait de l'œuvre elle-même, floutée ;
- « cover » (portraits, monuments) : rognée au format, depuis le haut (« top ») ou le centre.

`flags` lit la liste de scripts/duels_geo_source.py. `images` lit content/duels/images.json
(clé, cadrage, crédit) et les originaux dans <dossier_de_travail>/raw/<clé>.jpg (Wikimedia
Commons, domaine public ou CC0 uniquement). Les images vont sur Supabase Storage (bucket
public course-images, dossiers duels/flags et duels/images) et une copie locale dans
<dossier_de_travail>/out pour relecture. Sans SUPABASE_SECRET_KEY, rien n'est envoyé.
"""
from __future__ import annotations

import io
import json
import sys
import time
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from duels_assets import jpeg, upload  # noqa: E402
from duels_geo_source import FLAGS  # noqa: E402

WIDTH, HEIGHT = 640, 800
PAPER = (232, 228, 218)
MANIFEST = ROOT / "content" / "duels" / "images.json"


def shadowed(canvas: Image.Image, picture: Image.Image, box: tuple[int, int]) -> None:
    """Pose `picture` sur `canvas` avec une ombre douce et un filet."""
    x, y = box
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rectangle((x, y + 8, x + picture.width, y + picture.height + 8), fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    canvas.paste(shadow, (0, 0), shadow)
    canvas.paste(picture, (x, y))
    ImageDraw.Draw(canvas).rectangle((x, y, x + picture.width - 1, y + picture.height - 1), outline=(0, 0, 0, 60), width=1)


def fit_inside(image: Image.Image, width: int, height: int) -> Image.Image:
    ratio = min(width / image.width, height / image.height)
    return image.resize((max(1, round(image.width * ratio)), max(1, round(image.height * ratio))), Image.LANCZOS)


def flag_card(flag: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), PAPER + (255,))
    picture = fit_inside(flag.convert("RGB"), 540, 520)
    shadowed(canvas, picture, ((WIDTH - picture.width) // 2, (HEIGHT - picture.height) // 2))
    return canvas.convert("RGB")


def contain(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    ratio = max(WIDTH / image.width, HEIGHT / image.height)
    back = image.resize((round(image.width * ratio), round(image.height * ratio)), Image.BILINEAR)
    left, top = (back.width - WIDTH) // 2, (back.height - HEIGHT) // 2
    back = back.crop((left, top, left + WIDTH, top + HEIGHT)).filter(ImageFilter.GaussianBlur(26))
    back = ImageEnhance.Brightness(back).enhance(0.62)
    canvas = back.convert("RGBA")
    picture = fit_inside(image, WIDTH - 36, HEIGHT - 36)
    shadowed(canvas, picture, ((WIDTH - picture.width) // 2, (HEIGHT - picture.height) // 2))
    return canvas.convert("RGB")


def cover(image: Image.Image, focus: str, crop: list[float] | None) -> Image.Image:
    image = image.convert("RGB")
    if crop:
        l, t, r, b = crop
        image = image.crop((round(l * image.width), round(t * image.height), round(r * image.width), round(b * image.height)))
    ratio = max(WIDTH / image.width, HEIGHT / image.height)
    image = image.resize((round(image.width * ratio), round(image.height * ratio)), Image.LANCZOS)
    left = (image.width - WIDTH) // 2
    top = 0 if focus == "top" else (image.height - HEIGHT) // 2
    return image.crop((left, top, left + WIDTH, top + HEIGHT))


def flags(work: Path) -> None:
    cache, out = work / "flags_raw", work / "out" / "flags"
    cache.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)
    for code, country, _level, _wrong in FLAGS:
        source = cache / f"{code}.png"
        if not source.exists():
            req = urllib.request.Request(f"https://flagcdn.com/w1280/{code}.png", headers={"User-Agent": "quiz-content-builder/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                source.write_bytes(resp.read())
            time.sleep(0.3)
        data = jpeg(flag_card(Image.open(source)), 88)
        (out / f"{code}.jpg").write_bytes(data)
        upload(f"duels/flags/{code}.jpg", data)
        print("drapeau", code, country, flush=True)


def images(work: Path) -> None:
    out = work / "out" / "images"
    out.mkdir(parents=True, exist_ok=True)
    for key, meta in json.loads(MANIFEST.read_text(encoding="utf-8")).items():
        source = work / "raw" / f"{key}.jpg"
        if not source.exists():
            sys.exit(f"original manquant : {source}")
        image = Image.open(source)
        card = contain(image) if meta.get("fit") == "contain" else cover(image, meta.get("focus", "center"), meta.get("crop"))
        data = jpeg(card, 84)
        (out / f"{key}.jpg").write_bytes(data)
        upload(f"duels/images/{key}.jpg", data)
        print("image", key, meta.get("fit"), flush=True)


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in ("flags", "images"):
        print(__doc__)
        return 2
    (flags if sys.argv[1] == "flags" else images)(Path(sys.argv[2]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
