# V0.10 Status — TestFlight Release Hardening

## Goal

Convert the validated product mainline into a distribution-ready iOS/iPadOS project without adding new learning features.

## Completed automatically

- Added `PrivacyInfo.xcprivacy` to the app target.
- Declared required-reason API use:
  - `UserDefaults` → `CA92.1`
  - user-selected file timestamps → `3B52.1`
- Declared no tracking in the privacy manifest.
- Privacy manifest currently declares no tracking.
- App Store privacy disclosure for user-provided learning content sent to configured AI providers remains a release-policy item: the final App Store Connect answers must reflect provider retention behavior and the published privacy policy.
- Set marketing version to `0.10.0`.
- Set build number to `10`.
- Added `scripts/release-readiness.sh` to audit release metadata and external blockers.

## Confirmed current external blockers

### App Icon

The repository currently has no `Assets.xcassets/AppIcon.appiconset`.

Apple requires an app icon in the Xcode project for distribution and the icon is used in TestFlight, the Home Screen, Settings, notifications, and App Store surfaces.

This requires a product/brand asset decision. V0.10 will not silently fabricate a final brand icon.

### Apple signing

The Xcode target uses automatic signing but no `DEVELOPMENT_TEAM` is committed.

This is intentionally treated as an external/account-specific setting. A valid Apple Developer team must be selected before archive/upload.

### App privacy metadata

App Store Connect requires a public privacy policy URL for iOS apps. The final privacy answers must also account for user-provided learning content sent to configured AI providers if that content is retained beyond real-time request servicing.

### Bundle ID ownership

The current bundle identifier is:

`com.moyashi.recall`

It must be verified or registered in the Apple Developer account used for distribution.

## Distribution note

Local notifications use the UserNotifications authorization flow already implemented by the app. No remote-push capability is currently part of the product scope.

## V0.10 freeze rule

V0.10 can pass engineering freeze once:

- release metadata and privacy manifest compile successfully,
- full regression + iOS Simulator CI is green,
- the release-readiness audit has no engineering-controlled failures.

TestFlight upload readiness additionally requires:

- final App Icon asset,
- valid Apple Developer signing team,
- confirmed bundle ID ownership,
- public privacy policy URL and reviewed App Store privacy answers.


## Engineering validation

GitHub Actions run #171 passed on validated commit:

`90f824df1c5a794f62227ea3305aedc7a435c8dd`

Results:

- portable Linux core tests: passed
- full macOS / SwiftData regression suite: passed
- iOS Simulator build: passed
- release metadata audit executed successfully
- `PrivacyInfo.xcprivacy` verified inside the built `.app` bundle

**V0.10 engineering freeze: PASSED.**

TestFlight upload readiness remains blocked only by external/distribution prerequisites documented above.
