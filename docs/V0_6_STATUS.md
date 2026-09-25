# V0.6 Status — Local File Ingestion

## Goal

Expand Moyashi Recall beyond Notion so users can import their own learning files directly from iPhone/iPad while keeping the same normalized pipeline:

Source → Source Document → AI Knowledge Extraction → Flashcards → Review → FSRS.

## Implemented

### Local file ingestion

Supported initial formats:

- PDF
- TXT
- Markdown
- PNG
- JPG / JPEG
- HEIC

### PDF handling

- Uses PDFKit on Apple platforms.
- Extracts text page by page.
- Stores the PDF itself as a root container.
- Stores each non-empty page as its own child Source Document.
- Preserves page-level traceability:
  - filename
  - page number
  - source hierarchy
- Re-importing the same PDF updates existing pages idempotently.
- Pages removed from a later complete re-import are marked inactive rather than deleted.

### Text / Markdown

- Reads UTF-8 first, then Unicode fallback.
- Rejects empty documents.
- Imports one file as one Source Document.
- Re-importing the same file updates existing content instead of duplicating it.

### Images

- Uses Apple Vision on supported platforms.
- Performs on-device text recognition.
- Recognition languages prioritize:
  - Japanese
  - Simplified Chinese
  - English
- OCR text enters the same AI extraction/card-generation pipeline as Notion/PDF/text sources.
- Platforms without Vision fail explicitly rather than silently.

### Source identity and privacy

- Local filesystem paths are not stored in Source Documents.
- External IDs use a deterministic path hash to distinguish same-named files from different locations.
- Each imported file receives a collision-resistant source key.
- User-visible source paths remain clean:
  - Imported Files / filename
  - Imported Files / filename / Page N

### Library UX

- Added multi-file import from the Library toolbar.
- Supports selecting multiple files at once.
- Uses security-scoped file access.
- File parsing happens off the MainActor.
- Persisting parsed Source Documents happens on the MainActor.
- Library now shows both Notion and local file sources.
- PDF root containers are labeled as containers instead of incorrectly showing “AI update required”.
- AI generation remains available on text-bearing child units/pages.

## Quality and test coverage

Added tests for:

- TXT import
- Markdown import
- empty-text rejection
- unsupported-extension rejection
- same-named files in different folders producing distinct IDs/source keys
- source-key grouping
- idempotent local-file re-import
- changed-content update behavior
- no-Vision image fallback

No new force unwraps or TODO/FIXME markers were introduced in the V0.6 branch.

## Remaining V0.6 work

- Add Apple-platform PDF extraction tests.
- Add Apple-platform Vision OCR tests where practical.
- Improve import error feedback by file/type.
- Add file-source removal/archive UX.
- Add Word (.docx) ingestion strategy.
- Consider PowerPoint/Excel text extraction after DOCX architecture is settled.
- Full Xcode/iOS Simulator validation when GitHub Actions runners can execute normally.

V0.6 is currently an active stacked feature branch and is not ready to merge yet.
