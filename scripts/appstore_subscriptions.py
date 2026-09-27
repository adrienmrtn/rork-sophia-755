#!/usr/bin/env python3
"""Create the price-test subscriptions in App Store Connect from a manifest.

Reads ``appstore/subscriptions/price_tests.json`` and, for each product listed
there, creates in the existing "Sophia Premium" group an auto-renewable
subscription that is a copy of ``Sophia_yearly`` except for what the manifest
says: identifier, duration, base price, introductory offer.

Four subcommands, in the order you run them:

    plan     read the account and print what `apply` would create. Writes nothing.
    apply    create what is missing. Idempotent: a product that already exists is
             completed (localizations, prices, offer, screenshot), never duplicated.
    status   one line per subscription of the group with its App Store state.
    submit   submit the group for review (every subscription in "Ready to Submit").

What `apply` does for one product, in order, skipping every step already done:

    1. POST /subscriptions            name, productId, period, reviewNote, groupLevel
                                      (same level as the reference product)
    2. POST /subscriptionLocalizations the 12 locales of the manifest
    3. POST /subscriptionAvailabilities all territories, available in new territories
    4. prices: the base-territory price point for the manifest price, then one
       subscriptionPrice per territory from that point's `equalizations` (Apple's
       own grid), then the manifest `overrides` (e.g. TUR = 999.99)
    5. POST /subscriptionIntroductoryOffers  free trial, one per territory, when the
       manifest says so
    6. review screenshot copied from the reference product (download + upload)

Credentials come from the environment, never from the repository (same three
variables as scripts/appstore_metadata.py):

    ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY (path to the .p8, or its contents)

Nothing here touches an existing product's price: every variant is a new
product, so current subscribers are never affected.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from appstore_metadata import ApiError, Client, find_app  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "appstore" / "subscriptions" / "price_tests.json"


class PatientClient(Client):
    """Same client, built for a run longer than one token.

    One `apply` is roughly 350 calls per product (a price and an introductory
    offer per territory): a full run takes 20 to 30 minutes, longer than the
    20-minute lifetime Apple allows a token, and can brush the hourly quota.
    So the token is minted again every 15 minutes (and once more on a 401),
    and a rate limit or a transient 5xx is waited out instead of being fatal.
    """

    TOKEN_LIFETIME = 15 * 60
    RETRY_ON = {429, 500, 502, 503, 504}

    def __init__(self, dry_run: bool = False) -> None:
        super().__init__(dry_run=dry_run)
        self._minted_at = 0.0

    @property
    def auth(self) -> str:
        if self._token is None or time.monotonic() - self._minted_at > self.TOKEN_LIFETIME:
            self._token = None
            self._minted_at = time.monotonic()
        return super().auth

    def call(self, method: str, path: str, *, body: dict | None = None, params: dict | None = None) -> dict:
        refreshed = False
        for attempt in range(6):
            try:
                return super().call(method, path, body=body, params=params)
            except ApiError as error:
                if error.status == 401 and not refreshed:
                    refreshed = True
                    self._token = None
                    print("  (token expired, minting a new one)", flush=True)
                    continue
                if error.status not in self.RETRY_ON or attempt == 5:
                    raise
                wait = 60 if error.status == 429 else 5 * (attempt + 1)
                print(f"  (Apple answered {error.status}, waiting {wait}s before retrying)", flush=True)
                time.sleep(wait)
        raise AssertionError("unreachable")


def load_manifest(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(kind: str, ident: str) -> dict:
    return {"data": {"type": kind, "id": ident}}


# --- discovery ------------------------------------------------------------


def find_group(client: Client, app_id: str, name: str) -> dict:
    groups = client.get_all(f"/apps/{app_id}/subscriptionGroups")
    for group in groups:
        if (group["attributes"] or {}).get("referenceName") == name:
            return group
    names = ", ".join((g["attributes"] or {}).get("referenceName", "?") for g in groups)
    sys.exit(f"No subscription group named {name!r}. Groups on this app: {names}")


def subscriptions_in(client: Client, group_id: str) -> dict[str, dict]:
    return {
        (s["attributes"] or {}).get("productId"): s
        for s in client.get_all(f"/subscriptionGroups/{group_id}/subscriptions")
    }


def all_territories(client: Client) -> list[str]:
    return [t["id"] for t in client.get_all("/territories")]


# --- one product ----------------------------------------------------------


def ensure_subscription(client: Client, group_id: str, spec: dict, level: int, existing: dict | None) -> dict:
    if existing:
        print(f"  subscription exists ({(existing['attributes'] or {}).get('state')})")
        return existing
    body = {
        "data": {
            "type": "subscriptions",
            "attributes": {
                "name": spec["name"],
                "productId": spec["product_id"],
                "subscriptionPeriod": spec["period"],
                "familySharable": False,
                "reviewNote": spec["review_note"],
                "groupLevel": level,
            },
            "relationships": {"group": rel("subscriptionGroups", group_id)},
        }
    }
    if client.dry_run:
        print(f"  would create subscription {spec['product_id']} ({spec['period']}, level {level})")
        return {"id": None, "attributes": body["data"]["attributes"]}
    created = client.call("POST", "/subscriptions", body=body)["data"]
    print(f"  created subscription {spec['product_id']} -> {created['id']}")
    return created


def ensure_localizations(client: Client, sub_id: str | None, texts: dict[str, list[str]]) -> None:
    have = set()
    if sub_id:
        have = {
            (loc["attributes"] or {}).get("locale")
            for loc in client.get_all(f"/subscriptions/{sub_id}/subscriptionLocalizations")
        }
    missing = [loc for loc in texts if loc not in have]
    if not missing:
        print(f"  localizations: all {len(texts)} present")
        return
    if client.dry_run or not sub_id:
        print(f"  would add {len(missing)} localizations: {', '.join(missing)}")
        return
    for locale in missing:
        name, description = texts[locale]
        client.call(
            "POST",
            "/subscriptionLocalizations",
            body={
                "data": {
                    "type": "subscriptionLocalizations",
                    "attributes": {"name": name, "description": description, "locale": locale},
                    "relationships": {"subscription": rel("subscriptions", sub_id)},
                }
            },
        )
    print(f"  localizations: added {len(missing)}")


def ensure_availability(client: Client, sub_id: str | None, territories: list[str]) -> None:
    if sub_id:
        try:
            current = client.call("GET", f"/subscriptions/{sub_id}/subscriptionAvailability")
            if current.get("data"):
                print("  availability: already set")
                return
        except ApiError as error:
            if error.status != 404:
                raise
    if client.dry_run or not sub_id:
        print(f"  would set availability: {len(territories)} territories + new territories")
        return
    client.call(
        "POST",
        "/subscriptionAvailabilities",
        body={
            "data": {
                "type": "subscriptionAvailabilities",
                "attributes": {"availableInNewTerritories": True},
                "relationships": {
                    "subscription": rel("subscriptions", sub_id),
                    "availableTerritories": {"data": [{"type": "territories", "id": t} for t in territories]},
                },
            }
        },
    )
    print(f"  availability: {len(territories)} territories")


def price_point(client: Client, sub_id: str, territory: str, customer_price: str) -> dict:
    points = client.get_all(
        f"/subscriptions/{sub_id}/pricePoints",
        {"filter[territory]": territory, "include": "territory"},
    )
    for point in points:
        if (point["attributes"] or {}).get("customerPrice") == customer_price:
            return point
    available = sorted({(p["attributes"] or {}).get("customerPrice") for p in points}, key=lambda v: float(v))
    near = [v for v in available if abs(float(v) - float(customer_price)) < 5]
    sys.exit(
        f"No price point {customer_price} in {territory} for this subscription. "
        f"Nearby price points: {', '.join(near) or 'none'}"
    )


def territory_of(point: dict) -> str | None:
    return (((point.get("relationships") or {}).get("territory") or {}).get("data") or {}).get("id")


def current_prices(client: Client, sub_id: str) -> dict[str, dict]:
    prices = client.get_all(f"/subscriptions/{sub_id}/prices", {"include": "territory,subscriptionPricePoint"})
    return {territory_of(p): p for p in prices if territory_of(p)}


def create_price(client: Client, sub_id: str, point_id: str, territory: str) -> None:
    client.call(
        "POST",
        "/subscriptionPrices",
        body={
            "data": {
                "type": "subscriptionPrices",
                "relationships": {
                    "subscription": rel("subscriptions", sub_id),
                    "subscriptionPricePoint": rel("subscriptionPricePoints", point_id),
                    "territory": rel("territories", territory),
                },
            }
        },
    )


def ensure_prices(client: Client, sub_id: str | None, spec: dict, base_territory: str) -> None:
    if client.dry_run or not sub_id:
        overrides = ", ".join(f"{k}={v}" for k, v in (spec.get("overrides") or {}).items()) or "none"
        print(f"  would price: {spec['price']} in {base_territory}, Apple's grid elsewhere, overrides: {overrides}")
        return
    have = current_prices(client, sub_id)
    base = price_point(client, sub_id, base_territory, spec["price"])
    equalized = client.get_all(f"/subscriptionPricePoints/{base['id']}/equalizations", {"include": "territory"})
    wanted = {base_territory: base["id"]}
    for point in equalized:
        territory = territory_of(point)
        if territory and territory not in wanted:
            wanted[territory] = point["id"]
    created = 0
    for territory, point_id in wanted.items():
        if territory in have:
            continue
        create_price(client, sub_id, point_id, territory)
        created += 1
    print(f"  prices: {created} created, {len(have)} already there, {len(wanted)} territories in Apple's grid")

    for territory, customer_price in (spec.get("overrides") or {}).items():
        point = price_point(client, sub_id, territory, customer_price)
        have = current_prices(client, sub_id)
        existing = have.get(territory)
        existing_point = (((existing or {}).get("relationships") or {}).get("subscriptionPricePoint") or {}).get("data") or {}
        if existing_point.get("id") == point["id"]:
            print(f"  override {territory}: already {customer_price}")
            continue
        if existing:
            client.call("DELETE", f"/subscriptionPrices/{existing['id']}")
        create_price(client, sub_id, point["id"], territory)
        print(f"  override {territory}: set to {customer_price}")


def ensure_intro_offer(client: Client, sub_id: str | None, spec: dict, territories: list[str]) -> None:
    """App Store Connect stores one introductory offer per territory, so a free
    trial "in every territory" is one POST per territory. Territories that
    already carry an offer are skipped, which makes an interrupted run resumable."""
    duration = spec.get("trial")
    if not duration:
        print("  introductory offer: none (by design)")
        return
    have: set[str] = set()
    if sub_id:
        offers = client.get_all(f"/subscriptions/{sub_id}/introductoryOffers", {"include": "territory"})
        have = {t for t in (territory_of(o) for o in offers) if t}
    missing = [t for t in territories if t not in have]
    if not missing:
        print(f"  introductory offer: free trial {duration} already in all {len(have)} territories")
        return
    if client.dry_run or not sub_id:
        print(f"  would add introductory offer: free trial {duration} in {len(missing)} territories")
        return
    for territory in missing:
        client.call(
            "POST",
            "/subscriptionIntroductoryOffers",
            body={
                "data": {
                    "type": "subscriptionIntroductoryOffers",
                    "attributes": {"duration": duration, "offerMode": "FREE_TRIAL", "numberOfPeriods": 1},
                    "relationships": {
                        "subscription": rel("subscriptions", sub_id),
                        "territory": rel("territories", territory),
                    },
                }
            },
        )
    print(f"  introductory offer: free trial {duration} added in {len(missing)} territories ({len(have)} already there)")


def reference_screenshot(client: Client, reference_id: str) -> tuple[str, bytes] | None:
    try:
        shot = client.call("GET", f"/subscriptions/{reference_id}/appStoreReviewScreenshot").get("data")
    except ApiError as error:
        if error.status == 404:
            return None
        raise
    if not shot:
        return None
    attributes = shot["attributes"] or {}
    asset = attributes.get("imageAsset") or {}
    template = asset.get("templateUrl")
    if not template:
        return None
    url = template.replace("{w}", str(asset.get("width", 1290))).replace("{h}", str(asset.get("height", 2796))).replace("{f}", "png")
    with urllib.request.urlopen(url, timeout=60) as response:
        data = response.read()
    # The template always serves a PNG, whatever the original upload was called
    # (the account answers "SOURCE", with no extension), so name the copy as one.
    stem = Path(attributes.get("fileName") or "review").stem or "review"
    return f"{stem}.png", data


def ensure_screenshot(client: Client, sub_id: str | None, source: tuple[str, bytes] | None) -> None:
    if source is None:
        print("  review screenshot: no source available, attach one by hand")
        return
    if sub_id:
        try:
            if client.call("GET", f"/subscriptions/{sub_id}/appStoreReviewScreenshot").get("data"):
                print("  review screenshot: already present")
                return
        except ApiError as error:
            if error.status != 404:
                raise
    file_name, data = source
    if client.dry_run or not sub_id:
        print(f"  would upload review screenshot {file_name} ({len(data)} bytes)")
        return
    reservation = client.call(
        "POST",
        "/subscriptionAppStoreReviewScreenshots",
        body={
            "data": {
                "type": "subscriptionAppStoreReviewScreenshots",
                "attributes": {"fileName": file_name, "fileSize": len(data)},
                "relationships": {"subscription": rel("subscriptions", sub_id)},
            }
        },
    )["data"]
    for operation in (reservation["attributes"] or {}).get("uploadOperations") or []:
        offset, length = operation["offset"], operation["length"]
        request = urllib.request.Request(
            operation["url"],
            data=data[offset : offset + length],
            method=operation.get("method", "PUT"),
            headers={h["name"]: h["value"] for h in operation.get("requestHeaders") or []},
        )
        with urllib.request.urlopen(request, timeout=120):
            pass
    client.call(
        "PATCH",
        f"/subscriptionAppStoreReviewScreenshots/{reservation['id']}",
        body={
            "data": {
                "type": "subscriptionAppStoreReviewScreenshots",
                "id": reservation["id"],
                "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()},
            }
        },
    )
    print(f"  review screenshot: uploaded {file_name}")


# --- commands -------------------------------------------------------------


def run(client: Client, manifest: dict, only: list[str] | None) -> int:
    app_id = find_app(client, manifest["bundle_id"])
    group = find_group(client, app_id, manifest["group_name"])
    existing = subscriptions_in(client, group["id"])
    reference = existing.get(manifest["reference_product_id"])
    if not reference:
        sys.exit(f"Reference product {manifest['reference_product_id']} not found in the group.")
    level = (reference["attributes"] or {}).get("groupLevel") or 1
    territories = all_territories(client)
    screenshot = reference_screenshot(client, reference["id"])
    print(
        f"App {app_id}, group {group['id']} ({manifest['group_name']}), "
        f"reference level {level}, {len(territories)} territories, "
        f"screenshot {'found' if screenshot else 'missing'}"
    )

    for spec in manifest["products"]:
        if only and spec["product_id"] not in only:
            continue
        print(f"\n{spec['product_id']} — {spec['price']} € · {spec['period']} · trial {spec.get('trial') or 'none'}")
        sub = ensure_subscription(client, group["id"], spec, level, existing.get(spec["product_id"]))
        sub_id = sub.get("id")
        ensure_localizations(client, sub_id, manifest["localizations"][spec["kind"]])
        ensure_availability(client, sub_id, territories)
        ensure_prices(client, sub_id, spec, manifest["base_territory"])
        ensure_intro_offer(client, sub_id, spec, territories)
        ensure_screenshot(client, sub_id, screenshot)
    print("\nNothing was written (plan)." if client.dry_run else "\nDone. Run `status`, then `submit`.")
    return 0


def status(client: Client, manifest: dict) -> int:
    app_id = find_app(client, manifest["bundle_id"])
    group = find_group(client, app_id, manifest["group_name"])
    wanted = {p["product_id"] for p in manifest["products"]}
    for product_id, sub in sorted(subscriptions_in(client, group["id"]).items(), key=lambda kv: kv[0] or ""):
        attributes = sub["attributes"] or {}
        mark = "*" if product_id in wanted else " "
        print(f"{mark} {product_id:<26} {attributes.get('state', '?'):<26} level {attributes.get('groupLevel')} {attributes.get('subscriptionPeriod')}")
    print("\n* = product of the price-test manifest. Ready to Submit → run `submit`.")
    return 0


def submit(client: Client, manifest: dict) -> int:
    app_id = find_app(client, manifest["bundle_id"])
    group = find_group(client, app_id, manifest["group_name"])
    subs = subscriptions_in(client, group["id"])
    ready = [p for p, s in subs.items() if (s["attributes"] or {}).get("state") == "READY_TO_SUBMIT"]
    not_ready = [
        p for p in (x["product_id"] for x in manifest["products"])
        if p in subs and (subs[p]["attributes"] or {}).get("state") == "MISSING_METADATA"
    ]
    if not_ready:
        print("Still missing metadata (fix before submitting): " + ", ".join(not_ready))
    if not ready:
        print("Nothing in Ready to Submit.")
        return 1
    print("Submitting the group with: " + ", ".join(sorted(ready)))
    if client.dry_run:
        print("(plan) nothing submitted")
        return 0
    client.call(
        "POST",
        "/subscriptionGroupSubmissions",
        body={
            "data": {
                "type": "subscriptionGroupSubmissions",
                "relationships": {"subscriptionGroup": rel("subscriptionGroups", group["id"])},
            }
        },
    )
    print("Submitted. Apple usually answers within 1 to 3 days; watch `status`.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["plan", "apply", "status", "submit"])
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--only", action="append", help="Limit to one product id (repeatable)")
    parser.add_argument("--dry-run", action="store_true", help="With submit: show what would be submitted")
    args = parser.parse_args()
    manifest = load_manifest(args.manifest)
    client = PatientClient(dry_run=args.command == "plan" or args.dry_run)
    try:
        if args.command in ("plan", "apply"):
            return run(client, manifest, args.only)
        if args.command == "status":
            return status(client, manifest)
        return submit(client, manifest)
    except ApiError as error:
        print(f"App Store Connect refused: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
