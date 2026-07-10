#!/usr/bin/env python3
"""Generate a paywall funnel report from Mixpanel (view → purchase by context).

Requires a Mixpanel Service Account (Project Settings → Service Accounts):
  export MIXPANEL_SERVICE_ACCOUNT_USERNAME="..."
  export MIXPANEL_SERVICE_ACCOUNT_SECRET="..."
  export MIXPANEL_PROJECT_ID="..."   # numeric project id from Mixpanel settings

Optional:
  export MIXPANEL_WORKSPACE_ID="..." # only if your project uses Data Views
  --from-date / --to-date (default: last 90 days)

Example:
  python3 scripts/mixpanel_paywall_funnel_report.py
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, timedelta

API_BASE = "https://mixpanel.com/api/query/jql"
CONTEXTS = [
    "fin_onboarding",
    "quizz",
    "debloquer_cours",
    "offre_discount",
]


def jql_request(script: str, project_id: str, username: str, secret: str, workspace_id: str | None) -> list:
    params = {"project_id": project_id}
    if workspace_id:
        params["workspace_id"] = workspace_id
    url = f"{API_BASE}?{urllib.parse.urlencode(params)}"
    body = urllib.parse.urlencode({"script": script}).encode()
    auth = base64.b64encode(f"{username}:{secret}".encode()).decode()
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Basic {auth}",
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode()
        raise RuntimeError(f"Mixpanel JQL failed ({exc.code}): {detail}") from exc


def counts_by_context(from_date: str, to_date: str, event: str) -> dict[str, int]:
    project_id = os.environ["MIXPANEL_PROJECT_ID"]
    username = os.environ["MIXPANEL_SERVICE_ACCOUNT_USERNAME"]
    secret = os.environ["MIXPANEL_SERVICE_ACCOUNT_SECRET"]
    workspace_id = os.environ.get("MIXPANEL_WORKSPACE_ID")

    script = f"""
function main() {{
  return Events({{
    from_date: "{from_date}",
    to_date: "{to_date}",
    event_selectors: [{{event: "{event}"}}]
  }}).groupBy(["properties.context"], mixpanel.reducer.count());
}}
"""
    rows = jql_request(script, project_id, username, secret, workspace_id)
    result: dict[str, int] = {}
    for row in rows:
        key = row.get("key", [None])[0]
        value = row.get("value", 0)
        if key:
            result[str(key)] = int(value)
    return result


def funnel_users(from_date: str, to_date: str, context: str) -> dict[str, int]:
    """Users who viewed then purchased within the date window (same context)."""
    project_id = os.environ["MIXPANEL_PROJECT_ID"]
    username = os.environ["MIXPANEL_SERVICE_ACCOUNT_USERNAME"]
    secret = os.environ["MIXPANEL_SERVICE_ACCOUNT_SECRET"]
    workspace_id = os.environ.get("MIXPANEL_WORKSPACE_ID")

    script = f"""
function main() {{
  var viewed = Events({{
    from_date: "{from_date}",
    to_date: "{to_date}",
    event_selectors: [{{
      event: "paywall_viewed",
      selector: 'properties["context"] == "{context}"'
    }}]
  }}).groupByUser(mixpanel.reducer.null());

  var purchased = Events({{
    from_date: "{from_date}",
    to_date: "{to_date}",
    event_selectors: [{{
      event: "purchase_completed",
      selector: 'properties["context"] == "{context}"'
    }}]
  }}).groupByUser(mixpanel.reducer.null());

  var viewedUsers = viewed.map(function(row) {{ return row.key[0]; }});
  var purchasedUsers = purchased.map(function(row) {{ return row.key[0]; }});

  var viewedSet = {{}};
  viewedUsers.forEach(function(u) {{ viewedSet[u] = true; }});

  var converted = 0;
  purchasedUsers.forEach(function(u) {{
    if (viewedSet[u]) converted += 1;
  }});

  return [{{
    viewed_users: viewedUsers.length,
    purchase_users: purchasedUsers.length,
    converted_users: converted
  }}];
}}
"""
    rows = jql_request(script, project_id, username, secret, workspace_id)
    if not rows:
        return {"viewed_users": 0, "purchase_users": 0, "converted_users": 0}
    return rows[0]


def print_report(from_date: str, to_date: str) -> None:
    views = counts_by_context(from_date, to_date, "paywall_viewed")
    dismissals = counts_by_context(from_date, to_date, "paywall_dismissed")
    purchases = counts_by_context(from_date, to_date, "purchase_completed")

    print(f"# Rapport paywall Sophia ({from_date} → {to_date})\n")
    print("| Contexte | Vues | Fermetures | Achats | Conv. vue→achat |")
    print("|---|---:|---:|---:|---:|")

    for context in CONTEXTS:
        view_count = views.get(context, 0)
        purchase_count = purchases.get(context, 0)
        dismiss_count = dismissals.get(context, 0)
        conv = (purchase_count / view_count * 100) if view_count else 0.0
        print(
            f"| `{context}` | {view_count:,} | {dismiss_count:,} | {purchase_count:,} | {conv:.1f}% |"
        )

    print("\n## Funnel utilisateurs uniques (vue puis achat, même contexte)\n")
    print("| Contexte | Users vus | Users acheté | Users convertis | Taux |")
    print("|---|---:|---:|---:|---:|")

    for context in CONTEXTS:
        funnel = funnel_users(from_date, to_date, context)
        viewed_users = funnel.get("viewed_users", 0)
        converted = funnel.get("converted_users", 0)
        purchase_users = funnel.get("purchase_users", 0)
        rate = (converted / viewed_users * 100) if viewed_users else 0.0
        print(
            f"| `{context}` | {viewed_users:,} | {purchase_users:,} | {converted:,} | {rate:.1f}% |"
        )

    if sum(purchases.values()) == 0:
        print(
            "\n> Note : aucun événement `purchase_completed` sur la période. "
            "L'app ne l'envoyait pas avant la mise à jour récente — "
            "seules les vues/fermetures sont fiables sur l'historique."
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--from-date", dest="from_date")
    parser.add_argument("--to-date", dest="to_date")
    args = parser.parse_args()

    missing = [
        name
        for name in (
            "MIXPANEL_SERVICE_ACCOUNT_USERNAME",
            "MIXPANEL_SERVICE_ACCOUNT_SECRET",
            "MIXPANEL_PROJECT_ID",
        )
        if not os.environ.get(name)
    ]
    if missing:
        print("Variables manquantes : " + ", ".join(missing), file=sys.stderr)
        print(
            "\nCrée un Service Account dans Mixpanel → Project Settings → Service Accounts, "
            "puis ajoute les 3 variables dans les secrets Cursor.",
            file=sys.stderr,
        )
        return 2

    to_date = args.to_date or date.today().isoformat()
    from_date = args.from_date or (date.today() - timedelta(days=90)).isoformat()
    print_report(from_date, to_date)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
