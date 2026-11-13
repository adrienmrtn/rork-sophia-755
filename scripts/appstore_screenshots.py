#!/usr/bin/env python3
"""Upload the App Store screenshots in appstore/screenshots/ to App Store Connect.

    python3 scripts/appstore_screenshots.py check                    # no network, no account
    python3 scripts/appstore_screenshots.py push --version 1.12 --dry-run
    python3 scripts/appstore_screenshots.py push --version 1.12

For each store locale in SETS, each device slot is REPLACED by the PNGs of one folder, in file
name order: the screenshots already in that slot are deleted first. Locales and slots not
listed are left alone. Like release notes, it only writes to the version being prepared, and
only when that version is the one named.

The product page header is not handled: it goes through the Asset Library in App Store
Connect (appstore/screenshots/header/ holds the files).

Credentials: ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY, as for appstore_metadata.py.
"""
from __future__ import annotations

import argparse
import hashlib
import struct
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from appstore_metadata import BUNDLE_ID, ROOT, ApiError, Client, find_app, find_version  # noqa: E402

SHOTS = ROOT / "appstore" / "screenshots"

# Display type in the App Store Connect API -> (folder prefix, accepted pixel size).
# APP_IPHONE_67 is the 6.9" / 6.7" slot, APP_IPAD_PRO_3GEN_129 the 13" / 12.9" one.
SLOTS = {
    "APP_IPHONE_67": ("iphone-6.9-showcase-bold", (1320, 2868)),
    "APP_IPAD_PRO_3GEN_129": ("ipad-13-showcase-bold", (2064, 2752)),
}
# Store locale -> folder of appstore/screenshots/ that holds its set. The English regional
# pages take the en-US set, as their metadata does.
SETS = {
    "en-US": "en-US", "en-GB": "en-US", "en-AU": "en-US", "en-CA": "en-US",
    "fr-FR": "fr-FR",
}
MAX_PER_SLOT = 10


def png_size(path: Path) -> tuple[int, int]:
    head = path.read_bytes()[:24]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", head[16:24])


def files_for(locale: str, slot: str) -> list[Path]:
    return sorted((SHOTS / SETS[locale] / SLOTS[slot][0]).glob("*.png"))


def check(locales: list[str]) -> int:
    problems = 0
    for locale in locales:
        for slot, (folder, size) in SLOTS.items():
            files = files_for(locale, slot)
            line = f"{locale:6} {slot:22} {len(files)} file(s) from {SETS[locale]}/{folder}"
            if not files:
                print(f"  ! {line}: nothing to upload"); problems += 1; continue
            if len(files) > MAX_PER_SLOT:
                print(f"  ! {line}: more than {MAX_PER_SLOT}"); problems += 1; continue
            wrong = [f.name for f in files if png_size(f) != size]
            if wrong:
                print(f"  ! {line}: not {size[0]} x {size[1]}: {', '.join(wrong)}"); problems += 1
            else:
                print(f"  ok {line}")
    return 1 if problems else 0


def upload(client: Client, set_id: str, path: Path) -> None:
    data = path.read_bytes()
    created = client.call("POST", "/appScreenshots", body={"data": {
        "type": "appScreenshots",
        "attributes": {"fileName": path.name, "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
    }})["data"]
    for op in created["attributes"]["uploadOperations"]:
        request = urllib.request.Request(
            op["url"], data=data[op["offset"]: op["offset"] + op["length"]], method=op["method"],
            headers={h["name"]: h["value"] for h in op.get("requestHeaders") or []},
        )
        with urllib.request.urlopen(request, timeout=300) as response:
            response.read()
    client.call("PATCH", f"/appScreenshots/{created['id']}", body={"data": {
        "type": "appScreenshots", "id": created["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()},
    }})


def push(client: Client, locales: list[str], expect: str, dry_run: bool) -> int:
    if check(locales) != 0:
        print("\nRefusing to push while check fails.", file=sys.stderr)
        return 1
    app_id = find_app(client, BUNDLE_ID)
    version_id, state = find_version(client, app_id, expect)
    print(f"\napp {app_id}, version {expect} ({state}){' -- dry run, nothing written' if dry_run else ''}\n")
    on_version = {
        record["attributes"]["locale"]: record["id"]
        for record in client.get_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    }
    failures = 0
    for locale in locales:
        loc_id = on_version.get(locale)
        if loc_id is None:
            print(f"  ? {locale}  not on this version, left alone")
            continue
        sets = {
            record["attributes"]["screenshotDisplayType"]: record["id"]
            for record in client.get_all(f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
        }
        for slot in SLOTS:
            files = files_for(locale, slot)
            set_id = sets.get(slot)
            old = client.get_all(f"/appScreenshotSets/{set_id}/appScreenshots") if set_id else []
            print(f"  {locale} {slot}: replace {len(old)} screenshot(s) with {len(files)}")
            if dry_run:
                continue
            try:
                if set_id is None:
                    set_id = client.call("POST", "/appScreenshotSets", body={"data": {
                        "type": "appScreenshotSets",
                        "attributes": {"screenshotDisplayType": slot},
                        "relationships": {"appStoreVersionLocalization": {
                            "data": {"type": "appStoreVersionLocalizations", "id": loc_id}}},
                    }})["data"]["id"]
                for record in old:
                    client.call("DELETE", f"/appScreenshots/{record['id']}")
                for path in files:
                    upload(client, set_id, path)
                    print(f"      + {path.name}")
            except (ApiError, urllib.error.URLError) as error:
                failures += 1
                print(f"      ! {error}", file=sys.stderr)
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("check", "push"):
        p = sub.add_parser(name)
        p.add_argument("--locale", action="append", help="only this store locale (repeatable)")
        if name == "push":
            p.add_argument("--version", required=True, help="the version being prepared, e.g. 1.12")
            p.add_argument("--dry-run", action="store_true", help="report, write nothing")
    args = parser.parse_args()
    if unknown := [loc for loc in args.locale or [] if loc not in SETS]:
        sys.exit(f"No screenshot set for: {', '.join(unknown)} (known: {', '.join(SETS)})")
    locales = args.locale or list(SETS)
    if args.command == "check":
        return check(locales)
    return push(Client(), locales, args.version, args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
