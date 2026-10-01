import Foundation

public struct AIConfigurationProfileStore {
    private let defaults: UserDefaults

    private let profilesKey =
        "ai.configuration.profiles"

    private let activeProfileIDKey =
        "ai.configuration.active-profile-id"

    public init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
    }

    public func profiles() -> [AIConfigurationProfile] {
        guard
            let data = defaults.data(
                forKey: profilesKey
            ),
            let profiles = try? JSONDecoder().decode(
                [AIConfigurationProfile].self,
                from: data
            )
        else {
            return []
        }

        return profiles
    }

    public func save(
        _ profile: AIConfigurationProfile
    ) throws {
        var current = profiles()

        if let index = current.firstIndex(
            where: { $0.id == profile.id }
        ) {
            current[index] = profile
        } else {
            current.append(profile)
        }

        let data = try JSONEncoder().encode(current)
        defaults.set(
            data,
            forKey: profilesKey
        )
    }

    public func delete(
        id: UUID
    ) throws {
        let remaining = profiles().filter {
            $0.id != id
        }

        let data = try JSONEncoder().encode(remaining)
        defaults.set(
            data,
            forKey: profilesKey
        )

        if activeProfileID() == id {
            defaults.removeObject(
                forKey: activeProfileIDKey
            )
        }
    }

    public func activeProfileID() -> UUID? {
        guard
            let value = defaults.string(
                forKey: activeProfileIDKey
            )
        else {
            return nil
        }

        return UUID(uuidString: value)
    }

    public func activeProfile()
        -> AIConfigurationProfile?
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
        if let id {
            defaults.set(
                id.uuidString,
                forKey: activeProfileIDKey
            )
        } else {
            defaults.removeObject(
                forKey: activeProfileIDKey
            )
        }
    }
}
