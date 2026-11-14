#!/usr/bin/env python3
"""Upload the Google Play screenshots rendered in appstore/screenshots/.

    node appstore/screenshots/render-store.cjs --android     # draws <locale>/play-phone, play-tablet
    python3 scripts/play_screenshots.py check                 # no network, no account
    python3 scripts/play_screenshots.py push --dry-run        # reads the listing, writes nothing
    python3 scripts/play_screenshots.py push

For every language the Play listing already has, the phone, 7-inch tablet and 10-inch tablet
screenshots are REPLACED by the rendered set (the two tablet slots take the same images).
Languages without a store listing are reported and skipped: this never creates a listing.
Everything happens in one edit, committed at the end, so a failure leaves the listing untouched.

Credentials: PLAY_SERVICE_ACCOUNT_JSON (the service account key, as for play_pricing.py).
"""
from __future__ import annotations

import argparse
import json
import os
import struct
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from play_pricing import API, PlayError, access_token, play_call  # noqa: E402

SHOTS = Path(__file__).resolve().parents[1] / "appstore" / "screenshots"
UPLOAD = API.replace("/androidpublisher/v3/", "/upload/androidpublisher/v3/")

# App Store locale (the folder name) -> Google Play language code.
PLAY_LANG = {
    "en-US": "en-US", "en-GB": "en-GB", "en-AU": "en-AU", "en-CA": "en-CA", "fr-FR": "fr-FR",
    "ar-SA": "ar", "cs": "cs-CZ", "da": "da-DK", "de-DE": "de-DE", "el": "el-GR", "es-ES": "es-ES",
    "es-MX": "es-419", "fi": "fi-FI", "he": "iw-IL", "hr": "hr", "hu": "hu-HU", "it": "it-IT",
    "ja": "ja-JP", "nl-NL": "nl-NL", "no": "no-NO", "pl": "pl-PL", "pt-BR": "pt-BR",
    "pt-PT": "pt-PT", "ro": "ro", "ru": "ru-RU", "sk": "sk", "sl-SI": "sl", "sv": "sv-SE",
    "tr": "tr-TR",
}
# Play image type -> (rendered folder, pixel size).
SLOTS = {
    "phoneScreenshots": ("play-phone", (1320, 2346)),
    "sevenInchScreenshots": ("play-tablet", (2064, 2752)),
    "tenInchScreenshots": ("play-tablet", (2064, 2752)),
}
MAX_PER_SLOT = 8


def png_size(path: Path) -> tuple[int, int]:
    head = path.read_bytes()[:24]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", head[16:24])


def rendered() -> list[str]:
    return [loc for loc in PLAY_LANG if (SHOTS / loc / "play-phone").is_dir()]


def files_for(locale: str, slot: str) -> list[Path]:
    return sorted((SHOTS / locale / SLOTS[slot][0]).glob("*.png"))


def check(locales: list[str]) -> int:
    problems = 0
    for locale in locales:
        for slot, (folder, size) in SLOTS.items():
            files = files_for(locale, slot)
            line = f"{PLAY_LANG[locale]:7} {slot:21} {len(files)} file(s) from {locale}/{folder}"
            bad = [f.name for f in files if png_size(f) != size]
            # Play: each side 320 to 3840 px, the long side at most twice the short one.
            if not files or len(files) > MAX_PER_SLOT or bad or size[1] > 2 * size[0]:
                print(f"  ! {line}" + (f": wrong size {', '.join(bad)}" if bad else ": count or ratio"))
                problems += 1
            else:
                print(f"  ok {line}")
    return 1 if problems else 0


def upload(token: str, edit: str, lang: str, slot: str, path: Path) -> None:
    request = urllib.request.Request(
        f"{UPLOAD}/edits/{edit}/listings/{lang}/{slot}?uploadType=media",
        data=path.read_bytes(), method="POST",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "image/png"},
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            response.read()
    except urllib.error.HTTPError as error:
        raise PlayError(f"upload {path.name} -> {error.code}: {error.read().decode()[:600]}") from error


def push(locales: list[str], dry_run: bool) -> int:
    if check(locales) != 0:
        print("\nRefusing to push while check fails.", file=sys.stderr)
        return 1
    key = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON", "").strip()
    if not key:
        sys.exit("Missing PLAY_SERVICE_ACCOUNT_JSON.")
    token = access_token(key)
    edit = play_call(token, "POST", f"{API}/edits", {})["id"]
    try:
        listed = {item["language"] for item in play_call(token, "GET", f"{API}/edits/{edit}/listings").get("listings") or []}
        print(f"\nlisting languages on Play: {', '.join(sorted(listed)) or 'none'}"
              f"{' -- dry run, nothing written' if dry_run else ''}\n")
        done = 0
        for locale in locales:
            lang = PLAY_LANG[locale]
            if lang not in listed:
                print(f"  ? {lang}  no store listing in this language, left alone")
                continue
            for slot in SLOTS:
                files = files_for(locale, slot)
                old = play_call(token, "GET", f"{API}/edits/{edit}/listings/{lang}/{slot}").get("images") or []
                print(f"  {lang} {slot}: replace {len(old)} with {len(files)}")
                if dry_run:
                    continue
                play_call(token, "DELETE", f"{API}/edits/{edit}/listings/{lang}/{slot}")
                for path in files:
                    upload(token, edit, lang, slot, path)
            done += 1
        if dry_run or not done:
            play_call(token, "DELETE", f"{API}/edits/{edit}")
            return 0
        play_call(token, "POST", f"{API}/edits/{edit}:commit")
        print(f"\ncommitted: {done} language(s)")
        return 0
    except PlayError as error:
        print(f"\n! {error}\nNothing was committed.", file=sys.stderr)
        try:
            play_call(token, "DELETE", f"{API}/edits/{edit}")
        except PlayError:
            pass
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("check", "push"):
        p = sub.add_parser(name)
        p.add_argument("--locale", action="append", help="only this App Store locale folder, e.g. fr-FR (repeatable)")
        if name == "push":
            p.add_argument("--dry-run", action="store_true", help="report, write nothing")
    args = parser.parse_args()
    available = rendered()
    if not available:
        sys.exit("Nothing rendered. Run: node appstore/screenshots/render-store.cjs --android")
    if unknown := [loc for loc in args.locale or [] if loc not in available]:
        sys.exit(f"Not rendered: {', '.join(unknown)}")
    locales = args.locale or available
    return check(locales) if args.command == "check" else push(locales, args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
