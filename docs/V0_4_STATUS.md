# V0.4 Status — AI Knowledge Extraction & Flashcard Generation

## Goal

Turn normalized learning documents into structured Japanese-learning knowledge and reviewable flashcards while keeping the AI provider replaceable.

## Implemented

- Provider-agnostic `AICompletionProvider` contract.
- Two runtime-selectable provider adapters:
  - OpenAI Responses API with Structured Outputs and `store=false`.
  - Anthropic Messages API with `output_config.format` structured JSON output.
- Explicit handling for provider refusals and incomplete/truncated structured responses.
- Provider-specific model IDs and separate Keychain credentials.
- Source documents record the provider/model used by the latest successful AI generation.
- Provider-neutral connection test in Settings.
- Explicit structured-output request containing:
  - system prompt
  - source-aware user prompt
  - response schema name
  - JSON Schema
- HTTP error propagation and 429 `Retry-After` handling.
- Local AI configuration:
  - provider selection
  - provider-specific model ID
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
- Imported source content is explicitly treated as untrusted AI input.
- Extraction normalization:
  - trims generated stable keys and human-readable text
  - removes duplicate/empty tags
- Extraction validation:
  - version check
  - item/card count limits
  - non-empty keys
  - non-empty semantic content
  - duplicate-key rejection
  - semantic-duplicate rejection
  - non-empty prompt/answer
- Long-document paragraph-aware chunking.
- Cost guard limiting a single generation run to a bounded number of chunks.
- Multi-chunk provider/model identity consistency checks.
- Multi-chunk result merging using stable knowledge/card keys.
- Clean data separation:
  - `SourceDocumentEntity`
  - `KnowledgeItemEntity`
  - `FlashcardEntity`
- Idempotent persistence of generated knowledge and cards.
- Source traceability from generated records back to source document/reference/path.
- Removed generated knowledge/cards are marked inactive, not deleted.
- Review history is preserved when a generated card becomes inactive.
- Review queue, card browsing, counts, and home due totals exclude inactive cards.
- Study Scope filters both source and generated card type.
- Imported page detail can directly trigger AI extraction/card generation.
- Library shows AI freshness plus generated knowledge/card counts.
- Settings UI exposes provider/model/credential configuration and connection testing.
- Non-destructive legacy migration from V0.3 imported Knowledge Items into Source Documents.

## Quality fixes made during V0.4

- Corrected source-prompt interpolation defects found during review.
- Moved HTTP transport into a provider-neutral Core module.
- Moved Keychain storage into a shared security layer.
- Added explicit source-document persistence instead of overloading Knowledge Items as imported documents.
- Added inactive-card guards to review recording and due queues.
- Added source-trace updates when source category/reference/path changes.
- Validated bundles before merge to prevent duplicate-key dictionary traps.
- Preserved learning IDs when AI stable keys drift but semantic content remains equivalent.
- Prevented empty reruns from deactivating existing learning data.
- Deactivated generated learning when the source page becomes inactive while preserving review history.
- Preserved slashes inside Notion page titles during AI chunking.
- Added chunk-count cost protection before any large AI run starts.
- Added provider/model consistency checks across multi-chunk runs.
- Added provider-specific model persistence so switching providers does not reuse the wrong model ID.
- Added current-draft connection testing so unsaved UI selections are tested accurately.
- Added explicit refusal/incomplete-response handling for OpenAI and Anthropic.
- Added immediate UI refresh of the provider/model metadata after successful generation.
- Removed iOS-only text-input modifiers from shared SwiftUI package code.

## Validation coverage

Portable core tests cover:

- extraction prompt/schema
- normalization and validation
- document chunking
- bundle merging
- OpenAI request/response/error/rate-limit behavior
- Anthropic request/response/error/rate-limit behavior
- source-key stability
- FSRS core

SwiftData/full-app tests cover:

- idempotent knowledge/card generation
- source traceability
- extraction freshness
- stable-key drift
- inactive-card handling
- review-history preservation
- source removal
- review source/card-type filtering
- legacy source migration
- chunk-limit and provider-consistency guards
- provider-specific configuration behavior

## Validation state

The portable V0.4 AI core has previously been compiled independently with Swift 6.2 on Linux during development.

A fresh controlled validation attempt (run #137) was made after the latest V0.4 work. Both Ubuntu core tests and the macOS simulator job again failed before their first workflow step started (`steps: null`). The workflow was immediately returned to manual-only mode, so this remains an Actions execution/account issue rather than a reported Swift build/test failure.

The only remaining release gate is a normal macOS/Xcode validation pass covering:

- full SwiftData test suite
- shared SwiftUI package build
- iOS Simulator build

## V0.4 completion state

Feature implementation is complete enough to be treated as a **V0.4 freeze candidate**.

Do not merge the draft PR until the final macOS/Xcode validation pass is available.
