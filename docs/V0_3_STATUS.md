# V0.3 Status — Notion Integration

## Goal

Connect Moyashi Recall to Notion as the first real learning-content source while keeping the ingestion architecture source-agnostic for future PDF, Word, images, audio, and other inputs.

## Completed

- Source-agnostic `ImportedDocument` and `LearningContentSource` contracts.
- Notion REST client pinned to API version `2026-03-11`.
- Secure Notion token storage in Apple Keychain.
- Notion page search with pagination.
- Page retrieval and recursive block retrieval with pagination.
- Block normalization for paragraphs, headings, lists, toggles, quotes, code, tables, equations, child pages, and child databases.
- Root-page tree import with bounded depth and page count.
- Each Notion page is imported as its own local Knowledge Item.
- Parent page ID, selected root page ID, hierarchy depth, and full source path are persisted.
- Stable learning-source keys are derived from the Notion hierarchy.
- Imported documents are upserted idempotently by source kind + external page ID.
- Source edit timestamps and local sync timestamps are stored.
- Pages removed from a re-synced Notion tree are marked inactive instead of being deleted, preserving downstream learning history.
- Library UI displays the imported Notion page hierarchy.
- Settings UI supports token save/delete, page search, root selection, connection test, and root-tree sync.
- Unit tests cover pagination, recursive blocks, hierarchy metadata, source-key stability, sync idempotency, and stale-page reconciliation.

## Known CI constraint

Automatic GitHub Actions execution is temporarily paused because jobs are being created but fail before the first workflow step starts. The workflow is kept available through manual dispatch. Portable core tests have been isolated so that, once Actions execution is restored, FSRS and Notion core validation can run on Linux while the iOS simulator build remains a separate macOS validation.

## Remaining V0.3 work

- Add a sync result/report model for inserted, updated, unchanged, and deactivated pages.
- Improve incremental sync so unchanged pages can avoid unnecessary block downloads.
- Add imported-page detail/preview in Library.
- Add explicit sync state and last-sync feedback to the Notion settings flow.
- Final migration/edge-case review and manual iOS simulator validation when GitHub Actions can start jobs normally.

V0.3 remains a draft integration branch and should not be merged until final validation is available.
