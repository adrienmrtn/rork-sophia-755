#!/usr/bin/env python3
"""Extrait du repo les données et images de la vitrine.

Lit le catalogue français embarqué dans l'app (starter pack Android), les quiz,
les cours et les images iOS, puis écrit :
  - web/src/data/site.json
  - web/public/img/**.webp (images redimensionnées)

Lecture seule sur le reste du repo. Relancer après une mise à jour du catalogue :
  python3 web/scripts/sync-content.py
"""
import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / "web"
IOS = ROOT / "ios" / "Sophia"
CATALOG = ROOT / "android/app/src/main/assets/starter_pack/fr/catalog.json"
QUIZZES = ROOT / "content/locales/fr/quizzes_v2.json"
COURSES_DIR = ROOT / "content/courses/fr"
OUT_JSON = WEB / "src/data/site.json"
OUT_IMG = WEB / "public/img"

SUBJECTS = [
    ("histoire", "Histoire", ["13", "262", "264", "292"]),
    ("sciences", "Sciences", ["41", "42", "281", "304"]),
    ("comprendreLeMonde", "Comprendre le monde", ["203", "212", "220", "226"]),
    ("litterature", "Littérature", ["101", "106", "91", "119"]),
    ("mythologie", "Mythologie", ["162", "172", "179", "181"]),
    ("art", "Art", ["149", "150", "133", "128"]),
]
QUIZ_COURSES = ["101", "262", "41", "162", "149", "203"]
PHONE_COURSE = "101"


def num(course_id: str) -> str:
    return course_id.split("_")[1]


def save_webp(src: Path, dest: Path, max_side: int, quality: int = 78) -> bool:
    if not src.exists():
        return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    im = Image.open(src)
    im = im.convert("RGBA" if im.mode in ("RGBA", "LA", "P") else "RGB")
    im.thumbnail((max_side, max_side), Image.LANCZOS)
    im.save(dest, "WEBP", quality=quality, method=6)
    return True


def strip_markup(text: str) -> str:
    text = re.sub(r"\[\[([^\]]+)\]\]", r"\1", text)
    return text


def main() -> None:
    cat = json.loads(CATALOG.read_text())
    courses = {c["id"]: c for c in cat["courses"]}
    by_num = {num(cid): c for cid, c in courses.items()}

    def course_card(c: dict) -> dict:
        img = f"/img/courses/{c['cover']}.webp"
        save_webp(IOS / "CourseImages" / f"{c['cover']}.jpg", WEB / "public" / img.lstrip("/"), 560)
        return {
            "id": c["id"],
            "title": c["title"],
            "subtitle": c.get("subtitle") or "",
            "hook": c.get("hook") or c.get("description") or "",
            "image": img,
        }

    counts: dict[str, int] = {}
    for c in cat["courses"]:
        counts[c["subject"]] = counts.get(c["subject"], 0) + 1

    subjects = [
        {
            "id": sid,
            "label": label,
            "count": counts.get(sid, 0),
            "courses": [course_card(by_num[n]) for n in picks],
        }
        for sid, label, picks in SUBJECTS
    ]

    collections = []
    for col in cat["collections"]:
        src = IOS / "Assets.xcassets/CollectionCovers" / f"{col['cover']}.imageset" / f"{col['cover']}.jpg"
        img = f"/img/collections/{col['cover']}.webp"
        if save_webp(src, WEB / "public" / img.lstrip("/"), 720):
            collections.append(
                {
                    "id": col["id"],
                    "title": col["title"],
                    "description": col.get("description", ""),
                    "image": img,
                    "count": len(col["courseIds"]),
                }
            )

    creators = []
    for cr in cat["creators"]:
        photo = None
        if cr.get("photo"):
            photo = f"/img/authors/{cr['photo']}.webp"
            if not save_webp(IOS / "Resources/AuthorPhotos" / f"{cr['photo']}.jpg", WEB / "public" / photo.lstrip("/"), 320):
                photo = None
        creators.append(
            {
                "name": cr["name"],
                "title": cr["title"],
                "institution": cr.get("institution"),
                "photo": photo,
                "courses": len(cr["courseIds"]),
            }
        )
    creators.sort(key=lambda c: c["photo"] is None)

    quizzes = {q["courseId"]: q["quiz"] for q in json.loads(QUIZZES.read_text())}
    quiz = []
    for n in QUIZ_COURSES:
        c = by_num[n]
        q = next(x for x in quizzes[c["id"]] if x.get("type") == "mcq")
        quiz.append(
            {
                "question": q["question"],
                "options": q["options"],
                "correctIndex": q["correctIndex"],
                "explanation": q["explanation"],
                "course": c["title"],
                "image": course_card(c)["image"],
            }
        )

    pc = by_num[PHONE_COURSE]
    detail = json.loads((COURSES_DIR / f"{pc['id']}.json").read_text())
    paragraphs = [
        strip_markup(b["text"])
        for b in detail["sections"][0]["blocks"]
        if b.get("type") == "paragraph"
    ][:2]
    phone_course = {**course_card(pc), "paragraphs": paragraphs}

    for i in range(1, 7):
        save_webp(IOS / "Resources/ReviewAvatars" / f"review_avatar_{i}.jpg", OUT_IMG / f"avatars/review_{i}.webp", 160)
    for p in sorted((IOS / "Resources/UniversityLogos").glob("*.png")):
        save_webp(p, OUT_IMG / f"universities/{p.stem}.webp", 400, 90)

    brand = OUT_IMG / "brand"
    save_webp(IOS / "Assets.xcassets/sophia_mark.imageset/sophia_mark.png", brand / "sophia_logo.webp", 600, 92)
    save_webp(IOS / "Assets.xcassets/logo_white.imageset/logo_white.png", brand / "sophia_logo_white.webp", 600, 92)
    icon = ROOT / "Sophia/Assets.xcassets/AppIcon.appiconset/icon.png"
    save_webp(icon, brand / "app_icon.webp", 256, 92)
    Image.open(icon).convert("RGB").resize((180, 180), Image.LANCZOS).save(WEB / "src/app/apple-icon.png")
    Image.open(icon).convert("RGB").resize((64, 64), Image.LANCZOS).save(WEB / "src/app/icon.png")

    universities = sorted(f"/img/universities/{p.stem}.webp" for p in (IOS / "Resources/UniversityLogos").glob("*.png"))
    languages = len(list(IOS.glob("*.lproj")))

    data = {
        "stats": {
            "courses": len(cat["courses"]),
            "collections": len(cat["collections"]),
            "creators": len(cat["creators"]),
            "languages": languages,
            "quizQuestions": sum(c.get("quizCount", 0) for c in cat["courses"]),
        },
        "subjects": subjects,
        "collections": collections,
        "creators": creators,
        "universities": universities,
        "quiz": quiz,
        "phoneCourse": phone_course,
    }
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=1))
    print(f"OK : {OUT_JSON.relative_to(ROOT)}", data["stats"])


if __name__ == "__main__":
    main()
