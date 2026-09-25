# Distribution Handoff — TestFlight / App Store

This checklist begins after the automated V0.12 engineering gate has passed.

## 1. Final App Icon

Engineering has already created and wired:

- `App/MoyashiRecall/Assets.xcassets`
- `AppIcon.appiconset`
- target setting `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`

Remaining action:

- provide the approved final 1024 × 1024 App Icon image,
- add the image to `AppIcon.appiconset`,
- update `Contents.json` with the image filename if Xcode does not do so automatically,
- rerun `bash scripts/validate-macos.sh`.

Do not use a temporary engineering icon for App Store submission.

## 2. Apple Developer signing

In Xcode:

1. Open `App/MoyashiRecall.xcodeproj`.
2. Select target `MoyashiRecallApp`.
3. Open **Signing & Capabilities**.
4. Keep **Automatically manage signing** enabled unless the distribution workflow requires manual signing.
5. Select the intended Apple Developer Team.
6. Confirm the Release configuration resolves a valid distribution signing identity.

The Team ID is account-specific and is intentionally not committed to source control.

## 3. Bundle identifier

Current source identifier:

`com.moyashi.recall`

Before the first uploaded build:

- verify or register this exact Bundle ID in the intended Apple Developer account,
- verify the same Bundle ID is selected in App Store Connect,
- do not upload a production build until the identifier decision is final.

Apple does not allow the Bundle ID of an existing App Store Connect app record to be changed after a build has been uploaded.

## 4. Privacy policy

A publication-ready draft is stored at:

`docs/PRIVACY_POLICY_DRAFT.md`

Before submission:

- replace every bracketed placeholder,
- review the final policy against the actual shipping provider configuration,
- publish it at a stable public HTTPS URL,
- enter that URL in App Store Connect → App Privacy.

## 5. App Store Connect privacy answers

The privacy manifest and App Store privacy questionnaire are separate release artifacts.

Before publishing App Privacy answers:

- confirm which AI providers are enabled in the shipping build,
- confirm their current account-specific retention/data controls,
- account for learning content sent to third-party providers,
- account for Notion data only when the user connects Notion,
- keep the answers consistent with the published privacy policy.

Do not answer “no data collected” solely because Moyashi Recall has no first-party server.

## 6. Signed archive

After App Icon, Team, and Bundle ID are ready:

1. Select **Any iOS Device (arm64)** / generic iOS destination.
2. Product → Archive.
3. Confirm the archive completes under Release configuration.
4. In Organizer, run **Validate App**.
5. Resolve signing, icon, privacy, entitlement, or metadata validation errors before upload.

The repository CI already proves that an unsigned generic-iOS Release archive can be produced.

## 7. TestFlight upload

From Xcode Organizer:

1. Distribute App.
2. Choose App Store Connect.
3. Upload.
4. Wait for App Store Connect processing.
5. Review processing warnings.
6. Add the build to an internal TestFlight group.

## 8. Physical-device smoke test

On a TestFlight-installed physical iPhone/iPad, execute the complete flow:

1. Launch and verify existing SwiftData store opens.
2. Import representative TXT/Markdown/CSV.
3. Import a PDF with multiple text-bearing pages.
4. Import a rich document.
5. Import an image and verify OCR.
6. Connect Notion and sync a representative hierarchy.
7. Configure a real AI provider.
8. Generate Knowledge Items and Flashcards.
9. Narrow Study Scope by source/document/card type.
10. Complete a review session and verify FSRS due dates change.
11. Play Japanese TTS.
12. Enable a local daily reminder and verify notification delivery.
13. Export a JSON backup through Files/iCloud.
14. Restore into a database containing newer/local-only data.
15. Force-quit and relaunch.
16. Verify Home, Library, Study Scope, Cards, and Review History remain consistent.

## 9. Release stop conditions

Do not submit for external testing or App Review if any of these are unresolved:

- final App Icon missing,
- signing invalid,
- Bundle ID mismatch,
- persistent-store migration failure,
- privacy policy URL unavailable,
- App Store privacy answers incomplete,
- TestFlight build crashes on launch,
- backup/restore corrupts or regresses learning state.
