#!/usr/bin/env python3
"""L'usine de production : exécute un job créé par l'Edge Function publish-course.

Lancé par GitHub Actions (.github/workflows/produce-course.yml) sur repository_dispatch
« produce-course » (envoyé par la fonction SQL jobs_dispatch toutes les cinq minutes) ou à la main :

    python3 scripts/produce_course.py --job <uuid>

Ce que fait un job, étape par étape (production_steps, un webhook « job-step » au Studio à chacune) :

  glossary   les entrées de glossaire du cours dans sa langue d'origine (celles du Studio, complétées
             pour chaque [[terme]] du texte qui n'en a pas)
  quiz       le quiz (6 à 10 questions, CHARTE_QUIZ) : celui du Studio ou écrit par le modèle, chaque
             question citant la section qui la justifie, puis vérifié « à livre ouvert » par un second
             appel ; une question non justifiée par le texte est retirée
  cover      les images fournies par URL sont importées dans le bucket course-images
  translate  par langue : traduction guidée (content/TRANSLATION_GUIDE_<LANG>.md, terminologie,
             glossaire), relecture native adverse, et réparation à partir des constats de la porte ;
             seuls les segments dont le texte d'origine a changé sont retraduits
  gate       par langue : scripts/check_course_translation.py, terminologie (check_terminology),
             structure du quiz ; une langue passe quand il ne reste aucun constat
  publish    les langues qui passent sont écrites en base (catalog_upsert_course, status published)
             et les fichiers de la langue recalculés (catalog_finalize_language) ; les autres restent
             « failed » ; le cours passe published quand sa langue d'origine est publiée
  audio      narration ElevenLabs (fr, en) quand ELEVENLABS_API_KEY et ELEVENLABS_VOICE_<LANG> sont
             posés, sinon l'étape est « skipped »

Les fichiers produits sont écrits dans content/ (cours, quiz, glossaire, index, auteurs, carte des
couvertures) et poussés sur main ; content/ reste la source de vérité.

Variables d'environnement : SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY ; le modèle par l'API Anthropic
(ANTHROPIC_API_KEY, défaut claude-opus-5-5, sorties JSON contraintes, PRODUCTION_FALLBACKS=off pour
couper le repli serveur sur refus) ou par fal-ai/any-llm (FAL_KEY ou FAL_API_KEY, défaut
anthropic/claude-sonnet-4.5, JSON demandé dans le prompt et vérifié) ; PRODUCTION_PROVIDER pour
forcer l'un ou l'autre, PRODUCTION_MODEL pour changer de modèle, PRODUCTION_WORKERS (langues en
parallèle, défaut 4), ELEVENLABS_API_KEY, ELEVENLABS_VOICE_FR, ELEVENLABS_VOICE_EN.

Tests sans réseau :
    python3 scripts/produce_course.py --job-file job.json --dry-run --fake-llm --out-root /tmp/x
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import subprocess
import sys
import threading
import time
import traceback
import unicodedata
import urllib.request
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS))

import course_translation_io as cio  # noqa: E402
from i18n_languages import NON_FR_LANGS  # noqa: E402
from supabase_rest import DEFAULT_URL, Supabase, SupabaseError, env_key  # noqa: E402

ALL_LANGS = ["fr", *NON_FR_LANGS]
DEFAULT_MODEL = "claude-opus-5-5"
AUDIO_LANGS = ("fr", "en", "es", "de", "tr")
IMAGE_BUCKET = "course-images"
AUDIO_BUCKET = "course-audio"
MAX_REPAIRS = 2

LANGUAGE_NAMES = {
    "fr": "French", "en": "English (American spelling)", "es": "Spanish", "de": "German",
    "pt": "Brazilian Portuguese", "pt-PT": "European Portuguese", "it": "Italian", "tr": "Turkish",
    "pl": "Polish", "ro": "Romanian", "nl": "Dutch", "el": "Greek", "sv": "Swedish", "hu": "Hungarian",
    "bg": "Bulgarian", "cs": "Czech", "da": "Danish", "nb": "Norwegian Bokmål", "ru": "Russian",
    "hr": "Croatian", "sl": "Slovenian", "sk": "Slovak", "sr": "Serbian (Latin script, Ekavian)",
    "ar": "Modern Standard Arabic", "he": "Hebrew", "fi": "Finnish", "et": "Estonian",
    "lt": "Lithuanian", "lv": "Latvian", "ja": "Japanese",
}

QUESTION_TYPES = ["mcq", "trueFalse", "chronological", "numericSlider", "percentageSlider"]
CLASSIFICATIONS = ["referenceHistorique", "concept", "evenementConnexe", "personnage", "lieuInstitution"]
TEXT_FIELDS = ("question", "explanation")
GLOSSARY_RE = re.compile(r"\[\[(.+?)\]\]")


class ProductionError(RuntimeError):
    pass


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def log(msg: str) -> None:
    print(f"[{datetime.now(timezone.utc).strftime('%H:%M:%S')}] {msg}", flush=True)


def slugify(title: str) -> str:
    folded = unicodedata.normalize("NFD", title)
    folded = "".join(c for c in folded if not unicodedata.combining(c)).lower()
    slug = re.sub(r"[^a-z0-9]+", "_", folded).strip("_")
    return slug[:48].rstrip("_") or "cours"


def read_json(path: Path, default=None):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload) -> bool:
    text = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return True


# ---------------------------------------------------------------- les étapes en base

class Steps:
    """Écrit l'état des étapes dans production_steps (ou l'affiche en --dry-run)."""

    def __init__(self, sb: Supabase | None, job_id: str, dry_run: bool):
        self.sb = sb
        self.job_id = job_id
        self.dry_run = dry_run
        self.lock = threading.Lock()
        self.touched: set[tuple[str, str | None]] = set()

    def _set(self, step: str, lang: str | None, status: str, detail: dict | None = None, **extra) -> None:
        values = {"status": status, "updated_at": now_iso(), **extra}
        if detail is not None:
            values["detail"] = detail
        with self.lock:
            self.touched.add((step, lang))
        if self.dry_run or self.sb is None:
            summary = json.dumps(detail, ensure_ascii=False)[:160] if detail else ""
            log(f"  step {step}{'/' + lang if lang else ''} → {status} {summary}")
            return
        query = f"job_id=eq.{self.job_id}&step=eq.{step}&lang=" + (f"eq.{lang}" if lang else "is.null")
        try:
            rows = self.sb.update("production_steps", query, values)
            if not rows:
                # L'étape n'existait pas (job créé autrement) : on la crée.
                self.sb.insert("production_steps", [{"job_id": self.job_id, "step": step, "lang": lang, **values}])
        except SupabaseError as e:
            log(f"  (étape {step}/{lang} non enregistrée : {e})")

    def start(self, step: str, lang: str | None = None) -> None:
        self._set(step, lang, "running", started_at=now_iso())

    def done(self, step: str, lang: str | None = None, detail: dict | None = None) -> None:
        self._set(step, lang, "done", detail or {}, finished_at=now_iso())

    def fail(self, step: str, lang: str | None = None, detail: dict | None = None) -> None:
        self._set(step, lang, "failed", detail or {}, finished_at=now_iso())

    def skip(self, step: str, lang: str | None = None, detail: dict | None = None) -> None:
        self._set(step, lang, "skipped", detail or {}, finished_at=now_iso())

    def close_pending(self, reason: str) -> None:
        """Après un abandon : les étapes jamais touchées sont marquées skipped, pour que l'état du
        job ne reste pas « running »."""
        if self.dry_run or self.sb is None:
            return
        try:
            rows = self.sb.select("production_steps", f"job_id=eq.{self.job_id}&status=eq.pending&select=step,lang")
        except SupabaseError:
            return
        for row in rows:
            self.skip(row["step"], row.get("lang"), {"reason": reason})


# ---------------------------------------------------------------- le modèle

FAL_QUEUE = "https://queue.fal.run/fal-ai/any-llm"
DEFAULT_MODELS = {"anthropic": DEFAULT_MODEL, "fal": "anthropic/claude-sonnet-4.5"}


def detect_provider() -> str:
    """anthropic (API Anthropic, sorties JSON contraintes) ou fal (fal-ai/any-llm, JSON demandé dans le prompt)."""
    wanted = os.environ.get("PRODUCTION_PROVIDER", "").strip().lower()
    if wanted in DEFAULT_MODELS:
        return wanted
    if os.environ.get("ANTHROPIC_API_KEY", "").strip():
        return "anthropic"
    if os.environ.get("FAL_KEY", "").strip() or os.environ.get("FAL_API_KEY", "").strip():
        return "fal"
    return "anthropic"


def extract_json(text: str) -> dict:
    """Le premier objet JSON d'une réponse, avec ou sans clôture Markdown autour."""
    stripped = text.strip()
    stripped = re.sub(r"^```(?:json)?\s*", "", stripped)
    stripped = re.sub(r"\s*```$", "", stripped)
    try:
        value = json.loads(stripped)
        if isinstance(value, dict):
            return value
    except ValueError:
        pass
    start, end = stripped.find("{"), stripped.rfind("}")
    if start < 0 or end <= start:
        raise ProductionError("réponse du modèle sans objet JSON")
    value = json.loads(stripped[start:end + 1])
    if not isinstance(value, dict):
        raise ProductionError("réponse du modèle : JSON qui n'est pas un objet")
    return value


