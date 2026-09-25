#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT/.build/DerivedData"
ARCHIVE_PATH="$ROOT/.build/MoyashiRecall.xcarchive"

cd "$ROOT"

echo "== Moyashi Recall validation =="

echo
echo "1/6 Swift toolchain"
swift --version

echo
echo "2/6 Full macOS package test suite"
swift test

echo
echo "3/6 Release metadata audit"
bash scripts/release-readiness.sh

echo
echo "4/6 iOS Simulator Debug build"
rm -rf "$DERIVED_DATA"
xcodebuild \
  -project App/MoyashiRecall.xcodeproj \
  -scheme MoyashiRecall \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

echo
echo "5/6 Built-app privacy manifest"
APP_BUNDLE="$(find "$DERIVED_DATA/Build/Products" -type d -name '*.app' -print -quit)"
if [[ -z "$APP_BUNDLE" ]]; then
  echo "FAIL  No built .app bundle found"
  exit 1
fi

if [[ ! -f "$APP_BUNDLE/PrivacyInfo.xcprivacy" ]]; then
  echo "FAIL  PrivacyInfo.xcprivacy is missing from the built app bundle"
  exit 1
fi

echo "PASS  PrivacyInfo.xcprivacy is present in the built app bundle"

echo
echo "6/6 Unsigned Release archive"
rm -rf "$ARCHIVE_PATH"
xcodebuild \
  -project App/MoyashiRecall.xcodeproj \
  -scheme MoyashiRecall \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  archive

ARCHIVED_APP="$(find "$ARCHIVE_PATH/Products/Applications" -maxdepth 1 -type d -name '*.app' -print -quit)"
if [[ -z "$ARCHIVED_APP" ]]; then
  echo "FAIL  Release archive contains no application bundle"
  exit 1
fi

if [[ ! -f "$ARCHIVED_APP/PrivacyInfo.xcprivacy" ]]; then
  echo "FAIL  PrivacyInfo.xcprivacy is missing from the archived app bundle"
  exit 1
fi

echo "PASS  Unsigned Release archive contains the app and PrivacyInfo.xcprivacy"

echo
echo "Moyashi Recall validation completed successfully."
