import XCTest
@testable import MoyashiRecall

final class AppReadinessSnapshotTests: XCTestCase {
    func testReadinessDerivedStates() {
        let ready = AppReadinessSnapshot(
            notionCredentialConfigured: true,
            notionRootSelected: true,
            syncedDocumentCount: 3,
            aiProviderName: "OpenAI",
            aiModelConfigured: true,
            aiCredentialConfigured: true,
            activeCardCount: 20
        )

        XCTAssertTrue(ready.notionReady)
        XCTAssertTrue(ready.aiReady)
        XCTAssertTrue(ready.readyForReview)

        let notReady = AppReadinessSnapshot(
            notionCredentialConfigured: false,
            notionRootSelected: true,
            syncedDocumentCount: 3,
            aiProviderName: "OpenAI",
            aiModelConfigured: true,
            aiCredentialConfigured: false,
            activeCardCount: 0
        )

        XCTAssertFalse(notReady.notionReady)
        XCTAssertFalse(notReady.aiReady)
        XCTAssertFalse(notReady.readyForReview)
    }

    func testNegativeCountsAreClamped() {
        let snapshot = AppReadinessSnapshot(
            notionCredentialConfigured: false,
            notionRootSelected: false,
            syncedDocumentCount: -1,
            aiProviderName: "OpenAI",
            aiModelConfigured: false,
            aiCredentialConfigured: false,
            activeCardCount: -5
        )

        XCTAssertEqual(snapshot.syncedDocumentCount, 0)
        XCTAssertEqual(snapshot.activeCardCount, 0)
    }
}