class LLM:
    """Appels au modèle avec sortie JSON : contrainte par schéma chez Anthropic, demandée dans le
    prompt et vérifiée à la lecture chez fal (fal-ai/any-llm)."""

    def __init__(self, model: str | None, fake: bool = False, provider: str | None = None):
        self.fake = fake
        self.provider = provider or detect_provider()
        self.model = model or os.environ.get("PRODUCTION_MODEL", "").strip() or DEFAULT_MODELS[self.provider]
        self.calls = 0
        self.input_tokens = 0
        self.output_tokens = 0
        self.lock = threading.Lock()
        self.client = None
        self.fal_key = ""
        if not fake and self.provider == "anthropic":
            import anthropic
            self.client = anthropic.Anthropic(max_retries=4, timeout=900.0)
        if not fake and self.provider == "fal":
            self.fal_key = os.environ.get("FAL_KEY", "").strip() or os.environ.get("FAL_API_KEY", "").strip()
            if not self.fal_key:
                raise ProductionError("FAL_KEY (ou FAL_API_KEY) absent")
        self.fallbacks = os.environ.get("PRODUCTION_FALLBACKS", "default").lower() not in ("off", "0", "false", "")

    def json_call(self, system: list[dict] | str, user: str, schema: dict, max_tokens: int = 32000, fake=None) -> dict:
        if self.fake:
            return fake() if callable(fake) else (fake or {})
        if self.provider == "fal":
            return self._fal_json(system, user, schema, max_tokens)
        return self._anthropic_json(system, user, schema, max_tokens)

    # ----- fal-ai/any-llm (file d'attente : soumission, puis attente du résultat)
    def _fal_request(self, method: str, url: str, payload: dict | None = None) -> dict:
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        headers = {"Authorization": f"Key {self.fal_key}", "Accept": "application/json"}
        if data is not None:
            headers["Content-Type"] = "application/json"
        delay = 2.0
        for attempt in range(5):
            req = urllib.request.Request(url, data=data, method=method, headers=headers)
            try:
                with urllib.request.urlopen(req, timeout=120) as resp:
                    return json.loads(resp.read() or b"{}")
            except urllib.error.HTTPError as e:
                body = e.read()[:400]
                if e.code in (429, 500, 502, 503, 504) and attempt < 4:
                    time.sleep(delay)
                    delay *= 2
                    continue
                raise ProductionError(f"fal {method} {url.split('?')[0]} : HTTP {e.code} {body!r}") from e
            except (urllib.error.URLError, TimeoutError) as e:
                if attempt < 4:
                    time.sleep(delay)
                    delay *= 2
                    continue
                raise ProductionError(f"fal : réseau {e}") from e
        raise ProductionError("fal : inatteignable")

    def _fal_json(self, system: list[dict] | str, user: str, schema: dict, max_tokens: int) -> dict:
        system_text = system if isinstance(system, str) else "\n\n".join(b.get("text", "") for b in system)
        contract = (
            "\n\nOUTPUT FORMAT. Answer with exactly one JSON object and nothing else: no prose before or after, no "
            "Markdown code fence. The object must match this JSON Schema (every required key present, no other key):\n"
            + json.dumps(schema, ensure_ascii=False)
        )
        prompt = user + contract
        last_error = ""
        for attempt in range(2):
            payload = {"model": self.model, "prompt": prompt if not last_error else prompt + "\n\nYour previous answer was rejected: " + last_error + ". Return only the JSON object.",
                       "system_prompt": system_text, "max_tokens": max_tokens, "priority": "throughput", "reasoning": False}
            submitted = self._fal_request("POST", FAL_QUEUE, payload)
            status_url = submitted.get("status_url") or f"{FAL_QUEUE}/requests/{submitted.get('request_id')}/status"
            response_url = submitted.get("response_url") or f"{FAL_QUEUE}/requests/{submitted.get('request_id')}"
            deadline = time.time() + 1500
            while True:
                status = self._fal_request("GET", status_url + ("&" if "?" in status_url else "?") + "logs=0")
                if status.get("status") == "COMPLETED":
                    break
                if time.time() > deadline:
                    raise ProductionError("fal : réponse non arrivée en 25 minutes")
                time.sleep(3)
            result = self._fal_request("GET", response_url)
            with self.lock:
                self.calls += 1
            if result.get("error"):
                raise ProductionError(f"fal any-llm : {str(result['error'])[:300]}")
            output = result.get("output") or ""
            if result.get("partial"):
                raise ProductionError("fal any-llm : réponse partielle (max_tokens trop bas ?)")
            try:
                value = extract_json(output)
            except (ValueError, ProductionError) as e:
                last_error = f"invalid JSON ({e})"
                continue
            missing = [k for k in schema.get("required", []) if k not in value]
            if missing:
                last_error = f"missing keys {missing}"
                continue
            return value
        raise ProductionError(f"fal any-llm : {last_error}")

    # ----- API Anthropic
    def _anthropic_json(self, system: list[dict] | str, user: str, schema: dict, max_tokens: int) -> dict:
        kwargs = dict(
            model=self.model,
            max_tokens=max_tokens,
            system=system,
            messages=[{"role": "user", "content": user}],
            output_config={"effort": "high", "format": {"type": "json_schema", "schema": schema}},
        )
        if self.fallbacks:
            # Repli serveur sur refus : la même requête est rejouée sur un modèle de repli.
            kwargs["extra_headers"] = {"anthropic-beta": "server-side-fallback-2026-07-01"}
            kwargs["extra_body"] = {"fallbacks": "default"}
        with self.client.messages.stream(**kwargs) as stream:
            message = stream.get_final_message()
        with self.lock:
            self.calls += 1
            self.input_tokens += getattr(message.usage, "input_tokens", 0) or 0
            self.output_tokens += getattr(message.usage, "output_tokens", 0) or 0
        if message.stop_reason == "refusal":
            raise ProductionError("le modèle a refusé la demande (stop_reason refusal)")
        if message.stop_reason == "max_tokens":
            raise ProductionError("réponse du modèle tronquée (max_tokens)")
        text = next((b.text for b in message.content if b.type == "text"), "")
        try:
            return json.loads(text)
        except ValueError as e:
            raise ProductionError(f"réponse du modèle illisible : {e}") from e

    def usage(self) -> dict:
        return {"provider": self.provider, "model": self.model, "calls": self.calls,
                "input_tokens": self.input_tokens, "output_tokens": self.output_tokens}


def schema_object(properties: dict, required: list[str] | None = None) -> dict:
    return {"type": "object", "properties": properties, "required": required or list(properties), "additionalProperties": False}


def schema_array(items: dict) -> dict:
    return {"type": "array", "items": items}


STR = {"type": "string"}
NULLABLE_STR = {"type": ["string", "null"]}
NULLABLE_STR_ARRAY = {"type": ["array", "null"], "items": STR}
NULLABLE_NUM = {"type": ["number", "null"]}
NULLABLE_INT = {"type": ["integer", "null"]}

TRANSLATION_SCHEMA = schema_object({
    "segments": schema_array(schema_object({"key": STR, "text": STR})),
    "glossary": schema_array(schema_object({"source_term": STR, "term": STR, "explanation": STR})),
    "quiz": schema_array(schema_object({
        "id": STR, "question": STR, "explanation": STR,
        "options": NULLABLE_STR_ARRAY, "items": NULLABLE_STR_ARRAY, "unit": NULLABLE_STR,
    })),
    "subcategory": STR,
    "notes": STR,
})

QUIZ_SCHEMA = schema_object({
    "questions": schema_array(schema_object({
        "type": {"type": "string", "enum": QUESTION_TYPES},
        "question": STR,
        "explanation": STR,
        "options": NULLABLE_STR_ARRAY,
        "correctIndex": NULLABLE_INT,
        "items": NULLABLE_STR_ARRAY,
        "correctValue": NULLABLE_NUM,
        "sliderMin": NULLABLE_NUM,
        "sliderMax": NULLABLE_NUM,
        "tolerance": NULLABLE_NUM,
        "unit": NULLABLE_STR,
        "sourceSectionId": STR,
        "evidence": STR,
    })),
})

VERDICT_SCHEMA = schema_object({
    "verdicts": schema_array(schema_object({"id": STR, "ok": {"type": "boolean"}, "reason": STR})),
})

GLOSSARY_SCHEMA = schema_object({
    "entries": schema_array(schema_object({
        "term": STR,
        "classification": {"type": "string", "enum": CLASSIFICATIONS},
        "explanation": STR,
    })),
})


# ---------------------------------------------------------------- le contexte d'un job

