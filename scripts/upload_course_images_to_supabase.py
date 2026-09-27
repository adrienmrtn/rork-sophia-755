#!/usr/bin/env python3
"""Upload the course images to the public Supabase Storage bucket `course-images`.

Two folders feed the bucket, which both apps read:

  * ``ios/Sophia/CourseImages``  the covers (hero of each course), also bundled in the
    iOS app so the home and the intro page work offline;
  * ``content/images``           every other course image (inline illustrations and
    the pool not yet used), served only from the bucket on iOS and on Android.

Requires a secret key (service_role), not the publishable/anon key:

  export SUPABASE_URL=https://afnmcoovdvbtkgohtdij.supabase.co
  export SUPABASE_SERVICE_ROLE_KEY=eyJ...   # Project Settings → API → service_role
  python3 scripts/upload_course_images_to_supabase.py                # everything (upsert)
  python3 scripts/upload_course_images_to_supabase.py eiffel_* mercy_brown_*   # a few

Creates the bucket if missing, then upserts every *.jpg it finds.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMAGE_DIRS = (
    ROOT / "ios" / "Sophia" / "CourseImages",
    ROOT / "content" / "images",
)
BUCKET = "course-images"
DEFAULT_URL = "https://afnmcoovdvbtkgohtdij.supabase.co"


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
        # Storage reads the overwrite flag from this header, not from the query string:
        # without it, re-uploading an existing object fails with 400 (Duplicate).
        headers["x-upsert"] = "true"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read()


def ensure_bucket(base: str, key: str) -> None:
    code, body = request("GET", f"{base}/storage/v1/bucket/{BUCKET}", key)
    if code == 200:
        print(f"bucket `{BUCKET}` exists")
        return
    payload = json.dumps({
        "id": BUCKET,
        "name": BUCKET,
        "public": True,
        "file_size_limit": 2_000_000,
        "allowed_mime_types": ["image/jpeg"],
    }).encode()
    code, body = request("POST", f"{base}/storage/v1/bucket", key, payload, "application/json")
    if code not in (200, 201):
        sys.exit(f"could not create bucket `{BUCKET}`: HTTP {code} {body.decode(errors='replace')}")
    print(f"created public bucket `{BUCKET}`")


def upload_one(base: str, key: str, path: Path) -> int:
    url = f"{base}/storage/v1/object/{BUCKET}/{path.name}?upsert=true"
    return request("POST", url, key, path.read_bytes(), "image/jpeg")[0]


def main() -> int:
    import fnmatch

    base = os.environ.get("SUPABASE_URL", DEFAULT_URL).rstrip("/")
    key = env_key()
    patterns = sys.argv[1:]
    files = sorted(path for folder in IMAGE_DIRS for path in folder.glob("*.jpg"))
    if patterns:
        files = [f for f in files if any(fnmatch.fnmatch(f.stem, p) for p in patterns)]
    if not files:
        sys.exit(f"no JPEGs matching in {', '.join(str(d) for d in IMAGE_DIRS)}")
    print(f"=== Upload {len(files)} covers → {base}/storage/v1/object/public/{BUCKET}/ ===")
    ensure_bucket(base, key)
    ok = 0
    failed: list[str] = []
    for i, path in enumerate(files, 1):
        code = upload_one(base, key, path)
        if code in (200, 201):
            ok += 1
        else:
            failed.append(f"{path.name} HTTP {code}")
        if i % 50 == 0 or i == len(files):
            print(f"  {i}/{len(files)} ({ok} ok)")
    if failed:
        print("failures:")
        for line in failed[:20]:
            print(f"  {line}")
        if len(failed) > 20:
            print(f"  … {len(failed) - 20} more")
        return 1
    sample = files[0].name
    print(f"errors: none")
    print(f"sample: {base}/storage/v1/object/public/{BUCKET}/{sample}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
