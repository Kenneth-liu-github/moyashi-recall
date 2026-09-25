import XCTest
@testable import MoyashiRecall

final class ReviewSessionSummaryStoreTests: XCTestCase {
    func testLatestSessionSummaryRoundTrips() throws {
        let suiteName = "ReviewSessionSummaryStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let summary = ReviewSessionSummary(
            completedAt: Date(
                timeIntervalSince1970: 1_700_000_000
            ),
            reviewedCount: 12,
            againCount: 2,
            hardCount: 3,
            goodCount: 5,
            easyCount: 2
        )

        let store = ReviewSessionSummaryStore()
        try store.save(
            summary,
            defaults: defaults
        )

        XCTAssertEqual(
            store.load(defaults: defaults),
            summary
        )

        store.clear(defaults: defaults)
        XCTAssertNil(
            store.load(defaults: defaults)
        )
    }

    func testSummaryCountsCannotBecomeNegative() {
        let summary = ReviewSessionSummary(
            reviewedCount: -1,
            againCount: -1,
            hardCount: -1,
            goodCount: -1,
            easyCount: -1
        )

        XCTAssertEqual(summary.reviewedCount, 0)
        XCTAssertEqual(summary.againCount, 0)
        XCTAssertEqual(summary.hardCount, 0)
        XCTAssertEqual(summary.goodCount, 0)
        XCTAssertEqual(summary.easyCount, 0)
    }
}
