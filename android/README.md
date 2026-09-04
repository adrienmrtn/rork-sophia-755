# Sophia Android

Native Kotlin + Jetpack Compose port of the Sophia iOS app.

## Decisions

- Application ID: `app.rork.sophia`
- Auth: Google Sign-In only (no Apple on Android)
- Home: TikTok-style vertical pager (same as current iOS)

## Cloud build (recommended if your Mac is weak)

You do **not** need Android Studio or a local emulator.

1. Push your branch (or merge to `main`) — workflow: `.github/workflows/android-debug.yml`
2. On GitHub: **Actions** → **Android Debug APK** → open the latest run  
   (or **Run workflow** via `workflow_dispatch`)
3. When green: **Artifacts** → download **`sophia-debug-apk`**
4. Unzip → you get `app-debug.apk`
5. On a physical Android phone:
   - Enable **Install unknown apps** for Chrome/Files
   - Transfer the APK (AirDrop alternative: Drive, Slack, cable) and open it to install
6. Or with USB debugging: `adb install -r app-debug.apk`

Debug APK uses the placeholder RevenueCat key (`goog_REPLACE_ME`) until you set a real `goog_…` key — UI still runs; real Play Billing needs the key + Play Console.

## Open in Android Studio (optional)

1. Install [Android Studio](https://developer.android.com/studio)
2. Open the `android/` folder
3. Let Gradle sync
4. Prefer a **physical phone** over an emulator on low-RAM Macs
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
| Google OAuth Android client | Google Cloud Console (package + SHA-1) |
| Play Billing products | Play Console → linked in RevenueCat |
| Course cover upload | `SUPABASE_SERVICE_ROLE_KEY` + `python3 scripts/upload_course_images_to_supabase.py` |

The RevenueCat key is in the repo (public SDK key, shipped in the APK anyway), so the SDK
configures itself. Purchases still need the Play products attached to the `premium`
entitlement, and a build installed **from Play** — Play Billing does not work on a sideloaded
APK or an emulator without Play Store.

## Content pipeline

```bash
python3 scripts/export_ios_content_for_android.py --from-ref origin/main
```

Exports locale catalogs, UI strings (all 15 langs from AppLocalizable), and CoursesV2 into `app/src/main/assets/`.
Then slims `courses.{lang}.json` (quiz + metadata only) and writes `course_index.{lang}.json`
for the home feed. Cover JPEGs are **not** packaged — Coil loads them from the public
Supabase bucket `course-images` (see `scripts/upload_course_images_to_supabase.py`).

## Build from CLI

```bash
cd android
./gradlew :app:assembleDebug
```
