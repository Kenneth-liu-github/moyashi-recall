# V0.6 Acceptance Checklist

## Automated engineering gate

Validated by GitHub Actions run #148 on commit `5b65e048a5be09b4256a14dbc526117672403c0e`.

- [x] Portable Linux core tests
- [x] Full macOS Swift package tests
- [x] SwiftData/data-layer tests
- [x] Apple-platform PDF fixture
- [x] Apple-platform DOCX fixture
- [x] iOS Simulator build
- [x] V0.5 regression coverage

## Japanese TTS

- [x] Japanese prompts and answers support speech controls.
- [x] Kana reading annotations are normalized before speech.
- [x] Non-reading parentheses are preserved.
- [x] Slow / normal / fast settings are persisted.
- [x] Answer auto-play is opt-in and defaults off.
- [x] Leaving Review stops speech.

## Daily reminders

- [x] Daily reminders default off.
- [x] Permission is requested only when enabling.
- [x] Denied authorization returns preferences to a consistent disabled state.
- [x] Reminder time changes reschedule notifications.
- [x] Disabling removes the pending reminder.
- [x] Reminder copy can include current due-card count.
- [x] Reminder copy follows the selected interface language.

## Local file ingestion

- [x] TXT / Markdown / CSV / TSV parsing.
- [x] PDF page-level extraction and natural page ordering.
- [x] DOCX / DOC / RTF / ODT rich-document path implemented.
- [x] PNG / JPG / JPEG / HEIC OCR path implemented with Apple Vision.
- [x] Same-path re-import is idempotent.
- [x] Same-named files in different folders receive distinct identities.
- [x] Removed child pages are deactivated rather than deleted.
- [x] Archive preserves Review History while deactivating generated learning.
- [x] Imported filenames become Study Scope sources.
- [x] Batch AI generation is bounded.

## Privacy and quality

- [x] Raw local filesystem paths are not persisted in Source Documents.
- [x] Existing Notion/AI secrets remain Keychain-backed.
- [x] No new production `try!`, `fatalError`, TODO, or FIXME markers found in the V0.6 audit.
- [x] Combined PR #7 + PR #9 integration is merge-clean and validated.

## Release-readiness smoke checks

These require interactive simulator/device use and are intentionally not claimed as automated:

- [ ] Exercise the system document picker with real iCloud/local files.
- [ ] Confirm security-scoped access with externally provided files.
- [ ] Confirm notification delivery on a device/simulator with permission transitions.
- [ ] Listen to Japanese TTS on-device and confirm audio/voice behavior.

## Freeze decision

**V0.6 engineering freeze: PASSED.**

The remaining interactive smoke checks belong to release readiness and do not block the V0.6 engineering freeze.
