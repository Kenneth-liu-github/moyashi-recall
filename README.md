# Moyashi Recall

AI-powered personal Japanese learning library and spaced-repetition app for iPhone and iPad.

## Product rules

- Native Swift + SwiftUI Universal App
- Default interface language: Simplified Chinese
- Optional interface language: Japanese
- Interface language is independent from learning-content language
- Global UI palette: no more than 4 colors; cold blue + black/white/gray
- Source-agnostic learning-content architecture
- Every generated card remains traceable to its source
- AI providers are decoupled behind provider adapters
- FSRS-6 schedules review timing
- Local-first learning data via SwiftData

## Current pipeline

Source → Source Document → AI Knowledge Item → Flashcard → Review History → FSRS State

## Implemented milestones

### V0.1 — App shell

- Home
- Review
- Library
- Cards
- Settings
- Chinese/Japanese UI switching

### V0.2 — Persistence + FSRS

- SwiftData learning/review models
- due queue
- FSRS-6 scheduling
- Review History persistence

### V0.3 — Notion ingestion

- secure Keychain token
- Notion page search
- recursive page/block sync
- source hierarchy/path traceability

### V0.4 — AI extraction

- provider-neutral AI contract
- OpenAI + Anthropic adapters
- structured knowledge extraction
- generated flashcards
- idempotent AI regeneration

### V0.5 — Complete learning loop

- Study Scope
- saved presets
- live dashboard analytics
- weak-item reinforcement
- Review History search/filter
- session summaries

### V0.6 — Engagement, speech & local file ingestion

- daily local review reminders with due-aware copy
- native Japanese text-to-speech with kana-reading normalization
- configurable speech speed and optional answer auto-play
- PDF page extraction
- Word / RTF / ODT text extraction
- TXT / Markdown
- CSV / TSV
- image OCR with Apple Vision
- multi-file import
- source archive with Review History preservation

## Development workflow

Feature work is isolated on stacked branches and draft pull requests. A milestone is not merged until its validation gate is satisfied.

Portable parser/algorithm tests are kept Linux-compatible where possible. Full SwiftData, SwiftUI, PDFKit/Vision, and iOS Simulator validation require a working macOS/Xcode runner.
