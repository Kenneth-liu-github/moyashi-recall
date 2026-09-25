# V0.11 Acceptance Checklist

## Versioned schema

- [x] VersionedSchema V1 exists.
- [x] V1 has an explicit schema version identifier.
- [x] SchemaMigrationPlan exists.
- [x] App uses the versioned schema/migration plan for its default persistent container.
- [x] Container creation failure does not delete the store.
- [x] App does not use `try!` or `fatalError` for persistence startup.

## Backward compatibility

- [x] Test creates a real legacy unversioned on-disk store.
- [x] Legacy store contains persisted learning data before migration.
- [x] Same store opens through VersionedSchema V1.
- [x] Persisted record survives migration.
- [x] Persisted content survives migration.
- [x] Persisted source identity survives migration.

## Regression

- [x] Portable Linux core tests pass.
- [x] Full macOS / SwiftData tests pass.
- [x] iOS Simulator build passes.
- [x] V0.1–V0.10 regression remains green.

## Decision

**V0.11 engineering freeze: PASSED.**
