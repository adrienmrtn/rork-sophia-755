#!/usr/bin/env python3
"""Génère les illustrations du site (sophia-culture.com) avec fal.ai (Recraft v3).

Lit un manifeste JSON (liste d'images à produire : nom, prompt, style, taille, palette),
soumet chaque demande à la file fal, attend le résultat, télécharge l'image et l'écrit en
WebP (≤ 1 Mo, pour passer par l'API GitHub) dans le dossier de sortie, avec un index.json.

    FAL_KEY=… python3 scripts/site_art.py design/site-art/manifest.json design/site-art/out

Tourne dans GitHub Actions (.github/workflows/site-art.yml) : la clé fal n'est jamais dans le
dépôt ni dans une conversation. Sans Pillow, l'image est gardée telle quelle (PNG).
"""
from __future__ import annotations

import io
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

QUEUE = "https://queue.fal.run"
MODEL = "fal-ai/recraft-v3"
UA = "sophia-site-art/1.0"


def fal_key() -> str:
    key = os.environ.get("FAL_KEY") or os.environ.get("FAL_API_KEY") or ""
    key = key.strip().strip("<>")
    if not key:
        sys.exit("FAL_KEY (ou FAL_API_KEY) manquant")
    return key


def request(method: str, url: str, key: str, body: dict | None = None, timeout: int = 120) -> dict:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": f"Key {key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": UA,
    })
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read()
    return json.loads(raw.decode("utf-8")) if raw else {}


def submit(item: dict, key: str) -> dict:
    payload = {
        "prompt": item["prompt"],
        "image_size": item.get("size", "square_hd"),
        "style": item.get("style", "vector_illustration"),
        "enable_safety_checker": True,
    }
    if item.get("colors"):
        payload["colors"] = [{"r": c[0], "g": c[1], "b": c[2]} for c in item["colors"]]
    return request("POST", f"{QUEUE}/{MODEL}", key, payload)


def wait(submitted: dict, key: str, budget_s: int = 420) -> dict:
    request_id = submitted.get("request_id")
    status_url = submitted.get("status_url") or f"{QUEUE}/{MODEL}/requests/{request_id}/status"
    response_url = submitted.get("response_url") or f"{QUEUE}/{MODEL}/requests/{request_id}"
    deadline = time.time() + budget_s
    while time.time() < deadline:
        status = request("GET", status_url + ("&" if "?" in status_url else "?") + "logs=0", key)
        state = status.get("status")
        if state == "COMPLETED":
            return request("GET", response_url, key)
        if state in ("FAILED", "CANCELLED"):
            raise RuntimeError(f"fal {state}: {json.dumps(status)[:400]}")
        time.sleep(3)
    raise TimeoutError(f"fal : pas de résultat en {budget_s} s ({request_id})")


def download(url: str) -> tuple[bytes, str]:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read(60_000_000), resp.headers.get("Content-Type", "")


def to_webp(raw: bytes, content_type: str, max_side: int, url: str = "") -> tuple[bytes, str]:
    """WebP de qualité, bornée en taille, pour que l'API GitHub puisse la relire (< 1 Mo).
    Les styles vectoriels de Recraft renvoient un SVG : on le garde tel quel (c'est ce que le site
    préfère). Toute image que Pillow ne lit pas est gardée brute, avec l'extension de l'URL."""
    head = raw[:400].lstrip().lower()
    if "svg" in (content_type or "") or url.lower().split("?")[0].endswith(".svg") or head.startswith(b"<svg") or (head.startswith(b"<?xml") and b"<svg" in raw[:2000].lower()):
        return raw, "svg"
    guess = url.lower().split("?")[0].rsplit(".", 1)[-1] if "." in url.rsplit("/", 1)[-1] else "png"
    try:
        from PIL import Image  # type: ignore
        image = Image.open(io.BytesIO(raw))
        image.load()
    except Exception:  # noqa: BLE001
        return raw, guess if guess in ("png", "jpg", "jpeg", "webp", "gif") else "png"
    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGBA")
    if max(image.size) > max_side:
        ratio = max_side / max(image.size)
        image = image.resize((round(image.width * ratio), round(image.height * ratio)), Image.LANCZOS)
    buf = io.BytesIO()
    for quality in (92, 86, 80, 72):
        buf = io.BytesIO()
        image.save(buf, format="WEBP", quality=quality, method=6)
        if buf.tell() < 950_000:
            break
    return buf.getvalue(), "webp"


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[3].split(",")) if len(sys.argv) > 3 and sys.argv[3] else None
    key = fal_key()
    defaults = manifest.get("defaults", {})
    index: dict[str, dict] = {}
    index_path = out / "index.json"
    if index_path.exists():
        index = json.loads(index_path.read_text(encoding="utf-8"))
    failures = []
    for item in manifest["items"]:
        name = item["name"]
        if only and name not in only:
            continue
        merged = {**defaults, **item}
        print(f"→ {name} ({merged.get('style')}, {merged.get('size')})", flush=True)
        try:
            result = wait(submit(merged, key), key)
            images = result.get("images") or []
            if not images:
                raise RuntimeError(f"pas d'image dans la réponse : {json.dumps(result)[:300]}")
            raw, content_type = download(images[0]["url"])
            data, ext = to_webp(raw, content_type or images[0].get("content_type") or "", int(merged.get("max_side", 1600)), images[0].get("url", ""))
            path = out / f"{name}.{ext}"
            path.write_bytes(data)
            index[name] = {
                "file": path.name, "bytes": len(data), "style": merged.get("style"), "size": merged.get("size"),
                "prompt": merged["prompt"], "width": images[0].get("width"), "height": images[0].get("height"),
                "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            }
            print(f"  ok {path.name} ({len(data)} octets)", flush=True)
        except Exception as e:  # noqa: BLE001
            detail = ""
            if isinstance(e, urllib.error.HTTPError):
                try:
                    detail = e.read().decode("utf-8", "replace")[:400]
                except Exception:  # noqa: BLE001
                    detail = ""
            print(f"  ÉCHEC {name} : {e} {detail}", flush=True)
            failures.append(name)
        index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"terminé : {len(index)} image(s) dans {out}, {len(failures)} échec(s) {failures}")
    return 1 if failures and len(failures) == len(manifest["items"]) else 0


if __name__ == "__main__":
    sys.exit(main())
