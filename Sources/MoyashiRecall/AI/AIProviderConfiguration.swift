import Foundation

public enum AIProviderKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case openAI = "openai"
    case anthropic

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        }
    }
}

public struct AIProviderConfiguration: Codable, Equatable, Sendable {
    public let provider: AIProviderKind
    public let modelID: String

    public init(
        provider: AIProviderKind,
        modelID: String
    ) {
        self.provider = provider
        self.modelID = modelID
    }
}

public struct AIConfigurationStore {
    private static let key = "aiProviderConfiguration"

    public init() {}

    public func load(
        defaults: UserDefaults = .standard
    ) -> AIProviderConfiguration {
        guard
            let data = defaults.data(forKey: Self.key),
            let value = try? JSONDecoder().decode(
                AIProviderConfiguration.self,
                from: data
            )
        else {
            return AIProviderConfiguration(
                provider: .openAI,
                modelID: ""
            )
        }

        return value
    }

    public func save(
        _ configuration: AIProviderConfiguration,
        defaults: UserDefaults = .standard
    ) throws {
        let data = try JSONEncoder().encode(configuration)
        defaults.set(data, forKey: Self.key)
    }
}

public enum AICredential {
    public static func account(
        for provider: AIProviderKind
    ) -> String {
        switch provider {
        case .openAI:
            return "ai-openai-api-key"
        case .anthropic:
            return "ai-anthropic-api-key"
        }
    }
}

public enum AIProviderFactory {
    public static func makeConfiguredProvider(
        configurationStore: AIConfigurationStore = AIConfigurationStore(),
        credentialStore: KeychainCredentialStore = KeychainCredentialStore()
    ) throws -> any AICompletionProvider {
        let configuration = configurationStore.load()

        let modelID = configuration.modelID
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        guard !modelID.isEmpty else {
            throw AIProviderError.missingConfiguration(
                "AI model ID"
            )
        }

        let account = AICredential.account(
            for: configuration.provider
        )
        guard
            let secret = try credentialStore.read(
                account: account
            ),
            !secret.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        else {
            throw AIProviderError.missingConfiguration(
                "\(configuration.provider.displayName) API key"
            )
        }

        switch configuration.provider {
        case .openAI:
            return OpenAIResponsesProvider(
                apiKey: secret,
                modelID: modelID
            )
        case .anthropic:
            return AnthropicMessagesProvider(
                apiKey: secret,
                modelID: modelID
            )
        }
    }
}