class Context:
    def __init__(self, args, job: dict, steps_rows: list[dict]):
        self.args = args
        self.job = job
        self.job_id = job["id"]
        self.course_id = job["course_id"]
        self.origin = job.get("origin_lang") or "fr"
        self.payload = job.get("payload") or {}
        self.options = job.get("options") or {}
        self.course = json.loads(json.dumps(self.payload.get("course") or {}))
        self.course.pop("quiz", None)
        self.studio_glossary = self.course.pop("glossary", None) or self.payload.get("glossary") or []
        self.creator = self.payload.get("creator")
        self.previous = self.payload.get("previous_content")
        if isinstance(self.previous, dict):
            self.previous = json.loads(json.dumps(self.previous))
            self.previous.pop("quiz", None)
            self.previous.pop("glossary", None)
        self.images = self.payload.get("images_to_import") or []
        self.is_new = bool(self.options.get("is_new", True))
        self.skip_audio = bool(self.options.get("skip_audio"))
        targets = args.languages.split(",") if args.languages else (self.options.get("languages") or [l for l in ALL_LANGS if l != self.origin])
        self.targets = [l for l in targets if l in ALL_LANGS and l != self.origin]
        self.step_rows = {(r["step"], r.get("lang")) for r in steps_rows}
        self.glossary: list[dict] = []       # entrées d'origine {term, classification, explanation}
        self.quiz: list[dict] = []           # questions d'origine (format QuizQuestion + sourceSectionId)
        self.quiz_report: dict = {}
        self.results: dict[str, dict] = {}   # par langue : {ok, findings, course, quiz, glossary, subcategory}
        self.published: list[str] = []
        self.failed: list[str] = []
        self.summary: dict = {}
        self.content_root: Path = cio.CONTENT_ROOT  # content/courses
        self.glossary_dir: Path = cio.GLOSSARY_DIR
        self.locales_dir: Path = self.content_root.parent / "locales"
        self.content_dir: Path = self.content_root.parent
        self.repo_content_dir: Path = ROOT / "content"

    # ----- fichiers
    def course_path(self, lang: str) -> Path:
        return self.content_root / lang / f"{self.course_id}.json"

    def quiz_path(self, lang: str) -> Path:
        return self.locales_dir / lang / "quizzes_v2.json"

    def glossary_path(self, lang: str) -> Path:
        return self.glossary_dir / f"{lang}.json"


def segments_dict(course: dict) -> dict[str, str]:
    return dict(cio.segments(course))


def course_text(course: dict) -> str:
    return "\n".join(text for _, text in cio.segments(course))


def glossary_terms_in_course(course: dict) -> list[str]:
    seen: list[str] = []
    for _, text in cio.segments(course):
        for term in GLOSSARY_RE.findall(text):
            term = term.strip()
            if term and term not in seen:
                seen.append(term)
    return seen


def sections_outline(course: dict, max_chars: int = 60000) -> str:
    """Le cours lisible par section, pour les appels quiz et glossaire."""
    lines = [f"# {course.get('title', '')}", course.get("description", ""), ""]
    for section in course.get("sections") or []:
        lines.append(f"## [{section.get('id')}] {section.get('title', '')}")
        for block in section.get("blocks") or []:
            kind = block.get("type")
            if kind in ("heading", "paragraph", "funFact", "takeaway", "quote"):
                prefix = {"heading": "### ", "funFact": "(Le saviez-vous ?) ", "takeaway": "(À retenir) ", "quote": "> "}.get(kind, "")
                lines.append(prefix + (block.get("text") or ""))
                if kind == "quote" and block.get("attribution"):
                    lines.append(f"-- {block['attribution']}")
            elif kind == "timeline":
                for event in block.get("events") or []:
                    lines.append(f"- {event.get('date', '')} : {event.get('title', '')}" + (f" ({event['detail']})" if event.get("detail") else ""))
            elif kind == "image" and block.get("caption"):
                lines.append(f"[image] {block['caption']}")
        lines.append("")
    text = "\n".join(lines)
    return text[:max_chars]


# ---------------------------------------------------------------- glossaire d'origine

def ensure_glossary(ctx: Context, llm: LLM) -> list[dict]:
    """Les entrées fournies par le Studio, complétées pour chaque [[terme]] sans entrée."""
    entries: dict[str, dict] = {}
    for entry in ctx.studio_glossary:
        term = str(entry.get("term", "")).strip()
        if term:
            entries[term] = {"term": term, "classification": entry.get("classification", "concept"), "explanation": entry.get("explanation", "")}
    terms = glossary_terms_in_course(ctx.course)
    norm_existing = {cio.normalise_term(t) for t in entries}
    missing = [t for t in terms if cio.normalise_term(t) not in norm_existing]
    if missing:
        log(f"glossaire : {len(missing)} terme(s) sans entrée, demandés au modèle")
        system = (
            "You write the glossary of an educational course for Sophia, a general-culture app. "
            f"Write in {LANGUAGE_NAMES.get(ctx.origin, ctx.origin)}, the language of the course. "
            "For each requested term, give its classification (referenceHistorique: a historical reference or period; "
            "concept: an idea or notion; evenementConnexe: a related event; personnage: a person; lieuInstitution: a place or institution) "
            "and a self-contained explanation of one to three sentences (10 to 600 characters), factual, simple, no em dash, "
            "no markup. The `term` field must be copied exactly as given."
        )
        user = f"Course:\n{sections_outline(ctx.course)}\n\nTerms to define (copy each exactly):\n" + "\n".join(f"- {t}" for t in missing)
        result = llm.json_call(system, user, GLOSSARY_SCHEMA, max_tokens=8000,
                               fake=lambda: {"entries": [{"term": t, "classification": "concept", "explanation": f"Définition de {t} (fictive)."} for t in missing]})
        for entry in result.get("entries", []):
            term = str(entry.get("term", "")).strip()
            if term and cio.normalise_term(term) in {cio.normalise_term(m) for m in missing}:
                entries[term] = {"term": term, "classification": entry.get("classification", "concept"), "explanation": entry.get("explanation", "")}
    # Les entrées dont le terme n'est plus dans le texte restent (le Studio peut définir plus large).
    return list(entries.values())


# ---------------------------------------------------------------- quiz d'origine

def normalize_question(q: dict, course_id: str, index: int, lang: str) -> dict | None:
    """Un objet QuizQuestion valide (CHARTE_QUIZ §3) ou None."""
    kind = q.get("type") or "mcq"
    if kind not in QUESTION_TYPES:
        return None
    out: dict = {"id": f"{course_id}_q{index}", "type": kind, "question": str(q.get("question", "")).strip(),
                 "explanation": str(q.get("explanation", "")).strip()}
    if len(out["question"]) < 5 or len(out["explanation"]) < 5:
        return None
    if kind == "mcq":
        options = [str(o).strip() for o in (q.get("options") or []) if str(o).strip()]
        if not 3 <= len(options) <= 5:
            return None
        correct = q.get("correctIndex") or 0
        if not 0 <= correct < len(options):
            return None
        # La bonne réponse en position 0 dans les données ; l'app mélange à l'affichage.
        options = [options[correct]] + options[:correct] + options[correct + 1:]
        if len(set(options)) != len(options):
            return None
        out.update(options=options, correctIndex=0)
    elif kind == "trueFalse":
        options = [str(o).strip() for o in (q.get("options") or [])]
        if len(options) != 2:
            return None
        correct = q.get("correctIndex")
        if correct not in (0, 1):
            return None
        out.update(options=options, correctIndex=correct)
    elif kind == "chronological":
        items = [str(i).strip() for i in (q.get("items") or []) if str(i).strip()]
        if not 3 <= len(items) <= 6 or any(re.search(r"\(\s*\d{3,4}\s*\)", i) for i in items):
            return None
        out.update(items=items)
    else:
        try:
            value, lo, hi, tol = (float(q.get(k)) for k in ("correctValue", "sliderMin", "sliderMax", "tolerance"))
        except (TypeError, ValueError):
            return None
        if kind == "percentageSlider":
            lo, hi = 0.0, 100.0
        if not lo <= value <= hi or tol <= 0:
            return None
        out.update(correctValue=value, sliderMin=lo, sliderMax=hi, tolerance=tol, unit=str(q.get("unit") or ("%" if kind == "percentageSlider" else "")))
    if q.get("sourceSectionId"):
        out["sourceSectionId"] = q["sourceSectionId"]
    return out


def quiz_rules_text(course: dict) -> str:
    section_ids = ", ".join(s.get("id", "") for s in course.get("sections") or [])
    return (
        "Rules (CHARTE_QUIZ): 6 to 10 questions, 8 for a course of normal density; every answer must be "
        "stated in the course text, never from outside knowledge. Types: mcq (3 to 5 options, the correct one first, "
        "plausible distractors of the same kind), trueFalse (exactly two options meaning True and False in the course "
        "language, correctIndex 0 for true or 1 for false), chronological (3 to 6 events in the correct order, no date "
        "in the labels), numericSlider (a value with a slider range and a tolerance), percentageSlider (0 to 100, unit %). "
        "Choose the type that fits each fact; never force a type. Questions are short, concrete, one fact each, in the "
        "same language and register as the course, no em dash. The explanation gives the answer and why, one or two "
        "sentences. `sourceSectionId` is the id of the section whose text proves the answer (one of: "
        f"{section_ids}) and `evidence` quotes the passage."
    )


