# V0.4 Status — AI Knowledge Extraction & Flashcard Generation

## Goal

Turn normalized learning documents into structured Japanese-learning knowledge and reviewable flashcards while keeping the AI provider replaceable.

## Implemented

- Provider-agnostic `AICompletionProvider` contract.
- Explicit structured-output request containing:
  - system prompt
  - source-aware user prompt
  - response schema name
  - JSON Schema
- OpenAI Responses API adapter using Structured Outputs.
- OpenAI requests set `store=false`.
- OpenAI HTTP error propagation and 429 `Retry-After` handling.
- Local AI configuration:
  - provider selection
  - model ID
  - API key stored in Apple Keychain
- Knowledge extraction schema for:
  - vocabulary
  - expression
  - grammar
  - contrast
  - example
  - business usage
- Generated card types:
  - Chinese → Japanese
  - Japanese → Chinese
  - Cloze
  - Contrast
  - Application
- Prompt rule requiring Japanese kanji/kana annotation when practical.
- Extraction validation:
  - version check
  - item/card count limits
  - non-empty keys
  - duplicate-key rejection
  - non-empty prompt/answer
- Long-document paragraph-aware chunking.
- Multi-chunk result merging using stable knowledge/card keys.
- Clean data separation:
  - `SourceDocumentEntity`
  - `KnowledgeItemEntity`
  - `FlashcardEntity`
- Idempotent persistence of generated knowledge and cards.
- Source traceability from generated records back to source document/reference.
- Removed generated knowledge/cards are marked inactive, not deleted.
- Review history is preserved when a generated card becomes inactive.
- Review queue, card browsing, counts, and home due totals exclude inactive cards.
- Imported page detail can directly trigger AI extraction/card generation.
- Settings UI now exposes AI Provider/model/credential configuration.
- Portable core tests added for:
  - extraction prompt/schema
  - validation
  - document chunking
  - bundle merging
  - OpenAI request structure
  - response parsing
  - HTTP errors
  - rate-limit retry
- SwiftData tests added for:
  - idempotent knowledge/card generation
  - source traceability
  - inactive-card handling
  - review-history preservation

## Quality fixes made during V0.4

- Corrected a source-prompt interpolation defect found during code review.
- Moved HTTP transport into a provider-neutral Core module.
- Moved Keychain storage into a shared security layer.
- Added explicit source-document persistence instead of overloading Knowledge Items as imported documents.
- Added inactive-card guard to ReviewRecorder.
- Added source-trace updates when source category/reference changes.
- Validated bundles before merge to prevent duplicate-key dictionary traps.
- Removed iOS-only text-input modifiers from shared SwiftUI package code.

## Validation state

The portable V0.4 AI core was independently compiled with Swift 6.2 on Linux during development.

Repository GitHub Actions remain manually triggered because previous Actions jobs were failing before execution began. Full SwiftData/SwiftUI/iOS Simulator validation still requires a normal macOS runner or local Xcode run.

## Remaining V0.4 work

- Full Xcode/iOS simulator build on the current branch.
- Run complete SwiftData test suite on macOS.
- Add explicit AI generation status/knowledge-count feedback in Library/Card UI.
- Final review of provider configuration and API-error UX.
- Optional second provider adapter to demonstrate runtime provider switching.
- Freeze V0.4 after validation.

V0.4 is now an active functional implementation branch, not a planning placeholder.
