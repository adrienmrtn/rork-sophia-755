#!/usr/bin/env python3
"""CRS-1 quiz naturalness: glossary, informal chrono CTAs, known term bugs.

Patches iOS catalogs ``ios/Sophia/Resources/Locales/courses.<lang>.json``
and keeps ``content/locales/<lang>/quizzes_v2.json`` in sync.

Does not touch lesson bodies (CoursesV2 / catalog lessons).

Usage:
    python scripts/naturalness_quiz.py
    python scripts/naturalness_quiz.py --check
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS_LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
CONTENT_LOCALES = ROOT / "content" / "locales"

LANGS = [
    "en", "es", "de", "pt", "it", "tr", "pl", "ro", "nl",
    "el", "sv", "hu", "bg", "cs",
]

# Established local form of FR « Hégire ». Romanian keeps Hegira.
HIJRA = {
    "en": "Hijra",
    "es": "Hégira",
    "de": "Hidschra",
    "pt": "Hégira",
    "it": "Egira",
    "tr": "Hicret",
    "pl": "Hidżra",
    "ro": "Hegira",
    "nl": "Hidjra",
    "el": "Εγίρα",
    "sv": "Hidjra",
    "hu": "hidzsra",
    "bg": "хиджра",
    "cs": "hidžra",
}

# Greek-hero name. Do not apply next to Grant / Joyce / the novel.
ODYSSEUS = {
    "en": "Odysseus",
    "es": "Ulises",
    "de": "Odysseus",
    "pt": "Ulisses",
    "it": "Ulisse",
    "tr": "Odysseus",
    "pl": "Odyseusz",
    "ro": "Ulise",
    "nl": "Odysseus",
    "el": "Οδυσσέας",
    "sv": "Odysseus",
    "hu": "Odüsszeusz",
    "bg": "Одисей",
    "cs": "Odysseus",
}

# Formal / shop-order chrono stems → informal sequence CTA (SYS-8 + SYS-12).
CHRONO_PREFIX = {
    "es": [("Coloque estos ", "Coloca estos "), ("Coloque estas ", "Coloca estas ")],
    "de": [
        ("Ordnen Sie diese ", "Ordne diese "),
        ("Ordnen Sie die ", "Ordne die "),
        ("Bringen Sie diese ", "Bring diese "),
        ("Lassen Sie uns diese ", "Ordne diese "),
    ],
    "pt": [
        ("Coloque esses ", "Coloca esses "),
        ("Coloque essas ", "Coloca essas "),
        ("Coloque estas ", "Coloca estas "),
        ("Coloque estes ", "Coloca estes "),
        ("Coloque em ordem ", "Coloca em ordem "),
        ("Coloque por ordem ", "Coloca por ordem "),
    ],
    "el": [
        ("Βάλτε αυτά ", "Βάλε αυτά "),
        ("Βάλτε αυτές ", "Βάλε αυτές "),
        ("Βάλτε σε σειρά ", "Βάλε σε σειρά "),
        ("Βάλτε με τη σειρά ", "Βάλε με τη σειρά "),
        ("Βάλτε σε τάξη ", "Βάλε σε τάξη "),
    ],
    "bg": [
        ("Поставете тези ", "Подреди тези "),
        ("Поставете в реда ", "Подреди в реда "),
    ],
    "cs": [
        ("Seřaďte tyto ", "Seřaď tyto "),
        ("Seřaďte tato ", "Seřaď tato "),
        ("Seřaďte do pořadí ", "Seřaď do pořadí "),
    ],
    "ro": [
        ("Puneți aceste ", "Pune aceste "),
        ("Puneți acești ", "Pune acești "),
        ("Puneți în ordinea ", "Pune în ordinea "),
    ],
    "hu": [("Tegye ezeket ", "Tedd ezeket "), ("Helyezze ezeket ", "Tedd ezeket ")],
    "tr": [("Şu olayları kronolojik ", "Bu olayları kronolojik ")],
}

# Whole-string or regex patches that are safe (one language).
EXTRA_REGEX: dict[str, list[tuple[str, str]]] = {
    "en": [
        (r"\bMermaids episode\b", "Sirens episode"),
        (r"\bthe Hegira\b", "the Hijra"),
        (r"\bHegira\b", "Hijra"),
    ],
    "de": [
        (r"\bdie Hegira\b", "die Hidschra"),
        (r"\bHegira\b", "Hidschra"),
        (r"\u200b", ""),  # leftover bidi junk from MT
        (r"\bwenn Sie\b", "wenn du"),
        (r"\bWenn Sie\b", "Wenn du"),
        (r"Wie bezeichnen Sie ", "Wie nennst du "),
        (r"berechtigt Sie ", "berechtigt dich "),
    ],
    "pl": [(r"\bHegira\b", "Hidżra")],
    "nl": [
        (r"\bde Hegira\b", "de Hidjra"),
        (r"\bHegira\b", "Hidjra"),
        (r"Welke grond staat u volgens het Verdrag van Genève",
         "Welke grond heb je volgens het Verdrag van Genève"),
    ],
    "el": [
        (r"\bHegira\b", "Εγίρα"),
        (r"η Hegira", "η Εγίρα"),
    ],
    "sv": [
        (r"\bHegira\b", "Hidjra"),
    ],
    "hu": [
        (r"\bHegira\b", "hidzsra"),
        (r"a Hegira", "a hidzsra"),
    ],
    "cs": [(r"\bHegira\b", "hidžra")],
    "ro": [],  # Hegira is the Romanian form
}


# Leftover English / French work titles inside already-translated quizzes.
TITLE_LEFTOVER: dict[str, list[tuple[str, str]]] = {
    "es": [
        ("The Red and the Black", "Rojo y negro"),
        ("The Alchemist", "El alquimista"),
        ("Les Fleurs du Mal", "Las flores del mal"),
    ],
    "de": [
        ("The Red and the Black", "Rot und Schwarz"),
        ("The Alchemist", "Der Alchimist"),
        ("Les Fleurs du Mal", "Die Blumen des Bösen"),
    ],
    "pt": [
        ("The Red and the Black", "O Vermelho e o Negro"),
        ("The Alchemist", "O Alquimista"),
        ("Les Fleurs du Mal", "As Flores do Mal"),
    ],
    "it": [
        ("The Red and the Black", "Il rosso e il nero"),
        ("The Alchemist", "L'alchimista"),
        ("Les Fleurs du Mal", "I fiori del male"),
    ],
    "tr": [
        ("The Red and the Black", "Kırmızı ve Siyah"),
        ("The Alchemist", "Simyacı"),
        ("Les Fleurs du Mal", "Kötülük Çiçekleri"),
    ],
    "pl": [
        ("The Red and the Black", "Czerwone i czarne"),
        ("The Alchemist", "Alchemik"),
        ("Les Fleurs du Mal", "Kwiaty zła"),
    ],
    "ro": [
        ("The Red and the Black", "Roșu și Negru"),
        ("The Alchemist", "Alchimistul"),
        ("Les Fleurs du Mal", "Florile răului"),
    ],
    "nl": [
        ("The Red and the Black", "Het rood en het zwart"),
        ("The Alchemist", "De alchemist"),
        ("Les Fleurs du Mal", "De bloemen van het kwaad"),
    ],
    "el": [
        ("The Red and the Black", "Το κόκκινο και το μαύρο"),
        ("The Alchemist", "Ο αλχημιστής"),
        ("Les Fleurs du Mal", "Τα άνθη του κακού"),
    ],
    "sv": [
        ("The Red and the Black", "Rött och svart"),
        ("The Alchemist", "Alkemisten"),
        ("Les Fleurs du Mal", "Ondskans blommor"),
    ],
    "hu": [
        ("The Red and the Black", "Vörös és fekete"),
        ("The Alchemist", "Az alkimista"),
        ("Les Fleurs du Mal", "A romlás virágai"),
    ],
    "bg": [
        ("The Red and the Black", "Червено и черно"),
        ("The Alchemist", "Алхимикът"),
        ("Les Fleurs du Mal", "Цветя на злото"),
    ],
    "cs": [
        ("The Red and the Black", "Červený a černý"),
        ("The Alchemist", "Alchymista"),
        ("Les Fleurs du Mal", "Květy zla"),
    ],
}


GRANT_OR_JOYCE = re.compile(
    r"Grant|Joyce|Dublin|20th century|XXe|XX\.|20\. század|20\. Jahrhundert|"
    r"veinte|XX secolo|século XX|20\. yüzyıl|XX wieku|secolul XX|"
    r"20e eeuw|20ου αιώνα|1900-talet|20\. stol",
    re.I,
)


def replace_odysseus(text: str, lang: str) -> str:
    if "Ulysses" not in text and "Ulysse" not in text:
        return text
    if GRANT_OR_JOYCE.search(text):
        return text
    name = ODYSSEUS[lang]
    # Keep Joyce's novel and the general if they slipped past the regex.
    def repl_ulysses(m: re.Match[str]) -> str:
        after = text[m.end() : m.end() + 12]
        if after.startswith(" Grant") or after.startswith(" S.") or after.startswith(" S "):
            return m.group(0)
        return name

    text = re.sub(r"\bUlysses\b", repl_ulysses, text)
    if lang != "fr":
        text = re.sub(r"\bUlysse\b", name, text)
    return text


def replace_hijra(text: str, lang: str) -> str:
    target = HIJRA[lang]
    if lang == "ro":
        return text
    text = re.sub(r"\bthe Hegira\b", f"the {target}" if lang == "en" else target, text)
    text = re.sub(r"\bHegira\b", target, text)
    return text


def apply_chrono(text: str, lang: str) -> str:
    for old, new in CHRONO_PREFIX.get(lang, []):
        if text.startswith(old):
            text = new + text[len(old) :]
    return text


def apply_extra(text: str, lang: str) -> str:
    for pat, repl in EXTRA_REGEX.get(lang, []):
        text = re.sub(pat, repl, text)
    return text


def polish_text(text: str, lang: str) -> str:
    if not text:
        return text
    text = apply_extra(text, lang)
    text = replace_hijra(text, lang)
    text = replace_odysseus(text, lang)
    text = apply_chrono(text, lang)
    for old, new in TITLE_LEFTOVER.get(lang, []):
        if old in text:
            text = text.replace(old, new)
    return text


def polish_question(q: dict, lang: str) -> bool:
    changed = False
    for key in ("question", "explanation", "unit"):
        if key in q and isinstance(q[key], str):
            nxt = polish_text(q[key], lang)
            if nxt != q[key]:
                q[key] = nxt
                changed = True
    for key in ("options", "items"):
        if key in q and isinstance(q[key], list):
            nxt = [polish_text(x, lang) if isinstance(x, str) else x for x in q[key]]
            if nxt != q[key]:
                q[key] = nxt
                changed = True
    return changed


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def dump_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def patch_catalog(lang: str, check_only: bool) -> tuple[int, int]:
    path = IOS_LOCALES / f"courses.{lang}.json"
    courses = load_json(path)
    q_changed = 0
    q_total = 0
    by_id: dict[str, list] = {}
    for course in courses:
        quiz = course.get("quiz") or []
        by_id[course["id"]] = quiz
        for q in quiz:
            q_total += 1
            if polish_question(q, lang):
                q_changed += 1
    if not check_only:
        dump_json(path, courses)
        v2_path = CONTENT_LOCALES / lang / "quizzes_v2.json"
        if v2_path.exists():
            v2 = load_json(v2_path)
            for block in v2:
                cid = block.get("courseId")
                if cid in by_id:
                    block["quiz"] = by_id[cid]
            dump_json(v2_path, v2)
    return q_changed, q_total


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    total_changed = 0
    leftover = []
    for lang in LANGS:
        changed, total = patch_catalog(lang, check_only=args.check)
        total_changed += changed
        print(f"[{lang}] {changed}/{total} quiz items changed")
        # leftover Hegira (except RO)
        cat = load_json(IOS_LOCALES / f"courses.{lang}.json")
        quiz_blob = json.dumps(
            [q for c in cat for q in (c.get("quiz") or [])],
            ensure_ascii=False,
        )
        if lang != "ro" and "Hegira" in quiz_blob:
            leftover.append(f"{lang}: leftover Hegira in quizzes")
        if "Mermaids episode" in quiz_blob:
            leftover.append(f"{lang}: leftover Mermaids episode")
    print(f"{'would change' if args.check else 'changed'} {total_changed} quiz items")
    if leftover:
        print("LEFTOVER:", leftover)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
