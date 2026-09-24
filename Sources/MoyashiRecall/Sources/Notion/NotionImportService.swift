import Foundation

@MainActor
public struct NotionImportService {
    private let repository: LearningRepository
    private let client: NotionAPIClient

    public init(
        repository: LearningRepository,
        client: NotionAPIClient
    ) {
        self.repository = repository
        self.client = client
    }

    @discardableResult
    public func syncPage(
        id: String,
        now: Date = .now
    ) async throws -> KnowledgeItemEntity {
        let document = try await client.fetchDocument(id: id)
        return try repository.upsertImportedDocument(
            document,
            now: now
        )
    }

    @discardableResult
    public func syncPageTree(
        rootID: String,
        maxDepth: Int = 8,
        maxPages: Int = 200,
        now: Date = .now
    ) async throws -> [KnowledgeItemEntity] {
        let documents = try await client.fetchDocumentTree(
            rootID: rootID,
            maxDepth: maxDepth,
            maxPages: maxPages
        )

        return try documents.map { document in
            try repository.upsertImportedDocument(
                document,
                now: now
            )
        }
    }
}
