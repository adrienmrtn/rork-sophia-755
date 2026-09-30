#!/usr/bin/env python3
"""Upload course narration MP3s to the public Supabase Storage bucket `course-audio`.

Requires a secret key (service_role), not the publishable/anon key:

  export SUPABASE_URL=https://afnmcoovdvbtkgohtdij.supabase.co
  export SUPABASE_SERVICE_ROLE_KEY=eyJ...   # Project Settings → API Keys → secret / service_role
  python3 scripts/upload_course_audio_to_supabase.py audio_fr/ --language fr
  python3 scripts/upload_course_audio_to_supabase.py audio_en/ --language en

Expects one MP3 per course, named after the course id, with or without a
trailing language suffix:

  audio_fr/course_5_la_magna_carta_1215.mp3
  audio_fr/course_5_la_magna_carta_1215_fr.mp3

Objects land at `<language>/<course_id>.mp3`, which is the path
`CourseAudioCatalog.swift` builds on the client. Course ids are checked against
content/courses/<language>/ and a mismatch stops the run: a typo here surfaces
in the app as a silent 404 on a course that looks perfectly normal.

Narrations exist in French and English only. A narration already in the bucket
with the same size is skipped, so an interrupted run is resumed by running the
same command again (`--force` re-uploads everything).
`--purge-other-languages` deletes what an earlier setup left under es/, de/, tr/.
"""

from __future__ import annotations

import argparse
import functools
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUCKET = "course-audio"
DEFAULT_URL = "https://afnmcoovdvbtkgohtdij.supabase.co"
MAX_BYTES = 50 * 1024 * 1024
# The app's `AudioLanguage` (iOS and Android). The manifest lists these and nothing else.
LANGUAGES = ("fr", "en")


def env_key() -> str:
    for name in (
        "SUPABASE_SERVICE_ROLE_KEY",
        "SUPABASE_SECRET_KEY",
        "SUPABASE_SERVICE_KEY",
    ):
        value = os.environ.get(name, "").strip()
        if value:
            return value
    sys.exit(
        "Missing SUPABASE_SERVICE_ROLE_KEY (Project Settings → API → service_role).\n"
        "The publishable/anon key cannot create buckets or upload objects."
    )


def request(
    method: str,
    url: str,
    key: str,
    data: bytes | None = None,
    content_type: str | None = None,
    cache_control: str | None = None,
) -> tuple[int, bytes]:
    headers = {
        "Authorization": f"Bearer {key}",
        "apikey": key,
        # Storage ignores `?upsert=true` on a POST: without this header, re-uploading an
        # object that already exists (manifest.json every run, a corrected MP3) fails
        # with 400 "Duplicate".
        "x-upsert": "true",
    }
    if content_type:
        headers["Content-Type"] = content_type
    if cache_control:
        headers["cache-control"] = cache_control
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read()
    except OSError as exc:
        # Wi-Fi drop, timeout, reset: reported like an HTTP failure (code 0) so one file
        # does not end a run of three hundred.
        return 0, str(exc).encode()


def ensure_bucket(base: str, key: str) -> None:
    code, _ = request("GET", f"{base}/storage/v1/bucket/{BUCKET}", key)
    if code == 200:
        print(f"bucket `{BUCKET}` exists")
        return
    payload = json.dumps({
        "id": BUCKET,
        "name": BUCKET,
        "public": True,
        "file_size_limit": MAX_BYTES,
        # manifest.json goes in the same bucket, so JSON must be allowed
        "allowed_mime_types": ["audio/mpeg", "application/json"],
    }).encode()
    code, body = request("POST", f"{base}/storage/v1/bucket", key, payload, "application/json")
    if code not in (200, 201):
        sys.exit(f"could not create bucket `{BUCKET}`: HTTP {code} {body.decode(errors='replace')}")
    print(f"created public bucket `{BUCKET}`")


def course_id_for(path: Path, language: str) -> str:
    """Course id a file is meant for.

    Narrations come named `<course_id>_<language>.mp3`. The suffix is stripped
    only when the bare stem is not itself a course id: ids end in a number, but
    nothing guarantees one will never end in `_fr`.
    """
    stem = path.stem
    suffix = f"_{language}"
    if stem.endswith(suffix) and stem not in known_course_ids(language):
        return stem[: -len(suffix)]
    return stem


