# V0.5 Acceptance Checklist

V0.5 closes the daily learning loop built on top of V0.4.

## Automated validation

When a Mac/Xcode runner is available:

```bash
bash scripts/validate-v0.4-macos.sh
```

The command remains valid because it runs the full package tests plus the iOS Simulator build, including V0.5 sources and tests.

## Functional acceptance

### 1. Home

- Due count matches the actual due queue.
- Streak is based on persisted Review History.
- Today’s reviewed count updates after review.
- 7-day successful-recall rate treats Again as failure and Hard/Good/Easy as successful recall.
- The latest completed review session appears after returning to Home.
- A stale previous session summary disappears after newer unfinished review activity or reset history.
- Weak items come from real recent Hard/Again history and only appear when currently due.

### 2. Study Scope

- Each source shows total cards and due cards.
- Changing card types updates due counts.
- Effective session size reflects source + card-type filters.
- Empty source/type selections cannot start a review.
- The previous scope is restored exactly; stale selections are never broadened silently.

### 3. Named presets

- Save the current scope under a name.
- Saving the same name updates the existing preset rather than duplicating it.
- Applying a preset restores source, card-type, and count settings.
- Deleting a preset removes it.
- A preset referencing deleted sources becomes safely incomplete and does not expand to unrelated sources.

### 4. Review session

- Session uses only due cards from the selected scope.
- Again / Hard / Good / Easy all persist Review History and update FSRS state.
- Completion screen shows accurate rating counts.
- Completing the final card writes the latest session summary.
- Targeted weak-item review only includes the selected Knowledge Item.

### 5. Review History

- History is grouped by calendar day.
- Search matches prompt, answer, and source path.
- Rating filter supports All / Again / Hard / Good / Easy.
- History remains visible for cards that later become inactive.

### 6. Data preservation

- V0.4 source/knowledge/card IDs are preserved.
- No V0.5 feature deletes Review History.
- Inactive generated cards stay out of due queues while historical review events remain available.

## Freeze rule

PR #6 remains Draft until a normal macOS/Xcode validation pass completes successfully.
