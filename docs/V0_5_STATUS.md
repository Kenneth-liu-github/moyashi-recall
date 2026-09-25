# V0.5 Status — Complete Learning Loop

## Goal

Turn the V0.4 ingestion + AI generation stack into a daily-use learning product with a complete study loop, live analytics, targeted reinforcement, persistent study preferences, and review-history visibility.

## Implemented

- Real Home dashboard metrics from persisted Review History:
  - due cards
  - streak
  - reviewed today
  - reviews in the last 7 days
  - 7-day successful-recall rate
  - latest review timestamp
- Successful recall is defined as any non-Again rating; Hard still counts as successful retrieval.
- Recent weak knowledge is derived from real Hard/Again ratings over the last 14 days.
- Only weak knowledge that currently has due cards is surfaced for one-tap reinforcement.
- Home no longer contains static/mock weak-topic labels.
- One-tap “today review” from Home.
- Direct navigation from Home to:
  - Study Scope
  - Review History
  - targeted weak-item review
- Home shows the latest completed review-session summary when it is still consistent with Review History.
- Study Scope shows:
  - real total card count by source
  - real due-card count by source
  - source filtering
  - card-type filtering
  - card-type-aware per-source due counts
  - effective session size based on the currently filtered due queue
- Study Scope remembers the user's last:
  - selected sources
  - selected card types
  - review-count preference
- Named study presets:
  - save the current scope
  - update by reusing the same name
  - restore a saved scope
  - delete a saved scope
  - never silently broaden a stale preset to unrelated sources
- Review session completion summary shows Again / Hard / Good / Easy counts.
- Latest completed session is persisted for Home.
- Recent Review History:
  - grouped by day
  - searchable by prompt, answer, or source
  - filterable by Again / Hard / Good / Easy
  - includes historical events for cards that later become inactive
- Review queues can target one or more Knowledge Items directly.
- Historical dashboard metrics remain stable even when old cards later become inactive.

## Quality fixes

- Fixed Study Scope due counts so both source and card-type filters are included.
- Fixed per-source due counts so they update when card-type selection changes.
- Fixed 7-day success-rate semantics: Hard counts as successful recall; only Again counts as failed recall.
- Kept streak and review-history statistics based on all historical events rather than only currently active cards.
- Weak-item shortcuts only target currently due knowledge to avoid dead-end reinforcement screens.
- Stale saved scopes/presets are not silently expanded to all sources.
- Stale session summaries are hidden after newer review activity or a reset history.
- New V0.5 error text stays inside the four-color product palette.
- Removed force unwraps from new V0.5 test fixtures.

## Test coverage added

- real per-source due counts
- card-type-aware filtered due counts
- Home dashboard metrics
- latest-review timestamp
- weak-knowledge ranking
- targeted weak-item review queue
- review-history preservation for inactive cards
- Study Scope preference persistence
- named study preset create/update/delete
- latest review-session summary persistence

Portable Linux package validation also includes the pure Foundation-based V0.5 preference/preset/session-summary stores.

## Validation state

A controlled GitHub Actions attempt was made on the V0.5 branch. Both Linux core tests and macOS/iOS jobs were created but failed before their first workflow step started; GitHub returned no executed steps. Automatic triggering was therefore returned to manual-only mode to avoid producing misleading red runs.

The remaining release gate is still a normal environment that can actually execute:

1. the full Swift package test suite,
2. SwiftData/data-layer tests,
3. the iOS Simulator build.

## V0.5 completion state

Feature implementation is complete enough to be treated as a **V0.5 freeze candidate**.

Do not merge the stacked Draft PR until a normal macOS/Xcode validation pass is available.
