import Foundation

public struct StudyScopePreferences: Codable, Equatable, Sendable {
    public let sourceKeys: Set<String>
    public let cardTypes: Set<String>
    public let reviewCount: Int

    public init(
        sourceKeys: Set<String>,
        cardTypes: Set<String>,
        reviewCount: Int
    ) {
        self.sourceKeys = sourceKeys
        self.cardTypes = cardTypes
        self.reviewCount = min(max(reviewCount, 1), 100)
    }
}

public struct StudyScopePreferencesStore {
    private static let key = "studyScopePreferences"

    public init() {}

    public func load(
        defaults: UserDefaults = .standard
    ) -> StudyScopePreferences? {
        guard let data = defaults.data(
            forKey: Self.key
        ) else {
            return nil
        }

        return try? JSONDecoder().decode(
            StudyScopePreferences.self,
            from: data
        )
    }

    public func save(
        _ preferences: StudyScopePreferences,
        defaults: UserDefaults = .standard
    ) throws {
        let data = try JSONEncoder().encode(
            preferences
        )
        defaults.set(data, forKey: Self.key)
    }

    public func clear(
        defaults: UserDefaults = .standard
    ) {
        defaults.removeObject(
            forKey: Self.key
        )
    }
}
