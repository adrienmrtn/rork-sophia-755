#!/usr/bin/env python3
"""Translate EN Terms/Privacy into new app languages and inject into LegalDocumentContent.swift.

Usage:
  PYTHONPATH=scripts python3 scripts/translate_legal_docs.py translate --lang all --workers 2
  PYTHONPATH=scripts python3 scripts/translate_legal_docs.py inject
  PYTHONPATH=scripts python3 scripts/translate_legal_docs.py qa --lang all

Never rewrites French legal copy. Existing es/de/pt/it packs stay in Swift unless --force-existing.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from i18n_languages import GT_TARGETS, NON_FR_LANGS, SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
LEGAL_SWIFT = ROOT / "ios/Sophia/Utilities/LegalDocumentContent.swift"
EN_PACK = ROOT / "content/locales/en/legal.json"
CACHE_DIR = ROOT / "content/locales/_legal_mt_cache"
NEW_LANGS = [c for c in NON_FR_LANGS if c not in {"en", "es", "de", "pt", "it"}]

SWIFT_PROP = {
    "en": "English",
    "es": "Spanish",
    "de": "German",
    "pt": "Portuguese",
    "it": "Italian",
    "tr": "Turkish",
    "pl": "Polish",
    "ro": "Romanian",
    "nl": "Dutch",
    "el": "Greek",
    "sv": "Swedish",
    "hu": "Hungarian",
    "bg": "Bulgarian",
    "cs": "Czech",
}

CASE_NAME = {
    "en": "english",
    "es": "spanish",
    "de": "german",
    "pt": "portuguese",
    "it": "italian",
    "tr": "turkish",
    "pl": "polish",
    "ro": "romanian",
    "nl": "dutch",
    "el": "greek",
    "sv": "swedish",
    "hu": "hungarian",
    "bg": "bulgarian",
    "cs": "czech",
}


def _translate_one(target: str, text: str) -> str:
    if not text or not text.strip():
        return text
    # Keep pure bullets / punctuation
    if not re.search(r"[A-Za-zÀ-ÿ]", text):
        return text
    import translators as ts
    from deep_translator import GoogleTranslator
    from deep_translator.exceptions import TooManyRequests

    last: Exception | None = None
    try:
        time.sleep(0.15)
        result = GoogleTranslator(source="en", target=target).translate(text)
        if result and result.strip():
            return result
    except TooManyRequests as error:
        last = error
    except Exception as error:  # noqa: BLE001
        last = error

    for attempt in range(5):
        try:
            time.sleep(0.22)
            result = ts.translate_text(
                text, translator="bing", from_language="en", to_language=target
            )
            if result and str(result).strip():
                return str(result)
        except Exception as error:  # noqa: BLE001
            last = error
            time.sleep(min(2 * (2**attempt), 30))
    raise RuntimeError(f"MT failed: {text[:60]!r} ({last})")


def load_en() -> dict:
    if EN_PACK.exists():
        return json.loads(EN_PACK.read_text(encoding="utf-8"))
    raise SystemExit(f"Missing {EN_PACK} — extract EN legal first")


def pack_path(lang: str) -> Path:
    return ROOT / "content" / "locales" / lang / "legal.json"


def translate_lang(lang: str, *, workers: int, force: bool) -> Path:
    en = load_en()
    out_path = pack_path(lang)
    if out_path.exists() and not force:
        print(f"[{lang}] exists, skip (use --force)")
        return out_path

    target = GT_TARGETS[lang]
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_path = CACHE_DIR / f"{lang}.json"
    cache: dict[str, str] = {}
    if cache_path.exists():
        cache = json.loads(cache_path.read_text(encoding="utf-8"))

    pending: list[str] = []
    for kind in ("terms", "privacy"):
        for section in en[kind]:
            for field in ("title", "body"):
                text = section[field]
                if text not in cache:
                    pending.append(text)

    # unique preserve order
    seen: set[str] = set()
    unique = []
    for text in pending:
        if text not in seen:
            seen.add(text)
            unique.append(text)

    print(f"[{lang}] warming {len(unique)} strings (workers={workers})…")
    if unique:
        with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
            futs = {pool.submit(_translate_one, target, t): t for t in unique}
            done = 0
            for fut in as_completed(futs):
                src = futs[fut]
                cache[src] = fut.result()
                done += 1
                if done % 20 == 0 or done == len(unique):
                    print(f"  [{lang}] {done}/{len(unique)}", flush=True)
                    cache_path.write_text(
                        json.dumps(cache, ensure_ascii=False, indent=0) + "\n",
                        encoding="utf-8",
                    )
        cache_path.write_text(json.dumps(cache, ensure_ascii=False, indent=0) + "\n", encoding="utf-8")

    out = {"terms": [], "privacy": []}
    for kind in ("terms", "privacy"):
        for section in en[kind]:
            out[kind].append(
                {
                    "id": section["id"],
                    "title": cache[section["title"]],
                    "body": cache[section["body"]],
                }
            )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[{lang}] wrote {out_path}")
    return out_path


def swift_escape(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )


def render_sections(sections: list[dict]) -> str:
    lines = []
    for section in sections:
        lines.append(
            "        LegalSection("
            f'id: "{section["id"]}", '
            f'title: "{swift_escape(section["title"])}", '
            f'body: "{swift_escape(section["body"])}"'
            "),"
        )
    return "\n".join(lines)


def extract_existing_swift_array(text: str, name: str) -> str | None:
    m = re.search(rf"private static let {name}:\s*\[LegalSection\]\s*=\s*\[", text)
    if not m:
        return None
    start = m.start()
    # find end of array assignment including closing ]
    bracket_start = m.end() - 1
    depth = 0
    i = bracket_start
    while i < len(text):
        if text[i] == "[":
            depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0:
                # include trailing newline after ]
                end = i + 1
                if end < len(text) and text[end] == "\n":
                    end += 1
                return text[start:end]
        i += 1
    return None


def inject() -> None:
    source = LEGAL_SWIFT.read_text(encoding="utf-8")
    # Keep FR + existing lang arrays from current file.
    keep_names = [
        "termsFrench",
        "termsEnglish",
        "privacyFrench",
        "privacyEnglish",
        "termsSpanish",
        "termsGerman",
        "termsPortuguese",
        "termsItalian",
        "privacySpanish",
        "privacyGerman",
        "privacyPortuguese",
        "privacyItalian",
    ]
    kept = {name: extract_existing_swift_array(source, name) for name in keep_names}
    missing = [n for n, v in kept.items() if not v]
    if missing:
        raise SystemExit(f"Cannot extract existing arrays: {missing}")

    # Load new packs
    new_blocks: list[str] = []
    for lang in NEW_LANGS:
        path = pack_path(lang)
        if not path.exists():
            raise SystemExit(f"Missing {path}. Run translate first.")
        data = json.loads(path.read_text(encoding="utf-8"))
        prop = SWIFT_PROP[lang]
        new_blocks.append(
            f"""    // MARK: - Terms ({lang.upper()})

    private static let terms{prop}: [LegalSection] = [
{render_sections(data['terms'])}
    ]

    // MARK: - Privacy ({lang.upper()})

    private static let privacy{prop}: [LegalSection] = [
{render_sections(data['privacy'])}
    ]
