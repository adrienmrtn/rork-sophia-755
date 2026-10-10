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


STEP_VERBS = {"stop": ("running", "paused"), "start": ("draft",)}
EXPECTED_AFTER = {"stop": "stopped", "start": "running"}


def parse_steps(text: str) -> list[tuple[str, str]]:
    steps = []
    for raw in filter(None, (part.strip() for part in text.split(","))):
        verb, _, experiment_id = raw.partition(":")
        verb, experiment_id = verb.strip().lower(), experiment_id.strip()
        if verb not in STEP_VERBS or not experiment_id.startswith("exp"):
            raise RevenueCatError(f"bad step {raw!r}: expected stop:<experiment id> or start:<experiment id>")
        steps.append((verb, experiment_id))
    if not steps:
        raise RevenueCatError("no step given: pass e.g. stop:expaa99dcbc5d,start:expc04e8ff651")
    return steps


def switch(api_key: str, steps_text: str, check_only: bool) -> int:
    """Stop and start experiments in the given order, after checking the whole sequence first.

    A stop needs a running or paused experiment, a start needs a draft, and a start is refused if
    another experiment on the same audience would still be running at that point: RevenueCat gives
    each new customer to the first running experiment by priority, so the newcomer would get nobody.
    """
    project_id = resolve_project_id(api_key, os.environ.get("REVENUECAT_PROJECT_ID"))
    steps = parse_steps(steps_text)
    experiments = {e["id"]: e for e in paginate(api_key, f"/projects/{project_id}/experiments")}
    status = {exp_id: e.get("status") for exp_id, e in experiments.items()}
    print(f"Project {project_id}: {len(steps)} steps")
    for verb, exp_id in steps:
        experiment = experiments.get(exp_id)
        if not experiment:
            raise RevenueCatError(f"{verb}:{exp_id}: no such experiment")
        if status[exp_id] not in STEP_VERBS[verb]:
            raise RevenueCatError(f"{verb}:{exp_id} ({experiment['display_name']}): status is {status[exp_id]}, expected {' or '.join(STEP_VERBS[verb])}")
        if verb == "start":
            clash = [
                e["display_name"] for other, e in experiments.items()
                if other != exp_id and status[other] in ("running", "paused") and e.get("audience_id") == experiment.get("audience_id")
            ]
            if clash:
                raise RevenueCatError(f"start:{exp_id} ({experiment['display_name']}): still running on the same audience: {', '.join(clash)}; stop it first")
        status[exp_id] = EXPECTED_AFTER[verb]
        print(f"  ok  {verb:<5} {exp_id}  {experiment['display_name']}  ({experiment.get('status')} -> {status[exp_id]})")
    if check_only:
        print("\nChecked only: nothing was changed.")
        return 0

    print("\nRunning")
    for verb, exp_id in steps:
        request_json("POST", f"/projects/{project_id}/experiments/{exp_id}/actions/{verb}", api_key=api_key, body={})
        after = request_json("GET", f"/projects/{project_id}/experiments/{exp_id}", api_key=api_key)
        stamp = after.get("stopped_at") if verb == "stop" else after.get("started_at")
        print(f"  {verb:<5} {exp_id}  {after.get('display_name')}: status {after.get('status')} (at {stamp})")
        if after.get("status") != EXPECTED_AFTER[verb]:
            raise RevenueCatError(f"{verb}:{exp_id}: status is {after.get('status')}, expected {EXPECTED_AFTER[verb]}; later steps not run")
    print("\nDone.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["plan", "apply", "switch"])
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--steps", default="", help="switch: ordered steps, e.g. stop:expaa99dcbc5d,start:expc04e8ff651")
    parser.add_argument("--check", action="store_true", help="switch: check the steps and change nothing")
    args = parser.parse_args()
    api_key = os.environ.get("REVENUECAT_SECRET_API_KEY", "").strip()
    if not api_key.startswith("sk_"):
        print("REVENUECAT_SECRET_API_KEY is missing or is not a v2 secret key (sk_…).", file=sys.stderr)
        return 2
    try:
        if args.command == "switch":
            return switch(api_key, args.steps, check_only=args.check)
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
        return run(api_key, manifest, dry_run=args.command == "plan")
    except RevenueCatError as error:
        print(f"RevenueCat refused: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
