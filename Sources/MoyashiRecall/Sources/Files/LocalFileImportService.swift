import Foundation

public struct FileImportReport: Equatable, Sendable {
    public let title: String
    public let documentCount: Int
    public let inserted: Int
    public let updated: Int
    public let unchanged: Int
    public let deactivated: Int

    public init(
        title: String,
        documentCount: Int,
        inserted: Int,
        updated: Int,
        unchanged: Int,
        deactivated: Int
    ) {
        self.title = title
        self.documentCount = documentCount
        self.inserted = inserted
        self.updated = updated
        self.unchanged = unchanged
        self.deactivated = deactivated
    }
}

@MainActor
public struct LocalFileImportService {
    private let repository: LearningRepository
    private let importer: LocalFileImporter

    public init(
        repository: LearningRepository,
        importer: LocalFileImporter = LocalFileImporter()
    ) {
        self.repository = repository
        self.importer = importer
    }

    public func importFile(
        at url: URL,
        now: Date = .now
    ) throws -> FileImportReport {
        let result = try importer.importFile(at: url)
        guard let root = result.documents.first else {
            throw LocalFileImportError.emptyContent
        }

        var inserted = 0
        var updated = 0
        var unchanged = 0

        for document in result.documents {
            let upsert = try repository
                .upsertImportedDocumentWithResult(
                    document,
                    now: now
                )

            switch upsert.mutation {
            case .inserted:
                inserted += 1
            case .updated:
                updated += 1
            case .unchanged:
                unchanged += 1
            }
        }

        let activeIDs = Set(
            result.documents.map(\.id)
        )
        let deactivated = try repository.reconcileImportedTree(
            sourceKind: root.sourceKind,
            rootExternalID: root.rootExternalID,
            activeExternalIDs: activeIDs,
            now: now
        )

        return FileImportReport(
            title: root.title,
            documentCount: result.documents.count,
            inserted: inserted,
            updated: updated,
            unchanged: unchanged,
            deactivated: deactivated
        )
    }
}
