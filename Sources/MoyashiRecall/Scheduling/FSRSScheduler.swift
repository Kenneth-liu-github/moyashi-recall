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

/// Day-level FSRS-6 scheduler.
///
/// This implements the canonical FSRS-6 memory-state equations with the
/// published 21 default parameters. Moyashi Recall intentionally does not yet
/// add sub-day learning steps or interval fuzzing; those are card-state UX
/// policies layered on top of the FSRS core math.
public struct FSRSScheduler: Sendable {
    public static let defaultParameters: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956,
        6.4133, 0.8334, 3.0194, 0.001,
        1.8722, 0.1666, 0.796, 1.4835,
        0.0614, 0.2629, 1.6483, 0.6014,
        1.8729, 0.5425, 0.0912, 0.0658,
        0.1542
    ]

    private static let lowerBounds: [Double] = [
        0.001, 0.001, 0.001, 0.001,
        1.0, 0.001, 0.001, 0.001,
        0.0, 0.0, 0.001, 0.001,
        0.001, 0.001, 0.0, 0.0,
        1.0, 0.0, 0.0, 0.0,
        0.1
    ]

    private static let upperBounds: [Double] = [
        100.0, 100.0, 100.0, 100.0,
        10.0, 4.0, 4.0, 0.75,
        4.5, 0.8, 3.5, 5.0,
        0.25, 0.9, 4.0, 1.0,
        6.0, 2.0, 2.0, 0.8,
        0.8
    ]

    public let parameters: [Double]
    public let desiredRetention: Double
    public let maximumInterval: Int

    private let decay: Double
    private let factor: Double

    public init(
        parameters: [Double] = FSRSScheduler.defaultParameters,
        desiredRetention: Double = 0.90,
        maximumInterval: Int = 36_500
    ) {
        precondition(parameters.count == 21, "FSRS-6 requires exactly 21 parameters.")
        for index in parameters.indices {
            precondition(
                Self.lowerBounds[index]...Self.upperBounds[index] ~= parameters[index],
                "FSRS-6 parameter \(index) is outside the supported bounds."
            )
        }
        self.parameters = parameters
        self.desiredRetention = min(max(desiredRetention, 0.70), 0.97)
        self.maximumInterval = max(1, maximumInterval)
        self.decay = -parameters[20]
        self.factor = pow(0.9, 1.0 / self.decay) - 1.0
    }

    public func schedule(
        _ current: FSRSCardState,
        rating: ReviewRating,
        now: Date = .now
    ) -> FSRSScheduleResult {
        let elapsed = elapsedDays(since: current.lastReview, now: now)
        let isNew = current.state == .new || current.lastReview == nil || current.stability <= 0

        let nextStability: Double
        let nextDifficulty: Double

        if isNew {
            nextStability = initialStability(for: rating)
            nextDifficulty = initialDifficulty(for: rating, clamp: true)
        } else if elapsed < 1 {
            nextStability = shortTermStability(
                stability: current.stability,
                rating: rating
            )
            nextDifficulty = updatedDifficulty(
                current.difficulty,
                rating: rating
            )
        } else {
            let r = retrievability(
                stability: current.stability,
                elapsedDays: elapsed
            )
            nextStability = rating == .again
                ? forgetStability(
                    difficulty: current.difficulty,
                    stability: current.stability,
                    retrievability: r
                )
                : recallStability(
                    difficulty: current.difficulty,
                    stability: current.stability,
                    retrievability: r,
                    rating: rating
                )
            nextDifficulty = updatedDifficulty(
                current.difficulty,
                rating: rating
            )
        }

        let interval = intervalDays(forStability: nextStability)
        let due = now.addingTimeInterval(TimeInterval(interval) * 86_400)

        var nextLapses = current.lapses
        if !isNew && rating == .again {
            nextLapses += 1
        }

        let nextState: ReviewLearningState
        if rating == .again {
            nextState = isNew ? .learning : .relearning
        } else {
            nextState = .review
        }

        let next = FSRSCardState(
            due: due,
            stability: max(nextStability, 0.001),
            difficulty: clampDifficulty(nextDifficulty),
            repetitions: current.repetitions + 1,
            lapses: nextLapses,
            state: nextState,
            lastReview: now
        )

        return FSRSScheduleResult(
            state: next,
            elapsedDays: elapsed,
            scheduledDays: interval
        )
    }

    public func retrievability(stability: Double, elapsedDays: Int) -> Double {
        guard stability > 0 else { return 0 }
        let days = Double(max(0, elapsedDays))
        return pow(1.0 + factor * days / stability, decay)
    }

    public func intervalDays(forStability stability: Double) -> Int {
        let raw = (max(stability, 0.001) / factor)
            * (pow(desiredRetention, 1.0 / decay) - 1.0)
        return min(maximumInterval, max(1, Int(raw.rounded())))
    }

    private func elapsedDays(since lastReview: Date?, now: Date) -> Int {
        guard let lastReview else { return 0 }
        return max(0, Int(floor(now.timeIntervalSince(lastReview) / 86_400)))
    }

    private func initialStability(for rating: ReviewRating) -> Double {
        max(parameters[rating.rawValue - 1], 0.001)
    }

    private func initialDifficulty(for rating: ReviewRating, clamp: Bool) -> Double {
        let value = parameters[4]
            - exp(parameters[5] * Double(rating.rawValue - 1))
            + 1.0
        return clamp ? clampDifficulty(value) : value
    }

    private func updatedDifficulty(
        _ difficulty: Double,
        rating: ReviewRating
    ) -> Double {
        let delta = -parameters[6] * Double(rating.rawValue - 3)
        let damped = difficulty + (10.0 - difficulty) * delta / 9.0
        let easyTarget = initialDifficulty(for: .easy, clamp: false)
        let reverted = parameters[7] * easyTarget
            + (1.0 - parameters[7]) * damped
        return clampDifficulty(reverted)
    }

    private func shortTermStability(
        stability: Double,
        rating: ReviewRating
    ) -> Double {
        var increase = exp(
            parameters[17]
            * (Double(rating.rawValue - 3) + parameters[18])
        ) * pow(stability, -parameters[19])

        if rating != .again {
            increase = max(increase, 1.0)
        }
        return max(0.001, stability * increase)
    }

    private func forgetStability(
        difficulty: Double,
        stability: Double,
        retrievability: Double
    ) -> Double {
        let longTerm = parameters[11]
            * pow(difficulty, -parameters[12])
            * (pow(stability + 1.0, parameters[13]) - 1.0)
            * exp(parameters[14] * (1.0 - retrievability))

        let shortTermCap = stability
            / exp(parameters[17] * parameters[18])

        return max(0.001, min(longTerm, shortTermCap))
    }

    private func recallStability(
        difficulty: Double,
        stability: Double,
        retrievability: Double,
        rating: ReviewRating
    ) -> Double {
        let hardPenalty = rating == .hard ? parameters[15] : 1.0
        let easyBonus = rating == .easy ? parameters[16] : 1.0

        return max(
            0.001,
            stability * (
                1.0
                + exp(parameters[8])
                * (11.0 - difficulty)
                * pow(stability, -parameters[9])
                * (exp(parameters[10] * (1.0 - retrievability)) - 1.0)
                * hardPenalty
                * easyBonus
            )
        )
    }

    private func clampDifficulty(_ value: Double) -> Double {
        min(10.0, max(1.0, value))
    }
}
