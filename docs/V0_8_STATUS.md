# V0.8 Status — Safe Learning-Data Restore

## Goal

Allow users to restore a Moyashi Recall JSON backup without deleting local-only data, regressing newer learning state, importing credentials, or silently accepting ambiguous/corrupt backup relationships.

## Implemented

### Import validation

- Supports backup schema `v1`.
- Rejects malformed JSON and unsupported schema versions.
- Enforces a 100 MB default backup-size limit.
- Checks file size before loading a selected backup into memory.
- Enforces bounded record counts for:
  - sources
  - knowledge items
  - flashcards
  - review states
  - Review History
- Rejects duplicate primary IDs.
- Rejects duplicate semantic identities for Source, Knowledge, and Flashcard records.
- Validates Source → Knowledge → Flashcard → Review State / History references.
- Rejects invalid review ratings, invalid FSRS states, negative values, and non-finite scheduling values.

### Safe merge restore

- Restore is non-destructive:
  - missing records are inserted,
  - older local records may be updated from newer backup records,
  - newer local learning content and FSRS state are preserved,
  - local-only records are never deleted.
- Source, Knowledge, and Flashcard IDs are remapped when a single safe semantic match already exists locally.
- Older legacy records with missing stable keys may be enriched by a valid backup.
- Existing non-empty stable identities cannot be silently replaced by conflicting backup identities.
- UUID identity collisions are rejected during preflight before any model mutation.
- All required local fetches occur before the merge mutation phase.
- Main-context autosave is disabled during the controlled write window and restored afterward.
- Failed writes call rollback.
- Review History is append/deduplicate oriented rather than destructive.

### Restore UX

- Settings → Data Backup supports JSON restore.
- The selected file is validated before restore is enabled.
- The user sees Source / Knowledge / Card / FSRS / Review History counts before restore.
- Restore requires an explicit confirmation dialog.
- The UI states that local-only/newer data will be preserved.
- Restore never imports app settings, Notion credentials, AI API keys, or other Keychain secrets.

## Security and privacy

- Restore service contains no Keychain, Notion-token, AI-credential, or UserDefaults access.
- No local entities are deleted as part of restore.
- Oversized backup files are rejected before `Data(contentsOf:)`.
- Backup content cannot overwrite a local object solely because it reuses the same UUID with a conflicting business identity.

## Validation

Engineering validation passed in GitHub Actions run #166.

Validated commit:

`74bea8ce146e191b3282c346258da11333545394`

Results:

- portable Linux core tests: passed
- backup validator tests: passed
- backup-size and semantic-duplicate tests: passed
- full macOS Swift package tests: passed
- SwiftData restore tests: passed
- identity-conflict preflight tests: passed
- V0.1–V0.7 regression suite: passed
- iOS Simulator build: passed

## Quality findings fixed during V0.8 integration

- Preserved V0.6 LocalFileImporter portable coverage while merging the older V0.8 Package.swift.
- Added raw backup-size validation and pre-load file-size checking.
- Prevented semantic duplicate collapse during restore.
- Prevented sources with empty external IDs from being semantically collapsed.
- Added UUID/business-identity collision protection.
- Added backward-compatible stable-key enrichment for legacy records.
- Replaced mutation-then-rollback conflict handling with conflict preflight before any mutation after SwiftData tests demonstrated that relying on rollback alone was not strong enough for the desired safety guarantee.

## Freeze state

**V0.8 engineering freeze: PASSED.**

Interactive release-readiness checks remain for:
- selecting a real exported backup from Files/iCloud,
- reviewing the restore preview and confirmation flow on device,
- restoring a realistic backup into a device with existing local learning data,
- reopening Home/Library/History after restore to confirm UI refresh behavior.