def generate_quiz(ctx: Context, llm: LLM, feedback: str = "") -> list[dict]:
    system = (
        "You write end-of-course quizzes for Sophia, a general-culture app. Write in "
        f"{LANGUAGE_NAMES.get(ctx.origin, ctx.origin)}, the language of the course. " + quiz_rules_text(ctx.course)
    )
    user = f"Course:\n{sections_outline(ctx.course)}\n\nWrite the quiz." + (f"\n\nPrevious attempt, to improve on:\n{feedback}" if feedback else "")

    def fake():
        sections = ctx.course.get("sections") or []
        return {"questions": [
            {"type": "mcq", "question": f"Question factice {i} ?", "explanation": "Explication factice.",
             "options": ["Bonne réponse", "Leurre un", "Leurre deux", "Leurre trois"], "correctIndex": 0,
             "items": None, "correctValue": None, "sliderMin": None, "sliderMax": None, "tolerance": None, "unit": None,
             "sourceSectionId": sections[i % len(sections)].get("id", ""), "evidence": "…"} for i in range(1, 9)]}
    result = llm.json_call(system, user, QUIZ_SCHEMA, max_tokens=16000, fake=fake)
    questions = []
    for raw in result.get("questions", []):
        normalized = normalize_question(raw, ctx.course_id, len(questions) + 1, ctx.origin)
        if normalized:
            questions.append(normalized)
    return questions[:10]


def verify_quiz(ctx: Context, llm: LLM, quiz: list[dict]) -> dict[str, tuple[bool, str]]:
    """Second appel, à livre ouvert : chaque réponse est-elle justifiée par le texte ?"""
    system = (
        "You are the fact-checker of an educational quiz. You have the full course text. For each question, decide "
        "whether the marked correct answer is fully supported by the course text (not by outside knowledge), whether "
        "no distractor is also correct, whether the question is unambiguous, and whether the explanation is consistent "
        "with the text. For chronological items check the order against the text; for sliders check the value. "
        "Answer ok=false with a precise reason for any question that fails."
    )
    user = f"Course:\n{sections_outline(ctx.course)}\n\nQuestions (JSON):\n{json.dumps(quiz, ensure_ascii=False, indent=1)}"
    result = llm.json_call(system, user, VERDICT_SCHEMA, max_tokens=8000,
                           fake=lambda: {"verdicts": [{"id": q["id"], "ok": True, "reason": "ok"} for q in quiz]})
    verdicts = {q["id"]: (True, "") for q in quiz}
    for v in result.get("verdicts", []):
        if v.get("id") in verdicts:
            verdicts[v["id"]] = (bool(v.get("ok")), str(v.get("reason", "")))
    return verdicts


def ensure_quiz(ctx: Context, llm: LLM) -> list[dict]:
    """Le quiz du Studio, ou l'existant pour une mise à jour sans quiz, ou un quiz écrit par le modèle."""
    source = "studio"
    provided = ctx.payload.get("quiz")
    quiz: list[dict] = []
    if provided:
        for i, q in enumerate(provided, 1):
            normalized = normalize_question(q, ctx.course_id, i, ctx.origin)
            if normalized:
                quiz.append(normalized)
    if not quiz and not ctx.is_new:
        existing = read_json(ctx.quiz_path(ctx.origin), []) or []
        for entry in existing:
            if entry.get("courseId") == ctx.course_id and entry.get("quiz"):
                quiz = json.loads(json.dumps(entry["quiz"]))
                source = "existing"
                break
    if not quiz:
        quiz = generate_quiz(ctx, llm)
        source = "model"
    verdicts = verify_quiz(ctx, llm, quiz)
    rejected = {qid: reason for qid, (ok, reason) in verdicts.items() if not ok}
    kept = [q for q in quiz if q["id"] not in rejected]
    attempts = 1
    if len(kept) < 6 and source != "studio":
        feedback = "\n".join(f"- {qid}: {reason}" for qid, reason in rejected.items()) or "too few valid questions"
        quiz = generate_quiz(ctx, llm, feedback=feedback)
        verdicts = verify_quiz(ctx, llm, quiz)
        rejected = {qid: reason for qid, (ok, reason) in verdicts.items() if not ok}
        kept = [q for q in quiz if q["id"] not in rejected]
        attempts = 2
    if len(kept) < 6 and source == "studio" and len(quiz) >= 6:
        # Le quiz du Studio est gardé tel quel, avec les réserves dans le compte rendu.
        kept = quiz
    # Numérotation continue après les retraits (les ids d'un quiz existant sont conservés).
    if source != "existing":
        for i, q in enumerate(kept, 1):
            q["id"] = f"{ctx.course_id}_q{i}"
    ctx.quiz_report = {"source": source, "attempts": attempts, "questions": len(kept),
                       "rejected": [{"id": k, "reason": v} for k, v in rejected.items()],
                       "types": dict(Counter(q["type"] for q in kept))}
    if len(kept) < 6:
        raise ProductionError(f"quiz : {len(kept)} question(s) vérifiée(s) seulement, 6 au moins requises : {ctx.quiz_report}")
    return kept


def published_quiz(quiz: list[dict]) -> list[dict]:
    """Le quiz tel qu'il part dans les fichiers et en base : sans la citation de section."""
    return [{k: v for k, v in q.items() if k not in ("sourceSectionId", "evidence")} for q in quiz]


# ---------------------------------------------------------------- traduction

def guide_for(lang: str) -> str:
    path = ROOT / "content" / f"TRANSLATION_GUIDE_{lang.upper().replace('-', '_')}.md"
    if not path.exists():
        path = ROOT / "content" / "TRANSLATION_GUIDE_EN.md"
    return path.read_text(encoding="utf-8")


def terminology_for(lang: str) -> str:
    """Les formes imposées pour une langue : mots pièges, termes produit, titres d'œuvres."""
    term_dir = ROOT / "content" / "terminology"
    lines: list[str] = []
    traps = (read_json(term_dir / "mots_pieges.json", {}) or {}).get("entrees", [])
    for entry in traps:
        per = (entry.get("par_langue") or {}).get(lang) or {}
        if per.get("forme_imposee"):
            lines.append(f"- {entry.get('fr', entry.get('id'))} → « {per['forme_imposee']} »" + (f" ({per['note']})" if per.get("note") else ""))
    products = (read_json(term_dir / "termes_produit.json", {}) or {}).get("termes", [])
    for term in products:
        per = (term.get("par_langue") or {}).get(lang) or {}
        if per.get("canon"):
            lines.append(f"- product term {term.get('fr', term.get('id'))} → « {per['canon']} »")
    works = (read_json(term_dir / "oeuvres.json", {}) or {}).get("oeuvres", [])
    for work in works:
        per = (work.get("par_langue") or {}).get(lang) or {}
        if per.get("titre"):
            lines.append(f"- work title « {work.get('titre_fr')} » ({work.get('auteur', '')}) → « {per['titre']} »")
    return "\n".join(lines)


_SUBCATEGORY_CACHE: dict[str, dict[str, str]] = {}


def subcategory_map(ctx: Context, lang: str) -> dict[str, str]:
    """Libellé de sous-catégorie dans la langue pour chaque libellé d'origine, d'après les cours existants."""
    key = f"{ctx.origin}>{lang}"
    if key in _SUBCATEGORY_CACHE:
        return _SUBCATEGORY_CACHE[key]
    origin_by_id: dict[str, str] = {}
    for path in (ctx.repo_content_dir / "courses" / ctx.origin).glob("*.json"):
        course = read_json(path, {}) or {}
        origin_by_id[course.get("id", path.stem)] = course.get("subcategory", "")
    votes: dict[str, Counter] = defaultdict(Counter)
    for path in (ctx.repo_content_dir / "courses" / lang).glob("*.json"):
        course = read_json(path, {}) or {}
        source = origin_by_id.get(course.get("id", path.stem))
        if source and course.get("subcategory"):
            votes[source][course["subcategory"]] += 1
    mapping = {source: counter.most_common(1)[0][0] for source, counter in votes.items()}
    _SUBCATEGORY_CACHE[key] = mapping
    return mapping


def translation_memory(ctx: Context, lang: str) -> dict[str, str]:
    """Texte d'origine → texte traduit, pour les segments inchangés d'un cours déjà traduit."""
    memory: dict[str, str] = {}
    if not isinstance(ctx.previous, dict):
        return memory
    existing = read_json(ctx.course_path(lang))
    if not isinstance(existing, dict):
        return memory
    prev_segments = segments_dict(ctx.previous)
    done_segments = segments_dict(existing)
    for key, source in prev_segments.items():
        target = done_segments.get(key)
        if target and source.strip():
            memory[source] = target
    # Et le quiz déjà traduit, question par question.
    prev_quiz = next((e["quiz"] for e in (read_json(ctx.quiz_path(ctx.origin), []) or []) if e.get("courseId") == ctx.course_id), [])
    done_quiz = next((e["quiz"] for e in (read_json(ctx.quiz_path(lang), []) or []) if e.get("courseId") == ctx.course_id), [])
    done_by_id = {q.get("id"): q for q in done_quiz}
    for q in prev_quiz:
        t = done_by_id.get(q.get("id"))
        if not t:
            continue
        for field in TEXT_FIELDS:
            if q.get(field) and t.get(field):
                memory[q[field]] = t[field]
        for field in ("options", "items"):
            if isinstance(q.get(field), list) and isinstance(t.get(field), list) and len(q[field]) == len(t[field]):
                for a, b in zip(q[field], t[field]):
                    if isinstance(a, str) and isinstance(b, str):
                        memory[a] = b
    return memory


