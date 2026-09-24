import XCTest
@testable import MoyashiRecall

final class NotionAPIClientTests: XCTestCase {
    func testFetchDocumentUsesCurrentAPIVersionAndRecursesBlocks() async throws {
        let transport = MockHTTPTransport { request in
            let path = request.url?.path ?? ""
            let query = request.url?.query ?? ""

            if path == "/v1/pages/root" {
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "id": "root",
                      "url": "https://www.notion.so/root",
                      "last_edited_time": "2026-09-24T12:00:00.000Z",
                      "properties": {
                        "Name": {
                          "type": "title",
                          "title": [
                            {"plain_text": "办公室日语学习"}
                          ]
                        }
                      }
                    }
                    """
                )
            }

            if path == "/v1/blocks/root/children",
               !query.contains("start_cursor") {
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "object": "list",
                      "results": [
                        {
                          "id": "p1",
                          "type": "paragraph",
                          "has_children": false,
                          "paragraph": {
                            "rich_text": [
                              {"plain_text": "第一段"}
                            ]
                          }
                        },
                        {
                          "id": "toggle1",
                          "type": "toggle",
                          "has_children": true,
                          "toggle": {
                            "rich_text": [
                              {"plain_text": "展开内容"}
                            ]
                          }
                        }
                      ],
                      "next_cursor": "cursor-2",
                      "has_more": true
                    }
                    """
                )
            }

            if path == "/v1/blocks/root/children",
               query.contains("start_cursor=cursor-2") {
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "object": "list",
                      "results": [
                        {
                          "id": "h1",
                          "type": "heading_2",
                          "has_children": false,
                          "heading_2": {
                            "rich_text": [
                              {"plain_text": "重点语法"}
                            ]
                          }
                        }
                      ],
                      "next_cursor": null,
                      "has_more": false
                    }
                    """
                )
            }

            if path == "/v1/blocks/toggle1/children" {
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "object": "list",
                      "results": [
                        {
                          "id": "b1",
                          "type": "bulleted_list_item",
                          "has_children": false,
                          "bulleted_list_item": {
                            "rich_text": [
                              {"plain_text": "～について"}
                            ]
                          }
                        }
                      ],
                      "next_cursor": null,
                      "has_more": false
                    }
                    """
                )
            }

            XCTFail("Unexpected request: \(request.url?.absoluteString ?? "nil")")
            return Self.response(
                url: request.url!,
                statusCode: 404,
                json: """
                {"message": "not found"}
                """
            )
        }

        let client = NotionAPIClient(
            token: "secret_test",
            transport: transport,
            baseURL: URL(string: "https://api.notion.test")!
        )

        let document = try await client.fetchDocument(id: "root")

        XCTAssertEqual(document.title, "办公室日语学习")
        XCTAssertEqual(document.sourceKind, "notion")
        XCTAssertTrue(document.content.contains("第一段"))
        XCTAssertTrue(document.content.contains("展开内容"))
        XCTAssertTrue(document.content.contains("～について"))
        XCTAssertTrue(document.content.contains("## 重点语法"))

        let requests = transport.requests
        XCTAssertEqual(requests.count, 4)
        XCTAssertTrue(
            requests.allSatisfy {
                $0.value(forHTTPHeaderField: "Notion-Version")
                    == NotionAPIClient.apiVersion
            }
        )
        XCTAssertTrue(
            requests.allSatisfy {
                $0.value(forHTTPHeaderField: "Authorization")
                    == "Bearer secret_test"
            }
        )
    }

    func testSearchPagesPostsPageFilterAndParsesTitles() async throws {
        let transport = MockHTTPTransport { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/v1/search")

            let body = try XCTUnwrap(request.httpBody)
            let object = try JSONSerialization.jsonObject(with: body)
            let json = try XCTUnwrap(object as? [String: Any])
            let filter = try XCTUnwrap(json["filter"] as? [String: Any])

            XCTAssertEqual(json["query"] as? String, "Learning Home")
            XCTAssertEqual(filter["property"] as? String, "object")
            XCTAssertEqual(filter["value"] as? String, "page")

            return Self.response(
                url: request.url!,
                json: """
                {
                  "object": "list",
                  "results": [
                    {
                      "object": "page",
                      "id": "page-1",
                      "url": "https://www.notion.so/page-1",
                      "last_edited_time": "2026-09-24T12:00:00.000Z",
                      "properties": {
                        "title": {
                          "type": "title",
                          "title": [
                            {"plain_text": "Learning Home"}
                          ]
                        }
                      }
                    }
                  ],
                  "next_cursor": null,
                  "has_more": false
                }
                """
            )
        }

        let client = NotionAPIClient(
            token: "secret_test",
            transport: transport,
            baseURL: URL(string: "https://api.notion.test")!
        )

        let pages = try await client.searchPages(
            query: "Learning Home"
        )

        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages.first?.id, "page-1")
        XCTAssertEqual(pages.first?.title, "Learning Home")
    }

    func testHTTPErrorSurfacesNotionMessage() async throws {
        let transport = MockHTTPTransport { request in
            Self.response(
                url: request.url!,
                statusCode: 403,
                json: """
                {
                  "object": "error",
                  "status": 403,
                  "code": "restricted_resource",
                  "message": "No access to this page."
                }
                """
            )
        }

        let client = NotionAPIClient(
            token: "secret_test",
            transport: transport,
            baseURL: URL(string: "https://api.notion.test")!
        )

        do {
            _ = try await client.retrievePage(id: "missing")
            XCTFail("Expected API error")
        } catch let error as NotionAPIError {
            XCTAssertEqual(
                error,
                .http(
                    statusCode: 403,
                    message: "No access to this page."
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
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(json.utf8), response)
    }
}

private final class MockHTTPTransport: HTTPTransport {
    typealias Handler = (URLRequest) throws -> (Data, URLResponse)

    private let handler: Handler
    private(set) var requests: [URLRequest] = []

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        return try handler(request)
    }
}
