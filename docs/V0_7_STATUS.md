# V0.7 Status — Granular Study Scope, Diagnostics & Data Export

## Goal

Make review scope more precise while improving release readiness, diagnostics, onboarding, and backup capability.

## Implemented

### Granular Study Scope
- Source-level, document/page-level, and card-type filtering.
- Stable `SourceDocumentEntity.id` scope persisted in last-used preferences and named presets.
- Works with Notion pages, PDF pages, and imported Word/text/image documents.
- Per-document total-card and due-card counts.
- Explicit Select All / Clear document actions.
- Empty document scope means no cards and never broadens silently.
- Legacy V0.5 preferences/presets without document IDs remain backward-compatible.
- Review-count value `0` means all currently due cards in the selected scope.

### Release readiness and diagnostics
- System Status screen with Notion, learning-source, AI, knowledge/card, due, history, and latest-review diagnostics.
- Credential checks expose presence only; secret values are never shown.
- App version/build reporting and manual refresh.
- First-run guidance is source-agnostic:
  - local files are a valid learning source,
  - Notion is optional rather than mandatory,
  - AI setup is requested only after learning material exists,
  - users with generated cards do not see onboarding guidance.
- Keychain read failures degrade to “not configured” rather than breaking diagnostics.

### Learning-data export
- Native JSON file export from Settings.
- Versioned schema `v1`.
- Includes source documents, generated knowledge, flashcards, FSRS states, Review History, inactive preservation records, and AI provenance metadata.
- ISO-8601 dates and deterministic ordering.
- Excludes Notion tokens, AI API keys, Keychain credentials, passwords, and other secrets.
- No destructive restore path is introduced in V0.7.

## Validation

Engineering validation is green:

- Granular Study Scope validation: run #150
- Combined V0.7 validation: run #153
- combined commit: `60cef505519ce1364d610d82325e08915d6938d5`
- portable Linux core tests: passed
- full macOS Swift package / SwiftData tests: passed
- iOS Simulator build: passed
- V0.6 reminders, Japanese TTS, local-file ingestion, and earlier milestones remained in the regression suite

## Quality checks

- Explicit `nil` vs empty document-scope semantics are covered by tests.
- Local-file learning can satisfy readiness without Notion.
- Export tests cover JSON round-trip, deterministic ordering, inactive-card/history preservation, and absence of credential field names.
- No new production `try!`, `fatalError`, TODO, or FIXME markers were identified during the V0.7 audit.
- PR #10 and PR #8 were both merge-clean before integration.

## Freeze state

**V0.7 engineering freeze: PASSED.**

Remaining interactive checks belong to release readiness rather than engineering freeze:
- large Notion/PDF hierarchy UX
- real local/iCloud document-picker flow
- diagnostics navigation on device
- JSON file-export UX and Files app destination handling
