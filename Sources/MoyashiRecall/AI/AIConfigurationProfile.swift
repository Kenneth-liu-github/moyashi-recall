import Foundation

public struct AIConfigurationProfile:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    public let id: UUID
    public var name: String
    public var provider: AIProviderKind
    public var modelID: String
    public let credentialAccount: String

    public init(
        id: UUID = UUID(),
        name: String,
        provider: AIProviderKind,
        modelID: String,
        credentialAccount: String? = nil
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.modelID = modelID
        self.credentialAccount =
            credentialAccount ?? "ai-profile-\(id.uuidString)"
    }
}
