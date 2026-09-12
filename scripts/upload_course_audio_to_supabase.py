#!/usr/bin/env python3
"""Upload course narration MP3s to the public Supabase Storage bucket `course-audio`.

Requires a secret key (service_role), not the publishable/anon key:

  export SUPABASE_URL=https://afnmcoovdvbtkgohtdij.supabase.co
  export SUPABASE_SERVICE_ROLE_KEY=eyJ...   # Project Settings → API → service_role
  python3 scripts/upload_course_audio_to_supabase.py audio_fr/ --language fr

Expects one MP3 per course, named after the course id, with or without a
trailing language suffix:

  audio_fr/course_5_la_magna_carta_1215.mp3
  audio_fr/course_5_la_magna_carta_1215_fr.mp3

Objects land at `<language>/<course_id>.mp3`, which is the path
`CourseAudioCatalog.swift` builds on the client. Course ids are checked against
content/courses/<language>/ and a mismatch stops the run: a typo here surfaces
in the app as a silent 404 on a course that looks perfectly normal.
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


def request(method: str, url: str, key: str, data: bytes | None = None, content_type: str | None = None) -> tuple[int, bytes]:
    headers = {
        "Authorization": f"Bearer {key}",
        "apikey": key,
    }
    if content_type:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read()


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
        "allowed_mime_types": ["audio/mpeg"],
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


def list_language(base: str, key: str, language: str) -> list[str]:
    """Course ids that actually have an object under `<language>/`."""
    payload = json.dumps({
        "prefix": f"{language}/",
        "limit": 1000,
        "sortBy": {"column": "name", "order": "asc"},
    }).encode()
    code, body = request("POST", f"{base}/storage/v1/object/list/{BUCKET}", key, payload, "application/json")
    if code != 200:
        sys.exit(f"could not list `{language}/`: HTTP {code} {body.decode(errors='replace')}")
    return sorted(
        entry["name"][:-4]
        for entry in json.loads(body)
        if entry.get("name", "").endswith(".mp3")
    )


def bucket_languages(base: str, key: str) -> set[str]:
    """Language folders already present at the bucket root.

    Supabase reports a folder as an entry whose `id` is null.
    """
    payload = json.dumps({"prefix": "", "limit": 1000}).encode()
    code, body = request("POST", f"{base}/storage/v1/object/list/{BUCKET}", key, payload, "application/json")
    if code != 200:
        return set()
    return {
        entry["name"]
        for entry in json.loads(body)
        if entry.get("id") is None and not entry.get("name", "").endswith(".json")
    }


def write_manifest(base: str, key: str, languages: list[str]) -> None:
    """Rewrite `manifest.json` from what the bucket really holds.

    The app reads this instead of a hardcoded list, so adding a course or a
    language never needs an App Store release. Built from a bucket listing
    rather than from the files just uploaded, so a half-finished earlier run
    cannot leave the manifest claiming audio that is not there.
    """
    manifest = {lang: list_language(base, key, lang) for lang in languages}
    body = json.dumps(manifest, ensure_ascii=False, indent=2).encode()
    url = f"{base}/storage/v1/object/{BUCKET}/manifest.json?upsert=true"
    code, resp = request("POST", url, key, body, "application/json")
    if code not in (200, 201):
        sys.exit(f"could not write manifest: HTTP {code} {resp.decode(errors='replace')}")
    for lang, ids in manifest.items():
        print(f"manifest: {lang} → {len(ids)} course(s)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("folder", help="directory holding <course_id>.mp3 files")
    ap.add_argument("--language", default="fr", help="language code (default: fr)")
    ap.add_argument("--dry-run", action="store_true", help="validate names and sizes, upload nothing")
    args = ap.parse_args()

    folder = Path(args.folder)
    files = sorted(folder.glob("*.mp3"))
    if not files:
        sys.exit(f"no MP3s in {folder}")

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

    ok = 0
    failed: list[str] = []
    for i, path in enumerate(files, 1):
        code = upload_one(base, key, path, args.language)
        if code in (200, 201):
            ok += 1
        else:
            failed.append(f"{path.name} HTTP {code}")
        print(f"  {i}/{len(files)} ({ok} ok)")

    if failed:
        print("failures:")
        for line in failed:
            print(f"  {line}")
        print("manifest not rewritten: it would advertise audio that failed to upload")
        return 1

    write_manifest(base, key, sorted(bucket_languages(base, key) | {args.language}))
    print("errors: none")
    print(f"sample: {base}/storage/v1/object/public/{BUCKET}/{args.language}/{course_id_for(files[0], args.language)}.mp3")
    return 0


if __name__ == "__main__":
    sys.exit(main())
