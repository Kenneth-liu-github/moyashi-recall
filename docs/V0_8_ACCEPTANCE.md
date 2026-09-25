# V0.8 Acceptance Checklist

## Automated engineering gate

Validated by GitHub Actions run #166 on commit `74bea8ce146e191b3282c346258da11333545394`.

- [x] Portable Linux core tests
- [x] Full macOS Swift package tests
- [x] SwiftData/data-layer tests
- [x] iOS Simulator build
- [x] V0.1–V0.7 regression coverage

## Backup validation

- [x] Malformed JSON is rejected.
- [x] Unsupported schema versions are rejected.
- [x] Oversized backups are rejected.
- [x] File size is checked before loading the selected file into memory.
- [x] Record-count safety limits are enforced.
- [x] Duplicate primary IDs are rejected.
- [x] Duplicate Source semantic identities are rejected.
- [x] Duplicate Knowledge semantic identities are rejected.
- [x] Duplicate Flashcard semantic identities are rejected.
- [x] Dangling entity relationships are rejected.
- [x] Invalid review ratings and learning states are rejected.
- [x] Negative/non-finite scheduling values are rejected.

## Restore semantics

- [x] Restore into an empty database preserves IDs and relationships.
- [x] Newer local Source/Knowledge/Card data is not regressed by an older backup.
- [x] Newer local FSRS state is not regressed.
- [x] Newer backup records can update older local records.
- [x] Local-only records are not deleted.
- [x] Review History is preserved and deduplicated.
- [x] Legacy records with missing stable keys may be safely enriched.
- [x] Conflicting Source UUID identity is rejected.
- [x] Conflicting Knowledge UUID identity is rejected.
- [x] Conflicting Flashcard UUID identity is rejected.
- [x] Identity conflicts are detected before the mutation phase.
- [x] Restore uses a controlled autosave-disabled write window.

## UX and privacy

- [x] Restore is available only from JSON backup selection.
- [x] Backup counts are shown before confirmation.
- [x] Restore requires explicit user confirmation.
- [x] UI explains the non-destructive merge behavior.
- [x] Notion tokens are not imported.
- [x] AI API keys are not imported.
- [x] Keychain credentials are not imported.
- [x] UserDefaults/app settings are not imported.

## Interactive release-readiness smoke checks

These require hands-on simulator/device use and are not claimed as automated:

- [ ] Export a real JSON backup, then select it through the Files/iCloud picker.
- [ ] Verify the preview counts match the backup.
- [ ] Cancel at the confirmation dialog and verify nothing changes.
- [ ] Restore into a device that already contains newer and local-only learning data.
- [ ] Reopen Library, Home, Study Scope, and Review History after restore.
- [ ] Confirm restored content appears without duplicate or stale UI state.

## Freeze decision

**V0.8 engineering freeze: PASSED.**
