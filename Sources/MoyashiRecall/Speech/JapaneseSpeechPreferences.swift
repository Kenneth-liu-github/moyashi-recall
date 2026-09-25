import Foundation

public enum JapaneseSpeechRate: String, CaseIterable, Codable, Identifiable, Sendable {
    case slow
    case normal
    case fast

    public var id: String { rawValue }

    public var multiplier: Double {
        switch self {
        case .slow:
            return 0.82
        case .normal:
            return 1.0
        case .fast:
            return 1.16
        }
    }
}

public struct JapaneseSpeechPreferences: Codable, Equatable, Sendable {
    public var rate: JapaneseSpeechRate
    public var autoPlayAnswer: Bool

    public init(
        rate: JapaneseSpeechRate = .normal,
        autoPlayAnswer: Bool = false
    ) {
        self.rate = rate
        self.autoPlayAnswer = autoPlayAnswer
    }
}

public struct JapaneseSpeechPreferencesStore {
    private static let key = "japaneseSpeechPreferences"

    public init() {}

    public func load(
        defaults: UserDefaults = .standard
    ) -> JapaneseSpeechPreferences {
        guard
            let data = defaults.data(
                forKey: Self.key
            ),
            let value = try? JSONDecoder().decode(
                JapaneseSpeechPreferences.self,
                from: data
            )
        else {
            return JapaneseSpeechPreferences()
        }

        return value
    }

    public func save(
        _ preferences: JapaneseSpeechPreferences,
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
