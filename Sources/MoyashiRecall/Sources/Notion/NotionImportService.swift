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
}
