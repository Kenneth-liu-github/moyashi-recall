#!/usr/bin/env bash
set -euo pipefail

echo "== Moyashi Recall V0.4 validation =="

echo
echo "1/3 Swift toolchain"
swift --version

echo
echo "2/3 Full macOS package test suite"
swift test

echo
echo "3/3 iOS Simulator build"
xcodebuild \
  -project App/MoyashiRecall.xcodeproj \
  -scheme MoyashiRecall \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build

echo
echo "V0.4 validation completed successfully."
