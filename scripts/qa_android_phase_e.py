#!/usr/bin/env python3
"""Phase E QA gate for the Android Sophia port (no APK / no Gradle).

Checks:
  1. AppLanguage enum == 15 codes
  2. Assets: strings / locales / legal / courses_v2 counts
  3. String key parity (FR ⊆ every language) + critical Phase B–D keys
  4. Catalog / quiz / courses_v2 id parity vs FR
  5. Legal Play wording lint (no iOS / App Store / Apple / UserDefaults)
  6. Store packs schema (play_listing + revenuecat_products)
  7. Code wiring smoke (rg-style string presence in Kotlin sources)

Exit 0 on success, 1 on failure.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "android" / "app" / "src" / "main" / "assets"
JAVA = ROOT / "android" / "app" / "src" / "main" / "java" / "app" / "rork" / "sophia"
STORE = ROOT / "content" / "store"

LANGS = [
    "fr", "en", "es", "de", "pt", "it",
    "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs",
]
STORE_LANGS = ["en", "tr", "pl", "ro", "nl", "el", "sv", "hu", "bg", "cs"]

CRITICAL_KEYS = [
    "onboardingV2.language.scrollHint",
    "paywall.restore",
    "paywall.terms",
    "paywall.privacy",
    "settings.terms.title",
    "settings.privacy.title",
    "settings.restore.title",
    "legal.terms.title",
    "legal.privacy.title",
    "auth.legal.prefix",
    "onboardingV2.pw.startTrial",
    "onboardingV2.pw.subscribe",
    "onboardingV2.pw.priceNoTrial",
    "paywall.price.yearlyNoTrial",
    "paywall.price.trialThenYearly",
    "paywall.cta.activateTrial",
    "paywall.cta.subscribe",
    "paywall.quiz.faq.q1",
    "paywall.quiz.faq.q2",
    "paywall.quiz.faq.q3",
    "paywall.quiz.faq.q3.noTrial",
]

CODE_MARKERS = [
    (JAVA / "domain" / "AppLanguage.kt", "TURKISH"),
    (JAVA / "ui" / "onboarding" / "OnboardingSteps.kt", "scrollHint"),
    (JAVA / "ui" / "onboarding" / "OnboardingSteps.kt", "ProfileMetrics"),
    (JAVA / "ui" / "course" / "CourseLessonLockOverlay.kt", "CourseLessonLockOverlay"),
    (JAVA / "ui" / "course" / "CourseScreen.kt", "courseLocked"),
    (JAVA / "billing" / "StoreViewModel.kt", "shouldShowTrialSteps"),
    (JAVA / "billing" / "StoreViewModel.kt", "trackPaywallImpression"),
    (JAVA / "billing" / "StoreViewModel.kt", "restorePurchasesWith"),
    (JAVA / "ui" / "paywall" / "PaywallScreen.kt", "PaywallLegalRow"),
    (JAVA / "ui" / "paywall" / "PaywallScreen.kt", "QuizPaywall"),
    (JAVA / "data" / "LegalDocumentStore.kt", "privacy"),
    (JAVA / "ui" / "legal" / "LegalScreens.kt", "LegalDocumentScreen"),
    (JAVA / "ui" / "onboarding" / "OnboardingV2Screen.kt", 'analyticsName'),
    (JAVA / "data" / "CourseSessionTracker.kt", "engagement_tier"),
]


class Checker:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.oks: list[str] = []

    def ok(self, msg: str) -> None:
        self.oks.append(msg)
        print(f"  OK  {msg}")

    def fail(self, msg: str) -> None:
        self.errors.append(msg)
        print(f" FAIL {msg}")


def check_app_language(c: Checker) -> None:
    kt = (JAVA / "domain" / "AppLanguage.kt").read_text(encoding="utf-8")
    codes = re.findall(r'enum class AppLanguage.*?^}', kt, re.S)
    body = codes[0] if codes else kt
    found = re.findall(r'\("([a-z]{2})",', body)
    if found != LANGS:
        c.fail(f"AppLanguage codes mismatch: {found}")
    else:
        c.ok(f"AppLanguage has {len(found)} languages")


def check_assets(c: Checker) -> None:
    for lang in LANGS:
        for kind in ("courses", "collections", "glossary"):
            p = ASSETS / "locales" / f"{kind}.{lang}.json"
            if not p.is_file():
                c.fail(f"missing {p.relative_to(ROOT)}")
                continue
            try:
                json.loads(p.read_text(encoding="utf-8"))
            except Exception as e:
                c.fail(f"invalid JSON {p.name}: {e}")
        sp = ASSETS / "strings" / f"{lang}.json"
        if not sp.is_file():
            c.fail(f"missing strings/{lang}.json")
        else:
            try:
                json.loads(sp.read_text(encoding="utf-8"))
            except Exception as e:
                c.fail(f"invalid strings/{lang}.json: {e}")
        lp = ASSETS / "legal" / f"{lang}.json"
        if not lp.is_file():
            c.fail(f"missing legal/{lang}.json")
        else:
            d = json.loads(lp.read_text(encoding="utf-8"))
            if len(d.get("terms", [])) != 10 or len(d.get("privacy", [])) != 11:
                c.fail(
                    f"legal/{lang}.json section counts "
                    f"terms={len(d.get('terms', []))} privacy={len(d.get('privacy', []))}",
                )
        n = len(list((ASSETS / "courses_v2" / lang).glob("*.json")))
        if n != 239:
            c.fail(f"courses_v2/{lang} count={n} (expected 239)")
    if not c.errors or all("courses_v2" not in e and "missing" not in e for e in c.errors[-20:]):
        c.ok("assets present for 15 langs (locales/strings/legal/courses_v2)")


def check_string_keys(c: Checker) -> None:
    maps = {
        lang: json.loads((ASSETS / "strings" / f"{lang}.json").read_text(encoding="utf-8"))
        for lang in LANGS
    }
    fr = set(maps["fr"])
    for lang in LANGS:
        missing = sorted(fr - set(maps[lang]))
        if missing:
            c.fail(f"strings/{lang}.json missing {len(missing)} FR keys e.g. {missing[:3]}")
    for key in CRITICAL_KEYS:
        miss = [lang for lang in LANGS if key not in maps[lang]]
        if miss:
            c.fail(f"critical key {key} missing in {miss}")
    # Play-facing UI strings should not say App Store
    for lang in LANGS:
        for key in ("onboardingV2.review.appStore", "paywall.rating", "paywall.quiz.rating"):
            val = maps[lang].get(key, "")
            if "App Store" in val:
                c.fail(f"{lang} {key} still says App Store: {val}")
    c.ok(f"string key parity OK (FR={len(fr)}, critical={len(CRITICAL_KEYS)})")


def check_catalog(c: Checker) -> None:
    fr_courses = json.loads((ASSETS / "locales" / "courses.fr.json").read_text(encoding="utf-8"))
    fr_ids = {course["id"] for course in fr_courses}
    fr_v2 = {p.name for p in (ASSETS / "courses_v2" / "fr").glob("*.json")}
    quiz_total = sum(len(course.get("quiz") or []) for course in fr_courses)
    for lang in LANGS:
        courses = json.loads((ASSETS / "locales" / f"courses.{lang}.json").read_text(encoding="utf-8"))
        ids = {course["id"] for course in courses}
        if ids != fr_ids:
            c.fail(f"courses.{lang}.json id set != FR")
        if any(not course.get("quiz") for course in courses):
            c.fail(f"courses.{lang}.json has course without quiz")
        if sum(len(course.get("quiz") or []) for course in courses) != quiz_total:
            c.fail(f"courses.{lang}.json quiz count != {quiz_total}")
        v2 = {p.name for p in (ASSETS / "courses_v2" / lang).glob("*.json")}
        if v2 != fr_v2:
            c.fail(f"courses_v2/{lang} file set != FR")
        cols = json.loads((ASSETS / "locales" / f"collections.{lang}.json").read_text(encoding="utf-8"))
        if len(cols) != 31:
            c.fail(f"collections.{lang}.json count={len(cols)} (expected 31)")
    c.ok(f"catalog/quiz/v2 parity OK (courses={len(fr_ids)}, quiz={quiz_total})")


def check_legal_play(c: Checker) -> None:
    banned = [
        (r"\biOS\b", "iOS"),
        (r"\biPhone\b", "iPhone"),
        (r"\bApp Store\b", "App Store"),
        (r"UserDefaults", "UserDefaults"),
        (r"\bApple\b", "Apple"),
        (r"\bATT\b", "ATT"),
    ]
    for lang in LANGS:
        path = ASSETS / "legal" / f"{lang}.json"
        text = path.read_text(encoding="utf-8")
        data = json.loads(text)
        for pat, label in banned:
            if re.search(pat, text):
                c.fail(f"legal/{lang}.json still contains {label}")
        body = data["terms"][1]["body"]
        if "Android" not in body and "android" not in body.lower():
            c.fail(f"legal/{lang}.json terms#2 missing Android")
        # Privacy must not be a copy of terms
        if "Accept" in data["privacy"][0]["title"] or "Acceptation" in data["privacy"][0]["title"]:
            c.fail(f"legal/{lang}.json privacy looks like terms")
    c.ok("legal Play wording lint OK (15 langs)")


def check_store_packs(c: Checker) -> None:
    req = ["name", "short_description", "full_description", "whats_new"]
    for lang in STORE_LANGS:
        play = STORE / f"play_listing.{lang}.json"
        if not play.is_file():
            c.fail(f"missing {play.relative_to(ROOT)}")
            continue
        d = json.loads(play.read_text(encoding="utf-8"))
        if any(not d.get(k) for k in req):
            c.fail(f"play_listing.{lang}.json missing required fields")
        if len(d.get("name", "")) > 30:
            c.fail(f"play_listing.{lang}.json name too long")
        if len(d.get("short_description", "")) > 80:
            c.fail(f"play_listing.{lang}.json short_description > 80")
        if len(d.get("full_description", "")) > 4000:
            c.fail(f"play_listing.{lang}.json full_description > 4000")
        if "Apple" in d.get("full_description", ""):
            c.fail(f"play_listing.{lang}.json full_description mentions Apple")
        rc = STORE / f"revenuecat_products.{lang}.json"
        if not rc.is_file():
            c.fail(f"missing {rc.relative_to(ROOT)}")
            continue
        r = json.loads(rc.read_text(encoding="utf-8"))
        ids = {p.get("store_identifier") for p in r.get("products", [])}
        if not {"Sophia_monthly", "Sophia_yearly"} <= ids:
            c.fail(f"revenuecat_products.{lang}.json missing monthly/yearly ids")
    if not (STORE / "APPLY.md").is_file():
        c.fail("missing content/store/APPLY.md")
    else:
        c.ok(f"store packs OK ({len(STORE_LANGS)} play_listing + RC products)")


def check_code_wiring(c: Checker) -> None:
    for path, marker in CODE_MARKERS:
        if not path.is_file():
            c.fail(f"missing source {path.relative_to(ROOT)}")
            continue
        text = path.read_text(encoding="utf-8")
        if marker not in text:
            c.fail(f"{path.name} missing marker `{marker}`")
    # Freemium: Continue must not open paywall when courseLocked
    course = (JAVA / "ui" / "course" / "CourseScreen.kt").read_text(encoding="utf-8")
    if "if (courseLocked)" not in course or "CourseLessonLockOverlay" not in course:
        c.fail("CourseScreen missing overlay-only lock wiring")
    if re.search(r"courseLocked.*?onRequestPaywall", course, re.S):
        # Allow onRequestPaywall elsewhere, but not inside courseLocked block opening paywall via Continue
        block = re.search(r"if \(courseLocked\) \{(.*?)return@Button", course, re.S)
        if block and "onRequestPaywall" in block.group(1):
            c.fail("CourseScreen courseLocked Continue still calls onRequestPaywall")
    c.ok("code wiring smoke OK")


def main() -> int:
    print("=== Sophia Android Phase E QA ===")
    c = Checker()
    check_app_language(c)
    check_assets(c)
    check_string_keys(c)
    check_catalog(c)
    check_legal_play(c)
    check_store_packs(c)
    check_code_wiring(c)
    print()
    print("=== Summary ===")
    print(f"passed: {len(c.oks)}")
    print(f"failed: {len(c.errors)}")
    if c.errors:
        print("errors:")
        for err in c.errors:
            print(f"  - {err}")
        return 1
    print("errors: none")
    return 0


if __name__ == "__main__":
    sys.exit(main())
