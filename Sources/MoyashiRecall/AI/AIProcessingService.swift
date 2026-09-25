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
    case tooManyChunks(actual: Int, maximum: Int)
    case providerChangedDuringRun
}

@MainActor
public struct AIProcessingService {
    private let repository: LearningRepository
    private let extractor: KnowledgeExtractionService
    private let chunker: DocumentChunker
    private let maximumChunks: Int

    public init(
        repository: LearningRepository,
        provider: any AICompletionProvider,
        chunker: DocumentChunker = DocumentChunker(),
        maximumChunks: Int = 20
    ) {
        self.repository = repository
        self.extractor = KnowledgeExtractionService(
            provider: provider
        )
        self.chunker = chunker
        self.maximumChunks = max(1, maximumChunks)
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

        guard chunks.count <= maximumChunks else {
            throw AIProcessingError.tooManyChunks(
                actual: chunks.count,
                maximum: maximumChunks
            )
        }

        var bundles: [KnowledgeExtractionBundle] = []
        var providerID = ""
        var modelID = ""

        for (index, chunk) in chunks.enumerated() {
            try Task.checkCancellation()

            let document = ImportedDocument(
                id: source.id.uuidString
                    + "#chunk-\(index + 1)",
                sourceKind: source.sourceKind,
                title: source.title,
                sourceReference: source.sourceReference,
                content: chunk,
                sourcePath: source.sourcePath
                    .components(
                        separatedBy: " / "
                    )
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
                    .filter { !$0.isEmpty }
            )

            let extraction = try await extractor.extract(
                from: document
            )
            if providerID.isEmpty {
                providerID = extraction.providerID
                modelID = extraction.modelID
            } else if providerID != extraction.providerID
                        || modelID != extraction.modelID {
                throw AIProcessingError.providerChangedDuringRun
            }

            bundles.append(extraction.bundle)
        }

        try Task.checkCancellation()

        let merged = try KnowledgeBundleMerger.merge(
            bundles
        )

        try Task.checkCancellation()

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
