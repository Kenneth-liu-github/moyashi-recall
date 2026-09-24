# Moyashi Recall — Product Specification

## Vision

Moyashi Recall turns Japanese material a learner has already studied into a personal, continuously improving review system.

Primary source in the first production milestone is Notion, while the domain model must also support PDF, Word, PowerPoint, Excel, images, text/Markdown, audio, video, and manual input.

## V0.1 navigation

- 首页
- 复习
- 资料库
- 卡片
- 设置

## Home

Show due cards, streak, weekly study time, total/mastered cards, and weak topics. Primary CTA starts a review session.

## Study Scope

Users can select multiple sources and nested documents/pages, choose card types (中→日, 日→中, Cloze, grammar/contrast), choose card count, and later save presets.

## Review

Question side shows prompt and source context. Answer side shows Japanese answer with furigana where applicable, Chinese meaning, example, Natural English, grammar note, and Again / Hard / Good / Easy.

## Library

Organize learning sources by source type. Show hierarchy, card/item counts, sync status, and source traceability.

## Localization

First launch opens directly in Simplified Chinese. Users may switch the entire interface to Japanese in 设置 → 界面语言. This changes UI chrome only; it must never rewrite learning content or source material.

## Design system

Maximum four colors across the product:
1. white/background
2. dark text
3. neutral gray
4. cold blue accent

No rainbow category palette. Status differences should primarily use typography, iconography, opacity, shape, or the same blue/gray system.

## Architecture direction

SwiftUI + SwiftData locally. Services are protocol-driven so Notion, AI providers, persistence, and FSRS can be replaced/tested independently.

AI flow: App → AI Gateway → Provider Adapter

Learning data: Source → Document → KnowledgeItem → Flashcard → ReviewRecord → FSRSState