def system_prompt(ctx: Context, lang: str) -> list[dict]:
    name = LANGUAGE_NAMES.get(lang, lang)
    origin_name = LANGUAGE_NAMES.get(ctx.origin, ctx.origin)
    intro = (
        f"You are the native {name} editor of Sophia, a general-culture app with short illustrated courses. "
        f"You produce the {name} edition of a course written in {origin_name}: the text a native editor would have "
        "written from the same notes. The guide below is the specification; it was written for French sources, so read "
        f"\"French\" as \"the source language\" when the source is {origin_name}. Its target-language rules apply in full.\n\n"
        "Hard rules, enforced mechanically after you answer:\n"
        "- Keep every `**bold**` span and every `[[glossary term]]` marker: same count per segment, same position in the "
        "sentence; the text inside [[…]] is the translated glossary term, identical each time it appears and identical "
        "to the `term` you give in `glossary`. Never park a term at the end of a sentence; never drop one.\n"
        "- No em dash (—), no en dash (–), no curly quotes or apostrophes unless the guide requires them, no non-breaking "
        "or zero-width spaces. Follow the guide for quotation marks and number formats.\n"
        "- Translate every segment given, keep its key, change nothing structural. Years and bare numbers stay as they are.\n"
        "- Quiz: translate question, explanation, options and items; keep the order of options and items exactly (the "
        "first option of an mcq is the correct one; chronological items are in the correct order); the two trueFalse "
        "options are the words for True and False in the target language.\n"
        "- `subcategory`: use the known label when one is given, otherwise translate it as a short noun phrase.\n"
        "- `notes`: one line about any choice worth flagging, or an empty string."
    )
    terminology = terminology_for(lang)
    blocks = [
        {"type": "text", "text": intro},
        {"type": "text", "text": "TRANSLATION GUIDE\n\n" + guide_for(lang), "cache_control": {"type": "ephemeral"}},
    ]
    if terminology:
        blocks.append({"type": "text", "text": "IMPOSED TERMINOLOGY\n" + terminology})
    return blocks


def course_strings(course: dict, quiz: list[dict], glossary: dict[str, dict], course_id: str):
    """(surface, emplacement, texte) pour la terminologie, comme check_terminology.iter_texts."""
    for key, text in cio.segments(course):
        yield "cours", f"{course_id}/{key}", text
    for field in ("title", "subtitle", "description", "subcategory"):
        if course.get(field):
            yield "catalogue", f"{course_id}/{field}", course[field]
    for q in quiz:
        for field in TEXT_FIELDS:
            if q.get(field):
                yield "quiz", f"{q['id']}/{field}", q[field]
        for i, option in enumerate(q.get("options") or []):
            yield "quiz", f"{q['id']}/option{i}", option
        for i, item in enumerate(q.get("items") or []):
            yield "quiz", f"{q['id']}/item{i}", item
    for key, entry in glossary.items():
        for field in ("displayTerm", "explanation"):
            if entry.get(field):
                yield "glossaire", f"{key}/{field}", entry[field]


_RULES_CACHE: dict[str, list] = {}


def terminology_findings(lang: str, course: dict, quiz: list[dict], glossary: dict[str, dict], course_id: str) -> list[str]:
    from check_terminology import compile_rules, load_lists
    if lang not in _RULES_CACHE:
        _RULES_CACHE[lang] = compile_rules(lang, *load_lists())
    out = []
    for surface, location, text in course_strings(course, quiz, glossary, course_id):
        for kind, ident, expected, pattern, surfaces in _RULES_CACHE[lang]:
            if surfaces is not None and surface not in surfaces:
                continue
            match = pattern.search(text)
            if match:
                out.append(f"terminology {kind}:{ident} in {location}: found « {match.group(0)} », expected « {expected} »")
    return out


def structural_findings(origin_course: dict, course: dict, origin_quiz: list[dict], quiz: list[dict]) -> list[str]:
    out = []
    src, dst = segments_dict(origin_course), segments_dict(course)
    if list(src) != list(dst):
        out.append(f"structure: segment keys differ ({sorted(set(src) ^ set(dst))[:5]})")
    for key, text in dst.items():
        source = src.get(key, "")
        if "—" in text:
            out.append(f"{key}: em dash")
        if len(GLOSSARY_RE.findall(text)) != len(GLOSSARY_RE.findall(source)):
            out.append(f"{key}: glossary markers {len(GLOSSARY_RE.findall(text))} vs {len(GLOSSARY_RE.findall(source))} in source")
        if text.count("**") % 2 or text.count("**") != source.count("**"):
            out.append(f"{key}: bold markers {text.count('**')} vs {source.count('**')} in source")
        if not text.strip():
            out.append(f"{key}: empty")
    if len(quiz) != len(origin_quiz):
        out.append(f"quiz: {len(quiz)} questions vs {len(origin_quiz)}")
    return out


def validator_findings(ctx: Context, lang: str) -> list[str]:
    """scripts/check_course_translation.py sur ce cours (il lit les fichiers déjà écrits)."""
    if lang == "fr" or lang not in NON_FR_LANGS:
        return []
    from check_course_translation import check_course
    allowed = cio.glossary_keys_by_course(lang)
    return [f"{f.key} {f.rule}: {f.detail}" for f in check_course(ctx.course_id, lang, allowed)]


def apply_translation(ctx: Context, lang: str, result: dict, base_course: dict | None, base_quiz: list[dict] | None,
                      memory: dict[str, str]) -> tuple[dict, list[dict], dict[str, dict], list[str]]:
    """Reconstruit cours, quiz et glossaire traduits à partir de la réponse du modèle."""
    translations = {s["key"]: s["text"] for s in result.get("segments", []) if isinstance(s, dict) and s.get("key")}
    origin_segments = segments_dict(ctx.course)
    if base_course is not None:
        for key, text in segments_dict(base_course).items():
            translations.setdefault(key, text)
    for key, source in origin_segments.items():
        if key not in translations and source in memory:
            translations[key] = memory[source]
    course, missing = cio.apply_segments(ctx.course, translations)
    problems = [f"{k}: not translated" for k in missing]
    sub = result.get("subcategory") or (base_course or {}).get("subcategory")
    if sub:
        course["subcategory"] = sub
    course["id"] = ctx.course_id

    # Quiz : la structure vient de l'origine, les textes de la traduction.
    by_id = {q.get("id"): q for q in result.get("quiz", []) if isinstance(q, dict)}
    base_by_id = {q.get("id"): q for q in (base_quiz or [])}
    quiz = []
    for q in published_quiz(ctx.quiz):
        t = by_id.get(q["id"]) or base_by_id.get(q["id"]) or {}
        out = dict(q)
        for field in TEXT_FIELDS:
            value = t.get(field) or memory.get(q.get(field, ""), "")
            if value:
                out[field] = value
            else:
                problems.append(f"quiz {q['id']}.{field}: not translated")
        for field in ("options", "items"):
            if isinstance(q.get(field), list):
                values = t.get(field)
                if not (isinstance(values, list) and len(values) == len(q[field])):
                    values = [memory.get(v, "") for v in q[field]]
                if all(isinstance(v, str) and v.strip() for v in values):
                    out[field] = [v.strip() for v in values]
                else:
                    problems.append(f"quiz {q['id']}.{field}: not translated or wrong length")
        if q.get("unit") and t.get("unit"):
            out["unit"] = t["unit"]
        quiz.append(out)

    # Glossaire : chaque entrée d'origine doit avoir sa traduction, et le terme traduit doit être celui des [[…]].
    glossary: dict[str, dict] = {}
    by_source = {g.get("source_term", "").strip(): g for g in result.get("glossary", []) if isinstance(g, dict)}
    by_source_norm = {cio.normalise_term(k): v for k, v in by_source.items()}
    used_terms = glossary_terms_in_course(course)
    used_norm = {cio.normalise_term(t): t for t in used_terms}
    for entry in ctx.glossary:
        t = by_source.get(entry["term"]) or by_source_norm.get(cio.normalise_term(entry["term"]))
        if not t or not str(t.get("term", "")).strip():
            problems.append(f"glossary « {entry['term']} »: not translated")
            continue
        term = str(t["term"]).strip()
        # Si le texte emploie une variante (casse, espace), c'est celle du texte qui fait foi.
        term = used_norm.get(cio.normalise_term(term), term)
        glossary[f"{ctx.course_id}|{term}"] = {"displayTerm": term, "classification": entry["classification"],
                                                 "explanation": str(t.get("explanation", "")).strip() or entry["explanation"]}
    glossary_norm = {cio.normalise_term(k.split("|", 1)[1]) for k in glossary}
    for term in used_terms:
        if cio.normalise_term(term) not in glossary_norm:
            problems.append(f"glossary: [[{term}]] used in the text has no entry")
    return course, quiz, glossary, problems


