import Foundation
import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import MoyashiRecall

final class AnthropicMessagesProviderTests: XCTestCase {
    func testProviderSendsStructuredOutputRequest() async throws {
        let transport = AnthropicTestTransport { request in
            XCTAssertEqual(
                request.url?.path,
                "/v1/messages"
            )
            XCTAssertEqual(
                request.value(
                    forHTTPHeaderField: "x-api-key"
                ),
                "secret_test"
            )
            XCTAssertEqual(
                request.value(
                    forHTTPHeaderField: "anthropic-version"
                ),
                AnthropicMessagesProvider.apiVersion
            )

            let bodyData = try XCTUnwrap(request.httpBody)
            let object = try JSONSerialization.jsonObject(
                with: bodyData
            )
            let body = try XCTUnwrap(
                object as? [String: Any]
            )

            XCTAssertEqual(
                body["model"] as? String,
                "configured-model"
            )
            XCTAssertEqual(
                body["system"] as? String,
                "system"
            )

            let outputConfig = try XCTUnwrap(
                body["output_config"] as? [String: Any]
            )
            let format = try XCTUnwrap(
                outputConfig["format"] as? [String: Any]
            )
            XCTAssertEqual(
                format["type"] as? String,
                "json_schema"
            )
            XCTAssertNotNil(format["schema"])

            return Self.response(
                url: request.url!,
                json: """
                {
                  "content": [
                    {
                      "type": "text",
                      "text": "{\\\"version\\\":\\\"v1\\\",\\\"items\\\":[]}"
                    }
                  ]
                }
                """
            )
        }

        let provider = AnthropicMessagesProvider(
            apiKey: "secret_test",
            modelID: "configured-model",
            transport: transport,
            baseURL: URL(
                string: "https://api.anthropic.test"
            )!
        )

        let result = try await provider.complete(
            request: AICompletionRequest(
                systemPrompt: "system",
                userPrompt: "user",
                responseSchemaName: "schema-name",
                responseSchemaJSON: """
                {
                  "type": "object",
                  "properties": {},
                  "additionalProperties": false
                }
                """
            )
        )

        XCTAssertEqual(
            result.text,
            #"{"version":"v1","items":[]}"#
        )
        XCTAssertEqual(result.providerID, "anthropic")
        XCTAssertEqual(
            result.modelID,
            "configured-model"
        )
    }

    func testProviderSurfacesTruncatedGeneration() async throws {
        let transport = AnthropicTestTransport { request in
            Self.response(
                url: request.url!,
                json: """
                {
                  "stop_reason": "max_tokens",
                  "content": [
                    {
                      "type": "text",
                      "text": "{"
                    }
                  ]
                }
                """
            )
        }

        let provider = AnthropicMessagesProvider(
            apiKey: "secret_test",
            modelID: "configured-model",
            transport: transport,
            baseURL: URL(
                string: "https://api.anthropic.test"
            )!
        )

        do {
            _ = try await provider.complete(
                request: AICompletionRequest(
                    systemPrompt: "system",
                    userPrompt: "user",
                    responseSchemaName: "schema",
                    responseSchemaJSON: #"{"type":"object"}"#
                )
            )
            XCTFail("Expected incomplete response")
        } catch let error as AIProviderError {
            XCTAssertEqual(
                error,
                .incomplete("max_tokens")
            )
        }
    }

    func testProviderSurfacesHTTPErrorMessage() async throws {
        let transport = AnthropicTestTransport { request in
            Self.response(
                url: request.url!,
                statusCode: 401,
                json: """
                {
                  "type": "error",
                  "error": {
                    "type": "authentication_error",
                    "message": "Invalid API key"
                  }
                }
                """
            )
        }

        let provider = AnthropicMessagesProvider(
            apiKey: "bad-key",
            modelID: "configured-model",
            transport: transport,
            baseURL: URL(
                string: "https://api.anthropic.test"
            )!
        )

        do {
            _ = try await provider.complete(
                request: AICompletionRequest(
                    systemPrompt: "system",
                    userPrompt: "user",
                    responseSchemaName: "schema",
                    responseSchemaJSON: #"{"type":"object"}"#
                )
            )
            XCTFail("Expected HTTP error")
        } catch let error as AIProviderError {
            XCTAssertEqual(
                error,
                .http(
                    statusCode: 401,
                    message: "Invalid API key"
                )
            )
        }
    }

    func testProviderRetriesRateLimit() async throws {
        let transport = AnthropicRateLimitTransport()

        let provider = AnthropicMessagesProvider(
            apiKey: "secret_test",
            modelID: "configured-model",
            transport: transport,
            baseURL: URL(
                string: "https://api.anthropic.test"
            )!
        )

        let result = try await provider.complete(
            request: AICompletionRequest(
                systemPrompt: "system",
                userPrompt: "user",
                responseSchemaName: "schema",
                responseSchemaJSON: #"{"type":"object"}"#
            )
        )

        XCTAssertEqual(result.providerID, "anthropic")
        let attempts = await transport.attemptCount()
        XCTAssertEqual(attempts, 2)
    }

    private static func response(
        url: URL,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        json: String
    ) -> (Data, URLResponse) {
        var responseHeaders = [
            "Content-Type": "application/json"
        ]
        for (key, value) in headers {
            responseHeaders[key] = value
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: responseHeaders
        )!
        return (
            Data(json.utf8),
            response
        )
    }
}

private struct AnthropicTestTransport: HTTPTransport {
    let handler: @Sendable (
        URLRequest
    ) throws -> (Data, URLResponse)

    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}

private actor AnthropicRateLimitTransport: HTTPTransport {
    private var attempts = 0

    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        attempts += 1

        if attempts == 1 {
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "Retry-After": "0"
                ]
            )!
            return (
                Data(
                    #"{"error":{"message":"Slow down"}}"#.utf8
                ),
                response
            )
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "Content-Type": "application/json"
            ]
        )!
        return (
            Data(
                """
                {
                  "content": [
                    {
                      "type": "text",
                      "text": "{\\\"version\\\":\\\"v1\\\",\\\"items\\\":[]}"
                    }
                  ]
                }
                """.utf8
            ),
            response
        )
    }

    func attemptCount() -> Int {
        attempts
    }
}
