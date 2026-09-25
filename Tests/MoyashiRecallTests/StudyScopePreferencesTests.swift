import XCTest
@testable import MoyashiRecall

final class StudyScopePreferencesTests: XCTestCase {
    func testStudyScopePreferencesRoundTrip() throws {
        let suiteName = "StudyScopePreferencesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let preferences = StudyScopePreferences(
            sourceKeys: [
                "office-japanese",
                "japanese-bootcamp"
            ],
            cardTypes: [
                ReviewCardType.zhToJa.rawValue,
                ReviewCardType.application.rawValue
            ],
            reviewCount: 20
        )

        let store = StudyScopePreferencesStore()
        try store.save(
            preferences,
            defaults: defaults
        )

        XCTAssertEqual(
            store.load(defaults: defaults),
            preferences
        )

        store.clear(defaults: defaults)
        XCTAssertNil(
            store.load(defaults: defaults)
        )
    }

    func testStudyScopeReviewCountIsClamped() {
        XCTAssertEqual(
            StudyScopePreferences(
                sourceKeys: [],
                cardTypes: [],
                reviewCount: 0
            ).reviewCount,
            1
        )

        XCTAssertEqual(
            StudyScopePreferences(
                sourceKeys: [],
                cardTypes: [],
                reviewCount: 1_000
            ).reviewCount,
            100
        )
    }
}
