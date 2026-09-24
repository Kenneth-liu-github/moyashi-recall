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
}
