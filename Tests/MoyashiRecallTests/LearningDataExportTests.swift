import XCTest
import SwiftData
@testable import MoyashiRecall

final class LearningDataExportTests: XCTestCase {
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
    func testExportIncludesLearningAndReviewState() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date(
            timeIntervalSince1970: 1_700_000_000
        )

        let source = SourceDocumentEntity(
            title: "第二课",
            content: "source content",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1",
            createdAt: now,
            updatedAt: now
        )
        let knowledge = KnowledgeItemEntity(
            sourceDocumentID: source.id,
            extractionKey: "item-1",
            knowledgeType: "expression",
            title: "進（すす）め方（かた）について",
            canonicalExpression: "進（すす）め方（かた）について",
            meaning: "关于推进方式",
            content: "knowledge",
            sourceKind: "notion",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference,
            createdAt: now,
            updatedAt: now
        )
        let card = FlashcardEntity(
            knowledgeItemID: knowledge.id,
            sourceDocumentID: source.id,
            generationKey: "card-1",
            cardType: ReviewCardType.zhToJa.rawValue,
            prompt: "关于推进方式",
            answer: "進（すす）め方（かた）について",
            sourceKey: "office-japanese",
            sourceDisplayPath: source.sourcePath,
            sourceReference: source.sourceReference,
            createdAt: now,
            updatedAt: now
        )
        let state = ReviewStateEntity(
            cardID: card.id,
            due: now,
            stability: 3,
            difficulty: 5,
            elapsedDays: 1,
            scheduledDays: 3,
            repetitions: 2,
            lapses: 0,
            stateRawValue: ReviewLearningState.review.rawValue,
            lastReview: now
        )
        let history = ReviewHistoryEntity(
            cardID: card.id,
            reviewedAt: now,
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

        let package = try LearningDataExportService(
            context: context
        ).makePackage(exportedAt: now)

        XCTAssertEqual(package.schemaVersion, "v1")
        XCTAssertEqual(package.exportedAt, now)
        XCTAssertEqual(package.sources.count, 1)
        XCTAssertEqual(package.knowledgeItems.count, 1)
        XCTAssertEqual(package.flashcards.count, 1)
        XCTAssertEqual(package.reviewStates.count, 1)
        XCTAssertEqual(package.reviewHistory.count, 1)
        XCTAssertEqual(
            package.flashcards.first?.id,
            card.id
        )
        XCTAssertEqual(
            package.reviewHistory.first?.cardID,
            card.id
        )
    }

    @MainActor
    func testExportJSONRoundTripsAndContainsNoCredentialFields() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let data = try LearningDataExportService(
            context: context
        ).makeJSONData(
            exportedAt: Date(
                timeIntervalSince1970: 1_700_000_000
            )
        )

        let decoded = try JSONDecoder.withISO8601Dates.decode(
            LearningDataExportPackage.self,
            from: data
        )
        XCTAssertEqual(decoded.schemaVersion, "v1")

        let json = try XCTUnwrap(
            String(
                data: data,
                encoding: .utf8
            )
        )
        XCTAssertFalse(
            json.localizedCaseInsensitiveContains(
                "apiKey"
            )
        )
        XCTAssertFalse(
            json.localizedCaseInsensitiveContains(
                "token"
            )
        )
        XCTAssertFalse(
            json.localizedCaseInsensitiveContains(
                "keychain"
            )
        )
    }
}

private extension JSONDecoder {
    static var withISO8601Dates: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
