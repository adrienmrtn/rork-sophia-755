#!/usr/bin/env python3
"""Mirror the price-test manifest into RevenueCat (products, entitlement, offerings).

Reads ``appstore/subscriptions/price_tests.json`` and, through the RevenueCat
REST API v2, makes sure that:

    1. every product an offering references exists in RevenueCat for the App
       Store app and for the Play Store app (store identifiers from the
       manifest), older products reused by an offering included;
    2. every product the offerings reference, new or existing, is attached to the
       `premium` entitlement — the audit found two approved products that were not;
    3. every offering of the manifest exists, with its packages, each package
       attached to the App Store, Play Store and Test Store products that exist.

Two subcommands:

    plan     print what `apply` would create or attach. Writes nothing.
    apply    do it. Idempotent: nothing is created twice, nothing is deleted.

Experiments and audiences are not in RevenueCat's API: they stay a dashboard
step (docs/plan-ab-tests-prix.md § 6). Test Store products are attached when
they exist, never created here.

Credentials: REVENUECAT_SECRET_API_KEY (v2 secret key with write access), and
optionally REVENUECAT_PROJECT_ID.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from configure_revenuecat_offering import (  # noqa: E402
    RevenueCatError,
    paginate,
    request_json,
    resolve_project_id,
)

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "appstore" / "subscriptions" / "price_tests.json"
PACKAGE_NAMES = {"$rc_annual": ("Annual", 2), "$rc_monthly": ("Monthly", 1), "$rc_weekly": ("Weekly", 1)}


def apps_by_type(api_key: str, project_id: str) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for app in paginate(api_key, f"/projects/{project_id}/apps"):
        out.setdefault(app["type"], app)
    return out


def product_index(api_key: str, project_id: str) -> dict[tuple[str, str], dict[str, Any]]:
    """(app_id, store_identifier) -> product."""
    return {
        (p["app_id"], p["store_identifier"]): p
        for p in paginate(api_key, f"/projects/{project_id}/products")
    }


def store_ids(manifest: dict, ios_id: str) -> dict[str, str]:
    """iOS product id -> {app_store, play_store, test_store} store identifiers."""
    for spec in manifest["products"]:
        if spec["product_id"] == ios_id:
            return {"app_store": ios_id, "play_store": spec.get("play"), "test_store": spec.get("test_store")}
    known = manifest.get("existing_products", {}).get(ios_id)
    if known:
        return {"app_store": ios_id, "play_store": known.get("play"), "test_store": known.get("test_store")}
    return {"app_store": ios_id}


def ensure_product(api_key: str, project_id: str, products: dict, app: dict, store_identifier: str, display_name: str, dry_run: bool) -> str | None:
    key = (app["id"], store_identifier)
    if key in products:
        return products[key]["id"]
    if dry_run:
        print(f"  would create product {store_identifier} on {app['type']} ({app['name']})")
        return None
    created = request_json(
        "POST",
        f"/projects/{project_id}/products",
        api_key=api_key,
        body={"store_identifier": store_identifier, "app_id": app["id"], "type": "subscription", "display_name": display_name},
    )
    products[key] = created
    print(f"  created product {store_identifier} on {app['type']} -> {created['id']}")
    return created["id"]


def ensure_entitlement(api_key: str, project_id: str, lookup_key: str) -> dict[str, Any]:
    for entitlement in paginate(api_key, f"/projects/{project_id}/entitlements"):
        if entitlement.get("lookup_key") == lookup_key:
            return entitlement
    raise RevenueCatError(f"Entitlement {lookup_key!r} not found.")


def attached_product_ids(api_key: str, project_id: str, entitlement_id: str) -> set[str]:
    return {p["id"] for p in paginate(api_key, f"/projects/{project_id}/entitlements/{entitlement_id}/products")}


def ensure_attached(api_key: str, project_id: str, entitlement: dict, product_ids: list[str], dry_run: bool) -> None:
    have = attached_product_ids(api_key, project_id, entitlement["id"])
    missing = [p for p in product_ids if p not in have]
    if not missing:
        print(f"  entitlement {entitlement['lookup_key']}: all {len(product_ids)} products attached")
        return
    if dry_run:
        print(f"  would attach {len(missing)} products to entitlement {entitlement['lookup_key']}")
        return
    request_json(
        "POST",
        f"/projects/{project_id}/entitlements/{entitlement['id']}/actions/attach_products",
        api_key=api_key,
        body={"product_ids": missing},
    )
    print(f"  entitlement {entitlement['lookup_key']}: attached {len(missing)} products")


def ensure_offering(api_key: str, project_id: str, offerings: dict[str, dict], spec: dict, dry_run: bool) -> dict | None:
    if spec["lookup_key"] in offerings:
        return offerings[spec["lookup_key"]]
    if dry_run:
        print(f"  would create offering {spec['lookup_key']}")
        return None
    created = request_json(
        "POST",
        f"/projects/{project_id}/offerings",
        api_key=api_key,
        body={"lookup_key": spec["lookup_key"], "display_name": spec["display_name"], "metadata": spec.get("metadata") or {}},
    )
    offerings[spec["lookup_key"]] = created
    print(f"  created offering {spec['lookup_key']} -> {created['id']}")
    return created


def ensure_package(api_key: str, project_id: str, offering: dict, lookup_key: str, product_ids: list[str], dry_run: bool) -> None:
    packages = {p["lookup_key"]: p for p in paginate(api_key, f"/projects/{project_id}/offerings/{offering['id']}/packages")}
    package = packages.get(lookup_key)
    if not package:
        if dry_run:
            print(f"    would create package {lookup_key} with {len(product_ids)} products")
            return
        name, position = PACKAGE_NAMES.get(lookup_key, (lookup_key, 9))
        package = request_json(
            "POST",
            f"/projects/{project_id}/offerings/{offering['id']}/packages",
            api_key=api_key,
            body={"lookup_key": lookup_key, "display_name": name, "position": position},
        )
        print(f"    created package {lookup_key}")
    # Each item is {"product": {...}, "eligibility_criteria": ...}, not a bare product.
    have = {
        (item.get("product") or item).get("id")
        for item in paginate(api_key, f"/projects/{project_id}/packages/{package['id']}/products")
    }
    missing = [p for p in product_ids if p not in have]
    if not missing:
        print(f"    package {lookup_key}: {len(product_ids)} products attached")
        return
    if dry_run:
        print(f"    would attach {len(missing)} products to package {lookup_key}")
        return
    request_json(
        "POST",
        f"/projects/{project_id}/packages/{package['id']}/actions/attach_products",
        api_key=api_key,
        body={"products": [{"product_id": p, "eligibility_criteria": "all"} for p in missing]},
    )
    print(f"    package {lookup_key}: attached {len(missing)} products")


def run(api_key: str, manifest: dict, dry_run: bool) -> int:
    project_id = resolve_project_id(api_key, os.environ.get("REVENUECAT_PROJECT_ID"))
    apps = apps_by_type(api_key, project_id)
    products = product_index(api_key, project_id)
    entitlement = ensure_entitlement(api_key, project_id, manifest["entitlement"])
    app_summary = ", ".join(f"{store}={app['id']}" for store, app in apps.items())
    print(f"Project {project_id}: apps {app_summary}; entitlement {entitlement['id']}")

    # 1. every product the offerings reference, on App Store and Play Store.
    # That covers the manifest's new products and the older ones an offering
    # reuses on one store only (Sophia_yearly_5999 and Sophia_monthly_notrial
    # had no Play product, so their Android variants would have had no price).
    print("\nProducts")
    names = {spec["product_id"]: spec["name"] for spec in manifest["products"]}
    referenced_ids = sorted(
        {ios_id for offering in manifest["offerings"] for ios_id in offering["packages"].values()}
        # Every product of the manifest too, offered or not: Apple lets a subscriber switch to
        # any product of the group from their settings, and one RevenueCat does not know, or
        # that does not unlock `premium`, would cost them their access.
        | {spec["product_id"] for spec in manifest["products"]}
    )
    for ios_id in referenced_ids:
        ids = store_ids(manifest, ios_id)
        for store in ("app_store", "play_store"):
            app = apps.get(store)
            if app and ids.get(store):
                ensure_product(api_key, project_id, products, app, ids[store], names.get(ios_id, ios_id), dry_run)

    # 2. everything the offerings reference is attached to the entitlement
    print("\nEntitlement")
    referenced: set[str] = {spec["product_id"] for spec in manifest["products"]}
    for offering in manifest["offerings"]:
        referenced.update(offering["packages"].values())
    to_attach: list[str] = []
    unknown: list[str] = []
    for ios_id in sorted(referenced):
        ids = store_ids(manifest, ios_id)
        for store, store_identifier in ids.items():
            app = apps.get(store)
            if not app or not store_identifier:
                continue
            product = products.get((app["id"], store_identifier))
            if product:
                to_attach.append(product["id"])
            elif store == "app_store":
                unknown.append(store_identifier)
    if unknown:
        print("  not in RevenueCat yet (created above on apply, or still to import): " + ", ".join(unknown))
    ensure_attached(api_key, project_id, entitlement, to_attach, dry_run)

    # 3. offerings and packages
    print("\nOfferings")
    offerings = {o["lookup_key"]: o for o in paginate(api_key, f"/projects/{project_id}/offerings")}
    for spec in manifest["offerings"]:
        print(f"  {spec['lookup_key']}")
        offering = ensure_offering(api_key, project_id, offerings, spec, dry_run)
        for package_key, ios_id in spec["packages"].items():
            ids = store_ids(manifest, ios_id)
            product_ids = []
            for store, store_identifier in ids.items():
                app = apps.get(store)
                if app and store_identifier and (app["id"], store_identifier) in products:
                    product_ids.append(products[(app["id"], store_identifier)]["id"])
            if offering is None:
                print(f"    would create package {package_key} ({ios_id}: {len(product_ids)} store products known)")
                continue
            ensure_package(api_key, project_id, offering, package_key, product_ids, dry_run)

    print("\nNothing was written (plan)." if dry_run else "\nDone. Experiments and audiences: RevenueCat dashboard (plan § 6).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["plan", "apply"])
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    args = parser.parse_args()
    api_key = os.environ.get("REVENUECAT_SECRET_API_KEY", "").strip()
    if not api_key.startswith("sk_"):
        print("REVENUECAT_SECRET_API_KEY is missing or is not a v2 secret key (sk_…).", file=sys.stderr)
        return 2
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    try:
        return run(api_key, manifest, dry_run=args.command == "plan")
    except RevenueCatError as error:
        print(f"RevenueCat refused: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
