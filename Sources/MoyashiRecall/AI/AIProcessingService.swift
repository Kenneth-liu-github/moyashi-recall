import Foundation

public struct AIProcessingResult: Equatable, Sendable {
    public let sourceDocumentID: UUID
    public let providerID: String
    public let modelID: String
    public let chunksProcessed: Int
    public let extractedItems: Int
    public let persistence: ExtractionPersistenceReport

    public init(
        sourceDocumentID: UUID,
        providerID: String,
        modelID: String,
        chunksProcessed: Int,
        extractedItems: Int,
        persistence: ExtractionPersistenceReport
    ) {
        self.sourceDocumentID = sourceDocumentID
        self.providerID = providerID
        self.modelID = modelID
        self.chunksProcessed = chunksProcessed
        self.extractedItems = extractedItems
        self.persistence = persistence
    }
}

public enum AIProcessingError: Error, Equatable {
    case sourceDocumentNotFound(UUID)
    case emptySourceDocument(UUID)
}

@MainActor
public struct AIProcessingService {
    private let repository: LearningRepository
    private let extractor: KnowledgeExtractionService
    private let chunker: DocumentChunker

    public init(
        repository: LearningRepository,
        provider: any AICompletionProvider,
        chunker: DocumentChunker = DocumentChunker()
    ) {
        self.repository = repository
        self.extractor = KnowledgeExtractionService(
            provider: provider
        )
        self.chunker = chunker
    }

    public func process(
        sourceDocumentID: UUID,
        now: Date = .now
    ) async throws -> AIProcessingResult {
        guard let source = try repository.sourceDocument(
            id: sourceDocumentID
        ) else {
            throw AIProcessingError.sourceDocumentNotFound(
                sourceDocumentID
            )
        }

        let chunks = chunker.chunks(
            text: source.content
        )
        guard !chunks.isEmpty else {
            throw AIProcessingError.emptySourceDocument(
                sourceDocumentID
            )
        }

        var bundles: [KnowledgeExtractionBundle] = []
        var providerID = ""
        var modelID = ""

        for (index, chunk) in chunks.enumerated() {
            let document = ImportedDocument(
                id: source.id.uuidString
                    + "#chunk-\(index + 1)",
                sourceKind: source.sourceKind,
                title: source.title,
                sourceReference: source.sourceReference,
                content: chunk,
                sourcePath: source.sourcePath
                    .split(separator: "/")
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
            )

            let extraction = try await extractor.extract(
                from: document
            )
            bundles.append(extraction.bundle)
            providerID = extraction.providerID
            modelID = extraction.modelID
        }

        let merged = try KnowledgeBundleMerger.merge(
            bundles
        )

        let persistence = try repository.persistExtraction(
            merged,
            sourceDocumentID: sourceDocumentID,
            providerID: providerID,
            modelID: modelID,
            now: now
        )

        return AIProcessingResult(
            sourceDocumentID: sourceDocumentID,
            providerID: providerID,
            modelID: modelID,
            chunksProcessed: chunks.count,
            extractedItems: merged.items.count,
            persistence: persistence
        )
    }
}
