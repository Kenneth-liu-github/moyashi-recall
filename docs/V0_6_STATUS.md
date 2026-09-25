# V0.6 Status — Local File Ingestion

## Goal

Expand Moyashi Recall beyond Notion so users can import their own learning files directly from iPhone/iPad while keeping the same normalized pipeline:

Source → Source Document → AI Knowledge Extraction → Flashcards → Review → FSRS.

## Implemented

### Supported local formats

- PDF
- Word: DOCX / DOC
- RTF
- ODT
- TXT
- Markdown
- CSV / TSV
- PNG
- JPG / JPEG
- HEIC

### PDF handling

- Uses PDFKit on Apple platforms.
- Extracts text page by page.
- Stores the PDF itself as a root container.
- Stores each non-empty page as its own child Source Document.
- Preserves filename + page-number traceability.
- PDF pages are naturally ordered in Library (Page 1, Page 2, … Page 10).
- Re-importing the same PDF updates existing pages idempotently.
- Pages removed from a later complete re-import are marked inactive rather than deleted.
- Empty PDF roots are labeled as containers rather than incorrectly appearing AI-stale.

### Word / rich documents

- Uses Apple attributed-document reading APIs on supported platforms.
- Supports Office Open XML DOCX, legacy DOC, RTF, and ODT text extraction.
- Extracted text enters the same AI/card pipeline as Notion and PDF.
- Non-Apple platforms fail explicitly instead of silently.

### Text / Markdown / spreadsheet text

- Reads UTF-8 first, then Unicode fallback.
- Imports TXT and Markdown directly.
- Imports CSV/TSV as text-based spreadsheet sources.
- Rejects empty documents.

### Images

- Uses Apple Vision on supported platforms.
- Performs on-device text recognition.
- Recognition languages prioritize Japanese, Simplified Chinese, and English.
- OCR observations are ordered top-to-bottom and left-to-right before text is assembled.
- OCR text enters the same AI extraction/card-generation pipeline.
- Platforms without Vision fail explicitly.

### Source identity and privacy

- Local filesystem paths are never stored in Source Documents.
- A deterministic hash of the standardized path is used as local-file identity.
- Same-named files in different folders remain distinct.
- Re-importing the same path remains idempotent even when file contents are replaced atomically.
- Each file receives its own collision-resistant source key.
- User-visible paths stay clean:
  - Imported Files / filename
  - Imported Files / filename / Page N

### Library UX

- Multi-file import from the Library toolbar.
- Security-scoped file access.
- Parsing occurs off the MainActor; SwiftData persistence remains on the MainActor.
- Library now shows both Notion and local-file sources.
- Empty Library shows supported-format onboarding.
- Import result reports inserted / updated / unchanged / archived units.
- Per-file failures show a concrete reason.
- Imported file roots can be archived with confirmation.
- Archiving deactivates source documents and generated learning without deleting Review History.
- Imported filenames appear as separate Study Scope sources.

## Quality and tests

Added coverage for:

- TXT import
- Markdown import
- CSV import
- empty-file rejection
- unsupported-extension rejection
- same-named files in different folders
- source-key uniqueness
- idempotent local-file re-import
- changed-content update behavior
- removed PDF-page reconciliation
- file-source archive/history preservation
- imported filename Study Scope titles
- natural PDF page ordering
- non-Apple Vision fallback
- non-Apple rich-document fallback
- Apple-platform PDF text fixture
- Apple-platform DOCX fixture

No new production force unwraps, `try!`, `fatalError`, or unresolved TODO/FIXME markers are present in the V0.6 changes.

## Remaining V0.6 gates

- Execute Apple-platform PDF/DOCX/Vision tests in a working Xcode/macOS runner.
- Run the full SwiftData test suite.
- Run the iOS Simulator build.
- Perform a device/simulator UX pass for the system document picker and security-scoped URLs.

## Deferred formats

Native XLSX and PPTX structured extraction are intentionally deferred to the next ingestion milestone. CSV/TSV are supported now for spreadsheet-style text data.

## V0.6 completion state

Feature implementation is complete enough to be treated as a **V0.6 freeze candidate**.

PR remains Draft until the Apple/Xcode validation gate can execute normally.
