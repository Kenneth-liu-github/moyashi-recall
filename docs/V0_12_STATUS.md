# V0.12 Status — Release Archive Gate

## Goal

Prove that the consolidated pre-1.0 codebase can build not only in Debug Simulator mode, but also through the Release configuration and a generic iOS archive path without relying on signing credentials.

## Scope

- Preserve all V0.1–V0.11 behavior.
- Keep the existing Linux, macOS/SwiftData, Debug Simulator, privacy-manifest, and release-readiness gates.
- Add an unsigned Release archive check for generic iOS.
- Verify the archive contains an application bundle.
- Verify the archived application bundle includes PrivacyInfo.xcprivacy.
- Keep App Icon and Apple signing/team as explicit external distribution prerequisites rather than faking them in source control.

## Exit criteria

- Portable Linux tests pass.
- Full macOS/SwiftData tests pass.
- Debug iOS Simulator build passes.
- Unsigned Release archive succeeds for generic iOS.
- Archived app contains PrivacyInfo.xcprivacy.
- No regression in V0.1–V0.11.
- CI returns to manual-only after validation.

## Validation

GitHub Actions run #178 passed on commit:

`02fe0136a2bed37fd19547ab4ea6e5cadfbd9ff9`

Results:

- portable Linux core tests: passed
- full macOS / SwiftData test suite: passed
- Debug iOS Simulator build: passed
- release-readiness audit: 0 engineering failures
- unsigned Release archive for generic iOS: passed
- archived app bundle: present
- archived PrivacyInfo.xcprivacy: present
- V0.1–V0.11 regression gate: passed

The release audit now distinguishes engineering failures from external distribution blockers.

Current external distribution blockers are:

1. final App Icon asset is not yet supplied,
2. AppIcon target build setting remains pending that asset,
3. Apple Development Team must be selected for signed distribution,
4. `com.moyashi.recall` must be verified/registered in the intended Apple Developer account.

These blockers do not prevent the unsigned Release archive from succeeding and are intentionally not fabricated in source control.

## Freeze state

**V0.12 engineering freeze: PASSED.**

Signed TestFlight/App Store distribution remains pending the documented external prerequisites.
