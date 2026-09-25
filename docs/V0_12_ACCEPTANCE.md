# V0.12 Acceptance — Release Archive Gate

## Automated engineering gate

- [x] Portable Linux core tests pass.
- [x] Full macOS / SwiftData tests pass.
- [x] Debug iOS Simulator build passes.
- [x] Release metadata audit passes with no engineering-controlled failure.
- [x] Unsigned Release archive succeeds for generic iOS.
- [x] Archived app bundle exists.
- [x] PrivacyInfo.xcprivacy is present in the archived app.
- [x] V0.1–V0.11 regression suite remains green.

## Privacy and distribution metadata

- [x] Privacy manifest exists and is bundled.
- [x] Tracking is declared false.
- [x] Required-reason declarations cover UserDefaults and file timestamps.
- [x] App Store Connect privacy disclosure remains explicitly separate from the privacy manifest.
- [x] AI-provider data handling is documented as a release-policy disclosure item.
- [ ] Public Privacy Policy URL is supplied in App Store Connect.
- [ ] App Store Connect data-collection answers are finalized against the shipping AI-provider configuration.

## External distribution prerequisites

- [ ] Final App Icon is supplied.
- [ ] Assets.xcassets/AppIcon.appiconset is added and wired to the target.
- [ ] Apple Developer signing team is selected.
- [ ] com.moyashi.recall ownership/registration is confirmed.
- [ ] Signed Archive succeeds.
- [ ] TestFlight upload succeeds.
- [ ] Physical-device end-to-end smoke test passes.

## Decision

**V0.12 engineering freeze: PASSED. TestFlight/App Store distribution remains pending external prerequisites.**
