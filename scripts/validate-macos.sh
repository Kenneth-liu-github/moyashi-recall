#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT/.build/DerivedData"

cd "$ROOT"

echo "== Moyashi Recall validation =="

echo
echo "1/5 Swift toolchain"
swift --version

echo
echo "2/5 Full macOS package test suite"
swift test

echo
echo "3/5 Release metadata audit"
bash scripts/release-readiness.sh

echo
echo "4/5 iOS Simulator build"
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
echo "5/5 Built-app privacy manifest"
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
echo "Moyashi Recall validation completed successfully."
