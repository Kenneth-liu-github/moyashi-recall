import Foundation

public struct NotionSelectedSource:
    Codable,
    Equatable,
    Hashable,
    Identifiable,
    Sendable
{
    public let id: String
    public var title: String

    public init(
        id: String,
        title: String
    ) {
        self.id = id
        self.title = title
    }
}

public struct NotionConfigurationProfile:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    public let id: UUID
    public var name: String
    public var rootPageID: String
    public var rootPageTitle: String
    public var selectedSources: [NotionSelectedSource]
    public let credentialAccount: String

    public init(
        id: UUID = UUID(),
        name: String,
        rootPageID: String,
        rootPageTitle: String = "",
        selectedSources: [NotionSelectedSource] = [],
        credentialAccount: String? = nil
    ) {
        self.id = id
        self.name = name
        self.rootPageID = rootPageID
        self.rootPageTitle = rootPageTitle
        self.selectedSources = selectedSources
        self.credentialAccount =
            credentialAccount ?? "notion-profile-\(id.uuidString)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case rootPageID
        case rootPageTitle
        case selectedSources
        case credentialAccount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(
            UUID.self,
            forKey: .id
        )
        name = try container.decode(
            String.self,
            forKey: .name
        )
        rootPageID = try container.decode(
            String.self,
            forKey: .rootPageID
        )
        rootPageTitle = try container.decodeIfPresent(
            String.self,
            forKey: .rootPageTitle
        ) ?? ""
        selectedSources = try container.decodeIfPresent(
            [NotionSelectedSource].self,
            forKey: .selectedSources
        ) ?? []
        credentialAccount = try container.decode(
            String.self,
            forKey: .credentialAccount
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(
            rootPageID,
            forKey: .rootPageID
        )
        try container.encode(
            rootPageTitle,
            forKey: .rootPageTitle
        )
        try container.encode(
            selectedSources,
            forKey: .selectedSources
        )
        try container.encode(
            credentialAccount,
            forKey: .credentialAccount
        )
    }
}
