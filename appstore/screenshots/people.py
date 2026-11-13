#!/usr/bin/env python3
"""Full-body characters in the style of the app's avatars, as transparent PNGs, for the
App Store frames. Same service and style as scripts/site_art.py (fal.ai, Recraft v3,
2d_art_poster), followed by a background removal (fal-ai/birefnet).

    FAL_KEY=… python3 people.py [name,name…]      ->  src/people/<name>.png
"""
import io, json, os, sys, time, urllib.request
from pathlib import Path
from PIL import Image

QUEUE = "https://queue.fal.run"
KEY = (os.environ.get("FAL_KEY") or os.environ.get("API_FAL_KEY") or "").strip()
OUT = Path(__file__).parent / "src" / "people"
STYLE = ("Full body, whole figure visible from head to feet, centred with empty space around. "
         "Flat poster illustration, paper-cut shapes, limited palette of deep navy blue, saffron "
         "yellow, coral red, cream, warm brown and tan, bold simple forms, subtle paper grain, "
         "plain pure white background, no shadow on the ground, no text, no outlines, no scenery.")
COLORS = [[26, 58, 107], [242, 177, 52], [224, 90, 58], [251, 247, 239], [92, 58, 38], [160, 110, 70], [222, 184, 146]]
PEOPLE = {
    "reader_walking": "A young Black woman with a big afro and round glasses walking to the right while reading an open book, saffron coat, navy trousers.",
    "reader_sitting": "A young man with curly dark hair sitting cross-legged on the floor reading a big open book, coral sweater, navy trousers, calm smile.",
    "idea": "An elderly white man with a white beard, round glasses and a flat cap, standing and raising one finger with a delighted look, navy cardigan, saffron scarf.",
    "headphones": "A young South Asian woman with a long braid wearing big headphones, walking with a happy bounce, eyes closed, coral dress, navy jacket.",
    "trophy": "A teenage boy with a cap holding a golden trophy above his head with both arms, cheering, saffron hoodie, navy shorts.",
    "books": "A woman wearing a navy hijab carrying a tall stack of colourful books in her arms, smiling, coral long dress.",
    "waving": "A tall man with a red beard and a beanie leaning to the side and waving one hand, striped navy and cream sweater, tan trousers.",
    "lying": "A girl with two hair buns and round glasses lying on her stomach, legs up behind her, chin on her hands, reading a book on the floor, saffron sweater.",
    "phone_away": "A middle-aged woman with grey bob hair happily tossing a smartphone over her shoulder while holding a book in the other hand, navy dress, coral shoes.",
    "thinker": "A young East Asian man with glasses standing with one hand on his chin, thinking, a question mark shaped curl of hair, cream shirt, navy overalls.",
}

def call(method, url, body=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, method=method,
        headers={"Authorization": f"Key {KEY}", "Content-Type": "application/json", "Accept": "application/json", "User-Agent": "appstore-art/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        raw = r.read()
    return json.loads(raw) if raw else {}

def run(model, payload, budget=420):
    sub = call("POST", f"{QUEUE}/{model}", payload)
    end = time.time() + budget
    while time.time() < end:
        st = call("GET", sub["status_url"])
        if st.get("status") == "COMPLETED":
            return call("GET", sub["response_url"])
        if st.get("status") in ("FAILED", "CANCELLED"):
            raise RuntimeError(json.dumps(st)[:300])
        time.sleep(3)
    raise TimeoutError(model)

def make(name):
    res = run("fal-ai/recraft-v3", {"prompt": PEOPLE[name] + " " + STYLE, "image_size": "portrait_4_3",
        "style": "digital_illustration/2d_art_poster", "colors": [{"r": c[0], "g": c[1], "b": c[2]} for c in COLORS]})
    url = res["images"][0]["url"]
    cut = run("fal-ai/birefnet", {"image_url": url, "output_format": "png"})
    with urllib.request.urlopen(urllib.request.Request(cut["image"]["url"], headers={"User-Agent": "appstore-art/1.0"}), timeout=120) as r:
        im = Image.open(io.BytesIO(r.read())).convert("RGBA")
    im = im.crop(im.getbbox())
    if max(im.size) > 1400:
        k = 1400 / max(im.size); im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / f"{name}.png", optimize=True)
    print(name, im.size, flush=True)

if __name__ == "__main__":
    if not KEY: sys.exit("FAL_KEY manquant")
    names = sys.argv[1].split(",") if len(sys.argv) > 1 else list(PEOPLE)
    from concurrent.futures import ThreadPoolExecutor
    def safe(n):
        try: make(n)
        except Exception as e: print("ECHEC", n, repr(e)[:300], flush=True)
    with ThreadPoolExecutor(5) as ex: list(ex.map(safe, names))
