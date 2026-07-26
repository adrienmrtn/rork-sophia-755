#!/usr/bin/env python3
"""Translate EN locale catalog JSON (courses / glossary / collections) → new langs.

Source of truth: ``ios/Sophia/Resources/Locales/*.{en}.json``.
Does not modify French Swift sources. Preserves ids, subject keys, quiz
structure, and ``<>`` / ``**`` markup (angle links remapped via glossary).

Usage:
    python scripts/translate_locale_catalog.py --lang tr --workers 10
    python scripts/translate_locale_catalog.py --lang all --workers 10
    python scripts/translate_locale_catalog.py --lang nl --limit 3   # gate
    python scripts/translate_locale_catalog.py qa --lang all
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import unicodedata
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from i18n_languages import NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
CACHE_DIR = ROOT / "content" / "locales" / "_catalog_mt_cache"
CONTENT_LOCALES = ROOT / "content" / "locales"

EXISTING = {"fr", "en", "es", "de", "pt", "it"}
NEW_LANGS = [c for c in NON_FR_LANGS if c not in EXISTING]

TRUE_FALSE = {
    "tr": ["Doğru", "Yanlış"],
    "pl": ["Prawda", "Fałsz"],
    "ro": ["Adevărat", "Fals"],
    "nl": ["Waar", "Onwaar"],
    "el": ["Σωστό", "Λάθος"],
    "sv": ["Sant", "Falskt"],
    "hu": ["Igaz", "Hamis"],
    "bg": ["Вярно", "Грешно"],
    "cs": ["Pravda", "Nepravda"],
}

# Common short lesson titles — keep imperative/app sense consistent.
FIXED_TITLES: dict[str, dict[str, str]] = {
    "Introduction": {
        "tr": "Giriş",
        "pl": "Wprowadzenie",
        "ro": "Introducere",
        "nl": "Inleiding",
        "el": "Εισαγωγή",
        "sv": "Introduktion",
        "hu": "Bevezetés",
        "bg": "Въведение",
        "cs": "Úvod",
    },
    "Conclusion": {
        "tr": "Sonuç",
        "pl": "Zakończenie",
        "ro": "Concluzie",
        "nl": "Conclusie",
        "el": "Συμπέρασμα",
        "sv": "Slutsats",
        "hu": "Összegzés",
        "bg": "Заключение",
        "cs": "Závěr",
    },
}

SKIP_STRUCT_KEYS = {
    "id",
    "type",
    "subject",
    "courseIds",
    "correctIndex",
    "correctValue",
    "sliderMin",
    "sliderMax",
    "min",
    "max",
    "step",
    "tolerance",
    "classification",
}

ANGLE_RE = re.compile(r"<([^<>]+)>")
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")
SEN_B0, SEN_B1 = "ZZBOLDZZ", "ZZENDBOLDZZ"


def is_passthrough(text: str) -> bool:
    s = (text or "").strip()
    if not s:
        return True
    if s.isdigit():
        return True
    if re.fullmatch(r"[\d\s./–—:%°+\-]+", s):
        return True
    if not re.search(r"[A-Za-zÀ-ÿΑ-ωА-я]", s):
        return True
    return False


def protect_markup(text: str) -> tuple[str, list[str]]:
    """Opaque-protect <> links; visible-protect **bold** inners for MT."""
    angles: list[str] = []

    def angle_sub(match: re.Match[str]) -> str:
        angles.append(match.group(1))
        return f"ZZA{len(angles) - 1}ZZ"

    text = ANGLE_RE.sub(angle_sub, text)
    text = BOLD_RE.sub(lambda m: f"{SEN_B0}{m.group(1)}{SEN_B1}", text)
    return text, angles


def restore_markup(text: str, angles: list[str], term_map: dict[str, str] | None = None) -> str:
    # Normalize bold sentinels
    text = re.sub(r"zz\s*end\s*bold\s*zz", SEN_B1, text, flags=re.I)
    text = re.sub(r"zz\s*bold\s*zz", SEN_B0, text, flags=re.I)
    text = re.sub(
        re.escape(SEN_B0) + r"\s*(.*?)\s*" + re.escape(SEN_B1),
        lambda m: f"**{m.group(1).strip()}**",
        text,
        flags=re.DOTALL | re.I,
    )
    term_map = term_map or {}
    for idx, original in enumerate(angles):
        mapped = term_map.get(original, original)
        for token in (f"ZZA{idx}ZZ", f"zza{idx}zz", f"ZZA {idx} ZZ"):
            if token in text:
                text = text.replace(token, f"<{mapped}>")
                break
        else:
            # Soft: if marker lost, leave content (link may fuzzy-match later).
            pass
    return text


def _translate_one(target: str, text: str) -> str:
    from deep_translator import GoogleTranslator

    if not text or not text.strip():
        return text
    client = GoogleTranslator(source="en", target=target)
    for attempt in range(6):
        try:
            result = client.translate(text)
            if result is None:
                raise RuntimeError("empty")
            return result
        except Exception as error:  # noqa: BLE001
            time.sleep(min(2**attempt, 20))
            client = GoogleTranslator(source="en", target=target)
            if attempt == 5:
                print(f"    warn MT keep EN: {text[:50]!r} ({error})", file=sys.stderr)
                return text
    return text


class CatalogTranslator:
    def __init__(self, lang: str):
        self.lang = lang
        self.cache_path = CACHE_DIR / f"{lang}.json"
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        self.cache: dict[str, str] = {}
        if self.cache_path.exists():
            self.cache = json.loads(self.cache_path.read_text(encoding="utf-8"))

    def save(self) -> None:
        self.cache_path.write_text(
            json.dumps(self.cache, ensure_ascii=False, indent=0) + "\n",
            encoding="utf-8",
        )

    def translate_plain(self, text: str) -> str:
        if text in FIXED_TITLES and self.lang in FIXED_TITLES[text]:
            return FIXED_TITLES[text][self.lang]
        if is_passthrough(text):
            return text
        if text in self.cache:
            return self.cache[text]
        protected, angles = protect_markup(text)
        # angles empty for plain strings without <>
        if len(protected) < 4000:
            translated = _translate_one(self.lang, protected)
        else:
            parts = re.split(r"(?<=[.!?…])\s+", protected)
            chunks: list[str] = []
            buf = ""
            for part in parts:
                if len(buf) + len(part) + 1 > 3800 and buf:
                    chunks.append(_translate_one(self.lang, buf))
                    buf = part
                else:
                    buf = f"{buf} {part}".strip() if buf else part
            if buf:
                chunks.append(_translate_one(self.lang, buf))
            translated = " ".join(chunks)
        translated = restore_markup(translated, angles, None)
        self.cache[text] = translated
        return translated

    def translate_rich(self, text: str, term_map: dict[str, str]) -> str:
        if is_passthrough(text):
            return text
        cache_key = text
        # Don't use plain cache for rich remap — always apply term_map on restore.
        protected, angles = protect_markup(text)
        # Cache on protected form without angles? Use original + lang map version.
        # Simpler: cache MT of protected text keyed by protected string.
        mt_key = f"rich::{protected}"
        if mt_key in self.cache:
            translated = self.cache[mt_key]
        elif len(protected) < 4000:
            translated = _translate_one(self.lang, protected)
            self.cache[mt_key] = translated
        else:
            parts = re.split(r"(?<=[.!?…])\s+", protected)
            chunks: list[str] = []
            buf = ""
            for part in parts:
                if len(buf) + len(part) + 1 > 3800 and buf:
                    chunks.append(_translate_one(self.lang, buf))
                    buf = part
                else:
                    buf = f"{buf} {part}".strip() if buf else part
            if buf:
                chunks.append(_translate_one(self.lang, buf))
            translated = " ".join(chunks)
            self.cache[mt_key] = translated
        # Also store plain for reuse of non-rich identical strings
        result = restore_markup(translated, angles, term_map)
        self.cache[cache_key] = result
        return result

    def warmup(self, texts: list[str], workers: int) -> None:
        pending = []
        for text in texts:
            if is_passthrough(text):
                continue
            if text in FIXED_TITLES:
                continue
            protected, _angles = protect_markup(text)
            mt_key = f"rich::{protected}" if _angles else text
            if mt_key in self.cache or text in self.cache:
                continue
            pending.append(text)
        # Dedupe preserving order
        seen: set[str] = set()
        unique: list[str] = []
        for t in pending:
            if t not in seen:
                seen.add(t)
                unique.append(t)
        if not unique:
            print(f"  [{self.lang}] cache warm ({len(self.cache)} entries, 0 new)")
            return
        print(f"  [{self.lang}] warming {len(unique)} strings (workers={workers})…")

        def job(src: str) -> tuple[str, str, str]:
            protected, angles = protect_markup(src)
            if len(protected) < 4000:
                translated = _translate_one(self.lang, protected)
            else:
                parts = re.split(r"(?<=[.!?…])\s+", protected)
                chunks: list[str] = []
                buf = ""
                for part in parts:
                    if len(buf) + len(part) + 1 > 3800 and buf:
                        chunks.append(_translate_one(self.lang, buf))
                        buf = part
                    else:
                        buf = f"{buf} {part}".strip() if buf else part
                if buf:
                    chunks.append(_translate_one(self.lang, buf))
                translated = " ".join(chunks)
            mt_key = f"rich::{protected}" if angles else src
            restored = restore_markup(translated, angles, None)
            return mt_key, translated if angles else restored, restored

        done = 0
        with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
            futs = [pool.submit(job, src) for src in unique]
            for fut in as_completed(futs):
                mt_key, stored, restored = fut.result()
                self.cache[mt_key] = stored
                # Also index by restored plaintext path for plain lookups
                done += 1
                if done % 100 == 0 or done == len(unique):
                    print(f"  [{self.lang}] cached {done}/{len(unique)}")
                    self.save()
        self.save()


def collect_warmup_strings(
    courses: list[dict],
    glossary: dict[str, dict],
    collections: list[dict],
    limit: int,
) -> list[str]:
    out: list[str] = []
    use = courses[:limit] if limit else courses
    course_ids = {c["id"] for c in use}
    for key, entry in glossary.items():
        if "|" in key and key.split("|", 1)[0] not in course_ids:
            continue
        out.append(entry.get("displayTerm") or "")
        out.append(entry.get("explanation") or "")
    # Collections are tiny — always include.
    for col in collections:
        out.append(col.get("title") or "")
        out.append(col.get("description") or "")
    for course in use:
        out.append(course.get("title") or "")
        out.append(course.get("description") or "")
        out.append(course.get("subcategory") or "")
        for lesson in course.get("lessons") or []:
            out.append(lesson.get("title") or "")
            out.append(lesson.get("content") or "")
        for q in course.get("quiz") or []:
            out.append(q.get("question") or "")
            out.append(q.get("explanation") or "")
            out.append(q.get("unit") or "")
            for opt in q.get("options") or []:
                out.append(opt)
            for item in q.get("items") or []:
                out.append(item)
    return out


def translate_glossary(
    en_gloss: dict[str, dict],
    translator: CatalogTranslator,
    course_ids: set[str] | None = None,
) -> tuple[dict[str, dict], dict[str, dict[str, str]]]:
    """Return translated glossary + per-course EN→locale displayTerm map."""
    out: dict[str, dict] = {}
    term_maps: dict[str, dict[str, str]] = {}
    for key, entry in en_gloss.items():
        if "|" not in key:
            continue
        cid, en_term = key.split("|", 1)
        if course_ids is not None and cid not in course_ids:
            continue
        loc_term = translator.translate_plain(en_term).strip() or en_term
        loc_expl = translator.translate_plain(entry.get("explanation") or "")
        new_key = f"{cid}|{loc_term}"
        if new_key not in out:
            out[new_key] = {
                "displayTerm": loc_term,
                "classification": entry.get("classification") or "concept",
                "explanation": loc_expl,
            }
        term_maps.setdefault(cid, {})[en_term] = loc_term
    return out, term_maps


def translate_collections(
    en_cols: list[dict], translator: CatalogTranslator
) -> list[dict]:
    out = []
    for col in en_cols:
        out.append(
            {
                "id": col["id"],
                "title": translator.translate_plain(col.get("title") or ""),
                "description": translator.translate_plain(col.get("description") or ""),
                "courseIds": list(col.get("courseIds") or []),
            }
        )
    return out


def translate_quiz(q: dict, translator: CatalogTranslator) -> dict:
    out = {k: v for k, v in q.items() if k in SKIP_STRUCT_KEYS or k == "id" or k == "type"}
    # Ensure structural fields copied
    for k in (
        "id",
        "type",
        "correctIndex",
        "correctValue",
        "sliderMin",
        "sliderMax",
        "tolerance",
        "min",
        "max",
        "step",
    ):
        if k in q:
            out[k] = q[k]
    out["question"] = translator.translate_plain(q.get("question") or "")
    out["explanation"] = translator.translate_plain(q.get("explanation") or "")
    if q.get("type") == "trueFalse":
        out["options"] = list(TRUE_FALSE.get(translator.lang, ["True", "False"]))
    elif "options" in q:
        out["options"] = [translator.translate_plain(o) for o in q.get("options") or []]
    if "items" in q:
        out["items"] = [translator.translate_plain(i) for i in q.get("items") or []]
    if "unit" in q:
        unit = q.get("unit") or ""
        out["unit"] = unit if is_passthrough(unit) else translator.translate_plain(unit)
    return out


def translate_courses(
    en_courses: list[dict],
    translator: CatalogTranslator,
    term_maps: dict[str, dict[str, str]],
    limit: int,
) -> list[dict]:
    use = en_courses[:limit] if limit else en_courses
    out: list[dict] = []
    for course in use:
        cid = course["id"]
        term_map = term_maps.get(cid, {})
        lessons = []
        for lesson in course.get("lessons") or []:
            lessons.append(
                {
                    "id": lesson["id"],
                    "title": translator.translate_plain(lesson.get("title") or ""),
                    "content": translator.translate_rich(
                        lesson.get("content") or "", term_map
                    ),
                }
            )
        quiz = [translate_quiz(q, translator) for q in course.get("quiz") or []]
        out.append(
            {
                "id": cid,
                "title": translator.translate_plain(course.get("title") or ""),
                "description": translator.translate_plain(course.get("description") or ""),
                "subject": course.get("subject"),
                "subcategory": translator.translate_plain(course.get("subcategory") or ""),
                "lessons": lessons,
                "quiz": quiz,
            }
        )
    # If limit mode, pad with remaining EN courses so counts stay 239? No —
    # gate mode writes only limited set for smoke; full run writes all.
    if limit and limit < len(en_courses):
        # For gate, only write the translated slice — caller should not ship.
        pass
    return out


def write_json(path: Path, data: object) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def translate_lang(lang: str, workers: int, limit: int, force_warmup: bool) -> None:
    if lang not in NEW_LANGS:
        raise SystemExit(f"lang {lang} not in {NEW_LANGS}")

    en_courses = json.loads((LOCALE_DIR / "courses.en.json").read_text(encoding="utf-8"))
    en_gloss = json.loads((LOCALE_DIR / "glossary.en.json").read_text(encoding="utf-8"))
    en_cols = json.loads((LOCALE_DIR / "collections.en.json").read_text(encoding="utf-8"))

    translator = CatalogTranslator(lang)
    if force_warmup:
        # Drop cache entries? keep — force just re-warms missing
        pass

    warmup = collect_warmup_strings(en_courses, en_gloss, en_cols, limit)
    translator.warmup(warmup, workers=workers)

    use_courses = en_courses[:limit] if limit else en_courses
    course_ids = {c["id"] for c in use_courses}

    print(f"  [{lang}] translating glossary (scoped={bool(limit)})…")
    if limit:
        # Gate: translate glossary for selected courses only; keep EN for the rest
        # so the bundled file stays complete and loadable.
        partial, term_maps = translate_glossary(en_gloss, translator, course_ids)
        new_gloss = dict(en_gloss)
        # Drop EN keys for scoped courses, replace with translated keys.
        for key in list(new_gloss):
            if "|" in key and key.split("|", 1)[0] in course_ids:
                del new_gloss[key]
        new_gloss.update(partial)
    else:
        new_gloss, term_maps = translate_glossary(en_gloss, translator, None)
    translator.save()

    print(f"  [{lang}] translating collections ({len(en_cols)})…")
    new_cols = translate_collections(en_cols, translator)
    translator.save()

    n = len(use_courses)
    print(f"  [{lang}] translating courses ({n}/{len(en_courses)})…")
    head = translate_courses(en_courses, translator, term_maps, limit)
    if limit:
        new_courses = head + en_courses[limit:]
    else:
        new_courses = head
    translator.save()

    write_json(LOCALE_DIR / f"courses.{lang}.json", new_courses)
    write_json(LOCALE_DIR / f"glossary.{lang}.json", new_gloss)
    write_json(LOCALE_DIR / f"collections.{lang}.json", new_cols)

    # Mirror lightweight metadata under content/locales for traceability.
    meta_dir = CONTENT_LOCALES / lang
    meta_dir.mkdir(parents=True, exist_ok=True)
    write_json(
        meta_dir / "catalog_meta.json",
        {
            "lang": lang,
            "courses": len(new_courses),
            "glossary": len(new_gloss),
            "collections": len(new_cols),
            "source": "en",
        },
    )
    print(
        f"  [{lang}] wrote courses={len(new_courses)} glossary={len(new_gloss)} "
        f"collections={len(new_cols)}"
    )


def qa(langs: list[str]) -> int:
    en_c = json.loads((LOCALE_DIR / "courses.en.json").read_text(encoding="utf-8"))
    en_g = json.loads((LOCALE_DIR / "glossary.en.json").read_text(encoding="utf-8"))
    en_col = json.loads((LOCALE_DIR / "collections.en.json").read_text(encoding="utf-8"))
    en_ids = [c["id"] for c in en_c]
    en_col_ids = [c["id"] for c in en_col]
    hard = 0
    for lang in langs:
        courses = json.loads((LOCALE_DIR / f"courses.{lang}.json").read_text(encoding="utf-8"))
        gloss = json.loads((LOCALE_DIR / f"glossary.{lang}.json").read_text(encoding="utf-8"))
        cols = json.loads((LOCALE_DIR / f"collections.{lang}.json").read_text(encoding="utf-8"))
        ids = [c["id"] for c in courses]
        col_ids = [c["id"] for c in cols]
        print(
            f"{lang}: courses={len(courses)} glossary={len(gloss)} collections={len(cols)}"
        )
        if ids != en_ids:
            print(f"  HARD course id mismatch")
            hard += 1
        if col_ids != en_col_ids:
            print(f"  HARD collection id mismatch")
            hard += 1
        if len(cols) != 31:
            print(f"  HARD collections != 31")
            hard += 1
        # Still EN stub? title of course 0 equal to EN
        if courses and courses[0].get("title") == en_c[0].get("title"):
            print(f"  HARD course[0] title still English")
            hard += 1
        if cols and cols[0].get("title") == en_col[0].get("title"):
            print(f"  HARD collection[0] title still English")
            hard += 1
        # Glossary should be roughly EN size (aliases may grow later)
        if len(gloss) < len(en_g) * 0.9:
            print(f"  HARD glossary too small {len(gloss)} < 0.9*{len(en_g)}")
            hard += 1
        # Spot: first course lessons/quiz counts
        if courses[0].get("lessons") and len(courses[0]["lessons"]) != len(en_c[0]["lessons"]):
            print("  HARD lesson count drift course0")
            hard += 1
        if len(courses[0].get("quiz") or []) != len(en_c[0].get("quiz") or []):
            print("  HARD quiz count drift course0")
            hard += 1
        # Ensure not French bleed on title (heuristic: common FR words)
        title = courses[0].get("title") or ""
        if re.search(r"\b(le|la|les|des|une|naissance)\b", title, re.I) and lang != "fr":
            # weak — only warn
            print(f"  soft possible FR bleed in title: {title!r}")
    if hard:
        print(f"QA FAIL hard={hard}")
        return 1
    print("QA PASS")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", help="Language code or all")
    parser.add_argument("--workers", type=int, default=10)
    parser.add_argument("--limit", type=int, default=0, help="Translate only first N courses")
    parser.add_argument("--force-warmup", action="store_true")
    sub = parser.add_subparsers(dest="cmd")
    q = sub.add_parser("qa")
    q.add_argument("--lang", default="all")

    args, _unknown = parser.parse_known_args()
    if args.cmd == "qa":
        langs = NEW_LANGS if args.lang == "all" else [args.lang]
        return qa(langs)

    if not args.lang:
        parser.error("--lang is required (or use qa)")
    langs = NEW_LANGS if args.lang == "all" else [args.lang]
    for lang in langs:
        print(f"=== {lang} ===")
        translate_lang(lang, workers=args.workers, limit=args.limit, force_warmup=args.force_warmup)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
