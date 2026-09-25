# V0.4 Acceptance Checklist

V0.4 is the AI knowledge-extraction and flashcard-generation milestone.

## Automated validation

On a Mac with Xcode installed:

```bash
bash scripts/validate-v0.4-macos.sh
```

A successful run must complete:

1. the full Swift package test suite,
2. SwiftData/data-layer tests,
3. the iOS Simulator build.

GitHub Actions can run the same macOS validation manually once the account-level runner issue is resolved.

## Functional acceptance

### 1. Notion source

- Save a Notion integration token.
- Search for a page.
- Select a root page.
- Sync the page tree.
- Confirm Library shows the correct hierarchy and source path.

### 2. AI provider

- Open Settings → AI.
- Select OpenAI or Anthropic.
- Enter a model ID and API key.
- Test the current configuration.
- Save the configuration.
- Switch providers and confirm each provider retains its own model ID and credential state.

### 3. AI generation

- Open a synced Notion page in Library.
- Generate AI knowledge and cards.
- Confirm the page reports:
  - extracted knowledge count,
  - generated card count,
  - provider/model used,
  - AI freshness.
- Re-run generation and confirm stable items/cards are updated idempotently rather than duplicated.

### 4. Card quality

Generated Japanese-learning output should:

- preserve source meaning,
- annotate Japanese kanji with kana in `漢字（かんじ）` form,
- avoid duplicate or empty cards,
- preserve Natural English where useful,
- retain the readable source path.

### 5. Review integration

- Open Study Scope.
- Filter by source and card type.
- Start a review session.
- Reveal the answer and rate Again / Hard / Good / Easy.
- Confirm the card leaves the immediate due queue according to FSRS.
- Confirm inactive/deprecated AI cards do not appear in review.

### 6. Data preservation

- Regenerate a page with fewer cards and confirm removed cards become inactive rather than deleted.
- Confirm existing Review History remains intact.
- Remove a source page from a complete Notion sync and confirm its generated learning becomes inactive without deleting review history.
- A partial/bounded Notion sync must never deactivate unseen source pages.

## Freeze rule

PR #5 remains Draft until the automated macOS validation completes successfully. No merge should occur before that gate is green.
