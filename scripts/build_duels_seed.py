#!/usr/bin/env python3
"""Construit les données des duels et leur SQL d'amorçage.

    python3 scripts/build_duels_seed.py

Écrit, de façon reproductible (tirages à graine fixe) :
  content/duels/leagues.json        les 30 ligues (nom, seuil de trophées, images)
  content/duels/questions_en.json   les questions (scripts/duels_questions_source.py), options mélangées
  content/duels/bots.json           les adversaires simulés (@, pays, avatar)
  supabase/migrations/20261110020100_duels_seed_v2.sql   le tout en INSERT … ON CONFLICT DO UPDATE

Le SQL se rejoue sans risque : une ligne existante est mise à jour, jamais dupliquée.
Les images viennent de scripts/duels_assets.py (Supabase Storage, bucket public course-images).
"""
from __future__ import annotations

import json
import random
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from duels_questions_source import QUESTIONS  # noqa: E402

OUT = ROOT / "content" / "duels"
# Le contenu est republié en entier à chaque évolution, dans une nouvelle migration (la
# précédente, déjà exécutée, ne bouge pas) : chaque ligne est insérée ou mise à jour.
SEED = ROOT / "supabase" / "migrations" / "20261110020100_duels_seed_v2.sql"
STORAGE = "https://afnmcoovdvbtkgohtdij.supabase.co/storage/v1/object/public/course-images/duels"

# ------------------------------------------------------------------ ligues
# Une figure par ligue, de l'Antiquité à aujourd'hui ; la dernière porte le nom de l'app.
LEAGUES = [
    ("aesop", "Aesop", 0), ("homer", "Homer", 100), ("sappho", "Sappho", 200),
    ("confucius", "Confucius", 300), ("socrates", "Socrates", 400), ("cleopatra", "Cleopatra", 500),
    ("hypatia", "Hypatia", 650), ("avicenna", "Avicenna", 800), ("murasaki", "Murasaki", 950),
    ("mansa_musa", "Mansa Musa", 1100), ("dante", "Dante", 1300), ("joan_of_arc", "Joan of Arc", 1500),
    ("gutenberg", "Gutenberg", 1700), ("leonardo", "Leonardo", 1900), ("michelangelo", "Michelangelo", 2100),
    ("copernicus", "Copernicus", 2350), ("shakespeare", "Shakespeare", 2600), ("galileo", "Galileo", 2850),
    ("vermeer", "Vermeer", 3100), ("newton", "Newton", 3400), ("mozart", "Mozart", 3700),
    ("napoleon", "Napoleon", 4000), ("austen", "Austen", 4300), ("darwin", "Darwin", 4650),
    ("lovelace", "Lovelace", 5000), ("van_gogh", "Van Gogh", 5400), ("curie", "Curie", 5800),
    ("einstein", "Einstein", 6200), ("kahlo", "Kahlo", 6600), ("sophia", "Sophia", 7000),
]


def build_leagues() -> list[dict]:
    colors_path = OUT / "league_colors.json"
    colors = json.loads(colors_path.read_text(encoding="utf-8")) if colors_path.exists() else {}
    rows = []
    for position, (slug, name, min_trophies) in enumerate(LEAGUES, start=1):
        file = f"league_{position:02d}_{slug}"
        rows.append({
            "position": position, "slug": slug, "name": name, "min_trophies": min_trophies,
            "background_url": f"{STORAGE}/leagues/{file}.jpg",
            "thumb_url": f"{STORAGE}/leagues/{file}_thumb.jpg",
            "accent_hex": colors.get(slug, "#1A3A6B"),
        })
    return rows


