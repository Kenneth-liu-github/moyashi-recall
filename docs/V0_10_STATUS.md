# V0.10 Status — Pre-1.0 Release Readiness

## Goal

Turn the consolidated V0.9 mainline into a release-ready candidate that can be exercised on a real iPhone/iPad and prepared for TestFlight without hiding release blockers behind compile-only validation.

V0.10 is a hardening milestone, not a feature-expansion milestone.

## Pre-1.0 audit findings

### Already in good shape

- V0.1–V0.8 functionality is consolidated on `main`.
- Portable Linux tests and full macOS/SwiftData tests are green.
- iOS Simulator build is green.
- A privacy manifest is present and bundled.
- Marketing version/build metadata already targets 0.10.0 / build 10.
- The project has a release-readiness audit script.
- Backup/export/restore, diagnostics, local import, Notion, AI extraction, FSRS, reminders, and Japanese speech all have implementation/test coverage.

### Release blockers / manual gates

1. **App icon asset is missing.**
   - `scripts/release-readiness.sh` already treats this as a failure.
   - The Xcode project does not yet declare an AppIcon build setting.

2. **Apple signing is intentionally not committed.**
   - `DEVELOPMENT_TEAM` must be configured in Xcode for a real device/archive.
   - The bundle identifier `com.moyashi.recall` must be verified/registered in the intended Apple Developer account.

3. **Current CI proves buildability, not real-device behavior.**
   - Files/iCloud document picker behavior needs hands-on validation.
   - Local notification authorization/delivery needs device validation.
   - Japanese AVSpeechSynthesizer playback needs device validation.
   - Keychain persistence needs device validation.
   - Real Notion and AI-provider credentials need an opt-in smoke test.
   - Backup → restore with existing local data needs a device smoke test.

4. **Release workflow needs a strict readiness gate.**
   - The existing release-readiness script reports failures but the standard validation invocation is non-strict.
   - V0.10 will distinguish compile/test validation from release-candidate readiness.

## V0.10 completion rule

V0.10 engineering freeze requires:

- strict release-readiness script integrated into the release-candidate gate,
- app icon asset wiring complete,
- release metadata/privacy checks passing,
- full automated regression green,
- explicit real-device/TestFlight smoke-test checklist documented.

Signing credentials and App Store Connect upload remain operator-controlled and are not stored in the repository.
