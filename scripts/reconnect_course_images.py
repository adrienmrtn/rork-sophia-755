#!/usr/bin/env python3
"""
Reconnect real, bundled course illustrations that were wrongly set to the course
cover slug (or dropped) during the V2 content migration.

The V2 build assigned `asset = <cover slug>` to every inline image block of ~61
courses (captions describe distinct pictures), and left ~23 courses with no inline
image at all — even though the correct themed images exist in ios/Sophia/CourseImages
(and ios/Sophia/Resources/image_credits.json).

This tool matches each image block's caption (+ course title) to the best UNUSED
bundled image, using a bilingual (FR->EN) token-overlap score. Run in `report` mode
to inspect proposed matches, then `apply` to rewrite the `asset` fields in both the
source JSON (content/courses/fr) and the bundled V2 JSON (ios/Sophia/Resources/CoursesV2).
"""
import json
import os
import re
import sys
import glob
import unicodedata

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(REPO, "content/courses/fr")
BUILT_DIR = os.path.join(REPO, "ios/Sophia/Resources/CoursesV2")
IMAGES_DIR = os.path.join(REPO, "ios/Sophia/CourseImages")
CREDITS = os.path.join(REPO, "ios/Sophia/Resources/image_credits.json")
OVERRIDES = os.path.join(REPO, "scripts/image_reconnect_overrides.json")

STOP = set("""
le la les un une des du de d au aux et ou a à en dans sur par pour avec sans son sa ses leur leurs
ce cet cette qui que quoi dont ou est sont the a an of and or to in on for with without its their
this that image photo illustration vue scene représentation representation portrait
""".split())

# FR -> EN token hints (added alongside originals to bridge languages).
LEX = {
    "louve": "wolf", "loup": "wolf", "capitoline": "capitoline", "capitolin": "capitoline",
    "petrole": "oil", "petrolier": "oil", "choc": "crisis", "guerre": "war", "guerres": "war",
    "dieu": "god", "dieux": "gods", "deesse": "goddess", "roi": "king", "reine": "queen",
    "bataille": "battle", "mort": "death", "mortel": "death", "naissance": "birth",
    "创": "", "colline": "hill", "serpent": "serpent", "tete": "head", "regard": "gaze",
    "reflet": "reflection", "bouclier": "shield", "epee": "sword", "cheval": "horse",
    "chevaux": "horse", "navire": "ship", "bateau": "ship", "mer": "sea", "feu": "fire",
    "voleur": "thief", "geant": "giant", "geants": "giants", "monstre": "monster",
    "labyrinthe": "labyrinth", "fil": "thread", "toison": "fleece", "or": "gold",
    "sacrifice": "sacrifice", "pyramide": "pyramid", "temple": "temple", "creation": "creation",
    "monde": "world", "soleil": "sun", "lune": "moon", "etoile": "star", "etoiles": "stars",
    "univers": "universe", "trou": "hole", "noir": "black", "noire": "black",
    "abeille": "bee", "abeilles": "bees", "climat": "climate", "climatique": "climate",
    "eau": "water", "eaux": "water", "montee": "rising", "refugie": "refugee",
    "refugies": "refugees", "migration": "migration", "migrations": "migration",
    "donnees": "data", "numerique": "digital", "presse": "press", "journalisme": "journalism",
    "dette": "debt", "monnaie": "currency", "crypto": "cryptocurrency", "impot": "tax",
    "fiscal": "tax", "fiscale": "tax", "fiscaux": "tax", "evasion": "evasion",
    "banque": "bank", "economie": "economy", "economique": "economic",
    "empire": "empire", "revolution": "revolution", "mur": "wall", "chute": "fall",
    "vaccin": "vaccine", "cerveau": "brain", "memoire": "memory", "reve": "dream",
    "reves": "dreams", "sommeil": "sleep", "electricite": "electricity",
    "gravitation": "gravitation", "gravite": "gravity", "relativite": "relativity",
    "evolution": "evolution", "penicilline": "penicillin", "radioactivite": "radioactivity",
    "volcan": "volcano", "volcans": "volcano", "tremblement": "earthquake",
    "eclair": "lightning", "eclairs": "lightning", "saison": "season", "saisons": "seasons",
    "photosynthese": "photosynthesis", "avion": "airplane", "avions": "airplane",
    "internet": "internet", "adn": "dna", "onu": "un", "otan": "nato",
    "populisme": "populism", "populiste": "populist", "sante": "health", "mentale": "mental",
    "asile": "asylum", "alimentaire": "food", "energetique": "energy", "energie": "energy",
    "travail": "work", "emploi": "employment", "chine": "china", "chinois": "chinese",
    "russie": "russia", "russe": "russian", "ukraine": "ukraine", "israel": "israel",
    "palestinien": "palestinian", "palestine": "palestine", "taiwan": "taiwan",
    "heros": "hero", "invulnerabilite": "invulnerability", "talon": "heel",
    "sirene": "siren", "sirenes": "sirens", "cyclope": "cyclops", "minotaure": "minotaur",
    "sphinx": "sphinx", "enfers": "underworld", "supplice": "torment",
    "creation": "creation", "phenix": "phoenix", "titans": "titans", "titan": "titan",
    "vin": "wine", "table": "round", "ronde": "round", "enchanteur": "enchanter",
    "marin": "sailor", "nuits": "nights", "mille": "thousand",
}


