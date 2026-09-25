# V0.10 Acceptance — Pre-1.0 Release Hardening

## Automated engineering

- [ ] Portable Linux core tests pass.
- [ ] Full macOS / SwiftData tests pass.
- [ ] iOS Simulator build passes.
- [ ] Release project audit passes.
- [ ] V0.1–V0.9 regression suite remains green.

## Release project audit

- [x] Generated Info.plist is intentional.
- [x] PrivacyInfo.xcprivacy exists and is included in app resources.
- [x] UserDefaults required-reason declaration is present.
- [x] File timestamp required-reason declaration is present.
- [x] Bundle identifier is explicit.
- [x] Marketing version and build number are explicit.
- [ ] App icon / asset catalog is present and configured.
- [ ] Archive/signing is verified with an Apple Development/Distribution team.

## Data durability

- [x] V0.8 backup/restore safety gate is frozen.
- [ ] Formal SwiftData versioned-schema baseline is merged and validated.
- [ ] Legacy unversioned store compatibility is proven.
- [ ] App startup fails safely if the durable store cannot be opened.

## Manual device/TestFlight smoke checks

These are deliberately not claimed by CI:

- [ ] Install/launch on a physical iPhone.
- [ ] Connect Notion with a real integration token and sync a representative hierarchy.
- [ ] Import TXT/Markdown/CSV, PDF, rich document, and image OCR samples.
- [ ] Configure a real AI provider and generate learning content.
- [ ] Run Study Scope → Review → FSRS update end to end.
- [ ] Verify Japanese TTS on device.
- [ ] Request and receive a daily reminder notification.
- [ ] Export a backup through Files/iCloud.
- [ ] Restore that backup into a device containing newer/local-only data.
- [ ] Kill and relaunch the app; verify Home/Library/History consistency.
- [ ] Produce an Archive suitable for TestFlight upload.

## Freeze decision

**V0.10 engineering freeze: PENDING.**
