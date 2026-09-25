# V0.7 Status — Release Readiness, Diagnostics & Data Export

## Goal

Make the MVP easier to configure, diagnose, support, and back up without exposing credentials.

## Implemented

### Readiness diagnostics

- Central readiness snapshot covering:
  - Notion credential configured
  - Notion root page selected
  - synced Notion page count
  - selected AI provider
  - AI model configured
  - AI credential configured
  - active knowledge count
  - active flashcard count
  - current due-card count
  - Review History count
  - latest review timestamp
- Notion readiness is scoped specifically to Notion source documents.
- Keychain read failures degrade to “not configured” instead of making the entire diagnostics screen unusable.
- User-facing diagnostics screen in Settings.
- Manual diagnostics refresh.
- App version and build number shown in diagnostics.
- Direct recovery links to Notion and AI configuration when incomplete.

### First-run guidance

- Home detects when there are no reviewable cards.
- If Notion is incomplete, Home links directly to Notion setup.
- If Notion is ready but AI is incomplete, Home links directly to AI setup.
- If Notion + AI are ready but there are no cards yet, Home explains that the next step is generating cards from Library.
- Existing users with reviewable cards do not see the onboarding card.

### Learning-data export

- Native JSON file export from Settings.
- Export includes:
  - source documents and hierarchy metadata
  - AI-generated knowledge
  - flashcards
  - FSRS review states
  - Review History
  - active/inactive state required for preservation
  - provider/model provenance metadata
- Export order is deterministic for easier diffing and support inspection.
- Export intentionally excludes:
  - Notion Token
  - AI API keys
  - Keychain credentials
- Export uses a versioned package schema (`v1`).
- No destructive restore/import path is introduced in V0.7.

## Quality work

- No new force unwraps, TODOs, fatal errors, or out-of-palette colors in the V0.7 diff.
- Diagnostics remain useful when credential reads fail.
- Backup JSON has explicit ISO-8601 timestamps and sorted keys.
- Readiness derived-state tests and export round-trip tests were added.

## Validation state

The same GitHub Actions account/runner limitation remains: jobs are created but fail before their first workflow step executes. V0.7 therefore remains a stacked Draft milestone pending a normal macOS/Xcode validation environment.

## V0.7 completion state

V0.7 is a **feature-complete freeze candidate** pending full Apple-platform build/test validation.
