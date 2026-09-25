#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/App/MoyashiRecall.xcodeproj/project.pbxproj"
PRIVACY="$ROOT/App/MoyashiRecall/PrivacyInfo.xcprivacy"
ASSETS="$ROOT/App/MoyashiRecall/Assets.xcassets"
APPICON="$ASSETS/AppIcon.appiconset"

failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

if [[ -f "$PRIVACY" ]]; then
  pass "PrivacyInfo.xcprivacy exists"
else
  fail "PrivacyInfo.xcprivacy is missing"
fi

if grep -q "PrivacyInfo.xcprivacy in Resources" "$PROJECT"; then
  pass "Privacy manifest is bundled in the app target"
else
  fail "Privacy manifest is not wired into app resources"
fi

if grep -q "NSPrivacyAccessedAPICategoryUserDefaults" "$PRIVACY" &&
   grep -q "CA92.1" "$PRIVACY"; then
  pass "UserDefaults required-reason declaration is present"
else
  fail "UserDefaults required-reason declaration is incomplete"
fi

if grep -q "NSPrivacyAccessedAPICategoryFileTimestamp" "$PRIVACY" &&
   grep -q "3B52.1" "$PRIVACY"; then
  pass "User-selected file timestamp declaration is present"
else
  fail "File timestamp required-reason declaration is incomplete"
fi

if grep -q "MARKETING_VERSION = 0.10.0;" "$PROJECT"; then
  pass "Marketing version is 0.10.0"
else
  fail "Marketing version is not 0.10.0"
fi

if grep -q "CURRENT_PROJECT_VERSION = 10;" "$PROJECT"; then
  pass "Build number is 10"
else
  fail "Build number is not 10"
fi

if [[ -d "$APPICON" ]]; then
  pass "AppIcon asset set exists"
else
  fail "AppIcon asset set is missing"
fi

if grep -q "ASSETCATALOG_COMPILER_APPICON_NAME" "$PROJECT"; then
  pass "App target declares an AppIcon asset"
else
  fail "App target has no AppIcon build setting"
fi

if grep -q "DEVELOPMENT_TEAM = " "$PROJECT"; then
  pass "Apple Development Team is configured"
else
  warn "Apple Development Team is not committed; configure signing in Xcode before archive/upload"
fi

if grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.moyashi.recall;' "$PROJECT"; then
  warn "Bundle identifier is com.moyashi.recall; verify it is registered in the intended Apple Developer account"
else
  pass "Bundle identifier differs from the development default"
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"

if [[ "${1:-}" == "--strict" && "$failures" -gt 0 ]]; then
  exit 1
fi
