import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct AnthropicMessagesProvider: AICompletionProvider {
    public static let apiVersion = "2023-06-01"

    public let providerID = "anthropic"
    public let modelID: String

    private let apiKey: String
    private let transport: any HTTPTransport
    private let baseURL: URL
    private let maxTokens: Int

    public init(
        apiKey: String,
        modelID: String,
        transport: any HTTPTransport = URLSessionHTTPTransport(),
        baseURL: URL = URL(string: "https://api.anthropic.com")!,
        maxTokens: Int = 8_192
    ) {
        self.apiKey = apiKey
        self.modelID = modelID
        self.transport = transport
        self.baseURL = baseURL
        self.maxTokens = max(1_024, maxTokens)
    }

    public func complete(
        request: AICompletionRequest
    ) async throws -> AICompletionResponse {
        let trimmedKey = apiKey.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedKey.isEmpty else {
            throw AIProviderError.missingConfiguration(
                "Anthropic API key"
            )
        }

        let trimmedModel = modelID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedModel.isEmpty else {
            throw AIProviderError.missingConfiguration(
                "Anthropic model ID"
            )
        }

        guard
            let schemaData = request.responseSchemaJSON.data(
                using: .utf8
            ),
            let schema = try? JSONSerialization.jsonObject(
                with: schemaData
            )
        else {
            throw AIProviderError.invalidResponse
        }

        let body: [String: Any] = [
            "model": trimmedModel,
            "max_tokens": maxTokens,
            "system": request.systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": request.userPrompt
                ]
            ],
            "output_config": [
                "format": [
                    "type": "json_schema",
                    "schema": schema
                ]
            ]
        ]

        let url = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("messages")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(
            trimmedKey,
            forHTTPHeaderField: "x-api-key"
        )
        urlRequest.setValue(
            Self.apiVersion,
            forHTTPHeaderField: "anthropic-version"
        )
        urlRequest.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        urlRequest.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )

        let maxRateLimitRetries = 2

        for attempt in 0...maxRateLimitRetries {
            let (data, response) = try await transport.data(
                for: urlRequest
            )

            guard let http = response as? HTTPURLResponse else {
                throw AIProviderError.invalidResponse
            }

            if (200..<300).contains(http.statusCode) {
                if let issue = Self.responseIssue(from: data) {
                    throw issue
                }

                guard let text = Self.outputText(from: data),
                      !text.isEmpty
                else {
                    throw AIProviderError.invalidResponse
                }

                return AICompletionResponse(
                    text: text,
                    providerID: providerID,
                    modelID: trimmedModel
                )
            }

            if http.statusCode == 429,
               attempt < maxRateLimitRetries {
                let delay = Self.retryAfterSeconds(
                    from: http
                )
                let nanoseconds = UInt64(
                    max(0, min(delay, 60))
                        * 1_000_000_000
                )
                try await Task.sleep(
                    nanoseconds: nanoseconds
                )
                continue
            }

            throw AIProviderError.http(
                statusCode: http.statusCode,
                message: Self.errorMessage(from: data)
            )
        }

        throw AIProviderError.invalidResponse
    }

    private static func responseIssue(
        from data: Data
    ) -> AIProviderError? {
        guard
            let object = try? JSONSerialization.jsonObject(
                with: data
            ),
            let json = object as? [String: Any]
        else {
            return nil
        }

        let stopReason = json["stop_reason"] as? String

        if stopReason == "max_tokens"
            || stopReason == "model_context_window_exceeded"
            || stopReason == "pause_turn" {
            return .incomplete(
                stopReason ?? "incomplete"
            )
        }

        if stopReason == "refusal" {
            let details = json["stop_details"]
                as? [String: Any]
            let explanation = details?["explanation"]
                as? String
                ?? details?["category"] as? String
                ?? "Request refused"
            return .refused(explanation)
        }

        return nil
    }

    private static func outputText(
        from data: Data
    ) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(
                with: data
            ),
            let json = object as? [String: Any],
            let content = json["content"] as? [[String: Any]]
        else {
            return nil
        }

        let fragments = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else {
                return nil
            }
            return block["text"] as? String
        }

        return fragments.isEmpty
            ? nil
            : fragments.joined()
    }

    private static func retryAfterSeconds(
        from response: HTTPURLResponse
    ) -> Double {
        guard
            let raw = response.value(
                forHTTPHeaderField: "Retry-After"
            ),
            let seconds = Double(raw)
        else {
            return 1
        }

        return seconds
    }

    private static func errorMessage(
        from data: Data
    ) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(
                with: data
            ),
            let json = object as? [String: Any]
        else {
            return "Unknown Anthropic API error"
        }

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }

        if let message = json["message"] as? String {
            return message
        }

        return "Unknown Anthropic API error"
    }
}
