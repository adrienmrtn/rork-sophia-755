#!/bin/sh
# Xcode Cloud assigns CI_BUILD_NUMBER for uploads. It can disagree with
# CURRENT_PROJECT_VERSION in the repo (e.g. project=66 while Cloud uploads 12).
# See: https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds

set -e

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
  exit 0
fi

PBXPROJ="${CI_PRIMARY_REPOSITORY_PATH}/ios/Sophia.xcodeproj/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
  echo "error: missing project at $PBXPROJ"
  exit 1
fi

PROJECT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed -E 's/.*= ([0-9]+);/\1/')

echo "=== Build number (pre-xcodebuild) ==="
echo "CI_BUILD_NUMBER=${CI_BUILD_NUMBER}"
echo "CURRENT_PROJECT_VERSION in repo=${PROJECT_BUILD}"

# Never lower the project build; use whichever is higher.
if [ "$CI_BUILD_NUMBER" -gt "$PROJECT_BUILD" ]; then
  BUILD="$CI_BUILD_NUMBER"
else
  BUILD="$PROJECT_BUILD"
fi

echo "Applying CURRENT_PROJECT_VERSION=${BUILD} to all targets"
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = ${BUILD};/g" "$PBXPROJ"

# App extensions (TikTok blocker, daily question widget) must carry the app's version,
# or App Store Connect rejects the mismatch (ITMS-90473). The app target's
# MARKETING_VERSION is the reference: bumping the app is enough.
APP_VERSION=$(awk '/MARKETING_VERSION = /{v=$3} /PRODUCT_BUNDLE_IDENTIFIER = app\.rork\.assvmps5x7hpyq0ezcsut;/{print v; exit}' "$PBXPROJ" | tr -d ';')
if [ -n "$APP_VERSION" ]; then
  echo "Applying MARKETING_VERSION=${APP_VERSION} to all targets"
  sed -i '' "s/MARKETING_VERSION = [0-9.]*;/MARKETING_VERSION = ${APP_VERSION};/g" "$PBXPROJ"
fi
