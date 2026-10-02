import Foundation

public struct NotionConfigurationProfileStore {
    private static let profilesKey =
        "notion.configuration.profiles"

    private static let activeProfileIDKey =
        "notion.configuration.active-profile-id"

    private let defaults: UserDefaults

    public init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
    }

    public func profiles() -> [NotionConfigurationProfile] {
        guard
            let data = defaults.data(
                forKey: Self.profilesKey
            ),
            let profiles = try? JSONDecoder().decode(
                [NotionConfigurationProfile].self,
                from: data
            )
        else {
            return []
        }

        return profiles
    }

    public func save(
        _ profile: NotionConfigurationProfile
    ) throws {
        var values = profiles()

        if let index = values.firstIndex(
            where: { $0.id == profile.id }
        ) {
            values[index] = profile
        } else {
            values.append(profile)
        }

        let data = try JSONEncoder().encode(values)
        defaults.set(
            data,
            forKey: Self.profilesKey
        )
    }

    public func delete(
        id: UUID
    ) throws {
        let values = profiles().filter {
            $0.id != id
        }

        let data = try JSONEncoder().encode(values)
        defaults.set(
            data,
            forKey: Self.profilesKey
        )

        if activeProfileID() == id {
            defaults.removeObject(
                forKey: Self.activeProfileIDKey
            )
        }
    }

    public func activeProfileID() -> UUID? {
        guard
            let raw = defaults.string(
                forKey: Self.activeProfileIDKey
            )
        else {
            return nil
        }

        return UUID(uuidString: raw)
    }

    public func activeProfile()
        -> NotionConfigurationProfile?
    {
        guard let id = activeProfileID() else {
            return nil
        }

        return profiles().first {
            $0.id == id
        }
    }

    public func setActiveProfile(
        id: UUID?
    ) {
        guard let id else {
            defaults.removeObject(
                forKey: Self.activeProfileIDKey
            )
            return
        }

        guard profiles().contains(
            where: { $0.id == id }
        ) else {
            return
        }

        defaults.set(
            id.uuidString,
            forKey: Self.activeProfileIDKey
        )
    }
}
