#!/usr/bin/env python3
"""Align the Google Play prices of the `sophia_pro` subscription on the App Store prices.

Why: the Play base prices were entered as if they excluded tax, so Google added each
country's VAT on top (France 47,99 € instead of 39,99 €, Malta 47,19 € = 39,99 × 1,18) and
converted the rest at its own rates (Poland +40 %, Türkiye +33 %, US +31 % vs iOS). The
App Store customer price of the matching iOS product is the reference, country by country.

Base plans and their iOS reference:

    p1y           <- Sophia_yearly     (annual, 3-day trial offer `freetrial-3d` untouched)
    monthly       <- Sophia_monthly
    annual-promo  <- discount_yearly   (the flash "gift" offer)

Rules, per base plan and Play region:
    * same currency as iOS and iOS cheaper  -> set the Play price to the iOS price
    * same currency, iOS equal or dearer    -> unchanged (this script only lowers prices)
    * different currency or no iOS price    -> unchanged, listed for a later pass
    * a new price below 50 % of the current one is refused (guards against unit mistakes)
Offers, availability, `otherRegionsConfig` and existing subscribers are never touched:
Google keeps current subscribers on their price; only new purchases get the new one.

Subcommands:
    plan     read Play and the App Store prices, print every change. Writes nothing.
    apply    patch the subscription, then read it back and check every new price.

Credentials (environment, never in the repository):
    PLAY_SERVICE_ACCOUNT_JSON   service account key (JSON text) invited in Play Console
    REVENUECAT_SECRET_API_KEY   to read the App Store prices RevenueCat holds per country
    REVENUECAT_PROJECT_ID       optional
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from configure_revenuecat_offering import RevenueCatError, request_json, resolve_project_id  # noqa: E402

PACKAGE = "app.rork.sophia"
SUBSCRIPTION = "sophia_pro"
# Play base plan -> (RevenueCat product id of the iOS reference, its App Store identifier)
REFERENCE = {
    "p1y": ("prodf40359e7e1", "Sophia_yearly"),
    "monthly": ("prodf59fa512ae", "Sophia_monthly"),
    "annual-promo": ("prod87ca86a482", "discount_yearly"),
}
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}"
REGIONS_VERSION = "2022/02"
MIN_RATIO = Decimal("0.5")


class PlayError(RuntimeError):
    pass


# --- Google auth ---------------------------------------------------------------------------

def access_token(service_account_json: str) -> str:
    import jwt  # pyjwt, installed by the workflow

    info = json.loads(service_account_json)
    now = int(time.time())
    assertion = jwt.encode(
        {
            "iss": info["client_email"],
            "scope": "https://www.googleapis.com/auth/androidpublisher",
            "aud": info.get("token_uri", "https://oauth2.googleapis.com/token"),
            "iat": now,
            "exp": now + 3600,
        },
        info["private_key"],
        algorithm="RS256",
        headers={"kid": info.get("private_key_id", "")},
    )
    body = urllib.parse.urlencode(
        {"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion}
    ).encode()
    request = urllib.request.Request(info.get("token_uri", "https://oauth2.googleapis.com/token"), data=body, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read())["access_token"]
    except urllib.error.HTTPError as error:
        raise PlayError(f"Google refused the service account: {error.code} {error.read().decode()[:400]}") from error


def play_call(token: str, method: str, url: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(
        url, data=data, method=method,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            raw = response.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raise PlayError(f"{method} {url} -> {error.code}: {error.read().decode()[:1500]}") from error


# --- prices --------------------------------------------------------------------------------

def money_to_decimal(money: dict) -> Decimal:
    return Decimal(str(money.get("units") or "0")) + Decimal(int(money.get("nanos") or 0)) / Decimal(10**9)


def decimal_to_money(value: Decimal, currency: str) -> dict:
    value = value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    units = int(value)
    nanos = int(((value - units) * Decimal(10**9)).to_integral_value())
    return {"currencyCode": currency, "units": str(units), "nanos": nanos}


def ios_prices(rc_key: str, project_id: str) -> dict[str, dict[str, tuple[Decimal, str]]]:
    """Base plan -> {ISO2 region: (customer price, currency)} for its iOS reference product."""
    out: dict[str, dict[str, tuple[Decimal, str]]] = {}
    for base_plan, (product_id, store_identifier) in REFERENCE.items():
        product = request_json("GET", f"/projects/{project_id}/products/{product_id}", api_key=rc_key)
        if product.get("store_identifier") != store_identifier:
            raise PlayError(f"{product_id} is {product.get('store_identifier')!r}, expected {store_identifier!r}")
        state = request_json("GET", f"/projects/{project_id}/products/{product_id}/store_state", api_key=rc_key)
        territory_prices = ((state.get("common") or {}).get("pricing") or {}).get("territory_prices") or {}
        if len(territory_prices) < 150:
            raise PlayError(f"only {len(territory_prices)} App Store prices for {store_identifier}; refusing to plan on partial data")
        out[base_plan] = {
            region: (Decimal(price["amount_micros"]) / Decimal(10**6), price["currency"])
            for region, price in territory_prices.items()
        }
    return out


def plan_changes(subscription: dict, reference: dict[str, dict[str, tuple[Decimal, str]]]) -> tuple[dict, list[str]]:
    """Return ({base plan: {region: (old, new, currency)}}, notes) without modifying anything."""
    changes: dict[str, dict[str, tuple[Decimal, Decimal, str]]] = {}
    notes: list[str] = []
    plans = {bp["basePlanId"]: bp for bp in subscription.get("basePlans") or []}
    for base_plan in REFERENCE:
        if base_plan not in plans:
            raise PlayError(f"base plan {base_plan!r} not found in {SUBSCRIPTION}; found {sorted(plans)}")
        ios = reference[base_plan]
        changes[base_plan] = {}
        skipped = {"already at or below iOS": [], "different currency": [], "no iOS price": []}
        for config in plans[base_plan].get("regionalConfigs") or []:
            region, money = config["regionCode"], config.get("price") or {}
            current, currency = money_to_decimal(money), money.get("currencyCode")
            if region not in ios:
                skipped["no iOS price"].append(region)
                continue
            target, ios_currency = ios[region]
            if ios_currency != currency:
                skipped["different currency"].append(f"{region}({currency}/{ios_currency})")
                continue
            if target >= current:
                skipped["already at or below iOS"].append(region)
                continue
            if target < current * MIN_RATIO:
                raise PlayError(f"{base_plan} {region}: {current} -> {target} {currency} is below 50 % of the current price; refusing")
            changes[base_plan][region] = (current, target, currency)
        for reason, regions in skipped.items():
            if regions:
                notes.append(f"{base_plan}: unchanged, {reason} ({len(regions)}): {', '.join(regions)}")
    return changes, notes


def print_changes(changes: dict, notes: list[str]) -> None:
    for base_plan, regions in changes.items():
        print(f"\n{base_plan}: {len(regions)} price(s) lowered to the App Store price")
        for region, (old, new, currency) in sorted(regions.items()):
            print(f"  {region}  {old:>12} -> {new:>12} {currency:<4} ({(new / old - 1) * 100:+.0f} %)")
    print()
    for note in notes:
        print(note)


def apply_changes(token: str, subscription: dict, changes: dict) -> dict:
    for base_plan in subscription.get("basePlans") or []:
        regions = changes.get(base_plan["basePlanId"]) or {}
        for config in base_plan.get("regionalConfigs") or []:
            if config["regionCode"] in regions:
                _, new, currency = regions[config["regionCode"]]
                config["price"] = decimal_to_money(new, currency)
    query = urllib.parse.urlencode({
        "updateMask": "basePlans",
        "regionsVersion.version": REGIONS_VERSION,
        "latencyTolerance": "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE",
    })
    return play_call(token, "PATCH", f"{API}/subscriptions/{SUBSCRIPTION}?{query}", subscription)


def verify(subscription: dict, changes: dict) -> int:
    wrong = []
    plans = {bp["basePlanId"]: bp for bp in subscription.get("basePlans") or []}
    for base_plan, regions in changes.items():
        configs = {c["regionCode"]: c for c in plans[base_plan].get("regionalConfigs") or []}
        for region, (_, new, currency) in regions.items():
            got = money_to_decimal((configs.get(region) or {}).get("price") or {})
            if got != new.quantize(Decimal("0.01")):
                wrong.append(f"{base_plan} {region}: {got} instead of {new} {currency}")
    if wrong:
        print("Read back: MISMATCH\n  " + "\n  ".join(wrong))
        return 1
    print(f"Read back: all {sum(len(r) for r in changes.values())} new prices are in place.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["plan", "apply"])
    args = parser.parse_args()
    service_account = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON", "").strip()
    rc_key = os.environ.get("REVENUECAT_SECRET_API_KEY", "").strip()
    if not service_account.startswith("{"):
        print("PLAY_SERVICE_ACCOUNT_JSON is missing or is not the JSON key of a service account.", file=sys.stderr)
        return 2
    if not rc_key.startswith("sk_"):
        print("REVENUECAT_SECRET_API_KEY is missing.", file=sys.stderr)
        return 2
    try:
        print(f"Service account: {json.loads(service_account).get('client_email')}")
        token = access_token(service_account)
        subscription = play_call(token, "GET", f"{API}/subscriptions/{SUBSCRIPTION}")
        print(f"Play {PACKAGE} / {SUBSCRIPTION}: base plans {[bp['basePlanId'] for bp in subscription.get('basePlans') or []]}")
        project_id = resolve_project_id(rc_key, os.environ.get("REVENUECAT_PROJECT_ID"))
        changes, notes = plan_changes(subscription, ios_prices(rc_key, project_id))
        print_changes(changes, notes)
        if args.command == "plan":
            print("\nNothing was written (plan).")
            return 0
        if not any(changes.values()):
            print("\nNothing to change.")
            return 0
        apply_changes(token, subscription, changes)
        return verify(play_call(token, "GET", f"{API}/subscriptions/{SUBSCRIPTION}"), changes)
    except (PlayError, RevenueCatError) as error:
        print(f"Refused: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
