# V0.6 Acceptance Checklist

## 1. Japanese TTS

- Japanese prompts show a speaker control.
- Japanese answers show a speaker control after reveal.
- Chinese/English-only text does not show unnecessary Japanese speech controls.
- `進（すす）め方（かた）について` is spoken as `進め方について`, without repeating the readings.
- Standalone parentheses remain intact.
- Slow / Standard / Fast settings visibly change playback speed.
- Auto-play answer is opt-in and defaults off.
- Leaving Review stops ongoing speech.

## 2. Reminder preferences

- Daily reminders default off.
- Enabling reminders requests notification permission.
- Denied permission turns the feature back off and keeps preferences consistent.
- Changing reminder time reschedules the request.
- Disabling reminders cancels the pending daily notification.
- Reopening Settings restores the selected time and enabled state.
- The app requests only alert and sound notification permissions.

## 3. Due-aware reminder copy

- Opening Home while reminders are enabled refreshes the daily notification.
- If cards are due, notification copy includes the current due-card count.
- If none are due, notification copy stays generic rather than showing a false count.
- Reminder copy follows the selected interface language when rescheduled.

## 4. Data/privacy

- No audio recordings are created or stored.
- TTS uses on-device/system speech synthesis.
- Reminder preferences and speech preferences contain no secrets.
- Existing Notion/AI credentials remain in Keychain and are unaffected.

## 5. Regression

- V0.5 review queue, FSRS ratings, history, presets, weak-item review, and dashboard analytics continue to work.
- V0.4 AI generation and V0.3 Notion sync remain unchanged.

## Freeze rule

PR #7 remains Draft until the full macOS/Xcode test suite and iOS Simulator build can execute successfully.