def deaccent(s):
    return "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))


def tokenize(text):
    text = deaccent(text or "").lower()
    raw = [t for t in re.split(r"[^a-z0-9]+", text) if t and len(t) > 1 and t not in STOP]
    out = set()
    for t in raw:
        out.add(t)
        if t in LEX and LEX[t]:
            out.add(LEX[t])
    return out


def load(path):
    with open(path, encoding="utf-8-sig") as f:
        return json.load(f)


def image_tokens(slug, credits):
    toks = set(t for t in slug.split("_") if len(t) > 1 and t not in STOP)
    title = (credits.get(slug) or {}).get("title", "")
    toks |= tokenize(title)
    return toks


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "report"
    credits = load(CREDITS)
    src_files = sorted(glob.glob(os.path.join(SRC_DIR, "*.json")))

    # Compute used images across all source courses.
    used = set()
    course_data = {}
    for f in src_files:
        d = load(f)
        course_data[f] = d
        h = (d.get("hero") or {}).get("image")
        if h:
            used.add(h)
        for s in d.get("sections", []):
            for b in s.get("blocks", []):
                if b.get("type") == "image" and b.get("asset"):
                    used.add(b["asset"])

    all_imgs = set(os.path.splitext(x)[0] for x in os.listdir(IMAGES_DIR) if x.endswith(".jpg"))
    unused = sorted(all_imgs - used)
    unused_tokens = {u: image_tokens(u, credits) for u in unused}

    # IDF weighting over the unused image pool: rare/specific tokens (proper nouns,
    # topic words) count far more than common ones (world, battle, painting, ancient...).
    import math
    df = {}
    for u in unused:
        for t in unused_tokens[u]:
            df[t] = df.get(t, 0) + 1
    N = len(unused)
    def w(t):
        return math.log((N + 1) / (df.get(t, 0) + 1)) + 0.1

    overrides = load(OVERRIDES) if os.path.exists(OVERRIDES) else {}

    def best_match(query_tokens, hero, exclude, topn=6):
        scored = []
        for u in unused:
            if u in exclude:
                continue
            it = unused_tokens[u]
            inter = query_tokens & it
            if not inter:
                continue
            score = sum(w(t) for t in inter)
            scored.append((score, u, sorted(inter, key=lambda t: -w(t))))
        scored.sort(reverse=True)
        return scored[:topn]

    report_lines = []
    proposed = {}  # course_id -> list of {caption, chosen, score, candidates}
    for f in src_files:
        d = course_data[f]
        cid = d.get("id") or os.path.splitext(os.path.basename(f))[0]
        hero = (d.get("hero") or {}).get("image")
        title = d.get("title", "")
        blocks_imgs = [(si, bi, b) for si, s in enumerate(d.get("sections", []))
                       for bi, b in enumerate(s.get("blocks", [])) if b.get("type") == "image"]
        if not blocks_imgs:
            continue
        # Only fix courses where every inline image duplicates the hero (the bug).
        if not (hero and all(b.get("asset") == hero for _, _, b in blocks_imgs)):
            continue

        chosen_for_course = []
        used_local = set()
        ov = overrides.get(cid, {})
        for (si, bi, b) in blocks_imgs:
            caption = b.get("caption", "")
            key = f"{si}.{bi}"
            q = tokenize(caption) | tokenize(title)
            if key in ov:
                chosen = ov[key]
                cands = [(999, chosen or "<drop>", ["<override>"])]
            else:
                # No fuzzy guessing: every buggy image slot must be explicitly mapped.
                cands = best_match(q, hero, used_local)
                chosen = "__MISSING_OVERRIDE__"
            if chosen and chosen not in (None, "__MISSING_OVERRIDE__"):
                if chosen not in all_imgs:
                    raise SystemExit(f"ERROR: {cid} [{key}] -> unknown image slug '{chosen}'")
                used_local.add(chosen)
            chosen_for_course.append({"key": key, "caption": caption, "chosen": chosen,
                                      "candidates": [(round(s, 2), u) for s, u, _ in cands]})
        proposed[cid] = chosen_for_course
        report_lines.append(f"\n=== {cid}  (hero={hero})")
        for c in chosen_for_course:
            report_lines.append(f"  [{c['key']}] {c['caption']}")
            report_lines.append(f"      -> CHOSEN: {c['chosen']}")
            for s, u in c["candidates"]:
                report_lines.append(f"         {s}  {u}")

    missing = [(cid, c["key"], c["caption"]) for cid in proposed for c in proposed[cid]
               if c["chosen"] == "__MISSING_OVERRIDE__"]
    total = sum(len(v) for v in proposed.values())
    kept = sum(1 for cid in proposed for c in proposed[cid]
               if c["chosen"] not in (None, "__MISSING_OVERRIDE__"))
    dropped = sum(1 for cid in proposed for c in proposed[cid] if c["chosen"] is None)

    if mode == "report":
        print("\n".join(report_lines))
        print(f"\n--- buggy courses: {len(proposed)} | slots: {total} | reconnected: {kept} | dropped: {dropped} | MISSING OVERRIDES: {len(missing)}")
        for m in missing:
            print("  MISSING:", m)
        return

    if mode == "apply":
        if missing:
            raise SystemExit(f"Refusing to apply: {len(missing)} image slots lack an explicit override:\n" +
                             "\n".join(f"  {c} [{k}] {cap}" for c, k, cap in missing))
        _apply(proposed)


