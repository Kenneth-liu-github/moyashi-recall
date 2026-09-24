import Foundation
import SwiftData

public enum ReviewRecordingError: Error, Equatable {
    case cardNotFound(UUID)
    case cardInactive(UUID)
}

@MainActor
public struct ReviewRecorder {
    private let scheduler: FSRSScheduler

    public init(scheduler: FSRSScheduler = FSRSScheduler()) {
        self.scheduler = scheduler
    }

    @discardableResult
    public func record(
        cardID: UUID,
        rating: ReviewRating,
        in context: ModelContext,
        now: Date = .now
    ) throws -> FSRSScheduleResult {
        let targetCardID = cardID

        var cardDescriptor = FetchDescriptor<FlashcardEntity>(
            predicate: #Predicate { card in
                card.id == targetCardID
            }
        )
        cardDescriptor.fetchLimit = 1
        guard let card = try context.fetch(cardDescriptor).first else {
            throw ReviewRecordingError.cardNotFound(cardID)
        }
        guard card.isActive else {
            throw ReviewRecordingError.cardInactive(cardID)
        }

        var stateDescriptor = FetchDescriptor<ReviewStateEntity>(
            predicate: #Predicate { state in
                state.cardID == targetCardID
            }
        )
        stateDescriptor.fetchLimit = 1
        let stored = try context.fetch(stateDescriptor).first

        let current = stored.map {
            FSRSCardState(
                due: $0.due,
                stability: $0.stability,
                difficulty: $0.difficulty,
                repetitions: $0.repetitions,
                lapses: $0.lapses,
                state: ReviewLearningState(rawValue: $0.stateRawValue) ?? .new,
                lastReview: $0.lastReview
            )
        } ?? FSRSCardState(due: now)

        let result = scheduler.schedule(current, rating: rating, now: now)

        let state: ReviewStateEntity
        if let stored {
            state = stored
        } else {
            state = ReviewStateEntity(cardID: cardID)
            context.insert(state)
        }

        state.due = result.state.due
        state.stability = result.state.stability
        state.difficulty = result.state.difficulty
        state.elapsedDays = result.elapsedDays
        state.scheduledDays = result.scheduledDays
        state.repetitions = result.state.repetitions
        state.lapses = result.state.lapses
        state.stateRawValue = result.state.state.rawValue
        state.lastReview = result.state.lastReview

        context.insert(
            ReviewHistoryEntity(
                cardID: cardID,
                reviewedAt: now,
                ratingRawValue: rating.rawValue,
                elapsedDays: result.elapsedDays,
                scheduledDays: result.scheduledDays,
                stabilityBefore: current.stability,
                stabilityAfter: result.state.stability,
                difficultyBefore: current.difficulty,
                difficultyAfter: result.state.difficulty
            )
        )

        try context.save()
        return result
    }
}