# ------------------------------------------------------------------ questions
def build_questions() -> list[dict]:
    credits_path = OUT / "portraits.json"
    credits = json.loads(credits_path.read_text(encoding="utf-8")) if credits_path.exists() else {}
    rng = random.Random(20261109)
    counters: dict[int, int] = {}
    rows = []
    for q in QUESTIONS:
        counters[q["level"]] = counters.get(q["level"], 0) + 1
        row = {
            "id": f"dq_en_{q['level']}_{counters[q['level']]:02d}", "lang": "en", "level": q["level"],
            "kind": q["kind"], "subject": q["subject"], "question": q["question"],
            "options": None, "correct_index": None, "image_url": None, "image_credit": None,
            "slider_min": None, "slider_max": None, "slider_step": None, "correct_value": None, "unit": None,
        }
        if q["kind"] == "true_false":
            row["options"] = ["True", "False"]
            row["correct_index"] = 0 if q["answer"] else 1
        elif q["kind"] in ("mcq", "portrait"):
            order = list(range(len(q["options"])))
            rng.shuffle(order)
            row["options"] = [q["options"][i] for i in order]
            row["correct_index"] = order.index(0)
            if q["kind"] == "portrait":
                row["image_url"] = f"{STORAGE}/portraits/{q['portrait']}.jpg"
                meta = credits.get(q["portrait"], {})
                row["image_credit"] = " · ".join(x for x in (meta.get("artist"), meta.get("license"), "Wikimedia Commons") if x)
        else:
            row.update(slider_min=q["min"], slider_max=q["max"], slider_step=q["step"],
                       correct_value=q["value"], unit=q["unit"])
        rows.append(row)
    return rows


# ------------------------------------------------------------------ adversaires
# Groupes d'avatars : à quels visages un prénom peut plausiblement correspondre.
AVATAR_TAGS = {
    1: ("f", "af"), 2: ("m", "eu"), 3: ("f", "sa"), 4: ("m", "ea"), 5: ("f", "eu"), 6: ("m", "af"),
    7: ("f", "la"), 8: ("m", "me"), 9: ("f", "ea"), 10: ("f", "af"), 11: ("m", "sa"), 12: ("m", "eu"),
    13: ("x", "eu"), 14: ("m", "la"), 15: ("m", "sa"), 16: ("f", "eu"), 17: ("f", "sea"), 18: ("f", "af"),
    19: ("m", "eu"), 20: ("m", "af"),
    21: ("m", "la"), 22: ("f", "ea"), 23: ("f", "af"), 24: ("m", "eu"), 25: ("m", "ea"), 26: ("f", "sa"),
    27: ("f", "la"), 28: ("m", "eu"), 29: ("m", "af"), 30: ("f", "me"), 31: ("m", "ea"), 32: ("f", "eu"),
    33: ("m", "me"), 34: ("f", "sea"), 35: ("m", "eu"), 36: ("m", "af"), 37: ("f", "eu"), 38: ("m", "sa"),
    39: ("f", "sea"), 40: ("f", "af"), 41: ("m", "eu"), 42: ("f", "me"), 43: ("m", "ea"), 44: ("f", "eu"),
    45: ("m", "la"), 46: ("f", "af"), 47: ("m", "sa"), 48: ("f", "eu"), 49: ("m", "sea"), 50: ("f", "eu"),
    51: ("f", "la"), 52: ("m", "af"), 53: ("f", "eu"), 54: ("m", "me"), 55: ("f", "ea"), 56: ("m", "eu"),
    57: ("f", "sea"), 58: ("f", "af"), 59: ("m", "eu"), 60: ("m", "eu"),
}

