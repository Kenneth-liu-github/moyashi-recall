import XCTest
import SwiftData
@testable import MoyashiRecall

final class LearningDataRestoreServiceTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )
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
    func testRestoreIntoEmptyStorePreservesIDsAndRelationships() throws {
        let sourceContainer = try makeContainer()
        let sourceContext = sourceContainer.mainContext
        let fixture = try insertFixture(
            into: sourceContext,
            updatedAt: Date(
                timeIntervalSince1970: 1_700_000_000
            )
        )

        let package = try LearningDataExportService(
            context: sourceContext
        ).makePackage()

        let targetContainer = try makeContainer()
        let targetContext = targetContainer.mainContext
        let report = try LearningDataRestoreService(
            context: targetContext
        ).restore(package: package)

        XCTAssertEqual(report.sources.inserted, 1)
        XCTAssertEqual(report.knowledgeItems.inserted, 1)
        XCTAssertEqual(report.flashcards.inserted, 1)
        XCTAssertEqual(report.reviewStates.inserted, 1)
        XCTAssertEqual(report.reviewHistory.inserted, 1)

        let sources = try targetContext.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        let knowledge = try targetContext.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        let cards = try targetContext.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        let states = try targetContext.fetch(
            FetchDescriptor<ReviewStateEntity>()
        )
        let history = try targetContext.fetch(
            FetchDescriptor<ReviewHistoryEntity>()
        )

        XCTAssertEqual(sources.first?.id, fixture.sourceID)
        XCTAssertEqual(knowledge.first?.id, fixture.knowledgeID)
        XCTAssertEqual(
            knowledge.first?.sourceDocumentID,
            fixture.sourceID
        )
        XCTAssertEqual(cards.first?.id, fixture.cardID)
        XCTAssertEqual(
            cards.first?.knowledgeItemID,
            fixture.knowledgeID
        )
        XCTAssertEqual(
            states.first?.cardID,
            fixture.cardID
        )
        XCTAssertEqual(
            history.first?.cardID,
            fixture.cardID
        )
    }

    @MainActor
    func testRestoreDoesNotRegressNewerLocalLearningOrFSRSState() throws {
        let older = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let newer = older.addingTimeInterval(3_600)

        let backupContainer = try makeContainer()
        let backupContext = backupContainer.mainContext
        let fixture = try insertFixture(
            into: backupContext,
            updatedAt: older
        )
        let package = try LearningDataExportService(
            context: backupContext
        ).makePackage()

        let targetContainer = try makeContainer()
        let targetContext = targetContainer.mainContext

        let source = SourceDocumentEntity(
            id: fixture.sourceID,
            title: "Newer local source",
            content: "newer source content",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourcePath: "Learning Home / Newer",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: newer
        )
        let knowledge = KnowledgeItemEntity(
            id: fixture.knowledgeID,
            sourceDocumentID: fixture.sourceID,
            extractionKey: "item-1",
            knowledgeType: "expression",
            title: "Newer local knowledge",
            content: "newer knowledge",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: newer
        )
        let card = FlashcardEntity(
            id: fixture.cardID,
            knowledgeItemID: fixture.knowledgeID,
            sourceDocumentID: fixture.sourceID,
            generationKey: "card-1",
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "Newer local prompt",
            answer: "Newer local answer",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: newer
        )
        let state = ReviewStateEntity(
            cardID: fixture.cardID,
            due: newer.addingTimeInterval(86_400),
            stability: 20,
            difficulty: 4,
            elapsedDays: 3,
            scheduledDays: 20,
            repetitions: 8,
            lapses: 1,
            stateRawValue: ReviewLearningState.review.rawValue,
            lastReview: newer
        )

        targetContext.insert(source)
        targetContext.insert(knowledge)
        targetContext.insert(card)
        targetContext.insert(state)
        try targetContext.save()

        let report = try LearningDataRestoreService(
            context: targetContext
        ).restore(package: package)

        XCTAssertEqual(report.sources.updated, 0)
        XCTAssertEqual(report.sources.unchanged, 1)
        XCTAssertEqual(report.knowledgeItems.updated, 0)
        XCTAssertEqual(report.flashcards.updated, 0)
        XCTAssertEqual(report.reviewStates.updated, 0)

        XCTAssertEqual(source.title, "Newer local source")
        XCTAssertEqual(
            knowledge.title,
            "Newer local knowledge"
        )
        XCTAssertEqual(
            card.prompt,
            "Newer local prompt"
        )
        XCTAssertEqual(state.stability, 20)
        XCTAssertEqual(state.lastReview, newer)

        let history = try targetContext.fetch(
            FetchDescriptor<ReviewHistoryEntity>()
        )
        XCTAssertEqual(history.count, 1)
    }

    @MainActor
    func testRestoreUpdatesOlderLocalRecordsFromNewerBackup() throws {
        let older = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let newer = older.addingTimeInterval(3_600)

        let backupContainer = try makeContainer()
        let backupContext = backupContainer.mainContext
        let fixture = try insertFixture(
            into: backupContext,
            updatedAt: newer
        )
        let package = try LearningDataExportService(
            context: backupContext
        ).makePackage()

        let targetContainer = try makeContainer()
        let targetContext = targetContainer.mainContext
        let source = SourceDocumentEntity(
            id: fixture.sourceID,
            title: "Old",
            content: "old",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )
        let knowledge = KnowledgeItemEntity(
            id: fixture.knowledgeID,
            sourceDocumentID: fixture.sourceID,
            title: "Old",
            content: "old",
            sourceKind: "notion",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )
        let card = FlashcardEntity(
            id: fixture.cardID,
            knowledgeItemID: fixture.knowledgeID,
            sourceDocumentID: fixture.sourceID,
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "Old prompt",
            answer: "Old answer",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )

        targetContext.insert(source)
        targetContext.insert(knowledge)
        targetContext.insert(card)
        try targetContext.save()

        let report = try LearningDataRestoreService(
            context: targetContext
        ).restore(package: package)

        XCTAssertEqual(report.sources.updated, 1)
        XCTAssertEqual(report.knowledgeItems.updated, 1)
        XCTAssertEqual(report.flashcards.updated, 1)
        XCTAssertEqual(
            source.title,
            "第二课"
        )
        XCTAssertEqual(
            knowledge.canonicalExpression,
            "進（すす）め方（かた）について"
        )
        XCTAssertEqual(
            card.answer,
            "進（すす）め方（かた）について"
        )
    }

    @MainActor
    func testMalformedBackupMakesNoLocalChanges() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(
            SourceDocumentEntity(
                title: "Existing",
                content: "keep",
                sourceKind: "local",
                externalSourceID: "existing",
                sourceReference: "local://existing"
            )
        )
        try context.save()

        XCTAssertThrowsError(
            try LearningDataRestoreService(
                context: context
            ).restore(
                data: Data("{bad-json}".utf8)
            )
        )

        let sources = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources.first?.title, "Existing")
    }

    @MainActor
    func testRestoreRejectsSourceUUIDIdentityCollision() throws {
        let older = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let newer = older.addingTimeInterval(3_600)

        let backupContainer = try makeContainer()
        let fixture = try insertFixture(
            into: backupContainer.mainContext,
            updatedAt: newer
        )
        let package = try LearningDataExportService(
            context: backupContainer.mainContext
        ).makePackage()

        let targetContainer = try makeContainer()
        let context = targetContainer.mainContext
        let local = SourceDocumentEntity(
            id: fixture.sourceID,
            title: "Local unrelated source",
            content: "keep",
            sourceKind: "notion",
            externalSourceID: "different-page",
            sourceReference: "notion://different-page",
            createdAt: older,
            updatedAt: older
        )
        context.insert(local)
        try context.save()

        XCTAssertThrowsError(
            try LearningDataRestoreService(
                context: context
            ).restore(package: package)
        ) { error in
            XCTAssertEqual(
                error as? LearningDataRestoreError,
                .sourceIdentityConflict(fixture.sourceID)
            )
        }

        XCTAssertEqual(local.title, "Local unrelated source")
        XCTAssertEqual(local.externalSourceID, "different-page")
    }

    @MainActor
    func testKnowledgeIdentityConflictRollsBackEarlierSourceUpdate() throws {
        let older = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let newer = older.addingTimeInterval(3_600)

        let backupContainer = try makeContainer()
        let fixture = try insertFixture(
            into: backupContainer.mainContext,
            updatedAt: newer
        )
        let package = try LearningDataExportService(
            context: backupContainer.mainContext
        ).makePackage()

        let targetContainer = try makeContainer()
        let context = targetContainer.mainContext
        let source = SourceDocumentEntity(
            id: fixture.sourceID,
            title: "Local source",
            content: "local",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )
        let knowledge = KnowledgeItemEntity(
            id: fixture.knowledgeID,
            sourceDocumentID: fixture.sourceID,
            extractionKey: "different-item",
            knowledgeType: "expression",
            title: "Local knowledge",
            content: "local",
            sourceKind: "notion",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )
        context.insert(source)
        context.insert(knowledge)
        try context.save()

        XCTAssertThrowsError(
            try LearningDataRestoreService(
                context: context
            ).restore(package: package)
        ) { error in
            XCTAssertEqual(
                error as? LearningDataRestoreError,
                .knowledgeIdentityConflict(fixture.knowledgeID)
            )
        }

        XCTAssertEqual(source.title, "Local source")
        XCTAssertEqual(knowledge.title, "Local knowledge")
        XCTAssertEqual(knowledge.extractionKey, "different-item")
    }

    @MainActor
    func testFlashcardIdentityConflictRollsBackEarlierUpdates() throws {
        let older = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let newer = older.addingTimeInterval(3_600)

        let backupContainer = try makeContainer()
        let fixture = try insertFixture(
            into: backupContainer.mainContext,
            updatedAt: newer
        )
        let package = try LearningDataExportService(
            context: backupContainer.mainContext
        ).makePackage()

        let targetContainer = try makeContainer()
        let context = targetContainer.mainContext
        let source = SourceDocumentEntity(
            id: fixture.sourceID,
            title: "Local source",
            content: "local",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )
        let knowledge = KnowledgeItemEntity(
            id: fixture.knowledgeID,
            sourceDocumentID: fixture.sourceID,
            extractionKey: "item-1",
            knowledgeType: "expression",
            title: "Local knowledge",
            content: "local",
            sourceKind: "notion",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )
        let card = FlashcardEntity(
            id: fixture.cardID,
            knowledgeItemID: fixture.knowledgeID,
            sourceDocumentID: fixture.sourceID,
            generationKey: "different-card",
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "Local prompt",
            answer: "Local answer",
            sourceReference: "notion://page-1",
            createdAt: older,
            updatedAt: older
        )
        context.insert(source)
        context.insert(knowledge)
        context.insert(card)
        try context.save()

        XCTAssertThrowsError(
            try LearningDataRestoreService(
                context: context
            ).restore(package: package)
        ) { error in
            XCTAssertEqual(
                error as? LearningDataRestoreError,
                .flashcardIdentityConflict(fixture.cardID)
            )
        }

        XCTAssertEqual(source.title, "Local source")
        XCTAssertEqual(knowledge.title, "Local knowledge")
        XCTAssertEqual(card.prompt, "Local prompt")
        XCTAssertEqual(card.generationKey, "different-card")
    }

    @MainActor
    private func insertFixture(
        into context: ModelContext,
        updatedAt: Date
    ) throws -> (
        sourceID: UUID,
        knowledgeID: UUID,
        cardID: UUID
    ) {
        let sourceID = UUID()
        let knowledgeID = UUID()
        let cardID = UUID()

        let source = SourceDocumentEntity(
            id: sourceID,
            title: "第二课",
            content: "source",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1",
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
        let knowledge = KnowledgeItemEntity(
            id: knowledgeID,
            sourceDocumentID: sourceID,
            extractionKey: "item-1",
            knowledgeType: "expression",
            title: "進（すす）め方（かた）について",
            canonicalExpression: "進（すす）め方（かた）について",
            meaning: "关于推进方式",
            explanation: "说明",
            naturalEnglish: "regarding how to proceed",
            content: "knowledge",
            tags: "商务",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference,
            aiProvider: "openai",
            aiModel: "configured-model",
            extractionVersion: "v1",
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
        let card = FlashcardEntity(
            id: cardID,
            knowledgeItemID: knowledgeID,
            sourceDocumentID: sourceID,
            generationKey: "card-1",
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "关于推进方式",
            answer: "進（すす）め方（かた）について",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
        let state = ReviewStateEntity(
            cardID: cardID,
            due: updatedAt.addingTimeInterval(86_400),
            stability: 3,
            difficulty: 5,
            elapsedDays: 1,
            scheduledDays: 3,
            repetitions: 2,
            lapses: 0,
            stateRawValue: ReviewLearningState.review.rawValue,
            lastReview: updatedAt
        )
        let history = ReviewHistoryEntity(
            cardID: cardID,
            reviewedAt: updatedAt,
            ratingRawValue: ReviewRating.good.rawValue,
            elapsedDays: 1,
            scheduledDays: 3,
            stabilityBefore: 2,
            stabilityAfter: 3,
            difficultyBefore: 5,
            difficultyAfter: 4
        )

        context.insert(source)
        context.insert(knowledge)
        context.insert(card)
        context.insert(state)
        context.insert(history)
        try context.save()

        return (
            sourceID,
            knowledgeID,
            cardID
        )
    }
}
