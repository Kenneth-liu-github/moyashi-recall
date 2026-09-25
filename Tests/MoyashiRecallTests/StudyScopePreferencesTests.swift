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
    func testLegacyPreferencesWithoutDocumentIDsStillDecode() throws {
        struct LegacyPreferences: Codable {
            let sourceKeys: Set<String>
            let cardTypes: Set<String>
            let reviewCount: Int
        }

        let suiteName = "StudyScopePreferencesLegacy.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let legacy = LegacyPreferences(
            sourceKeys: ["office-japanese"],
            cardTypes: [
                ReviewCardType.zhToJa.rawValue
            ],
            reviewCount: 20
        )
        let data = try JSONEncoder().encode(legacy)
        defaults.set(
            data,
            forKey: "studyScopePreferences"
        )

        let loaded = try XCTUnwrap(
            StudyScopePreferencesStore().load(
                defaults: defaults
            )
        )

        XCTAssertEqual(
            loaded.sourceKeys,
            ["office-japanese"]
        )
        XCTAssertNil(loaded.documentIDs)
        XCTAssertEqual(loaded.reviewCount, 20)
    }


}