"""
        )

    terms_cases = [
        "        case .french: termsFrench",
        "        case .english: termsEnglish",
        "        case .spanish: termsSpanish",
        "        case .german: termsGerman",
        "        case .portuguese: termsPortuguese",
        "        case .italian: termsItalian",
    ]
    privacy_cases = list(terms_cases)
    for lang in NEW_LANGS:
        case = CASE_NAME[lang]
        prop = SWIFT_PROP[lang]
        terms_cases.append(f"        case .{case}: terms{prop}")
        privacy_cases.append(f"        case .{case}: privacy{prop}")

    rendered = f"""import Foundation

struct LegalSection: Identifiable {{
    let id: String
    let title: String
    let body: String
}}

enum LegalDocumentContent {{
    static func terms(language: AppLanguage) -> [LegalSection] {{
        switch language {{
{chr(10).join(terms_cases)}
        }}
    }}

    static func privacy(language: AppLanguage) -> [LegalSection] {{
        switch language {{
{chr(10).join(privacy_cases)}
        }}
    }}

    // MARK: - Terms (FR)

{kept['termsFrench']}
    // MARK: - Terms (EN)

{kept['termsEnglish']}
    // MARK: - Privacy (FR)

{kept['privacyFrench']}
    // MARK: - Privacy (EN)

{kept['privacyEnglish']}
    // MARK: - Terms (ES)

{kept['termsSpanish']}
    // MARK: - Terms (DE)

{kept['termsGerman']}
    // MARK: - Terms (PT)

{kept['termsPortuguese']}
    // MARK: - Terms (IT)

{kept['termsItalian']}
    // MARK: - Privacy (ES)

{kept['privacySpanish']}
    // MARK: - Privacy (DE)

{kept['privacyGerman']}
    // MARK: - Privacy (PT)

{kept['privacyPortuguese']}
    // MARK: - Privacy (IT)

{kept['privacyItalian']}
{''.join(new_blocks)}}}
"""
    # Verify FR arrays unchanged
    fr_terms_old = kept["termsFrench"]
    fr_priv_old = kept["privacyFrench"]
    if fr_terms_old not in rendered or fr_priv_old not in rendered:
        raise SystemExit("FR legal arrays would be altered — abort")

    LEGAL_SWIFT.write_text(rendered, encoding="utf-8")
    print(f"Wrote {LEGAL_SWIFT}")


def qa(langs: list[str]) -> int:
    en = load_en()
    hard = 0
    source = LEGAL_SWIFT.read_text(encoding="utf-8")
    # Ensure no EN fallback for new langs
    if re.search(
        r"case \.turkish.*:\s*\n\s*termsEnglish",
        source,
        re.S,
    ) or "termsEnglish\n        }" in source and "case .turkish, .polish" in source:
        # Detect old grouped fallback
        if "case .turkish, .polish" in source:
            print("HARD: new langs still fall back to English in switch")
            hard += 1

    for lang in langs:
        path = pack_path(lang)
        if not path.exists():
            print(f"HARD {lang}: missing {path}")
            hard += 1
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        for kind in ("terms", "privacy"):
            if len(data.get(kind, [])) != len(en[kind]):
                print(
                    f"HARD {lang} {kind}: {len(data.get(kind, []))} sections != EN {len(en[kind])}"
                )
                hard += 1
                continue
            for a, b in zip(data[kind], en[kind]):
                if a["id"] != b["id"]:
                    print(f"HARD {lang} {kind}: id {a['id']} != {b['id']}")
                    hard += 1
                if not a["title"].strip() or not a["body"].strip():
                    print(f"HARD {lang} {kind}: empty section {a['id']}")
                    hard += 1
                # Identical long body to EN is suspicious (except proper names)
                if a["body"] == b["body"] and len(a["body"]) > 80:
                    print(f"SOFT {lang} {kind}#{a['id']}: body identical to EN")
            prop = SWIFT_PROP[lang]
            if f"terms{prop}" not in source or f"privacy{prop}" not in source:
                print(f"HARD {lang}: missing Swift arrays terms{prop}/privacy{prop}")
                hard += 1
            if f"case .{CASE_NAME[lang]}: terms{prop}" not in source:
                print(f"HARD {lang}: switch not wired for terms")
                hard += 1
    # FR unchanged vs git is caller's job; check FR still present
    if "termsFrench" not in source or "privacyFrench" not in source:
        print("HARD: French legal missing")
        hard += 1
    print("LEGAL QA PASS" if hard == 0 else f"LEGAL QA FAIL ({hard})")
    return 1 if hard else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_tr = sub.add_parser("translate")
    p_tr.add_argument("--lang", required=True)
    p_tr.add_argument("--workers", type=int, default=2)
    p_tr.add_argument("--force", action="store_true")

    sub.add_parser("inject")

    p_qa = sub.add_parser("qa")
    p_qa.add_argument("--lang", required=True)

    args = parser.parse_args()
    if args.cmd == "translate":
        langs = NEW_LANGS if args.lang == "all" else [args.lang]
        for lang in langs:
            if lang not in NEW_LANGS:
                raise SystemExit(f"lang {lang} not in {NEW_LANGS}")
            translate_lang(lang, workers=args.workers, force=args.force)
        return 0
    if args.cmd == "inject":
        inject()
        return 0
    if args.cmd == "qa":
        langs = NEW_LANGS if args.lang == "all" else [args.lang]
        return qa(langs)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
