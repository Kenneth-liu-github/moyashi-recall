import Foundation

public struct AICompletionRequest: Equatable, Sendable {
    public let systemPrompt: String
    public let userPrompt: String
    public let responseSchemaName: String

    public init(
        systemPrompt: String,
        userPrompt: String,
        responseSchemaName: String
    ) {
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        self.responseSchemaName = responseSchemaName
    }
}

public struct AICompletionResponse: Equatable, Sendable {
    public let text: String
    public let providerID: String
    public let modelID: String

    public init(
        text: String,
        providerID: String,
        modelID: String
    ) {
        self.text = text
        self.providerID = providerID
        self.modelID = modelID
    }
}

public protocol AICompletionProvider: Sendable {
    var providerID: String { get }
    var modelID: String { get }

    func complete(
        request: AICompletionRequest
    ) async throws -> AICompletionResponse
}

public enum AIProviderError: Error, Equatable {
    case invalidResponse
    case decodingFailed
}
