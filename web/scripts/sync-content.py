#!/usr/bin/env python3
"""Extrait du repo les données et images du site.

Lit le catalogue français embarqué dans l'app (starter pack Android), les cours,
les quiz et les images iOS, puis écrit :
  - web/src/data/catalog.json     tout le catalogue (pages serveur uniquement)
  - web/src/data/showcase.json    petit extrait pour les composants interactifs
  - web/src/data/courses/<slug>.json  introduction, parties et quiz de chaque cours
  - web/public/img/**.webp        images redimensionnées

Lecture seule sur le reste du repo. Relancer après une mise à jour du catalogue :
  python3 web/scripts/sync-content.py
"""
import json
import re
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / "web"
IOS = ROOT / "ios" / "Sophia"
CATALOG = ROOT / "android/app/src/main/assets/starter_pack/fr/catalog.json"
QUIZZES = ROOT / "content/locales/fr/quizzes_v2.json"
COURSES_DIR = ROOT / "content/courses/fr"
DATA = WEB / "src/data"
IMG = WEB / "public/img"

SUBJECTS = [
    ("histoire", "histoire", "Histoire", "Des pyramides à la chute du mur : les tournants qui ont fait le monde."),
    ("sciences", "sciences", "Sciences", "Le corps, l'espace, la matière : les grandes questions et les petits mystères."),
    ("comprendreLeMonde", "comprendre-le-monde", "Comprendre le monde", "Géopolitique, économie, société : les clés de l'actualité."),
    ("litterature", "litterature", "Littérature", "Les classiques et leurs auteurs, racontés comme des histoires."),
    ("mythologie", "mythologie", "Mythologie", "Dieux, héros et monstres, de la Grèce antique aux légendes nordiques."),
    ("art", "art", "Art", "Peinture, musique, cinéma, architecture : les œuvres et ce qu'elles disent."),
]
QUIZ_COURSES = ["101", "262", "41", "162", "149", "203"]
READER_COURSE = "149"
FEATURED = ["149", "262", "101", "41", "162", "203"]
HOUSE = {
    "slug": "redaction",
    "name": "La rédaction Sophia",
    "title": "Équipe éditoriale",
    "bio": "L'équipe éditoriale de Sophia écrit, vérifie et illustre les cours qui ne sont pas encore signés par un auteur invité. Chaque cours est relu avant publication et mis à jour quand la recherche avance.",
    "institution": None,
    "country": None,
    "links": {},
    "photo": "/img/brand/app_icon.webp",
    "verified": True,
}


def num(course_id: str) -> str:
    return course_id.split("_")[1]


def slug_of(course_id: str) -> str:
    return re.sub(r"^course_\d+_", "", course_id).replace("_", "-")


def slugify(text: str) -> str:
    import unicodedata

    t = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", "-", t).strip("-")


def save_webp(src: Path, dest: Path, max_side: int, quality: int = 76) -> bool:
    if not src.exists():
        return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.stat().st_mtime >= src.stat().st_mtime:
        return True
    im = Image.open(src)
    im = im.convert("RGBA" if im.mode in ("RGBA", "LA", "P") else "RGB")
    im.thumbnail((max_side, max_side), Image.LANCZOS)
    im.save(dest, "WEBP", quality=quality, method=6)
    return True


def clean(text: str) -> str:
    return re.sub(r"\[\[([^\]]+)\]\]", r"\1", text)


