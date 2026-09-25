import XCTest
@testable import MoyashiRecall

final class AppReadinessSnapshotTests: XCTestCase {
    func testReadinessDerivedStates() {
        let ready = AppReadinessSnapshot(
            notionCredentialConfigured: true,
            notionRootSelected: true,
            syncedDocumentCount: 3,
            activeSourceDocumentCount: 3,
            aiProviderName: "OpenAI",
            aiModelConfigured: true,
            aiCredentialConfigured: true,
            activeKnowledgeCount: 8,
            activeCardCount: 20,
            dueCardCount: 5,
            reviewHistoryCount: 42,
            latestReviewAt: Date(
                timeIntervalSince1970: 1_700_000_000
            )
        )

        XCTAssertTrue(ready.notionReady)
        XCTAssertTrue(ready.learningSourceReady)
        XCTAssertTrue(ready.aiReady)
        XCTAssertTrue(ready.readyForReview)
        XCTAssertEqual(ready.activeKnowledgeCount, 8)
        XCTAssertEqual(ready.dueCardCount, 5)
        XCTAssertEqual(ready.reviewHistoryCount, 42)
        XCTAssertNotNil(ready.latestReviewAt)

        let notReady = AppReadinessSnapshot(
            notionCredentialConfigured: false,
            notionRootSelected: true,
            syncedDocumentCount: 3,
            activeSourceDocumentCount: 3,
            aiProviderName: "OpenAI",
            aiModelConfigured: true,
            aiCredentialConfigured: false,
            activeCardCount: 0
        )

        XCTAssertFalse(notReady.notionReady)
        XCTAssertTrue(notReady.learningSourceReady)
        XCTAssertFalse(notReady.aiReady)
        XCTAssertFalse(notReady.readyForReview)
    }

    func testNegativeCountsAreClamped() {
        let snapshot = AppReadinessSnapshot(
            notionCredentialConfigured: false,
            notionRootSelected: false,
            syncedDocumentCount: -1,
            activeSourceDocumentCount: -4,
            aiProviderName: "OpenAI",
            aiModelConfigured: false,
            aiCredentialConfigured: false,
            activeKnowledgeCount: -2,
            activeCardCount: -5,
            dueCardCount: -3,
            reviewHistoryCount: -7
        )

        XCTAssertEqual(snapshot.syncedDocumentCount, 0)
        XCTAssertEqual(snapshot.activeSourceDocumentCount, 0)
        XCTAssertFalse(snapshot.learningSourceReady)
        XCTAssertEqual(snapshot.activeKnowledgeCount, 0)
        XCTAssertEqual(snapshot.activeCardCount, 0)
        XCTAssertEqual(snapshot.dueCardCount, 0)
        XCTAssertEqual(snapshot.reviewHistoryCount, 0)
    }
}


extension AppReadinessSnapshotTests {
    func testLocalFilesCanSatisfyLearningSourceReadinessWithoutNotion() {
        let snapshot = AppReadinessSnapshot(
            notionCredentialConfigured: false,
            notionRootSelected: false,
            syncedDocumentCount: 0,
            activeSourceDocumentCount: 2,
            aiProviderName: "OpenAI",
            aiModelConfigured: true,
            aiCredentialConfigured: true,
            activeCardCount: 0
        )

        XCTAssertFalse(snapshot.notionReady)
        XCTAssertTrue(snapshot.learningSourceReady)
        XCTAssertTrue(snapshot.aiReady)
        XCTAssertFalse(snapshot.readyForReview)
    }
}
