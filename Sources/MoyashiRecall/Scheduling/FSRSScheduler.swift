import Foundation

public enum ReviewRating: Int, CaseIterable, Codable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

public struct FSRSCardState: Equatable, Sendable {
    public var due: Date
    public var stability: Double
    public var difficulty: Double
    public var repetitions: Int
    public var lapses: Int
    public var state: ReviewLearningState
    public var lastReview: Date?

    public init(
        due: Date = .now,
        stability: Double = 0,
        difficulty: Double = 5,
        repetitions: Int = 0,
        lapses: Int = 0,
        state: ReviewLearningState = .new,
        lastReview: Date? = nil
    ) {
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.repetitions = repetitions
        self.lapses = lapses
        self.state = state
        self.lastReview = lastReview
    }
}

public struct FSRSScheduleResult: Equatable, Sendable {
    public let state: FSRSCardState
    public let elapsedDays: Int
    public let scheduledDays: Int

    public init(state: FSRSCardState, elapsedDays: Int, scheduledDays: Int) {
        self.state = state
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
    }
}

/// V0.2 scheduling engine.
///
/// This keeps the app's persistence/UI contract independent from the scheduling
/// implementation. The parameters are deliberately centralized so we can later
/// replace or calibrate them against a canonical FSRS implementation without
/// migrating stored review history.
public struct FSRSScheduler: Sendable {
    public var desiredRetention: Double

    public init(desiredRetention: Double = 0.90) {
        self.desiredRetention = min(max(desiredRetention, 0.70), 0.97)
    }

    public func schedule(
        _ current: FSRSCardState,
        rating: ReviewRating,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> FSRSScheduleResult {
        let elapsed = max(0, current.lastReview.map { calendar.dateComponents([.day], from: $0, to: now).day ?? 0 } ?? 0)
        let nextDifficulty = adjustedDifficulty(current.difficulty, rating: rating)
        let nextStability: Double
        let nextState: ReviewLearningState
        var lapses = current.lapses

        if current.state == .new {
            nextStability = initialStability(for: rating)
            nextState = rating == .again ? .learning : .review
        } else if rating == .again {
            nextStability = max(0.2, current.stability * 0.35)
            nextState = .relearning
            lapses += 1
        } else {
            let retrievability = self.retrievability(stability: max(current.stability, 0.1), elapsedDays: elapsed)
            let ratingFactor: Double = rating == .hard ? 0.70 : (rating == .easy ? 1.35 : 1.0)
            let difficultyFactor = max(0.35, (11.0 - nextDifficulty) / 6.0)
            let growth = 1.0 + ratingFactor * difficultyFactor * (1.0 - retrievability + 0.12)
            nextStability = max(current.stability + 0.1, current.stability * growth)
            nextState = .review
        }

        let interval = intervalDays(stability: nextStability, rating: rating, state: nextState)
        let due = calendar.date(byAdding: .day, value: interval, to: now) ?? now
        let next = FSRSCardState(
            due: due,
            stability: nextStability,
            difficulty: nextDifficulty,
            repetitions: current.repetitions + 1,
            lapses: lapses,
            state: nextState,
            lastReview: now
        )
        return FSRSScheduleResult(state: next, elapsedDays: elapsed, scheduledDays: interval)
    }

    public func retrievability(stability: Double, elapsedDays: Int) -> Double {
        guard stability > 0 else { return 0 }
        let t = Double(max(0, elapsedDays))
        return pow(1.0 + t / (9.0 * stability), -1.0)
    }

    private func initialStability(for rating: ReviewRating) -> Double {
        switch rating {
        case .again: return 0.25
        case .hard: return 1.2
        case .good: return 3.0
        case .easy: return 7.0
        }
    }

    private func adjustedDifficulty(_ current: Double, rating: ReviewRating) -> Double {
        let delta: Double
        switch rating {
        case .again: delta = 1.0
        case .hard: delta = 0.45
        case .good: delta = -0.15
        case .easy: delta = -0.7
        }
        return min(10, max(1, current + delta))
    }

    private func intervalDays(stability: Double, rating: ReviewRating, state: ReviewLearningState) -> Int {
        if rating == .again || state == .learning || state == .relearning {
            return 1
        }
        let retentionScale = log(desiredRetention) / log(0.90)
        let raw = stability * max(0.55, retentionScale)
        return max(1, Int(raw.rounded()))
    }
}
