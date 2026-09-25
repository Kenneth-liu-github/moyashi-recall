import XCTest
@testable import MoyashiRecall

final class JapaneseSpeechPreferencesTests: XCTestCase {
    func testSpeechPreferencesRoundTrip() throws {
        let suiteName = "JapaneseSpeechPreferencesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let preferences = JapaneseSpeechPreferences(
            rate: .fast,
            autoPlayAnswer: true
        )
        let store = JapaneseSpeechPreferencesStore()
        try store.save(
            preferences,
            defaults: defaults
        )

        XCTAssertEqual(
            store.load(defaults: defaults),
            preferences
        )
    }

    func testSpeechRateMultipliersAreOrdered() {
        XCTAssertLessThan(
            JapaneseSpeechRate.slow.multiplier,
            JapaneseSpeechRate.normal.multiplier
        )
        XCTAssertLessThan(
            JapaneseSpeechRate.normal.multiplier,
            JapaneseSpeechRate.fast.multiplier
        )
    }
}
