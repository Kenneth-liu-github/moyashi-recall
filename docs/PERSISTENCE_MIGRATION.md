# Persistence and Migration Policy

Moyashi Recall uses SwiftData for local learning state.

## Current entity boundary

- `SourceDocumentEntity`: normalized imported source material and source-sync metadata.
- `KnowledgeItemEntity`: semantic learning units extracted from source documents.
- `FlashcardEntity`: generated review cards linked to a Knowledge Item and, when available, its Source Document.
- `ReviewStateEntity`: current FSRS scheduling state.
- `ReviewHistoryEntity`: immutable review-event history.

## V0.3 → V0.4 migration assessment

V0.4 introduces semantic AI fields on Knowledge Items, generated-card metadata, and AI freshness metadata on Source Documents.

New V0.4 persisted fields are optional or carry stored defaults so an existing V0.2/V0.3 development store can migrate additively.

V0.3 Knowledge Item source-sync columns are intentionally retained as compatibility fields. New imports no longer use those columns; imported source pages live in `SourceDocumentEntity`. The compatibility columns will only be removed in a future explicit versioned migration.

Review entities are not structurally coupled to source synchronization and are intentionally preserved.

## Data-preservation rules

1. Never delete Review History as part of source synchronization or AI regeneration.
2. A page removed from a complete source sync is marked inactive instead of deleting its Source Document.
3. A partial/bounded source sync must never deactivate unseen pages.
4. Re-imports use source kind + external source ID for idempotent Source Document upsert.
5. AI Knowledge Items use source document + stable extraction key, with semantic fallback matching to survive provider key drift.
6. Generated cards use Knowledge Item + stable generation key, with card-face fallback matching to preserve card IDs and FSRS history when an AI key changes.
7. AI outputs removed from a later successful generation are marked inactive instead of deleted.
8. Inactive cards are excluded from review sessions, counts, and new Review writes.
9. An empty AI rerun cannot deactivate existing active learning data.
10. New persistence fields remain additive/defaulted until an explicit versioned migration is introduced.

## AI freshness

A Source Document stores:

- last successful AI-processing time,
- the source-document update timestamp used for that processing,
- the AI provider ID used for the latest successful generation,
- the model ID used for the latest successful generation.

When the source changes later, Library marks the AI result as stale until knowledge/cards are regenerated successfully.

## Future incompatible schema changes

Before any incompatible schema change, introduce a SwiftData `VersionedSchema` and `SchemaMigrationPlan`. Store recreation is not an acceptable production migration strategy.

No V0.4 code path intentionally deletes the local SwiftData store or review history.


## V0.11 versioned schema baseline

Before the first external TestFlight data becomes a durable compatibility commitment, Moyashi Recall establishes an explicit SwiftData schema baseline:

- `MoyashiRecallSchemaV1` uses `Schema.Version(1, 0, 0)`.
- `MoyashiRecallMigrationPlan` is now the canonical migration-plan entry point.
- The App creates its persistent container from `Schema(versionedSchema: MoyashiRecallSchemaV1.self)`.
- Container creation failure does not delete or recreate the local store. The App displays a blocking recovery message instead.
- Future incompatible model changes must add a new VersionedSchema and an explicit MigrationStage.

Compatibility was proven with an on-disk migration test that:

1. creates the pre-V0.11 unversioned schema,
2. writes a real SourceDocument to a temporary SQLite store,
3. closes that container,
4. reopens the same store through the V1 VersionedSchema + MigrationPlan,
5. verifies the persisted record and content are preserved.

This test passed in GitHub Actions run #174.
