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

## Current state

V0.12 branch created from the latest mainline. Release-archive gate implementation pending validation.
