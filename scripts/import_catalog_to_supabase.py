#!/usr/bin/env python3
"""Importe le catalogue de cours (content/) dans Supabase et y publie les JSON que les apps
téléchargent. Idempotent : ce qui n'a pas changé (même hash) n'est ni réécrit ni retéléversé.

  export SUPABASE_URL=https://afnmcoovdvbtkgohtdij.supabase.co
  export SUPABASE_SERVICE_ROLE_KEY=eyJ...     # Project Settings → API Keys → service_role
  python3 scripts/import_catalog_to_supabase.py                 # tout : tables + Storage + packs
  python3 scripts/import_catalog_to_supabase.py --lang fr,en    # quelques langues
  python3 scripts/import_catalog_to_supabase.py --starter-pack-only   # ne touche pas à Supabase
  python3 scripts/import_catalog_to_supabase.py --verify        # compte ce qui est en base

Sources (toutes dans content/) :
  courses/<lang>/<courseId>.json          contenu V2 (format inchangé)
  locales/<lang>/quizzes_v2.json          questions par cours
  glossary/<lang>.json                    "<courseId>|<terme>" → {displayTerm, classification, explanation}
  collections/collections.json            ordre, couverture et cours de chaque collection
  collections/<lang>.json                 titre et description traduits
  authors.json                            créateurs (title et bio par langue)
  image_credits.json, course_image_map.json, catalog_withheld.json

Ce qui est écrit :
  tables creators, courses, course_contents, quizzes, glossary_entries, collections,
  collection_courses, collection_translations, course_assets, catalog_files ;
  bucket course-content : <lang>/catalog.<hash>.json, <lang>/quizzes.<hash>.json,
  <lang>/glossary.<hash>.json, <lang>/courses/<courseId>.<hash>.json (cache immuable) ;
  packs de départ embarqués : ios/Sophia/Resources/StarterPack/<lang>/ et
  android/app/src/main/assets/starter_pack/<lang>/ (catalogue complet + les 40 cours
  du début du Parcours, avec quiz et glossaire).

Le hash d'un paquet est les 16 premiers hexas du sha256 de son JSON canonique (clés triées,
séparateurs compacts) ; c'est lui qui nomme l'objet dans Storage, donc un cours modifié
change d'adresse et les caches des apps ne servent jamais une version périmée.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content"
sys.path.insert(0, str(ROOT / "scripts"))
from i18n_languages import SWIFT_CASE_BY_CODE  # noqa: E402

BUCKET = "course-content"
DEFAULT_URL = "https://afnmcoovdvbtkgohtdij.supabase.co"
# La clé publique des apps : Kong exige un en-tête apikey ; les droits viennent du Bearer.
PUBLISHABLE_KEY = "sb_publishable_eNzCyPFfEuKC0tKWr0Hjag_lJ_qsWRw"
STARTER_COUNT = 40
IOS_PACK = ROOT / "ios/Sophia/Resources/StarterPack"
ANDROID_PACK = ROOT / "android/app/src/main/assets/starter_pack"
EXPECTED_COURSES = 309


# ---------------------------------------------------------------- utilitaires

def canonical(obj) -> bytes:
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def digest(obj) -> str:
    return hashlib.sha256(canonical(obj)).hexdigest()[:16]


def load_json(path: Path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def env_key() -> str:
    for name in ("SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_KEY"):
        value = os.environ.get(name, "").strip()
        if value:
            return value
    # Dans une session Claude Code, un proxy peut injecter le Bearer : on envoie alors un
    # jeton factice que le proxy remplace. Hors de ce cas, l'appel échouera en 401 et le
    # message ci-dessous dira quoi faire.
    if os.environ.get("HTTPS_PROXY"):
        return "proxy-injected"
    sys.exit(
        "SUPABASE_SERVICE_ROLE_KEY manquante (Project Settings → API Keys → service_role).\n"
        "La clé publishable ne peut ni écrire les tables ni téléverser dans Storage."
    )


class Supabase:
    def __init__(self, url: str, key: str):
        self.url = url.rstrip("/")
        self.key = key

    def _headers(self, extra: dict | None = None) -> dict:
        headers = {
            "Authorization": f"Bearer {self.key}",
            "apikey": PUBLISHABLE_KEY if self.key == "proxy-injected" else self.key,
        }
        if extra:
            headers.update(extra)
        return headers

    def request(self, method: str, path: str, data: bytes | None = None, headers: dict | None = None,
                retries: int = 4) -> tuple[int, bytes]:
        req = urllib.request.Request(self.url + path, data=data, method=method, headers=self._headers(headers))
        delay = 1.0
        for attempt in range(retries + 1):
            try:
                with urllib.request.urlopen(req, timeout=120) as resp:
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
                raise SystemExit(f"réseau : {method} {path} : {e}")
        raise SystemExit("inatteignable")

    # ----- PostgREST
    def upsert(self, table: str, rows: list[dict], on_conflict: str, batch: int = 200) -> None:
        for start in range(0, len(rows), batch):
            chunk = rows[start:start + batch]
            status, body = self.request(
                "POST",
                f"/rest/v1/{table}?on_conflict={urllib.parse.quote(on_conflict)}",
                data=json.dumps(chunk, ensure_ascii=False).encode("utf-8"),
                headers={
                    "Content-Type": "application/json",
                    "Prefer": "resolution=merge-duplicates,return=minimal",
                },
            )
            if status not in (200, 201, 204):
                raise SystemExit(f"upsert {table} ({start}-{start + len(chunk)}) : HTTP {status} {body[:400]!r}")

    def select(self, table: str, query: str) -> list[dict]:
        rows: list[dict] = []
        offset, page = 0, 1000
        while True:
            status, body = self.request(
                "GET", f"/rest/v1/{table}?{query}&limit={page}&offset={offset}",
                headers={"Accept": "application/json"},
            )
            if status != 200:
                raise SystemExit(f"select {table} : HTTP {status} {body[:400]!r}")
            chunk = json.loads(body)
            rows.extend(chunk)
            if len(chunk) < page:
                return rows
            offset += page

    def delete(self, table: str, query: str) -> None:
        status, body = self.request("DELETE", f"/rest/v1/{table}?{query}", headers={"Prefer": "return=minimal"})
        if status not in (200, 204):
            raise SystemExit(f"delete {table} : HTTP {status} {body[:400]!r}")

    # ----- Storage
    def list_objects(self, prefix: str) -> set[str]:
        names: set[str] = set()
        offset = 0
        while True:
            payload = json.dumps({"prefix": prefix, "limit": 1000, "offset": offset,
                                  "sortBy": {"column": "name", "order": "asc"}}).encode("utf-8")
            status, body = self.request("POST", f"/storage/v1/object/list/{BUCKET}", data=payload,
                                        headers={"Content-Type": "application/json"})
            if status != 200:
                raise SystemExit(f"list {prefix} : HTTP {status} {body[:300]!r}")
            chunk = json.loads(body)
            for item in chunk:
                if item.get("id"):  # les « dossiers » n'ont pas d'id
                    names.add(f"{prefix}{item['name']}" if prefix.endswith("/") else item["name"])
            if len(chunk) < 1000:
                return names
            offset += 1000

    def upload(self, path: str, data: bytes) -> None:
        status, body = self.request(
            "POST", f"/storage/v1/object/{BUCKET}/{urllib.parse.quote(path)}", data=data,
            headers={
                "Content-Type": "application/json",
                "x-upsert": "true",
                # Le hash est dans le nom : l'objet ne change jamais, le CDN peut le garder un an.
                "cache-control": "public, max-age=31536000, immutable",
            },
        )
        if status not in (200, 201):
            raise SystemExit(f"upload {path} : HTTP {status} {body[:300]!r}")


# ---------------------------------------------------------------- sources

class Sources:
    def __init__(self, languages: list[str]):
        self.languages = languages
        self.authors = load_json(CONTENT / "authors.json")["authors"]
        self.credits = load_json(CONTENT / "image_credits.json")
        self.cover_map = load_json(CONTENT / "course_image_map.json")
        withheld = load_json(CONTENT / "catalog_withheld.json")
        self.withheld_by_lang = {k: set(v) for k, v in withheld.get("by_language", {}).items()}
        self.collections = load_json(CONTENT / "collections" / "collections.json")
        self.course_ids = sorted(p.stem for p in (CONTENT / "courses" / "fr").glob("*.json"))
        # L'index est la liste de référence : un cours français hors index (ou l'inverse) est une erreur.
        indexed = set(load_json(CONTENT / "courses" / "index.json").get("courses", []))
        if indexed and indexed != set(self.course_ids):
            print(f"attention : {len(self.course_ids)} cours en français, {len(indexed)} dans content/courses/index.json "
                  f"(écart : {sorted(indexed ^ set(self.course_ids))[:5]})")

    def courses(self, lang: str) -> dict[str, dict]:
        out = {}
        for cid in self.course_ids:
            path = CONTENT / "courses" / lang / f"{cid}.json"
            if path.exists():
                out[cid] = load_json(path)
        return out

    def quizzes(self, lang: str) -> dict[str, list]:
        path = CONTENT / "locales" / lang / "quizzes_v2.json"
        if not path.exists():
            return {}
        return {entry["courseId"]: entry["quiz"] for entry in load_json(path)}

    def glossary(self, lang: str) -> dict[str, dict]:
        path = CONTENT / "glossary" / f"{lang}.json"
        return load_json(path) if path.exists() else {}

    def collection_translations(self, lang: str) -> dict[str, dict]:
        path = CONTENT / "collections" / f"{lang}.json"
        if not path.exists():
            return {}
        return {row["id"]: row for row in load_json(path)}

    def author_slug(self, course: dict) -> str | None:
        slug = course.get("author")
        if isinstance(slug, dict):
            slug = slug.get("slug")
        return slug if slug and any(a["slug"] == slug for a in self.authors) else None

    def image_slugs(self, course: dict) -> list[str]:
        """La couverture et les images des blocs, dans l'ordre d'apparition."""
        slugs: list[str] = []
        hero = (course.get("hero") or {}).get("image")
        if hero:
            slugs.append(hero)
        for section in course.get("sections", []):
            for block in section.get("blocks", []):
                # Les blocs image nomment leur objet dans `asset` (format V2) ; `image` est l'ancien nom.
                slug = block.get("asset") or block.get("image") if block.get("type") == "image" else None
                if slug:
                    slugs.append(slug)
        seen: set[str] = set()
        return [s for s in slugs if not (s in seen or seen.add(s))]

    def starter_course_ids(self) -> list[str]:
        """Les 40 premiers cours du Parcours, dans l'ordre des collections : ce que le lecteur
        ouvre en premier, et ce qui doit marcher sans réseau."""
        out: list[str] = []
        for collection in self.collections:
            for cid in collection["courseIds"]:
                if cid in self.course_ids and cid not in out:
                    out.append(cid)
                if len(out) >= STARTER_COUNT:
                    return out
        for cid in self.course_ids:
            if cid not in out:
                out.append(cid)
            if len(out) >= STARTER_COUNT:
                break
        return out


# ---------------------------------------------------------------- construction des paquets

def build_language(src: Sources, lang: str) -> dict:
    """Tout ce qui concerne une langue : les lignes des tables, les paquets et les fichiers."""
    courses = src.courses(lang)
    quizzes = src.quizzes(lang)
    glossary = src.glossary(lang)
    translations = src.collection_translations(lang)
    withheld = src.withheld_by_lang.get(lang, set())

    glossary_by_course: dict[str, dict] = {}
    for key, entry in glossary.items():
        cid, _, term = key.partition("|")
        glossary_by_course.setdefault(cid, {})[term] = entry

    bundles: dict[str, dict] = {}
    contents_rows, quiz_rows, glossary_rows, catalog_courses = [], [], [], []
    for cid, course in courses.items():
        quiz = quizzes.get(cid, [])
        course_glossary = glossary_by_course.get(cid, {})
        credits = {slug: src.credits[slug] for slug in src.image_slugs(course) if slug in src.credits}
        bundle = {"id": cid, "lang": lang, "content": course, "quiz": quiz, "glossary": course_glossary, "credits": credits}
        bundle_hash = digest({k: v for k, v in bundle.items() if k != "hash"})
        bundle["hash"] = bundle_hash
        bundles[cid] = bundle
        status = "withheld" if cid in withheld else "published"
        hero = course.get("hero") or {}
        sections = course.get("sections", [])
        contents_rows.append({
            "course_id": cid, "lang": lang, "status": status,
            "title": course["title"], "subtitle": course.get("subtitle"),
            "description": course.get("description", ""), "subcategory": course.get("subcategory", ""),
            "hook": hero.get("hook"), "section_ids": [s["id"] for s in sections],
            "content": course, "hash": bundle_hash, "bytes": len(canonical(bundle)),
        })
        quiz_rows.append({"course_id": cid, "lang": lang, "questions": quiz, "hash": digest(quiz)})
        for term, entry in course_glossary.items():
            glossary_rows.append({
                "course_id": cid, "lang": lang, "term": term,
                "display_term": entry.get("displayTerm") or term,
                "classification": entry.get("classification"),
                "explanation": entry.get("explanation", ""),
            })
        if status == "published":
            catalog_courses.append({
                "id": cid, "title": course["title"], "subtitle": course.get("subtitle"),
                "description": course.get("description", ""),
                "subject": course["subject"], "subcategory": course.get("subcategory", ""),
                "hook": hero.get("hook"), "creator": src.author_slug(course),
                "cover": src.cover_map.get(cid) or hero.get("image"),
                "tier": "standard",
                "sections": [{"id": s["id"], "title": s["title"], "free": bool(s.get("free", False))} for s in sections],
                "quizCount": len(quiz), "hash": bundle_hash,
            })

    catalog_collections = []
    for index, collection in enumerate(src.collections):
        tr = translations.get(collection["id"])
        if not tr:
            continue
        catalog_collections.append({
            "id": collection["id"], "title": tr["title"], "description": tr.get("description", ""),
            "cover": collection.get("coverAssetName", ""),
            "courseIds": [cid for cid in collection["courseIds"] if cid in courses and cid not in withheld],
        })

    creators = []
    courses_by_author: dict[str, list[str]] = {}
    for cid, course in courses.items():
        slug = src.author_slug(course)
        if slug and cid not in withheld:
            courses_by_author.setdefault(slug, []).append(cid)
    for author in src.authors:
        creators.append({
            "slug": author["slug"], "name": author["name"], "photo": author.get("photo"),
            "institution": author.get("institution"), "country": author.get("country"),
            "links": author.get("links") or {},
            "title": (author.get("title") or {}).get(lang) or (author.get("title") or {}).get("fr"),
            "bio": (author.get("bio") or {}).get(lang) or (author.get("bio") or {}).get("fr"),
            "verified": True,
            "courseIds": courses_by_author.get(author["slug"], []),
        })

    catalog = {"lang": lang, "courses": catalog_courses, "collections": catalog_collections, "creators": creators}
    catalog["hash"] = digest(catalog)
    quizzes_file = {cid: bundles[cid]["quiz"] for cid in courses if cid not in withheld}
    glossary_file = {key: entry for key, entry in glossary.items() if key.partition("|")[0] in courses and key.partition("|")[0] not in withheld}
    files = {
        "catalog": catalog,
        "quizzes": quizzes_file,
        "glossary": glossary_file,
    }
    return {
        "lang": lang, "bundles": bundles, "files": files,
        "file_hashes": {kind: (catalog["hash"] if kind == "catalog" else digest(data)) for kind, data in files.items()},
        "contents_rows": contents_rows, "quiz_rows": quiz_rows, "glossary_rows": glossary_rows,
        "translations": [{"collection_id": cid, "lang": lang, "title": tr["title"], "description": tr.get("description", "")}
                         for cid, tr in translations.items() if any(c["id"] == cid for c in src.collections)],
    }


def global_rows(src: Sources, fr_courses: dict[str, dict]) -> dict:
    creators = [{
        "slug": a["slug"], "name": a["name"], "photo": a.get("photo"), "institution": a.get("institution"),
        "country": a.get("country"), "links": a.get("links") or {}, "title": a.get("title") or {},
        "bio": a.get("bio") or {}, "verified": True,
    } for a in src.authors]
    courses = [{
        "id": cid, "subject": course["subject"], "creator_slug": src.author_slug(course),
        "status": "published", "tier": "standard", "origin_lang": "fr",
        "cover_slug": src.cover_map.get(cid) or (course.get("hero") or {}).get("image"),
        "published_at": "2026-01-01T00:00:00Z",
    } for cid, course in fr_courses.items()]
    collections = [{"id": c["id"], "sort_index": i, "cover_slug": c.get("coverAssetName") or None, "status": "published"}
                   for i, c in enumerate(src.collections)]
    collection_courses = [{"collection_id": c["id"], "course_id": cid, "position": pos}
                          for c in src.collections for pos, cid in enumerate(c["courseIds"]) if cid in fr_courses]
    assets = []
    for cid, course in fr_courses.items():
        for index, slug in enumerate(src.image_slugs(course)):
            kind = "cover" if index == 0 and slug == (course.get("hero") or {}).get("image") else "image"
            assets.append({
                "course_id": cid, "slug": slug, "kind": kind, "lang": None,
                "url": f"{DEFAULT_URL}/storage/v1/object/public/course-images/{slug}.jpg",
                "credit": src.credits.get(slug),
            })
    return {"creators": creators, "courses": courses, "collections": collections,
            "collection_courses": collection_courses, "assets": assets}


# ---------------------------------------------------------------- packs de départ

def write_starter_pack(root: Path, built: dict, starter_ids: list[str]) -> int:
    """Le catalogue complet de la langue et les 40 cours du début, avec quiz et glossaire."""
    lang_dir = root / built["lang"]
    courses_dir = lang_dir / "courses"
    courses_dir.mkdir(parents=True, exist_ok=True)
    for stale in courses_dir.glob("*.json"):
        if stale.stem not in starter_ids:
            stale.unlink()
    (lang_dir / "catalog.json").write_bytes(canonical(built["files"]["catalog"]))
    written = 1
    for cid in starter_ids:
        bundle = built["bundles"].get(cid)
        if bundle is None:
            continue
        (courses_dir / f"{cid}.json").write_bytes(canonical(bundle))
        written += 1
    return written


# ---------------------------------------------------------------- import

def import_language(sb: Supabase, built: dict, existing_objects: set[str], dry_run: bool) -> dict:
    lang = built["lang"]
    stats = {"contents": 0, "uploads": 0, "files": 0}
    # Ce qui est déjà en base avec le même hash n'est pas réécrit.
    known = {row["course_id"]: row["hash"] for row in sb.select(
        "course_contents", f"select=course_id,hash&lang=eq.{lang}")} if not dry_run else {}
    changed = [row for row in built["contents_rows"] if known.get(row["course_id"]) != row["hash"]]
    stats["contents"] = len(changed)
    if changed and not dry_run:
        sb.upsert("course_contents", changed, "course_id,lang", batch=40)
        changed_ids = {row["course_id"] for row in changed}
        sb.upsert("quizzes", [r for r in built["quiz_rows"] if r["course_id"] in changed_ids], "course_id,lang")
        for cid in changed_ids:
            sb.delete("glossary_entries", f"course_id=eq.{urllib.parse.quote(cid)}&lang=eq.{lang}")
        glossary_rows = [r for r in built["glossary_rows"] if r["course_id"] in changed_ids]
        if glossary_rows:
            sb.upsert("glossary_entries", glossary_rows, "course_id,lang,term", batch=500)
    if built["translations"] and not dry_run:
        sb.upsert("collection_translations", built["translations"], "collection_id,lang")

    # Storage : les paquets des cours, puis les trois fichiers de la langue.
    to_upload: list[tuple[str, bytes]] = []
    for cid, bundle in built["bundles"].items():
        path = f"{lang}/courses/{cid}.{bundle['hash']}.json"
        if path not in existing_objects:
            to_upload.append((path, canonical(bundle)))
    for kind, data in built["files"].items():
        path = f"{lang}/{kind}.{built['file_hashes'][kind]}.json"
        if path not in existing_objects:
            to_upload.append((path, canonical(data)))
    stats["uploads"] = len(to_upload)
    if to_upload and not dry_run:
        with ThreadPoolExecutor(max_workers=8) as pool:
            futures = [pool.submit(sb.upload, path, data) for path, data in to_upload]
            for future in as_completed(futures):
                future.result()
    if not dry_run:
        sb.upsert("catalog_files", [
            {"lang": lang, "kind": kind, "hash": built["file_hashes"][kind], "bytes": len(canonical(data))}
            for kind, data in built["files"].items()
        ], "lang,kind")
        stats["files"] = 3
    return stats


def verify(sb: Supabase, languages: list[str], expected: int) -> bool:
    ok = True
    for lang in languages:
        rows = sb.select("course_contents", f"select=course_id&lang=eq.{lang}&status=eq.published")
        files = sb.select("catalog_files", f"select=kind&lang=eq.{lang}")
        flag = "ok " if len(files) == 3 else "KO "
        print(f"  {flag}{lang}: {len(rows)} cours publiés, {len(files)} fichiers")
        ok &= len(files) == 3
    courses = sb.select("courses", "select=id")
    print(f"  courses : {len(courses)} (attendu {expected})")
    return ok and len(courses) == expected


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--lang", default="all", help="codes séparés par des virgules (défaut : les 30)")
    parser.add_argument("--dry-run", action="store_true", help="construit et compte, n'écrit rien dans Supabase")
    parser.add_argument("--starter-pack-only", action="store_true", help="écrit seulement les packs de départ des apps")
    parser.add_argument("--no-starter-pack", action="store_true")
    parser.add_argument("--verify", action="store_true", help="compte ce qui est en base et s'arrête")
    args = parser.parse_args()

    languages = sorted(SWIFT_CASE_BY_CODE) if args.lang == "all" else [l.strip() for l in args.lang.split(",") if l.strip()]
    src = Sources(languages)
    url = os.environ.get("SUPABASE_URL", DEFAULT_URL)

    if args.verify:
        sb = Supabase(url, env_key())
        sys.exit(0 if verify(sb, languages, len(src.course_ids)) else 1)

    starter_ids = src.starter_course_ids()
    built_by_lang: dict[str, dict] = {}
    for lang in languages:
        built = build_language(src, lang)
        built_by_lang[lang] = built
        n = len(built["bundles"])
        if n != len(src.course_ids):
            print(f"attention : {lang} a {n} cours, le français {len(src.course_ids)}")
        if not args.no_starter_pack:
            write_starter_pack(IOS_PACK, built, starter_ids)
            write_starter_pack(ANDROID_PACK, built, starter_ids)
    if not args.no_starter_pack:
        print(f"packs de départ : {len(languages)} langues × (catalogue + {len(starter_ids)} cours) dans {IOS_PACK.relative_to(ROOT)} et {ANDROID_PACK.relative_to(ROOT)}")
    if args.starter_pack_only:
        return

    sb = Supabase(url, env_key())
    fr = src.courses("fr")
    rows = global_rows(src, fr)
    if not args.dry_run:
        sb.upsert("creators", rows["creators"], "slug")
        sb.upsert("courses", rows["courses"], "id")
        sb.upsert("collections", rows["collections"], "id")
        sb.upsert("collection_courses", rows["collection_courses"], "collection_id,course_id")
        # Les ressources sont recréées (clé composée avec un coalesce : pas d'on_conflict simple).
        sb.delete("course_assets", "id=gt.0")
        sb.upsert("course_assets", rows["assets"], "id", batch=500)
        print(f"tables communes : {len(rows['creators'])} créateurs, {len(rows['courses'])} cours, "
              f"{len(rows['collections'])} collections, {len(rows['assets'])} ressources")

    existing = set()
    if not args.dry_run:
        for lang in languages:
            existing |= sb.list_objects(f"{lang}/")
            existing |= sb.list_objects(f"{lang}/courses/")
    total_uploads = 0
    for lang in languages:
        stats = import_language(sb, built_by_lang[lang], existing, args.dry_run)
        total_uploads += stats["uploads"]
        print(f"  {lang}: {stats['contents']} contenus à écrire, {stats['uploads']} objets à téléverser")
    print(f"objets téléversés : {total_uploads}")
    if not args.dry_run:
        print("vérification :")
        if not verify(sb, languages, len(src.course_ids)):
            sys.exit(1)


if __name__ == "__main__":
    main()
