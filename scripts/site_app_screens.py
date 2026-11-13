#!/usr/bin/env python3
"""Captures d'écran de l'app Android pour la page d'accueil du site (web/public/app/).

Tourne dans l'émulateur du workflow « Site app screens » : installe l'APK de debug, passe
l'accueil sans refaire l'onboarding (préférences posées avant le premier lancement), puis
photographie le fil, Explorer et la lecture d'un cours. Chaque étape laisse aussi l'arbre
de l'interface (.xml) à côté de l'image, pour comprendre une capture ratée sans relancer.

    python3 scripts/site_app_screens.py <apk> <dossier de sortie> [identifiant de cours]
"""
import re
import subprocess
import sys
import time
from pathlib import Path

PACKAGE = "app.rork.sophia"
APK = sys.argv[1]
OUT = Path(sys.argv[2])
COURSE = sys.argv[3] if len(sys.argv) > 3 else "course_149_la_joconde"
OUT.mkdir(parents=True, exist_ok=True)


def adb(*args, check=True, stdin=None, binary=False):
    result = subprocess.run(["adb", *args], input=stdin, capture_output=True, check=False)
    if check and result.returncode != 0:
        raise SystemExit(f"adb {' '.join(args)} : {result.stderr.decode(errors='replace')}")
    return result.stdout if binary else result.stdout.decode(errors="replace")


def shell(command, check=True):
    return adb("shell", command, check=check)


def write_prefs(name, entries):
    """Écrit un fichier de préférences dans le dossier privé de l'app (build debug : run-as)."""
    rows = []
    for key, value in entries.items():
        if isinstance(value, bool):
            rows.append(f'    <boolean name="{key}" value="{str(value).lower()}" />')
        else:
            rows.append(f'    <string name="{key}">{value}</string>')
    xml = "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n" + "\n".join(rows) + "\n</map>\n"
    shell(f"run-as {PACKAGE} mkdir -p shared_prefs")
    adb("shell", f"run-as {PACKAGE} sh -c 'cat > shared_prefs/{name}.xml'", stdin=xml.encode())


def dump():
    shell("uiautomator dump /sdcard/ui.xml", check=False)
    return adb("shell", "cat /sdcard/ui.xml", check=False)


def snap(name):
    (OUT / f"{name}.png").write_bytes(adb("exec-out", "screencap", "-p", binary=True))
    tree = dump()
    (OUT / f"{name}.xml").write_text(tree)
    print(f"capture {name} : {len(tree)} caractères d'arbre", flush=True)
    return tree


def tap_text(*labels, tree=None):
    """Touche le premier élément dont le texte ou la description vaut l'un des libellés."""
    tree = tree or dump()
    for label in labels:
        for node in re.finditer(r"<node [^>]*>", tree):
            attrs = node.group(0)
            if f'text="{label}"' not in attrs and f'content-desc="{label}"' not in attrs:
                continue
            bounds = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', attrs)
            if not bounds:
                continue
            x1, y1, x2, y2 = map(int, bounds.groups())
            shell(f"input tap {(x1 + x2) // 2} {(y1 + y2) // 2}")
            print(f"touché : {label}", flush=True)
            return True
    print(f"introuvable : {labels}", flush=True)
    return False


adb("install", "-r", "-g", APK)
shell(f"pm clear {PACKAGE}", check=False)
shell(f"pm grant {PACKAGE} android.permission.POST_NOTIFICATIONS", check=False)
write_prefs("sophia_prefs", {
    "sophia_onboarding_completed": True,
    "sophia_account_prompted": True,
    "sophia_app_language": "en",
    "sophia_pt_variant_resolved": True,
    "sophia_user_first_name": "Alex",
})
write_prefs("sophia_tutorial_flags", {key: True for key in (
    "sophia_tut_home_swipe", "sophia_tut_course_terms", "sophia_tut_collections",
    "sophia_tut_training", "sophia_tut_training_onboarding", "sophia_tut_path",
)})
write_prefs("sophia_debug", {"forcePremium": True})

# Barre d'état propre : 9:41, batterie pleine, pas de notifications.
shell("settings put global sysui_demo_allowed 1")
for command in (
    "enter",
    "clock -e hhmm 0941",
    "battery -e level 100 -e plugged false",
    "network -e wifi show -e level 4 -e fully true",
    "network -e mobile show -e datatype none -e level 4 -e fully true",
    "notifications -e visible false",
):
    shell(f"am broadcast -a com.android.systemui.demo -e command {command}", check=False)

shell(f"am start -W -n {PACKAGE}/.MainActivity")
time.sleep(25)
snap("01_home_first")
time.sleep(10)
tree = snap("02_home")

if tap_text("Explore", tree=tree):
    time.sleep(8)
    snap("03_explore")
    shell("input swipe 540 1700 540 900 400")
    time.sleep(3)
    snap("04_explore_scrolled")

shell(f"am start -W -a android.intent.action.VIEW -d sophia://course/{COURSE} {PACKAGE}")
time.sleep(12)
tree = snap("05_course")
# Selon l'état du cours, le lien ouvre sa fiche ou directement la lecture.
if tap_text("Read the course", "Read again", tree=tree):
    time.sleep(8)
    tree = dump()
# La lecture dévoile le texte bloc par bloc, à chaque « Continue ». Le conseil « Touche les
# mots » de la première lecture arrive avec le premier bloc et recouvre la page : on le ferme.
snap("06_reader_0")
for step in range(1, 5):
    if not tap_text("Continue"):
        break
    time.sleep(4)
    if tap_text("OK"):
        time.sleep(3)
    snap(f"06_reader_{step}")

shell("am broadcast -a com.android.systemui.demo -e command exit", check=False)
print("terminé", flush=True)
