import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct KimiChatCompletionsProvider:
    AICompletionProvider {

    public let providerID = "kimi"
    public let modelID: String

    private let apiKey: String
    private let transport: any HTTPTransport
    private let baseURL: URL

    public init(
        apiKey: String,
        modelID: String,
        transport:
            any HTTPTransport =
                URLSessionHTTPTransport(),
        baseURL: URL = URL(
            string:
                "https://api.moonshot.cn"
        )!
    ) {
        self.apiKey = apiKey
        self.modelID = modelID
        self.transport = transport
        self.baseURL = baseURL
    }

    public func complete(
        request: AICompletionRequest
    ) async throws
        -> AICompletionResponse {

        let trimmedKey =
            apiKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedKey.isEmpty else {
            throw AIProviderError
                .missingConfiguration(
                    "Kimi API key"
                )
        }

        let trimmedModel =
            modelID.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedModel.isEmpty else {
            throw AIProviderError
                .missingConfiguration(
                    "Kimi model ID"
                )
        }

        let body: [String: Any] = [
            "model": trimmedModel,

            "messages": [
                [
                    "role": "system",
                    "content":
                        request.systemPrompt
                        + """



                        Return exactly one valid JSON object.
                        Do not use Markdown code fences.
                        Do not add commentary outside JSON.
                        """
                ],
                [
                    "role": "user",
                    "content":
                        request.userPrompt
                ]
            ],

            "thinking": [
                "type": "disabled"
            ],

            "response_format": [
                "type": "json_object"
            ],

            "temperature": 0.6,

            "max_completion_tokens":
                12_000
        ]

        let url =
            baseURL
                .appendingPathComponent("v1")
                .appendingPathComponent("chat")
                .appendingPathComponent(
                    "completions"
                )

        var urlRequest =
            URLRequest(url: url)

        urlRequest.timeoutInterval = 180
        urlRequest.httpMethod = "POST"

        urlRequest.setValue(
            "Bearer \(trimmedKey)",
            forHTTPHeaderField:
                "Authorization"
        )

        urlRequest.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        urlRequest.httpBody =
            try JSONSerialization.data(
                withJSONObject: body
            )

        let maximumRetries = 2

        for attempt in 0...maximumRetries {

            let (data, response) =
                try await transport.data(
                    for: urlRequest
                )

            guard
                let http =
                    response
                        as? HTTPURLResponse
            else {
                throw AIProviderError
                    .invalidResponse
            }

            if (200..<300)
                .contains(
                    http.statusCode
                ) {

                guard
                    let text =
                        Self.outputText(
                            from: data
                        ),
                    !text
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                else {
                    throw AIProviderError
                        .invalidResponse
                }

                return AICompletionResponse(
                    text: text,
                    providerID:
                        providerID,
                    modelID:
                        trimmedModel
                )
            }

            if AIHTTPRetryPolicy
                .shouldRetry(
                    statusCode:
                        http.statusCode,
                    attempt: attempt,
                    maximumRetries:
                        maximumRetries
                ) {

                let delay =
                    AIHTTPRetryPolicy
                        .delaySeconds(
                            response: http,
                            attempt: attempt
                        )

                let nanoseconds =
                    UInt64(
                        max(
                            0,
                            min(delay, 60)
                        )
                        * 1_000_000_000
                    )

                try await Task.sleep(
                    nanoseconds:
                        nanoseconds
                )

                continue
            }

            throw AIProviderError.http(
                statusCode:
                    http.statusCode,
                message:
                    Self.errorMessage(
                        from: data
                    )
            )
        }

        throw AIProviderError
            .invalidResponse
    }

    private static func outputText(
        from data: Data
    ) -> String? {

        guard
            let object =
                try? JSONSerialization
                    .jsonObject(
                        with: data
                    ),
            let json =
                object
                    as? [String: Any],
            let choices =
                json["choices"]
                    as? [[String: Any]],
            let first =
                choices.first,
            let message =
                first["message"]
                    as? [String: Any]
        else {
            return nil
        }

        return message["content"]
            as? String
    }

    private static func errorMessage(
        from data: Data
    ) -> String {

        guard
            let object =
                try? JSONSerialization
                    .jsonObject(
                        with: data
                    ),
            let json =
                object
                    as? [String: Any]
        else {
            return "Unknown Kimi API error"
        }

        if let error =
            json["error"]
                as? [String: Any],
           let message =
            error["message"]
                as? String {
            return message
        }

        if let message =
            json["message"]
                as? String {
            return message
        }

        return "Unknown Kimi API error"
    }
}