def main() -> None:
    cat = json.loads(CATALOG.read_text())
    quizzes = {q["courseId"]: q["quiz"] for q in json.loads(QUIZZES.read_text())}
    subject_meta = {sid: (slug, label, blurb) for sid, slug, label, blurb in SUBJECTS}

    # Auteurs
    creators = []
    for cr in cat["creators"]:
        photo = None
        if cr.get("photo"):
            photo = f"/img/authors/{cr['photo']}.webp"
            if not save_webp(IOS / "Resources/AuthorPhotos" / f"{cr['photo']}.jpg", WEB / "public" / photo.lstrip("/"), 400):
                photo = None
        creators.append(
            {
                "slug": cr["slug"],
                "name": cr["name"],
                "title": cr["title"],
                "bio": cr.get("bio") or "",
                "institution": cr.get("institution"),
                "country": cr.get("country"),
                "links": cr.get("links") or {},
                "photo": photo,
                "verified": bool(cr.get("verified")),
                "courses": [],
            }
        )
    by_creator = {c["slug"]: c for c in creators}
    house = {**HOUSE, "courses": []}

    # Collections
    collections = []
    course_cols: dict[str, list[str]] = {}
    for col in cat["collections"]:
        src = IOS / "Assets.xcassets/CollectionCovers" / f"{col['cover']}.imageset" / f"{col['cover']}.jpg"
        img = f"/img/collections/{col['cover']}.webp"
        if not save_webp(src, WEB / "public" / img.lstrip("/"), 900):
            continue
        cslug = slugify(col["title"])
        collections.append(
            {"slug": cslug, "title": col["title"], "description": col.get("description", ""), "image": img, "courses": [slug_of(i) for i in col["courseIds"]]}
        )
        for cid in col["courseIds"]:
            course_cols.setdefault(cid, []).append(cslug)

    # Cours
    if (IMG / "courses").exists():
        shutil.rmtree(IMG / "courses")
    if (DATA / "courses").exists():
        shutil.rmtree(DATA / "courses")
    (DATA / "courses").mkdir(parents=True)
    courses = []
    seen = set()
    for c in cat["courses"]:
        slug = slug_of(c["id"])
        assert slug not in seen, slug
        seen.add(slug)
        img = f"/img/courses/{c['cover']}.webp"
        save_webp(IOS / "CourseImages" / f"{c['cover']}.jpg", WEB / "public" / img.lstrip("/"), 760)
        author = c.get("creator") if c.get("creator") in by_creator else "redaction"
        sslug, slabel, _ = subject_meta[c["subject"]]
        entry = {
            "slug": slug,
            "n": int(num(c["id"])),
            "title": c["title"],
            "subtitle": c.get("subtitle") or "",
            "hook": c.get("hook") or c.get("description") or "",
            "description": c.get("description") or "",
            "subject": sslug,
            "subjectLabel": slabel,
            "subcategory": c.get("subcategory") or "",
            "image": img,
            "quizCount": c.get("quizCount", 0),
            "author": author,
            "collections": course_cols.get(c["id"], []),
        }
        courses.append(entry)
        (by_creator.get(author) or house)["courses"].append(slug)

        detail = json.loads((COURSES_DIR / f"{c['id']}.json").read_text())
        intro = []
        for b in detail["sections"][0]["blocks"]:
            if b["type"] == "paragraph":
                intro.append({"type": "paragraph", "text": clean(b["text"])})
            elif b["type"] == "funFact":
                intro.append({"type": "funFact", "text": clean(b["text"])})
        teaser = next(
            (clean(b["text"]) for s in detail["sections"][1:2] for b in s["blocks"] if b["type"] == "paragraph"),
            "",
        )
        mcq = next((q for q in quizzes.get(c["id"], []) if q.get("type") == "mcq"), None)
        body = {
            "intro": intro,
            "sections": [s["title"] for s in detail["sections"]],
            "teaser": teaser[:420],
            "quiz": {k: mcq[k] for k in ("question", "options", "correctIndex", "explanation")} if mcq else None,
        }
        (DATA / "courses" / f"{slug}.json").write_text(json.dumps(body, ensure_ascii=False))

    by_num = {c["n"]: c for c in courses}

    subjects = []
    for sid, sslug, label, blurb in SUBJECTS:
        own = [c for c in courses if c["subject"] == sslug]
        subs: dict[str, list[str]] = {}
        for c in own:
            subs.setdefault(c["subcategory"] or "Autres", []).append(c["slug"])
        subjects.append(
            {"slug": sslug, "label": label, "blurb": blurb, "count": len(own), "subcategories": [{"title": k, "courses": v} for k, v in subs.items()]}
        )

    for i in range(1, 7):
        save_webp(IOS / "Resources/ReviewAvatars" / f"review_avatar_{i}.jpg", IMG / f"avatars/review_{i}.webp", 160)
    for p in sorted((IOS / "Resources/UniversityLogos").glob("*.png")):
        save_webp(p, IMG / f"universities/{p.stem}.webp", 400, 90)
    brand = IMG / "brand"
    save_webp(IOS / "Assets.xcassets/sophia_mark.imageset/sophia_mark.png", brand / "sophia_logo.webp", 600, 92)
    save_webp(IOS / "Assets.xcassets/logo_white.imageset/logo_white.png", brand / "sophia_logo_white.webp", 600, 92)
    icon = ROOT / "Sophia/Assets.xcassets/AppIcon.appiconset/icon.png"
    save_webp(icon, brand / "app_icon.webp", 256, 92)
    Image.open(icon).convert("RGB").resize((180, 180), Image.LANCZOS).save(WEB / "src/app/apple-icon.png")
    Image.open(icon).convert("RGB").resize((64, 64), Image.LANCZOS).save(WEB / "src/app/icon.png")

    stats = {
        "courses": len(courses),
        "collections": len(collections),
        "creators": len(creators),
        "languages": len(list(IOS.glob("*.lproj"))),
        "quizQuestions": sum(c.get("quizCount", 0) for c in cat["courses"]),
    }
    universities = sorted(f"/img/universities/{p.stem}.webp" for p in (IOS / "Resources/UniversityLogos").glob("*.png"))

    catalog = {
        "stats": stats,
        "courses": courses,
        "creators": creators + [house],
        "collections": collections,
        "subjects": subjects,
        "universities": universities,
        "featured": [by_num[int(n)]["slug"] for n in FEATURED],
    }
    (DATA / "catalog.json").write_text(json.dumps(catalog, ensure_ascii=False))

    # Petit extrait pour les composants interactifs (envoyé au navigateur).
    authors = {c["slug"]: c for c in creators + [house]}

    def card(c: dict) -> dict:
        a = authors[c["author"]]
        return {
            "slug": c["slug"], "title": c["title"], "hook": c["hook"], "image": c["image"], "subject": c["subjectLabel"],
            "quizCount": c["quizCount"], "subtitle": c["subtitle"],
            "author": {"name": a["name"], "title": a["title"], "photo": a["photo"], "slug": a["slug"]},
        }

    quiz = []
    for n in QUIZ_COURSES:
        c = by_num[int(n)]
        q = json.loads((DATA / "courses" / f"{c['slug']}.json").read_text())["quiz"]
        quiz.append({**q, "course": c["title"], "slug": c["slug"], "image": c["image"]})
    rc = by_num[int(READER_COURSE)]
    rbody = json.loads((DATA / "courses" / f"{rc['slug']}.json").read_text())
    showcase = {
        "stats": stats,
        "universities": universities,
        "quiz": quiz,
        "reader": {**card(rc), "paragraphs": [b["text"] for b in rbody["intro"] if b["type"] == "paragraph"][:3], "sections": rbody["sections"], "quiz": rbody["quiz"]},
        "heroFeed": [card(by_num[int(n)]) for n in FEATURED],
    }
    (DATA / "showcase.json").write_text(json.dumps(showcase, ensure_ascii=False, indent=1))
    print("OK", stats, "pages cours :", len(courses))


if __name__ == "__main__":
    main()
