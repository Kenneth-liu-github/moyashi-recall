import XCTest
@testable import MoyashiRecall

final class ReviewReminderPreferencesTests: XCTestCase {
    func testReminderPreferencesRoundTrip() throws {
        let suiteName = "ReviewReminderPreferencesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let preferences = ReviewReminderPreferences(
            enabled: true,
            hour: 7,
            minute: 45
        )
        let store = ReviewReminderPreferencesStore()
        try store.save(
            preferences,
            defaults: defaults
        )

        XCTAssertEqual(
            store.load(defaults: defaults),
            preferences
        )
    }

    func testReminderTimeIsClamped() {
        let preferences = ReviewReminderPreferences(
            enabled: true,
            hour: 99,
            minute: -20
        )

        XCTAssertEqual(preferences.hour, 23)
        XCTAssertEqual(preferences.minute, 0)
    }
}
