# V0.6 Status — Daily Reminders & Japanese TTS

## Goal

Improve daily-use engagement and accessibility after the V0.5 learning loop by adding local review reminders and native Japanese text-to-speech.

## Implemented

### Japanese TTS

- Native AVSpeechSynthesizer-based Japanese playback.
- Speaker controls on Japanese review prompts.
- Speaker controls on Japanese review answers.
- Speech stops when the review screen is left.
- Kana reading annotations such as `進（すす）め方（かた）` are removed before speech so words are not read twice.
- Standalone Japanese parentheses such as `これは（テスト）です` are preserved.
- Configurable speech speed:
  - slow
  - normal
  - fast
- Optional automatic answer playback after revealing a Japanese answer.
- Speech preferences are persisted locally.

### Daily review reminders

- Local notifications using UserNotifications.
- Opt-in daily reminder toggle.
- Configurable reminder time.
- Notification permission is requested only when enabling reminders.
- Only alert + sound permission is requested; badge permission is not requested.
- Disabling reminders cancels the pending daily request.
- Stored reminder preferences are reconciled with the current system authorization state.
- Programmatic permission corrections do not recursively trigger Toggle side effects.
- Reminder content is refreshed from Home with the current due-card count when available.
- Changing interface language while reminder settings are open reschedules localized notification copy.

### Settings

Settings now includes:

- Daily review reminder settings.
- Japanese speech speed and auto-play settings.

## Quality work

- TTS text normalization is independently testable without AVFoundation.
- Reminder preferences are independently testable without UserNotifications.
- Speech preferences are independently testable without AVFoundation.
- New pure V0.6 components are included in the portable Linux package test slice.
- Notification authorization handling is kept cross-platform-safe for the shared iOS/macOS package target.
- TTS ObservableObject explicitly imports Combine.
- Reminder scheduling errors propagate correctly during initial enable.
- No new force unwraps, TODOs, fatal errors, or extra palette colors were introduced.

## Validation state

GitHub Actions is still affected by the repository/account-level runner issue where jobs fail before the first workflow step starts. V0.6 therefore remains dependent on the same final macOS/Xcode validation gate used by the previous stacked milestones.

## V0.6 completion state

V0.6 is a **feature-complete freeze candidate** pending normal Apple-platform build/test validation.
