# Privacy Data Flow — Release Review

## Local data

Moyashi Recall stores learning sources, generated knowledge, flashcards, FSRS scheduling state, and Review History locally in SwiftData.

Notion tokens and AI API keys are stored in Apple Keychain.

The app does not implement advertising, analytics tracking, cross-app tracking, or data-broker integrations.

## Network data flows

### Notion

The app contacts the Notion API when the user explicitly configures a Notion integration and chooses content to synchronize.

### AI providers

When the user asks Moyashi Recall to generate learning content, source text is sent to the AI provider selected/configured by the user.

Current provider adapters include OpenAI and Anthropic.

The OpenAI direct adapter requests response storage disabled where supported by the API implementation. Provider-side operational or abuse-prevention retention is governed by the provider/API terms applicable to the user's account and must be reviewed before the App Store privacy questionnaire is finalized.

## App Store privacy review

Before public distribution:

1. Publish a privacy policy URL.
2. Confirm the retention behavior of each enabled AI provider.
3. Answer App Store Connect privacy questions based on actual off-device retention, not only local app storage.
4. Keep the privacy manifest and App Store privacy answers aligned with the shipping build.
5. Re-review these disclosures whenever a new AI provider, analytics SDK, or network service is added.

## Tracking

The app declares `NSPrivacyTracking = false` and currently contains no advertising/tracking SDK integration.
