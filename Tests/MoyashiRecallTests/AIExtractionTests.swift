import XCTest
import SwiftData
@testable import MoyashiRecall

final class AIExtractionTests: XCTestCase {
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

    func testExtractorDecodesStructuredKnowledgeBundle() async throws {
        let provider = StaticAIProvider(
            providerID: "fixture",
            modelID: "fixture-1",
            response: Self.fixtureJSON
        )
        let service = KnowledgeExtractionService(
            provider: provider
        )

        let result = try await service.extract(
            from: ImportedDocument(
                id: "doc",
                sourceKind: "notion",
                title: "第二课",
                sourceReference: "notion://doc",
                content: "進（すす）め方（かた）について",
                sourcePath: [
                    "Learning Home",
                    "办公室日语学习",
                    "第二课"
                ]
            )
        )

        XCTAssertEqual(result.providerID, "fixture")
        XCTAssertEqual(result.modelID, "fixture-1")
        XCTAssertEqual(result.bundle.version, "v1")
        XCTAssertEqual(result.bundle.items.count, 1)
        XCTAssertEqual(
            result.bundle.items.first?.kind,
            .expression
        )
        XCTAssertEqual(
            result.bundle.items.first?.cards.first?.type,
            .zhToJa
        )
    }

    func testExtractorRejectsMalformedJSON() async throws {
        let service = KnowledgeExtractionService(
            provider: StaticAIProvider(
                providerID: "fixture",
                modelID: "fixture-1",
                response: "not-json"
            )
        )

        do {
            _ = try await service.extract(
                from: ImportedDocument(
                    id: "doc",
                    sourceKind: "notion",
                    title: "Bad",
                    sourceReference: "notion://bad",
                    content: "bad"
                )
            )
            XCTFail("Expected decoding failure")
        } catch let error as AIProviderError {
            XCTAssertEqual(error, .decodingFailed)
        }
    }

    @MainActor
    func testProcessingPersistsKnowledgeAndCardsIdempotently() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let source = SourceDocumentEntity(
            title: "第二课",
            content: "進（すす）め方（かた）について",
            sourceKind: "notion",
            externalSourceID: "page-1",
            rootExternalSourceID: "root",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            sourceKey: "office-japanese",
            hierarchyDepth: 2,
            sourceReference: "https://notion.so/page-1"
        )
        context.insert(source)
        try context.save()

        let repository = LearningRepository(context: context)
        let provider = StaticAIProvider(
            providerID: "fixture",
            modelID: "fixture-1",
            response: Self.fixtureJSON
        )
        let service = AIProcessingService(
            repository: repository,
            provider: provider
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let first = try await service.process(
            sourceDocumentID: source.id,
            now: now
        )
        let second = try await service.process(
            sourceDocumentID: source.id,
            now: now.addingTimeInterval(60)
        )

        XCTAssertEqual(first.extractedItems, 1)
        XCTAssertEqual(
            first.persistence.knowledgeInserted,
            1
        )
        XCTAssertEqual(first.persistence.cardsInserted, 2)

        XCTAssertEqual(
            second.persistence.knowledgeUnchanged,
            1
        )
        XCTAssertEqual(second.persistence.cardsUnchanged, 2)

        let knowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )

