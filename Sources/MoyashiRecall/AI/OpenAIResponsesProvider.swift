import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenAIResponsesProvider: AICompletionProvider {
    public let providerID = "openai"
    public let modelID: String

    private let apiKey: String
    private let transport: any HTTPTransport
    private let baseURL: URL

    public init(
        apiKey: String,
        modelID: String,
        transport: any HTTPTransport = URLSessionHTTPTransport(),
        baseURL: URL = URL(string: "https://api.openai.com")!
    ) {
        self.apiKey = apiKey
        self.modelID = modelID
        self.transport = transport
        self.baseURL = baseURL
    }

    public func complete(
        request: AICompletionRequest
    ) async throws -> AICompletionResponse {
        let trimmedKey = apiKey.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedKey.isEmpty else {
            throw AIProviderError.missingConfiguration(
                "OpenAI API key"
            )
        }

        let trimmedModel = modelID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedModel.isEmpty else {
            throw AIProviderError.missingConfiguration(
                "OpenAI model ID"
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
            "store": false,
            "input": [
                [
                    "role": "system",
                    "content": request.systemPrompt
                ],
                [
                    "role": "user",
                    "content": request.userPrompt
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": request.responseSchemaName,
                    "strict": true,
                    "schema": schema
                ]
            ]
        ]

        let url = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("responses")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(
            "Bearer \(trimmedKey)",
            forHTTPHeaderField: "Authorization"
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

        if json["status"] as? String == "incomplete" {
            let details = json["incomplete_details"]
                as? [String: Any]
            let reason = details?["reason"] as? String
                ?? "unknown"
            return .incomplete(reason)
        }

        guard let output = json["output"]
                as? [[String: Any]]
        else {
            return nil
        }

        for item in output {
            guard
                item["type"] as? String == "message",
                let content = item["content"]
                    as? [[String: Any]]
            else {
                continue
            }

            for part in content
            where part["type"] as? String == "refusal" {
                let message = part["refusal"] as? String
                    ?? "Request refused"
                return .refused(message)
            }
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
            let json = object as? [String: Any]
        else {
            return nil
        }

        if let outputText = json["output_text"] as? String,
           !outputText.isEmpty {
            return outputText
        }

        guard let output = json["output"] as? [[String: Any]]
        else {
            return nil
        }

        var fragments: [String] = []
        for item in output {
            guard
                item["type"] as? String == "message",
                let content = item["content"] as? [[String: Any]]
            else {
                continue
            }

            for part in content where
                part["type"] as? String == "output_text"
            {
                if let text = part["text"] as? String {
                    fragments.append(text)
                }
            }
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
            return "Unknown OpenAI API error"
        }

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }

        if let message = json["message"] as? String {
            return message
        }

        return "Unknown OpenAI API error"
    }
}
