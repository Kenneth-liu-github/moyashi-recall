import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import MoyashiRecall

final class OpenAIResponsesProviderTests: XCTestCase {
    func testProviderSendsStructuredOutputRequest() async throws {
        let transport = OpenAITestTransport { request in
            XCTAssertEqual(
                request.url?.path,
                "/v1/responses"
            )
            XCTAssertEqual(
                request.value(
                    forHTTPHeaderField: "Authorization"
                ),
                "Bearer secret_test"
            )

            let bodyData = try XCTUnwrap(
                request.httpBody
            )
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
                body["store"] as? Bool,
                false
            )

            let text = try XCTUnwrap(
                body["text"] as? [String: Any]
            )
            let format = try XCTUnwrap(
                text["format"] as? [String: Any]
            )
            XCTAssertEqual(
                format["type"] as? String,
                "json_schema"
            )
            XCTAssertEqual(
                format["name"] as? String,
                "schema-name"
            )
            XCTAssertEqual(
                format["strict"] as? Bool,
                true
            )
            XCTAssertNotNil(format["schema"])

            return Self.response(
                url: request.url!,
                json: """
                {
                  "output_text": "{\"version\":\"v1\",\"items\":[]}"
                }
                """
            )
        }

        let provider = OpenAIResponsesProvider(
            apiKey: "secret_test",
            modelID: "configured-model",
            transport: transport,
            baseURL: URL(
                string: "https://api.openai.test"
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
        XCTAssertEqual(result.providerID, "openai")
        XCTAssertEqual(result.modelID, "configured-model")
    }

    func testProviderReadsNestedOutputTextFallback() async throws {
        let transport = OpenAITestTransport { request in
            Self.response(
                url: request.url!,
                json: """
                {
                  "output": [
                    {
                      "type": "message",
                      "content": [
                        {
                          "type": "output_text",
                          "text": "{\"version\":\"v1\",\"items\":[]}"
                        }
                      ]
                    }
                  ]
                }
                """
            )
        }

        let provider = OpenAIResponsesProvider(
            apiKey: "secret_test",
            modelID: "configured-model",
            transport: transport,
            baseURL: URL(
                string: "https://api.openai.test"
            )!
        )

        let response = try await provider.complete(
            request: AICompletionRequest(
                systemPrompt: "system",
                userPrompt: "user",
                responseSchemaName: "schema",
                responseSchemaJSON: #"{"type":"object"}"#
            )
        )

        XCTAssertEqual(
            response.text,
            #"{"version":"v1","items":[]}"#
        )
    }

    func testProviderSurfacesHTTPErrorMessage() async throws {
        let transport = OpenAITestTransport { request in
            Self.response(
                url: request.url!,
                statusCode: 401,
                json: """
                {
                  "error": {
                    "message": "Invalid API key"
                  }
                }
                """
            )
        }

        let provider = OpenAIResponsesProvider(
            apiKey: "bad-key",
            modelID: "configured-model",
            transport: transport,
            baseURL: URL(
                string: "https://api.openai.test"
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

    private static func response(
        url: URL,
        statusCode: Int = 200,
        json: String
    ) -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: [
                "Content-Type": "application/json"
            ]
        )!
        return (
            Data(json.utf8),
            response
        )
    }
}

private struct OpenAITestTransport: HTTPTransport {
    let handler: @Sendable (
        URLRequest
    ) throws -> (Data, URLResponse)

    init(
        handler: @escaping @Sendable (
            URLRequest
        ) throws -> (Data, URLResponse)
    ) {
        self.handler = handler
    }

    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}
