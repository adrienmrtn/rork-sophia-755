#!/usr/bin/env python3
"""Configure a RevenueCat offering (packages + paywall) via the v2 REST API.

Used to finish setup for context-specific paywalls such as `debloquer_cours`,
which the iOS app loads by offering identifier in `SophiaPaywallView`.

Requirements:
  - REVENUECAT_SECRET_API_KEY: v2 secret key (starts with `sk_`)
  - Optional REVENUECAT_PROJECT_ID: skips project auto-discovery

Example:
  REVENUECAT_SECRET_API_KEY=sk_... python3 scripts/configure_revenuecat_offering.py \\
      --offering debloquer_cours --reference quizz
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any

API_BASE = "https://api.revenuecat.com/v2"
PUBLIC_IOS_KEY = "appl_uGsIMbbdKdSEmAoLNJFcfveiQgC"

# RC standard package lookup keys used across Sophia offerings.
DEFAULT_PACKAGES = [
    {
        "lookup_key": "$rc_monthly",
        "display_name": "Monthly",
        "position": 1,
        "store_identifier": "Sophia_monthly",
    },
    {
        "lookup_key": "$rc_annual",
        "display_name": "Annual",
        "position": 2,
        "store_identifier": "Sophia_yearly",
    },
]

# Course-unlock headline overrides (cloned from `quizz` paywall, key iuFGR2yPjh).
COURSE_UNLOCK_TITLES = {
    "fr_FR": "Débloquez gratuitement ce cours",
    "en_US": "Unlock this course for free",
    "es_ES": "Desbloquea este curso gratis",
    "de_DE": "Schalte diesen Kurs kostenlos frei",
    "pt_PT": "Desbloqueia este curso grátis",
    "it_IT": "Sblocca questo corso gratis",
    # Step 7 — 9 new app languages (RC paywall localization keys).
    "tr_TR": "Bu dersi ücretsiz aç",
    "pl_PL": "Odblokuj ten kurs za darmo",
    "ro_RO": "Deblochează acest curs gratuit",
    "nl_NL": "Ontgrendel deze cursus gratis",
    "el_GR": "Ξεκλείδωσε αυτό το μάθημα δωρεάν",
    "sv_SE": "Lås upp den här kursen gratis",
    "hu_HU": "Oldd fel ingyen ezt a tanfolyamot",
    "bg_BG": "Отключи този курс безплатно",
    "cs_CZ": "Odemkni tento kurz zdarma",
}


class RevenueCatError(RuntimeError):
    pass


def request_json(
    method: str,
    path: str,
    *,
    api_key: str,
    body: dict[str, Any] | None = None,
) -> Any:
    url = f"{API_BASE}{path}"
    data = None
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    if body is not None:
        data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode()
        raise RevenueCatError(f"{method} {path} -> {exc.code}: {detail}") from exc


def paginate(api_key: str, path: str) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    next_path = path
    while next_path:
        payload = request_json("GET", next_path, api_key=api_key)
        items.extend(payload.get("items", []))
        next_url = payload.get("next_page")
        next_path = next_url.replace(API_BASE, "") if next_url else None
    return items


def resolve_project_id(api_key: str, explicit: str | None) -> str:
    if explicit:
        return explicit
    projects = request_json("GET", "/projects", api_key=api_key).get("items", [])
    if not projects:
        raise RevenueCatError("No RevenueCat projects visible for this API key.")
    if len(projects) == 1:
        return projects[0]["id"]
    names = ", ".join(f"{p['id']} ({p.get('name', 'unnamed')})" for p in projects)
    raise RevenueCatError(
        "Multiple projects found; set REVENUECAT_PROJECT_ID. Available: " + names
    )


def offering_by_lookup(offerings: list[dict[str, Any]], lookup_key: str) -> dict[str, Any]:
    for offering in offerings:
        if offering.get("lookup_key") == lookup_key:
            return offering
    raise RevenueCatError(f"Offering '{lookup_key}' not found.")


def product_id_for_store(products: list[dict[str, Any]], store_identifier: str) -> str:
    for product in products:
        if product.get("store_identifier") == store_identifier:
            return product["id"]
    raise RevenueCatError(f"Product with store identifier '{store_identifier}' not found.")


def ensure_packages(
    api_key: str,
    project_id: str,
    offering: dict[str, Any],
    packages_spec: list[dict[str, Any]],
    products: list[dict[str, Any]],
) -> None:
    offering_id = offering["id"]
    existing = paginate(api_key, f"/projects/{project_id}/offerings/{offering_id}/packages")
    existing_keys = {pkg.get("lookup_key") for pkg in existing}

    for spec in packages_spec:
        lookup_key = spec["lookup_key"]
        if lookup_key in existing_keys:
            print(f"  package {lookup_key}: already present")
            continue

        created = request_json(
            "POST",
            f"/projects/{project_id}/offerings/{offering_id}/packages",
            api_key=api_key,
            body={
                "lookup_key": lookup_key,
                "display_name": spec["display_name"],
                "position": spec["position"],
            },
        )
        package_id = created["id"]
        product_id = product_id_for_store(products, spec["store_identifier"])
        request_json(
            "POST",
            f"/projects/{project_id}/packages/{package_id}/actions/attach_products",
            api_key=api_key,
            body={"products": [{"product_id": product_id, "eligibility_criteria": "all"}]},
        )
        print(f"  package {lookup_key}: created and attached to {spec['store_identifier']}")


def fetch_public_paywall_components(reference_offering: str) -> dict[str, Any]:
    req = urllib.request.Request(
        "https://api.revenuecat.com/v1/subscribers/$RCAnonymousID:configure-script/offerings",
        headers={
            "Authorization": f"Bearer {PUBLIC_IOS_KEY}",
            "X-Platform": "ios",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        payload = json.load(resp)
    for offering in payload.get("offerings", []):
        if offering.get("identifier") == reference_offering:
            components = offering.get("paywall_components")
            if components:
                return components
            break
    raise RevenueCatError(
        f"Reference offering '{reference_offering}' has no published paywall components."
    )


def customize_course_unlock_titles(components: dict[str, Any]) -> dict[str, Any]:
    cloned = json.loads(json.dumps(components))
    localizations = cloned.setdefault("components_localizations", {})
    for locale, title in COURSE_UNLOCK_TITLES.items():
        locale_payload = localizations.setdefault(locale, {})
        locale_payload["iuFGR2yPjh"] = title
    if "fr_FR" in localizations:
        cloned["default_locale"] = "fr_FR"
    return cloned


def ensure_paywall(
    api_key: str,
    project_id: str,
    offering: dict[str, Any],
    reference_components: dict[str, Any],
) -> None:
    offering_id = offering["id"]
    paywall_id = offering.get("paywall_id")

    if not paywall_id:
        created = request_json(
            "POST",
            f"/projects/{project_id}/paywalls",
            api_key=api_key,
            body={"offering_id": offering_id, "automatically_scale_font_size": True},
        )
        paywall_id = created["id"]
        print(f"  paywall: created draft {paywall_id}")
    else:
        print(f"  paywall: reusing {paywall_id}")

    paywall = request_json(
        "GET",
        f"/projects/{project_id}/paywalls/{paywall_id}?expand=components",
        api_key=api_key,
    )
    draft = paywall.get("components", {}).get("draft") or {}
    revision = draft.get("revision", 1)

    customized = customize_course_unlock_titles(reference_components)
    request_json(
        "PATCH",
        f"/projects/{project_id}/paywalls/{paywall_id}",
        api_key=api_key,
        body={
            "revision": revision,
            "components_config": customized["components_config"],
            "components_localizations": customized["components_localizations"],
            "default_locale": customized.get("default_locale", "fr_FR"),
            "automatically_scale_font_size": customized.get(
                "automatically_scale_font_size", True
            ),
        },
    )
    print("  paywall: draft updated with course-unlock copy")

    request_json(
        "POST",
        f"/projects/{project_id}/paywalls/{paywall_id}/versions",
        api_key=api_key,
        body={"name": "Configured by configure_revenuecat_offering.py"},
    )
    print("  paywall: published new version")


def verify_public_offering(offering_lookup: str) -> dict[str, Any]:
    req = urllib.request.Request(
        "https://api.revenuecat.com/v1/subscribers/$RCAnonymousID:verify-script/offerings",
        headers={
            "Authorization": f"Bearer {PUBLIC_IOS_KEY}",
            "X-Platform": "ios",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        payload = json.load(resp)
    for offering in payload.get("offerings", []):
        if offering.get("identifier") == offering_lookup:
            return {
                "identifier": offering_lookup,
                "packages": [p["identifier"] for p in offering.get("packages", [])],
                "has_paywall": offering.get("paywall_components") is not None,
            }
    return {"identifier": offering_lookup, "packages": [], "has_paywall": False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--offering", default="debloquer_cours")
    parser.add_argument("--reference", default="quizz")
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()

    if args.verify_only:
        status = verify_public_offering(args.offering)
        print(json.dumps(status, indent=2))
        return 0 if status["packages"] and status["has_paywall"] else 1

    api_key = os.environ.get("REVENUECAT_SECRET_API_KEY", "").strip()
    if not api_key or api_key.startswith("http"):
        print(
            "REVENUECAT_SECRET_API_KEY is missing or invalid (expected v2 secret key starting with sk_).",
            file=sys.stderr,
        )
        return 2

    project_id = resolve_project_id(api_key, os.environ.get("REVENUECAT_PROJECT_ID"))
    offerings = paginate(api_key, f"/projects/{project_id}/offerings")
    products = paginate(api_key, f"/projects/{project_id}/products")

    target = offering_by_lookup(offerings, args.offering)
    reference = offering_by_lookup(offerings, args.reference)

    print(f"Project: {project_id}")
    print(f"Target offering: {target['lookup_key']} ({target['id']})")
    print(f"Reference offering: {reference['lookup_key']} ({reference['id']})")

    print("Ensuring packages…")
    ensure_packages(api_key, project_id, target, DEFAULT_PACKAGES, products)

    print("Ensuring paywall…")
    reference_components = fetch_public_paywall_components(args.reference)
    ensure_paywall(api_key, project_id, target, reference_components)

    status = verify_public_offering(args.offering)
    print("Verification:", json.dumps(status, indent=2))
    if not status["packages"] or not status["has_paywall"]:
        print("Offering is still incomplete after configuration.", file=sys.stderr)
        return 1

    print(f"Offering '{args.offering}' is ready.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
