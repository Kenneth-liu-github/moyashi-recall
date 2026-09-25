# V0.9 Status — Release Candidate & Mainline Consolidation

## Goal

Promote the validated V0.1–V0.8 product line from stacked feature/integration branches into a single canonical mainline baseline.

V0.9 intentionally adds no major product feature. Its purpose is engineering consolidation and release-candidate readiness.

## Scope

- Start from the frozen V0.8 integration baseline.
- Preserve all validated V0.1–V0.8 product capabilities.
- Re-run the complete regression suite on the release-candidate branch.
- Verify Linux portable tests, full macOS/SwiftData tests, and iOS Simulator build.
- Update stale architecture/CI documentation.
- Merge the release candidate to `main`.
- Close historical stacked PRs that are fully superseded by the consolidated mainline.
- Keep the validated milestone integration branches available as historical checkpoints.

## Product baseline included

- V0.1 app shell
- V0.2 SwiftData + FSRS
- V0.3 Notion ingestion
- V0.4 AI extraction
- V0.5 complete learning loop
- V0.6 reminders, Japanese TTS, and local file ingestion
- V0.7 granular Study Scope, diagnostics, and JSON export
- V0.8 safe non-destructive JSON restore

## Release-candidate rule

V0.9 can be promoted to `main` only after the release-candidate branch passes:

- portable Linux core tests
- full macOS Swift package / SwiftData tests
- iOS Simulator build
- no unresolved merge conflict with `main`

## Current state

Release candidate validation passed in GitHub Actions run #167.

Validated commit:

`e5d5a55d15c85667652d31cee92b80347d0a1e3f`

Results:

- portable Linux core tests: passed
- full macOS Swift package / SwiftData tests: passed
- iOS Simulator build: passed
- V0.1–V0.8 regression suite: passed
- static release-candidate scan found no TODO, FIXME, `try!`, or `fatalError` markers
- PR #12 is merge-clean against `main`

**V0.9 release candidate: PASSED.**
