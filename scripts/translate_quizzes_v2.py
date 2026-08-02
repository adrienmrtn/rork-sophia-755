#!/usr/bin/env python3
"""Port rich FR quizzes (CourseData.swift) → non-FR locale catalogs.

French source of truth: ``ios/Sophia/Services/CourseData.swift`` (8–10 Q/course,
types mcq / trueFalse / chronological / numericSlider / percentageSlider).

Non-FR catalogs historically ship 5 legacy MCQs in
``ios/Sophia/Resources/Locales/courses.<lang>.json``. This script:

  1. Extracts every FR ``QuizQuestion`` into ``content/locales/fr/quizzes_v2.json``
  2. Machine-translates text fields into ``content/locales/<lang>/quizzes_v2.json``
  3. Replaces the ``quiz`` array on each course in ``courses.<lang>.json``
  4. Writes a flat CSV source ``content/locales/<lang>/source/quizzes_v2.csv``

Numeric / structural fields (id, type, correctIndex, correctValue, slider bounds,
tolerance) are copied unchanged. trueFalse options are localized via a fixed map.

Usage:
    python scripts/translate_quizzes_v2.py extract
    python scripts/translate_quizzes_v2.py translate --lang en --only course_1_* --force
    python scripts/translate_quizzes_v2.py merge --lang en
    python scripts/translate_quizzes_v2.py qa --lang en
    python scripts/translate_quizzes_v2.py translate --lang all --workers 10 --force
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from i18n_languages import GT_TARGETS, NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
COURSE_DATA = ROOT / "ios" / "Sophia" / "Services" / "CourseData.swift"
LOCALE_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
CONTENT_LOCALES = ROOT / "content" / "locales"
CACHE_DIR = CONTENT_LOCALES / "_quiz_v2_mt_cache"

LANGS = NON_FR_LANGS

TRUE_FALSE = {
    "en": ["True", "False"],
    "es": ["Verdadero", "Falso"],
    "de": ["Wahr", "Falsch"],
    "pt": ["Verdadeiro", "Falso"],
    "it": ["Vero", "Falso"],
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

# Common slider units — keep symbols; translate word units.
# Every NON_FR lang must have a key here (translate_unit indexes by self.lang).
UNIT_FIXED = {
    "": {lang: "" for lang in LANGS},
    "%": {lang: "%" for lang in LANGS},
    "°C": {lang: "°C" for lang in LANGS},
    "°": {lang: "°" for lang in LANGS},
    "km": {lang: "km" for lang in LANGS},
    "cm": {lang: "cm" for lang in LANGS},
    "ans": {
        "en": "years", "es": "años", "de": "Jahre", "pt": "anos", "it": "anni",
        "tr": "yıl", "pl": "lat", "ro": "ani", "nl": "jaar", "el": "έτη",
        "sv": "år", "hu": "év", "bg": "години", "cs": "let",
    },
    "jours": {
        "en": "days", "es": "días", "de": "Tage", "pt": "dias", "it": "giorni",
        "tr": "gün", "pl": "dni", "ro": "zile", "nl": "dagen", "el": "ημέρες",
        "sv": "dagar", "hu": "nap", "bg": "дни", "cs": "dny",
    },
    "heures": {
        "en": "hours", "es": "horas", "de": "Stunden", "pt": "horas", "it": "ore",
        "tr": "saat", "pl": "godzin", "ro": "ore", "nl": "uur", "el": "ώρες",
        "sv": "timmar", "hu": "óra", "bg": "часа", "cs": "hodin",
    },
    "semaines": {
        "en": "weeks", "es": "semanas", "de": "Wochen", "pt": "semanas", "it": "settimane",
        "tr": "hafta", "pl": "tygodni", "ro": "săptămâni", "nl": "weken", "el": "εβδομάδες",
        "sv": "veckor", "hu": "hét", "bg": "седмици", "cs": "týdnů",
    },
    "fois": {
        "en": "times", "es": "veces", "de": "Mal", "pt": "vezes", "it": "volte",
        "tr": "kez", "pl": "razy", "ro": "ori", "nl": "keer", "el": "φορές",
        "sv": "gånger", "hu": "alkalom", "bg": "пъти", "cs": "krát",
    },
    "millions": {
        "en": "million", "es": "millones", "de": "Millionen", "pt": "milhões", "it": "milioni",
        "tr": "milyon", "pl": "milionów", "ro": "milioane", "nl": "miljoen", "el": "εκατομμύρια",
        "sv": "miljoner", "hu": "millió", "bg": "милиони", "cs": "milionů",
    },
    "milliards": {
        "en": "billion", "es": "miles de millones", "de": "Milliarden", "pt": "bilhões", "it": "miliardi",
        "tr": "milyar", "pl": "miliardów", "ro": "miliarde", "nl": "miljard", "el": "δισεκατομμύρια",
        "sv": "miljarder", "hu": "milliárd", "bg": "милиарди", "cs": "miliard",
    },
    "milliers": {
        "en": "thousands", "es": "miles", "de": "Tausende", "pt": "milhares", "it": "migliaia",
        "tr": "binler", "pl": "tysiące", "ro": "mii", "nl": "duizenden", "el": "χιλιάδες",
        "sv": "tusentals", "hu": "ezrek", "bg": "хиляди", "cs": "tisíce",
    },
}

VALID_TYPES = {
    "mcq",
    "trueFalse",
    "chronological",
    "numericSlider",
    "percentageSlider",
}


# ---------------------------------------------------------------------------
# Swift literal parsing
# ---------------------------------------------------------------------------

def _parse_swift_string(src: str, i: int) -> tuple[str, int]:
    """Parse a Swift string literal starting at src[i] == '\"'."""
    assert src[i] == '"'
    i += 1
    out: list[str] = []
    while i < len(src):
        ch = src[i]
        if ch == "\\":
            if i + 1 >= len(src):
                raise ValueError("unterminated escape")
            nxt = src[i + 1]
            escapes = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}
            out.append(escapes.get(nxt, nxt))
            i += 2
            continue
        if ch == '"':
            return "".join(out), i + 1
        out.append(ch)
        i += 1
    raise ValueError("unterminated string")


def _parse_swift_string_array(src: str, i: int) -> tuple[list[str], int]:
    """Parse `[\"a\", \"b\"]` starting at '['."""
    assert src[i] == "["
    i += 1
    items: list[str] = []
    while i < len(src):
        while i < len(src) and src[i] in " \t\n\r,":
            i += 1
        if i < len(src) and src[i] == "]":
            return items, i + 1
        if src[i] != '"':
            raise ValueError(f"expected string in array at {i}: {src[i:i+40]!r}")
        value, i = _parse_swift_string(src, i)
        items.append(value)
    raise ValueError("unterminated string array")


def _parse_number(src: str, i: int) -> tuple[float | int, int]:
    m = re.match(r"-?\d+(?:\.\d+)?", src[i:])
    if not m:
        raise ValueError(f"expected number at {i}: {src[i:i+20]!r}")
    raw = m.group(0)
    i += len(raw)
    if "." in raw:
        return float(raw), i
    return int(raw), i


def _skip_ws_comma(src: str, i: int) -> int:
    while i < len(src) and src[i] in " \t\n\r,":
        i += 1
    return i


def _extract_call_body(src: str, start: int) -> tuple[str, int]:
    """Given index of 'QuizQuestion(', return (body, index_after_closing_paren)."""
    assert src.startswith("QuizQuestion(", start)
    i = start + len("QuizQuestion(")
    depth = 1
    in_string = False
    escape = False
    begin = i
    while i < len(src):
        ch = src[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            i += 1
            continue
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return src[begin:i], i + 1
        i += 1
    raise ValueError("unterminated QuizQuestion(")


def parse_quiz_question(body: str) -> dict:
    """Parse the inside of QuizQuestion(...) into a dict."""
    fields: dict = {"type": "mcq"}
    i = 0
    while True:
        i = _skip_ws_comma(body, i)
        if i >= len(body):
            break
        m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s*:", body[i:])
        if not m:
            raise ValueError(f"expected field at {i}: {body[i:i+60]!r}")
        key = m.group(1)
        i += m.end()
        i = _skip_ws_comma(body, i)
        if i >= len(body):
            raise ValueError(f"missing value for {key}")

        if body[i] == '"':
            value, i = _parse_swift_string(body, i)
            fields[key] = value
        elif body[i] == "[":
            value, i = _parse_swift_string_array(body, i)
            fields[key] = value
        elif body.startswith(".", i):
            m2 = re.match(r"\.([A-Za-z_][A-Za-z0-9_]*)", body[i:])
            if not m2:
                raise ValueError(f"bad enum at {i}")
            fields[key] = m2.group(1)
            i += m2.end()
        elif body[i].isdigit() or body[i] == "-":
            num, i = _parse_number(body, i)
            fields[key] = num
        else:
            raise ValueError(f"unsupported value for {key} at {i}: {body[i:i+40]!r}")
    return fields


def course_id_from_question_id(qid: str) -> str:
    m = re.match(r"(.+)_q\d+$", qid)
    if not m:
        raise ValueError(f"cannot derive course id from {qid!r}")
    return m.group(1)


def extract_fr_quizzes() -> dict[str, list[dict]]:
    text = COURSE_DATA.read_text(encoding="utf-8")
    by_course: dict[str, list[dict]] = {}
    i = 0
    while True:
        j = text.find("QuizQuestion(", i)
        if j < 0:
            break
        body, end = _extract_call_body(text, j)
        raw = parse_quiz_question(body)
        q = normalize_question(raw)
        cid = course_id_from_question_id(q["id"])
        by_course.setdefault(cid, []).append(q)
        i = end
    return by_course


def normalize_question(raw: dict) -> dict:
    qtype = raw.get("type") or "mcq"
    if qtype not in VALID_TYPES:
        raise ValueError(f"unknown type {qtype} on {raw.get('id')}")
    out: dict = {
        "id": raw["id"],
        "type": qtype,
        "question": raw["question"],
        "explanation": raw.get("explanation") or "",
    }
    if qtype in ("mcq", "trueFalse"):
        out["options"] = list(raw["options"])
        out["correctIndex"] = int(raw["correctIndex"])
    if qtype == "chronological":
        out["items"] = list(raw["items"])
    if qtype in ("numericSlider", "percentageSlider"):
        out["correctValue"] = float(raw["correctValue"])
        out["sliderMin"] = float(raw["sliderMin"])
        out["sliderMax"] = float(raw["sliderMax"])
        out["tolerance"] = float(raw["tolerance"])
        out["unit"] = raw.get("unit") or ""
    return out


# ---------------------------------------------------------------------------
# Validation (hard QA)
# ---------------------------------------------------------------------------

def validate_question(q: dict, *, fr: dict | None = None) -> list[str]:
    errs: list[str] = []
    qid = q.get("id", "?")
    qtype = q.get("type")
    if qtype not in VALID_TYPES:
        errs.append(f"{qid}: bad type {qtype}")
        return errs
    if not isinstance(q.get("question"), str) or not q["question"].strip():
        errs.append(f"{qid}: empty question")
    if not isinstance(q.get("explanation"), str):
        errs.append(f"{qid}: missing explanation")

    if qtype in ("mcq", "trueFalse"):
        opts = q.get("options")
        if not isinstance(opts, list) or not opts:
            errs.append(f"{qid}: missing options")
        else:
            if any(not isinstance(o, str) or not o.strip() for o in opts):
                errs.append(f"{qid}: empty option")
            if qtype == "trueFalse" and len(opts) != 2:
                errs.append(f"{qid}: trueFalse needs 2 options")
            if qtype == "mcq" and not (3 <= len(opts) <= 5):
                errs.append(f"{qid}: mcq needs 3–5 options (got {len(opts)})")
        idx = q.get("correctIndex")
        if not isinstance(idx, int) or opts is None or not (0 <= idx < len(opts)):
            errs.append(f"{qid}: bad correctIndex")

    if qtype == "chronological":
        items = q.get("items")
        if not isinstance(items, list) or not (3 <= len(items) <= 5):
            errs.append(f"{qid}: chronological needs 3–5 items")
        elif any(not isinstance(it, str) or not it.strip() for it in items):
            errs.append(f"{qid}: empty chrono item")
        else:
            # Charte: no years in parentheses in items.
            for it in items:
                if re.search(r"\(\s*\d{3,4}\s*\)", it):
                    errs.append(f"{qid}: year in chrono item {it!r}")

    if qtype in ("numericSlider", "percentageSlider"):
        for key in ("correctValue", "sliderMin", "sliderMax", "tolerance"):
            if not isinstance(q.get(key), (int, float)):
                errs.append(f"{qid}: missing {key}")
        if qtype == "percentageSlider":
            if q.get("sliderMin") != 0 or q.get("sliderMax") != 100:
                errs.append(f"{qid}: percentageSlider must be 0–100")
            if q.get("unit") not in ("%", None, ""):
                # allow missing then normalize
                if q.get("unit") != "%":
                    errs.append(f"{qid}: percentageSlider unit must be %")

    if fr is not None:
        if q.get("id") != fr.get("id"):
            errs.append(f"{qid}: id mismatch vs FR")
        if q.get("type") != fr.get("type"):
            errs.append(f"{qid}: type mismatch vs FR")
        if q.get("correctIndex") != fr.get("correctIndex"):
            errs.append(f"{qid}: correctIndex mismatch")
        for key in ("correctValue", "sliderMin", "sliderMax", "tolerance"):
            if fr.get(key) is not None and q.get(key) != fr.get(key):
                errs.append(f"{qid}: {key} mismatch vs FR")
        if fr.get("type") in ("mcq", "trueFalse"):
            if len(q.get("options") or []) != len(fr.get("options") or []):
                errs.append(f"{qid}: options count mismatch")
        if fr.get("type") == "chronological":
            if len(q.get("items") or []) != len(fr.get("items") or []):
                errs.append(f"{qid}: items count mismatch")
        # Leftover French trueFalse labels outside FR
        if q.get("type") == "trueFalse" and q.get("options") == ["Vrai", "Faux"]:
            errs.append(f"{qid}: trueFalse still French")
        # Sentinel / MT debris
        blob = json.dumps(q, ensure_ascii=False)
        for bad in ("ZZBOLD", "ZZGLOSS", "⟦", "[[]]", "QuizQuestion"):
            if bad in blob:
                errs.append(f"{qid}: leftover {bad}")
    return errs


def validate_catalog(
    by_course: dict[str, list[dict]],
    *,
    fr_by_course: dict[str, list[dict]] | None = None,
) -> list[str]:
    errs: list[str] = []
    if fr_by_course is not None:
        if set(by_course) != set(fr_by_course):
            missing = sorted(set(fr_by_course) - set(by_course))
            extra = sorted(set(by_course) - set(fr_by_course))
            if missing:
                errs.append(f"missing courses: {missing[:5]}… ({len(missing)})")
            if extra:
                errs.append(f"extra courses: {extra[:5]}… ({len(extra)})")
    for cid, questions in by_course.items():
        if not (8 <= len(questions) <= 10):
            errs.append(f"{cid}: expected 8–10 questions, got {len(questions)}")
        ids = [q["id"] for q in questions]
        if len(ids) != len(set(ids)):
            errs.append(f"{cid}: duplicate question ids")
        fr_qs = (fr_by_course or {}).get(cid)
        for index, q in enumerate(questions):
            fr_q = fr_qs[index] if fr_qs and index < len(fr_qs) else None
            if fr_qs and len(fr_qs) != len(questions):
                errs.append(f"{cid}: question count {len(questions)} != FR {len(fr_qs)}")
                break
            errs.extend(validate_question(q, fr=fr_q))
    return errs


# ---------------------------------------------------------------------------
# Translation
# ---------------------------------------------------------------------------

# Sentence-level French markers (exclude particles common in proper names: de/le/la/du).
_FR_SENTENCE = re.compile(
    r"\b(les|des|une|est|sont|dans|pour|avec|qui|que|sur|par|plus|aussi|"
    r"comme|cette|ces|aux|dont|entre|être|avoir|fait|peut|deux|trois|"
    r"c'est|n'est|qu'est|d'un|d'une|lors|après|avant|très|même|mais|"
    r"nous|vous|ils|elles|était|étaient|ont|avait)\b",
    re.I,
)


def _looks_like_proper_name(text: str) -> bool:
    """Heuristic for names / titles MT often leaves unchanged (De Stijl, Le Corbusier…)."""
    words = re.findall(r"[A-Za-zÀ-ÿ']+", text)
    if not words or len(words) > 8:
        return False
    if len(text) > 60:
        return False
    if _FR_SENTENCE.search(text):
        return False
    # Mostly Capitalized tokens (allow lowercase particles de/van/von/di…).
    particles = {"de", "du", "des", "la", "le", "van", "von", "di", "da", "del", "der", "den", "of", "y"}
    caps = 0
    for word in words:
        low = word.lower()
        if low in particles:
            continue
        if word[:1].isupper():
            caps += 1
        else:
            return False
    return caps >= 1


def _looks_translatable_french(text: str) -> bool:
    """True when unchanged MT output would indicate a real failure (not a proper name)."""
    if not text or not re.search(r"[A-Za-zÀ-ÿ]", text):
        return False
    if _looks_like_proper_name(text):
        return False
    words = re.findall(r"[A-Za-zÀ-ÿ']+", text)
    if len(words) <= 3 and not _FR_SENTENCE.search(text):
        return False
    if len(text) <= 24 and text[:1].isupper() and not _FR_SENTENCE.search(text):
        return False
    return bool(_FR_SENTENCE.search(text)) or len(words) >= 6


# Sticky: once Google rate-limits us, skip it for the rest of the process.
_GOOGLE_BLOCKED = False


def _translate_via_bing(target: str, text: str) -> str:
    """Fallback when Google rate-limits (past runs stalled mid-batch)."""
    import translators as ts

    time.sleep(0.22)
    result = ts.translate_text(
        text,
        translator="bing",
        from_language="fr",
        to_language=target,
    )
    if result is None or not str(result).strip():
        raise RuntimeError("empty bing translation")
    return str(result)


def _translate_one(target: str, text: str) -> str:
    """Translate one FR string. Raises on persistent failure — do not cache FR."""
    global _GOOGLE_BLOCKED
    from deep_translator import GoogleTranslator
    from deep_translator.exceptions import TooManyRequests

    if not text or not text.strip():
        return text
    if not re.search(r"[A-Za-zÀ-ÿ]", text):
        return text

    last_error: Exception | None = None
    if not _GOOGLE_BLOCKED:
        client = GoogleTranslator(source="fr", target=target)
        for attempt in range(4):
            try:
                # Stay under Google's ~5 req/s soft limit when many workers run.
                time.sleep(0.18)
                result = client.translate(text)
                if result is None:
                    raise RuntimeError("empty translation")
                return result
            except TooManyRequests as error:
                last_error = error
                _GOOGLE_BLOCKED = True
                print("  Google rate-limited — switching to Bing fallback", flush=True)
                break
            except Exception as error:  # noqa: BLE001
                last_error = error
                time.sleep(min(2 * (2**attempt), 30))
                client = GoogleTranslator(source="fr", target=target)

    # Google daily/burst limit — finish the pack via Bing rather than writing FR.
    for attempt in range(5):
        try:
            return _translate_via_bing(target, text)
        except Exception as error:  # noqa: BLE001
            last_error = error
            time.sleep(min(2 * (2**attempt), 30))
    raise RuntimeError(f"MT failed after retries: {text[:60]!r} ({last_error})")


class QuizTranslator:
    def __init__(self, lang: str):
        self.lang = lang
        self.target = GT_TARGETS[lang]
        self.cache_path = CACHE_DIR / f"{lang}.json"
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        self.cache: dict[str, str] = {}
        if self.cache_path.exists():
            raw = json.loads(self.cache_path.read_text(encoding="utf-8"))
            # Drop identity entries left by older soft-fail caching (FR bleed),
            # but keep legitimate proper-name identities.
            kept: dict[str, str] = {}
            scrubbed = 0
            for key, value in raw.items():
                if value == key and _looks_translatable_french(key):
                    scrubbed += 1
                    continue
                kept[key] = value
            self.cache = kept
            if scrubbed:
                print(f"  scrubbed {scrubbed} FR-identity cache entries", flush=True)
                self.save()

    def save(self) -> None:
        self.cache_path.write_text(
            json.dumps(self.cache, ensure_ascii=False, indent=0) + "\n",
            encoding="utf-8",
        )

    def mt(self, text: str) -> str:
        if text in self.cache:
            return self.cache[text]
        translated = _translate_one(self.target, text)
        if translated == text and _looks_translatable_french(text):
            # Avoid poisoning the cache with untranslated FR sentences.
            raise RuntimeError(f"MT returned source unchanged: {text[:60]!r}")
        self.cache[text] = translated
        return translated

    def warmup(self, texts: list[str], workers: int = 10) -> None:
        pending = [t for t in texts if t and t not in self.cache]
        if not pending:
            print(f"  cache warm ({len(self.cache)} entries, 0 new)")
            return
        print(f"  warming cache: {len(pending)} new strings (workers={workers})…")
        done = 0
        failures = 0
        with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
            futs = {pool.submit(_translate_one, self.target, t): t for t in pending}
            for fut in as_completed(futs):
                src = futs[fut]
                try:
                    translated = fut.result()
                    if translated == src and _looks_translatable_french(src):
                        failures += 1
                        print(f"    warn: unchanged FR, not cached: {src[:50]!r}", flush=True)
                    else:
                        self.cache[src] = translated
                except Exception as error:  # noqa: BLE001
                    failures += 1
                    print(f"    warn: {error}", flush=True)
                done += 1
                if done % 100 == 0 or done == len(pending):
                    print(
                        f"    cached {done}/{len(pending)} (failures={failures})",
                        flush=True,
                    )
                    self.save()
        self.save()
        if failures:
            # Sequential slow retry — past runs wrote FR when this was soft-failed.
            retry = [t for t in pending if t not in self.cache]
            print(f"  sequential retry: {len(retry)} strings…", flush=True)
            still = 0
            for index, src in enumerate(retry, 1):
                try:
                    translated = _translate_one(self.target, src)
                    if translated == src and _looks_translatable_french(src):
                        still += 1
                    else:
                        self.cache[src] = translated
                except Exception as error:  # noqa: BLE001
                    still += 1
                    print(f"    retry fail: {error}", flush=True)
                if index % 50 == 0 or index == len(retry):
                    self.save()
                    print(f"    retry {index}/{len(retry)} still_fail={still}", flush=True)
            self.save()
            if still:
                raise RuntimeError(
                    f"warmup still has {still} failures for {self.lang} — "
                    "aborting to avoid FR bleed (wait for rate-limit cooldown)"
                )

    def translate_unit(self, unit: str) -> str:
        if unit in UNIT_FIXED:
            mapped = UNIT_FIXED[unit].get(self.lang)
            if mapped is not None:
                return mapped
        return self.mt(unit)

    def translate_question(self, fr_q: dict) -> dict:
        qtype = fr_q["type"]
        out = {
            "id": fr_q["id"],
            "type": qtype,
            "question": self.mt(fr_q["question"]),
            "explanation": self.mt(fr_q["explanation"]),
        }
        if qtype == "trueFalse":
            out["options"] = list(TRUE_FALSE[self.lang])
            out["correctIndex"] = int(fr_q["correctIndex"])
        elif qtype == "mcq":
            out["options"] = [self.mt(o) for o in fr_q["options"]]
            out["correctIndex"] = int(fr_q["correctIndex"])
        elif qtype == "chronological":
            out["items"] = [self.mt(it) for it in fr_q["items"]]
        elif qtype in ("numericSlider", "percentageSlider"):
            out["correctValue"] = float(fr_q["correctValue"])
            out["sliderMin"] = float(fr_q["sliderMin"])
            out["sliderMax"] = float(fr_q["sliderMax"])
            out["tolerance"] = float(fr_q["tolerance"])
            unit = fr_q.get("unit") or ("" if qtype == "numericSlider" else "%")
            if qtype == "percentageSlider":
                out["unit"] = "%"
            else:
                out["unit"] = self.translate_unit(unit)
        return out


def collect_strings(by_course: dict[str, list[dict]]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for questions in by_course.values():
        for q in questions:
            for key in ("question", "explanation"):
                s = q.get(key) or ""
                if s and s not in seen:
                    seen.add(s)
                    out.append(s)
            if q["type"] == "mcq":
                for o in q.get("options") or []:
                    if o and o not in seen:
                        seen.add(o)
                        out.append(o)
            if q["type"] == "chronological":
                for it in q.get("items") or []:
                    if it and it not in seen:
                        seen.add(it)
                        out.append(it)
            if q["type"] == "numericSlider":
                unit = q.get("unit") or ""
                if unit and unit not in UNIT_FIXED and unit not in seen:
                    seen.add(unit)
                    out.append(unit)
    return out


# ---------------------------------------------------------------------------
# I/O helpers
# ---------------------------------------------------------------------------

def quizzes_path(lang: str) -> Path:
    return CONTENT_LOCALES / lang / "quizzes_v2.json"


def csv_path(lang: str) -> Path:
    return CONTENT_LOCALES / lang / "source" / "quizzes_v2.csv"


def courses_bundle_path(lang: str) -> Path:
    return LOCALE_DIR / f"courses.{lang}.json"


def save_quizzes(lang: str, by_course: dict[str, list[dict]]) -> None:
    path = quizzes_path(lang)
    path.parent.mkdir(parents=True, exist_ok=True)
    # Stable list form for readability / diffs.
    payload = [
        {"courseId": cid, "quiz": by_course[cid]}
        for cid in sorted(by_course)
    ]
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_quizzes(lang: str) -> dict[str, list[dict]]:
    path = quizzes_path(lang)
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        return {k: v for k, v in data.items()}
    return {entry["courseId"]: entry["quiz"] for entry in data}


def write_csv(lang: str, by_course: dict[str, list[dict]]) -> None:
    path = csv_path(lang)
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "courseId",
        "id",
        "type",
        "question",
        "explanation",
        "options_json",
        "correctIndex",
        "items_json",
        "correctValue",
        "sliderMin",
        "sliderMax",
        "tolerance",
        "unit",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for cid in sorted(by_course):
            for q in by_course[cid]:
                writer.writerow(
                    {
                        "courseId": cid,
                        "id": q["id"],
                        "type": q["type"],
                        "question": q["question"],
                        "explanation": q["explanation"],
                        "options_json": json.dumps(q.get("options"), ensure_ascii=False)
                        if q.get("options") is not None
                        else "",
                        "correctIndex": q.get("correctIndex", ""),
                        "items_json": json.dumps(q.get("items"), ensure_ascii=False)
                        if q.get("items") is not None
                        else "",
                        "correctValue": q.get("correctValue", ""),
                        "sliderMin": q.get("sliderMin", ""),
                        "sliderMax": q.get("sliderMax", ""),
                        "tolerance": q.get("tolerance", ""),
                        "unit": q.get("unit", ""),
                    }
                )


def merge_into_courses(lang: str, by_course: dict[str, list[dict]]) -> tuple[int, int]:
    path = courses_bundle_path(lang)
    courses = json.loads(path.read_text(encoding="utf-8"))
    updated = 0
    missing = 0
    for course in courses:
        cid = course["id"]
        if cid not in by_course:
            missing += 1
            continue
        course["quiz"] = by_course[cid]
        updated += 1
    path.write_text(json.dumps(courses, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return updated, missing


def filter_courses(
    by_course: dict[str, list[dict]],
    only: str,
    limit: int,
) -> dict[str, list[dict]]:
    items = sorted(by_course.items())
    if only:
        import fnmatch

        patterns = [p.strip() for p in only.split(",") if p.strip()]
        items = [
            (cid, qs)
            for cid, qs in items
            if any(fnmatch.fnmatch(cid, pat) or cid == pat for pat in patterns)
        ]
    if limit:
        items = items[:limit]
    return dict(items)


# ---------------------------------------------------------------------------
# CLI commands
# ---------------------------------------------------------------------------

def cmd_extract(_: argparse.Namespace) -> int:
    print("Extracting FR quizzes from CourseData.swift…")
    by_course = extract_fr_quizzes()
    total_q = sum(len(v) for v in by_course.values())
    print(f"  courses={len(by_course)} questions={total_q}")
    errs = validate_catalog(by_course)
    if errs:
        print(f"EXTRACT QA FAILED ({len(errs)}):")
        for e in errs[:40]:
            print(" -", e)
        return 1
    save_quizzes("fr", by_course)
    write_csv("fr", by_course)
    # type histogram
    from collections import Counter

    types = Counter(q["type"] for qs in by_course.values() for q in qs)
    print("  types:", dict(types))
    print(f"  wrote {quizzes_path('fr')}")
    print(f"  wrote {csv_path('fr')}")
    print("EXTRACT PASS")
    return 0


def cmd_translate(args: argparse.Namespace) -> int:
    fr_all = load_quizzes("fr")
    langs = LANGS if args.lang == "all" else [args.lang]
    for lang in langs:
        if lang not in LANGS:
            print(f"Unknown lang {lang}", file=sys.stderr)
            return 1
        subset = filter_courses(fr_all, args.only, args.limit)
        print(f"\n=== Translate {len(subset)} courses → {lang} ===")
        existing: dict[str, list[dict]] = {}
        if quizzes_path(lang).exists() and not args.force:
            existing = load_quizzes(lang)
        to_do = {
            cid: qs
            for cid, qs in subset.items()
            if args.force or cid not in existing
        }
        skipped = len(subset) - len(to_do)
        translator = QuizTranslator(lang)
        strings = collect_strings(to_do)
        try:
            translator.warmup(strings, workers=args.workers)
        except RuntimeError as error:
            print(f"ABORT {lang}: {error}", flush=True)
            return 1

        done = 0
        try:
            for index, (cid, fr_qs) in enumerate(sorted(to_do.items()), 1):
                if index == 1 or index % 25 == 0 or index == len(to_do):
                    print(f"  [{index}/{len(to_do)}] {cid}", flush=True)
                existing[cid] = [translator.translate_question(q) for q in fr_qs]
                done += 1
                if done % 20 == 0:
                    translator.save()
            translator.save()
        except Exception as error:  # noqa: BLE001
            translator.save()
            print(f"ABORT {lang} during apply after {done} courses: {error}", flush=True)
            # Never write a partial full-catalog pack (past merge QA failures).
            return 1

        # Persist only courses we care about this run, but keep prior translations.
        # If --only/--limit, merge into full file when present.
        if quizzes_path(lang).exists() and (args.only or args.limit):
            full = load_quizzes(lang)
            full.update(existing)
            out = full
        else:
            # When translating full set without prior, existing holds all to_do (+old).
            out = existing if existing else {}
            if not args.only and not args.limit:
                # ensure all FR courses present
                out = {cid: existing[cid] for cid in sorted(fr_all) if cid in existing}

        # If force full translate, out should be complete
        if not args.only and not args.limit and args.force:
            out = {cid: existing[cid] for cid in sorted(fr_all)}

        if not args.only and not args.limit and len(out) != len(fr_all):
            print(
                f"ABORT {lang}: incomplete pack {len(out)}/{len(fr_all)} — not writing",
                flush=True,
            )
            return 1

        save_quizzes(lang, out)
        write_csv(lang, out)
        # QA on the subset we just translated
        qa_target = {cid: out[cid] for cid in subset}
        fr_target = {cid: fr_all[cid] for cid in subset}
        errs = validate_catalog(qa_target, fr_by_course=fr_target)
        print(f"Done {lang}: wrote={done} skipped_existing={skipped} qa_errors={len(errs)}")
        if errs:
            for e in errs[:30]:
                print(" -", e)
            return 1
    return 0


def cmd_merge(args: argparse.Namespace) -> int:
    langs = LANGS if args.lang == "all" else [args.lang]
    fr = load_quizzes("fr")
    for lang in langs:
        by_course = load_quizzes(lang)
        errs = validate_catalog(by_course, fr_by_course=fr)
        if errs:
            print(f"merge blocked for {lang}: {len(errs)} QA errors")
            for e in errs[:20]:
                print(" -", e)
            return 1
        updated, missing = merge_into_courses(lang, by_course)
        write_csv(lang, by_course)
        print(f"Merged {lang}: updated={updated} missing_in_bundle={missing}")
        # Verify bundle
        courses = json.loads(courses_bundle_path(lang).read_text(encoding="utf-8"))
        bundle_map = {c["id"]: c["quiz"] for c in courses}
        errs2 = validate_catalog(bundle_map, fr_by_course=fr)
        # Also ensure no course left at 5 legacy if FR has rich
        legacy = [c["id"] for c in courses if len(c.get("quiz", [])) == 5]
        if legacy:
            print(f"  WARN: {len(legacy)} courses still have 5 questions")
        if errs2:
            print(f"bundle QA failed ({len(errs2)})")
            for e in errs2[:20]:
                print(" -", e)
            return 1
        total_q = sum(len(c["quiz"]) for c in courses)
        print(f"  bundle OK: {len(courses)} courses, {total_q} questions")
    return 0


def cmd_qa(args: argparse.Namespace) -> int:
    fr = load_quizzes("fr")
    langs = LANGS if args.lang == "all" else [args.lang]
    failed = 0
    for lang in langs:
        if lang == "fr":
            by_course = fr
            errs = validate_catalog(by_course)
        else:
            # Prefer bundle if merged, else quizzes_v2.json
            path = courses_bundle_path(lang)
            if path.exists() and args.source != "json":
                courses = json.loads(path.read_text(encoding="utf-8"))
                by_course = {c["id"]: c["quiz"] for c in courses}
            else:
                by_course = load_quizzes(lang)
            subset = filter_courses(by_course, args.only, args.limit)
            fr_sub = {cid: fr[cid] for cid in subset if cid in fr}
            errs = validate_catalog(subset, fr_by_course=fr_sub)
        print(f"{lang}: {len(errs)} errors")
        for e in errs[:25]:
            print(" -", e)
        if errs:
            failed += 1
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_ex = sub.add_parser("extract", help="Extract FR quizzes from CourseData.swift")
    p_ex.set_defaults(func=cmd_extract)

    p_tr = sub.add_parser("translate", help="Translate FR quizzes to a language")
    p_tr.add_argument("--lang", required=True, help="en|es|de|pt|it|all")
    p_tr.add_argument("--only", default="", help="Comma-separated course id globs")
    p_tr.add_argument("--limit", type=int, default=0)
    p_tr.add_argument("--force", action="store_true")
    p_tr.add_argument(
        "--workers",
        type=int,
        default=3,
        help="Parallel MT workers (keep ≤3; Google ~5 req/s). One lang at a time.",
    )
    p_tr.set_defaults(func=cmd_translate)

    p_mg = sub.add_parser("merge", help="Merge quizzes_v2.json into courses.<lang>.json")
    p_mg.add_argument("--lang", required=True)
    p_mg.set_defaults(func=cmd_merge)

    p_qa = sub.add_parser("qa", help="Hard QA")
    p_qa.add_argument("--lang", required=True)
    p_qa.add_argument("--only", default="")
    p_qa.add_argument("--limit", type=int, default=0)
    p_qa.add_argument("--source", choices=["bundle", "json"], default="bundle")
    p_qa.set_defaults(func=cmd_qa)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
