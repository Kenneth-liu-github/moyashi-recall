# V0.5 Status — Complete Learning Loop

## Goal

Turn the V0.4 ingestion + AI generation stack into a daily-use learning product with a complete study loop, live analytics, targeted reinforcement, and persistent study preferences.

## Implemented

- Real Home dashboard metrics from persisted Review History:
  - due cards
  - streak
  - reviewed today
  - reviews in the last 7 days
  - 7-day successful-recall rate
- Successful recall is defined as any non-Again rating; Hard still counts as a successful retrieval.
- Recent weak knowledge is derived from real Hard/Again ratings over the last 14 days.
- Only weak knowledge that currently has due cards is surfaced for one-tap reinforcement.
- Home no longer contains static/mock weak-topic labels.
- One-tap “today review” from Home.
- Direct navigation from Home to:
  - Study Scope
  - Review History
  - targeted weak-item review
- Study Scope shows:
  - real total card count by source
  - real due-card count by source
  - source filtering
  - card-type filtering
  - effective session size based on the currently filtered due queue
- Study Scope remembers the user's last:
  - selected sources
  - selected card types
  - review-count preference
- Review session completion summary shows Again / Hard / Good / Easy counts.
- Recent Review History screen displays persisted historical review events, including history for cards that later become inactive.
- Review queues can target one or more Knowledge Items directly.
- Historical dashboard metrics remain stable even when old cards later become inactive.

## Quality fixes

- Fixed Study Scope due counts so card-type filters are included.
- Fixed 7-day success-rate semantics: Hard counts as successful recall; only Again counts as failed recall.
- Kept streak and review-history statistics based on all historical events rather than only currently active cards.
- Weak-item shortcuts only target currently due knowledge to avoid dead-end reinforcement screens.
- Removed force unwraps from new V0.5 dashboard test fixtures.

## Test coverage added

- real per-source due counts
- card-type-aware filtered due counts
- Home dashboard metrics
- weak-knowledge ranking
- targeted weak-item review queue
- review-history preservation for inactive cards
- Study Scope preference persistence

## Remaining V0.5 work

- Add named/saved study presets beyond the automatically restored last scope.
- Improve Review History grouping/filtering.
- Add a compact session summary back to Home after review.
- Final edge-case pass for empty queues, deleted sources, and stale preferences.
- Full macOS/Xcode + iOS Simulator validation when the runner environment can execute jobs normally.

V0.5 remains a stacked Draft PR on top of V0.4.
