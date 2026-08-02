# Sophia Android

Native Kotlin + Jetpack Compose port of the Sophia iOS app.

## Decisions

- Application ID: `app.rork.sophia`
- Auth: Google Sign-In only (no Apple on Android)
- Home: TikTok-style vertical pager (same as current iOS)

## Open in Android Studio

1. Install [Android Studio](https://developer.android.com/studio)
2. Open the `android/` folder
3. Let Gradle sync
4. Create an emulator (Pixel + system image **with Google Play**)
5. Run the `app` configuration

## Implemented so far

- 5-tab shell + TikTok home + library/collections/profile
- Course reader (v2 blocks) + freemium locks + **glossary `[[terms]]`**
- Full quiz engine (mcq / trueFalse / chronological / sliders)
- Training SRS session
- Onboarding V2 funnel (~17 steps: phone time, years grid, swipe courses, trial, dual paywalls)
- Context paywalls (fin_onboarding annual+comparison, discount flash, quiz/course unlock)
- RevenueCat purchase hooks
- Google Sign-In → Supabase + progress sync / conflict dialog (with summaries)
- **Discount gift** (3 swipes → 3-tap reveal → 60 min offer) + side tab
- **Friends** (handle, requests, leaderboard, friend profile, rank ring)
- **Post-completion rewards** (streak → rank-up → collection → level-up)
- **Glossary** `[[terms]]` + first-term coachmark
- **First-open tutorials** (home / collections / training)
- **Training mini-onboarding** (Discover → 3 screens → fin_onboarding paywalls)
- **Trial reminder** local notifications + POST_NOTIFICATIONS
- **Course share** (`sophia://course/{id}`)
- **Meta Ads** service (consent-gated auto-log)
- **Ambassador** Formspree candidature from profile
- **Play In-App Review** (3rd lesson of first course)
- **Mixpanel EU** funnel events (onboarding, course, quiz, locks, discount)
- **15 languages** (Phase A) + onboarding language scroll / scrollable profile (Phase B)
- **Trial/no-trial paywalls**, RC impressions, quiz FAQ, lock overlay (Phase C)
- **Legal docs** (Play-adapted), restore, analytics parity, Play store packs (Phase D)

## Phase E QA (no APK)

```bash
python3 scripts/qa_android_phase_e.py
```

See [`QA.md`](./QA.md) for the full static checklist and deferred device checks.

## What you still need to provide

| Item | Where |
|---|---|
| RevenueCat Android API key (`goog_…`) | `app/build.gradle.kts` `REVENUECAT_API_KEY` |
| Google OAuth Android client | Google Cloud Console (package + SHA-1) |
| Play Billing products | Play Console → linked in RevenueCat |
| Meta Android key hashes | Meta Developer Console |

Until the RevenueCat key is set, the app runs in free mode (`goog_REPLACE_ME`). Debug paywall can simulate premium.

## Content pipeline

```bash
python3 scripts/export_ios_content_for_android.py --from-ref origin/main
```

Exports locale catalogs, UI strings (new langs), and CoursesV2 into `app/src/main/assets/`.

## Build from CLI

```bash
cd android
./gradlew :app:assembleDebug
```
