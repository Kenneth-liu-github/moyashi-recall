import XCTest
import SwiftData
@testable import MoyashiRecall

final class DataLayerTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: SourceDocumentEntity.self,
            KnowledgeItemEntity.self,
            FlashcardEntity.self,
            ReviewStateEntity.self,
            ReviewHistoryEntity.self,
            configurations: configuration
        )
    }

    @MainActor
    func testReviewQueueFiltersBySourceAndDueDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let knowledgeID = UUID()

        let dueCard = FlashcardEntity(
            knowledgeItemID: knowledgeID,
            cardType: "zh-to-ja",
            prompt: "A",
            answer: "A",
            sourceKey: "office-japanese",
            sourceReference: "办公室日语学习"
        )
        let futureCard = FlashcardEntity(
            knowledgeItemID: knowledgeID,
            cardType: "zh-to-ja",
            prompt: "B",
            answer: "B",
            sourceKey: "office-japanese",
            sourceReference: "办公室日语学习"
        )
        let otherSource = FlashcardEntity(
            knowledgeItemID: knowledgeID,
            cardType: "zh-to-ja",
            prompt: "C",
            answer: "C",
            sourceKey: "japanese-bootcamp",
            sourceReference: "日语训练营"
        )

        context.insert(dueCard)
        context.insert(futureCard)
        context.insert(otherSource)
        context.insert(ReviewStateEntity(cardID: dueCard.id, due: now.addingTimeInterval(-3600)))
        context.insert(ReviewStateEntity(cardID: futureCard.id, due: now.addingTimeInterval(86_400)))
        try context.save()

        let result = try ReviewQueueService().dueCards(
            in: context,
            now: now,
            sourceKeys: ["office-japanese"]
        )

        XCTAssertEqual(result.map(\.id), [dueCard.id])
    }

    @MainActor
    func testReviewQueueFiltersByCardType() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let knowledgeID = UUID()

        let zhToJa = FlashcardEntity(
            knowledgeItemID: knowledgeID,
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "中文",
            answer: "日本語",
            sourceKey: "office-japanese",
            sourceReference: "test"
        )
        let contrast = FlashcardEntity(
            knowledgeItemID: knowledgeID,
            cardType: ReviewCardType.contrast.rawValue,
            prompt: "A vs B",
            answer: "difference",
            sourceKey: "office-japanese",
            sourceReference: "test"
        )
        context.insert(zhToJa)
        context.insert(contrast)
        try context.save()

        let result = try ReviewQueueService().dueCards(
            in: context,
            cardTypes: [
                ReviewCardType.contrast.rawValue
            ]
        )

        XCTAssertEqual(
            result.map(\.id),
            [contrast.id]
        )
    }

    @MainActor
    func testNewCardsAreImmediatelyDueAndLimitIsHonored() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let knowledgeID = UUID()

        for index in 0..<3 {
            context.insert(
                FlashcardEntity(
                    knowledgeItemID: knowledgeID,
                    cardType: "zh-to-ja",
                    prompt: "Q\(index)",
                    answer: "A\(index)",
                    sourceKey: "office-japanese",
                    sourceReference: "办公室日语学习",
                    createdAt: Date(timeIntervalSince1970: Double(index))
                )
            )
        }
        try context.save()

        let result = try ReviewQueueService().dueCards(in: context, limit: 2)

        XCTAssertEqual(result.count, 2)
    }

    @MainActor
    func testReviewRecorderPersistsStateAndHistory() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let cardID = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(
            FlashcardEntity(
                id: cardID,
                knowledgeItemID: UUID(),
                cardType: "zh-to-ja",
                prompt: "Q",
                answer: "A",
                sourceKey: "office-japanese",
                sourceReference: "办公室日语学习"
            )
        )
        try context.save()

        let result = try ReviewRecorder().record(
            cardID: cardID,
            rating: .good,
            in: context,
            now: now
        )

        let states = try context.fetch(FetchDescriptor<ReviewStateEntity>())
        let history = try context.fetch(FetchDescriptor<ReviewHistoryEntity>())

        XCTAssertEqual(states.count, 1)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(states.first?.cardID, cardID)
        XCTAssertEqual(history.first?.ratingRawValue, ReviewRating.good.rawValue)
        XCTAssertEqual(states.first?.scheduledDays, result.scheduledDays)
    }

    @MainActor
    func testReviewRecorderRejectsMissingCardWithoutCreatingOrphans() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let missingID = UUID()

        XCTAssertThrowsError(
            try ReviewRecorder().record(
                cardID: missingID,
                rating: .good,
                in: context
            )
        ) { error in
            XCTAssertEqual(
                error as? ReviewRecordingError,
                ReviewRecordingError.cardNotFound(missingID)
            )
        }

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<ReviewStateEntity>()).isEmpty
        )
        XCTAssertTrue(
            try context.fetch(FetchDescriptor<ReviewHistoryEntity>()).isEmpty
        )
    }

    @MainActor
    func testReviewRecorderRejectsInactiveCard() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let card = FlashcardEntity(
            knowledgeItemID: UUID(),
            cardType: "zh-to-ja",
            prompt: "Q",
            answer: "A",
            sourceReference: "test",
            isActive: false
        )
        context.insert(card)
        try context.save()

        XCTAssertThrowsError(
            try ReviewRecorder().record(
                cardID: card.id,
                rating: .good,
                in: context
            )
        ) { error in
            XCTAssertEqual(
                error as? ReviewRecordingError,
                .cardInactive(card.id)
            )
        }
    }

    @MainActor
    func testReviewQueuePrioritizesOverdueReviewsBeforeNewCards() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let newCard = FlashcardEntity(
            knowledgeItemID: UUID(),
            cardType: "zh-to-ja",
            prompt: "new",
            answer: "new",
            sourceKey: "office-japanese",
            sourceReference: "办公室日语学习",
            createdAt: now.addingTimeInterval(-86_400)
        )
        let overdueCard = FlashcardEntity(
            knowledgeItemID: UUID(),
            cardType: "zh-to-ja",
            prompt: "overdue",
            answer: "overdue",
            sourceKey: "office-japanese",
            sourceReference: "办公室日语学习",
            createdAt: now
        )
        context.insert(newCard)
        context.insert(overdueCard)
        context.insert(
            ReviewStateEntity(
                cardID: overdueCard.id,
                due: now.addingTimeInterval(-3_600)
            )
        )
        try context.save()

        let result = try ReviewQueueService().dueCards(
            in: context,
            now: now
        )

        XCTAssertEqual(result.first?.id, overdueCard.id)
        XCTAssertEqual(result.last?.id, newCard.id)
    }

    @MainActor
    func testDemoSeederIsIdempotentAndMigratesSourceKey() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try DemoDataSeeder.seedIfNeeded(in: context)
        try DemoDataSeeder.seedIfNeeded(in: context)

        var cards = try context.fetch(FetchDescriptor<FlashcardEntity>())
        XCTAssertEqual(cards.filter { $0.id == DemoDataSeeder.cardID }.count, 1)

        cards.first { $0.id == DemoDataSeeder.cardID }?.sourceKey = ""
        try context.save()
        try DemoDataSeeder.seedIfNeeded(in: context)

        cards = try context.fetch(FetchDescriptor<FlashcardEntity>())
        XCTAssertEqual(cards.first { $0.id == DemoDataSeeder.cardID }?.sourceKey, "office-japanese")
    }

    @MainActor
    func testRepositoryBuildsHomeSnapshotFromPersistence() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let card = FlashcardEntity(
            knowledgeItemID: UUID(),
            cardType: "zh-to-ja",
            prompt: "Q",
            answer: "A",
            sourceKey: "office-japanese",
            sourceReference: "办公室日语学习"
        )
        context.insert(card)
        context.insert(
            ReviewHistoryEntity(
                cardID: card.id,
                reviewedAt: now,
                ratingRawValue: ReviewRating.good.rawValue,
                elapsedDays: 0,
                scheduledDays: 2,
                stabilityBefore: 0,
                stabilityAfter: 2.3065,
                difficultyBefore: 5,
                difficultyAfter: 2.1181
            )
        )
        try context.save()

        let snapshot = try LearningRepository(context: context).homeSnapshot(now: now)

        XCTAssertEqual(snapshot.dueCount, 1)
        XCTAssertEqual(snapshot.streakDays, 1)
    }

    @MainActor
    func testRepositorySearchAndSourceCountsUsePersistedCards() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(
            FlashcardEntity(
                knowledgeItemID: UUID(),
                cardType: "zh-to-ja",
                prompt: "关于推进方式",
                answer: "進（すす）め方（かた）について",
                sourceKey: "office-japanese",
                sourceReference: "办公室日语学习 · 第二课"
            )
        )
        context.insert(
            FlashcardEntity(
                knowledgeItemID: UUID(),
                cardType: "zh-to-ja",
                prompt: "条件表达",
                answer: "～ば",
                sourceKey: "japanese-bootcamp",
                sourceReference: "日语训练营"
            )
        )
        try context.save()

        let repository = LearningRepository(context: context)
        let matches = try repository.allSessionCards(searchText: "推进")
        let counts = try repository.cardCountsBySourceKey()

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.sourceKey, "office-japanese")
        XCTAssertEqual(counts["office-japanese"], 1)
        XCTAssertEqual(counts["japanese-bootcamp"], 1)
    }

    @MainActor
    func testImportedDocumentUpsertIsIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = LearningRepository(context: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let sourceEditedAt = now.addingTimeInterval(-120)

        let original = ImportedDocument(
            id: "notion-page-1",
            sourceKind: "notion",
            title: "第二课",
            sourceReference: "https://www.notion.so/page-1",
            content: "原始内容",
            lastEditedAt: sourceEditedAt,
            parentExternalID: "office-root",
            sourcePath: [
                "Learning Home",
                "办公室日语学习",
                "第二课"
            ],
            hierarchyDepth: 2
        )
        let firstResult = try repository.upsertImportedDocumentWithResult(
            original,
            now: now
        )
        let first = firstResult.entity
        XCTAssertEqual(firstResult.mutation, .inserted)

        let unchangedResult = try repository.upsertImportedDocumentWithResult(
            original,
            now: now.addingTimeInterval(30)
        )
        XCTAssertEqual(unchangedResult.mutation, .unchanged)

        let updated = ImportedDocument(
            id: "notion-page-1",
            sourceKind: "notion",
            title: "第二课（更新）",
            sourceReference: "https://www.notion.so/page-1",
            content: "更新后的内容",
            lastEditedAt: sourceEditedAt.addingTimeInterval(60),
            parentExternalID: "office-root",
            sourcePath: [
                "Learning Home",
                "办公室日语学习",
                "第二课（更新）"
            ],
            hierarchyDepth: 2
        )
        let secondResult = try repository.upsertImportedDocumentWithResult(
            updated,
            now: now.addingTimeInterval(60)
        )
        let second = secondResult.entity
        XCTAssertEqual(secondResult.mutation, .updated)

        let items = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(items.first?.externalSourceID, "notion-page-1")
        XCTAssertEqual(items.first?.title, "第二课（更新）")
        XCTAssertEqual(items.first?.content, "更新后的内容")
        XCTAssertEqual(
            items.first?.parentExternalSourceID,
            "office-root"
        )
        XCTAssertEqual(
            items.first?.sourcePath,
            "Learning Home / 办公室日语学习 / 第二课（更新）"
        )
        XCTAssertEqual(
            items.first?.sourceKey,
            "office-japanese"
        )
        XCTAssertEqual(items.first?.hierarchyDepth, 2)
        XCTAssertEqual(
            items.first?.sourceLastEditedAt,
            sourceEditedAt.addingTimeInterval(60)
        )
        XCTAssertEqual(
            items.first?.lastSyncedAt,
            now.addingTimeInterval(60)
        )

        let summaries = try repository.importedDocuments(
            sourceKind: "notion"
        )
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(
            summaries.first?.sourcePath,
            "Learning Home / 办公室日语学习 / 第二课（更新）"
        )
    }

    @MainActor
    func testReconcileImportedTreeDeactivatesRemovedPages() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = LearningRepository(context: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let root = ImportedDocument(
            id: "root",
            sourceKind: "notion",
            title: "Learning Home",
            sourceReference: "https://www.notion.so/root",
            content: "root",
            rootExternalID: "root",
            sourcePath: ["Learning Home"],
            hierarchyDepth: 0
        )
        let removedChild = ImportedDocument(
            id: "removed-child",
            sourceKind: "notion",
            title: "旧页面",
            sourceReference: "https://www.notion.so/removed",
            content: "old",
            parentExternalID: "root",
            rootExternalID: "root",
            sourcePath: ["Learning Home", "旧页面"],
            hierarchyDepth: 1
        )

        _ = try repository.upsertImportedDocument(root, now: now)
        _ = try repository.upsertImportedDocument(
            removedChild,
            now: now
        )

        let deactivated = try repository.reconcileImportedTree(
            sourceKind: "notion",
            rootExternalID: "root",
            activeExternalIDs: ["root"],
            now: now.addingTimeInterval(60)
        )

        XCTAssertEqual(deactivated, 1)

        let allItems = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        XCTAssertEqual(
            allItems.first {
                $0.externalSourceID == "removed-child"
            }?.isSourceActive,
            false
        )

        let visible = try repository.importedDocuments(
            sourceKind: "notion"
        )
        XCTAssertEqual(visible.map(\.externalSourceID), ["root"])
    }

    @MainActor
    func testLegacyImportedKnowledgeMigratesToSourceDocumentWithoutDeletion() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let legacy = KnowledgeItemEntity(
            title: "第二课",
            content: "旧导入内容",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceReference: "https://notion.so/page-1",
            externalSourceID: "page-1",
            parentExternalSourceID: "office-root",
            rootExternalSourceID: "root",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            hierarchyDepth: 2,
            isSourceActive: true
        )
        context.insert(legacy)
        try context.save()

        let repository = LearningRepository(context: context)
        let migrated = try repository
            .migrateLegacyImportedKnowledgeIfNeeded()

        XCTAssertEqual(migrated, 1)

        let sources = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(
            sources.first?.externalSourceID,
            "page-1"
        )
        XCTAssertEqual(
            sources.first?.sourcePath,
            "Learning Home / 办公室日语学习 / 第二课"
        )

        let legacyItems = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        XCTAssertEqual(legacyItems.count, 1)
        XCTAssertEqual(
            legacyItems.first?.isActive,
            false
        )
        XCTAssertEqual(
            legacyItems.first?.isSourceActive,
            false
        )

        XCTAssertEqual(
            try repository
                .migrateLegacyImportedKnowledgeIfNeeded(),
            0
        )
    }

    @MainActor
    func testRepositoryReturnsValueTypeSessionCards() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let card = FlashcardEntity(
            knowledgeItemID: UUID(),
            cardType: "zh-to-ja",
            prompt: "Q",
            answer: "A",
            naturalEnglish: "answer",
            sourceKey: "office-japanese",
            sourceReference: "办公室日语学习"
        )
        context.insert(card)
        try context.save()

        let cards = try LearningRepository(context: context).dueSessionCards(
            sourceKeys: ["office-japanese"],
            limit: 10
        )

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.id, card.id)
        XCTAssertEqual(cards.first?.naturalEnglish, "answer")
    }
    @MainActor
    func testReviewSourcesAndFilteredDueCountsUseRealQueueState() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let source = SourceDocumentEntity(
            title: "第二课",
            content: "content",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1"
        )
        let knowledge = KnowledgeItemEntity(
            sourceDocumentID: source.id,
            extractionKey: "item",
            knowledgeType: "expression",
            title: "進（すす）め方（かた）について",
            canonicalExpression: "進（すす）め方（かた）について",
            content: "content",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )
        let dueCard = FlashcardEntity(
            knowledgeItemID: knowledge.id,
            sourceDocumentID: source.id,
            generationKey: "due",
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "Q1",
            answer: "A1",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )
        let futureCard = FlashcardEntity(
            knowledgeItemID: knowledge.id,
            sourceDocumentID: source.id,
            generationKey: "future",
            cardType: ReviewCardType.jaToZh.rawValue,
            prompt: "Q2",
            answer: "A2",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )

        context.insert(source)
        context.insert(knowledge)
        context.insert(dueCard)
        context.insert(futureCard)
        context.insert(
            ReviewStateEntity(
                cardID: dueCard.id,
                due: now.addingTimeInterval(-60)
            )
        )
        context.insert(
            ReviewStateEntity(
                cardID: futureCard.id,
                due: now.addingTimeInterval(86_400)
            )
        )
        try context.save()

        let repository = LearningRepository(context: context)
        let sources = try repository.reviewSources(now: now)

        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources.first?.cardCount, 2)
        XCTAssertEqual(sources.first?.dueCardCount, 1)

        let jaToZhOnly = try repository.reviewSources(
            now: now,
            cardTypes: [ReviewCardType.jaToZh.rawValue]
        )
        XCTAssertEqual(jaToZhOnly.first?.cardCount, 2)
        XCTAssertEqual(jaToZhOnly.first?.dueCardCount, 0)

        XCTAssertEqual(
            try repository.dueCardCount(
                now: now,
                sourceKeys: ["office-japanese"],
                cardTypes: [ReviewCardType.zhToJa.rawValue]
            ),
            1
        )
        XCTAssertEqual(
            try repository.dueCardCount(
                now: now,
                sourceKeys: ["office-japanese"],
                cardTypes: [ReviewCardType.jaToZh.rawValue]
            ),
            0
        )
    }

    @MainActor
    func testHomeSnapshotUsesRealReviewHistoryAndWeakKnowledge() throws {
        let container = try makeContainer()
        let context = container.mainContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(secondsFromGMT: 0)
        )
        let now = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 25,
                    hour: 12
                )
            )
        )

        let source = SourceDocumentEntity(
            title: "第二课",
            content: "content",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1"
        )
        let knowledge = KnowledgeItemEntity(
            sourceDocumentID: source.id,
            extractionKey: "weak-item",
            knowledgeType: "grammar",
            title: "使役・受身",
            canonicalExpression: "使役（しえき）・受身（うけみ）",
            content: "content",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )
        let card = FlashcardEntity(
            knowledgeItemID: knowledge.id,
            sourceDocumentID: source.id,
            generationKey: "weak-card",
            cardType: ReviewCardType.application.rawValue,
            prompt: "Q",
            answer: "A",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )

        context.insert(source)
        context.insert(knowledge)
        context.insert(card)
        context.insert(
            ReviewStateEntity(
                cardID: card.id,
                due: now.addingTimeInterval(-60)
            )
        )

        let ratings: [(Int, Int)] = [
            (ReviewRating.again.rawValue, 0),
            (ReviewRating.hard.rawValue, -1),
            (ReviewRating.good.rawValue, -2),
            (ReviewRating.easy.rawValue, -3)
        ]
        for (rating, dayOffset) in ratings {
            let reviewedAt = try XCTUnwrap(
                calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: now
                )
            )
            context.insert(
                ReviewHistoryEntity(
                    cardID: card.id,
                    reviewedAt: reviewedAt,
                    ratingRawValue: rating,
                    elapsedDays: 1,
                    scheduledDays: 2,
                    stabilityBefore: 1,
                    stabilityAfter: 2,
                    difficultyBefore: 5,
                    difficultyAfter: 4
                )
            )
        }
        try context.save()

        let snapshot = try LearningRepository(
            context: context
        ).homeSnapshot(now: now)

        XCTAssertEqual(snapshot.dueCount, 1)
        XCTAssertEqual(snapshot.reviewedToday, 1)
        XCTAssertEqual(snapshot.reviewedLast7Days, 4)
        XCTAssertEqual(snapshot.latestReviewAt, now)
        XCTAssertEqual(
            snapshot.successRateLast7Days,
            0.75,
            accuracy: 0.000001
        )
        XCTAssertEqual(snapshot.weakKnowledge.count, 1)
        XCTAssertEqual(
            snapshot.weakKnowledge.first?.title,
            "使役（しえき）・受身（うけみ）"
        )
        XCTAssertEqual(
            snapshot.weakKnowledge.first?.difficultReviews,
            2
        )
    }


    @MainActor
    func testDueQueueCanTargetWeakKnowledgeItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let firstKnowledge = KnowledgeItemEntity(
            extractionKey: "first",
            knowledgeType: "grammar",
            title: "First",
            content: "first",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceReference: "notion://first"
        )
        let secondKnowledge = KnowledgeItemEntity(
            extractionKey: "second",
            knowledgeType: "grammar",
            title: "Second",
            content: "second",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceReference: "notion://second"
        )
        let firstCard = FlashcardEntity(
            knowledgeItemID: firstKnowledge.id,
            cardType: ReviewCardType.application.rawValue,
            prompt: "Q1",
            answer: "A1",
            sourceKey: "office-japanese",
            sourceReference: "notion://first"
        )
        let secondCard = FlashcardEntity(
            knowledgeItemID: secondKnowledge.id,
            cardType: ReviewCardType.application.rawValue,
            prompt: "Q2",
            answer: "A2",
            sourceKey: "office-japanese",
            sourceReference: "notion://second"
        )

        context.insert(firstKnowledge)
        context.insert(secondKnowledge)
        context.insert(firstCard)
        context.insert(secondCard)
        try context.save()

        let targeted = try LearningRepository(
            context: context
        ).dueSessionCards(
            now: now,
            knowledgeItemIDs: [secondKnowledge.id]
        )

        XCTAssertEqual(targeted.map(\.id), [secondCard.id])
    }


    @MainActor
    func testRecentReviewHistoryPreservesInactiveCardHistory() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let card = FlashcardEntity(
            knowledgeItemID: UUID(),
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "过去的问题",
            answer: "过去的答案",
            sourceKey: "office-japanese",
            sourceDisplayPath: "Learning Home / 办公室日语学习 / 第二课",
            sourceReference: "notion://page",
            isActive: false
        )
        let reviewedAt = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let event = ReviewHistoryEntity(
            cardID: card.id,
            reviewedAt: reviewedAt,
            ratingRawValue: ReviewRating.hard.rawValue,
            elapsedDays: 1,
            scheduledDays: 2,
            stabilityBefore: 1,
            stabilityAfter: 2,
            difficultyBefore: 5,
            difficultyAfter: 5
        )

        context.insert(card)
        context.insert(event)
        try context.save()

        let history = try LearningRepository(
            context: context
        ).recentReviewHistory()

        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.cardID, card.id)
        XCTAssertEqual(history.first?.rating, .hard)
        XCTAssertEqual(
            history.first?.sourceDisplay,
            "Learning Home / 办公室日语学习 / 第二课"
        )
    }


    @MainActor
    func testLocalFileImportIsIdempotentAndUpdatesChangedContent() throws {
        let container = try makeContainer()
        let repository = LearningRepository(
            context: container.mainContext
        )
        let service = LocalFileImportService(
            repository: repository
        )

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let url = directory.appendingPathComponent(
            "lesson.txt"
        )
        try "first".write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        let first = try service.importFile(
            at: url,
            now: Date(
                timeIntervalSince1970: 1_700_000_000
            )
        )
        XCTAssertEqual(first.inserted, 1)
        XCTAssertEqual(first.updated, 0)

        let second = try service.importFile(
            at: url,
            now: Date(
                timeIntervalSince1970: 1_700_000_060
            )
        )
        XCTAssertEqual(second.inserted, 0)
        XCTAssertEqual(second.unchanged, 1)

        try "second".write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        let third = try service.importFile(
            at: url,
            now: Date(
                timeIntervalSince1970: 1_700_000_120
            )
        )
        XCTAssertEqual(third.inserted, 0)
        XCTAssertEqual(third.updated, 1)

        let documents = try repository.importedDocuments(
            sourceKind: "file"
        )
        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents.first?.content, "second")
        XCTAssertTrue(
            documents.first?.sourceKey
                .hasPrefix("file-") == true
        )
    }


    @MainActor
    func testArchivingLocalFilePreservesReviewHistory() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = LearningRepository(
            context: context
        )

        let source = SourceDocumentEntity(
            title: "notes.txt",
            content: "content",
            sourceKind: "file",
            externalSourceID: "local-file:notes:abc",
            rootExternalSourceID: "local-file:notes:abc",
            sourcePath: "Imported Files / notes.txt",
            sourceKey: "file-abc",
            sourceReference: "local-file://notes.txt"
        )
        let knowledge = KnowledgeItemEntity(
            sourceDocumentID: source.id,
            extractionKey: "item",
            knowledgeType: "expression",
            title: "表現（ひょうげん）",
            content: "content",
            sourceKind: "file",
            sourceKey: "file-abc",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )
        let card = FlashcardEntity(
            knowledgeItemID: knowledge.id,
            sourceDocumentID: source.id,
            generationKey: "card",
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "Q",
            answer: "A",
            sourceKey: "file-abc",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )
        let event = ReviewHistoryEntity(
            cardID: card.id,
            reviewedAt: .now,
            ratingRawValue: ReviewRating.good.rawValue,
            elapsedDays: 1,
            scheduledDays: 2,
            stabilityBefore: 1,
            stabilityAfter: 2,
            difficultyBefore: 5,
            difficultyAfter: 4
        )

        context.insert(source)
        context.insert(knowledge)
        context.insert(card)
        context.insert(event)
        try context.save()

        let archived = try repository.archiveImportedSource(
            sourceKind: "file",
            rootExternalID: source.rootExternalSourceID
        )

        XCTAssertEqual(archived, 1)
        XCTAssertEqual(
            try repository.importedDocuments(
                sourceKind: "file"
            ).count,
            0
        )
        XCTAssertTrue(
            try repository.dueSessionCards().isEmpty
        )
        XCTAssertEqual(
            try repository.recentReviewHistory().count,
            1
        )
    }


    @MainActor
    func testImportedFileUsesFilenameAsStudySourceTitle() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let source = SourceDocumentEntity(
            title: "lesson.pdf",
            content: "",
            sourceKind: "file",
            externalSourceID: "local-file:lesson:abc",
            rootExternalSourceID: "local-file:lesson:abc",
            sourcePath: "Imported Files / lesson.pdf",
            sourceKey: "file-abc",
            sourceReference: "local-file://lesson.pdf"
        )
        let knowledge = KnowledgeItemEntity(
            sourceDocumentID: source.id,
            extractionKey: "item",
            knowledgeType: "expression",
            title: "表現（ひょうげん）",
            content: "content",
            sourceKind: "file",
            sourceKey: "file-abc",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )
        let card = FlashcardEntity(
            knowledgeItemID: knowledge.id,
            sourceDocumentID: source.id,
            generationKey: "card",
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "Q",
            answer: "A",
            sourceKey: "file-abc",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference
        )

        context.insert(source)
        context.insert(knowledge)
        context.insert(card)
        try context.save()

        let sources = try LearningRepository(
            context: context
        ).reviewSources()

        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(
            sources.first?.title,
            "lesson.pdf"
        )
        XCTAssertEqual(
            sources.first?.key,
            "file-abc"
        )
    }

    @MainActor
    func testImportedPDFPagesSortNaturally() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let rootID = "local-file:lesson:abc"

        for page in [10, 2, 1] {
            context.insert(
                SourceDocumentEntity(
                    title: "Page \(page)",
                    content: "page \(page)",
                    sourceKind: "file",
                    externalSourceID:
                        "\(rootID)#page-\(page)",
                    parentExternalSourceID: rootID,
                    rootExternalSourceID: rootID,
                    sourcePath:
                        "Imported Files / lesson.pdf / Page \(page)",
                    sourceKey: "file-abc",
                    hierarchyDepth: 1,
                    sourceReference:
                        "local-file://lesson.pdf#page=\(page)"
                )
            )
        }

        context.insert(
            SourceDocumentEntity(
                title: "lesson.pdf",
                content: "",
                sourceKind: "file",
                externalSourceID: rootID,
                rootExternalSourceID: rootID,
                sourcePath: "Imported Files / lesson.pdf",
                sourceKey: "file-abc",
                hierarchyDepth: 0,
                sourceReference: "local-file://lesson.pdf"
            )
        )
        try context.save()

        let items = try LearningRepository(
            context: context
        ).importedDocuments(
            sourceKind: "file"
        )

        XCTAssertEqual(
            items.map(\.title),
            [
                "lesson.pdf",
                "Page 1",
                "Page 2",
                "Page 10"
            ]
        )
    }


}
