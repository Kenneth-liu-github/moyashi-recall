# Architecture

## Product pipeline

```
Source
  → SourceDocument
  → AI Knowledge Extraction
  → KnowledgeItem
  → Flashcard
  → ReviewState / ReviewHistory
  → FSRS-6
```

Every generated Knowledge Item and Flashcard retains source traceability.

## Modules

```
MoyashiRecall/
  App/
  Core/
    DesignSystem/
    Localization/
    Networking/
    Security/
  Data/
    PersistenceModels
    LearningRepository
    ReviewQueueService
    ReviewRecorder
  Scheduling/
    FSRS
  Sources/
    LearningContentSource
    SourceKeyResolver
    Notion/
    Files/
  AI/
    AICompletionProvider
    Provider Adapters
    KnowledgeExtraction
    DocumentChunking
    AIProcessing
  Features/
    Home/
    StudyScope/
    Review/
    Library/
    Cards/
    Settings/
  PreviewData/
MoyashiRecallTests/
```

## Boundaries

### Source layer

External source integrations normalize data into `ImportedDocument`.

Implemented source adapters now include:

```
Notion API
  → ImportedDocument tree
  → SourceDocumentEntity

Local files
  → TXT / Markdown / CSV / TSV
  → PDF page extraction
  → DOCX / DOC / RTF / ODT text extraction
  → Vision OCR for images
  → ImportedDocument tree
  → SourceDocumentEntity
```

All source adapters produce the same `ImportedDocument` contract. PDF files preserve page-level traceability by representing the file as a root container and text-bearing pages as child documents. Local file paths are hashed for identity and are not stored as user-visible source references.

PowerPoint/XLSX structured extraction, audio, video, and manual-entry adapters remain future source-layer work.

### AI layer

UI and persistence do not depend on a concrete model vendor.

```
AIProcessingService
  → KnowledgeExtractionService
  → AICompletionProvider
      → OpenAIResponsesProvider
      → future Anthropic/Gemini/Gateway adapters
```

The provider contract receives a system prompt, user prompt, schema name, and explicit JSON Schema.

V0.4 currently includes an OpenAI Responses API adapter using Structured Outputs with `store=false`. Model IDs are configuration, not hard-coded application logic.

### Data layer

SwiftData stores five core record families:

- `SourceDocumentEntity`: normalized imported source pages/documents.
- `KnowledgeItemEntity`: semantic learning units extracted from a source document.
- `FlashcardEntity`: generated study cards.
- `ReviewStateEntity`: current FSRS scheduling state.
- `ReviewHistoryEntity`: immutable review-event history.

Source synchronization never deletes review history.

Removed source pages and superseded AI-generated items/cards are marked inactive so historical learning data remains traceable.

### Review layer

```
Study Scope
  → ReviewQueueService
  → active due cards
  → ReviewRecorder
  → ReviewHistory
  → FSRS-6
  → next due date
```

Inactive generated cards are excluded from review sessions.

## Security

- Notion tokens are stored in Apple Keychain.
- AI API keys are stored in Apple Keychain.
- Provider/model selection is non-secret local configuration.
- Secrets are never committed to GitHub or written to SwiftData.
- OpenAI response storage is disabled in the direct adapter request.

## Long-document handling

V0.4 splits long source text into bounded paragraph-aware chunks before AI extraction.

Each chunk is processed independently, then `KnowledgeBundleMerger`:

- validates each bundle,
- deduplicates stable knowledge keys,
- merges non-duplicate cards,
- merges tags,
- validates the final bundle before persistence.

## CI strategy

Portable algorithm/network/parser tests are isolated into a Linux-compatible Swift Package slice.

Full SwiftData + SwiftUI + iOS Simulator validation remains a macOS/Xcode validation step.

Automatic GitHub Actions triggers are temporarily paused while repository Actions jobs are failing before their first workflow step starts. The workflow remains available through manual dispatch.
