# Persistence and Migration Policy

Moyashi Recall uses SwiftData for local learning state.

## V0.3 migration assessment

The V0.3 Notion work extends `KnowledgeItemEntity` with import metadata such as:

- external source ID
- parent/root source IDs
- source path and source key
- hierarchy depth
- source active state
- source last-edited timestamp
- local last-sync timestamp

All fields introduced during V0.3 are either optional or have explicit defaults. Existing V0.2 records therefore do not require destructive migration.

Existing review entities are unchanged:

- `FlashcardEntity`
- `ReviewStateEntity`
- `ReviewHistoryEntity`

This is intentional: source ingestion changes must not invalidate spaced-repetition history.

## Data-preservation rules

1. Never delete review history as part of source synchronization.
2. A page removed from a complete source sync is marked inactive instead of deleting its Knowledge Item.
3. A partial/bounded sync must never deactivate unseen pages.
4. Re-imports use source kind + external source ID for idempotent upsert.
5. New persistence fields should remain additive/defaulted until an explicit versioned migration is introduced.
6. Before any future incompatible schema change, introduce a SwiftData `VersionedSchema` and `SchemaMigrationPlan` rather than relying on store recreation.

## Current upgrade behavior

Older imported records with newly added metadata receive safe defaults. The next successful Notion tree sync backfills their root ID, parent ID, path, category key, edit time, sync time, and active state.

No code path in V0.3 intentionally deletes the local SwiftData store.
