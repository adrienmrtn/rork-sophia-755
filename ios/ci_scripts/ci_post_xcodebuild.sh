#!/bin/sh
# Log the build numbers actually embedded in the archive (what App Store Connect sees).

set -e

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  exit 0
fi

if [ -z "${CI_ARCHIVE_PATH:-}" ] || [ ! -d "$CI_ARCHIVE_PATH" ]; then
  echo "ci_post_xcodebuild: no archive at CI_ARCHIVE_PATH"
  exit 0
fi

APP_PLIST=$(find "$CI_ARCHIVE_PATH/Products/Applications" -name Info.plist -maxdepth 3 2>/dev/null | head -1)

if [ -z "$APP_PLIST" ]; then
  echo "ci_post_xcodebuild: Info.plist not found in archive"
  exit 0
fi

echo "=== Build number (in archive — this is what gets uploaded) ==="
MARKETING=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PLIST" 2>/dev/null || echo "?")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PLIST" 2>/dev/null || echo "?")
echo "CFBundleShortVersionString (marketing)=${MARKETING}"
echo "CFBundleVersion (build)=${BUILD}"