@functools.lru_cache(maxsize=None)
def known_course_ids(language: str) -> frozenset[str]:
    folder = ROOT / "content" / "courses" / language
    if not folder.is_dir():
        sys.exit(f"no course content for language `{language}` ({folder})")
    return frozenset(json.loads(p.read_text(encoding="utf-8"))["id"] for p in folder.glob("*.json"))


def upload_one(base: str, key: str, path: Path, language: str) -> int:
    url = f"{base}/storage/v1/object/{BUCKET}/{language}/{course_id_for(path, language)}.mp3?upsert=true"
    return request("POST", url, key, path.read_bytes(), "audio/mpeg")[0]


def list_folder(base: str, key: str, prefix: str) -> list[dict]:
    """Every entry directly under `prefix`, page by page."""
    entries: list[dict] = []
    while True:
        payload = json.dumps({
            "prefix": prefix,
            "limit": 1000,
            "offset": len(entries),
            "sortBy": {"column": "name", "order": "asc"},
        }).encode()
        code, body = request("POST", f"{base}/storage/v1/object/list/{BUCKET}", key, payload, "application/json")
        if code != 200:
            sys.exit(f"could not list `{prefix or '/'}`: HTTP {code} {body.decode(errors='replace')}")
        page = json.loads(body)
        entries.extend(page)
        if len(page) < 1000:
            return entries


def list_language(base: str, key: str, language: str) -> dict[str, int]:
    """Size in bytes of each narration under `<language>/`, by course id."""
    return {
        entry["name"][:-4]: int((entry.get("metadata") or {}).get("size") or 0)
        for entry in list_folder(base, key, f"{language}/")
        if entry.get("name", "").endswith(".mp3")
    }


def purge_other_languages(base: str, key: str) -> None:
    """Delete every folder at the bucket root that is not a narrated language.

    Supabase reports a folder as an entry whose `id` is null. Objects go in
    batches: one request per object would take minutes on a full language.
    """
    folders = sorted(
        entry["name"]
        for entry in list_folder(base, key, "")
        if entry.get("id") is None and entry["name"] not in LANGUAGES
    )
    if not folders:
        print("purge: no other language in the bucket")
        return
    for folder in folders:
        paths = [f"{folder}/{entry['name']}" for entry in list_folder(base, key, f"{folder}/") if entry.get("id")]
        for start in range(0, len(paths), 100):
            batch = json.dumps({"prefixes": paths[start:start + 100]}).encode()
            code, body = request("DELETE", f"{base}/storage/v1/object/{BUCKET}", key, batch, "application/json")
            if code != 200:
                sys.exit(f"could not delete in `{folder}/`: HTTP {code} {body.decode(errors='replace')}")
        print(f"purge: {folder}/ → {len(paths)} file(s) deleted")


