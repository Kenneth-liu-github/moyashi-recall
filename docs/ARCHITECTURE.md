# Architecture

## Modules

```
MoyashiRecall/
  App/
  Core/
    DesignSystem/
    Localization/
  Models/
  Features/
    Home/
    StudyScope/
    Review/
    Library/
    Cards/
    Settings/
  Services/
  PreviewData/
MoyashiRecallTests/
```

## Boundaries

UI features depend on domain models and service protocols, not concrete external providers.

Planned service protocols:
- ContentSourceService
- KnowledgeExtractionService
- AIProvider
- ReviewScheduler
- PersistenceService

## V0.1

V0.1 intentionally uses local mock repositories. This keeps UI iteration fast and prevents Notion/backend implementation details from locking the product design too early.

## Later integration

Notion sync produces normalized Source/Document/KnowledgeItem records. AI generates cards through the AI Gateway. FSRS consumes review events and updates scheduling state. All generated cards retain source references.
