# V0.7 Acceptance Checklist

## Automated engineering gate

Validated by GitHub Actions:

- [x] Granular Study Scope run #150
- [x] Combined V0.7 run #153
- [x] Portable Linux core tests
- [x] Full macOS Swift package tests
- [x] SwiftData/data-layer tests
- [x] iOS Simulator build
- [x] V0.6 regression coverage

## Granular Study Scope

- [x] Filter by source.
- [x] Filter by concrete source document/page.
- [x] Filter by card type.
- [x] Persist document IDs in last-used Study Scope.
- [x] Persist document IDs in named presets.
- [x] Legacy presets/preferences without document IDs remain usable.
- [x] Explicit empty document scope returns no cards.
- [x] Adding a source does not re-select manually excluded documents from other sources.
- [x] Card-type changes preserve a narrowed document subset.
- [x] “All due” review-count semantics use `reviewCount = 0`.

## Readiness and diagnostics

- [x] Diagnostics expose credential presence only.
- [x] Notion status remains independently visible.
- [x] Local files can satisfy learning-source readiness without Notion.
- [x] First-run guidance is source-agnostic.
- [x] AI setup is requested only after learning material exists.
- [x] Active card, due card, knowledge, Review History, and latest review metrics are reported.
- [x] Keychain read failures degrade safely.

## Learning-data export

- [x] Export produces a JSON document.
- [x] Export includes source documents, knowledge, cards, FSRS states, and Review History.
- [x] Inactive records needed for historical preservation are included.
- [x] Dates use ISO-8601.
- [x] Ordering is deterministic.
- [x] Schema is versioned as `v1`.
- [x] Export contains no Notion token, AI API key, Keychain credential, password, or secret fields.
- [x] Export generation does not mutate local learning data.

## Regression

- [x] V0.6 reminders remain integrated.
- [x] V0.6 Japanese TTS remains integrated.
- [x] V0.6 local-file ingestion remains integrated.
- [x] V0.5 dashboard/history/presets/weak-item review remain covered.
- [x] V0.4 AI extraction and V0.3 Notion ingestion remain covered.

## Interactive release-readiness smoke checks

These require hands-on simulator/device use and are not claimed as automated:

- [ ] Exercise granular Study Scope with a large Notion/PDF hierarchy.
- [ ] Import real local/iCloud files and confirm navigation into Study Scope.
- [ ] Open Diagnostics and follow recovery links on device.
- [ ] Export JSON through the system file exporter and confirm Files-app behavior.
- [ ] Inspect an exported JSON file manually for expected content and readability.

## Freeze decision

**V0.7 engineering freeze: PASSED.**
