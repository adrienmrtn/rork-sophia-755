#!/usr/bin/env python3
"""Create the price-test audiences and draft experiments in RevenueCat.

Reads the ``audiences`` and ``experiments`` sections of
``appstore/subscriptions/price_tests.json`` and, through the RevenueCat REST API
v2:

    plan     previews every audience (how many customers it matches today),
             resolves the offerings, and lists what `apply` would create. Writes
             nothing.
    apply    creates the audiences that are missing (matched by name) and the
             experiments that are missing (matched by display name), as DRAFTS.
             Idempotent: nothing is created twice, nothing is started, nothing
             is deleted.

An audience is "country is any of <list> AND platform is <platform> AND app
version >= <min_app_version>": the price tests run on iOS only until the Play
base plans exist, so Android keeps the current offering, and only on builds that
sell on every paywall the offering RevenueCat serves (1.1.7, the R1 fix; 1.1.6
showed the variant's price on the course and quiz paywalls but charged 39,99 €).
The five country lists are disjoint, which is what lets the five experiments run
at the same time.

Starting an experiment has no documented endpoint: on the day Apple approves the
products, open each draft in the dashboard and press Start.

Permissions needed on REVENUECAT_SECRET_API_KEY, beyond the catalogue ones:
    audiences:audiences:read_write
    project_configuration:experiments:read_write
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
VARIANT_KEYS = ("offering_b_id", "offering_c_id", "offering_d_id")


def rules_for(spec: dict) -> dict:
    conditions = [{"field": "country", "operator": "isAnyOf", "value": ",".join(spec["countries"])}]
    if spec.get("platform"):
        conditions.append({"field": "platform", "operator": "is", "value": spec["platform"]})
    # RevenueCat compares versions numerically (1.1.10 >= 1.1.7), checked on the account.
    if spec.get("min_app_version"):
        conditions.append({"field": "appVersion", "operator": "greaterThanOrEqual", "value": spec["min_app_version"]})
    return {"groups": [{"conditions": conditions}]}


def preview(api_key: str, project_id: str, rules: dict) -> str:
    result = request_json("POST", f"/projects/{project_id}/audiences/actions/preview", api_key=api_key, body={"rules": rules})
    stats = (result or {}).get("stats") or result
    if isinstance(stats, dict):
        keys = [k for k in ("total_customers", "customers", "count", "total", "active_subscribers", "total_spent") if k in stats]
        if keys:
            return ", ".join(f"{k}={stats[k]}" for k in keys)
    return json.dumps(stats, ensure_ascii=False)[:200]


def experiment_body(spec: dict, settings: dict, audience_id: str | None, offerings: dict[str, dict]) -> dict:
    missing = [k for k in [spec["control"], *spec["treatments"]] if k not in offerings]
    if missing:
        raise RevenueCatError(f"offerings not found for experiment {spec['name']!r}: {', '.join(missing)}")
    if len(spec["treatments"]) > 3:
        raise RevenueCatError(f"experiment {spec['name']!r}: RevenueCat allows at most 3 treatments")
    body: dict[str, Any] = {
        "display_name": spec["name"],
        "experiment_type": spec.get("type", "other"),
        "enrollment_mode": settings.get("enrollment_mode", "only_new"),
        "enrollment_percentage": int(settings.get("enrollment_percentage", 100)),
        "offering_a_id": offerings[spec["control"]]["id"],
        "primary_metric": settings.get("primary_metric", "realized_ltv_per_customer"),
        "secondary_metrics": settings.get("secondary_metrics", []),
        "notes": spec.get("notes", ""),
    }
    for key, lookup in zip(VARIANT_KEYS, spec["treatments"]):
        body[key] = offerings[lookup]["id"]
    if audience_id:
        body["audience_id"] = audience_id
    return body


def run(api_key: str, manifest: dict, dry_run: bool) -> int:
    project_id = resolve_project_id(api_key, os.environ.get("REVENUECAT_PROJECT_ID"))
    audiences = {a["name"]: a for a in paginate(api_key, f"/projects/{project_id}/audiences")}
    experiments = {e["display_name"]: e for e in paginate(api_key, f"/projects/{project_id}/experiments")}
    offerings = {o["lookup_key"]: o for o in paginate(api_key, f"/projects/{project_id}/offerings")}
    settings = manifest.get("experiment_settings", {})
    print(f"Project {project_id}: {len(audiences)} audiences, {len(experiments)} experiments, {len(offerings)} offerings")

    print("\nAudiences")
    audience_ids: dict[str, str | None] = {}
    for spec in manifest.get("audiences", []):
        rules = rules_for(spec)
        existing = audiences.get(spec["name"])
        if existing:
            audience_ids[spec["name"]] = existing["id"]
            same = existing.get("rules") == rules
            print(f"  {spec['name']}: exists ({existing['id']}){'' if same else ' — rules differ from the manifest, left untouched'}")
            continue
        try:
            matched = preview(api_key, project_id, rules)
        except RevenueCatError as error:
            matched = f"preview refused: {error}"
        if dry_run:
            print(f"  {spec['name']}: would create — {len(spec['countries'])} countries, platform {spec.get('platform') or 'any'}, app >= {spec.get('min_app_version') or 'any'}; today: {matched}")
            audience_ids[spec["name"]] = None
            continue
        created = request_json("POST", f"/projects/{project_id}/audiences", api_key=api_key, body={"name": spec["name"], "rules": rules})
        audiences[spec["name"]] = created
        audience_ids[spec["name"]] = created["id"]
        print(f"  {spec['name']}: created {created['id']} ({len(spec['countries'])} countries; today: {matched})")

    print("\nExperiments (drafts)")
    for spec in manifest.get("experiments", []):
        existing = experiments.get(spec["name"])
        if existing:
            print(f"  {spec['name']}: exists ({existing['id']}, status {existing.get('status')})")
            continue
        audience_id = audience_ids.get(spec["audience"])
        variants = " / ".join([spec["control"], *spec["treatments"]])
        if dry_run:
            problems = [k for k in [spec["control"], *spec["treatments"]] if k not in offerings]
            note = f" — MISSING offerings: {', '.join(problems)}" if problems else ""
            print(f"  {spec['name']}: would create — {spec.get('type', 'other')}, audience {spec['audience']}, {variants}{note}")
            continue
        if audience_id is None:
            raise RevenueCatError(f"audience {spec['audience']!r} has no id; create audiences first")
        body = experiment_body(spec, settings, audience_id, offerings)
        created = request_json("POST", f"/projects/{project_id}/experiments", api_key=api_key, body=body)
        experiments[spec["name"]] = created
        print(f"  {spec['name']}: created {created['id']} (status {created.get('status')}) — {variants}")

    print("\nNothing was written (plan)." if dry_run else "\nDone. Nothing is running: press Start on each draft the day Apple approves the products.")
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
