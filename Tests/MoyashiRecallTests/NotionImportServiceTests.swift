import XCTest
import SwiftData
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import MoyashiRecall

final class NotionImportServiceTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: SourceDocumentEntity.self,
            KnowledgeItemEntity.self,
            FlashcardEntity.self,
            ReviewStateEntity.self,
            ReviewHistoryEntity.self,
            configurations: configuration
        )
    }

    @MainActor
    func testPartialTreeSyncDoesNotDeactivateUnseenPages() async throws {
        let container = try makeContainer()
        let repository = LearningRepository(
            context: container.mainContext
        )

        _ = try repository.upsertImportedDocument(
            ImportedDocument(
                id: "root",
                sourceKind: "notion",
                title: "Learning Home",
                sourceReference: "notion://root",
                content: "root",
                rootExternalID: "root",
                sourcePath: ["Learning Home"]
            )
        )
        _ = try repository.upsertImportedDocument(
            ImportedDocument(
                id: "existing-child",
                sourceKind: "notion",
                title: "办公室日语学习",
                sourceReference: "notion://existing-child",
                content: "existing",
                parentExternalID: "root",
                rootExternalID: "root",
                sourcePath: [
                    "Learning Home",
                    "办公室日语学习"
                ],
                hierarchyDepth: 1
            )
        )

        let transport = ImportServiceHTTPTransport { request in
            switch request.url?.path {
            case "/v1/pages/root":
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "id": "root",
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
                          "id": "new-child",
                          "type": "child_page",
                          "has_children": false,
                          "child_page": {"title": "日语训练营"}
                        }
                      ],
                      "next_cursor": null,
                      "has_more": false
                    }
                    """
                )

            default:
                XCTFail("Unexpected request: \(request.url?.absoluteString ?? "nil")")
                return Self.response(
                    url: request.url!,
                    statusCode: 500,
                    json: #"{"message":"unexpected"}"#
                )
            }
        }

        let service = NotionImportService(
            repository: repository,
            client: NotionAPIClient(
                token: "test",
                transport: transport,
                baseURL: URL(string: "https://api.notion.test")!
            )
        )

        let report = try await service.syncPageTreeReport(
            rootID: "root",
            maxPages: 1
        )

        XCTAssertFalse(report.isComplete)
        XCTAssertEqual(report.deactivated, 0)

        let visible = try repository.importedDocuments(
            sourceKind: "notion"
        )
        XCTAssertTrue(
            visible.contains {
                $0.externalSourceID == "existing-child"
            }
        )
    }

    @MainActor
    func testCompleteTreeSyncReportsAndDeactivatesRemovedPages() async throws {
        let container = try makeContainer()
        let repository = LearningRepository(
            context: container.mainContext
        )

        _ = try repository.upsertImportedDocument(
            ImportedDocument(
                id: "stale-child",
                sourceKind: "notion",
                title: "旧页面",
                sourceReference: "notion://stale-child",
                content: "old",
                parentExternalID: "root",
                rootExternalID: "root",
                sourcePath: ["Learning Home", "旧页面"],
                hierarchyDepth: 1
            )
        )

        let transport = ImportServiceHTTPTransport { request in
            switch request.url?.path {
            case "/v1/pages/root":
                return Self.response(
                    url: request.url!,
                    json: """
                    {
                      "id": "root",
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
                      "results": [],
                      "next_cursor": null,
                      "has_more": false
                    }
                    """
                )

            default:
                XCTFail("Unexpected request")
                return Self.response(
                    url: request.url!,
                    statusCode: 500,
                    json: #"{"message":"unexpected"}"#
                )
            }
        }

        let service = NotionImportService(
            repository: repository,
            client: NotionAPIClient(
                token: "test",
                transport: transport,
                baseURL: URL(string: "https://api.notion.test")!
            )
        )

        let report = try await service.syncPageTreeReport(
            rootID: "root"
        )

        XCTAssertTrue(report.isComplete)
        XCTAssertEqual(report.totalPages, 1)
        XCTAssertEqual(report.inserted, 1)
        XCTAssertEqual(report.updated, 0)
        XCTAssertEqual(report.unchanged, 0)
        XCTAssertEqual(report.deactivated, 1)

        let visible = try repository.importedDocuments(
            sourceKind: "notion"
        )
        XCTAssertEqual(
            visible.map(\.externalSourceID),
            ["root"]
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
        return (Data(json.utf8), response)
    }
}

private final class ImportServiceHTTPTransport: HTTPTransport, @unchecked Sendable {
    typealias Handler = (
        URLRequest
    ) throws -> (Data, URLResponse)

    private let handler: Handler

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}
