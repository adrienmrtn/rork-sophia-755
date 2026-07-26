#!/usr/bin/env python3
"""Machine-translate AppLocalizable English UI keys into new app languages.

Source of truth for keys/values: the English dictionary in
``ios/Sophia/Utilities/AppLocalizable.swift``.

Outputs:
  - ``content/locales/_ui_mt_cache/<lang>.json`` (MT cache, gitignored)
  - ``content/locales/<lang>/ui_strings.json`` (key → translated string)
  - optionally rewrites ``AppLocalizable.swift`` with dedicated dictionaries

Usage:
    python scripts/translate_ui_strings.py translate --lang tr --workers 10
    python scripts/translate_ui_strings.py translate --lang all --workers 10
    python scripts/translate_ui_strings.py inject
    python scripts/translate_ui_strings.py qa --lang all
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from i18n_languages import NON_FR_LANGS, SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"
CACHE_DIR = ROOT / "content" / "locales" / "_ui_mt_cache"
LOCALES_DIR = ROOT / "content" / "locales"

# Languages that already ship hand-maintained packs — never overwrite them here.
EXISTING_PACKS = {"fr", "en", "es", "de", "pt", "it"}
NEW_UI_LANGS = [code for code in NON_FR_LANGS if code not in EXISTING_PACKS]

ENTRY_RE = re.compile(r'^\s*"((?:\\.|[^"\\])*)":\s*"((?:\\.|[^"\\])*)",?\s*$')
# Format tokens + newlines/tabs on *decoded* string values.
TOKEN_RE = re.compile(
    r"%(?:\d+\$)?(?:lld|ld|lu|lf|f|d|@)|\n|\t"
)

NATIVE_LANGUAGE_NAMES: dict[str, str] = {
    "french": "Français",
    "english": "English",
    "spanish": "Español",
    "german": "Deutsch",
    "portuguese": "Português",
    "italian": "Italiano",
    "turkish": "Türkçe",
    "polish": "Polski",
    "romanian": "Română",
    "dutch": "Nederlands",
    "greek": "Ελληνικά",
    "swedish": "Svenska",
    "hungarian": "Magyar",
    "bulgarian": "Български",
    "czech": "Čeština",
}

SECTION_TITLES = {
    "french": "French",
    "english": "English",
    "spanish": "Spanish",
    "german": "German",
    "portuguese": "Portuguese",
    "italian": "Italian",
    "turkish": "Turkish",
    "polish": "Polish",
    "romanian": "Romanian",
    "dutch": "Dutch",
    "greek": "Greek",
    "swedish": "Swedish",
    "hungarian": "Hungarian",
    "bulgarian": "Bulgarian",
    "czech": "Czech",
}


_SWIFT_UNICODE_RE = re.compile(r"\\u\{([0-9a-fA-F]+)\}")


def decode_swift_string(raw: str) -> str:
    """Decode a Swift string literal body (not JSON — supports \\u{...})."""
    # Normalize Swift unicode scalars to JSON-compatible \\uXXXX when possible.
    def repl(match: re.Match[str]) -> str:
        code = int(match.group(1), 16)
        if code <= 0xFFFF:
            return f"\\u{code:04x}"
        # Outside BMP: emit the actual character directly.
        return chr(code)

    normalized = _SWIFT_UNICODE_RE.sub(repl, raw)
    try:
        return json.loads(f'"{normalized}"')
    except json.JSONDecodeError:
        # Last-resort unescape for common Swift escapes.
        out: list[str] = []
        i = 0
        while i < len(normalized):
            ch = normalized[i]
            if ch != "\\" or i + 1 >= len(normalized):
                out.append(ch)
                i += 1
                continue
            nxt = normalized[i + 1]
            mapping = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}
            out.append(mapping.get(nxt, nxt))
            i += 2
        return "".join(out)


def encode_swift_string(value: str) -> str:
    """Encode a Python string as a Swift/JSON-compatible literal body."""
    # Prefer readable \\n over JSON's default escaping of non-ascii.
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\t", "\\t")
        .replace("\r", "\\r")
    )


def extract_dict_entries(source: str, name: str) -> list[tuple[str, str]]:
    match = re.search(
        rf"private static let {name}: \[String: String\] = \[",
        source,
    )
    if not match:
        raise SystemExit(f"Dictionary {name!r} not found in AppLocalizable.swift")
    start = match.end() - 1
    depth = 0
    i = start
    while i < len(source):
        ch = source[i]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                body = source[start + 1 : i]
                break
        i += 1
    else:
        raise SystemExit(f"Unclosed dictionary {name!r}")

    entries: list[tuple[str, str]] = []
    for line in body.splitlines():
        m = ENTRY_RE.match(line)
        if not m:
            continue
        entries.append((decode_swift_string(m.group(1)), decode_swift_string(m.group(2))))
    return entries


def protect_tokens(text: str) -> tuple[str, list[str]]:
    tokens: list[str] = []

    def repl(match: re.Match[str]) -> str:
        tokens.append(match.group(0))
        return f"ZZP{len(tokens) - 1}ZZ"

    return TOKEN_RE.sub(repl, text), tokens


def restore_tokens(text: str, tokens: list[str]) -> str:
    out = text
    for idx, token in enumerate(tokens):
        # Google sometimes inserts spaces around markers.
        patterns = [
            f"ZZP{idx}ZZ",
            f"ZZP {idx} ZZ",
            f"zzp{idx}zz",
            f"Zzp{idx}Zz",
        ]
        for pattern in patterns:
            if pattern in out:
                out = out.replace(pattern, token)
                break
        else:
            # Soft recovery: leave as-is; QA will flag placeholder drift.
            pass
    return out


def pinned_value(key: str, english: str) -> str | None:
    if key.startswith("language.") and key != "language.section":
        name = key.removeprefix("language.")
        return NATIVE_LANGUAGE_NAMES.get(name, english)
    # Pure brand / empty / punctuation-only — keep English.
    if english.strip() in {"", "Sophia", "Sophia.", "XP", "OK", "iOS"}:
        return english
    if not re.search(r"[A-Za-zÀ-ÿ]", english):
        return english
    return None


def translate_one(target: str, text: str) -> str:
    from deep_translator import GoogleTranslator

    if not text:
        return text
    protected, tokens = protect_tokens(text)
    # Skip MT when nothing alphabetic remains (placeholders / symbols only).
    if not re.search(r"[A-Za-zÀ-ÿ]", protected):
        return text

    client = GoogleTranslator(source="en", target=target)
    for attempt in range(6):
        try:
            result = client.translate(protected)
            if result is None:
                raise RuntimeError("empty translation")
            return restore_tokens(result, tokens)
        except Exception as error:  # noqa: BLE001
            time.sleep(min(2**attempt, 20))
            client = GoogleTranslator(source="en", target=target)
            if attempt == 5:
                print(
                    f"    warn: MT failed, keeping EN: {text[:60]!r} ({error})",
                    file=sys.stderr,
                )
                return text
    return text


def placeholder_signature(text: str) -> list[str]:
    return TOKEN_RE.findall(text)


def translate_lang(lang: str, workers: int, force: bool) -> Path:
    if lang not in NEW_UI_LANGS:
        raise SystemExit(f"Unsupported lang {lang!r}. Expected one of {NEW_UI_LANGS}")

    source = LOCALIZABLE.read_text(encoding="utf-8")
    entries = extract_dict_entries(source, "english")
    print(f"[{lang}] English keys: {len(entries)}")

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_path = CACHE_DIR / f"{lang}.json"
    cache: dict[str, str] = {}
    if cache_path.exists() and not force:
        cache = json.loads(cache_path.read_text(encoding="utf-8"))

    out: dict[str, str] = {}
    pending: list[tuple[str, str]] = []

    for key, english in entries:
        pinned = pinned_value(key, english)
        if pinned is not None:
            out[key] = pinned
            continue
        cached = cache.get(english)
        if cached is not None and not force:
            out[key] = cached
            continue
        pending.append((key, english))

    print(f"[{lang}] cached/pinned={len(entries) - len(pending)}  to_translate={len(pending)}")

    if pending:
        # Dedupe by English source text.
        unique = sorted({english for _, english in pending})
        translated_unique: dict[str, str] = {}

        def work(text: str) -> tuple[str, str]:
            return text, translate_one(lang, text)

        done = 0
        with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
            futures = [pool.submit(work, text) for text in unique]
            for fut in as_completed(futures):
                src, dst = fut.result()
                translated_unique[src] = dst
                cache[src] = dst
                done += 1
                if done % 50 == 0 or done == len(unique):
                    print(f"[{lang}] MT {done}/{len(unique)}")
                    cache_path.write_text(
                        json.dumps(cache, ensure_ascii=False, indent=0) + "\n",
                        encoding="utf-8",
                    )

        for key, english in pending:
            out[key] = translated_unique[english]

    # Soft placeholder repair: if counts drift, fall back to English for that key.
    en_map = dict(entries)
    repaired = 0
    for key, value in list(out.items()):
        if placeholder_signature(value) != placeholder_signature(en_map[key]):
            out[key] = en_map[key]
            repaired += 1
    if repaired:
        print(f"[{lang}] placeholder drift → kept EN for {repaired} keys")

    # Ensure every language.* endonym is correct even if EN block was incomplete.
    for name, label in NATIVE_LANGUAGE_NAMES.items():
        out[f"language.{name}"] = label

    # Apply curated chrome overrides when present (short labels / imperatives).
    overrides_path = ROOT / "scripts" / "ui_string_overrides.json"
    if overrides_path.exists():
        all_overrides = json.loads(overrides_path.read_text(encoding="utf-8"))
        for key, value in all_overrides.get(lang, {}).items():
            out[key] = value

    locale_dir = LOCALES_DIR / lang
    locale_dir.mkdir(parents=True, exist_ok=True)
    out_path = locale_dir / "ui_strings.json"
    # Stable key order matching English dictionary order.
    ordered = {key: out[key] for key, _ in entries if key in out}
    # Append any extra keys we forced (should not happen).
    for key, value in out.items():
        if key not in ordered:
            ordered[key] = value
    out_path.write_text(
        json.dumps(ordered, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    cache_path.write_text(
        json.dumps(cache, ensure_ascii=False, indent=0) + "\n",
        encoding="utf-8",
    )
    print(f"[{lang}] wrote {out_path} ({len(ordered)} keys)")
    return out_path


def render_dict_body(entries: list[tuple[str, str]]) -> str:
    lines = [f'        "{encode_swift_string(k)}": "{encode_swift_string(v)}",' for k, v in entries]
    return "\n".join(lines)


def load_pack_entries(lang: str) -> list[tuple[str, str]]:
    path = LOCALES_DIR / lang / "ui_strings.json"
    if not path.exists():
        raise SystemExit(f"Missing UI pack: {path}. Run translate first.")
    data = json.loads(path.read_text(encoding="utf-8"))
    source = LOCALIZABLE.read_text(encoding="utf-8")
    english = extract_dict_entries(source, "english")
    en_keys = [k for k, _ in english]
    missing = [k for k in en_keys if k not in data]
    if missing:
        raise SystemExit(f"{lang}: missing {len(missing)} keys vs EN (e.g. {missing[:5]})")
    return [(k, data[k]) for k in en_keys]


def inject() -> None:
    source = LOCALIZABLE.read_text(encoding="utf-8")
    shipped_codes = ["fr", "en", "es", "de", "pt", "it", *NEW_UI_LANGS]
    shipped_names = [SWIFT_CASE_BY_CODE[c] for c in shipped_codes]

    dict_bodies: dict[str, str] = {}
    for code in shipped_codes:
        name = SWIFT_CASE_BY_CODE[code]
        if code in EXISTING_PACKS:
            entries = extract_dict_entries(source, name)
            # Keep endonyms complete on existing packs too.
            as_map = dict(entries)
            for lang_name, label in NATIVE_LANGUAGE_NAMES.items():
                as_map[f"language.{lang_name}"] = label
            # Preserve original key order, append any new language.* keys after language.italian block area.
            ordered: list[tuple[str, str]] = []
            seen = set()
            for key, _ in entries:
                ordered.append((key, as_map[key]))
                seen.add(key)
            for lang_name in NATIVE_LANGUAGE_NAMES:
                key = f"language.{lang_name}"
                if key not in seen:
                    # Insert near other language keys if possible.
                    ordered.append((key, as_map[key]))
            dict_bodies[name] = render_dict_body(ordered)
        else:
            dict_bodies[name] = render_dict_body(load_pack_entries(code))

    case_lines = []
    for name in shipped_names:
        case_lines.append(f"        case .{name}: {name}")

    sections = []
    for name in shipped_names:
        title = SECTION_TITLES.get(name, name.capitalize())
        sections.append(
            f"""    // MARK: - {title}

    private static let {name}: [String: String] = [
{dict_bodies[name]}
    ]"""
        )

    rendered = f"""import Foundation