def _apply(proposed):
    # Rewrite `asset` in both source and built JSON for chosen matches.
    # For image blocks with no confident match, remove the block (do NOT keep the cover).
    def rewrite(dirpath, suffix):
        changed = 0
        for cid, blocks in proposed.items():
            path = os.path.join(dirpath, cid + suffix)
            if not os.path.exists(path):
                continue
            # preserve BOM-less utf-8
            d = load(path)
            plan = {c["key"]: c["chosen"] for c in blocks}
            for si, s in enumerate(d.get("sections", [])):
                new_blocks = []
                for bi, b in enumerate(s.get("blocks", [])):
                    if b.get("type") == "image":
                        key = f"{si}.{bi}"
                        chosen = plan.get(key, "__keep__")
                        if chosen is None:
                            # drop the block (no real image available)
                            continue
                        if chosen != "__keep__":
                            b["asset"] = chosen
                    new_blocks.append(b)
                s["blocks"] = new_blocks
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(d, fh, ensure_ascii=False, indent=2)
                fh.write("\n")
            changed += 1
        return changed

    c1 = rewrite(SRC_DIR, ".json")
    c2 = rewrite(BUILT_DIR, ".fr.json")
    print(f"applied to {c1} source files and {c2} built files")


if __name__ == "__main__":
    main()
