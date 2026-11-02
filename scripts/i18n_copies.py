#!/usr/bin/env python3
"""Every copy of every displayed string, per language, and a way to rewrite them all.

The same text lives in several files: the course sources (content/courses), the
iOS bundles (Resources/CoursesV2), the Android copies (assets/courses_v2), the
catalogs (courses / course_index / glossary / collections, iOS and Android), the
quiz source (content/locales/<lang>/quizzes_v2.json), the UI tables
(AppLocalizable.swift, Android strings, content/locales/<lang>/ui_strings.json)
and the legal packs. The Android export rewrites more than it should (Android-only
UI keys), so a correction is applied here to every copy at once, string by string,
and each file is written back in exactly the format it had.

    from i18n_copies import apply_mapping
    apply_mapping("fi", {"vanha teksti": "uusi teksti"})   # -> per-file change counts
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from i18n_languages import SWIFT_CASE_BY_CODE

ROOT = Path(__file__).resolve().parents[1]
LOCALIZABLE = ROOT / "ios" / "Sophia" / "Utilities" / "AppLocalizable.swift"

_DUMPERS = {
    "indent2": lambda d: json.dumps(d, ensure_ascii=False, indent=2) + "\n",
    "min_sorted": lambda d: json.dumps(d, ensure_ascii=False, separators=(",", ":"), sort_keys=True),
    "min_nl": lambda d: json.dumps(d, ensure_ascii=False, separators=(",", ":")) + "\n",
    "min": lambda d: json.dumps(d, ensure_ascii=False, separators=(",", ":")),
    "indent2_nonl": lambda d: json.dumps(d, ensure_ascii=False, indent=2),
}


def json_files(lang: str) -> list[Path]:
    a = ROOT / "android" / "app" / "src" / "main" / "assets"
    i = ROOT / "ios" / "Sophia" / "Resources"
    files = sorted((ROOT / "content" / "courses" / lang).glob("*.json"))
    files += sorted((i / "CoursesV2").glob(f"*.{lang}.json"))
    files += sorted((a / "courses_v2" / lang).glob("*.json"))
    for name in ("courses", "course_index", "glossary", "collections"):
        files += [p for p in (i / "Locales" / f"{name}.{lang}.json", a / "locales" / f"{name}.{lang}.json") if p.exists()]
    for p in (ROOT / "content" / "locales" / lang / "quizzes_v2.json", ROOT / "content" / "locales" / lang / "ui_strings.json",
              ROOT / "content" / "locales" / lang / "legal.json", a / "strings" / f"{lang}.json", a / "legal" / f"{lang}.json"):
        if p.exists():
            files.append(p)
    return files


def _style(raw: str, data) -> str:
    for name, dump in _DUMPERS.items():
        if dump(data) == raw:
            return name
    raise ValueError("unknown JSON layout")


def _rewrite(value, mapping: dict[str, str], counter: list[int]):
    if isinstance(value, str):
        if value in mapping:
            counter[0] += 1
            return mapping[value]
        return value
    if isinstance(value, list):
        return [_rewrite(v, mapping, counter) for v in value]
    if isinstance(value, dict):
        # Dict keys are rewritten too: glossary keys are "<courseId>|<displayTerm>".
        out = {}
        for k, v in value.items():
            nk = k
            if "|" in k:
                cid, _, term = k.partition("|")
                if term in mapping:
                    nk = f"{cid}|{mapping[term]}"
                    counter[0] += 1
            out[nk] = _rewrite(v, mapping, counter)
        return out
    return value


def _swift_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def apply_mapping(lang: str, mapping: dict[str, str], dry_run: bool = False) -> dict[str, int]:
    """Replace whole strings equal to a mapping key, in every copy of ``lang``."""
    changes: dict[str, int] = {}
    if not mapping:
        return changes
    for path in json_files(lang):
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
        style = _style(raw, data)
        counter = [0]
        new = _rewrite(data, mapping, counter)
        if counter[0]:
            changes[str(path.relative_to(ROOT))] = counter[0]
            if not dry_run:
                path.write_text(_DUMPERS[style](new), encoding="utf-8")
    # iOS UI table: entries are one per line inside `private static let <case>: [String: String] = [`.
    source = LOCALIZABLE.read_text(encoding="utf-8")
    name = SWIFT_CASE_BY_CODE.get(lang)
    m = re.search(r"private static let %s: \[String: String\] = \[(.*?)\n    \]" % name, source, re.S) if name else None
    if m:
        body = m.group(1)
        count = 0
        for old, new in mapping.items():
            needle = f': "{_swift_escape(old)}"'
            if needle in body:
                count += body.count(needle)
                body = body.replace(needle, f': "{_swift_escape(new)}"')
        if count:
            changes[str(LOCALIZABLE.relative_to(ROOT))] = count
            if not dry_run:
                LOCALIZABLE.write_text(source[: m.start(1)] + body + source[m.end(1):], encoding="utf-8")
    return changes
