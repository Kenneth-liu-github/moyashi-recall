# V0.13 Status — Distribution Handoff Hardening

## Goal

Reduce the remaining TestFlight/App Store blockers to account-, brand-, and device-specific actions only.

## Engineering scope

- Scaffold and wire the AppIcon asset catalog into the app target.
- Keep final brand artwork external rather than fabricating it.
- Distinguish AppIcon engineering configuration from final image availability in the release audit.
- Prepare a public privacy-policy draft matching the current product architecture.
- Prepare an explicit TestFlight/App Store distribution handoff checklist.
- Re-run the full V0.12 archive gate after the asset-catalog wiring change.

## Remaining external inputs

- approved 1024 × 1024 App Icon artwork,
- Apple Developer Team,
- Bundle ID ownership/registration,
- public privacy-policy URL,
- App Store Connect metadata/privacy answers,
- signed Archive and TestFlight upload,
- physical-device smoke validation.

## Validation

GitHub Actions run #179 passed on commit:

`ee54d099b7b1d3522b4806eebf8713e484619883`

Results:

- portable Linux tests: passed
- full macOS / SwiftData regression suite: passed
- Debug iOS Simulator build: passed
- AppIcon asset catalog compilation: passed
- target AppIcon build setting: passed
- unsigned generic-iOS Release archive: passed
- archived PrivacyInfo.xcprivacy: present
- V0.1–V0.12 regression gate: passed
- release audit: 0 engineering failures

After the AppIcon engineering wiring, the remaining distribution blockers are reduced to:

1. supply the approved final 1024 × 1024 App Icon image,
2. select the intended Apple Development Team,
3. verify/register `com.moyashi.recall` in the intended Apple Developer account.

Additional App Store/TestFlight release actions remain external:

- publish the privacy policy at a stable public URL,
- finalize App Store Connect privacy answers,
- produce a signed Archive,
- upload to TestFlight,
- run the physical-device smoke checklist.

## Freeze state

**V0.13 engineering freeze: PASSED.**