def write_manifest(base: str, key: str, languages: list[str]) -> None:
    """Rewrite `manifest.json` from what the bucket really holds.

    The app reads this instead of a hardcoded list, so adding a course or a
    language never needs an App Store release. Built from a bucket listing
    rather than from the files just uploaded, so a half-finished earlier run
    cannot leave the manifest claiming audio that is not there.
    """
    manifest = {lang: sorted(list_language(base, key, lang)) for lang in languages}
    body = json.dumps(manifest, ensure_ascii=False, indent=2).encode()
    url = f"{base}/storage/v1/object/{BUCKET}/manifest.json?upsert=true"
    # Short CDN lifetime: the default hour kept serving the previous manifest, so a new
    # narration stayed invisible in the app long after its upload.
    code, resp = request("POST", url, key, body, "application/json", cache_control="max-age=60")
    if code not in (200, 201):
        sys.exit(f"could not write manifest: HTTP {code} {resp.decode(errors='replace')}")
    for lang, ids in manifest.items():
        print(f"manifest: {lang} → {len(ids)} course(s)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("folder", nargs="?", help="directory holding <course_id>.mp3 files")
    ap.add_argument("--language", default="fr", choices=LANGUAGES, help="language code (default: fr)")
    ap.add_argument("--dry-run", action="store_true", help="validate names and sizes, upload nothing")
    ap.add_argument("--force", action="store_true",
                    help="re-upload narrations already in the bucket with the same size")
    ap.add_argument("--manifest-only", action="store_true",
                    help="rewrite manifest.json from the bucket, re-upload nothing")
    ap.add_argument("--purge-other-languages", action="store_true",
                    help="delete every folder but fr/ and en/ from the bucket, then rewrite the manifest")
    args = ap.parse_args()

    if args.manifest_only or args.purge_other_languages:
        base = os.environ.get("SUPABASE_URL", DEFAULT_URL).rstrip("/")
        key = env_key()
        ensure_bucket(base, key)
        if args.purge_other_languages:
            purge_other_languages(base, key)
        write_manifest(base, key, list(LANGUAGES))
        return 0

    if not args.folder:
        ap.error("folder is required (the directory holding the MP3s)")
    folder = Path(args.folder).expanduser()
    # Case-insensitive: some exports write `.MP3`, and the glob would silently skip them.
    files = sorted(p for p in folder.glob("*") if p.is_file() and p.suffix.lower() == ".mp3")
    if not files:
        sys.exit(f"no MP3s in {folder}")

    by_course: dict[str, list[str]] = {}
    for p in files:
        by_course.setdefault(course_id_for(p, args.language), []).append(p.name)
    duplicates = {cid: names for cid, names in by_course.items() if len(names) > 1}
    if duplicates:
        print("several files for the same course (only one would survive):")
        for names in duplicates.values():
            print(f"  {', '.join(names)}")
        return 1

    known = known_course_ids(args.language)
    unknown = [p.name for p in files if course_id_for(p, args.language) not in known]
    if unknown:
        print(f"{len(unknown)} file(s) do not match a course id in content/courses/{args.language}:")
        for name in unknown[:10]:
            print(f"  {name}")
        sys.exit("aborting: fix the names, or the app will 404 on these courses")

    oversized = [p.name for p in files if p.stat().st_size > MAX_BYTES]
    if oversized:
        print("over the 50 MB bucket limit:")
        for name in oversized:
            print(f"  {name}")
        return 1

    total = sum(p.stat().st_size for p in files)
    print(f"=== {len(files)} MP3s, {total / 1024 / 1024:.1f} MB → {BUCKET}/{args.language}/ ===")
    for p in files:
        print(f"  {course_id_for(p, args.language)}  ({p.stat().st_size / 1024 / 1024:.1f} MB)")
    if args.dry_run:
        print("dry run: nothing uploaded")
        return 0

    base = os.environ.get("SUPABASE_URL", DEFAULT_URL).rstrip("/")
    key = env_key()
    ensure_bucket(base, key)

    # Same size as what is already there: the same narration, from a previous run that was
    # interrupted. Skipping it makes a rerun of the same command pick up where it stopped.
    existing = {} if args.force else list_language(base, key, args.language)
    ok = 0
    skipped = 0
    failed: list[str] = []
    for i, path in enumerate(files, 1):
        size = path.stat().st_size
        if existing.get(course_id_for(path, args.language)) == size:
            skipped += 1
        else:
            code = upload_one(base, key, path, args.language)
            if code in (200, 201):
                ok += 1
            else:
                failed.append(f"{path.name} HTTP {code}")
        print(f"  {i}/{len(files)} ({ok} uploaded, {skipped} already there)")

    if failed:
        print("failures:")
        for line in failed:
            print(f"  {line}")
        print("manifest not rewritten: it would advertise audio that failed to upload")
        print("run the same command again: what already went up is skipped")
        return 1

    write_manifest(base, key, list(LANGUAGES))
    print("errors: none")
    print(f"sample: {base}/storage/v1/object/public/{BUCKET}/{args.language}/{course_id_for(files[0], args.language)}.mp3")
    return 0


if __name__ == "__main__":
    sys.exit(main())
