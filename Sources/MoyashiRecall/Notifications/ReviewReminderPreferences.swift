import Foundation

public struct ReviewReminderPreferences: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var hour: Int
    public var minute: Int

    public init(
        enabled: Bool = false,
        hour: Int = 20,
        minute: Int = 0
    ) {
        self.enabled = enabled
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }
}

public struct ReviewReminderPreferencesStore {
    private static let key = "reviewReminderPreferences"

    public init() {}

    public func load(
        defaults: UserDefaults = .standard
    ) -> ReviewReminderPreferences {
        guard
            let data = defaults.data(
                forKey: Self.key
            ),
            let value = try? JSONDecoder().decode(
                ReviewReminderPreferences.self,
                from: data
            )
        else {
            return ReviewReminderPreferences()
        }

        return value
    }

    public func save(
        _ preferences: ReviewReminderPreferences,
        defaults: UserDefaults = .standard
    ) throws {
        let data = try JSONEncoder().encode(
            preferences
        )
        defaults.set(
            data,
            forKey: Self.key
        )
    }
}