        XCTAssertEqual(knowledge.count, 1)
        XCTAssertEqual(cards.count, 2)
        XCTAssertEqual(
            knowledge.first?.sourceDocumentID,
            source.id
        )
        XCTAssertEqual(
            knowledge.first?.sourceKey,
            "office-japanese"
        )
        XCTAssertEqual(
            cards.first?.sourceDocumentID,
            source.id
        )
        XCTAssertTrue(cards.allSatisfy(\.isActive))
    }

    @MainActor
    func testRemovedGeneratedCardBecomesInactiveButHistorySurvives() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let source = SourceDocumentEntity(
            title: "第二课",
            content: "content",
            sourceKind: "notion",
            externalSourceID: "page-1",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            sourceKey: "office-japanese",
            sourceReference: "notion://page-1"
        )
        context.insert(source)
        try context.save()

        let repository = LearningRepository(context: context)
        let firstService = AIProcessingService(
            repository: repository,
            provider: StaticAIProvider(
                providerID: "fixture",
                modelID: "fixture-1",
                response: Self.fixtureJSON
            )
        )
        _ = try await firstService.process(
            sourceDocumentID: source.id
        )

        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        let removedCard = try XCTUnwrap(
            cards.first { $0.generationKey == "card-ja-zh" }
        )

        context.insert(
            ReviewHistoryEntity(
                cardID: removedCard.id,
                reviewedAt: .now,
                ratingRawValue: ReviewRating.good.rawValue,
                elapsedDays: 0,
                scheduledDays: 2,
                stabilityBefore: 0,
                stabilityAfter: 2,
                difficultyBefore: 5,
                difficultyAfter: 4
            )
        )
        try context.save()

        let secondService = AIProcessingService(
            repository: repository,
            provider: StaticAIProvider(
                providerID: "fixture",
                modelID: "fixture-2",
                response: Self.fixtureWithoutSecondCardJSON
            )
        )
        let result = try await secondService.process(
            sourceDocumentID: source.id
        )

        XCTAssertEqual(
            result.persistence.cardsDeactivated,
            1
        )

        let refreshedCards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        XCTAssertEqual(
            refreshedCards.first {
                $0.id == removedCard.id
            }?.isActive,
            false
        )

        let history = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>()
        )
        XCTAssertEqual(history.count, 1)

        let due = try repository.dueSessionCards()
        XCTAssertFalse(
            due.contains { $0.id == removedCard.id }
        )
    }

    private static let fixtureJSON = """
    {
      "version": "v1",
      "items": [
        {
          "key": "susumekata-ni-tsuite",
          "kind": "expression",
          "title": "進（すす）め方（かた）について",
          "canonicalExpression": "進（すす）め方（かた）について",
          "meaning": "关于推进方式",
          "explanation": "商务场景中用于讨论如何推进某项工作。",
          "naturalEnglish": "regarding how to proceed",
          "tags": ["商务", "について"],
          "cards": [
            {
              "key": "card-zh-ja",
              "type": "zh-to-ja",
              "prompt": "“关于推进方式”用日语怎么说？",
              "answer": "進（すす）め方（かた）について",
              "explanation": "用于引出推进方式这一讨论主题。",
              "naturalEnglish": "regarding how to proceed"
            },
            {
              "key": "card-ja-zh",
              "type": "ja-to-zh",
              "prompt": "進（すす）め方（かた）について",
              "answer": "关于推进方式",
              "explanation": "",
              "naturalEnglish": ""
            }
          ]
        }
      ]
    }
    """

    private static let fixtureWithoutSecondCardJSON = """
    {
      "version": "v1",
      "items": [
        {
          "key": "susumekata-ni-tsuite",
          "kind": "expression",
          "title": "進（すす）め方（かた）について",
          "canonicalExpression": "進（すす）め方（かた）について",
          "meaning": "关于推进方式",
          "explanation": "商务场景中用于讨论如何推进某项工作。",
          "naturalEnglish": "regarding how to proceed",
          "tags": ["商务", "について"],
          "cards": [
            {
              "key": "card-zh-ja",
              "type": "zh-to-ja",
              "prompt": "“关于推进方式”用日语怎么说？",
              "answer": "進（すす）め方（かた）について",
              "explanation": "用于引出推进方式这一讨论主题。",
              "naturalEnglish": "regarding how to proceed"
            }
          ]
        }
      ]
    }
    """
}

private struct StaticAIProvider: AICompletionProvider {
    let providerID: String
    let modelID: String
    let response: String

    func complete(
        request: AICompletionRequest
    ) async throws -> AICompletionResponse {
        AICompletionResponse(
            text: response,
            providerID: providerID,
            modelID: modelID
        )
    }
}
