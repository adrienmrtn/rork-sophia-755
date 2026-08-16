#!/usr/bin/env python3
"""Export iOS / content packs into Android assets (all 15 languages).

Sources (in priority order):
  1. Working tree under ios/Sophia and content/
  2. Optional --from-ref (e.g. origin/main) via `git show` / `git archive`

Writes:
  android/app/src/main/assets/locales/{courses,course_index,collections,glossary}.{lang}.json
  android/app/src/main/assets/courses_v2/{lang}/{courseId}.json
  android/app/src/main/assets/strings/{lang}.json   (new langs from ui_strings + overrides)
  android/app/src/main/assets/locales/courses.fr.json (+ collections/glossary) from Swift when present

Course catalogs are slimmed after copy (no lesson bodies; lesson text lives in courses_v2).
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tarfile
import tempfile
from io import BytesIO
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS_LOCALES = ROOT / "ios" / "Sophia" / "Resources" / "Locales"
IOS_COURSES_V2 = ROOT / "ios" / "Sophia" / "Resources" / "CoursesV2"
CONTENT_LOCALES = ROOT / "content" / "locales"
OVERRIDES_PATH = ROOT / "scripts" / "ui_string_overrides.json"
ANDROID_ASSETS = ROOT / "android" / "app" / "src" / "main" / "assets"
ANDROID_LOCALES = ANDROID_ASSETS / "locales"
ANDROID_STRINGS = ANDROID_ASSETS / "strings"
ANDROID_COURSES_V2 = ANDROID_ASSETS / "courses_v2"

# Full app language set (matches iOS AppLanguage).
ALL_LANGS = [
    "fr", "en", "es", "de", "pt", "it",
    "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs",
]
# New packs that may only exist on main / content/
NEW_LANGS = ["tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs"]


# ---------------------------------------------------------------------------
# git helpers
# ---------------------------------------------------------------------------


def git_show(ref: str, path: str) -> bytes | None:
    try:
        return subprocess.check_output(
            ["git", "show", f"{ref}:{path}"],
            cwd=ROOT,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return None


def extract_archive(ref: str, paths: list[str], dest: Path) -> None:
    """Extract selected paths from ref into dest via git archive."""
    cmd = ["git", "archive", ref, *paths]
    data = subprocess.check_output(cmd, cwd=ROOT)
    dest.mkdir(parents=True, exist_ok=True)
    with tarfile.open(fileobj=BytesIO(data), mode="r:") as tar:
        tar.extractall(dest)


# ---------------------------------------------------------------------------
# I/O
# ---------------------------------------------------------------------------


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def load_json_bytes(raw: bytes) -> object:
    return json.loads(raw.decode("utf-8"))


def resolve_file(local: Path, ref: str | None, repo_path: str) -> bytes | None:
    if local.is_file():
        return local.read_bytes()
    if ref:
        return git_show(ref, repo_path)
    return None


def copy_locale_json(ref: str | None) -> list[str]:
    ANDROID_LOCALES.mkdir(parents=True, exist_ok=True)
    copied: list[str] = []
    kinds = ("courses", "collections", "glossary")
    for lang in ALL_LANGS:
        for kind in kinds:
            name = f"{kind}.{lang}.json"
            local = IOS_LOCALES / name
            # FR glossary/courses may be Swift-only on iOS; still try JSON.
            raw = resolve_file(local, ref, f"ios/Sophia/Resources/Locales/{name}")
            if raw is None:
                continue
            dest = ANDROID_LOCALES / name
            dest.write_bytes(raw)
            copied.append(name)
    return copied


def export_courses_v2(ref: str | None) -> dict[str, int]:
    """Map iOS CoursesV2/<id>.<lang>.json → android courses_v2/<lang>/<id>.json."""
    counts: dict[str, int] = {lang: 0 for lang in ALL_LANGS}
    pattern = re.compile(r"^(?P<id>.+)\.(?P<lang>[a-z]{2})\.json$")

    sources: list[tuple[str, bytes]] = []  # (filename, bytes)

    if IOS_COURSES_V2.is_dir():
        for src in IOS_COURSES_V2.glob("*.json"):
            sources.append((src.name, src.read_bytes()))

    # Always pull from ref when provided so new langs on main are included even if
    # the working tree only has the original 6-language CoursesV2 set.
    if ref:
        listing = subprocess.check_output(
            ["git", "ls-tree", "-r", "--name-only", ref, "--", "ios/Sophia/Resources/CoursesV2"],
            cwd=ROOT,
            text=True,
        )
        names = [Path(line).name for line in listing.splitlines() if line.endswith(".json")]
        print(f"  fetching {len(names)} CoursesV2 files from {ref}…")
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            extract_archive(ref, ["ios/Sophia/Resources/CoursesV2"], tmp_path)
            v2 = tmp_path / "ios" / "Sophia" / "Resources" / "CoursesV2"
            # Prefer ref versions (overwrite local list for same names).
            by_name = {name: raw for name, raw in sources}
            for src in v2.glob("*.json"):
                by_name[src.name] = src.read_bytes()
            sources = list(by_name.items())

    for name, raw in sources:
        m = pattern.match(name)
        if not m:
            continue
        lang = m.group("lang")
        course_id = m.group("id")
        if lang not in counts:
            continue
        dest = ANDROID_COURSES_V2 / lang / f"{course_id}.json"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(raw)
        counts[lang] += 1
    return counts


def export_ui_strings(ref: str | None) -> list[str]:
    """Build strings/{lang}.json for NEW_LANGS from content ui_strings + overrides + EN fallback."""
    ANDROID_STRINGS.mkdir(parents=True, exist_ok=True)
    written: list[str] = []

    en_path = ANDROID_STRINGS / "en.json"
    if not en_path.is_file():
        print("  WARNING: android en.json missing — skipping UI string export")
        return written
    en = json.loads(en_path.read_text(encoding="utf-8"))

    overrides_raw = resolve_file(
        OVERRIDES_PATH,
        ref,
        "scripts/ui_string_overrides.json",
    )
    overrides_root = json.loads(overrides_raw.decode("utf-8")) if overrides_raw else {}

    for lang in NEW_LANGS:
        ui_raw = resolve_file(
            CONTENT_LOCALES / lang / "ui_strings.json",
            ref,
            f"content/locales/{lang}/ui_strings.json",
        )
        if ui_raw is None:
            print(f"  WARNING: no ui_strings for {lang}")
            continue
        ui = json.loads(ui_raw.decode("utf-8"))
        merged = dict(en)
        merged.update(ui)
        lang_overrides = overrides_root.get(lang) or {}
        merged.update(lang_overrides)
        out = ANDROID_STRINGS / f"{lang}.json"
        write_json(out, merged)
        written.append(out.name)
        print(f"  strings/{lang}.json — {len(merged)} keys")
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--from-ref",
        default=None,
        help="Git ref to pull missing iOS/content assets from (e.g. origin/main)",
    )
    parser.add_argument(
        "--skip-courses-v2",
        action="store_true",
        help="Skip CoursesV2 copy (faster iteration)",
    )
    args = parser.parse_args()
    ref = args.from_ref

    print("=== Sophia iOS → Android content export ===")
    if ref:
        print(f"fallback ref: {ref}")

    print("Copying locale catalog JSON…")
    copied = copy_locale_json(ref)
    print(f"  wrote {len(copied)} locale files")

    print("Slimming course catalogs (drop lesson bodies, write course_index)…")
    sys.path.insert(0, str(ROOT / "scripts"))
    from slim_android_catalog import slim_locale_catalogs
    slim_locale_catalogs()

    print("Exporting UI strings for new languages…")
    strings = export_ui_strings(ref)
    print(f"  wrote {len(strings)} string packs")

    v2_counts: dict[str, int] = {}
    if not args.skip_courses_v2:
        print("Exporting CoursesV2…")
        v2_counts = export_courses_v2(ref)
        for lang, n in v2_counts.items():
            if n:
                print(f"  courses_v2/{lang}: {n}")

        # The inline `image` slugs come from the freshly exported courses_v2, so the
        # slug → Storage object map has to be rebuilt with them.
        from build_block_image_map import build_block_image_map
        resolved, unresolved = build_block_image_map()
        print(f"  course_block_images.json: {len(resolved)} slugs")
        if unresolved:
            print(f"  unresolved image slugs: {unresolved}")
    else:
        print("Skipping CoursesV2 (--skip-courses-v2)")

    print()
    print("=== Summary ===")
    print(f"locale JSON files: {len(copied)}")
    print(f"new string packs: {len(strings)}")
    if v2_counts:
        missing_v2 = [lang for lang in ALL_LANGS if v2_counts.get(lang, 0) < 200]
        print(f"courses_v2 langs OK: {sum(1 for n in v2_counts.values() if n >= 200)}/15")
        if missing_v2:
            print(f"courses_v2 thin/missing: {missing_v2}")
            # Not fatal if only FR missing from archive naming — check fr separately.
            critical = [l for l in NEW_LANGS if v2_counts.get(l, 0) < 200]
            if critical:
                print(f"ERROR: new langs missing CoursesV2: {critical}")
                return 1
    missing_locales = []
    for lang in NEW_LANGS:
        for kind in ("courses", "course_index", "collections", "glossary"):
            if not (ANDROID_LOCALES / f"{kind}.{lang}.json").is_file():
                missing_locales.append(f"{kind}.{lang}.json")
    if missing_locales:
        print(f"ERROR: missing locale files: {missing_locales[:12]}…")
        return 1
    for lang in NEW_LANGS:
        if not (ANDROID_STRINGS / f"{lang}.json").is_file():
            print(f"ERROR: missing strings/{lang}.json")
            return 1
    print("errors: none")
    return 0


if __name__ == "__main__":
    sys.exit(main())
