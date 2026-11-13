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

# Objects for the opening collage: same style, brighter palette so they read on brand blue.
# Avoid objects that are mostly cream or white: the background removal eats them.
PROP_STYLE = ("A single isolated object, centred with empty space around. Flat poster illustration, paper-cut "
              "shapes, limited palette of saffron yellow, coral red and cream with small deep navy details, bold "
              "simple forms, subtle paper grain, plain pure white background, no shadow, no text, no outlines, no scenery.")
PROPS = {
    "prop_bust": "An ancient Greek marble bust of a bearded philosopher wearing a laurel wreath, seen in three-quarter view.",
    "prop_saturn": "The planet Saturn with its rings, with two small stars.",
    "prop_amphora": "An ancient Greek amphora vase decorated with a running figure.",
    "prop_telescope": "A brass telescope on a tripod pointing up to the left.",
    "prop_rocket": "A retro space rocket flying upward to the right with a flame.",
    "prop_portrait": "A framed painted portrait of a renaissance lady with a mysterious smile, in an ornate golden frame.",
    "prop_globe": "A desk globe of the Earth on a stand.",
    "prop_mask": "A pair of theatre masks, comedy and tragedy.",
}
# Before / after for the opening panel: the same teenager slumped over a phone, then reading.
# The model draws a floor whatever the prompt says, so the prompt asks for a cream wall and a
# green floor strip: the wall is cut out by colour (chroma key on the top corners, which keeps
# the cream and white parts of the figure) and the two floors line up along the panel's bottom
# edge. Recraft caps prompts at 1000 characters. Several takes were made and one pair kept.
BOY = ("a teenage boy with pale cream skin, messy straight dark brown hair with spiky tufts, coral red sweater, "
       "navy blue trousers, cream sneakers with saffron stripes")
SCENE_STYLE = ("Whole figure visible, centred. Flat poster illustration, paper-cut shapes, palette of navy blue, "
               "saffron yellow, coral red, cream and brown, bold simple forms, subtle paper grain, plain empty cream "
               "background, a thin flat green floor strip along the bottom edge, no text, no outlines, no furniture.")
SCENES = {
    "boy_before": f"Full-body drawing of {BOY}, sitting slumped on the floor with knees up, back hunched, head down, staring at a smartphone held in both hands, tired half-closed eyes, sad bored expression. " + SCENE_STYLE,
    "boy_after": f"Full-body drawing of {BOY}, sitting upright cross-legged on the floor, reading an open saffron book that rests in his lap, both hands on the book at chest height, arms down, eyes looking down at the pages, absorbed, happy smile. " + SCENE_STYLE,
}
SCENE_COLORS = COLORS[:4] + [[92, 58, 38], [38, 150, 140]]

def chroma_key(im):
    """Transparent wherever the pixel is close to the wall colour sampled in the top corners."""
    import numpy as np
    a = np.asarray(im.convert("RGB")).astype(float)
    corners = np.concatenate([a[:24, :24].reshape(-1, 3), a[:24, -24:].reshape(-1, 3)])
    d = np.sqrt(((a - np.median(corners, axis=0)) ** 2).sum(axis=2))
    alpha = np.clip((d - 38) / 22, 0, 1)
    out = Image.fromarray(np.dstack([a, alpha * 255]).astype("uint8"), "RGBA")
    # drop the paper-grain specks the key leaves on the wall: keep alpha only near solid areas
    from PIL import ImageChops, ImageFilter
    al = out.getchannel("A")
    solid = al.point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.MinFilter(7)).filter(ImageFilter.MaxFilter(13))
    out.putalpha(ImageChops.multiply(al, solid))
    return out

PROMPTS = {**SCENES, **{k: v + " " + STYLE for k, v in PEOPLE.items()}, **{k: v + " " + PROP_STYLE for k, v in PROPS.items()}}

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
    res = run("fal-ai/recraft-v3", {"prompt": PROMPTS[name], "image_size": "square_hd" if name in PROPS or name in SCENES else "portrait_4_3",
        "style": "digital_illustration/2d_art_poster", "colors": [{"r": c[0], "g": c[1], "b": c[2]} for c in (SCENE_COLORS if name in SCENES else COLORS)]})
    url = res["images"][0]["url"]
    if name in SCENES:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "appstore-art/1.0"}), timeout=120) as r:
            im = chroma_key(Image.open(io.BytesIO(r.read())))
    else:
        cut = run("fal-ai/birefnet", {"image_url": url, "output_format": "png"})
        with urllib.request.urlopen(urllib.request.Request(cut["image"]["url"], headers={"User-Agent": "appstore-art/1.0"}), timeout=120) as r:
            im = Image.open(io.BytesIO(r.read())).convert("RGBA")
    if name not in SCENES:
        im = im.crop(im.getbbox())
    if max(im.size) > 900:
        k = 900 / max(im.size); im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / f"{name}{SUFFIX}.png", optimize=True)
    print(name, im.size, flush=True)

SUFFIX = os.environ.get("SUFFIX", "")   # to keep several takes of one prompt

if __name__ == "__main__":
    if not KEY: sys.exit("FAL_KEY manquant")
    names = sys.argv[1].split(",") if len(sys.argv) > 1 else list(PROMPTS)
    from concurrent.futures import ThreadPoolExecutor
    def safe(n):
        try: make(n)
        except Exception as e: print("ECHEC", n, repr(e)[:200], getattr(e, "read", lambda: b"")()[:300], flush=True)
    with ThreadPoolExecutor(5) as ex: list(ex.map(safe, names))
