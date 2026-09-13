#!/usr/bin/env python3
"""Fill the App Store product page in every language the app speaks.

Sophia ships 26 languages and App Store Connect will take 23 of them. Estonian,
Serbian and Bulgarian are not among the 50 locales Apple offers for store
metadata, so those readers get a product page in the primary language and an app
in theirs -- which works, because the app picks its language itself rather than
following the device locale.

Four steps, each its own subcommand, in the order you run them:

    pull    read what App Store Connect already holds into appstore/metadata/
    build   translate the source locale into every locale still missing text
    check   validate lengths and locales -- no network, no account needed
    push    write the tree back to App Store Connect

Only ``build`` calls the translation engine and only ``push`` writes to Apple, so
whatever is about to be published can always be read on disk in between. Nothing
is ever translated twice: ``build`` skips a field that already has text unless
asked to redo it.

Screenshots are deliberately not handled. A locale with no screenshots of its own
shows the primary locale's, so 23 languages times six device sizes is work Apple
makes unnecessary.

Credentials come from the environment, never from the repository:

    export ASC_KEY_ID=XXXXXXXXXX
    export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    export ASC_PRIVATE_KEY=~/.appstoreconnect/AuthKey_XXXXXXXXXX.p8

That .p8 signs for your whole account. Keep it outside the repo, as
``AppConfig.swift`` already says of the other keys.

Usage:
    python3 scripts/appstore_metadata.py check
    python3 scripts/appstore_metadata.py pull
    python3 scripts/appstore_metadata.py build --from fr-FR
    python3 scripts/appstore_metadata.py push --dry-run
    python3 scripts/appstore_metadata.py push
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from i18n_languages import ALL_CONTENT_LANGS, GT_TARGETS  # noqa: E402

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLE_ID = "app.rork.assvmps5x7hpyq0ezcsut"
METADATA = ROOT / "appstore" / "metadata"
SUBSCRIPTIONS = ROOT / "appstore" / "subscriptions"
GROUPS = ROOT / "appstore" / "subscription_groups"

#: App language code -> App Store Connect locale shortcode, or None where Apple
#: has no such locale.
#:
#: The shortcodes are not plain ISO codes throughout -- a few carry a region and
#: most do not -- and Apple publishes the table on a page that renders in
#: JavaScript, so this mapping is treated as a proposal rather than a fact.
#: ``pull`` prints the real shortcode of every locale already configured on the
#: account, which is the authoritative answer for those; ``push`` reports one
#: line per locale and keeps going, so a wrong code costs that locale and not the
#: run. Fix any Apple rejects here and re-run.
ASC_LOCALE: dict[str, str | None] = {
    "fr": "fr-FR",
    "en": "en-US",
    "es": "es-ES",
    "de": "de-DE",
    "pt": "pt-PT",
    "it": "it",
    "nl": "nl-NL",
    "pl": "pl",
    "ru": "ru",
    "tr": "tr",
    "sv": "sv",
    "da": "da",
    "nb": "no",
    "fi": "fi",
    "cs": "cs",
    "sk": "sk",
    # Apple rejected plain "sl" with "The language specified is not listed for
    # localization". fastlane spells Slovenian "sl-SI", so that is what this
    # tries -- but the same error hits a known group of languages Apple
    # announced in March 2026 and has not finished wiring up (Bengali, Marathi,
    # Slovenian, Punjabi, Tamil, Telugu, Urdu), so the shortcode may not be the
    # problem at all. If "sl-SI" is refused too, set this to None: the store has
    # no Slovenian page to offer yet, whatever the documentation lists.
    "sl": "sl-SI",
    "hr": "hr",
    "hu": "hu",
    "ro": "ro",
    "el": "el",
    "he": "he",
    "ar": "ar-SA",
    # Not offered by App Store Connect. The app speaks them; the store does not.
    "bg": None,
    "sr": None,
    "et": None,
}

LANG_FOR_LOCALE = {locale: lang for lang, locale in ASC_LOCALE.items() if locale}

#: Version-level fields, file name -> API attribute.
VERSION_FIELDS = {
    "description": "description",
    "keywords": "keywords",
    "promotional_text": "promotionalText",
    "whats_new": "whatsNew",
    "marketing_url": "marketingUrl",
    "support_url": "supportUrl",
}

#: App-level fields (name and subtitle live on appInfoLocalizations, not on the
#: version -- changing them is a different object with a different lifecycle).
INFO_FIELDS = {
    "name": "name",
    "subtitle": "subtitle",
    "privacy_policy_url": "privacyPolicyUrl",
}

#: Apple truncates nothing: over the limit, the whole request is rejected.
LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "whats_new": 4000,
    "subscription_name": 30,
    "subscription_description": 45,
}

#: Fields worth translating.
TRANSLATABLE = ("subtitle", "description", "keywords", "promotional_text", "whats_new")

#: Fields copied from the source locale rather than translated.
#:
#: The name is a brand and the engine reads it as a word: "Sophia" came back
#: "Sofia" in Italian, "Σοφία" in Greek and "صوفي" in Arabic -- three different
#: apps, none of them this one, and the Arabic did not even match the spelling
#: its own description used. A URL is the same string in every language by
#: definition. Pass --translate-name if you want a transliterated name in some
#: market: that is a branding decision, taken per market, not a translation.
COPIED = ("name", "marketing_url", "support_url", "privacy_policy_url")

#: A version in one of these states accepts metadata edits. Anything else -- in
#: review, live, waiting for release -- does not, and Apple answers 409.
EDITABLE = {
    "PREPARE_FOR_SUBMISSION",
    "DEVELOPER_REJECTED",
    "REJECTED",
    "METADATA_REJECTED",
    "INVALID_BINARY",
}


# --- credentials ----------------------------------------------------------


def token() -> str:
    """A 20-minute App Store Connect JWT, signed with the account's .p8.

    Apple caps the lifetime at 20 minutes and rejects anything longer. This asks
    for 19: a token minted at exactly the cap is refused outright by a server
    clock a second ahead of yours. It is minted per run and cached nowhere.
    """
    try:
        import jwt  # PyJWT, which needs `cryptography` for ES256
    except ImportError:
        sys.exit(
            "Missing PyJWT. Install it with:\n"
            "    python3 -m pip install pyjwt cryptography"
        )

    missing = [n for n in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_PRIVATE_KEY") if not os.environ.get(n)]
    if missing:
        sys.exit(
            f"Missing {', '.join(missing)}.\n"
            "App Store Connect -> Users and Access -> Integrations -> App Store Connect API.\n"
            "ASC_PRIVATE_KEY is the path to the .p8 file, which belongs outside this repo."
        )

    # On a laptop this names a .p8 file; in CI the key itself is the secret and
    # there is no file to name. Telling them apart beats a second variable.
    raw = os.environ["ASC_PRIVATE_KEY"]
    if "BEGIN PRIVATE KEY" in raw:
        secret = raw.replace("\\n", "\n")
    else:
        key_path = Path(raw).expanduser()
        if not key_path.is_file():
            sys.exit(
                f"ASC_PRIVATE_KEY is neither a key nor a file: {key_path}\n"
                "Give it the path to the .p8, or the contents of one."
            )
        secret = key_path.read_text(encoding="utf-8")

    now = int(time.time())
    return jwt.encode(
        {
            "iss": os.environ["ASC_ISSUER_ID"],
            "iat": now,
            "exp": now + 19 * 60,
            "aud": "appstoreconnect-v1",
        },
        secret,
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"},
    )


# --- transport ------------------------------------------------------------


class Client:
    def __init__(self, dry_run: bool = False) -> None:
        self.dry_run = dry_run
        self._token: str | None = None

    @property
    def auth(self) -> str:
        if self._token is None:
            self._token = token()
        return self._token

    def call(self, method: str, path: str, *, body: dict | None = None, params: dict | None = None) -> dict:
        url = path if path.startswith("http") else f"{API}{path}"
        if params:
            url = f"{url}?{urllib.parse.urlencode(params)}"
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "Authorization": f"Bearer {self.auth}",
                **({"Content-Type": "application/json"} if data else {}),
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                raw = response.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as error:
            raise ApiError(error.code, error.read().decode(errors="replace")) from None

    def get_all(self, path: str, params: dict | None = None) -> list[dict]:
        """Every page of a collection, followed through `links.next`."""
        out: list[dict] = []
        page = self.call("GET", path, params={**(params or {}), "limit": 200})
        while True:
            out.extend(page.get("data") or [])
            nxt = (page.get("links") or {}).get("next")
            if not nxt:
                return out
            page = self.call("GET", nxt)


class ApiError(Exception):
    def __init__(self, status: int, payload: str) -> None:
        self.status = status
        try:
            errors = json.loads(payload).get("errors") or []
            detail = "; ".join(
                f"{e.get('title', '')}: {e.get('detail', '')}".strip(": ") for e in errors
            )
        except Exception:  # noqa: BLE001 -- a non-JSON body is still worth showing
            detail = payload[:400]
        self.detail = detail or f"HTTP {status}"
        super().__init__(f"HTTP {status} -- {self.detail}")


# --- discovery ------------------------------------------------------------


def find_app(client: Client, bundle_id: str) -> str:
    apps = client.get_all("/apps", {"filter[bundleId]": bundle_id})
    if not apps:
        sys.exit(f"No app with bundle id {bundle_id} on this account.")
    return apps[0]["id"]


def state_of(record: dict) -> str:
    """The version's state, under whichever name this API version uses.

    Apple renamed `appStoreState` to `appVersionState`; accounts answer with one
    or the other depending on when they were migrated.
    """
    attributes = record.get("attributes") or {}
    return attributes.get("appVersionState") or attributes.get("appStoreState") or ""


def find_version(client: Client, app_id: str) -> tuple[str, str]:
    """The version accepting metadata edits, and its state."""
    versions = client.get_all(f"/apps/{app_id}/appStoreVersions")
    for version in versions:
        if state_of(version) in EDITABLE:
            return version["id"], state_of(version)
    states = ", ".join(sorted({state_of(v) for v in versions})) or "none"
    sys.exit(
        "No editable App Store version. Metadata can only be written to a version "
        f"being prepared; this app's versions are: {states}.\n"
        "Create the next version in App Store Connect first."
    )


def find_app_info(client: Client, app_id: str) -> str:
    """The editable appInfo, which carries the name and subtitle."""
    infos = client.get_all(f"/apps/{app_id}/appInfos")
    for info in infos:
        if state_of(info) in EDITABLE:
            return info["id"]
    if infos:
        return infos[0]["id"]
    sys.exit("This app has no appInfo record, which should not happen.")


# --- local tree -----------------------------------------------------------


def read_field(locale: str, field: str) -> str | None:
    path = METADATA / locale / f"{field}.txt"
    return path.read_text(encoding="utf-8").strip() if path.is_file() else None


def write_field(locale: str, field: str, value: str) -> None:
    folder = METADATA / locale
    folder.mkdir(parents=True, exist_ok=True)
    (folder / f"{field}.txt").write_text(value.strip() + "\n", encoding="utf-8")


def locales_on_disk() -> list[str]:
    if not METADATA.is_dir():
        return []
    return sorted(p.name for p in METADATA.iterdir() if p.is_dir())


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}


def save_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


# --- check ----------------------------------------------------------------


def too_long(field: str, value: str) -> str | None:
    limit = LIMITS.get(field)
    if limit and len(value) > limit:
        return f"{field}: {len(value)} characters, limit {limit}"
    return None


def keyword_problems(value: str) -> list[str]:
    """What is wrong with a keyword list, beyond its length.

    The field is 100 characters and Apple counts every one of them, so a space
    after a comma is a keyword's worth of budget spent on nothing. Apple also
    recombines single keywords into phrases by itself, which is why these are
    single words: spelling out "culture generale" buys a match that "culture" and
    "generale" already cover.
    """
    problems: list[str] = []
    if " " in value:
        problems.append("keywords: contains a space -- Apple counts it, and gains nothing")
    terms = [t.strip().lower() for t in value.split(",")]
    duplicates = sorted({t for t in terms if terms.count(t) > 1 and t})
    if duplicates:
        problems.append(f"keywords: repeated term(s) {', '.join(duplicates)}")
    if empty := sum(1 for t in terms if not t):
        problems.append(f"keywords: {empty} empty slot(s) from a stray comma")
    return problems


def check() -> int:
    problems: list[str] = []
    known = set(LANG_FOR_LOCALE)

    for locale in locales_on_disk():
        if locale not in known:
            problems.append(
                f"{locale}: not a locale this script maps to a language. Either it is "
                "not an App Store locale, or ASC_LOCALE needs the entry."
            )
        for field in (*VERSION_FIELDS, *INFO_FIELDS):
            value = read_field(locale, field)
            if value is None:
                continue
            if problem := too_long(field, value):
                problems.append(f"{locale}/{problem}")
            if field == "keywords":
                problems += [f"{locale}/{p}" for p in keyword_problems(value)]

    for path in sorted(SUBSCRIPTIONS.glob("*.json")) if SUBSCRIPTIONS.is_dir() else []:
        for locale, entry in load_json(path).items():
            for key, field in (("name", "subscription_name"), ("description", "subscription_description")):
                value = (entry or {}).get(key) or ""
                if problem := too_long(field, value):
                    problems.append(f"{path.name} [{locale}] {problem}")

    unsupported = [lang for lang, locale in ASC_LOCALE.items() if locale is None]
    missing_map = [lang for lang in ALL_CONTENT_LANGS if lang not in ASC_LOCALE]

    print(f"{len(locales_on_disk())} locale(s) on disk, {len(LANG_FOR_LOCALE)} mappable")
    if unsupported:
        print(f"no App Store locale: {', '.join(sorted(unsupported))} -- these get the primary language")
    if missing_map:
        print(f"app language with no entry in ASC_LOCALE: {', '.join(missing_map)}")
        problems.append("ASC_LOCALE does not cover every app language")

    if problems:
        print(f"\n{len(problems)} problem(s):")
        for problem in problems:
            print(f"  {problem}")
        return 1
    print("check OK: every field fits, every locale maps")
    return 0


# --- pull -----------------------------------------------------------------


def pull(client: Client) -> int:
    app_id = find_app(client, BUNDLE_ID)
    version_id, state = find_version(client, app_id)
    info_id = find_app_info(client, app_id)
    print(f"app {app_id}, version {version_id} ({state})")

    seen: set[str] = set()
    for record in client.get_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations"):
        attributes = record["attributes"]
        locale = attributes["locale"]
        seen.add(locale)
        for field, key in VERSION_FIELDS.items():
            if value := (attributes.get(key) or "").strip():
                write_field(locale, field, value)

    for record in client.get_all(f"/appInfos/{info_id}/appInfoLocalizations"):
        attributes = record["attributes"]
        locale = attributes["locale"]
        seen.add(locale)
        for field, key in INFO_FIELDS.items():
            if value := (attributes.get(key) or "").strip():
                write_field(locale, field, value)

    for group in client.get_all(f"/apps/{app_id}/subscriptionGroups"):
        group_id = group["id"]
        reference = (group["attributes"] or {}).get("referenceName") or group_id
        payload = {
            record["attributes"]["locale"]: {
                "name": record["attributes"].get("name") or "",
                "custom_app_name": record["attributes"].get("customAppName") or "",
            }
            for record in client.get_all(f"/subscriptionGroups/{group_id}/subscriptionGroupLocalizations")
        }
        if payload:
            save_json(GROUPS / f"{safe(reference)}.json", payload)

        for subscription in client.get_all(f"/subscriptionGroups/{group_id}/subscriptions"):
            product_id = (subscription["attributes"] or {}).get("productId") or subscription["id"]
            entries = {
                record["attributes"]["locale"]: {
                    "name": record["attributes"].get("name") or "",
                    "description": record["attributes"].get("description") or "",
                }
                for record in client.get_all(
                    f"/subscriptions/{subscription['id']}/subscriptionLocalizations"
                )
            }
            if entries:
                save_json(SUBSCRIPTIONS / f"{safe(product_id)}.json", entries)

    print(f"pulled {len(seen)} locale(s): {', '.join(sorted(seen))}")
    print(f"  -> {METADATA.relative_to(ROOT)}/")
    unmapped = sorted(seen - set(LANG_FOR_LOCALE))
    if unmapped:
        print(f"  note: {', '.join(unmapped)} came back from Apple but ASC_LOCALE has no language for them")
    return 0


def safe(name: str) -> str:
    return "".join(c if c.isalnum() or c in "._-" else "_" for c in name)


# --- build ----------------------------------------------------------------


def fit_keywords(terms: list[str], limit: int) -> str:
    """As many keywords as fit, in order, comma separated.

    Apple counts the separators, and a keyword list cut mid-word is worse than a
    shorter one, so whole terms are dropped from the end until it fits.
    """
    kept: list[str] = []
    for term in terms:
        candidate = ",".join([*kept, term])
        if len(candidate) > limit:
            break
        kept.append(term)
    return ",".join(kept)


PARAGRAPH = re.compile(r"(\n[ \t]*\n)")

#: Strings that must come back exactly as they went in, in every language.
#:
#: A URL is obvious: the description ends on its EULA link and an engine rewrites
#: a path the way it rewrites a sentence.
#:
#: The app's name is the same problem wearing a disguise. Left to itself the
#: engine declines it, transliterates it, or does both in one paragraph: the
#: Russian description came back carrying "Sophia" once, "София" five times and
#: seven declined forms besides, and the Arabic dropped the Latin name entirely.
#: A reader should meet one name, the one on the icon and in the store listing.
KEEP = ("Sophia",)
PROTECTED = re.compile("|".join([r"https?://[^\s<>\"]+", *(re.escape(k) for k in KEEP)]))

#: Sentinels are spelled with a letter and never a digit.
#:
#: ``ZZKEEP0ZZ`` reads as the obvious choice and loses: Greek swallows the
#: ``ZZKEEP`` and leaves ``1ZZ`` glued to the previous word, Hungarian eats the
#: trailing ``ZZ``, Finnish and Hebrew drop one of a pair. Measured on the same
#: paragraph across seven languages, the numbered sentinel came back whole in
#: three of them and the letter one in all seven. Identical runs share a
#: sentinel, so the app name costs one letter however often it appears.
LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def protect(text: str) -> tuple[str, dict[str, str]]:
    """Swap every protected run for a sentinel, one sentinel per distinct run."""
    kept: dict[str, str] = {}
    sentinel_for: dict[str, str] = {}

    def take(match: re.Match) -> str:
        original = match.group(0)
        if original not in sentinel_for:
            if len(sentinel_for) >= len(LETTERS):
                return original  # more distinct runs than letters; leave it be
            sentinel = f"ZZ{LETTERS[len(sentinel_for)]}ZZ"
            sentinel_for[original] = sentinel
            kept[sentinel] = original
        return sentinel_for[original]

    return PROTECTED.sub(take, text), kept


def restore(text: str, kept: dict[str, str]) -> str | None:
    """The text with the protected runs back, or None if one did not survive.

    Engines space out and re-case a bare token, so the sentinel is matched
    loosely -- but it has to be there. A field that lost one is reported and left
    empty rather than published with a mangled link or a half-translated name.
    """
    for sentinel, original in kept.items():
        pattern = re.compile(rf"ZZ\s*{sentinel[2:-2]}\s*ZZ", re.IGNORECASE)
        if not pattern.search(text):
            return None
        text = pattern.sub(lambda _: original, text)
    return text


def split_field(text: str) -> tuple[list[str], list[str], dict[str, str]]:
    """One field as (paragraphs, the separators between them, its protected runs).

    Paragraphs are translated one by one and rejoined on their own separators:
    handed the whole field, the engine returns it as a single run and the store
    page becomes a wall of text.
    """
    guarded, kept = protect(text)
    parts = PARAGRAPH.split(guarded)
    return parts[0::2], parts[1::2], kept


def join_field(pieces: list[str], separators: list[str], kept: dict[str, str]) -> str | None:
    out: list[str] = []
    for index, piece in enumerate(pieces):
        out.append(piece.strip())
        if index < len(separators):
            out.append(separators[index])
    return restore("".join(out), kept)


def build(source: str, redo: bool, only: list[str] | None, translate_name: bool) -> int:
    import mt_backend

    if not (METADATA / source).is_dir():
        sys.exit(f"No source metadata at {(METADATA / source).relative_to(ROOT)} -- run `pull` first.")

    targets = [
        locale
        for locale in sorted(LANG_FOR_LOCALE)
        if locale != source and (not only or locale in only)
    ]
    if not targets:
        sys.exit("Nothing to build.")

    source_lang = LANG_FOR_LOCALE.get(source)
    if not source_lang:
        sys.exit(f"{source} is not a locale this script knows a language for.")
    source_gt = GT_TARGETS.get(source_lang, source_lang)

    copied = tuple(f for f in COPIED if f != "name") if translate_name else COPIED
    translatable = ("name", *TRANSLATABLE) if translate_name else TRANSLATABLE

    written = 0
    skipped: list[str] = []
    for locale in targets:
        lang = LANG_FOR_LOCALE[locale]
        target_gt = GT_TARGETS.get(lang, lang)

        for field in copied:
            if (value := read_field(source, field)) and (redo or read_field(locale, field) is None):
                write_field(locale, field, value)

        pending = [
            field
            for field in translatable
            if read_field(source, field) and (redo or read_field(locale, field) is None)
        ]
        if not pending:
            continue

        # Keywords are a comma-separated list, not prose: each term is translated
        # on its own, or the engine renders the commas as a sentence.
        keyword_terms: list[str] = []
        if "keywords" in pending:
            keyword_terms = [t.strip() for t in (read_field(source, "keywords") or "").split(",") if t.strip()]

        # Every paragraph of every prose field goes in one batch, and each field
        # is rebuilt from its own slice of the answer.
        prose = [field for field in pending if field != "keywords"]
        layout: list[tuple[str, int, list[str], dict[str, str]]] = []
        payload: list[str] = []
        for field in prose:
            pieces, separators, urls = split_field(read_field(source, field) or "")
            layout.append((field, len(pieces), separators, urls))
            payload.extend(pieces)
        payload.extend(keyword_terms)

        try:
            out = mt_backend.translate_batch(payload, target_gt, source_gt)
        except Exception as error:  # noqa: BLE001
            print(f"  {locale}: translation failed ({error})", file=sys.stderr)
            continue

        cursor = 0
        for field, count, separators, urls in layout:
            value = join_field(out[cursor : cursor + count], separators, urls)
            cursor += count
            if value is None:
                skipped.append(f"{locale}/{field}: a link or the app name did not come back intact")
                continue
            value = value.strip()
            if problem := too_long(field, value):
                skipped.append(f"{locale}/{problem}")
                continue
            write_field(locale, field, value)
            written += 1

        if keyword_terms:
            fitted = fit_keywords([t.strip() for t in out[cursor:] if t.strip()], LIMITS["keywords"])
            if fitted:
                write_field(locale, "keywords", fitted)
                written += 1

        print(f"  {locale}: {len(pending)} field(s)")

    print(f"\n{written} field(s) written")
    if skipped:
        print(f"\n{len(skipped)} field(s) left empty because the translation overflows:")
        for line in skipped:
            print(f"  {line}")
        print("Shorten these by hand -- Apple rejects the whole request, it does not truncate.")
    return 0


# --- push -----------------------------------------------------------------


def push_localizations(
    client: Client,
    existing: list[dict],
    fields: dict[str, str],
    create_path: str,
    kind: str,
    parent: tuple[str, str, str],
    locales: list[str],
) -> tuple[int, int, list[str]]:
    """Create or update one family of localizations.

    `parent` is (relationship name, type, id) -- the link a new record needs back
    to its version or appInfo.
    """
    by_locale = {record["attributes"]["locale"]: record for record in existing}
    created = updated = 0
    failures: list[str] = []
    relationship, parent_type, parent_id = parent

    for locale in locales:
        wanted = {
            key: value
            for field, key in fields.items()
            if (value := read_field(locale, field)) is not None
        }
        if not wanted:
            continue

        record = by_locale.get(locale)
        try:
            if record is None:
                client.call(
                    "POST",
                    create_path,
                    body={
                        "data": {
                            "type": kind,
                            "attributes": {**wanted, "locale": locale},
                            "relationships": {
                                relationship: {"data": {"type": parent_type, "id": parent_id}}
                            },
                        }
                    },
                )
                created += 1
                print(f"  + {locale}  ({', '.join(sorted(wanted))})")
            else:
                changed = {
                    key: value
                    for key, value in wanted.items()
                    if (record["attributes"].get(key) or "").strip() != value
                }
                if not changed:
                    continue
                client.call(
                    "PATCH",
                    f"{create_path}/{record['id']}",
                    body={"data": {"type": kind, "id": record["id"], "attributes": changed}},
                )
                updated += 1
                print(f"  ~ {locale}  ({', '.join(sorted(changed))})")
        except ApiError as error:
            failures.append(f"{locale}: {error.detail}")
            print(f"  ! {locale}: {error.detail}", file=sys.stderr)

    return created, updated, failures


def push(client: Client, only: list[str] | None) -> int:
    if check() != 0:
        print("\nRefusing to push while check fails.", file=sys.stderr)
        return 1

    locales = [loc for loc in locales_on_disk() if loc in LANG_FOR_LOCALE and (not only or loc in only)]
    if not locales:
        sys.exit("No locale to push.")

    app_id = find_app(client, BUNDLE_ID)
    version_id, state = find_version(client, app_id)
    info_id = find_app_info(client, app_id)
    print(f"app {app_id}, version {version_id} ({state})")
    print(f"{len(locales)} locale(s): {', '.join(locales)}\n")

    if client.dry_run:
        version_existing = client.get_all(
            f"/appStoreVersions/{version_id}/appStoreVersionLocalizations"
        )
        have = {record["attributes"]["locale"] for record in version_existing}
        for locale in locales:
            fields = sorted(
                field for field in (*VERSION_FIELDS, *INFO_FIELDS) if read_field(locale, field)
            )
            print(f"  {'~' if locale in have else '+'} {locale}  ({', '.join(fields)})")
        print("\ndry run: nothing written")
        print(
            "Note a dry run cannot tell you whether Apple accepts a locale shortcode -- "
            "only the server knows. Locales it rejects are reported per line on the real run."
        )
        return 0

    print("App information (name, subtitle):")
    info_created, info_updated, info_failed = push_localizations(
        client,
        client.get_all(f"/appInfos/{info_id}/appInfoLocalizations"),
        INFO_FIELDS,
        "/appInfoLocalizations",
        "appInfoLocalizations",
        ("appInfo", "appInfos", info_id),
        locales,
    )

    print("\nVersion (description, keywords, what's new):")
    version_created, version_updated, version_failed = push_localizations(
        client,
        client.get_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations"),
        VERSION_FIELDS,
        "/appStoreVersionLocalizations",
        "appStoreVersionLocalizations",
        ("appStoreVersion", "appStoreVersions", version_id),
        locales,
    )

    sub_failed = push_subscriptions(client, app_id, locales)

    failures = info_failed + version_failed + sub_failed
    print(
        f"\n{info_created + version_created} created, {info_updated + version_updated} updated, "
        f"{len(failures)} failed"
    )
    if failures:
        print("\nRejected -- most often a locale shortcode Apple does not use:")
        for line in failures:
            print(f"  {line}")
        print("Correct ASC_LOCALE in this script and re-run; what succeeded is not redone.")
        return 1
    return 0


def push_subscriptions(client: Client, app_id: str, locales: list[str]) -> list[str]:
    if not SUBSCRIPTIONS.is_dir() and not GROUPS.is_dir():
        return []

    failures: list[str] = []
    wanted_by_product = {path.stem: load_json(path) for path in sorted(SUBSCRIPTIONS.glob("*.json"))}
    wanted_by_group = {path.stem: load_json(path) for path in sorted(GROUPS.glob("*.json"))}
    if not wanted_by_product and not wanted_by_group:
        return []

    print("\nSubscriptions:")
    for group in client.get_all(f"/apps/{app_id}/subscriptionGroups"):
        group_id = group["id"]
        reference = safe((group["attributes"] or {}).get("referenceName") or group_id)
        if entries := wanted_by_group.get(reference):
            failures += write_subscription_locales(
                client,
                f"/subscriptionGroups/{group_id}/subscriptionGroupLocalizations",
                "/subscriptionGroupLocalizations",
                "subscriptionGroupLocalizations",
                ("subscriptionGroup", "subscriptionGroups", group_id),
                entries,
                locales,
                ("name", "custom_app_name"),
                {"name": "name", "custom_app_name": "customAppName"},
                label=reference,
            )

        for subscription in client.get_all(f"/subscriptionGroups/{group_id}/subscriptions"):
            product_id = safe((subscription["attributes"] or {}).get("productId") or subscription["id"])
            entries = wanted_by_product.get(product_id)
            if not entries:
                continue
            failures += write_subscription_locales(
                client,
                f"/subscriptions/{subscription['id']}/subscriptionLocalizations",
                "/subscriptionLocalizations",
                "subscriptionLocalizations",
                ("subscription", "subscriptions", subscription["id"]),
                entries,
                locales,
                ("name", "description"),
                {"name": "name", "description": "description"},
                label=product_id,
            )
    return failures


def write_subscription_locales(
    client: Client,
    list_path: str,
    create_path: str,
    kind: str,
    parent: tuple[str, str, str],
    entries: dict,
    locales: list[str],
    keys: tuple[str, ...],
    api_key: dict[str, str],
    label: str,
) -> list[str]:
    existing = {record["attributes"]["locale"]: record for record in client.get_all(list_path)}
    relationship, parent_type, parent_id = parent
    failures: list[str] = []

    for locale in locales:
        entry = entries.get(locale)
        if not entry:
            continue
        wanted = {api_key[k]: (entry.get(k) or "").strip() for k in keys if (entry.get(k) or "").strip()}
        if not wanted:
            continue

        record = existing.get(locale)
        try:
            if record is None:
                client.call(
                    "POST",
                    create_path,
                    body={
                        "data": {
                            "type": kind,
                            "attributes": {**wanted, "locale": locale},
                            "relationships": {
                                relationship: {"data": {"type": parent_type, "id": parent_id}}
                            },
                        }
                    },
                )
                print(f"  + {label} [{locale}]")
            else:
                changed = {
                    key: value
                    for key, value in wanted.items()
                    if (record["attributes"].get(key) or "").strip() != value
                }
                if not changed:
                    continue
                client.call(
                    "PATCH",
                    f"{create_path}/{record['id']}",
                    body={"data": {"type": kind, "id": record["id"], "attributes": changed}},
                )
                print(f"  ~ {label} [{locale}]")
        except ApiError as error:
            failures.append(f"{label} [{locale}]: {error.detail}")
            print(f"  ! {label} [{locale}]: {error.detail}", file=sys.stderr)
    return failures


# --- entry point ----------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="validate the local tree; no network, no credentials")
    sub.add_parser("pull", help="download the live metadata into appstore/metadata/")

    builder = sub.add_parser("build", help="translate the source locale into the missing ones")
    builder.add_argument("--from", dest="source", default="fr-FR", help="source locale (default: fr-FR)")
    builder.add_argument("--redo", action="store_true", help="overwrite fields that already have text")
    builder.add_argument("--locale", action="append", help="only this locale (repeatable)")
    builder.add_argument(
        "--translate-name",
        action="store_true",
        help="also translate the app name, which is a branding decision (off by default)",
    )

    pusher = sub.add_parser("push", help="upload appstore/metadata/ to App Store Connect")
    pusher.add_argument("--dry-run", action="store_true", help="report what would change, write nothing")
    pusher.add_argument("--locale", action="append", help="only this locale (repeatable)")

    args = parser.parse_args()

    if args.command == "check":
        return check()
    if args.command == "build":
        return build(args.source, args.redo, args.locale, args.translate_name)

    client = Client(dry_run=getattr(args, "dry_run", False))
    try:
        if args.command == "pull":
            return pull(client)
        return push(client, args.locale)
    except ApiError as error:
        sys.exit(f"App Store Connect refused the request: {error}")


if __name__ == "__main__":
    raise SystemExit(main())
