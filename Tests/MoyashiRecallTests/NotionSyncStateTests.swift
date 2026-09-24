import XCTest
@testable import MoyashiRecall

final class NotionSyncStateTests: XCTestCase {
    func testSyncStateRoundTripsWithoutPersistingSecrets() throws {
        let suiteName = "NotionSyncStateTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let report = NotionSyncReport(
            totalPages: 12,
            inserted: 3,
            updated: 2,
            unchanged: 7,
            deactivated: 1,
            isComplete: true
        )
        let state = NotionSyncState(
            rootPageID: "root-page",
            lastSyncedAt: Date(
                timeIntervalSince1970: 1_700_000_000
            ),
            report: report
        )

        let store = NotionSyncStateStore()
        try store.save(state, defaults: defaults)

        XCTAssertEqual(
            try store.load(defaults: defaults),
            state
        )

        store.clear(defaults: defaults)
        XCTAssertNil(
            try store.load(defaults: defaults)
        )
    }
}
