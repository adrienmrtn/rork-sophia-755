# AGENTS.md

Guidance for AI agents and developers working on **Sophia**, a native iOS (Swift/SwiftUI) culture générale app.

## Repository layout

| Path | Purpose |
|------|---------|
| `ios/Sophia.xcodeproj` | Xcode project (canonical app) |
| `ios/Sophia/` | App source, assets, bundled course content |
| `ios/SophiaTests/` | Unit tests (Swift Testing) |
| `ios/SophiaUITests/` | UI tests (XCTest) |
| `ios/ci_scripts/` | Xcode Cloud pre/post build hooks |
| `scripts/` | Python content-import tooling (Excel → Swift) |
| `rork.json` | Rork platform manifest |

There is **no backend**, **no Docker**, and **no `package.json`**. Runtime data (courses, glossary, images) ships inside the app bundle.

## Cursor Cloud specific instructions

### Platform limitation (important)

This is an **iOS-only** project. **Building, running, and testing the app require macOS with Xcode 16+** (iOS 18.0 deployment target). Linux cloud VMs **cannot** run `xcodebuild`, the iOS Simulator, or XCTest UI tests.

On Linux, agents can still:

- Install Python deps for `scripts/` (`openpyxl`)
- Validate repo structure and bundled content (see validation snippet below)
- Edit Swift source and Python import scripts

Full app verification must happen on a Mac (local machine or Xcode Cloud).

### Services

| Service | Required? | Notes |
|---------|-----------|-------|
| **Sophia iOS app** (Xcode → Simulator/device) | **Yes** for E2E | Only runnable product in this repo |
| **RevenueCat** | For paywall/IAP flows | Test API key used in DEBUG (`AppConfig.swift`) |
| **Apple StoreKit sandbox** | For purchase E2E | Needs sandbox Apple ID |
| Python + `openpyxl` | Optional | Content authoring only; Excel files are not in the repo |

No local servers need to be started.

### macOS: build and run

```bash
cd ios
xcodebuild -scheme Sophia -destination 'platform=iOS Simulator,name=iPhone 16' build
open Sophia.xcodeproj   # or: xed .
```

In Xcode: select the **Sophia** scheme → choose an **iOS 18+ Simulator** → Run (⌘R).

First launch shows onboarding; completing it reaches the home swipe deck (`HomeView`).

### macOS: tests

```bash
cd ios
xcodebuild test -scheme Sophia -destination 'platform=iOS Simulator,name=iPhone 16'
```

Unit tests (`SophiaTests`) and UI tests (`SophiaUITests`) are mostly stubs today.

### Linux: Python tooling

```bash
pip3 install --user openpyxl
python3 -c "import openpyxl; print(openpyxl.__version__)"
```

Import scripts expect local Excel paths (see each script's `EXCEL_*` constants). They are **not** required to run the app.

**Do not run `scripts/fix_course_newlines.py` during environment setup** — it mutates `CourseData.swift`.

### Linux: quick validation (read-only)

```bash
python3 - <<'PY'
import json, re
from pathlib import Path
root = Path("ios/Sophia")
assert (root.parent / "Sophia.xcodeproj/project.pbxproj").exists()
text = (root / "Services/CourseData.swift").read_text(encoding="utf-8")
assert len(re.findall(r"Course\(", text)) >= 200
pkg = json.loads((root.parent / "Sophia.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved").read_text())
assert any("revenuecat" in p.get("location","").lower() for p in pkg["pins"])
import openpyxl
print("OK: project, courses, SPM, openpyxl")
PY
```

### Dependencies

- **Swift Package Manager**: RevenueCat `purchases-ios-spm` **5.74.0** (`RevenueCat`, `RevenueCatUI`)
- **Python**: `openpyxl` for Excel import scripts only

### Linting

No SwiftLint or other linter config is checked in. Use Xcode's built-in diagnostics on macOS.
