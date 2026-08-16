#!/usr/bin/env python3
"""Resolve inline course-image slugs to their real Supabase Storage filenames.

The `image` blocks in `content/courses` / `courses_v2` reference slugs that do not
always match the JPEG names in `ios/Sophia/CourseImages` (accents encoded as
`_u0301`, abbreviations, casing). iOS resolves this at runtime via
`CourseImageAliases` plus a case-insensitive lookup; Android has no equivalent, so
we resolve it once here and ship the result as a flat asset map.

Writes `android/app/src/main/assets/course_block_images.json`:

    {"<slug referenced by the content>": "<object name in the bucket>", ...}

Every referenced slug that cannot be resolved is reported; those simply render as
a placeholder in the reader.

    python3 scripts/build_block_image_map.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "ios" / "Sophia" / "CourseImages"
ALIASES = ROOT / "ios" / "Sophia" / "Utilities" / "CourseImageAliases.swift"
COURSES_V2 = ROOT / "android" / "app" / "src" / "main" / "assets" / "courses_v2"
OUT = ROOT / "android" / "app" / "src" / "main" / "assets" / "course_block_images.json"


def available_objects() -> set[str]:
    names = {path.stem for path in IMAGES.glob("*.jpg")}
    if not names:
        sys.exit(f"no JPEGs in {IMAGES}")
    return names


def swift_aliases() -> dict[str, str]:
    if not ALIASES.exists():
        return {}
    return dict(re.findall(r'"([^"]+)":\s*"([^"]+)"', ALIASES.read_text()))


def referenced_assets() -> set[str]:
    assets: set[str] = set()
    for path in COURSES_V2.glob("*/*.json"):
        course = json.loads(path.read_text())
        for section in course.get("sections", []):
            for block in section.get("blocks", []):
                if block.get("type") == "image" and block.get("asset"):
                    assets.add(block["asset"])
    if not assets:
        sys.exit(f"no image blocks found under {COURSES_V2}")
    return assets


def build_block_image_map() -> tuple[dict[str, str], list[str]]:
    """Write the asset map; returns (resolved, unresolved slugs)."""
    objects = available_objects()
    lowered = {name.lower(): name for name in objects}
    aliases = swift_aliases()

    def resolve(slug: str) -> str | None:
        for candidate in (slug, aliases.get(slug)):
            if candidate is None:
                continue
            if candidate in objects:
                return candidate
            match = lowered.get(candidate.lower())
            if match:
                return match
        return None

    resolved: dict[str, str] = {}
    unresolved: list[str] = []
    for slug in sorted(referenced_assets()):
        target = resolve(slug)
        if target is None:
            unresolved.append(slug)
        else:
            resolved[slug] = target

    OUT.write_text(json.dumps(resolved, ensure_ascii=False, indent=1, sort_keys=True) + "\n")
    return resolved, unresolved


def main() -> int:
    resolved, unresolved = build_block_image_map()
    print(f"resolved          : {len(resolved)}")
    print(f"identity mappings : {sum(1 for k, v in resolved.items() if k == v)}")
    print(f"wrote {OUT.relative_to(ROOT)}")
    if unresolved:
        print(f"unresolved ({len(unresolved)}) — these render as a placeholder:")
        for slug in unresolved:
            print(f"  {slug}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
