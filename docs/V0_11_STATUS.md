# V0.11 Status — SwiftData Versioned Schema Baseline

## Goal

Establish an explicit, tested SwiftData schema version and migration-plan baseline before external TestFlight users accumulate durable learning history.

## Implemented

- Added `MoyashiRecallSchemaV1` with schema version `1.0.0`.
- Added `MoyashiRecallMigrationPlan`.
- Added `MoyashiRecallModelContainerFactory` as the canonical container creation path.
- Switched the App from implicit model-type container creation to the versioned schema + migration plan.
- App startup no longer assumes container creation must succeed.
- Persistence-open failure shows a blocking recovery UI instead of:
  - crashing with `fatalError`,
  - using `try!`,
  - silently recreating/deleting the store.

## Legacy-store compatibility

A dedicated macOS SwiftData test creates a real pre-V0.11 unversioned disk store, writes data, then reopens the exact same store using V1 VersionedSchema + MigrationPlan.

The test verifies that the existing record survives with its title, content, and external source identity unchanged.

## Validation

GitHub Actions run #174 passed on commit:

`0cca3cebef04853722b663b33fc2f9efc3c4846f`

Results:

- portable Linux core tests: passed
- full macOS SwiftData regression suite: passed
- legacy unversioned-store compatibility test: passed
- versioned App container compiled successfully
- iOS Simulator build: passed
- V0.1–V0.10 regression gate: passed

## Future migration rule

Any future incompatible persistence change must:

1. preserve `MoyashiRecallSchemaV1` as a historical schema,
2. add a new VersionedSchema,
3. add an explicit MigrationStage,
4. test migration from the previous shipping schema using an on-disk store,
5. never use store deletion/recreation as a production migration strategy.

## Freeze state

**V0.11 engineering freeze: PASSED.**
