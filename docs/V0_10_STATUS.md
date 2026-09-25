# V0.10 Status — Pre-1.0 Release Hardening

## Goal

Turn the consolidated V0.9 mainline into a release-ready pre-1.0 baseline without broadening product scope.

## Audit findings

The core product pipeline is implemented and regression-tested, but release readiness still needs explicit closure around:

- real-device end-to-end smoke testing,
- App Store / TestFlight packaging assets and metadata,
- signing/team configuration outside source control,
- privacy-manifest consistency with the actual app behavior,
- migration and larger-data-set risk checks,
- release configuration and archive validation.

## Scope

V0.10 is a hardening milestone, not a feature milestone.

1. Release packaging and project completeness.
2. Privacy/resource audit.
3. Data migration and performance risk audit.
4. End-to-end smoke-test runbook.
5. Full Linux + macOS/SwiftData + iOS Simulator regression gate.
6. Final handoff checklist for TestFlight/device validation.

## Current repository observations

- iOS deployment target: 17.0.
- Current project marketing version: 0.10.0.
- Current build number: 10.
- Bundle identifier: com.moyashi.recall.
- Privacy manifest is present and included in app resources.
- The privacy manifest declares UserDefaults and file-timestamp required-reason API usage.
- No asset catalog / AppIcon resource is currently represented in the Xcode project.
- Signing is Automatic, but no development team is committed to the project.
- Notifications are requested at runtime by the reminder feature and do not require an Info.plist usage-description key.
- The app uses generated Info.plist configuration.

## Exit criteria

V0.10 engineering freeze requires:

- project-level release gaps documented and code-fixable gaps repaired,
- automated release audit added,
- full regression validation green,
- no regression in V0.1–V0.9 capabilities,
- remaining manual/device/App Store Connect steps explicitly separated from automated engineering claims.
