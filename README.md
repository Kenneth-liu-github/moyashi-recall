# Moyashi Recall

AI-powered personal Japanese learning library and spaced-repetition app for iPhone and iPad.

## Product rules

- Native Swift + SwiftUI Universal App
- Default interface language: Simplified Chinese
- Optional interface language: Japanese (Settings)
- Interface language is independent from learning-content language
- Global UI palette: no more than 4 colors; cold blue + black/white/gray
- Notion-first, source-agnostic content architecture
- Every card remains traceable to its source
- AI provider is decoupled behind an AI Gateway
- FSRS is the review scheduler
- V0.1 is offline-first and uses mock data; Notion/AI/backend come after UX validation

## V0.1 scope

1. Home dashboard
2. Study Scope selection
3. Review question/answer flow
4. Library
5. Cards
6. Settings with Chinese/Japanese UI switching
7. Adaptive iPhone/iPad SwiftUI layout

## Canonical learning pipeline

Source → Document → Knowledge Item → Flashcard(s) → Review History → FSRS State

## Development workflow

Product feedback is reviewed in small iterations. Feature work should be developed on branches and merged through pull requests after review.