# Viviers de prénoms et de noms : (groupes d'avatars, prénoms masculins, prénoms féminins, noms).
POOLS = {
    "anglo": (("eu", "af"),
              "james liam noah ethan mason logan jack oliver harry george ben sam tom alex ryan tyler josh luke adam owen max charlie leo dylan connor".split(),
              "emma olivia ava sophie mia chloe grace lily ella hannah zoe ruby amelia lucy megan sarah kate abby maya nora isla freya poppy erin holly".split(),
              "smith jones taylor brown wilson walker white hall clarke wright green baker hill scott cooper ward morris king turner parker reed kelly brooks hayes".split()),
    "hispanic": (("la", "eu"),
                 "mateo santiago diego carlos luis javier andres pablo miguel sergio alejandro daniel nico tomas rafael emilio".split(),
                 "sofia valentina camila lucia isabella mariana daniela paula elena carmen julia martina ana gabriela renata ximena".split(),
                 "garcia lopez martinez rodriguez hernandez gomez diaz torres ruiz morales ortiz castro vargas romero mendoza silva".split()),
    "brazil": (("la", "af", "eu"),
               "lucas gabriel pedro matheus rafael thiago bruno felipe gustavo joao caio vitor".split(),
               "ana beatriz julia larissa camila fernanda leticia bruna mariana isadora carol luiza".split(),
               "silva santos oliveira souza costa pereira almeida ferreira ribeiro carvalho rocha lima".split()),
    "french": (("eu", "af", "me"),
               "lucas hugo theo louis jules antoine maxime clement romain baptiste adrien mathis".split(),
               "lea chloe manon camille ines jade louise sarah clara margaux elise oceane".split(),
               "martin bernard dubois thomas robert petit durand leroy moreau simon laurent michel".split()),
    "german": (("eu",),
               "lukas jonas felix leon paul max finn moritz jan niklas tobias simon".split(),
               "anna lena laura lea marie hannah julia sophie johanna clara nina emilia".split(),
               "muller schmidt schneider fischer weber meyer wagner becker hoffmann koch richter klein".split()),
    "dutch": (("eu",),
              "daan sem lars bram thijs ruben jesse stijn niels koen".split(),
              "emma sanne lotte fenna noor femke anouk iris lieke eva".split(),
              "dejong jansen devries bakker visser smit meijer bos mulder dekker".split()),
    "nordic": (("eu",),
               "erik lars magnus oskar nils anders mikkel jonas emil axel henrik soren".split(),
               "ingrid freja astrid sofie elsa maja linnea ida signe tove saga karin".split(),
               "andersson johansson nilsson hansen larsen berg lindberg olsen dahl holm strand lund".split()),
    "italian": (("eu",),
                "luca marco matteo andrea francesco davide simone alessandro giulio pietro".split(),
                "giulia chiara sara martina francesca elisa alice federica silvia marta".split(),
                "rossi russo ferrari esposito bianchi romano colombo ricci marino greco".split()),
    "slavic": (("eu",),
               "jakub mateusz kacper piotr tomasz marek pavel ivan dmitri andrei".split(),
               "kasia ania zuzanna natalia ola magda katya daria elena milena".split(),
               "nowak kowalski wisniewski novak horvat petrov ivanov popescu kovac dvorak".split()),
    "south_asian": (("sa",),
                    "arjun rohan aditya rahul vikram karan ishaan dev sahil ali hamza bilal imran nikhil".split(),
                    "priya ananya aisha diya kavya neha pooja riya sana fatima meera tanvi zara isha".split(),
                    "sharma patel singh kumar gupta reddy mehta iyer khan ahmed malik nair joshi rao".split()),
    "east_asian": (("ea",),
                   "wei jun hao ming chen kai jin li yang bo".split(),
                   "mei lin xiu yan jing hui li na ying fang".split(),
                   "wang li zhang liu chen yang huang zhao wu zhou".split()),
    "japanese": (("ea",),
                 "haruto yuto sota ren kaito riku daiki kenta shun takumi".split(),
                 "yui hina sakura aoi rin mio yuna haruka emi nanami".split(),
                 "sato suzuki takahashi tanaka watanabe ito yamamoto nakamura kobayashi kato".split()),
    "korean": (("ea",),
               "minjun jihoon seojun hyun woojin taeyang junho sungmin".split(),
               "jiwoo seoyeon minji hana yuna soojin eunji dahye".split(),
               "kim lee park choi jung kang cho yoon".split()),
    "sea": (("sea",),
            "miguel jose paolo rizal budi agus dimas an minh nam somchai arif".split(),
            "maria angel bea joy putri dewi sari linh mai thao nicha siti".split(),
            "santos reyes cruz bautista delacruz wijaya pratama nguyen tran pham lim tan".split()),
    "african": (("af",),
                "chidi emeka tunde kwame kofi sipho thabo jabari kelechi femi baraka amadou".split(),
                "amara ngozi chioma adaeze zainab akua abena thandi wanjiru nia fatou aminata".split(),
                "okafor adeyemi mensah owusu nkosi dlamini mwangi otieno balogun eze diallo ndiaye".split()),
    "arab": (("me",),
             "omar youssef karim khalid tariq hassan samir rami ziad amir mehmet emre can reza".split(),
             "layla nour yasmin salma hana rania dina mariam leila farah elif zeynep defne shirin".split(),
             "haddad khoury mansour nasser saleh farouk aziz darwish yilmaz kaya demir hosseini".split()),
}

