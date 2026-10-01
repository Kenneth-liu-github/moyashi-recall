import Foundation
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import MoyashiRecall

final class KimiChatCompletionsProviderTests: XCTestCase {

    func testProviderSendsKimiK26ExtractionRequest() async throws {
        let transport = KimiTestTransport { request in

            XCTAssertEqual(
                request.url?.host,
                "api.moonshot.cn"
            )

            XCTAssertEqual(
                request.url?.path,
                "/v1/chat/completions"
            )

            XCTAssertEqual(
                request.httpMethod,
                "POST"
            )

            XCTAssertEqual(
                request.value(
                    forHTTPHeaderField: "Authorization"
                ),
                "Bearer secret_test"
            )

            XCTAssertEqual(
                request.value(
                    forHTTPHeaderField: "Content-Type"
                ),
                "application/json"
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
                "kimi-k2.6"
            )

            let thinking = try XCTUnwrap(
                body["thinking"] as? [String: Any]
            )

            XCTAssertEqual(
                thinking["type"] as? String,
                "disabled"
            )

            let temperature = try XCTUnwrap(
                body["temperature"] as? NSNumber
            )

            XCTAssertEqual(
                temperature.doubleValue,
                0.6,
                accuracy: 0.0001
            )

            let maxCompletionTokens = try XCTUnwrap(
                body["max_completion_tokens"] as? NSNumber
            )

            XCTAssertEqual(
                maxCompletionTokens.intValue,
                12_000
            )

            let responseFormat = try XCTUnwrap(
                body["response_format"] as? [String: Any]
            )

            XCTAssertEqual(
                responseFormat["type"] as? String,
                "json_object"
            )

            let messages = try XCTUnwrap(
                body["messages"] as? [[String: Any]]
            )

            XCTAssertEqual(
                messages.count,
                2
            )

            XCTAssertEqual(
                messages[0]["role"] as? String,
                "system"
            )

            XCTAssertEqual(
                messages[1]["role"] as? String,
                "user"
            )

            return Self.response(
                url: request.url!,
                json: """
                {
                  "id": "chatcmpl-test",
                  "object": "chat.completion",
                  "model": "kimi-k2.6",
                  "choices": [
                    {
                      "index": 0,
                      "message": {
                        "role": "assistant",
                        "content": "{\\"status\\":\\"ok\\"}",
                        "reasoning_content": ""
                      },
                      "finish_reason": "stop"
                    }
                  ]
                }
                """
            )
        }

        let provider = KimiChatCompletionsProvider(
            apiKey: "secret_test",
            modelID: "kimi-k2.6",
            transport: transport
        )

        let result = try await provider.complete(
            request: AICompletionRequest(
                systemPrompt: "system",
                userPrompt: "user",
                responseSchemaName: "schema",
                responseSchemaJSON:
                    #"{"type":"object"}"#
            )
        )

        XCTAssertEqual(
            result.text,
            #"{"status":"ok"}"#
        )

        XCTAssertEqual(
            result.providerID,
            "kimi"
        )

        XCTAssertEqual(
            result.modelID,
            "kimi-k2.6"
        )
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

private struct KimiTestTransport: HTTPTransport {

    let handler: @Sendable (
        URLRequest
    ) throws -> (Data, URLResponse)

    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}
