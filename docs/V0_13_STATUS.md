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

## Current state

Engineering changes prepared. Full regression and Release archive validation pending.
