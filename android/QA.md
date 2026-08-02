# Android Phase E — QA

Static QA gate for the Kotlin/Compose port (no APK required).

## Automated gate

```bash
python3 scripts/qa_android_phase_e.py
```

Covers:

1. `AppLanguage` = 15 codes  
2. Assets for all langs: `strings/`, `locales/`, `legal/`, `courses_v2/` (239 courses)  
3. String key parity + critical Phase B–D keys (scroll hint, trial/no-trial, quiz FAQ, legal chrome)  
4. Catalog / quiz / CoursesV2 id parity vs FR  
5. Legal Play wording lint (no iOS / App Store / Apple / UserDefaults)  
6. Store packs: `content/store/play_listing.*` + `revenuecat_products.*`  
7. Code wiring smoke (lock overlay, trial detect, RC impressions, restore, legal row, analytics names)

Expected: `errors: none`.

## Mapped plan checks (A–D → E)

| Plan | Automated substitute |
|------|----------------------|
| 15-lang picker | Enum + `AppLanguage.entries` in onboarding/profile |
| Course + quiz + glossary | Catalog counts + glossary locale files |
| Trial / no-trial without RC | `shouldShowTrialSteps` / `hasFreeTrial` + no-trial string keys |
| Small-screen profile CTA | `ProfileMetrics` + scroll body / pinned footer in `OnboardingSteps.kt` |
| Overlay-only freemium lock | `CourseLessonLockOverlay` + `courseLocked` Continue no-op |
| Legal / restore | `LegalDocumentStore`, paywall legal row, login note, profile restore |

## Deferred to device (needs APK / credentials)

- Visual small-screen profile CTA with long translations  
- Real RevenueCat trial vs no-trial packages  
- Restore against Play Billing sandbox  
- Google OAuth + Meta key hashes  
- Live Play Console paste of `play_listing.*`

## Human / dashboard (out of code)

See `content/store/APPLY.md` (ASC + Play + RC product titles). Placeholders:

- `privacy_policy_url` / `support_url` in store drafts  
- `goog_…` RevenueCat Android key in `app/build.gradle.kts`
