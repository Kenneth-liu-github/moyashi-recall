# V0.10 Acceptance Checklist

## Engineering-controlled release hardening

- [x] Privacy manifest exists.
- [x] Privacy manifest is bundled in the iOS app target.
- [x] UserDefaults required-reason API is declared.
- [x] User-selected file timestamp required-reason API is declared.
- [x] Tracking is declared false.
- [x] Marketing version is 0.10.0.
- [x] Build number is 10.
- [x] Release-readiness audit script exists.
- [ ] Portable Linux regression tests pass.
- [ ] Full macOS / SwiftData regression tests pass.
- [ ] iOS Simulator build passes.
- [ ] Privacy manifest is present in the built app bundle.

## External distribution prerequisites

- [ ] Final App Icon is supplied and added to the asset catalog.
- [ ] App target points to the AppIcon asset.
- [ ] Apple Developer signing team is selected.
- [ ] Bundle identifier ownership/registration is confirmed.
- [ ] Archive succeeds with distribution signing.
- [ ] TestFlight upload succeeds.

## Decision

**V0.10 engineering freeze: PENDING CI AND RELEASE-ASSET GAPS.**
