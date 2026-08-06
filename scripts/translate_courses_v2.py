#!/usr/bin/env python3
"""Translate French CoursesV2 sources into every non-FR app language.

Reads ``content/courses/fr/*.json``, writes ``content/courses/<lang>/<id>.json``.
Does NOT modify French sources. Preserves structure, assets, ids, and inline
markup (``**bold**``, ``[[glossary]]``). Glossary markers are remapped to the
existing per-locale glossary display terms when possible.

Usage:
    python scripts/translate_courses_v2.py --lang en
    python scripts/translate_courses_v2.py --lang all
    python scripts/translate_courses_v2.py --lang es --limit 5
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import unicodedata
from pathlib import Path

from i18n_languages import GT_TARGETS, NON_FR_LANGS

ROOT = Path(__file__).resolve().parents[1]
SOURCE_FR = ROOT / "content" / "courses" / "fr"
OUT_ROOT = ROOT / "content" / "courses"
CACHE_DIR = ROOT / "content" / "locales" / "_v2_mt_cache"
GLOSSARY_DIR = ROOT / "ios" / "Sophia" / "Resources" / "Locales"

LANGS = NON_FR_LANGS

SKIP_KEYS = {"id", "type", "asset", "ratio", "credit", "free", "subject", "image"}

# Fixed FR → locale subcategory labels (majority vote from legacy courses).
SUBCATEGORY = {
    "Anglo-saxons & littérature mondiale": {
        "en": "Anglo-Saxons & world literature",
        "es": "Anglosajones y literatura mundial",
        "de": "Angelsachsen & Weltliteratur",
        "pt": "Anglo-saxões & literatura mundial",
        "it": "Anglosassoni e letteratura mondiale",
    },
    "Antiquité & Moyen Âge": {
        "en": "Antiquity & Middle Ages",
        "es": "Antigüedad y Edad Media",
        "de": "Antike & Mittelalter",
        "pt": "Antiguidade & Idade Média",
        "it": "Antichità & Medioevo",
    },
    "Autres mythologies": {
        "en": "Other mythologies",
        "es": "Otras mitologías",
        "de": "Andere Mythologien",
        "pt": "Outras mitologias",
        "it": "Altre mitologie",
    },
    "Cinéma, photo & architecture": {
        "en": "Cinema, photography & architecture",
        "es": "Cine, foto y arquitectura",
        "de": "Kino, Fotografie & Architektur",
        "pt": "Cinema, foto & arquitetura",
        "it": "Cinema, fotografia & architettura",
    },
    "Cinéma, photo & architecture + œuvres iconiques": {
        "en": "Cinema, photography & architecture + iconic works",
        "es": "Cine, foto y arquitectura + obras icónicas",
        "de": "Kino, Fotografie & Architektur + ikonische Werke",
        "pt": "Cinema, foto & arquitetura + obras icônicas",
        "it": "Cinema, fotografia & architettura + opere iconiche",
    },
    "Classiques français & européens": {
        "en": "French & European Classics",
        "es": "Clásicos franceses y europeos",
        "de": "Französische & europäische Klassiker",
        "pt": "Clássicos franceses & europeus",
        "it": "Classici francesi ed europei",
    },
    "Conflits & géopolitique": {
        "en": "Conflicts & geopolitics",
        "es": "Conflictos y geopolítica",
        "de": "Konflikte & Geopolitik",
        "pt": "Conflitos & geopolítica",
        "it": "Conflitti e geopolitica",
    },
    "Découvertes qui ont changé le monde": {
        "en": "Discoveries that changed the world",
        "es": "Descubrimientos que cambiaron el mundo",
        "de": "Entdeckungen, die die Welt veränderten",
        "pt": "Descobertas que mudaram o mundo",
        "it": "Scoperte che hanno cambiato il mondo",
    },
    "Environnement & avenir": {
        "en": "Environment & the future",
        "es": "Medio ambiente y futuro",
        "de": "Umwelt & Zukunft",
        "pt": "Ambiente & futuro",
        "it": "Ambiente & futuro",
    },
    "Grecs & Philosophes antiques": {
        "en": "Ancient Greeks & Philosophers",
        "es": "Griegos y filósofos antiguos",
        "de": "Griechen & antike Philosophen",
        "pt": "Gregos & Filósofos antigos",
        "it": "Greci e filosofi antichi",
    },
    "Grèce : les dieux": {
        "en": "Greece: the gods",
        "es": "Grecia: los dioses",
        "de": "Griechenland: Die Götter",
        "pt": "Grécia: os deuses",
        "it": "Grecia: gli dei",
    },
    "Grèce : les héros": {
        "en": "Greece: the heroes",
        "es": "Grecia: los héroes",
        "de": "Griechenland: die Helden",
        "pt": "Grécia: os heróis",
        "it": "Grecia: gli eroi",
    },
    "Guerre froide & monde contemporain": {
        "en": "Cold War & Contemporary World",
        "es": "Guerra Fría y mundo contemporáneo",
        "de": "Kalter Krieg & zeitgenössische Welt",
        "pt": "Guerra Fria & mundo contemporâneo",
        "it": "Guerra fredda & mondo contemporaneo",
    },
    "La Terre et l'Univers": {
        "en": "The Earth and the Universe",
        "es": "La Tierra y el Universo",
        "de": "Die Erde und das Universum",
        "pt": "A Terra e o Universo",
        "it": "La Terra e l'Universo",
    },
    "Musique": {
        "en": "Music",
        "es": "Música",
        "de": "Musik",
        "pt": "Música",
        "it": "Musica",
    },
    "Notre quotidien expliqué": {
        "en": "Our daily life explained",
        "es": "Nuestro día a día explicado",
        "de": "Unser Alltag erklärt",
        "pt": "O nosso quotidiano explicado",
        "it": "La nostra quotidianità spiegata",
    },
    "Peinture & mouvements": {
        "en": "Painting & Movements",
        "es": "Pintura y movimientos",
        "de": "Malerei & Strömungen",
        "pt": "Pintura & movimentos",
        "it": "Pittura e movimenti",
    },
    "Révolutions & conflits modernes": {
        "en": "Modern Revolutions & Conflicts",
        "es": "Revoluciones y conflictos modernos",
        "de": "Revolutionen & moderne Konflikte",
        "pt": "Revoluções & conflitos modernos",
        "it": "Rivoluzioni e conflitti moderni",
    },
    "Économie & société": {
        "en": "Economy & society",
        "es": "Economía y sociedad",
        "de": "Wirtschaft & Gesellschaft",
        "pt": "Economia & sociedade",
        "it": "Economia & società",
    },
    "Œuvres iconiques": {
        "en": "Iconic works",
        "es": "Obras icónicas",
        "de": "Ikonische Werke",
        "pt": "Obras icônicas",
        "it": "Opere iconiche",
    },
}

# High-frequency short labels — keep tone consistent / avoid MT drift.
FIXED = {
    "Introduction": {
        "en": "Introduction",
        "es": "Introducción",
        "de": "Einführung",
        "pt": "Introdução",
        "it": "Introduzione",
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
    "Héritage": {
        "en": "Legacy",
        "es": "Legado",
        "de": "Vermächtnis",
        "pt": "Legado",
        "it": "Eredità",
        "tr": "Miras",
        "pl": "Dziedzictwo",
        "ro": "Moștenire",
        "nl": "Erfenis",
        "el": "Κληρονομιά",
        "sv": "Arv",
        "hu": "Örökség",
        "bg": "Наследство",
        "cs": "Dědictví",
    },
    "À retenir": {
        "en": "Key takeaway",
        "es": "Para recordar",
        "de": "Zum Mitnehmen",
        "pt": "A reter",
        "it": "Da ricordare",
        "tr": "Akılda tut",
        "pl": "Do zapamiętania",
        "ro": "De reținut",
        "nl": "Onthouden",
        "el": "Να θυμάσαι",
        "sv": "Att komma ihåg",
        "hu": "Megjegyzendő",
        "bg": "За запомняне",
        "cs": "K zapamatování",
    },
}


def norm_key(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in decomposed.lower() if ch.isalnum())


def is_passthrough(text: str) -> bool:
    s = text.strip()
    if not s:
        return True
    if s.isdigit():
        return True
    if re.fullmatch(r"[\d\s./–—-]+", s):
        return True
    return False


MARKER_BOLD = re.compile(r"\*\*(.+?)\*\*")
MARKER_GLOSS = re.compile(r"\[\[(.+?)\]\]")
MARKER_EMPH = re.compile(r"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)")


# Bold-wrapped glossary: **[[Term]]**
MARKER_BOLD_GLOSS = re.compile(r"\*\*\[\[(.+?)\]\]\*\*")

# Opaque sentinels (no single-letter tags — MT turns ⟦I⟧ into Yo/Ich, etc.).
SEN_B0, SEN_B1 = "ZZBOLDZZ", "ZZENDBOLDZZ"
SEN_G0, SEN_G1 = "ZZGLOSSZZ", "ZZENDGLOSSZZ"
SEN_I0, SEN_I1 = "ZZITALZZ", "ZZENDITALZZ"

def protect_markup(text: str) -> tuple[str, list[str]]:
    """Swap markdown markers for sentinels while keeping inner text visible to MT."""
    text = MARKER_BOLD_GLOSS.sub(
        lambda m: f"{SEN_B0}{SEN_G0}{m.group(1)}{SEN_G1}{SEN_B1}", text
    )
    text = MARKER_GLOSS.sub(lambda m: f"{SEN_G0}{m.group(1)}{SEN_G1}", text)
    text = MARKER_BOLD.sub(lambda m: f"{SEN_B0}{m.group(1)}{SEN_B1}", text)
    text = MARKER_EMPH.sub(lambda m: f"{SEN_I0}{m.group(1)}{SEN_I1}", text)
    return text, []


def restore_markup(text: str, tokens: list[str]) -> str:
    # MT sometimes lowercases or inserts spaces inside sentinels.
    def norm_sentinels(src: str) -> str:
        mapping = {
            "zzboldzz": SEN_B0,
            "zzendboldzz": SEN_B1,
            "zzglosszz": SEN_G0,
            "zzendglosszz": SEN_G1,
            "zzitalzz": SEN_I0,
            "zzenditalzz": SEN_I1,
        }
        pattern = re.compile(
            r"zz\s*end\s*(bold|gloss|ital)\s*zz|zz\s*(bold|gloss|ital)\s*zz",
            flags=re.IGNORECASE,
        )

        def repl(match: re.Match[str]) -> str:
            raw = re.sub(r"\s+", "", match.group(0)).lower()
            return mapping.get(raw, match.group(0))

        return pattern.sub(repl, src)

    text = norm_sentinels(text)

    def restore_pair(open_s: str, close_s: str, wrap_left: str, wrap_right: str, src: str) -> str:
        pattern = re.compile(
            re.escape(open_s) + r"\s*(.*?)\s*" + re.escape(close_s),
            flags=re.DOTALL | re.IGNORECASE,
        )
        return pattern.sub(lambda m: f"{wrap_left}{m.group(1).strip()}{wrap_right}", src)

    # Innermost glossary first, then bold/italic.
    text = restore_pair(SEN_G0, SEN_G1, "[[", "]]", text)
    text = restore_pair(SEN_B0, SEN_B1, "**", "**", text)
    text = restore_pair(SEN_I0, SEN_I1, "*", "*", text)
    # Orphan opens when the engine eats the END marker (e.g. ZZBOLDZimpressionismo).
    text = re.sub(
        r"ZZBOLDZ+([A-Za-zÀ-ÿ][\wÀ-ÿ\-]*)",
        r"**\1**",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"ZZITALZ+([A-Za-zÀ-ÿ][\wÀ-ÿ\-]*)",
        r"*\1*",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"ZZGLOSSZ+([A-Za-zÀ-ÿ][\wÀ-ÿ\-]*)",
        r"[[\1]]",
        text,
        flags=re.IGNORECASE,
    )
    # Drop leftover bold/italic/gloss sentinels from protect_markup.
    # Do NOT touch numeric glossary slots (ZZG0ZZ…ZZXG0ZZ) — those belong to
    # translate_with_glossary and must survive this pass.
    for s in (SEN_B0, SEN_B1, SEN_G0, SEN_G1, SEN_I0, SEN_I1):
        text = re.sub(re.escape(s), "", text, flags=re.IGNORECASE)
    # Collapsed / doubled sentinel debris (e.g. ZZBOLDBOLDZZ), but not ZZG0ZZ.
    text = re.sub(r"ZZ(?:BOLD|ITAL|GLOSS|END(?:BOLD|ITAL|GLOSS))+ZZ", "", text, flags=re.IGNORECASE)
    return text


def load_glossary(lang: str) -> dict[str, list[str]]:
    """courseId -> list of displayTerms."""
    path = GLOSSARY_DIR / f"glossary.{lang}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    by_course: dict[str, list[str]] = {}
    for key, entry in data.items():
        if "|" not in key:
            continue
        course_id, term = key.split("|", 1)
        display = entry.get("displayTerm") or term
        by_course.setdefault(course_id, []).append(display)
    return by_course


def best_glossary_term(fr_term: str, translated_term: str, candidates: list[str]) -> str:
    if not candidates:
        return translated_term
    from difflib import SequenceMatcher

    needle_fr = norm_key(fr_term)
    needle_tr = norm_key(translated_term)
    # Exact normalized match on translated candidate
    for candidate in candidates:
        if norm_key(candidate) == needle_tr:
            return candidate

    best = None
    best_score = 0.0
    for candidate in candidates:
        hay = norm_key(candidate)
        if not hay or not needle_tr:
            continue
        score = SequenceMatcher(None, needle_tr, hay).ratio()
        # Near-prefix only when lengths are close (avoids "Robert Moses" eating
        # "Robert Moses's highway policy").
        shorter, longer = (needle_tr, hay) if len(needle_tr) <= len(hay) else (hay, needle_tr)
        if longer.startswith(shorter) and len(shorter) >= 0.75 * len(longer):
            score = max(score, 0.9)
        elif needle_tr in hay or hay in needle_tr:
            overlap = min(len(needle_tr), len(hay)) / max(len(needle_tr), len(hay))
            score = max(score, overlap)
        if needle_fr and len(needle_fr) >= 5:
            score = max(score, 0.55 * SequenceMatcher(None, needle_fr, hay).ratio())
        # Prefer longer candidates on near-ties (full glossary display terms).
        if score > best_score + 0.02 or (
            abs(score - best_score) <= 0.02 and best is not None and len(hay) > len(norm_key(best))
        ):
            best_score = score
            best = candidate
        elif best is None and score >= best_score:
            best_score = score
            best = candidate
    if best and best_score >= 0.55:
        return best
    return translated_term


def _translate_one(target: str, text: str) -> str:
    """Stateless single-string translate with retries (thread-safe)."""
    from deep_translator import GoogleTranslator

    if not text or not text.strip():
        return text
    # Punctuation-only / symbol crumbs — never send to MT.
    if not re.search(r"[A-Za-zÀ-ÿ]", text):
        return text

    client = GoogleTranslator(source="fr", target=target)
    for attempt in range(6):
        try:
            result = client.translate(text)
            if result is None:
                raise RuntimeError("empty translation")
            return result
        except Exception as error:  # noqa: BLE001
            wait = min(2**attempt, 20)
            time.sleep(wait)
            client = GoogleTranslator(source="fr", target=target)
            if attempt == 5:
                # Soft-fail: keep source rather than killing a whole language run.
                print(f"    warn: MT failed, keeping source: {text[:60]!r} ({error})", file=sys.stderr)
                return text
    return text


class Translator:
    def __init__(self, lang: str):
        self.lang = lang
        self.target = GT_TARGETS[lang]
        self.cache_path = CACHE_DIR / f"{lang}.json"
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        self.cache: dict[str, str] = {}
        if self.cache_path.exists():
            self.cache = json.loads(self.cache_path.read_text(encoding="utf-8"))
        self.glossary = load_glossary(lang)

    def save(self) -> None:
        self.cache_path.write_text(
            json.dumps(self.cache, ensure_ascii=False, indent=0),
            encoding="utf-8",
        )

    def _apply_mt(self, text: str) -> str:
        """Translate one FR string using cache; network only on miss."""
        if text in FIXED and self.lang in FIXED[text]:
            return FIXED[text][self.lang]
        if is_passthrough(text):
            return text
        if text in self.cache:
            return self.cache[text]
        protected, tokens = protect_markup(text)
        if len(protected) < 4000:
            translated = _translate_one(self.target, protected)
        else:
            parts = re.split(r"(?<=[.!?…])\s+", protected)
            chunks: list[str] = []
            buf = ""
            for part in parts:
                if len(buf) + len(part) + 1 > 3800 and buf:
                    chunks.append(_translate_one(self.target, buf))
                    buf = part
                else:
                    buf = f"{buf} {part}".strip() if buf else part
            if buf:
                chunks.append(_translate_one(self.target, buf))
            translated = " ".join(chunks)
        translated = restore_markup(translated, tokens)
        self.cache[text] = translated
        return translated

    def warmup(self, texts: list[str], workers: int = 12) -> None:
        """Parallel-fill the cache for all unique FR strings."""
        from concurrent.futures import ThreadPoolExecutor, as_completed

        pending = []
        for text in texts:
            if (text in FIXED and self.lang in FIXED[text]) or is_passthrough(text) or text in self.cache:
                continue
            pending.append(text)
        if not pending:
            print(f"  cache warm ({len(self.cache)} entries, 0 new)")
            return
        print(f"  warming cache: {len(pending)} new strings (workers={workers})…")
        done = 0

        def job(src: str) -> tuple[str, str]:
            protected, tokens = protect_markup(src)
            if len(protected) < 4000:
                translated = _translate_one(self.target, protected)
            else:
                parts = re.split(r"(?<=[.!?…])\s+", protected)
                chunks: list[str] = []
                buf = ""
                for part in parts:
                    if len(buf) + len(part) + 1 > 3800 and buf:
                        chunks.append(_translate_one(self.target, buf))
                        buf = part
                    else:
                        buf = f"{buf} {part}".strip() if buf else part
                if buf:
                    chunks.append(_translate_one(self.target, buf))
                translated = " ".join(chunks)
            translated = restore_markup(translated, tokens)
            return src, translated

        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = [pool.submit(job, src) for src in pending]
            for fut in as_completed(futures):
                src, translated = fut.result()
                self.cache[src] = translated
                done += 1
                if done % 100 == 0 or done == len(pending):
                    print(f"    cached {done}/{len(pending)}")
                    self.save()
        self.save()

    def translate_plain(self, text: str) -> str:
        return self.retouch_markup_inners(self._apply_mt(text))

    def retouch_markup_inners(self, text: str) -> str:
        """Force-translate bold/italic inners that the engine left in French."""

        def fix_wrap(match: re.Match[str], left: str, right: str) -> str:
            inner = match.group(1).strip()
            if not inner or "[[" in inner or "ZZ" in inner:
                return match.group(0)
            if is_passthrough(inner):
                return match.group(0)
            # Skip punctuation-only crumbs produced by broken markdown (**,** / **.**).
            if not re.search(r"[A-Za-zÀ-ÿ]", inner):
                return match.group(0)
            # Avoid re-entering retouch on tiny dictionary lookups.
            bare = self._apply_mt(inner).strip()
            if not bare:
                return match.group(0)
            if norm_key(bare) == norm_key(inner):
                return match.group(0)  # cognate / same form
            # Reject runaway expansions (engine sometimes returns a sentence).
            if len(bare) > max(len(inner) * 3, len(inner) + 24):
                return match.group(0)
            return f"{left}{bare}{right}"

        text = MARKER_BOLD.sub(lambda m: fix_wrap(m, "**", "**"), text)
        text = MARKER_EMPH.sub(lambda m: fix_wrap(m, "*", "*"), text)
        return text

    def translate_with_glossary(self, text: str, course_id: str) -> str:
        """Pre-resolve [[glossary]] to opaque ZZG#ZZ slots, MT, then restore.

        MT engines often drop or empty ``[[…]]`` / ``**[[…]]**``. Resolving first
        and hiding terms behind numeric tokens preserves count and linking.
        """
        candidates = self.glossary.get(course_id, [])
        slots: list[tuple[bool, str]] = []

        def snap_term(fr_term: str) -> str:
            bare = self._apply_mt(fr_term).strip().strip("[]")
            return best_glossary_term(fr_term, bare, candidates)

        def stash_bold_gloss(match: re.Match[str]) -> str:
            snapped = snap_term(match.group(1).strip())
            slots.append((True, snapped))
            i = len(slots) - 1
            # Keep term TEXT visible to MT so dropping the wrapper doesn't erase meaning.
            return f"ZZG{i}ZZ{snapped}ZZXG{i}ZZ"

        def stash_gloss(match: re.Match[str]) -> str:
            snapped = snap_term(match.group(1).strip())
            slots.append((False, snapped))
            i = len(slots) - 1
            return f"ZZG{i}ZZ{snapped}ZZXG{i}ZZ"

        work = MARKER_BOLD_GLOSS.sub(stash_bold_gloss, text)
        work = MARKER_GLOSS.sub(stash_gloss, work)
        translated = self.retouch_markup_inners(self._apply_mt(work))

        def find_bare_term(haystack: str, term: str) -> int:
            """Index of bare term not already inside [[…]]."""
            if not term:
                return -1
            lower = haystack.lower()
            needle = term.lower()
            start = 0
            while True:
                idx = lower.find(needle, start)
                if idx < 0:
                    return -1
                open_idx = haystack.rfind("[[", 0, idx)
                close_idx = haystack.rfind("]]", 0, idx)
                if open_idx > close_idx:
                    start = idx + len(needle)
                    continue
                return idx

        for index, (is_bold, term) in enumerate(slots):
            repl = f"**[[{term}]]**" if is_bold else f"[[{term}]]"
            start_re = re.compile(rf"ZZ\s*G\s*{index}\s*ZZ", flags=re.IGNORECASE)
            end_re = re.compile(rf"ZZ\s*X\s*G\s*{index}\s*ZZ", flags=re.IGNORECASE)
            start_m = start_re.search(translated)
            if start_m:
                end_m = end_re.search(translated, pos=start_m.end())
                if end_m:
                    translated = translated[: start_m.start()] + repl + translated[end_m.end() :]
                    continue
                # Closer missing: drop the opener and fall through to bare-term wrap.
                translated = translated[: start_m.start()] + translated[start_m.end() :]
            # Already linked (e.g. polluted cache returned pre-wrapped text).
            if repl in translated or f"[[{term}]]" in translated:
                continue
            idx = find_bare_term(translated, term)
            if idx >= 0:
                translated = translated[:idx] + repl + translated[idx + len(term) :]
                continue
            # Prefer re-inserting into an empty article/prep slot left by MT
            # (e.g. "de :" / "do ,") instead of parking the term at the end.
            empty_slot = re.search(
                r"\b(de|do|da|del|the|di|du|des|um|uma|un|une|el|il|lo|la|le|les|"
                r"der|die|das|dem|den|o|a|par|pelo|pela|au|aux|al)\s*([,:])\s+(?!\[)",
                translated,
                flags=re.IGNORECASE,
            )
            if empty_slot:
                article = empty_slot.group(1)
                punct = empty_slot.group(2)
                insertion = f"{article} {repl}{punct} "
                translated = (
                    translated[: empty_slot.start()]
                    + insertion
                    + translated[empty_slot.end() :]
                )
                continue
            empty_space = re.search(
                r"\b(de|do|da|del|the|di|du|des|le|la|par|pelo|pela)\s{2,}(?!\[)",
                translated,
                flags=re.IGNORECASE,
            )
            if empty_space:
                article = empty_space.group(1)
                insertion = f"{article} {repl} "
                translated = (
                    translated[: empty_space.start()]
                    + insertion
                    + translated[empty_space.end() :]
                )
                continue
            # Last resort: append so glossary count never silently drops.
            translated = f"{translated.rstrip()} {repl}"

        # Clean accidental empty / broken markers from older paths.
        translated = translated.replace("[[]]", "")
        translated = re.sub(
            r"ZZ\s*G\s*(\d+)\s*ZZ(.*?)ZZ\s*X\s*G\s*\1\s*ZZ",
            r"[[\2]]",
            translated,
            flags=re.IGNORECASE | re.DOTALL,
        )
        translated = re.sub(r"ZZ\s*X?\s*G\s*\d+\s*ZZ", "", translated, flags=re.IGNORECASE)
        # Collapse accidental nested / doubled glossary wraps.
        for _ in range(4):
            nxt = re.sub(r"\[\[\[\[([^\]]+)\]\]\]\]", r"[[\1]]", translated)
            nxt = re.sub(r"\[\[\[([^\]]+)\]\]\]", r"[[\1]]", nxt)
            if nxt == translated:
                break
            translated = nxt
        translated = re.sub(r"\]{3,}", "]]", translated)
        return translated


def map_value(value, translator: Translator, course_id: str, key: str | None = None):
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if k in SKIP_KEYS:
                out[k] = v
            elif k == "subcategory" and isinstance(v, str) and v in SUBCATEGORY:
                labels = SUBCATEGORY[v]
                out[k] = labels.get(translator.lang) or labels.get("en") or v
            else:
                out[k] = map_value(v, translator, course_id, k)
        return out
    if isinstance(value, list):
        return [map_value(v, translator, course_id, key) for v in value]
    if isinstance(value, str):
        if key in SKIP_KEYS or is_passthrough(value):
            return value
        if "[[" in value:
            return translator.translate_with_glossary(value, course_id)
        return translator.translate_plain(value)
    return value


def translate_course(data: dict, translator: Translator) -> dict:
    course_id = data["id"]
    return map_value(data, translator, course_id)


def validate_light(data: dict) -> None:
    assert data.get("id") and data.get("title") and data.get("sections")
    for section in data["sections"]:
        assert section.get("id") and isinstance(section.get("blocks"), list)


def collect_strings(obj, key: str | None = None) -> list[str]:
    out: list[str] = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in SKIP_KEYS or k == "subcategory":
                continue
            out.extend(collect_strings(v, k))
    elif isinstance(obj, list):
        for v in obj:
            out.extend(collect_strings(v, key))
    elif isinstance(obj, str):
        if not is_passthrough(obj):
            out.append(obj)
            out.extend(MARKER_GLOSS.findall(obj))
            # Bold/italic inners need their own cache entries for retouch.
            out.extend(MARKER_BOLD.findall(obj))
            out.extend(MARKER_EMPH.findall(obj))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", required=True, help="en|es|de|pt|it|all")
    parser.add_argument("--limit", type=int, default=0, help="Max courses (0 = all)")
    parser.add_argument("--force", action="store_true", help="Overwrite existing outputs")
    parser.add_argument("--workers", type=int, default=12, help="Parallel MT workers")
    parser.add_argument(
        "--only",
        default="",
        help="Comma-separated course ids (or filenames) to translate",
    )
    args = parser.parse_args()

    langs = LANGS if args.lang == "all" else [args.lang]
    for lang in langs:
        if lang not in LANGS:
            print(f"Unknown lang {lang}", file=sys.stderr)
            return 1

    sources = sorted(SOURCE_FR.glob("*.json"))
    if args.only:
        wanted = {part.strip() for part in args.only.split(",") if part.strip()}
        sources = [
            s
            for s in sources
            if s.name in wanted or s.stem in wanted or s.stem.split(".")[0] in wanted
        ]
        if not sources:
            print(f"No courses matched --only {args.only!r}", file=sys.stderr)
            return 1
    if args.limit:
        sources = sources[: args.limit]

    for lang in langs:
        print(f"\n=== Translating {len(sources)} courses → {lang} ===")
        translator = Translator(lang)
        # Phase 1: warm cache in parallel over unique FR strings.
        unique: list[str] = []
        seen: set[str] = set()
        for source in sources:
            data = json.loads(source.read_text(encoding="utf-8"))
            for s in collect_strings(data):
                if s not in seen:
                    seen.add(s)
                    unique.append(s)
        translator.warmup(unique, workers=args.workers)

        out_dir = OUT_ROOT / lang
        out_dir.mkdir(parents=True, exist_ok=True)
        done = 0
        skipped = 0
        errors = 0
        for index, source in enumerate(sources, 1):
            out_path = out_dir / source.name
            if out_path.exists() and not args.force:
                skipped += 1
                continue
            data = json.loads(source.read_text(encoding="utf-8"))
            if index % 25 == 1 or index == len(sources):
                print(f"  [{index}/{len(sources)}] writing {data['id']}…", flush=True)
            try:
                translated = translate_course(data, translator)
                validate_light(translated)
                out_path.write_text(
                    json.dumps(translated, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )
                done += 1
            except Exception as error:  # noqa: BLE001
                errors += 1
                print(f"  ERROR {data.get('id', source.name)}: {error}", file=sys.stderr, flush=True)
            if done and done % 20 == 0:
                translator.save()
        translator.save()
        print(f"Done {lang}: wrote {done}, skipped existing {skipped}, errors {errors}")
        if errors:
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