enum AppLocalizable {{
    static func string(_ key: String, language: AppLanguage) -> String {{
        if let value = table(for: language)[key] {{
            return value
        }}
        if language != .english, let value = english[key] {{
            return value
        }}
        return key
    }}

    private static func table(for language: AppLanguage) -> [String: String] {{
        switch language {{
{chr(10).join(case_lines)}
        }}
    }}

{chr(10).join(sections)}
}}
"""
    LOCALIZABLE.write_text(rendered, encoding="utf-8")
    print(f"Wrote {LOCALIZABLE} with {len(shipped_names)} language dictionaries")


def qa(langs: list[str]) -> int:
    source = LOCALIZABLE.read_text(encoding="utf-8")
    english = dict(extract_dict_entries(source, "english"))
    hard = 0
    for lang in langs:
        name = SWIFT_CASE_BY_CODE[lang]
        try:
            entries = extract_dict_entries(source, name)
        except SystemExit:
            print(f"HARD {lang}: dictionary missing in AppLocalizable.swift")
            hard += 1
            continue
        data = dict(entries)
        missing = sorted(set(english) - set(data))
        if missing:
            print(f"HARD {lang}: missing {len(missing)} keys (e.g. {missing[:3]})")
            hard += len(missing)
        drift = 0
        for key, en_val in english.items():
            val = data.get(key)
            if val is None:
                continue
            if placeholder_signature(val) != placeholder_signature(en_val):
                drift += 1
        if drift:
            print(f"HARD {lang}: placeholder drift on {drift} keys")
            hard += drift
        print(f"OK {lang}: {len(data)} keys")
    if hard:
        print(f"QA FAIL hard={hard}")
        return 1
    print("QA PASS")
    return 0


def translate_infoplist(langs: list[str]) -> None:
    """Translate NSUserTrackingUsageDescription into each new .lproj."""
    from deep_translator import GoogleTranslator

    en = (
        ROOT / "ios" / "Sophia" / "en.lproj" / "InfoPlist.strings"
    ).read_text(encoding="utf-8")
    m = re.search(r'NSUserTrackingUsageDescription\s*=\s*"(.*)";', en)
    if not m:
        print("warn: could not parse EN InfoPlist.strings", file=sys.stderr)
        return
    en_text = m.group(1)
    for lang in langs:
        try:
            translated = GoogleTranslator(source="en", target=lang).translate(en_text)
        except Exception as error:  # noqa: BLE001
            print(f"warn: InfoPlist {lang}: {error}", file=sys.stderr)
            translated = en_text
        path = ROOT / "ios" / "Sophia" / f"{lang}.lproj" / "InfoPlist.strings"
        path.parent.mkdir(parents=True, exist_ok=True)
        escaped = encode_swift_string(translated)
        path.write_text(
            f'NSUserTrackingUsageDescription = "{escaped}";\n',
            encoding="utf-8",
        )
        print(f"InfoPlist {lang}: ok")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_tr = sub.add_parser("translate", help="MT English UI keys into locale JSON packs")
    p_tr.add_argument("--lang", required=True, help="Language code or 'all'")
    p_tr.add_argument("--workers", type=int, default=8)
    p_tr.add_argument("--force", action="store_true")
    p_tr.add_argument("--infoplist", action="store_true", help="Also translate InfoPlist.strings")

    sub.add_parser("inject", help="Rewrite AppLocalizable.swift with all UI packs")

    p_qa = sub.add_parser("qa", help="Check key/placeholder parity in AppLocalizable")
    p_qa.add_argument("--lang", default="all")

    args = parser.parse_args()

    if args.cmd == "translate":
        langs = NEW_UI_LANGS if args.lang == "all" else [args.lang]
        for lang in langs:
            if lang not in NEW_UI_LANGS:
                raise SystemExit(f"lang {lang} not in {NEW_UI_LANGS}")
            translate_lang(lang, workers=args.workers, force=args.force)
        if args.infoplist:
            translate_infoplist(langs)
        return 0

    if args.cmd == "inject":
        inject()
        return 0

    if args.cmd == "qa":
        # Default "all" = newly added UI packs. Pass an explicit code to check
        # an older pack (some intentional EN/ES copy diffs exist historically).
        langs = NEW_UI_LANGS if args.lang == "all" else [args.lang]
        return qa(langs)

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
