#!/usr/bin/env bash
set -euo pipefail

project="App/MoyashiRecall.xcodeproj/project.pbxproj"
privacy="App/MoyashiRecall/PrivacyInfo.xcprivacy"

fail() {
  echo "release-audit: $1" >&2
  exit 1
}

[[ -f "$project" ]] || fail "missing Xcode project"
[[ -f "$privacy" ]] || fail "missing PrivacyInfo.xcprivacy"

grep -q 'PrivacyInfo.xcprivacy in Resources' "$project"   || fail "privacy manifest is not in app resources"
grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.moyashi.recall;' "$project"   || fail "unexpected or missing bundle identifier"
grep -Eq 'MARKETING_VERSION = [0-9]+\.[0-9]+\.[0-9]+;' "$project"   || fail "marketing version is missing"
grep -Eq 'CURRENT_PROJECT_VERSION = [0-9]+;' "$project"   || fail "build number is missing"
grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 17.0;' "$project"   || fail "unexpected iOS deployment target"
grep -q 'NSPrivacyAccessedAPICategoryUserDefaults' "$privacy"   || fail "UserDefaults privacy reason is missing"
grep -q 'NSPrivacyAccessedAPICategoryFileTimestamp' "$privacy"   || fail "file timestamp privacy reason is missing"

if grep -q 'ASSETCATALOG_COMPILER_APPICON_NAME' "$project"; then
  echo "release-audit: app icon configuration present"
else
  echo "release-audit: warning: AppIcon asset catalog is not configured"
fi

if grep -q 'DEVELOPMENT_TEAM = ' "$project"; then
  echo "release-audit: development team is configured"
else
  echo "release-audit: note: development team is intentionally not committed; archive signing remains a manual release step"
fi

echo "release-audit: automated project checks passed"
