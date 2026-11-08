#!/usr/bin/env python3
"""Un client Supabase minimal (PostgREST, RPC, Storage) sur urllib, sans dépendance.

Utilisé par l'usine (scripts/produce_course.py) depuis GitHub Actions avec la clé service_role :

    from supabase_rest import Supabase, env_key
    sb = Supabase(os.environ.get("SUPABASE_URL", DEFAULT_URL), env_key())
    sb.select("production_jobs", "id=eq.…&select=*")
    sb.rpc("catalog_upsert_course", {...})
    sb.upload("course-images", "slug.jpg", data, "image/jpeg")

Les erreurs HTTP remontent en SupabaseError avec le début du corps de réponse ; les 429 et 5xx
sont réessayés avec une attente croissante.
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

DEFAULT_URL = "https://afnmcoovdvbtkgohtdij.supabase.co"


class SupabaseError(RuntimeError):
    def __init__(self, status: int, body: bytes, what: str):
        self.status = status
        self.body = body
        super().__init__(f"{what} : HTTP {status} {body[:400]!r}")


def env_key() -> str:
    for name in ("SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_KEY"):
        value = os.environ.get(name, "").strip()
        if value:
            return value
    sys.exit(
        "SUPABASE_SERVICE_ROLE_KEY manquante (Project Settings → API Keys → service_role).\n"
        "La clé publishable ne peut ni écrire les tables ni téléverser dans Storage."
    )


class Supabase:
    def __init__(self, url: str, key: str):
        self.url = url.rstrip("/")
        self.key = key

    # ----- bas niveau
    def request(self, method: str, path: str, data: bytes | None = None, headers: dict | None = None,
                retries: int = 4, timeout: int = 120) -> tuple[int, bytes]:
        merged = {"Authorization": f"Bearer {self.key}", "apikey": self.key}
        if headers:
            merged.update(headers)
        delay = 1.0
        for attempt in range(retries + 1):
            req = urllib.request.Request(self.url + path, data=data, method=method, headers=merged)
            try:
                with urllib.request.urlopen(req, timeout=timeout) as resp:
                    return resp.status, resp.read()
            except urllib.error.HTTPError as e:
                body = e.read()
                if e.code in (429, 500, 502, 503, 504) and attempt < retries:
                    time.sleep(delay)
                    delay *= 2
                    continue
                return e.code, body
            except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
                if attempt < retries:
                    time.sleep(delay)
                    delay *= 2
                    continue
                raise SupabaseError(0, str(e).encode(), f"réseau {method} {path}")
        raise SupabaseError(0, b"", f"inatteignable {method} {path}")

    def _json(self, method: str, path: str, payload=None, headers: dict | None = None, what: str = ""):
        data = None
        merged = {"Accept": "application/json"}
        if payload is not None:
            data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            merged["Content-Type"] = "application/json"
        if headers:
            merged.update(headers)
        status, body = self.request(method, path, data=data, headers=merged)
        if status not in (200, 201, 204):
            raise SupabaseError(status, body, what or f"{method} {path}")
        if not body:
            return None
        try:
            return json.loads(body)
        except ValueError:
            return body.decode("utf-8", "replace")

    # ----- PostgREST
    def select(self, table: str, query: str) -> list[dict]:
        rows: list[dict] = []
        offset, page = 0, 1000
        while True:
            chunk = self._json("GET", f"/rest/v1/{table}?{query}&limit={page}&offset={offset}", what=f"select {table}")
            rows.extend(chunk or [])
            if not chunk or len(chunk) < page:
                return rows
            offset += page

    def insert(self, table: str, rows: list[dict]) -> list[dict]:
        return self._json("POST", f"/rest/v1/{table}", rows,
                          headers={"Prefer": "return=representation"}, what=f"insert {table}") or []

    def upsert(self, table: str, rows: list[dict], on_conflict: str) -> None:
        self._json("POST", f"/rest/v1/{table}?on_conflict={urllib.parse.quote(on_conflict)}", rows,
                   headers={"Prefer": "resolution=merge-duplicates,return=minimal"}, what=f"upsert {table}")

    def update(self, table: str, query: str, values: dict) -> list[dict]:
        return self._json("PATCH", f"/rest/v1/{table}?{query}", values,
                          headers={"Prefer": "return=representation"}, what=f"update {table}") or []

    def rpc(self, name: str, params: dict | None = None):
        return self._json("POST", f"/rest/v1/rpc/{name}", params or {}, what=f"rpc {name}")

    # ----- Storage
    def upload(self, bucket: str, path: str, data: bytes, content_type: str,
               cache_control: str = "public, max-age=86400") -> None:
        status, body = self.request(
            "POST", f"/storage/v1/object/{bucket}/{urllib.parse.quote(path)}", data=data,
            headers={"Content-Type": content_type, "x-upsert": "true", "cache-control": cache_control},
            timeout=300,
        )
        if status not in (200, 201):
            raise SupabaseError(status, body, f"upload {bucket}/{path}")

    def download_public(self, bucket: str, path: str) -> bytes | None:
        url = f"{self.url}/storage/v1/object/public/{bucket}/{urllib.parse.quote(path)}"
        req = urllib.request.Request(url, headers={"Cache-Control": "no-cache"})
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            if e.code in (400, 404):
                return None
            raise SupabaseError(e.code, e.read(), f"download {bucket}/{path}")

    def object_exists(self, bucket: str, path: str) -> bool:
        status, _ = self.request("HEAD", f"/storage/v1/object/{bucket}/{urllib.parse.quote(path)}", retries=1)
        return status == 200