def write_language(ctx: Context, lang: str, course: dict, quiz: list[dict], glossary: dict[str, dict]) -> None:
    """Écrit le cours, son quiz et son glossaire dans content/ pour une langue."""
    cio.write_course(lang, course)
    entries = read_json(ctx.quiz_path(lang), []) or []
    entries = [e for e in entries if e.get("courseId") != ctx.course_id] + [{"courseId": ctx.course_id, "quiz": quiz}]
    write_json(ctx.quiz_path(lang), entries)
    current = read_json(ctx.glossary_path(lang), {}) or {}
    kept = {k: v for k, v in current.items() if not k.startswith(f"{ctx.course_id}|")}
    kept.update(glossary)
    write_json(ctx.glossary_path(lang), kept)


def translate_language(ctx: Context, llm: LLM, steps: Steps, lang: str) -> dict:
    """Traduction, relecture, porte et réparations pour une langue. Rend le résultat (ok ou non)."""
    name = LANGUAGE_NAMES.get(lang, lang)
    steps.start("translate", lang)
    memory = translation_memory(ctx, lang)
    origin_segments = segments_dict(ctx.course)
    to_translate = {k: v for k, v in origin_segments.items() if v not in memory}
    reused = len(origin_segments) - len(to_translate)
    sub_map = subcategory_map(ctx, lang)
    known_sub = sub_map.get(ctx.course.get("subcategory", ""))
    system = system_prompt(ctx, lang)

    def user_prompt(extra: str = "") -> str:
        parts = [
            f"Course id: {ctx.course_id}. Subject: {ctx.course.get('subject')}. Source language: {LANGUAGE_NAMES.get(ctx.origin, ctx.origin)}. Target: {name}.",
            f"Subcategory (source): {ctx.course.get('subcategory', '')}" + (f" → known {name} label, use exactly: {known_sub}" if known_sub else " → translate it"),
            "Glossary entries of the course (source language). Translate `term` and `explanation`; the translated term is the one to use inside [[…]] in the text:",
            json.dumps(ctx.glossary, ensure_ascii=False, indent=1),
            "Segments to translate (key → source text):",
            json.dumps(to_translate, ensure_ascii=False, indent=1),
        ]
        if reused:
            sample = {k: {"source": v, "translation": memory[v]} for k, v in origin_segments.items() if v in memory}
            parts += ["Segments already translated in a previous edition, kept as they are; stay consistent with them:",
                      json.dumps(sample, ensure_ascii=False, indent=1)]
        parts += ["Quiz to translate (keep ids; translate question, explanation, options, items, unit):",
                  json.dumps(published_quiz(ctx.quiz), ensure_ascii=False, indent=1)]
        if extra:
            parts.append(extra)
        return "\n\n".join(parts)

    def fake_translation() -> dict:
        marker = "" if ctx.args.fake_llm else ""
        return {
            "segments": [{"key": k, "text": v + marker} for k, v in to_translate.items()],
            "glossary": [{"source_term": g["term"], "term": g["term"], "explanation": g["explanation"]} for g in ctx.glossary],
            "quiz": [{"id": q["id"], "question": q["question"], "explanation": q["explanation"],
                      "options": q.get("options"), "items": q.get("items"), "unit": q.get("unit")} for q in ctx.quiz],
            "subcategory": known_sub or ctx.course.get("subcategory", ""),
            "notes": "fake",
        }

    try:
        result = llm.json_call(system, user_prompt(), TRANSLATION_SCHEMA, fake=fake_translation)
        course, quiz, glossary, problems = apply_translation(ctx, lang, result, None, None, memory)

        # Relecture native adverse : fidélité d'abord, langue ensuite. Elle ne rend que ce qu'elle corrige.
        if not llm.fake:
            review_user = (
                f"REVIEW PASS. Below is the {name} edition you must review against the source: fidelity first (no fact "
                "drifted, dropped or added; numbers, names and order preserved), then language (idiomatic, simple, "
                "natural when read aloud, typography per the guide). Return ONLY the segments, quiz entries and glossary "
                "entries you change, corrected; return empty arrays when nothing needs changing. Keep every marker rule.\n\n"
                f"Source segments:\n{json.dumps(origin_segments, ensure_ascii=False, indent=1)}\n\n"
                f"{name} segments:\n{json.dumps(segments_dict(course), ensure_ascii=False, indent=1)}\n\n"
                f"{name} quiz:\n{json.dumps(quiz, ensure_ascii=False, indent=1)}\n\n"
                f"{name} glossary:\n{json.dumps([{'source_term': e['term'], 'term': k.split('|', 1)[1], 'explanation': v['explanation']} for e, (k, v) in zip(ctx.glossary, glossary.items())], ensure_ascii=False, indent=1)}"
            )
            review = llm.json_call(system, review_user, TRANSLATION_SCHEMA, max_tokens=24000)
            review.setdefault("subcategory", course.get("subcategory", ""))
            if review.get("segments") or review.get("quiz") or review.get("glossary"):
                merged_glossary = {g["source_term"]: g for g in result.get("glossary", []) if isinstance(g, dict)}
                for g in review.get("glossary", []):
                    if isinstance(g, dict) and g.get("source_term"):
                        merged_glossary[g["source_term"]] = g
                review["glossary"] = list(merged_glossary.values())
                review_quiz = {q.get("id"): q for q in result.get("quiz", []) if isinstance(q, dict)}
                for q in review.get("quiz", []):
                    if isinstance(q, dict) and q.get("id"):
                        review_quiz[q["id"]] = q
                review["quiz"] = list(review_quiz.values())
                course, quiz, glossary, problems = apply_translation(ctx, lang, review, course, quiz, memory)
            review_note = review.get("notes", "")
        else:
            review_note = ""

        # La porte, puis jusqu'à MAX_REPAIRS réparations à partir des constats.
        steps.done("translate", lang, {"segments": len(origin_segments), "retranslated": len(to_translate), "reused": reused,
                                       "notes": (result.get("notes") or "")[:300], "review": review_note[:300]})
        steps.start("gate", lang)
        findings: list[str] = []
        for attempt in range(MAX_REPAIRS + 1):
            write_language(ctx, lang, course, quiz, glossary)
            findings = structural_findings(ctx.course, course, ctx.quiz, quiz) + problems
            findings += terminology_findings(lang, course, quiz, glossary, ctx.course_id)
            if not ctx.args.skip_gate:
                findings += validator_findings(ctx, lang)
            if not findings or llm.fake or attempt == MAX_REPAIRS:
                break
            log(f"  [{lang}] {len(findings)} constat(s), réparation {attempt + 1}/{MAX_REPAIRS}")
            repair_user = user_prompt(
                "REPAIR PASS. The mechanical validator reports the findings below on your edition. Return the corrected "
                "segments, quiz entries and glossary entries (only those you change), fixing every finding without "
                "introducing new ones; keep everything else identical.\n\n"
                f"Current {name} segments:\n{json.dumps(segments_dict(course), ensure_ascii=False, indent=1)}\n\n"
                f"Current {name} quiz:\n{json.dumps(quiz, ensure_ascii=False, indent=1)}\n\n"
                f"Current {name} glossary:\n{json.dumps([{'source_term': e['term'], 'term': k.split('|', 1)[1], 'explanation': v['explanation']} for e, (k, v) in zip(ctx.glossary, glossary.items())], ensure_ascii=False, indent=1)}\n\n"
                "Findings:\n" + "\n".join(f"- {f}" for f in findings[:80])
            )
            repair = llm.json_call(system, repair_user, TRANSLATION_SCHEMA, max_tokens=24000)
            repair.setdefault("subcategory", course.get("subcategory", ""))
            course, quiz, glossary, problems = apply_translation(ctx, lang, repair, course, quiz, memory)
        ok = not findings
        detail = {"findings": findings[:60], "count": len(findings), "repairs": min(attempt, MAX_REPAIRS)}
        (steps.done if ok else steps.fail)("gate", lang, detail)
        log(f"  [{lang}] {'passe' if ok else 'retenue'} ({len(findings)} constat(s))")
        return {"ok": ok, "findings": findings, "course": course, "quiz": quiz, "glossary": glossary}
    except Exception as e:  # noqa: BLE001 — une langue qui plante ne doit pas emporter les autres
        detail = {"error": f"{type(e).__name__}: {e}"[:600]}
        log(f"  [{lang}] erreur : {detail['error']}")
        steps.fail("translate", lang, detail)
        steps.fail("gate", lang, {"error": "translation failed"})
        return {"ok": False, "findings": [detail["error"]], "course": None, "quiz": None, "glossary": None}


# ---------------------------------------------------------------- fichiers partagés de content/

