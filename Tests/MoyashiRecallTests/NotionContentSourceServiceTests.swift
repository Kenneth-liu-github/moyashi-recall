import XCTest
@testable import MoyashiRecall

final class NotionContentSourceServiceTests: XCTestCase {
    struct FixtureTransport: HTTPTransport {
        let pageData: Data
        let firstBlocksData: Data
        let secondBlocksData: Data

        func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let url = try XCTUnwrap(request.url)
            let data: Data

            if url.path.contains("/pages/") {
                data = pageData
            } else if url.query?.contains("start_cursor=next-page") == true {
                data = secondBlocksData
            } else {
                data = firstBlocksData
            }

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            return (data, response)
        }
    }

    func testNotionPageIsNormalizedIntoSourceDocument() async throws {
        let page = Data(
            """
            {
              "id": "page-1",
              "last_edited_time": "2026-09-24T10:00:00.000Z",
              "parent": { "page_id": "parent-1" },
              "properties": {
                "title": {
                  "type": "title",
                  "title": [
                    { "plain_text": "办公室日语学习" }
                  ]
                }
              }
            }
            """.utf8
        )

        let firstBlocks = Data(
            """
            {
              "results": [
                {
                  "type": "heading_1",
                  "heading_1": {
                    "rich_text": [{ "plain_text": "第二课" }]
                  }
                },
                {
                  "type": "paragraph",
                  "paragraph": {
                    "rich_text": [{ "plain_text": "進め方について" }]
                  }
                }
              ],
              "next_cursor": "next-page",
              "has_more": true
            }
            """.utf8
        )

        let secondBlocks = Data(
            """
            {
              "results": [
                {
                  "type": "bulleted_list_item",
                  "bulleted_list_item": {
                    "rich_text": [{ "plain_text": "Natural English: regarding how to proceed" }]
                  }
                }
              ],
              "next_cursor": null,
              "has_more": false
            }
            """.utf8
        )

        let service = NotionContentSourceService(
            configuration: NotionConfiguration(
                token: "test-token",
                baseURL: URL(string: "https://example.test/v1")!
            ),
            transport: FixtureTransport(
                pageData: page,
                firstBlocksData: firstBlocks,
                secondBlocksData: secondBlocks
            )
        )

        let document = try await service.fetchDocument(id: "page-1")

        XCTAssertEqual(document.id, "page-1")
        XCTAssertEqual(document.sourceKind, .notion)
        XCTAssertEqual(document.title, "办公室日语学习")
        XCTAssertEqual(document.parentID, "parent-1")
        XCTAssertEqual(
            document.plainText,
            "第二课\n進め方について\nNatural English: regarding how to proceed"
        )
        XCTAssertEqual(document.sourceReference, "Notion · 办公室日语学习")
    }

    func testHTTPFailureIsSurfaced() async {
        struct FailureTransport: HTTPTransport {
            func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (Data(), response)
            }
        }

        let service = NotionContentSourceService(
            configuration: NotionConfiguration(
                token: "bad-token",
                baseURL: URL(string: "https://example.test/v1")!
            ),
            transport: FailureTransport()
        )

        do {
            _ = try await service.fetchDocument(id: "page-1")
            XCTFail("Expected authentication failure")
        } catch let error as NotionAPIError {
            XCTAssertEqual(error, .httpStatus(401))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
