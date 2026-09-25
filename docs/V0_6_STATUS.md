# V0.6 Status — Engagement, Japanese TTS & Local File Ingestion

## Goal

Extend the V0.5 learning loop with daily-use engagement features and direct local-file ingestion while preserving the same traceable learning pipeline:

Source → Source Document → AI Knowledge Extraction → Flashcards → Review → FSRS.

## Implemented

### Daily reminders
- Local UserNotifications-based daily reminders.
- Opt-in enable/disable and configurable time.
- Alert + sound permission only.
- Permission-state reconciliation.
- Due-aware reminder copy refreshed from Home.
- Localized reminder copy follows the selected interface language.

### Japanese TTS
- Native AVSpeechSynthesizer playback for Japanese review prompts and answers.
- Kana reading annotations such as `進（すす）め方（かた）` are normalized before speech.
- Slow / normal / fast speech rates.
- Optional answer auto-play, default off.
- Speech stops when leaving Review.

### Local file ingestion
- PDF with page-level text extraction and hierarchy.
- DOCX / DOC / RTF / ODT rich-document extraction.
- TXT / Markdown / CSV / TSV.
- PNG / JPG / JPEG / HEIC OCR through Apple Vision.
- Multi-file import and security-scoped access.
- Idempotent re-import and stale-child reconciliation.
- Archive flow that deactivates current learning while preserving Review History.
- Source identity avoids persisting raw local filesystem paths.
- Imported files appear as distinct Study Scope sources.
- Bounded batch AI generation for text-bearing file units.

## Validation

Engineering validation is green on GitHub Actions:

- Run #148
- commit: `5b65e048a5be09b4256a14dbc526117672403c0e`
- portable Linux core tests: passed
- full macOS Swift package / SwiftData tests: passed
- Apple-platform PDF and DOCX fixture coverage: passed
- iOS Simulator build: passed

The earlier runner/budget provisioning issue was resolved after the repository was made public.

## Quality checks

- No new production `try!`, `fatalError`, TODO, or FIXME markers were found in the V0.6 audit.
- Local source references persist filename/page metadata, not raw filesystem paths.
- V0.5 FSRS, review queue, history, presets, weak-item review, and dashboard regression coverage remained green.
- V0.4 AI extraction and V0.3 Notion ingestion remain covered by the combined test suite.

## Freeze state

V0.6 is **engineering-frozen**.

The automated engineering gate is complete. A physical-device UX smoke test for the system document picker, security-scoped URLs, notifications, and spoken-audio behavior remains a release-readiness check rather than an engineering-freeze blocker.