def update_shared_files(ctx: Context, cover_slug: str | None, credit) -> None:
    content = ctx.content_dir
    index_path = content / "courses" / "index.json"
    index = read_json(index_path, {"courses": []}) or {"courses": []}
    if ctx.course_id not in index.get("courses", []):
        index.setdefault("courses", []).append(ctx.course_id)
        write_json(index_path, index)
    if cover_slug:
        image_map = read_json(content / "course_image_map.json", {}) or {}
        if image_map.get(ctx.course_id) != cover_slug:
            image_map[ctx.course_id] = cover_slug
            write_json(content / "course_image_map.json", image_map)
        if isinstance(credit, dict) and credit:
            credits = read_json(content / "image_credits.json", {}) or {}
            credits[cover_slug] = {k: credit.get(k, "") for k in ("title", "author", "license", "source")}
            write_json(content / "image_credits.json", credits)
    if ctx.creator and ctx.creator.get("slug"):
        authors_path = content / "authors.json"
        authors = read_json(authors_path, {"authors": []}) or {"authors": []}
        slug = ctx.creator["slug"]
        current = next((a for a in authors.get("authors", []) if a.get("slug") == slug), None)
        if current is None:
            current = {"slug": slug, "name": ctx.creator.get("name", slug), "photo": None, "institution": None, "country": None,
                       "links": {}, "title": {}, "bio": {}}
            authors.setdefault("authors", []).append(current)
        current["name"] = ctx.creator.get("name", current.get("name"))
        for field in ("institution", "country"):
            if ctx.creator.get(field) is not None:
                current[field] = ctx.creator[field]
        if ctx.creator.get("photo_url"):
            current["photo_url"] = ctx.creator["photo_url"]
        if ctx.creator.get("links"):
            current["links"] = ctx.creator["links"]
        for field in ("title", "bio"):
            if ctx.creator.get(field):
                current.setdefault(field, {})
                if not isinstance(current[field], dict):
                    current[field] = {}
                current[field][ctx.origin] = ctx.creator[field]
        write_json(authors_path, authors)


def update_withheld(ctx: Context, failed: list[str]) -> None:
    path = ctx.content_dir / "catalog_withheld.json"
    data = read_json(path, {"by_language": {}, "by_region": {}}) or {}
    by_lang = data.setdefault("by_language", {})
    changed = False
    for lang in ALL_LANGS:
        ids = by_lang.get(lang, [])
        if lang in failed and ctx.course_id not in ids:
            by_lang[lang] = sorted(set(ids) | {ctx.course_id})
            changed = True
        elif lang not in failed and ctx.course_id in ids:
            by_lang[lang] = [i for i in ids if i != ctx.course_id]
            changed = True
    if changed:
        write_json(path, data)


# ---------------------------------------------------------------- images et audio

def import_images(ctx: Context, sb: Supabase | None, steps: Steps) -> dict:
    steps.start("cover")
    hero = ctx.course.get("hero") or {}
    cover_slug = hero.get("image")
    imported, errors = [], []
    for item in ctx.images:
        slug, url = item.get("slug"), item.get("url")
        if not slug or not url or not url.startswith("https://"):
            errors.append(f"{slug}: bad url")
            continue
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "sophia-usine/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read(25_000_000)
            data, content_type = to_jpeg(raw)
            if ctx.args.dry_run or sb is None:
                log(f"  image {slug} ({len(data)} octets) non téléversée (dry-run)")
            else:
                sb.upload(IMAGE_BUCKET, f"{slug}.jpg", data, content_type, cache_control="public, max-age=86400")
            imported.append(slug)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{slug}: {type(e).__name__}: {e}"[:200])
    detail = {"cover": cover_slug, "imported": imported, "errors": errors}
    if errors and cover_slug in [e.split(":")[0] for e in errors]:
        steps.fail("cover", None, detail)
    elif not ctx.images:
        steps.done("cover", None, {"cover": cover_slug, "note": "no image to import (slug already in the bucket or no cover)"})
    else:
        steps.done("cover", None, detail)
    return detail


def to_jpeg(raw: bytes) -> tuple[bytes, str]:
    """Recadre en JPEG (côté max 1600 px) quand Pillow est là ; sinon l'image telle quelle."""
    try:
        from PIL import Image
    except ImportError:
        return raw, "image/jpeg"
    image = Image.open(io.BytesIO(raw))
    image = image.convert("RGB")
    image.thumbnail((1600, 1600))
    out = io.BytesIO()
    image.save(out, format="JPEG", quality=85, optimize=True)
    return out.getvalue(), "image/jpeg"


