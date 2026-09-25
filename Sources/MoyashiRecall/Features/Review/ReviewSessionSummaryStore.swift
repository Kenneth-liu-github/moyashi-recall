import Foundation

public struct ReviewSessionSummary: Codable, Equatable, Sendable {
    public let completedAt: Date
    public let reviewedCount: Int
    public let againCount: Int
    public let hardCount: Int
    public let goodCount: Int
    public let easyCount: Int

    public init(
        completedAt: Date = .now,
        reviewedCount: Int,
        againCount: Int,
        hardCount: Int,
        goodCount: Int,
        easyCount: Int
    ) {
        self.completedAt = completedAt
        self.reviewedCount = max(0, reviewedCount)
        self.againCount = max(0, againCount)
        self.hardCount = max(0, hardCount)
        self.goodCount = max(0, goodCount)
        self.easyCount = max(0, easyCount)
    }
}

public struct ReviewSessionSummaryStore {
    private static let key = "latestReviewSessionSummary"

    public init() {}

    public func load(
        defaults: UserDefaults = .standard
    ) -> ReviewSessionSummary? {
        guard let data = defaults.data(
            forKey: Self.key
        ) else {
            return nil
        }

        return try? JSONDecoder().decode(
            ReviewSessionSummary.self,
            from: data
        )
    }

    public func save(
        _ summary: ReviewSessionSummary,
        defaults: UserDefaults = .standard
    ) throws {
        let data = try JSONEncoder().encode(
            summary
        )
        defaults.set(
            data,
            forKey: Self.key
        )
    }

    public func clear(
        defaults: UserDefaults = .standard
    ) {
        defaults.removeObject(
            forKey: Self.key
        )
    }
}
