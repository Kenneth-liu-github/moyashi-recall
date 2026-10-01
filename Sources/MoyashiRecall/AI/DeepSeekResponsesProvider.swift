import Foundation

public struct DeepSeekResponsesProvider: AICompletionProvider {
    public let providerID = "deepseek"
    public let modelID: String

    private let provider: OpenAIResponsesProvider

    public init(
        apiKey: String,
        modelID: String,
        transport: any HTTPTransport = URLSessionHTTPTransport(),
        baseURL: URL = URL(string: "https://api.deepseek.com")!
    ) {
        self.modelID = modelID
        self.provider = OpenAIResponsesProvider(
            apiKey: apiKey,
            modelID: modelID,
            transport: transport,
            baseURL: baseURL,
            reasoningEffort: "none",
            maxOutputTokens: 12_000
        )
    }

    public func complete(
        request: AICompletionRequest
    ) async throws -> AICompletionResponse {
        let response = try await provider.complete(
            request: request
        )

        return AICompletionResponse(
            text: response.text,
            providerID: providerID,
            modelID: response.modelID
        )
    }
}
