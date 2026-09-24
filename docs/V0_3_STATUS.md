# V0.3 Status — Notion Integration

## Goal

Connect Moyashi Recall to Notion as the first real learning-content source while keeping the ingestion architecture source-agnostic for future PDF, Word, images, audio, and other inputs.

## Completed

- Source-agnostic `ImportedDocument` and `LearningContentSource` contracts.
- Notion REST client pinned to API version `2026-03-11`.
- Secure Notion token storage in Apple Keychain.
- Notion page search with pagination.
- Page retrieval and recursive block retrieval with pagination.
- Rate-limit handling that respects `Retry-After`.
- Block normalization for paragraphs, headings, lists, toggles, quotes, code, tables, equations, child pages, and child databases.
- Root-page tree import with bounded depth and page count.
- Each Notion page is imported as its own local Knowledge Item.
- Parent page ID, selected root page ID, hierarchy depth, and full source path are persisted.
- Stable learning-source keys are derived from the Notion hierarchy, including collision-safe deterministic fallbacks for non-Latin titles.
- Imported documents are upserted idempotently by source kind + external page ID.
- Sync results classify inserted, updated, unchanged, and deactivated pages.
- Source edit timestamps and local sync timestamps are stored.
- Pages removed from a complete re-synced Notion tree are marked inactive instead of being deleted, preserving downstream learning history.
- Partial/bounded syncs never deactivate unseen local pages.
- Library UI displays the imported Notion page hierarchy.
- Imported pages can be opened in Library for normalized-content preview and source/sync metadata.
- Settings UI supports token save/delete, page search, root selection, connection test, root-tree sync, and detailed sync feedback.
- Unit tests cover pagination, recursive blocks, hierarchy metadata, source-key stability, rate-limit retry, sync idempotency, mutation classification, stale-page reconciliation, and partial-sync safety.

## CI state

Automatic GitHub Actions execution is temporarily paused because jobs are being created but fail before the first workflow step starts. Historical red runs remain visible in GitHub, but new commits on the feature branches no longer create additional failed runs.

The workflow is still available through manual dispatch. Portable core tests have been isolated so that, once Actions execution is restored, FSRS and Notion core validation can run on Linux while the iOS simulator build remains a separate macOS validation.

## Remaining V0.3 work

- Optional bandwidth optimization for unchanged leaf pages; current sync already avoids duplicate local records and duplicate writes but still traverses the selected Notion tree to discover hierarchy.
- Final SwiftData migration/upgrade review.
- Manual iOS simulator validation when GitHub Actions can start jobs normally.
- Final V0.3 code review and freeze decision.

V0.3 remains a draft integration branch and should not be merged until final validation is available.