def render_audio(ctx: Context, sb: Supabase | None, steps: Steps, lang: str, course: dict) -> dict:
    steps.start("audio", lang)
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    voice = os.environ.get(f"ELEVENLABS_VOICE_{lang.upper().replace('-', '_')}", "").strip()
    if ctx.skip_audio:
        steps.skip("audio", lang, {"reason": "skip_audio option"})
        return {"skipped": "option"}
    if lang not in AUDIO_LANGS:
        steps.skip("audio", lang, {"reason": f"no narration rules for {lang}"})
        return {"skipped": "language"}
    if not key or not voice:
        steps.skip("audio", lang, {"reason": "ELEVENLABS_API_KEY or ELEVENLABS_VOICE_<LANG> not set"})
        return {"skipped": "not configured"}
    try:
        sys.path.insert(0, str(SCRIPTS / "tts"))
        import importlib
        tts_common = importlib.import_module("tts_common")
        lang_mod = importlib.import_module(f"lang_{lang}")
        text, chapters, _parts = tts_common.render(course, lang_mod, tts_common.Log())
        issues = tts_common.problems(text, lang_mod)
        if issues:
            steps.fail("audio", lang, {"problems": [f"{k}: {w}" for k, w in issues][:20]})
            return {"failed": "narration text has residues"}
        if ctx.args.dry_run or sb is None:
            steps.done("audio", lang, {"characters": len(text), "chapters": len(chapters), "note": "dry-run, nothing rendered"})
            return {"dry_run": True}
        body = json.dumps({"text": text, "model_id": "eleven_multilingual_v2",
                           "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}}).encode()
        req = urllib.request.Request(f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
                                     data=body, method="POST",
                                     headers={"xi-api-key": key, "Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=600) as resp:
            mp3 = resp.read()
        path = f"{lang}/{ctx.course_id}.mp3"
        sb.upload(AUDIO_BUCKET, path, mp3, "audio/mpeg", cache_control="public, max-age=31536000")
        manifest = json.loads(sb.download_public(AUDIO_BUCKET, "manifest.json") or b"{}")
        ids = set(manifest.get(lang, []))
        ids.add(ctx.course_id)
        manifest[lang] = sorted(ids)
        sb.upload(AUDIO_BUCKET, "manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2).encode(),
                  "application/json", cache_control="public, max-age=300")
        sb.upsert("course_assets", [{"course_id": ctx.course_id, "slug": ctx.course_id, "kind": "audio", "lang": lang,
                                     "url": f"{sb.url}/storage/v1/object/public/{AUDIO_BUCKET}/{path}"}],
                  on_conflict="course_id,kind,slug,lang")
        steps.done("audio", lang, {"characters": len(text), "bytes": len(mp3), "path": path})
        return {"path": path}
    except Exception as e:  # noqa: BLE001
        steps.fail("audio", lang, {"error": f"{type(e).__name__}: {e}"[:400]})
        return {"failed": str(e)[:200]}


# ---------------------------------------------------------------- publication en base

def glossary_payload(ctx: Context, lang: str, glossary: dict[str, dict] | None = None) -> dict:
    if glossary is not None:
        return glossary
    return {f"{ctx.course_id}|{e['term']}": {"displayTerm": e["term"], "classification": e["classification"], "explanation": e["explanation"]}
            for e in ctx.glossary}


def publish_language(ctx: Context, sb: Supabase | None, lang: str, course: dict, quiz: list[dict], glossary: dict, status: str) -> dict | None:
    params = {
        "p_lang": lang, "p_course": course, "p_quiz": quiz, "p_glossary": glossary, "p_status": status,
        "p_creator_slug": (ctx.creator or {}).get("slug") or course.get("author"),
        "p_cover_slug": (course.get("hero") or {}).get("image"),
        "p_with_assets": lang == ctx.origin,
    }
    if ctx.args.dry_run or sb is None:
        log(f"  publish {lang} → {status} (dry-run)")
        return None
    result = sb.rpc("catalog_upsert_course", params)
    sb.rpc("catalog_finalize_language", {"p_lang": lang})
    return result


# ---------------------------------------------------------------- git

def commit_and_push(ctx: Context, message: str) -> str | None:
    if ctx.args.dry_run or ctx.args.no_commit or ctx.args.out_root:
        log("commit : sauté (dry-run / --no-commit / --out-root)")
        return None
    env = dict(os.environ)
    git = ["git", "-c", "user.name=Sophia usine", "-c", "user.email=usine@users.noreply.github.com"]
    subprocess.run([*git, "add", "-A", "content"], cwd=ROOT, check=True)
    if subprocess.run([*git, "diff", "--cached", "--quiet"], cwd=ROOT).returncode == 0:
        log("commit : rien à écrire")
        return None
    subprocess.run([*git, "commit", "-q", "-m", message], cwd=ROOT, check=True, env=env)
    sha = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    branch = os.environ.get("PRODUCE_BRANCH") or "main"
    for attempt in range(3):
        pull = subprocess.run([*git, "pull", "--rebase", "-q", "origin", branch], cwd=ROOT)
        push = subprocess.run(["git", "push", "-q", "origin", f"HEAD:{branch}"], cwd=ROOT)
        if pull.returncode == 0 and push.returncode == 0:
            log(f"commit {sha} poussé sur {branch}")
            return sha
        time.sleep(2 ** attempt)
    # La branche est protégée ou la course perdue : une branche et une pull request à la place.
    side = f"usine/{ctx.course_id}"
    subprocess.run(["git", "push", "-q", "-f", "origin", f"HEAD:{side}"], cwd=ROOT, check=True)
    log(f"push sur {branch} refusé : commit {sha} poussé sur {side}")
    if subprocess.run(["which", "gh"], capture_output=True).returncode == 0:
        subprocess.run(["gh", "pr", "create", "--base", branch, "--head", side, "--title", message,
                        "--body", f"Produit par l'usine (job {ctx.job_id}). Fusionner pour que content/ reflète la base."],
                       cwd=ROOT, env=env)
    return sha


# ---------------------------------------------------------------- le job

def load_job(args) -> tuple[Supabase | None, dict, list[dict]]:
    if args.job_file:
        data = read_json(Path(args.job_file))
        if not isinstance(data, dict):
            sys.exit(f"{args.job_file} : JSON illisible")
        job = data.get("job") or data
        job.setdefault("id", "local-job")
        steps = data.get("steps") or []
        sb = None
        if not args.dry_run:
            sb = Supabase(os.environ.get("SUPABASE_URL", DEFAULT_URL), env_key())
        return sb, job, steps
    sb = Supabase(os.environ.get("SUPABASE_URL", DEFAULT_URL), env_key())
    rows = sb.select("production_jobs", f"id=eq.{args.job}&select=*")
    if not rows:
        sys.exit(f"job {args.job} introuvable")
    steps = sb.select("production_steps", f"job_id=eq.{args.job}&select=step,lang,status&order=id")
    return sb, rows[0], steps


def run(args) -> int:
    sb, job, step_rows = load_job(args)
    ctx = Context(args, job, step_rows)
    if args.out_root:
        # Mode test : tout content/ est recréé sous out_root (les sources nécessaires y sont copiées).
        out = Path(args.out_root)
        (out / "courses").mkdir(parents=True, exist_ok=True)
        (out / "glossary").mkdir(exist_ok=True)
        (out / "locales").mkdir(exist_ok=True)
        cio.CONTENT_ROOT = out / "courses"
        cio.GLOSSARY_DIR = out / "glossary"
        ctx.content_root, ctx.glossary_dir = cio.CONTENT_ROOT, cio.GLOSSARY_DIR
        ctx.locales_dir, ctx.content_dir = out / "locales", out
        for lang in [ctx.origin, *ctx.targets]:
            (out / "courses" / lang).mkdir(exist_ok=True)
            (out / "locales" / lang).mkdir(exist_ok=True)
            if not (out / "glossary" / f"{lang}.json").exists():
                write_json(out / "glossary" / f"{lang}.json", {})
    if not ctx.course or not ctx.course.get("sections"):
        sys.exit("payload.course absent ou sans sections")
    steps = Steps(sb, ctx.job_id, args.dry_run)
    llm = LLM(args.model, fake=args.fake_llm, provider=args.provider)
    log(f"job {ctx.job_id} · {ctx.course_id} · origine {ctx.origin} · {len(ctx.targets)} langue(s) · {llm.provider} {llm.model}"
        + (" · FAKE" if llm.fake else ""))
    hero = ctx.course.get("hero") or {}
    cover_slug = hero.get("image")

    try:
        # 1. glossaire d'origine
        steps.start("glossary")
        ctx.glossary = ensure_glossary(ctx, llm)
        steps.done("glossary", None, {"entries": len(ctx.glossary), "from_studio": len(ctx.studio_glossary)})

        # 2. quiz d'origine, vérifié à livre ouvert
        steps.start("quiz")
        try:
            ctx.quiz = ensure_quiz(ctx, llm)
        except ProductionError as e:
            steps.fail("quiz", None, {"error": str(e)[:600], **ctx.quiz_report})
            raise
        steps.done("quiz", None, ctx.quiz_report)

        # 3. fichiers d'origine et publication de la langue d'origine
        origin_glossary = glossary_payload(ctx, ctx.origin)
        write_language(ctx, ctx.origin, ctx.course, published_quiz(ctx.quiz), origin_glossary)
        update_shared_files(ctx, cover_slug, hero.get("credit"))
        publish_language(ctx, sb, ctx.origin, ctx.course, published_quiz(ctx.quiz), origin_glossary, "published")
        ctx.published.append(ctx.origin)

        # 4. couverture et images
        cover = import_images(ctx, sb, steps)

        # 5. traductions : le français d'abord quand il n'est pas l'origine (c'est le pivot des porte),
        #    puis les autres langues en parallèle.
        ordered = [l for l in ctx.targets if l == "fr"] + [l for l in ctx.targets if l != "fr"]
        if "fr" in ordered:
            ctx.results["fr"] = translate_language(ctx, llm, steps, "fr")
            ordered.remove("fr")
        workers = max(1, int(os.environ.get("PRODUCTION_WORKERS", "4")))
        with ThreadPoolExecutor(max_workers=workers) as pool:
            for lang, result in zip(ordered, pool.map(lambda l: translate_language(ctx, llm, steps, l), ordered)):
                ctx.results[lang] = result

        # 6. publication langue par langue
        steps.start("publish")
        for lang in ctx.targets:
            result = ctx.results.get(lang) or {"ok": False, "course": None}
            if result["ok"]:
                publish_language(ctx, sb, lang, result["course"], result["quiz"], result["glossary"], "published")
                ctx.published.append(lang)
            else:
                ctx.failed.append(lang)
                if result.get("course"):
                    publish_language(ctx, sb, lang, result["course"], result["quiz"], result["glossary"], "failed")
        update_withheld(ctx, ctx.failed)
        if not args.dry_run and sb is not None:
            sb.update("courses", f"id=eq.{ctx.course_id}", {"status": "published", "origin_lang": ctx.origin,
                                                           "published_at": now_iso(), "updated_at": now_iso()})
        steps.done("publish", None, {"published": ctx.published, "failed": ctx.failed})

        # 7. audio (fr, en) sur les langues publiées
        audio = {}
        for lang in ("fr", "en"):
            if ("audio", lang) not in ctx.step_rows and not args.job_file:
                continue
            course = ctx.course if lang == ctx.origin else (ctx.results.get(lang) or {}).get("course")
            if lang in ctx.published and course:
                audio[lang] = render_audio(ctx, sb, steps, lang, course)
            else:
                steps.skip("audio", lang, {"reason": f"{lang} not published"})
                audio[lang] = {"skipped": "not published"}

        # 8. commit
        sha = commit_and_push(ctx, f"Usine : {ctx.course_id} ({len(ctx.published)} langue(s))")
        ctx.summary = {
            "published": ctx.published, "failed": {l: (ctx.results.get(l) or {}).get("findings", [])[:20] for l in ctx.failed},
            "quiz": ctx.quiz_report, "glossary_entries": len(ctx.glossary), "cover": cover, "audio": audio,
            "commit": sha, "llm": llm.usage(), "finished_at": now_iso(),
        }
        if not args.dry_run and sb is not None:
            sb.update("production_jobs", f"id=eq.{ctx.job_id}", {"summary": ctx.summary, "error": None, "updated_at": now_iso()})
        log(f"terminé : {len(ctx.published)} publiée(s) {ctx.published}, {len(ctx.failed)} retenue(s) {ctx.failed}, {llm.usage()}")
        if args.out_root:
            log(f"fichiers écrits sous {args.out_root}")
        return 0 if not ctx.failed else 2
    except Exception as e:  # noqa: BLE001
        error = f"{type(e).__name__}: {e}"
        log(f"ABANDON : {error}")
        traceback.print_exc()
        steps.close_pending(f"job aborted: {error[:200]}")
        if not args.dry_run and sb is not None:
            try:
                sb.update("production_jobs", f"id=eq.{ctx.job_id}", {"error": error[:1000], "summary": {"llm": llm.usage(), "published": ctx.published},
                                                                      "updated_at": now_iso()})
            except SupabaseError:
                pass
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--job", help="id du job (production_jobs.id)")
    parser.add_argument("--job-file", help="un job local {job:{…}, steps:[…]} ou directement la ligne de production_jobs")
    parser.add_argument("--languages", help="langues cibles, séparées par des virgules (défaut : celles du job)")
    parser.add_argument("--model", default=None, help="défaut : PRODUCTION_MODEL, sinon claude-opus-5-5 (Anthropic) ou anthropic/claude-sonnet-4.5 (fal)")
    parser.add_argument("--provider", choices=["anthropic", "fal"], default=None,
                        help="défaut : PRODUCTION_PROVIDER, sinon anthropic si ANTHROPIC_API_KEY est posée, sinon fal si FAL_KEY l'est")
    parser.add_argument("--dry-run", action="store_true", help="n'écrit ni en base ni dans Storage, ne pousse pas")
    parser.add_argument("--fake-llm", action="store_true", help="pas d'appel au modèle : les textes source tiennent lieu de traduction")
    parser.add_argument("--skip-gate", action="store_true", help="ne lance pas check_course_translation (tests)")
    parser.add_argument("--no-commit", action="store_true")
    parser.add_argument("--out-root", help="écrit les fichiers sous ce dossier au lieu de content/ (tests)")
    args = parser.parse_args()
    if not args.job and not args.job_file:
        parser.error("--job ou --job-file requis")
    return run(args)


if __name__ == "__main__":
    sys.exit(main())
