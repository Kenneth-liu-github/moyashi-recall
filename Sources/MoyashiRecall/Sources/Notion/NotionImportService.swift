import Foundation

public struct NotionSyncReport: Equatable, Sendable {
    public let totalPages: Int
    public let inserted: Int
    public let updated: Int
    public let unchanged: Int
    public let deactivated: Int
    public let isComplete: Bool

    public init(
        totalPages: Int,
        inserted: Int,
        updated: Int,
        unchanged: Int,
        deactivated: Int,
        isComplete: Bool
    ) {
        self.totalPages = totalPages
        self.inserted = inserted
        self.updated = updated
        self.unchanged = unchanged
        self.deactivated = deactivated
        self.isComplete = isComplete
    }
}

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
        let tree = try await client.fetchDocumentTreeResult(
            rootID: rootID,
            maxDepth: maxDepth,
            maxPages: maxPages
        )

        let items = try tree.documents.map { document in
            try repository.upsertImportedDocument(
                document,
                now: now
            )
        }

        if tree.isComplete {
            _ = try repository.reconcileImportedTree(
                sourceKind: client.kind,
                rootExternalID: rootID,
                activeExternalIDs: Set(tree.documents.map(\.id)),
                now: now
            )
        }

        return items
    }

    public func syncPageTreeReport(
        rootID: String,
        maxDepth: Int = 8,
        maxPages: Int = 200,
        now: Date = .now
    ) async throws -> NotionSyncReport {
        let tree = try await client.fetchDocumentTreeResult(
            rootID: rootID,
            maxDepth: maxDepth,
            maxPages: maxPages
        )

        var inserted = 0
        var updated = 0
        var unchanged = 0

        for document in tree.documents {
            let result = try repository
                .upsertImportedDocumentWithResult(
                    document,
                    now: now
                )

            switch result.mutation {
            case .inserted:
                inserted += 1
            case .updated:
                updated += 1
            case .unchanged:
                unchanged += 1
            }
        }

        let deactivated: Int
        if tree.isComplete {
            deactivated = try repository.reconcileImportedTree(
                sourceKind: client.kind,
                rootExternalID: rootID,
                activeExternalIDs: Set(tree.documents.map(\.id)),
                now: now
            )
        } else {
            deactivated = 0
        }

        return NotionSyncReport(
            totalPages: tree.documents.count,
            inserted: inserted,
            updated: updated,
            unchanged: unchanged,
            deactivated: deactivated,
            isComplete: tree.isComplete
        )
    }
}