# Pays (code ISO) : poids dans le tirage, et viviers de prénoms avec leur poids.
COUNTRIES = [
    ("US", 20, {"anglo": 60, "hispanic": 16, "south_asian": 8, "east_asian": 8, "african": 4, "arab": 4}),
    ("GB", 9, {"anglo": 76, "south_asian": 14, "african": 6, "arab": 4}),
    ("CA", 5, {"anglo": 60, "french": 15, "south_asian": 13, "east_asian": 12}),
    ("AU", 4, {"anglo": 82, "east_asian": 10, "south_asian": 8}),
    ("IE", 2, {"anglo": 100}), ("NZ", 1, {"anglo": 100}),
    ("ZA", 2, {"african": 60, "anglo": 40}),
    ("IN", 8, {"south_asian": 100}), ("PK", 2, {"south_asian": 100}),
    ("NG", 3, {"african": 100}), ("KE", 2, {"african": 100}), ("GH", 1, {"african": 100}),
    ("PH", 3, {"sea": 100}), ("ID", 2, {"sea": 100}), ("VN", 1, {"sea": 100}),
    ("SG", 1, {"east_asian": 60, "south_asian": 20, "sea": 20}), ("MY", 1, {"sea": 60, "east_asian": 40}),
    ("DE", 4, {"german": 88, "arab": 12}), ("NL", 3, {"dutch": 90, "arab": 10}),
    ("SE", 2, {"nordic": 100}), ("NO", 1, {"nordic": 100}), ("DK", 1, {"nordic": 100}), ("FI", 1, {"nordic": 100}),
    ("FR", 3, {"french": 100}), ("BE", 1, {"french": 50, "dutch": 50}), ("CH", 1, {"german": 60, "french": 40}),
    ("ES", 2, {"hispanic": 100}), ("IT", 2, {"italian": 100}), ("PT", 1, {"brazil": 100}),
    ("PL", 2, {"slavic": 100}), ("RO", 1, {"slavic": 100}), ("CZ", 1, {"slavic": 100}),
    ("BR", 3, {"brazil": 100}), ("MX", 2, {"hispanic": 100}), ("AR", 1, {"hispanic": 100}), ("CO", 1, {"hispanic": 100}),
    ("TR", 1, {"arab": 100}), ("EG", 1, {"arab": 100}), ("AE", 1, {"arab": 60, "south_asian": 40}),
    ("JP", 2, {"japanese": 100}), ("KR", 2, {"korean": 100}), ("CN", 1, {"east_asian": 100}),
]

NICK_FRONT = "quiz trivia history book night curious lucky silent clever cosmic paper golden velvet wander atlas nova pixel mellow".split()
NICK_BACK = "owl nerd buff worm fox wizard sage scholar reader pilot comet panda otter raven badger ninja monk".split()
BOT_COUNT = 300


def ascii_handle(text: str) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii").lower()
    return re.sub(r"[^a-z0-9]", "", text)


