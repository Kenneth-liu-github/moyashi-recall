import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
                        },
                        {
                          "id": "row1",
                          "type": "table_row",
                          "has_children": false,
                          "table_row": {
                            "cells": [
                              [{"plain_text": "日语"}],
                              [{"plain_text": "中文"}]
                            ]
                          }
                        },
                        {
                          "id": "eq1",
                          "type": "equation",
                          "has_children": false,
                          "equation": {
                            "expression": "S=R"
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
        XCTAssertTrue(document.content.contains("| 日语 | 中文 |"))
        XCTAssertTrue(document.content.contains("S=R"))
        XCTAssertNotNil(document.lastEditedAt)

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

    func testSearchPagesPaginatesAndParsesTitles() async throws {
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

            if json["start_cursor"] == nil {
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
                      "next_cursor": "cursor-2",
                      "has_more": true
                    }
                    """
                )
            }

            XCTAssertEqual(
                json["start_cursor"] as? String,
                "cursor-2"
            )

            return Self.response(
                url: request.url!,
                json: """
                {
                  "object": "list",
                  "results": [
                    {
                      "object": "page",
                      "id": "page-2",
                      "url": "https://www.notion.so/page-2",
                      "last_edited_time": "2026-09-24T13:00:00Z",
                      "properties": {
                        "title": {
                          "type": "title",
                          "title": [
                            {"plain_text": "Learning Home Child"}
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

        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[0].id, "page-1")
        XCTAssertEqual(pages[0].title, "Learning Home")
        XCTAssertNotNil(pages[0].lastEditedAt)
        XCTAssertEqual(pages[1].id, "page-2")
        XCTAssertEqual(pages[1].title, "Learning Home Child")
        XCTAssertEqual(transport.requests.count, 2)
    }

    func testFetchDocumentTreeImportsChildPagesSeparately() async throws {
        let transport = MockHTTPTransport { request in
            let path = request.url?.path ?? ""

            switch path {
            case "/v1/pages/root":
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "id": "root",
                      "url": "https://www.notion.so/root",
                      "properties": {
                        "title": {
                          "type": "title",
                          "title": [{"plain_text": "Learning Home"}]
                        }
                      }
                    }
                    """
                )

            case "/v1/blocks/root/children":
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "object": "list",
                      "results": [
                        {
                          "id": "child-1",
                          "type": "child_page",
                          "has_children": false,
                          "child_page": {
                            "title": "办公室日语学习"
                          }
                        }
                      ],
                      "next_cursor": null,
                      "has_more": false
                    }
                    """
                )

            case "/v1/pages/child-1":
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "id": "child-1",
                      "url": "https://www.notion.so/child-1",
                      "properties": {
                        "title": {
                          "type": "title",
                          "title": [{"plain_text": "办公室日语学习"}]
                        }
                      }
                    }
                    """
                )

            case "/v1/blocks/child-1/children":
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
                              {"plain_text": "第二课内容"}
                            ]
                          }
                        }
                      ],
                      "next_cursor": null,
                      "has_more": false
                    }
                    """
                )

            default:
                XCTFail(
                    "Unexpected request: \(request.url?.absoluteString ?? "nil")"
                )
                return Self.response(
                    url: request.url!,
                    statusCode: 404,
                    json: """
                    {"message": "not found"}
                    """
                )
            }
        }

        let client = NotionAPIClient(
            token: "secret_test",
            transport: transport,
            baseURL: URL(string: "https://api.notion.test")!
        )

        let documents = try await client.fetchDocumentTree(
            rootID: "root"
        )

        XCTAssertEqual(documents.count, 2)
        XCTAssertEqual(documents[0].id, "root")
        XCTAssertEqual(documents[0].title, "Learning Home")
        XCTAssertNil(documents[0].parentExternalID)
        XCTAssertEqual(documents[0].rootExternalID, "root")
        XCTAssertEqual(
            documents[0].sourcePath,
            ["Learning Home"]
        )
        XCTAssertEqual(documents[0].hierarchyDepth, 0)

        XCTAssertEqual(documents[1].id, "child-1")
        XCTAssertEqual(
            documents[1].title,
            "办公室日语学习"
        )
        XCTAssertEqual(
            documents[1].parentExternalID,
            "root"
        )
        XCTAssertEqual(documents[1].rootExternalID, "root")
        XCTAssertEqual(
            documents[1].sourcePath,
            ["Learning Home", "办公室日语学习"]
        )
        XCTAssertEqual(documents[1].hierarchyDepth, 1)
        XCTAssertTrue(
            documents[1].content.contains("第二课内容")
        )
    }

    func testDocumentTreeHonorsPageLimit() async throws {
        let transport = MockHTTPTransport { request in
            let path = request.url?.path ?? ""

            if path == "/v1/pages/root" {
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "id": "root",
                      "properties": {
                        "title": {
                          "type": "title",
                          "title": [{"plain_text": "Root"}]
                        }
                      }
                    }
                    """
                )
            }

            if path == "/v1/blocks/root/children" {
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "object": "list",
                      "results": [
                        {
                          "id": "child-1",
                          "type": "child_page",
                          "has_children": false,
                          "child_page": {"title": "Child"}
                        }
                      ],
                      "next_cursor": null,
                      "has_more": false
                    }
                    """
                )
            }

            XCTFail("Page limit should prevent child fetch")
            return Self.response(
                url: request.url!,
                statusCode: 500,
                json: """
                {"message": "unexpected"}
                """
            )
        }

        let client = NotionAPIClient(
            token: "secret_test",
            transport: transport,
            baseURL: URL(string: "https://api.notion.test")!
        )

        let documents = try await client.fetchDocumentTree(
            rootID: "root",
            maxPages: 1
        )

        XCTAssertEqual(documents.map(\.id), ["root"])
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
