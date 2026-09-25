import Foundation

public struct SavedStudyPreset: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var sourceKeys: Set<String>
    public var cardTypes: Set<String>
    public var reviewCount: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        sourceKeys: Set<String>,
        cardTypes: Set<String>,
        reviewCount: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        self.sourceKeys = sourceKeys
        self.cardTypes = cardTypes
        self.reviewCount = min(max(reviewCount, 1), 100)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct StudyPresetStore {
    private static let key = "savedStudyPresets"

    public init() {}

    public func load(
        defaults: UserDefaults = .standard
    ) -> [SavedStudyPreset] {
        guard let data = defaults.data(
            forKey: Self.key
        ),
        let presets = try? JSONDecoder().decode(
            [SavedStudyPreset].self,
            from: data
        )
        else {
            return []
        }

        return presets.sorted {
            if $0.updatedAt == $1.updatedAt {
                return $0.name.localizedCompare(
                    $1.name
                ) == .orderedAscending
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    @discardableResult
    public func save(
        name: String,
        sourceKeys: Set<String>,
        cardTypes: Set<String>,
        reviewCount: Int,
        now: Date = .now,
        defaults: UserDefaults = .standard
    ) throws -> SavedStudyPreset {
        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {
            throw StudyPresetStoreError.emptyName
        }

        var presets = load(defaults: defaults)

        if let index = presets.firstIndex(
            where: {
                $0.name.compare(
                    trimmedName,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) == .orderedSame
            }
        ) {
            let existing = presets[index]
            presets[index] = SavedStudyPreset(
                id: existing.id,
                name: trimmedName,
                sourceKeys: sourceKeys,
                cardTypes: cardTypes,
                reviewCount: reviewCount,
                createdAt: existing.createdAt,
                updatedAt: now
            )
        } else {
            presets.append(
                SavedStudyPreset(
                    name: trimmedName,
                    sourceKeys: sourceKeys,
                    cardTypes: cardTypes,
                    reviewCount: reviewCount,
                    createdAt: now,
                    updatedAt: now
                )
            )
        }

        try persist(
            presets,
            defaults: defaults
        )

        return presets.first {
            $0.name.compare(
                trimmedName,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }!
    }

    public func delete(
        id: UUID,
        defaults: UserDefaults = .standard
    ) throws {
        let presets = load(defaults: defaults)
            .filter { $0.id != id }
        try persist(
            presets,
            defaults: defaults
        )
    }

    public func clear(
        defaults: UserDefaults = .standard
    ) {
        defaults.removeObject(
            forKey: Self.key
        )
    }

    private func persist(
        _ presets: [SavedStudyPreset],
        defaults: UserDefaults
    ) throws {
        let data = try JSONEncoder().encode(
            presets
        )
        defaults.set(
            data,
            forKey: Self.key
        )
    }
}

public enum StudyPresetStoreError: Error, Equatable {
    case emptyName
}
