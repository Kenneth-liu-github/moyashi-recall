# V0.6 Acceptance Checklist

## Automated validation

On a Mac with Xcode installed, run the normal full validation used by the project.

The gate must cover:

1. Swift package tests,
2. SwiftData/data-layer tests,
3. Apple-platform PDF/DOCX fixtures,
4. iOS Simulator build.

## Functional acceptance

### Text / Markdown / CSV

- Import TXT, Markdown, CSV, and TSV.
- Confirm Library shows a clean filename source.
- Re-import the same path unchanged and confirm it is reported unchanged.
- Modify the same file and re-import; confirm it updates instead of duplicating.

### PDF

- Import a multi-page PDF.
- Confirm Library shows:
  - one root file container,
  - child page units,
  - natural page ordering.
- Open a text-bearing page and generate AI knowledge/cards.
- Confirm card/source trace includes filename and page number.
- Re-import a version with fewer text pages and confirm removed page units become inactive.

### Word / rich text

- Import DOCX, DOC, RTF, and ODT.
- Confirm readable text appears in Library.
- Generate AI knowledge/cards from extracted text.

### Images

- Import PNG, JPG/JPEG, and HEIC screenshots containing Japanese text.
- Confirm on-device OCR produces usable text in reading order.
- Generate cards and verify Japanese kanji readings follow the existing kana-annotation rule.

### Archive

- Swipe a local file root and choose Archive.
- Confirm the user receives a confirmation dialog.
- Confirm the source disappears from active Library/Study Scope.
- Confirm its generated cards no longer appear in due review.
- Confirm previous Review History remains visible.

### Privacy

- Confirm Library/source references display filename/page metadata only.
- Confirm raw local filesystem paths are not persisted in Source Documents.

## Validation result

The automated Apple/Xcode validation gate passed in GitHub Actions run #148.

The remaining document-picker, security-scoped URL, OCR, notification, and audio checks require interactive simulator/device use and are tracked as release-readiness smoke checks rather than engineering-freeze blockers.

## Freeze rule

**V0.6 engineering freeze: PASSED.**
