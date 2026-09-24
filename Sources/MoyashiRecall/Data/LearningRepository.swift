import Foundation
import SwiftData

public struct ReviewSessionCard: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let cardType: String
    public let prompt: String
    public let answer: String
    public let explanation: String
    public let naturalEnglish: String
    public let sourceKey: String
    public let sourceReference: String

    public init(entity: FlashcardEntity) {
        self.id = entity.id
        self.cardType = entity.cardType
        self.prompt = entity.prompt
        self.answer = entity.answer
        self.explanation = entity.explanation
        self.naturalEnglish = entity.naturalEnglish
        self.sourceKey = entity.sourceKey
        self.sourceReference = entity.sourceReference
    }
}

public struct HomeSnapshot: Equatable, Sendable {
    public let dueCount: Int
    public let streakDays: Int

    public init(dueCount: Int, streakDays: Int) {
        self.dueCount = dueCount
        self.streakDays = streakDays
    }
}

@MainActor
public struct LearningRepository {
    private let context: ModelContext
    private let queueService: ReviewQueueService
    private let recorder: ReviewRecorder

    public init(
        context: ModelContext,
        scheduler: FSRSScheduler = FSRSScheduler()
    ) {
        self.context = context
        self.queueService = ReviewQueueService()
        self.recorder = ReviewRecorder(scheduler: scheduler)
    }

    public func seedDemoIfNeeded() throws {
        #if DEBUG
        try DemoDataSeeder.seedIfNeeded(in: context)
        #endif
    }

    public func dueSessionCards(
        now: Date = .now,
        sourceKeys: Set<String>? = nil,
        limit: Int? = nil
    ) throws -> [ReviewSessionCard] {
        try queueService
            .dueCards(
                in: context,
                now: now,
                sourceKeys: sourceKeys,
                limit: limit
            )
            .map(ReviewSessionCard.init)
    }

    public func allSessionCards(
        searchText: String = ""
    ) throws -> [ReviewSessionCard] {
        let entities = try context.fetch(
            FetchDescriptor<FlashcardEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        )
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [FlashcardEntity]
        if normalized.isEmpty {
            filtered = entities
        } else {
            filtered = entities.filter {
                $0.prompt.localizedCaseInsensitiveContains(normalized)
                    || $0.answer.localizedCaseInsensitiveContains(normalized)
                    || $0.explanation.localizedCaseInsensitiveContains(normalized)
                    || $0.sourceReference.localizedCaseInsensitiveContains(normalized)
            }
        }
        return filtered.map(ReviewSessionCard.init)
    }

    public func cardCountsBySourceKey() throws -> [String: Int] {
        let cards = try context.fetch(FetchDescriptor<FlashcardEntity>())
        return cards.reduce(into: [String: Int]()) { result, card in
            result[card.sourceKey, default: 0] += 1
        }
    }

    @discardableResult
    public func recordReview(
        cardID: UUID,
        rating: ReviewRating,
        now: Date = .now
    ) throws -> FSRSScheduleResult {
        try recorder.record(
            cardID: cardID,
            rating: rating,
            in: context,
            now: now
        )
    }

    public func homeSnapshot(now: Date = .now) throws -> HomeSnapshot {
        let cards = try context.fetch(FetchDescriptor<FlashcardEntity>())
        let states = try context.fetch(FetchDescriptor<ReviewStateEntity>())
        let history = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>(
                sortBy: [SortDescriptor(\.reviewedAt, order: .reverse)]
            )
        )

        let stateByCard = states.reduce(into: [UUID: ReviewStateEntity]()) { result, state in
            if let existing = result[state.cardID] {
                if state.due < existing.due { result[state.cardID] = state }
            } else {
                result[state.cardID] = state
            }
        }

        let dueCount = cards.reduce(0) { count, card in
            guard let state = stateByCard[card.id] else { return count + 1 }
            return count + (state.due <= now ? 1 : 0)
        }

        let calendar = Calendar.current
        let reviewDays = Set(history.map { calendar.startOfDay(for: $0.reviewedAt) })
        var streak = 0

        if !reviewDays.isEmpty {
            var cursor = calendar.startOfDay(for: now)
            if !reviewDays.contains(cursor) {
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            }

            while reviewDays.contains(cursor) {
                streak += 1
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            }
        }

        return HomeSnapshot(dueCount: dueCount, streakDays: streak)
    }
}