def weighted(rng: random.Random, table: dict[str, int]) -> str:
    names, weights = zip(*table.items())
    return rng.choices(names, weights=weights, k=1)[0]


def build_bots() -> list[dict]:
    rng = random.Random(755)
    codes = [c for c, _, _ in COUNTRIES]
    country_weights = [w for _, w, _ in COUNTRIES]
    pools_by_country = {c: p for c, _, p in COUNTRIES}
    seen: set[str] = set()
    bots = []
    while len(bots) < BOT_COUNT:
        country = rng.choices(codes, weights=country_weights, k=1)[0]
        groups, males, females, lasts = POOLS[weighted(rng, pools_by_country[country])]
        gender = rng.choice("mf")
        first = rng.choice(males if gender == "m" else females)
        last = rng.choice(lasts)
        year = rng.choice([str(rng.randint(84, 99)), "0" + str(rng.randint(0, 9)), str(rng.randint(1985, 2008))])
        style = rng.random()
        if style < 0.24:
            handle = first + last
        elif style < 0.42:
            handle = first + last[0] + str(rng.randint(1, 99))
        elif style < 0.60:
            handle = first + year
        elif style < 0.72:
            handle = first[0] + last + str(rng.randint(1, 99))
        elif style < 0.82:
            handle = last + first
        elif style < 0.90:
            handle = first + str(rng.randint(1, 999))
        else:
            handle = rng.choice(NICK_FRONT) + rng.choice(NICK_BACK) + rng.choice(["", str(rng.randint(1, 99))])
        handle = ascii_handle(handle)[:20]
        if not re.fullmatch(r"[a-z][a-z0-9]{2,19}", handle) or handle in seen:
            continue
        seen.add(handle)
        fitting = [n for n, (g, grp) in AVATAR_TAGS.items() if grp in groups and g in (gender, "x")]
        bots.append({"handle": handle, "country_code": country, "avatar_id": f"avatar_{rng.choice(fitting):02d}"})
    return bots


# ------------------------------------------------------------------ SQL
def sql(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (list, dict)):
        return "'" + json.dumps(value, ensure_ascii=False).replace("'", "''") + "'::jsonb"
    return "'" + str(value).replace("'", "''") + "'"


def insert(table: str, columns: list[str], rows: list[dict], conflict: str) -> str:
    values = ",\n".join("  (" + ", ".join(sql(r[c]) for c in columns) + ")" for r in rows)
    updates = ", ".join(f"{c} = EXCLUDED.{c}" for c in columns if c != conflict)
    return (f"INSERT INTO public.{table} ({', '.join(columns)}) VALUES\n{values}\n"
            f"ON CONFLICT ({conflict}) DO UPDATE SET {updates};\n")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    leagues, questions, bots = build_leagues(), build_questions(), build_bots()
    for name, data in (("leagues.json", leagues), ("questions_en.json", questions), ("bots.json", bots)):
        (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    parts = [
        "-- Contenu des duels : 30 ligues, les adversaires simulés et les questions de la bêta (anglais).\n"
        "-- Fichier généré par scripts/build_duels_seed.py depuis content/duels : ne pas le modifier à la main.\n"
        "-- Rejouable : chaque ligne est insérée ou mise à jour.\n",
        insert("duel_leagues", ["position", "slug", "name", "min_trophies", "background_url", "thumb_url", "accent_hex"], leagues, "position"),
        insert("duel_bots", ["handle", "country_code", "avatar_id"], bots, "handle"),
        insert("duel_questions", ["id", "lang", "level", "kind", "subject", "question", "options", "correct_index",
                                  "image_url", "image_credit", "slider_min", "slider_max", "slider_step",
                                  "correct_value", "unit"], questions, "id"),
    ]
    SEED.write_text("\n".join(parts), encoding="utf-8")
    print(f"{len(leagues)} ligues, {len(bots)} adversaires, {len(questions)} questions → {SEED.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
