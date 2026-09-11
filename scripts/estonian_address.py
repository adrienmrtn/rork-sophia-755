#!/usr/bin/env python3
"""Put the Estonian pack into the second person singular.

The French source addresses the reader as *tu* and every locale follows it, but
the engine answers Estonian in the polite plural whichever language it is given:

    FR  Découvre des cours courts et clairs
    ET  Avastage lühikesed ja selged kursused        ← plural, as to a stranger
        Avasta lühikesed ja selged kursused          ← what the app should say

Pronouns map one to one. Imperatives do not — the plural is the stem plus
``-ge``/``-ke`` but the singular is the bare stem, and Estonian stems change
(``Muutke`` → ``Muuda``, ``Tehke`` → ``Tee``), so those are listed rather than
derived. Ordinary words that happen to end in ``-ge``/``-ke`` — ``kõige``,
``külge``, ``natuke`` — are simply absent from the list and stay untouched.

Usage:
    python scripts/estonian_address.py --check
    python scripts/estonian_address.py
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

PRONOUNS = {
    "Teie": "Sinu", "teie": "sinu",
    "Teid": "Sind", "teid": "sind",
    "Teile": "Sulle", "teile": "sulle",
    "Teil": "Sul", "teil": "sul",
    "Teiega": "Sinuga", "teiega": "sinuga",
    "Teist": "Sinust", "teist": "sinust",
    "Te": "Sa", "te": "sa",
}

VERBS = {
    "Avage": "Ava", "avage": "ava",
    "Alustage": "Alusta", "alustage": "alusta",
    "Avastage": "Avasta", "avastage": "avasta",
    "Jätkake": "Jätka", "jätkake": "jätka",
    "Hallake": "Halda", "hallake": "halda",
    "Kandideerige": "Kandideeri", "kandideerige": "kandideeri",
    "Kirjeldage": "Kirjelda", "kirjeldage": "kirjelda",
    "Kujutage": "Kujuta", "kujutage": "kujuta",
    "Laiendage": "Laienda", "laiendage": "laienda",
    "Logige": "Logi", "logige": "logi",
    "Looge": "Loo", "looge": "loo",
    "Lõpetage": "Lõpeta", "lõpetage": "lõpeta",
    "Lähtestage": "Lähtesta", "lähtestage": "lähtesta",
    "Lülitage": "Lülita", "lülitage": "lülita",
    "Minge": "Mine", "minge": "mine",
    "Muutke": "Muuda", "muutke": "muuda",
    "Pange": "Pane", "pange": "pane",
    "Pidage": "Pea", "pidage": "pea",
    "Proovige": "Proovi", "proovige": "proovi",
    "Puudutage": "Puuduta", "puudutage": "puuduta",
    "Pühkige": "Pühi", "pühkige": "pühi",
    "Püsige": "Püsi", "püsige": "püsi",
    "Rääkige": "Räägi", "rääkige": "räägi",
    "Saage": "Saa", "saage": "saa",
    "Saatke": "Saada", "saatke": "saada",
    "Salvestage": "Salvesta", "salvestage": "salvesta",
    "Sisestage": "Sisesta", "sisestage": "sisesta",
    "Suurendage": "Suurenda", "suurendage": "suurenda",
    "Taaskäivitage": "Taaskäivita", "taaskäivitage": "taaskäivita",
    "Testige": "Testi", "testige": "testi",
    "Tehke": "Tee", "tehke": "tee",
    "Tulge": "Tule", "tulge": "tule",
    "Täitke": "Täida", "täitke": "täida",
    "Tühistage": "Tühista", "tühistage": "tühista",
    "Uurige": "Uuri", "uurige": "uuri",
    "Vaadake": "Vaata", "vaadake": "vaata",
    "Valige": "Vali", "valige": "vali",
    "Varundage": "Varunda", "varundage": "varunda",
    "Võtke": "Võta", "võtke": "võta",
    "Õppige": "Õpi", "õppige": "õpi",
    # Indicative second person plural, for the sentences that state a fact.
    "Olete": "Oled", "olete": "oled",
    "Saate": "Saad", "saate": "saad",
    "Peate": "Pead", "peate": "pead",
    "Võite": "Võid", "võite": "võid",
    "Soovite": "Soovid", "soovite": "soovid",
    "Näete": "Näed", "näete": "näed",
    "Teate": "Tead", "teate": "tead",
    "Leiate": "Leiad", "leiate": "leiad",
    "Tahate": "Tahad", "tahate": "tahad",
}

REPLACEMENTS = {**PRONOUNS, **VERBS}
WORD = re.compile(
    r"\b(" + "|".join(sorted(REPLACEMENTS, key=len, reverse=True)) + r")\b"
)


def singularise(text: str) -> str:
    return WORD.sub(lambda m: REPLACEMENTS[m.group(1)], text)


def targets() -> list[Path]:
    paths = [ROOT / "content" / "locales" / "et" / "ui_strings.json"]
    android = ROOT / "android" / "app" / "src" / "main" / "assets" / "strings" / "et.json"
    if android.exists():
        paths.append(android)
    return [p for p in paths if p.exists()]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report only, write nothing")
    args = parser.parse_args()

    total = 0
    for path in targets():
        data = json.loads(path.read_text(encoding="utf-8"))
        changed = 0
        for key, value in data.items():
            if not isinstance(value, str):
                continue
            updated = singularise(value)
            if updated != value:
                changed += 1
                if changed <= 3 and args.check:
                    print(f"    {key}: {value[:60]!r} → {updated[:60]!r}")
                data[key] = updated
        if changed and not args.check:
            path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
        total += changed
        print(f"  {path.name}: {changed} string(s)")
    print(f"{'Would rewrite' if args.check else 'Rewrote'} {total} string(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
