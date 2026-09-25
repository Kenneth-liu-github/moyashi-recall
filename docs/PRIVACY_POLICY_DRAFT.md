# Moyashi Recall Privacy Policy — Draft for Publication

> Release note: replace all bracketed placeholders before publishing this policy and entering its public URL in App Store Connect.

Effective date: [EFFECTIVE DATE]

Moyashi Recall is a personal Japanese-learning and spaced-repetition application. This policy explains how the current iOS/iPadOS application handles information.

## 1. Local learning data

Moyashi Recall stores its learning database locally on the user's device using Apple's SwiftData framework. Local learning data may include:

- imported source-document text,
- extracted learning items,
- generated flashcards,
- review history,
- spaced-repetition scheduling state,
- study preferences and presets.

Moyashi Recall does not operate a first-party cloud account service for this learning database in the current release.

## 2. User-selected files

Users may choose local or iCloud files for import. Supported content can include text documents, PDFs, rich documents, tabular text files, and images.

File content is processed to create learning material. The application uses a local deterministic identifier for imported files and does not intentionally persist the user's raw filesystem path as the source reference.

## 3. Notion integration

If a user chooses to connect Notion, Moyashi Recall uses the Notion integration token provided by the user to retrieve the pages and blocks the user selects or authorizes.

The Notion token is stored in Apple Keychain on the device. Moyashi Recall does not include Notion credentials in learning-data backup exports.

Use of Notion is also subject to Notion's own terms and privacy practices.

## 4. AI providers

Moyashi Recall can send selected learning content to an AI provider chosen and configured by the user in order to extract learning items and generate flashcards.

The current application supports provider adapters including OpenAI and Anthropic. API credentials are supplied by the user and stored in Apple Keychain.

Content sent to an AI provider is processed by that provider under the provider's applicable terms, privacy policy, account configuration, and data-retention controls. Provider practices may change independently of Moyashi Recall.

For OpenAI Responses API requests, Moyashi Recall requests non-persistent application-state behavior where supported by setting `store=false`. This does not by itself override all provider-side security, abuse-monitoring, legal, or account-specific retention requirements.

Users should avoid submitting sensitive information to an AI provider unless they understand and accept the provider's data-handling terms.

## 5. Credentials

Notion integration tokens and AI API keys are stored using Apple Keychain.

Moyashi Recall does not include these credentials in its JSON learning-data backup/export feature.

## 6. Backup and restore

Users can choose to export a JSON backup of their learning data and save it through Apple's system file interface.

The exported learning-data package can include source metadata and content, learning items, flashcards, review history, and scheduling state. It excludes Notion tokens, AI API keys, Keychain credentials, and app secrets.

The user controls where exported backup files are stored and shared.

## 7. Notifications and speech

If the user enables daily study reminders, Moyashi Recall uses Apple's local notification system. Reminder notifications are scheduled on the device.

Japanese text-to-speech uses Apple's system speech functionality.

## 8. Tracking, advertising, and analytics

The current release does not include third-party advertising SDKs or cross-app tracking functionality.

The current release does not intentionally use learning data for advertising.

## 9. Third-party services

Optional integrations may cause information to be transmitted to third-party services selected by the user, including Notion and configured AI providers.

Those services process information according to their own agreements and privacy practices. Users are responsible for ensuring that their use of third-party services is appropriate for the information they submit.

## 10. Data deletion

Learning data stored locally by Moyashi Recall remains on the device unless the user deletes or replaces it through application/device data-management actions, restores different data, or removes the application.

Deleting local data from Moyashi Recall does not automatically delete information that may previously have been transmitted to a third-party provider. Requests concerning third-party-held information must follow the applicable provider's controls and policies.

## 11. Children

Moyashi Recall is not designed to knowingly collect children's personal information through a first-party account or advertising service. App Store age-rating and distribution settings should be configured consistently with the intended audience before release.

## 12. Changes to this policy

This policy may be updated when product capabilities, integrations, data practices, or legal requirements change. The effective date above will be updated when material changes are published.

## 13. Contact

Privacy questions can be sent to:

[PUBLIC CONTACT NAME OR COMPANY]  
[PUBLIC CONTACT EMAIL]  
[OPTIONAL POSTAL ADDRESS]
