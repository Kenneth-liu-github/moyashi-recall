# V0.2 Data + FSRS Status

Status: **feature complete for the V0.2 scope; pending final CI confirmation and visual simulator acceptance.**

## Completed

- SwiftData schema for KnowledgeItem, Flashcard, ReviewState, ReviewHistory
- stable source keys and source traceability
- due-card queue with source filters and session limits
- real multi-card review sessions
- persisted ReviewState + ReviewHistory
- home due-count and streak derived from persistence
- repository boundary between SwiftUI and SwiftData/services
- FSRS-6 canonical 21-parameter core
- desired-retention interval calculation
- parameter-bound validation
- calendar-day due scheduling across DST
- demo-data migration/idempotency
- failure and empty-state handling
- automated tests for queueing, persistence, repository behavior, seeding, FSRS reference math, and DST behavior
- GitHub Actions validation for Swift package/tests and iOS Simulator build

## Explicitly deferred beyond V0.2

- sub-day learning/relearning steps
- interval fuzzing
- personalized FSRS parameter optimization from user review history
- cloud sync
- Notion ingestion
- AI knowledge extraction/card generation

These are intentionally deferred so V0.2 stays focused on a stable local learning and scheduling foundation.

## Exit criteria

V0.2 is ready to freeze when:
1. the latest branch commit is green in package tests and iOS Simulator build;
2. no open blocking regression is found in a final edge-case review;
3. the current simulator UI is accepted as the baseline for V0.3.
