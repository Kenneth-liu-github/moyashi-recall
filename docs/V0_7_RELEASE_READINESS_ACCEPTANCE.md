# V0.7 Acceptance Checklist

## 1. First-run readiness

- Fresh install with no cards shows a setup card on Home.
- Missing Notion setup links to Notion configuration.
- Notion complete + AI incomplete links to AI configuration.
- Notion + AI complete + zero cards explains the Library generation step.
- Once active cards exist, the setup card disappears.

## 2. Diagnostics

- Settings → System Status opens without exposing any credential values.
- Notion Token status reflects presence only.
- Notion root selection and synced-page count are correct.
- AI provider/model/credential status is correct.
- Knowledge, card, due, and Review History counts match local data.
- Latest review timestamp is shown when available.
- Refresh updates the snapshot after configuration/data changes.
- App version/build is visible.

## 3. Learning-data export

- Settings → Data Export generates a JSON document.
- Export contains sources, knowledge, cards, FSRS state, and Review History.
- Inactive records needed for historical preservation are included.
- Dates encode as ISO-8601.
- Ordering is stable/deterministic.
- Export contains no stored Notion Token, AI API key, or Keychain credential fields.
- Cancelling the system file exporter does not mutate local learning data.

## 4. Regression

- V0.6 reminders and Japanese TTS continue to work.
- V0.5 study presets, weak-item review, history, and dashboard continue to work.
- V0.4 AI extraction and V0.3 Notion sync remain unchanged.

## Freeze rule

PR #8 remains Draft until the complete macOS/Xcode test suite and iOS Simulator build can execute successfully.
