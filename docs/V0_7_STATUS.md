# V0.7 Status — Granular Study Scope

## Goal

Let learners narrow a review session beyond a top-level source and down to specific imported documents/pages while preserving saved scopes and presets.

## Implemented

- Added page/document-level study scope using stable `SourceDocumentEntity.id` values.
- Review queue now supports:
  - source keys
  - card types
  - source document IDs
  - knowledge item IDs
- Study Scope now supports multi-select at three levels:
  - source
  - concrete document/page
  - card type
- Concrete scope works for:
  - Notion pages
  - PDF pages
  - imported Word/text/image documents
- Document rows show:
  - source path
  - total matching card count
  - due matching card count
- Added Select All / Clear document actions.
- Adding a new source selects documents only from that source and does not re-select manually excluded documents from existing sources.
- Card-type changes preserve a manually narrowed document subset; if the user had all documents selected, newly available documents remain selected.
- Filtered due count now includes document scope.
- Empty document scope explicitly means no cards and can never silently broaden to all cards.
- Review sessions receive the selected document IDs.
- Last-used Study Scope persists document IDs.
- Named presets persist document IDs.
- Old V0.5 preferences/presets that do not contain document IDs remain backward-compatible and are interpreted as all currently available documents.
- Added an explicit “全部 / すべて” review-count option:
  - stored as `reviewCount = 0`
  - means all currently due cards in the selected scope
  - positive counts remain bounded

## Quality fixes

- Removed an initial granular-scope loading defect where document selection was incorrectly required before documents could load.
- Removed an invalid repository parameter introduced during the first UI wiring pass.
- Fixed a stale parameter call after the document-selection API changed.
- Prevented adding a source from re-selecting documents the user had manually excluded from another source.
- Defined safe optional-scope semantics:
  - `nil` document IDs = unrestricted / legacy all-documents behavior
  - empty document IDs = intentionally no documents
- No production force unwraps, `try!`, `fatalError`, or unresolved TODO/FIXME markers were introduced in V0.7.

## Test coverage

Added/extended tests for:

- source-document filtered due queues
- source-document filtered due counts
- document-level card and due counts
- empty document scope never expanding to all cards
- legacy Study Scope JSON without document IDs
- legacy named preset JSON without document IDs
- named preset document-ID persistence
- all-due preset semantics

## Remaining validation gate

- Full SwiftData test suite on macOS/Xcode
- iOS Simulator build
- device/simulator UX pass with a large Notion/PDF hierarchy

V0.7 is a freeze candidate pending the Apple/Xcode validation gate.
