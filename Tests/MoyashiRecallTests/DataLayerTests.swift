import XCTest
import SwiftData
@testable import MoyashiRecall

final class DataLayerTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: KnowledgeItemEntity.self,
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
